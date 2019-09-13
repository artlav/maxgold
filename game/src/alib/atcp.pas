//############################################################################//  
{$ifdef win32}{$define windows}{$endif}
{$ifdef win64}{$define windows}{$endif}
{$ifdef wince}{$define windows}{$endif}
   
{$ifdef unix}{$define genunix}{$endif}
{$ifdef linux}{$define genunix}{$endif}
//{$ifdef android}{$undef genunix}{$endif}
//{$ifdef darwin}{$undef genunix}{$endif}
//############################################################################//
unit atcp;
interface
uses asys
 {$ifdef windows},atcp_win{$endif}
 {$ifdef genunix},atcp_unix{$endif}
; 
//############################################################################//      
type ptcp_conn=pointer;
//############################################################################//
function tcp_create_server(ip:string;port:word):ptcp_conn;
function tcp_client_create(url:string;port:word;no_resolve:boolean=false):ptcp_conn;
function tcp_socket_client_create(fn:string):ptcp_conn;
function tcp_udp_create_server(ip:string;port:word):ptcp_conn;
function tcp_udp_create_mcast(ip:string;port:word):ptcp_conn;
function tcp_udp_client_create(fn:string;port:word;no_resolve:boolean=false):ptcp_conn;
function tcp_mk_client_copy(sck:integer):ptcp_conn;
procedure tcp_free(cl:ptcp_conn);

function tcp_client_connect(cl:ptcp_conn):boolean;
function tcp_disconnect(cl:ptcp_conn):boolean;

function tcp_server_establish(cl:ptcp_conn;again:boolean):boolean;
function tcp_server_run(cl:ptcp_conn;again:boolean):boolean;
function tcp_server_run_one(cl:ptcp_conn;proc,par:pointer):boolean;
function tcp_server_runsplit(cl:ptcp_conn;proc,par:pointer):boolean;
function tcp_server_runsplit_stp(cl:ptcp_conn;proc,par:pointer;var stop:boolean):boolean;
function tcp_server_stop(cl:ptcp_conn):boolean;

procedure tcp_dump_tail(cl:ptcp_conn);

function tcp_read_str(cl:ptcp_conn;single:boolean=false):string;
function tcp_read_buf(cl:ptcp_conn;buf:pointer;bs:integer;single:boolean=false):integer;

function tcp_write_str(cl:ptcp_conn;str:string):boolean;
function tcp_write_buf(cl:ptcp_conn;buf:pointer;siz:integer):boolean;

function tcp_write_buf_to(cl:ptcp_conn;buf:pointer;siz:integer;dst:dword;dst_port:word):boolean;
function tcp_write_str_to(cl:ptcp_conn;str:string;dst:dword;dst_port:word):boolean;

function tcp_iserror(cl:ptcp_conn):boolean;
function tcp_isdata(cl:ptcp_conn):boolean;
function tcp_get_buf_size(cl:ptcp_conn):integer;
function tcp_host2ip(host:string):string;
function tcp_localip:string;
//############################################################################//
function tcp_waitreadbuf(cl:ptcp_conn;buf:pointer;bs:integer):integer;
function tcp_waitreadstring(cl:ptcp_conn;sz:integer):string;
procedure tcp_waitreadpad(cl:ptcp_conn;sz:integer);
//############################################################################//
implementation 
//############################################################################//
function tcp_create_server(ip:string;port:word):ptcp_conn;                             begin result:=atcp_create_server(ip,port); end;
function tcp_client_create(url:string;port:word;no_resolve:boolean=false):ptcp_conn;   begin result:=atcp_client_create(url,port,no_resolve); end;
function tcp_socket_client_create(fn:string):ptcp_conn;                                begin result:=atcp_socket_client_create(fn); end;
function tcp_udp_create_server(ip:string;port:word):ptcp_conn;                         begin result:=atcp_udp_create_server(ip,port); end;
function tcp_udp_create_mcast(ip:string;port:word):ptcp_conn;                          begin result:=atcp_udp_create_mcast(ip,port); end;
function tcp_udp_client_create(fn:string;port:word;no_resolve:boolean=false):ptcp_conn;begin result:=atcp_udp_client_create(fn,port,no_resolve); end;
function tcp_mk_client_copy(sck:integer):ptcp_conn;                                    begin result:=atcp_mk_client_copy(sck); end;
procedure tcp_free(cl:ptcp_conn);                                                      begin atcp_free(cl); end;

function tcp_client_connect(cl:ptcp_conn):boolean; begin result:=atcp_client_connect(cl); end;
function tcp_disconnect(cl:ptcp_conn):boolean;     begin result:=atcp_disconnect(cl); end;

function tcp_server_establish(cl:ptcp_conn;again:boolean):boolean;                        begin result:=atcp_server_establish(cl,again); end;
function tcp_server_run(cl:ptcp_conn;again:boolean):boolean;                              begin result:=atcp_server_run(cl,again); end;
function tcp_server_run_one(cl:ptcp_conn;proc,par:pointer):boolean;                       begin result:=atcp_server_run_one(cl,proc,par); end;
function tcp_server_runsplit(cl:ptcp_conn;proc,par:pointer):boolean;                      begin result:=atcp_server_runsplit(cl,proc,par); end;
function tcp_server_runsplit_stp(cl:ptcp_conn;proc,par:pointer;var stop:boolean):boolean; begin result:=atcp_server_runsplit_stp(cl,proc,par,stop); end;
function tcp_server_stop(cl:ptcp_conn):boolean;                                           begin result:=atcp_server_stop(cl); end;

procedure tcp_dump_tail(cl:ptcp_conn);                                begin atcp_dump_tail(cl); end;

function tcp_read_buf(cl:ptcp_conn;buf:pointer;bs:integer;single:boolean=false):integer;   begin result:=atcp_read_buf(cl,buf,bs,single); end;
function tcp_read_str(cl:ptcp_conn;single:boolean=false):string;                           begin result:=atcp_read_str(cl,single); end;

function tcp_write_buf_to(cl:ptcp_conn;buf:pointer;siz:integer;dst:dword;dst_port:word):boolean;begin result:=atcp_write_buf(cl,buf,siz,dst,dst_port); end;
function tcp_write_str_to(cl:ptcp_conn;str:string;dst:dword;dst_port:word):boolean;             begin result:=false;if length(str)=0 then exit; result:=tcp_write_buf_to(cl,@str[1],length(str),dst,dst_port); end;

function tcp_write_buf(cl:ptcp_conn;buf:pointer;siz:integer):boolean;begin result:=tcp_write_buf_to(cl,buf,siz,0,0); end;
function tcp_write_str(cl:ptcp_conn;str:string):boolean;             begin result:=tcp_write_str_to(cl,str,0,0); end;

procedure tcp_set_iface(cl:ptcp_conn;iface:string);begin atcp_set_iface(cl,iface); end;

function tcp_iserror(cl:ptcp_conn):boolean;      begin result:=atcp_iserror(cl); end;
function tcp_isdata(cl:ptcp_conn):boolean;       begin result:=atcp_isdata(cl); end;
function tcp_get_buf_size(cl:ptcp_conn):integer; begin result:=atcp_get_buf_size(cl); end;
//For UDP
function tcp_last_port(cl:ptcp_conn):word;       begin result:=atcp_last_port(cl); end;
function tcp_last_ip(cl:ptcp_conn):dword;        begin result:=atcp_last_ip(cl); end;

function tcp_host2ip(host:string):string;        begin result:=atcp_host2ip(host); end;
function tcp_localip:string;                     begin result:=atcp_localip; end;
//############################################################################//
//############################################################################//
function tcp_waitreadbuf(cl:ptcp_conn;buf:pointer;bs:integer):integer;
begin 
 result:=0;
 while result<bs do begin
  if tcp_isdata(cl) then result:=result+tcp_read_buf(cl,@pbytea(buf)[result],bs-result) else sleep(1);
 end;
end;
//############################################################################//
function tcp_waitreadstring(cl:ptcp_conn;sz:integer):string;
var i:integer;
begin 
 setlength(result,sz);
 i:=0;
 while i<sz do if tcp_isdata(cl) then i:=i+tcp_read_buf(cl,@result[i+1],sz-i) else sleep(1);
end;
//############################################################################//
procedure tcp_waitreadpad(cl:ptcp_conn;sz:integer);
var i:integer;
buf:pointer;
begin
 if sz=0 then exit;
 i:=0;
 getmem(buf,sz);
 while i<sz do if tcp_isdata(cl) then i:=i+tcp_read_buf(cl,buf,sz-i) else sleep(1);
 freemem(buf);
end;
//############################################################################//
begin
end.
//############################################################################//

