//############################################################################//
// Made in 2003-2010 by Artyom Litvinovich
// AlgorLib: Timer 
//############################################################################//
//FIXME: Is TimeStampToMSecs(DateTimeToTimeStamp(Time))*1000 universal?
unit tim;   
{$ifdef win32}{$define i386}{$endif}
{$ifdef cpu86}{$define i386}{$endif}
{$ifdef win32}{$define windows}{$endif}
{$ifdef win64}{$define windows}{$endif}

{$ifdef delphi}{$define asmdir}{$endif}
{$ifdef i386}{$define asmdir}{$endif}
{$ifdef cpu64}{$define asmdir}{$endif}

{$ifdef fpc}
 {$mode delphi}
 {$ifdef asmdir}{$asmmode intel}{$endif}
{$endif}

interface
{$ifdef windows}uses asys,windows;{$endif}
{$ifdef ape3}uses asys,akernel;{$endif}
{$ifdef unix}uses asys,sysutils,unix;{$endif}
//############################################################################//
procedure stdt(d:integer);
function rtdt(d:integer):Int64;  
{$ifdef asmdir}function rdtsc:Int64;{$endif}
function getdt:integer;
procedure freedt(n:integer);
//############################################################################//
implementation
//############################################################################//
const dt_cnt=1000;
//############################################################################//
var dtts:array[0..dt_cnt-1]of int64;
dtused:array[0..dt_cnt-1]of boolean;
{$ifdef windows}frq:int64;{$endif} 
{$ifdef ape3}
timer_ticks:pinteger;
sethz:pinteger;
{$endif}
mx:mutex_typ;
//############################################################################//
{$ifdef asmdir}
function rdtsc:Int64;
asm
 rdtsc
 mov dword ptr [Result], eax
 mov dword ptr [Result + 4], edx
end;
{$endif}
//############################################################################//
{$ifdef unix}
function getuscount:int64;
var tv:TimeVal;
begin
 FPGetTimeOfDay(@tv,nil);
 result:=tv.tv_Sec*int64(1000000)+tv.tv_uSec;
end;
{$endif}
//############################################################################//
{$ifdef windows}
function getuscount:int64;
begin
 QueryPerformanceCounter(result{%H-});
 result:=(int64(1000000)*result) div frq;
end;
{$endif}
//############################################################################//
procedure stdt(d:integer);
begin
 {$ifdef darwin} dtts[d]:=round(TimeStampToMSecs(DateTimeToTimeStamp(Time))*1000);exit;{$endif}
 {$ifdef windows}dtts[d]:=getuscount;exit;{$endif}
 {$ifdef ape3}   dtts[d]:=int64(1000000)*int64(timer_ticks^) div int64(sethz^);exit;{$endif}
 {$ifdef unix}   dtts[d]:=getuscount;exit;{$endif}
 {$ifdef paser}  dtts[d]:=nano_time;exit;{$endif}
end;
//############################################################################//
function rtdt(d:integer):int64;
begin
 {$ifdef darwin} result:=round(TimeStampToMSecs(DateTimeToTimeStamp(Time))*1000)-dtts[d];exit;{$endif}
 {$ifdef windows}result:=getuscount-dtts[d];exit;{$endif}
 {$ifdef unix}   result:=getuscount-dtts[d];exit;{$endif}
 {$ifdef ape3}   result:=int64(1000000)*int64(timer_ticks^) div int64(sethz^)-dtts[d];exit;{$endif}
 {$ifdef paser}  result:=nano_time-dtts[d];exit;{$endif}
end; 
//############################################################################//
function getdt:integer;
var i:integer;
begin
 result:=0;
 mutex_lock(mx);
 for i:=dt_cnt-1 downto 0 do if not dtused[i] then begin dtused[i]:=true;result:=i;break;end;
 mutex_release(mx);
end;
//############################################################################//
procedure freedt(n:integer);begin dtused[n]:=false;end;
//############################################################################//
var i:integer;
begin
 mx:=mutex_create;
 for i:=0 to dt_cnt-1 do dtused[i]:=false;
 dtused[0]:=true;
 {$ifdef windows}QueryPerformanceFrequency(frq{%H-});{$endif}
 {$ifdef ape3}timer_ticks:=sckereg($02);sethz:=sckereg($03);{$endif}
 stdt(0);
end.
//############################################################################//

