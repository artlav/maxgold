//############################################################################//
//Lab upgrades menu
unit si_lab;
interface
uses asys,strval,grph,graph8,sdigrtools,mgrecs,mgl_common,mgl_actions,sdirecs,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation   
//############################################################################// 
const
res_icos:array[0..RS_COUNT-1]of integer=(20,10,24,16,00,06,18,14); 
//############################################################################//
var 
lab_scr:array[0..7]of pscrollbox_type;  
lab:array[0..7]of integer;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin 
 case par of  
  300..307:begin
   act_change_research(s.the_game,true,par-300,(px-1)*2-1);
   calcmnuinfo(s,MG_UPGRLAB);
  end;
 end;
end;
//############################################################################//
procedure draw_research_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i:integer;
p:pplrtyp;
begin
 p:=get_cur_plr(s.the_game);
 for i:=0 to 8-1 do begin
  putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[res_icos[i]],xn+160,yn+70+28*i); 
  wrtxtrmg8(s.cg,dst,xn+58,yn+74+28*i,stri(p.rsrch_labs[i]),4); 
  wrtxtrmg8(s.cg,dst,xn+275,yn+74+28*i,'+'+stri(p.rsrch_level[i]*10)+'%',4);
  if p.rsrch_labs[i]<>0 then wrtxtrmg8(s.cg,dst,xn+330,yn+74+28*i,stri(p.rsrch_left[i]),4);
  //'attack','shots','range','armor','hits','speed','scan','cost'
 end;
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;
 calcmnuinfo(s,MG_UPGRLAB);
end;   
//############################################################################//
function calc(s:psdi_rec;par:integer):boolean;    
var i:integer;
cp:pplrtyp;
begin   
 result:=true;
 act_change_research(s.the_game,false,0,0);
 cp:=get_cur_plr(s.the_game);
 for i:=0 to RS_COUNT-1 do begin
  lab_scr[i].bottom:=lab[i];
  lab_scr[i].top:=lab[i];
  if cp.rsrch_labs[i]>0 then lab_scr[i].top:=lab[i]-1;
  if cp.labs_free>0 then lab_scr[i].bottom:=lab[i]+1;
 end;
end;
//############################################################################//
function init(s:psdi_rec):boolean;  
var mn,pg,i:integer;
begin
 result:=true;  
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_UPGRLAB;  
 pg:=0;
 
 add_label    (mn,pg,176,022,1,3,po('Research'));
 add_button   (mn,pg,200,297,76,22,7,5,po('Done'),on_ok_btn,0);
 add_button   (mn,pg,090,297,76,22,7,5,po('Cancel'),on_cancel_btn,0);

 add_label    (mn,pg,080,048,3,7,po('Labs'));
 add_label    (mn,pg,215,048,3,7,po('Topics'));
 add_label    (mn,pg,310,048,3,7,po('Turns'));

 add_label    (mn,pg,180,074+28*0,0,7,po('Attack'));
 add_label    (mn,pg,180,074+28*1,0,7,po('Shots'));
 add_label    (mn,pg,180,074+28*2,0,7,po('Range'));
 add_label    (mn,pg,180,074+28*3,0,7,po('Armor'));
 add_label    (mn,pg,180,074+28*4,0,7,po('Hits'));
 add_label    (mn,pg,180,074+28*5,0,7,po('Speed'));
 add_label    (mn,pg,180,074+28*6,0,7,po('Scan'));
 add_label    (mn,pg,180,074+28*7,0,7,po('Cost'));

 for i:=0 to 7 do begin
  lab[i]:=0;
  lab_scr[i]:=add_scrollbox(mn,pg,SCB_HORIZONTAL,73,70+28*i,142,70+28*i,18,17,1,0,100,false,@lab[i],on_btn,300+i);
 end;
end;                                         
//############################################################################//
function deinit(s:psdi_rec):boolean;    
var i:integer;
begin   
 result:=true; 
 for i:=0 to 7 do begin  
  lab[i]:=0;
  lab_scr[i]:=nil; 
 end;
end;   
//############################################################################//
begin      
 add_menu('Lab upgrades menu',MG_UPGRLAB,180,165,GRP_RSRCHPIC,init,deinit,draw_research_menu,nil,nil,enter,nil,calc,nil,nil,nil,nil,nil);
end.
//############################################################################//
