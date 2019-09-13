//############################################################################//  
unit rob;
{$ifdef FPC}{$MODE delphi}{$endif}
interface 
uses asys,rob_rec{$ifdef ape3},akernel{$endif};
//############################################################################// 
type
rob_msg_rec=record
 used:boolean;
 one,frm:dword;
 data:pointer;
 len:dword;
 fix_buf:array[0..rob_fix_len-1]of byte;
end;
prob_msg_rec=^rob_msg_rec;

rob_rec=record
 name:string_name;
 id:dword;
 ones_cnt:integer;
 ones:array[0..rob_ones_count-1]of dword;  //Which thread
  
 last_msg:dword; 
 msg_cnt,msg_sent,msg_received:integer;
 msg:array[0..rob_msg_count-1]of rob_msg_rec; //Messages
end;
prob_rec=^rob_rec;
//############################################################################//
type
prob_bst_node_rec=^rob_bst_node_rec;
rob_bst_node_rec=record
 used:boolean;
 key:dword;
 vl:integer;
 left,right:integer;
end;
rob_bst_rec=record
 n:array of rob_bst_node_rec;
 cnt,sp:integer;
 count,root:integer;
end;
//############################################################################//  
var
robs:array of prob_rec;
robs_bst:rob_bst_rec;
last_rob_id:dword=1;
rob_mx:mutex_typ;
//############################################################################//
function call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword; 
function call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;

function register_rob(const nam:pchar):dword;
procedure unregister_rob_thread(const one:dword);
function get_rob_id(const nam:pchar):dword;

function peek_rob (const id,frm,len:pdword):boolean;
function fetch_rob(const id,frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;
//############################################################################// 
implementation
//############################################################################//
function rob_bst_new(var t:rob_bst_rec):integer;
begin
 t.count:=t.count+1;
 result:=t.cnt;
 t.cnt:=t.cnt+1;
 if result>=length(t.n) then setlength(t.n,result*2+1);
 t.n[result].used:=true;
end;
//############################################################################//
procedure rob_bst_create(out t:rob_bst_rec);
begin
 setlength(t.n,100);
 t.cnt:=0;
 t.sp:=0;
 t.root:=-1;
 t.count:=0;
end;
//############################################################################//
function rob_bst_find_node_parent(var t:rob_bst_rec;const key:dword;out parent:integer):integer;
begin
 result:=t.root;
 parent:=-1;
 while result<>-1 do begin
  if t.n[result].key=key then exit;
  parent:=result;
  if t.n[result].key>key then result:=t.n[result].left
                         else result:=t.n[result].right;
 end;
end;
//############################################################################//
function rob_bst_find_node(var t:rob_bst_rec;const key:dword):integer;
var parent,n:integer;
begin
 result:=-1;
 n:=rob_bst_find_node_parent(t,key,parent);
 if n=-1 then exit;
 result:=t.n[n].vl;
end;
//############################################################################//
//Assumes no repeats
function rob_bst_insert(var t:rob_bst_rec;const key:dword;const vl:integer):boolean;
var nt,parent:integer;
begin
 result:=true;
 nt:=rob_bst_find_node_parent(t,key,parent);
 if nt<>-1 then begin
  t.n[nt].vl:=vl;
  result:=false;
  exit;
 end;

 nt:=rob_bst_new(t);
 t.n[nt].left:=-1;
 t.n[nt].right:=-1;
 t.n[nt].key:=key;
 t.n[nt].vl:=vl;

 if parent=-1 then begin
  t.root:=nt;
 end else begin
  if t.n[parent].key>key then t.n[parent].left:=nt
                         else t.n[parent].right:=nt;
 end;
end;
//############################################################################//
procedure rob_lock;begin mutex_lock(rob_mx);end;
procedure rob_unlock;begin mutex_release(rob_mx);end;
//############################################################################//
//############################################################################//
procedure sort_rob(l,r:integer);
var i,j:integer;
p:string_name;  
t:prob_rec;
begin
 repeat
  i:=l;j:=r;    
  p:=robs[(l+r)div 2].name;
  repeat
   while (i<r)and(p>robs[i].name) do i:=i+1;
   while (j>l)and(p<robs[j].name) do j:=j-1;
   if i<=j then begin
    if i<j then begin
     t:=robs[i];
     robs[i]:=robs[j];
     robs[j]:=t;
    end;
    i:=i+1;
    j:=j-1;
   end;
  until i>j;
  if j>l then sort_rob(l,j);
  if i<r then sort_rob(i,r);
  l:=i;
 until i>=r;
end;
//############################################################################//  
function fetch_rob_linear(const nam:string_name):integer;
var i:integer;
begin
 result:=-1;
 for i:=0 to length(robs)-1 do if robs[i].name=nam then begin result:=i;exit;end;
end;
//############################################################################//  
function fetch_rob_binary(const nam:string_name):integer;
var i,n,d,k:integer;
begin
 result:=-1;
 if length(robs)=0 then exit;
 
 n:=length(robs)-1;
 i:=n div 2;  
 d:=0;
 while robs[i].name<>nam do begin
  if n=d then exit;
  if n-d=1 then begin
   if robs[i].name=nam then break;
   if robs[n].name=nam then begin i:=n;break;end;
   exit;
  end;
  k:=(n-d)div 2+d;
  if nam<robs[i].name then n:=k else d:=k;
  i:=(n-d)div 2+d;
 end;
 result:=i;
end;
//############################################################################//
function add_one_rob(const n,one,frm:dword;const sg:psg_list;const sg_cnt:integer):dword;
var i,p,c,len:integer;
m:prob_msg_rec;
begin
 result:=ROBERR_FULL;
 c:=robs[n].last_msg;
 m:=@robs[n].msg[c];
 if m.used then exit;
 robs[n].last_msg:=(c+1)mod rob_msg_count;
 robs[n].msg_cnt:=robs[n].msg_cnt+1;

 m.used:=true;
 m.one:=one;
 m.frm:=frm;

 len:=0;
 for i:=0 to sg_cnt-1 do len:=len+sg[i].sz;
 m.len:=len;

 if(len<>0)and(sg<>nil)then begin
  if len<=rob_fix_len then m.data:=@m.fix_buf[0] else getmem(m.data,len);  
  p:=0; 
  for i:=0 to sg_cnt-1 do begin
   if sg[i].sz<>0 then move(sg[i].ptr^,pbytea(m.data)[p],sg[i].sz);
   p:=p+sg[i].sz;
  end;
 end else m.data:=nil;


 {$ifdef ape3}unpause_pid(one,true);{$endif}

 result:=ROBERR_OK;
end;
//############################################################################//
function call_rob_proc(const i:integer;const sg:psg_list;const sg_cnt:integer):dword;
var j:integer;
frm,r:dword;
begin
 result:=ROBERR_NO_TARGET;
 frm:=get_process_id;
 if robs[i].ones_cnt<>0 then result:=ROBERR_OK;
 for j:=0 to robs[i].ones_cnt-1 do begin
  r:=add_one_rob(i,robs[i].ones[j],frm,sg,sg_cnt);
  if r<>ROBERR_OK then begin
   result:=r;
   break;
  end;
 end;
 if result=ROBERR_OK then robs[i].msg_sent:=robs[i].msg_sent+1;
end;
//############################################################################//
function call_rob(const nam:pchar;const sg:psg_list;const sg_cnt:integer):dword;
var i:integer;
begin
 rob_lock;
 result:=ROBERR_NO_TARGET;
 i:=fetch_rob_binary(nam);
 if i<>-1 then result:=call_rob_proc(i,sg,sg_cnt);
 rob_unlock;
end;
//############################################################################//
function call_rob_id(const id:dword;const sg:psg_list;const sg_cnt:integer):dword;
var i:integer;
begin
 rob_lock;
 result:=ROBERR_NO_TARGET;
 i:=rob_bst_find_node(robs_bst,id);
 if i<>-1 then result:=call_rob_proc(i,sg,sg_cnt);
 rob_unlock;
end;
//############################################################################//
function register_rob(const nam:pchar):dword;
var i:integer;
begin   
 rob_lock;

 i:=fetch_rob_binary(nam);
 if i=-1 then begin
  i:=length(robs);
  setlength(robs,i+1);
  
  new(robs[i]);
  fillchar(robs[i]^,sizeof(robs[i]^),0);
  
  robs[i].name:=nam;
  robs[i].id:=last_rob_id;
  last_rob_id:=last_rob_id+1;
 end;
 result:=robs[i].id;

 if robs[i].ones_cnt<rob_ones_count then begin
  robs[i].ones[robs[i].ones_cnt]:=get_process_id;
  robs[i].ones_cnt:=robs[i].ones_cnt+1;
 end;
 
 sort_rob(0,length(robs)-1);
 rob_bst_create(robs_bst);
 for i:=0 to length(robs)-1 do rob_bst_insert(robs_bst,robs[i].id,i);

 rob_unlock;
end;  
//############################################################################//
function get_rob_id(const nam:pchar):dword;
var i:integer;
begin
 result:=0;
 rob_lock;
 i:=fetch_rob_binary(nam);
 if i<>-1 then result:=robs[i].id;
 rob_unlock;
end;
//############################################################################//
function get_rob(const id,frm,len:pdword;const sg:psg_list;const sg_cnt:integer;const fetch:boolean):boolean;
var i,j,c,n,p,k,sz,part_sz:integer;
one:dword;
r:prob_rec;
m:prob_msg_rec;
begin result:=false; try
 rob_lock;
 one:=get_process_id;
 
 for j:=0 to length(robs)-1 do begin
  r:=robs[j];
  if id^<>0 then if id^<>r.id then continue;
  c:=r.last_msg;
  for i:=0 to rob_msg_count-1 do begin
   n:=(c+i) mod rob_msg_count;
   m:=@r.msg[n];
   if m.used then if m.one=one then begin 
    id^:=r.id;
    len^:=m.len;
    frm^:=m.frm;
    
    if fetch then begin
     m.used:=false;
     if m.data<>nil then begin
      if sg<>nil then begin
       p:=0;
       sz:=m.len;
       for k:=0 to sg_cnt-1 do begin
        part_sz:=sg[k].sz;
        if part_sz>sz then part_sz:=sz;
        if part_sz<>0 then move(pbytea(m.data)[p],sg[k].ptr^,part_sz);
        p:=p+part_sz;
        sz:=sz-part_sz;
        if sz=0 then break;
       end;
      end;
      if m.len>rob_fix_len then freemem(m.data);
     end;
     r.msg_cnt:=r.msg_cnt-1;  
     r.msg_received:=r.msg_received+1;
    end;
    
    result:=true;
    rob_unlock;
    exit;
   end;   
  end;
 end;
 rob_unlock;
 except halt; end;
end;
//############################################################################//
function peek_rob (const id,frm,len:pdword):boolean;                                                 begin result:=get_rob(id,frm, len,nil,0     ,false);end;
function fetch_rob(const id,frm:pdword;const sg:psg_list;const sg_cnt:integer):boolean;var len:dword;begin result:=get_rob(id,frm,@len,sg ,sg_cnt,true);end;
//############################################################################//
procedure unregister_rob_thread(const one:dword);
var i,j,c:integer;
mv:boolean;
tmp:array[0..rob_ones_count-1]of dword;
begin  
 rob_lock;

 for i:=0 to length(robs)-1 do begin
  mv:=false;
  for j:=0 to robs[i].ones_cnt-1 do if robs[i].ones[j]=one then begin mv:=true;robs[i].ones[j]:=$FFFFFFFF;end;
  if mv then begin
   c:=0;
   for j:=0 to robs[i].ones_cnt-1 do if robs[i].ones[j]<>$FFFFFFFF then begin tmp[c]:=robs[i].ones[j];c:=c+1;end;
   if c<>0 then for j:=0 to c-1 do robs[i].ones[j]:=tmp[j];
   robs[i].ones_cnt:=c;
  end;

  for j:=0 to rob_msg_count-1 do if robs[i].msg[j].used then if robs[i].msg[j].one=one then begin 
   if robs[i].msg[j].data<>nil then begin
    if robs[i].msg[j].len>rob_fix_len then freemem(robs[i].msg[j].data);
   end;
   robs[i].msg[j].used:=false;
  end;
 end;
 
 rob_unlock;
end;
//############################################################################//
begin
 rob_mx:=mutex_create;
end.
//############################################################################//
