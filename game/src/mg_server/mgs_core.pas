//############################################################################//
unit mgs_core;
interface
uses asys,strval,log,json,vfsint
,mgl_json,mgs_db,mgrecs,mginit
,mgs_net
,mgs_srv
;
//############################################################################//
procedure mgs_set_server;
procedure mgs_begin_server;
procedure mgs_clean_server;
procedure mgs_server_idle;
//############################################################################//
implementation
//############################################################################//
var last_time:dword=0;
//############################################################################//
//Load maxg_srv.cfg
procedure loadsetup;
var sz:integer;
js:pjs_node;
s:string;
f:vfile;
begin js:=nil; try
 if not vfexists(mgrootdir+'maxg_srv.txt') then exit;
 if vfopen(f,mgrootdir+'maxg_srv.txt',VFO_READ)<>VFERR_OK then exit;
 sz:=vffilesize(f);
 setlength(s,sz);
 vfread(f,@s[1],sz);
 vfclose(f);

 js:=js_parse(s);
 if js=nil then exit;

 s:=js_get_string(js,'server_port');if s<>'nil' then server_port:=vali(s);
 s:=js_get_string(js,'server_code');if s<>'nil' then server_code:=s;
 s:=js_get_string(js,'debug');      if s<>'nil' then debug:=vali(s)<>0;
 s:=js_get_string(js,'local');      if s<>'nil' then local:=vali(s)<>0;
 s:=js_get_string(js,'no_pass');    if s<>'nil' then no_pass:=vali(s)<>0;
 s:=js_get_string(js,'rle');        if s<>'nil' then mgl_json_rle:=vali(s)<>0;

 free_js(js);

 except stderr('LoadSav','LoadSetup');end;
end;
//############################################################################//
procedure mgs_set_server;
var s:string;
begin
 gd_mx:=mutex_create;
 
 mg_init_core;
 s:='SDI M.A.X. Gold server V '+core_progver+' started';
 wr_log('SDI',s);
 loadsetup;
end;
//############################################################################//
procedure mgs_begin_server;
begin 
 wr_log('SDI','Loading DB');
 load_games;

 srv_hnd:=do_mg_server;
 run_server;
end;
//############################################################################//
procedure mgs_clean_server;
begin
 wr_log('SYS','Saving games...');
 clean_all_games;
 wr_log('SYS','Done.'); 
end;
//############################################################################//
procedure mgs_server_idle;
begin
 if get_cur_time_utc-last_time>refresh_interval then begin
  mutex_lock(gd_mx);
  proc_games;
  last_time:=get_cur_time_utc;       
  //wr_log('UPD','Status refresh '+stri(i));    
  //i:=i+1;
  mutex_release(gd_mx);   
 end;
end;     
//############################################################################//
begin
end.  
//############################################################################//


