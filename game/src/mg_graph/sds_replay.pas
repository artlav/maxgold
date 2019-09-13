//############################################################################//
unit sds_replay;
interface
uses asys,strval,json,sdirecs,sdiinit,sdiauxi,sdicalcs,sds_util,sds_rec,sds_net,sds_replies,mgrecs,mgl_json,mgl_common;
//############################################################################//
procedure rep_prev_turn(s:psdi_rec;start:boolean);
procedure rep_next_turn(s:psdi_rec);
procedure sds_replay_game(s:psdi_rec;name:string);
//############################################################################//
implementation
//############################################################################//
procedure rep_prev_turn(s:psdi_rec;start:boolean);
var i,n:integer;
begin
 n:=-1;
 for i:=0 to s.rep.endturn_count-2 do if (s.rep.pos>=s.rep.turns[i])and(s.rep.pos<s.rep.turns[i+1]) then begin n:=i;break;end;
 if n=-1 then if s.rep.pos>s.rep.turns[s.rep.endturn_count-1] then n:=s.rep.endturn_count-2;

 if start then begin
  n:=n; //Roll back to the current turn's start
 end else begin
  if s.rep.plr>-1 then n:=n-s.the_game.info.plr_cnt else n:=n-1;
 end;

 if (n>=0)and(n<s.rep.endturn_count) then s.rep.pos:=s.rep.turns[n] else s.rep.pos:=s.rep.color_step;

 if s.rep.pos>=s.rep.sz then s.rep.pos:=s.rep.sz-1;
 if s.rep.pos<s.rep.color_step then s.rep.pos:=s.rep.color_step;
 //s.rep.pos:=s.rep.pos-1;

 clear_evented_units(s);
 clear_anim_units(s);
 s.rep.paused:=true;
 s.rep.skip_fetches:=true; 
 s.active_events:=false;
end;
//############################################################################//
procedure rep_next_turn(s:psdi_rec);
var i,n:integer;
begin
 n:=-1;
 for i:=0 to s.rep.endturn_count-2 do if (s.rep.pos>=s.rep.turns[i])and(s.rep.pos<s.rep.turns[i+1]) then begin n:=i;break;end;

 if s.rep.plr>-1 then n:=n+s.the_game.info.plr_cnt else n:=n+1;

 if (n>=0)and(n<s.rep.endturn_count) then begin
  s.rep.pos:=s.rep.turns[n];

  if s.rep.pos>=s.rep.sz then s.rep.pos:=s.rep.sz-1;
  if s.rep.pos<s.rep.color_step then s.rep.pos:=s.rep.color_step;
  //s.rep.pos:=s.rep.pos-1;
 end;

 clear_evented_units(s);
 clear_anim_units(s);
 s.rep.paused:=true; 
 s.rep.skip_fetches:=true;
 s.active_events:=false;
end;
//############################################################################//
function parse_replay(sd:psdi_rec;name,data:string):replay_rec;
var s,st:string;
i,sz:integer;
was_plrshort:integer;
was_passmap,was_udb,was_ginfo:boolean;
cjs:pjs_node;
begin
 result.js:=nil;
 if name='' then exit;

 cjs:=js_parse(data);
 if cjs=nil then exit;
 sd.steps.step_progress:=0.1;
 data:=js_get_string(cjs,'compressed_log');
 sz:=vali(js_get_string(cjs,'size'));
 free_js(cjs);

 if data='nil' then exit;

 result.st:='{"log":['+decompress_string(data,sz)+']}';
 sd.steps.step_progress:=0.15;
 result.js:=js_parse(result.st);
 sd.steps.step_progress:=0.2;

 if result.js=nil then exit;

 result.sz:=js_get_node_length(result.js,'log');

 was_udb:=false;
 was_passmap:=false;
 was_ginfo:=false;
 was_plrshort:=0;

 result.init_step:=0;
 result.passmap_step:=0;
 result.udb_step:=0;
 result.reentry_step:=0;
 result.color_step:=0;

 result.endturn_count:=0;
 setlength(result.turns,result.sz);
 setlength(result.events,result.sz);
 setlength(result.reqs,result.sz);
 for i:=0 to result.sz-1 do begin
  sd.steps.step_progress:=0.2+0.8*i/result.sz;

  s:='log['+stri(i)+']';
  result.reqs[i]:=js_stringify(js_get_node(result.js,s));
  result.events[i]:=js_get_string(result.js,s+'.reply_to');

  st:=result.events[i];
  if st='end_turn' then begin
   //Skip non-turn-changing end_turn
   if js_get_string(result.js,s+'.changeover')='1' then begin
    result.turns[result.endturn_count]:=i;
    result.endturn_count:=result.endturn_count+1;
   end;
  end;

  if (st='fetch_ginfo')and(not was_ginfo) then begin was_ginfo:=true;result.init_step:=i;end;
  if (st='fetch_passmap')and(not was_passmap) then begin was_passmap:=true;result.passmap_step:=i;end;
  if (st='fetch_udb')and(not was_udb) then begin was_udb:=true;result.udb_step:=i;end;
  if st='fetch_plrshort' then begin
   was_plrshort:=was_plrshort+1;
   if was_plrshort=2 then result.reentry_step:=i;
   if was_plrshort=3 then result.color_step:=i;
  end;
 end;
 setlength(result.turns,result.endturn_count);


 result.pos:=-1;
 result.plr:=-1;
 result.turn_count:=result.endturn_count div 2;  //FIXME: What if more than two players?
 result.fast_replay:=false; 
 result.skip_replay:=false; 
 result.paused:=false;
 result.single_step:=false;
 result.skip_fetches:=false;
end;
//############################################################################//
procedure sds_replay_game(s:psdi_rec;name:string);
var st,rs:string;
i,prev_plr:integer;
begin
 if name='' then exit;

 sds_set_dual_message(@s.steps,po('Server is generating the replay')+'...',po('Downloading the replay'));

 st:=make_sys_request('get_replay',',"game_id":"'+name+'"}');
 sds_json_exchange(st,rs,@s.steps.step_progress,4);              //Extra waiting time here
 st:=rs;

 s.steps.step_progress:=0;
 sds_set_message(@s.steps,po('Parsing the replay')+'...');
 s.rep:=parse_replay(s,name,st);
 if s.rep.js=nil then exit;

 prev_plr:=-1;

 sds_set_message(@s.steps,'Running the replay...');
 s.steps.replay_mode:=true;

 preinit_stuff(s);
 alloc_game(s);

 while true do begin
  if not sds_is_replay(@s.steps) then break;

  mutex_lock(sds_mx);
  s.rep.pos:=s.rep.pos+1;
  i:=s.rep.pos;
  if s.rep.pos>=s.rep.sz then begin
   s.rep.pos:=s.rep.sz-1;
   s.rep.paused:=true;
   s.rep.fast_replay:=false;
   s.rep.skip_replay:=false;
   s.rep.single_step:=false;
   s.rep.skip_fetches:=false;
   mutex_release(sds_mx);
   sleep(1);
   continue;
  end;
  mutex_release(sds_mx);

  //s.rep.reqs[i]=log[i]
  //s.rep.events[i]=log[i].reply_to
  proc_reply(s,s.rep.reqs[i],false);

  if i=s.rep.init_step then initialize_game(s);
  if i=s.rep.passmap_step then do_load_map(s);
  if i=s.rep.udb_step then do_load_udb(s);

  if i=s.rep.reentry_step then begin
   do_player_reentry(s);
   sds_set_message(@s.steps,'*');
   s.steps.step_progress:=0;
  end;
  if i=s.rep.color_step then begin
   do_refresh_colors(s);
   s.rep.paused:=true;
   s.rep.skip_fetches:=true;
  end;

  if s.state=CST_INSGAME then begin s.state:=CST_THEGAME;clear_menu(s);end;


  if s.rep.plr<>-1 then begin
   if i>s.rep.color_step then begin
    mutex_lock(sds_mx);
    if s.the_game.state.cur_plr<>prev_plr then begin
     if prev_plr<>-1 then begin
      if s.the_game.state.cur_plr<>s.rep.plr then begin
       //s.skip_replay:=true;
       rep_next_turn(s);   
       if s.rep.fast_replay then s.rep.paused:=false;
      end else begin
       s.rep.skip_replay:=false;
      end;
     end;
     prev_plr:=s.the_game.state.cur_plr;
    end;
    mutex_release(sds_mx);
   end;
  end else s.rep.skip_replay:=false;

  //If paused or in a menu, wait here.
  while (s.rep.paused) or ((i>s.rep.color_step)and(s.state=CST_THEGAME)and(s.cur_menu<>MG_NOMENU)) do begin
   //If asked for a single step, stop waiting once.
   if s.rep.paused and s.rep.single_step then begin
    s.rep.single_step:=false;
    break;
   end;
   //Skip fetches after end_turn
   if s.rep.paused and s.rep.skip_fetches then begin
    if (s.rep.pos<s.rep.sz-1) then if (copy(s.rep.events[s.rep.pos+1],1,6)='fetch_')or(copy(s.rep.events[s.rep.pos+1],1,5)='land_') then break;
    s.rep.skip_fetches:=false;
   end;
   sleep(1);
   if not sds_is_replay(@s.steps) then break;
  end;
  if not replay_skip(s) and (i>=10) then sleep(50);
  if not sds_is_replay(@s.steps) then break;
 end;

 s.steps.replay_mode:=false;
 s.steps.dumping_steps:=true;

 free_js(s.rep.js);
end;
//############################################################################//
begin
end.
//############################################################################//
