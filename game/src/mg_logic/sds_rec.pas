//############################################################################//
unit sds_rec;
interface
uses asys,mgrecs;
//############################################################################//
const
step_count=1024;  
//############################################################################//
sts_get_maps       =1;
sts_get_def_rules  =2;
sts_get_unisets    =3;
sts_save_def_rules =4;
sts_def_newgame    =5;
sts_new_game       =6;
sts_load_udb       =7;
sts_initialize_game=8;   
sts_fetch_clans    =9;
sts_fetch_udb      =10;
sts_fetch_resmap   =11;
sts_fetch_passmap  =12;
sts_player_landing =13;
sts_land_player    =14;    
sts_fetch_ginfo    =15;
sts_fetch_gstate   =16;
sts_fetch_all_units=17;
sts_refresh_colors =18;
sts_fetch_plrshort =19;
sts_move_unit      =20;
sts_dbg_place_unit =21;
sts_ask_end_turn   =22;
sts_start_stop     =23;
sts_load_map       =24; 
sts_set_build      =25;
sts_xfer           =26;
sts_tool           =27;
sts_store          =28;
sts_move_close     =29;
sts_fire           =30;
sts_set_upgrades   =31;    
sts_fetch_plrall   =32;  
sts_fetch_games    =33;   
sts_alloc_game     =34;
sts_get_to_reentry =35;
sts_check_updates  =36;
sts_get_updates    =37;
sts_load_grps      =38;  
sts_fetch_cdata    =39;
sts_set_cdata      =40;  
sts_enter_turn     =41;   
sts_surrender      =42;  
sts_fetch_finishes =43;
sts_research       =44;  
sts_check_updlog   =45;
sts_do_replay      =46;
sts_add_comment    =47;
sts_fetch_plrcomm  =48;
//############################################################################//
sew_hit       =1;
sew_boom      =2;
sew_stored    =3;
sew_unstored  =4;
sew_fire      =5;
sew_move      =6;
sew_act_stop  =7;
sew_act_start =8;
//############################################################################//
type   
//############################################################################//
move_rec=record
 un:integer;
 xt,yt:integer;
 isstd:boolean;
 stop_task,stop_target,stop_param:integer;
end;
pmove_rec=^move_rec;  
//############################################################################//
dbgev_rec=record
 x,y,un:integer;
 full,delete,boom:boolean
end;
pdbgev_rec=^dbgev_rec;
//############################################################################//
startstop_rec=record
 un:integer;
 motion,start,anyway,done,doze,mine_add,mine_rem:boolean;
end;
pstartstop_rec=^startstop_rec;
//############################################################################//   
xfer_rec=record           
 ua,ub:integer;
 cnt:array[0..3]of integer;
end;
pxfer_rec=^xfer_rec;  
//############################################################################//   
tool_rec=record           
 typ,ua,ub:integer;
end;
ptool_rec=^tool_rec;  
//############################################################################//   
fire_rec=record           
 typ,ua,ub:integer;
 x,y:integer;
 act:boolean;
end;
pfire_rec=^fire_rec;
//############################################################################//
research_rec=record
 change:boolean;
 a,b:integer;
end;
presearch_rec=^research_rec;   
//############################################################################//
event_rec=record
 tp:integer;
 un:integer;
 mv:move_rec;
 dbg:dbgev_rec;
 ss:startstop_rec;
 xf:xfer_rec;
 tl:tool_rec;
 fr:fire_rec;
 rs:research_rec;
 com:comment_typ;
end;
//############################################################################//
step_rec=record
 tp:integer;
 ev:event_rec;
end;
//############################################################################//
sds_sys=record
 replay_mode:boolean;
 steps:array[0..step_count-1]of step_rec;
 last_step_read:integer;
 last_step_write:integer;
 dumping_steps:boolean;
 step_message_wait:string;
 step_message_progress:string;
 step_progress:double;
 step_do_reset:boolean;
end;
psds_sys=^sds_sys;
//############################################################################//
function sds_is_replay(s:psds_sys):boolean;
procedure sds_reset(s:psds_sys);
procedure add_step(s:psds_sys;tp:integer);
procedure add_step_ev(s:psds_sys;tp:integer;ev:event_rec);
function fetch_step(s:psds_sys;out tp:integer;out ev:event_rec):boolean;
procedure free_step(s:psds_sys);
procedure dump_all_steps(s:psds_sys);
procedure sds_set_message(s:psds_sys;str:string);  
procedure sds_set_dual_message(s:psds_sys;str_wait,str_prog:string);
//############################################################################//
var sds_mx:mutex_typ;
//############################################################################//
implementation    
//############################################################################//
function sds_is_replay(s:psds_sys):boolean;begin result:=s.replay_mode;end;
//############################################################################//
procedure sds_reset(s:psds_sys);
begin
 s.last_step_read:=0;
 s.last_step_write:=0;
 s.dumping_steps:=false;
 s.step_message_wait:='';
 s.step_message_progress:='';
 s.step_progress:=-1;
 s.step_do_reset:=false;
end;
//############################################################################//
procedure add_step(s:psds_sys;tp:integer);
var n:integer;
begin
 if s.replay_mode then exit;
 n:=s.last_step_write;
 s.steps[n].tp:=tp;
 s.steps[n].ev.tp:=0;
 s.last_step_write:=(n+1) mod step_count;
end;                                                          
//############################################################################//
procedure add_step_ev(s:psds_sys;tp:integer;ev:event_rec);
var n:integer;
begin          
 if s.replay_mode then exit;
 n:=s.last_step_write;
 s.steps[n].tp:=tp;
 s.steps[n].ev:=ev;
 s.steps[n].ev.tp:=tp;
 s.last_step_write:=(n+1) mod step_count;
end;                                                     
//############################################################################//
function fetch_step(s:psds_sys;out tp:integer;out ev:event_rec):boolean;
var n:integer;
begin
 result:=false;
 if s.last_step_read=s.last_step_write then exit;
 n:=s.last_step_read;
 tp:=s.steps[n].tp;
 ev:=s.steps[n].ev;
 result:=true;
end;                                                
//############################################################################//
procedure free_step(s:psds_sys);
var n:integer;
begin        
 n:=s.last_step_read;
 s.steps[n].ev.tp:=0;
 s.last_step_read:=(n+1) mod step_count;
end;                                          
//############################################################################//
procedure dump_all_steps(s:psds_sys);
var tp:integer;
ev:event_rec;
begin
 while fetch_step(s,tp,ev) do free_step(s);
end;
//############################################################################//
procedure sds_set_message(s:psds_sys;str:string);
begin
 s.step_message_wait:=str;
 s.step_message_progress:=str;
end;
//############################################################################//
procedure sds_set_dual_message(s:psds_sys;str_wait,str_prog:string);
begin
 s.step_message_wait:=str_wait;
 s.step_message_progress:=str_prog;
end;
//############################################################################//
begin
end.
//############################################################################//
