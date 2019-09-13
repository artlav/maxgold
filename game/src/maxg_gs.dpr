//############################################################################//
//MaxGold SDI client (for SDL)
//
//All hope abandon ye who enter here.
//
//Defines: BGR
//mgnet_tcp for TCP
//mgnet_rob for local
//update for update and versioning
//############################################################################//
{$ifdef mswindows}{$apptype console}{$R std.res}{$endif}
//############################################################################//
program maxg_gs;
uses asys,log{$ifdef update},upd_cli{$endif},mgrecs,mgs_net,mgs_core,mgs_db,console;
//############################################################################//
function input_thread(p:pointer):integer;
var ch:char;
begin
 result:=0;
 while true do begin
  if keypressed then begin
   ch:=readkey;
   write(' ');
   case ch of
    'p':begin no_pass:=not no_pass;writeln('no_pass: ',ord(no_pass));end;
    'e':begin stop_threads:=true;writeln('exiting...');end;
    {$ifdef update}
    'u':begin
     write('Checking for updates... ');
     if upd_can_we_update then if upd_net_check then if upd_online_version>core_progvernum then begin
      if upd_net_download(nil) then upd_resetprog(true);
     end;
     writeln('None.');
    end;
    'g':begin write('Making version... ');upd_make_version;writeln('Done.');end;
    {$endif}

   end;
  end;
  sleep(1);
 end;
end;
//############################################################################//
procedure main;
var sthid:intptr;
begin try
 log_file_name:='mgs.log';
 log_con:=true;

 {$ifdef update}
 upd_set_product('maxg_srv','maxg_gs',core_progvernum,false,true);
 upd_check_update_rename;
 upd_look_for_update_parameters;
 {$endif}

 mgs_set_server;
 mgs_begin_server;

 beginThread(nil,4*1024*1024,@input_thread,nil,0,sthid{%H-});
 wr_log('SYS','Running '+version);
 while not stop_threads do begin
  sleep(1000);
  mgs_server_idle;
 end;

 mgs_clean_server;

 except wr_log('ERR','Error in main',true); end;
end;
//############################################################################//
begin
 main;
end.
//############################################################################//


