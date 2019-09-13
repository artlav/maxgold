//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
{$ifdef android}{$define no_sdl}{$endif}
{$ifdef ios}{$define no_sdl}{$endif}
unit sdi_rec;
interface
uses asys,grph,grpop{$ifdef ape3},gui_int,gui_rec{$endif};
//############################################################################//
//FIXME: It's the truncated MAXG pallette, should use something better
const defpal:array[0..768-1]of byte=(
 $00,$00,$00,$00,$00,$FF,$00,$FF,$00,$FF,$00,$00,$00,$FF,$FF,$00,$AB,$FF,$A3,$83,$83,$00,$47,$FF,$93,$FF,$FF,$FF,$CB,$CB,$E3,$AB,$AB,$DF,$5B,$63,$E3,$AB,$AB,$9F,$FF,$FF,$67,$AB,$F3,$33,$33,$EB,
 $67,$AB,$F3,$87,$63,$17,$4B,$3F,$2B,$0F,$0F,$0F,$4B,$3F,$2B,$00,$67,$B7,$27,$3B,$4B,$0F,$0F,$0F,$27,$3B,$4B,$0F,$0F,$0F,$1B,$1B,$1B,$2B,$2B,$2B,$37,$37,$37,$43,$43,$47,$53,$53,$57,$00,$00,$00,
 $1B,$BB,$83,$0F,$AB,$6F,$0B,$9F,$5F,$07,$93,$4F,$07,$77,$43,$07,$5F,$33,$07,$43,$27,$07,$2B,$1B,$07,$BB,$BB,$07,$87,$B3,$07,$57,$AB,$07,$2F,$A3,$FF,$FF,$FF,$7B,$07,$67,$07,$37,$7B,$0F,$BB,$93,
 $BB,$9F,$6B,$AB,$87,$47,$97,$73,$2F,$87,$63,$17,$6F,$4F,$0F,$57,$3B,$0B,$43,$2B,$07,$2B,$1B,$07,$57,$7B,$BB,$37,$63,$AF,$1B,$4F,$A3,$07,$3B,$97,$07,$2F,$7B,$07,$27,$63,$07,$1B,$47,$07,$0F,$27,
 $FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,
 $FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,
 $FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,
 $FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,
 $FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,
 $FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,$FF,$07,$D7,
 $F7,$FB,$FF,$D3,$DF,$F3,$BB,$DB,$F3,$AF,$C7,$DF,$9B,$C3,$DF,$8F,$B7,$DB,$7F,$A7,$C7,$83,$A3,$B7,$7B,$9B,$AB,$8B,$97,$9F,$93,$A7,$AF,$97,$AB,$BF,$AF,$BB,$C7,$6B,$A3,$CF,$67,$9B,$BF,$5F,$8B,$AB,
 $6B,$8B,$A3,$63,$87,$9B,$73,$87,$93,$77,$7F,$83,$67,$73,$7B,$5B,$73,$83,$63,$7B,$8B,$53,$77,$93,$4B,$7F,$9F,$4B,$83,$AB,$53,$8B,$B3,$53,$93,$C3,$43,$8B,$C7,$3B,$7F,$B3,$37,$73,$A7,$3B,$6F,$93,
 $3B,$6B,$83,$47,$63,$7B,$3B,$63,$73,$2B,$57,$73,$2F,$53,$67,$3B,$4F,$5B,$33,$47,$53,$2B,$3F,$53,$27,$3B,$4B,$2B,$3B,$43,$27,$33,$3B,$1F,$2B,$33,$23,$27,$2B,$1F,$23,$27,$17,$1B,$1F,$0F,$0F,$0F,
 $1F,$1F,$37,$2B,$2B,$2F,$33,$33,$37,$3B,$3B,$3F,$47,$47,$4B,$53,$53,$57,$5B,$5B,$5F,$63,$63,$67,$6B,$6B,$6F,$53,$67,$73,$4B,$5F,$6B,$43,$57,$63,$23,$43,$57,$2B,$2B,$4B,$3B,$2B,$2F,$2B,$63,$83,
 $4B,$6B,$83,$6B,$83,$CF,$5B,$6F,$AB,$37,$53,$BB,$43,$4F,$7B,$2F,$3F,$9B,$23,$27,$73,$17,$1F,$4B,$0F,$0F,$1F,$63,$AB,$8B,$4F,$93,$73,$3B,$93,$57,$43,$73,$5F,$2F,$6B,$43,$23,$53,$3B,$1B,$43,$2B,
 $0F,$1B,$17,$9F,$6F,$77,$83,$57,$63,$8B,$43,$3B,$6B,$43,$43,$6B,$33,$2F,$4F,$3B,$43,$4B,$23,$1F,$2B,$13,$0F,$00,$67,$B7,$00,$4B,$87,$00,$33,$5B,$00,$9B,$9B,$00,$6F,$6F,$00,$43,$43,$FF,$FF,$FF
);
//############################################################################//
var
ducnt,fpsc,fps:integer;

//Graphs
sdiscr,sdiscr_real,sdiscr_alloc:pointer;
sdiscrp:typspr;
sdipal4:pallette;

real_scrx,real_scry:integer;
{$ifdef ios}ios_surf:pointer;{$endif}
vnc_pass:string='';

//Exported for IOS/etc
sdi_mainloop_clean:procedure(ct,dt:double)=nil;
sdi_mainloop:procedure(ct,dt:double)=nil;
sdi_event:procedure(evt,x,y:integer;key,shift:dword)=nil;

//User
curx,cury:integer;
max_fps:integer=60;
fullscreen,sdiev:boolean;
fpsdbg:boolean=false;
doublebuf:boolean=false;

sdi_keys_lower:boolean=false; //lowercase keys, ignore special symbols
sdi_full_keys:boolean=false;  //fully evaluated keys
sdi_uni:boolean=false;        //crude unicode
sdi_sc:boolean=false;         //scancodes

sdi_check_res:boolean=true;
sdi_tag:pointer=nil;

sdi_key_uni:word;

sdi_centre_top:boolean=true;
sdi_centre_mid:boolean=false;

sdbasetitle:string='';

//Scaling
override_scale:integer=0;
direct_scale_10x:integer=10;
use_scaling:boolean=false;
use_scale2x:boolean=false;
use_scale15x:boolean=false;
scl:scale_rec;               //For non-integer scales
//############################################################################//
var
//User
sdifocus:boolean=true;
sdifocusoff:boolean=false;
{$ifdef ape3}sdi_w:pguwin_shared_rec;{$endif}
//############################################################################//
implementation
//############################################################################//
procedure main;
var i:integer;
begin
 for i:=0 to 255 do begin
  thepal[i][0]:=defpal[i*3+0];
  thepal[i][1]:=defpal[i*3+1];
  thepal[i][2]:=defpal[i*3+2];
 end;
 for i:=0 to 255 do sdipal4[i]:=tcrgba(thepal[i][0],thepal[i][1],thepal[i][2],255);
end;
//############################################################################//
begin
 main;
end.
//############################################################################//
