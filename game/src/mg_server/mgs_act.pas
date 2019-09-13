//############################################################################//
unit mgs_act;
interface
uses asys,sysutils,strval,sds_rec,mgs_net,log,json
,mgrecs,mgl_common,mgl_json,mgl_res,mgl_tests,mgress
,mgunits,mgproduct,mgmotion,mg_builds
,mgs_util
;
//############################################################################//
function do_move_unit(g:pgametyp;js:pjs_node):string;
function do_dbg_place_unit(g:pgametyp;js:pjs_node):string;
function do_start_stop(g:pgametyp;js:pjs_node):string;
function do_set_build(g:pgametyp;js:pjs_node):string;
function do_set_upgrades(g:pgametyp;js:pjs_node):string;
function xfer(g:pgametyp;js:pjs_node):string;
function tool(g:pgametyp;js:pjs_node):string;
function research(g:pgametyp;js:pjs_node):string;
function store(g:pgametyp;js:pjs_node):string;
function move_close(g:pgametyp;js:pjs_node):string;
function do_fire(g:pgametyp;js:pjs_node):string;
//############################################################################//
implementation
//############################################################################//
function do_move_unit(g:pgametyp;js:pjs_node):string;
var ev:move_rec;
r:boolean;
u:ptypunits;
what:integer;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=move_from_json(js_get_node(js,'move'));

 r:=false;
 u:=get_unit(g,ev.un);
 if u<>nil then begin
  r:=true;
  if u.stored then begin
   r:=do_unstore(g,u,ev.xt,ev.yt);
  end else if u.isbuildfin then begin
   r:=finish_build(g,ev.xt,ev.yt,u);
  end else if (u.builds_cnt<>0)and(u.builds[0].sz=2)and(not u.isbuild) then begin
   what:=getdbnum(g,u.builds[0].typ);
   r:=false;
   if unavdb(g,what) then if can_build_rect_here(g,u,ev.xt,ev.yt,what) then begin
    u.prior_x:=u.x;
    u.prior_y:=u.y;
    unit_newpos(g,u,ev.xt,ev.yt,0);
    r:=set_build(g,u,u.reserve);
   end;
  end else begin
   if not u.isbuild then set_move_unit(g,u,ev.xt,ev.yt,ev.isstd,ev.stop_task,ev.stop_target,ev.stop_param);
  end;
 end;

 result:=produce_result(g,r);
end;
//############################################################################//
function do_dbg_place_unit(g:pgametyp;js:pjs_node):string;
var ev:dbgev_rec;
un:integer;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 if not g.info.rules.debug then begin
  result:=produce_result(g,false);
  exit;
 end;

 ev:=dbgev_from_json(js_get_node(js,'dbgev'));

 un:=ev.un;
 if ev.boom then begin
  boom_unit(g,get_unit(g,ev.un));
 end else begin
  if ev.delete then un:=-1;
  dbg_place_unit(g,ev.x,ev.y,un,ev.full);
 end;

 result:=produce_result(g,true);
end;
//############################################################################//
function do_start_stop(g:pgametyp;js:pjs_node):string;
var ev:startstop_rec;
un:integer;
r:boolean;
u:ptypunits;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=startstop_from_json(js_get_node(js,'startstop'));

 un:=ev.un;
 u:=get_unit(g,ev.un);
 if unav(u) then begin
  r:=true;
  if ev.start then begin
   r:=startunit(g,u,true,false);
  end else if ev.motion then begin
   stop_motion(g,u);
  end else if ev.done then begin
   if u.is_moving and u.isstd then begin
    u.isstd:=false;
    u.plen:=0;
   end;
  end else if ev.doze then begin
   setdoze(g,u);
  end else if ev.mine_add then begin
   mark_unit(g,u.num);
   u.is_bomb_removing:=false;
   if u.prod.now[RES_MAT]>0 then u.is_bomb_placing:=not u.is_bomb_placing;
  end else if ev.mine_rem then begin
   mark_unit(g,u.num);
   u.is_bomb_placing :=false;
   if u.prod.now[RES_MAT]<u.prod.num[RES_MAT] then u.is_bomb_removing:=not u.is_bomb_removing;
  end else begin
   r:=stop_action(g,get_unit(g,un),ev.anyway);
  end;
 end else r:=false;

 result:=produce_result(g,r);
end;
//############################################################################//
function do_set_build(g:pgametyp;js:pjs_node):string;
var i,un:integer;
r:boolean;
u:ptypunits;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 r:=false;
 un:=vali(js_get_string(js,'num'));
 u:=get_unit(g,un);
 if unav(u) then begin
  u.reserve:=vali(js_get_string(js,'reserve'));
  u.builds_cnt:=vali(js_get_string(js,'builds_cnt'));
  if u.builds_cnt>=length(u.builds) then u.builds_cnt:=length(u.builds)-1;
  for i:=0 to u.builds_cnt-1 do u.builds[i]:=builds_from_json(js_get_node(js,'builds['+stri(i)+']'));

  if u.builds_cnt<>0 then begin
   if u.builds[0].sz=1 then r:=set_build(g,u,u.reserve) else r:=true;
  end;
 end;

 result:=produce_result(g,r);
end;
//############################################################################//
function do_set_upgrades(g:pgametyp;js:pjs_node):string;
var i,n,k,diff:integer;
r:boolean;
cp:pplrtyp;
u:typ_unupd;
un:ptypunits;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 r:=false;
 cp:=get_cur_plr(g);
 if cp<>nil then begin
  if g.info.rules.direct_gold then begin
   un:=get_unit(g,vali(js_get_string(js,'unit')));
   diff:=vali(js_get_string(js,'gold'))-get_rescount(g,un,RES_GOLD,GROP_NOW);
   if diff<0 then take_res_now_minding(g,un,RES_GOLD,-diff) else put_res_now(g,un,RES_GOLD,diff,false);
  end else begin
   cp.gold:=vali(js_get_string(js,'gold'));
  end;

  n:=js_get_node_length(js,'unupd');
  for i:=0 to n-1 do begin
   u:=unupd_from_json(js_get_node(js,'unupd['+stri(i)+']'));
   k:=getdbnum(g,u.typ);
   if k<>-1 then cp.unupd[k]:=u;
  end;
 end;

 result:=produce_result(g,r);
end;
//############################################################################//
function xfer(g:pgametyp;js:pjs_node):string;
var ev:xfer_rec;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=xfer_from_json(js_get_node(js,'xfer'));

 do_xfer(g,get_unit(g,ev.ua),get_unit(g,ev.ub),@ev.cnt[0]);

 result:=produce_result(g,true);
end;
//############################################################################//
function tool(g:pgametyp;js:pjs_node):string;
var ev:tool_rec;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=tool_from_json(js_get_node(js,'tool'));

 do_toolunit(g,ev.typ,get_unit(g,ev.ua),get_unit(g,ev.ub));

 result:=produce_result(g,true);
end;
//############################################################################//
function research(g:pgametyp;js:pjs_node):string;
var ev:research_rec;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=research_rec_from_json(js_get_node(js,'research'));

 do_research(g);
 if ev.change then do_change_research(g,ev.a,ev.b);

 result:=start_reply(MGSTATUS_OK)+',"research":{'+research_to_json(g,get_cur_plr(g))+'}'+event_result(g)+'}';
end;
//############################################################################//
function store(g:pgametyp;js:pjs_node):string;
var ev:tool_rec;
r:boolean;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=tool_from_json(js_get_node(js,'store'));

 r:=do_store(g,get_unit(g,ev.ua),get_unit(g,ev.ub));

 result:=produce_result(g,r);
end;
//############################################################################//
function move_close(g:pgametyp;js:pjs_node):string;
var ev:tool_rec;
r:boolean;
u:ptypunits;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=tool_from_json(js_get_node(js,'move'));

 u:=get_unit(g,ev.ua);
 r:=do_move_closeup(g,get_unit(g,ev.ua),get_unit(g,ev.ub),ev.typ);
 if r then begin u.stop_task:=stsk_enter;u.stop_target:=ev.ub;end;

 result:=produce_result(g,r);
end;
//############################################################################//
function do_fire(g:pgametyp;js:pjs_node):string;
var ev:fire_rec;
r:boolean;
ua,ub:ptypunits;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 ev:=fire_from_json(js_get_node(js,'fire'));

 ua:=get_unit(g,ev.ua);
 ub:=get_unit(g,ev.ub);

 r:=false;
 if ua<>nil then case ev.typ of
  0:r:=do_order_firing_to(g,ua,ev.x,ev.y,ev.act);
  1:if ub<>nil then r:=do_order_firing_at(g,ua,ub,ev.x-ub.x,ev.y-ub.y,ev.act);
 end;

 result:=produce_result(g,r);
end;
//############################################################################//
begin
end.
//############################################################################//
