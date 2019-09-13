//############################################################################//
unit mgl_actions;
interface
uses asys,mgrecs,mgl_common,sds_rec;
//############################################################################//
procedure act_set_move_unit(g:pgametyp;u:ptypunits;xt,yt:integer;isstd:boolean=false;stop_task:integer=stsk_none;stop_target:integer=0;stop_param:integer=0);
procedure act_unstore(g:pgametyp;u:ptypunits;xt,yt:integer);
procedure act_add_comment(g:pgametyp;global:boolean;x,y:integer;text:string);
procedure act_dbg_place_unit(g:pgametyp;x,y,un:integer;full,delete:boolean);
procedure act_dbg_boom_unit(g:pgametyp;un:integer);
procedure act_land_player(g:pgametyp;start:pplayer_start_rec);

procedure act_finish_build(g:pgametyp;ox,oy:integer;u:ptypunits);

procedure act_startunit(g:pgametyp;u:ptypunits);
procedure act_stop_action(g:pgametyp;u:ptypunits;stop_anyway:boolean);
procedure act_stop_motion(g:pgametyp;u:ptypunits);
procedure act_unit_done(g:pgametyp;u:ptypunits);
procedure act_unit_doze(g:pgametyp;u:ptypunits);
procedure act_unit_mining(g:pgametyp;u:ptypunits);
procedure act_unit_unmining(g:pgametyp;u:ptypunits);

procedure act_toolunit(g:pgametyp;typ:integer;ua,ub:ptypunits);
procedure act_set_build(g:pgametyp;u:ptypunits;res_mat:integer);
procedure act_set_upgrades(g:pgametyp);
procedure act_xfer(g:pgametyp;ev:xfer_rec);
procedure act_store(g:pgametyp;ua,ub:ptypunits);
procedure act_move_close(g:pgametyp;ua,ub:ptypunits;range:integer);

procedure act_fire_to(g:pgametyp;u:ptypunits;xt,yt:integer;act:boolean);
procedure act_fire_at(g:pgametyp;u,ut:ptypunits;xt,yt:integer;act:boolean);
procedure act_change_research(g:pgametyp;act:boolean;a,b:integer);
//############################################################################//
implementation
//############################################################################//
procedure act_set_move_unit(g:pgametyp;u:ptypunits;xt,yt:integer;isstd:boolean=false;stop_task:integer=stsk_none;stop_target:integer=0;stop_param:integer=0);
var ev:move_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.xt:=xt;
 ev.yt:=yt;
 ev.isstd:=isstd;
 ev.stop_task:=stop_task;
 ev.stop_target:=stop_target;
 ev.stop_param:=stop_param;

 evt.mv:=ev;
 add_step_ev(g.grp_2,sts_move_unit,evt);
end;
//############################################################################//
procedure act_unstore(g:pgametyp;u:ptypunits;xt,yt:integer);
var ev:move_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.xt:=xt;
 ev.yt:=yt;
 ev.isstd:=false;
 ev.stop_task:=stsk_none;
 ev.stop_target:=0;
 ev.stop_param:=0;

 evt.mv:=ev;
 add_step_ev(g.grp_2,sts_move_unit,evt);
end;
//############################################################################//
procedure act_add_comment(g:pgametyp;global:boolean;x,y:integer;text:string);
var ev:comment_typ;
evt:event_rec;
begin
 ev.x:=x;
 ev.y:=y;
 ev.text:=text;
 ev.typ:=ord(global);
 ev.turn:=0; //Not used

 evt.com:=ev;
 add_step_ev(g.grp_2,sts_add_comment,evt);
end;
//############################################################################//
procedure act_dbg_place_unit(g:pgametyp;x,y,un:integer;full,delete:boolean);
var ev:dbgev_rec;
evt:event_rec;
begin
 ev.x:=x;
 ev.y:=y;
 ev.un:=un;
 ev.full:=full;
 ev.delete:=delete;
 ev.boom:=false;

 evt.dbg:=ev;
 add_step_ev(g.grp_2,sts_dbg_place_unit,evt);
end;
//############################################################################//
procedure act_dbg_boom_unit(g:pgametyp;un:integer);
var ev:dbgev_rec;
evt:event_rec;
begin
 ev.x:=0;
 ev.y:=0;
 ev.un:=un;
 ev.full:=false;
 ev.delete:=false;
 ev.boom:=true;

 evt.dbg:=ev;
 add_step_ev(g.grp_2,sts_dbg_place_unit,evt);
end;
//############################################################################//
procedure act_land_player(g:pgametyp;start:pplayer_start_rec);
begin
 add_step(g.grp_2,sts_land_player);
end;
//############################################################################//
procedure act_finish_build(g:pgametyp;ox,oy:integer;u:ptypunits);
var ev:move_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.xt:=ox;
 ev.yt:=oy;
 ev.isstd:=false;
 ev.stop_task:=stsk_none;
 ev.stop_target:=0;
 ev.stop_param:=0;

 evt.mv:=ev;
 add_step_ev(g.grp_2,sts_move_unit,evt);
end;
//############################################################################//
procedure act_startunit(g:pgametyp;u:ptypunits);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=false;
 ev.start:=true;
 ev.done:=false;
 ev.doze:=false;
 ev.anyway:=false;
 ev.mine_add:=false;
 ev.mine_rem:=false;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_stop_action(g:pgametyp;u:ptypunits;stop_anyway:boolean);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=false;
 ev.start:=false;
 ev.done:=false;
 ev.doze:=false;
 ev.anyway:=stop_anyway;
 ev.mine_add:=false;
 ev.mine_rem:=false;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_stop_motion(g:pgametyp;u:ptypunits);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=true;
 ev.start:=false;
 ev.done:=false;
 ev.doze:=false;
 ev.anyway:=false;
 ev.mine_add:=false;
 ev.mine_rem:=false;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_unit_done(g:pgametyp;u:ptypunits);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=false;
 ev.start:=false;
 ev.done:=true;
 ev.doze:=false;
 ev.anyway:=false;
 ev.mine_add:=false;
 ev.mine_rem:=false;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_unit_doze(g:pgametyp;u:ptypunits);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=false;
 ev.start:=false;
 ev.done:=false;
 ev.doze:=true;
 ev.anyway:=false;
 ev.mine_add:=false;
 ev.mine_rem:=false;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_unit_mining(g:pgametyp;u:ptypunits);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=false;
 ev.start:=false;
 ev.done:=false;
 ev.doze:=false;
 ev.anyway:=false;
 ev.mine_add:=true;
 ev.mine_rem:=false;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_unit_unmining(g:pgametyp;u:ptypunits);
var ev:startstop_rec;
evt:event_rec;
begin
 ev.un:=u.num;
 ev.motion:=false;
 ev.start:=false;
 ev.done:=false;
 ev.doze:=false;
 ev.anyway:=false;
 ev.mine_add:=false;
 ev.mine_rem:=true;

 evt.ss:=ev;
 add_step_ev(g.grp_2,sts_start_stop,evt);
end;
//############################################################################//
procedure act_toolunit(g:pgametyp;typ:integer;ua,ub:ptypunits);
var ev:tool_rec;
evt:event_rec;
begin
 if ua=nil then exit;
 if ub=nil then exit;

 ev.typ:=typ;
 ev.ua:=ua.num;
 ev.ub:=ub.num;

 evt.tl:=ev;
 add_step_ev(g.grp_2,sts_tool,evt);
end;
//############################################################################//
procedure act_set_build(g:pgametyp;u:ptypunits;res_mat:integer);
var evt:event_rec;
begin
 evt.un:=u.num;
 u.reserve:=res_mat;
 add_step_ev(g.grp_2,sts_set_build,evt);
end;
//############################################################################//
procedure act_set_upgrades(g:pgametyp);
begin
 add_step(g.grp_2,sts_set_upgrades);
 add_step(g.grp_2,sts_fetch_plrall);
end;
//############################################################################//
procedure act_xfer(g:pgametyp;ev:xfer_rec);
var evt:event_rec;
begin
 evt.xf:=ev;
 add_step_ev(g.grp_2,sts_xfer,evt);
end;
//############################################################################//
procedure act_store(g:pgametyp;ua,ub:ptypunits);
var ev:tool_rec;
evt:event_rec;
begin
 if ua=nil then exit;
 if ub=nil then exit;

 ev.typ:=0;
 ev.ua:=ua.num;
 ev.ub:=ub.num;

 evt.tl:=ev;
 add_step_ev(g.grp_2,sts_store,evt);
end;
//############################################################################//
procedure act_move_close(g:pgametyp;ua,ub:ptypunits;range:integer);
var ev:tool_rec;
evt:event_rec;
begin
 if ua=nil then exit;
 if ub=nil then exit;

 ev.typ:=range;
 ev.ua:=ua.num;
 ev.ub:=ub.num;

 evt.tl:=ev;
 add_step_ev(g.grp_2,sts_move_close,evt);
end;
//############################################################################//
procedure act_fire_to(g:pgametyp;u:ptypunits;xt,yt:integer;act:boolean);
var ev:fire_rec;
evt:event_rec;
begin
 if u=nil then exit;

 ev.typ:=0;
 ev.ua:=u.num;
 ev.ub:=-1;
 ev.x:=xt;
 ev.y:=yt;
 ev.act:=act;

 evt.fr:=ev;
 add_step_ev(g.grp_2,sts_fire,evt);
end;
//############################################################################//
procedure act_fire_at(g:pgametyp;u,ut:ptypunits;xt,yt:integer;act:boolean);
var ev:fire_rec;
evt:event_rec;
begin
 if u=nil then exit;
 if ut=nil then exit;

 ev.typ:=1;
 ev.ua:=u.num;
 ev.ub:=ut.num;
 ev.x:=xt;
 ev.y:=yt;
 ev.act:=act;

 evt.fr:=ev;
 add_step_ev(g.grp_2,sts_fire,evt);
end;
//############################################################################//
procedure act_change_research(g:pgametyp;act:boolean;a,b:integer);
var ev:research_rec;
evt:event_rec;
begin
 ev.change:=act;
 ev.a:=a;
 ev.b:=b;

 evt.rs:=ev;
 add_step_ev(g.grp_2,sts_research,evt);
end;
//############################################################################//
begin
end.
//############################################################################//
