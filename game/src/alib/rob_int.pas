//############################################################################//
unit rob_int;
{$ifdef FPC}{$MODE delphi}{$endif}
interface
uses asys
{$ifdef ape3}
 ,akernel,rob_rec
{$else}
 {$ifdef vm_kernel}
  ,dev,kerec,kevar,rob_rec
 {$else}
  ,rob,rob_rec
 {$endif}
{$endif};
//############################################################################//
{$ifdef ape3}{$I ape.inc}{$endif}
//############################################################################//
function call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;
function call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;
function register_rob(const nam:pchar):dword; 
function get_rob_id(const nam:pchar):dword;

function peek_rob_any_wait(const id,frm,len:pdword):boolean;
function peek_rob_id_wait (const id:dword;const frm,len:pdword):boolean;
function peek_rob_any     (const id,frm,len:pdword):boolean;
function peek_rob_id      (const id:dword;const frm,len:pdword):boolean;
function fetch_rob_id     (const id:dword;const frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;
function fetch_rob_id_buf (const id:dword;const frm:pdword;const buf:pointer;const len:dword):boolean;
//############################################################################//   
function call_rob_buf   (const nam:pchar;const buf:pointer;const len:dword):dword;
function call_rob_0     (const nam:pchar):dword;
function call_rob_byte  (const nam:pchar;const d:byte):dword;
function call_rob_word  (const nam:pchar;const d:word):dword;
function call_rob_dword (const nam:pchar;const d:dword):dword;
function call_rob_string(const nam:pchar;const s:string):dword;
//############################################################################//
function robs_reply       (const frm:dword;const buf:pointer;const len:dword):dword;
function robs_reply_0     (const frm:dword)               :dword;
function robs_reply_byte  (const frm:dword;const d:byte)  :dword;
function robs_reply_word  (const frm:dword;const d:word)  :dword;
function robs_reply_dword (const frm:dword;const d:dword) :dword;
function robs_reply_string(const frm:dword;const s:string):dword;
//############################################################################//
procedure robs_set_reply;
function robs_poll_reply(out len:dword):boolean;
function robs_fetch_reply(const buf:pointer;const len:integer):boolean;

function robs_get_sg(const sg:psg_list;const sg_cnt:integer):boolean;
function robs_get_string(out s:string):boolean;
function robs_get_dword(out d:dword):boolean;
function robs_get_buf(const buf:pointer;const exp_len:dword):boolean;
//############################################################################//
function sync_call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;
function sync_call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;

function sync_call_rob_buf   (const nam:pchar;const buf:pointer;const len:dword):dword;
function sync_call_rob_0     (const nam:pchar)               :dword;
function sync_call_rob_byte  (const nam:pchar;const d:byte)  :dword;
function sync_call_rob_word  (const nam:pchar;const d:word)  :dword;
function sync_call_rob_dword (const nam:pchar;const d:dword) :dword;
function sync_call_rob_string(const nam:pchar;const s:string):dword;
//############################################################################//
procedure write_sys_log(const s:string);
//############################################################################//
implementation
//############################################################################//
//Shared with system unit in APE3
{$ifndef ape3}
threadvar
reply_ev:dword;
{$endif}
//############################################################################//
{$ifdef ape3}
threadvar 
themsgint:pmsginttyp;
//############################################################################//
procedure msginit;
var themsgref:pdevref;
begin
 if themsgint<>nil then exit;
 themsgref:=devgetref(ape_msg_dev);
 if themsgref=nil then exit;
 themsgint:=themsgref.calls.prdgetint();
end;
//############################################################################//
{$else}
{$ifdef vm_kernel}
//############################################################################//
function ins_msg(nam:string;data:pointer;len:dword):dword;
var c,sz,szn,i,free:integer;
first:dword;
begin
 result:=ROBERR_FULL;
 szn:=length(nam);
 sz:=szn+integer(len);
 if sz>=255 then exit;

 first:=kmsg.first;
 free:=kmsg_size-1;
 if kmsg.last<>first then begin
  free:=0;
  c:=kmsg.last;
  for i:=0 to kmsg_size-1 do begin
   c:=(c+1)mod kmsg_size;
   if dword(c)=first then break;
   free:=free+1;
  end;
 end;   
 if sz>=free then begin
  writeln('No free space');
  exit;
 end;

 result:=ROBERR_OK;
 c:=kmsg.last;
 kmsg.data[(c+0)mod kmsg_size]:=szn;
 kmsg.data[(c+1)mod kmsg_size]:=len;
 for i:=0 to szn-1 do kmsg.data[(c+2+i)mod kmsg_size]:=ord(nam[i+1]);
 for i:=0 to len-1 do kmsg.data[(c+2+szn+i)mod kmsg_size]:=pbytea(data)[i];
 kmsg.last:=(kmsg.last+dword(sz)+2)mod kmsg_size;
end;
{$endif}
{$endif}
//############################################################################//
{$i rob_coreint.inc}
//############################################################################//
begin
 //Would be called on demand anyway
 //{$ifdef ape3}msginit;{$endif}
end.
//############################################################################//
