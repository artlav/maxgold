//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
{$ifdef android}{$define no_sdl}{$endif}
{$ifdef darwin}{$define no_sdl}{$define sdi_gl}{$endif}
{$ifdef ios}{$define no_sdl}{$undef sdi_gl}{$endif}
unit sdisdl;
interface
uses grph,sdi_rec{$ifndef paser},bmp{$endif}
{$ifdef sdi_vnc}
 ,sdi_eng_vnc
{$else}
 {$ifdef sdi_gl}
  ,sdi_eng_gl
 {$else}
  {$ifdef mswindows}{$ifdef sdi_dll},sdi_eng_sdl{$else},sdi_eng_win32{$endif}{$endif}
  {$ifdef linux},sdi_eng_sdl{$endif}
  {$ifdef ape3},sdi_eng_ape3{$endif}
  {$ifdef no_sdl},sdi_eng_direct{$endif}
  {$ifdef paser},sdi_eng_paser{$endif}
 {$endif}
{$endif}
;
//############################################################################//
procedure savescreen8(f:string);
procedure savescreen32(f:string);

procedure raw_maintim(ct,dt:double);

procedure setsdi2(x,y,bit:integer;fs:boolean;cap:string;tim,evt:pointer);
procedure setsdi(x,y,bit:integer;fs:boolean;cap:string;tim,evt:pointer);
procedure sdiset_win_pos(x,y:integer);
procedure sdiflip;
procedure sdisdlquit;
procedure sdiloop;
procedure setsdlpal;
procedure sditestscreenset(var fs:boolean);
procedure sdi_handleinput;
procedure sdi_touch_params;

function  sdilock:boolean;
function  sdicursor(n:integer):integer;
procedure sdiunlock;
//############################################################################//
implementation
//############################################################################//
procedure savescreen8(f:string);
var ssptr:typspr;
begin
 ssptr:=sdiscrp;
 {$ifndef paser}storeBMP8(f,ssptr.srf,ssptr.xs,ssptr.ys,true,true,sdipal4);{$endif}
end;
//############################################################################//
procedure savescreen32(f:string);
var ssptr:typspr;
begin
 ssptr:=sdiscrp;
 {$ifndef paser}storeBMP32(f,ssptr.srf,ssptr.xs,ssptr.ys,true,false);{$endif}
end;
//############################################################################//
procedure raw_maintim(ct,dt:double);
begin
 {$ifndef paser}try{$endif}
 if not sdilock then exit;sdicursor(1);fpsc:=fpsc+1;

 if assigned(sdi_mainloop_clean) then sdi_mainloop_clean(ct,dt);

 if fpsdbg then begin ducnt:=tdu div 1000;tdu:=0;end;sdiunlock;sdiflip;
 {$ifndef paser}except halt;end;{$endif}
end;
//############################################################################//
procedure setsdi2(x,y,bit:integer;fs:boolean;cap:string;tim,evt:pointer);
begin
 scrx:=x;
 scry:=y;
 scrbit:=bit;
 fullscreen:=fs;
 sdbasetitle:=cap;
 sdi_mainloop_clean:=tim;
 sdi_mainloop:=@raw_maintim;
 sdi_event:=evt;
 fpsc:=0;
 fps:=0;
 fpsdbg:=true;
 max_fps:=20;

 eng_setsdi(x,y,bit,fs,cap,tim,evt);
end;
//############################################################################//
procedure setsdi(x,y,bit:integer;fs:boolean;cap:string;tim,evt:pointer);
begin
 scrx:=x;
 scry:=y;
 scrbit:=bit;
 fullscreen:=fs;
 sdbasetitle:=cap;
 sdi_mainloop_clean:=nil;
 sdi_mainloop:=tim;
 sdi_event:=evt;
 fpsc:=0;
 fps:=0;

 eng_setsdi(x,y,bit,fs,cap,tim,evt);
end;
//############################################################################//
procedure sditestscreenset(var fs:boolean);
begin
 scrx:=scrx-scrx mod 4;
 scry:=scry-scry mod 4;
 eng_sditestscreenset(fs);
end;
//############################################################################//
procedure setsdlpal;
var i:integer;
begin
 for i:=0 to 255 do sdipal4[i]:=tcrgba(thepal[i][0],thepal[i][1],thepal[i][2],255);
 eng_setsdlpal;
end;
//############################################################################//
procedure sdiflip;                     begin eng_sdiflip;end;
procedure sdi_handleinput;             begin eng_sdi_handleinput;end;
procedure sdi_touch_params;            begin eng_sdi_touch_params;end;
procedure sdiloop;                     begin eng_sdiloop;end;
procedure sdwinunfoc;                  begin eng_sdwinunfoc;end;
procedure sdwinfoc;                    begin eng_sdwinfoc;end;
procedure sdwinmousein;                begin eng_sdwinmousein; end;
procedure sdwinmouseout;               begin eng_sdwinmouseout; end;
procedure settitle(a:string);          begin eng_settitle(a);end;
procedure sdiset_win_pos(x,y:integer); begin eng_sdiset_win_pos(x,y);end;
procedure sdisdlquit;                  begin eng_sdisdlquit;end;
function  sdicursor(n:integer):integer;begin result:=eng_sdicursor(n);end;
function  sdilock:boolean;             begin result:=eng_sdilock;end;
procedure sdiunlock;                   begin eng_sdiunlock;end;
//############################################################################//
begin
end.
//############################################################################//
