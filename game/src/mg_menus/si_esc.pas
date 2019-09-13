//############################################################################//
//ESC menu
unit si_esc;
interface
uses asys,strval,sdigrtools,mgrecs,mgl_common,sdirecs,sdiauxi,sdicalcs,sdiinit,sdimenu,sdigui,sds_rec,graph8,md5,grph,si_nothing;
//############################################################################//
implementation         
//############################################################################//
const
btn_width=153;
btn_height=50;
btn_gap=5;
btn_top_gap=35;
//############################################################################//
var g8passwd:string;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
var cp:pplrtyp;
begin 
 case par of 
  13:begin haltprog;exit;end;
  14:begin clear_menu(s);haltgame(s);end; 
   
  29:begin
   cp:=get_cur_plr(s.the_game);
   cp.info.passhash:=str_md5_hash(md5_str(g8passwd));
  end;
  
  940:case s.surrender_count of
   0:begin s.surrender_count:=s.surrender_count+1;mbox(s,po('Press 2 more times to confirm'),po('Surrender'));end;
   1:begin s.surrender_count:=s.surrender_count+1;mbox(s,po('Press 1 more times to confirm'),po('Surrender'));end;
   2:begin 
    add_step(@s.steps,sts_surrender);
    mbox(s,po('You have surrendered'),po('Surrender'));
   end;
  end;
 end;
end;      
//############################################################################//
procedure draw(s:psdi_rec;dst:ptypspr;xn,yn:integer);  
var xp,yp,xs,ys:integer;
cp:pplrtyp;  
begin
 no_reset:=true; //Prevents gold hike in direct landing (si_nothing)

 wrbgtxtcnt8(s.cg,dst,xn+240,yn+10,po('File'),3);
 wrbgtxt8(s.cg,dst,xn+15,yn+130,po('Change password'),3);  
                
 cp:=get_cur_plr(s.the_game);
 
 xp:=xn+5;
 yp:=yn+20;
 xs:=200;
 ys:=100;
 
 tran_rect8(s.cg,dst,xp,yp,xs,ys,0);
 
 wrtxtcnt8(s.cg,dst,xp+xs div 2,yp+5,'<M.A.X.G> '+sdi_progver,0);
 wrtxt8(s.cg,dst,xp+5,yp+5+15*1,po('Game')+': '+s.the_game.info.game_name,0);
 wrtxt8(s.cg,dst,xp+5,yp+5+15*2,po('Turn')+': '+stri(s.the_game.state.turn),0);
 if cp<>nil then begin 
  drfrectx8(dst,xp+5,yp+5+15*3-4,12,12,cp.info.color8);
  drrectx8(dst,xp+5,yp+5+15*3-4,12,12,0);
  wrtxt8(s.cg,dst,xp+5+10+5,yp+5+15*3,po('Player')+': '+cp.info.name,0);
 end;
end;                            
//############################################################################//
function init(s:psdi_rec):boolean;      
var mn,pg:integer;
begin         
 result:=true;
 g8passwd:='';
 
 mn:=MG_ESCSAVE;  
 pg:=0;
                                     
 add_inputbox(mn,pg,015,155,170,0,@g8passwd,nil,0,'');
      
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*0,btn_width,btn_height,19,20,po('Surrender'),on_btn,940); 
 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*2,btn_width,btn_height,19,20,po('Set'),on_btn,29);   
 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*0,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Exit game'),on_btn,13);
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*1,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Back to menu') ,on_btn,14); 
 add_button(mn,pg,btn_gap+(btn_width+btn_gap)*2,btn_top_gap+(btn_height+btn_gap)*3,btn_width,btn_height,19,20,po('Close')    ,on_ok_btn,0);   
end;     
//############################################################################//
begin      
 add_menu('ESC menu',MG_ESCSAVE,240,130,BCK_SHADE,init,nil,draw,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//   
