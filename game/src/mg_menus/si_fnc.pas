//############################################################################//
unit si_fnc;
interface
uses asys,grph,sdigrtools,mgrecs,mgl_common,mgl_rmnu,sdirecs,sdiauxi,sdicalcs,sdiinit,sdimenu,sdigui,sdisound,sdiovermind,sds_rec,si_nothing;
//############################################################################//
implementation
//############################################################################//
var btn_ut:array[0..11]of pbutton_type;
dbg_btn:pbutton_type;
//############################################################################//
const
btn_width=100;
btn_height=50;
btn_gap=5;
btn_top_gap=35;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
var cp:pplrtyp;
begin
 case par of
  601:set_game_menu(s.the_game,MG_CUSTOM_CLRS);
  602:set_game_menu(s.the_game,MG_DIPLOMACY);
  603:s.show_comments:=not s.show_comments;

  700:begin snd_click(SND_ACCEPT);set_game_menu(s.the_game,MG_ESCSAVE);event_frame(s);end;
  701:begin set_game_menu(s.the_game,MG_REPORT); event_frame(s);end;
  702:begin no_reset:=true;go_end_turn(s,false);event_units(s);end;  //no_reset prevents the si_nothing from nuking the update list
  703:so_set_zoom(s,so_range_by_zoom(s,s.clinfo.sopt.zoom-1),scrx div 2,scry div 2);
  704:so_set_zoom(s,so_range_by_zoom(s,s.clinfo.sopt.zoom+1),scrx div 2,scry div 2);
    
  705:if s.the_game.info.rules.debug then set_game_menu(s.the_game,MG_DEBUG);
  706:begin
   add_step(@s.steps,sts_fetch_plrshort);
   add_step(@s.steps,sts_fetch_all_units);
   add_step(@s.steps,sts_set_cdata);
  end;

  800:s.cur_menu_page:=1;
  
  900:s.cur_menu_page:=2;
  

  801..812:begin  
   cp:=get_cur_plr(s.the_game);
   event_map_reposition(s);
   event_frame(s);
   snd_click(SND_TOGGLE);
   s.clinfo.sopt.frame_btn[par-801]:=1-s.clinfo.sopt.frame_btn[par-801];   
   if is_landed(s.the_game,cp) then add_step(@s.steps,sts_set_cdata);
  end;
 end;
end;
//############################################################################//
procedure draw(s:psdi_rec;dst:ptypspr;xn,yn:integer);  
var i:integer;
begin    
 no_reset:=true; //Prevents gold hike in direct landing (si_nothing)
 dbg_btn.vis:=s.the_game.info.rules.debug;
 for i:=0 to length(s.clinfo.sopt.frame_btn)-1 do if btn_ut[i]<>nil then begin
  btn_ut[i].set_stat:=s.clinfo.sopt.frame_btn[i]<>0;
  btn_ut[i].no_snd:=true;
 end;
 case s.cur_menu_page of
  0:wrbgtxtcnt8(s.cg,dst,xn+160,yn+10,po('Menu'),3);
  1:wrbgtxtcnt8(s.cg,dst,xn+160,yn+10,po('UT'),3);
  2:wrbgtxtcnt8(s.cg,dst,xn+160,yn+10,po('Confirm end of turn'),3);
  3:wrbgtxtcnt8(s.cg,dst,xn+160,yn+10,po('Confirm landing'),3);
 end;
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;
 
 mn:=MG_FNC;

 pg:=0;
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,'++++',on_btn,703); 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*1,btn_width,btn_height,19,20,'----',on_btn,704); 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('File')  ,on_btn,700);  
 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*4,btn_width,btn_height,19,20,po('End turn')  ,on_btn,900); 
 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,po('Reports'),on_btn,701); 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*1,btn_width,btn_height,19,20,po('Allies'),on_btn,602); 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Colors'),on_btn,601);
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Comments'),on_btn,603);
 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,po('UT'),on_btn,800); 
 dbg_btn:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*1,btn_width,btn_height,19,20,po('Debug'),on_btn,705);
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Resync'),on_btn,706);

 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*4,btn_width,btn_height,19,20,po('Close'),on_ok_btn,0);

 pg:=1;
 btn_ut[ 0]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,po('Survey'),on_btn,801); 
 btn_ut[ 1]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,po('Grid'),on_btn,802); 
 btn_ut[ 2]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,po('Moves'),on_btn,803); 
 
 btn_ut[ 3]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*1,btn_width,btn_height,19,20,po('Scan'),on_btn,804); 
 btn_ut[ 4]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*1,btn_width,btn_height,19,20,po('Range'),on_btn,805); 
 btn_ut[ 5]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*1,btn_width,btn_height,19,20,po('Colors'),on_btn,806); 
 
 btn_ut[ 6]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Hits'),on_btn,807); 
 btn_ut[ 7]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Status'),on_btn,808); 
 btn_ut[ 8]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Ammo'),on_btn,809); 
 
 btn_ut[ 9]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Gas'),on_btn,810); 
 btn_ut[10]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Names'),on_btn,811); 
 btn_ut[11]:=add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Builds'),on_btn,812);  
 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*4,btn_width,btn_height,19,20,po('Close'),on_ok_btn,0);  

 pg:=2;
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('End turn'),on_btn,702);
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Close'),on_ok_btn,0);

 pg:=3;
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('End turn'),on_btn,702);
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Close'),on_ok_btn,0);
 
end;
//############################################################################//
begin
 add_menu('FNC menu',MG_FNC,160,155,BCK_SHADE,init,nil,draw,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//   
