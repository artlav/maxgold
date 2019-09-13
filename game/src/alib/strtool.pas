//############################################################################// 
//Made in 2002-2016 by Artyom Litvinovich
//AlgorLib: String tools
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit strtool;
interface
uses asys;
//############################################################################//  
procedure mkpc(var c:pchar;s:integer);
procedure stpc(c:pchar;s:string);
procedure mspc(var c:pchar;n:integer;s:string);
{$ifndef paser}
function ppcn2astr(s:ppchar;n:integer):astr;
function ppcz2astr(s:ppchar):astr;
function pca2astr(s:pchar):astr;
function astr2msppc(s:astr):ppchar;
function astr2msppcz(s:astr):ppchar;
{$endif}
function msppc(s:integer):ppchar;
procedure frppc(c:ppchar;s:integer);

function despace(s:string):string;
function decomment(s:string):string;
function decomment_despace(s:string):string;
function getfsymp(st:string;sb:char):integer;
function getfsymp2(st:string;sb,sc:char):integer;
function getfsympo(st:string;off:integer;sb:char):integer;
function getfsympo2(st:string;off:integer;sb,sc:char):integer;
function getnsymp(st:string;sb:char;n:integer):integer;
function getlsymp(st:string;sb:char):integer; 
function trimsr(s:string;n:integer;c:char):string;
function trimsl(s:string;n:integer;c:char):string; 
function wcmatch(s,mask:string;igcase:boolean):boolean;

function txt_t2l(const s:string):string;
function txt_l2t(const s:string):string;
//############################################################################// 
implementation
//############################################################################// 
procedure mkpc(var c:pchar;s:integer);begin getmem(c,s); fillchar(c^,s,0);end;
procedure stpc(c:pchar;s:string);var i:integer;begin for i:=0 to length(s)-1 do c[i]:=s[i+1];c[length(s)]:=#0; end;
procedure mspc(var c:pchar;n:integer;s:string);
var i:integer;
begin 
 getmem(c,n); 
 fillchar(c^,n,0);
 for i:=0 to length(s)-1 do c[i]:=s[i+1]; 
end;
{$ifndef paser}
function ppcn2astr(s:ppchar;n:integer):astr;
var i:integer;
begin
 setlength(result,n);
 for i:=0 to n-1 do result[i]:=ppchar(intptr(s)+intptr(i)*4)^;
end;
function ppcz2astr(s:ppchar):astr;
var n:integer;
begin
 result:=nil;
 n:=0;
 repeat
  if ppchar(intptr(s)+intptr(n)*4)^=nil then exit;
  setlength(result,intptr(n)+1);
  result[n]:=ppchar(intptr(s)+intptr(n)*4)^;
  n:=n+1;
 until false;
end;   
function pca2astr(s:pchar):astr;
var n,c:integer;
begin
 result:=nil;
 n:=0;
 c:=0;
 repeat
  if pdword(intptr(s)+intptr(n))^=0 then exit;
  setlength(result,c+1);
  result[c]:=pchar(intptr(s)+intptr(n+4));
  c:=c+1;
  n:=n+pinteger(intptr(s)+intptr(n))^+5;
 until false;
end;
function astr2msppc(s:astr):ppchar;
var i:integer;
begin
 getmem(result,length(s)*4);
 for i:=0 to length(s)-1 do mspc(ppchar(intptr(result)+intptr(i)*4)^,255,s[i]);
end;
function astr2msppcz(s:astr):ppchar;
var i:integer;
begin
 getmem(result,length(s)*4+4);
 for i:=0 to length(s)-1 do mspc(ppchar(intptr(result)+intptr(i)*4)^,255,s[i]);
 ppchar(intptr(result)+intptr(length(s)*4))^:=nil;
end;
{$endif}
function msppc(s:integer):ppchar;
var i:integer;
begin
 getmem(result,s*4);
 for i:=0 to s-1 do mspc(ppchar(intptr(result)+intptr(i)*4)^,255,'');
end;
procedure frppc(c:ppchar;s:integer);
var i:integer;
begin
 for i:=0 to s-1 do freemem(ppchar(intptr(c)+intptr(i)*4)^);
 freemem(c);
end;
//############################################################################//
function despace(s:string):string;
var i:integer;
begin
 result:='';
 for i:=1 to length(s) do if(s[i]<>' ')and(s[i]<>#10)and(s[i]<>#13)and(s[i]<>#9)then result:=result+s[i];
end;
//############################################################################//
function decomment(s:string):string;
var i:integer;
c:boolean;
begin
 result:='';
 c:=false;
 for i:=1 to length(s) do begin
  if s[i]='{' then c:=true;
  if not c then result:=result+s[i];
  if s[i]='}' then c:=false;
 end;
end;
//############################################################################//
function decomment_despace(s:string):string;
var i:integer;
c:boolean;
begin
 result:='';
 c:=false;
 for i:=1 to length(s) do begin
  if s[i]='{' then c:=true;
  if not c then if(s[i]<>' ')and(s[i]<>#10)and(s[i]<>#13)and(s[i]<>#9)then result:=result+s[i];
  if s[i]='}' then c:=false;
 end;
end;
//############################################################################//  
function getfsymp(st:string;sb:char):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=1 to length(st) do if (st[i]=sb)or((sb=' ')and(st[i]=#9)) then begin result:=i; exit; end;
end;
//############################################################################//  
function getfsymp2(st:string;sb,sc:char):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=1 to length(st) do if(st[i]=sb)or(st[i]=sc)or((sb=' ')and(st[i]=#9))or((sc=' ')and(st[i]=#9))then begin result:=i; exit; end;
end;
//############################################################################//  
function getfsympo(st:string;off:integer;sb:char):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=off to length(st) do if (st[i]=sb)or((sb=' ')and(st[i]=#9)) then begin result:=i-off+1; exit; end;
end;
//############################################################################//  
function getfsympo2(st:string;off:integer;sb,sc:char):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=off to length(st) do if(st[i]=sb)or(st[i]=sc)or((sb=' ')and(st[i]=#9))or((sc=' ')and(st[i]=#9))then begin result:=i-off+1; exit; end;
end;
//############################################################################//  
function getnsymp(st:string;sb:char;n:integer):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=1 to length(st) do if (st[i]=sb)or((sb=' ')and(st[i]=#9)) then begin n:=n-1; if n=0 then begin result:=i; exit; end else continue; end;
end;
//############################################################################//  
function getlsymp(st:string;sb:char):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=length(st) downto 1 do if (st[i]=sb)or((sb=' ')and(st[i]=#9)) then begin result:=i; exit; end;
end;
//############################################################################//
//############################################################################//
function trimsr(s:string;n:integer;c:char):string;begin result:=s;while length(result)<n do result:=result+c;end;  
function trimsl(s:string;n:integer;c:char):string;begin result:=s;while length(result)<n do result:=c+result;end;
//############################################################################//
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
function posx(substr,s:string;start:integer):integer;
var i,j,len:integer;
begin
 len:=length(substr);
 if len=0 then begin result:=1;exit;end;
 for i:=start to length(s)-len+1 do begin
  j:=1;
  while j<=len do begin
   if not((substr[j]='?')or(substr[j]=s[i+j-1])) then break;
   inc(j);
  end;
  if j>len then begin result:=i;exit;end;
 end;
 result:=0;
end;
//############################################################################//
function wcmatch(s,mask:string;igcase:boolean):boolean;
const wildsize=0; //minimal number of characters representing a "*"
var mn,mx,i,maskstart,maskend:integer;
t:string;
begin
 if igcase then begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  for i:=1 to length(mask) do mask[i]:=upcase(mask[i]);
 end;
 s:=s+#0;
 mask:=mask+#0;
 mn:=1;
 mx:=1;
 maskend:=0;
 while length(mask)>=maskend do begin
  maskstart:=maskend+1;
  repeat
   inc(maskend);
  until (maskend>length(mask))or(mask[maskend]='*');
  t:=copy(mask,maskstart,maskend-maskstart);
  i:=posx(t,s,mn);
  if(i=0)or(i>mx)then begin result:=false;exit;end;
  mn:=i+length(t)+wildsize;
  mx:=length(s);
 end;
 result:=true;
end;
//############################################################################//
function txt_t2l(const s:string):string;
var p,i:integer;
begin
 setlength(result,length(s));
 p:=1;
 for i:=1 to length(s) do if s[i]<>#$0D then begin result[p]:=s[i];p:=p+1;end;
 setlength(result,p-1);
end;
//############################################################################//
function txt_l2t(const s:string):string;
var p,i:integer;
last:char;
begin
 setlength(result,2*length(s));
 p:=1;
 last:=' ';
 for i:=1 to length(s) do begin
  if (s[i]=#$0A)and(last<>#$0D) then begin result[p]:=#$0D;p:=p+1;result[p]:=#$0A;p:=p+1;end else begin result[p]:=s[i];p:=p+1;end;
  last:=s[i];
 end;
 setlength(result,p-1 );
end;
//############################################################################//
begin
end.
//############################################################################//

