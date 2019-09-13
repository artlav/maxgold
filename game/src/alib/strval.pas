//############################################################################//
//Made in 2002-2010 by Artyom Litvinovich
//AlgorLib: String <-> binary converters
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit strval;
interface
uses sysutils,asys,maths,strtool;
//############################################################################//
const
STRCV_DIST=1;
STRCV_DIST_PARSEC=2;
STRCV_BYTES=3;
STRCV_SI=4;
//############################################################################//
STRE_CNT=-99;
STRE_CNT_LONG=-98;
STRE_CNT_CUT=-97;
//############################################################################//
{$ifndef paser}type numa=array of integer;{$endif}
//############################################################################//
function rev_hex(s:string):string;

{$ifndef paser}
function stri(const par:int64):string;
function stris(const par:int64):string;
function stre(par:double;dec:integer=STRE_CNT):string;
function vali(const par:string):int64;
function valu(const par:string):qword;
function vale(const par:string):double;
function valf(const par:string):single;
{$endif}

function valhex(s:string):intptr;
function valhex_le(s:string):dword;
function valhex64_le(s:string):qword;
function valehex(s:string):double;

function valoct(s:string):dword;
function stroct(bit:dword):string;

function strhex(const bit:dword):string;
function strhex_le(const bit:dword):string;
function strhex1(const bit:dword):string;
function strhex2(const bit:dword):string;
function strhex3(const bit:dword):string;
function strhex4(const bit:dword):string;
function strhex4_le(const bit:dword):string;
function strhex6(const bit:dword):string;
function strhex6_le(const bit:dword):string;
function strhex16(const bit:qword):string;
function strhex16_le(const bit:qword):string;

function valbin(ins:string):dword;
function valbinrev(ins:string):dword;
function strbin1(bit:byte):string;
function strbin2(bit:byte):string;
function strbin2_rev(bit:byte):string;
function strbin4(bit:word):string;
function strbin4_rev(bit:word):string;

function strboolx(b:boolean;t,f:string):string;

function strivec2(v:ivec2):string;
function strvec2(v:vec2;dec:integer=STRE_CNT):string;
function strvec(v:vec;dec:integer=STRE_CNT):string;
function strquat(v:quat;dec:integer=STRE_CNT):string;

function vala(ins:string):dword;

function valivec2(st:string):ivec2;
function valvec2(st:string):vec2;
function valvec (st:string):vec;
function valqvec(st:string):qvec;
function valquat(st:string):quat;
function valvec5(st:string):vec5;

{$ifndef paser}
function valep(par:pchar):double;
procedure valnuma(ins:string;out res:numa);
{$endif}

function strlat(par:longint):string;
function strcv(par:double;tp:integer=STRCV_DIST;frc:integer=3):string;

function strdat6cs(i:integer):string;
function strdat6cf(i:integer):string;

function bytefy(s:string):string;
function unbytefy(s:string):string;

function hex2bin(s:string;buf:pointer;bs:integer):integer;
function bits2bin(s:string;buf:pointer;bs:integer):integer;
function hex2bin_le(s:string;buf:pointer;bs:integer):integer;
function hex2bin_string(s:string):string;
function bin2hex(buf:pointer;bs:integer;le:boolean=false):string;
function bin2bits(buf:pointer;bs:integer;le:boolean=false):string;
function bin2hex_c(buf:pointer;bs:integer;le:boolean=false):string;
function str2hex(s:string;zero:boolean):string;

procedure print_hex(addr:pointer;off,len:dword);
//############################################################################//
implementation
//############################################################################//
function rev_hex(s:string):string;
var i,n:integer;
begin
 setlength(result,length(s));
 n:=length(result) div 2;
 for i:=0 to n-1 do begin
  result[1+i*2+0]:=s[1+(n-i-1)*2+0];
  result[1+i*2+1]:=s[1+(n-i-1)*2+1];
 end;
end;
//############################################################################//
function strsinsym(s:string;c:char):string;
var i:integer;
b:boolean;
begin
 b:=false;
 result:='';
 for i:=1 to length(s) do if s[i]=c then begin
  if not b then begin
   result:=result+c;
   b:=true;
  end;
 end else begin
  b:=false;
  result:=result+s[i];
 end;
end;
//############################################################################//
{$ifndef paser}
function stri(const par:int64):string;begin str(par,result);end;
function stris(const par:int64):string;begin str(par,result);if par>=0 then result:='+'+result;end;
function stre(par:double;dec:integer=STRE_CNT):string;
begin
 {if abs(par)>maxint then result:='INF' else} begin     //FIXME: WTF was that for? Something on Windows/delphi/paser?
  if dec=STRE_CNT then dec:=cntfrac(par,3);
  if dec=STRE_CNT_LONG then dec:=cntfrac(par,20);
  if dec=STRE_CNT_CUT then begin
   dec:=cntfrac(par,3);
   if dec>0 then dec:=3;
  end;
  str(par:1:dec,result);
 end;
end;
function vali(const par:string):int64; var n:integer;begin result:=0;val(trim(par),int64(result),n);if n=0 then exit;end;
function valu(const par:string):qword; var n:integer;begin result:=0;val(trim(par),qword(result),n);if n=0 then exit;end;
function vale(const par:string):double;var n:integer;begin val(trim(par),result,n);if n=0 then exit;end;
function valf(const par:string):single;var n:integer;begin val(trim(par),result,n);if n=0 then exit;end;
{$endif}
//############################################################################//
function valhex(s:string):intptr;
var i:integer;
lg,n:byte;
lt:char;
begin
 result:=0;
 lg:=length(s);
 for i:=lg-1 downto 0 do begin
  lt:=s[lg-i];
  n:=0;
  if(lt>='0')and(lt<='9')then n:=ord(lt)-ord('0');
  if(lt>='A')and(lt<='F')then n:=ord(lt)-ord('A')+10;
  if(lt>='a')and(lt<='f')then n:=ord(lt)-ord('a')+10;
  result:=(result shl 4)or n;
 end;
end;
//############################################################################//
function valhex_le(s:string):dword;
var i:integer;
lg,n:byte;
lt:char;
d:dword;
begin
 d:=0;
 lg:=length(s);
 for i:=lg-1 downto 0 do begin
  lt:=s[lg-i];
  n:=0;
  if(lt>='0')and(lt<='9')then n:=ord(lt)-ord('0');
  if(lt>='A')and(lt<='F')then n:=ord(lt)-ord('A')+10;
  if(lt>='a')and(lt<='f')then n:=ord(lt)-ord('a')+10;
  d:=(d shl 4)or n;
 end;
 pbytea(@result)[0]:=pbytea(@d)[3];
 pbytea(@result)[1]:=pbytea(@d)[2];
 pbytea(@result)[2]:=pbytea(@d)[1];
 pbytea(@result)[3]:=pbytea(@d)[0];
end;
//############################################################################//
function valhex64_le(s:string):qword;
var i:integer;
lg,n:byte;
lt:char;
d:qword;
begin
 d:=0;
 lg:=length(s);
 for i:=lg-1 downto 0 do begin
  lt:=s[lg-i];
  n:=0;
  if(lt>='0')and(lt<='9')then n:=ord(lt)-ord('0');
  if(lt>='A')and(lt<='F')then n:=ord(lt)-ord('A')+10;
  if(lt>='a')and(lt<='f')then n:=ord(lt)-ord('a')+10;
  d:=(d shl 4)or n;
 end;
 pbytea(@result)[0]:=pbytea(@d)[7];
 pbytea(@result)[1]:=pbytea(@d)[6];
 pbytea(@result)[2]:=pbytea(@d)[5];
 pbytea(@result)[3]:=pbytea(@d)[4];
 pbytea(@result)[4]:=pbytea(@d)[3];
 pbytea(@result)[5]:=pbytea(@d)[2];
 pbytea(@result)[6]:=pbytea(@d)[1];
 pbytea(@result)[7]:=pbytea(@d)[0];
end;
//############################################################################//
function valehex(s:string):double;
var i:integer;
lg,n:byte;
lt:char;
begin
 result:=0;
 lg:=length(s);
 for i:=lg-1 downto 0 do begin
  lt:=s[lg-i];
  n:=0;
  if(lt>='0')and(lt<='9')then n:=ord(lt)-ord('0');
  if(lt>='A')and(lt<='F')then n:=ord(lt)-ord('A')+10;
  if(lt>='a')and(lt<='f')then n:=ord(lt)-ord('a')+10;
  result:=(result*16)+n;
 end;
end;
//############################################################################//
function valoct(s:string):dword;
var lg,i,n:byte;
lt:char;
begin
 result:=0;
 lg:=length(s);
 if lg=0 then exit;
 for i:=lg-1 downto 0 do begin
  lt:=s[lg-i];
  n:=0;
  if(lt>='0')and(lt<='7')then n:=ord(lt)-ord('0');
  result:=(result shl 3)or n;
 end;
end;
//############################################################################//
function stroct(bit:dword):string;
var i:integer;
r:dword;
begin
 result:='';
 for i:=0 to 11 do begin
  r:=bit shr i;
  r:=r shr i;
  r:=r shr i;
  result:=stri(r and 7)+result;
 end;
 while true do begin
  if result='' then exit;
  if result[1]='0' then result:=copy(result,2,length(result)) else break;
 end;
end;
//############################################################################//
function strhex16(const bit:qword):string;
begin
 result:=inttohex(bit shr 32,8)+inttohex(bit and $FFFFFFFF,8);
end;
//############################################################################//
function strhex16_le(const bit:qword):string;
var s:string;
begin
 s:=inttohex(bit shr 32,8)+inttohex(bit and $FFFFFFFF,8);
 result:=s[15]+s[16]+s[13]+s[14]+s[11]+s[12]+s[9]+s[10]+s[7]+s[8]+s[5]+s[6]+s[3]+s[4]+s[1]+s[2];
end;
//############################################################################//
function strhex1(const bit:dword):string;begin result:=inttohex(bit,1);end;
function strhex2(const bit:dword):string;begin result:=inttohex(bit,2);end;
function strhex3(const bit:dword):string;begin result:=inttohex(bit,3);end;
function strhex4(const bit:dword):string;begin result:=inttohex(bit,4);end;
function strhex6(const bit:dword):string;begin result:=inttohex(bit,6);end;
function strhex (const bit:dword):string;begin result:=inttohex(bit,8);end;
//############################################################################//
function strhex4_le(const bit:dword):string;
var s:string;
begin
 s:=inttohex(bit,4);
 result:=s[3]+s[4]+s[1]+s[2];
end;
//############################################################################//
function strhex6_le(const bit:dword):string;
var s:string;
begin
 s:=inttohex(bit,6);
 result:=s[5]+s[6]+s[3]+s[4]+s[1]+s[2];
end;
//############################################################################//
function strhex_le(const bit:dword):string;
var s:string;
begin
 s:=inttohex(bit,8);
 result:=s[7]+s[8]+s[5]+s[6]+s[3]+s[4]+s[1]+s[2];
end;
//############################################################################//
function valbin(ins:string):dword;
var lg,i:byte;
pa:dword;
begin
 result:=0;
 if length(ins)=0 then exit;
 pa:=1;
 ins:=lowercase(ins);
 lg:=length(ins);
 for i:=0 to lg-1 do begin
  if ins[lg-i]='1' then result:=result or pa;
  pa:=pa shl 1;
 end;
end;
//############################################################################//
function valbinrev(ins:string):dword;
var i:integer;
pa:dword;
begin
 pa:=1;
 result:=0;
 ins:=lowercase(ins);
 for i:=0 to length(ins)-1 do begin
  if ins[i+1]='1' then result:=result or pa;
  pa:=pa shl 1;
 end;
end;
//############################################################################//
function strbin1(bit:byte):string;
var i:integer;
r:byte;
re:string;
begin
 re:='';
 for i:=3 downto 0 do begin
  r:=bit shl (7-i);
  re:=re+stri(r shr 7);
 end;
 result:=re;
end;
//############################################################################//
function strbin2(bit:byte):string;
var i:integer;
r:byte;
re:string;
begin
 re:='';
 for i:=7 downto 0 do begin
  r:=bit shl (7-i);
  re:=re+stri(r shr 7);
 end;
 result:=re;
end;
//############################################################################//
function strbin2_rev(bit:byte):string;
var i:integer;
r:byte;
re:string;
begin
 re:='';
 for i:=7 downto 0 do begin
  r:=bit shl (7-i);
  re:=stri(r shr 7)+re;
 end;
 result:=re;
end;
//############################################################################//
function strbin4(bit:word):string;
var i:integer;
r:word;
re:string;
begin
 re:='';
 for i:=15 downto 0 do begin
  r:=bit shl (15-i);
  re:=re+stri(r shr 15);
 end;
 result:=re;
end;
//############################################################################//
function strbin4_rev(bit:word):string;
var i:integer;
r:word;
re:string;
begin
 re:='';
 for i:=15 downto 0 do begin
  r:=bit shl (15-i);
  re:=stri(r shr 15)+re;
 end;
 result:=re;
end;
//############################################################################//
function strboolx(b:boolean;t,f:string):string;
begin
 if b then result:=t else result:=f;
end;
//############################################################################//
function strivec2(v:ivec2):string;
begin
 result:=stri(v.x)+','+stri(v.y);
end;
//############################################################################//
function strvec2(v:vec2;dec:integer=STRE_CNT):string;
begin
 result:=stre(v.x,dec)+','+stre(v.y,dec);
end;
//############################################################################//
function strvec(v:vec;dec:integer=STRE_CNT):string;
begin
 result:=stre(v.x,dec)+','+stre(v.y,dec)+','+stre(v.z,dec);
end;
//############################################################################//
function strquat(v:quat;dec:integer=STRE_CNT):string;
begin
 result:=stre(v.x,dec)+','+stre(v.y,dec)+','+stre(v.z,dec)+','+stre(v.w,dec);
end;
//############################################################################//
function vala(ins:string):dword;
begin
 result:=vali(ins);
 if copy(ins,1,1)='$' then result:=valhex(copy(ins,2,length(ins)-1));
 if copy(ins,length(ins),1)='h' then result:=valhex(copy(ins,1,length(ins)-1));
 if copy(ins,length(ins),1)='b' then result:=valbin(copy(ins,1,length(ins)-1));
end;
//############################################################################//
function valivec2(st:string):ivec2;
var i:integer;
str1,str2:string;
begin
 st:=strsinsym(st,' ');
 i:=getfsymp(st,',');
 if i=0 then i:=getfsymp(st,' ');
 str1:=copy(st,1,i-1);
 str2:=copy(st,i+1,length(st)-i);
 result.x:=vali(trim(str1));
 result.y:=vali(trim(str2));
end;
//############################################################################//
function valvec2(st:string):vec2;
var i:integer;
str1,str2:string;
begin
 st:=strsinsym(st,' ');
 i:=getfsymp(st,',');
 if i=0 then i:=getfsymp(st,' ');
 str1:=copy(st,1,i-1);
 str2:=copy(st,i+1,length(st)-i);
 result.x:=vale(trim(str1));
 result.y:=vale(trim(str2));
end;
//############################################################################//
function valvec(st:string):vec;
var i,j:integer;
str1,str2,str3:string;
begin
 st:=strsinsym(st,' ');
 i:=getfsymp(st,',');
 j:=getnsymp(st,',',2);
 if i=0 then i:=getfsymp(st,' ');
 if j=0 then j:=getnsymp(st,' ',2);
 str1:=copy(st,1,i-1);
 str2:=copy(st,i+1,j-i-1);
 str3:=copy(st,j+1,length(st)-j);
 result.x:=vale(trim(str1));
 result.y:=vale(trim(str2));
 result.z:=vale(trim(str3));
end;
//############################################################################//
function undot(s:string):string;
var i:integer;
begin
 result:=s;
 i:=getfsymp(s,'.');
 if i<>0 then result:=copy(s,1,i-1);
end;
//############################################################################//
function valqvec(st:string):qvec;
var i,j:integer;
str1,str2,str3:string;
begin
 st:=strsinsym(st,' ');
 i:=getfsymp(st,',');
 j:=getnsymp(st,',',2);
 if i=0 then i:=getfsymp(st,' ');
 if j=0 then j:=getnsymp(st,' ',2);
 str1:=undot(copy(st,1,i-1));
 str2:=undot(copy(st,i+1,j-i-1));
 str3:=undot(copy(st,j+1,length(st)-j));
 result.x:=vali(trim(str1));
 result.y:=vali(trim(str2));
 result.z:=vali(trim(str3));
end;
//############################################################################//
function valquat(st:string):quat;
var i,j,k:integer;
str1,str2,str3,str4:string;
begin
 st:=strsinsym(st,' ');
 i:=getfsymp(st,',');
 j:=getnsymp(st,',',2);
 k:=getnsymp(st,',',3);
 if i=0 then i:=getfsymp(st,' ');
 if j=0 then j:=getnsymp(st,' ',2);
 if k=0 then k:=getnsymp(st,' ',3);
 str1:=copy(st,1,i-1);
 str2:=copy(st,i+1,j-i-1);
 str3:=copy(st,j+1,k-j-1);
 str4:=copy(st,k+1,length(st)-j);
 result.x:=vale(trim(str1));
 result.y:=vale(trim(str2));
 result.z:=vale(trim(str3));
 result.w:=vale(trim(str4));
end;
//############################################################################//
function valvec5(st:string):vec5;
var i,j,k,l:integer;
str1,str2,str3,str4,str5:string;
begin
 st:=strsinsym(st,' ');
 result.w:=0; result.t:=0;
 i:=getfsymp(st,',');
 j:=getnsymp(st,',',2);
 k:=getnsymp(st,',',3);
 l:=getnsymp(st,',',4);
 if i=0 then i:=getfsymp(st,' ');
 if j=0 then j:=getnsymp(st,' ',2);
 if k=0 then k:=getnsymp(st,' ',3);
 if l=0 then l:=getnsymp(st,' ',4);
 if j=0 then j:=length(st)+1;
 if k=0 then k:=length(st)+1;
 if l=0 then l:=length(st)+1;
 str1:=copy(st,1,i-1);
 str2:=copy(st,i+1,j-i-1);
 str3:=copy(st,j+1,k-j-1);
 str4:=copy(st,k+1,l-k-1);
 str5:=copy(st,l+1,length(st)-j);
 result.x:=vale(trim(str1));
 result.y:=vale(trim(str2));
 result.z:=vale(trim(str3));
 result.w:=vale(trim(str4));
 result.t:=vale(trim(str5));
end;
//############################################################################//
{$ifndef paser}
function valep(par:pchar):double;
var p:integer;
s:string;
begin
 s:=StrPas(par);
 val(trim(s),result,p);
 if p=0 then exit;
end;
//############################################################################//
procedure valnuma(ins:string;out res:numa);
var i,c,r:integer;
s:string;
label 1;
begin
 c:=0;s:='';
 setlength(res,0);r:=0;
 for i:=1 to length(ins) do begin
  1:
  case c of
   0:case ins[i] of
    ',',' ',#9:continue;
    else begin c:=1; goto 1;end;
   end;
   1:case ins[i] of
    ',',' ',#9:begin
     setlength(res,r+1);
     res[r]:=vali(s);
     r:=r+1;
     s:='';
     c:=0;
     continue;
    end;
    else begin s:=s+ins[i]; continue; end;
   end;
  end;
 end;
 if length(s)<>0 then begin
  setlength(res,r+1);
  res[r]:=vali(s);
 end;
end;
{$endif}
//############################################################################//
//############################################################################//
{$R+}
function strlat(par:longint):string;
var st:string;
begin
 st:='';
 while par>=50 do begin
  par:=par-50;
  st:=st+'L';
 end;
 while par>=10 do begin
  if par>40 then begin
   par:=par-40;
   st:=st+'XL';
  end else begin
   par:=par-10;
   st:=st+'X';
  end;
 end;
 while par>=5 do begin
  if par=9 then begin
   par:=0;
   st:=st+'IX';
  end else begin
   par:=par-5;
   st:=st+'V';
  end;
 end;
 while par>=1 do begin
  if par=4 then begin
   par:=0;
   st:=st+'IV';
  end else begin
   par:=par-1;
   st:=st+'I';
  end;
 end;
 result:=st;
end;
//############################################################################//
function strcv(par:double;tp:integer=1;frc:integer=3):string;
var a:double;
begin
 a:=abs(par);
 case tp of
  //Astro
  STRCV_DIST:begin
   if(a<1000)then begin      //1km
    result:=stre(par,frc);
   end else if(a<1e6)then begin    //1000km
    par:=par/1000;
    result:=stre(par,frc)+'K';
   end else if(a<1e9)then begin    //1 million km
    par:=par/1e6;
    result:=stre(par,frc)+'M';
   end else if(a<10e3*au)then begin //10000AU
    par:=par/au;
    result:=stre(par,frc)+'AU';
   end else if(a<1000*le)then begin          //1000ly
    par:=par/le;
    result:=stre(par,frc)+'ly';
   end else if(a<1e6*le)then begin             //1Mly
    par:=par/(1000*le);
    result:=stre(par,frc)+'Kly';
   end else if(a<1e9*le)then begin             //1Gly
    par:=par/(1e6*le);
    result:=stre(par,frc)+'Mly';
   end else begin
    par:=par/(1e9*le);
    result:=stre(par,frc)+'Gly';
   end;
  end;
  //Astro in parsec
  STRCV_DIST_PARSEC:begin
   if(a<1000)then begin      //1km
    result:=stre(par,frc);
   end else if(a<1e6)then begin    //1000km
    par:=par/1000;
    result:=stre(par,frc)+'K';
   end else if(a<1e9)then begin    //1 million km
    par:=par/1e6;
    result:=stre(par,frc)+'M';
   end else if(a<10e3*au)then begin //10000AU
    par:=par/au;
    result:=stre(par,frc)+'AU';
   end else if(a<1000*parsec)then begin          //1000pc
    par:=par/parsec;
    result:=stre(par,frc)+'pc';
   end else if(a<1e6*parsec)then begin             //1Mpc
    par:=par/(1000*parsec);
    result:=stre(par,frc)+'kpc';
   end else if(a<1e9*parsec)then begin             //1Gpc
    par:=par/(1e6*parsec);
    result:=stre(par,frc)+'Mpc';
   end else begin
    par:=par/(1e9*parsec);
    result:=stre(par,frc)+'Gpc';
   end;
  end;
  //Bytes
  STRCV_BYTES:begin
   if(a<1024)then begin
    result:=stre(par,frc)+'';
   end else if(a<1024*1024)then begin
    par:=par/1024;
    result:=stre(par,frc)+'K';
   end else if(a<1024*1024*1024)then begin
    par:=par/(1024*1024);
    result:=stre(par,frc)+'M';
   end else if(a<1099511627776)then begin
    par:=par/(1024*1024*1024);
    result:=stre(par,frc)+'G';
   end else begin
    par:=par/(1099511627776);
    result:=stre(par,frc)+'T';
   end;
  end;
  //Si
  STRCV_SI:begin
   if(a=0)then begin
    result:=stre(par,frc);
   end else if(a<0.000000001)then begin
    result:=stre(par*1e12,frc)+'p';
   end else if(a<0.000001)then begin
    result:=stre(par*1e9,frc)+'n';
   end else if(a<0.001)then begin
    result:=stre(par*1e6,frc)+'u';
   end else if(a<1)then begin
    result:=stre(par*1e3,frc)+'m';
   end else if(a<1000)then begin      //1km
    result:=stre(par,frc);
   end else if(a<1e6)then begin    //1000km
    par:=par/1000;
    result:=stre(par,frc)+'K';
   end else if(a<1e9)then begin
    par:=par/1e6;
    result:=stre(par,frc)+'M';
   end else if(a<1e12)then begin
    par:=par/1e9;
    result:=stre(par,frc)+'G';
   end else if(a<1e15)then begin
    par:=par/1e12;
    result:=stre(par,frc)+'T';
   end else begin
    par:=par/1e15;
    result:=stre(par,frc)+'P';
   end;
  end;
  else result:=stre(par);
 end;
end;
//############################################################################//
function strdat6cs(i:integer):string;
var y,m,d:integer;
ys,ms,ds:string;
begin
 y:=i div 10000;
 m:=i div 100-y*100;
 d:=i mod 100;
// writeln('('+stri(d)+' '+stri(m)+' '+stri(y)+')');
 ys:=stri(y+2000);
 ds:=stri(d);
 case m of
  01:ms:='jan';
  02:ms:='feb';
  03:ms:='mar';
  04:ms:='apr';
  05:ms:='may';
  06:ms:='jun';
  07:ms:='jul';
  08:ms:='aug';
  09:ms:='sep';
  10:ms:='oct';
  11:ms:='nov';
  12:ms:='dec';
  else ms:=stri(m);
 end;

 result:=ds+' '+ms+' '+ys;
end;
//############################################################################//
function strdat6cf(i:integer):string;
var y,m,d:integer;
ys,ms,ds:string;
begin
 y:=i div 10000;
 m:=i div 100-y*100;
 d:=i mod 100;
// writeln('('+stri(d)+' '+stri(m)+' '+stri(y)+')');
 ys:=stri(y+2000);
 ds:=stri(d);
 case m of
  01:ms:='january';
  02:ms:='feburary';
  03:ms:='marth';
  04:ms:='april';
  05:ms:='may';
  06:ms:='june';
  07:ms:='july';
  08:ms:='august';
  09:ms:='september';
  10:ms:='october';
  11:ms:='november';
  12:ms:='december';
  else ms:=stri(m);
 end;

 result:=ds+' '+ms+' '+ys;
end;
//############################################################################//
function bytefy(s:string):string;
var i:integer;
st:string;
begin
 result:=s;
 if s='' then exit;
 setlength(result,length(s)*2);
 for i:=0 to length(s)-1 do begin
  st:=strhex2(byte(s[1+i]));
  result[1+i*2+0]:=st[1];
  result[1+i*2+1]:=st[2];
 end;
end;
//############################################################################//
function unbytefy(s:string):string;
var i:integer;
st:string;
b:byte;
begin
 result:=s;
 if s='' then exit;
 setlength(result,length(s) div 2);
 setlength(st,2);
 for i:=0 to length(s) div 2-1 do begin
  st[1]:=s[1+i*2+0];
  st[2]:=s[1+i*2+1];
  b:=valhex(st);
  result[1+i]:=char(b);
 end;
end;
//############################################################################//
function hex2bin(s:string;buf:pointer;bs:integer):integer;
var i:integer;
begin
 result:=min2i(length(s) div 2,bs);
 for i:=0 to result-1 do pbytea(buf)[i]:=valhex(copy(s,1+i*2,2));
end;
//############################################################################//
function bits2bin(s:string;buf:pointer;bs:integer):integer;
var i,n,k,l:integer;
begin
 l:=length(s);
 n:=l div 8;
 if l mod 8<>0 then n:=n+1;
 n:=min2i(n,bs);
 result:=n;
 for i:=0 to n-1 do begin
  if i=n-1 then begin
   if l-7-8*i<1 then begin
    k:=8-(1-(l-7-8*i));
    pbytea(buf)[n-1-i]:=valbin(copy(s,1,k));
   end else pbytea(buf)[n-1-i]:=valbin(copy(s,l-7-8*i,8));
  end else pbytea(buf)[n-1-i]:=valbin(copy(s,l-7-8*i,8));
 end;
end;
//############################################################################//
function hex2bin_le(s:string;buf:pointer;bs:integer):integer;
var i:integer;
begin
 result:=min2i(length(s) div 2,bs);
 for i:=0 to result-1 do pbytea(buf)[result-1-i]:=valhex(copy(s,1+i*2,2));
end;
//############################################################################//
function hex2bin_string(s:string):string;
begin
 if length(s)<2 then begin result:='';exit;end;
 setlength(result,length(s) div 2);
 hex2bin(s,@result[1],length(result));
end;
//############################################################################//
function bin2hex(buf:pointer;bs:integer;le:boolean=false):string;
var i:integer;
begin
 result:='';
 if le then for i:=0 to bs-1 do result:=result+strhex2(pbytea(buf)[bs-1-i])
       else for i:=0 to bs-1 do result:=result+strhex2(pbytea(buf)[i]);
end;
//############################################################################//
function bin2bits(buf:pointer;bs:integer;le:boolean=false):string;
var i:integer;
begin
 result:='';
 if le then for i:=0 to bs-1 do result:=result+strbin2(pbytea(buf)[bs-1-i])
       else for i:=0 to bs-1 do result:=result+strbin2(pbytea(buf)[i]);
end;
//############################################################################//
function bin2hex_c(buf:pointer;bs:integer;le:boolean=false):string;
var i:integer;
begin
 result:='';
 for i:=0 to bs-1 do begin
  if le then result:=result+'0x'+strhex2(pbytea(buf)[bs-1-i])
        else result:=result+'0x'+strhex2(pbytea(buf)[i]);
  if i<>bs-1 then result:=result+',';
  if i mod 16=15 then result:=result+#$0a;
 end;
end;
//############################################################################//
function str2hex(s:string;zero:boolean):string;
var i:integer;
begin
 result:='';
 for i:=0 to length(s)-1 do result:=result+strhex2(pbytea(@s[1])[i]);
 if zero then result:=result+'00';
end;
//############################################################################//
procedure print_hex(addr:pointer;off,len:dword);
var i:integer;
base:pbytea;
begin
 base:=pointer(addr);

 for i:=0 to len-1 do begin
  if (i mod 16)=0 then write(strhex(off+dword(i)),'   ');
  write(strhex2(base[i]),' ');
  if (i mod 16)=15 then writeln;
 end;
 if (len mod 16)<>0 then writeln;
end;
//############################################################################//
begin
end.
//############################################################################//

