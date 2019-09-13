//############################################################################//
//Mining menu
unit si_mine;
interface
uses asys,maths,strval,grph,graph8,sdigrtools
,mgrecs,mgl_common,mgl_res
,sdirecs,sdimenu,sdicalcs,sdigui;
//############################################################################//
implementation  
//############################################################################// 
type
gm_mine_rec=record
 use,pro,now,max,mine:array[0..2]of integer;
end;     
pgm_mine_rec=^gm_mine_rec;   
//############################################################################//
var mine_menu:gm_mine_rec;
//############################################################################//
//evt_init_mine_menu  
procedure init_mine_menu(s:psdi_rec;u:ptypunits;gm_mine:pgm_mine_rec);
var i:integer;
begin
 for i:=RES_MINING_MIN to RES_MINING_MAX do begin
  gm_mine.mine[i-1]:=get_rescount(s.the_game,u,i,GROP_MINING);
  gm_mine.use [i-1]:=get_rescount(s.the_game,u,i,GROP_DBT);
  gm_mine.pro [i-1]:=get_rescount(s.the_game,u,i,GROP_PRO);
  gm_mine.now [i-1]:=get_rescount(s.the_game,u,i,GROP_NOW);
  gm_mine.max [i-1]:=get_rescount(s.the_game,u,i,GROP_MAX);
 end;
end;
//############################################################################//
procedure draw_mine_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var st:string;
n,xh,i,clr:integer;
begin
 for i:=0 to 2 do begin
  n:=mine_menu.pro[i]-mine_menu.use[i];
  st:=stri(mine_menu.use[i])+' (';
  if n>=0 then st:=st+'+';
  st:=st+stri(n)+' / '+po('Turn')+')';
  if n>0 then n:=mine_menu.pro[i]
         else n:=mine_menu.use[i];
  if n>0 then begin
   xh:=round(s.cg.grapu[GRU_BAR].sprc[i].xs*((n-mine_menu.use[i])/n));
   putsprtcut8(dst,@s.cg.grapu[GRU_BAR].sprc[i],xn+174,yn+107+i*120,xh+29*ord(i=1),0,1000,30,0);
  end;
  wrbgtxtcnt8(s.cg,dst,xn+295,yn+115+i*120,st,0);

  if mine_menu.max[i]<>0 then begin
   xh:=round(s.cg.grapu[GRU_BAR].sprc[i].xs*((mine_menu.max[i]-mine_menu.now[i])/mine_menu.max[i]));
   putsprtcut8(dst,@s.cg.grapu[GRU_BAR].sprc[i],xn+174,yn+107+38+i*120,xh+29*ord(i=1),0,1000,30,0);
   n:=mine_menu.now[i];
  end else n:=0;
  st:=stri(n);
  clr:=0;
  if(mine_menu.pro[i]<>0)or(mine_menu.use[i]<>0)then st:=st+' ('+stri(min2i(n+mine_menu.pro[i]-mine_menu.use[i],mine_menu.max[i]))+')';
  if n+mine_menu.pro[i]-mine_menu.use[i]>mine_menu.max[i] then clr:=2;
  st:=st+' / '+stri(mine_menu.max[i]);
  wrbgtxtcnt8(s.cg,dst,xn+295,yn+115+38+i*120,st,clr);

  n:=mine_menu.mine[i];
  st:=stri(mine_menu.pro[i])+' / '+stri(n);
  if mine_menu.mine[i]<>0 then begin
   xh:=round(s.cg.grapu[GRU_BAR].sprc[i].xs*((mine_menu.mine[i]-mine_menu.pro[i])/mine_menu.mine[i]));
   putsprtcut8(dst,@s.cg.grapu[GRU_BAR].sprc[i],xn+174,yn+107-38+i*120,xh+29*ord(i=1),0,1000,30,0);
  end;
  wrbgtxtcnt8(s.cg,dst,xn+295,yn+115-38+i*120,st,0);
 end;
end;     
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;         
 init_mine_menu(s,get_sel_unit(s.the_game),@mine_menu);
end;               
//############################################################################//
function init(s:psdi_rec):boolean;      
var mn,pg:integer;
begin         
 result:=true;   
 if s.state<>CST_THEGAME then exit;

 mn:=MG_MINE;  
 pg:=0;
 
 add_label (mn,pg,320,013,1,3,po('Resource balance'));
 add_button(mn,pg,496,428,109,40,7,5,po('Done'),on_ok_btn,0);

 add_label (mn,pg,081,081,1,3,po('Raw'));
 add_label (mn,pg,081,119,1,3,po('Usage'));
 add_label (mn,pg,081,155,1,3,po('Reserve'));

 add_label (mn,pg,081,202,1,3,po('Fuel'));
 add_label (mn,pg,081,239,1,3,po('Usage'));
 add_label (mn,pg,081,275,1,3,po('Reserve'));

 add_label (mn,pg,081,322,1,3,po('Gold'));
 add_label (mn,pg,081,359,1,3,po('Usage'));
 add_label (mn,pg,081,397,1,3,po('Reserve'));
end;
//############################################################################//
begin      
 add_menu('Mining menu',MG_MINE,320,240,GRP_ALLOCFRM,init,nil,draw_mine_menu,nil,nil,enter,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//
