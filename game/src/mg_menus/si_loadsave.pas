//############################################################################//
//Network game menu
unit si_loadsave;
interface
uses asys,maths,strval,grph,graph8,sdigrtools
,sds_net,sds_util,sds_rec
,mgrecs,mgl_common
,sdirecs,sdiauxi,sdicalcs,sdisound,sdimenu,sdigui,sdiinit;
//############################################################################//  
var games:array of game_db_rec=nil;          
//############################################################################//  
implementation
//############################################################################//
const
btn_off=100;
btn_height=70;
btn_wid=130;

list_top=25;  
list_top_txt_off=list_top div 2-8;

list_step=40;
list_txt_off=list_step div 2-10;  
list_left_txt_off=10;

list_xo=0;
list_yo=25; 
 
blocks_ys=80;
scroll_xs=40;   
//############################################################################// 
rule_name:array[0..15]of string=
(
 'Отладка',
 'Топливо',
 'Пер. топлива', 
 'Выг. выстрелы',
 'Выг. скорость',
 'Выг. -1 скор.', 
 'Загр. -1 скор.',
 'Загр. на площ.',   
 'Нач. радар',   
 'Без геолога',
 'Без базы',   
 'Без паролей',
 'Выст. топливо',
 'Не зак. боевых',
 'Дор. топливо',
 'Центр 4х'
);
//############################################################################//
var
gn_size:integer=6;
gn_cur_sel:integer=0;
gn_off:integer=0;
finisheds:boolean=false;
cont_btn:pbutton_type;
menu:integer;
//############################################################################//
procedure fetch(s:psdi_rec);
begin              
 setlength(games,0);
 if finisheds then add_step(@s.steps,sts_fetch_finishes) else add_step(@s.steps,sts_fetch_games);
end;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin 
 case par of  
  459:fetch(s);
  9:event_frame(s);
 end;
end;     
//############################################################################//
procedure on_cbx(s:psdi_rec;par,px:dword);
begin 
 case par of
  0:begin
   gn_off:=0;       
   gn_cur_sel:=0;
   if finisheds then cont_btn.txt:=po('Playback') else cont_btn.txt:=po('Continue');
   fetch(s);
  end;
 end;
end;
//############################################################################//
//Draws end turn menu
procedure draw_net_list(s:psdi_rec;dst:ptypspr;x,y,xs,ys:integer);
var sx:array[0..5]of integer;
i,yo:integer;
c,f:byte;
st:string;
g:pgame_db_rec;
begin try
 c:=4;
 f:=0;    

 sx[0]:=0;
 sx[1]:=xs div 4;
 sx[2]:=sx[1]+60;
 sx[3]:=2*xs div 4;
 sx[4]:=3*xs div 4;
 sx[5]:=sx[4]+xs div 8;
     
 drfrectx8(dst,x,y,xs,ys,0);
 drrect8(dst,x,y,x+xs,y+ys,c);

 wrbgtxt8(s.cg,dst,x+sx[0]+10,y+list_top_txt_off,po('Game name'),0);
 wrbgtxt8(s.cg,dst,x+sx[1]+10,y+list_top_txt_off,po('Turn'),0);
 wrbgtxt8(s.cg,dst,x+sx[2]+10,y+list_top_txt_off,po('State'),0);
 wrbgtxt8(s.cg,dst,x+sx[3]+10,y+list_top_txt_off,po('Players'),0);
 wrbgtxt8(s.cg,dst,x+sx[4]+10,y+list_top_txt_off,po('Now'),0);
 wrbgtxt8(s.cg,dst,x+sx[5]+10,y+list_top_txt_off,po('Uniset'),0);

 drline8(dst,x,y+list_top-1,x+xs,y+list_top-1,c);
   
 for i:=0 to min2i(gn_size,length(games)-gn_off-1) do begin
  yo:=y+list_top+i*list_step;
  g:=@games[i+gn_off];

  if (i+gn_off)=gn_cur_sel then drfrectx8(dst,x+1,yo,xs-1,list_step,1) else drfrectx8(dst,x+1,yo,xs-1,list_step,190+i);
  
  wrbgtxt8(s.cg,dst,x+sx[0]+list_left_txt_off,yo+list_txt_off,g.info.game_name,f);
  wrbgtxt8(s.cg,dst,x+sx[1]+list_left_txt_off,yo+list_txt_off,stri(g.state.turn),f);
  
  st:='N/A';
  if g.state.status=GST_THEGAME then st:='Active';
  if g.state.status=GST_SETGAME then st:='Landing';
  if g.state.status=GST_ENDGAME then st:='Finished';
  if g.state.status=GST_TAINT then st:='Intersected';
  
  wrbgtxt8(s.cg,dst,x+sx[2]+list_left_txt_off,yo+list_txt_off,po(st),f); 
  
  st:='';
  //for j:=0 to length(g.teams)-1 do st:=st+g.teams[j]+' ';
  wrbgtxt8(s.cg,dst,x+sx[3]+list_left_txt_off,yo+list_txt_off,st,f); 
  
  st:=g.cur_plr;
  wrbgtxt8(s.cg,dst,x+sx[4]+list_left_txt_off,yo+list_txt_off,st,f);   
     
  wrbgtxt8(s.cg,dst,x+sx[5]+list_left_txt_off,yo+list_txt_off,g.info.rules.uniset,f);
 end;

 for i:=max2i(0,min2i(gn_size,length(games)-gn_off)) to gn_size do drfrectx8(dst,x+1,y+list_top+i*list_step-5,xs-1,list_step,190+i);
 for i:=0 to length(sx)-1 do drline8(dst,x+sx[i],y,x+sx[i],y+ys,c);
    
 except stderr(s,'SDIDraws','draw_plr_list');end;
end;
//############################################################################//
procedure draw_net_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var xo,yo,xs,ys,i,mxs,mys:integer;
f:dword;
begin try   
 if menu_list[menu].xn<>(scrx div 2-10) then event_frame(s);
 menu_list[menu].xn:=scrx div 2-10;
 menu_list[menu].yn:=scry div 2-10;
 
 mxs:=scrx-20;
 mys:=scry-20;
 
 xs:=mxs-scroll_xs;
 ys:=mys-list_yo-btn_off-blocks_ys;    
 gn_size:=(ys-list_top) div list_step-1;
 draw_net_list(s,dst,xn+list_xo,yn+list_yo,xs,ys);
 
 wrtxt8(s.cg,dst,xn+10,yn+5,po('Server')+': '+gs_server+':'+stri(gs_port),19);
 
 xo:=xn+list_xo;
 yo:=yn+list_yo+ys+5;

 drfrectx8(dst,xo,yo,mxs div 2-2,blocks_ys,0);
 drrectx8 (dst,xo,yo,mxs div 2-2,blocks_ys,4);
 
 drfrectx8(dst,xo+mxs div 2,yo,mxs div 2-2,blocks_ys,0);
 drrectx8 (dst,xo+mxs div 2,yo,mxs div 2-2,blocks_ys,4);
      
 if gn_cur_sel<length(games) then begin
  f:=rules_to_dword(@games[gn_cur_sel].info.rules);
  wrtxtbox8(s.cg,dst,xo+5,yo+7,xo+mxs div 2-2-6,yo+blocks_ys-14,games[gn_cur_sel].info.descr,0); 
  for i:=0 to 15 do wrtxt8(s.cg,dst,xo+mxs div 2+5+120*(i div 7),yo+7+10*(i mod 7),rule_name[i],4-ord((f and (1 shl i))<>0));
 end;    
 
 except stderr(s,'SDIDraws','draw_etmnu');end;
end;   
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i,yo,xo,mxs:integer;
begin       
 result:=true;  
 mxs:=scrx-20;
 for i:=0 to min2i(gn_size,length(games)-gn_off)-1 do begin
  yo:=yn+list_yo+list_top+i*list_step;
  xo:=xn+list_xo;
  if inrects(x,y,xo+1,yo,mxs-scroll_xs,list_step) then begin
   snd_click(SND_ACCEPT);
   gn_cur_sel:=i+gn_off; 
   break;
  end;
 end;
end;
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;
 case key of
  KEY_TAB:begin
   finisheds:=not finisheds;
   on_cbx(s,0,0);
  end;
 end;
end;
//############################################################################//
function init(s:psdi_rec):boolean;     
var mn,pg:integer;
sb:pscrollbox_type;
by,mxs,mys:integer;
begin         
 result:=true;  

 gn_off:=0;  
 finisheds:=false;
 
 mxs:=scrx-20;
 mys:=scry-20;  
 by:=mys-btn_off+10; 
 
 mn:=MG_LOADSAVE;
 pg:=0;
 
           add_button(mn,pg,0*(btn_wid+5),by,btn_wid,btn_height,19,20,po('Back'),on_cancel_btn,0);
           add_button(mn,pg,1*(btn_wid+5),by,btn_wid,btn_height,19,20,po('Refresh'),on_btn,459);
 cont_btn:=add_button(mn,pg,2*(btn_wid+5),by,btn_wid,btn_height,19,20,po('Continue'),on_ok_btn,0);
                       
 add_checkbox(mn,pg,3*(btn_wid+5),by,110,btn_height,nil,@finisheds,on_cbx,0);
 add_label(mn,pg,3*(btn_wid+5)+55,by+btn_height div 2-5,1,0,po('Finished ones'));
   
 sb:=add_scrollbox(mn,pg,SCB_VERTICAL,mxs-scroll_xs+5,list_yo,mxs-scroll_xs+5,mys-btn_off-blocks_ys-40,24,25,gn_size,0,990,false,@gn_off,on_btn,9);
     add_scrolarea(mn,pg,-1,0,0,mxs,mys,1,list_step,0,990,@gn_off,on_btn,9,sb);

end;
//############################################################################//
function ok(s:psdi_rec):boolean;
var ld:string; 
begin 
 result:=true;
                      
 if gn_cur_sel>=length(games) then begin clear_menu(s);exit;end;
 if finisheds then begin 
  load_id:=games[gn_cur_sel].id;
  add_step(@s.steps,sts_do_replay);
 end else begin
  ld:=games[gn_cur_sel].id;; 
  init_game_load(s,ld);
 end;
end;   
//############################################################################//
function calc(s:psdi_rec;par:integer):boolean;      
begin   
 result:=true;
 
 gn_cur_sel:=0;
 finisheds:=false;     
 fetch(s);
end;    
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;
 calcmnuinfo(s,MG_LOADSAVE);
end;  
//############################################################################//
begin      
 menu:=add_menu('Saveload menu',MG_LOADSAVE,320,240,BCK_NONE,init,nil,draw_net_menu,ok,nil,enter,nil,calc,keydown,mousedown,nil,nil,nil);
end.
//############################################################################//

