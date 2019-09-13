//############################################################################//
unit atcp_unix;
{$WARN 5028 off : Local $1 "$2" is not used}
interface
uses asys,strval,sockets,baseunix,termio,dns_unix;
//############################################################################//
const packet_size=64000;
connection_timeout=5;
//############################################################################//
var bug_nonblocking_send:boolean=false;
//############################################################################//
type
atcp_conn=record
 used:boolean;
 typ:integer;
 con_typ:integer;
 proc,par:pointer;
 error:integer;

 iface:string;
 addr:sockaddr;
 last_recv_addr:sockaddr;
 uaddr:sockaddr_un;
 sock,lstn:integer;
 braodcast_on:boolean;
end;
patcp_conn=^atcp_conn;
//############################################################################//
srv_proc=procedure(cl,par:pointer);
//############################################################################//
function atcp_create_server    (ip:string;port:word):patcp_conn;
function atcp_udp_create_server(ip:string;port:word):patcp_conn;
function atcp_udp_create_mcast (ip:string;port:word):patcp_conn;

function atcp_client_create       (url:string;port:word;no_resolve:boolean):patcp_conn;
function atcp_udp_client_create   (url:string;port:word;no_resolve:boolean):patcp_conn;
function atcp_socket_client_create(fn:string):patcp_conn;

function atcp_mk_client_copy(sck:integer):patcp_conn;
procedure atcp_free(cl:patcp_conn);

function atcp_iserror(cl:patcp_conn):boolean;

function atcp_client_connect(cl:patcp_conn):boolean;
function atcp_disconnect(cl:patcp_conn):boolean;

function atcp_server_establish(cl:patcp_conn;again:boolean):boolean;
function atcp_server_run(cl:patcp_conn;again:boolean):boolean;
function atcp_server_run_one(cl:patcp_conn;proc,par:pointer):boolean;
function atcp_server_runsplit(cl:patcp_conn;proc,par:pointer):boolean;
function atcp_server_runsplit_stp(cl:patcp_conn;proc,par:pointer;var stop:boolean):boolean;
function atcp_server_stop(cl:patcp_conn):boolean;

procedure atcp_dump_tail(cl:patcp_conn);

function atcp_write_buf(cl:patcp_conn;buf:pointer;siz:integer;dst:dword;dst_port:word):boolean;
function atcp_read_str(cl:patcp_conn;single:boolean):string;
function atcp_read_buf(cl:patcp_conn;buf:pointer;bs:integer;single:boolean):integer;

function atcp_isdata(cl:patcp_conn):boolean;
function atcp_get_buf_size(cl:patcp_conn):integer;
//For UDP
function atcp_last_port(cl:patcp_conn):word;
function atcp_last_ip(cl:patcp_conn):dword;

procedure atcp_set_iface(cl:patcp_conn;iface:string);
//############################################################################//
function atcp_host2ip(host:string):string;
function atcp_localip:string;
//############################################################################//
implementation
//############################################################################//
function ramp_thread(t:pointer):intptr;begin result:=0; srv_proc(patcp_conn(t).proc)(t,patcp_conn(t).par);end;
//############################################################################//
const //FIONREAD=$0000541B;
SOCKET_ERROR=-1;

CON_TYP_TCP=0;
CON_TYP_SCK=1;
CON_TYP_UDP=2;
CON_TYP_UDP_MCAST=3;

TYP_CLIENT=0;
TYP_SERVER=1;
//############################################################################//
type
pip_mreq=^ip_mreq;
ip_mreq=record
 imr_multiaddr:in_addr;
 imr_interface:in_addr;
end;
//############################################################################//
//'127.0.0.1' to dword
function str_to_ip(ip:string):dword;
var h:in_addr;
begin
 h:=strtohostaddr(ip);
 result:=HostToNet(h.s_addr);
end;
//############################################################################//
function dns_resolve(url:string;no_resolve:boolean):dword;
var h:in_addr;
begin
 result:=0;
 if no_resolve then begin
  h:=strtohostaddr(url);
  result:=HostToNet(h.s_addr);
 end else begin
  if resolvehostbyname(url,h) then result:=h.s_addr;
  if result=0 then begin h:=strtohostaddr(url); result:=HostToNet(h.s_addr);end;
 end;
end;
//############################################################################//
function h2ip_(name:string):string;
const stbl:set of char=['0','1','2','3','4','5','6','7','8','9','.'];
var i:integer;
begin
 result:='';

 i:=1;
 while(i<=length(name))and(result='')do if not(name[i] in stbl)then begin result:=atcp_host2ip(name);i:=9999;end else i:=i+1;

 if result='' then result:=name;
end;
//############################################################################//
function atcp_host2ip(host:string):string;
var h:in_addr;
begin
 if resolvehostbyname(host,h) then result:=strhex(h.s_addr) else result:=host;
 //FIXME: Make IP out of it, not hex
end;
//############################################################################//
function atcp_localip:string;
begin
 result:='0.0.0.0';
end;
//############################################################################//
//############################################################################//
function mk_conn(typ,con_typ:integer):patcp_conn;
begin
 new(result);
 result.typ:=typ;
 result.used:=true;
 result.error:=0;
 result.con_typ:=con_typ;
 result.iface:='';
 result.braodcast_on:=false;
end;
//############################################################################//
function mk_server(ip:string;port:word;con_typ:integer):patcp_conn;
var addr:dword;
begin
 result:=mk_conn(TYP_SERVER,con_typ);

 fillchar(result.addr,sizeof(result.addr),0);
 addr:=str_to_ip(ip);
 result.addr.sin_family:=af_inet;
 result.addr.sin_addr.s_addr:=addr;
 result.addr.sin_port:=htons(port);
end;
//############################################################################//
function mk_client(url:string;port:word;con_typ:integer;no_resolve:boolean):patcp_conn;
var addr:dword;
begin
 result:=mk_conn(TYP_CLIENT,con_typ);

 case con_typ of
  CON_TYP_TCP,CON_TYP_UDP:begin
   fillchar(result.addr,sizeof(result.addr),0);
   addr:=dns_resolve(url,no_resolve);
   if addr<>0 then begin
    result.addr.sin_family:=AF_inet;
    result.addr.sin_addr.s_addr:=addr;
    result.addr.sin_port:=htons(port);
    result.last_recv_addr:=result.addr;
   end else begin
    dispose(result);
    result:=nil;
   end;
  end;
  CON_TYP_SCK:begin
   fillchar(result.uaddr,sizeof(result.uaddr),0);
   result.uaddr.sun_family:=AF_UNIX;
   move(url[1],result.uaddr.sun_path[0],length(url));
   result.uaddr.sun_path[length(url)]:=#0;
  end;
  CON_TYP_UDP_MCAST:begin
   fillchar(result.addr,sizeof(result.addr),0);
   addr:=str_to_ip(url);
   result.addr.sin_family:=af_inet;
   result.addr.sin_addr.s_addr:=addr;
   result.addr.sin_port:=htons(port);
  end;
 end;
end;
//############################################################################//
procedure atcp_free(cl:patcp_conn);begin closesocket(cl.sock);dispose(cl);end;
//############################################################################//
function atcp_create_server    (ip:string;port:word):patcp_conn;begin result:=mk_server(ip,port,CON_TYP_TCP);end;
function atcp_udp_create_server(ip:string;port:word):patcp_conn;begin result:=mk_server(ip,port,CON_TYP_UDP);end;
//############################################################################//
function atcp_client_create       (url:string;port:word;no_resolve:boolean):patcp_conn;begin result:=mk_client(url,port,CON_TYP_TCP,no_resolve);end;
function atcp_udp_client_create   (url:string;port:word;no_resolve:boolean):patcp_conn;begin result:=mk_client(url,port,CON_TYP_UDP,no_resolve);end;
function atcp_socket_client_create(fn:string):patcp_conn;                              begin result:=mk_client(fn ,0   ,CON_TYP_SCK,true);end;
function atcp_udp_create_mcast    (ip:string;port:word):patcp_conn;                    begin result:=mk_client(ip ,port,CON_TYP_UDP_MCAST,true);end;
//############################################################################//
function atcp_mk_client_copy(sck:integer):patcp_conn;
begin
 new(result);
 result.sock:=sck;
 result.used:=true;
 result.error:=0;
 result.typ:=TYP_CLIENT;
end;
//############################################################################//
function atcp_server_establish(cl:patcp_conn;again:boolean):boolean;
begin
 result:=false;
end;
//############################################################################//
function atcp_server_run(cl:patcp_conn;again:boolean):boolean;
begin
 result:=false;
 if cl.typ<>TYP_SERVER then exit;
 if cl.con_typ<>CON_TYP_UDP then exit;

 cl.sock:=fpsocket(af_inet,sockets.sock_dgram,IPPROTO_UDP);
 if cl.sock<0 then begin cl.error:=1;exit;end;

 if cl.iface<>'' then fpsetsockopt(cl.sock,SOL_SOCKET,SO_BINDTODEVICE,@cl.iface[1],length(cl.iface));

 if fpbind(cl.sock,sockets.psockaddr(@cl.addr),sizeof(cl.addr))<>0 then begin cl.error:=1;exit;end;

 result:=true;
end;
//############################################################################//
function do_atcp_server_run(cl:patcp_conn;proc,par:pointer;thread:boolean):boolean;
var mk:patcp_conn;
acc:integer;
begin
 result:=false;
 if cl.typ<>TYP_SERVER then exit;
 result:=true;
 case cl.con_typ of
  CON_TYP_TCP:cl.lstn:=fpsocket(af_inet,sockets.sock_stream,IPPROTO_IP);
  CON_TYP_UDP:cl.lstn:=fpsocket(af_inet,sockets.sock_dgram,IPPROTO_UDP);
  else cl.lstn:=-1;
 end;
 if cl.lstn<0 then begin cl.error:=1;result:=false;exit;end;

 if fpbind(cl.lstn,sockets.psockaddr(@cl.addr),sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;

 case cl.con_typ of
  CON_TYP_TCP:while not stop_threads and (fplisten(cl.lstn,somaxconn)=0) do begin
   acc:=fpaccept(cl.lstn,nil,nil);
   if acc<0 then begin cl.error:=1;result:=false;exit;end;
   mk:=atcp_mk_client_copy(acc);
   mk.con_typ:=cl.con_typ;
   mk.proc:=proc;
   mk.par:=par;
   if mk.sock<>-1 then begin
    if thread then begin
     start_thread(ramp_thread,mk);
    end else begin
     ramp_thread(mk);
    end;
   end else begin
    if fpbind(cl.lstn,sockets.psockaddr(@cl.addr),sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;
   end;
  end;
  CON_TYP_UDP:begin
   mk:=atcp_mk_client_copy(cl.lstn);
   mk.con_typ:=cl.con_typ;
   mk.proc:=proc;
   mk.par:=par;
   if thread then begin
    start_thread(ramp_thread,mk);
   end else begin
    ramp_thread(mk);
   end;
  end;
  else begin cl.error:=2;result:=false;exit;end;
 end;
end;
//############################################################################//
function atcp_server_run_one(cl:patcp_conn;proc,par:pointer):boolean;begin result:=do_atcp_server_run(cl,proc,par,false);end;
function atcp_server_runsplit(cl:patcp_conn;proc,par:pointer):boolean;begin result:=do_atcp_server_run(cl,proc,par,true);end;
//############################################################################//
function atcp_server_runsplit_stp(cl:patcp_conn;proc,par:pointer;var stop:boolean):boolean;
begin
 result:=false;
end;
//############################################################################//
function atcp_server_stop(cl:patcp_conn):boolean;
begin
 result:=true;

 if fpshutdown(cl.lstn,2)<>0 then begin cl.error:=1;result:=false; end;
 if closesocket(cl.lstn)<>0 then begin cl.error:=1;result:=false; end;
 if closesocket(cl.sock)<>0 then begin cl.error:=1;result:=false; end;
end;
//############################################################################//
function atcp_client_connect(cl:patcp_conn):boolean;
var d:timeval;
y:integer;
mreq:ip_mreq;
begin
 result:=true;
 case cl.con_typ of
  CON_TYP_TCP:cl.sock:=fpsocket(AF_inet,sockets.sock_stream,0);
  CON_TYP_SCK:cl.sock:=fpsocket(AF_unix,sockets.sock_stream,0);
  CON_TYP_UDP,CON_TYP_UDP_MCAST:cl.sock:=fpsocket(AF_inet,sockets.sock_dgram,IPPROTO_UDP);
  else begin cl.error:=2;result:=false;exit;end;
 end;

 if cl.con_typ=CON_TYP_UDP_MCAST then begin
  mreq.imr_multiaddr.s_addr:=cl.addr.sin_addr.s_addr;
  mreq.imr_interface.s_addr:=htonl(INADDR_ANY);

  y:=1;
  fpsetsockopt(cl.sock,SOL_SOCKET,SO_REUSEADDR,@y,sizeof(y));
  if fpbind(cl.sock,sockets.psockaddr(@cl.addr),sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;closesocket(cl.sock);exit;end;
  //FIXME: This fails. Looks like lo can't do local multicast if loopback is off.
  //y:=0;
  //fpsetsockopt(cl.sock,IPPROTO_IP,IP_MULTICAST_LOOP,@y,sizeof(y));
  fpsetsockopt(cl.sock,IPPROTO_IP,IP_ADD_MEMBERSHIP,@mreq,sizeof(mreq));
  result:=true;
 end else begin
  d.tv_usec:=0;
  d.tv_sec:=connection_timeout;
  fpsetsockopt(cl.sock,SOL_SOCKET,SO_RCVTIMEO,@d,sizeof(d));
  fpsetsockopt(cl.sock,SOL_SOCKET,SO_SNDTIMEO,@d,sizeof(d));

  case cl.con_typ of
   CON_TYP_TCP:if fpconnect(cl.sock,sockets.psockaddr(@cl.addr),sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;end;
   CON_TYP_SCK:if fpconnect(cl.sock,sockets.psockaddr(@cl.uaddr),sizeof(cl.uaddr))<>0 then begin cl.error:=1;result:=false;end;
   CON_TYP_UDP:;
   else begin cl.error:=2;result:=false;exit;end;
  end;

  d.tv_sec:=0;
  fpsetsockopt(cl.sock,SOL_SOCKET,SO_RCVTIMEO,@d,sizeof(d));
  fpsetsockopt(cl.sock,SOL_SOCKET,SO_SNDTIMEO,@d,sizeof(d));
 end;

 if not result then closesocket(cl.sock);
end;
//############################################################################//
function atcp_disconnect(cl:patcp_conn):boolean;
begin
 result:=true;
 if fpshutdown(cl.sock,2)<>0 then begin cl.error:=1;result:=false;end;
 if closesocket(cl.sock)<>0 then begin cl.error:=1;result:=false;end;
 if cl.typ=TYP_SERVER then if closesocket(cl.lstn)<>0 then begin cl.error:=1;result:=false;end;
end;
//############################################################################//
//############################################################################//
procedure enable_broadcast(cl:patcp_conn);
var y:integer;
begin
 if cl=nil then exit;
 if cl.braodcast_on then exit;
 cl.braodcast_on:=true;
 y:=1;
 fpsetsockopt(cl.sock,SOL_SOCKET,SO_BROADCAST,@y,sizeof(y));
end;
//############################################################################//
procedure atcp_dump_tail(cl:patcp_conn);
var buf:string;
begin
 while atcp_isdata(cl) do begin
  setlength(buf,packet_size);
  fprecv(cl.sock,pointer(buf),packet_size,0);
 end;
end;
//############################################################################//
function atcp_write_buf(cl:patcp_conn;buf:pointer;siz:integer;dst:dword;dst_port:word):boolean;
var i,p,flags:integer;
begin result:=false;try
 if siz<packet_size then i:=siz else i:=packet_size;
 p:=0;
 flags:=0;
 if bug_nonblocking_send then flags:=MSG_DONTWAIT;  //MSG_DONTWAIT flag makes it not get stuck, but also makes it fail and never succeed on slow connections. Can't use as default

 while siz>0 do begin
  case cl.con_typ of
   CON_TYP_TCP,CON_TYP_SCK:result:=fpsend(cl.sock,pointer(intptr(buf)+intptr(p)),i,flags)<>SOCKET_ERROR;
   CON_TYP_UDP:begin
    if dst<>0 then cl.last_recv_addr.sin_addr.s_addr:=dst;
    if dst_port<>0 then cl.last_recv_addr.sin_port:=dst_port;
    if cl.last_recv_addr.sin_addr.s_addr=0 then cl.last_recv_addr.sin_addr.s_addr:=$FFFFFFFF;
    if cl.last_recv_addr.sin_addr.s_addr=$FFFFFFFF then enable_broadcast(cl);
    result:=fpsendto(cl.sock,pointer(intptr(buf)+intptr(p)),i,flags,@cl.last_recv_addr,sizeof(cl.addr))<>SOCKET_ERROR;     //FIXME: NOT THREAD SAFE!
   end;
   CON_TYP_UDP_MCAST:result:=fpsendto(cl.sock,pointer(intptr(buf)+intptr(p)),i,flags,@cl.addr,sizeof(cl.addr))<>SOCKET_ERROR;
   else writeln('ATCP: WTF? cl.con_typ unknown in write');
  end;
  if not result then begin cl.error:=1;exit;end;
  p:=p+i;

  siz:=siz-i;
  if siz<packet_size then i:=siz;
 end;
 result:=true;
 except cl.error:=1; end;
end;
//############################################################################//
function atcp_read_buf(cl:patcp_conn;buf:pointer;bs:integer;single:boolean):integer;
var c:integer;
sz:intptr;
begin
 result:=0;
 sz:=sizeof(cl.addr);
 while atcp_isdata(cl) and(bs-result>0)do begin
  case cl.con_typ of
   CON_TYP_TCP,CON_TYP_SCK:      c:=fprecv    (cl.sock,pointer(intptr(buf)+intptr(result)),bs-result,0);
   CON_TYP_UDP,CON_TYP_UDP_MCAST:c:=fprecvfrom(cl.sock,pointer(intptr(buf)+intptr(result)),bs-result,0,@cl.last_recv_addr,@sz);
   else writeln('ATCP: WTF? cl.con_typ unknown in read');
  end;
  if c<0 then exit;
  result:=result+c;
  if single then break;
 end;
end;
//############################################################################//
function atcp_read_str(cl:patcp_conn;single:boolean):string;
var buf:string;
count:integer;
sz:intptr;
begin
 result:='';
 sz:=sizeof(cl.addr);
 while atcp_isdata(cl) do begin
  setlength(buf,packet_size);
  case cl.con_typ of
   CON_TYP_TCP,CON_TYP_SCK:      count:=fprecv    (cl.sock,pointer(buf),packet_size,0);
   CON_TYP_UDP,CON_TYP_UDP_MCAST:count:=fprecvfrom(cl.sock,pointer(buf),packet_size,0,@cl.last_recv_addr,@sz);
   else writeln('ATCP: WTF? cl.con_typ unknown in read');
  end;
  setlength(buf,count);
  result:=result+buf;
  if single then break;
 end;
end;
//############################################################################//
function atcp_iserror(cl:patcp_conn):boolean;
var v,c:integer;
begin
 result:=false;
 if cl=nil then exit;
 result:=cl.error<>0;

 if socket_extra_error_check then if not result and (cl.con_typ=CON_TYP_TCP) then begin
  c:=fprecv(cl.sock,@v,1,MSG_DONTWAIT or MSG_PEEK);
  if c=0 then result:=true;
 end;
end;
//############################################################################//
function atcp_get_buf_size(cl:patcp_conn):integer;
var count,x:integer;
begin
 result:=0;
 count:=0;
 if cl=nil then exit;
 if fpioctl(cl.sock,termio.FIONREAD,@x)=0 then count:=x;
 result:=count;
end;
//############################################################################//
function atcp_last_port(cl:patcp_conn):word;
begin
 result:=0;
 if cl=nil then exit;
 case cl.con_typ of
  CON_TYP_UDP,CON_TYP_UDP_MCAST:result:=cl.last_recv_addr.sin_port;
  else exit;
 end;
end;
//############################################################################//
function atcp_last_ip(cl:patcp_conn):dword;
begin
 result:=0;
 if cl=nil then exit;
 case cl.con_typ of
  CON_TYP_UDP,CON_TYP_UDP_MCAST:result:=cl.last_recv_addr.sin_addr.s_addr;
  else exit;
 end;
end;
//############################################################################//
function atcp_isdata(cl:patcp_conn):boolean;begin result:=atcp_get_buf_size(cl)>0;end;
//############################################################################//
procedure atcp_set_iface(cl:patcp_conn;iface:string);
begin
 if cl=nil then exit;
 cl.iface:=iface;
end;
//############################################################################//
procedure SignalHandler(SigNo:cint); cdecl;
begin
 //if SigNo = SIGPIPE Then WriteLn('Received SIGPIPE.');
end;
//############################################################################//
begin
 //Need to intercept SIGPIPE, or write errors won't be getting caught.
 fpSignal(SIGPIPE,@SignalHandler);
end.
//############################################################################//
