//############################################################################//  
unit mgs_db;
interface
uses sysutils,asys,grph,strval,strtool,log,vfsint,json
,mgrecs,mgvars,mgsaveload,mgloads
,mgl_common;
//############################################################################//  
const
refresh_interval=10;//*60;
wait_limit=15;//*60; 
auto_wait_limit=15;
//############################################################################//  
var 
gd_mx:mutex_typ;
games:array[0..99]of pgame_db_rec;
no_pass:boolean=false;             //Config file override for password checks
fetch_debug:boolean=false;         //Enable mechanism to detect and alter the fixing of the fetch lists in fetch_units as detection and events change.
fetch_debug_list:array of integer;

ido_request:function(cont,ng_id:string;mk_log,skip_fetches,mk_client_log,print,make_reply:boolean):string=nil;
//############################################################################//   
procedure game_store(id:string;req,res:string);

procedure unload_one_games(id:string);
procedure sync_one_games(id:string;unload,log:boolean);
function game_by_id(id:string;mark:boolean):pgametyp;
function make_new_game(gs:pgamestart_rec;id:string;print:boolean):pgametyp;
function game_auth(g:pgametyp;pass:string):boolean;
procedure proc_games;
procedure save_all_games;
procedure clean_all_games;
procedure load_games;
function read_game_replay(name:string):string;
procedure make_game_finished(id:string;log:boolean);

function replay_game_log(name:string;gen_client:boolean):boolean;
//############################################################################//
implementation
//############################################################################//
const
local_ext='.game';
replay_ext='.replay';
cache_ext='.cache';
//############################################################################//
var last_id:integer=10001;
//############################################################################//  
procedure append_game_log(fn,req,res:string);
var f:vfile;
s:string;
begin
 s:=req;
 if s<>'' then begin
  if vfopen(f,mgrootdir+mg_core.save_dir+'/'+fn+local_ext,VFO_RW)<>VFERR_OK then begin
   if vfopen(f,mgrootdir+mg_core.save_dir+'/'+fn+local_ext,VFO_WRITE)<>VFERR_OK then exit;
  end else if vffilesize(f)<>0 then s:=','+#$0A+s;
  vfseek(f,vffilesize(f));
  vfwrite(f,@s[1],length(s));
  vfclose(f);
 end;
 
 s:=res;
 if s<>'' then begin
  if vfopen(f,mgrootdir+mg_core.save_dir+'/'+fn+replay_ext,VFO_RW)<>VFERR_OK then begin
   if vfopen(f,mgrootdir+mg_core.save_dir+'/'+fn+replay_ext,VFO_WRITE)<>VFERR_OK then exit;
  end else if vffilesize(f)<>0 then s:=','+#$0A+s;
  vfseek(f,vffilesize(f));
  vfwrite(f,@s[1],length(s));
  vfclose(f);
 end;
end;    
//############################################################################//  
procedure game_store(id:string;req,res:string);
var i,c:integer;
begin           
 c:=-1;
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].id=id then begin c:=i;break;end;
 if c=-1 then exit;
 if games[c].gam=nil then exit;

 append_game_log(games[c].id,req,res);
 if games[c].gam.state.status=GST_ENDGAME then make_game_finished(id,true);
end;     
//############################################################################//  
procedure unload_one_games(id:string);
var i,c:integer;
begin
 c:=-1;
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].id=id then begin c:=i;break;end;
 if c=-1 then exit;
 if games[c].gam=nil then exit;
       
 dispose_game(games[c].gam);
 dispose(games[c].gam);
 games[c].gam:=nil;
end; 
//############################################################################//  
procedure sync_one_games(id:string;unload,log:boolean);
var i,c:integer;
begin
 c:=-1;
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].id=id then begin c:=i;break;end;
 if c=-1 then exit;
 if games[c].gam=nil then exit;

 if log then wr_log('UPD','Synced '+games[c].id);
 save_game_file(games[c].gam,games[c].id+cache_ext);
 games[c].save_date:=get_cur_time_utc;
   
 games[c].info:=games[c].gam.info;
 games[c].state:=games[c].gam.state;
 games[c].id:=games[c].gam.remote_id;

 if unload then begin  
  if log then wr_log('UPD','Unloaded '+games[c].id);
  unload_one_games(id);
 end;
end;
//############################################################################//  
procedure make_game_finished(id:string;log:boolean);
var i,c:integer;
begin
 c:=-1;
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].id=id then begin c:=i;break;end;
 if c=-1 then exit;
 if games[c].gam=nil then exit;

 if log then wr_log('UPD','Finished '+games[c].id);
 save_game_file(games[c].gam,games[c].id+cache_ext);
 games[c].save_date:=get_cur_time_utc;  
 games[c].info:=games[c].gam.info;
 games[c].state:=games[c].gam.state;
 games[c].id:=games[c].gam.remote_id;
 unload_one_games(id);
end; 
//############################################################################//  
procedure load_one_games(db:pgame_db_rec;fn:string);
begin
 db.gam:=load_game_file(fn);
 if db.gam<>nil then begin
  db.info:=db.gam.info;
  db.state:=db.gam.state;
  db.id:=db.gam.remote_id;
  db.save_date:=get_cur_time_utc;
  wr_log('UPD','Loaded '+fn);
 end else begin 
  wr_log('UPD','Failed to load '+fn);
 end;
end;
//############################################################################//  
function game_by_id(id:string;mark:boolean):pgametyp; 
var i,c:integer;
cl:crgba;
begin
 result:=nil;
 c:=-1;
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].id=id then begin c:=i;break;end;
 if c=-1 then exit;

 if games[c].gam=nil then load_one_games(games[c],games[c].id+cache_ext);
 if games[c].gam=nil then exit;

 if mark then games[c].date:=get_cur_time_utc;
 
 if(games[c].gam.state.cur_plr>=0)and(games[c].gam.state.cur_plr<games[c].gam.info.plr_cnt) then begin
  games[c].cur_plr:=games[c].gam.plr[games[c].gam.state.cur_plr].info.name;
  cl:=nata(games[c].gam.plr[games[c].gam.state.cur_plr].info.color);
  games[c].cur_color:=strhex2(cl[2])+strhex2(cl[1])+strhex2(cl[0]);   
 end;
 
 result:=games[c].gam;
end;
//############################################################################//  
function make_new_game(gs:pgamestart_rec;id:string;print:boolean):pgametyp;
var i,c:integer;
seed:dword;
begin
 result:=nil;
 c:=-1;
 for i:=0 to length(games)-1 do if games[i]=nil then begin c:=i;break;end;
 if c=-1 then exit;
 
 seed:=last_id;
 if id<>'' then seed:=vali(id);
 
 result:=init_new_game(gs,seed);
 if result<>nil then begin
  if id='' then begin
   result.remote_id:=stri(last_id);
   last_id:=last_id+1;
  end else result.remote_id:=id;

  new(games[c]);
  games[c].gam:=result;  
  games[c].info:=games[c].gam.info;
  games[c].state:=games[c].gam.state;
  games[c].id:=games[c].gam.remote_id;
  games[c].date:=get_cur_time_utc;
  
  sync_one_games(result.remote_id,false,print);
 end;
end;
//############################################################################//  
function game_auth(g:pgametyp;pass:string):boolean;
var cp:pplrtyp;
begin
 result:=false;
 if g=nil then exit;
 if g.state.status=GST_ENDGAME then exit;
 if g.info.rules.nopaswds or no_pass then begin result:=true;exit;end;
 cp:=get_cur_plr(g);
 if cp=nil then exit;
 
 result:=lowercase(pass)=lowercase(cp.info.passhash);
end;   
//############################################################################//  
procedure proc_games;
var i:integer;
begin
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].gam<>nil then begin
  if get_cur_time_utc-games[i].date>wait_limit then begin
   sync_one_games(games[i].id,true,true);
   continue;
  end else if get_cur_time_utc-games[i].save_date>auto_wait_limit then begin
   sync_one_games(games[i].id,false,true);
   continue;
  end;
 end;
end;   
//############################################################################//  
procedure save_all_games;
var i:integer;
begin
 for i:=0 to length(games)-1 do if games[i]<>nil then sync_one_games(games[i].id,true,true);
end;   
//############################################################################//  
procedure clean_all_games;
var i:integer;
begin
 save_all_games;
 for i:=0 to length(games)-1 do if games[i]<>nil then begin
  dispose(games[i]);
 end;
end;
//############################################################################//
function fetch_debug_list_to_list:string;
var i:integer;
first:boolean;
begin
 result:='';
 first:=true;
 for i:=0 to length(fetch_debug_list)-1 do begin
  if not first then result:=result+',';
  result:=result+stri(fetch_debug_list[i]);
  if first then first:=false;
 end;
end;
//############################################################################//  
function replay_game_log(name:string;gen_client:boolean):boolean;
var f:vfile;
s,req:string;
sz,i,c:integer;
js,jn:pjs_node;
begin
 result:=false;
 setlength(fetch_debug_list,0);
 if vfopen(f,mgrootdir+mg_core.save_dir+'/'+name+local_ext,VFO_READ)<>VFERR_OK then exit;
 sz:=vffilesize(f);
 setlength(s,sz);
 vfread(f,@s[1],sz);
 vfclose(f);

 s:='{"log":['+s+']}';
 js:=js_parse(s);

 if js=nil then exit;

 if gen_client then begin
  if vfopen(f,mgrootdir+mg_core.save_dir+'/'+name+replay_ext,VFO_WRITE)=VFERR_OK then vfclose(f);
 end;

 c:=-1;
 for i:=0 to length(games)-1 do if games[i]<>nil then if games[i].id=name then begin c:=i;break;end;
 if c<>-1 then begin
  if games[c].gam<>nil then unload_one_games(name);
  dispose(games[c]);
  games[c]:=nil;
 end; 

 sz:=js_get_node_length(js,'log');
 {$ifdef srv_stat}zero_stat;{$endif}
 for i:=0 to sz-1 do begin
  jn:=js_get_node(js,'log['+stri(i)+']');
  req:=js_stringify(jn);
  ido_request(req,name,false,not gen_client,gen_client,false,gen_client);

  if fetch_debug and gen_client then begin
   if length(fetch_debug_list)<>0 then begin
    req:='{"code":"'+js_get_string(jn,'code')+'","game_id":"'+js_get_string(jn,'game_id')+'","list":['+fetch_debug_list_to_list+'],"pass":"'+js_get_string(jn,'pass')+'","request":"'+js_get_string(jn,'request')+'"},';
    setlength(fetch_debug_list,0);
   end;
   writeln(req,',');
  end;

 end;
 {$ifdef srv_stat}print_stat(name);{$endif}
 sync_one_games(name,false,false);

 free_js(js);
 result:=true;
end;
//############################################################################//  
procedure load_games;
var l:avdir;
n,i,k:integer;
id:string;
g:pgametyp; 
begin
 for i:=0 to length(games)-1 do games[i]:=nil;
 
 l:=vffind_arr(mgrootdir+mg_core.save_dir+'/*'+local_ext,attall);
 n:=length(l);
 for i:=0 to n-1 do begin
  k:=getlsymp(l[i].name,'.');
  id:=copy(l[i].name,1,k-1);
  
  wr_log('UPD','Replaying '+id+'...');
  replay_game_log(id,false); 
  g:=game_by_id(id,false);
  
  if g<>nil then begin
   if vali(g.remote_id)>=last_id then last_id:=vali(g.remote_id)+1; 
   //Unload
   //wr_log('UPD','Unloaded '+id);
   unload_one_games(id);
  end;
 end;
end;
//############################################################################//  
function read_game_replay(name:string):string;
var f:vfile;
sz:integer;
begin
 result:='';
 replay_game_log(name,true);
 if vfopen(f,mgrootdir+mg_core.save_dir+'/'+name+replay_ext,VFO_READ)<>VFERR_OK then exit;
 sz:=vffilesize(f);
 setlength(result,sz);
 vfread(f,@result[1],sz);
 vfclose(f);
end;
//############################################################################//  
begin
end.
//############################################################################//  
