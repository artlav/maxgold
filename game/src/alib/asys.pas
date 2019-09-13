//############################################################################//
// Made in 2003-2018 by Artyom Litvinovich
// AlgorLib: General definitions
//############################################################################//
//Systems:
//ape3
//windows
//genunix
//android
//darwin
//zaurus
//paser
//nosys

//Systemwide defines:
//self_tests - Would run tests on many units
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit asys;
{$define nosys}
{$define defmutex}
{$ifdef paser}{$undef nosys}{$undef defmutex}{$endif}
{$ifdef win32}{$undef nosys}{$undef defmutex}{$define i386}{$define windows}{$endif}
{$ifdef win64}{$undef nosys}{$undef defmutex}{$define windows}{$endif}
{$ifdef wince}{$undef nosys}{$undef defmutex}{$define windows}{$endif}
{$ifdef cpu86}{$define i386}{$endif}
{$ifdef i386}{$define fast_mov}{$endif}
{$ifdef ape3}{$undef nosys}{$undef defmutex}{$undef fast_mov}{$endif}
{$ifdef unix}{$undef nosys}{$define genunix}{$endif}
{$ifdef linux}{$undef nosys}{$define genunix}{$endif}
{$ifdef no_threads}{$undef genunix}{$define notunix}{$endif}
{$ifdef android}{$undef nosys}{$undef genunix}{$undef fast_mov}{$endif}
{$ifdef zaurus}{$undef nosys}{$undef genunix}{$endif}
{$ifdef darwin}{$undef nosys}{$undef genunix}{$undef fast_mov}{$endif}

{$ifdef genunix}{$define can_nohup}{$endif}
interface
{$ifdef ape3}uses akernel;{$endif}
{$ifdef windows}uses windows,sysutils;{$endif}
{$ifdef genunix}uses cthreads,baseunix,sysutils;{$endif}
{$ifdef notunix}uses sysutils;{$endif}
{$ifdef android}uses cthreads,sysutils;{$endif}
{$ifdef darwin}uses cthreads,sysutils;{$endif}
{$ifdef zaurus}uses sysutils;{$endif}
{$ifdef nosys}uses cthreads,sysutils;{$endif}
{$ifdef paser}uses sysutils;{$endif}

const
{$ifdef windows}
CH_SLASH='\'; // - xcode bug
crlf=#13#10;
{$else}
CH_SLASH='/';
crlf=#10;
{$endif}

Mb=1024*1024;
Kb=1024;

//--Aprom system--//
{$ifdef ape3}{$i ape.inc}{$endif}
//----------------//

type
int8=shortint;
int16=smallint;
int32=integer;
{$ifndef paser}
dword=cardinal;
{$ifndef fpc}qword=int64;{$endif}
{$endif}

{$ifndef CPUX86_64}
intptr=dword;
{$else}
intptr=PtrUInt;
{$endif}

pintptr=^intptr;
pdword=^dword;
pqword=^qword;
pboolean=^boolean;
pint16=^int16;
ppinteger=^pinteger;

{$ifndef paser}
astr=array of string;
aoint8=array of int8;
aoint16=array of int16;
aint=array of int32;
aointeger=aint;
aosingle=array of single;
adouble=array of double;
aadouble=array of adouble;
abyte=array of byte;
aword=array of word;
adword=array of dword;
aqword=array of qword;
apointer=array of pointer;
acardinal=array of cardinal;
aoboolean=array of boolean;

papointer=^apointer;
paointeger=^aointeger;
paosingle=^aosingle;
padword=^adword;
paqword=^aqword;
pabyte=^abyte;
pastr=^astr;
{$endif}

bytea=array[0..maxint-1]of byte;
pbytea=^bytea;
chara=array[0..maxint-1]of char;
pchara=^chara;
worda=array[0..maxint div 2-1]of word;
pworda=^worda;
dworda=array[0..maxint div 4-1]of dword;
pdworda=^dworda;
qworda=array[0..maxint div 8-1]of qword;
pqworda=^qworda;
dwordap=array[0..maxint div 4-1]of pdworda;
ppdworda=^dwordap;
inta=array[0..maxint div 4-1]of integer;
pinta=^inta;
smallinta=array[0..maxint div 4-1]of smallint;
psmallinta=^smallinta;
shortinta=array[0..maxint div 4-1]of shortint;
pshortinta=^shortinta;
singlea=array[0..maxint div 4-1]of single;
psinglea=^singlea;
doublea=array[0..maxint div 8-1]of double;
pdoublea=^doublea;
pointera=array[0..maxint div 16-1]of pointer;
ppointera=^pointera;
aint16=array[0..1000000]of int16;
paint16=^aint16;

apinteger=array[0..1000]of pinteger;
papinteger=^apinteger;
//############################################################################//
thread_func=function(par:pointer):intptr;
//############################################################################//
function sshr(a,n:integer):integer;
function ashr(const a,sh:dword):dword;
{$ifndef paser}function ashr64(const a,sh:qword):qword;{$endif}
function  isf(flags:dword;bit:dword):boolean;
procedure setf(var flags:dword;bit:dword);
procedure unsf(var flags:dword;bit:dword);
procedure bolf(var flags:dword;bit:dword;b:boolean);
//############################################################################//
function transendian_qw(const ix:qword):qword;{$ifdef fpc}inline;{$endif}
function transendian_dw(const ix:dword):dword;{$ifdef fpc}inline;{$endif}
function transendian_w(const ix:word):word;{$ifdef fpc}inline;{$endif}
function te_qw(const ix:qword):qword;{$ifdef fpc}inline;{$endif}
function te_dw(const ix:dword):dword;{$ifdef fpc}inline;{$endif}
function te_w(const ix:word):word;{$ifdef fpc}inline;{$endif}
function flip_byte(const b:byte):byte;
//############################################################################//
procedure sleep(t:dword);
{$ifndef paser}procedure ub1;{$endif}
procedure fastMove(const source;var dest;count:integer);
//############################################################################//
{$ifndef fpc}type tthreadid=dword;{$endif}
{$ifdef defmutex}
 type mutex_typ=pRTLCriticalSection;
{$else}
 {$ifdef windows}type mutex_typ=thandle;{$endif}
 {$ifdef ape3}type mutex_typ=dword;{$endif}
 {$ifdef paser}type mutex_typ=dword;{$endif}
{$endif}
pmutex_typ=^mutex_typ;

function mutex_create:mutex_typ;
procedure mutex_lock(var m:mutex_typ);
procedure mutex_release(var m:mutex_typ);
procedure mutex_free(var m:mutex_typ);
function get_process_id:intptr;
function get_cpu_count:integer;
//############################################################################//
function start_thread(func:thread_func;par:pointer):intptr;
//############################################################################//
function getdate:string;
function getdatestamp:string;
function getdatestamp_unix(unix:dword):string;
function getdatestamp_unix_write(unix:dword):string;
{$ifndef paser}
{$ifndef ape3}
function DateTimeToUnix(ConvDate:TDateTime):Longint;
function UnixToDateTime(USec:Longint):TDateTime;
{$endif}
function get_cur_time_utc:dword;
function current_unix_timestamp:dword;
{$endif}
function date_to_timestamp(const y,m,d,hr,min,sec:integer):dword;
procedure timestamp_to_date(ts:dword;out y,m,d,hr,min,sec:integer);
//############################################################################//
procedure nohup_me;
//############################################################################//
var ce_curdir:string='';
stop_threads:boolean=false;
socket_extra_error_check:boolean=false;  //Makes atcp's tcp_iserror do potentially stuff-breaking checks for closed sockets.
timezone:integer=3;
//############################################################################//
implementation
//############################################################################//
function sshr(a,n:integer):integer;
begin
 if a>=0 then result:=a shr n else result:=(a shr n)or integer($FFFFFFFF shl(32-n));
end;
//############################################################################//
//May be the same as sshr
function ashr(const a,sh:dword):dword;
var i:integer;
rs:byte;
begin
 rs:=ord((a and $80000000)<>0);
 result:=a shr sh;
 if rs<>0 then for i:=0 to sh-1 do result:=result or ($80000000 shr i);
end;
//############################################################################//
//May be the same as sshr
{$ifndef paser}
function ashr64(const a,sh:qword):qword;
var i:integer;
rs:byte;
begin
 rs:=ord((a and qword($8000000000000000))<>0);
 result:=a shr sh;
 if rs<>0 then for i:=0 to sh-1 do result:=result or (qword($8000000000000000) shr i);
end;
{$endif}
//##############################################################################
function  isf(flags:dword;bit:dword):boolean;begin result:=(flags and bit)<>0;end;
procedure setf(var flags:dword;bit:dword);begin flags:=flags or bit;end;
procedure unsf(var flags:dword;bit:dword);begin flags:=flags and(not bit);end;
procedure bolf(var flags:dword;bit:dword;b:boolean);begin if b then setf(flags,bit)else unsf(flags,bit);end;
//############################################################################//
function transendian_qw(const ix:qword):qword;{$ifdef fpc}inline;{$endif}var i:integer;begin for i:=0 to 7 do pbytea(@result)[i]:=pbytea(@ix)[7-i];end;
{$ifdef endian_big}
function transendian_dw(const ix:dword):dword;{$ifdef fpc}inline;{$endif}var x:pbytea;begin x:=@ix; result:=(x[3] shl 24) or (x[2] shl 16) or (x[1] shl 8) or x[0];end;
function transendian_w (const ix: word): word;{$ifdef fpc}inline;{$endif}var x:pbytea;begin x:=@ix; result:=(x[1] shl 8) or x[0];end;
{$else}
function transendian_dw(const ix:dword):dword;{$ifdef fpc}inline;{$endif}var x:pbytea;begin x:=@ix; result:=(x[0] shl 24) or (x[1] shl 16) or (x[2] shl 8) or x[3];end;
function transendian_w (const ix: word): word;{$ifdef fpc}inline;{$endif}var x:pbytea;begin x:=@ix; result:=(x[0] shl 8) or x[1];end;
{$endif}
//############################################################################//
function te_qw(const ix:qword):qword;{$ifdef fpc}inline;{$endif}begin result:=transendian_qw(ix);end;
function te_dw(const ix:dword):dword;{$ifdef fpc}inline;{$endif}begin result:=transendian_dw(ix);end;
function te_w (const ix: word): word;{$ifdef fpc}inline;{$endif}begin result:=transendian_w (ix);end;
//############################################################################//
function flip_byte(const b:byte):byte;
begin
 result:=
  ((b and $80)shr 7)or
  ((b and $40)shr 5)or
  ((b and $20)shr 3)or
  ((b and $10)shr 1)or
  ((b and $08)shl 1)or
  ((b and $04)shl 3)or
  ((b and $02)shl 5)or
  ((b and $01)shl 7);
end;
//##############################################################################
function mini_getlsymp(st:string;c:char):integer;
var i:integer;
begin
 result:=0;
 if st<>'' then for i:=length(st) downto 1 do if st[i]=c then begin result:=i; exit; end;
end;
//############################################################################//
{$ifdef ape3}
var ss:integer;
procedure sleep(t:dword);begin ss:=t div 5;while ss>0 do begin ss:=ss-1; skip_tick;end;end;
{$else}
procedure sleep(t:dword);begin {$ifndef paser}sysutils.sleep(t);{$endif}end;
{$endif}
//############################################################################//
procedure fastMove(const source;var dest;count:Integer);begin move(source,dest,count);end;
//############################################################################//
procedure ub1;
begin
{$ifdef i386}
{$ifndef darwin}
asm
 mov ebx,0
 mov dword [ebx],55
end;
{$endif}
{$endif}
end;
//##############################################################################
{$ifndef paser}
{$ifndef ape3}
var UnixStartDate:TDateTime=25569.0;
//##############################################################################
function getdate:string;begin result:=DateTimeToStr(date+time);end;
function getdatestamp:string;begin DateTimeToString(result,'yymmdd_hh-nn-ss-zzz',date+time); end;
function getdatestamp_unix(unix:dword):string;begin DateTimeToString(result,'yymmdd_hh-nn-ss-zzz',UnixToDateTime(unix)); end;
function getdatestamp_unix_write(unix:dword):string;begin DateTimeToString(result,'yymmdd hh:nn:ss',UnixToDateTime(unix)); end;
function current_unix_timestamp:dword;begin result:=round((now-25569)*86400){$ifdef unix}+GetLocalTimeOffset*60{$endif};end;
{$else}
var UnixStartDate:TDateTime=25569.0;
//##############################################################################
function getdate:string;begin result:=''; end;
function getdatestamp:string;begin result:=''; end;
function getdatestamp_unix(unix:dword):string;begin result:=''; end;
function getdatestamp_unix_write(unix:dword):string;begin result:=''; end;
function current_unix_timestamp:dword;begin result:=1;end;
{$endif}
{$endif}
//############################################################################//
{$ifdef defmutex}
var cpu_cnt:integer=0;
function mutex_create:mutex_typ;   begin new(result); InitCriticalSection(result^);end;
procedure mutex_lock(var m:mutex_typ);  begin EnterCriticalSection(m^);end;
procedure mutex_release(var m:mutex_typ); begin try LeaveCriticalSection(m^); except end;end;
procedure mutex_free(var m:mutex_typ); begin DoneCriticalSection(m^); dispose(m);end;
function get_process_id:intptr;begin result:=intptr(GetThreadID);end;
function get_cpu_count:integer;
var f:text;
s:string;
k:integer;
begin
 if cpu_cnt=0 then begin
  cpu_cnt:=1;
  result:=cpu_cnt;
  try
   {$I-}
   if not fileexists('/proc/cpuinfo') then exit;
   filemode:=0;
   assignfile(f,'/proc/cpuinfo');
   reset(f);
   if ioresult<>0 then exit;
   while not eof(f) do begin
    readln(f,s);
    if copy(s,1,9)='processor' then begin
     k:=mini_getlsymp(s,':');
     if k<>0 then begin
      s:=trim(copy(s,k+1,length(s)));
      val(s,cpu_cnt,k);
      cpu_cnt:=cpu_cnt+1;
     end;
    end;
   end;
   closefile(f);
   {$I+}
  except end;
 end;
 result:=cpu_cnt;
end;
{$endif}
//############################################################################//
{$ifdef windows}
function mutex_create:mutex_typ;begin {$ifndef semamutex}result:=createmutex(nil,true,nil);releasemutex(result);{$else}result:=createsemaphore(nil,1,1,nil);{$endif}end;
procedure mutex_lock(var m:mutex_typ);begin waitforsingleobject(m,INFINITE);end;
procedure mutex_release(var m:mutex_typ);begin {$ifndef semamutex}releasemutex(m);{$else}releasesemaphore(m,1,nil);{$endif}end;
procedure mutex_free(var m:mutex_typ); begin closehandle(m);end;
function get_process_id:intptr;begin result:=GetCurrentThreadId;end;
function get_cpu_count:integer;var sysinfo:system_info;begin GetSystemInfo(sysinfo{%H-}); result:=sysinfo.dwNumberOfProcessors;end;
{$endif}
//############################################################################//
{$ifdef ape3}
function mutex_create:mutex_typ; begin result:=alloc_mutex;end;
procedure mutex_lock(var m:mutex_typ);  begin wait_mutex(m);end;
procedure mutex_release(var m:mutex_typ); begin signal_mutex(m);end;
procedure mutex_free(var m:mutex_typ); begin free_mutex(m);end;
function get_process_id:dword;begin result:=getpid;end;
function get_cpu_count:integer;begin result:=1;end;
{$endif}
//############################################################################//
{$ifdef paser}
function mutex_create:mutex_typ;begin result:=0;end;
procedure mutex_lock(var m:mutex_typ);begin end;
procedure mutex_release(var m:mutex_typ);begin end;
procedure mutex_free(var m:mutex_typ);begin end;
function get_process_id:dword;begin result:=1;end;
function get_cpu_count:integer;begin result:=1;end;
{$endif}
//############################################################################//
type th_par=record
 th:thread_func;
 par:pointer;
end;
pth_par=^th_par;
//############################################################################//
function thread_onramp(p:pointer):{$ifdef fpc}{$ifdef cpuarm}longint;stdcall{$else}{$ifdef cpu64}int64;{$else}longint;{$endif}register{$endif}{$else}intptr{$endif};
var t:th_par;
begin
 t:=pth_par(p)^;
 dispose(pth_par(p));
 result:=t.th(t.par);
end;
//############################################################################//
function start_thread(func:thread_func;par:pointer):intptr;
var sthid:intptr;
t:pth_par;
begin
 result:=0;
 if not assigned(func) then exit;
 new(t);
 t.th:=func;
 t.par:=par;
 beginthread(nil,4*1024*1024,thread_onramp,t,0,sthid{%H-});
 result:=sthid;
end;
//############################################################################//
{$ifndef paser}
{$ifndef ape3}
function DateTimeToUnix(ConvDate:TDateTime):Longint;begin result:=Round((ConvDate-UnixStartDate)*86400); end;
function UnixToDateTime(USec:Longint):TDateTime;begin result:=(Usec/86400)+UnixStartDate; end;
{$else}
function DateTimeToUnix(ConvDate:TDateTime):Longint;begin result:=0; end;
function UnixToDateTime(USec:Longint):TDateTime;begin result:=0; end;
function now:TDateTime;begin result:=0; end;
{$endif}
{$endif}
//############################################################################//
{$ifdef windows}
function get_cur_time_utc:dword;
var ZoneInfo:TTimeZoneInformation;
begin
 GetTimeZoneInformation(ZoneInfo{%H-});
 result:=DateTimeToUnix(now+ZoneInfo.Bias/1440);
end;
{$else}
{$ifndef paser}
function get_cur_time_utc:dword;begin result:=DateTimeToUnix(now);end;
{$endif}
{$endif}
//############################################################################//
const
year_offsets:array[0..3]of integer=(129600,64800,86400,108000);
day_count:array[0..11]of integer=(0,31,59,90,120,151,181,212,243,273,304,334);
//############################################################################//
function date_to_timestamp(const y,m,d,hr,min,sec:integer):dword;
var dc:integer;
begin
 result:=0;
 if (m<1)or(m>12) then exit;
 if (y<1970)or(y>2038) then exit;

 dc:=day_count[m-1];
 if m>=3 then if (y mod 4)=0 then dc:=dc+1;

 result:=sec+min*60+hr*3600+(d+dc)*86400+(y-1970)*(86400*365+21600)-year_offsets[y mod 4];
end;
//############################################################################//
procedure timestamp_to_date(ts:dword;out y,m,d,hr,min,sec:integer);
var x,b,c,f,e:integer;
begin
 sec:=ts mod 60;
 min:=(ts div 60) mod 60;
 hr:=(ts div 3600) mod 24;

 ts:=ts div 86400;

 x:=(ts*4+102032) div 146097+15;
 b:=ts+2442113+x-(x div 4);
 c:=(b*20-2442) div 7305;
 f:=b-365*c-c div 4;
 e:=f*1000 div 30601;
 d:=f-e*30-e*601 div 1000;

 if e<14 then begin
  y:=c-4716;
  m:=e-1;
 end else begin
  y:=c-4715;
  m:=e-13;
 end;
end;
//############################################################################//
{$ifdef can_nohup}
var aold,ahup:sigactionrec;
zerosigs:sigset_t;
//############################################################################//
procedure dosig(sig:longint);cdecl;
begin
 case sig of
  SIGHUP:;
 end;
end;
//############################################################################//
procedure nohup_me;
begin
 fpsigemptyset(zerosigs);
 ahup.sa_handler:=sigactionHandler(@dosig);
 ahup.sa_mask:=zerosigs;
 ahup.sa_flags:=0;
 {$ifndef BSD}ahup.sa_restorer:=nil;{$endif}
 fpSigAction(SIGHUP,@ahup,@aold);
end;
//############################################################################//
{$else}
//############################################################################//
procedure nohup_me;begin end;
//############################################################################//
{$endif}
//############################################################################//
begin
{$ifndef paser}
 ce_curdir:=copy(paramstr(0),1,mini_getlsymp(paramstr(0),CH_SLASH));
 if ce_curdir='.'+CH_SLASH then begin
  getdir(0,ce_curdir);
  ce_curdir:=ce_curdir+CH_SLASH;
 end;
{$endif}
end.
//############################################################################//
