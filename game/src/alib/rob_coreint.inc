//############################################################################//
//BEWARE: System unit's integer is 16bit!
//############################################################################//
{$ifdef ape3}
function call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;       begin result:=ROBERR_NO_SYS;{$ifndef sys}msginit;{$endif}if themsgint=nil then exit;result:=themsgint^.call_rob(nam,sg,sg_cnt);end;
function call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;     begin result:=ROBERR_NO_SYS;{$ifndef sys}msginit;{$endif}if themsgint=nil then exit;result:=themsgint^.call_rob_id(id,sg,sg_cnt);end;
function register_rob(const nam:pchar):dword;                                          begin result:=$FFFFFFFF;    {$ifndef sys}msginit;{$endif}if themsgint=nil then exit;result:=themsgint^.register_rob(nam);end;
function get_rob_id(const nam:pchar):dword;                                            begin result:=$FFFFFFFF;    {$ifndef sys}msginit;{$endif}if themsgint=nil then exit;result:=themsgint^.get_rob_id(nam);end;
function peek_rob(const id,frm,len:pdword):boolean;                                    begin result:=false;        {$ifndef sys}msginit;{$endif}if themsgint=nil then exit;result:=themsgint^.peek_rob(id,frm,len);end;
function fetch_rob(const id,frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;begin result:=false;        {$ifndef sys}msginit;{$endif}if themsgint=nil then exit;result:=themsgint^.fetch_rob(id,frm,sg,sg_cnt);end;
//############################################################################//
{$else}
{$ifdef vm_kernel}
function call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;       begin result:=ins_msg(nam,sg[0].ptr,sg[0].sz);end;
function call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;     begin result:=0;end;
function register_rob(const nam:pchar):dword;                                          begin result:=0;end;   
function get_rob_id(const nam:pchar):dword;                                            begin result:=0;end;
function peek_rob(const id,frm,len:pdword):boolean;                                    begin result:=false;end;
function fetch_rob(const id,frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;begin result:=false;end;
{$else}
//############################################################################//
function call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;       begin result:=rob.call_rob(nam,sg,sg_cnt);end;   
function call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;     begin result:=rob.call_rob_id(id,sg,sg_cnt);end;
function register_rob(const nam:pchar):dword;                                          begin result:=rob.register_rob(nam);end;       
function get_rob_id(const nam:pchar):dword;                                            begin result:=rob.get_rob_id(nam);end;
function peek_rob(const id,frm,len:pdword):boolean;                                    begin result:=rob.peek_rob(id,frm,len);end;
function fetch_rob(const id,frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;begin result:=rob.fetch_rob(id,frm,sg,sg_cnt);end;
{$endif}
{$endif}
//############################################################################//
function mstri(const par:longint):string_name;begin str(par,result);end;
//############################################################################//
procedure robs_set_reply;
var s:string;
begin
 if reply_ev<>0 then exit;
 s:=mstri(get_process_id)+'.reply';
 reply_ev:=register_rob(pchar(s));
end;
//############################################################################//
//############################################################################//
function call_rob_buf(const nam:pchar;const buf:pointer;const len:dword):dword;
var sg:sg_rec;
begin
 sg.ptr:=buf;
 sg.sz:=len;
 result:=call_rob(nam,@sg,1);
end;
//############################################################################//
function call_rob_0     (const nam:pchar)               :dword;begin result:=call_rob_buf(nam,nil,0);end;
function call_rob_byte  (const nam:pchar;const d:byte)  :dword;begin result:=call_rob_buf(nam,@d,sizeof(d));end;
function call_rob_word  (const nam:pchar;const d:word)  :dword;begin result:=call_rob_buf(nam,@d,sizeof(d));end;
function call_rob_dword (const nam:pchar;const d:dword) :dword;begin result:=call_rob_buf(nam,@d,sizeof(d));end;
function call_rob_string(const nam:pchar;const s:string):dword;begin result:=call_rob_buf(nam,@s[1],length(s));end;
//############################################################################//
function peek_rob_any(const id,frm,len:pdword):boolean;
begin
 id^:=0;
 result:=peek_rob(id,frm,len);
end;
//############################################################################//
function peek_rob_id(const id:dword;const frm,len:pdword):boolean;
var i:dword;
begin
 i:=id;
 result:=peek_rob(@i,frm,len);
end;
//############################################################################//
function peek_rob_any_wait(const id,frm,len:pdword):boolean;
begin
 result:=peek_rob_any(id,frm,len);
 {$ifdef ape3}if not result then pause;{$endif}   
 if not result then result:=peek_rob_any(id,frm,len);
end;
//############################################################################//
function peek_rob_id_wait (const id:dword;const frm,len:pdword):boolean;
begin
 result:=peek_rob_id(id,frm,len);
 {$ifdef ape3}if not result then pause;{$endif}  
 if not result then result:=peek_rob_id(id,frm,len);
end;
//############################################################################//
function fetch_rob_id(const id:dword;const frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;
var i:dword;
begin
 i:=id;
 result:=fetch_rob(@i,frm,sg,sg_cnt);
end;
//############################################################################//
function fetch_rob_id_buf(const id:dword;const frm:pdword;const buf:pointer;const len:dword):boolean;
var i:dword;
sg:sg_rec;
begin
 sg.ptr:=buf;
 sg.sz:=len;

 i:=id;
 result:=fetch_rob(@i,frm,@sg,1);
end;
//############################################################################//
//############################################################################//
function robs_reply(const frm:dword;const buf:pointer;const len:dword):dword;
var rp:string_name;
begin
 rp:=mstri(frm)+'.reply';
 rp[length(rp)+1]:=#0;
 result:=call_rob_buf(pchar(@rp[1]),buf,len);
end;
//############################################################################//
function robs_reply_0     (const frm:dword)               :dword;begin result:=robs_reply(frm,nil,0);end;
function robs_reply_byte  (const frm:dword;const d:byte)  :dword;begin result:=robs_reply(frm,@d,sizeof(d));end;
function robs_reply_word  (const frm:dword;const d:word)  :dword;begin result:=robs_reply(frm,@d,sizeof(d));end;
function robs_reply_dword (const frm:dword;const d:dword) :dword;begin result:=robs_reply(frm,@d,sizeof(d));end;
function robs_reply_string(const frm:dword;const s:string):dword;begin result:=robs_reply(frm,@s[1],length(s));end;
//############################################################################//
//############################################################################//
function robs_poll_reply(out len:dword):boolean;
var frm:dword;
begin
 robs_set_reply;
 result:=peek_rob_id(reply_ev,@frm,@len);
end;
//############################################################################//
function robs_fetch_reply(const buf:pointer;const len:integer):boolean;
var frm:dword;
begin
 result:=fetch_rob_id_buf(reply_ev,@frm,buf,len);
end;
//############################################################################//
function robs_get_sg(const sg:psg_list;const sg_cnt:integer):boolean;
var frm,len:dword;
begin
 result:=robs_poll_reply(len);
 if result then result:=fetch_rob_id(reply_ev,@frm,sg,sg_cnt);
end;
//############################################################################//
function robs_get_string(out s:string):boolean;
var len:dword;
begin
 result:=robs_poll_reply(len);
 if result then begin
  setlength(s,len);
  result:=robs_fetch_reply(@s[1],len);
 end;
end;
//############################################################################//
function robs_get_dword(out d:dword):boolean;
var len:dword;
begin
 result:=robs_poll_reply(len);
 if result and (len=sizeof(d)) then begin
  result:=robs_fetch_reply(@d,len);
 end else result:=false;
end;
//############################################################################//
function robs_get_buf(const buf:pointer;const exp_len:dword):boolean;
var len:dword;
begin
 result:=robs_poll_reply(len);
 if result and (len=exp_len) then begin
  result:=robs_fetch_reply(buf,len);
 end else result:=false;
end;
//############################################################################//
//############################################################################//
function sync_call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;
begin
 robs_set_reply;
 result:=call_rob(nam,sg,sg_cnt);
end;
//############################################################################//
function sync_call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;
begin
 robs_set_reply;
 result:=call_rob_id(id,sg,sg_cnt);
end;
//############################################################################// 
function sync_call_rob_buf(const nam:pchar;const buf:pointer;const len:dword):dword;
var sg:sg_rec;
begin
 sg.ptr:=buf;
 sg.sz:=len;
 result:=sync_call_rob(nam,@sg,1);
end;
//############################################################################//
function sync_call_rob_0     (const nam:pchar)               :dword;begin result:=sync_call_rob_buf(nam,nil,0);end;
function sync_call_rob_byte  (const nam:pchar;const d:byte)  :dword;begin result:=sync_call_rob_buf(nam,@d,sizeof(d));end;
function sync_call_rob_word  (const nam:pchar;const d:word)  :dword;begin result:=sync_call_rob_buf(nam,@d,sizeof(d));end;
function sync_call_rob_dword (const nam:pchar;const d:dword) :dword;begin result:=sync_call_rob_buf(nam,@d,sizeof(d));end;
function sync_call_rob_string(const nam:pchar;const s:string):dword;begin result:=sync_call_rob_buf(nam,@s[1],length(s));end;
//############################################################################//
procedure write_sys_log(const s:string);begin call_rob_string('ulog.post_line',s);end;
//############################################################################//


