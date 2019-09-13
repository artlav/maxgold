//############################################################################//
unit sdidraw_int;
interface
uses asys,maths,strval,strtool,grph,graph8
,sdigrtools,mgrecs,mgl_common,mgl_attr,mgl_tests,mgl_rmnu,mgl_land,sdirecs,sdiauxi,sdigui,sdicalcs,sdidraw_game,sdimenu,sdi_int_elem;
//############################################################################//     
procedure draw_debug_unit(s:psdi_rec;dst:ptypspr;xns,yns:integer;map:pmap_window_rec);
procedure draw_landing_units(s:psdi_rec;dst:ptypspr;xns,yns:integer;map:pmap_window_rec);

procedure draw_framebase_slim(s:psdi_rec;dst:ptypspr);
procedure draw_framedyn_slim(s:psdi_rec;map:pmap_window_rec;dst:ptypspr;mx,my,xns,yns:integer);
procedure draw_now_loading(s:psdi_rec;dst:ptypspr);

procedure draw_menus(s:psdi_rec;dst:ptypspr);
//############################################################################//
implementation
//############################################################################//
procedure draw_background(s:psdi_rec;dst:ptypspr);
begin try
 if s.bkgr_image<length(s.cg.scaled_bkgr) then if s.cg.scaled_bkgr[s.bkgr_image]<>nil then begin
  drfrectx8(dst,0,0,scrx,scry,0);
  putspr8(dst,s.cg.scaled_bkgr[s.bkgr_image],dst.xs div 2-s.cg.scaled_bkgr[s.bkgr_image].xs div 2,dst.ys div 2-s.cg.scaled_bkgr[s.bkgr_image].ys div 2);
 end;
 except stderr(s,'sdidraw_int','draw_background');end;
end;
//############################################################################//
//Static part of the frame
procedure draw_framebase_slim(s:psdi_rec;dst:ptypspr);
begin try
 if not s.frameev then exit;
 s.frameev:=false;

 if (s.state<>CST_THEGAME)or s.now_loading then draw_background(s,dst);

 except stderr(s,'sdidraw_int','draw_framebase_slim');end;
end;
//############################################################################//
procedure draw_clan(s:psdi_rec;dst:ptypspr;x,y:integer);
var c,dx,dy:integer;
cp:pplrtyp;
st:string;
begin try
 cp:=get_cur_plr(s.the_game);
 c:=cp.info.clan+1;

 dx:=s.cg.clns[c].xs+10;
 dy:=s.cg.clns[c].ys+10;
 drfrectx8(dst,x+64-dx div 2,y+64-dy div 2-5,dx,dy,178);
 putsprt8(dst,s.cg.clns[c],x+64-s.cg.clns[c].xs div 2,y+64-s.cg.clns[c].ys div 2-10);
 wrtxtcnt8(s.cg,dst,x+64,y+4,clannames[c],4);

 st:=s.the_game.info.game_name;
 wrtxtcnt8(s.cg,dst,x+64,y+110,st,0);
 st:=po('Credit')+' '+stri(cp.gold);
 wrtxtcnt8(s.cg,dst,x+64,y+120,st,0);

 except stderr(s,'sdidraw_int','draw_clan');end;
end;
//############################################################################//
procedure draw_db_unit(s:psdi_rec;dst:ptypspr;map:pmap_window_rec;dn,x,y:integer;is_blink:boolean=true;has_platform:boolean=false);
var xn,yn,p,c:integer;
ud:ptypunitsdb;
spr:ptypspr;
zoom:double;
eu:ptypeunitsdb;
cp:pplrtyp;
begin try
 ud:=get_unitsdb(s.the_game,dn);
 if ud=nil then exit;
 cp:=get_cur_plr(s.the_game);

 spr:=nil;
 p:=0;
 if is_blink and(round(s.gct*100) mod 50>25)then exit;
 c:=4;
 if has_platform then begin
  if get_map_pass(s.the_game,x,y)=P_OBSTACLE then c:=1;
 end else if not test_pass_db(s.the_game,x,y,dn,nil) then c:=1;
 if isadb(s.the_game,ud,a_bld_on_plate) then begin
  if ud.siz=1 then begin if s.auxun[UN_SMLPLATE]<>nil then draw_db_unit(s,dst,map,s.auxun[UN_SMLPLATE].udb_num,x,y,false,has_platform);end
              else begin if s.auxun[UN_BIGPLATE]<>nil then draw_db_unit(s,dst,map,s.auxun[UN_BIGPLATE].udb_num,x,y,false,has_platform);end;
 end;

 eu:=get_edb(s,ud.typ);
 if eu=nil then exit;

 p:=p+round(eu.base_frames.x);
 if ud.typ='mining' then p:=p+cp.info.clan*2;
 if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
 if eu.spr_base.cnt<>0 then spr:=@eu.spr_base.sprc[p];
 if spr=nil then exit;
 zoom:=s.clinfo.sopt.zoom;
 xn:=round(((x*XCX+XHCX*ud.siz-spr.cx)/zoom-map.mapl));
 yn:=round(((y*XCX+XHCX*ud.siz-spr.cy)/zoom-map.mapt));
 //base
 if (c=1)or((zoom>=map.colorzoom)and(ud.level>=3)) then putsprmczoomt8(s,dst,spr,xn,yn,c)
                                                   else putsprzoomt8x(s,dst,spr,xn,yn,@s.colors.al_palpx);
 //gun
 if eu.gun_frames.x<>-1 then if eu.spr_base.cnt<>0 then begin
  p:=round(eu.gun_frames.x);
  if p>=eu.spr_base.cnt then p:=eu.spr_base.cnt-1;
  spr:=@eu.spr_base.sprc[p];
  if spr=nil then exit;
  xn:=round(((x*XCX+XHCX*ud.siz-spr.cx)/zoom-map.mapl));
  yn:=round(((y*XCX+XHCX*ud.siz-spr.cy)/zoom-map.mapt));
  if (c=1)or((zoom>=map.colorzoom)and(ud.level>=3)) then putsprmczoomt8(s,dst,spr,xn,yn,c)
                                                    else putsprzoomt8x (s,dst,spr,xn,yn,@s.colors.al_palpx);
 end;

 except stderr(s,'sdidraw_int','draw_db_unit');end;
end;
//############################################################################//
procedure draw_debug_unit(s:psdi_rec;dst:ptypspr;xns,yns:integer;map:pmap_window_rec);
begin
 draw_db_unit(s,dst,map,s.debug_placed_unit,xns,yns);
end;
//############################################################################//
procedure draw_landing_units_nml(s:psdi_rec;dst:ptypspr;xns,yns:integer;map:pmap_window_rec);
var dn,dn_plat:ptypeunitsdb;
j,x,y,px,py,d,r,n:integer;
is_ok:boolean;
begin try
 dn_plat:=get_edb(s,'plat');

 is_ok:=landing_pass_test(s.the_game,xns-1,yns-1,xns+1,yns+1,x);
 if dn_plat<>nil then begin
  for x:=-3 to 3 do
   for y:=-2 to 3 do
    if(get_map_pass(s.the_game,xns+x,yns+y)=P_WATER)or(get_map_pass(s.the_game,xns+x,yns+y)=P_COAST)then
     draw_db_unit(s,dst,map,dn_plat.udb_num,xns+x,yns+y,false);
 end;

 dn:=s.auxun[UN_MINING];
 if dn<>nil then draw_db_unit(s,dst,map,dn.udb_num,xns,yns,not is_ok,is_ok);

 dn:=get_edb(s,'powergen');
 if dn<>nil then draw_db_unit(s,dst,map,dn.udb_num,xns-1,yns+1,not is_ok,is_ok);

 px:=xns-1;py:=yns-1;d:=0;r:=2;n:=0;
 for j:=0 to plr_begin.bgncnt-1 do begin
  dn:=get_edb(s,plr_begin.bgn[j].typ);
  if dn=nil then continue;
  while(get_map_pass(s.the_game,px,py)=P_OBSTACLE)or (not inrm(s.the_game,px,py))do begin
   case d of
    0:begin px:=px+1; py:=py+0;end;
    1:begin px:=px+0; py:=py+1;end;
    2:begin px:=px-1; py:=py+0;end;
    3:begin px:=px+0; py:=py-1;end;
   end;
   n:=n+1;
   if n>r then begin
    n:=0;d:=d+1;
    if d=2 then r:=r+1;
    if d>=4 then d:=0;
    if d=0 then r:=r+1;
   end;
  end;

  if inrm(s.the_game,px,py) then begin

   if dn_plat<>nil then
    if((get_map_pass(s.the_game,px,py)=P_WATER)or(get_map_pass(s.the_game,px,py)=P_COAST))then
     draw_db_unit(s,dst,map,dn_plat.udb_num,px,py,false);

   draw_db_unit(s,dst,map,dn.udb_num,px,py,not is_ok,is_ok);
  end;
  case d of
   0:begin px:=px+1; py:=py+0;end;
   1:begin px:=px+0; py:=py+1;end;
   2:begin px:=px-1; py:=py+0;end;
   3:begin px:=px+0; py:=py-1;end;
  end;
  n:=n+1;
  if n>r then begin
   n:=0;d:=d+1;
   if d=2 then r:=r+1;
   if d>=4 then d:=0;
   if d=0 then r:=r+1;
  end;
 end;

 except stderr(s,'sdidraw_int','draw_landing_units_nml');end;
end;
//############################################################################//
procedure draw_landing_units_direct(s:psdi_rec;dst:ptypspr;xns,yns:integer;map:pmap_window_rec);
var dn:ptypeunitsdb;
ud:ptypunitsdb;
i,x,y,px,py,xn,yn,sz:integer;
begin try
 x:=xns;
 y:=yns;
 if plr_begin.lndx<>-1 then begin
  x:=plr_begin.lndx;
  y:=plr_begin.lndy;
 end;

 for i:=0 to plr_begin.bgncnt-1 do begin
  dn:=get_edb(s,plr_begin.bgn[i].typ);
  if dn=nil then continue;
  ud:=get_unitsdb(s.the_game,dn.udb_num);
  if ud=nil then continue;

  px:=x+plr_begin.bgn[i].x;
  py:=y+plr_begin.bgn[i].y;

  //Units from the landing set
  if inrm(s.the_game,px,py) then begin
   draw_db_unit(s,dst,map,dn.udb_num,px,py,false,true);
   if i=plr_land.sel_unit then begin
    xn:=round(((px*XCX)/s.clinfo.sopt.zoom-map.mapl));
    yn:=round(((py*XCX)/s.clinfo.sopt.zoom-map.mapt));
    sz:=round(ud.siz*XCX/s.clinfo.sopt.zoom);
    draw_unitframe(dst,xn-2,yn-2,xn+sz,yn+sz,255,false);
   end;
  end;
 end;

 //Currently placed unit
 if inrm(s.the_game,xns,yns) and (plr_land.sel_db_unit<>-1) then begin
  draw_db_unit(s,dst,map,plr_land.sel_db_unit,xns,yns);
 end;

 except stderr(s,'sdidraw_int','draw_landing_units_direct');end;
end;
//############################################################################//
procedure draw_landing_units(s:psdi_rec;dst:ptypspr;xns,yns:integer;map:pmap_window_rec);
begin
 if s.the_game.info.rules.direct_land then draw_landing_units_direct(s,dst,xns,yns,map)
                                      else draw_landing_units_nml(s,dst,xns,yns,map);
end;
//############################################################################//
procedure draw_frame_mmap(s:psdi_rec;map:pmap_window_rec;dst:ptypspr);
var mmx,mmy,dx,dy:integer;
xx,yy:double;
rcleft,rcTop,rcright,rcbottom:integer;
begin try
 mmx:=gcrx(s.cg.intf.mmap);
 mmy:=gcry(s.cg.intf.mmap);
 drrectx8(dst,mmx-1,mmy-1,112+2,112+2,line_color);
 draw_mmap(s,@s.mainmap,mmx,mmy);
 putspr8(dst,@s.minimap_plane,mmx,mmy);

 xx:=112/s.mapx;
 yy:=112/s.mapy;
 if xx<yy then yy:=xx else xx:=yy;
 if(xx>1)and(yy>1)then begin xx:=1;yy:=1;end;
 dx:=round(112-s.mapx*xx)div 2;
 dy:=round(112-s.mapy*yy)div 2;
 rcleft  :=mmx   +round(map.ssx*xx)+dx;
 rctop   :=mmy   +round(map.ssy*yy)+dy;
 rcright :=rcleft+round(s.mainmap.gfcx*xx);
 rcbottom:=rcTop +round(s.mainmap.gfcy*yy);
 if rcleft  <mmx       then rcleft  :=mmx;
 if rctop   <mmy+1     then rctop   :=mmy+1;
 if rcright >mmx+112-1 then rcright :=mmx+112-1;
 if rcbottom>mmy+112   then rcbottom:=mmy+112;
 drrect8(dst,rcleft,rctop,rcright,rcbottom,1);

 except stderr(s,'sdidraw_int','draw_frame_mmap');end;
end;
//############################################################################//
procedure draw_video_rect(s:psdi_rec;dst:ptypspr;x,y:integer);
var su:ptypunits;
g,frame:integer;
ud:ptypunitsdb;
edb:ptypeunitsdb;
begin try
 su:=get_sel_unit(s.the_game);
 drrectx8(dst,x-1,y-1,128+2,128+2,line_color);
 if unav(su) and(s.cur_menu<>MG_DEBUG)and(not s.debug_placing)then begin
  g:=su.grp_db;
  edb:=nil;
  if g<>-1 then edb:=s.eunitsdb[g];
  if edb<>nil then begin
   if edb.video.used then begin
    frame:=(round(s.gct*1000)div edb.video.dtms)mod edb.video.frmc;
    putmov8(dst,@edb.video,x,y,frame);
   end else puttran8(s.cg,dst,x,y,128,128,0);
  end  else puttran8(s.cg,dst,x,y,128,128,0);
  wrtxt8(s.cg,dst,x+3,y+3,unit_mk(su)+unit_name(s.the_game,su)+base_mk(s.the_game,su,true),17);
 end else if s.debug_placing then begin
  ud:=get_unitsdb(s.the_game,s.debug_placed_unit);
  if ud=nil then exit;
  edb:=get_edb(s,ud.typ);

  if edb<>nil then begin
   if edb.video.used then begin
    frame:=(round(s.gct*1000)div edb.video.dtms)mod edb.video.frmc;
    putmov8(dst,@edb.video,x,y,frame);
   end else puttran8(s.cg,dst,x,y,128,128,0);
  end  else puttran8(s.cg,dst,x,y,128,128,0);

  if lrus then wrtxt8(s.cg,dst,x+3,y+3,ud.name_rus,2)
          else wrtxt8(s.cg,dst,x+3,y+3,ud.name_eng,2);
 end else begin
  puttran8(s.cg,dst,x,y,128,128,0);
  draw_clan(s,dst,x,y);
 end;

 except stderr(s,'sdidraw_int','draw_video_rect');end;
end;
//############################################################################//
//display unit info under cursor
//Name, coordinates
//And units in landing
procedure draw_cursor_info(s:psdi_rec;dst:ptypspr;xns,yns:integer);
var tu:ptypunits;
cp:pplrtyp;
i:integer;
st:string;
xp,yp,xs,ys:integer;
begin try
 if not inrm(s.the_game,xns,yns) then exit;
 cp:=get_cur_plr(s.the_game);

 xp:=gcrx(s.cg.intf.coord);
 yp:=gcry(s.cg.intf.coord);
 xs:=gcrxs(s.cg.intf.coord);
 ys:=gcrys(s.cg.intf.coord);
 tran_rect8(s.cg,dst,xp,yp,xs,ys,0);

 //get_unu_length takes care of bounds
 for i:=0 to get_unu_length(s.the_game,xns,yns)-1 do begin
  tu:=get_unu(s.the_game,xns,yns,i);
  if unav(tu) then if can_see(s.the_game,xns,yns,cp.num,tu)and (not isa(s.the_game,tu,a_unselectable)) then begin
   st:=unit_mk(tu)+unit_name(s.the_game,tu)+' '+base_mk(s.the_game,tu);
   wrtxtcnt8(s.cg,dst,xp+xs div 2,yp+5,st,0);
   break;
  end;
 end;

 if(xns>=0)and(yns>=0)and(xns<s.mapx)and(yns<s.mapy) then begin
  st:=trimsl(stri(xns),3,'0')+':'+trimsl(stri(yns),3,'0');
  wrtxtcnt8(s.cg,dst,xp+xs div 2,yp+18,st,0);
 end;

 except stderr(s,'sdidraw_int','draw_cursor_info');end;
end;
//############################################################################//
//Dynamic part of the frame
procedure draw_framedyn_slim(s:psdi_rec;map:pmap_window_rec;dst:ptypspr;mx,my,xns,yns:integer);
//var i:integer;
{s1,s2:string;
rcleft,rcTop,rcright,rcbottom,dx,dy,g:integer;
i,mmx,mmy:integer;
d:single;
xx,yy:double;
su:ptypunits;
}
//tu:ptypunits;
//cp:pplrtyp;
begin try
 if s.now_loading then exit;

 draw_frame_mmap(s,map,dst);
 draw_video_rect(s,dst,gcrx(s.cg.intf.uview),gcry(s.cg.intf.uview));

 //cp:=get_cur_plr(s.the_game);
 if s.cur_menu=MG_NOMENU then begin
  draw_cursor_info(s,dst,xns,yns);
  {
  //display stored camera position
  if intf.stored_pos.sx>intf.stored_pos.sy then begin d:=intf.stored_pos.sx/MAX_PRESEL;dx:=round(d);dy:=intf.stored_pos.sy;end
                                           else begin d:=intf.stored_pos.sy/MAX_PRESEL;dx:=intf.stored_pos.sx;dy:=round(d);end;
  for i:=0 to MAX_CAMPOS-1 do begin
   if cp.clinfo.cam_pos[i].x<>-1 then g:=5 else g:=4;
   if intf.stored_pos.sx> intf.stored_pos.sy then begin
    rcLeft:=gcrx(intf.stored_pos)+round(i*d);
    rcTop:=gcry(intf.stored_pos);
   end else begin
    rcLeft:=gcrx(intf.stored_pos);
    rcTop:=gcry(intf.stored_pos)+round(i*d);
   end;
   if intf.trans then drfrect8(dst,rcLeft+1,rcTop+1,rcLeft+dx-1,rcTop+dy-1,maxg_nearest_in_thepal(tcrgb(20,20,20)));
   wrtxtcnt8(s.cg,dst,rcLeft+(dx div 2),rcTop+(dy div 2),'F'+stri(i+5),g);
  end;
  }
 end;

 except stderr(s,'sdidraw_int','draw_framedyn_slim');end;
end;
//############################################################################//
//Loading screen
procedure draw_now_loading(s:psdi_rec;dst:ptypspr);
var xn,yn,i,xs,ys,bar_hei,middle,step:integer;
begin try
 if length(s.cg.grap)=0 then exit;
 bar_hei:=12;
 step:=10;
 middle:=8+(LD_CNT-1)*step;
 xs:=320;
 ys:=2*bar_hei+middle+4;
 xn:=(dst.xs div 2)-xs div 2;
 yn:=(dst.ys div 2)-ys div 2;

 drfrectx8(dst,xn  ,yn  ,xs-1,ys-1,maxg_nearest_in_thepal(tcrgb(8,56,54)));
 drfrectx8(dst,xn+1,yn+1,xs-1,ys-1,maxg_nearest_in_thepal(tcrgb(8,56,54)));

 drrectx8(dst,xn+1,yn+1,          xs-1,ys-1          ,maxg_nearest_in_thepal(tcrgb(0,0,0)));
 drrectx8(dst,xn+1,yn+1+bar_hei+1,xs-1,ys-2*bar_hei-3,maxg_nearest_in_thepal(tcrgb(0,0,0)));

 drrectx8(dst,xn,yn,          xs-1,ys-1          ,maxg_nearest_in_thepal(tcrgb(128,124,116)));
 drrectx8(dst,xn,yn+bar_hei+1,xs-1,ys-2*bar_hei-3,maxg_nearest_in_thepal(tcrgb(128,124,116)));

 wrtxtcnt8(s.cg,dst,xn+xs div 2,yn+2+(bar_hei-8) div 2,s.load_box_str[0],4);
 for i:=1 to LD_CNT-1 do wrtxt8(s.cg,dst,xn+6,yn+bar_hei+2+6+(i-1)*step,s.load_box_str[i],4);
 drfrectx8(dst,xn+1,yn+ys-bar_hei-2,round((xs-2)*s.load_bar_pos),bar_hei,maxg_nearest_in_thepal(tcrgb(128,124,116)));

 except stderr(s,'sdidraw_int','draw_now_loading');end;
end;
//############################################################################//
procedure draw_rmnu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,xs,ys,tyo:integer;
u:ptypunits;
mods:pmods_rec;
begin try
 mods:=get_mods(s.the_game);

 u:=get_sel_unit(s.the_game);
 if not unav(u) then exit;

 xn:=gcrx(s.cg.intf.rmnu);
 yn:=gcry(s.cg.intf.rmnu);
 rmnu_sizes(s.cg,xs,ys,tyo);

 for i:=0 to r_menu.cnt-1 do begin
  case r_menu.fnc[i].func of
   RMNU_PUT_MINES:s.rmnu_state[i]:=ord(u.is_bomb_placing);
   RMNU_GET_MINES:s.rmnu_state[i]:=ord(u.is_bomb_removing);
   RMNU_SENTRY   :s.rmnu_state[i]:=ord(u.is_sentry);
   RMNU_STEAL    :s.rmnu_state[i]:=ord(mods.steal_command);
   RMNU_DISABLE  :s.rmnu_state[i]:=ord(mods.disabe_command);
   RMNU_ENTER    :s.rmnu_state[i]:=ord(mods.enter_command);
   RMNU_MOVE     :s.rmnu_state[i]:=ord(mods.move_command);
   RMNU_LOAD     :s.rmnu_state[i]:=ord(mods.fetch_command);
   RMNU_XFER     :s.rmnu_state[i]:=ord(mods.xfer);
   RMNU_REFUEL   :s.rmnu_state[i]:=ord(mods.refuel);
   RMNU_ATTACK   :s.rmnu_state[i]:=ord(mods.attack_command);
   RMNU_RELOAD   :s.rmnu_state[i]:=ord(mods.reload);
   RMNU_GIVE_2   :s.rmnu_state[i]:=ord(mods.give_two);
   RMNU_REPAIR   :s.rmnu_state[i]:=ord(mods.repair);
  end;

  tran_rect8(s.cg,dst,xn,yn+i*ys,xs,ys,0);
  wrtxtcntmg8(s.cg,dst,xn+xs div 2,yn+i*ys+tyo,r_menu.fnc[i].nam,s.rmnu_state[i]+19);
 end;

 except stderr(s,'sdidraw_int','draw_rmnu');end;
end;
//############################################################################//
procedure draw_menus(s:psdi_rec;dst:ptypspr);
var xn,yn:integer;
begin try
 calc_menuframe_pos(s.cur_menu,xn,yn);

 //Menus
 if not draw_menu_by_id(s,s.cur_menu,dst,xn,yn) then begin
  if s.state=CST_THEGAME then draw_rmnu(s,dst,xn,yn);
 end;

 //Update draw
 s.frame_map_ev:=false;
 s.frame_mmap_ev:=false;

 except stderr(s,'sdidraw_int','draw_menus');end;
end;
//############################################################################//
begin
end.
//############################################################################//
