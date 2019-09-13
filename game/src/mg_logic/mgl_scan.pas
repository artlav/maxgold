//############################################################################//
//Made by Artyom Litvinovich in 2003-2013
//MaxGold scan, unu, razv - cell maps
//############################################################################//
unit mgl_scan;
interface
uses mgrecs,mgl_common,mgl_attr,mgl_logs,mgl_unu;
//############################################################################// 
procedure addscan(g:pgametyp;u:ptypunits;ux,uy:integer;add_log:boolean=false);
procedure subscan(g:pgametyp;u:ptypunits;add_log:boolean=false);    
procedure reset_scan(g:pgametyp;pl:pplrtyp;do_razved:boolean);
procedure calc_scan_full(g:pgametyp;pl:pplrtyp;do_razved:boolean);
//############################################################################//
implementation
//############################################################################//
function compute_scan_point(const g:pgametyp;const u:ptypunits;const x,y,ux,uy:integer):boolean;
var xsiz:integer;
begin
 result:=false;
 xsiz:=u.siz+ord(isa(g,u,a_bor));
 if g.info.rules.center_4x_scan then begin
  if xsiz=2 then result:=sqr(x-(ux+0.5))+sqr(y-(uy+0.5))<=sqr(u.bas.scan)
            else result:=sqr(x-ux)+sqr(y-uy)<=sqr(u.bas.scan);
 end else begin
  result:=sqr(x-ux)+sqr(y-uy)<=sqr(u.bas.scan);
  if(not result)and(xsiz=2)then result:=(sqr(x-(ux+1))+sqr(y-(uy+1))<=sqr(u.bas.scan))or
                                        (sqr(x-(ux+1))+sqr(y-(uy  ))<=sqr(u.bas.scan))or
                                        (sqr(x-(ux  ))+sqr(y-(uy+1))<=sqr(u.bas.scan));
 end;
end;
//############################################################################//
procedure change_scan_point(const g:pgametyp;const pl:pplrtyp;const u:ptypunits;const pos,change:integer);
begin
                                   pl.scan_map[SL_NORMAL    ][pos]:=pl.scan_map[SL_NORMAL    ][pos]+change;
 if isa(g,u,a_see_underwater) then pl.scan_map[SL_UNDERWATER][pos]:=pl.scan_map[SL_UNDERWATER][pos]+change;
 if isa(g,u,a_see_stealth)    then pl.scan_map[SL_STEALTH   ][pos]:=pl.scan_map[SL_STEALTH   ][pos]+change;
end;
//############################################################################//
//Add scan
procedure addscan(g:pgametyp;u:ptypunits;ux,uy:integer;add_log:boolean=false);
var x,y,xh,yh,xl,yl,j,pos,rad:integer;
zero,st_zero:boolean;
pl,pl2:pplrtyp;
ut:ptypunits;
begin
 if not unav(u) then exit;
 if u.own=-1 then exit;
 pl:=get_plr(g,u.own);
 if isa(g,u,a_disabled)  then exit;
                                     
 rad:=u.bas.scan+u.bas.speed+1;
 xh:=ux-rad;yh:=uy-rad;xl:=ux+rad;yl:=uy+rad;
 if xh<0 then xh:=0;
 if yh<0 then yh:=0;
 if xl>g.info.mapx-1 then xl:=g.info.mapx-1;
 if yl>g.info.mapy-1 then yl:=g.info.mapy-1;

 for x:=xh to xl do for y:=yh to yl do begin
  if not compute_scan_point(g,u,x,y,ux,uy) then continue;

  pos:=x+y*g.info.mapx;
  zero:=pl.scan_map[SL_NORMAL][pos]=0;  
  change_scan_point(g,pl,u,pos,1);

  razved_on_scan_add(pl,x,y);

  for j:=0 to get_unu_length(g,x,y)-1 do if unav(get_unu(g,x,y,j)) then begin
   ut:=get_unu(g,x,y,j);
   if ut.own=u.own then continue;
   st_zero:=ut.stealth_detected[u.own]=0;
   if isa(g,ut,a_stealth)    and(pl.scan_map[SL_STEALTH   ][pos]>0) then ut.stealth_detected[u.own]:=2;
   if isa(g,ut,a_underwater) and(pl.scan_map[SL_UNDERWATER][pos]>0) then ut.stealth_detected[u.own]:=2;
   if isa(g,ut,a_bomb)       and isa(g,u,a_see_mines) and(abs(ux-ut.x)<=1)and(abs(uy-ut.y)<=1)and isa(g,ut,a_sentry_or_not_bomb)then ut.stealth_detected[u.own]:=2;

   if zero or st_zero then if can_see(g,x,y,u.own,ut) then begin
    mark_unit(g,ut.num);
    if add_log then if (get_unu_qtr(g,x,y,j)=UQ_UP_LEFT)and not isa(g,ut,a_unselectable) then add_log_msgu(g,u.own,lmt_enemy_unit_spoted,ut);
   end;
  end;
  if(ux=x)and(uy=y) then for j:=0 to get_plr_count(g)-1 do begin
   pl2:=get_plr(g,j);
   if pl2.used then begin
    if isa(g,u,a_stealth)    and(pl2.scan_map[SL_STEALTH   ][pos]>0) then u.stealth_detected[j]:=2;
    if isa(g,u,a_underwater) and(pl2.scan_map[SL_UNDERWATER][pos]>0) then u.stealth_detected[j]:=2;
   end;
  end;
 end;
end;
//############################################################################//
//Substract scan
procedure subscan(g:pgametyp;u:ptypunits;add_log:boolean=false);
var x,y,xh,yh,xl,yl,pos,rad,i:integer;
prev_visible:boolean;
pl:pplrtyp;
uv:ptypunits;
begin 
 if not unav(u) then exit;  
 if u.own=-1 then exit;    
 pl:=get_plr(g,u.own); 
 if isa(g,u,a_disabled)  then exit;
 
 rad:=u.bas.scan+u.bas.speed+1;
 xh:=u.x-rad;yh:=u.y-rad;xl:=u.x+rad;yl:=u.y+rad;
 if xh<0 then xh:=0;if yh<0 then yh:=0;
 if xl>g.info.mapx-1 then xl:=g.info.mapx-1;
 if yl>g.info.mapy-1 then yl:=g.info.mapy-1;

 for x:=xh to xl do for y:=yh to yl do begin
  pos:=x+y*g.info.mapx;
  prev_visible:=pl.scan_map[SL_NORMAL][pos]<>0;  //Previous value of it.
  
  if compute_scan_point(g,u,x,y,u.x,u.y) then begin
   if pl.scan_map[SL_NORMAL][pos]=1 then begin
    for i:=0 to get_unu_length(g,x,y)-1 do if unav(get_unu(g,x,y,i)) then begin
     uv:=get_unu(g,x,y,i);
     if(uv.own<>u.own)and can_see(g,x,y,u.own,uv)then begin
      mark_unit(g,uv.num); 
      if add_log then if (get_unu_qtr(g,x,y,i)=UQ_UP_LEFT)and(not isa(g,uv,a_building))then add_log_msgu(g,u.own,lmt_enemy_unit_hiden,uv); 
     end;
    end;
   end;
   change_scan_point(g,pl,u,pos,-1);
  end;

  if pl.scan_map[SL_NORMAL    ][pos]<0 then pl.scan_map[SL_NORMAL    ][pos]:=0;
  if pl.scan_map[SL_UNDERWATER][pos]<0 then pl.scan_map[SL_UNDERWATER][pos]:=0;
  if pl.scan_map[SL_STEALTH   ][pos]<0 then pl.scan_map[SL_STEALTH   ][pos]:=0;

  if(pl.scan_map[SL_NORMAL    ][pos]=0)and prev_visible then razved_on_scan_sub(g,pl,u,x,y);
 end;
end;
//############################################################################//
//Full scan recalc, very slow
procedure reset_scan(g:pgametyp;pl:pplrtyp;do_razved:boolean);
var i:integer;
begin
 for i:=0 to SL_COUNT-1 do fillchar(pl.scan_map[i][0],2*g.info.mapx*g.info.mapy,0);
 if do_razved then razved_reset(pl); //Clears razved map without re-allocating things
end;
//############################################################################//
//Full scan recalc, very slow
procedure calc_scan_full(g:pgametyp;pl:pplrtyp;do_razved:boolean);
var i,x,y,xh,yh,xl,yl:integer;
un:ptypunits;
begin          
 reset_scan(g,pl,do_razved);

 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  un:=get_unit(g,i); 
  if un.own<>pl.num then continue;
  if un.bas.scan=0 then continue;
  if isa(g,un,a_disabled)  then continue;  

  xl:=un.x-un.bas.scan-2;
  xh:=un.x+un.bas.scan+2;
  yl:=un.y-un.bas.scan-2;
  yh:=un.y+un.bas.scan+2;
  if xl<0 then xl:=0;
  if yl<0 then yl:=0; 
  if xh>=g.info.mapx then xh:=g.info.mapx-1;
  if yh>=g.info.mapy then yh:=g.info.mapy-1;
  
  for y:=yl to yh do for x:=xl to xh do begin
   if not compute_scan_point(g,un,x,y,un.x,un.y) then continue;
   change_scan_point(g,pl,un,x+y*g.info.mapx,1);
   razved_on_scan_add(pl,x,y);                   //Does not damage the existing parts of the map.
  end;
 end;
end;     
//############################################################################//
begin
end.   
//############################################################################//
