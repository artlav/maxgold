//############################################################################//
unit sdicalcs;
interface
uses sysutils,asys,strval,grph,maths,md5,mgl_common,mgl_actions,mgl_land,mgl_attr,mgl_rmnu,mgrecs
,sdirecs,sdiauxi,sdigrtools,sdisound,sdimenu,sds_util,sds_rec;
//############################################################################//
function ingf(s:psdi_rec;u:ptypunits):boolean;  
function ingf_xys(s:psdi_rec;x,y,siz:integer):boolean;

procedure begin_player_landing(s:psdi_rec);

procedure palshiftu(var pal:pallette3;s,e:integer);
procedure palshiftd(var pal:pallette3;s,e:integer);
procedure palblnkd(var pal:pallette3;s:integer;t:double;cs:crgba);
procedure upd_minimap_pal(s:psdi_rec;n:integer);     
procedure clear_minimap_pal(s:psdi_rec);
procedure palanim(s:psdi_rec);
                  
procedure calczoom(s:psdi_rec;map:pmap_window_rec;zoom:double);
procedure calcmbrd(s:psdi_rec;map:pmap_window_rec;zoom:double;var mapox,mapoy:int16);
procedure procresmap(s:psdi_rec;map:pmap_window_rec);
function  max_zoom(s:psdi_rec):double;

function  gcrx(cr:vcomp):integer;             //get x value               \
function  gcry(cr:vcomp):integer;             //get y value                | 
function  gcrxs(cr:vcomp):integer;
function  gcrys(cr:vcomp):integer;

procedure gcrxy(cr:vcomp;out x,y:integer);    //get x and y value           \
function  gcrmx(cr:vcomp):integer;            //medium of vcomp             /  WTF?
function  gcrmy(cr:vcomp):integer;            //medium of vcomp            |
procedure gcrmxy(cr:vcomp;out mx,my:integer); //medium of vcomp           /
function  inrectv(x,y:integer;ob:vcomp):boolean;

procedure sync_units_graphics(s:psdi_rec);
procedure go_end_turn(s:psdi_rec;of_player:boolean);
procedure nextturn(s:psdi_rec);  

procedure enter_menu(s:psdi_rec;mn:dword;sound:integer=-1);
procedure clear_menu(s:psdi_rec);
procedure on_ok_btn    (s:psdi_rec;par,px:dword);
procedure on_cancel_btn(s:psdi_rec;par,px:dword);

procedure menu_ok(s:psdi_rec;sound:integer=-1);
procedure menu_cancel(s:psdi_rec;sound:integer=-1); 
procedure calcmnuinfo(s:psdi_rec;mnu:dword);
procedure sdi_coremenu_callback(s:psdi_rec;n:dword);
  
procedure mk_gamename(s:psdi_rec);   
procedure verify_sopt(s:psdi_rec);
//############################################################################//
implementation    
//############################################################################//
function ingf_xys(s:psdi_rec;x,y,siz:integer):boolean;
begin       
 result:=false;
 if (((x*XCX+siz*XCX+XCX)/s.clinfo.sopt.zoom-s.mainmap.mapl)>0)and
    (((y*XCX+siz*XCX+XCX)/s.clinfo.sopt.zoom-s.mainmap.mapt)>0)and
    (((x*XCX)/s.clinfo.sopt.zoom-s.mainmap.mapl)<scrx)and
    (((y*XCX)/s.clinfo.sopt.zoom-s.mainmap.mapt)<scry)then result:=true;
end;
//############################################################################//
function ingf(s:psdi_rec;u:ptypunits):boolean;
begin       
 result:=false;
 if u=nil then exit;
 result:=ingf_xys(s,u.x,u.y,u.siz);
end;
//############################################################################//
//############################################################################//
procedure palshiftd(var pal:pallette3;s,e:integer);
var cl:crgb;           
i:integer;
begin       
 cl:=pal[s];   
 for i:=s to e-1 do pal[i]:=pal[i+1];    
 pal[e]:=cl; 
end;           
//############################################################################//
procedure palshiftu(var pal:pallette3;s,e:integer);
var cl:crgb;           
i:integer;
begin    
 cl:=pal[e];   
 for i:=e downto s+1 do pal[i]:=pal[i-1];
 pal[s]:=cl;
end;    
//############################################################################//
procedure palblnkd(var pal:pallette3;s:integer;t:double;cs:crgba);
var cl:crgb;  
begin      
 cl:=pal[s]; 
 cl[0]:=round(cs[0]*t);
 cl[1]:=round(cs[1]*t);
 cl[2]:=round(cs[2]*t); 
 pal[s]:=cl;   
end;
//############################################################################//
procedure upd_minimap_pal(s:psdi_rec;n:integer);
var x:integer;
begin
 if n<0 then exit;
 if n>=length(s.map_pal_list)then exit;
 for x:=64 to 159 do begin 
  thepal[x][0]:=s.map_pal_list[n][x][0];
  thepal[x][1]:=s.map_pal_list[n][x][1];
  thepal[x][2]:=s.map_pal_list[n][x][2];
 end;
end;   
//############################################################################//
procedure clear_minimap_pal(s:psdi_rec);
var x:integer;
begin
 for x:=64 to 159 do thepal[x]:=s.cg.base_pal[x];
end;     
//############################################################################//
procedure palanim(s:psdi_rec);
begin
 if s.anim_dt>0.15 then begin
  s.anim_dt:=0;   
  
  palshiftd(thepal,  9, 12);
  palshiftu(thepal, 13, 16);
  palshiftu(thepal, 17, 20);   
  palshiftu(thepal, 21, 24); 

  palshiftu(thepal, 25, 30);  
  palblnkd (thepal, 31, 1-frac(s.gct),gclgreen);
                   
  palshiftu(thepal, 96,102); 
  palshiftu(thepal,103,109);  
  palshiftu(thepal,110,116);  
  palshiftu(thepal,117,122); 
  palshiftu(thepal,123,127);    
 end; 
end;
//############################################################################//
//############################################################################//  
procedure calczoom(s:psdi_rec;map:pmap_window_rec;zoom:double);
var i:integer;
scaled_pixel:double;
pixels,block:integer;
begin
 pixels:=XCX*max2i(s.mapx,s.mapy);
 scaled_pixel:=0;
 block:=0;       
                                  
 setlength(map.block_xlate,pixels+1); 
 setlength(map.offset_xlate_x,pixels+1);
 setlength(map.offset_xlate_y,pixels+1);
 
 //X&Y scalers
 for i:=0 to pixels-1 do begin         
  map.offset_xlate_x[i]:=round(scaled_pixel);
  map.offset_xlate_y[i]:=map.offset_xlate_x[i]*dword(XCX);
  map.block_xlate[i]:=block;  
  scaled_pixel:=scaled_pixel+zoom;
  if round(scaled_pixel)>=XCX then begin
   scaled_pixel:=scaled_pixel-XCX;
   block:=block+1;
  end;
 end;
 
 map.gfcx:=round(scrx/(XCX/zoom));
 map.gfcy:=round(scry/(XCX/zoom));
 event_map_reposition(s);
 sdi_calczoomer(s,zoom);
end;   
//############################################################################//
function max_zoom(s:psdi_rec):double;
begin result:=1; try
 if s.cg.mapedge then result:=max2((s.mapx*XCX)/scrx,(s.mapy*XCX)/scry)
                 else result:=min2((s.mapx*XCX)/scrx,(s.mapy*XCX)/scry);
 except stderr(s,'sdicalc','max_zoom, gfsx='+stri(scrx)+', gfsy='+stri(scry));end;
end;
//############################################################################//
procedure calcmbrd(s:psdi_rec;map:pmap_window_rec;zoom:double;var mapox,mapoy:int16);
begin try
 if mapox<0 then mapox:=-mapox*XCX;
 if mapoy<0 then mapoy:=-mapoy*XCX;
 if mapox/zoom-scrx/2<0 then mapox:=round((scrx/2)*zoom);
 if mapoy/zoom-scry/2<0 then mapoy:=round((scry/2)*zoom);
 if mapox/zoom+scrx/2>s.mapx*XCX/zoom then mapox:=round((s.mapx*XCX/zoom-scrx/2)*zoom);
 if mapoy/zoom+scry/2>s.mapy*XCX/zoom then mapoy:=round((s.mapy*XCX/zoom-scry/2)*zoom);
 map.mapl:=round(mapox/zoom-scrx/2);
 map.mapr:=round(mapox/zoom+scrx/2);
 map.mapt:=round(mapoy/zoom-scry/2);
 map.mapb:=round(mapoy/zoom+scry/2);
 if map.mapl<0 then begin map.mapr:=map.mapr-map.mapl; map.mapl:=0; end;
 if map.mapt<0 then begin map.mapb:=map.mapb-map.mapt; map.mapt:=0; end; 
 if map.mapr>XCX*s.mapx then map.mapr:=XCX*s.mapx-1;
 if map.mapb>XCX*s.mapy then map.mapb:=XCX*s.mapy-1;

 map.ssx:=map.block_xlate[map.mapl];
 map.ssy:=map.block_xlate[map.mapt];
 map.psx:=round((map.ssx+1)*XCX/zoom-map.mapl);
 map.psy:=round((map.ssy+1)*XCX/zoom-map.mapt); 

 event_map_scroll(s);
 except stderr(s,'sdicalc','calcmbrd, zoom='+stre(zoom));end;
end;
//############################################################################//
procedure procresmap(s:psdi_rec;map:pmap_window_rec);
var ot:dword;
i,x,y:integer;
rm:presrec;
rv:boolean;
p,cp:pplrtyp;
scan_only:boolean;
begin
 cp:=get_cur_plr(s.the_game); 
 scan_only:=not is_landed(s.the_game,cp);

 //0.57s x1000
 if length(s.rpmap)<>s.mapx*s.mapy then setlength(s.rpmap,s.mapx*s.mapy);
 for y:=0 to s.mapy-1 do for x:=0 to s.mapx-1 do begin
  rv:=s.resdbg or s.the_game.info.rules.no_survey;
  if not rv then begin
   for i:=0 to get_plr_count(s.the_game)-1 do begin
    p:=get_plr(s.the_game,i);
    if not plr_are_enemies(s.the_game,cp.num,p.num)then rv:=rv or(p.resmp[x+y*s.mapx]>0);
   end;
  end;
  rv:=rv and(get_map_pass(s.the_game,x,y)<>P_OBSTACLE);
  if scan_only then if not fast_can_see(s.the_game,x,y,cp.num) or (plr_begin.lndx=-1) then rv:=false;
  if rv then begin
   rm:=@s.the_game.resmap[x+y*s.mapx];
   if(rm=nil)or(rm.typ=0)or(rm.typ>3)then begin
    s.rpmap[x+y*s.mapx]:=0;
   end else begin
    ot:=XCX*XCX*16+(rm.typ-1)*XCX*XCX*16;
    s.rpmap[x+y*s.mapx]:=ot+rm.amt*dword(XCX);
   end;
  end else s.rpmap[x+y*s.mapx]:=XCX;
 end;
end;
//############################################################################//
//############################################################################//
function gcr(cr:vcomp;coord:integer):integer;
begin
 result:=0;
 case coord of
  0:result:=cr.x;
  1:result:=cr.y;
 end;
end;
//############################################################################//
function  gcrx(cr:vcomp):integer;begin result:=gcr(cr,0);end;
function  gcry(cr:vcomp):integer;begin result:=gcr(cr,1);end;   
function  gcrxs(cr:vcomp):integer;begin result:=cr.sx;end;
function  gcrys(cr:vcomp):integer;begin result:=cr.sy;end;

procedure gcrxy(cr:vcomp;out x,y:integer);begin x:=gcr(cr,0);y:=gcr(cr,1);end;
function  gcrmx(cr:vcomp):integer;begin result:=gcr(cr,0)+cr.sx div 2;end;
function  gcrmy(cr:vcomp):integer;begin result:=gcr(cr,1)+cr.sy div 2;end;
procedure gcrmxy(cr:vcomp;out mx,my:integer);begin mx:=gcrmx(cr);my:=gcrmy(cr);end;
//############################################################################//
function inrectv(x,y:integer;ob:vcomp):boolean;
begin
 if inrect(x,y,gcrx(ob),gcry(ob),gcrx(ob)+ob.sx,gcry(ob)+ob.sy) then inrectv:=true else inrectv:=false;
end;
//############################################################################//
procedure sync_units_graphics(s:psdi_rec);
var i,j:integer;
c:boolean;
u:ptypunits;
begin 
 if s.state<>CST_THEGAME then exit; 
 for i:=0 to get_units_count(s.the_game)-1 do begin
  u:=get_unit(s.the_game,i);
  if u=nil then continue;
  
  c:=false;
  if u.grp_db=-1 then begin
   c:=true
  end else begin
   if u.grp_db<length(s.eunitsdb) then if s.eunitsdb[u.grp_db]<>nil then if s.eunitsdb[u.grp_db].typ<>u.typ then c:=true;
  end;
  if c then begin       
   u.grp_db:=-1;
   for j:=0 to length(s.eunitsdb)-1 do if s.eunitsdb[j]<>nil then if s.eunitsdb[j].typ=u.typ then begin u.grp_db:=j;break;end;
  end;
 end;
end;
//############################################################################//
procedure go_end_turn(s:psdi_rec;of_player:boolean);
var cp:pplrtyp;
begin       
 cp:=get_cur_plr(s.the_game);

 clear_menu(s);
 if not is_landed(s.the_game,cp) then begin
  if plr_begin.lndx<>-1 then act_land_player(s.the_game,@plr_begin);
 end else begin
  add_step(@s.steps,sts_set_cdata);
  add_step(@s.steps,sts_ask_end_turn);
 end;
end;  
//############################################################################//
procedure begin_player_landing(s:psdi_rec);
begin
 clear_menu(s);
 add_step(@s.steps,sts_player_landing);
end;
//############################################################################//
procedure nextturn(s:psdi_rec);
var cp:pplrtyp;
begin        
 passhash:=str_md5_hash(md5_str(s.entered_password));
                
 clear_menu(s);
 stop_running_snd(s);

 cp:=get_cur_plr(s.the_game);
 
 if (s.the_game.state.status=GST_SETGAME)and not is_landed(s.the_game,cp) then begin
  s.state:=CST_THEMENU;
  enter_menu(s,MS_PLAYERSETUP);
  s.clinfo.sopt.sx:=s.mapx*XHCX;
  s.clinfo.sopt.sy:=s.mapy*XHCX;
  s.clinfo.sopt.zoom:=s.mainmap.maxzoom; 
 end else begin    
  clear_menu(s);
  add_step(@s.steps,sts_fetch_resmap);
  add_step(@s.steps,sts_fetch_plrall);
  add_step(@s.steps,sts_fetch_all_units);
  add_step(@s.steps,sts_enter_turn);
 end;
  
 event_frame(s); 
 event_units(s);
 event_map_reposition(s);
end;
//############################################################################//
procedure mk_gamename(s:psdi_rec);
var i:integer;
st:string;
begin
 s.newgame.name:='';
 for i:=0 to s.newgame.plr_cnt-1 do begin
  st:=s.newgame.plr_names[i];
  s.newgame.name:=s.newgame.name+copy(st,1,3);
  if i<>s.newgame.plr_cnt-1 then s.newgame.name:=s.newgame.name+'_';
 end;
 s.newgame.name:=s.newgame.name+'_'+stri(s.runcnt);
end;
//############################################################################//
procedure enter_menu(s:psdi_rec;mn:dword;sound:integer=-1);
begin
 if sound<>-1 then snd_click(sound);
 event_frame(s);
 s.cur_menu:=mn;
 s.cur_menu_page:=0;
 enter_menu_by_id(s,mn);
end;
//############################################################################//
procedure clear_menu(s:psdi_rec);
begin
 if s.state=CST_THEMENU then s.cur_menu:=MS_MAINMENU else s.cur_menu:=MG_NOMENU;   
 if s.state=CST_THEGAME then set_game_menu(s.the_game,MG_NOMENU); 
 
 event_frame(s);
 menu_all_clear(s);   
 s.cur_menu_page:=0;
 s.surrender_count:=0;  
 event_map_reposition(s);
 
 s.debug_placing:=false;  
 s.entered_password:='';
end;            
//############################################################################//
procedure menu_cancel(s:psdi_rec;sound:integer=-1);
begin
 if sound<>-1 then snd_click(sound); 
 if cancel_menu_by_id(s,s.cur_menu) then exit;          
 //Default: close menu
 clear_menu(s);
end;
//############################################################################//
procedure menu_ok(s:psdi_rec;sound:integer=-1);
begin
 if sound<>-1 then snd_click(sound);
 if ok_menu_by_id(s,s.cur_menu) then exit;
 //Default: close menu
 clear_menu(s);
end;    
//############################################################################//
procedure on_ok_btn(s:psdi_rec;par,px:dword);begin menu_ok(s);end;
procedure on_cancel_btn(s:psdi_rec;par,px:dword);begin menu_cancel(s);end;
procedure calcmnuinfo(s:psdi_rec;mnu:dword);begin calc_menu_by_id(s,mnu);end;
procedure sdi_coremenu_callback(s:psdi_rec;n:dword);begin enter_menu(s,n);end;
//############################################################################//
procedure verify_sopt(s:psdi_rec);
begin
 if s.clinfo.sopt.zoom=0 then s.clinfo.sopt.zoom:=s.mainmap.maxzoom;
 if s.clinfo.sopt.zoom>s.mainmap.maxzoom then s.clinfo.sopt.zoom:=s.mainmap.maxzoom;
 calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);
end;           
//############################################################################//
begin
end.
//############################################################################//

