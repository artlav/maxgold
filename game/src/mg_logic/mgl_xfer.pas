//############################################################################//
unit mgl_xfer;
interface  
uses maths,mgrecs,mgl_common,mgl_res;    
//############################################################################//    
//xfer menu info
type
xfer_menu_rec=record
 cnt,min,max:array[0..3]of integer;
 o:array[0..3]of double;
 era,mra,erb,mrb:array[0..2]of integer;
 ua,ub:ptypunits;
 naf:array[0..3]of boolean;
end;
pxfer_menu_rec=^xfer_menu_rec;
//############################################################################// 
procedure init_xfer_menu(g:pgametyp;xfer:pxfer_menu_rec);  
procedure recalc_xfer_menu(g:pgametyp;xfer:pxfer_menu_rec);
//############################################################################// 
//FIXME if possible
var xfer_menu:xfer_menu_rec;   
//############################################################################// 
implementation     
//############################################################################//
//Calc transfer menu
//Logic: Source is a complex, destination is a unit.
procedure init_xfer_menu(g:pgametyp;xfer:pxfer_menu_rec);
var ri,i:integer;
begin            
 if not unav(xfer.ua) then exit;
 if not unav(xfer.ub) then exit;
 
 for i:=0 to 3 do xfer.cnt[i]:=0;
 for ri:=RES_MINING_MIN to RES_MINING_MAX do begin
  i:=ri-1;                             
  xfer.era[i]:=get_rescount(g,xfer.ua,ri,GROP_NOW);
  xfer.mra[i]:=get_rescount(g,xfer.ua,ri,GROP_MAX);
  //This way it's a problem if you want to transfer into a full part of an empty complex
  //xfer.erb[i]:=xfer.ub.prod.now[ri];
  //xfer.mrb[i]:=xfer.ub.prod.num[ri];
  //This way it's a problem that xfer does not fill the meanu
  xfer.erb[i]:=get_rescount(g,xfer.ub,ri,GROP_NOW);
  xfer.mrb[i]:=get_rescount(g,xfer.ub,ri,GROP_MAX);

  //This menu needs a rewrite...
   
  xfer.naf[i]:=(xfer.mra[ri-1]=0)or(xfer.mrb[ri-1]=0);
 end;
 xfer.naf[3]:=(xfer.ua.bas.fuel=0)or(xfer.ub.bas.fuel=0);

 for i:=0 to 3 do xfer.cnt[i]:=1111111;
end;     
//############################################################################//
//Calc transfer menu
//Logic: Source is a complex, destination is a unit.
procedure recalc_xfer_menu(g:pgametyp;xfer:pxfer_menu_rec);
var i:integer;
rul:prulestyp;
begin           
 if not unav(xfer.ua) then exit;
 if not unav(xfer.ub) then exit;
 
 rul:=get_rules(g);          

 for i:=0 to 3 do xfer.o[i]:=0;
 for i:=0 to 2 do begin
  if xfer.era[i]-xfer.cnt[i]<0 then xfer.cnt[i]:=xfer.era[i];
  if xfer.era[i]-xfer.cnt[i]>xfer.mra[i] then xfer.cnt[i]:=xfer.era[i]-xfer.mra[i];
  if xfer.erb[i]+xfer.cnt[i]>xfer.mrb[i] then xfer.cnt[i]:=xfer.mrb[i]-xfer.erb[i];
  if xfer.erb[i]+xfer.cnt[i]<0 then xfer.cnt[i]:=-xfer.erb[i];
  xfer.min[i]:=max2i(xfer.era[i]-xfer.mra[i],-xfer.erb[i]);
  xfer.max[i]:=xfer.mrb[i]-xfer.erb[i];
  if abs(xfer.max[i]-xfer.min[i])<>0 then xfer.o[i]:=(xfer.cnt[i]-xfer.min[i])/abs(xfer.max[i]-xfer.min[i]);
 end;
 if rul.fuelxfer and rul.fueluse then begin
  if xfer.ua.cur.fuel-xfer.cnt[3]<0 then xfer.cnt[3]:=xfer.ua.cur.fuel;
  if xfer.ua.cur.fuel-xfer.cnt[3]>xfer.ua.bas.fuel*10 then xfer.cnt[3]:=xfer.ua.cur.fuel   -xfer.ua.bas.fuel*10;
  if xfer.ub.cur.fuel+xfer.cnt[3]>xfer.ub.bas.fuel*10 then xfer.cnt[3]:=xfer.ub.bas.fuel*10-xfer.ub.cur.fuel;
  if xfer.ub.cur.fuel+xfer.cnt[3]<0 then xfer.cnt[3]:=-xfer.ub.cur.fuel;
  xfer.min[3]:=(xfer.ua.cur.fuel   -xfer.ua.bas.fuel*10);
  xfer.max[3]:=(xfer.ub.bas.fuel*10-xfer.ub.cur.fuel);
  if abs(xfer.max[3]-xfer.min[3])<>0 then xfer.o[3]:=(1/abs(xfer.max[3]-xfer.min[3]))*(xfer.cnt[3]-xfer.min[3]);
 end;
end;        
//############################################################################//
begin
end.
//############################################################################//