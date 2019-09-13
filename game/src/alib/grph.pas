//############################################################################//
// Made in 2003-2016 by Artyom Litvinovich
// AlgorLib: Graph Main
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit grph;
interface
uses asys,maths;
//############################################################################//
//Clamping near-byte values into 0..255
{$ifndef paser}
const
clamp_table_alloc:array[0..3*256-1]of byte=(
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,

   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
  64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
  96, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,
 128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,
 160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,
 192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,
 224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,

 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
);
clamp_table:pbytea=@clamp_table_alloc[256];
{$endif}
//############################################################################//
const
sh_shift =$0001;
sh_lshift=$0002;
sh_rshift=$0004;
sh_alt   =$0008;
sh_lalt  =$0010;
sh_ralt  =$0020;
sh_ctrl  =$0040;
sh_lctrl =$0080;
sh_rctrl =$0100;
sh_left  =$0200;
sh_right =$0400;
sh_middle=$0800;
sh_double=$1000;
sh_up    =$2000;
sh_down  =$4000;
//############################################################################//
glgr_evclose=1;
glgr_evresize=2;
glgr_evkeyup=3;
glgr_evkeydwn=4;
glgr_evmsmove=5;
glgr_evmsup=6;
glgr_evmsdwn=7;
glgr_evcreate=8;
glgr_evsetparam=9;
glgr_evgetparam=10;
//############################################################################//
{$ifdef win32}{$define mswindows}{$endif}
{$ifdef win64}{$define mswindows}{$endif}
{$ifdef wince}{$define mswindows}{$endif}
{$ifdef darwin}{$define keys_glut}{$endif}
{$ifdef linux}{$define keys_linux}{$endif}
{$ifdef paser}{$define keys_linux}{$endif}

{$ifdef keys_glut}{$undef keys_linux}{$endif}
//############################################################################//
{$ifdef android}   {$i grph_key_android.inc}  {$endif}
{$ifdef ape3}      {$i grph_key_ape3.inc}     {$endif}
{$ifdef keys_glut} {$i grph_key_glut.inc}     {$endif}
{$ifdef keys_linux}{$i grph_key_sdl_linux.inc}{$endif}
{$ifdef mswindows} {$i grph_key_win.inc}      {$endif}
//############################################################################//
type
crgb=array[0..2]of byte;
pcrgb=^crgb;
bcrgb=array[0..1000000]of crgb;
pbcrgb=^bcrgb;

crgba=array[0..3]of byte;
pcrgba=^crgba;
crgbad=array[0..3]of single;
pcrgbad=^crgba;
bcrgba=array[0..1000000]of crgba;
pbcrgba=^bcrgba;
{$ifndef paser}
acrgba=array of crgba;
pacrgba=^acrgba;
{$endif}

pallette=array[0..255]of crgba;
ppallette=^pallette;
pallette3=array[0..255]of crgb;
ppallette3=^pallette3;
//############################################################################//
const
notx=$FFFFFFFF;
gclz:crgb=(0,0,0);
gclaz:crgba=(0,0,0,0);
{$ifndef BGR}
is_bgr=false;
CLBLUE=2;
CLGREEN=1;
CLRED=0;
gclwhite:crgba=(255,255,255,255);
gclblack:crgba=(0,0,0,255);
gclred:crgba=(255,0,0,255);
gclgreen:crgba=(0,255,0,255);
gcllightgreen:crgba=(128,255,128,255);
gcldarkgreen:crgba=(0,128,0,255);
gclblue:crgba=(0,0,255,255);
gcllightblue:crgba=(128,128,255,255);
gclgray:crgba=(128,128,128,255);
gcllightgray:crgba=(200,200,200,255);
gcldarkgray:crgba=(64,64,64,255);
gclyellow:crgba=(255,255,0,255);
gcldarkyellow:crgba=(128,128,0,255);
gclorange:crgba=(255,128,0,255);
gclbrown:crgba=(150,75,0,255);
gclcyan:crgba=(0,255,255,255);
gclmagenta:crgba=(255,0,255,255);
{$else}
is_bgr=true;
CLBLUE=0;
CLGREEN=1;
CLRED=2;
gclwhite:crgba=(255,255,255,255);
gclblack:crgba=(0,0,0,255);
gclred:crgba=(0,0,255,255);
gclgreen:crgba=(0,255,0,255);
gcllightgreen:crgba=(128,255,128,255);
gcldarkgreen:crgba=(0,128,0,255);
gclblue:crgba=(255,0,0,255);
gcllightblue:crgba=(255,128,128,255);
gclgray:crgba=(128,128,128,255);
gcllightgray:crgba=(200,200,200,255);
gcldarkgray:crgba=(64,64,64,255);
gclyellow:crgba=(0,255,255,255);
gcldarkyellow:crgba=(0,128,128,255);
gclorange:crgba=(0,128,255,255);
gclbrown:crgba=(0,75,150,255);
gclcyan:crgba=(255,255,0,255);
gclmagenta:crgba=(255,0,255,255);
{$endif}
//############################################################################//
{$ifndef paser}
type
shortvid8frmtyp=record
 tp:integer;
 frm:pbytea;
 //fdl:
end;
pshortvid8frmtyp=shortvid8frmtyp;
shortvid8typ=record
 used:boolean;
 frmc,dtms:integer;
 wid,hei:integer;

 frms:array of shortvid8frmtyp;
 pal:pallette3;
end;
pshortvid8typ=^shortvid8typ;

shortvid32frmtyp=record
 tp:integer;
 frm:pbcrgba;
end;
pshortvid32frmtyp=shortvid32frmtyp;
shortvid32typ=record
 used:boolean;
 frmc,dtms:integer;
 wid,hei:integer;

 frms:array of shortvid32frmtyp;
end;
pshortvid32typ=^shortvid32typ;
{$endif}
//############################################################################//
//############################################################################//
type
palxtyp=array[0..255]of byte;
ppalxtyp=^palxtyp;

typspr=record
 srf:pointer;
 xp,yp,xs,ys,cx,cy,tp,bits:integer;
 sz:integer; //I.e. for a webcam returning a JPG
 tx:cardinal;
end;
ptypspr=^typspr;

{$ifndef paser}
aptypspr=array of ptypspr;
atypspr=array of typspr;

typuspr=record
 sprc:array of typspr;
 cnt:integer;
 ex:boolean;
end;
ptypuspr=^typuspr;
//############################################################################//
txt_attr_rec=record
 col:crgba;
 sym_pos,line_pos:integer;
 line:integer;
 sel:boolean;
end;
ptxt_attr_rec=^txt_attr_rec;
arr_txt_attr_rec=array of txt_attr_rec;
{$endif}
//############################################################################//
tex_proc_func=function(nam:string):ptypspr;
//############################################################################//
var
tdu:integer=0; //For counting the graphic operations

pref_size:integer=256;
halting:boolean=false;
glgr_set_cur:boolean=false;

scrx,scry,scrbit,scrbitbin:integer;
thepal:pallette3;
//############################################################################//
function f_to_col(const f:double):integer;
function f256_to_col(const f:double):integer;

function simple_gray(cl:crgba):integer;

function tcrgb(const r,g,b:integer):crgb;
function tcrgba(const r,g,b,a:byte):crgba;
function tdcrgba(const r,g,b,a:single):crgba;

function tvcrgba(v:vec):crgba;
function tmvcrgba(v:mvec):crgba;
function crgba2mquat(c:crgba):mquat;
function tvcrgbad(v:vec):crgbad;
function tcrgbav(v:crgba):vec;
function tcrgbaq(v:crgba):quat;
function tqcrgba(q:quat):crgba;
function cl_from_quat(q:quat):crgba;

function tcrgbad(const r,g,b,a:single):crgbad;
function dw2crgb(a:longword):crgb;
function dw2crgba(a:longword):crgba;
//function crgb2dw(a:crgb):longword;
//function crgba2dw(a:crgba):longword;
function nata(const a:crgb):crgba;
function atna(const a:crgba):crgb;
function bgrcrgba(const c:crgba):crgba;

function tcolor16_1555(r,g,b:byte):word;
function xcrgba16_1555(c:crgba):word;
function tcolor16_565(r,g,b:byte):word;
function xcrgba16_565(c:crgba):word;
function yuv_to_crgba(y,u,v:byte):crgba;

function mercl(c1,c2:crgba;r:single):crgba;
function mercld(c1,c2:crgbad;r:single):crgbad;
function mercla(c1,c2:crgba;r:single):crgba;
function mixcl(c1,c2:crgba;r:single):crgba;
function subcl(c1,c2:crgba):crgba;
function addcl(c1,c2:crgba):crgba;
function addcla(c1,c2:crgba):crgba;
function nmulcl(c1:crgba;n:single):crgba;
function nmulcla(c1:crgba;n:single):crgba;
function subcld(c1,c2:crgba):crgbad;
function addcld(c1,c2:crgba):crgbad;
function nmulcld(c1:crgba;n:single):crgbad;

function crgbaccmp(a,b:crgba):boolean;
function td2crgba(v:crgbad):crgba;
function tcrgba2d(v:crgba):crgbad;

function bchcrgba(c:boolean;t,f:crgba):crgba;

procedure set_spr(var spr:typspr;ip:pointer;wid,hei:integer);
function genspr_mem(ip:pointer;wid,hei:integer):ptypspr;
function genspr8_memcpy(ip:pointer;wid,hei:integer):ptypspr;
function genspr32_memcpy(ip:pointer;wid,hei:integer):ptypspr;
function genspr_blank(wid,hei,bits:integer):ptypspr;

function spr_to_srf(xs,ys:integer;p:pbcrgba):ptypspr;
function in_image_with_border(im:ptypspr;const pos:ivec2;border:integer):boolean;
function in_image_with_border_xs(xs,ys:integer;const pos:ivec2;border:integer):boolean;
//############################################################################//
implementation
//############################################################################//
function f_to_col(const f:double):integer;
begin
 result:=round(f*255);
 if result>255 then result:=255;
 if result<0 then result:=0;
end;
//############################################################################//
function f256_to_col(const f:double):integer;
begin
 result:=round(f);
 if result>255 then result:=255;
 if result<0 then result:=0;
end;
//############################################################################//
function simple_gray(cl:crgba):integer;
begin
 result:=(cl[0]+cl[1]+cl[2])div 3;
end;
//############################################################################//
function crgbaccmp(a,b:crgba):boolean;
begin
 result:=(a[0]=b[0])and(a[1]=b[1])and(a[2]=b[2]);
end;
function tcrgb(const r,g,b:integer):crgb;
begin
 {$ifdef darwin}
 //FIXME: overflow checking...
 if r>255 then r:=255;if r<0 then r:=0;
 if g>255 then g:=255;if g<0 then g:=0;
 if b>255 then b:=255;if b<0 then b:=0;
 {$endif}
 result[CLRED]:=r;
 result[CLGREEN]:=g;
 result[CLBLUE]:=b;
end;
function tcrgba(const r,g,b,a:byte):crgba;
begin
 result[CLRED]:=r;
 result[CLGREEN]:=g;
 result[CLBLUE]:=b;
 result[3]:=a;
end;
function tcrgbad(const r,g,b,a:single):crgbad;
begin
 result[CLRED]:=r;
 result[CLGREEN]:=g;
 result[CLBLUE]:=b;
 result[3]:=a;
end;
function tdcrgba(const r,g,b,a:single):crgba;
begin
 result[CLRED]:=round(r*255);
 result[CLGREEN]:=round(g*255);
 result[CLBLUE]:=round(b*255);
 result[3]:=round(a*255);
end;
function td2crgba(v:crgbad):crgba;
begin
 result[0]:=round(v[0]*255);
 result[1]:=round(v[1]*255);
 result[2]:=round(v[2]*255);
 result[3]:=round(v[3]*255);
end;
function bgrcrgba(const c:crgba):crgba;
begin
 result[0]:=c[2];
 result[1]:=c[1];
 result[2]:=c[0];
 result[3]:=c[3];
end;
function tcrgba2d(v:crgba):crgbad;
begin
 result[0]:=v[0]/255;
 result[1]:=v[1]/255;
 result[2]:=v[2]/255;
 result[3]:=v[3]/255;
end;

function crgba2mquat(c:crgba):mquat;
begin
 result.x:=c[0]/255;
 result.y:=c[1]/255;
 result.z:=c[2]/255;
 result.w:=c[3]/255;
end;
function tvcrgba(v:vec):crgba;
begin
 if v.x>1 then v.x:=1;
 if v.y>1 then v.y:=1;
 if v.z>1 then v.z:=1;
 if v.x<0 then v.x:=0;
 if v.y<0 then v.y:=0;
 if v.z<0 then v.z:=0;
{$ifndef BGR}
 result[0]:=round(v.x*255);
 result[1]:=round(v.y*255);
 result[2]:=round(v.z*255);
 result[3]:=255;
{$else}
 result[2]:=round(v.x*255);
 result[1]:=round(v.y*255);
 result[0]:=round(v.z*255);
 result[3]:=255;
{$endif}
end;
function tmvcrgba(v:mvec):crgba;
begin
 if v.x>1 then v.x:=1;
 if v.y>1 then v.y:=1;
 if v.z>1 then v.z:=1;
 if v.x<0 then v.x:=0;
 if v.y<0 then v.y:=0;
 if v.z<0 then v.z:=0;
{$ifndef BGR}
 result[0]:=round(v.x*255);
 result[1]:=round(v.y*255);
 result[2]:=round(v.z*255);
 result[3]:=255;
{$else}
 result[2]:=round(v.x*255);
 result[1]:=round(v.y*255);
 result[0]:=round(v.z*255);
 result[3]:=255;
{$endif}
end;
function tvcrgbad(v:vec):crgbad;
begin
{$ifndef BGR}
 result[0]:=v.x;
 result[1]:=v.y;
 result[2]:=v.z;
 result[3]:=255;
{$else}
 result[2]:=v.x;
 result[1]:=v.y;
 result[0]:=v.z;
 result[3]:=255;
{$endif}
end;
function tcrgbav(v:crgba):vec;
begin
{$ifndef BGR}
 result.x:=v[0]/255;
 result.y:=v[1]/255;
 result.z:=v[2]/255;
{$else}
 result.x:=v[2]/255;
 result.y:=v[1]/255;
 result.z:=v[0]/255;
{$endif}
end;
function tcrgbaq(v:crgba):quat;
begin
{$ifndef BGR}
 result.x:=v[0]/255;
 result.z:=v[2]/255;
{$else}
 result.x:=v[2]/255;
 result.z:=v[0]/255;
{$endif}
 result.y:=v[1]/255;
 result.w:=v[3]/255;
end;
function tqcrgba(q:quat):crgba;
begin
{$ifndef BGR}
 result[0]:=round(255*q.x);
 result[2]:=round(255*q.z);
{$else}
 result[2]:=round(255*q.x);
 result[0]:=round(255*q.z);
{$endif}

 result[1]:=round(255*q.y);
 result[3]:=round(255*q.w);
end;
function cl_from_quat(q:quat):crgba;
begin
 result[0]:=round(q.x);
 result[1]:=round(q.y);
 result[2]:=round(q.z);
 result[3]:=round(q.w);
end;

function nata(const a:crgb):crgba;
begin
 result[0]:=a[0];
 result[1]:=a[1];
 result[2]:=a[2];
 result[3]:=255;
end;
function atna(const a:crgba):crgb;
begin
 result[0]:=a[0];
 result[1]:=a[1];
 result[2]:=a[2];
end;
//############################################################################//
//Old version
//rrrrrggggg0bbbbb
//function tcolor16_555(r,g,b:byte):word;begin result:=((r and $F8) shr 3) shl 11+((g and $F8) shr 3) shl 6+((b and $F8) shr 3);end;
//############################################################################//
//arrrrrgggggbbbbb
function tcolor16_1555(r,g,b:byte):word;begin result:=((r and $F8) shr 3) shl 10+((g and $F8) shr 3) shl 5+((b and $F8) shr 3);end;
function xcrgba16_1555(c:crgba):word;   begin result:=tcolor16_1555(c[CLRED],c[CLGREEN],c[CLBLUE]); end;
//############################################################################//
//rrrrrggggggbbbbb
function tcolor16_565(r,g,b:byte):word;begin result:=((r and $F8) shr 3) shl 11+((g and $FC) shr 2) shl 5+((b and $F8) shr 3);end;
function xcrgba16_565(c:crgba):word;   begin result:=tcolor16_565(c[CLRED],c[CLGREEN],c[CLBLUE]); end;
//############################################################################//
function yuv_to_crgba(y,u,v:byte):crgba;
var r,g,b,yy,uu,vv:integer;
begin
 yy:=y*256;
 uu:=u-128;
 vv:=v-128;

 r:=(yy+(359*vv)) div 256;
 g:=(yy-(88 *uu)-(183*vv)) div 256;
 b:=(yy+(454*uu)) div 256;

 if r>255 then r:=255;
 if g>255 then g:=255;
 if b>255 then b:=255;
 if r<0 then r:=0;
 if g<0 then g:=0;
 if b<0 then b:=0;
 result:=tcrgba(r,g,b,255);
end;
//############################################################################//
function mercl(c1,c2:crgba;r:single):crgba;
var e:single;
begin
 e:=(c1[0]/255)*r+(c2[0]/255)*(1-r);if e>1 then e:=1;result[0]:=round(e*255);
 e:=(c1[1]/255)*r+(c2[1]/255)*(1-r);if e>1 then e:=1;result[1]:=round(e*255);
 e:=(c1[2]/255)*r+(c2[2]/255)*(1-r);if e>1 then e:=1;result[2]:=round(e*255);
 result[3]:=255;
end;
function mercld(c1,c2:crgbad;r:single):crgbad;
var e:single;
begin
 e:=c1[0]*r+c2[0]*(1-r);if e>1 then e:=1;result[0]:=e;
 e:=c1[1]*r+c2[1]*(1-r);if e>1 then e:=1;result[1]:=e;
 e:=c1[2]*r+c2[2]*(1-r);if e>1 then e:=1;result[2]:=e;
 result[3]:=1;
end;
function mercla(c1,c2:crgba;r:single):crgba;
var e:single;
begin
 e:=(c1[0]/255)*r+(c2[0]/255)*(1-r);if e>1 then e:=1;result[0]:=round(e*255);
 e:=(c1[1]/255)*r+(c2[1]/255)*(1-r);if e>1 then e:=1;result[1]:=round(e*255);
 e:=(c1[2]/255)*r+(c2[2]/255)*(1-r);if e>1 then e:=1;result[2]:=round(e*255);
 e:=(c1[3]/255)*r+(c2[3]/255)*(1-r);if e>1 then e:=1;result[3]:=round(e*255);
end;
function mixcl(c1,c2:crgba;r:single):crgba;
var e:single;
begin
 e:=(c1[0]/255)*(1-r)+(c2[0]/255)*r;if e>1 then e:=1;result[0]:=round(e*255);
 e:=(c1[1]/255)*(1-r)+(c2[1]/255)*r;if e>1 then e:=1;result[1]:=round(e*255);
 e:=(c1[2]/255)*(1-r)+(c2[2]/255)*r;if e>1 then e:=1;result[2]:=round(e*255);
 result[3]:=255;
end;
function subcl(c1,c2:crgba):crgba;
begin
 result[0]:=(c1[0]-c2[0]);
 result[1]:=(c1[1]-c2[1]);
 result[2]:=(c1[2]-c2[2]);
 result[3]:=255;
end;
function addcl(c1,c2:crgba):crgba;
begin
 result[0]:=(c1[0]+c2[0]);
 result[1]:=(c1[1]+c2[1]);
 result[2]:=(c1[2]+c2[2]);
 result[3]:=255;
end;
function addcla(c1,c2:crgba):crgba;
begin
 result[0]:=(c1[0]+c2[0]);
 result[1]:=(c1[1]+c2[1]);
 result[2]:=(c1[2]+c2[2]);
 result[3]:=(c1[3]+c2[3]);
end;
function nmulcl(c1:crgba;n:single):crgba;
var k:single;
begin
 k:=c1[0]*n;if k>255 then k:=255;result[0]:=round(k);
 k:=c1[1]*n;if k>255 then k:=255;result[1]:=round(k);
 k:=c1[2]*n;if k>255 then k:=255;result[2]:=round(k);
 result[3]:=255;
end;
function nmulcla(c1:crgba;n:single):crgba;
var k:single;
begin
 k:=c1[0]*n;if k>255 then k:=255;result[0]:=round(k);
 k:=c1[1]*n;if k>255 then k:=255;result[1]:=round(k);
 k:=c1[2]*n;if k>255 then k:=255;result[2]:=round(k);
 k:=c1[3]*n;if k>255 then k:=255;result[3]:=round(k);
end;
function subcld(c1,c2:crgba):crgbad;
begin
 result[0]:=(c1[0]-c2[0])/255;
 result[1]:=(c1[1]-c2[1])/255;
 result[2]:=(c1[2]-c2[2])/255;
 result[3]:=255;
end;
function addcld(c1,c2:crgba):crgbad;
begin
 result[0]:=(c1[0]+c2[0])/255;
 result[1]:=(c1[1]+c2[1])/255;
 result[2]:=(c1[2]+c2[2])/255;
 result[3]:=1;
end;
function nmulcld(c1:crgba;n:single):crgbad;
begin
 result[0]:=c1[0]*n/255;
 result[1]:=c1[1]*n/255;
 result[2]:=c1[2]*n/255;
 result[3]:=1;
end;


function dw2crgb(a:longword):crgb;
begin
 result[0]:=a and $FF;
 result[1]:=(a shr 8) and $FF;
 result[2]:=(a shr 16) and $FF;
end;
function dw2crgba(a:longword):crgba;
begin
 result[0]:=a and $FF;
 result[1]:=(a shr 8) and $FF;
 result[2]:=(a shr 16) and $FF;
 result[3]:=(a shr 24) and $FF;
end;
//function crgb2dw(a:crgb):longword; begin result:=0; end;
//function crgba2dw(a:crgba):longword; begin result:=0; end;
function bchcrgba(c:boolean;t,f:crgba):crgba;begin if c then result:=t else result:=f;end;
//############################################################################//
procedure set_spr(var spr:typspr;ip:pointer;wid,hei:integer);
begin
 spr.srf:=ip;
 spr.tp:=1;
 spr.xs:=wid;
 spr.ys:=hei;
 spr.cx:=wid div 2;
 spr.cy:=hei div 2;
 spr.tx:=notx;
end;
//############################################################################//
//Get sprite from memory
function genspr_mem(ip:pointer;wid,hei:integer):ptypspr;
begin
 new(result);
 set_spr(result^,ip,wid,hei);
end;
//############################################################################//
//Get sprite from memory copy
function genspr8_memcpy(ip:pointer;wid,hei:integer):ptypspr;
var p:pointer;
begin
 getmem(p,wid*hei);
 move(ip^,p^,wid*hei);
 new(result);
 set_spr(result^,p,wid,hei);
end;
//############################################################################//
//Get sprite from memory copy
function genspr32_memcpy(ip:pointer;wid,hei:integer):ptypspr;
var p:pointer;
begin
 getmem(p,wid*hei*4);
 move(ip^,p^,wid*hei*4);
 new(result);
 set_spr(result^,p,wid,hei);
end;
//############################################################################//
function genspr_blank(wid,hei,bits:integer):ptypspr;
var p:pointer;
begin
 new(result);
 getmem(p,wid*hei*(bits div 8));
 set_spr(result^,p,wid,hei);
 result.bits:=bits;
end;
//############################################################################//
function spr_to_srf(xs,ys:integer;p:pbcrgba):ptypspr;
var x,y:integer;
c:crgba;
begin
 result:=genspr_mem(nil,xs,ys);

 getmem(result.srf,xs*ys*4);
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  c:=p[x+y*xs];
  pbcrgba(result.srf)[x+y*xs]:=tcrgba(c[0],c[1],c[2],c[3]);
 end;
end;
//############################################################################//
function in_image_with_border(im:ptypspr;const pos:ivec2;border:integer):boolean;
begin
 result:=inrect_eq(pos.x,pos.y,border,border,im.xs-border,im.ys-border);
end;
//############################################################################//
function in_image_with_border_xs(xs,ys:integer;const pos:ivec2;border:integer):boolean;
begin
 result:=inrect_eq(pos.x,pos.y,border,border,xs-border,ys-border);
end;
//############################################################################//
begin
end.
//############################################################################//


