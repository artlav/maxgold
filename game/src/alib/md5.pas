//############################################################################//
//Made in 2003-2019 by Artyom Litvinovich
//AlgorLib: MD5 hasher
//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit md5;
interface
uses sysutils,asys;
//############################################################################//
const MD5_HASH_SIZE=16;
//############################################################################//
type md5_digest=array[0..MD5_HASH_SIZE-1] of byte;
//############################################################################//
function md5_buf(buf:pointer;bs:integer):md5_digest;
function md5_compare(a,b:md5_digest):boolean;

function md5_str(const msg:string):md5_digest;
function str_md5_hash(m:md5_digest):string;
function dstr_md5_hash(m:md5_digest):string;

{$ifdef self_tests}procedure md5_test;{$endif}
//############################################################################//
implementation
//############################################################################//
type
context=array[0..3]of dword;
xarray=array[0..15]of dword;
fn=function(const x,y,z:dword):dword;
//############################################################################//
function mdf(const x,y,z:dword):dword; begin result:=(x and y)or((not x)and z); end;
function mdg(const x,y,z:dword):dword; begin result:=(x and z)or y and(not z); end;
function mdh(const x,y,z:dword):dword; begin result:=x xor y xor z; end;
function mdj(const x,y,z:dword):dword; begin result:=y xor(x or(not z)); end;
function rol(const x:dword;const s:byte):dword; begin result:=(x shl s)or(x shr (32-s)); end;
//############################################################################//
const
initial:md5_digest=($01,$23,$45,$67,$89,$ab,$cd,$ef,$fe,$dc,$ba,$98,$76,$54,$32,$10);
{$ifdef paser}
fntbl:array[0..3]of fn=(@mdf,@mdg,@mdh,@mdj);
{$else}
fntbl:array[0..3]of fn=(mdf,mdg,mdh,mdj);
{$endif}
order:array[0..3]of byte=(0,3,2,1);
schedule1:array[0..63]of byte=(
 0,1, 2,3, 4,5,6, 7, 8,9,10,11,12,13,14,15,1,6,11,0, 5,10,15,4,9,14,3, 8,13, 2,7,12,
 5,8,11,14,1,4,7,10,13,0, 3, 6, 9,12,15, 2,0,7,14,5,12, 3,10,1,8,15,6,13, 4,11,2, 9
);
schedule2:array[0..63]of byte=(
 7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,5, 9,14,20,5, 9,14,20,5, 9,14,20,5, 9,14,20,
 4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21
);
t:array[0..63]of dword=(
 $d76aa478,$e8c7b756,$242070db,$c1bdceee,$f57c0faf,$4787c62a,$a8304613,$fd469501,
 $698098d8,$8b44f7af,$ffff5bb1,$895cd7be,$6b901122,$fd987193,$a679438e,$49b40821,
 $f61e2562,$c040b340,$265e5a51,$e9b6c7aa,$d62f105d,$02441453,$d8a1e681,$e7d3fbc8,
 $21e1cde6,$c33707d6,$f4d50d87,$455a14ed,$a9e3e905,$fcefa3f8,$676f02d9,$8d2a4c8a,
 $fffa3942,$8771f681,$6d9d6122,$fde5380c,$a4beea44,$4bdecfa9,$f6bb4b60,$bebfbc70,
 $289b7ec6,$eaa127fa,$d4ef3085,$04881d05,$d9d4d039,$e6db99e5,$1fa27cf8,$c4ac5665,
 $f4292244,$432aff97,$ab9423a7,$fc93a039,$655b59c3,$8f0ccc92,$ffeff47d,$85845dd1,
 $6fa87e4f,$fe2ce6e0,$a3014314,$4e0811a1,$f7537e82,$bd3af235,$2ad7d2bb,$eb86d391
);
//############################################################################//
procedure transform(var ctxt:context;const x:xarray);
var ctct:context;
i,n:word;
ctn1,a,f,c,xw:dword;
begin
 {$ifdef endian_big}for i:=0 to 3 do ctxt[i]:=te_dw(ctxt[i]);{$endif}
 ctct:=ctxt;
 for i:=0 to 63 do begin
  n:=order[i and 3];
  ctn1:=ctxt[(n+1)and 3];
  f:=fntbl[i shr 4](ctn1,ctxt[(n+2)and 3],ctxt[(n-1)and 3]);
  xw:=x[schedule1[i]];
  {$ifdef endian_big}xw:=te_dw(xw);{$endif}
  c:=ctxt[n]+f+xw+t[i];
  a:=rol(c,schedule2[i]);
  ctxt[n]:=ctn1+a;
 end;
 for i:=0 to 3 do ctxt[i]:=ctxt[i]+ctct[i];
 {$ifdef endian_big}for i:=0 to 3 do ctxt[i]:=te_dw(ctxt[i]);{$endif}
end;
//############################################################################//
function md5_buf(buf:pointer;bs:integer):md5_digest;
var x:xarray;
xx:pbytea;
i:integer;
ctxt:context;
begin
 xx:=@x[0];
 move(initial,ctxt,16);

 i:=bs;
 while i>=64 do begin
  move(buf^,x,64);
  transform(ctxt,x);
  buf:=pointer(intptr(buf)+64);
  i:=i-64;
 end;
 move(buf^,x,i);
 xx[i]:=$80;
 if i<56 then fillchar(xx[i+1],55-i,0) else begin
  fillchar(xx[i+1],63-i,0);
  transform(ctxt,x);
  fillchar(x,56,0)
 end;
 x[14]:=dword(bs) shl 3;
 {$ifdef endian_big}x[14]:=te_dw(x[14]);{$endif}
 x[15]:=0;
 transform(ctxt,x);
 move(ctxt,result,16);
end;
//############################################################################//
function md5_compare(a,b:md5_digest):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to MD5_HASH_SIZE-1 do if a[i]<>b[i] then exit;
 result:=true;
end;
//############################################################################//
//FIXME: MD5 fails on IOS
//Reasons unknown at this time
{$ifndef ios}
function md5_str(const msg:string):md5_digest;begin result:=md5_buf(@msg[1],length(msg));end;
{$else}
function md5_str(const msg:string):md5_digest;
var i:integer;
begin
 for i:=0 to 15 do result[i]:=0;
end;
{$endif}
//############################################################################//
function strhex2(bit:dword):string;begin result:=inttohex(bit,2);end;
//############################################################################//
function str_md5_hash(m:md5_digest):string;
var i:integer;
begin
 result:='';
 for i:=0 to MD5_HASH_SIZE-1 do result:=result+strhex2(m[i]);
end;
//############################################################################//
function dstr_md5_hash(m:md5_digest):string;
var i:integer;
begin
 result:='';
 for i:=0 to MD5_HASH_SIZE-1 do result:=result+char(m[i]);
end;
//############################################################################//
{$ifdef self_tests}
//############################################################################//
function strhex(bit:dword):string;begin result:=inttohex(bit,8);end;
procedure gen_md5_t_const;
var i:integer;
nt:array[0..63]of dword;
begin
 for i:=0 to 63 do nt[i]:=abs(trunc(sin(i+1)*4294967296));
 for i:=0 to 63 do begin write('$',lowercase(strhex(nt[i])),',');if (i mod 8)=7 then writeln;end;
end;
//############################################################################//
procedure md5_test;
begin
 if str_md5_hash(md5_str('125466'))='2660B824474616622243D34099DB8282' then writeln('MD5: ok 1') else writeln('MD5: fail 1');
 if str_md5_hash(md5_str('The quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dog'))='D27C6D8BCAA695E377D32387E115763C' then writeln('MD5: ok 2') else writeln('MD5: fail 2');
end;
{$endif}
//############################################################################//
begin
end.
//############################################################################//
