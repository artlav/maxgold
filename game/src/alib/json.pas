//############################################################################//
unit json;
{$ifdef fpc}{$mode delphi}{$endif}
interface
uses sysutils,asys,maths,strval;
//############################################################################//
const
JTP_NULL=0;
JTP_NODE=1;
JTP_STRING=2;
JTP_ARRAY=3;
JTP_INT=4;
JTP_BOOL=5;
//############################################################################//
type
pjs_elem=^js_elem;
pjs_node=^js_node;
js_node=record
 sorted:boolean;
 start_pos,end_pos:integer;
 e:array of pjs_elem;
end;
//############################################################################//
js_elem=record
 name:string;
 typ:integer;

 node:pjs_node;
 s:string;
 b:boolean;
end;
//############################################################################//
function js_parse(const ins:string;const do_sort:boolean=true):pjs_node;
function js_parse_until(const ins,terminal:string;const do_sort:boolean=true):pjs_node;

function js_to_string(node:pjs_node;md:integer;pad,gap,nl:string):string;
function js_dump(node:pjs_node;md:integer=0;pad:string=''):string;
function js_stringify(node:pjs_node;md:integer=0):string;
//############################################################################//
function js_find_elem(const n:pjs_node;const desc:string):pjs_elem;
function js_get_string(const n:pjs_node;const desc:string;const def:string='nil'):string;
function js_get_node(const n:pjs_node;const desc:string):pjs_node;
function js_get_node_length(const n:pjs_node;const desc:string):integer;
function js_get_node_name(const n:pjs_node;const desc:string):string;
function json_escape(const s:string):string;
procedure free_js(node:pjs_node);
//############################################################################//
function js_vec(const v:vec):string;
function js_quat(const v:quat):string;
function js_qvec(const v:qvec):string;

procedure js_add_line(var s:string;const sp,nl,vl:string);
procedure js_add(var s:string;const sp,nl,nm,vl:string);

procedure js_add_bool(var s:string;const sp,nl,nm:string;const vl:boolean);
procedure js_add_dbl(var s:string;const sp,nl,nm:string;const vl:double);
procedure js_add_int(var s:string;const sp,nl,nm:string;const vl:int64);
procedure js_add_str(var s:string;const sp,nl,nm:string;const vl:string);
procedure js_add_vec(var s:string;const sp,nl,nm:string;const vl:vec);
procedure js_add_qvec(var s:string;const sp,nl,nm:string;const vl:qvec);
procedure js_add_quat(var s:string;const sp,nl,nm:string;const vl:quat);

procedure js_add_blk(var s:string;const sp,nl,new:string);
procedure js_finish(var s:string;const sp,nl:string);
procedure js_finish_arr(var s:string;const sp,nl:string);

function js_parse_vec2(const node:pjs_node):vec2;
function js_parse_vec(const node:pjs_node):vec;
function js_parse_qvec(const node:pjs_node):qvec;
function js_parse_quat(const node:pjs_node):quat;

{$ifdef self_tests}procedure json_self_test;{$endif}
//############################################################################//
implementation
//############################################################################//
type
js_parsing=record
 ins:string;
 p:integer;
 root:pjs_node;
 fault:boolean;
 do_sort:boolean;
end;
pjs_parsing=^js_parsing;
//############################################################################//
procedure sort_node_recursive(n:pjs_node;l,r:integer);
var i,j:integer;
p:string;
t:pjs_elem;
begin
 if r<=l then exit;
 repeat
  i:=l;j:=r;
  p:=n.e[(l+r)div 2].name;
  repeat
   while (i<r)and(p>n.e[i].name) do i:=i+1;
   while (j>l)and(p<n.e[j].name) do j:=j-1;
   if i<=j then begin
    if i<j then begin
     t:=n.e[i];
     n.e[i]:=n.e[j];
     n.e[j]:=t;
    end;
    i:=i+1;
    j:=j-1;
   end;
  until i>j;
  if j>l then sort_node_recursive(n,l,j);
  if i<r then sort_node_recursive(n,i,r);
  l:=i;
 until i>=r;
end;
//############################################################################//
procedure sort_node(n:pjs_node);
begin
 if length(n.e)<>0 then sort_node_recursive(n,0,length(n.e)-1);
end;
//############################################################################//
function find_in_node(const n:pjs_node;const inp:string):pjs_elem;
var i,s,e,k:integer;
begin
 result:=nil;
 if n=nil then exit;
 if length(n.e)=0 then exit;
 if n.sorted then begin
  s:=length(n.e)-1;
  e:=0;
  i:=s div 2;
  while n.e[i].name<>inp do begin
   if s=e then exit;
   if s-e=1 then begin
    if n.e[i].name=inp then break;
    if n.e[s].name=inp then begin i:=s;break;end;
    exit;
   end;
   k:=(s-e)div 2+e;

   if inp<n.e[i].name then s:=k else e:=k;
   i:=(s-e)div 2+e;
  end;
  result:=n.e[i];
 end else begin
  for i:=0 to length(n.e)-1 do if n.e[i].name=inp then begin result:=n.e[i];exit;end;
 end;
end;
//############################################################################//
function js_find_elem(const n:pjs_node;const desc:string):pjs_elem;
var s:string;
c:char;
p,md,off:integer;
e:pjs_elem;
begin
 result:=nil;
 if n=nil then exit;
 p:=1;
 s:='';
 md:=0;
 off:=0;

 while p<=length(desc) do begin
  c:=desc[p];
  p:=p+1;
  case md of
   0:case c of
    'a'..'z','A'..'Z','0'..'9','-','_',' ':s:=s+c;
    '.':begin
     if s='' then continue;
     e:=find_in_node(n,s);
     if e=nil then exit;
     if e.typ<>JTP_NODE then exit;
     if e.node=nil then exit;
     s:=copy(desc,p,length(desc));
     result:=js_find_elem(e.node,s);
     exit;
    end;
    '[':begin
     if s='' then begin
      off:=0;
      md:=1;
     end else begin
      e:=find_in_node(n,s);
      if e=nil then exit;
      if (e.typ<>JTP_ARRAY)and(e.typ<>JTP_NODE) then exit;  //Index elements as well...
      if e.node=nil then exit;
      s:=copy(desc,p-1,length(desc));
      result:=js_find_elem(e.node,s);
      exit;
     end;
    end;
   end;
   1:case c of
    '0'..'9':off:=off*10+ord(c)-ord('0');
    ']':begin
     if off>=length(n.e) then exit;
     e:=n.e[off];
     s:=copy(desc,p,length(desc));
     if trim(s)='' then begin result:=e;exit;end;
     if e=nil then exit;
     if e.node=nil then exit;

     if s[1]='.' then begin
      if e.typ<>JTP_NODE then exit;
      result:=js_find_elem(e.node,s);
     end else if s[1]='[' then begin
      if e.typ<>JTP_ARRAY then exit;
      result:=js_find_elem(e.node,s);
     end;
     exit;
    end;
   end;
  end;
 end;

 if s<>'' then result:=find_in_node(n,s);
end;
//############################################################################//
function js_get_string(const n:pjs_node;const desc:string;const def:string='nil'):string;
var e:pjs_elem;
begin
 result:=def;
 if n=nil then exit;
 e:=js_find_elem(n,desc);
 if e=nil then exit;
 case e.typ of
  JTP_STRING:result:=e.s;
  JTP_NULL:result:='null';
  JTP_INT:result:=e.s;//stre(e.n);
  JTP_BOOL:if e.b then result:='true' else result:='false';
  JTP_NODE:result:='{node}';
  JTP_ARRAY:result:='[array]';
 end;
end;
//############################################################################//
function js_get_node(const n:pjs_node;const desc:string):pjs_node;
var e:pjs_elem;
begin
 result:=nil;
 if n=nil then exit;
 e:=js_find_elem(n,desc);
 if e=nil then exit;
 result:=e.node;
end;
//############################################################################//
function js_get_node_length(const n:pjs_node;const desc:string):integer;
var e:pjs_elem;
begin
 result:=0;
 if n=nil then exit;
 if desc='' then result:=length(n.e);
 e:=js_find_elem(n,desc);
 if e=nil then exit;
 result:=length(e.node.e);
end;
//############################################################################//
function js_get_node_name(const n:pjs_node;const desc:string):string;
var e:pjs_elem;
begin
 result:='';
 if n=nil then exit;
 e:=js_find_elem(n,desc);
 if e=nil then exit;
 result:=e.name;
end;
//############################################################################//
//############################################################################//
function parse_node(const p:pjs_parsing;const terminal:string):pjs_node;forward;
function parse_value(const p:pjs_parsing;const e:pjs_elem):boolean;forward;
//############################################################################//
function get_char(const p:pjs_parsing;out c:char):boolean;{$ifdef fpc}inline;{$endif}
begin
 result:=false;
 if p.p>length(p.ins) then exit;
 c:=p.ins[p.p];
 p.p:=p.p+1;
 result:=true;
end;
//############################################################################//
procedure add_to_str(var s:string;var o,sz:integer;const c:char);{$ifdef fpc}inline;{$endif}
begin
 if o>=sz then begin sz:=sz*2+10;setlength(s,sz);end;
 s[o+1]:=c;
 o:=o+1;
end;
//############################################################################//
function parse_string(const p:pjs_parsing):string;
var esc:boolean;
c:char;
sz,o:integer;
begin
 o:=0;
 sz:=10;
 setlength(result,sz);
 esc:=false;
 while get_char(p,c) do case esc of
  false:case c of
   '"':break;
   '\':esc:=true;
   #$0D:;                                                                     //WTF?
   #$0A:begin add_to_str(result,o,sz,'\');add_to_str(result,o,sz,'n');end;    //WTF?
   else add_to_str(result,o,sz,c);
  end;
  true:begin
   case c of  
    'b':add_to_str(result,o,sz,#$08);   //Backspace
    'f':add_to_str(result,o,sz,#$0C);   //Form feed
    'n':add_to_str(result,o,sz,#$0A);
    'r':add_to_str(result,o,sz,#$0D);
    't':add_to_str(result,o,sz,#$09);   //Tab
    //FIXME: uXXXX
    else begin
     //Includes / \ and "
     add_to_str(result,o,sz,c);   //FIXME: Skip?
    end;
   end;
   esc:=false;
  end;
 end;
 setlength(result,o);
end;
//############################################################################//
procedure parse_number(const p:pjs_parsing;out rs:string);
var c:char;
sz,o:integer;
begin
 o:=0;
 sz:=10;
 setlength(rs,sz);

 while get_char(p,c) do case c of
  '0'..'9':add_to_str(rs,o,sz,c);
  '.':add_to_str(rs,o,sz,c);
  '-':add_to_str(rs,o,sz,c);
  '+':add_to_str(rs,o,sz,c);
  'e':add_to_str(rs,o,sz,c); //1.7e+308
  else begin
   p.p:=p.p-1;
   break;
  end;
 end;
 setlength(rs,o);
end;
//############################################################################//
function parse_array(const p:pjs_parsing):pjs_node;
var sz,o:integer;
c:char;
elem:pjs_elem;
begin
 new(result);
 result.sorted:=p.do_sort;
 result.start_pos:=p.p-1;
 sz:=0;
 o:=0;

 while get_char(p,c) do case c of
  ',':;
  ']':break;
  '}':break;
  else begin
   p.p:=p.p-1;
   new(elem);
   elem.name:='';
   elem.typ:=JTP_NULL;
   elem.node:=nil;

   if parse_value(p,elem) then begin
    if o>=length(result.e) then begin
     sz:=sz*2+1;
     setlength(result.e,sz);
    end;
    result.e[o]:=elem;
    o:=o+1;
   end else dispose(elem);
  end;
 end;
 setlength(result.e,o);
 result.end_pos:=p.p-1;
end;
//############################################################################//
function parse_value(const p:pjs_parsing;const e:pjs_elem):boolean;
var c:char;
begin
 result:=true;
 while get_char(p,c) do case c of
  '"':begin
   e.typ:=JTP_STRING;
   e.s:=parse_string(p);
   break;
  end;
  '{':begin
   e.typ:=JTP_NODE;
   e.node:=parse_node(p,'');
   break;
  end;
  '[':begin
   e.typ:=JTP_ARRAY;
   e.node:=parse_array(p);
   break;
  end;
  '0'..'9','-':begin
   p.p:=p.p-1;
   e.typ:=JTP_INT;
   parse_number(p,e.s);
   break;
  end;
  'a'..'z','A'..'Z':begin
   if lowercase(copy(p.ins,p.p-1,4))='true' then begin
    e.typ:=JTP_BOOL;
    e.b:=true;
    break;
   end else if lowercase(copy(p.ins,p.p-1,5))='false' then begin
    e.typ:=JTP_BOOL;
    e.b:=false;
    break;
   end else if lowercase(copy(p.ins,p.p-1,4))='null' then begin
    e.typ:=JTP_NULL;
    break;
   end else p.fault:=true;
  end;
  ',',']','}':begin
   p.p:=p.p-1;
   result:=false;
   break;
  end;
  else continue;
 end;
end;
//############################################################################//
function parse_node(const p:pjs_parsing;const terminal:string):pjs_node;
var sz,o:integer;
c:char;
elem:pjs_elem;
done:boolean;
begin
 new(result);
 result.sorted:=p.do_sort;
 result.start_pos:=p.p-1;
 sz:=0;
 o:=0;
 elem:=nil;
 done:=false;

 while get_char(p,c) do case c of
  '"':if elem=nil then begin
   new(elem);
   elem.name:=parse_string(p);
   if (terminal<>'')and(elem.name=terminal) then begin
    dispose(elem);
    done:=true;
    break;
   end;
   elem.typ:=JTP_NULL;
   elem.node:=nil;
   if o>=length(result.e) then begin
    sz:=sz*2+1;
    setlength(result.e,sz);
   end;
   result.e[o]:=elem;
   o:=o+1;
  end else begin setlength(result.e,o);p.fault:=true;exit;end;
  ':':if elem<>nil then parse_value(p,elem) else begin setlength(result.e,o);p.fault:=true;exit;end;
  ',':if elem=nil then begin setlength(result.e,o);p.fault:=true;exit;end else elem:=nil;
  '}':begin done:=true;result.end_pos:=p.p-1;break;end;
  else continue;
 end;
 if not done then begin setlength(result.e,o);p.fault:=true;exit;end;

 setlength(result.e,o);
 if p.do_sort then sort_node(result);
end;
//############################################################################//
function js_parse_until(const ins,terminal:string;const do_sort:boolean=true):pjs_node;
var p:pjs_parsing;
c:char;
begin
 result:=nil;
 new(p);
 p.ins:=ins;
 p.p:=1;
 p.root:=nil;
 p.fault:=false;
 p.do_sort:=do_sort;

 while get_char(p,c) do if c='{' then begin
  p.root:=parse_node(p,terminal);
  if not p.fault then begin   
   result:=p.root;
   if do_sort then sort_node(result);
  end else free_js(p.root);
  dispose(p);
  exit;
 end;
end;
//############################################################################//
function js_parse(const ins:string;const do_sort:boolean=true):pjs_node;
begin
 result:=js_parse_until(ins,'',do_sort);
end;
//############################################################################//
function js_to_string(node:pjs_node;md:integer;pad,gap,nl:string):string;
var i:integer;
begin
 result:='';
 if node=nil then exit;
 case md of
  0:result:=result+pad+'{'+NL;
  1:result:=result+pad+'['+NL;
 end;
 for i:=0 to length(node.e)-1 do begin
  if md=0 then result:=result+pad+gap+'"'+node.e[i].name+'"'+gap+':'+gap;
  case node.e[i].typ of
   JTP_NULL:result:=result+'null';
   JTP_NODE:result:=result+js_to_string(node.e[i].node,0,pad+gap,gap,nl);
   JTP_STRING:result:=result+'"'+json_escape(node.e[i].s)+'"';
   JTP_ARRAY:result:=result+js_to_string(node.e[i].node,1,pad+gap,gap,nl);
   //JTP_INT:result:=result+stre(node.e[i].n);
   JTP_INT:result:=result+'"'+node.e[i].s+'"';
   JTP_BOOL:if node.e[i].b then result:=result+'true' else result:=result+'false';
  end;
  if i<>length(node.e)-1 then result:=result+',';
  if gap<>'' then result:=result+NL;
 end;
 case md of
  0:result:=result+pad+'}';
  1:result:=result+pad+']';
 end;
end;
//############################################################################//
function js_dump(node:pjs_node;md:integer=0;pad:string=''):string;begin result:=js_to_string(node,md,pad,' ',#$0A);end;
function js_stringify(node:pjs_node;md:integer=0):string;begin result:=js_to_string(node,md,'','',#$0A);end;
//############################################################################//
procedure free_js(node:pjs_node);
var i:integer;
begin
 if node=nil then exit;
 for i:=0 to length(node.e)-1 do begin
  if node.e[i].node<>nil then free_js(node.e[i].node);
  dispose(node.e[i]);
 end;
 dispose(node);
end;
//############################################################################//
function json_escape(const s:string):string;
var i:integer;
begin
 result:='';
 for i:=1 to length(s) do begin
  if s[i]='\' then begin result:=result+'\\';continue;end;
  //if s[i]='/' then begin result:=result+'\/';continue;end;     //Nope. Too ugly.
  if s[i]='"' then begin result:=result+'\"';continue;end;
  if s[i]=#$0A then begin result:=result+'\n';continue;end;
  if s[i]=#$0D then begin result:=result+'\r';continue;end;
  if s[i]=#$09 then begin result:=result+'\t';continue;end;
  if s[i]=#$08 then begin result:=result+'\b';continue;end;
  if s[i]=#$0C then begin result:=result+'\f';continue;end;
  result:=result+s[i];
 end;
end;
//############################################################################//
function js_vec(const v:vec):string;begin result:='["'+stre(v.x,-98)+'","'+stre(v.y,-98)+'","'+stre(v.z,-98)+'"]';end;
function js_quat(const v:quat):string;begin result:='["'+stre(v.x,-98)+'","'+stre(v.y,-98)+'","'+stre(v.z,-98)+'","'+stre(v.w,-98)+'"]';end;
function js_qvec(const v:qvec):string;begin result:='["'+stri(v.x)+'","'+stri(v.y)+'","'+stri(v.z)+'"]';end;
//############################################################################//
procedure js_add_line(var s:string;const sp,nl,vl:string);
begin
 if s<>'' then s:=s+','+nl+sp;
 if nl<>'' then s:=s+' ';
 s:=s+vl;
end;
//############################################################################//
procedure js_add(var s:string;const sp,nl,nm,vl:string);begin if vl<>'' then js_add_line(s,sp,nl,'"'+nm+'":'+vl);end;
//############################################################################//
procedure js_add_bool(var s:string;const sp,nl,nm:string;const vl:boolean);begin js_add(s,sp,nl,nm,'"'+stri(ord(vl))+'"');end;
procedure js_add_dbl(var s:string;const sp,nl,nm:string;const vl:double);begin js_add(s,sp,nl,nm,'"'+stre(vl,-98)+'"');end;
procedure js_add_int(var s:string;const sp,nl,nm:string;const vl:int64);begin js_add(s,sp,nl,nm,'"'+stri(vl)+'"');end;
procedure js_add_str(var s:string;const sp,nl,nm:string;const vl:string);begin js_add(s,sp,nl,nm,'"'+json_escape(vl)+'"');end;
procedure js_add_vec(var s:string;const sp,nl,nm:string;const vl:vec);begin js_add(s,sp,nl,nm,js_vec(vl));end;
procedure js_add_qvec(var s:string;const sp,nl,nm:string;const vl:qvec);begin js_add(s,sp,nl,nm,js_qvec(vl));end;
procedure js_add_quat(var s:string;const sp,nl,nm:string;const vl:quat);begin js_add(s,sp,nl,nm,js_quat(vl));end;
//############################################################################//
procedure js_add_blk(var s:string;const sp,nl,new:string);
begin
 if new='' then exit;
 if s<>'' then begin
  s:=s+','+nl+sp;
 end;
 s:=s+new;
end;
//############################################################################//
procedure js_finish(var s:string;const sp,nl:string);
begin
 if s='' then exit;
 s:='{'+nl+sp+s+nl+sp+'}';
end;
//############################################################################//
procedure js_finish_arr(var s:string;const sp,nl:string);
begin
 if s='' then exit;
 s:='['+nl+sp+s+nl+sp+']';
end;
//############################################################################//
function js_parse_vec2(const node:pjs_node):vec2;
begin
 result:=zvec2;
 if node=nil then exit;
 if length(node.e)<>2 then exit;
 result.x:=vale(node.e[0].s);
 result.y:=vale(node.e[1].s);
end;
//############################################################################//
function js_parse_vec(const node:pjs_node):vec;
begin
 result:=zvec;
 if node=nil then exit;
 if length(node.e)<>3 then exit;
 result.x:=vale(node.e[0].s);
 result.y:=vale(node.e[1].s);
 result.z:=vale(node.e[2].s);
end;
//############################################################################//
function js_parse_qvec(const node:pjs_node):qvec;
begin
 result.x:=0;result.y:=0;result.z:=0;
 if node=nil then exit;
 if length(node.e)<>3 then exit;
 result.x:=vali(node.e[0].s);
 result.y:=vali(node.e[1].s);
 result.z:=vali(node.e[2].s);
end;
//############################################################################//
function js_parse_quat(const node:pjs_node):quat;
begin
 result:=zquat;
 if node=nil then exit;
 if length(node.e)<>4 then exit;
 result.x:=vale(node.e[0].s);
 result.y:=vale(node.e[1].s);
 result.z:=vale(node.e[2].s);
 result.w:=vale(node.e[3].s);
end;
//############################################################################//
{$ifdef self_tests}
procedure json_self_test;
var j:pjs_node;
ok:boolean;
s,k:string;
begin
 ok:=false;
 s:='{"ping_count":"123"}';
 j:=js_parse(s);
 if j<>nil then begin
  k:=js_get_string(j,'ping_count');
  if k<>'nil' then if k='123' then ok:=true;
  free_js(j);
 end;
 if ok then writeln('JSON: simple ok') else writeln('JSON: simple ERROR');

 s:='{"a":{"b":["123"  , 456 ,{"c":3}],"d":"aaa"},"e":"ee"}';   
 ok:=true;
 j:=js_parse(s);
 if j<>nil then begin
  k:=js_get_string(j,'a.b[0]');if k='nil' then ok:=false else if k<>'123' then ok:=false;
  k:=js_get_string(j,'a.b[1]');if k='nil' then ok:=false else if k<>'456' then ok:=false;
  k:=js_get_string(j,'a.b[2].c');if k='nil' then ok:=false else if k<>'3' then ok:=false;
  k:=js_get_string(j,'a.d');if k='nil' then ok:=false else if k<>'aaa' then ok:=false;
  k:=js_get_string(j,'e');if k='nil' then ok:=false else if k<>'ee' then ok:=false;
  free_js(j);
 end else ok:=false;
 if ok then writeln('JSON: complex ok') else writeln('JSON: complex ERROR');

 s:='{'+#$0A;
 s:=s+' "start_delay":"0",'+#$0A;
 s:=s+' "watchdog_seconds":"0",'+#$0A;
 s:=s+' "codes":['+#$0A;
 s:=s+'  {"name":"camera_pnode4","runner":"1","restart_on_fail":"1","restart_interval":"3","dir":"/data/camera","cmd":"/data/camera/cam_srv","par":"/data/camera/camera.txt"},'+#$0A;
 s:=s+'  {"name":"pic"          ,"runner":"0","restart_on_fail":"0","restart_interval":"3","dir":"/home/artlav","item":"take_pic","par":""},'+#$0A;
 s:=s+'  {"name":"video"        ,"runner":"0","restart_on_fail":"0","restart_interval":"3","dir":"/home/artlav","item":"video_rec","par":"10"}'+#$0A;
 s:=s+' ]'+#$0A;
 s:=s+'}'+#$0A;
 ok:=true;
 j:=js_parse(s);
 if j<>nil then begin
  k:=js_get_string(j,'start_delay');if k='nil' then ok:=false else if k<>'0' then ok:=false;
  k:=js_get_string(j,'watchdog_seconds');if k='nil' then ok:=false else if k<>'0' then ok:=false;
  k:=js_get_string(j,'codes[2].name');if k='nil' then ok:=false else if k<>'video' then ok:=false;
  k:=js_get_string(j,'codes[2].dir');if k='nil' then ok:=false else if k<>'/home/artlav' then ok:=false;
  free_js(j);
 end else ok:=false;
 if ok then writeln('JSON: real 1 ok') else writeln('JSON: real 1 ERROR');

 s:='{"pars":['+#$0A;
 s:=s+'{"name":"msnd_enabled","time":1553888282,"data":"31"},'+#$0A;
 s:=s+'{"name":"sw_0_blk","time":1552886183,"data":"31"},'+#$0A;
 s:=s+'{"name":"sw_0_fast","time":1554043936,"data":"31"},'+#$0A;
 s:=s+']}'+#$0A; 
 ok:=true;
 j:=js_parse(s);
 if j<>nil then begin
  k:=js_get_string(j,'pars[0].name');if k='nil' then ok:=false else if k<>'msnd_enabled' then ok:=false;
  k:=js_get_string(j,'pars[2].time');if k='nil' then ok:=false else if k<>'1554043936' then ok:=false;
  k:=js_get_string(j,'pars[1].data');if k='nil' then ok:=false else if k<>'31' then ok:=false;
  free_js(j);
 end else ok:=false;
 if ok then writeln('JSON: real 2 ok') else writeln('JSON: real 2 ERROR');

 s:='{'+#$0A;
 s:=s+' "cameras":['+#$0A;
 s:=s+'  {"typ":"0","id":"cam_6","name":"Бабушка"},'+#$0A;
 s:=s+'  {"typ":"0","id":"cam_3","name":"Дача двор"},'+#$0A;
 s:=s+'  {"typ":"0","id":"cam_4","name":"Дача крыльцо"}'+#$0A;
 s:=s+' ]'+#$0A;
 s:=s+'}'+#$0A; 
 ok:=true;
 j:=js_parse(s);
 if j<>nil then begin
  k:=js_get_string(j,'cameras[1].id');if k='nil' then ok:=false else if k<>'cam_3' then ok:=false;
  k:=js_get_string(j,'cameras[2].name');if k='nil' then ok:=false else if k<>'Дача крыльцо' then ok:=false;
  free_js(j);
 end else ok:=false;
 if ok then writeln('JSON: real 3 ok') else writeln('JSON: real 3 ERROR');

 s:='fcty67drt6yesry5';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 1 ok') else writeln('JSON: err 1 ERROR');
 s:='{{a:b}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 2 ok') else writeln('JSON: err 2 ERROR');
 s:='{a:"b"}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 3 ok') else writeln('JSON: err 3 ERROR');
 s:='{123:"b"}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 4 ok') else writeln('JSON: err 4 ERROR');
 s:='123:"b"';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 5 ok') else writeln('JSON: err 5 ERROR');
 s:='{:"b"}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 6 ok') else writeln('JSON: err 6 ERROR');
 s:='{,"a":"b"}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 7 ok') else writeln('JSON: err 7 ERROR');
 s:='{"a":"b",,"b":"b"}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 8 ok') else writeln('JSON: err 8 ERROR');
 s:='{"a":"b" "b":"b"}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 9 ok') else writeln('JSON: err 9 ERROR');
 s:='{"name":"b","na';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err 9 ok') else writeln('JSON: err 9 ERROR');
 s:='{"a":"b"';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err a ok') else writeln('JSON: err a ERROR');
 s:='{"a":{"aa":123}';
 j:=js_parse(s);if j<>nil then begin ok:=false;free_js(j);end else ok:=true;if ok then writeln('JSON: err b ok') else writeln('JSON: err b ERROR');
end;
{$endif}
//############################################################################//
begin
end.
//############################################################################//
