//############################################################################//
//MaxGold SDI client main
//############################################################################//
unit sdi_root;
interface
uses asys,grph,maths,strval,graph8
,mgrecs,mgl_common,mgl_attr,mgl_tests,mgl_rmnu,mgl_scan,mgl_unu
,sdirecs,sdiauxi,sdigrtools,sdicalcs,sdigui,sdiovermind,sdi_int_elem,sdidraw_int,sdidraw_game,sdisound,sdigrinit
,sdikeyinput,sdimousedwn,sdimouseup
,sds_rec
,sdi_rec;
//############################################################################// 
procedure maxg_sdi_main(s:psdi_rec;mx,my:integer;ct,dt:double);
procedure maxg_sdi_event(s:psdi_rec;evt,x,y:integer;key,shift:dword);
//############################################################################//
implementation
//############################################################################//
procedure getcur(s:psdi_rec;dst:ptypspr;x,y,xs,ys:integer);
var xx,yy,xxs:integer;
d:pbytea;
begin try
 d:=dst.srf;
 xxs:=dst.xs;
 if x<0 then begin xs:=xs+x; x:=0; end;
 if y<0 then begin ys:=ys+y; y:=0; end;
 if x+xs>=dst.xs then begin xs:=dst.xs-x; end;
 if y+ys>=dst.ys then begin ys:=dst.ys-y; end;
 if(length(s.prcur)<(xs*ys))then setlength(s.prcur,xs*ys);
 for yy:=0 to ys-1 do for xx:=0 to xs-1 do s.prcur[xx+yy*xs]:=d[(x+xx)+(y+yy)*xxs];
 s.prcx:=x;
 s.prcy:=y;
 s.prcxs:=xs;
 s.prcys:=ys;
 except stderr(s,'sdimaxg_main','getcur');end;
end;
//############################################################################//
procedure retcur(s:psdi_rec;dst:ptypspr);
var xx,yy,xxs:integer;
d:pbytea;
begin try
 d:=dst.srf;
 xxs:=dst.xs;
 if length(s.prcur)<(s.prcxs*s.prcys) then exit;
 for yy:=0 to s.prcys-1 do if (s.prcy+yy)<scry then for xx:=0 to s.prcxs-1 do if (s.prcx+xx)<scrx then d[(s.prcx+xx)+(s.prcy+yy)*xxs]:=s.prcur[xx+yy*s.prcxs];
 except stderr(s,'sdimaxg_main','retcur');end;
end;
//############################################################################//
procedure draw_attack_cursor(s:psdi_rec;dst:ptypspr;x,y,xns,yns:integer;sun:integer);
var i,rcl,rcr,attk:integer;
su,tu:ptypunits;
ud:ptypunitsdb;
cp:pplrtyp;
mods:pmods_rec;
begin try
 mods:=get_mods(s.the_game);
 //Attack
 //FIXME?
 cp:=get_cur_plr(s.the_game);
 if not unav(s.the_game,sun) then exit;
 if not mods.attack_default then exit;
 if not inrm(s.the_game,xns,yns) then exit;
 if not can_see(s.the_game,xns,yns,cp.num,nil) then exit;
 if get_unu_length(s.the_game,xns,yns)=0 then exit;

 su:=get_unit(s.the_game,sun);
 ud:=get_unitsdb(s.the_game,su.dbn);
 attk:=su.bas.attk;

 for i:=0 to get_unu_length(s.the_game,xns,yns)-1 do begin
  tu:=get_unu(s.the_game,xns,yns,i);
  if not unav(tu) then continue;
  if not fire_possible(s.the_game,su,tu) then continue;
  if not can_see(s.the_game,xns,yns,cp.num,tu) then continue;

  if(tu.ptyp=pt_wateronly)and isa(s.the_game,tu,a_underwater)then begin
   if ud.weapon_type=WT_BOMB then attk:=attk div 2;
  end;

  if tu.own=cp.num then wrbgtxt8(s.cg,dst,x-20,y-20,'!',2);
  if tu.bas.hits<>0 then begin
   drrect8(dst,x-16,y+16,x+16,y+16+5,0);

   rcr:=x-15+round(30*(tu.cur.hits/tu.bas.hits));
   rcl:=x-15;
   if tu.cur.hits>0 then drfrect8(dst,x-15,y+17,rcr,y+20,2);
   if tu.bas.hits<>0 then rcl:=rcr-round(30*((attk-tu.bas.armr)/tu.bas.hits));
   if rcl<x-15 then rcl:=x-15;
   if tu.cur.hits>0 then drfrect8(dst,rcl,y+17,rcr,y+20,1);
  end;
  break;
 end;
 except stderr(s,'sdimaxg_main','draw_attack_cursor');end;
end;
//############################################################################//
procedure proc_threads(s:psdi_rec;dst:ptypspr);
var st:string;
x,y,xs,ys:integer;
begin
 if s.steps.step_do_reset then resetprog(s,1);

 if s.steps.last_step_read=s.steps.last_step_write then exit;
 if s.steps.step_message_wait='*' then exit;
 if s.steps.step_message_wait='' then begin
  st:=po('Communicating')+'...';
 end else begin
  if s.steps.step_progress<0.0001 then st:=s.steps.step_message_wait else st:=s.steps.step_message_progress+' ('+stre(s.steps.step_progress*100)+'%)';
 end;

 x:=dst.xs div 2-200;
 y:=12;
 xs:=400;
 ys:=40;

 if s.state=CST_INSGAME then begin
  y:=scry div 2-ys div 2;
  event_frame(s);
 end;

 tran_rect8(s.cg,dst,x,y,xs,ys,0);
 wrtxtcnt8(s.cg,dst,x+xs div 2,y+ys div 2-4,st,3);
end;
//############################################################################//
procedure draw_messagebox(s:psdi_rec;dst:ptypspr);
var xs,ys,xn,yn,xc,yc,xcs,ycs:integer;
begin try
 if not s.mbox_on then exit;
 xs:=400;
 ys:=182;
 xn:=(dst.xs div 2)-xs div 2;
 yn:=(dst.ys div 2)-ys div 2;
 xc:=xn+110;
 yc:=yn+10;
 xcs:=xs-2*110;
 ycs:=20;

 tran_rect8(s.cg,dst,xn,yn,xs,ys,0);

 tran_rect8(s.cg,dst,xc,yc,xcs,ycs,0);
 wrtxtcnt8(s.cg,dst,xn+xs div 2,yc+7,s.mbox_nam,2);

 tran_rect8(s.cg,dst,xn+10,yn+50,xs-20,110,0);
 wrtxtbox8(s.cg,dst,xn+20,yn+60,xn+xs-20,yn+110,s.mbox_msg,0);

 except stderr(s,'sdimaxg_main','proc_messagebox');end;
end;
//############################################################################//
procedure draw_mouse(s:psdi_rec;dst:ptypspr;x,y:integer);
var c:ptypspr;
begin
 if s.cur_cur=CUR_NONE then exit;
 if s.cur_cur>=length(s.cg.curs) then exit;
 c:=s.cg.curs[s.cur_cur];       
 if c=nil then exit;
 if c.xs<>25 then begin
  if c.xs<25 then begin
   getcur(s,dst,x,y,c.xs,c.ys);
   putsprt8(dst,c,x,y);
  end;
  if c.xs>25 then begin
   getcur(s,dst,x-c.xs div 2,y-c.ys div 2,c.xs,c.ys);
   putsprt8(dst,c,x-c.xs div 2,y-c.ys div 2);
  end;
 end else begin
  getcur(s,dst,x-12,y-12,c.xs,c.ys);
  putsprt8(dst,c,x-12,y-12);
 end;
end;
//############################################################################//
procedure draw_fps(s:psdi_rec;dst:ptypspr;x,y,xs,ys,fps,ducnt:integer);
begin
 drfrectx8(dst,x,y,xs,ys,0);
 drrectx8(dst,x,y,xs,ys,line_color);
 wrtxtcnt8(s.cg,dst,x+xs div 2,y+ 5,'FPS='+stri(round(fps)),2);
 wrtxtcnt8(s.cg,dst,x+xs div 2,y+15,'UDC='+stri(ducnt),2);
end;
//############################################################################//
procedure draw_msgu(s:psdi_rec;dst:ptypspr;x,y:integer);
var i,yn:integer;
begin
 yn:=1;
 for i:=1 to length(msgu.txt) do if msgu.txt[i]='&' then yn:=yn+1;
 puttran8(s.cg,dst,x,y,scrx-x-1,14+yn*11,msgu.c);
 wrtxtbox8(s.cg,dst,x+10,y+5,dst.xs+100,dst.ys,msgu.txt,0);
end;
//############################################################################//
procedure draw_stats_rect(s:psdi_rec;dst:ptypspr;x,y,xs,ys:integer);
begin
 drfrectx8(dst,x,y,xs,ys,0);
 drrectx8(dst,x,y,xs,ys,line_color);
 draw_stats_un(s,dst,x,y,xs,ys,get_sel_unit(s.the_game),false,0);
end;
//############################################################################//
procedure proc_frame_slim(s:psdi_rec;map:pmap_window_rec;dst:ptypspr;x,y,xns,yns:integer;cp:pplrtyp;wev:boolean);
begin
 if msgu.p and (wev) then draw_msgu(s,dst,gcrx(s.cg.intf.stats)+gcrxs(s.cg.intf.stats)+1,msgu_yoff);
 draw_framedyn_slim(s,map,dst,x,y,xns,yns);
 draw_stats_rect(s,dst,gcrx(s.cg.intf.stats),gcry(s.cg.intf.stats),gcrxs(s.cg.intf.stats),gcrys(s.cg.intf.stats));
end; 
//############################################################################//
procedure proc_background(s:psdi_rec);
begin try
 //Background image
 if s.now_loading then begin
  if not s.picked_loading_bkgr then begin
   s.bkgr_image:=random(length(s.cg.scaled_bkgr));     //Loading
   s.picked_loading_bkgr:=true;
  end;
 end else begin
  s.picked_loading_bkgr:=false;
  case s.state of
   CST_THEMENU:case s.cur_menu of
    MS_MAINMENU   :s.bkgr_image:=4;
    MS_MULTIPLAYER:s.bkgr_image:=7;
    MS_RULES      :s.bkgr_image:=2;
    MS_ABOUT      :s.bkgr_image:=2;
    MS_MAPSELECT  :s.bkgr_image:=9;
    MG_LOADSAVE   :s.bkgr_image:=6;
    MS_OPTIONS    :s.bkgr_image:=5;
    MS_UPDATE     :s.bkgr_image:=0;
    MS_CLANSELECT :s.bkgr_image:=3;
    MS_BUYINIT    :s.bkgr_image:=8;
    MS_PLAYERSETUP:s.bkgr_image:=1;
    else s.bkgr_image:=2;
   end;
   CST_INSGAME:s.bkgr_image:=1;      //Inter-turn
   else s.bkgr_image:=0;
  end;
 end;
 except stderr(s,'sdimaxg_main','proc_background');end;
end;
//############################################################################//
procedure proc_cursor(s:psdi_rec;x,y:integer);
var i,xn,yn,xs,ys,tyo:integer;
mods:pmods_rec;
begin try
 mods:=get_mods(s.the_game);
//Cursog GFX
 s.cur_cur:=CUR_MOVE;
 if mods.select_default then s.cur_cur:=CUR_SELECT;
 if (mods.enter_command or mods.fetch_command)and not mods.select_default then s.cur_cur:=CUR_ENTER;   
 if mods.xfer                                 and not mods.select_default then s.cur_cur:=CUR_TRANSFER;
 if mods.store_exit     then s.cur_cur:=CUR_EXIT;
 if mods.build_rect     then s.cur_cur:=CUR_BUILDTO;
 if mods.build_path     then s.cur_cur:=CUR_BUILDTO;
 if mods.refuel         then s.cur_cur:=CUR_REFUEL;
 if mods.reload         then s.cur_cur:=CUR_RELOAD;
 if mods.give_two       then s.cur_cur:=CUR_TRANSFER;
 if mods.repair         then s.cur_cur:=CUR_REPAIR;
 if mods.disabe_default then s.cur_cur:=CUR_DISABLE;
 if mods.disabe_command then s.cur_cur:=CUR_DISABLEF;
 if mods.steal_default  then s.cur_cur:=CUR_STEAL;
 if mods.steal_command  then s.cur_cur:=CUR_STEALF;
 if mods.move_default   then s.cur_cur:=CUR_MOVE;
 if mods.move_path      then s.cur_cur:=CUR_GOTO;
 if mods.move_command   then s.cur_cur:=CUR_BUILDTO;
 if mods.not_available  then s.cur_cur:=CUR_NOTAVAILABLE;
 if mods.attack_default then s.cur_cur:=CUR_ATTACK;

 //Cursor X interface
 if s.cur_menu<>MG_NOMENU then s.cur_cur:=CUR_POINTER;
 if (inrectv(x,y,s.cg.intf.mmap)) or
    (inrectv(x,y,s.cg.intf.coord)) or
    (inrectv(x,y,s.cg.intf.stats)) or
    (inrectv(x,y,s.cg.intf.uview)) then s.cur_cur:=CUR_POINTER;

 rmnu_sizes(s.cg,xs,ys,tyo);
 xn:=gcrx(s.cg.intf.rmnu);
 yn:=gcry(s.cg.intf.rmnu);
 for i:=0 to r_menu.cnt-1 do if inrects(x,y,xn,yn+i*ys,xs,ys) then s.cur_cur:=CUR_POINTER;

 if s.gm_comment_mode then s.cur_cur:=CUR_BUILDTO;

 except stderr(s,'sdimaxg_main','proc_cursor');end;
end;
//############################################################################//
procedure proc_scroll(s:psdi_rec;dt:double;cp:pplrtyp);
begin try
 //Scroll, zoom
 if so_in_game_navigation_mode(s) then begin
  //if scrg or scrh then so_set_zoom(so_range_by_zoom(cp.zoom+0.1*dt*60*(ord(scrh)-ord(scrg))),-1,-1);
  if s.scroll_right or s.scroll_left or s.scroll_up or s.scroll_down then so_reposition_map_pixels(s,s.clinfo.sopt.sx+XHCX*s.clinfo.sopt.zoom*dt*60*(ord(s.scroll_right)-ord(s.scroll_left)),s.clinfo.sopt.sy+XHCX*s.clinfo.sopt.zoom*dt*60*(-ord(s.scroll_up)+ord(s.scroll_down)));
 end;

 //Zoom, position change event
 if s.clinfo.sopt.zoom<>s.mainmap.oldzoom then begin
  calczoom(s,@s.mainmap,s.clinfo.sopt.zoom);
  calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);
  s.mainmap.oldzoom:=s.clinfo.sopt.zoom;
 end;
 if(s.clinfo.sopt.sx<>s.mainmap.mapoxo)or(s.mainmap.mapoyo<>s.clinfo.sopt.sy)then calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);

 except stderr(s,'sdimaxg_main','proc_scroll');end;
end;
//############################################################################//
procedure altitude_tick(s:psdi_rec;g:pgametyp;dt:double;u:ptypunits);
var i:integer;
bridgedwn,bridgeup:boolean;
ut:ptypunits;
begin
 if not unav(u) then exit;
 if u.alt=1 then u.alt:=XCX;

 bridgedwn:=false;
 bridgeup:=false;
 if u.typ='bridge' then begin
  for i:=0 to get_unu_length(g,u.x,u.y)-1 do begin
   ut:=get_unu(g,u.x,u.y,i);
   bridgeup:=bridgeup or((ut.ptyp=PT_WATERONLY)and not isa(g,ut,a_stealthed));
  end;

  if bridgeup then begin
   if u.alt=0 then u.alt:=1;
  end else begin
   u.alt:=round(u.alt-dt*XCX*2);
   if u.alt<=0 then u.alt:=0;
   bridgedwn:=true;
  end;
 end;

 if(u.alt<>0)and(not bridgedwn)then begin
  if u.alt<XCX then u.alt:=round(u.alt+(4*ord(u.typ='bridge')+1)*dt*XCX);
  if u.alt>XCX then u.alt:=XCX;
 end;
end;
//############################################################################//
procedure calc_game_events(s:psdi_rec;cp:pplrtyp;dt:double);
var i,unc:integer;
mvn:boolean;
u:ptypunits;
begin try
 //Unit number change event
 unc:=0;for i:=0 to get_units_count(s.the_game)-1 do if unav(s.the_game,i) then unc:=unc+1;
 if unc<>s.unit_count_old then s.unev:=true;
 s.unit_count_old:=unc;

 //Unit move event
 mvn:=false;
 for i:=0 to get_units_count(s.the_game)-1 do if unav(s.the_game,i) then begin
  u:=get_unit(s.the_game,i);
  if u.is_moving_now and (not u.isstd) then begin s.unev:=true; mvn:=true; end;
  altitude_tick(s,s.the_game,dt,u);
 end;
 if s.move_old<>mvn then s.unev:=true;
 if s.move_old_2<>mvn then s.unev:=true;
 s.move_old_2:=s.move_old;
 s.move_old:=mvn;

 s.unev:=s.unev or s.map_event or s.map_scroll_ev;
 if s.selunit_old<>cp.selunit then begin
  s.ut_event:=true;
  s.unev:=true;
 end;
 s.selunit_old:=cp.selunit;
 if s.unev then s.map_event:=true;
 if s.map_event then s.ut_event:=true;
 if s.unev then s.frameev:=true;
 s.plane_ev:=(s.state=CST_THEGAME) or s.unev or s.map_event or s.map_scroll_ev or s.ut_event;

 except stderr(s,'sdimaxg_main','calc_game_events');end;
end;
//############################################################################//
procedure draw_game_events(s:psdi_rec;dst:ptypspr;cp:pplrtyp);
var u:ptypunits;
begin try
 cp:=get_cur_plr(s.the_game);

 if s.frameev then begin s.frameev:=false;drfrect8(dst,0,0,dst.xs-1,dst.ys-1,0);end;  ////FIXME: Why so?  SLim mode?

 //Map and survey
 if s.unev then procresmap(s,@s.mainmap);
 if s.map_event or s.map_scroll_ev then draw_map(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy,s.clinfo.sopt.frame_btn[fb_grid]=1);
 if s.plane_ev then putspr8(dst,@s.map_plane,0,0);

 //Units and UTs
 draw_units(s,@s.mainmap,s.clinfo.sopt.zoom);

 if s.ut_event then draw_ut(s,@s.mainmap,s.clinfo.sopt.zoom);
 if s.plane_ev then begin
  u:=get_unit(s.the_game,cp.selunit);
  if(s.clinfo.sopt.frame_btn[fb_survey]=1)then begin
   putsprt8z(dst,@s.ut_plane,0,0);
  end else begin
   if unav(u) then if isa(s.the_game,u,a_surveyor)and(u.own=cp.num) then putsprt8z(dst,@s.ut_plane,0,0)
  end;
 end;
 draw_ut(s,@s.mainmap,s.clinfo.sopt.zoom);

 s.unev:=false;

 except stderr(s,'sdimaxg_main','draw_game_events');end;
end;
//############################################################################//
procedure addtrk(s:psdi_rec;u:ptypunits;x,y,rot:integer;enter:boolean);
const track_tab_exit:array[0..7]of integer=(2,3,4,5,6,7,0,1);
track_tab_enter:array[0..7]of integer=(6,7,0,1,2,3,4,5);
var c,i,d:integer;
begin try
 if(u.ptyp<pt_watercoast)and(not isa(s.the_game,u,a_human))and(get_map_pass(s.the_game,x,y)=P_LAND)then begin
  d:=0;
  if rot in [0..7] then begin
   if not enter then d:=track_tab_exit[rot]
                else d:=track_tab_enter[rot];
  end;
  c:=-1;
  for i:=0 to length(s.trk)-1 do if(s.trk[i].t<0)then begin c:=i; break; end;
  if c=-1 then begin
   c:=length(s.trk);
   setlength(s.trk,c+1);
  end;
  s.trk[c].x:=x;
  s.trk[c].y:=y;
  s.trk[c].d:=d;
  s.trk[c].t:=track_decay_time;
  s.trk[c].dx:=random(5)-2;
  s.trk[c].dy:=random(5)-2;
 end;

 except stderr(s,'sdimaxg_main','addtrk');end;
end;
//############################################################################//
procedure calc_motion(s:psdi_rec;u:ptypunits;dt:double);
var dx,dy,nx,ny:integer;
mvel,minvel:integer;                //Unit velocity max and min
mspd:double;                           //Unit maxspeed
begin try
 mspd:=XCX*8;
 mvel:=XCX*8;
 minvel:=XCX;
 if u.ptyp=pt_air then mvel:=2*mvel;

 dx:=u.xnt-u.x;
 dy:=u.ynt-u.y;

 u.move_vel:=u.move_vel+dt*mspd;
 //if slowing then u.move_vel:=u.move_vel-dt*mspd;
 if u.move_vel>mvel then u.move_vel:=mvel;
 if u.move_vel<minvel then u.move_vel:=minvel;

 if(dx<>0)and(abs(u.mox)<XCX)then u.mox:=round(u.mox+sgn(dx)*u.move_vel*dt);
 if(dy<>0)and(abs(u.moy)<XCX)then u.moy:=round(u.moy+sgn(dy)*u.move_vel*dt);
 if(abs(u.mox)>=XCX)or(abs(u.moy)>=XCX)then begin
  nx:=u.x;
  ny:=u.y;
  if abs(u.mox)>=XCX then nx:=u.x+sgn(dx);
  if abs(u.moy)>=XCX then ny:=u.y+sgn(dy);

  addscan(s.the_game,u,nx,ny);
  subscan(s.the_game,u);
  remunuc(s.the_game,u.x,u.y,u);

  if abs(u.mox)>=XCX then begin u.x:=u.x+sgn(u.mox);u.mox:=0;end;
  if abs(u.moy)>=XCX then begin u.y:=u.y+sgn(u.moy);u.moy:=0;end;
  addtrk(s,u,u.x,u.y,u.rot,true);

  addunu(s.the_game,u);

  event_map_reposition(s);
  event_units(s);
 end;
 if(u.xnt=u.x)and(u.ynt=u.y)then begin
  u.move_anim:=false;
 end;

 except stderr(s,'sdimaxg_main','calc_motion');end;
end;
//############################################################################//
procedure state_main_menu(s:psdi_rec;dst:ptypspr;ct,dt:double);
begin
 retcur(s,dst);
 s.cur_cur:=CUR_POINTER;

 draw_framebase_slim(s,dst);
 draw_menus(s,dst);
 draw_uint(s,dst);
end;
//############################################################################//
procedure state_the_game(s:psdi_rec;dst:ptypspr;mx,my:integer;ct,dt:double);
var cp:pplrtyp;
i:integer;
u:ptypunits;
begin try
 retcur(s,dst);

 //Tracks
 for i:=0 to length(s.trk)-1 do s.trk[i].t:=s.trk[i].t-dt;

 //Actions?
 s.active_events:=false;
 for i:=0 to get_units_count(s.the_game)-1 do if unav(s.the_game,i) then begin
  u:=get_unit(s.the_game,i);
  if u.fires then begin
   u.fire_timer:=u.fire_timer+dt;
   if u.fire_timer>=fire_length then u.fires:=false;
  end;  
  if u.fires then s.active_events:=true;
 end;
 if any_anim_units(s) then s.active_events:=true;
 if get_moving_unit(s)<>nil then begin
  s.active_events:=true;
  calc_motion(s,get_moving_unit(s),dt);
 end;

 if sds_is_replay(@s.steps) then event_frame_map(s);

 //Check the modes active, disable if not applicable any more
 check_unit_mods(s.the_game,sds_is_replay(@s.steps));

 cp:=get_cur_plr(s.the_game);

 sync_units_graphics(s);
 proc_scroll(s,dt,cp);
 proc_cursor(s,mx,my);
 calc_game_events(s,cp,dt);
 draw_game_events(s,dst,cp);

 //Debug menu unit
 if (s.cur_menu=MG_DEBUG)and s.debug_placing and inrm(s.the_game,s.cur_map_x,s.cur_map_y) then draw_debug_unit(s,dst,s.cur_map_x,s.cur_map_y,@s.mainmap);

 //Landing stuff
 if s.cur_menu=MG_NOMENU then if not is_landed(s.the_game,cp) then draw_landing_units(s,dst,s.cur_map_x,s.cur_map_y,@s.mainmap);

 if not s.hide_interface then begin
  proc_frame_slim(s,@s.mainmap,dst,mx,my,s.cur_map_x,s.cur_map_y,cp,s.plane_ev);
  draw_menus(s,dst);
  draw_uint(s,dst);
 end;

 //Map offset detection
 s.mainmap.mapoxo:=s.clinfo.sopt.sx;
 s.mainmap.mapoyo:=s.clinfo.sopt.sy;

 draw_attack_cursor(s,dst,mx,my,s.cur_map_x,s.cur_map_y,cp.selunit);

 except stderr(s,'sdimaxg_main','state_the_game');end;
end;
//############################################################################//
procedure state_transgame(s:psdi_rec;dst:ptypspr;ct,dt:double;wev:boolean);
begin try
 if not wev then retcur(s,dst);
 s.cur_cur:=CUR_POINTER;

 s.cur_menu:=MS_INTERTURN;

 draw_framebase_slim(s,dst);
 if s.steps.last_step_read=s.steps.last_step_write then begin
  draw_menus(s,dst);
  draw_uint(s,dst);
 end;

 except stderr(s,'sdimaxg_main','state_transgame');end;
end;
//############################################################################//
procedure state_loading(s:psdi_rec;dst:ptypspr;ct,dt:double);
begin
 s.cur_cur:=CUR_NONE;

 draw_framebase_slim(s,dst);
 draw_now_loading(s,dst);
end;
//############################################################################//
function preset_events(s:psdi_rec;dst:ptypspr;ct,dt:double):boolean;
begin result:=false;try
 if snd_on then initsound(s,0);
 if (s.state=CST_THEGAME) or s.now_loading then event_frame(s);

 fpsc:=fpsc+1;
 s.gct:=ct;
 s.gdt:=dt;

 if fpsc mod 10=0 then handle_background_sounds;

 if sdiev then begin
  sdiev:=false;

  event_frame(s);
  s.unev:=true;
  s.map_event:=true;
 end;
 if s.state<>s.pstate then begin
  drfrect8(dst,0,0,dst.xs,dst.ys,0);

  event_frame(s);

  result:=true;
 end;
 if s.cur_menu<>s.pcur_menu then event_frame_map(s);
 if s.frameev then event_frame_map(s);
 if s.frameev or s.frame_map_ev or s.frame_mmap_ev then gui_frame_event;
 s.pstate:=s.state;
 s.pcur_menu:=s.cur_menu;

 except stderr(s,'sdimaxg_main','preset_events');end;
end;
//############################################################################//
procedure performance_tests(dst:ptypspr);
//var i:integer;
begin
 //Font tests
 //for i:=0 to 6 do wrtxtcntmg8(dst,curx-100,cury+i*30,'UDC='+stri(ducnt),i,5,199,56);
 //for i:=0 to 8 do wrtxtcntmg8(dst,curx,cury+i*30,'UDC='+stri(ducnt),i);
 //for i:=0 to 8 do wrtxtcnt8(dst,curx+100,cury+i*30,'UDC='+stri(ducnt),i);

 //Performance tests
 //drcirc(dst,100,100,20,1);
 //for i:=0 to 1000000 do drcircg(dst,curx,cury,20,1);
 //for i:=0 to 1000000 do drline(dst,curx-20,cury-15,curx+20,cury+15,1);
 //for i:=0 to 0 do draaline(dst,curx-20,cury-15,curx+20,cury+15,1);
 //for i:=0 to 100000 do drpolyflat(dst,curx-20,cury-15,curx+20,cury-15,curx,cury+25,1);
end;
//############################################################################//
procedure maxg_sdi_main(s:psdi_rec;mx,my:integer;ct,dt:double);
var wev:boolean;
begin try
 //If size was changed, then resize
 if not s.now_loading then if s.pending_resize then begin
  bkgr_resize(s);
  iresetgui(s);
  s.pending_resize:=false;
 end;

 mutex_lock(sds_mx);

 wev:=preset_events(s,@sdiscrp,ct,dt);
 proc_background(s);

 if s.now_loading then begin
  state_loading(s,@sdiscrp,ct,dt);
 end else case s.state of
  CST_THEMENU:state_main_menu(s,@sdiscrp,ct,dt);
  CST_THEGAME:state_the_game(s,@sdiscrp,mx,my,ct,dt);
  CST_INSGAME:state_transgame(s,@sdiscrp,ct,dt,wev);
 end;

 if fpsdbg then draw_fps(s,@sdiscrp,scrx-85,5,80,26,fps,ducnt);

 proc_threads(s,@sdiscrp);
 draw_messagebox(s,@sdiscrp);
 draw_mouse(s,@sdiscrp,mx,my);

 //performance_tests(@sdiscrp);

 mutex_release(sds_mx);

 except mbox(s,'maxg_sdi_main: '+po('crerr'),po('err')); halt;end;
end;
//############################################################################//
function uni_to_cp1251(ch:word):word;
begin
 result:=ch;
 if(ch>=$410)and(ch<=$44F)then result:=ch-$410+$C0;
 if ch=$451 then result:=$B8; //ё
 if ch=$401 then result:=$A8; //Ё
end;
//############################################################################//
procedure maxg_sdi_event(s:psdi_rec;evt,x,y:integer;key,shift:dword);
begin try
 //tolog('DBG',stri(evt)+' '+stri(x)+' '+stri(y)+' '+stri(key)+' '+stri(shift));

 if evt=glgr_evresize then if s.inited then begin so_screen_resize(s);exit;end;
 if evt=glgr_evclose then begin haltprog;exit;end;
 mutex_lock(sds_mx);
 if not s.now_loading then case evt of
  glgr_evmsup  :begin
   mg_msup(s,shift,x,y);
   s.msd_dt:=0;
  end;
  glgr_evmsdwn :begin
        if isf(shift,sh_up)   then mg_mswheel(s,-1,shift)
   else if isf(shift,sh_down) then mg_mswheel(s, 1,shift)
   else mg_msdown(s,shift,x,y);
  end;
  glgr_evmsmove:mg_msmove(s,shift,x,y);
  glgr_evkeydwn:mg_keydown(s,key,uni_to_cp1251(sdi_key_uni),shift);
  glgr_evkeyup:mg_keyup(s,key,shift);
 end;
 mutex_release(sds_mx);
 except mbox(s,'maxg_sdi_event: '+po('crerr')+' '+stri(evt)+' '+stri(x)+' '+stri(y)+' '+stri(key)+' '+stri(shift),po('err')); halt;end;
end;
//############################################################################//
begin
end.
//############################################################################//

