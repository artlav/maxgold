//############################################################################//
unit sds_replies;
interface
uses asys,strval,grph,json
,sdirecs,sdiloads,sdiauxi,sdiinit,sdicalcs,sdisound,sds_util,sds_rec,sds_net
,mgrecs,mgl_common,mgl_json,mgl_unu,mgl_scan,mgl_rmnu,mgl_attr,mgl_logs,mgl_land
,si_loadsave;
//############################################################################//
function replay_skip(s:psdi_rec):boolean;

procedure do_refresh_colors(s:psdi_rec);
procedure alloc_game(s:psdi_rec);
procedure initialize_game(s:psdi_rec);

procedure do_player_reentry(s:psdi_rec);
procedure do_load_map(s:psdi_rec);
procedure do_load_udb(s:psdi_rec);

procedure proc_status(s:psdi_rec;js:pjs_node);
procedure proc_event_result(s:psdi_rec;g:pgametyp;js:pjs_node);

procedure proc_reply(s:psdi_rec;rs:string;terminal:boolean);
//############################################################################//
implementation
uses sds_calls;
//############################################################################//
function replay_skip(s:psdi_rec):boolean;
begin
 result:=(s.rep.fast_replay or s.rep.skip_replay or s.rep.skip_fetches) and sds_is_replay(@s.steps);
end;
//############################################################################//
 //Init custom color when last player landing
procedure do_refresh_colors(s:psdi_rec);
var j:integer;
plj:pplrtyp;
begin
 mutex_lock(sds_mx);
 setlength(s.clinfo.custom_color8,get_plr_count(s.the_game)+1);
 setlength(s.clinfo.custom_color,get_plr_count(s.the_game)+1);
 for j:=0 to get_plr_count(s.the_game)-1 do begin
  plj:=get_plr(s.the_game,j);
  s.clinfo.custom_color[j+1]:=thepal[plj.info.color8];
  s.clinfo.custom_color8[j+1]:=plj.info.color8;
 end;
 pxpal_upd(s);
 mutex_release(sds_mx);
end;
//############################################################################//
procedure alloc_game(s:psdi_rec);
begin
 sds_set_message(@s.steps,'Allocating the game');

 s.active_events:=false;

 mutex_lock(sds_mx);
 new(s.the_game);
 fillchar(s.the_game^,sizeof(s.the_game^),0);
 s.the_game.grp_1:=s;
 s.the_game.grp_2:=@s.steps;
 s.the_game.remote_id:=load_id;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure initialize_game(s:psdi_rec);
var i:integer;
pl:pplrtyp;
begin
 sds_set_message(@s.steps,'Initializing the game');

 s.active_events:=false;

 mutex_lock(sds_mx);
 s.mapx:=s.the_game.info.mapx;
 s.mapy:=s.the_game.info.mapy;

 setlength(s.trk,0);

 alloc_clean_game(s.the_game);

 ////FIXME: Should be outside.
 for i:=0 to get_plr_count(s.the_game)-1 do begin
  pl:=get_plr(s.the_game,i);

  pl.num:=i;

  pl.info.color8:=i+1;
  pl.info.color:=thepal[pl.info.color8];

  alloc_clean_plr(s,s.the_game,pl);
 end;

 alloc_clean_clinfo(s,s.the_game);
 mutex_release(sds_mx);
end;
//############################################################################//
procedure do_player_reentry(s:psdi_rec);
begin
 sds_set_message(@s.steps,'Re-entering the game');
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);

 if s.the_game.state.status=GST_SETGAME then begin
  s.newgame.rules:=s.the_game.info.rules;

  s.newgame.plr_cnt:=s.the_game.info.plr_cnt;
  s.newgame.plr_names[s.the_game.state.cur_plr]:=s.the_game.plr[s.the_game.state.cur_plr].info.name;
  plr_begin:=s.the_game.plr[s.the_game.state.cur_plr].info;
 end;

 if not sds_is_replay(@s.steps) then begin
  enter_menu(s,MS_INTERTURN);
  s.state:=CST_INSGAME;
 end else begin
  s.state:=CST_THEGAME;
  clear_menu(s);
 end;
 s.now_loading:=false;
 reset_interface(s);

 verify_sopt(s);

 event_map_reposition(s);
 event_units(s);
 event_frame(s);

 mutex_release(sds_mx);
end;
//############################################################################//
procedure do_load_map(s:psdi_rec);
var k:smallint;
begin
 sds_set_message(@s.steps,'Loading map');
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 s.mapx:=s.the_game.info.mapx;
 s.mapy:=s.the_game.info.mapy;
 write_load_box(s,po('Starting game on the map')+' '+s.the_game.info.map_name);
 set_load_box_caption(s,po('Reading'));
 write_load_box(s,po('Loading map'));
 set_load_bar_pos(s,0.01);
 mutex_release(sds_mx);

 if not loadmap(s,s.the_game.info.map_name) then begin
  mutex_lock(sds_mx);
  mbox(s,'Loader: '+po('Error loading map'),po('Error'));
  clean_to_menu(s,MS_MAINMENU);
  s.steps.dumping_steps:=true;
  mutex_release(sds_mx);
  exit;
 end;

 mutex_lock(sds_mx);
 set_load_box_caption(s,po('Setting settings'));
 write_load_box(s,po('Configuring players'));
 set_load_bar_pos(s,0.09);

 s.mainmap.maxzoom:=max_zoom(s);

 calczoom(s,@s.mainmap,1);
 k:=1;
 calcmbrd(s,@s.mainmap,1,k,k);

 write_load_box(s,po('Starting game'));
 set_load_bar_pos(s,0.095);
 mutex_release(sds_mx);
end;
//############################################################################//
procedure do_load_udb(s:psdi_rec);
begin
 sds_set_message(@s.steps,'Loading units');
 set_load_box_caption(s,po('Loading units'));
 write_load_box(s,po('Loading units'));
 set_load_bar_pos(s,0.1);

 loadunits_grpdb(s,false);

 set_load_box_caption(s,po('Postinit'));
 write_load_box(s,po('Cleaning up'));
 pxpal_upd(s);
end;
//############################################################################//
//############################################################################//
procedure proc_status(s:psdi_rec;js:pjs_node);
var err:string;
st:integer;
begin
 if js=nil then exit;
 st:=vali(js_get_string(js,'status'));
 err:=js_get_string(js,'error');
 case st of
  2:begin
   if not s.mbox_on then mbox(s,'Authentification error ('+err+')',po('startgame'));
   s.state:=CST_INSGAME;
  end;
  else if not s.mbox_on then mbox(s,'Error ('+err+')','Error');
 end;
end;
//############################################################################//
//blastlen:double;
// if ud.blastlen=0 then ud.blastlen:=ud.siz*1.1;
procedure proc_events(s:psdi_rec;g:pgametyp;js:pjs_node);
var i,n:integer;
sew:sew_rec;
au:panim_unit_typ;
u:ptypunits;
ud:ptypunitsdb;
mods:pmods_rec;
last_no_wait:boolean;
begin
 last_no_wait:=false;
 if js=nil then exit;
 n:=js_get_node_length(js,'events');
 for i:=0 to n-1 do begin
  sew:=sew_from_json(js_get_node(js,'events['+stri(i)+']'));
  if replay_skip(s) then exit;
  if not last_no_wait then while s.active_events do sleep(1);  
  if replay_skip(s) then exit;
  mutex_lock(sds_mx);
  case sew.typ of
   sew_stored:begin
    u:=get_unit(g,sew.ua);
    if unav(u) then begin
     change_selection(s.the_game,u,get_unit(s.the_game,sew.ub));
     if assigned(on_unit_event) then on_unit_event(s,u,uevt_stored);
    end;
    u:=get_unit(g,sew.ub);
    if unav(u) then begin
     mods:=get_mods(s.the_game);
     ud:=get_unitsdb(s.the_game,u.dbn);
     if mods.fetch_command and (u.currently_stored>=ud.store_lnd+ud.store_wtr+ud.store_air+ud.store_hmn) then mods.fetch_command:=false;
    end;
   end;
   sew_unstored:begin
    u:=get_unit(g,sew.ua);
    //not unav cause it's not updated yet
    if u<>nil then if assigned(on_unit_event) then on_unit_event(s,u,uevt_unstored);
   end;
   sew_act_start:begin
    u:=get_unit(g,sew.ua);
    if unav(u) then if assigned(on_unit_event) then on_unit_event(s,u,uevt_started);
   end;
   sew_act_stop:begin
    u:=get_unit(g,sew.ua);
    if unav(u) then if assigned(on_unit_event) then on_unit_event(s,u,uevt_stopped);
   end;
   sew_fire:begin
    u:=get_unit(g,sew.ua);
    if unav(u) then begin
     s.active_events:=true;
     ud:=get_unitsdb(s.the_game,u.dbn);
     u.fires:=true;
     u.fire_timer:=0;
     if ud.isgun then u.grot:=getdirbydp(sew.x,u.x,sew.y,u.y) else u.rot:=getdirbydp(sew.x,u.x,sew.y,u.y);
     if assigned(on_unit_event) then on_unit_event(s,u,uevt_fire);
    end;
   end;
   sew_move:begin
    u:=get_unit(g,sew.ua);
    if unav(u) then begin
     s.active_events:=true;

     u.move_anim:=true;
     if sew.n=0 then u.move_vel:=0;
     u.mox:=0;
     u.moy:=0;
     u.xnt:=sew.x;
     u.ynt:=sew.y;
     u.rot:=getdirbydp(sew.x,u.x,sew.y,u.y);
    end;
   end;
   sew_hit:begin
    au:=add_anim_unit(s);
    if au<>nil then begin
     //s.active_events:=true;  //Blocks the boom
     au.used:=true;
     au.x:=sew.x;
     au.y:=sew.y;
     au.siz:=1;
     au.anim_timer:=-1;
     au.spr:=s.cg.grapu[GRU_HIT];
     au.animation_frames.x:=0;
     au.animation_frames.y:=4;
     au.animation_frames.z:=2;
     if assigned(on_unit_event) then on_unit_event(s,get_unit(g,sew.ua),uevt_hit);
    end;
   end;
   sew_boom:begin
    au:=add_anim_unit(s);
    if au<>nil then begin
     s.active_events:=true;
     //if i=n-1 then
     last_no_wait:=true;
     au.used:=true;
     au.x:=sew.x;
     au.y:=sew.y;
     au.siz:=sew.ub;
     au.anim_timer:=-1;
     au.animation_frames.x:=0;
     au.spr:=nil;
     case sew.n of
      0:au.spr:=s.cg.grapu[GRU_LANDEXP];
      1:begin au.spr:=s.cg.grapu[GRU_BLDEXP];au.siz:=2;end;
      2:au.spr:=s.cg.grapu[GRU_AIREXP];
      3:au.spr:=s.cg.grapu[GRU_SEAEXP];
      else continue;
     end;
     au.animation_frames.z:=1/(au.siz*1.1);
     au.animation_frames.y:=au.spr.cnt-1;
     au.siz:=1; ///WTF? Without it big  buildings explode with offset
     if assigned(on_unit_event) then on_unit_event(s,get_unit(g,sew.ua),uevt_boom);
    end;
   end;
  end;
  mutex_release(sds_mx);
 end;
 if not last_no_wait then while s.active_events do sleep(1);
end;
//############################################################################//
procedure proc_event_result(s:psdi_rec;g:pgametyp;js:pjs_node);
var st:string;
begin
 if js=nil then exit;

 if replay_skip(s) then exit;

 if js_get_node_length(js,'events')<>0 then proc_events(s,g,js);

 if not sds_is_replay(@s.steps) then begin
  if vali(js_get_string(js,'plr_event'))<>0 then game_request(s,'fetch_plrshort','');
  if vali(js_get_string(js,'log_event'))<>0 then fetch_log(s);
  if js_get_node_length(js,'update_list')<>0 then begin
   st:=list_to_list(js,'update_list');
   if st<>'' then do_fetch_units(s,st);
  end;
 end;
end;
//############################################################################//
procedure reply_get_games(s:psdi_rec;js:pjs_node);
var i,n:integer;
begin
 mutex_lock(sds_mx);
 n:=js_get_node_length(js,'games');
 setlength(games,n);
 for i:=0 to n-1 do begin
  games[i].id:=js_get_string(js,'games['+stri(n-1-i)+'].id');
  games[i].cur_plr:=js_get_string(js,'games['+stri(n-1-i)+'].cur_plr');
  games[i].cur_color:=js_get_string(js,'games['+stri(n-1-i)+'].cur_color');
  games[i].info:=ginfo_from_json(js_get_node(js,'games['+stri(n-1-i)+'].game_info'));
  games[i].state:=gstate_from_json(js_get_node(js,'games['+stri(n-1-i)+'].game_state'));
 end;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_get_unisets(s:psdi_rec;js:pjs_node);
var i:integer;
begin
 mutex_lock(sds_mx);
 s.uniset_count:=js_get_node_length(js,'unisets');
 setlength(s.unitsets,s.uniset_count);
 for i:=0 to s.uniset_count-1 do begin
  s.unitsets[i].name:=js_get_string(js,'unisets['+stri(i)+'].name');
  s.unitsets[i].descr_rus:=js_get_string(js,'unisets['+stri(i)+'].desc_rus');
  s.unitsets[i].descr_eng:=js_get_string(js,'unisets['+stri(i)+'].desc_eng');
 end;
 s.unisets_loaded:=true;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_get_def_rules(s:psdi_rec;js:pjs_node);
begin
 mutex_lock(sds_mx);
 s.def_rules:=rules_from_json(js_get_node(js,'rules'));
 s.got_def_rules:=true;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_get_maps(s:psdi_rec;js:pjs_node);
var i,nummaps:integer;
begin
 nummaps:=js_get_node_length(js,'maps');
 setlength(s.map_list,nummaps);
 for i:=0 to nummaps-1 do begin
  s.map_list[i].file_name:=js_get_string(js,'maps['+stri(i)+'].file_name');
  s.map_list[i].name     :=js_get_string(js,'maps['+stri(i)+'].name');
  s.map_list[i].descr    :=js_get_string(js,'maps['+stri(i)+'].descr');
 end;
 getmaps(s);
 mutex_lock(sds_mx);
 reset_interface(s);
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_udb(s:psdi_rec;js:pjs_node);
var i,j,n:integer;
pl:pplrtyp;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 n:=js_get_node_length(js,'udb');
 s.the_game.info.unitsdb_cnt:=n;
 setlength(s.the_game.unitsdb,n);
 for i:=0 to n-1 do begin
  s.the_game.unitsdb[i]:=unitsdb_from_json(js_get_node(js,'udb['+stri(i)+']'));
  //FIXME: Check!
  s.the_game.unitsdb[i].num:=i;
 end;
 for i:=0 to get_plr_count(s.the_game)-1 do begin
  pl:=get_plr(s.the_game,i);
  setlength(pl.unupd,s.the_game.info.unitsdb_cnt);
  setlength(pl.tmp_unupd,s.the_game.info.unitsdb_cnt);
  setlength(pl.u_num,s.the_game.info.unitsdb_cnt);
  setlength(pl.u_cas,s.the_game.info.unitsdb_cnt);
  for j:=0 to s.the_game.info.unitsdb_cnt-1 do begin
   pl.u_cas[j]:=0;
   pl.u_num[j]:=0;
  end;
 end;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_resmap(s:psdi_rec;js:pjs_node);
var x,y,xs,ys:integer;
st:string;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 xs:=vali(js_get_string(js,'resmap.xsize'));
 ys:=vali(js_get_string(js,'resmap.ysize'));
 //if(xs<>mapx)or(ys<>mapy)then error
 setlength(s.the_game.resmap,xs*ys);
 for y:=0 to ys-1 do begin
  st:=js_get_string(js,'resmap.map['+stri(y*2+0)+']');
  st:=unrle_map(st,xs);
  if length(st)<xs then continue;
  for x:=0 to xs-1 do s.the_game.resmap[x+y*xs].amt:=ord(st[1+x])-ord('A');

  st:=js_get_string(js,'resmap.map['+stri(y*2+1)+']');
  st:=unrle_map(st,xs);
  if length(st)<xs then continue;
  for x:=0 to xs-1 do s.the_game.resmap[x+y*xs].typ:=ord(st[1+x])-ord('0');
 end;
 procresmap(s,@s.map_plane);
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_passmap(s:psdi_rec;js:pjs_node);
var x,y,xs,ys:integer;
st:string;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 xs:=vali(js_get_string(js,'passmap.xsize'));
 ys:=vali(js_get_string(js,'passmap.ysize'));
 //if(xs<>mapx)or(ys<>mapy)then error
 setlength(s.the_game.passm,xs*ys);
 for y:=0 to ys-1 do begin
  st:=js_get_string(js,'passmap.map['+stri(y)+']');
  st:=unrle_map(st,xs);
  if length(st)<xs then continue;
  for x:=0 to xs-1 do s.the_game.passm[x+y*xs]:=ord(st[1+x])-ord('0');
 end;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_clans(s:psdi_rec;js:pjs_node);
var i,n:integer;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 n:=js_get_node_length(js,'clans');
 setlength(s.the_game.clansdb,n);
 for i:=0 to n-1 do s.the_game.clansdb[i]:=clan_from_json(js_get_node(js,'clans['+stri(i)+']'));
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_ginfo(s:psdi_rec;js:pjs_node);
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 s.the_game.info:=ginfo_from_json(js_get_node(js,'game_info'));
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_gstate(s:psdi_rec;js:pjs_node);
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 s.the_game.state:=gstate_from_json(js_get_node(js,'game_state'));
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_plrshort(s:psdi_rec;js:pjs_node);
var i,n:integer;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 n:=js_get_node_length(js,'plr_short');
 for i:=0 to n-1 do pall_from_json(s.the_game,@s.the_game.plr[i],js_get_node(js,'plr_short['+stri(i)+']'),true);
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_plrcomm(s:psdi_rec;js:pjs_node);
var cp:pplrtyp;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);

 cp:=get_cur_plr(s.the_game);
 pcomm_from_json(s.the_game,cp,js_get_node(js,'plr_comm'));

 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_plrall(s:psdi_rec;js:pjs_node);
var x:integer;
jsc:pjs_node;
cp:pplrtyp;
rs:string;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 cp:=get_cur_plr(s.the_game);
 pall_from_json(s.the_game,cp,js_get_node(js,'plr'),false);

 for x:=0 to SL_COUNT-1 do begin
  setlength(cp.scan_map[x],s.the_game.info.mapx*s.the_game.info.mapy);
  fillchar(cp.scan_map[x][0],2*s.the_game.info.mapx*s.the_game.info.mapy,1);
 end;

 calc_scan_full(s.the_game,cp,false);

 cp.selunit:=-1;

 rs:=unbytefy(cp.client_data);
 if rs<>'' then begin
  jsc:=js_parse(rs);
  if not sds_is_replay(@s.steps) then s.clinfo:=cdata_from_json(jsc);
  verify_sopt(s);
  free_js(jsc);
 end;

 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_log(s:psdi_rec;js:pjs_node);
var i,n,k:integer;
cp:pplrtyp;
begin
 if s.the_game=nil then exit;
 cp:=get_cur_plr(s.the_game);
 if cp=nil then exit;
 k:=length(cp.logmsg);

 if k<>vali(js_get_string(js,'from')) then exit;

 mutex_lock(sds_mx);
 n:=js_get_node_length(js,'log');
 setlength(cp.logmsg,k+n);
 for i:=k to k+n-1 do begin
  cp.logmsg[i]:=log_from_json(js_get_node(js,'log['+stri(i-k)+']'));
  if k<>0 then msgu_set(string_log_msg(s.the_game,@cp.logmsg[i]),0);
 end;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_cdata(s:psdi_rec;js:pjs_node);
var cp:pplrtyp;
begin
 if s.the_game=nil then exit;
 cp:=get_cur_plr(s.the_game);
 if cp=nil then exit;

 mutex_lock(sds_mx);
 //n:=js_get_string(js,'cdata');
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_fetch_units(s:psdi_rec;js:pjs_node);
var i,j,n,k,x:integer;
ujs:pjs_node;
u:typunits;
up:ptypunits;
su:ptypunits;
used,rx:boolean;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);

 n:=vali(js_get_string(js,'unit_count'));
 su:=get_sel_unit(s.the_game);
 if n<length(s.the_game.units) then begin
  for i:=n to length(s.the_game.units)-1 do begin
   up:=s.the_game.units[i];
   if up<>nil then begin
    subscan(s.the_game,up);
    remunuc(s.the_game,up.x,up.y,up);
    if (su<>nil)and(su=up) then begin
     select_nothing(s.the_game,get_cur_plr(s.the_game));
     if su.isact then if assigned(on_unit_event) then on_unit_event(s,su,uevt_stopped);
    end;
    dispose(s.the_game.units[i]);
   end;
   s.the_game.units[i]:=nil;
  end;
  setlength(s.the_game.units,n);
 end;


 n:=js_get_node_length(js,'units');
 su:=get_sel_unit(s.the_game);
 for i:=0 to n-1 do begin
  ujs:=js_get_node(js,'units['+stri(i)+']');
  used:=(vali(js_get_string(ujs,'used'))<>0)and(js_get_string(ujs,'typ')<>'nil');
  u:=units_from_json(ujs);
  k:=u.num;

  if used then begin
   x:=length(s.the_game.units);
   if k>=x then begin
    setlength(s.the_game.units,k+1);
    for j:=x to k do s.the_game.units[j]:=nil;
   end;

   //FIXME: Maybe some less slow way?
   rx:=false;
   up:=s.the_game.units[k];
   if up<>nil then begin
    //FIXME: Init/link client unit state, should be a function
    u.wave_step:=up.wave_step;
    u.wave_timer:=up.wave_timer;

    subscan(s.the_game,up);
    remunuc(s.the_game,up.x,up.y,up);

    if (su<>nil)and(su=up) then rx:=true;
    dispose(s.the_game.units[k]);
    s.the_game.units[k]:=nil;
   end else begin
    //FIXME: Init/link client unit state, should be a function
    u.wave_step:=random(8);
    u.wave_timer:=0;
   end;
   new(s.the_game.units[k]);
   s.the_game.units[k]^:=u;
   up:=s.the_game.units[k];
   if rx then if not unav(up) then begin
    select_nothing(s.the_game,get_cur_plr(s.the_game));
    if up.isact then if assigned(on_unit_event) then on_unit_event(s,up,uevt_stopped);
   end;

   if unav(up) then begin
    addunu(s.the_game,up);
    addscan(s.the_game,up,up.x,up.y);
   end;

  end else begin
   if(k>=0)and(k<length(s.the_game.units)) then begin
    up:=s.the_game.units[k];
    if up<>nil then begin

     subscan(s.the_game,up);
     remunuc(s.the_game,up.x,up.y,up);

     if (su<>nil)and(su=up) then begin
      select_nothing(s.the_game,get_cur_plr(s.the_game));
      if su.isact then if assigned(on_unit_event) then on_unit_event(s,su,uevt_stopped);
     end;
     dispose(s.the_game.units[k]);
    end;
    s.the_game.units[k]:=nil;
   end;
  end;
 end;

 event_map_reposition(s);
 event_units(s);

 //For full rescan, not needed
 //setunu(s.the_game);
 //calc_scan_full(s.the_game,get_cur_plr(s.the_game));

 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_move_unit(s:psdi_rec;js:pjs_node);
var mods:pmods_rec;
begin
 if js_get_string(js,'success')='1' then begin
  mutex_lock(sds_mx);
  ////FIXME?
  mods:=get_mods(s.the_game);
  mods.attack_command:=false;
  mods.move_command:=false;
  mods.build_rect:=false;
  mutex_release(sds_mx);
 end;
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_dbg_place_unit(s:psdi_rec;js:pjs_node);
begin
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_start_stop(s:psdi_rec;js:pjs_node);
begin
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_set_build(s:psdi_rec;js:pjs_node);
begin
 //if js_get_string(js,'success')='1' then
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_set_upgrades(s:psdi_rec;js:pjs_node);
begin
 //if js_get_string(js,'success')='1' then
 //FIXME: What if not enough gold?
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_xfer(s:psdi_rec;js:pjs_node);
begin
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_tool(s:psdi_rec;js:pjs_node);
begin
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_store(s:psdi_rec;js:pjs_node);
begin
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_move_close(s:psdi_rec;js:pjs_node);
var mods:pmods_rec;
begin
 if js_get_string(js,'success')='1' then begin
  mutex_lock(sds_mx);
  ////FIXME?
  mods:=get_mods(s.the_game);
  mods.enter_command:=false;
  mutex_release(sds_mx);
 end;
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_fire(s:psdi_rec;js:pjs_node);
begin
 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_research(s:psdi_rec;js:pjs_node);
var p:pplrtyp;
begin
 if s.the_game=nil then exit;

 mutex_lock(sds_mx);
 p:=get_cur_plr(s.the_game);
 research_from_json(s.the_game,p,js_get_node(js,'research'));
 mutex_release(sds_mx);

 proc_event_result(s,s.the_game,js);
end;
//############################################################################//
procedure reply_end_turn(s:psdi_rec;js:pjs_node);
begin
 mutex_lock(sds_mx);

 blank_modes(s.the_game);
 msgu.p:=false;
 msgu.txt:='';

 s.the_game.state:=gstate_from_json(js_get_node(js,'game_state'));
 if js_get_string(js,'changeover')='1' then begin
  s.state:=CST_INSGAME;
  stop_running_snd(s);
 end else begin
  s.state:=CST_THEGAME;
  mutex_release(sds_mx);
  proc_event_result(s,s.the_game,js);
  mutex_lock(sds_mx);
 end;
 clear_menu(s);

 event_frame(s);
 event_units(s);
 event_map_reposition(s);

 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_surrender(s:psdi_rec;js:pjs_node);
begin
 mutex_lock(sds_mx);

 blank_modes(s.the_game);
 msgu.p:=false;
 msgu.txt:='';

 s.the_game.state:=gstate_from_json(js_get_node(js,'game_state'));

 s.state:=CST_INSGAME;
 stop_running_snd(s);

 clear_menu(s);

 event_frame(s);
 event_units(s);
 event_map_reposition(s);

 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_land_player(s:psdi_rec;js:pjs_node);
begin
 mutex_lock(sds_mx);

 s.the_game.state:=gstate_from_json(js_get_node(js,'game_state'));
 s.state:=CST_INSGAME;

 if s.the_game.state.status=GST_THEGAME then begin
  alloc_and_clear_all_razved(s.the_game);  ////FIXME: Right place?
  if not sds_is_replay(@s.steps) then game_request(s,'fetch_plrshort','');
  do_refresh_colors(s);
 end;
 if s.the_game.state.status=GST_TAINT then begin
  if not s.mbox_on then  mbox(s,po('warn-loading-intersection'),po('warning'));
  clean_to_menu(s,MS_MAINMENU);
  s.steps.dumping_steps:=true;
  dispose(s.the_game);
  s.the_game:=nil;
  s.state:=CST_THEMENU;
 end;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure reply_new_game(s:psdi_rec;js:pjs_node);
begin
 mutex_lock(sds_mx);
 load_id:=js_get_string(js,'game_id');
 mutex_release(sds_mx);
end;
//############################################################################//
procedure do_terminal_event(s:psdi_rec;req:string;js:pjs_node);
begin
 //FIXME: Is that a correct behaviour?
 mutex_lock(sds_mx);
 if not s.mbox_on then mbox(s,'Failed in "'+req+'" ('+js_get_string(js,'error')+')',po('startgame'));
 clean_to_menu(s,MS_MAINMENU);
 s.steps.dumping_steps:=true;
 dispose(s.the_game);
 s.the_game:=nil;
 mutex_release(sds_mx);
end;
//############################################################################//
procedure proc_reply(s:psdi_rec;rs:string;terminal:boolean);
label 1;
var req:string;
js:pjs_node;
begin
 if rs='' then begin if terminal then do_terminal_event(s,'connection',nil);exit;end;
 js:=js_parse(rs);
 if js=nil then begin if terminal then do_terminal_event(s,'parse_json',nil);exit;end;

 req:=js_get_string(js,'reply_to');

 if js_get_string(js,'status')<>'1' then begin
  proc_status(s,js);
  if terminal then do_terminal_event(s,req,js);
  goto 1;
 end;

 if req='get_games'     then begin reply_get_games      (s,js);goto 1; end;
 if req='get_unisets'   then begin reply_get_unisets    (s,js);goto 1; end;
 if req='get_def_rules' then begin reply_get_def_rules  (s,js);goto 1; end;
 if req='get_maps'      then begin reply_get_maps       (s,js);goto 1; end;

 if req='fetch_udb'     then begin reply_fetch_udb      (s,js);goto 1; end;
 if req='fetch_resmap'  then begin reply_fetch_resmap   (s,js);goto 1; end;
 if req='fetch_passmap' then begin reply_fetch_passmap  (s,js);goto 1; end;
 if req='fetch_clans'   then begin reply_fetch_clans    (s,js);goto 1; end;

 if req='fetch_ginfo'   then begin reply_fetch_ginfo    (s,js);goto 1; end;
 if req='fetch_gstate'  then begin reply_fetch_gstate   (s,js);goto 1; end;
 if req='fetch_plrshort'then begin reply_fetch_plrshort (s,js);goto 1; end;
 if req='fetch_plrcomm' then begin reply_fetch_plrcomm  (s,js);goto 1; end;
 if req='fetch_log'     then begin reply_fetch_log      (s,js);goto 1; end;
 if req='fetch_cdata'   then begin reply_fetch_cdata    (s,js);goto 1; end;
 if req='fetch_plrall'  then begin reply_fetch_plrall   (s,js);goto 1; end;
 if req='fetch_units'   then begin reply_fetch_units    (s,js);goto 1; end;

 //set_cdata, no special reply

 if req='move_unit'     then begin reply_move_unit      (s,js);goto 1; end;
 if req='dbg_place_unit'then begin reply_dbg_place_unit (s,js);goto 1; end;
 if req='start_stop'    then begin reply_start_stop     (s,js);goto 1; end;
 if req='set_build'     then begin reply_set_build      (s,js);goto 1; end;
 if req='set_upgrades'  then begin reply_set_upgrades   (s,js);goto 1; end;
 if req='xfer'          then begin reply_xfer           (s,js);goto 1; end;
 if req='tool'          then begin reply_tool           (s,js);goto 1; end;
 if req='store'         then begin reply_store          (s,js);goto 1; end;
 if req='move_close'    then begin reply_move_close     (s,js);goto 1; end;
 if req='fire'          then begin reply_fire           (s,js);goto 1; end;
 if req='research'      then begin reply_research       (s,js);goto 1; end;

 if req='surrender'     then begin reply_surrender      (s,js);goto 1; end;
 if req='end_turn'      then begin reply_end_turn       (s,js);goto 1; end;
 if req='land_player'   then begin reply_land_player    (s,js);goto 1; end;
 if req='new_game'      then begin reply_new_game       (s,js);goto 1; end;

 1:
 free_js(js);
end;
//############################################################################//
begin
end.
//############################################################################//
