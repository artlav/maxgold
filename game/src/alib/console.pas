//############################################################################//
unit console;
interface
uses {$ifdef mswindows}windows{$else}baseunix{$endif};
//############################################################################//   
function keypressed:boolean;
function readkey:char;
//############################################################################//   
implementation
//############################################################################//  
{$ifdef mswindows} 
function keypressed:boolean;
var lpNumberOfEvents:dword;
lpBuffer:TInputRecord;
lpNumberOfEventsRead:dword;
nStdHandle:THandle;
begin
 result:=false;
 //get the console handle
 nStdHandle:=GetStdHandle(STD_INPUT_HANDLE);
 lpNumberOfEvents:=0;
 //get the number of events
 GetNumberOfConsoleInputEvents(nStdHandle,lpNumberOfEvents);
 if lpNumberOfEvents<>0 then begin
  //retrieve the event
  PeekConsoleInput(nStdHandle,lpBuffer,1,lpNumberOfEventsRead);
  if lpNumberOfEventsRead<>0 then begin
   if lpBuffer.EventType=KEY_EVENT then begin //is a Keyboard event?
    if lpBuffer.Event.KeyEvent.bKeyDown then result:=true //the key was pressed?
                                        else FlushConsoleInputBuffer(nStdHandle); //flush the buffer
   end else FlushConsoleInputBuffer(nStdHandle);//flush the buffer
  end;
 end;
end;  
//############################################################################//       
function readkey:char;
var NumRead:dword;
InputRec:TInputRecord;    
hConsoleInput:THandle;
begin          
 hConsoleInput:=GetStdHandle(STD_INPUT_HANDLE);
 repeat
  repeat
  until keypressed;
  ReadConsoleInput(hConsoleInput, InputRec, 1, NumRead);
 until InputRec.Event.KeyEvent.AsciiChar > #0;
 result:=InputRec.Event.KeyEvent.AsciiChar;
end;   
//############################################################################//
{$else}
//############################################################################//
const
ttyin=0;
insize=256;
keybuffersize=20;
//############################################################################//
var
inbuf:array[0..insize-1] of char;
incnt,inhead,intail:integer;
keybuffer:array[0..keybuffersize-1] of char;
keyput,keysend:integer;
//############################################################################//
function ttyrecvchar:char;
var readed,i:integer;
begin
 if inhead=intail then begin
  i:=insize-inhead;
  if intail>inhead then i:=intail-inhead;
  readed:=fpread(ttYin,inbuf[inhead],i);
  inc(incnt,readed);
  inc(inhead,readed);
  if inhead>=insize then inhead:=0;
 end;
 if (incnt=0) then result:=#0 else begin
  result:=inbuf[intail];
  dec(incnt);
  inc(intail);
  if intail>=insize then intail:=0;
 end;
end;
//############################################################################//
procedure pushkey(ch:char);
var tmp:integer;
begin
 tmp:=keyput;
 inc(keyput);
 if keyput>=keybuffersize then keyput:=0;
 if keyput<>keysend then keybuffer[tmp]:=ch else keyput:=tmp;
end;
//############################################################################//
function popkey:char;
begin
 if keyput<>keysend then begin
  result:=keybuffer[keysend];
  inc(keysend);
  if keysend>=keybuffersize then keysend:=0;
 end else result:=#0;
end;
//############################################################################//
function syskeypressed:boolean;
var fdsin:tfdset;
begin
 result:=true;
 if incnt>0 then exit;

 fpfd_zero(fdsin);
 fpfd_set(ttyin,fdsin);
 result:=fpselect(ttyin+1,@fdsin,nil,nil,0)>0;
end;
//############################################################################//
function keypressed:boolean;begin result:=(keysend<>keyput) or syskeypressed;end;
//############################################################################//
function readkey:char;
var ch:char;
fds:tfdset;
begin
 if keysend<>keyput then begin result:=popkey;exit;end;

 if not syskeypressed then begin
  fpfd_zero(fds);
  fpfd_set(0,fds);
  fpselect(1,@fds,nil,nil,nil);
 end;

 ch:=ttyrecvchar;
 case ch Of
  #27: pushkey(#27);
  #127:pushkey(#8);
  else pushkey(ch);
 end;
 result:=popkey;
end;
//############################################################################// 
//function keypressed:boolean;begin result:=crt.keypressed;end;
//function readkey:char;begin result:=crt.readkey;end;
//############################################################################//
{$endif}
//############################################################################//
begin
end. 
//############################################################################//
