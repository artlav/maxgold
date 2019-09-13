//############################################################################//
unit log;
interface
uses {$ifdef mswindows}windows,{$endif}sysutils,asys;
//############################################################################//
type lngtyp=record
 txt,nm:string;
end;
//############################################################################//
var log_file_name:string='thelog.log';
lang:array of lngtyp;
errcnt:integer=0;
crash:boolean=false;
log_con:boolean=false;
log_time:boolean=true;
//############################################################################//
procedure set_log(n:string;con:boolean);
procedure wr_log(sys,err:string;hlt:boolean=false);
procedure wr_log_asis(s:string);
procedure bigerror(n:dword;msg:string);
procedure stderr(dev,proc:string);

procedure wrln_dbg(s,err:string);
procedure wr_dbg(s,err:string);
procedure haltprog;
//############################################################################//
function  po(inp:string):string;
procedure add_lang(const nm,txt:string);
//############################################################################//
implementation
//############################################################################//
{$ifdef mswindows}
const
errs:array[0..1]of string=('OpenGL init failed|Ошибка инициализации OpenGL','Rendering error|Ошибка рендеринга');
crlf:string=#13#10;
{$endif}
//############################################################################//
//Error report message thread
var
smerr:string;
{$ifdef mswindows}smms:dword;{$endif}
function smm(p:pointer):intptr;
begin
 result:=0;
 sleep(1000);
 {$ifdef mswindows}
 if smms=999 then begin
  if messagebox(0,pchar('Critical error in OGLA.dll, terminating. See ogla.log for details for developer.'+crlf+'Критическая ошибка в OGLA.dll. Подробности для разработчика в ogla.log.'+crlf+crlf+'Error|Ошибка: "'+smerr+'"'),pchar('OGLA: Error|Ошибка'),MB_ICONERROR or MB_OK or MB_TOPMOST)=0 then;
 end else begin
  if messagebox(0,pchar('Critical error in OGLA.dll, terminating. See ogla.log for details for developer.'+crlf+'Критическая ошибка в OGLA.dll. Подробности для разработчика в ogla.log.'+crlf+crlf+'Error|Ошибка: "'+errs[smms]+'"'),pchar('OGLA: Error|Ошибка'),MB_ICONERROR or MB_OK or MB_TOPMOST)=0 then;
 end;
 {$endif}
 crash:=true;
 halt;
end;
//############################################################################//
procedure set_log(n:string;con:boolean);
begin
 log_con:=con;
 {$ifdef mswindows}if con then allocconsole;{$endif}
 log_file_name:=ce_curdir+n;
end;
//############################################################################//
function trims(s:string;n:integer):string;
begin
 result:=s;
 while length(result)<n do result:=result+' ';
end;
//############################################################################//
procedure wr_log(sys,err:string;hlt:boolean=false);
var t:text;
s,hdr:string;
begin
 if log_time then hdr:=DateToStr(date)+'-'+TimeToStr(time)+':' else hdr:='';
 if sys<>'' then hdr:=hdr+'['+trims(sys,10)+']:';
 s:=hdr+err;

 if log_con then begin writeln(s);flush(output);end;

 {$I-}
 assignfile(t,log_file_name);
 if fileexists(log_file_name) then append(t) else rewrite(t);
 writeln(t,s);
 closefile(t);
 if ioresult<>0 then ;
 {$I+}
 if hlt then halt;
end;
//############################################################################//
procedure wr_log_asis(s:string);
var t:text;
begin
 if log_con then writeln(s);
 {$I-}
 assignfile(t,log_file_name);
 if fileexists(log_file_name) then append(t) else rewrite(t);
 writeln(t,s);
 closefile(t);
 if ioresult<>0 then ;
 {$I+}
end;
//############################################################################//
procedure wrln_dbg(s,err:string);begin exit;wr_log(s,err);{$ifdef CONDEBUG}writeln(s);{$endif}end;
procedure wr_dbg(s,err:string);begin exit;wr_log(s,err);{$ifdef CONDEBUG}write(s);{$endif}end;
procedure haltprog;
begin
 {$ifdef mswindows}exitprocess(0);{$endif}
 halt;
end;
//############################################################################//
procedure bigerror(n:dword;msg:string);
begin
 {$ifdef mswindows}smms:=n;{$endif}
 smerr:=msg;
 start_thread(smm,@n);
 EndThread(0);
end;
//############################################################################//
procedure stderr(dev,proc:string);
begin
 wr_log(dev,'Error: '+proc);
 errcnt:=errcnt+1;
 if errcnt>20 then begin
  smerr:='Last Error|Последняя ошибка: '+dev+': Error: '+proc;
  bigerror(999,proc);
 end;
end;
//############################################################################//
procedure sortlang(l,r:integer);
var i,j:integer;
p,t0,t1:string;
begin
 repeat
  i:=l;j:=r;
  p:=lang[(i+j)div 2].nm;
  repeat
   while (i<r)and(p>lang[i].nm) do i:=i+1;
   while (i<r)and(p<lang[j].nm) do j:=j-1;
   if i<=j then begin
    if i<j then begin
     t0:=lang[i].nm;
     t1:=lang[i].txt;
     lang[i].nm:=lang[j].nm;
     lang[i].txt:=lang[j].txt;
     lang[j].nm:=t0;
     lang[j].txt:=t1;
    end;
    i:=i+1;
    j:=j-1;
   end;
  until i>j;
  if j>l then sortlang(l,j);
  if i<r then sortlang(i,r);
  l:=i;
 until i>=r;
end;
//############################################################################//
procedure add_lang(const nm,txt:string);
var i:integer;
begin
 for i:=0 to length(lang)-1 do if lang[i].nm=lowercase(nm) then exit;
 i:=length(lang);
 setlength(lang,i+1);
 lang[i].nm:=lowercase(nm);
 lang[i].txt:=txt;
end;
//############################################################################//
function po(inp:string):string;
var i,n,d,k:integer;
begin
 result:=inp;
 if length(lang)=0 then exit;
 //for i:=0 to length(lang)-1 do if lang[i].nm=inp then begin result:=lang[i].txt;exit; end;

 inp:=lowercase(inp);

 n:=length(lang)-1;
 i:=n div 2;
 d:=0;
 while lang[i].nm<>inp do begin
  if n=d then exit;
  if n-d=1 then begin
   if lang[i].nm=inp then break;
   if lang[n].nm=inp then begin i:=n;break;end;
   exit;
  end;
  k:=(n-d)div 2+d;
  if inp<lang[i].nm then n:=k else d:=k;
  i:=(n-d)div 2+d;
 end;
 result:=lang[i].txt;
end;
//############################################################################//
begin
end.
//############################################################################//

