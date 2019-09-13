//############################################################################//
unit mgs_srv;
interface    
uses asys,mgs_net,log,json
{$ifdef srv_stat},tim{$endif}
,mgrecs
,mgs_util,mgs_sys,mgs_fetch,mgs_act,mgs_db
,mgvars
; 
//############################################################################//
function do_mg_server(req:string;out res:string):boolean;
//############################################################################//
implementation
//############################################################################//
function process_req(js:pjs_node;g:pgametyp;req,pass,ng_id:string;mk_log,print:boolean;out storage:boolean):string;
begin
 result:=start_reply(MGSTATUS_ERR)+',"error":"Invalid request"}';
 storage:=false;

 if req='nil'           then begin result:=start_reply(MGSTATUS_ERR)+',"error":"Parse error"}';exit; end;
 
 if req='get_unisets'   then begin result:=get_unisets;             exit;end;
 if req='get_def_rules' then begin result:=get_def_rules;           exit;end;
 if req='get_maps'      then begin result:=get_maps;                exit;end;  
 if req='get_games'     then begin result:=get_games(js);           exit;end;  
 if req='get_replay'    then begin result:=get_replay(js);          exit;end;  
 if req='get_the_map'   then begin result:=get_the_map(js);         exit;end;  
 if req='get_minimap'   then begin result:=get_minimap(js);         exit;end;  
 if req='get_minimaps'  then begin result:=get_minimaps(js);        exit;end;  
 
 if req='new_game'      then begin result:=new_game(js,ng_id,print);  storage:=true;exit;end;
  
 if g<>nil then begin
  if req='fetch_clans'    then begin result:=fetch_clans(g);          storage:=true;exit;end;
  if req='fetch_udb'      then begin result:=fetch_udb(g);            storage:=true;exit;end;
  if req='fetch_passmap'  then begin result:=fetch_passmap(g);        storage:=true;exit;end;
  if req='fetch_plrshort' then begin result:=fetch_plrshort(g);       storage:=true;exit;end;
  if req='fetch_ginfo'    then begin result:=fetch_ginfo(g);          storage:=true;exit;end;
  if req='fetch_gstate'   then begin result:=fetch_gstate(g);         storage:=true;exit;end;
  if req='fetch_resmap'   then begin result:=fetch_resmap(g);         storage:=true;exit;end;    
  if req='land_player'    then begin result:=do_land_player(g,js);    storage:=true;exit;end;
 
  if game_auth(g,pass) then begin
   if req='surrender'     then begin result:=do_surrender(g,mk_log);  storage:=true;exit;end;  
   if req='end_turn'      then begin result:=do_end_turn(g,mk_log);   storage:=true;exit;end;  
   if req='fetch_units'   then begin result:=fetch_units(g,js);       storage:=true;exit;end;
   if req='fetch_plrall'  then begin result:=fetch_plrall(g);         storage:=true;exit;end;
   if req='fetch_plrcomm' then begin result:=fetch_plrcomm(g);        storage:=true;exit;end;
   if req='fetch_log'     then begin result:=fetch_log(g,js);         storage:=true;exit;end;
   
   if req='fetch_cdata'   then begin result:=fetch_cdata(g);          storage:=true;exit;end;
   if req='set_cdata'     then begin result:=set_cdata(g,js,mk_log);  storage:=true;exit;end;
   if req='add_comment'   then begin result:=do_add_comment(g,js);    storage:=true;exit;end;
   
   if req='move_unit'     then begin result:=do_move_unit(g,js);      storage:=true;exit;end;
   if req='dbg_place_unit'then begin result:=do_dbg_place_unit(g,js); storage:=true;exit;end;
   if req='start_stop'    then begin result:=do_start_stop(g,js);     storage:=true;exit;end;
   if req='set_build'     then begin result:=do_set_build(g,js);      storage:=true;exit;end;
   if req='set_upgrades'  then begin result:=do_set_upgrades(g,js);   storage:=true;exit;end;
   if req='xfer'          then begin result:=xfer(g,js);              storage:=true;exit;end;
   if req='tool'          then begin result:=tool(g,js);              storage:=true;exit;end;
   if req='store'         then begin result:=store(g,js);             storage:=true;exit;end;
   if req='move_close'    then begin result:=move_close(g,js);        storage:=true;exit;end; 
   if req='fire'          then begin result:=do_fire(g,js);           storage:=true;exit;end;
   if req='research'      then begin result:=research(g,js);          storage:=true;exit;end;
  end else begin
   result:=start_reply(MGSTATUS_AUTHERR)+',"error":"Authentification failure"}';
  end;
 end;
end;
//############################################################################//
function do_request(cont,ng_id:string;mk_log,skip_fetches,mk_client_log,print,make_reply:boolean):string;
var js:pjs_node;
req,code,remote_id,pass,reply:string;
g:pgametyp;
storage:boolean;   
{$ifdef srv_stat}rt:int64;{$endif}
begin
 result:='';
 js:=js_parse(cont);
                       
 req:=js_get_string(js,'request');
 code:=js_get_string(js,'code');
 pass:=js_get_string(js,'pass');    
 remote_id:=js_get_string(js,'game_id');
 
 if code<>server_code then begin    
  wr_log('Err',req);
  result:='{"status":0,"error":"Server auth error"}';
  free_js(js);
  exit;
 end;   
 
 if skip_fetches then if copy(req,1,6)='fetch_' then begin free_js(js);exit;end;

 g:=game_by_id(remote_id,true);   

 if mk_log then begin
  if g<>nil then wr_log(g.remote_id,req) else wr_log('Sys',req);
  if debug then wr_log('in',cont);  
 end;

 //If we are regenerating the state, then no need to generate replays.
 if g<>nil then g.make_reply:=make_reply;

 {$ifdef srv_stat}stdt(stat_dt);{$endif}
 reply:=process_req(js,g,req,pass,ng_id,mk_log,print,storage); 
 {$ifdef srv_stat}rt:=rtdt(stat_dt);add_req(req,rt);t_req:=t_req+rt;{$endif}
 reply:='{"reply_to":"'+req+'",'+reply;

 if storage and not skip_fetches then begin
  if req='new_game' then begin 
   free_js(js);
   js:=js_parse(reply);
   remote_id:=js_get_string(js,'game_id');
  end;       
  if mk_client_log then begin
   if mk_log then game_store(remote_id,cont,reply)
             else game_store(remote_id,'',reply);
  end else begin
   if mk_log then game_store(remote_id,cont,'');
  end;
 end;
 
 result:=reply;
 free_js(js);
end;
//############################################################################//
function do_mg_server(req:string;out res:string):boolean;
begin
 res:='';
 result:=false;
 mutex_lock(gd_mx);
 try
  res:=do_request(req,'',true,false,false,true,true);
  result:=true;
 except res:='Crash in mg_server';wr_log('ERR','Error in do_mg_server',false);  end;      
 mutex_release(gd_mx);
end;
//############################################################################//
begin
 ido_request:=do_request;
end.   
//############################################################################//
