//############################################################################//
//End turn menu
unit si_interturn;
interface
uses asys,strval,grph,graph8,sdigrtools,sdiinit,mgrecs,mgl_common,mgl_attr,sdirecs,sdiauxi,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation     
//############################################################################//
var end_turn_passwd_ib:pinputbox_type;
eg_btn:pbutton_type;
//############################################################################//
procedure get_list_cas(s:psdi_rec;pn:integer;out scnt,scost:integer);
var i:integer;
ud:ptypunitsdb;  
p:pplrtyp;
begin try
 scnt:=0;scost:=0;
 for i:=0 to get_unitsdb_count(s.the_game)-1 do begin
  ud:=get_unitsdb(s.the_game,i);  
  p:=get_plr(s.the_game,pn);
  if not isadb(s.the_game,ud,a_minor) then if p.u_cas[i]<>0 then begin
   scost:=scost+p.u_cas[i]*ud.bas.cost;
   scnt:=scnt+p.u_cas[i];
  end;
 end;
 except end;      ///WTF?
end;    
//############################################################################//
//Draws end turn menu
procedure draw_plr_list(s:psdi_rec;dst:ptypspr;x,y,xs,ys:integer);
const sx:array[0..4]of integer=(0,100,200,280,380);
var i,j,yo,scnt,scost:integer;
f:byte;
st:string;
landing:boolean;
p,cp:pplrtyp;
begin try
 f:=0;

 drfrectx8(dst,x,y,xs,ys,0);
 drrect8(dst,x,y,x+xs,y+ys,line_color);

 wrtxt8(s.cg,dst,x+sx[0]+10,y+5,po('Player'),0);
 wrtxt8(s.cg,dst,x+sx[1]+10,y+5,'N/A',0);
 wrtxt8(s.cg,dst,x+sx[2]+10,y+5,po('Casualties'),0);
 wrtxt8(s.cg,dst,x+sx[3]+10,y+5,po('Landed'),0);
 wrtxt8(s.cg,dst,x+sx[4]+10,y+5,po('Status'),0);

 drline8(dst,x,y+15,x+xs,y+15,line_color);

 cp:=get_cur_plr(s.the_game);
 landing:=false;
 for i:=0 to get_plr_count(s.the_game)-1 do begin    
  p:=get_plr(s.the_game,i);
  landing:=landing or not is_landed(s.the_game,p);
 end;
 
 j:=cp.num;
 for i:=0 to get_plr_count(s.the_game)-1 do begin
  yo:=y+20+i*20;             
  p:=get_plr(s.the_game,j);

  drfrectx8(dst,x+1,yo-5,xs-1,20,190+i);
  drfrectx8(dst,x+sx[0]+10,yo,10,10,p.info.color8);
  wrtxt8(s.cg,dst,x+sx[0]+25,yo+2,p.info.name,f);
  get_list_cas(s,j,scnt,scost);
  
  wrtxt8(s.cg,dst,x+sx[1]+10,yo+2,'N/A',f);
  wrtxt8(s.cg,dst,x+sx[2]+10,yo+2,stri(scnt)+' ('+stri(scost)+')',f);
  if is_landed(s.the_game,p) then st:=po('Landed')
                             else st:=po('In Orbit');
  wrtxt8(s.cg,dst,x+sx[3]+10,yo+2,st,f); 

  
  if cp.num>j then begin
   if landing then st:=po('Landed')
              else st:=po('Complete');  
  end;
  if cp.num<j then begin
   if landing then st:=po('Waiting for landing')
              else st:=po('Waiting'); 
  end;
  if cp.num=j then begin
   if landing then st:=po('Ready for landing')
              else st:=po('Next Player');
  end;   
   
  if is_lost(s.the_game,p) then begin
   st:=po('Lost');
  end else begin
   if s.the_game.state.status=GST_ENDGAME then st:=po('Won');
  end;
  
  wrtxt8(s.cg,dst,x+sx[4]+10,yo+2,st,f);
  j:=j+1;
  if j>=get_plr_count(s.the_game) then j:=0;
 end;
 for i:=get_plr_count(s.the_game) to 12 do drfrectx8(dst,x+1,y+20+i*20-5,xs-1,20,190+i);

 for i:=0 to length(sx)-1 do drline8(dst,x+sx[i],y,x+sx[i],y+ys,line_color);

 except stderr(s,'SDIDraws','draw_plr_list');end;
end;
//############################################################################//
//Draws end turn menu
procedure draw_intergame_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var p:pplrtyp;
begin 
 if s.the_game=nil then exit;
 if eg_btn<>nil then eg_btn.vis:=s.the_game.state.status<>GST_ENDGAME;
 p:=get_cur_plr(s.the_game);
 if end_turn_passwd_ib<>nil then begin
  if is_landed(s.the_game,p) and (s.the_game.state.status<>GST_ENDGAME) then begin
   end_turn_passwd_ib.vis:=not s.the_game.info.rules.nopaswds;
   wrtxt8(s.cg,dst,xn+214,yn+035,po('Enter password')+' ('+p.info.name+')',0);
  end else end_turn_passwd_ib.vis:=false;
 end;
 draw_plr_list(s,dst,xn+10,yn+105,600-20,295-20);
end;   
//############################################################################//
function init(s:psdi_rec):boolean;  
var mn,pg:integer;
begin
 result:=true;
 
 mn:=MS_INTERTURN;   
 pg:=0;
 
 add_label    (mn,pg,300,008,1,3,po('Game entry'));

 end_turn_passwd_ib:=
 add_inputbox (mn,pg,214,047,170,0,@s.entered_password,nil,0,'');   

 eg_btn:=add_button(mn,pg,600-180-5,5,180,95,19,20,po('Enter game'),on_ok_btn,0); 
         add_button(mn,pg,5,5,180,95,19,20,po('Exit'),on_cancel_btn,0);
end;   
//############################################################################//
function deinit(s:psdi_rec):boolean;  
begin
 result:=true;
 end_turn_passwd_ib:=nil;
end;     
//############################################################################//
function ok(s:psdi_rec):boolean;
begin 
 result:=true;   
 if s.the_game=nil then exit;
 if s.the_game.state.status<>GST_ENDGAME then nextturn(s);
end;           
//############################################################################//
function cancel(s:psdi_rec):boolean;  
begin 
 result:=true;
 clear_menu(s);
 haltgame(s);
end;
//############################################################################//
begin      
 add_menu('End turn menu',MS_INTERTURN,300,200,BCK_SHADE,init,deinit,draw_intergame_menu,ok,cancel,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################// 
