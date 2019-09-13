//############################################################################//
unit sdikeyinput;
interface
uses asys,maths,grph,sdi_rec,sdisdl
,mgrecs,mgl_common,mgl_attr,mgl_cursors,mgl_rmnu,mgl_actions
,sdirecs,sdiauxi,sdicalcs,sdisound,sdigui,sdiovermind,sdimenu
,sds_util,sds_rec;
//############################################################################//   
function click_rmnu(s:psdi_rec;x,y:integer;shift:dword;act:boolean):boolean;

procedure minimap_pos(s:psdi_rec;x,y:integer);
procedure menu_cam_position(s:psdi_rec;idx:integer;store:boolean);      
procedure menu_comment(s:psdi_rec;x,y:integer);  

procedure mg_keyup(s:psdi_rec;key,shift:dword);
procedure mg_keydown(s:psdi_rec;key,uni,shift:dword);  

procedure move_curs(s:psdi_rec;shift:dword;x,y:integer);

procedure mg_msmove(s:psdi_rec;shift:dword;x,y:integer);
procedure mg_mswheel(s:psdi_rec;dir:integer;shift:dword);
//############################################################################//
implementation          
//############################################################################//
function click_rmnu(s:psdi_rec;x,y:integer;shift:dword;act:boolean):boolean;
var un:ptypunits;   
i,xs,ys,tyo,xn,yn:integer;
cp:pplrtyp;
begin result:=false; try
 if s.active_events then exit;
 
 un:=get_sel_unit(s.the_game);
 cp:=get_cur_plr(s.the_game);
 if cp<>nil then if is_landed(s.the_game,cp) and not s.rmov and(s.cur_menu=MG_NOMENU) then if unav(un) then begin
  rmnu_sizes(s.cg,xs,ys,tyo);     
  xn:=gcrx(s.cg.intf.rmnu);
  yn:=gcry(s.cg.intf.rmnu);
  
  if r_menu.cnt=0 then exit;
  event_map_reposition(s);
  
  if r_menu.cnt>0 then for i:=0 to r_menu.cnt-1 do s.rmnu_state[i]:=0;  
  
  if r_menu.cnt>0 then for i:=0 to r_menu.cnt-1 do begin
   if inrects(x,y,xn,yn+i*ys,xs,ys) then begin 
    if act then begin
     do_rmnu(s.the_game,i+1,sds_is_replay(@s.steps));
     curs_calc(s.the_game,s.cur_map_x,s.cur_map_y,isf(shift,sh_shift));
     s.rmnu_state[i]:=0;
    end else s.rmnu_state[i]:=1;
    result:=true;
    exit;
   end;
  end;
  curs_calc(s.the_game,s.cur_map_x,s.cur_map_y,isf(shift,sh_shift));            
 end;   
 except stderr(s,'sdikeyinput','click_rmnu');end;
end;        
//############################################################################//
function getmapcoord(mv,reg,dv:integer;xx:double):double;
begin
 result:=mv;
 if mv>reg-dv then result:=reg-dv;
 result:=result-dv;
 if result<0 then result:=0;
 result:=result/xx; 
end;
//############################################################################//
//command mean send left/middle click command based on minimap coordinates
//0 - set map position
procedure minimap_pos(s:psdi_rec;x,y:integer);
var dx,dy,mx,my:integer;
xx,yy:double;
begin try
 mx:=x-gcrx(s.cg.intf.mmap);
 my:=y-gcry(s.cg.intf.mmap);

 xx:=s.cg.intf.mmap.sx/s.mapx;
 yy:=s.cg.intf.mmap.sy/s.mapy;
 if xx<yy then yy:=xx else xx:=yy;
 if(xx>1)and(yy>1)then begin xx:=1;yy:=1; end;

 dx:=round(s.cg.intf.mmap.sx-s.mapx*xx) div 2;
 dy:=round(s.cg.intf.mmap.sy-s.mapy*yy) div 2;

 so_reposition_map_pixels(s,getmapcoord(mx,s.cg.intf.mmap.sx,dx,xx)*XCX,getmapcoord(my,s.cg.intf.mmap.sy,dy,xx)*XCX);
 except stderr(s,'sdikeyinput','minimap_pos');end;
end;
//############################################################################//
procedure menu_comment(s:psdi_rec;x,y:integer);
var i:integer;
pl:pplrtyp;
begin try
 s.gm_comment_x:=x;
 s.gm_comment_y:=y;
 s.gm_comment_mode:=false;
 s.gm_comment_num:=-1;
 s.gm_comment_text:='';
 pl:=get_cur_plr(s.the_game);
 for i:=0 to length(pl.comments)-1 do if(pl.comments[i].typ=1)and(pl.comments[i].x=x)and(pl.comments[i].y=y)then begin
  s.gm_comment_num:=i;
  s.gm_comment_text:=pl.comments[i].text;
  break;
 end;
 set_game_menu(s.the_game,MG_COMMENT);
 except stderr(s,'sdikeyinput','menu_comment');end;
end;
//############################################################################//
procedure menu_cam_position(s:psdi_rec;idx:integer;store:boolean);
begin try
 if store then begin
  s.clinfo.cam_pos[idx].x:=s.clinfo.sopt.sx;
  s.clinfo.cam_pos[idx].y:=s.clinfo.sopt.sy;
  s.clinfo.cam_pos[idx].zoom:=s.clinfo.sopt.zoom;
 end else if s.clinfo.cam_pos[idx].x<>-1 then begin   
  so_set_zoom(s,so_range_by_zoom(s,s.clinfo.cam_pos[idx].zoom),0-1,-1);
  so_reposition_map_pixels(s,s.clinfo.cam_pos[idx].x,s.clinfo.cam_pos[idx].y);
 end;  
 except stderr(s,'sdikeyinput','menu_cam_position');end;
end;
//############################################################################//
procedure press_rmnu(s:psdi_rec;f:integer);
var i:integer;
begin try
 calc_rmnu(s.the_game,get_sel_unit(s.the_game),sds_is_replay(@s.steps));
   
 for i:=0 to r_menu.cnt-1 do if r_menu.fnc[i].key=f then begin do_rmnu(s.the_game,i+1,sds_is_replay(@s.steps));break;end;
 curs_calc(s.the_game,s.cur_map_x,s.cur_map_y,false);
 except stderr(s,'sdikeyinput','press_rmnu');end;
end;
//############################################################################//
procedure click_fb(s:psdi_rec;n:integer);
begin try
 event_map_reposition(s);
 event_frame(s);

 snd_click(SND_TOGGLE);
 s.clinfo.sopt.frame_btn[n]:=1-s.clinfo.sopt.frame_btn[n];  
 except stderr(s,'sdikeyinput','click_fb');end;
end;
//############################################################################//
//Game, no menus keys
procedure mg_keydown_game(s:psdi_rec;key,shift:dword);
var cp:pplrtyp;   
su,u:ptypunits;
ud:ptypunitsdb;
//i:integer;
begin try
 ud:=nil;              
 cp:=get_cur_plr(s.the_game);
 su:=get_sel_unit(s.the_game);
 if su<>nil then ud:=get_unitsdb(s.the_game,su.dbn);

 case key of
  //Game menu
  KEY_ESC:set_game_menu(s.the_game,MG_ESCSAVE);

  //End turn   
  KEY_ENTER,KEY_NUM_ENTER:if is_landed(s.the_game,cp) then go_end_turn(s,isf(shift,sh_shift));

  //Unit info
  KEY_I:if su<>nil then set_game_menu(s.the_game,MG_UNITINFO);

  //See depot
  KEY_D:if isf(shift,sh_shift) then begin
   if(su<>nil)and(ud<>nil)then if su.own=cp.num then
    if(ud.store_lnd>0)or(ud.store_wtr>0)or(ud.store_air>0)or(ud.store_hmn>0)then set_game_menu(s.the_game,MG_DEPOT);
  end else if not isf(shift,sh_alt) then click_fb(s,fb_range);

  //Rename units
  KEY_R:begin
   if isf(shift,sh_alt) then begin
    if su<>nil then if isa(s.the_game,su,a_ours) then set_game_menu(s.the_game,MG_UNIT_RENAME);
   end else if isf(shift,sh_shift) then begin
    click_fb(s,fb_survey);
   end else if is_landed(s.the_game,cp) then set_game_menu(s.the_game,MG_REPORT);
  end;

  {
  //Thst was for all, should be for one
  KEY_SPACE:begin
   for i:=0 to get_units_count(s.the_game)-1 do begin
    u:=get_unit(s.the_game,i);
    if u<>nil then if unav(s.the_game,u.num) then if u.own=cp.num then if u.isstd and not u.isbuild and not u.isbuildfin then act_unit_done(s.the_game,u);
   end;
  end;
  }
  KEY_SPACE:if su<>nil then if unav(s.the_game,su.num) then if su.own=cp.num then if su.isstd and not su.isbuild and not su.isbuildfin then act_unit_done(s.the_game,su);

  KEY_C:if isf(shift,sh_shift) then s.gm_comment_mode:=not s.gm_comment_mode
  else if isf(shift,sh_alt) then set_game_menu(s.the_game,MG_CUSTOM_CLRS)
  else s.show_comments:=not s.show_comments;


  KEY_W:click_fb(s,fb_hits);
  KEY_X:click_fb(s,fb_scan);
  KEY_H:click_fb(s,fb_colors);
  KEY_N:click_fb(s,fb_names);
  KEY_Z:if not isf(shift,sh_alt) then click_fb(s,fb_speedrange);
  KEY_E:click_fb(s,fb_ammo);
  KEY_Q:click_fb(s,fb_fuel);
  KEY_G:click_fb(s,fb_grid);
  KEY_S:click_fb(s,fb_status);

  KEY_0:if isf(shift,sh_ctrl) then  else press_rmnu(s,key-KEY_0);
  KEY_1:if isf(shift,sh_ctrl) then click_fb(s,fb_range)  else press_rmnu(s,key-KEY_0);
  KEY_2:if isf(shift,sh_ctrl) then click_fb(s,fb_scan)   else press_rmnu(s,key-KEY_0);
  KEY_3:if isf(shift,sh_ctrl) then click_fb(s,fb_speedrange) else press_rmnu(s,key-KEY_0);
  KEY_4:if isf(shift,sh_ctrl) then click_fb(s,fb_survey) else press_rmnu(s,key-KEY_0);
  KEY_5:if isf(shift,sh_ctrl) then click_fb(s,fb_status) else press_rmnu(s,key-KEY_0);
  KEY_6:if isf(shift,sh_ctrl) then click_fb(s,fb_colors) else press_rmnu(s,key-KEY_0);
  KEY_7:if isf(shift,sh_ctrl) then click_fb(s,fb_hits)   else press_rmnu(s,key-KEY_0);
  KEY_8:if isf(shift,sh_ctrl) then click_fb(s,fb_fuel)   else press_rmnu(s,key-KEY_0);
  KEY_9:if isf(shift,sh_ctrl) then click_fb(s,fb_ammo)   else press_rmnu(s,key-KEY_0);

  KEY_A:press_rmnu(s,KEY_3);
  KEY_B:press_rmnu(s,KEY_1);

  //Toggle circles and squares
  KEY_U:begin
   set_game_menu(s.the_game,MG_FNC);
   s.cur_menu_page:=1;
  end;

  {$ifndef ape3}
  //Store/Restore position
  KEY_F5..KEY_F8:menu_cam_position(s,key-KEY_F5,isf(shift,sh_ctrl));
  {$endif}

  //Lock mode
  KEY_L:if is_landed(s.the_game,cp) then begin
   if isf(shift,sh_shift) then begin
    s.clinfo.lck_mode:=not s.clinfo.lck_mode;
    add_step(@s.steps,sts_set_cdata);
   end else begin
    if s.clinfo.lck_mode then begin
     u:=get_unit(s.the_game,cp.selunit);
     if unav(u) then if u.own<>cp.num then begin
      toggle_unit_in_lock(s,u);
      select_unit(s.the_game,-1,false);
      add_step(@s.steps,sts_set_cdata);
      exit;
     end;
    end;
   end;
  end;

  //Deselect units
  KEY_P:if is_landed(s.the_game,cp) then select_unit(s.the_game,-1,false);

  KEY_F:if unav(su) then so_reposition_map_pixels(s,-(su.x+1),-(su.y+1));

  //Keyboard scroll
  KEY_RIGHT:s.scroll_right:=true;
  KEY_LEFT :s.scroll_left :=true;
  KEY_UP   :s.scroll_up   :=true;
  KEY_DWN  :s.scroll_down :=true;

  //Resync with server   
  KEY_M:if is_landed(s.the_game,cp) then begin
   add_step(@s.steps,sts_fetch_plrshort);
   add_step(@s.steps,sts_fetch_all_units);
   if isf(shift,sh_shift) then add_step(@s.steps,sts_set_cdata);
  end;
 end;
 
 if s.the_game.info.rules.debug then case key of
  //Blow up selected unit
  KEY_D:if isf(shift,sh_alt) then if unav(su) then act_dbg_boom_unit(s.the_game,su.num);

  //Create/destroy menu
  KEY_Z:if isf(shift,sh_alt) then if is_landed(s.the_game,cp) and((s.cur_menu=MG_NOMENU) or (s.cur_menu=MG_DEBUG)) then begin set_game_menu(s.the_game,MG_DEBUG); s.debug_placing:=false; end;

  //See all resources
  KEY_O:if isf(shift,sh_alt) then begin s.resdbg:=not s.resdbg;event_units(s); end;
 end;
 except stderr(s,'sdikeyinput','mg_keydown_game');end;
end;  
//############################################################################//
 //Program-global keys
function mg_key_global(s:psdi_rec;key,shift:dword):boolean;
begin result:=true; try
 case key of
  //Menu OK
  KEY_ENTER,KEY_NUM_ENTER:if s.cur_menu<>MG_NOMENU then menu_ok(s,SND_BUTTON) else result:=false;
  //Get out of whatever we are in
  KEY_ESC:if not((s.state=CST_THEGAME)and(s.cur_menu=MG_NOMENU))then begin
   event_frame(s);
   menu_cancel(s,SND_BUTTON);
  end else result:=false;
  //Screenshot
  KEY_C:if isf(shift,sh_alt) then savescreen8(mgrootdir+'screenshot-'+getdatestamp+'.bmp') else result:=false;     
  //Exit the game for good
  //KEY_F4:if ssalt in shift then begin snd_click(SND_BUTTON);haltprog;exit;end else result:=false;

  KEY_F3:s.rep.fast_replay:=not s.rep.fast_replay;
  KEY_F4:s.rep.paused:=not s.rep.paused;

  KEY_TAB:s.hide_interface:=not s.hide_interface;
  
  else result:=false;
 end;
 except stderr(s,'sdikeyinput','mg_key_global');end;
end;   
//############################################################################//
procedure mg_keydown(s:psdi_rec;key,uni,shift:dword);
begin try
 //Message box
 if s.mbox_on then begin 
  if(key=KEY_ENTER)or(key=KEY_NUM_ENTER)or(key=KEY_ESC) then begin s.mbox_on:=false;event_frame(s);end;
  exit;
 end;

 //GUI
 if proc_input_boxes(s,uni,shift) then exit;

 //Program-global keys
 if mg_key_global(s,key,shift) then exit;

 //State-specific keys
 case s.state of
  CST_THEGAME:if s.cur_menu<>MG_NOMENU then keydown_menu_by_id(s,s.cur_menu,key,shift) else mg_keydown_game(s,key,shift);
  CST_THEMENU:keydown_menu_by_id(s,s.cur_menu,key,shift);
 end;

 except stderr(s,'sdikeyinput','mg_keydown');end;
end;  
//############################################################################//
procedure mg_keyup(s:psdi_rec;key,shift:dword);
begin try
 if s.mbox_on then exit;
 
 case key of
  KEY_RIGHT:s.scroll_right:=false;
  KEY_LEFT :s.scroll_left :=false;
  KEY_UP   :s.scroll_up   :=false;
  KEY_DWN  :s.scroll_down :=false;
 end;
 
 except stderr(s,'sdikeyinput','mg_keyup');end;
end; 
//############################################################################//
//############################################################################//  
//Updates s.cur_map_x and y, among other things
procedure move_curs(s:psdi_rec;shift:dword;x,y:integer);
begin try
 curx:=x;cury:=y;  
 ////FIXME: Incorrect comparison
 if s.state>CST_THEMENU then begin if(curx>=0)and(curx<scrx)and(cury>=0)and(cury<scry)then begin
  s.cur_map_x:=s.mainmap.block_xlate[s.mainmap.mapl+curx];
  s.cur_map_y:=s.mainmap.block_xlate[s.mainmap.mapt+cury];
 end else begin
  s.cur_map_x:=-1;
  s.cur_map_y:=-1;
 end;end; 
 if(s.state=CST_THEGAME)and(s.cur_menu=MG_NOMENU)then curs_calc(s.the_game,s.cur_map_x,s.cur_map_y,isf(shift,sh_shift)); 
 except stderr(s,'sdikeyinput','move_curs');end;
end;   
//############################################################################//  
//############################################################################//  
procedure mg_msmove(s:psdi_rec;shift:dword;x,y:integer);
var xn,yn:integer; 
z0,zs:double;
begin try      
 if s.ignore_mousemove then exit;
 move_curs(s,shift,x,y);

 if not isf(shift,sh_alt) then if gui_mouse_move(s,shift,x,y) then exit;
        
 if s.state=CST_THEGAME then begin
  if (s.cur_menu=MG_NOMENU) or ((s.cur_menu=MG_DEBUG) and s.debug_placing) then if isf(shift,sh_right) or isf(shift,sh_left) or isf(shift,sh_middle) then begin
   if not s.rmov and((abs(s.rmxo-x)>10)or(abs(s.rmyo-y)>10))then begin
    s.rmxo:=x;
    s.rmyo:=y;
    s.rmov:=true;
    if isf(shift,sh_right) or isf(shift,sh_left) then s.ignore_mouseup:=true;
   end;
   if s.rmov then begin
    if isf(shift,sh_right) or isf(shift,sh_left) then so_reposition_map_pixels(s,s.clinfo.sopt.sx-(x-s.rmxo)*s.clinfo.sopt.zoom,s.clinfo.sopt.sy-(y-s.rmyo)*s.clinfo.sopt.zoom);
    if isf(shift,sh_middle) then begin
     z0:=s.clinfo.sopt.zoom;
     zs:=s.zoomspd;
     if y-s.rmyo<0 then z0:=z0/(1+zs/10) else z0:=z0*(1+zs/10);
     so_set_zoom(s,so_range_by_zoom(s,z0),curx,cury);
    end;
    s.rmxo:=x;
    s.rmyo:=y;
    s.rmov:=true;
    if isf(shift,sh_right) or isf(shift,sh_left) then s.ignore_mouseup:=true;
   end;
  end;

  if s.cur_menu=MG_NOMENU then if isf(shift,sh_left) then if inrectv(x,y,s.cg.intf.mmap) then begin
   minimap_pos(s,x,y); 
   s.ignore_mouseup:=true;
   exit;
  end;
 end;

 calc_menuframe_pos(s.cur_menu,xn,yn);
 //if (s.state=CST_THEGAME)or(s.state=CST_THEMENU) then
 mm_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn);

 except stderr(s,'sdikeyinput','mg_msmove');end;
end;
//############################################################################//
//############################################################################//
procedure mg_mswheel(s:psdi_rec;dir:integer;shift:dword);
var z0,zs:double;
xn,yn:integer;
cp:pplrtyp;
begin try        
 {$ifdef embedded}s.ignore_mousemove:=true;{$endif}
 {$ifndef embedded}if gui_mouse_wheel(s,shift,curx,cury,dir) then exit;{$endif}
 cp:=get_cur_plr(s.the_game);

 calc_menuframe_pos(s.cur_menu,xn,yn);
 if s.cur_menu=MG_NOMENU then begin
  if mw_menu_by_id(s,s.cur_menu,shift,dir,xn,yn) then exit;
 end else mw_menu_by_id(s,s.cur_menu,shift,dir,xn,yn);

 if s.state=CST_THEGAME then if (s.cur_menu=MG_NOMENU) or ((s.cur_menu=MG_DEBUG) and s.debug_placing) then if cp<>nil then begin
  z0:=s.clinfo.sopt.zoom;
  zs:=s.zoomspd;
  if isf(shift,sh_shift) then zs:=0.3;
  if isf(shift,sh_ctrl) then zs:=3;         
  if dir=-1 then z0:=z0/(1+zs/10) else z0:=z0*(1+zs/10);
  so_set_zoom(s,so_range_by_zoom(s,z0),curx,cury);
 end;

 except stderr(s,'sdikeyinput','mg_mswheel');end;
end;   
//############################################################################//
//############################################################################//
begin
end.
//############################################################################//
