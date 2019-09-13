//############################################################################//
unit mgs_net;
interface
uses sysutils,asys
{$ifdef mgnet_tcp},strval,strtool,atcp{$endif}
{$ifdef mgnet_rob},rob_int{$endif}
,log
;
//############################################################################//  
const
version='1909100';
//############################################################################//  
type
{$ifdef mgnet_tcp}conn_type=ptcp_conn;{$endif}
{$ifdef mgnet_rob}conn_type=intptr;{$endif}
//############################################################################//  
var
server_port:integer=18008;
server_code:string='123456';
debug:boolean=false;
local:boolean=false;

srv_hnd:function(req:string;out res:string):boolean;
//############################################################################//
procedure run_server; 
//############################################################################//  
implementation
//############################################################################//
{$ifdef mgnet_tcp}
//############################################################################//
const
tcp_proto_ver=2;
tcp_timeout=10;
tcp_srv_timeout=60;
//############################################################################//
//MGSP*2*52*{"code":"123456","request":"get_games","finished":0}
//############################################################################//
function return_res(const res:string):string;
begin
 result:='MGSP*'+stri(tcp_proto_ver)+'*'+stri(length(res))+'*'+res;
end;
//############################################################################//
function parse_message(cl:conn_type;out data:string):boolean;
var buf,s:string;
rd,skip,n,ver,len:integer;
begin
 result:=false;

 buf:=tcp_read_str(cl); 
 rd:=length(buf);

 if rd<9 then exit;
 if copy(buf,1,5)<>'MGSP*' then exit;
 if copy(buf,7,1)<>'*' then exit;
 ver:=vali(copy(buf,6,1));
 if ver<>tcp_proto_ver then exit;
 n:=getfsymp(copy(buf,8,100),'*');
 if n=0 then exit;
 n:=n+8-1;
 len:=vali(copy(buf,8,n-8));
 buf:=copy(buf,n+1,length(buf));
 rd:=rd-n;

 skip:=0;
 while rd<len do begin
  while tcp_isdata(cl) do begin
   s:=tcp_read_str(cl);
   buf:=buf+s;
   rd:=rd+length(s);
   skip:=0;
  end;
  sleep(10);
  skip:=skip+1;
  if skip>=tcp_timeout*100 then exit;
 end;

 data:=buf;
 result:=true;
 //writeln(data);
end;
//############################################################################//
function sthread(cl:ptcp_conn):intptr;
var req,res:string;
cnt:integer;
begin result:=0; try
 cnt:=0;
 wr_log('NET','Client added');
 while not stop_threads do begin
  if tcp_isdata(cl) then begin
   cnt:=0;
   if not parse_message(cl,req) then break;

   if not srv_hnd(req,res) then begin
    tcp_write_str(cl,return_res(res));
    wr_log('LOG-ERR',res);
   end else begin
    tcp_write_str(cl,return_res(res));
    if debug then wr_log('out',res);
   end;
  end else begin
   cnt:=cnt+1;
   if cnt>tcp_srv_timeout*10 then break;
   sleep(100);
  end;
 end;      
 wr_log('NET','Client done');
 tcp_disconnect(cl);
 dispose(cl);
 except wr_log('ERR','Error in sthread',true); end;
end;
//############################################################################//
function mainthread(p:pointer):intptr;
var serv:ptcp_conn;
begin result:=0; try
 serv:=tcp_create_server('0.0.0.0',server_port);
 tcp_server_runsplit(serv,@sthread,nil);
 wr_log('SYS','Server thread exited');
 stop_threads:=true;
 except wr_log('ERR','Error in mainthread',true); end;
end;
{$endif}
//############################################################################//
{$ifdef mgnet_rob}
var ev_server,ev_version:dword;
//############################################################################//
function srv_handle(s:string):string;
var r:boolean;
begin
 r:=srv_hnd(s,result);
 if not r then wr_log('LOG-ERR',result);
end;
//############################################################################//
procedure proc_msgs;
var id,frm,len:dword;
s:string;
begin
 while peek_rob_any_wait(@id,@frm,@len) do begin
  if id=ev_version then begin  
   fetch_rob_id_buf(id,@frm,nil,len);
   robs_reply_string(frm,'MAXG '+version);
  end else if id=ev_server then begin
   setlength(s,len);
   fetch_rob_id_buf(id,@frm,@s[1],len);
   s:=srv_handle(s);
   robs_reply_string(frm,s);
  end else fetch_rob_id_buf(id,@frm,nil,len);
 end;
end;
//############################################################################//
function mainthread(p:pointer):intptr;
begin
 result:=0;
 ev_server:=register_rob('maxg.server');
 ev_version:=register_rob('maxg.version');
 try 
  while true do proc_msgs;
 except wr_log('ERR','Error in core mainthread',true); end;
end;
{$endif}
//############################################################################//
procedure run_server;
var sthid:tthreadid;
begin
 beginThread(nil,4*1024*1024,@mainthread,nil,0,sthid{%H-});
end;
//############################################################################//
begin
end.
//############################################################################//

