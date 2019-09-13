//############################################################################//
unit atcp_win;
interface
uses asys,winsock;
//############################################################################//
const packet_size=64000;
connection_timeout=5;
//############################################################################//
type
atcp_conn=record
 used:boolean;
 typ:integer;
 con_typ:integer;
 proc,par:pointer;
 error:integer;

 addr:sockaddr_in;

 sock,lstn:integer;
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
function atcp_read_str(cl:patcp_conn;single:boolean):string;
function atcp_read_buf(cl:patcp_conn;buf:pointer;bs:integer;single:boolean):integer;
function atcp_write_buf(cl:patcp_conn;buf:pointer;siz:integer;dst:dword;dst_port:word):boolean;

function atcp_isdata(cl:patcp_conn):boolean;
function atcp_get_buf_size(cl:patcp_conn):integer;

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
const
CON_TYP_TCP=0;
CON_TYP_SCK=1;
CON_TYP_UDP=2;

TYP_CLIENT=0;
TYP_SERVER=1;
//############################################################################//
var WSData:TWSAData;
//############################################################################//
function dns_resolve(url:string;no_resolve:boolean):dword;
var hst:phostent;
begin
 result:=0;
 //if no_resolve then exit;   //FIXME: Make it return the IP
 hst:=gethostbyname(pchar(url));
 if hst<>nil then result:=intptr(pointer(hst.h_addr_list^)^);
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
var p:phostent;
begin
 p:=gethostbyname(pchar(host));
 if p<>nil then result:=inet_ntoa(pinaddr(p.h_addr_list^)^) else result:=host;
end;
//############################################################################//
function atcp_localip:string;
var p:phostent;
buf:array[0..127] of char;
begin
 result:='';
 if gethostname(@buf,128)=0 then begin
  p:=gethostbyname(@buf);
  if p<>nil then result:=inet_ntoa(pinaddr(p^.h_addr_list^)^)else result:='127.0.0.1';
 end else result:='127.0.0.1';
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
end;
//############################################################################//
function mk_server(ip:string;port:word;con_typ:integer):patcp_conn;
begin
 result:=mk_conn(TYP_SERVER,con_typ);

 fillchar(result.addr,sizeof(result.addr),0);
 result.addr.sin_family:=af_inet;
 result.addr.sin_addr.s_addr:=inet_addr(pchar(h2ip_(ip)));
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
    fillchar(result.addr.sin_zero,sizeof(result.addr.sin_zero),0);
   end;
  end;
 end;
end;
//############################################################################//
procedure atcp_free(cl:patcp_conn);begin closesocket(cl.sock); dispose(cl);end;
//############################################################################//
function atcp_create_server    (ip:string;port:word):patcp_conn;begin result:=mk_server(ip,port,CON_TYP_TCP);end;
function atcp_udp_create_server(ip:string;port:word):patcp_conn;begin result:=mk_server(ip,port,CON_TYP_UDP);end;
//############################################################################//
function atcp_client_create       (url:string;port:word;no_resolve:boolean):patcp_conn;begin result:=mk_client(url,port,CON_TYP_TCP,no_resolve);end;
function atcp_udp_client_create   (url:string;port:word;no_resolve:boolean):patcp_conn;begin result:=mk_client(url,port,CON_TYP_UDP,no_resolve);end;
function atcp_socket_client_create(fn:string):patcp_conn;                              begin result:=nil;end;
function atcp_udp_create_mcast    (ip:string;port:word):patcp_conn;                    begin result:=nil;end;
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
 if cl.typ<>TYP_SERVER then exit;
 result:=true;

 if not again then begin
  cl.lstn:=socket(af_inet,sock_stream,iPPROTO_TCP);
  if cl.lstn<0 then begin cl.error:=1;result:=false;exit;end;

  if bind(cl.lstn,cl.addr,sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;
  if listen(cl.lstn,0)<>0 then begin cl.error:=1;result:=false;exit;end;
 end;
end;
//############################################################################//
function atcp_server_run(cl:patcp_conn;again:boolean):boolean;
begin
 result:=false;
 if cl.typ<>TYP_SERVER then exit;
 result:=true;

 atcp_server_establish(cl,again);

 cl.sock:=accept(cl.lstn,nil,nil);
 if cl.sock<0 then begin cl.error:=1;result:=false;exit;end;
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
  CON_TYP_TCP:cl.lstn:=socket(af_inet,sock_stream,0);
  CON_TYP_UDP:cl.lstn:=socket(af_inet,sock_dgram,IPPROTO_UDP);
  else cl.lstn:=-1;
 end;
 if cl.lstn<0 then begin cl.error:=1;result:=false;exit;end;

 if bind(cl.lstn,cl.addr,sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;

 case cl.con_typ of
  CON_TYP_TCP:while listen(cl.lstn,somaxconn)=0 do begin
   acc:=accept(cl.lstn,nil,nil);
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
    if bind(cl.lstn,cl.addr,sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;
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
 end;
end;
//############################################################################//
function atcp_server_run_one (cl:patcp_conn;proc,par:pointer):boolean;begin result:=do_atcp_server_run(cl,proc,par,false);end;
function atcp_server_runsplit(cl:patcp_conn;proc,par:pointer):boolean;begin result:=do_atcp_server_run(cl,proc,par,true);end;
//############################################################################//
function atcp_server_runsplit_stp(cl:patcp_conn;proc,par:pointer;var stop:boolean):boolean;
var mk:patcp_conn;
n:integer;
tf:tfdset;
tv:timeval;
acc:integer;
begin
 result:=false;
 if cl.typ<>TYP_SERVER then exit;
 result:=true;

 cl.lstn:=socket(af_inet,sock_stream,0);
 if cl.lstn<0 then begin cl.error:=1;result:=false;exit;end;

 if bind(cl.lstn,cl.addr,sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;
 if listen(cl.lstn,somaxconn)<>0 then begin cl.error:=1;result:=false;exit;end;
 while not stop do begin
  tf.fd_count:=1;tf.fd_array[0]:=cl.lstn;
  tv.tv_sec:=1;tv.tv_usec:=0;
  n:=select(0,@tf,nil,nil,@tv);
  if n=SOCKET_ERROR then begin cl.error:=1;result:=false;exit;end;
  if n=1 then begin
   acc:=accept(cl.lstn,nil,nil);
   if acc<0 then begin cl.error:=1;result:=false;exit;end;
   mk:=atcp_mk_client_copy(acc);
   mk.proc:=proc;
   mk.par:=par;
   if mk.sock<>-1 then begin
    start_thread(ramp_thread,mk);
   end else begin
    if bind(cl.lstn,cl.addr,sizeof(cl.addr))<>0 then begin cl.error:=1;result:=false;exit;end;
   end;
  end;
 end;
 shutdown(cl.lstn,2);
 closesocket(cl.lstn);
end;
//############################################################################//
function atcp_server_stop(cl:patcp_conn):boolean;
begin
 result:=true;

 if shutdown(cl.lstn,2)<>0 then begin cl.error:=1;result:=false; end;
 if closesocket(cl.lstn)<>0 then begin cl.error:=1;result:=false; end;
 if closesocket(cl.sock)<>0 then begin cl.error:=1;result:=false; end;
end;
//############################################################################//
function atcp_client_connect(cl:patcp_conn):boolean;
var d,ret,err:integer;
fdwr,fderr:tfdset;
timeout:timeval;
begin
 result:=true;

 case cl.con_typ of
  CON_TYP_TCP:cl.sock:=socket(AF_inet,sock_stream,0);
  CON_TYP_SCK:cl.sock:=socket(AF_unix,sock_stream,0);
  CON_TYP_UDP:cl.sock:=socket(AF_inet,sock_dgram,IPPROTO_UDP);
 end;

 d:=1;
 ioctlsocket(cl.sock,FIONBIO,d);

 ret:=0;
 case cl.con_typ of
  CON_TYP_TCP:ret:=connect(cl.sock,cl.addr,sizeof(cl.addr));
  CON_TYP_SCK:begin cl.error:=1;result:=false;end;
  CON_TYP_UDP:ret:=connect(cl.sock,cl.addr,sizeof(cl.addr));    //Huh?
 end;

 if ret=SOCKET_ERROR then begin
  err:=WSAGetLastError;
  if err=WSAEWOULDBLOCK then begin
   FD_ZERO(fdwr{%H-});
   FD_ZERO(fderr{%H-});
   FD_SET(cl.sock,fdwr);
   FD_SET(cl.sock,fderr);

   timeout.tv_sec:=connection_timeout;
   timeout.tv_usec:=0;

   ret:=select(0,nil,@fdwr,@fderr,@timeout);

   if ret=0 then begin
    cl.error:=1;
    result:=false;
   end else begin
    if FD_ISSET(cl.sock,fdwr)  then begin end;
    if FD_ISSET(cl.sock,fderr) then begin cl.error:=1;result:=false;end;
   end;
  end else begin cl.error:=1;result:=false;end;
 end;

 d:=0;
 ioctlsocket(cl.sock,FIONBIO,d);
end;
//############################################################################//
function atcp_disconnect(cl:patcp_conn):boolean;
begin
 result:=true;
 if shutdown(cl.sock,2)<>0 then begin cl.error:=1;result:=false;end;
 if closesocket(cl.sock)<>0 then begin cl.error:=1;result:=false;end;
 if cl.typ=TYP_SERVER then if closesocket(cl.sock)<>0 then begin cl.error:=1;result:=false;end;
end;
//############################################################################//
//############################################################################//
procedure atcp_dump_tail(cl:patcp_conn);
var buf:string;
begin
 while atcp_isdata(cl) do begin
  setlength(buf,packet_size);
  recv(cl.sock,pointer(buf)^,packet_size,0);
 end;
end;
//############################################################################//
function atcp_read_str(cl:patcp_conn;single:boolean):string;
var buf:string;
count:integer;
begin
 result:='';
 while atcp_isdata(cl) do begin    
  setlength(buf,packet_size);
  count:=recv(cl.sock,pointer(buf)^,packet_size,0);
  setlength(buf,count);
  result:=result+buf;
 end;
end;
//############################################################################//
function atcp_write_buf(cl:patcp_conn;buf:pointer;siz:integer;dst:dword;dst_port:word):boolean;
var i,p:integer;
begin
 //result:=false;
 if siz<packet_size then i:=siz else i:=packet_size;
 p:=0;

 while siz>0 do begin
  result:=(send(cl.sock,pointer(intptr(buf)+intptr(p))^,i,0)<>SOCKET_ERROR);
  if not result then begin cl.error:=1;exit;end;
  p:=p+i;

  siz:=siz-i;
  if siz<packet_size then i:=siz;
 end; 
 result:=true;
end;    
//############################################################################//
function atcp_read_buf(cl:patcp_conn;buf:pointer;bs:integer;single:boolean):integer;
var c:integer;
begin   
 result:=0;
 while atcp_isdata(cl) and(bs-result>0)do begin
  c:=recv(cl.sock,pointer(intptr(buf)+intptr(result))^,bs-result,0);
  if c<0 then exit;
  result:=result+c;
 end;
end;
//############################################################################//
//############################################################################//
//############################################################################//
function atcp_iserror(cl:patcp_conn):boolean;
var v,c,d:integer;
begin
 result:=false;
 if cl=nil then exit;
 result:=cl.error<>0;
  
 if socket_extra_error_check then if not result and (cl.con_typ=CON_TYP_TCP) then begin
  d:=1;
  ioctlsocket(cl.sock,FIONBIO,d);
  //if WSAGetLastError<>0 then begin result:=true;exit;end;
  c:=recv(cl.sock,v{%H-},0,0);
  //writeln(' ',WSAGetLastError,' ',c);
  if c=0 then result:=true;
  d:=0;
  ioctlsocket(cl.sock,FIONBIO,d);
 end;
end;
//############################################################################//
function atcp_isdata(cl:patcp_conn):boolean;
var count:integer;
begin
 result:=false;
 count:=0;
 IOCtlSocket(cl.sock,FIONRead,count);
 if count>0 then result:=true;
end;
//############################################################################//
function atcp_get_buf_size(cl:patcp_conn):integer;
var count:integer;
begin
 count:=0;
 IOCtlSocket(cl.sock,FIONRead,count);
 result:=count;
end;
//############################################################################//
function atcp_last_port(cl:patcp_conn):word;
begin
 result:=0;
end;
//############################################################################//
function atcp_last_ip(cl:patcp_conn):dword;
begin
 result:=0;
end;
//############################################################################// 
procedure atcp_set_iface(cl:patcp_conn;iface:string);
begin
end;
//############################################################################//
initialization
 WSAStartup($0101,WSData{%H-});
finalization
 WSACleanup;
end.
//############################################################################//
