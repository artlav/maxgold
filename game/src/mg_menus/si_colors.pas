//############################################################################//
//Custom colors menu
unit si_colors;
interface
uses asys,maths,grph,graph8,sdigrtools,mgrecs,mgl_common,sdirecs,sdiauxi,sdimenu,sdicalcs,sdigui,sds_rec;
//############################################################################//
implementation          
//############################################################################//
//Custom Colors
var gm_custom_clrs_selected:integer;
//############################################################################//
procedure draw_customclrs_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,k,y:integer;
p:pplrtyp;
begin
 wrtxtcnt8(s.cg,dst,xn+200,yn+18,po('Change color settings'),3);
 if gm_custom_clrs_selected>get_plr_count(s.the_game)-1+1 then gm_custom_clrs_selected:=get_plr_count(s.the_game)-1+1;
 for i:=0 to get_plr_count(s.the_game)-1+1 do begin
  y:=i*20+40;
  if i=gm_custom_clrs_selected then drrect8(dst,xn+14,yn+y-6,xn+14+200,yn+y+11,255);
  if i<1 then begin
   //Grid Color
   drfrect8(dst,xn+15,yn+y-5,xn+35,yn+10+y,get_grid_color8(s));
   wrtxt8(s.cg,dst,xn+40,yn+y,po('Map grid color'),5);
  end else begin
   //Player list           
   p:=get_plr(s.the_game,i-1);
   drfrect8(dst,xn+15,yn+y-5,xn+35,yn+10+y,get_player_color8(s,i-1));
   if i=get_next_plr(s.the_game) then drrect8(dst,xn+15,yn+y-5,xn+35,yn+10+y,255);
   wrtxt8(s.cg,dst,xn+40,yn+y,p.info.name,5);
  end;
 end;
 //custom colors
 k:=0;
 for i:=0 to 255 do if((i>=0)and(i<=6))or((i>=32)and(i<64))or(i>=160)then begin
  drfrect8(dst,xn+250+(k mod 8)*15,yn+40+(k div 8)*10,xn+250+(k mod 8)*15+15,yn+40+(k div 8)*10+10,i);
  k:=k+1;
 end;
end;  
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean; 
var i,k:integer;
begin
 result:=true;
 
 //Select player or Grid
 for i:=0 to get_plr_count(s.the_game)-1+1 do begin
  k:=i*20+40;
  if inrect(x,y,xn+14,yn+k-6,xn+14+200,yn+k+11) then gm_custom_clrs_selected:=i;
 end;
 //Select Color
 k:=0;
 for i:=0 to 255 do if((i>=0)and(i<=6))or((i>=32)and(i<64))or(i>=160)then begin
  if inrect(x,y,xn+250+(k mod 8)*15,yn+40+(k div 8)*10,xn+250+(k mod 8)*15+15,yn+40+(k div 8)*10+10) then begin
   s.clinfo.custom_color8[gm_custom_clrs_selected]:=i;
   s.clinfo.custom_color[gm_custom_clrs_selected]:=thepal[i];  
   add_step(@s.steps,sts_set_cdata);    

   event_map_reposition(s);
   event_units(s);
   event_frame(s);
   
   break;
  end;
  k:=k+1;
 end;
end;                                        
//############################################################################//
function init(s:psdi_rec):boolean;      
var mn,pg:integer;
begin         
 result:=true;    
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_CUSTOM_CLRS;  
 pg:=0;
 
 add_button(mn,pg,165,320,100,70,19,20,'OK',on_ok_btn,0);                  
end;   
//############################################################################//
begin      
 add_menu('Custom colors menu',MG_CUSTOM_CLRS,200,211,BCK_SHADE,init,nil,draw_customclrs_menu,nil,nil,nil,nil,nil,nil,mousedown,nil,nil,nil);
end.
//############################################################################//     
