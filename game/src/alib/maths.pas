//############################################################################//
// AlgorLib: Maths
// Made in 2002-2016 by Artyom Litvinovich
//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit maths;
interface
uses math,asys;
//############################################################################//
const
cconst:double=299792458;
hconst:double=6.626068e-34;
Gconst:double=6.67259e-11;
kconst:double=1.381e-23;
econst:double=2.718281828459045235360287471352;

le= 9460800000000000.0;
lef:double=946080000;
lec:double=0.0000001;
eps:double=0.00001;
au :double=1.49597870691e11;
parsec:double=3.0858e16;

half_pi=pi/2;
sqrt2=1.4142135623730950488016887242097;
trad=1/180*pi;

{$ifndef paser}
FLT_EPSILON=2.2204460492503131e-16;
FLT_MAX=MaxDouble;
{$else}
FLT_EPSILON=0.0000001;
FLT_MAX=1000000000000000;
{$endif}

type vec2 =record x,y:double;end;
type mvec2=record x,y:single;end;
type ivec2=record x,y:integer;end;
type qvec2=record x,y:int64;end;
type vec  =record x,y,z:double;end;
type mvec =record x,y,z:single;end;
type ivec =record x,y,z:integer;end;
type qvec =record x,y,z:int64;end;
type quat =record x,y,z,w:double;end;
type mquat=record x,y,z,w:single;end;
type iquat=record x,y,z,w:integer;end;
type qvec4=record x,y,z,w:int64;end;
type vec5 =record x,y,z,w,t:double;end;
type mvec5=record x,y,z,w,t:single;end;
type ivec5=record x,y,z,w,t:integer;end;
type qvec5=record x,y,z,w,t:int64;end;
pvec2=^vec2;pmvec2=^mvec2;pivec2=^ivec2;pqvec2=^qvec2;
pvec =^vec; pmvec= ^mvec; pivec= ^ivec; pqvec= ^qvec;
pquat=^quat;pmquat=^mquat;piquat=^iquat;pqvec4=^qvec4;
pvec5=^vec5;pmvec5=^mvec5;pivec5=^ivec5;pqvec5=^qvec5;
vec2ar=array[0..100000]of vec2;pvec2ar=^vec2ar;
ivec2ar=array[0..100000]of ivec2;pivec2ar=^ivec2ar;
qvec2ar=array[0..100000]of qvec2;pqvec2ar=^qvec2ar;
vecar=array[0..100000]of vec;pvecar=^vecar;
mvecar=array[0..100000]of mvec;pmvecar=^mvecar;
quatar=array[0..100000]of quat;pquatar=^quatar;
mquatar=array[0..100000]of mquat;pmquatar=^mquatar;
{$ifndef paser}
aovec2 =array of vec2;
aomvec2=array of mvec2;
aoivec2=array of ivec2;
aoqvec2=array of qvec2;
aovec  =array of vec;
aomvec =array of mvec;
aoivec =array of ivec;
aoqvec =array of qvec;
aoquat =array of quat;
aomquat=array of mquat;
aoiquat=array of iquat;
aoqvec4=array of qvec4;
aovec5 =array of vec5;
aomvec5=array of mvec5;
aoivec5=array of ivec5;
aoqvec5=array of qvec5;
paovec2=^aovec2;
paoivec2=^aoivec2;
{$endif}
ivec2a =array[0..1] of integer;
vec2a =array[0..1] of double;
mvec2a=array[0..1] of single;
veca  =array[0..2] of double;
mveca =array[0..2] of single;
quata =array[0..3] of double;
mquata=array[0..3] of single;
vec5a =array[0..4] of double;
mvec5a=array[0..4] of single;
vec6  =array[0..5] of double;
mvec6 =array[0..5] of single;
pveca=^veca;

mmat2 =array[0..1] of mvec2;
mmat2a=array[0..1] of mvec2a;
mat2  =array[0..1] of vec2;
mat2a =array[0..1] of vec2a;

mmat =array[0..2] of mvec;
mmata=array[0..2] of mveca;
mat  =array[0..2] of vec;
mata =array[0..2] of veca;

mmatq =array[0..3] of mquat;
mmatqa=array[0..3] of mquata;
matq  =array[0..3] of quat;
matqa =array[0..3] of quata;

mat5  =array[0..4] of vec5;
mat5a =array[0..4] of vec5a;
mmat5 =array[0..4] of mvec5;
mmat5a=array[0..4] of mvec5a;

mat6=array[0..5]of vec6;
mmat6=array[0..5]of mvec6;

pmat2=^mat2;pmat2a=^mat2a;
pmat =^mat; pmata =^mata;
pmatq=^matq;pmatqa=^matqa;
pmmatq=^mmatq;pmmatqa=^mmatqa;
pmat5=^mat5;pmat5a=^mat5a;
matn =array[0..8] of double;
{$ifndef paser}matint=array of array of int32;{$endif}

const
zvec2:vec2=(x:0;y:0);
zivec2:ivec2=(x:0;y:0);
zvec:vec=(x:0;y:0;z:0);
zquat:quat=(x:0;y:0;z:0;w:0);
evec:vec=(x:1;y:1;z:1);
equat:quat=(x:0;y:0;z:0;w:1);
zvec5:vec5=(x:0;y:0;z:0;w:0;t:0);
zvec6:vec6=(0,0,0,0,0,0);

zmvec2:mvec2=(x:0;y:0);
zmvec:mvec=(x:0;y:0;z:0);
zmquat:mquat=(x:0;y:0;z:0;w:0);
emvec:mvec=(x:1;y:1;z:1);

emat2:mat2=((x:1;y:0),(x:0;y:1));
zmat2:mat2=((x:0;y:0),(x:0;y:0));
emmat2:mmat2=((x:1;y:0),(x:0;y:1));
zmmat2:mmat2=((x:0;y:0),(x:0;y:0));

emat:mat=((x:1;y:0;z:0),(x:0;y:1;z:0),(x:0;y:0;z:1));
zmat:mat=((x:0;y:0;z:0),(x:0;y:0;z:0),(x:0;y:0;z:0));
emmat:mmat=((x:1;y:0;z:0),(x:0;y:1;z:0),(x:0;y:0;z:1));
zmmat:mmat=((x:0;y:0;z:0),(x:0;y:0;z:0),(x:0;y:0;z:0));

ematq:matq=((x:1;y:0;z:0;w:0),(x:0;y:1;z:0;w:0),(x:0;y:0;z:1;w:0),(x:0;y:0;z:0;w:1));
zmatq:matq=((x:0;y:0;z:0;w:0),(x:0;y:0;z:0;w:0),(x:0;y:0;z:0;w:0),(x:0;y:0;z:0;w:0));
emmatq:mmatq=((x:1;y:0;z:0;w:0),(x:0;y:1;z:0;w:0),(x:0;y:0;z:1;w:0),(x:0;y:0;z:0;w:1));
zmmatq:mmatq=((x:0;y:0;z:0;w:0),(x:0;y:0;z:0;w:0),(x:0;y:0;z:0;w:0),(x:0;y:0;z:0;w:0));

emat5:mat5=((x:1;y:0;z:0;w:0;t:0),(x:0;y:1;z:0;w:0;t:0),(x:0;y:0;z:1;w:0;t:0),(x:0;y:0;z:0;w:1;t:0),(x:0;y:0;z:0;w:0;t:1));  //Equal to emat5z:mat5;
zmat5:mat5=((x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0));
emmat5:mmat5=((x:1;y:0;z:0;w:0;t:0),(x:0;y:1;z:0;w:0;t:0),(x:0;y:0;z:1;w:0;t:0),(x:0;y:0;z:0;w:1;t:0),(x:0;y:0;z:0;w:0;t:1));
zmmat5:mmat5=((x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0),(x:0;y:0;z:0;w:0;t:0));
//############################################################################//
//############################################################################//
function flt_valid(f:double):boolean;
function sround(d:double):integer;overload;
//function sround(d:single):integer;overload;
//############################################################################//
function fclamp(const a,low,high:double):double;
function fmod(x,y:double):double;

function iclamp(const a,low,high:integer):integer;

function inrect_eq(x,y,x1,y1,x2,y2:integer):boolean;
function inrect(x,y,x1,y1,x2,y2:integer):boolean;
function inrects(x,y,x1,y1,xs,ys:integer):boolean;
function inbox(p,bh,bl:vec):boolean;
function inboxs(p,cnt,siz:mvec):boolean;
function incube(p,b:vec;s:double):boolean;

function nbool(b:boolean):integer;
function zchk(n:double):double;

procedure swapd(var a,b:double);
procedure swapi(var a,b:integer);

function max2(const a,b:double):double;
function max2i(const a,b:integer):integer;
function max2q(const a,b:int64):int64;
function min2(const a,b:double):double;
function min2i(const a,b:integer):integer;
function min2q(const a,b:int64):int64;
function max3(a,b,c:double):double;
function max3i(a,b,c:integer):integer;
function min3(a,b,c:double):double;
function min3i(a,b,c:integer):integer;
function min6(a,b,c,d,e,f:double):double;
function min6n(a,b,c,d,e,f:double):integer;
function deg2rad(dg:double):double;
function hitrunc(par:double):integer;
function getrtang(pmx,pmy,wx,wy:double):double;
function pow(a,x:double):double;
function is_pot(x:integer):boolean;
function upround_pot(x:integer):integer;
function powi(a,x:double):integer;
function sgn(a:double):integer;
function sgna(a:integer):integer;
function arctan2(y,x:real):real;
function arctan21(sy,cy:real):real;
function angnmr(ang:double):double;
function cntfrac(v:double;limit:integer):dword;
//############################################################################//
function vec_valid(const v:vec2):boolean;overload;
function vec_valid(const v:vec):boolean; overload;

function tivec2(x,y:integer):ivec2;
function tivec (x,y,z:integer):ivec;
function tiquat(x,y,z,w:integer):iquat;

function tqvec2(x,y:int64):qvec2;
function tqvec (x,y,z:int64):qvec;
function tqvec4(x,y,z,w:int64):qvec4;

function tvec2(x,y:double):vec2;
function tvec (x,y,z:double):vec;
function tquat(x,y,z,w:double):quat;
function tvec5(x,y,z,w,t:double):vec5;
function tvec2a(x,y:double):vec2a;
function tveca (x,y,z:double):veca;
function tquata(x,y,z,w:double):quata;
function tvec5a(x,y,z,w,t:double):vec5a;
function tmvec2(x,y:single):mvec2;
function tmvec (x,y,z:single):mvec;
function tmquat(x,y,z,w:single):mquat;
function tmvec5(x,y,z,w,t:single):mvec5;
function tmvec2a(x,y:single):mvec2a;
function tmveca (x,y,z:single):mveca;
function tmquata(x,y,z,w:single):mquata;
function tmvec5a(x,y,z,w,t:single):mvec5a;

function tvec6(a,b,c,d,e,f:double):vec6;
function tmvec6(a,b,c,d,e,f:single):mvec6;

function v2m(const v:vec2):mvec2;overload;
function v2m(const v:vec ):mvec ;overload;
function v2q(const v:vec ):qvec ;overload;
function q2m(const v:qvec):mvec ;overload;
function q2v(const v:qvec):vec  ;overload;
function v2m(const v:quat):mquat;overload;
function v2m(const v:vec5):mvec5;overload;
function m2v(const v:mvec2):vec2;overload;
function m2v(const v:mvec ):vec ;overload;
function m2v(const v:mquat):quat;overload;
function m2v(const v:mvec5):vec5;overload;

function vi2d(const v:ivec2):vec2;
function vd2i(const v:vec2):ivec2;

function v3v2(const v:vec):vec2;
function v2v3(const v:vec2;z:double):vec;

function v4v3(const v:quat):vec;  overload;
function v4v3(const v:mquat):mvec;overload;
function v3v4(const v:vec;w:double):quat;overload;
function v3v4(const v:mvec;w:single):mquat;overload;

function project_v3v2  (const v:vec):vec2;
function unproject_v2v3(const v:vec2):vec;

function vec_skew(const v:vec2):vec2;

function modv (const v:ivec2):double;overload;
function modv (const v:vec2):double;overload;
function modv (const v:vec ):double;overload;
function modv (const v:quat):double;overload;
function modv (const v:vec5):double;overload;
function modv (const v:mvec2):double;overload;
function modv (const v:mvec ):double;overload;
function modv (const v:mquat):double;overload;
function modv (const v:mvec5):double;overload;

function modvs(const v:ivec2):double;overload;
function modvs(const v:vec2):double;overload;
function modvs(const v:vec ):double;overload;
function modvs(const v:quat):double;overload;
function modvs(const v:vec5):double;overload;
function modvs(const v:mvec2):double;overload;
function modvs(const v:mvec ):double;overload;
function modvs(const v:mquat):double;overload;
function modvs(const v:mvec5):double;overload;

function nrvec(const v:vec2):vec2;overload;
function nrvec(const v:vec ):vec ;overload;
function nrvec(const v:quat):quat;overload;
function nrvec(const v:vec5):vec5;overload;
function nrvec(const v:mvec2):mvec2;overload;
function nrvec(const v:mvec ):mvec ;overload;
function nrvec(const v:mquat):mquat;overload;
function nrvec(const v:mvec5):mvec5;overload;

function vcmp (const v1,v2:ivec2):boolean;overload;
function vcmp (const v1,v2:vec2):boolean;overload;
function vcmp (const v1,v2:vec ):boolean;overload;
function vcmp (const v1,v2:qvec):boolean;overload;
function vcmp (const v1,v2:quat):boolean;overload;
function vcmp (const v1,v2:vec5):boolean;overload;
function vcmp (const v1,v2:mvec2):boolean;overload;
function vcmp (const v1,v2:mvec ):boolean;overload;

function vdst (const v1,v2:vec2):double;overload;
function vdst (const v1,v2:vec ):double;overload;
function vdst (const v1,v2:qvec):qword; overload;
function vdst (const v1,v2:quat):double;overload;
function vdst (const v1,v2:vec5):double;overload;
function vdst (const v1,v2:mvec2):single;overload;
function vdst (const v1,v2:mvec):single; overload;

function vdsts(const v1,v2:ivec2):integer;overload;
function vdsts(const v1,v2:vec2):double;overload;
function vdsts(const v1,v2:vec ):double;overload;
function vdsts(const v1,v2:quat):double;overload;
function vdsts(const v1,v2:vec5):double;overload;
function vdsts(const v1,v2:mvec2):single;overload;
function vdsts(const v1,v2:mvec ):single;overload;

function vcollin(const v1,v2,v3:vec):boolean;overload;
function vcollin(const v1,v2,v3:mvec):boolean;overload;
function vcoplan(const v1,v2,v3,v4:vec):boolean;overload;
function vcoplan(const v1,v2,v3,v4:mvec):boolean;overload;

function vmid2(const v1,v2:vec2):vec2;overload;
function vmid2(const v1,v2:vec ):vec ;overload;
function vmid2(const v1,v2:quat):quat;overload;
function vmid2(const v1,v2:vec5):vec5;overload;
function vmid2(const v1,v2:mvec2):mvec2;overload;

function vmid3(const v1,v2,v3:vec2):vec2;overload;
function vmid3(const v1,v2,v3:vec ):vec ;overload;
function vmid3(const v1,v2,v3:quat):quat;overload;
function vmid3(const v1,v2,v3:vec5):vec5;overload;
function vmid4(const v1,v2,v3,v4:vec2):vec2;overload;
function vmid4(const v1,v2,v3,v4:vec ):vec ;overload;
function vmid4(const v1,v2,v3,v4:quat):quat;overload;
function vmid4(const v1,v2,v3,v4:vec5):vec5;overload;
function vmid5(const v1,v2,v3,v4,v5:vec2):vec2;overload;
function vmid5(const v1,v2,v3,v4,v5:vec ):vec ;overload;
function vmid5(const v1,v2,v3,v4,v5:quat):quat;overload;
function vmid5(const v1,v2,v3,v4,v5:vec5):vec5;overload;

function vmulv(const v1,v2:vec2):double;overload;
function vmulv(const v1,v2:vec ):vec ;overload;
function vmulv(const v1,v2:quat):quat;overload;
function vmulv(const v1,v2:mvec2):single;overload;
function vmulv(const v1,v2:mvec ):mvec ;overload;
function vmulv(const v1,v2:mquat):mquat;overload;

function smulv(const v1,v2:vec2):double;overload;
function smulv(const v1,v2:vec ):double;overload;
function smulv(const v1,v2:quat):double;overload;
function smulv(const v1,v2:vec5):double;overload;
function smulv(const v1,v2:mvec2):double;overload;
function smulv(const v1,v2:mvec ):double;overload;
function smulv(const v1,v2:mquat):double;overload;
function smulv(const v1,v2:mvec5):double;overload;

function smulv_xvec(a,b:pdoublea;n:integer):double;

function omulv(const a,b:vec ):mat;overload;
function omulv(const a,b:vec6):mat6;overload;

function nmulv(const v:vec2;a:double):vec2;overload;
function nmulv(const v:ivec2;a:integer):ivec2;overload;
function nmulv(const v:vec ;a:double):vec ;overload;
function nmulv(const v:qvec;a:qword ):qvec;overload;
function nmulv(const v:quat;a:double):quat;overload;
function nmulv(const v:vec5;a:double):vec5;overload;
function nmulv(const v:mvec2;a:double):mvec2;overload;
function nmulv(const v:mvec ;a:double):mvec ;overload;
function nmulv(const v:mquat;a:double):mquat;overload;
function nmulv(const v:mvec5;a:double):mvec5;overload;
function nmulv(const a:vec6;const n:double):vec6;overload;
function nmulv(const a:mvec6;const n:single):mvec6;overload;

function addv (const v1,v2:ivec2):ivec2;overload;
function addv (const v1,v2:vec2):vec2;overload;
function addv (const v1,v2:vec ):vec ;overload;
function addv (const v1,v2:qvec):qvec;overload;
function addv (const v1,v2:quat):quat;overload;
function addv (const v1,v2:vec5):vec5;overload;
function addv (const v1,v2:mvec2):mvec2;overload;
function addv (const v1,v2:mvec ):mvec ;overload;
function addv (const v1,v2:mquat):mquat;overload;
function addv (const v1,v2:mvec5):mvec5;overload;
function addv (const a,b:vec6):vec6;overload;
function addv (const a,b:mvec6):mvec6;overload;

function subv (const v1,v2:ivec2):ivec2;overload;
function subv (const v1,v2:vec2):vec2;overload;
function subv (const v1,v2:vec ):vec ;overload;
function subv (const v1,v2:qvec):qvec;overload;
function subv (const v1,v2:quat):quat;overload;
function subv (const v1,v2:vec5):vec5;overload;
function subv (const v1,v2:mvec2):mvec2;overload;
function subv (const v1,v2:mvec ):mvec ;overload;
function subv (const v1,v2:mquat):mquat;overload;
function subv (const v1,v2:mvec5):mvec5;overload;
function subv (const a,b:vec6):vec6;overload;
function subv (const a,b:mvec6):mvec6;overload;

function lerpv(v1,v2:vec2 ;a:double):vec2;overload;
function lerpv(v1,v2:vec;a:double):vec;overload;
function lerpv(v1,v2:mvec2;a:single):mvec2;overload;
function lerpv(v1,v2:mvec;a:single):mvec;overload;

function addv (const v1,v2:ivec):ivec;overload;
function subv (const v1,v2:ivec):ivec;overload;
function vmulv(const v1,v2:ivec):ivec;overload;
function smulv(const v1,v2:ivec):integer;overload;
function nmulv(const v:ivec ;a:double):ivec  ;overload;
function nmulv(const v:ivec ;a:integer):ivec ;overload;
function ndivv(const v:ivec ;a:integer):ivec;overload;
function ndivv(const v:ivec2;a:integer):ivec2;overload;


function addv(const v1:vec;v2:veca):vec;overload;
function subv(const v1:vec;v2:veca):vec;overload;

function perpv(const v1,v2:vec):vec;overload;
function perpv(const v1,v2:mvec):mvec;overload;

function lmulv(const v1,v2:vec2):vec2;overload;
function lmulv(const v1,v2:vec ):vec ;overload;
function lmulv(const v1,v2:quat):quat;overload;
function lmulv(const v1,v2:vec5):vec5;overload;
function lmulv(const v1,v2:mvec2):mvec2;overload;
function lmulv(const v1,v2:mvec ):mvec ;overload;
function lmulv(const v1,v2:mquat):mquat;overload;
function lmulv(const v1,v2:mvec5):mvec5;overload;

function ldivv(const v1,v2:vec2):vec2;overload;
function ldivv(const v1,v2:vec ):vec ;overload;
function ldivv(const v1,v2:quat):quat;overload;
function ldivv(const v1,v2:vec5):vec5;overload;
function ldivv(const v1,v2:mvec ):mvec ;overload;

function naddv(v1:vec2;a:double):vec2;overload;
function naddv(v1:vec ;a:double):vec ;overload;
function naddv(v1:quat;a:double):quat;overload;
function naddv(v1:vec5;a:double):vec5;overload;
function nsubv(v1:vec2;a:double):vec2;overload;
function nsubv(v1:vec ;a:double):vec ;overload;
function nsubv(v1:quat;a:double):quat;overload;
function nsubv(v1:vec5;a:double):vec5;overload;

procedure vrot(var v:vec2;e:double);overload;
procedure vrotz(var v:vec;e:double);overload;
procedure vroty(var v:vec;e:double);overload;
procedure vrotx(var v:vec;e:double);overload;
function  vrotf(const v:vec2;e:double):vec2;overload;
function  vrotzf(const v:vec;e:double):vec;overload;
function  vrotyf(const v:vec;e:double):vec;overload;
function  vrotxf(const v:vec;e:double):vec;overload;

procedure vrot(var v:mvec2;e:double);overload;
procedure vrotz(var v:mvec;e:double);overload;
procedure vroty(var v:mvec;e:double);overload;
procedure vrotx(var v:mvec;e:double);overload;
function  vrotf(const v:mvec2;e:double):mvec2;overload;
function  vrotzf(const v:mvec;e:double):mvec;overload;
function  vrotyf(const v:mvec;e:double):mvec;overload;
function  vrotxf(const v:mvec;e:double):mvec;overload;

procedure vrotix(var v:ivec;e:double);

function trr2l(const v:vec ):vec; overload;
function trr2l(const v:mvec):mvec;overload;

procedure gvec(var x:double;var y:double;var z:double;a:vec);
procedure vreps(var v:vec;e:double);

function vec34(a:vec):quat;
function vec32(a:vec):vec2;
function vec23(a:vec2):vec;
procedure vscale(var v:vec;a,b,c:double);
//############################################################################//
function tmat(a1,a2,a3,b1,b2,b3,c1,c2,c3:double):mat;

function m2v(const v:mmat):mat;overload;
function v2m(const v:mat):mmat;overload;

function matq2mmatq(const a:matq):mmatq;
function mat2matq(const a:mat):matq;
function epsmat(const a:mat):mat;

function rvmat(const b:vec2;const a:mat2):vec2; overload;
function rvmat(const b:vec;const a:mat):vec; overload;
function rvmat(const b:vec;const a:matq):vec;overload;
function rvmat(const b:mvec;const a:matq):mvec;overload;
function rvmat(const b:quat;const a:mat5):quat;overload;
function rvmat(const b:mvec;const a:mat):mvec; overload;
function rvmat(const b:quat;const a:matq):quat;overload;
function rvmat(const b:mquat;const a:matq):mquat;overload;
function rvmat(const b:mquat;const a:mmatq):mquat;overload;

function lvmat(const a:mat2;const b:vec2):vec2;overload;
function lvmat(const a:mat;const b:vec):vec; overload;
function lvmat(const a:mat;const b:vec2):vec2;overload;
function lvmat(const a:matq;const b:vec):vec;overload;
function lvmat(const a:mat5;const b:quat):quat;overload;
function lvmat(const a:mat;const b:mvec):mvec; overload;
function lvmat(const a:mmat;const b:mvec):mvec; overload;
function lvmat(const a:matq;const b:mvec):mvec;overload;
function lvmat(const a:mmatq;const b:mvec):mvec;overload;
function lvmat(const a:matq;const b:quat):quat;overload;
function lvmat(const a:matq;const b:mquat):mquat;overload;
function lvmat(const a:mmatq;const b:mquat):mquat;overload;

function nmulmat(const tm:mat2;a:double):mat2;overload;
function nmulmat(const tm:mat;a:double):mat;  overload;
function nmulmat(const tm:matq;a:double):matq;overload;

function atmat(const a:vec):mat;
function atmatz(const a:vec):mat;
function tamat(const a:mat):vec;
function tamatz(const a:mat):vec;

function addmat(const a,b:mat):mat;overload;
function addmat(const a,b:mat6):mat6;overload;

function mulm(const a,b:mat):mat;overload;
function mulm(const a,b:mmat):mmat;overload;
function mulm(const a,b:matq):matq;overload;
function mulm(const a,b:mmatq):mmatq;overload;
function mulm(const a,b:mat5):mat5;overload;
procedure rtmatx(var a:mat;an:double);
procedure rtmaty(var a:mat;an:double);
procedure rtmatz(var a:mat;an:double);
function vecs2mat (const fwd,up:vec):mat;
function vecs2matz(const fwd,up:vec):mat;
function v2vrotmat(const v1,v2:vec):mat;

function matq_get_translation(const m:matq):vec;
function matq_get_rotation(const m:matq):mat;
function mat_get_translation(const m:mat):vec2;
function mat_get_rotation(const m:mat):mat2;

function create_rot_mat_by_axis_angle(const axis:vec;angle:double):mat;
function create_rot_mat_by_axis_cos(const axis:mvec;c:single):mat;

function rotate_vec_axis_angle(const v: vec;const axis:vec;angle:double): vec; overload;
function rotate_vec_axis_angle(const v:mvec;const axis:vec;angle:double):mvec; overload;
function rotate_vec_axis_cos  (const v,axis:mvec;ca:single):mvec;

function quat2rotm(const q:quat):mat;
function quat2orotm(const q:quat):mat;
function rotm2quat(a:mat):quat;
function rotm2quatz(a:mat):quat;

function trquat(x,y,z:double):quat;
function vtrquat(a:vec):quat;
procedure quat_to_axis_angle(q:quat;out v:vec;out ang:double);
function qrot(iv:vec;iq:quat):vec;
function qunrot(iv:vec;iq:quat):vec;
function qrotvec(v:vec;q:quat):vec;
function qunrotvec(v:vec;q:quat):vec;
function qmul(q1,q2:quat):quat;
function qinv(q:quat):quat;
//############################################################################//
implementation
//############################################################################//
function flt_valid(f:double):boolean;begin result:=not (IsNan(f) or IsInfinite(f));end;
//############################################################################//
function sround(d:double):integer;overload;begin if abs(frac(d))-0.5<eps then result:=round(d+0.1)else result:=round(d);end;
//function sround(d:single):integer;overload;begin if abs(frac(d))-0.5<eps then result:=round(d+0.1)else result:=round(d);end;
//############################################################################//
function fclamp(const a,low,high:double):double;
begin
 if a<low then result:=low
 else if a>high then result:=high
 else result:=a;
end;
//############################################################################//
function fmod(x,y:double):double;begin result:=frac(x/y)*y;end;
//############################################################################//
function iclamp(const a,low,high:integer):integer;
begin
 if a<low then result:=low
 else if a>high then result:=high
 else result:=a;
end;
//############################################################################//
function inrect_eq(x,y,x1,y1,x2,y2:integer):boolean;begin result:=(x>=x1)and(x<x2)and(y>=y1)and(y<y2);end;
function inrect   (x,y,x1,y1,x2,y2:integer):boolean;begin result:=(x>=x1)and(x<=x2)and(y>=y1)and(y<=y2);end;
function inrects  (x,y,x1,y1,xs,ys:integer):boolean;begin result:=(x>=x1)and(x<=x1+xs)and(y>=y1)and(y<=y1+ys);end;
function inbox(p,bh,bl:vec):boolean;begin result:=false; if(p.x>=bh.x)and(p.x<=bl.x)and(p.y>=bh.y)and(p.y<=bl.y)and(p.z>=bh.z)and(p.z<=bl.z)then result:=true;end;
function inboxs(p,cnt,siz:mvec):boolean;begin result:=false; if(p.x>=cnt.x-siz.x/2)and(p.x<=cnt.x+siz.x/2)and(p.y>=cnt.y-siz.y/2)and(p.y<=cnt.y+siz.y/2)and(p.z>=cnt.z-siz.z/2)and(p.z<=cnt.z+siz.z/2)then result:=true;end;
function incube(p,b:vec;s:double):boolean;begin result:=(p.x>=b.x-s)and(p.x<b.x+s)and(p.y>=b.y-s)and(p.y<b.y+s)and(p.z>=b.z-s)and(p.z<b.z+s);end;
function nbool(b:boolean):integer;begin result:=ord(b)*2-1;end;
function zchk(n:double):double;begin if abs(n)<eps then result:=eps else result:=n;end;
//############################################################################//
procedure swapd(var a,b:double);var c:double;begin  c:=a;a:=b;b:=c;end;
procedure swapi(var a,b:integer);var c:integer;begin  c:=a;a:=b;b:=c;end;
//############################################################################//
function max2(const a,b:double):double;begin if a>b then result:=a else result:=b;end;
function max2i(const a,b:integer):integer;begin if a>b then result:=a else result:=b;end;
function max2q(const a,b:int64):int64;begin if a>b then result:=a else result:=b;end;
function min2(const a,b:double):double;begin if a<b then result:=a else result:=b;end;
function min2i(const a,b:integer):integer;begin if a<b then result:=a else result:=b;end;
function min2q(const a,b:int64):int64;begin if a<b then result:=a else result:=b;end;
function max3(a,b,c:double):double;begin if a>b then result:=a else result:=b; if c>result then result:=c;end;
function max3i(a,b,c:integer):integer;begin if a>b then result:=a else result:=b; if c>result then result:=c;end;
function min3(a,b,c:double):double;begin if a<b then result:=a else result:=b; if c<result then result:=c;end;
function min3i(a,b,c:integer):integer;begin if a<b then result:=a else result:=b; if c<result then result:=c;end;
function min6(a,b,c,d,e,f:double):double;
begin
 if a<b then result:=a else result:=b;
 if c<result then result:=c;
 if d<result then result:=d;
 if e<result then result:=e;
 if f<result then result:=f;
end;
function min6n(a,b,c,d,e,f:double):integer;
var mi:double;
begin
 if a<b then begin result:=0; mi:=a; end else begin result:=1; mi:=b; end;
 if c<mi then begin result:=2; mi:=c; end;
 if d<mi then begin result:=3; mi:=d; end;
 if e<mi then begin result:=4; mi:=e; end;
 if f<mi then begin result:=5; end;//mi:=f; end;
end;
//############################################################################//
function deg2rad(dg:double):double;begin result:=(dg*pi)/180;end;
function hitrunc(par:double):integer;var st:integer;begin st:=trunc(par); if frac(par)>0 then st:=st+1; result:=st;end;
//############################################################################//
function getrtang(pmx,pmy,wx,wy:double):double;
var dx,dy:double;
begin
 result:=0;
 if(pmx=wx)and(pmy=wy)then result:=0;
 if(pmx=wx)and(pmy>wy)then result:=180;
 if(pmx=wx)and(pmy<wy)then result:=0;
 if(pmx<wx)and(pmy=wy)then result:=270;
 if(pmx>wx)and(pmy=wy)then result:=90;
 if(pmx>wx)and(pmy<wy)then begin
  dx:=pmx-wx;
  dy:=wy-pmy;
  result:=arctan(dx/dy)*180/pi;
 end;
 if(pmx>wx)and(pmy>wy)then begin
  dx:=pmx-wx;
  dy:=pmy-wy;
  result:=90+arctan(dy/dx)*180/pi;
 end;
 if(pmx<wx)and(pmy>wy)then begin
  dx:=wx-pmx;
  dy:=pmy-wy;
  result:=180+arctan(dx/dy)*180/pi;
 end;
 if(pmx<wx)and(pmy<wy)then begin
  dx:=wx-pmx;
  dy:=wy-pmy;
  result:=270+arctan(dy/dx)*180/pi;
 end;
end;
//############################################################################//
function sgn(a:double):integer;begin result:=0; if a<0 then result:=-1; if a>=0 then result:=1;end;
function sgna(a:integer):integer;begin result:=0; if a<0 then result:=-1; if a>0 then result:=1;end;
function pow(a,x:double):double;var res:double;begin res:=1; if a>0 then res:=exp(x*ln(a)); result:=res;end;
function powi(a,x:double):integer;var res:double;begin res:=1; if a>0 then res:=exp(x*ln(a)); result:=round(res);end;
function is_pot(x:integer):boolean;begin result:=(x>1)and((x and (x-1))=0);end;
function angnmr(ang:double):double;begin result:=ang-(int(ang/(2*pi))*2*pi);end;
//############################################################################//
function upround_pot(x:integer):integer;
begin
 result:=x;
 if(x>2)and(x<4)then result:=4;
 if(x>4)and(x<8)then result:=8;
 if(x>8)and(x<16)then result:=16;
 if(x>16)and(x<32)then result:=32;
 if(x>32)and(x<64)then result:=64;
 if(x>64)and(x<128)then result:=128;
 if(x>128)and(x<256)then result:=256;
 if(x>256)and(x<512)then result:=512;
 if(x>512)and(x<1024)then result:=1024;
 if(x>1024)and(x<2048)then result:=2048;
 if(x>2048)and(x<4096)then result:=4096;
end;
//############################################################################//
function arctan2(y,x:real):real;
begin
 result:=0;
 if x=0 then begin
  if y=0 then begin end else if y>0 then result:=half_pi else result:=-half_pi
 end else begin if x>0 then result:=arctan(y/x)
 else if x<0 then begin
   if y>=0 then result:=arctan(y/x)+pi else result:=arctan(y/x)-pi
  end;
 end;
end;
//############################################################################//
function arctan21(sy,cy:real):real;
var atn:double;
begin
 result:=0;
 if cy=0.0 then begin
  if sy=0 then result:=0;
  if sy<0 then result:=3*half_pi;
  if sy>0 then result:=half_pi;
 end else {cos g is not zero} begin
  atn:=arctan(sy/cy);
  if cy<0 then atn:=atn+pi;
  if (cy>0)and(sy<0) then atn:=atn+2*pi;
  result:=atn;
 end
end;
//############################################################################//
function cntfrac(v:double;limit:integer):dword;
var k:integer;
begin
 result:=0;
 if limit>20 then limit:=20;
 if limit<0 then limit:=0;
 {$ifndef paser}try{$endif}
  v:=abs(v);
  v:=v-trunc(v);
  k:=1;
  while k<=limit do begin
   v:=v*10;
   if round(v)>=1 then result:=k;
   v:=v-trunc(v);
   //if v<eps then exit;
   k:=k+1;
  end;
 {$ifndef paser}except end;{$endif}
end;
//############################################################################//
//############################################################################//
//############################# Vector #######################################//
//############################################################################//
//############################################################################//
function vec_valid(const v:vec2):boolean;overload;begin result:=flt_valid(v.x) and flt_valid(v.y);end;
function vec_valid(const v:vec):boolean; overload;begin result:=flt_valid(v.x) and flt_valid(v.y) and flt_valid(v.z);end;

function tivec2(x,y:integer):ivec2;          begin result.x:=x;result.y:=y;end;
function tivec (x,y,z:integer):ivec;         begin result.x:=x;result.y:=y;result.z:=z;end;
function tiquat(x,y,z,w:integer):iquat;      begin result.x:=x;result.y:=y;result.z:=z;result.w:=w;end;

function tqvec2(x,y:int64):qvec2;          begin result.x:=x;result.y:=y;end;
function tqvec (x,y,z:int64):qvec;         begin result.x:=x;result.y:=y;result.z:=z;end;
function tqvec4(x,y,z,w:int64):qvec4;      begin result.x:=x;result.y:=y;result.z:=z;result.w:=w;end;

function tvec2(x,y:double):vec2;          begin result.x:=x;result.y:=y;end;
function tvec (x,y,z:double):vec;         begin result.x:=x;result.y:=y;result.z:=z;end;
function tquat(x,y,z,w:double):quat;      begin result.x:=x;result.y:=y;result.z:=z;result.w:=w;end;
function tvec5(x,y,z,w,t:double):vec5;    begin result.x:=x;result.y:=y;result.z:=z;result.w:=w;result.t:=t;end;
function tvec2a(x,y:double):vec2a;        begin result[0]:=x;result[1]:=y;end;
function tveca (x,y,z:double):veca;       begin result[0]:=x;result[1]:=y;result[2]:=z;end;
function tquata(x,y,z,w:double):quata;    begin result[0]:=x;result[1]:=y;result[2]:=z;result[3]:=w;end;
function tvec5a(x,y,z,w,t:double):vec5a;  begin result[0]:=x;result[1]:=y;result[2]:=z;result[3]:=w;result[4]:=t;end;
function tmvec2(x,y:single):mvec2;        begin result.x:=x;result.y:=y;end;
function tmvec (x,y,z:single):mvec;       begin result.x:=x;result.y:=y;result.z:=z;end;
function tmquat(x,y,z,w:single):mquat;    begin result.x:=x;result.y:=y;result.z:=z;result.w:=w;end;
function tmvec5(x,y,z,w,t:single):mvec5;  begin result.x:=x;result.y:=y;result.z:=z;result.w:=w;result.t:=t;end;
function tmvec2a(x,y:single):mvec2a;      begin result[0]:=x;result[1]:=y;end;
function tmveca (x,y,z:single):mveca;     begin result[0]:=x;result[1]:=y;result[2]:=z;end;
function tmquata(x,y,z,w:single):mquata;  begin result[0]:=x;result[1]:=y;result[2]:=z;result[3]:=w;end;
function tmvec5a(x,y,z,w,t:single):mvec5a;begin result[0]:=x;result[1]:=y;result[2]:=z;result[3]:=w;result[4]:=t;end;

function tvec6(a,b,c,d,e,f:double):vec6;  begin result[0]:=a;result[1]:=b;result[2]:=c;result[3]:=d;result[4]:=e;result[5]:=f;end;
function tmvec6(a,b,c,d,e,f:single):mvec6;begin result[0]:=a;result[1]:=b;result[2]:=c;result[3]:=d;result[4]:=e;result[5]:=f;end;

function v2m(const v:vec2):mvec2;begin result.x:=v.x;result.y:=v.y;end;
function v2m(const v:vec ):mvec ;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;end;
function v2q(const v:vec ):qvec ;begin result.x:=round(v.x);result.y:=round(v.y);result.z:=round(v.z);end;
function q2m(const v:qvec):mvec ;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;end;
function q2v(const v:qvec):vec  ;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;end;
function v2m(const v:quat):mquat;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;result.w:=v.w;end;
function v2m(const v:vec5):mvec5;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;result.w:=v.w;result.t:=v.t;end;
function m2v(const v:mvec2):vec2;begin result.x:=v.x;result.y:=v.y;end;
function m2v(const v:mvec ):vec ;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;end;
function m2v(const v:mquat):quat;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;result.w:=v.w;end;
function m2v(const v:mvec5):vec5;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;result.w:=v.w;result.t:=v.t;end;
//############################################################################//
function vi2d(const v:ivec2):vec2;begin result.x:=v.x;result.y:=v.y;end;
function vd2i(const v:vec2):ivec2;begin result.x:=round(v.x);result.y:=round(v.y);end;
//############################################################################//
function v3v2(const v:vec):vec2;begin result.x:=v.x;result.y:=v.y;end;
function v2v3(const v:vec2;z:double):vec;begin result.x:=v.x;result.y:=v.y;result.z:=z;end;
function v4v3(const v:quat):vec;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;end;
function v4v3(const v:mquat):mvec;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;end;
function v3v4(const v:vec;w:double):quat;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;result.w:=w;end;
function v3v4(const v:mvec;w:single):mquat;begin result.x:=v.x;result.y:=v.y;result.z:=v.z;result.w:=w;end;
//############################################################################//
function project_v3v2  (const v:vec):vec2;begin result.x:=v.x/v.z;result.y:=v.y/v.z; end;
function unproject_v2v3(const v:vec2):vec;begin result.x:=v.x;result.y:=v.y; result.z:=1;end;
//############################################################################//
function vec_skew(const v:vec2):vec2;begin result.x:=-v.y; result.y:=v.x;end;
//############################################################################//
function modv (const v:ivec2):double;begin result:=sqrt(sqr(v.x)+sqr(v.y));end;
function modv (const v:vec2) :double;begin result:=sqrt(sqr(v.x)+sqr(v.y));end;
function modv (const v:vec ) :double;begin result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z));end;
function modv (const v:quat) :double;begin result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w));end;
function modv (const v:vec5) :double;begin result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w)+sqr(v.t));end;
function modv (const v:mvec2):double;begin result:=sqrt(sqr(v.x)+sqr(v.y));end;
function modv (const v:mvec ):double;begin result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z));end;
function modv (const v:mquat):double;begin result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w));end;
function modv (const v:mvec5):double;begin result:=sqrt(sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w)+sqr(v.t));end;

function modvs(const v:ivec2):double;begin result:=sqr(v.x)+sqr(v.y);end;
function modvs(const v:vec2) :double;begin result:=sqr(v.x)+sqr(v.y);end;
function modvs(const v:vec ) :double;begin result:=sqr(v.x)+sqr(v.y)+sqr(v.z);end;
function modvs(const v:quat) :double;begin result:=sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w);end;
function modvs(const v:vec5) :double;begin result:=sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w)+sqr(v.t);end;
function modvs(const v:mvec2):double;begin result:=sqr(v.x)+sqr(v.y);end;
function modvs(const v:mvec ):double;begin result:=sqr(v.x)+sqr(v.y)+sqr(v.z);end;
function modvs(const v:mquat):double;begin result:=sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w);end;
function modvs(const v:mvec5):double;begin result:=sqr(v.x)+sqr(v.y)+sqr(v.z)+sqr(v.w)+sqr(v.t);end;
//############################################################################//
function nrvec(const v:vec2):vec2;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit; end;
 result.x:=v.x/md;result.y:=v.y/md;
end;
function nrvec(const v:vec):vec;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;result.z:=v.z/md;
end;
function nrvec(const v:quat):quat;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;result.z:=v.z/md;result.w:=v.w/md;
end;
function nrvec(const v:vec5):vec5;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;result.z:=v.z/md;result.w:=v.w/md;result.t:=v.t/md;
end;
//############################################################################//
function nrvec(const v:mvec2):mvec2;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;
end;
function nrvec(const v:mvec):mvec;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;result.z:=v.z/md;
end;
function nrvec(const v:mquat):mquat;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;result.z:=v.z/md;result.w:=v.w/md;
end;
function nrvec(const v:mvec5):mvec5;
var md:double;
begin
 md:=modv(v);
 if abs(md)<FLT_EPSILON then begin result:=v;exit;end;
 result.x:=v.x/md;result.y:=v.y/md;result.z:=v.z/md;result.w:=v.w/md;result.t:=v.t/md;
end;
//############################################################################//
function vcmp (const v1,v2:ivec2):boolean;begin result:=(v1.x=v2.x)and(v1.y=v2.y);end;
function vcmp (const v1,v2:vec2):boolean;begin result:=(abs(v1.x-v2.x)<eps)and(abs(v1.y-v2.y)<eps);end;
function vcmp (const v1,v2:vec ):boolean;begin result:=(abs(v1.x-v2.x)<eps)and(abs(v1.y-v2.y)<eps)and(abs(v1.z-v2.z)<eps);end;
function vcmp (const v1,v2:qvec):boolean;begin result:=(v1.x=v2.x)and(v1.y=v2.y)and(v1.z=v2.z);end;
function vcmp (const v1,v2:quat):boolean;begin result:=(abs(v1.x-v2.x)<eps)and(abs(v1.y-v2.y)<eps)and(abs(v1.z-v2.z)<eps)and(abs(v1.w-v2.w)<eps);end;
function vcmp (const v1,v2:vec5):boolean;begin result:=(abs(v1.x-v2.x)<eps)and(abs(v1.y-v2.y)<eps)and(abs(v1.z-v2.z)<eps)and(abs(v1.w-v2.w)<eps)and(abs(v1.t-v2.t)<eps);end;
function vcmp (const v1,v2:mvec2):boolean;begin result:=(abs(v1.x-v2.x)<eps)and(abs(v1.y-v2.y)<eps);end;
function vcmp (const v1,v2:mvec ):boolean;begin result:=(abs(v1.x-v2.x)<eps)and(abs(v1.y-v2.y)<eps)and(abs(v1.z-v2.z)<eps);end;

function vdst (const v1,v2:vec2):double;begin result:=sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y));end;
function vdst (const v1,v2:vec ):double;begin result:=sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z));end;
function vdst (const v1,v2:qvec):qword; begin result:=round(sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z)));end; //FIXME: Integer sqrt?
function vdst (const v1,v2:quat):double;begin result:=sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z)+sqr(v1.w-v2.w));end;
function vdst (const v1,v2:vec5):double;begin result:=sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z)+sqr(v1.w-v2.w)+sqr(v1.t-v2.t));end;
function vdst (const v1,v2:mvec2):single;begin result:=sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y));end;
function vdst (const v1,v2:mvec):single;begin result:=sqrt(sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z));end;

function vdsts(const v1,v2:ivec2):integer;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y);end;
function vdsts(const v1,v2:vec2):double;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y);end;
function vdsts(const v1,v2:vec ):double;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z);end;
function vdsts(const v1,v2:quat):double;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z)+sqr(v1.w-v2.w);end;
function vdsts(const v1,v2:vec5):double;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z)+sqr(v1.w-v2.w)+sqr(v1.t-v2.t);end;
function vdsts(const v1,v2:mvec2):single;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y);end;
function vdsts(const v1,v2:mvec ):single;begin result:=sqr(v1.x-v2.x)+sqr(v1.y-v2.y)+sqr(v1.z-v2.z);end;

function vcollin(const v1,v2,v3:mvec):boolean;begin result:=abs( (v2.y-v1.y)*(v1.z-v3.z)-(v2.z-v1.z)*(v1.y-v3.y))+abs(-(v2.x-v1.x)*(v1.z-v3.z)+(v2.z-v1.z)*(v1.x-v3.x))+abs( (v2.x-v1.x)*(v1.y-v3.y)-(v2.y-v1.y)*(v1.x-v3.x))<eps;end;
function vcollin(const v1,v2,v3:vec ):boolean;begin result:=abs( (v2.y-v1.y)*(v1.z-v3.z)-(v2.z-v1.z)*(v1.y-v3.y))+abs(-(v2.x-v1.x)*(v1.z-v3.z)+(v2.z-v1.z)*(v1.x-v3.x))+abs( (v2.x-v1.x)*(v1.y-v3.y)-(v2.y-v1.y)*(v1.x-v3.x))<eps;end;
function vcoplan(const v1,v2,v3,v4:vec):boolean;begin result:=abs(smulv(subv(v3,v1),vmulv(subv(v2,v1),subv(v4,v3))))<eps;end;
function vcoplan(const v1,v2,v3,v4:mvec):boolean;begin result:=abs(smulv(subv(v3,v1),vmulv(subv(v2,v1),subv(v4,v3))))<eps;end;

function vmid2(const v1,v2:vec2):vec2;begin result.x:=(v1.x+v2.x)/2;result.y:=(v1.y+v2.y)/2;end;
function vmid2(const v1,v2:vec ):vec ;begin result.x:=(v1.x+v2.x)/2;result.y:=(v1.y+v2.y)/2;result.z:=(v1.z+v2.z)/2;end;
function vmid2(const v1,v2:quat):quat;begin result.x:=(v1.x+v2.x)/2;result.y:=(v1.y+v2.y)/2;result.z:=(v1.z+v2.z)/2;result.w:=(v1.w+v2.w)/2;end;
function vmid2(const v1,v2:vec5):vec5;begin result.x:=(v1.x+v2.x)/2;result.y:=(v1.y+v2.y)/2;result.z:=(v1.z+v2.z)/2;result.w:=(v1.w+v2.w)/2;result.t:=(v1.t+v2.t)/2;end;
function vmid2(const v1,v2:mvec2):mvec2;begin result.x:=(v1.x+v2.x)/2;result.y:=(v1.y+v2.y)/2;end;

function vmid3(const v1,v2,v3:vec2):vec2;begin result.x:=(v1.x+v2.x+v3.x)/3;result.y:=(v1.y+v2.y+v3.y)/3;end;
function vmid3(const v1,v2,v3:vec ):vec ;begin result.x:=(v1.x+v2.x+v3.x)/3;result.y:=(v1.y+v2.y+v3.y)/3;result.z:=(v1.z+v2.z+v3.z)/3;end;
function vmid3(const v1,v2,v3:quat):quat;begin result.x:=(v1.x+v2.x+v3.x)/3;result.y:=(v1.y+v2.y+v3.y)/3;result.z:=(v1.z+v2.z+v3.z)/3;result.w:=(v1.w+v2.w+v3.w)/3;end;
function vmid3(const v1,v2,v3:vec5):vec5;begin result.x:=(v1.x+v2.x+v3.x)/3;result.y:=(v1.y+v2.y+v3.y)/3;result.z:=(v1.z+v2.z+v3.z)/3;result.w:=(v1.w+v2.w+v3.w)/3;result.t:=(v1.t+v2.t+v3.t)/3;end;
function vmid4(const v1,v2,v3,v4:vec2):vec2;begin result.x:=(v1.x+v2.x+v3.x+v4.x)/4;result.y:=(v1.y+v2.y+v3.y+v4.y)/4;end;
function vmid4(const v1,v2,v3,v4:vec ):vec ;begin result.x:=(v1.x+v2.x+v3.x+v4.x)/4;result.y:=(v1.y+v2.y+v3.y+v4.y)/4;result.z:=(v1.z+v2.z+v3.z+v4.z)/4;end;
function vmid4(const v1,v2,v3,v4:quat):quat;begin result.x:=(v1.x+v2.x+v3.x+v4.x)/4;result.y:=(v1.y+v2.y+v3.y+v4.y)/4;result.z:=(v1.z+v2.z+v3.z+v4.z)/4;result.w:=(v1.w+v2.w+v3.w+v4.w)/4;end;
function vmid4(const v1,v2,v3,v4:vec5):vec5;begin result.x:=(v1.x+v2.x+v3.x+v4.x)/4;result.y:=(v1.y+v2.y+v3.y+v4.y)/4;result.z:=(v1.z+v2.z+v3.z+v4.z)/4;result.w:=(v1.w+v2.w+v3.w+v4.w)/4;result.z:=(v1.t+v2.t+v3.t+v4.t)/4;end;
function vmid5(const v1,v2,v3,v4,v5:vec2):vec2;begin result.x:=(v1.x+v2.x+v3.x+v4.x+v5.x)/5;result.y:=(v1.y+v2.y+v3.y+v4.y+v5.y)/5;end;
function vmid5(const v1,v2,v3,v4,v5:vec ):vec ;begin result.x:=(v1.x+v2.x+v3.x+v4.x+v5.x)/5;result.y:=(v1.y+v2.y+v3.y+v4.y+v5.y)/5;result.z:=(v1.z+v2.z+v3.z+v4.z+v5.z)/5;end;
function vmid5(const v1,v2,v3,v4,v5:quat):quat;begin result.x:=(v1.x+v2.x+v3.x+v4.x+v5.x)/5;result.y:=(v1.y+v2.y+v3.y+v4.y+v5.y)/5;result.z:=(v1.z+v2.z+v3.z+v4.z+v5.z)/5;result.w:=(v1.w+v2.w+v3.w+v4.w+v5.w)/5;end;
function vmid5(const v1,v2,v3,v4,v5:vec5):vec5;begin result.x:=(v1.x+v2.x+v3.x+v4.x+v5.x)/5;result.y:=(v1.y+v2.y+v3.y+v4.y+v5.y)/5;result.z:=(v1.z+v2.z+v3.z+v4.z+v5.z)/5;result.w:=(v1.w+v2.w+v3.w+v4.w+v5.w)/5;result.t:=(v1.t+v2.t+v3.t+v4.t+v5.t)/5;end;
//############################################################################//
function vmulv(const v1,v2:vec2):double;begin result:=v1.x*v2.y-v1.y*v2.x;end;
function vmulv(const v1,v2:vec ):vec ;begin result.x:=v1.y*v2.z-v1.z*v2.y;result.y:=-v1.x*v2.z+v1.z*v2.x;result.z:=v1.x*v2.y-v1.y*v2.x;end;
function vmulv(const v1,v2:quat):quat;begin result.x:=v1.w*v2.x+v1.x*v2.w+v1.y*v2.z-v1.z*v2.y;result.y:=v1.w*v2.y+v1.y*v2.w+v1.z*v2.x-v1.x*v2.z;result.z:=v1.w*v2.z+v1.z*v2.w+v1.x*v2.y-v1.y*v2.x;result.w:=v1.w*v2.w-v1.x*v2.x-v1.y*v2.y-v1.z*v2.z;end;
function vmulv(const v1,v2:mvec2):single;begin result:=v1.x*v2.y-v1.y*v2.x;end;
function vmulv(const v1,v2:mvec ):mvec ;begin result.x:=v1.y*v2.z-v1.z*v2.y;result.y:=-v1.x*v2.z+v1.z*v2.x;result.z:=v1.x*v2.y-v1.y*v2.x;end;
function vmulv(const v1,v2:mquat):mquat;begin result.x:=v1.w*v2.x+v1.x*v2.w+v1.y*v2.z-v1.z*v2.y;result.y:=v1.w*v2.y+v1.y*v2.w+v1.z*v2.x-v1.x*v2.z;result.z:=v1.w*v2.z+v1.z*v2.w+v1.x*v2.y-v1.y*v2.x;result.w:=v1.w*v2.w-v1.x*v2.x-v1.y*v2.y-v1.z*v2.z;end;

function vmulv(const v1,v2:ivec ):ivec ;begin result.x:=v1.y*v2.z-v1.z*v2.y;result.y:=-v1.x*v2.z+v1.z*v2.x;result.z:=v1.x*v2.y-v1.y*v2.x;end;

function smulv(const v1,v2:vec2):double;begin result:=v1.x*v2.x+v1.y*v2.y;end;
function smulv(const v1,v2:vec ):double;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;end;
function smulv(const v1,v2:quat):double;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z+v1.w*v2.w;end;
function smulv(const v1,v2:vec5):double;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z+v1.w*v2.w+v1.t*v2.t;end;
function smulv(const v1,v2:mvec2):double;begin result:=v1.x*v2.x+v1.y*v2.y;end;
function smulv(const v1,v2:mvec ):double;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;end;
function smulv(const v1,v2:mquat):double;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z+v1.w*v2.w;end;
function smulv(const v1,v2:mvec5):double;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z+v1.w*v2.w+v1.t*v2.t;end;

function smulv(const v1,v2:ivec ):integer;begin result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;end;

function smulv_xvec(a,b:pdoublea;n:integer):double;
var i:integer;
begin
 result:=0;
 for i:=0 to n-1 do result:=result+a[i]*b[i];
end;

function omulv(const a,b:vec):mat;
begin
 result[0]:=tvec(a.x*b.x,a.x*b.y,a.x*b.z);
 result[1]:=tvec(a.y*b.x,a.y*b.y,a.y*b.z);
 result[2]:=tvec(a.z*b.x,a.z*b.y,a.z*b.z);
end;
function omulv(const a,b:vec6):mat6;
var i:integer;
begin
 for i:=0 to 5 do result[i]:=tvec6(a[i]*b[0],a[i]*b[1],a[i]*b[2],a[i]*b[3],a[i]*b[4],a[i]*b[5]);
end;

function nmulv(const v:vec2;a:double):vec2;begin result.x:=a*v.x;result.y:=a*v.y;end;
function nmulv(const v:ivec2;a:integer):ivec2;begin result.x:=a*v.x;result.y:=a*v.y;end;
function nmulv(const v:vec ;a:double):vec ;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;end;
function nmulv(const v:qvec;a:qword):qvec;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;end;
function nmulv(const v:quat;a:double):quat;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;result.w:=a*v.w;end;
function nmulv(const v:vec5;a:double):vec5;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;result.w:=a*v.w;result.t:=a*v.t;end;
function nmulv(const v:mvec2;a:double):mvec2;begin result.x:=a*v.x;result.y:=a*v.y;end;
function nmulv(const v:mvec ;a:double):mvec ;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;end;
function nmulv(const v:mquat;a:double):mquat;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;result.w:=a*v.w;end;
function nmulv(const v:mvec5;a:double):mvec5;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;result.w:=a*v.w;result.t:=a*v.t;end;
function nmulv(const a:vec6;const n:double):vec6;var i:integer;begin  for i:=0 to 5 do result[i]:=a[i]*n;end;
function nmulv(const a:mvec6;const n:single):mvec6;var i:integer;begin  for i:=0 to 5 do result[i]:=a[i]*n;end;

function nmulv(const v:ivec ;a:double):ivec  ;begin result.x:=round(a*v.x);result.y:=round(a*v.y);result.z:=round(a*v.z);end;
function nmulv(const v:ivec ;a:integer):ivec ;begin result.x:=a*v.x;result.y:=a*v.y;result.z:=a*v.z;end;
function ndivv(const v:ivec ;a:integer):ivec ;begin result.x:=v.x div a;result.y:=v.y div a;result.z:=v.z div a;end;
function ndivv(const v:ivec2;a:integer):ivec2;begin result.x:=v.x div a;result.y:=v.y div a;end;

function addv(const v1,v2:ivec2):ivec2;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;end;
function addv(const v1,v2:vec2):vec2;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;end;
function addv(const v1,v2:vec ):vec ;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;end;
function addv(const v1,v2:qvec):qvec;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;end;
function addv(const v1,v2:quat):quat;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;result.w:=v1.w+v2.w;end;
function addv(const v1,v2:vec5):vec5;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;result.w:=v1.w+v2.w;result.t:=v1.t+v2.t;end;
function addv(const v1,v2:mvec2):mvec2;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;end;
function addv(const v1,v2:mvec ):mvec ;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;end;
function addv(const v1,v2:mquat):mquat;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;result.w:=v1.w+v2.w;end;
function addv(const v1,v2:mvec5):mvec5;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;result.w:=v1.w+v2.w;result.t:=v1.t+v2.t;end;
function addv(const a,b:vec6):vec6;var i:integer;begin for i:=0 to 5 do result[i]:=a[i]+b[i];end;
function addv(const a,b:mvec6):mvec6;var i:integer;begin for i:=0 to 5 do result[i]:=a[i]+b[i];end;
function subv(const v1,v2:ivec2):ivec2;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;end;
function subv(const v1,v2:vec2):vec2;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;end;
function subv(const v1,v2:vec ):vec ;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;end;
function subv(const v1,v2:qvec):qvec;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;end;
function subv(const v1,v2:quat):quat;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;result.w:=v1.w-v2.w;end;
function subv(const v1,v2:vec5):vec5;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;result.w:=v1.w-v2.w;result.t:=v1.t-v2.t;end;
function subv(const v1,v2:mvec2):mvec2;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;end;
function subv(const v1,v2:mvec ):mvec ;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;end;
function subv(const v1,v2:mquat):mquat;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;result.w:=v1.w-v2.w;end;
function subv(const v1,v2:mvec5):mvec5;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;result.w:=v1.w-v2.w;result.t:=v1.t-v2.t;end;
function subv(const a,b:vec6):vec6;var i:integer;begin for i:=0 to 5 do result[i]:=a[i]-b[i];end;
function subv(const a,b:mvec6):mvec6;var i:integer;begin for i:=0 to 5 do result[i]:=a[i]-b[i];end;

function addv(const v1,v2:ivec):ivec;begin result.x:=v1.x+v2.x;result.y:=v1.y+v2.y;result.z:=v1.z+v2.z;end;
function subv(const v1,v2:ivec):ivec;begin result.x:=v1.x-v2.x;result.y:=v1.y-v2.y;result.z:=v1.z-v2.z;end;

function addv(const v1:vec;v2:veca):vec;begin result.x:=v1.x+v2[0];result.y:=v1.y+v2[1];result.z:=v1.z+v2[2];end;
function subv(const v1:vec;v2:veca):vec;begin result.x:=v1.x-v2[0];result.y:=v1.y-v2[1];result.z:=v1.z-v2[2];end;

function perpv(const v1,v2:vec):vec;begin result.x:=v1.y*v2.z-v1.z*v2.y;result.y:=-v1.x*v2.z+v1.z*v2.x;result.z:=v1.x*v2.y-v1.y*v2.x;result:=nrvec(result);end;
function perpv(const v1,v2:mvec):mvec;begin result.x:=v1.y*v2.z-v1.z*v2.y;result.y:=-v1.x*v2.z+v1.z*v2.x;result.z:=v1.x*v2.y-v1.y*v2.x;result:=nrvec(result);end;

function lmulv(const v1,v2:vec2):vec2;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;end;
function lmulv(const v1,v2:vec ):vec ;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;result.z:=v1.z*v2.z;end;
function lmulv(const v1,v2:quat):quat;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;result.z:=v1.z*v2.z;result.w:=v1.w*v2.w;end;
function lmulv(const v1,v2:vec5):vec5;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;result.z:=v1.z*v2.z;result.w:=v1.w*v2.w;result.t:=v1.t*v2.t;end;
function lmulv(const v1,v2:mvec ):mvec ;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;result.z:=v1.z*v2.z;end;
function lmulv(const v1,v2:mvec2):mvec2;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;end;
function lmulv(const v1,v2:mquat):mquat;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;result.z:=v1.z*v2.z;result.w:=v1.w*v2.w;end;
function lmulv(const v1,v2:mvec5):mvec5;begin result.x:=v1.x*v2.x;result.y:=v1.y*v2.y;result.z:=v1.z*v2.z;result.w:=v1.w*v2.w;result.t:=v1.t*v2.t;end;

function ldivv(const v1,v2:vec2):vec2;begin result.x:=v1.x/v2.x;result.y:=v1.y/v2.y;end;
function ldivv(const v1,v2:vec ):vec ;begin result.x:=v1.x/v2.x;result.y:=v1.y/v2.y;result.z:=v1.z/v2.z;end;
function ldivv(const v1,v2:quat):quat;begin result.x:=v1.x/v2.x;result.y:=v1.y/v2.y;result.z:=v1.z/v2.z;result.w:=v1.w/v2.w;end;
function ldivv(const v1,v2:vec5):vec5;begin result.x:=v1.x/v2.x;result.y:=v1.y/v2.y;result.z:=v1.z/v2.z;result.w:=v1.w/v2.w;result.t:=v1.t/v2.t;end;
function ldivv(const v1,v2:mvec ):mvec ;begin result.x:=v1.x/v2.x;result.y:=v1.y/v2.y;result.z:=v1.z/v2.z;end;
function naddv(v1:vec2;a:double):vec2;begin result.x:=v1.x+a;result.y:=v1.y+a;end;
function naddv(v1:vec ;a:double):vec ;begin result.x:=v1.x+a;result.y:=v1.y+a;result.z:=v1.z+a;end;
function naddv(v1:quat;a:double):quat;begin result.x:=v1.x+a;result.y:=v1.y+a;result.z:=v1.z+a;result.w:=v1.w+a;end;
function naddv(v1:vec5;a:double):vec5;begin result.x:=v1.x+a;result.y:=v1.y+a;result.z:=v1.z+a;result.w:=v1.w+a;result.t:=v1.t+a;end;
function nsubv(v1:vec2;a:double):vec2;begin result.x:=v1.x-a;result.y:=v1.y-a;end;
function nsubv(v1:vec ;a:double):vec ;begin result.x:=v1.x-a;result.y:=v1.y-a;result.z:=v1.z-a;end;
function nsubv(v1:quat;a:double):quat;begin result.x:=v1.x-a;result.y:=v1.y-a;result.z:=v1.z-a;result.w:=v1.w-a;end;
function nsubv(v1:vec5;a:double):vec5;begin result.x:=v1.x-a;result.y:=v1.y-a;result.z:=v1.z-a;result.w:=v1.w-a;result.t:=v1.t-a;end;

function lerpv(v1,v2:vec2 ;a:double):vec2; begin result.x:=v1.x+a*(v2.x-v1.x);result.y:=v1.y+a*(v2.y-v1.y);end;
function lerpv(v1,v2:vec  ;a:double):vec;  begin result.x:=v1.x+a*(v2.x-v1.x);result.y:=v1.y+a*(v2.y-v1.y);result.z:=v1.z+a*(v2.z-v1.z);end;
function lerpv(v1,v2:mvec2;a:single):mvec2;begin result.x:=v1.x+a*(v2.x-v1.x);result.y:=v1.y+a*(v2.y-v1.y);end;
function lerpv(v1,v2:mvec ;a:single):mvec; begin result.x:=v1.x+a*(v2.x-v1.x);result.y:=v1.y+a*(v2.y-v1.y);result.z:=v1.z+a*(v2.z-v1.z);end;
//############################################################################//
procedure vrot(var v:vec2;e:double);
var c,s,tx:extended;
begin
 if e=0 then exit;
 sincos(e,s,c);
 tx:=v.x;
 v.x:=tx*c-v.y*s;
 v.y:=tx*s+v.y*c;
end;
procedure vrotz(var v:vec;e:double);
var c,s,tx:extended;
begin
 if e=0 then exit;
 sincos(e,s,c);
 tx:=v.x;
 v.x:=tx*c-v.y*s;
 v.y:=tx*s+v.y*c;
end;
procedure vroty(var v:vec;e:double);
var c,s,tx:extended;
begin
 if e=0 then exit;
 sincos(e,s,c);
 tx:=v.x;
 v.x:=tx*c+v.z*s;
 v.z:=-tx*s+v.z*c;
end;
procedure vrotx(var v:vec;e:double);
var c,s,ty:extended;
begin
 if e=0 then exit;
 sincos(e,s,c);
 ty:=v.y;
 v.y:=ty*c-v.z*s;
 v.z:=ty*s+v.z*c;
end;
//############################################################################//
procedure vrotix(var v:ivec;e:double);
var c,s,ty:extended;
begin
 if e=0 then exit;
 sincos(e,s,c);
 ty:=v.y;
 v.y:=round(ty*c-v.z*s);
 v.z:=round(ty*s+v.z*c);
end;
//############################################################################//
function vrotf(const v:vec2;e:double):vec2;
var c,s,tx:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 result.x:=tx*c-v.y*s;
 result.y:=tx*s+v.y*c;
end;
function vrotzf(const v:vec;e:double):vec;
var c,s,tx:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 result.x:=tx*c-v.y*s;
 result.y:=tx*s+v.y*c;
 result.z:=v.z;
end;
function vrotyf(const v:vec;e:double):vec;
var c,s,tx:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 result.x:=tx*c+v.z*s;
 result.y:=v.y;
 result.z:=-tx*s+v.z*c;
end;
function vrotxf(const v:vec;e:double):vec;
var c,s,ty:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 ty:=v.y;
 result.x:=v.x;
 result.y:=ty*c-v.z*s;
 result.z:=ty*s+v.z*c;
end;
procedure vrot(var v:mvec2;e:double);
var c,s,tx:double;
begin
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 v.x:=tx*c-v.y*s;
 v.y:=tx*s+v.y*c;
end;
procedure vrotz(var v:mvec;e:double);
var c,s,tx:double;
begin
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 v.x:=tx*c-v.y*s;
 v.y:=tx*s+v.y*c;
end;
procedure vroty(var v:mvec;e:double);
var c,s,tx:double;
begin
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 v.x:=tx*c+v.z*s;
 v.z:=-tx*s+v.z*c;
end;
procedure vrotx(var v:mvec;e:double);
var c,s,ty:double;
begin
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 ty:=v.y;
 v.y:=ty*c-v.z*s;
 v.z:=ty*s+v.z*c;
end;

function vrotf(const v:mvec2;e:double):mvec2;
var c,s,tx:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 result.x:=tx*c-v.y*s;
 result.y:=tx*s+v.y*c;
end;
function vrotzf(const v:mvec;e:double):mvec;
var c,s,tx:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 result.x:=tx*c-v.y*s;
 result.y:=tx*s+v.y*c;
 result.z:=v.z;
end;
function vrotyf(const v:mvec;e:double):mvec;
var c,s,tx:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 tx:=v.x;
 result.x:=tx*c+v.z*s;
 result.y:=v.y;
 result.z:=-tx*s+v.z*c;
end;
function vrotxf(const v:mvec;e:double):mvec;
var c,s,ty:double;
begin
 result:=v;
 if e=0 then exit;
 c:=cos(e);
 s:=sin(e);
 ty:=v.y;
 result.x:=v.x;
 result.y:=ty*c-v.z*s;
 result.z:=ty*s+v.z*c;
end;
//############################################################################//
function trr2l(const v:vec):vec;overload;begin result.x:=v.x;result.y:=v.z; result.z:=v.y;end;
function trr2l(const v:mvec):mvec;overload;begin result.x:=v.x;result.y:=v.z; result.z:=v.y;end;
//############################################################################//
function vec32(a:vec):vec2;begin result.x:=a.x; result.y:=a.y;end;
function vec34(a:vec):quat;begin result.x:=a.x; result.y:=a.y; result.z:=a.z; result.w:=0;end;
function vec23(a:vec2):vec;begin result.x:=a.x; result.y:=a.y; result.z:=0;end;
//##############################################################################
procedure gvec(var x:double;var y:double;var z:double;a:vec);begin x:=a.x;y:=a.y;z:=a.z;end;
procedure vreps(var v:vec;e:double);var t:double;begin t:=1/e; v.x:=round(v.x*t)/t; v.y:=round(v.y*t)/t; v.z:=round(v.z*t)/t;end;
procedure vscale(var v:vec;a,b,c:double);begin v.x:=v.x*a; v.y:=v.y*b; v.z:=v.z*c;end;
//############################################################################//
function vteps(v:vec):vec;overload;begin if abs(v.x)<eps then v.x:=0;if abs(v.y)<eps then v.y:=0;if abs(v.z)<eps then v.z:=0;result:=v;end;
function vteps(v:quat):quat;overload;begin if abs(v.x)<eps then v.x:=0;if abs(v.y)<eps then v.y:=0;if abs(v.z)<eps then v.z:=0;if abs(v.w)<eps then v.w:=0;result:=v;end;
function vteps(v:mat):mat;overload;
begin
 if abs(v[0].x)<eps then v[0].x:=0;if abs(v[0].y)<eps then v[0].y:=0;if abs(v[0].z)<eps then v[0].z:=0;
 if abs(v[1].x)<eps then v[1].x:=0;if abs(v[1].y)<eps then v[1].y:=0;if abs(v[1].z)<eps then v[1].z:=0;
 if abs(v[2].x)<eps then v[2].x:=0;if abs(v[2].y)<eps then v[2].y:=0;if abs(v[2].z)<eps then v[2].z:=0;
 result:=v;
end;
//############################################################################//
//############################################################################//
//############################### Matrices ###################################//
//############################################################################//
function tmat(a1,a2,a3,b1,b2,b3,c1,c2,c3:double):mat;
begin
 result[0].x:=a1; result[0].y:=a2; result[0].z:=a3;
 result[1].x:=b1; result[1].y:=b2; result[1].z:=b3;
 result[2].x:=c1; result[2].y:=c2; result[2].z:=c3;
end;
{$ifndef paser}
procedure set_matint(var m:matint;xs,ys:integer);
var i:integer;
begin
 setlength(m,ys);
 for i:=0 to ys-1 do setlength(m[i],xs);
end;
{$endif}
//############################################################################//
function m2v(const v:mmat):mat;begin result[0]:=m2v(v[0]);result[1]:=m2v(v[1]);result[2]:=m2v(v[2]);end;
function v2m(const v:mat):mmat;begin result[0]:=v2m(v[0]);result[1]:=v2m(v[1]);result[2]:=v2m(v[2]);end;
//############################################################################//
function matq2mmatq(const a:matq):mmatq;
begin
 result[0]:=tmquat(a[0].x,a[0].y,a[0].z,a[0].w);
 result[1]:=tmquat(a[1].x,a[1].y,a[1].z,a[1].w);
 result[2]:=tmquat(a[2].x,a[2].y,a[2].z,a[2].w);
 result[3]:=tmquat(a[3].x,a[3].y,a[3].z,a[3].w);
end;
//############################################################################//
function mat2matq(const a:mat):matq;
begin
 result[0]:=tquat(a[0].x,a[0].y,a[0].z,0);
 result[1]:=tquat(a[1].x,a[1].y,a[1].z,0);
 result[2]:=tquat(a[2].x,a[2].y,a[2].z,0);
 result[3]:=tquat(0,0,0,1);
end;
//############################################################################//
function lvmat(const a:mat2;const b:vec2):vec2;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y;
 result.y:=a[1].x*b.x+a[1].y*b.y;
end;
function lvmat(const a:mat;const b:vec):vec;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z;
end;
function lvmat(const a:mat;const b:vec2):vec2;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z;
end;
function lvmat(const a:mat;const b:mvec):mvec;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z;
end;
function lvmat(const a:mmat;const b:mvec):mvec;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z;
end;
function lvmat(const a:matq;const b:quat):quat;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w*b.w;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w*b.w;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w*b.w;
 result.w:=a[3].x*b.x+a[3].y*b.y+a[3].z*b.z+a[3].w*b.w;
end;
function lvmat(const a:matq;const b:mquat):mquat;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w*b.w;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w*b.w;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w*b.w;
 result.w:=a[3].x*b.x+a[3].y*b.y+a[3].z*b.z+a[3].w*b.w;
end;
function lvmat(const a:mmatq;const b:mquat):mquat;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w*b.w;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w*b.w;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w*b.w;
 result.w:=a[3].x*b.x+a[3].y*b.y+a[3].z*b.z+a[3].w*b.w;
end;
function lvmat(const a:matq;const b:vec):vec;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w;
end;
function lvmat(const a:matq;const b:mvec):mvec;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w;
end;
function lvmat(const a:mmatq;const b:mvec):mvec;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w;
end;
function lvmat(const a:mat5;const b:quat):quat;
begin
 result.x:=a[0].x*b.x+a[0].y*b.y+a[0].z*b.z+a[0].w*b.w+a[0].t;
 result.y:=a[1].x*b.x+a[1].y*b.y+a[1].z*b.z+a[1].w*b.w+a[1].t;
 result.z:=a[2].x*b.x+a[2].y*b.y+a[2].z*b.z+a[2].w*b.w+a[2].t;
 result.w:=a[3].x*b.x+a[3].y*b.y+a[3].z*b.z+a[3].w*b.w+a[3].t;
end;
//############################################################################//
function rvmat(const b:vec2;const a:mat2):vec2;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y;
 result.y:=a[0].y*b.x+a[1].y*b.y;
end;
function rvmat(const b:vec;const a:mat):vec;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z;
end;
function rvmat(const b:mvec;const a:mat):mvec;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z;
end;
function rvmat(const b:quat;const a:matq):quat;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z+a[3].x*b.w;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z+a[3].y*b.w;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z+a[3].z*b.w;
 result.w:=a[0].w*b.x+a[1].w*b.y+a[2].w*b.z+a[3].w*b.w;
end;
function rvmat(const b:mquat;const a:matq):mquat;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z+a[3].x*b.w;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z+a[3].y*b.w;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z+a[3].z*b.w;
 result.w:=a[0].w*b.x+a[1].w*b.y+a[2].w*b.z+a[3].w*b.w;
end;
function rvmat(const b:mquat;const a:mmatq):mquat;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z+a[3].x*b.w;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z+a[3].y*b.w;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z+a[3].z*b.w;
 result.w:=a[0].w*b.x+a[1].w*b.y+a[2].w*b.z+a[3].w*b.w;
end;
function rvmat(const b:vec;const a:matq):vec;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z;
end;
function rvmat(const b:mvec;const a:matq):mvec;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z;
end;
function rvmat(const b:quat;const a:mat5):quat;
begin
 result.x:=a[0].x*b.x+a[1].x*b.y+a[2].x*b.z+a[3].x*b.w;
 result.y:=a[0].y*b.x+a[1].y*b.y+a[2].y*b.z+a[3].y*b.w;
 result.z:=a[0].z*b.x+a[1].z*b.y+a[2].z*b.z+a[3].z*b.w;
 result.w:=a[0].w*b.x+a[1].w*b.y+a[2].w*b.z+a[3].w*b.w;
end;
//############################################################################//
function nmulmat(const tm:mat2;a:double):mat2;
begin
 result[0].x:=a*tm[0].x; result[0].y:=a*tm[0].y;
 result[1].x:=a*tm[1].x; result[1].y:=a*tm[1].y;
end;
//############################################################################//
function nmulmat(const tm:mat;a:double):mat;
begin
 result[0].x:=a*tm[0].x; result[0].y:=a*tm[0].y; result[0].z:=a*tm[0].z;
 result[1].x:=a*tm[1].x; result[1].y:=a*tm[1].y; result[1].z:=a*tm[1].z;
 result[2].x:=a*tm[2].x; result[2].y:=a*tm[2].y; result[2].z:=a*tm[2].z;
end;
//############################################################################//
function nmulmat(const tm:matq;a:double):matq;
begin
 result[0].x:=a*tm[0].x; result[0].y:=a*tm[0].y; result[0].z:=a*tm[0].z; result[0].w:=a*tm[0].w;
 result[1].x:=a*tm[1].x; result[1].y:=a*tm[1].y; result[1].z:=a*tm[1].z; result[1].w:=a*tm[1].w;
 result[2].x:=a*tm[2].x; result[2].y:=a*tm[2].y; result[2].z:=a*tm[2].z; result[2].w:=a*tm[2].w;
 result[3].x:=a*tm[3].x; result[3].y:=a*tm[3].y; result[3].z:=a*tm[3].z; result[3].w:=a*tm[3].w;
end;
//############################################################################//
function atmat(const a:vec):mat;
var sinx,siny,sinz,cosx,cosy,cosz:double;
begin
 sinz:=sin(a.z);
 cosz:=cos(a.z);
 siny:=sin(a.y);
 cosy:=cos(a.y);
 sinx:=sin(a.x);
 cosx:=cos(a.x);

 result[0].x:=cosy*cosz;
 result[0].y:=cosy*sinz;
 result[0].z:=-siny;
 result[1].x:=cosz*sinx*siny-sinz*cosx;
 result[1].y:=sinx*siny*sinz+cosx*cosz;
 result[1].z:=sinx*cosy;
 result[2].x:=cosx*siny*cosz+sinz*sinx;
 result[2].y:=sinz*cosx*siny-sinx*cosz;
 result[2].z:=cosx*cosy;
end;
//############################################################################//
function atmatz(const a:vec):mat;
var sinx,siny,sinz,cosx,cosy,cosz:double;
begin
 sinx:=sin(-a.x);cosx:=cos(-a.x);
 siny:=sin(-a.y);cosy:=cos(-a.y);
 sinz:=sin(a.z);cosz:=cos(a.z);

 //syz:=siny*sinz;
 //cxz:=cosx*cosz;
 //sxcz:=sinx*cosz;

 result[0].x:=cosy*cosz;
 result[0].y:=cosy*sinz;
 result[0].z:=-siny;
 result[1].x:=cosz*sinx*siny-sinz*cosx;
 result[1].y:=sinx*siny*sinz+cosx*cosz;
 result[1].z:=sinx*cosy;
 result[2].x:=cosx*siny*cosz+sinz*sinx;
 result[2].y:=sinz*cosx*siny-sinx*cosz;
 result[2].z:=cosx*cosy;
end;
//############################################################################//
function tamat(const a:mat):vec; begin result.x:= arctan2(a[1].z,a[2].z); result.y:=-arcsin(a[0].z); result.z:=arctan2(a[0].y,a[0].x);end;
function tamatz(const a:mat):vec;begin result.x:=-arctan2(a[1].z,a[2].z); result.y:= arcsin(a[0].z); result.z:=arctan2(a[0].y,a[0].x);end;
//############################################################################//
function addmat(const a,b:mat):mat;
begin
 result[0]:=addv(a[0],b[0]);
 result[1]:=addv(a[1],b[1]);
 result[2]:=addv(a[2],b[2]);
end;
function addmat(const a,b:mat6):mat6;
var i:integer;
begin
 for i:=0 to 5 do result[i]:=addv(a[i],b[i]);
end;
//############################################################################//
function mulm(const a,b:mat):mat;overload;
begin
 result[0].x:=a[0].x*b[0].x+a[0].y*b[1].x+a[0].z*b[2].x;
 result[0].y:=a[0].x*b[0].y+a[0].y*b[1].y+a[0].z*b[2].y;
 result[0].z:=a[0].x*b[0].z+a[0].y*b[1].z+a[0].z*b[2].z;
 result[1].x:=a[1].x*b[0].x+a[1].y*b[1].x+a[1].z*b[2].x;
 result[1].y:=a[1].x*b[0].y+a[1].y*b[1].y+a[1].z*b[2].y;
 result[1].z:=a[1].x*b[0].z+a[1].y*b[1].z+a[1].z*b[2].z;
 result[2].x:=a[2].x*b[0].x+a[2].y*b[1].x+a[2].z*b[2].x;
 result[2].y:=a[2].x*b[0].y+a[2].y*b[1].y+a[2].z*b[2].y;
 result[2].z:=a[2].x*b[0].z+a[2].y*b[1].z+a[2].z*b[2].z;
end;
function mulm(const a,b:mmat):mmat;overload;
begin
 result[0].x:=a[0].x*b[0].x+a[0].y*b[1].x+a[0].z*b[2].x;
 result[0].y:=a[0].x*b[0].y+a[0].y*b[1].y+a[0].z*b[2].y;
 result[0].z:=a[0].x*b[0].z+a[0].y*b[1].z+a[0].z*b[2].z;
 result[1].x:=a[1].x*b[0].x+a[1].y*b[1].x+a[1].z*b[2].x;
 result[1].y:=a[1].x*b[0].y+a[1].y*b[1].y+a[1].z*b[2].y;
 result[1].z:=a[1].x*b[0].z+a[1].y*b[1].z+a[1].z*b[2].z;
 result[2].x:=a[2].x*b[0].x+a[2].y*b[1].x+a[2].z*b[2].x;
 result[2].y:=a[2].x*b[0].y+a[2].y*b[1].y+a[2].z*b[2].y;
 result[2].z:=a[2].x*b[0].z+a[2].y*b[1].z+a[2].z*b[2].z;
end;
function mulm(const a,b:matq):matq;overload;
begin
 result[0].x:=a[0].x*b[0].x+a[0].y*b[1].x+a[0].z*b[2].x+a[0].w*b[3].x;
 result[0].y:=a[0].x*b[0].y+a[0].y*b[1].y+a[0].z*b[2].y+a[0].w*b[3].y;
 result[0].z:=a[0].x*b[0].z+a[0].y*b[1].z+a[0].z*b[2].z+a[0].w*b[3].z;
 result[0].w:=a[0].x*b[0].w+a[0].y*b[1].w+a[0].z*b[2].w+a[0].w*b[3].w;
 result[1].x:=a[1].x*b[0].x+a[1].y*b[1].x+a[1].z*b[2].x+a[1].w*b[3].x;
 result[1].y:=a[1].x*b[0].y+a[1].y*b[1].y+a[1].z*b[2].y+a[1].w*b[3].y;
 result[1].z:=a[1].x*b[0].z+a[1].y*b[1].z+a[1].z*b[2].z+a[1].w*b[3].z;
 result[1].w:=a[1].x*b[0].w+a[1].y*b[1].w+a[1].z*b[2].w+a[1].w*b[3].w;
 result[2].x:=a[2].x*b[0].x+a[2].y*b[1].x+a[2].z*b[2].x+a[2].w*b[3].x;
 result[2].y:=a[2].x*b[0].y+a[2].y*b[1].y+a[2].z*b[2].y+a[2].w*b[3].y;
 result[2].z:=a[2].x*b[0].z+a[2].y*b[1].z+a[2].z*b[2].z+a[2].w*b[3].z;
 result[2].w:=a[2].x*b[0].w+a[2].y*b[1].w+a[2].z*b[2].w+a[2].w*b[3].w;
 result[3].x:=a[3].x*b[0].x+a[3].y*b[1].x+a[3].z*b[2].x+a[3].w*b[3].x;
 result[3].y:=a[3].x*b[0].y+a[3].y*b[1].y+a[3].z*b[2].y+a[3].w*b[3].y;
 result[3].z:=a[3].x*b[0].z+a[3].y*b[1].z+a[3].z*b[2].z+a[3].w*b[3].z;
 result[3].w:=a[3].x*b[0].w+a[3].y*b[1].w+a[3].z*b[2].w+a[3].w*b[3].w;
end;
function mulm(const a,b:mmatq):mmatq;overload;
begin
 result[0].x:=a[0].x*b[0].x+a[0].y*b[1].x+a[0].z*b[2].x+a[0].w*b[3].x;
 result[0].y:=a[0].x*b[0].y+a[0].y*b[1].y+a[0].z*b[2].y+a[0].w*b[3].y;
 result[0].z:=a[0].x*b[0].z+a[0].y*b[1].z+a[0].z*b[2].z+a[0].w*b[3].z;
 result[0].w:=a[0].x*b[0].w+a[0].y*b[1].w+a[0].z*b[2].w+a[0].w*b[3].w;
 result[1].x:=a[1].x*b[0].x+a[1].y*b[1].x+a[1].z*b[2].x+a[1].w*b[3].x;
 result[1].y:=a[1].x*b[0].y+a[1].y*b[1].y+a[1].z*b[2].y+a[1].w*b[3].y;
 result[1].z:=a[1].x*b[0].z+a[1].y*b[1].z+a[1].z*b[2].z+a[1].w*b[3].z;
 result[1].w:=a[1].x*b[0].w+a[1].y*b[1].w+a[1].z*b[2].w+a[1].w*b[3].w;
 result[2].x:=a[2].x*b[0].x+a[2].y*b[1].x+a[2].z*b[2].x+a[2].w*b[3].x;
 result[2].y:=a[2].x*b[0].y+a[2].y*b[1].y+a[2].z*b[2].y+a[2].w*b[3].y;
 result[2].z:=a[2].x*b[0].z+a[2].y*b[1].z+a[2].z*b[2].z+a[2].w*b[3].z;
 result[2].w:=a[2].x*b[0].w+a[2].y*b[1].w+a[2].z*b[2].w+a[2].w*b[3].w;
 result[3].x:=a[3].x*b[0].x+a[3].y*b[1].x+a[3].z*b[2].x+a[3].w*b[3].x;
 result[3].y:=a[3].x*b[0].y+a[3].y*b[1].y+a[3].z*b[2].y+a[3].w*b[3].y;
 result[3].z:=a[3].x*b[0].z+a[3].y*b[1].z+a[3].z*b[2].z+a[3].w*b[3].z;
 result[3].w:=a[3].x*b[0].w+a[3].y*b[1].w+a[3].z*b[2].w+a[3].w*b[3].w;
end;
function mulm(const a,b:mat5):mat5;overload;
begin
 result[0].x:=a[0].x*b[0].x+a[0].y*b[1].x+a[0].z*b[2].x+a[0].w*b[3].x+a[0].t*b[4].x;
 result[0].y:=a[0].x*b[0].y+a[0].y*b[1].y+a[0].z*b[2].y+a[0].w*b[3].y+a[0].t*b[4].y;
 result[0].z:=a[0].x*b[0].z+a[0].y*b[1].z+a[0].z*b[2].z+a[0].w*b[3].z+a[0].t*b[4].z;
 result[0].w:=a[0].x*b[0].w+a[0].y*b[1].w+a[0].z*b[2].w+a[0].w*b[3].w+a[0].t*b[4].w;
 result[0].t:=a[0].x*b[0].t+a[0].y*b[1].t+a[0].z*b[2].t+a[0].w*b[3].t+a[0].t*b[4].t;
 result[1].x:=a[1].x*b[0].x+a[1].y*b[1].x+a[1].z*b[2].x+a[1].w*b[3].x+a[1].t*b[4].x;
 result[1].y:=a[1].x*b[0].y+a[1].y*b[1].y+a[1].z*b[2].y+a[1].w*b[3].y+a[1].t*b[4].y;
 result[1].z:=a[1].x*b[0].z+a[1].y*b[1].z+a[1].z*b[2].z+a[1].w*b[3].z+a[1].t*b[4].z;
 result[1].w:=a[1].x*b[0].w+a[1].y*b[1].w+a[1].z*b[2].w+a[1].w*b[3].w+a[1].t*b[4].w;
 result[1].t:=a[1].x*b[0].t+a[1].y*b[1].t+a[1].z*b[2].t+a[1].w*b[3].t+a[1].t*b[4].t;
 result[2].x:=a[2].x*b[0].x+a[2].y*b[1].x+a[2].z*b[2].x+a[2].w*b[3].x+a[2].t*b[4].x;
 result[2].y:=a[2].x*b[0].y+a[2].y*b[1].y+a[2].z*b[2].y+a[2].w*b[3].y+a[2].t*b[4].y;
 result[2].z:=a[2].x*b[0].z+a[2].y*b[1].z+a[2].z*b[2].z+a[2].w*b[3].z+a[2].t*b[4].z;
 result[2].w:=a[2].x*b[0].w+a[2].y*b[1].w+a[2].z*b[2].w+a[2].w*b[3].w+a[2].t*b[4].w;
 result[2].t:=a[2].x*b[0].t+a[2].y*b[1].t+a[2].z*b[2].t+a[2].w*b[3].t+a[2].t*b[4].t;
 result[3].x:=a[3].x*b[0].x+a[3].y*b[1].x+a[3].z*b[2].x+a[3].w*b[3].x+a[3].t*b[4].x;
 result[3].y:=a[3].x*b[0].y+a[3].y*b[1].y+a[3].z*b[2].y+a[3].w*b[3].y+a[3].t*b[4].y;
 result[3].z:=a[3].x*b[0].z+a[3].y*b[1].z+a[3].z*b[2].z+a[3].w*b[3].z+a[3].t*b[4].z;
 result[3].w:=a[3].x*b[0].w+a[3].y*b[1].w+a[3].z*b[2].w+a[3].w*b[3].w+a[3].t*b[4].w;
 result[3].t:=a[3].x*b[0].t+a[3].y*b[1].t+a[3].z*b[2].t+a[3].w*b[3].t+a[3].t*b[4].t;
 result[4].x:=a[4].x*b[0].x+a[4].y*b[1].x+a[4].z*b[2].x+a[4].w*b[3].x+a[4].t*b[4].x;
 result[4].y:=a[4].x*b[0].y+a[4].y*b[1].y+a[4].z*b[2].y+a[4].w*b[3].y+a[4].t*b[4].y;
 result[4].z:=a[4].x*b[0].z+a[4].y*b[1].z+a[4].z*b[2].z+a[4].w*b[3].z+a[4].t*b[4].z;
 result[4].w:=a[4].x*b[0].w+a[4].y*b[1].w+a[4].z*b[2].w+a[4].w*b[3].w+a[4].t*b[4].w;
 result[4].t:=a[4].x*b[0].t+a[4].y*b[1].t+a[4].z*b[2].t+a[4].w*b[3].t+a[4].t*b[4].t;
end;
//############################################################################//
function epsmat(const a:mat):mat;
var i:integer;
begin
 for i:=0 to 2 do begin
  result[i].x:=a[i].x;if abs(a[i].x)<eps then result[i].x:=0;
  result[i].y:=a[i].y;if abs(a[i].y)<eps then result[i].y:=0;
  result[i].z:=a[i].z;if abs(a[i].z)<eps then result[i].z:=0;
 end;
end;
//############################################################################//
procedure rtmatx(var a:mat;an:double);
var result:mat;
begin
 result[0].x:=a[0].x*1+a[0].y*0      +a[0].z*0;
 result[0].y:=a[0].x*0+a[0].y*cos(an)-a[0].z*sin(an);
 result[0].z:=a[0].x*0+a[0].y*sin(an)+a[0].z*cos(an);
 result[1].x:=a[1].x*1+a[1].y*0      +a[1].z*0;
 result[1].y:=a[1].x*0+a[1].y*cos(an)-a[1].z*sin(an);
 result[1].z:=a[1].x*0+a[1].y*sin(an)+a[1].z*cos(an);
 result[2].x:=a[2].x*1+a[2].y*0      +a[2].z*0;
 result[2].y:=a[2].x*0+a[2].y*cos(an)-a[2].z*sin(an);
 result[2].z:=a[2].x*0+a[2].y*sin(an)+a[2].z*cos(an);
 a:=result;
end;
//############################################################################//
procedure rtmaty(var a:mat;an:double);
var result:mat;
begin
 result[0].x:=a[0].x*cos(an)+a[0].y*0-a[0].z*sin(an);
 result[0].y:=a[0].x*0      +a[0].y*1+a[0].z*0;
 result[0].z:=a[0].x*sin(an)+a[0].y*0+a[0].z*cos(an);
 result[1].x:=a[1].x*cos(an)+a[1].y*0-a[1].z*sin(an);
 result[1].y:=a[1].x*0      +a[1].y*1+a[1].z*0;
 result[1].z:=a[1].x*sin(an)+a[1].y*0+a[1].z*cos(an);
 result[2].x:=a[2].x*cos(an)+a[2].y*0-a[2].z*sin(an);
 result[2].y:=a[2].x*0      +a[2].y*1+a[2].z*0;
 result[2].z:=a[2].x*sin(an)+a[2].y*0+a[2].z*cos(an);
 a:=result;
end;
//############################################################################//
procedure rtmatz(var a:mat;an:double);
var result:mat;
begin
 result[0].x:= a[0].x*cos(an)-a[0].y*sin(an)-a[0].z*0;
 result[0].y:= a[0].x*sin(an)+a[0].y*cos(an)+a[0].z*0;
 result[0].z:= a[0].x*0      +a[0].y*0      +a[0].z*1;
 result[1].x:= a[1].x*cos(an)-a[1].y*sin(an)-a[1].z*0;
 result[1].y:= a[1].x*sin(an)+a[1].y*cos(an)+a[1].z*0;
 result[1].z:= a[1].x*0      +a[1].y*0      +a[1].z*1;
 result[2].x:= a[2].x*cos(an)-a[2].y*sin(an)-a[2].z*0;
 result[2].y:= a[2].x*sin(an)+a[2].y*cos(an)+a[2].z*0;
 result[2].z:= a[2].x*0      +a[2].y*0      +a[2].z*1;
 a:=result;
end;
//############################################################################//
function matq_get_translation(const m:matq):vec;
begin
 result:=tvec(m[0].w,m[1].w,m[2].w);
end;
//############################################################################//
function matq_get_rotation(const m:matq):mat;
begin
 result[0]:=v4v3(m[0]);
 result[1]:=v4v3(m[1]);
 result[2]:=v4v3(m[2]);
end;
//############################################################################//
function mat_get_translation(const m:mat):vec2;
begin
 result:=tvec2(m[0].z,m[1].z);
end;
//############################################################################//
function mat_get_rotation(const m:mat):mat2;
begin
 result[0]:=tvec2(m[0].x,m[0].y);
 result[1]:=tvec2(m[1].x,m[1].y);
end;
//############################################################################//
//used to be procedure rtmataa(var a:mat;an:double;axis:vec);
function create_rot_mat_by_axis_angle(const axis:vec;angle:double):mat;
var c,s,nc:double;
xs,ys,zs,nx,ny,nz:double;
begin
 s:=sin(angle);
 c:=cos(angle);
 nc:=1-c;

 xs:=axis.x*s;
 ys:=axis.y*s;
 zs:=axis.z*s;
 nx:=nc*axis.x;
 ny:=nc*axis.y;
 nz:=nc*axis.z;
 result[0].x:=(nx*axis.x)+c;  result[0].y:=(ny*axis.x)-zs; result[0].z:=(nz*axis.x)+ys;
 result[1].x:=(nx*axis.y)+zs; result[1].y:=(ny*axis.y)+c;  result[1].z:=(nz*axis.y)-xs;
 result[2].x:=(nx*axis.z)-ys; result[2].y:=(ny*axis.z)+xs; result[2].z:=(nz*axis.z)+c;
end;
//############################################################################//
//Same as create_rot_mat_by_axis_angle, but with cos(angle) given instead of angle
function create_rot_mat_by_axis_cos(const axis:mvec;c:single):mat;
var s,nc:single;
xs,ys,zs,nx,ny,nz:single;
begin
 s:=sqrt(1-c*c);
 nc:=1-c;

 xs:=axis.x*s;
 ys:=axis.y*s;
 zs:=axis.z*s;
 nx:=nc*axis.x;
 ny:=nc*axis.y;
 nz:=nc*axis.z;
 result[0].x:=(nx*axis.x)+c;  result[0].y:=(ny*axis.x)-zs; result[0].z:=(nz*axis.x)+ys;
 result[1].x:=(nx*axis.y)+zs; result[1].y:=(ny*axis.y)+c;  result[1].z:=(nz*axis.y)-xs;
 result[2].x:=(nx*axis.z)-ys; result[2].y:=(ny*axis.z)+xs; result[2].z:=(nz*axis.z)+c;
end;
//############################################################################//
//Rotation matrix to (fwd, up) orientation
//From X to the side, Y forward, Z up zero frame
function vecs2mat(const fwd,up:vec):mat;
var s,u,f,nup:vec;
m:mat;
begin
 result:=emat;

 f:=nrvec(fwd);
 nup:=vmulv(vmulv(f,up),f);
 if (nup.x=0)and(nup.y=0)and(nup.z=0) then exit;
 nup:=nrvec(nup);

 s:=vmulv(f,nup);
 u:=vmulv(s,f);

 m[0]:=tvec(s.x,f.x,u.x);
 m[1]:=tvec(s.y,f.y,u.y);
 m[2]:=tvec(s.z,f.z,u.z);

 result:=m;
end;
//############################################################################//
//Rotation matrix to (fwd, up) orientation
//From X to the side, Z forward, Y up zero frame
function vecs2matz(const fwd,up:vec):mat;
var m:mat;
begin
 m:=vecs2mat(fwd,up);
 result:=epsmat(mulm(m,atmat(tvec(pi/2,0,pi))));
end;
//############################################################################//
function v2vrotmat(const v1,v2:vec):mat;
var fv,tv,vs,v,vt:vec;
ca:double;
begin
 fv:=nrvec(v1);
 tv:=nrvec(v2);

 vs:=vmulv(fv,tv); // axis multiplied by sin

 v:=nrvec(vs);// axis of rotation
 ca:=smulv(fv,tv); // cos angle

 vt:=nmulv(v,(1-ca));

 result[0].x:=vt.x*v.x+ca;
 result[1].y:=vt.y*v.y+ca;
 result[2].z:=vt.z*v.z+ca;

 vt.x:=vt.x*v.y;
 vt.z:=vt.z*v.x;
 vt.y:=vt.y*v.z;

 result[0].y:=vt.x-vs.z;
 result[0].z:=vt.z+vs.y;
 result[1].x:=vt.x+vs.z;
 result[1].z:=vt.y-vs.x;
 result[2].x:=vt.z-vs.y;
 result[2].y:=vt.y+vs.x;
end;
//############################################################################//
//was rotatevector
function rotate_vec_axis_angle(const v:vec;const axis:vec;angle:double):vec;  begin result:=    rvmat(    v ,create_rot_mat_by_axis_angle(axis,angle));end;
function rotate_vec_axis_angle(const v:mvec;const axis:vec;angle:double):mvec;begin result:=v2m(rvmat(m2v(v),create_rot_mat_by_axis_angle(axis,angle)));end;
function rotate_vec_axis_cos  (const v,axis:mvec;ca:single):mvec;             begin result:=    rvmat(    v ,create_rot_mat_by_axis_cos  (axis,ca));end;
//############################################################################//
//############################### Quaternion #################################//
//############################################################################//
function trquat(x,y,z:double):quat;
var ex,ey,ez:double;
cr,cp,cy,sr,sp,sy,cpcy,spsy:double;
begin
 ex:=x/2; ey:=y/2; ez:=z/2;
 cr:=cos(ex); cp:=cos(ey); cy:=cos(ez);
 sr:=sin(ex); sp:=sin(ey); sy:=sin(ez);

 cpcy:=cp*cy;
 spsy:=sp*sy;

 result.x:=sr*cpcy-cr*spsy;
 result.y:=cr*sp*cy+sr*cp*sy;
 result.z:=cr*cp*sy-sr*sp*cy;
 result.w:=cr*cpcy+sr*spsy;

 result:=nrvec(result);
end;
//##############################################################################
function vtrquat(a:vec):quat;begin result:=trquat(a.x,a.y,a.z);end;
//############################################################################//
//Quaternion to axis+angle (used to be getqaa)
procedure quat_to_axis_angle(q:quat;out v:vec;out ang:double);
var temp_angle,scale:double;
begin
 if q.w>=1 then q.w:=1-eps;
 temp_angle:=arccos(q.w);
 scale:=sqrt(sqr(q.x)+sqr(q.y)+sqr(q.z));

 if (scale=0) then begin
  ang:=0;
  v.x:=0;
  v.y:=0;
  v.z:=1;
  v:=nrvec(v);
 end else begin
  ang:=temp_angle*2.0;
  v.x:=q.x/scale;
  v.y:=q.y/scale;
  v.z:=q.z/scale;
  v:=nrvec(v);
 end;
end;
//############################################################################//
function qrot(iv:vec;iq:quat):vec;
var tv,axis:vec;
ang:double;
tq:quat;
begin
 tv:=iv;
 tq:=qmul(trquat(iv.x,iv.y,iv.z),iq);
 quat_to_axis_angle(tq,axis,ang);
 result:=rotate_vec_axis_angle(tv,axis,ang);
end;
//############################################################################//
function qunrot(iv:vec;iq:quat):vec;
var tv,axis:vec;
ang:double;
tq:quat;
begin
 tv:=iv;
 tq:=qmul(trquat(iv.x,iv.y,iv.z),iq);
 quat_to_axis_angle(tq,axis,ang);
 result:=rotate_vec_axis_angle(tv,axis,-ang);
end;
//############################################################################//
function qrotvec(v:vec;q:quat):vec;
var axis:vec;
ang:double;
begin
 quat_to_axis_angle(q,axis,ang);
 result:=rotate_vec_axis_angle(v,axis,ang);
end;
//############################################################################//
function qunrotvec(v:vec;q:quat):vec;
var axis:vec;
ang:double;
begin
 quat_to_axis_angle(q,axis,ang);
 result:=rotate_vec_axis_angle(v,axis,-ang);
end;
//############################################################################//
function qmul(q1,q2:quat):quat;
begin
 result.w:=q1.w*q2.w-q1.x*q2.x-q1.y*q2.y-q1.z*q2.z;
 result.x:=q1.w*q2.x+q1.x*q2.w+q1.y*q2.z-q1.z*q2.y;
 result.y:=q1.w*q2.y+q1.y*q2.w+q1.z*q2.x-q1.x*q2.z;
 result.z:=q1.w*q2.z+q1.z*q2.w+q1.x*q2.y-q1.y*q2.x;
end;
//############################################################################//
function qinv(q:quat):quat;
begin
 result.x:=-q.x;
 result.y:=-q.y;
 result.z:=-q.z;
 result.w:=q.w;
end;
//##############################################################################
function rotm2quat(a:mat):quat;
var ta:vec;
begin
 rtmaty(a,pi/2);
 rtmatx(a,-pi/2);
 ta:=tamat(vteps(a));
 result:=vmulv(trquat(0,0,0),trquat(ta.x,ta.y,ta.z));
end;
//##############################################################################
function rotm2quatz(a:mat):quat;
var ta:vec;
begin
 ta:=tamat(vteps(a));
 result:=trquat(ta.x,ta.y,ta.z);
end;
//############################################################################//
function quat2rotm(const q:quat):mat;
begin
 result[0]:=tvec(1-2*q.y*q.y-2*q.z*q.z,  2*q.x*q.y-2*q.z*q.w,  2*q.x*q.z+2*q.y*q.w);
 result[1]:=tvec(  2*q.x*q.y+2*q.z*q.w,1-2*q.x*q.x-2*q.z*q.z,  2*q.y*q.z-2*q.x*q.w);
 result[2]:=tvec(  2*q.x*q.z-2*q.y*q.w,  2*q.y*q.z+2*q.x*q.w,1-2*q.x*q.x-2*q.y*q.y);
end;
//############################################################################//
function quat2orotm(const q:quat):mat;
var axis,upv,rotv:vec;
ang:double;
begin
 quat_to_axis_angle(q,axis,ang);
 upv :=rotate_vec_axis_angle(tvec(0,1,0),axis,ang);
 rotv:=rotate_vec_axis_angle(tvec(0,0,1),axis,ang);

 result:=vecs2mat(rotv,upv);
 rtmatz(result,pi);
 rtmaty(result,-pi/2);
 result:=epsmat(result);
end;
//############################################################################//
begin
end.
//############################################################################//

