//############################################################################//
const
ROBERR_OK       =0;
ROBERR_UNK      =1;
ROBERR_NO_TARGET=2;
ROBERR_FULL     =4;
ROBERR_NO_SYS   =8;
//############################################################################//
const
rob_name_limit=64;
rob_msg_count=256;
rob_ones_count=32;
rob_fix_len=128;
//############################################################################//
type
string_name=string[rob_name_limit];
sg_rec=record
 ptr:pointer;
 sz:dword;
end;
asg_rec=array[0..100000]of sg_rec;
psg_list=^asg_rec;
//############################################################################//
msginttyp=record
 call_rob:function(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;
 call_rob_id:function(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;
 register_rob:function(const nam:pchar):dword;

 peek_rob: function(const id,frm,len:pdword):boolean;
 fetch_rob:function(const id,frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;  

 get_rob_id:function(const nam:pchar):dword;
end;
pmsginttyp=^msginttyp;
//############################################################################//

