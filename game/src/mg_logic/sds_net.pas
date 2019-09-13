//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold server interoperability
//############################################################################//
unit sds_net;
interface
uses sysutils,asys
{$ifdef mgnet_tcp},atcp,strval,strtool{$endif}
{$ifdef mgnet_rob},rob_int,rob_rec{$endif}
;    
//############################################################################//
var
gs_server:string='127.0.0.1';
gs_code:string='123456';
gs_port:integer=18008;
//############################################################################//    
function sds_json_exchange(st:string;out res:string;status:pdouble=nil;mult:integer=1):boolean;
//############################################################################//   
implementation
//############################################################################//
{$ifdef mgnet_tcp}
//############################################################################//
const
tcp_proto_ver=2;
tcp_timeout=60;
//############################################################################//
var cl:ptcp_conn=nil;
timeout_mult:integer=1;
//############################################################################//
function parse_message(cl:ptcp_conn;out data:string;status:pdouble):boolean;
var buf,s:string;
rd,skip,n,ver,len:integer;
begin
 result:=false;
 if status<>nil then status^:=0;

 skip:=0;
 while not stop_threads do begin
  if tcp_isdata(cl) then break;
  sleep(10);
  skip:=skip+1;
  if skip>=timeout_mult*tcp_timeout*100 then exit;
 end;

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

 if status<>nil then if len<>0 then status^:=rd/len;

 skip:=0;
 while rd<len do begin
  while tcp_isdata(cl) do begin
   s:=tcp_read_str(cl);
   buf:=buf+s;
   rd:=rd+length(s);
   if status<>nil then if len<>0 then status^:=rd/len;
   skip:=0;
  end;
  sleep(10);
  skip:=skip+1;
  if skip>=timeout_mult*tcp_timeout*100 then exit;
 end;

 data:=buf;
 result:=true;
 //writeln(data);
end;
//############################################################################//
function put_post_data(fbuf:string;out rs:string;status:pdouble):boolean;
var s:string;
i:integer;
begin
 result:=false;
 socket_extra_error_check:=true; //For detection of closed connections

 s:='MGSP*'+stri(tcp_proto_ver)+'*'+stri(length(fbuf))+'*'+fbuf;

 if tcp_iserror(cl) then begin tcp_free(cl);cl:=nil;end;

 for i:=0 to 1 do begin
  if cl=nil then begin
   cl:=tcp_client_create(gs_server,gs_port);
   if not tcp_client_connect(cl) then begin tcp_free(cl);cl:=nil;exit;end;
  end;

  if not tcp_write_str(cl,s) then begin tcp_disconnect(cl);tcp_free(cl);cl:=nil;continue;end;  
  if tcp_iserror(cl) then begin tcp_free(cl);cl:=nil;continue;end;

  result:=parse_message(cl,rs,status);

  if tcp_iserror(cl) then begin tcp_free(cl);cl:=nil;end;
  break;
 end;
end;
{$endif}
//############################################################################//
function sds_json_exchange(st:string;out res:string;status:pdouble=nil;mult:integer=1):boolean;
begin
 {$ifdef mgnet_tcp}
 timeout_mult:=mult;
 result:=put_post_data(st,res,status);
 {$endif}

 {$ifdef mgnet_rob}
 result:=sync_call_rob_string('maxg.server',st)=ROBERR_OK;
 if result then while not robs_get_string(res) do sleep(1);
 {$endif}
 if res<>'' then if res[1]<>'{' then res:='';
end;   
//############################################################################//
begin
end. 
//############################################################################//
