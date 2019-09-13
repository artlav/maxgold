//############################################################################//
unit sdidraw_game;
interface
uses sysutils,asys,maths,strval,grph,sdi_rec,graph8
,mgrecs,mgl_common,mgl_attr,mgl_tests,mgl_rmnu,sdirecs,sdiauxi,sdicalcs,sdigrtools;
//############################################################################//
procedure draw_ut(s:psdi_rec;map:pmap_window_rec;zoom:double);   
procedure draw_mmap(s:psdi_rec;map:pmap_window_rec;mmx,mmy:integer);
procedure do_movmap(s:psdi_rec;dx,dy:integer);
procedure do_drawmap(s:psdi_rec;map:pmap_window_rec;xh,yh,xl,yl:integer);
procedure draw_map(s:psdi_rec;map:pmap_window_rec;zoom:double;sx,sy:integer;grid:boolean); 
procedure draw_units(s:psdi_rec;map:pmap_window_rec;zoom:double);
//############################################################################//
implementation    
//############################################################################//
const    
connector_x1:array[0..3]of array[0..2]of integer=((0,-1,0),(1,0,1),(0,1,2),(-1,0,3));
connector_x2:array[0..7]of array[0..2]of integer=((0,-1,0),(2,0,1),(0,2,2),(-1,0,3),(1,-1,4),(2,1,5),(1,2,6),(-1,1,7));    

wave_shift_ship:array[0..15]of array[0..1]of integer=
(( 0,-1),(0,0),( 1,-1),(0,0),
 ( 1, 0),(0,0),( 1, 1),(0,0),
 ( 0, 1),(0,0),(-1, 1),(0,0),
 (-1, 0),(0,0),(-1,-1),(0,0));
wave_shift_plane:array[0..31]of array[0..1]of integer=
(( 0,-1),( 0,-2),( 0,-1),(0,0),
 ( 1,-1),( 2,-2),( 1,-1),(0,0),
 ( 1, 0),( 2, 0),( 1, 0),(0,0),
 ( 1, 1),( 2, 2),( 1, 1),(0,0),
 ( 0, 1),( 0, 2),( 0, 1),(0,0),
 (-1, 1),(-2, 2),(-1, 1),(0,0),
 (-1, 0),(-2, 0),(-1, 0),(0,0),
 (-1,-1),(-2,-2),(-1,-1),(0,0));
//############################################################################// 
function sqc_cond(x,y,cx,cy,r,i,siz:integer):boolean;
begin
 result:=false;
 if cx>x then x:=x+(siz-1)*(1-ord((cx=x+1)and((i=0)or(i=3))));
 if cy>y then y:=y+(siz-1)*(1-ord((cy=y+1)and((i=0)or(i=1))));
 case i of
  0:result:=((sqr(cx-1-x)+sqr(cy-1-y))>sqr(r))and((sqr(cx  -x)+sqr(cy-1-y))<=sqr(r));
  1:result:=((sqr(cx  -x)+sqr(cy-1-y))>sqr(r))and((sqr(cx  -x)+sqr(cy  -y))<=sqr(r));
  2:result:=((sqr(cx  -x)+sqr(cy  -y))>sqr(r))and((sqr(cx-1-x)+sqr(cy  -y))<=sqr(r));
  3:result:=((sqr(cx-1-x)+sqr(cy  -y))>sqr(r))and((sqr(cx-1-x)+sqr(cy-1-y))<=sqr(r));
 end;
end;
//############################################################################//       
procedure squarecircle(s:psdi_rec;map:pmap_window_rec;zoom:double;x,y,r,off,siz,nc:integer;col:byte);
var cx,cy,fx,fy,i,xl,yl,n:integer;  
b:boolean;
label 1;
begin
 cx:=x-r;
 cy:=y;
 fx:=cx;
 fy:=cy;  
 n:=round(XCX/zoom);
 b:=false;

 1:     
 xl:=round((cx*XCX)/zoom-map.mapl);
 yl:=round((cy*XCX)/zoom-map.mapt);
 for i:=0 to 3 do case i of
  0:if(fx<>cx)or(fy<>(cy-1))then if sqc_cond(x,y,cx,cy,r,i,siz) then begin         
   drline8_skip(@sdiscrp,xl+off,yl+off,xl+off,yl+off-n,nc,col);
   fx:=cx;
   fy:=cy;
   cx:=cx;
   cy:=cy-1;
   if(cx=x-r)and(cy=y)then exit;
   goto 1;
  end;
  1:if(fx<>(cx+1))or(fy<>cy)then if sqc_cond(x,y,cx,cy,r,i,siz) then begin     
   drline8_skip(@sdiscrp,xl+off,yl+off,xl+off+n,yl+off,nc,col);
   if b then exit;
   fx:=cx;
   fy:=cy;
   cx:=cx+1;
   cy:=cy;
   if(cx=x-r)and(cy=y)then exit;
   goto 1;
  end;
  2:if(fx<>cx)or(fy<>(cy+1))then if sqc_cond(x,y,cx,cy,r,i,siz) then begin  
   drline8_skip(@sdiscrp,xl+off,yl+off,xl+off,yl+off+n,nc,col);
   fx:=cx;
   fy:=cy;
   cx:=cx;
   cy:=cy+1; 
   if(cx=x-r)and(cy=y)then exit;
   goto 1;
  end;  
  3:if(fx<>(cx-1))or(fy<>cy)then if sqc_cond(x,y,cx,cy,r,i,siz) then begin     
   drline8_skip(@sdiscrp,xl+off,yl+off,xl+off-n,yl+off,nc,col);
   fx:=cx;
   fy:=cy;
   cx:=cx-1;   
   b:=true;
   cy:=cy;
   if(cx=x-r)and(cy=y)then exit;
   goto 1;
  end;
 end; 
end;   
//############################################################################//
procedure ut_unit_a(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double;speed,scan,range:boolean);   
var xl,yl,bor,xp,yp,xlp,ylp,n,nc:integer;
col:byte; 
ud:ptypunitsdb;
begin try
 if not s.ut_circles and not s.ut_squares then exit;
 bor:=ord(isa(s.the_game,u,a_bor));
 xl:=round(((u.x*XCX+(u.mox+u.dmx*(1+3*ord(u.ptyp=5)))*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
 yl:=round(((u.y*XCX+(u.moy+u.dmy*(1+3*ord(u.ptyp=5)))*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
 if u.isstd and s.ut_at_end_move and cur_plr_unit(s.the_game,u) then begin
  xlp:=round(((u.xt*XCX+(u.dmx*(1+3*ord(u.ptyp=5)))*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
  ylp:=round(((u.yt*XCX+(u.dmy*(1+3*ord(u.ptyp=5)))*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
  xp:=u.xt;
  yp:=u.yt;
  nc:=5;
 end else begin
  xlp:=round(((u.x*XCX+(u.mox+u.dmx*(1+3*ord(u.ptyp=5)))*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
  ylp:=round(((u.y*XCX+(u.moy+u.dmy*(1+3*ord(u.ptyp=5)))*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
  xp:=u.x;
  yp:=u.y;
  nc:=10;
 end;
   
 //Speed
 if speed then if u.cur.speed>0 then begin
  col:=s.colors.clr_speed; 
  if s.ut_circles then begin
   n:=round(((u.cur.speed*XCX/10)/zoom))-2;
   drcirc8(@sdiscrp,xl,yl,n,col);
  end;
  if s.ut_squares then squarecircle(s,map,zoom,u.x,u.y,u.cur.speed div 10,-2,1,10,col);
 end;
 //Scan
 if scan then if u.bas.scan>0 then begin
  if isa(s.the_game,u,a_see_stealth)or isa(s.the_game,u,a_see_underwater) then col:=s.colors.clr_scan_det
                                                                          else col:=s.colors.clr_scan;
  if s.ut_circles then begin
   if s.the_game.info.rules.center_4x_scan then begin
    n:=round(((u.bas.scan*XCX)/zoom))+2;
   end else begin
    if u.siz+bor=2 then n:=round((u.bas.scan+0.65)*XCX/zoom)+2
                   else n:=round( u.bas.scan      *XCX/zoom)+2;
   end;
   if(xp<>u.x)or(yp<>u.y)then drcirc8_skip(@sdiscrp,xlp,ylp,n,nc,col)
                         else drcirc8(@sdiscrp,xlp,ylp,n,col);
  end;
  if s.ut_squares then squarecircle(s,map,zoom,xp,yp,u.bas.scan,0,u.siz+bor,nc,col);
  //Mine detector
  if isa(s.the_game,u,a_see_mines) then begin
   col:=s.colors.clr_scan_det;
   if s.ut_circles then begin
    if s.the_game.info.rules.center_4x_scan then begin
     n:=round(((1.5*XCX)/zoom))+2;
    end else begin
     if u.siz+bor=2 then n:=round((1.5+0.65)*XCX/zoom)+2
                    else n:=round( 1.5      *XCX/zoom)+2;
    end;
    if(xp<>u.x)or(yp<>u.y)then drcirc8_skip(@sdiscrp,xlp,ylp,n,nc,col)
                          else drcirc8(@sdiscrp,xlp,ylp,n,col);
   end;
   if s.ut_squares then squarecircle(s,map,zoom,xp,yp,1,0,u.siz+bor,nc,col);
  end;
 end;
 //Range
 if range then if u.bas.range>0 then begin
  ud:=get_unitsdb(s.the_game,u.dbn);
  case ud.fire_type of
   FT_LAND_WATER_COAST:col:=s.colors.clr_range_land;
   FT_WATER_COAST:     col:=s.colors.clr_range_water;
   FT_AIR:             col:=s.colors.clr_range_air;
   else                col:=s.colors.clr_range_all;
  end;
  if s.ut_circles then begin
   n:=round(((u.bas.range*XCX)/zoom));
   if(xp<>u.x)or(yp<>u.y)then drcirc8_skip(@sdiscrp,xlp,ylp,n,nc,col)
                         else drcirc8(@sdiscrp,xlp,ylp,n,col);
  end;
  if s.ut_squares then squarecircle(s,map,zoom,xp,yp,u.bas.range,2,1,nc,col); 
 end;  
 except stderr(s,'sdidraw_game','ut_unit_a'); end;
end;
//############################################################################//
procedure ut_unit_b(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double);   
var k,x,y,xl,yl,bor,n:integer;
col:byte;
su:ptypunits;
p,cp:pplrtyp;
begin try
 cp:=get_cur_plr(s.the_game);
 //check fog of war
 if can_see(s.the_game,u.x,u.y,cp.num,u) and (zoom<map.colorzoom) then begin
  //Next params are visible for all players
  //Colors
  if s.clinfo.sopt.frame_btn[fb_colors]=1 then if (((not isa(s.the_game,u,a_half_selectable)) and (not isa(s.the_game,u,a_unselectable)))or(isa(s.the_game,u,a_bomb))) then begin
   col:=get_player_color8(s,u.own);
   bor:=ord(isa(s.the_game,u,a_bor));
   xl:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
   yl:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
   n:=round((XHCX*(u.siz+bor))/zoom);
   drrect8(@sdiscrp,xl-n,yl-n,xl+n,yl+n,col);
  end;
  //Status
  if(s.clinfo.sopt.frame_btn[fb_status]=1)and(zoom<map.colorzoom)then begin
   //disabled
   if u.disabled_for<>0 then begin
    bor:=u.siz+ord(isa(s.the_game,u,a_bor))-1;
    y:=round((u.y*XCX+(u.moy+u.dmy+XHCX-12+XHCX*bor))/zoom-map.mapt);
    x:=round((u.x*XCX+(u.mox+u.dmx+XHCX-12+XHCX*bor))/zoom-map.mapl);
    putsprt8(@sdiscrp,s.cg.curs[5],x-12+round(12/zoom),y-12+round(12/zoom));
    drcirc8(@sdiscrp,x+round(12/zoom),y+round(12/zoom),round(16/zoom),1);
   end else begin //not disabled
    //speed. If no fuel then speed displayed for enemy players
    if(u.cur.speed>9)and((u.cur.fuel>9)or(plr_are_enemies(s.the_game,u.own,cp.num))or(u.bas.fuel=0)or(not s.the_game.info.rules.fueluse))then begin
     x:=round((u.x*XCX+(u.mox+u.dmx+XHCX-4))/zoom-4-map.mapl);
     y:=round((u.y*XCX+(u.moy+u.dmy+XCX))/zoom-10-map.mapt);
     if s.cg.grapu[GRU_DISABLED]<>nil then if length(s.cg.grapu[GRU_DISABLED].sprc)>2 then putsprt8(@sdiscrp,@s.cg.grapu[GRU_DISABLED].sprc[2],x,y);
    end;
    //no fuel. Do not displayed for enemy players
    if (u.cur.fuel<10)and not plr_are_enemies(s.the_game,u.own,cp.num)and(u.bas.fuel>0)and(s.the_game.info.rules.fueluse)then begin
     x:=round((u.x*XCX+(u.mox+u.dmx+XHCX-10))/zoom-6-map.mapl);
     y:=round((u.y*XCX+(u.moy+u.dmy+XCX))/zoom-14-map.mapt);
     if s.cg.grapu[GRU_ICOS]<>nil then if length(s.cg.grapu[GRU_ICOS].sprc)>4 then putsprt8(@sdiscrp,@s.cg.grapu[GRU_ICOS].sprc[4],x,y);
    end;
    //shots
    if not plr_are_enemies(s.the_game,u.own,cp.num) then n:=u.cur.ammo else n:=u.bas.ammo;
    if(u.cur.shoot>0)and(n>0)then begin
     y:=round((u.y*XCX+(u.moy+u.dmy+XCX))/zoom-10-map.mapt);
     for k:=0 to min2i(u.cur.shoot-1,n-1) do begin
      x:=round((u.x*XCX+(u.mox+u.dmx+XHCX+4)+k*8)/zoom+4-4-map.mapl);
      if s.cg.grapu[GRU_DISABLED]<>nil then if length(s.cg.grapu[GRU_DISABLED].sprc)>1 then putsprt8(@sdiscrp,@s.cg.grapu[GRU_DISABLED].sprc[1],x,y);
     end;
    end;
   end;
  end;
  //upgrade needed
  p:=get_plr(s.the_game,u.own);
  if not plr_are_enemies(s.the_game,u.own,cp.num)and(u.own<>-1)and(not u.is_unselectable)and(u.mk<>p.unupd[u.dbn].mk) then begin
   su:=get_sel_unit(s.the_game);
   if unav(su) then begin
    if isa(s.the_game,su,a_research) or isa(s.the_game,su,a_upgrader) then begin
     x:=round((u.x*XCX+(u.mox+u.dmx+XHCX*u.siz-4)-10)/zoom-4-4-map.mapl);
     y:=round((u.y*XCX+(u.moy+u.dmy+XCX*u.siz))/zoom-14-map.mapt);
     putsprt8(@sdiscrp,@s.cg.grapu[GRU_ICOS].sprc[30],x,y);
    end;
   end;
  end;
  //Next params are visible only for selectable units
  if not isa(s.the_game,u,a_unselectable) then begin
   //Hits
   if(u.bas.hits<>0)and(u.cur.hits<>u.bas.hits)then if(s.clinfo.sopt.frame_btn[fb_hits]=1)or is_hits_low(u) then begin
    x :=round((u.x*XCX+(u.mox+u.dmx+5))/zoom-map.mapl);
    y :=round((u.y*XCX+(u.moy+u.dmy+5))/zoom-map.mapt);
    xl:=round((u.x*XCX+(u.mox+u.dmx+u.siz*XCX-5))/zoom-map.mapl);
    yl:=round((u.y*XCX+(u.moy+u.dmy+5+5*u.siz))/zoom-map.mapt);
    if yl-y<2 then yl:=y+2;
           
    if is_hits_red(u) then col:=1 else if is_hits_yellow(u) then col:=4 else col:=2;
    drfrect8(@sdiscrp,x,y,xl,yl,0);
    if(u.bas.hits<>0)and(u.cur.hits<>0)then drfrect8(@sdiscrp,x+1,y+1,x+round((xl-x-1)*(u.cur.hits/u.bas.hits)),yl-1,col);
   end;
   //Names
   if s.clinfo.sopt.frame_btn[fb_names]=1 then begin
    if not isa(s.the_game,u,a_half_selectable) then begin
     x:=round((u.x*XCX+(u.mox+u.dmx)+5)/zoom-map.mapl);
     y:=round((u.y*XCX+(u.moy+u.dmy)+15)/zoom-map.mapt);
     xl:=round((u.x*XCX+(u.mox+u.dmx)+u.siz*XCX-5)/zoom-map.mapl);
     yl:=round((u.y*XCX+(u.moy+u.dmy)+u.siz*XCX-15)/zoom-map.mapt);
     wrtxtbox8(s.cg,@sdiscrp,x,y,xl,yl,unit_name(s.the_game,u),14);
    end;
   end;
   //Next params are visible for current player only and not half selectable units
   if not plr_are_enemies(s.the_game,u.own,cp.num) and not isa(s.the_game,u,a_half_selectable) then begin
    //Ammo
    if(u.bas.ammo<>0)and(u.cur.ammo<>u.bas.ammo)then if(s.clinfo.sopt.frame_btn[fb_ammo]=1) or is_ammo_low(u) then begin
     x :=round((u.x*XCX+(u.mox+u.dmx+5))/zoom-map.mapl);
     y :=round((u.y*XCX+(u.moy+u.dmy+5+5+5*u.siz))/zoom-map.mapt);
     xl:=round((u.x*XCX+(u.mox+u.dmx+u.siz*XCX-5))/zoom-map.mapl);
     yl:=round((u.y*XCX+(u.moy+u.dmy+5+5*u.siz+5+5*u.siz))/zoom-map.mapt);
     if yl-y<2 then yl:=y+2;

     if is_ammo_red(u) then col:=1 else if is_ammo_yellow(u) then col:=4 else col:=40;
     drfrect8(@sdiscrp,x,y,xl,yl,0);
     if(u.bas.ammo<>0)and(u.cur.ammo<>0)then drfrect8(@sdiscrp,x+1,y+1,x+round((xl-x-1)*(u.cur.ammo/u.bas.ammo)),yl-1,col);
    end;
    //Fuel
    if(u.bas.fuel<>0)and(u.cur.fuel<>u.bas.fuel)then if(s.clinfo.sopt.frame_btn[fb_fuel]=1)or(u.cur.fuel/(u.bas.fuel*10)<=0.25)then begin
     x :=round((u.x*XCX+(u.mox+u.dmx+5))/zoom-map.mapl);
     y :=round((u.y*XCX+(u.moy+u.dmy+u.siz*XCX-5-5*u.siz))/zoom-map.mapt);
     xl:=round((u.x*XCX+(u.mox+u.dmx+u.siz*XCX-5))/zoom-map.mapl);
     yl:=round((u.y*XCX+(u.moy+u.dmy+u.siz*XCX-5))/zoom-map.mapt);
     if yl-y<2 then yl:=y+2;

     col:=1;
     if u.cur.fuel/(u.bas.fuel*10)>0.25 then col:=4;
     if u.cur.fuel/(u.bas.fuel*10)>0.5  then col:=32;

     drfrect8(@sdiscrp,x,y,xl,yl,0);
     if(u.bas.fuel<>0)and(u.cur.fuel<>0)then drfrect8(@sdiscrp,x+1,y+1,x+round((xl-x-1)*(u.cur.fuel/(u.bas.fuel*10))),yl-1,col);
    end;
   end;
  end;
 end;  
 except stderr(s,'sdidraw_game','ut_unit_b'); end;
end;     
//############################################################################//
procedure draw_survey(s:psdi_rec;map:pmap_window_rec;zoom:double);
var x,y,xl,yl,yo:integer;
ydo,yso,mx:dword;
f,d:pbytea;
u:ptypunits;
cp:pplrtyp;
begin try  
 if s.cg.grap[GRP_SURVRES]=nil then exit;
 if s.cg.grap[GRP_SURVRES].srf=nil then exit;         
 if not s.ut_event then exit;
 
 //Geolog
 //for i:=0 to 100 do if utev then drawut;  
 //0.46s
 cp:=get_cur_plr(s.the_game);
 s.ut_event:=false;
 u:=get_sel_unit(s.the_game);
 if u<>nil then if not((u.own=cp.num)and(isa(s.the_game,u,a_surveyor)))then u:=nil;
 if not ((s.clinfo.sopt.frame_btn[fb_survey]=1)or(u<>nil)) then exit;

 xl:=map.mapr-map.mapl-1;
 yl:=map.mapb-map.mapt-1;
 if xl>scrx-1 then xl:=scrx-1;
 if yl>scry-1 then yl:=scry-1;
 for y:=0 to yl do begin
  yo:=y*scrx;
  yso:=map.block_xlate[map.mapt+y]*dword(s.mapx);
  if yso<dword(s.mapy*s.mapx) then begin
   if map.block_xlate[xl+map.mapl]+yso>=dword(length(s.rpmap)) then break;
   ydo:=map.offset_xlate_y[map.mapt+y]*16;
   intptr(d):=intptr(s.ut_plane.srf)+intptr(yo-map.mapl);
   intptr(f):=intptr(s.cg.grap[GRP_SURVRES].srf)+ydo;

   for x:=map.mapl to xl+map.mapl do begin
    mx:=map.block_xlate[x];
    if mx<dword(s.mapx) then d[x]:=f^[s.rpmap[mx+yso]+map.offset_xlate_x[x]]
                        else d[x]:=map.background_fill_color;
   end;

  end else fillchar(pointer(intptr(s.ut_plane.srf)+intptr(yo-map.mapl))^,xl+map.mapl-map.mapl,map.background_fill_color);
 end;
 tdu:=tdu+xl*yl;

 except stderr(s,'sdidraw_game','draw_survey'); end;
end;
//############################################################################//
//Draw statists - survey, scan, range, move, names, Grid is in drawmap
procedure draw_ut(s:psdi_rec;map:pmap_window_rec;zoom:double);
var i:integer;
u:ptypunits;
cp:pplrtyp;
begin try
 draw_survey(s,map,zoom);
         
 cp:=get_cur_plr(s.the_game);
 if unav(s.the_game,cp.selunit) then begin
  u:=get_unit(s.the_game,cp.selunit);
  if can_see(s.the_game,u.x,u.y,cp.num,u) then ut_unit_a(s,map,u,zoom,s.clinfo.sopt.frame_btn[fb_speedrange]=1,s.clinfo.sopt.frame_btn[fb_scan]=1,s.clinfo.sopt.frame_btn[fb_range]=1);
 end;

 for i:=0 to get_units_count(s.the_game)-1 do if unav(s.the_game,i) then begin
  u:=get_unit(s.the_game,i);
  if not ingf(s,u) then continue;
  if s.clinfo.lck_mode then if unit_in_lock(s,u) then if can_see(s.the_game,u.x,u.y,cp.num,u) or isa(s.the_game,u,a_building) then ut_unit_a(s,map,u,zoom,s.clinfo.sopt.frame_btn[fb_speedrange]=1,s.clinfo.sopt.frame_btn[fb_scan]=1,s.clinfo.sopt.frame_btn[fb_range]=1);
  ut_unit_b(s,map,u,zoom);
 end;

 except stderr(s,'sdidraw_game','draw_ut'); end;
end;
//############################################################################//
//############################################################################//
//Draws minimap
procedure draw_mmap(s:psdi_rec;map:pmap_window_rec;mmx,mmy:integer);
var i,x,y,dx,dy,xsx,ysy,yo:integer;
d,ms,md:pbytea;
c:byte;
u,su:ptypunits;
cp:pplrtyp;
begin try
 if not s.minimap_event then exit;
 if s.the_game=nil then exit;
 s.minimap_event:=false;
 
 cp:=get_cur_plr(s.the_game);
 d:=s.minimap_plane.srf;
 ms:=s.mm_tileset.srf;
 md:=s.mm_tileset_fow.srf;

 //draw surface
 xsx:=(100*112) div s.mapx;
 ysy:=(100*112) div s.mapy;
 if xsx<ysy then ysy:=xsx else xsx:=ysy;
 if xsx>100 then begin xsx:=100;ysy:=100; end; //correct aspect ratio
 dx:=(112-(s.mapx*xsx) div 100) div 2;
 dy:=(112-(s.mapy*ysy) div 100) div 2;
 for y:=0 to 112-1 do begin
  yo:=100*(y-dy) div ysy;
  for x:=0 to 112-1 do begin
   if can_see(s.the_game,100*(x-dx) div xsx,yo,cp.num,nil) then d[x+y*112]:=ms[x+y*112] else d[x+y*112]:=md[x+y*112];
  end;
 end;

 //draw units
 su:=get_sel_unit(s.the_game);
 for i:=0 to get_units_count(s.the_game)-1 do begin
  u:=get_unit(s.the_game,i);
  if not unav(u) then continue;
  if not can_see(s.the_game,u.x,u.y,cp.num,u) then continue;
  if isa(s.the_game,u,a_bomb) or isa(s.the_game,u,a_unselectable) then continue;
  c:=get_player_color8(s,u.own);
  if u=su then c:=255;
  if u.siz=1 then drpix8(@s.minimap_plane,(u.x*xsx) div 100+dx,(u.y*ysy) div 100+dy,c);
  if u.siz=2 then begin
   drpix8(@s.minimap_plane,((u.x  )*xsx)div 100+dx,((u.y  )*ysy)div 100+dy,c);
   drpix8(@s.minimap_plane,((u.x+1)*xsx)div 100+dx,((u.y  )*ysy)div 100+dy,c);
   drpix8(@s.minimap_plane,((u.x  )*xsx)div 100+dx,((u.y+1)*ysy)div 100+dy,c);
   drpix8(@s.minimap_plane,((u.x+1)*xsx)div 100+dx,((u.y+1)*ysy)div 100+dy,c);
  end;
 end;

 except stderr(s,'sdidraw_game','draw_mmap'); end;
end;             
//############################################################################//
//FIXME: Still very slow...  Move to map layer!
//Also, fix eunitsdb in it
procedure draw_units_razved(s:psdi_rec;map:pmap_window_rec;zoom:double);
var n,p,x,y,l,xn,yn,yl,yh,xl,xh:integer;
raz:prazvedtyp;   
ud:ptypunitsdb;
eu:ptypeunitsdb;
spr:ptypspr;
c:byte;
px:pointer;
cp,pl:pplrtyp;
begin try
 cp:=get_cur_plr(s.the_game);

 yl:=round((1+map.mapt)*zoom/XCX)-2;
 yh:=round((scry-1+map.mapt)*zoom/XCX);
 xl:=round(map.mapl*zoom/XCX)-2;
 xh:=round((scrx-1+map.mapl)*zoom/XCX);
 if xl<0 then xl:=0;
 if yl<0 then yl:=0;
 if xh>=s.mapx then xh:=s.mapx-1;
 if yh>=s.mapy then yh:=s.mapy-1; 
 
 for y:=yl to yh do for x:=xl to xh do begin
  if fast_can_see(s.the_game,x,y,cp.num) then continue;
  raz:=@cp.razvedmp[x,y];
  {
  if not raz.seen then begin
   //Find recon data from allied players only if no data.
   for i:=0 to get_plr_count(s.the_game)-1 do if not plr_are_enemies(s.the_game,cp.num,i) then begin
    pl:=get_plr(s.the_game,i);
    raz:=@pl.razvedmp[x,y];
    if raz.seen then break;
   end;      
  end;
  }
  if not(raz.seen and(length(raz.blds)<>0))then continue;

  for n:=0 to 6 do for l:=length(raz.blds)-1 downto 0 do if raz.blds[l].level=n then begin
   spr:=nil;

   ud:=get_unitsdb(s.the_game,raz.blds[l].id);  
   if ud=nil then continue;
   eu:=get_edb(s,ud.typ);
   if eu=nil then continue;

   p:=round(eu.base_frames.x)+0;
   if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
   if eu.spr_base.cnt<>0 then spr:=@eu.spr_base.sprc[p];

   if eu.typ='mining' then begin
    pl:=get_plr(s.the_game,raz.blds[l].own);
    if raz.blds[l].own<>-1 then p:=p+pl.info.clan*2;
    spr:=@eu.spr_base.sprc[p];
   end;

   c:=get_player_color8(s,raz.blds[l].own);
   px:=get_player_palpx(s,raz.blds[l].own);

   //Base
   if spr<>nil then begin
    xn:=round(((x*XCX+XHCX*ud.siz-spr.cx)/zoom-map.mapl));
    yn:=round(((y*XCX+XHCX*ud.siz-spr.cy)/zoom-map.mapt));
    if zoom< map.colorzoom then                     putsprzoomt8xtra(s,@s.map_plane,spr,xn,yn,px);
    if zoom>=map.colorzoom then if ud.level>=3 then putsprmczoomt8  (s,@s.map_plane,spr,xn,yn,c);
   end;

  end;
 end;

 except stderr(s,'sdidraw_game','draw_units_razved');end;
end;
//############################################################################//
//############################################################################//
//Map move process
procedure do_movmap(s:psdi_rec;dx,dy:integer);
var y,ss,sd:integer;
a1,a2:pchar;
begin  
 if dx>=0 then begin  
  a1:=pointer(intptr(s.map_plane.srf)+intptr(dx));    //src
  a2:=pointer(intptr(s.map_plane.srf));      //dst
  ss:=(scrx-dx);
 end else begin 
  a1:=pointer(intptr(s.map_plane.srf));    //src
  a2:=pointer(intptr(s.map_plane.srf)+intptr(abs(dx)));      //dst
  ss:=(scrx-(-dx));
 end;
 sd:=scrx;
 if dy>=0 then begin  
  a1:=a1+dy*scrx;    //src
  for y:=0 to scry-dy-1 do begin fastmove(a1^,a2^,ss);a1:=a1+sd;a2:=a2+sd;end;
 end else begin     
  a1:=a1+(scry-(-dy)-1)*scrx;    //src
  a2:=a2+(scry-1)*scrx;      //dst
  for y:=0 to scry-(-dy)-1 do begin fastmove(a1^,a2^,ss);a1:=a1-sd;a2:=a2-sd;end;
 end;
end;
//############################################################################//
//Map region drawing 
procedure do_drawmap(s:psdi_rec;map:pmap_window_rec;xh,yh,xl,yl:integer);
type aoi16=array of int16;
var i,x,y,yso,ys2o,y2mo,ox,mx,yo:integer;
ydo:dword;
xx:boolean;
c1,a1,d1:pchar; 
d,sx,f:pbytea;
sm:array of ^aoi16;
p,cp:pplrtyp;
begin 
 //0.60s x100?
 //48
 if s.map_tileset=nil then exit;
 if s.map_tileset_fow=nil then exit;
 d:=s.map_plane.srf;
 cp:=get_cur_plr(s.the_game);

 a1:=@(d^[xh+yh*scrx]);
 yo:=(scrx-xl+xh-1);
 c1:=@map.block_xlate[map.mapl+xh];
 d1:=@map.offset_xlate_x[map.mapl+xh];  

 setlength(sm,get_plr_count(s.the_game));
 for i:=0 to get_plr_count(s.the_game)-1 do begin
  p:=get_plr(s.the_game,i);
  sm[i]:=@p.scan_map[SL_NORMAL];
 end;

 for y:=yh to yl do begin
  yso:=map.block_xlate[map.mapt+yh+y]*dword(s.mapx);
  if yso>=s.mapx*s.mapx then begin
   fillchar(pbyte(a1)^,xl-xh,map.background_fill_color);
   a1:=a1+xl-xh;
  end else begin

   if s.cg.fog_of_war then begin
    ox:=pinteger(c1)^;
    ys2o:=map.block_xlate[map.mapt+y];
    y2mo:=ys2o*s.mapx;
    if ox+y2mo<s.mapx*s.mapx then xx:=can_see(s.the_game,ox,ys2o,cp.num,nil) else xx:=true;
    ydo:=map.offset_xlate_y[map.mapt+y];
    intptr(f):=intptr(s.map_tileset.srf)+ydo;
    intptr(sx):=intptr(s.map_tileset_fow.srf)+ydo;
    for x:=xh to xl do begin
     mx:=pinteger(c1)^;
     if mx>=s.mapx then begin
      pbyte(a1)^:=map.background_fill_color;
     end else begin
      if mx<>ox then if mx+y2mo<s.mapx*s.mapx then begin
       xx:=false;
       for i:=0 to get_plr_count(s.the_game)-1 do if not plr_are_enemies(s.the_game,cp.num,i) then xx:=xx or(sm[i]^[mx+y2mo]>0)
      end else xx:=true;
      if not xx then pbyte(a1)^:=sx^[s.pmap[mx+yso]+pinteger(d1)^] else
                     pbyte(a1)^:=f^ [s.pmap[mx+yso]+pinteger(d1)^];
      ox:=mx;
     end;
     a1:=a1+1;
     c1:=c1+4;
     d1:=d1+4;
    end;
   end else begin
    intptr(f):=intptr(s.map_tileset.srf)+map.offset_xlate_y[map.mapt+yh+y];
    for x:=xh to xl do begin
     mx:=pinteger(c1)^;
     if mx>=s.mapx then begin
      pbyte(a1)^:=map.background_fill_color;
     end else begin
      pbyte(a1)^:=f^[s.pmap[mx+yso]+pinteger(d1)^];
     end;
     a1:=a1+1;
     c1:=c1+4;
     d1:=d1+4;
    end;
   end;
         
   c1:=@map.block_xlate[map.mapl+xh];
   d1:=@map.offset_xlate_x[map.mapl+xh];
  end;
  a1:=a1+yo;
 end;
end;
//############################################################################//
//############################################################################//
//Map drawings controller and grid draw
procedure draw_map(s:psdi_rec;map:pmap_window_rec;zoom:double;sx,sy:integer;grid:boolean);
var xl,yl,x,y,dx,dy:integer;   
d:pbytea;
col:byte;
su:ptypunits;
cp:pplrtyp;
begin try xl:=0;yl:=0;  
 if not(s.map_event or s.map_scroll_ev) then exit;
 cp:=get_cur_plr(s.the_game);

 if s.map_event then begin
  do_drawmap(s,map,0,0,scrx-1,scry-1);
 end else begin
  dx:=round((sx-map.mapoxo)/zoom);
  dy:=round((sy-map.mapoyo)/zoom);

  if(abs(dx)>=scrx)or(abs(dy)>=scry)then do_drawmap(s,map,0,0,scrx-1,scry-1) 
  else begin
   do_movmap(s,dx,dy);
   if dx<>0 then if dx>=0 then do_drawmap(s,map,scrx-dx,0      ,scrx-1,scry-1)else do_drawmap(s,map,0,0,-dx   ,scry-1);
   if dy<>0 then if dy>0  then do_drawmap(s,map,      0,scry-dy,scrx-1,scry-1)else do_drawmap(s,map,0,0,scrx-1,-dy);
  end;     
 end; 
  
 s.map_event:=false;
 s.map_scroll_ev:=false;
 s.ut_event:=true;       
    
 //Draw grid
 d:=s.map_plane.srf;
 su:=get_sel_unit(s.the_game);
 if grid and(zoom<map.colorzoom)and((not is_landed(s.the_game,cp))or unav(su)) then begin
  col:=get_grid_color8(s);
  dx:=2;    //Dotted grid
  for y:=0 to min2i(map.gfcy,s.mapx)-1 do begin
   yl:=round(map.psy+y*XCX/zoom);
   xl:=min2i(round(s.mapx*(XCX/zoom)),scrx);
   if yl<scry then for x:=0 to (xl div dx)-1 do d^[x*dx+yl*scrx]:=col;
  end;
  for x:=0 to min2i(map.gfcx,s.mapx)-1 do begin
   xl:=round(map.psx+x*XCX/zoom);
   yl:=min2i(round(s.mapx*(XCX/zoom)),scry);
   if xl<scrx then for y:=0 to (yl div dx)-1 do d^[xl+y*dx*scrx]:=col;
  end;
 end;  

 tdu:=tdu+xl*yl+map.gfcx*s.mapx+map.gfcy*s.mapx;
    
 //Razvedka
 draw_units_razved(s,map,zoom);
  
 except stderr(s,'sdidraw_game','draw_map');end;
end;          
//############################################################################// 
//############################################################################// 
//############################################################################// 
//Drawing units
procedure put_con(s:psdi_rec;map:pmap_window_rec;u:ptypunits;eu:ptypeunitsdb;zoom:double;bor,n:integer;sh:boolean);
var p,xn,yn:integer;
spr:ptypspr;
c:byte;
px:pointer; 
begin try
 c:=get_player_color8(s,u.own);
 px:=get_player_palpx(s,u.own);
 p:=round(eu.connector_frames.x)+n;
 if not sh then begin       
  if p>=length(eu.spr_base.sprc) then exit;
  if eu.spr_base.sprc[p].srf=nil then exit;
  spr:=@eu.spr_base.sprc[p];
  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor)-spr.cx)/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor)-spr.cy)/zoom-map.mapt));
  if zoom< map.colorzoom then                    putsprzoomt8x (s,@sdiscrp,spr,xn,yn,px);
  if zoom>=map.colorzoom then if u.level>=3 then putsprmczoomt8(s,@sdiscrp,spr,xn,yn,c);
 end else begin
  if p>=length(eu.spr_shadow.sprc) then exit;
  if eu.spr_shadow.sprc[p].srf=nil then exit;
  spr:=@eu.spr_shadow.sprc[p];
  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor)-spr.cx)/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor)-spr.cy)/zoom-map.mapt));
  if zoom< map.colorzoom then                    putsprszoomt8(s,@sdiscrp,spr,xn,yn);
 end;   
 except stderr(s,'sdidraw_game','put_con');end;
end;
//############################################################################//
procedure proc_con(s:psdi_rec;map:pmap_window_rec;u:ptypunits;eu:ptypeunitsdb;zoom:double;bor:integer;sh:boolean);
var j,k:integer;
uu:ptypunits;
begin try
 if eu.connector_frames.x<>-1 then if u.siz=1 then for k:=0 to 3 do begin
  for j:=0 to get_unu_length(s.the_game,u.x+connector_x1[k][0],u.y+connector_x1[k][1])-1 do begin      //get_unu_length takes care of bounds
   uu:=get_unu(s.the_game,u.x+connector_x1[k][0],u.y+connector_x1[k][1],j);
   if (isa(s.the_game,uu,a_building))and(unav(uu))and(uu.own=u.own)and((not isa(s.the_game,uu,a_half_selectable))or(uu.typ='conn'))and(not isa(s.the_game,uu,a_unselectable))and(uu.rot<>16) then begin
    put_con(s,map,u,eu,zoom,bor,connector_x1[k][2],sh);
   end;
  end;
 end;
 if eu.connector_frames.x<>-1 then if u.siz=2 then for k:=0 to 7 do begin
  for j:=0 to get_unu_length(s.the_game,u.x+connector_x2[k][0],u.y+connector_x2[k][1])-1 do begin
   uu:=get_unu(s.the_game,u.x+connector_x2[k][0],u.y+connector_x2[k][1],j);
   if (isa(s.the_game,uu,a_building))and(unav(uu))and(uu.own=u.own)and((not isa(s.the_game,uu,a_half_selectable))or(uu.typ='conn'))and(not isa(s.the_game,uu,a_unselectable))and(uu.rot<>16) then begin
    put_con(s,map,u,eu,zoom,bor,connector_x2[k][2],sh);
   end;
  end;
 end;    
 except stderr(s,'sdidraw_game','proc_con');end;
end;
//############################################################################//
procedure draw_build_path(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double);
var i,xn,yn,dir:integer;
b:buildrec;
begin try
 for i:=1 to u.builds_cnt-1 do begin
  b:=u.builds[i];
  xn:=round(((b.x*XCX)/zoom-map.mapl));
  yn:=round(((b.y*XCX)/zoom-map.mapt));
       if u.x<b.x then dir:=2
  else if u.x>b.x then dir:=6
  else if u.y<b.y then dir:=4
                  else dir:=0;
  putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_PATH].sprc[dir],xn,yn);
 end;
 except stderr(s,'sdidraw_game','draw_build_path');end;
end;
//############################################################################//
procedure draw_unit_path(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double);
var i,j,xn,yn:integer;
av:double;
ud:ptypunitsdb;
p:prec;              //current path item
dsh,ssp,fsh:boolean; //flag to show shots and speed on the path
ssc:boolean;         //flag to show speed counter on the end of a path
sc:integer;          //shoots counter
av_speed:integer;    //available speed
av_shots:integer;    //available speed used for calculate shots
av_fuel:integer;     //available fuel used for calculate fuel and speed
sps:double;          //speed per one shot
kin:boolean;         //end turn marker
begin try
 if isa(s.the_game,u,a_building) then exit;
 av_shots:=0;
 sps:=1;
 av_fuel:=0;
 av_speed:=u.cur.speed;
 if (s.clinfo.sopt.frame_btn[fb_status]=1)and(zoom<5) then begin
  ssp:=true;
  dsh:=u.bas.shoot>0;
  if dsh then begin
   sps:=u.bas.speed*10/u.bas.shoot;
   av_shots:=av_speed;
  end;
  fsh:=s.the_game.info.rules.fueluse and (u.bas.fuel>0);
  if fsh then av_fuel:=u.cur.fuel;
 end else begin ssp:=false;dsh:=false;fsh:=false;end;
 ssc:=ssp;
 av:=u.bas.speed*10-u.cur.speed;
 for i:=u.pstep+1 to u.plen-1 do begin
  p:=u.path[i];
  xn:=round(((p.px*XCX)/zoom-map.mapl));
  yn:=round(((p.py*XCX)/zoom-map.mapt));
  kin:=(i=u.plen-1)or((u.bas.speed*10-av>=p.pval)and(u.bas.speed*10-av<p.pval+u.path[i+1].pval));
  putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_PATH].sprc[p.dir+8*ord(not kin)],xn,yn);

  av:=av+p.pval;
  repeat
   if av>=u.bas.speed*10 then begin
    av:=av-u.bas.speed*10;ssp:=false;
    if fsh and (u.ptyp=pt_air) and (u.alt<>0) and (u.bas.speed>0) then av_fuel:=av_fuel-10; // dec fuel each turn
   end;
  until av<u.bas.speed*10;
  av_speed:=round(av_speed-p.pval);
  if dsh then av_shots:=av_shots-trunc(p.pval);
  if fsh then begin
   av_fuel:=av_fuel-trunc(p.pval);
   if av_fuel<=0 then ssp:=false; // no speed status because no fuel to move
  end;

  //speed
  if ssp then if av_speed>9 then if av_speed>=p.pval then begin
   xn:=round((p.px*XCX+(XHCX-4))/zoom-4-map.mapl);
   yn:=round((p.py*XCX+(XCX))/zoom-10-map.mapt);
   putsprt8(@sdiscrp,@s.cg.grapu[GRU_DISABLED].sprc[2],xn,yn);
  end;
  // available speed count on the end of a path
  if ssc and (i=u.plen-1) and (av_speed>9) then begin
   ssc:=false;
   xn:=round((p.px*XCX+(XHCX-4))/zoom-8-map.mapl);
   yn:=round((p.py*XCX+(XCX)-4)/zoom-10-map.mapt);
   wrbgtxtcnt8(s.cg,@sdiscrp,xn,yn,stri(trunc(av_speed/10)),3);
  end;
  //fuel
  if fsh and(av_fuel<=0)then begin
   xn:=round((p.px*XCX+(XHCX-10))/zoom-6-map.mapl);
   yn:=round((p.py*XCX+(XCX))/zoom-14-map.mapt);
   putsprt8(@sdiscrp,@s.cg.grapu[GRU_ICOS].sprc[4],xn,yn);
  end;
  //shots
  if dsh and(av_shots>=0) then begin
   yn:=round((p.py*XCX+XCX)/zoom-10-map.mapt);
   ud:=get_unitsdb(s.the_game,u.dbn);
   if ud.firemov then sc:=u.cur.shoot else sc:=min2i(trunc(av_shots/sps),u.bas.shoot);
   for j:=0 to min2i(sc, u.cur.ammo)-1 do begin
    xn:=round((p.px*XCX+(XHCX+4)+j*8)/zoom+4-4-map.mapl);
    putsprt8(@sdiscrp,@s.cg.grapu[GRU_DISABLED].sprc[1],xn,yn);
   end;
  end;
 end;
 except stderr(s,'sdidraw_game','draw_unit_path');end;
end;
//############################################################################//
procedure draw_unit_buildstuff(s:psdi_rec;xns,yns:integer;map:pmap_window_rec;u:ptypunits;zoom:double);   
var i,j,bor,xn,yn,d:integer;  
mods:pmods_rec;
begin try  
 if not unav(u) then exit;
 mods:=get_mods(s.the_game);
   
 //Build fin
 if mods.build_exit and(u.builds_cnt<>0)then if s.cg.grapu[GRU_BUILDMARK]<>nil then if length(s.cg.grapu[GRU_BUILDMARK].sprc)<>0 then begin
  bor:=ord(isa(s.the_game,u,a_bor));
  d:=getdbnum(s.the_game,u.builds[0].typ);

  if isa(s.the_game,u,a_building) then begin
   if u.siz+bor=1 then for i:=u.x-1 to u.x+1 do for j:=u.y-1 to u.y+1 do if not((i=u.x)and(j=u.y))then begin
    if test_pass_db(s.the_game,i,j,d,nil) then begin
     xn:=round((i*XCX/zoom-map.mapl));
     yn:=round((j*XCX/zoom-map.mapt));

     putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_BUILDMARK].sprc[round(s.gct*8) mod 5],xn,yn);
    end;
   end;
   if u.siz+bor=2 then for i:=u.x-1 to u.x+2 do for j:=u.y-1 to u.y+2 do if not inrects(i,j,u.x,u.y,1,1)then begin
    if test_pass_db(s.the_game,i,j,d,nil) then begin
     xn:=round((i*XCX/zoom-map.mapl));
     yn:=round((j*XCX/zoom-map.mapt));

     putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_BUILDMARK].sprc[round(s.gct*8) mod 5],xn,yn);
    end;
   end;
  end else begin
   if u.siz+bor=1 then for i:=u.x-1 to u.x+1 do for j:=u.y-1 to u.y+1 do if not((i=u.x)and(j=u.y))then begin
    if test_pass(s.the_game,i,j,u) then begin
     xn:=round((i*XCX/zoom-map.mapl));
     yn:=round((j*XCX/zoom-map.mapt));

     putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_BUILDMARK].sprc[round(s.gct*8) mod 5],xn,yn);
    end;
   end;
   if u.siz+bor=2 then for i:=u.x-1 to u.x+2 do for j:=u.y-1 to u.y+2 do if not inrects(i,j,u.x,u.y,1,1)then begin
    if test_pass(s.the_game,i,j,u) then begin
     xn:=round((i*XCX/zoom-map.mapl));
     yn:=round((j*XCX/zoom-map.mapt));

     putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_BUILDMARK].sprc[round(s.gct*8) mod 5],xn,yn);
    end;
   end;
  end;
 end;

 //Build
 if mods.build_rect and not mods.not_available then begin
  if (xns>=u.x-1)and(yns>=u.y-1)and(xns<=u.x+1)and(yns<=u.y+1)then begin
   if (xns>=u.x-1)and(yns>=u.y-1)and(xns<=u.x)and(yns<=u.y)then begin
    xn:=round(((xns*XCX)/zoom-map.mapl));
    yn:=round(((yns*XCX)/zoom-map.mapt));
   end else begin
    xn:=round((((xns-ord(xns=(u.x+1)))*XCX)/zoom-map.mapl));
    yn:=round((((yns-ord(yns=(u.y+1)))*XCX)/zoom-map.mapt));
   end;
   if s.auxun[UN_BIGROPE]<>nil then putsprzoomt8(s,@sdiscrp,@s.auxun[UN_BIGROPE].spr_base.sprc[0],xn,yn);
  end;
 end;

 //Build path
 if mods.build_path then begin
  if(xns=u.x)or(yns=u.y)then begin
   xn:=round(((xns*XCX)/zoom-map.mapl));
   yn:=round(((yns*XCX)/zoom-map.mapt));
   if s.auxun[UN_SMLROPE]<>nil then putsprzoomt8(s,@sdiscrp,@s.auxun[UN_SMLROPE].spr_base.sprc[0],xn,yn);
  end;
 end;
 except stderr(s,'sdidraw_game','draw_unit_buildstuff');end;
end;
//############################################################################//
procedure draw_one_unit(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double);
var eu:ptypeunitsdb;
c:byte;
px:pointer;
p,bor,xn,yn,k:integer;
spr:ptypspr;
pl,cp:pplrtyp;
revealed_stealth,true_water:boolean;
begin try
 if u.grp_db=-1 then exit;
 eu:=s.eunitsdb[u.grp_db];
 if eu=nil then exit;
 c:=get_player_color8(s,u.own);
 px:=get_player_palpx(s,u.own);
 cp:=get_cur_plr(s.the_game);

 bor:=ord(isa(s.the_game,u,a_bor));
 if(u.siz=1)and(bor=0)then begin
  if not can_see(s.the_game,u.x,u.y,cp.num,u) then exit;
 end else begin
  if(not can_see(s.the_game,u.x,u.y,cp.num,u))and(not can_see(s.the_game,u.x+1,u.y,cp.num,u))and(not can_see(s.the_game,u.x,u.y+1,cp.num,u))and(not can_see(s.the_game,u.x+1,u.y+1,cp.num,u)) then exit;
 end;

 if u.rot=16 then exit;

 true_water:=(get_map_pass(s.the_game,u.x,u.y)=P_WATER)and not cell_attrib(s.the_game,u.x,u.y,CA_SMALLPLAT) and not cell_attrib(s.the_game,u.x,u.y,CA_BRIDGE);
 revealed_stealth:=isa(s.the_game,u,a_stealth_or_underw) and not isa(s.the_game,u,a_stealthed);

 spr:=nil;
 //Base spr
 p:=round(eu.base_frames.x)+u.rot;
 if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
 if eu.spr_base.cnt<>0 then spr:=@eu.spr_base.sprc[p];

 //Base spr on water
 if true_water then begin
  if eu.water_base_frames.x<>-1 then begin
   p:=round(eu.water_base_frames.x)+u.rot;
   if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
   if eu.spr_base.cnt<>0 then spr:=@eu.spr_base.sprc[p];
  end;
 end;

 //Visible stealth on water
 if revealed_stealth and true_water then begin
  p:=p+8;
  if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
  if eu.spr_base.cnt<>0 then spr:=@eu.spr_base.sprc[p];
 end;

 //Base spr shoot
 if u.fires then if eu.firing_base_frames.x<>-1 then begin
  p:=round(eu.firing_base_frames.x)+u.rot;
  if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
  spr:=@eu.spr_base.sprc[p];
 end;

 //Base spr active/active on water
 if(u.isact and isa(s.the_game,u,a_building))or(u.isclrg)or(u.isbuild and(not isa(s.the_game,u,a_building)))and(get_map_pass(s.the_game,u.x,u.y)<>P_WATER) then begin
  if eu.active_frames.x<>-1 then begin
   k:=round((eu.active_frames.y-eu.active_frames.x)*frac(s.gct*2));
   p:=round(eu.active_frames.x)+k+u.rot;
   if p>eu.active_frames.y then p:=round(eu.active_frames.y);
   spr:=@eu.spr_base.sprc[p];
  end;
 end else if (u.isact and isa(s.the_game,u,a_building)) or u.isbuild and (get_map_pass(s.the_game,u.x,u.y)=P_WATER) then begin
  if eu.water_active_frames.x<>-1 then begin
   k:=round((eu.active_frames.y-eu.active_frames.x)*frac(s.gct*2));
   p:=round(eu.water_active_frames.x)+k+u.rot;
   if p>eu.water_active_frames.y then p:=round(eu.water_active_frames.y);
   spr:=@eu.spr_base.sprc[p];
  end;
 end else begin
 end;

 //Scale
 bor:=ord(isa(s.the_game,u,a_bor));
 if isa(s.the_game,u,a_building) then proc_con(s,map,u,eu,zoom,bor,true);

 //Shadow
 if s.cg.unit_shadows then if eu.spr_shadow.ex then begin
  k:=p;
  if isa(s.the_game,u,a_building)and(eu.gun_frames.x<>-1)then k:=k+u.grot+1;
  while k>=eu.spr_shadow.cnt do k:=k-eu.spr_shadow.cnt;
  xn:=round(((u.x*XCX+(u.mox+u.dmx*(1+3*ord(u.ptyp=pt_air)))*(1-bor)+XHCX*(u.siz+bor)-eu.spr_shadow.sprc[k].cx+u.alt{*ord(u.ptyp=pt_air)})/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy*(1+3*ord(u.ptyp=pt_air)))*(1-bor)+XHCX*(u.siz+bor)-eu.spr_shadow.sprc[k].cy+u.alt{*ord(u.ptyp=pt_air)})/zoom-map.mapt));
  if zoom< map.colorzoom then putsprszoomt8(s,@sdiscrp,@eu.spr_shadow.sprc[k],xn,yn);
 end;
 
 if u.typ='mining' then begin
  pl:=get_plr(s.the_game,u.own);
  if u.own<>-1 then p:=p+pl.info.clan*2;
  spr:=@eu.spr_base.sprc[p];
 end;

 //Base
 if spr<>nil then begin
  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor)-spr.cx)/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor)-spr.cy)/zoom-map.mapt));
  if zoom< map.colorzoom then                    putsprzoomt8x(s,@sdiscrp,spr,xn,yn,px);
  if zoom>=map.colorzoom then if u.level>=3 then putsprmczoomt8(s,@sdiscrp,spr,xn,yn,c);
                            //FIXME: Why let it draw invisible units at distance?
                            //Not M.A.X.-like.
                            //Blots out shapes of units with underlay
                            //Ne vidno form unitov
  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
  if not(((u.siz+bor=2)and(zoom<map.bld_zoom_2))or((u.siz+bor=1)and(zoom<map.bld_zoom_1)))then if u.isbuildfin and(u.own=cp.num)and(u.builds_cnt<>0)then begin
   drfrect8(@sdiscrp,xn-round(XHCX*(u.siz+bor)/zoom),yn-round(XHCX*(u.siz+bor)/zoom),xn+round(XHCX*(u.siz+bor)/zoom),yn+round(XHCX*(u.siz+bor)/zoom),31);
  end;
 end;
 if isa(s.the_game,u,a_building) then proc_con(s,map,u,eu,zoom,bor,false);

 //Base gun
 if eu.gun_frames.x<>-1 then if eu.spr_base.cnt<>0 then begin
  p:=round(eu.gun_frames.x)+u.grot;
  if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
  spr:=@eu.spr_base.sprc[p];

  if u.fires then if eu.firing_gun_frames.x<>-1 then if eu.spr_base.cnt<>0 then begin
   p:=round(eu.firing_gun_frames.x)+u.grot;
   if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
   spr:=@eu.spr_base.sprc[p];
  end;

  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor)-spr.cx)/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor)-spr.cy)/zoom-map.mapt));
  if zoom< map.colorzoom then                    putsprzoomt8x (s,@sdiscrp,spr,xn,yn,px);
  if zoom>=map.colorzoom then if u.level>=3 then putsprmczoomt8(s,@sdiscrp,spr,xn,yn,c);
 end;

 //Base animation
 if eu.animation_frames.x<>-1 then if eu.spr_base.cnt<>0 then begin
  k:=round((eu.animation_frames.y-eu.animation_frames.x)*frac(s.gct*eu.animation_frames.z));
  if isa(s.the_game,u,a_disabled) then k:=0;
  p:=round(eu.animation_frames.x)+k;
  if p>eu.animation_frames.y then p:=round(eu.animation_frames.y);
  spr:=@eu.spr_base.sprc[p];
  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor)-spr.cx)/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor)-spr.cy)/zoom-map.mapt));
  if zoom< map.colorzoom then                    putsprzoomt8x (s,@sdiscrp,spr,xn,yn,px);
  if zoom>=map.colorzoom then if u.level>=3 then putsprmczoomt8(s,@sdiscrp,spr,xn,yn,c);
 end;

 //Building note
 if((u.siz+bor=2)and(zoom<=map.bld_zoom_2))or((u.siz+bor=1)and(zoom<=map.bld_zoom_1)) then begin
  if((((u.isact and isa(s.the_game,u,a_building))or(not isa(s.the_game,u,a_building)))and u.isbuild)or u.isbuildfin)and(u.own=cp.num)and(u.builds_cnt<>0)then if eu.spr_base.cnt<>0 then begin
   xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
   yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
   //drfrect8(@sdiscrp,xn-17,yn-12,xn+14,yn+9,6);
   //drrect8(@sdiscrp,xn-17,yn-12,xn+14,yn+9,3);
   if s.clinfo.sopt.frame_btn[fb_build]=1 then begin
    if (u.builds[0].left_turns<10)and(u.builds[0].left_turns>0) then wrbgtxtcnt8(s.cg,@sdiscrp,xn,yn-8,stri(u.builds[0].left_turns),3);
    if u.builds[0].left_turns>=10 then wrbgtxtcnt8(s.cg,@sdiscrp,xn,yn-8,stri(u.builds[0].left_turns),3);
   end;
   if u.isbuildfin then wrbgtxtcnt8(s.cg,@sdiscrp,xn,yn-8,'OK',8);
  end;
 end;

 //Dozer note
 if s.clinfo.sopt.frame_btn[fb_build]=1 then if((u.siz+bor=2)and(zoom<map.bld_zoom_2))or((u.siz+bor=1)and(zoom<map.bld_zoom_1)) then begin
  if(isa(s.the_game,u,a_cleaner) and u.isclrg)and(u.own=cp.num) then if eu.spr_base.cnt<>0 then begin
   xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
   yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
   drfrect8(@sdiscrp,xn-17,yn-12,xn+14,yn+9,6);
   drrect8(@sdiscrp,xn-17,yn-12,xn+14,yn+9,3);
   wrbgtxtcnt8(s.cg,@sdiscrp,xn,yn-8,stri(u.clrturns),2);
  end;
 end;
  
 //Debug
 if isa(s.the_game,u,a_passes_res) then begin
  //xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl));
 // yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt));
  //wrtxtcnt8(@sdiscrp,xn,yn   ,'Dom='+stri(u.domain),3);
 end;
  
 //Debug
 if isa(s.the_game,u,a_solid_building) then begin
  //xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl))-XHCX;
  //yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt))-XHCX;
  {
  if isa(s.the_game,u,a_mining) then begin
   wrtxt8(@sdiscrp,xn,yn   ,stri(u.prod.now[RES_MAT])+'+'+stri(u.prod.pro[RES_MAT]*ord(u.isact))+'-'+stri(u.prod.dbt[RES_MAT])+'/'+stri(u.prod.num[RES_MAT]),0);
   s1:='';
   if u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT]>u.prod.num[RES_MAT] then
    s1:='+'+stri(u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT]-u.prod.num[RES_MAT]);
   if u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT]<u.prod.num[RES_MAT] then
    s1:='['+stri(u.prod.num[RES_MAT]-(u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT]))+']';
   wrtxt8(@sdiscrp,xn,yn+10,stri(min2i(u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT],u.prod.num[RES_MAT]))+' '+s1,0);
  end else begin
   if(u.prod.use[RES_MAT]*ord(u.isact)<>0)or(u.prod.dbt[RES_MAT]<>0)then
    wrtxt8(@sdiscrp,xn,yn   ,'-'+stri(u.prod.use[RES_MAT]*ord(u.isact))+'-'+stri(u.prod.dbt[RES_MAT]),0);
   if u.prod.num[RES_MAT]>0 then begin
    s1:='['+stri(u.prod.num[RES_MAT]-(u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT]))+']';
    wrtxt8(@sdiscrp,xn,yn+10,stri(min2i(u.prod.now[RES_MAT]+u.prod.pro[RES_MAT]-u.prod.use[RES_MAT]-u.prod.dbt[RES_MAT],u.prod.num[RES_MAT]))+' '+s1,0);
   end;
  end;
   }
  //wrtxt8(@sdiscrp,xn+20,yn   ,'P'+stri(u.prod.use[RES_POW]*ord(u.isact)),3);
  //wrtxt8(@sdiscrp,xn+20,yn+10,'P'+stri(u.prod.pro[RES_POW]*ord(u.isact)),3);
  //wrtxt8(@sdiscrp,xn+20,yn+20,'P'+stri(u.prod.dbt[RES_POW]),3);
   {
  wrtxt8(@sdiscrp,xn+40,yn   ,'G'+stri(u.prod.golduse*ord(u.isact)),3);
  wrtxt8(@sdiscrp,xn+40,yn+10,'G'+stri(u.prod.goldpro*ord(u.isact)),3);
  wrtxt8(@sdiscrp,xn+40,yn+20,'G'+stri(u.prod.golddbt),3);
  }
 end;
  
 {
 if u.triggered_auto_fire or u.afireip then begin
  xn:=gfx+round(((u.x*XCX+(u.mox+u.dmx)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapl))-XHCX;
  yn:=gfy+round(((u.y*XCX+(u.moy+u.dmy)*(1-bor)+XHCX*(u.siz+bor))/zoom-map.mapt))-XHCX;

  if u.triggered_auto_fire then wrtxt8(@sdiscrp,xn,yn   ,'AF',3);
  if u.afireip             then wrtxt8(@sdiscrp,xn,yn+10,'IP',3);
 end;
 }
 
 except stderr(s,'sdidraw_game','draw_one_unit');end;
end;  
//############################################################################//
procedure draw_one_anim(s:psdi_rec;map:pmap_window_rec;au:panim_unit_typ;zoom:double);
var px:pointer;
p,xn,yn,k:integer;
spr:ptypspr;
cp:pplrtyp; 
begin try
 if not au.used then exit;
 if au.animation_frames.x=-1 then exit;
 if au.spr=nil then exit;   
 if au.spr.cnt=0 then exit;   
 if zoom>=map.colorzoom then exit;              
 cp:=get_cur_plr(s.the_game);
 if cp=nil then exit;
 px:=get_player_palpx(s,cp.num);
 
 k:=round((au.animation_frames.y-au.animation_frames.x)*(s.gct-au.anim_timer)*au.animation_frames.z);
 p:=round(au.animation_frames.x)+k;
 if p>au.animation_frames.y then p:=round(au.animation_frames.y);
 spr:=@au.spr.sprc[p];

 xn:=round(((au.x*XCX+XHCX*au.siz-spr.cx)/zoom-map.mapl));
 yn:=round(((au.y*XCX+XHCX*au.siz-spr.cy)/zoom-map.mapt));
 putsprzoomt8x(s,@sdiscrp,spr,xn,yn,px);

 except stderr(s,'sdidraw_game','draw_one_anim_unit');end;
end;  
//############################################################################//
procedure anim_one_unit(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double);
var k:integer;
av:double;
unstealth:boolean;
cp:pplrtyp;   
begin try
 if u=nil then exit;
 if u.grp_db=-1 then exit;   
 if u.rot=16 then exit;
 cp:=get_cur_plr(s.the_game);   
 if cp=nil then exit;

 unstealth:=false;
 for k:=0 to get_plr_count(s.the_game)-1 do unstealth:=unstealth or(u.stealth_detected[k]>0);
 if u.own<>cp.num then unstealth:=u.stealth_detected[cp.num]>0;
 //Tremble in air and water
 if(u.ptyp>pt_landwater)or((u.ptyp=pt_landwater)and(get_map_pass(s.the_game,u.x,u.y)=P_WATER))then begin
  if(u.ptyp=pt_air)and(u.alt=0)then exit;
  if isa(s.the_game,u,a_stealth_or_underw) and(not unstealth)then exit;
  if(u.ptyp<>pt_air)and(get_map_pass(s.the_game,u.x,u.y)=P_COAST)then exit;
   
  u.wave_timer:=u.wave_timer+s.gdt;
  av:=0.5;
  if u.ptyp in[pt_landwater,pt_watercoast,pt_wateronly]then av:=1;
  if (u.ptyp=pt_air)then av:=0.1;
  if isa(s.the_game,u,a_building)and not isa(s.the_game,u,a_bomb) then av:=3;
  if cell_attrib(s.the_game,u.x,u.y,CA_SMALLPLAT) or cell_attrib(s.the_game,u.x,u.y,CA_BRIDGE) then av:=2;
  if u.wave_timer>=av then begin
   u.wave_timer:=0;
   u.wave_step:=u.wave_step+1;
   if(u.wave_step>=16)and(av>=0.9)then u.wave_step:=0;
   if(u.wave_step>=32)and(av<=0.2)then u.wave_step:=0;
   if av>=0.9 then begin u.dmx:=wave_shift_ship[u.wave_step][0];u.dmy:=wave_shift_ship[u.wave_step][1];end;
   if av<=0.2 then begin u.dmx:=wave_shift_plane[u.wave_step][0];u.dmy:=wave_shift_plane[u.wave_step][1];end;
  end;
 end;

 except stderr(s,'sdidraw_game','anim_one_unit');end;
end;    
//############################################################################//
procedure anim_one_anim(s:psdi_rec;map:pmap_window_rec;au:panim_unit_typ;zoom:double);
var  k:integer;
begin try
 if not au.used then exit;  
 if au.animation_frames.x=-1 then exit;
 if au.spr.cnt=0 then exit;   

 if au.anim_timer=-1 then au.anim_timer:=s.gct;
 k:=round((au.animation_frames.y-au.animation_frames.x)*(s.gct-au.anim_timer)*au.animation_frames.z);
 if k>(au.animation_frames.y-au.animation_frames.x) then au.used:=false;
  
 except stderr(s,'sdidraw_game','anim_one_anim_unit');end;
end;
//############################################################################//
procedure draw_units_selection(s:psdi_rec;map:pmap_window_rec;zoom:double);
var xn,yn,os:integer;  
u:ptypunits;  
cl1,cl2:byte;
begin try 
 u:=get_sel_unit(s.the_game); 
 if unav(u) then if ingf(s,u) then if s.cur_menu=MG_NOMENU then begin
  xn:=round(((u.x*XCX+(u.mox+u.dmx)*(1-ord(u.cur_siz=2)))/zoom-map.mapl));
  yn:=round(((u.y*XCX+(u.moy+u.dmy)*(1-ord(u.cur_siz=2)))/zoom-map.mapt));
  if round(s.gct*100) mod 50>=25 then begin
   cl1:=0;
   cl2:=255;
  end else begin    
   cl2:=0;
   cl1:=255;
  end;
  os:=round((XCX/4)/zoom);
  if (u.siz=2)or(u.cur_siz=2) then os:=round((2*XCX/4)/zoom);
  if (xn>=0)and(yn>=0)and(xn+os*4<scrx)and(yn+os*4<scry)then begin
   drrect8(@sdiscrp,xn  ,yn  ,xn+os,yn   ,cl1);
   drrect8(@sdiscrp,xn  ,yn  ,xn+os,yn   ,cl1);
   drrect8(@sdiscrp,xn+1,yn+1,xn+os,yn+1 ,cl2);
   drrect8(@sdiscrp,xn+2,yn+2,xn+os,yn+2 ,cl1);
         
   drrect8(@sdiscrp,xn  ,yn  ,xn   ,yn+os,cl1);
   drrect8(@sdiscrp,xn+1,yn+1,xn+1 ,yn+os,cl2);
   drrect8(@sdiscrp,xn+2,yn+2,xn+2 ,yn+os,cl1);

   drrect8(@sdiscrp,xn+os*4  ,yn  ,xn+os*4-os,yn  ,cl1);
   drrect8(@sdiscrp,xn+os*4-1,yn+1,xn+os*4-os,yn+1,cl2);
   drrect8(@sdiscrp,xn+os*4-2,yn+2,xn+os*4-os,yn+2,cl1);

   drrect8(@sdiscrp,xn+os*4  ,yn  ,xn+os*4  ,yn+os,cl1);
   drrect8(@sdiscrp,xn+os*4-1,yn+1,xn+os*4-1,yn+os,cl2);
   drrect8(@sdiscrp,xn+os*4-2,yn+2,xn+os*4-2,yn+os,cl1);

   drrect8(@sdiscrp,xn  ,yn+os*4  ,xn+os,yn+os*4  ,cl1);
   drrect8(@sdiscrp,xn+1,yn+os*4-1,xn+os,yn+os*4-1,cl2);
   drrect8(@sdiscrp,xn+2,yn+os*4-2,xn+os,yn+os*4-2,cl1);

   drrect8(@sdiscrp,xn  ,yn+os*4  ,xn  ,yn+os*4-os,cl1);
   drrect8(@sdiscrp,xn+1,yn+os*4-1,xn+1,yn+os*4-os,cl2);
   drrect8(@sdiscrp,xn+2,yn+os*4-2,xn+2,yn+os*4-os,cl1);

   drrect8(@sdiscrp,xn+os*4  ,yn+os*4  ,xn+os*4-os,yn+os*4  ,cl1);
   drrect8(@sdiscrp,xn+os*4-1,yn+os*4-1,xn+os*4-os,yn+os*4-1,cl2);
   drrect8(@sdiscrp,xn+os*4-2,yn+os*4-2,xn+os*4-os,yn+os*4-2,cl1);

   drrect8(@sdiscrp,xn+os*4  ,yn+os*4  ,xn+os*4  ,yn+os*4-os,cl1);
   drrect8(@sdiscrp,xn+os*4-1,yn+os*4-1,xn+os*4-1,yn+os*4-os,cl2);
   drrect8(@sdiscrp,xn+os*4-2,yn+os*4-2,xn+os*4-2,yn+os*4-os,cl1);       
  end;
 end;  
 
 except stderr(s,'sdidraw_game','draw_units_selection');end;
end;          
//############################################################################//
procedure draw_unit_tracks(s:psdi_rec;map:pmap_window_rec;zoom:double);
var i,xn,yn:integer;
cp:pplrtyp;
begin try         
 if not s.cg.grapu[GRU_TRACKS].ex then exit;
 cp:=get_cur_plr(s.the_game);
 for i:=0 to length(s.trk)-1 do if s.trk[i].t>0 then begin
  xn:=s.trk[i].x;
  yn:=s.trk[i].y;
  if not can_see(s.the_game,xn,yn,cp.num,nil) then continue;
  xn:=round((xn*XCX+s.trk[i].dx)/zoom-map.mapl);
  yn:=round((yn*XCX+s.trk[i].dy)/zoom-map.mapt);
  if s.trk[i].t>50 then putsprzoomt8xtra(s,@sdiscrp,@s.cg.grapu[GRU_TRACKS].sprc[s.trk[i].d],xn,yn,@s.colors.palpx[0])
                   else putsprzoomt8    (s,@sdiscrp,@s.cg.grapu[GRU_TRACKS].sprc[s.trk[i].d],xn,yn);
 end;            
 except stderr(s,'sdidraw_game','draw_unit_tracks');end;
end;      
//############################################################################//
procedure draw_comments(s:psdi_rec;map:pmap_window_rec;zoom:double);
var i,xn,yn,xs:integer;
pl:pplrtyp;
begin try    
 pl:=get_cur_plr(s.the_game);   
 for i:=0 to length(pl.comments)-1 do case pl.comments[i].typ of
  0:;
  1:begin
   xn:=round(pl.comments[i].x*XCX/zoom-map.mapl);
   yn:=round(pl.comments[i].y*XCX/zoom-map.mapt);
   xs:=round(XCX/zoom);
   if xn>=scrx then continue;
   if yn>=scry then continue;
   if xn+xs<=0 then continue;
   if yn+xs<=0 then continue;
   puttran8  (s.cg,@sdiscrp,xn  ,yn  ,xs,xs,0);
   wrtxtxbox8(s.cg,@sdiscrp,xn+2,yn+2,xs-4,xs-4,pl.comments[i].text,0);
  end;
 end;            
 except stderr(s,'sdidraw_game','draw_comments');end;
end;  
//############################################################################//
procedure draw_unit_storageutil(s:psdi_rec;map:pmap_window_rec;u:ptypunits;zoom:double);
var i,j,xn,yn:integer;
mods:pmods_rec;
begin try 
 mods:=get_mods(s.the_game);
 if u.siz=1 then for i:=u.x-1 to u.x+1 do for j:=u.y-1 to u.y+1 do if not((i=u.x)and(j=u.y))then begin
  if unstore_test_pass(s.the_game,i,j,get_unit(s.the_game,mods.exit_storage_unit)) then begin
   xn:=round(i*XCX/zoom-map.mapl);
   yn:=round(j*XCX/zoom-map.mapt);
   putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_BUILDMARK].sprc[round(s.gct*8) mod 5],xn,yn);
  end;
 end;
 if u.siz=2 then for i:=u.x-1 to u.x+2 do for j:=u.y-1 to u.y+2 do if not inrects(i,j,u.x,u.y,1,1)then begin
  if unstore_test_pass(s.the_game,i,j,get_unit(s.the_game,mods.exit_storage_unit)) then begin
   xn:=round(i*XCX/zoom-map.mapl);
   yn:=round(j*XCX/zoom-map.mapt);
   putsprzoomt8(s,@sdiscrp,@s.cg.grapu[GRU_BUILDMARK].sprc[round(s.gct*8) mod 5],xn,yn);
  end;
 end;      
 except stderr(s,'sdidraw_game','draw_unit_storageutil');end;
end;
//############################################################################//
//Units drawing controller
procedure draw_units(s:psdi_rec;map:pmap_window_rec;zoom:double);
var n,i:integer;
u:ptypunits;
cp:pplrtyp;
mods:pmods_rec;
begin try
 cp:=get_cur_plr(s.the_game);
 mods:=get_mods(s.the_game);

 //Tracks
 draw_unit_tracks(s,map,zoom);
         
 //Explosion and service animation handling
 for i:=0 to get_units_count(s.the_game)-1 do if unav(s.the_game,i) then anim_one_unit(s,map,get_unit(s.the_game,i),zoom);
                  
 //Draw units
 for n:=0 to 6 do for i:=0 to get_units_count(s.the_game)-1 do if unav(s.the_game,i) then begin
  u:=get_unit(s.the_game,i);
  if ingf(s,u) and(u.level=n)then draw_one_unit(s,map,u,zoom);
 end;   
  
 //Draw anim units
 for i:=0 to length(s.anim_units)-1 do if s.anim_units[i].used then begin
  anim_one_anim(s,map,@s.anim_units[i],zoom);
  if s.anim_units[i].used then if ingf_xys(s,s.anim_units[i].x,s.anim_units[i].y,s.anim_units[i].siz) then draw_one_anim(s,map,@s.anim_units[i],zoom);
 end;
    
 u:=get_sel_unit(s.the_game);  
 if unav(u) then begin
  if not plr_are_enemies(s.the_game,u.own,cp.num) then begin
   //Path
   if u.isstd then draw_unit_path(s,map,u,zoom);
   //Build Path
   if u.isbuild and not isa(s.the_game,u,a_building) and (u.builds_cnt>0) then draw_build_path(s,map,u,zoom);
  end;

  //Storage exit
  if mods.store_exit then if unave(s.the_game,mods.exit_storage_unit) then draw_unit_storageutil(s,map,u,zoom);
   
  //Construction
  draw_unit_buildstuff(s,s.cur_map_x,s.cur_map_y,map,u,zoom);    
 end;
      
 //Selector
 draw_units_selection(s,map,zoom);

 //Comments
 if s.show_comments then draw_comments(s,map,zoom);
     
 except stderr(s,'sdidraw_game','draw_units');end;
end;
//############################################################################//
begin
end.
//############################################################################//
