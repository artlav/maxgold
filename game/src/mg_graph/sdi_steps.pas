//############################################################################//
unit sdi_steps;
interface
uses asys,strval
,sdirecs,sdiauxi,sdiinit,sdiloads,sdicalcs,sdisound,sds_util,sds_rec,sds_calls,si_multipl,sds_replies,sds_replay
,mgrecs,mgl_common,mgl_json
{$ifdef update},upd_cli{$endif}
;
//############################################################################// 
procedure sds_runthread(s:psdi_rec);
//############################################################################//
implementation
//############################################################################//
procedure do_player_landing(s:psdi_rec);
begin        
 if s.the_game=nil then exit;     
 
 mutex_lock(sds_mx);   
           
 s.state:=CST_THEGAME;
 clear_menu(s);

 verify_sopt(s);

 event_map_reposition(s);
 event_units(s);
 event_frame(s);

 //Needed for checks in direct landing to work, i.e. is_beginable_unit looks for no_buy_atk
 //FIXME: Also in init_new_game 
 //No need: sts_fetch_gstate effectively does that already.
 //s.the_game.info.rules:=s.newgame.rules;
 
 msgu_set(po('Select landing position')+'.',0);
 
 mutex_release(sds_mx);
end;
//############################################################################//
function sds_thfnc(s:psdi_rec):intptr;{$ifdef android}stdcall;{$else}{$ifdef unix}register;{$endif}{$endif}
var tp:integer;
ev:event_rec;    
s1:string;
u:ptypunits;
cp:pplrtyp;
post:boolean;
begin result:=0;tp:=0; try
 tolog('SDI','SDS thread running');
 post:=false;
 
 //result:=0;
 while not stop_threads do begin
  if not fetch_step(@s.steps,tp,ev) then begin sleep(1);continue;end;
  case tp of
   sts_load_grps:begin    
    sds_set_message(@s.steps,'Loading graphics');   
    load_grps(s);   
    resetgui(s);    
    mutex_lock(sds_mx);  
    event_frame(s);
    s.now_loading:=false;   
    mutex_release(sds_mx);
   end;

   sts_do_replay:sds_replay_game(s,load_id);
  
   sts_get_maps:      begin sds_set_message(@s.steps,'Fetching maps');         sys_request(s,'get_maps'     ,'');end;
   sts_get_def_rules: begin sds_set_message(@s.steps,'Fetching default rules');sys_request(s,'get_def_rules','');end;
   sts_get_unisets:   begin sds_set_message(@s.steps,'Fetching unisets');      sys_request(s,'get_unisets'  ,'');end;
   sts_fetch_games:   begin sds_set_message(@s.steps,'Fetching games list');   sys_request(s,'get_games'    ,',"finished":0');end;
   sts_fetch_finishes:begin sds_set_message(@s.steps,'Fetching games list');   sys_request(s,'get_games'    ,',"finished":1');end;
   sts_new_game:      begin sds_set_message(@s.steps,'Requesting new game');   sys_request(s,'new_game'     ,',"newgame":'+newgame_to_json(@s.newgame));end;
                        
   sts_save_def_rules:;////mg_save_def_rules(@def_rules);
   sts_def_newgame:default_newgame(s);
   sts_alloc_game:alloc_game(s);   
   sts_initialize_game:initialize_game(s);
   sts_get_to_reentry:do_player_reentry(s);
   sts_load_map:do_load_map(s);
                                 
   sts_fetch_all_units:do_fetch_units(s,'');
     
   sts_fetch_plrall:  begin sds_set_message(@s.steps,'Fetching player info'); game_request(s,'fetch_plrall'  ,'');end; 
   sts_fetch_plrshort:begin sds_set_message(@s.steps,'Fetching players');     game_request(s,'fetch_plrshort','');end;
   sts_fetch_plrcomm: begin sds_set_message(@s.steps,'Fetching player extra');game_request(s,'fetch_plrcomm' ,'');end;
   sts_fetch_clans:   begin sds_set_message(@s.steps,'Fetching clans');       game_request(s,'fetch_clans'   ,'');end;
   sts_fetch_udb:     begin sds_set_message(@s.steps,'Fetching uniset');      game_request(s,'fetch_udb'     ,'');end;
   sts_fetch_resmap:  begin sds_set_message(@s.steps,'Fetching resource map');game_request(s,'fetch_resmap'  ,'');end;
   sts_fetch_passmap: begin sds_set_message(@s.steps,'Fetching pass map');    game_request(s,'fetch_passmap' ,'');end;
   sts_fetch_ginfo:   begin sds_set_message(@s.steps,'Fetching game info');   game_request(s,'fetch_ginfo'   ,'');end;
   sts_fetch_gstate:  begin sds_set_message(@s.steps,'Fetching game state');  game_request(s,'fetch_gstate'  ,'');end;
   sts_fetch_cdata:   begin sds_set_message(@s.steps,'Fetching cdata');       game_request(s,'fetch_cdata'   ,'');end;

   sts_player_landing:do_player_landing(s);  
   sts_land_player:do_land_player(s);
   sts_refresh_colors:do_refresh_colors(s);
                 
   sts_set_cdata:set_cdata(s);   
   sts_set_build:set_build(s,ev);
   sts_set_upgrades:set_upgrades(s,ev); 
    
   sts_ask_end_turn:   game_request(s,'end_turn','');
   sts_surrender:      game_request(s,'surrender','');
   sts_move_unit:      game_request(s,'move_unit',',"move":'+move_to_json(@ev.mv));
   sts_dbg_place_unit: game_request(s,'dbg_place_unit',',"dbgev":'+dbgev_to_json(@ev.dbg));
   sts_start_stop:     game_request(s,'start_stop',',"startstop":'+startstop_to_json(@ev.ss));
   sts_xfer:           game_request(s,'xfer',',"xfer":'+xfer_to_json(@ev.xf));
   sts_tool:           game_request(s,'tool',',"tool":'+tool_to_json(@ev.tl));
   sts_store:          game_request(s,'store',',"store":'+tool_to_json(@ev.tl));
   sts_move_close:     game_request(s,'move_close',',"move":'+tool_to_json(@ev.tl));
   sts_fire:           game_request(s,'fire',',"fire":'+fire_to_json(@ev.fr));
   sts_research:       game_request(s,'research',',"research":'+research_rec_to_json(@ev.rs));  
   sts_add_comment:    game_request(s,'add_comment',',"comment":'+comment_to_json(@ev.com));

   sts_enter_turn:begin
    mutex_lock(sds_mx); 
     
    cp:=get_cur_plr(s.the_game);
    s.state:=CST_THEGAME;   
    iresetgui(s);
    clear_menu(s);
 
    s1:=po('Start of turn')+' #'+stri(s.the_game.state.turn)+'.';
    if not is_landed(s.the_game,cp) then s1:=s1+'&'+po('Select landing position')+'.';
    msgu_set(s1,0);

    u:=get_sel_unit(s.the_game);
    if u<>nil then if u.isact then play_running_snd(s,u);
  
    event_frame(s); 
    event_units(s);
    event_map_reposition(s);
    mutex_release(sds_mx);
   end; 
   
   sts_load_udb:do_load_udb(s);
   
   {$ifdef update}
   sts_check_updates:begin
    s.steps.step_message_wait:=po('Checking for updates')+'...';
    s.steps.step_message_progress:=s.steps.step_message_wait;
    upd_net_check;
   end;
   sts_check_updlog:begin
    s.steps.step_message_wait:=po('Fetching changelog')+'...';
    s.steps.step_message_progress:=s.steps.step_message_wait;
    upd_net_get_log;
   end;
   sts_get_updates:begin
    s.steps.step_message_wait:=po('Downloading updates');
    s.steps.step_message_progress:=s.steps.step_message_wait;
    s.steps.step_do_reset:=upd_net_download(@s.steps.step_progress);
   end;
   {$endif}
  end;
  post:=true;
  if not s.steps.dumping_steps then free_step(@s.steps);
  if s.steps.dumping_steps then dump_all_steps(@s.steps);
  s.steps.dumping_steps:=false;
  s.steps.step_message_wait:='';
  s.steps.step_message_progress:='';
  s.steps.step_progress:=-1;
  event_frame(s);
 end;

 dump_all_steps(@s.steps);
 
 except mbox(s,'Mga sds: '+po('crerr')+' '+stri(tp)+' '+stri(ord(post)),po('err')); halt; end;
end;
//############################################################################//
procedure sds_runthread(s:psdi_rec);
{$ifndef unix}var th:intptr;{$endif}
begin
 sds_mx:=mutex_create;
 {$ifndef unix}
 beginthread(nil,4*1024*1024,@sds_thfnc,s,0,th);
 {$else}
 beginthread(@sds_thfnc,s);
 {$endif}           
end;
//############################################################################//
begin
end.     
//############################################################################//
