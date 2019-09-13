//############################################################################//
//Unit info menu
unit si_unitinfo;
interface
uses asys,grph,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui,sdi_int_elem;
//############################################################################//
implementation
//############################################################################//
procedure draw_unitinfo_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var u:ptypunits;
begin
 u:=get_sel_unit(s.the_game);
 if not unav(u) then begin clear_menu(s);exit;end;
 
 drut_poster_box    (s,dst,u,xn+10,yn+10,300,240);   
 drut_full_stats_box(s,dst,u,xn+10,yn+10+240+5,300,480-240-10-10-5);  
 drut_descr_box     (s,dst,u,xn+10+300+5,yn+60,640-(10+300+5+10),10+240-60);
end;         
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;

 case key of
  KEY_I:if isf(shift,sh_alt) then clear_menu(s);
 end;
end;                              
//############################################################################//
function init(s:psdi_rec):boolean;      
var mn,pg:integer;
begin         
 result:=true;    
 if s.state<>CST_THEGAME then exit;

 mn:=MG_UNITINFO;  
 pg:=0;
 
 add_label (mn,pg,10+300+20+140,020,1,3,po('Information'));    
 add_button(mn,pg,10+300+20,10+240+20,640-(10+300+20+10),480-240-10-20-10,19,20,'OK',on_ok_btn,0);         
end;   
//############################################################################//
begin      
 add_menu('Unit info menu',MG_UNITINFO,320,240,BCK_SHADE,init,nil,draw_unitinfo_menu,nil,nil,nil,nil,nil,keydown,nil,nil,nil,nil);
end.
//############################################################################// 
