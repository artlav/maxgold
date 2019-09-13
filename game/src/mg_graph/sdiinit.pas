//############################################################################//
unit sdiinit;
interface
uses sysutils,asys,grph,sdi_rec,sdigrtools,sdiovermind
,mgrecs,mgl_common,mgl_land,mgl_attr
,sds_util,sds_rec,sds_net,sdirecs,sdiauxi,sdigrinit,sdicalcs,sdiloads,sdisound,sdigui,sdimenu;
//############################################################################//            
procedure pxpal_upd(s:psdi_rec);
procedure init_new_game(s:psdi_rec);
procedure init_game_load(s:psdi_rec;id:string);
procedure resetgui(s:psdi_rec); 
procedure reset_interface(s:psdi_rec);  
 
procedure preinit_stuff(s:psdi_rec);
  
procedure pre_load_grps(s:psdi_rec);
procedure load_grps(s:psdi_rec);

procedure maininit(s:psdi_rec);    
procedure haltgame(s:psdi_rec);
//############################################################################//
implementation
//############################################################################//
procedure voice_unit_status(s:psdi_rec;u:ptypunits);    
var voi:integer;
begin
 if s=nil then exit;
 voi:=-1;
 if not isa(s.the_game,u,a_building) then voi:=VOI_READY_1+random(4);
 if (u.bas.speed<>0) and (u.cur.speed=0) then voi:=VOI_MOVE_GONE;
 if is_ammo_low(u) then voi:=VOI_AMMO_LOW;
 if (u.bas.ammo<>0) and (u.cur.ammo=0) then voi:=VOI_AMMO_GONE;
 if is_hits_yellow(u) then voi:=VOI_HIT_MED_1+random(2);
 if is_hits_red(u) then voi:=VOI_HIT_BAD_1+random(2);
 if voi<>-1 then snd_voice(voi);
end;
//############################################################################//
procedure selection_changed(s:psdi_rec;was,now:ptypunits);
var cp:pplrtyp;
begin
 if s=nil then exit;
 if (was=nil) and (now=nil) then begin
  cp:=get_cur_plr(s.the_game);
  if is_landed(s.the_game,cp) then exit;
  if now<>nil then s.clinfo.sel_unit_uid:=now.uid;
  so_set_zoom(s,0,-1,-1);
  so_reposition_map_pixels(s,-plr_begin.lndx,-plr_begin.lndy);
  exit;
 end;

 if was=now then exit;
 stop_running_snd(s);
 if now<>nil then if now.isact then begin
  play_running_snd(s,now);
  if cur_plr_unit(s.the_game,now) then voice_unit_status(s,now);
 end;
end;
//############################################################################//
procedure on_unit_event(s:psdi_rec;u:ptypunits;evt:integer);
begin
 case evt of
  uevt_stored:begin
   if get_sel_unit(s.the_game)=u then stop_running_snd(s);
   snd_click(SND_ENTER);
  end;
  uevt_unstored:begin
   snd_click(SND_ENTER);
   ////play_running_snd(s,u);
  end;
  uevt_boom:begin    
   if get_sel_unit(s.the_game)=u then stop_running_snd(s);
   play_boom_snd(s,u);
  end;
  uevt_stopped:if get_sel_unit(s.the_game)=u then begin stop_running_snd(s);play_stop_snd(s,u);end;
  uevt_started:if get_sel_unit(s.the_game)=u then begin play_start_snd(s,u);play_running_snd(s,u);end;
  uevt_fire:play_fire_snd(s,u);
  uevt_hit:snd_click(SND_HIT_MED);
 end;
end;
//############################################################################//
procedure pxpal_upd(s:psdi_rec);
var i,n:integer;
pl:pplrtyp;
begin
 for n:=0 to get_plr_count(s.the_game)-1 do for i:=0 to 255 do s.colors.palpx[n][i]:=i;
 for n:=0 to get_plr_count(s.the_game)-1 do begin
  pl:=get_plr(s.the_game,n);
  for i:=32 to 39 do
   s.colors.palpx[n][i]:=maxg_nearest_in_thepal(tcrgb(round(pl.info.color[2]*((40-i)/8*200)/255),
                                                      round(pl.info.color[1]*((40-i)/8*200)/255),
                                                      round(pl.info.color[0]*((40-i)/8*200)/255)));
 end;

 for i:=0 to 255 do s.colors.al_palpx[i]:=i;
 for i:=32 to 39 do s.colors.al_palpx[i]:=maxg_nearest_in_thepal(tcrgb(round(128*((40-i)/8*200)/255),
                                                                       round(128*((40-i)/8*200)/255),
                                                                       round(128*((40-i)/8*200)/255)));
 s.colors.clr_speed      :=maxg_nearest_in_thepal(tcrgb($00,$FF,$00));
 s.colors.clr_scan       :=maxg_nearest_in_thepal(tcrgb($CC,$FF,$00));
 s.colors.clr_scan_det   :=maxg_nearest_in_thepal(tcrgb($FF,$FF,$FF));
 s.colors.clr_range_land :=maxg_nearest_in_thepal(tcrgb($CC,$00,$00));
 s.colors.clr_range_water:=maxg_nearest_in_thepal(tcrgb($33,$00,$CC));
 s.colors.clr_range_air  :=maxg_nearest_in_thepal(tcrgb($EE,$99,$00));
 s.colors.clr_range_all  :=maxg_nearest_in_thepal(tcrgb($CC,$00,$00));
end;
//############################################################################//
procedure haltgame(s:psdi_rec);
begin try
 event_frame(s);
 s.steps.replay_mode:=false;
 s.active_events:=false;
 
 if s.state=CST_THEGAME then begin
  tolog('SDI','');
  tolog('SDI','Game mode closed');
  tolog('SDI','Graphics PostCleanup');
  stop_running_snd(s);
  dispose(s.the_game);
  s.the_game:=nil;
 end;           
 s.state:=CST_THEMENU;
 setlength(s.pmap,0);
 setlength(s.rpmap,0);

 clear_map(s);
 clean_to_menu(s,MS_MAINMENU);
 iresetgui(s);
 
 except stderr(s,'SDI','HaltGame');end;
end;     
//############################################################################//
procedure preinit_stuff(s:psdi_rec);
begin
 s.now_loading:=true;
 s.pstate:=-99;
 s.hide_interface:=false;

 event_frame(s);
 event_units(s);
 event_map_reposition(s);    

 s.mainmap.maxzoom:=max_zoom(s);

 resize_planes(s,scrx,scry);
 
 event_map_reposition(s);
 event_frame(s);
 
 if s.state=CST_THEGAME then calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);
 //

 s.rmov:=false;
 s.entered_password:='';

 //clear_menu;
 
 //FIXME: Find a better place?
 clear_anim_units(s);
   
 clear_load_box(s);
 write_load_box(s,'');
 write_load_box(s,po('Maxgold launched'));
end;
//############################################################################//
procedure schedule_game_connect(s:psdi_rec);  
begin
 add_step(@s.steps,sts_alloc_game);  
 add_step(@s.steps,sts_fetch_ginfo);  
 add_step(@s.steps,sts_initialize_game);  
 
 add_step(@s.steps,sts_fetch_gstate);
 add_step(@s.steps,sts_fetch_plrshort);
  
 add_step(@s.steps,sts_fetch_passmap);
 add_step(@s.steps,sts_load_map);
 
 add_step(@s.steps,sts_fetch_clans);
 add_step(@s.steps,sts_fetch_udb);
 add_step(@s.steps,sts_load_udb);  

 add_step(@s.steps,sts_fetch_plrshort);   //To get the casualties...
 add_step(@s.steps,sts_fetch_resmap);     //For direct landing. FIXME: Should we check for in in the rules? Or are rules not known at this point?
       
 add_step(@s.steps,sts_get_to_reentry);
end;
//############################################################################//
procedure init_new_game(s:psdi_rec);   
begin
 preinit_stuff(s);

 //Needed for checks in direct landing and mgl_buy to work, i.e. is_beginable_unit looks for no_buy_atk
 //FIXME: Also in do_player_landing
 //No need: sts_fetch_gstate effectively does that already.
 //s.the_game.info.rules:=s.newgame.rules;

 add_step(@s.steps,sts_new_game);
 schedule_game_connect(s);
end;
//############################################################################//
procedure init_game_load(s:psdi_rec;id:string);
begin
 preinit_stuff(s);
 load_id:=id;
 schedule_game_connect(s);
end;
//############################################################################//
procedure reset_interface(s:psdi_rec);
begin try
 //GUI Interface cleanup   
 menu_all_deinit(s); 
 clear_gui;
 
 //Options  
 lrus:=(lowercase(s.cg.lang)='rus');
 leng:=(lowercase(s.cg.lang)='eng');
 cur_lng:=ord(lrus)+(ord(leng) shl 1);
 prv_lng:=cur_lng;
          
 //GUI Interface init
 menu_all_init(s);  

 event_frame(s);

 except stderr(s,'SDIInit','ResetGUI');end;
end;
//############################################################################//
procedure resetgui(s:psdi_rec);
begin try
 //Pages and buttons
 setlength(s.rmnu_state,10);
 s.show_comments:=false;
 s.gm_comment_mode:=false;
        
 s.mainmap.colorzoom:=8;
 s.mainmap.bld_zoom_1:=s.mainmap.colorzoom-6;
 s.mainmap.bld_zoom_2:=s.mainmap.colorzoom-4;

 s.ignore_mouseup:=false;
 s.ignore_mousemove:=false;
 
 s.entered_password:='';

 reset_interface(s); 
 
 except stderr(s,'SDIInit','ResetGUI');end;
end;
//############################################################################//
procedure pre_load_grps(s:psdi_rec);
begin  
 init_grtools(s);
 load_pal(s);   
 load_fonts(s.cg);   
 
 setlength(s.cg.curs,length(curs_lst));  
 setlength(s.cg.grap,length(grap_lst));     
 setlength(s.cg.grapu,gru_count);
 fillchar(s.cg.curs[0],length(s.cg.curs)*sizeof(pointer),0);    
 fillchar(s.cg.grap[0],length(s.cg.grap)*sizeof(pointer),0); 
 fillchar(s.cg.grapu[0],length(s.cg.grapu)*sizeof(pointer),0);
 fillchar(s.cg.raw_bkgr[0],length(s.cg.raw_bkgr)*sizeof(pointer),0);
 fillchar(s.cg.scaled_bkgr[0],length(s.cg.scaled_bkgr)*sizeof(pointer),0);
end;
//############################################################################//
procedure load_grps(s:psdi_rec);
begin
 tolog('SDI','Main graphics block');
 resize_planes(s,scrx,scry);
 init_graph(s);
 tolog('SDI','Main graphics loaded');
end;
//############################################################################//
procedure default_settings(s:psdi_rec);
begin
 {$ifdef embedded}
 snd_on:=false;
 snd_muson:=false;
 max_fps:=61;

 s.cg.mapedge:=false;

 gs_server:='127.0.0.1';
 gs_port:=18008;

 {$else}
 snd_on:=true;
 snd_muson:=true;
 max_fps:=31;
 s.cg.mapedge:=true;
 {$endif}
 
 fpsdbg:=true;
 use_scaling:=false;
 {$ifndef embedded}scrx:=800;scry:=600;{$endif}
 s.cg.msg_density:=50/100;
 s.cg.fow_density:=63/100;
 s.cg.shadow_density:=70/100;
 s.ut_circles:=true;
 s.ut_squares:=true;
 s.ut_at_end_move:=true;
 s.center_zoom:=true;
 s.cg.load_unit_sounds:=false;

 s.cg.lang:='rus';
 s.cg.show_cursor:=true;
 s.cg.fog_of_war:=true;
 s.cg.unit_shadows:=true;

 s.zoomspd:=1;
 s.runcnt:=0;
 s.resdbg:=true;
 
 s.steps.replay_mode:=false;
 s.active_events:=false;
 s.now_loading:=false;
 s.pending_resize:=false;
 s.unisets_loaded:=false;

 sds_reset(@s.steps);

 s.mainmap.background_fill_color:=48;
end;
//############################################################################//
procedure maininit(s:psdi_rec);
var st:string;
i:integer;
begin
 on_selection_changed:=@selection_changed;
 menu_callback:=@sdi_coremenu_callback;
 mgl_common.on_unit_event:=@on_unit_event;

 st:='SDI M.A.X. Gold graphics V'+sdi_progver+' started';
 tolog('SDI',st);
 tolog('','');
 tolog('SDI','Loading...');   

 s.cur_menu:=MS_MAINMENU;
 s.cur_cur:=CUR_POINTER;
 s.loaded_uniset:=false;
 for i:=0 to length(s.auxun)-1 do s.auxun[i]:=nil;
 
 event_frame(s);

 default_settings(s);
 loadsetup(s);

 {$ifdef embedded}s.cg.mapedge:=false;{$endif}
 {$ifdef darwin}s.cg.mapedge:=false;{$endif}
 {$ifdef android}s.cg.mapedge:=false;{$endif}
 s.runcnt:=s.runcnt+1; 

 loadlang(s);
 loadint(s);
 fill_transparency_cache(s.cg);
  
 tolog('SDI','Finished init');
end;
//############################################################################//
begin
 iresetgui:=resetgui;
end.
//############################################################################//
