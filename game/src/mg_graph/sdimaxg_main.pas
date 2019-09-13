//############################################################################//
//MaxGold SDI client main
//############################################################################//
unit sdimaxg_main;
interface
uses sysutils,asys,grph,png,log
,sdisdl,sdi_rec

{$ifdef linkdirect},mgs_core{$endif}

,mgrecs
,mgl_common
,sdirecs,sdiauxi,sdigui,sdisound,sdiinit,sdigrinit,sdiloads,sdicalcs
,sdi_steps,sds_util,sds_rec

,sdi_root

//Menus
,si_loadsave
,si_setup
,si_mapselect
,si_multipl
,si_rules
,si_options
,si_main
,si_about
,si_fnc
,si_interturn
,si_nothing
,si_xfer
,si_report
,si_depot
,si_build
,si_buyupg
,si_lab
,si_esc
,si_uniren
,si_debug
,si_colors
,si_unitinfo
,si_mine
,si_diplomat
,si_claninfo
,si_comment
,si_boom
,si_help
,si_setturn
;
//############################################################################//
procedure sdimaxg_start(s:psdi_rec);
//############################################################################//
implementation
//############################################################################//
procedure proc_palette(s:psdi_rec;ct,dt:double);
begin try
 //Animations
 palanim(s);
 setsdlpal;

 //Timings
 if sdicursor(-1)<>ord(s.cg.show_cursor) then sdicursor(ord(s.cg.show_cursor));
 s.anim_dt:=s.anim_dt+dt;
 s.msd_dt:=s.msd_dt+dt;

 except stderr(s,'sdimaxg_main','proc_palette');end;
end;
//############################################################################//
procedure mgsdi_mainloop(ct,dt:double);
begin try
 if not sdilock then exit;

 maxg_sdi_main(sdi_tag,curx,cury,ct,dt);

 if fpsdbg then begin ducnt:=tdu div 1000;tdu:=0;end;

 sdiunlock;
 sdiflip;
 proc_palette(sdi_tag,ct,dt);

 except mbox(sdi_tag,'mgsdi_mainloop: '+po('crerr'),po('err')); halt;end;
end;
//############################################################################//
procedure mainevent(evt,x,y:integer;key,shift:dword);
begin
 maxg_sdi_event(sdi_tag,evt,x,y,key,shift);
end;
//############################################################################//
procedure clean_mg_sdi(s:psdi_rec);
begin
 tolog('SDI','Graphics closed.');
 clear_sound; //Have to be first, or the unit sounds would crash on clean
 savsetup(s);
 clear_map(s);
 clear_units_grpdb(s);
 clear_gui;
 clear_graph(s);
 sdisdlquit;
 dispose(s.cg);
end;
//############################################################################//
procedure start_graphics;
var s:string;
begin
 tolog('SDI','Starting graphics...');

 s:='M.A.X. Gold'+'  '+sdi_progver;

 img_mainloop:=mgsdi_mainloop;
 sdifocusoff:=true;

 setsdi(scrx,scry,8,false,s,@mgsdi_mainloop,@mainevent);
end;
//############################################################################//
procedure sdimg_core_setup(s:psdi_rec);
begin
 sdi_tag:=s;
 s.inited:=false;

 filemode:=0;
 randomize;
 set_log('mga_sdi.log',sdi_log_console);
 tolog('LOG','Log started');
 {$ifdef i386}setup_fastmove;{$endif}

 {$ifdef linkdirect}mgs_set_server;{$endif}
end;
//############################################################################//
procedure sdimaxg_start(s:psdi_rec);
begin
 sdimg_core_setup(s);
 maininit(s);
 start_graphics;
 s.inited:=true;
 pre_load_grps(s);

 set_load_box_caption(s,'M.A.X. Gold'+' '+sdi_progver);
 s.now_loading:=true;

 sds_runthread(s);

 {$ifdef linkdirect}
 write_load_box(s,'Loading the server');set_load_bar_pos(s,0.01);sdi_handleinput;mgsdi_mainloop(0,0.01);sdi_handleinput;
 mgs_begin_server;
 {$endif}

 write_load_box(s,'Loading the game');
 set_load_bar_pos(s,0.05);

 add_step(@s.steps,sts_load_grps);

 //Won't block on some platforms, mind the ifdefs
 sdiloop;

 {$ifndef darwin}
  stop_threads:=true;
  clean_mg_sdi(s);
  {$ifdef linkdirect}mgs_clean_server;{$endif}
 {$endif}
end;
//############################################################################//
end.
//############################################################################//
