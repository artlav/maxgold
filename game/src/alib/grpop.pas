//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit grpop;
interface
uses math,asys,grph,palutil;
//############################################################################//
type
scale_pix=record
 pos,mul:array[0..3]of integer;
end;
scale_rec=record
 xs,ys,tw,th:integer;
 pix:array of scale_pix;
end;
//############################################################################//
function calc_border      (dst,spr:ptypspr;xp,yp,bcs,bcd:integer;   out psrc,pdst:pchar;out xs,ys,dst_line,src_line,line_siz:integer):boolean;
function calc_border_scale(dst,spr:ptypspr;xp,yp,xsz,ysz,bc:integer;out psrc,pdst:pchar;out xs,ys,xc,yc,dst_line:integer):boolean;

procedure tx_swap_bgr(p:pointer;x,y:integer);
procedure yuyv_to_rgb(src,dst:pointer;xs,ys:integer;uyvy:boolean);
function hue_shift(c:crgba;h:single):crgba;

procedure putspr_24_to_32    (dst,spr:ptypspr;xp,yp:integer);                   //Former putspr24t32
procedure putspr_16_565_to_32(dst,spr:ptypspr;xp,yp:integer);                   //Former putspr16_565t32
procedure putspr_8_to_32     (dst,spr:ptypspr;xp,yp:integer;pl:ppallette);      //Former putsprt8t32
procedure putsprt_8_to_32    (dst,spr:ptypspr;xp,yp:integer;key:byte;pl:ppallette);
procedure putspr32scl_bld   (dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
procedure putspr32scl_bli   (dst,spr:ptypspr;xp,yp,xsz,ysz:integer;szs:dword=4);
procedure putsprt32scl_nr   (dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
procedure putspr32scl_nr    (dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
procedure putspr24t32scl_bli(dst,spr:ptypspr;xp,yp,xsz,ysz:integer);

procedure scale_2x_8 (xs,ys:integer;ina,outa:pbytea);
procedure scale_2x_16(xs,ys:integer;ina,outa:pworda);
procedure scale_2x_32(xs,ys:integer;ina,outa:pbcrgba);
procedure scale_15x_32(xs,ys:integer;ina,outa:pbcrgba;do_alpha:boolean=true);

procedure scale_spr_flt_linear_32(s:ptypspr;scale:integer);
procedure scale_spr_linear_32    (s:ptypspr;scale:integer);
procedure scale_spr_linear_32_direct_core(src,dst:pointer;sw,sh,tw,th:integer);
procedure scale_spr_linear_32_direct(s:ptypspr;tw,th:integer);
procedure scale_spr_linear_32_fpu(s:ptypspr;scale:integer);

procedure scale_spr_linear_32_do_precompute(out scl:scale_rec;xs,ys,tw,th:integer);
procedure scale_spr_linear_32_precomputed_direct_core(var scl:scale_rec;src,dst:pointer;sw,sh,tw,th:integer;do_alpha:boolean=true);
procedure scale_spr_linear_32_precomputed_direct(var scl:scale_rec;s:ptypspr;tw,th:integer);
procedure scale_spr_linear_32_precomputed(var scl:scale_rec;s:ptypspr;scale:integer);

procedure scale_spr_nearest_32   (s:ptypspr;tw,th:integer);

procedure scale_spr_linear_8 (s:ptypspr;tw,th:integer);
procedure scale_spr_nearest_8(s:ptypspr;tw,th:integer);
{$ifndef paser}
procedure scaleispr8 (s:ptypuspr;siz:integer);
procedure scaleispr32(s:ptypuspr;siz:integer);
{$endif}
procedure half_spr_8    (s,d:ptypspr);
procedure half_spr_8_flt(s,d:psinglea;sxs:integer);
{$ifndef paser}
procedure img_rotate_area_cw_32(spr:ptypspr;xp,yp,xs,ys:integer);
procedure img_rotate_cw_32(spr:ptypspr);
procedure img_rotate_ccw_32(spr:ptypspr);
{$endif}
//############################################################################//
implementation
//############################################################################//
function calc_border(dst,spr:ptypspr;xp,yp,bcs,bcd:integer;out psrc,pdst:pchar;out xs,ys,dst_line,src_line,line_siz:integer):boolean;
var pdst_off,c:integer;
begin
 result:=false;
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<-spr.xs)or(xp>=dst.xs)or(yp<-spr.ys)or(yp>=dst.ys)then exit;

 xs:=spr.xs;
 ys:=spr.ys;
 dst_line:=dst.xs*bcd;
 src_line:=spr.xs*bcs;

 psrc:=spr.srf;
 pdst_off:=xp+yp*dst.xs;
 line_siz:=spr.xs;

 if xp<0 then begin xs:=xs+xp;psrc:=psrc-xp*bcs;          pdst_off:=pdst_off-xp;          line_siz:=spr.xs+xp;end;
 if yp<0 then begin ys:=ys+yp;psrc:=psrc+(-yp)*spr.xs*bcs;pdst_off:=pdst_off+(-yp)*dst.xs;end;
 if xp+spr.xs>=dst.xs then begin c:=dst.xs-xp-spr.xs;xs:=xs+c;line_siz:=line_siz+c;end;
 if yp+spr.ys>=dst.ys then begin c:=dst.ys-yp-spr.ys;ys:=ys+c;end;

 line_siz:=line_siz*bcd;
 pdst:=@pbytea(dst.srf)[pdst_off*bcd];
 result:=true;
end;
//############################################################################//
function calc_border_scale(dst,spr:ptypspr;xp,yp,xsz,ysz,bc:integer;out psrc,pdst:pchar;out xs,ys,xc,yc,dst_line:integer):boolean;
var pdst_off,c:integer;
begin
 result:=false;
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<-xsz)or(xp>=dst.xs)or(yp<-ysz)or(yp>=dst.ys)then exit;
 if xsz<=0 then exit;
 if ysz<=0 then exit;

 xc:=0;
 yc:=0;
 xs:=xsz;
 ys:=ysz;
 dst_line:=dst.xs-xsz;

 psrc:=spr.srf;
 pdst_off:=xp+yp*dst.xs;

 if xp<0 then begin xs:=xs+xp;pdst_off:=pdst_off-xp;dst_line:=dst.xs-xsz-xp;xc:=-xp; end;
 if yp<0 then begin ys:=ys+yp;pdst_off:=pdst_off+(-yp)*dst.xs;yc:=-yp;end;
 if xp+xsz>=dst.xs then begin c:=dst.xs-xp-xsz;xs:=xs+c;dst_line:=dst_line-c; end;
 if yp+ysz>=dst.ys then ys:=ys-(yp+ysz-dst.ys);

 pdst:=@pbytea(dst.srf)[pdst_off*bc];
 dst_line:=dst_line*bc;

 result:=true;
end;
//############################################################################//
procedure tx_swap_bgr(p:pointer;x,y:integer);
var xx,yy:integer;
c:pcrgba;
b:byte;
begin
 for yy:=0 to y-1 do for xx:=0 to x-1 do begin
  c:=@pbcrgba(p)[xx+yy*x];
  b:=c[0];
  c[0]:=c[2];
  c[2]:=b;
 end;
end;
//############################################################################//
procedure yuyv_to_rgb(src,dst:pointer;xs,ys:integer;uyvy:boolean);
var ptr:pbytea;
d:pbcrgba;
z,n:integer;
y,u,v:integer;
begin
	ptr:=src;
 d:=dst;

	for n:=0 to xs*ys-1 do begin
  z:=n and 1;
  if uyvy then begin
   if z=0 then y:=ptr[1] else y:=ptr[3];
   u:=ptr[0];
   v:=ptr[2];
  end else begin //yuyv
   if z=0 then y:=ptr[0] else y:=ptr[2];
   u:=ptr[1];
   v:=ptr[3];
  end;

  d[n]:=yuv_to_crgba(y,u,v);

  if z=1 then ptr:=@ptr[4];
 end;
end;
//############################################################################//
function hue_shift(c:crgba;h:single):crgba;
var u,w:single;
begin
 u:=cos(h*pi/180);
 w:=sin(h*pi/180);

 result[CLRED]  :=f256_to_col((0.299+0.701*u+0.168*w)*c[CLRED]+(0.587-0.587*u+0.330*w)*c[CLGREEN]+(0.114-0.114*u-0.497*w)*c[CLBLUE]);
 result[CLGREEN]:=f256_to_col((0.299-0.299*u-0.328*w)*c[CLRED]+(0.587+0.413*u+0.035*w)*c[CLGREEN]+(0.114-0.114*u+0.292*w)*c[CLBLUE]);
 result[CLBLUE] :=f256_to_col((0.299-0.300*u+1.250*w)*c[CLRED]+(0.587-0.588*u-1.050*w)*c[CLGREEN]+(0.114+0.886*u-0.203*w)*c[CLBLUE]);
end;
//############################################################################//
procedure putspr_24_to_32(dst,spr:ptypspr;xp,yp:integer);
var x,y:integer;
sd,sd1,xs,ys,c:integer;
a1,a2:pchar;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<-spr.xs)or(xp>=dst.xs)or(yp<-spr.ys)or(yp>=dst.ys)then exit;

 a1:=spr.srf;a2:=@pbcrgba(dst.srf)[xp+yp*dst.xs];
 sd:=(dst.xs-spr.xs)*4;sd1:=0;

 xs:=spr.xs;ys:=spr.ys;
 if(xp<0)then begin xs:=xs+xp; a1:=a1-xp*3; a2:=a2-xp*4; sd1:=-xp*3; sd:=(dst.xs-(spr.xs+xp))*4; end;
 if(yp<0)then begin ys:=ys+yp; a1:=a1+(-yp)*spr.xs*3; a2:=a2+(-yp)*dst.xs*4; end;
 if((xp+spr.xs)>=dst.xs)then begin c:=-((xp+spr.xs)-dst.xs); xs:=xs+c; sd1:=-c*3; sd:=(dst.xs-(spr.xs+c))*4 end;
 if((yp+spr.ys)>=dst.ys)then begin c:=-((yp+spr.ys)-dst.ys); ys:=ys+c; end;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   a2^:=a1^;
   a1:=a1+1;a2:=a2+1;
   a2^:=a1^;
   a1:=a1+1;a2:=a2+1;
   a2^:=a1^;
   a1:=a1+1;a2:=a2+2;
  end;
  a1:=a1+sd1;
  a2:=a2+sd;
 end;
end;
//############################################################################//
//Used in CMIPS, and where else?
//rrrrrggggggbbbbb
procedure putspr_16_565_to_32(dst,spr:ptypspr;xp,yp:integer);
var x,y:integer;
sd,sd1,xs,ys,c:integer;
a1,a2:pchar;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<-spr.xs)or(xp>=dst.xs)or(yp<-spr.ys)or(yp>=dst.ys)then exit;

 a1:=spr.srf;a2:=@pbcrgba(dst.srf)[xp+yp*dst.xs];
 sd:=(dst.xs-spr.xs)*4;sd1:=0;

 xs:=spr.xs;ys:=spr.ys;
 if(xp<0)then begin xs:=xs+xp; a1:=a1-xp*2; a2:=a2-xp*4; sd1:=-xp*2; sd:=(dst.xs-(spr.xs+xp))*4; end;
 if(yp<0)then begin ys:=ys+yp; a1:=a1+(-yp)*spr.xs*2; a2:=a2+(-yp)*dst.xs*4; end;
 if((xp+spr.xs)>=dst.xs)then begin c:=-((xp+spr.xs)-dst.xs); xs:=xs+c; sd1:=-c*2; sd:=(dst.xs-(spr.xs+c))*4 end;
 if((yp+spr.ys)>=dst.ys)then begin c:=-((yp+spr.ys)-dst.ys); ys:=ys+c; end;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   pbytea(a2)[CLRED]  :=((pword(a1)^ and $F800) shr 11)shl 3;
   pbytea(a2)[CLGREEN]:=((pword(a1)^ and $07E0) shr  5)shl 2;
   pbytea(a2)[CLBLUE] := (pword(a1)^ and $001F)        shl 3;

   pbytea(a2)[3]:=255;
   a1:=a1+2;a2:=a2+4;
  end;
  a1:=a1+sd1;
  a2:=a2+sd;
 end;
end;
//############################################################################//
//Put 8bit sprite to 32 bit screen
procedure putspr_8_to_32(dst,spr:ptypspr;xp,yp:integer;pl:ppallette);
var x,y:integer;
sd,sd1,xs,ys,c:integer;
a1,a2:pchar;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<-spr.xs)or(xp>=dst.xs)or(yp<-spr.ys)or(yp>=dst.ys)then exit;

 a1:=spr.srf;a2:=@pbcrgba(dst.srf)[xp+yp*dst.xs];
 sd:=dst.xs*4-spr.xs*4;sd1:=0;

 xs:=spr.xs;ys:=spr.ys;
 if xp<0 then begin xs:=xs+xp; a1:=a1-xp; a2:=a2-xp*4; sd1:=-xp; sd:=dst.xs*4-(spr.xs+xp)*4 end;
 if yp<0 then begin ys:=ys+yp; a1:=a1+(-yp)*spr.xs; a2:=a2+(-yp*4)*dst.xs; end;
 if (xp+spr.xs)>=dst.xs then begin c:=-((xp+spr.xs)-dst.xs); xs:=xs+c; sd1:=-c; sd:=dst.xs*4-(spr.xs+c)*4 end;
 if (yp+spr.ys)>=dst.ys then begin c:=-((yp+spr.ys)-dst.ys); ys:=ys+c; end;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   pdword(a2)^:=dword(pl^[pbyte(a1)^]);
   a1:=a1+1;a2:=a2+4;
  end;
  a1:=a1+sd1;
  a2:=a2+sd;
 end;
end;
//############################################################################//
//Put 8bit sprite to 32 bit screen
procedure putsprt_8_to_32(dst,spr:ptypspr;xp,yp:integer;key:byte;pl:ppallette);
var x,y:integer;
sd,sd1,xs,ys,c:integer;
a1,a2:pchar;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<-spr.xs)or(xp>=dst.xs)or(yp<-spr.ys)or(yp>=dst.ys)then exit;

 a1:=spr.srf;a2:=@pbcrgba(dst.srf)[xp+yp*dst.xs];
 sd:=dst.xs*4-spr.xs*4;sd1:=0;

 xs:=spr.xs;ys:=spr.ys;
 if(xp<0)then begin xs:=xs+xp; a1:=a1-xp; a2:=a2-xp*4; sd1:=-xp; sd:=dst.xs*4-(spr.xs+xp)*4 end;
 if(yp<0)then begin ys:=ys+yp; a1:=a1+(-yp)*spr.xs; a2:=a2+(-yp*4)*dst.xs; end;
 if((xp+spr.xs)>=dst.xs)then begin c:=-((xp+spr.xs)-dst.xs); xs:=xs+c; sd1:=-c; sd:=dst.xs*4-(spr.xs+c)*4 end;
 if((yp+spr.ys)>=dst.ys)then begin c:=-((yp+spr.ys)-dst.ys); ys:=ys+c; end;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   //if (pbyte(a1)^ xor key)<>0 then
    pdword(a2)^:=dword(pl^[pbyte(a1)^]);
   a1:=a1+1;a2:=a2+4;
  end;
  a1:=a1+sd1;
  a2:=a2+sd;
 end;
end;
//############################################################################//
//############################################################################//
//Put sprite scaled - bilinear float
//1.8s x100 400x400
procedure putspr32scl_bld(dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
var dst_line,ys,xs,xc,yc:integer;
psrc,pdst:pchar;
u,v,ur,vr,u_ratio,v_ratio,u_opposite,v_opposite:double;
x,y,i,xa,ya,yo,yo1:integer;
begin
 if not calc_border_scale(dst,spr,xp,yp,xsz,ysz,4,psrc,pdst,xs,ys,xc,yc,dst_line) then exit;

 ur:=spr.xs/xsz;
 vr:=spr.ys/ysz;
 for y:=yc to ys+yc-1 do begin
  v:=y*vr;
  ya:=floor(v);
  v_ratio:=v-ya;
  v_opposite:=1-v_ratio;
  yo:=ya*spr.xs;
  yo1:=(ya+1)*spr.xs;
  for x:=xc to xs+xc-1 do begin
   u:=x*ur;
   xa:=floor(u);
   u_ratio:=u-xa;
   u_opposite:=1-u+xa;

   for i:=0 to 2 do
    pbyte(pdst+i)^:=round((pbyte(psrc+(xa+yo )*4+i)^*u_opposite+pbyte(psrc+(xa+1+yo )*4+i)^*u_ratio)*v_opposite+
                          (pbyte(psrc+(xa+yo1)*4+i)^*u_opposite+pbyte(psrc+(xa+1+yo1)*4+i)^*u_ratio)*v_ratio);

   pdst:=pdst+4;
  end;
  pdst:=pdst+dst_line;
 end;
end;
//############################################################################//
//Put sprite scaled - bilinear integer
//0.5s x100 400x400
procedure putspr32scl_bli(dst,spr:ptypspr;xp,yp,xsz,ysz:integer;szs:dword=4);
var dst_line,ys,xs,xc,yc:integer;
psrc,pdst,s1,s2:pchar;
u,v,ur,vr,u_ratio,v_ratio,u_opposite,v_opposite:integer;
x,y,i,xa,ya,yo,yo1:integer;
begin
 if not calc_border_scale(dst,spr,xp,yp,xsz,ysz,4,psrc,pdst,xs,ys,xc,yc,dst_line) then exit;

 ur:=((spr.xs shl 8) div xsz);
 vr:=((spr.ys shl 8) div ysz);
 for y:=yc to ys+yc-1 do begin   //FIXME? Used to be -2, might need some range checking
  v:=y*vr;
  ya:=v shr 8;
  v_ratio:=v-(ya shl 8);
  v_opposite:=256-v_ratio;

  yo:=dword(ya*spr.xs)*szs;
  yo1:=dword((ya+1)*spr.xs)*szs;

  for x:=xc to xs+xc-1 do begin
   u:=x*ur;
   xa:=u shr 8;
   u_ratio:=u-(xa shl 8);
   u_opposite:=256-u_ratio;
   xa:=dword(xa)*szs;

   for i:=0 to 2 do begin
    s1:=psrc+xa+yo +i;
    s2:=psrc+xa+yo1+i;
    pbyte(pdst+i)^:=(
                     (pbyte(s1)^*u_opposite+pbyte(s1+szs)^*u_ratio)*v_opposite
                     +
                     (pbyte(s2)^*u_opposite+pbyte(s2+szs)^*u_ratio)*v_ratio
                     )shr 16;
   end;

   pdst:=pdst+szs;
  end;

  pdst:=pdst+dst_line;
 end;
end;
//############################################################################//
//Put sprite scaled - nearest
//0.1s x100 400x400
procedure putspr32scl_nr(dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
var dst_line,ys,xs,xc,yc:integer;
psrc,pdst:pchar;
x,y,ya,yo,xac,yac:integer;
begin
 if not calc_border_scale(dst,spr,xp,yp,xsz,ysz,4,psrc,pdst,xs,ys,xc,yc,dst_line) then exit;

 xac:=((spr.xs shl 8) div xsz);
 yac:=((spr.ys shl 8) div ysz);
 for y:=yc to ys+yc-1 do begin
  ya:=(y shl 8)*yac shr 16;
  yo:=ya*spr.xs;
  for x:=xc to xs+xc-1 do begin
   pdword(pdst)^:=pdword(psrc+((x shl 8)*xac shr 16+yo)*4)^;
   pdst:=pdst+4;
  end;
  pdst:=pdst+dst_line;
 end;
end;
//############################################################################//
//Put sprite scaled - nearest, transparent
//0.1s x100 400x400
procedure putsprt32scl_nr(dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
var dst_line,ys,xs,xc,yc:integer;
psrc,pdst:pchar;
x,y,ya,yo,xac,yac:integer;
n:dword;
begin
 if not calc_border_scale(dst,spr,xp,yp,xsz,ysz,4,psrc,pdst,xs,ys,xc,yc,dst_line) then exit;

 xac:=((spr.xs shl 8) div xsz);
 yac:=((spr.ys shl 8) div ysz);
 for y:=yc to ys+yc-1 do begin
  ya:=(y shl 8)*yac shr 16;
  yo:=ya*spr.xs;
  for x:=xc to xs+xc-1 do begin
   n:=pdword(psrc+((x shl 8)*xac shr 16+yo)*4)^;
   if pcrgba(@n)[3]<>0 then pdword(pdst)^:=n;
   pdst:=pdst+4;
  end;
  pdst:=pdst+dst_line;
 end;
end;
//############################################################################//
procedure putspr24t32scl_bli(dst,spr:ptypspr;xp,yp,xsz,ysz:integer);
begin
 putspr32scl_bli(dst,spr,xp,yp,xsz,ysz,3);
end;
//############################################################################//
procedure scale_2x_8(xs,ys:integer;ina,outa:pbytea);
var x,y,ym,yp,xm,xp:integer;
e:array[0..3]of byte;
bv,dv,ev,fv,hv:byte;
begin
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  if x=0 then xm:=0 else xm:=x-1;
  if x=xs-1 then xp:=xs-1 else xp:=x+1;
  if y=0 then ym:=0 else ym:=y-1;
  if y=ys-1 then yp:=ys-1 else yp:=y+1;
  bv:=ina[x+ym*xs];
  dv:=ina[xm+y*xs];
  ev:=ina[x+y*xs];
  fv:=ina[xp+y*xs];
  hv:=ina[x+yp*xs];

  e[0]:=ev;
  e[1]:=ev;
  e[2]:=ev;
  e[3]:=ev;
  if(bv<>hv)and(dv<>fv)then begin
   if dv=bv then e[0]:=dv;
   if bv=fv then e[1]:=fv;
   if dv=hv then e[2]:=dv;
   if hv=fv then e[3]:=fv;
  end;

  outa[x*2+0+(y*2+0)*xs*2]:=e[0];
  outa[x*2+1+(y*2+0)*xs*2]:=e[1];
  outa[x*2+0+(y*2+1)*xs*2]:=e[2];
  outa[x*2+1+(y*2+1)*xs*2]:=e[3];
 end;
end;
//############################################################################//
procedure scale_2x_16(xs,ys:integer;ina,outa:pworda);
var x,y,ym,yp,xm,xp:integer;
e:array[0..3]of word;
bv,dv,ev,fv,hv:word;
begin
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  if x=0 then xm:=0 else xm:=x-1;
  if x=xs-1 then xp:=xs-1 else xp:=x+1;
  if y=0 then ym:=0 else ym:=y-1;
  if y=ys-1 then yp:=ys-1 else yp:=y+1;
  bv:=dword(ina[x+ym*xs]);
  dv:=dword(ina[xm+y*xs]);
  ev:=dword(ina[x+y*xs]);
  fv:=dword(ina[xp+y*xs]);
  hv:=dword(ina[x+yp*xs]);

  e[0]:=ev;
  e[1]:=ev;
  e[2]:=ev;
  e[3]:=ev;
  if(bv<>hv)and(dv<>fv)then begin
   if dv=bv then e[0]:=dv;
   if bv=fv then e[1]:=fv;
   if dv=hv then e[2]:=dv;
   if hv=fv then e[3]:=fv;
  end;

  outa[x*2+0+(y*2+0)*xs*2]:=e[0];
  outa[x*2+1+(y*2+0)*xs*2]:=e[1];
  outa[x*2+0+(y*2+1)*xs*2]:=e[2];
  outa[x*2+1+(y*2+1)*xs*2]:=e[3];
 end;
end;
//############################################################################//
procedure scale_2x_32(xs,ys:integer;ina,outa:pbcrgba);
var x,y,ym,yp,xm,xp:integer;
e:array[0..3]of dword;
bv,dv,ev,fv,hv:dword;
begin
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  if x=0 then xm:=0 else xm:=x-1;
  if x=xs-1 then xp:=xs-1 else xp:=x+1;
  if y=0 then ym:=0 else ym:=y-1;
  if y=ys-1 then yp:=ys-1 else yp:=y+1;
  bv:=dword(ina[x+ym*xs]);
  dv:=dword(ina[xm+y*xs]);
  ev:=dword(ina[x+y*xs]);
  fv:=dword(ina[xp+y*xs]);
  hv:=dword(ina[x+yp*xs]);

  e[0]:=ev;
  e[1]:=ev;
  e[2]:=ev;
  e[3]:=ev;
  if(bv<>hv)and(dv<>fv)then begin
   if dv=bv then e[0]:=dv;
   if bv=fv then e[1]:=fv;
   if dv=hv then e[2]:=dv;
   if hv=fv then e[3]:=fv;
  end;

  outa[x*2+0+(y*2+0)*xs*2]:=crgba(e[0]);
  outa[x*2+1+(y*2+0)*xs*2]:=crgba(e[1]);
  outa[x*2+0+(y*2+1)*xs*2]:=crgba(e[2]);
  outa[x*2+1+(y*2+1)*xs*2]:=crgba(e[3]);
 end;
end;
//############################################################################//
//Assumes the sizes are divisible by 2 and 3
procedure scale_15x_32(xs,ys:integer;ina,outa:pbcrgba;do_alpha:boolean=true);
var x,y,xc,yc,xp,yp,xn,yn,xsn,y0,y1,y2:integer;
a,b,c,d,ab,ac,bd,cd,e:crgba;
begin
 if xs mod 2=1 then exit;
 if ys mod 2=1 then exit;
 xsn:=xs*3 div 2;
 for y:=0 to ys div 2-1 do begin 
  yc:=y*2;
  yp:=y*2+1;
  yn:=y*3;
  y0:=(yn+0)*xsn;
  y1:=(yn+1)*xsn;
  y2:=(yn+2)*xsn;
  for x:=0 to xs div 2-1 do begin
   xc:=x*2;
   xp:=x*2+1;
   xn:=x*3;

   a:=ina[xc+yc*xs];b:=ina[xp+yc*xs];
   c:=ina[xc+yp*xs];d:=ina[xp+yp*xs];

   ab[0]:=(a[0]+b[0]) shr 1;ac[0]:=(a[0]+c[0]) shr 1;bd[0]:=(b[0]+d[0]) shr 1;cd[0]:=(c[0]+d[0]) shr 1;e[0]:=(ab[0]+ac[0]+bd[0]+cd[0]) shr 2;
   ab[1]:=(a[1]+b[1]) shr 1;ac[1]:=(a[1]+c[1]) shr 1;bd[1]:=(b[1]+d[1]) shr 1;cd[1]:=(c[1]+d[1]) shr 1;e[1]:=(ab[1]+ac[1]+bd[1]+cd[1]) shr 2;
   ab[2]:=(a[2]+b[2]) shr 1;ac[2]:=(a[2]+c[2]) shr 1;bd[2]:=(b[2]+d[2]) shr 1;cd[2]:=(c[2]+d[2]) shr 1;e[2]:=(ab[2]+ac[2]+bd[2]+cd[2]) shr 2;
   if do_alpha then begin ab[3]:=(a[3]+b[3]) shr 1;ac[3]:=(a[3]+c[3]) shr 1;bd[3]:=(b[3]+d[3]) shr 1;cd[3]:=(c[3]+d[3]) shr 1;e[3]:=(ab[3]+ac[3]+bd[3]+cd[3]) shr 2;end;

   outa[xn+0+y0]:=a; outa[xn+1+y0]:=ab;outa[xn+2+y0]:=b;
   outa[xn+0+y1]:=ac;outa[xn+1+y1]:=e; outa[xn+2+y1]:=bd;
   outa[xn+0+y2]:=c; outa[xn+1+y2]:=cd;outa[xn+2+y2]:=d;
  end;
 end;
end;
//############################################################################//
procedure scale_spr_flt_linear_32(s:ptypspr;scale:integer);
var r,c,r1,c1,idx:integer;
ori_r,ori_c,dr,dc,x1,x2,x3,x4:single;
p:psinglea;
begin
 getmem(p,s.xs*scale*s.ys*scale*4);

 for r:=0 to s.ys*scale-1 do for c:=0 to s.xs*scale-1 do begin
  ori_r:=r/scale;
  ori_c:=c/scale;
  r1:=trunc(ori_r);
  c1:=trunc(ori_c);
  dr:=ori_r-r1;
  dc:=ori_c-c1;

  idx:=r1*s.xs+c1;
  x1:=(1-dr)*(1-dc)*psinglea(s.srf)[idx];
  if r1<s.ys-1 then x2:=psinglea(s.srf)[idx+s.xs] else x2:=psinglea(s.srf)[idx];
  x2:=dr*(1-dc)*x2;
  if c1<s.xs-1 then x3:=psinglea(s.srf)[idx+1] else x3:=psinglea(s.srf)[idx];
  x3:=dc*(1-dr)*x3;
  if (c1<s.xs-1)and(r1<s.ys-1) then x4:=psinglea(s.srf)[idx+s.xs+1] else x4:=psinglea(s.srf)[idx];
  x4:=dc*dr*x4;

  p[r*s.xs*scale+c]:=x1+x2+x3+x4;
 end;

 freemem(s.srf);
 s.srf:=p;
 s.xs:=s.xs*scale;
 s.ys:=s.ys*scale;
end;
//############################################################################//
procedure scale_spr_linear_32_fpu(s:ptypspr;scale:integer);
var r,c,r1,c1,idx,k,f:integer;
ori_r,ori_c,dr,dc,x1,x2,x3,x4:single;
p:pbcrgba;
begin
 getmem(p,s.xs*scale*s.ys*scale*4);

 for r:=0 to s.ys*scale-1 do for c:=0 to s.xs*scale-1 do begin
  ori_r:=r/scale;
  ori_c:=c/scale;
  r1:=trunc(ori_r);
  c1:=trunc(ori_c);
  dr:=ori_r-r1;
  dc:=ori_c-c1;

  idx:=r1*s.xs+c1;
  for k:=0 to 3 do begin

   x1:=(1-dr)*(1-dc)*pbcrgba(s.srf)[idx][k]/255;

   if r1<s.ys-1 then x2:=pbcrgba(s.srf)[idx+s.xs][k]/255 else x2:=pbcrgba(s.srf)[idx][k]/255;
   x2:=dr*(1-dc)*x2;

   if c1<s.xs-1 then x3:=pbcrgba(s.srf)[idx+1][k]/255 else x3:=pbcrgba(s.srf)[idx][k]/255;
   x3:=dc*(1-dr)*x3;

   if (c1<s.xs-1)and(r1<s.ys-1) then x4:=pbcrgba(s.srf)[idx+s.xs+1][k]/255 else x4:=pbcrgba(s.srf)[idx][k]/255;
   x4:=dc*dr*x4;

   f:=round(255*(x1+x2+x3+x4));
   if f<0 then f:=0; if f>255 then f:=255;
   p[r*s.xs*scale+c][k]:=f;
  end;
 end;

 freemem(s.srf);
 s.srf:=p;
 s.xs:=s.xs*scale;
 s.ys:=s.ys*scale;
end; 
//############################################################################//
//BROKEN for non-rectangular resizes!
procedure scale_spr_linear_32_direct_core(src,dst:pointer;sw,sh,tw,th:integer);
const factor=1024;
var r,c,r1,c1,idx,k,f:integer;
ori_r,ori_c,dr,dc,x1,x2,x3,x4:integer;
begin
 for r:=0 to th-1 do begin
  for c:=0 to tw-1 do begin
   ori_r:=round((r*factor)/(tw/sw));
   ori_c:=round((c*factor)/(th/sh));
   r1:=ori_r div factor;
   c1:=ori_c div factor;
   dr:=ori_r-r1*factor;
   dc:=ori_c-c1*factor;

   idx:=r1*sw+c1;
   for k:=0 to 3 do begin
    x1:=factor*pbcrgba(src)[idx][k] div 255;
    x1:=(factor-dr)*(factor-dc)*x1 div (factor*factor);

    if r1<sh-1 then x2:=factor*pbcrgba(src)[idx+sw][k] div 255 else x2:=factor*pbcrgba(src)[idx][k] div 255;
    x2:=dr*(factor-dc)*x2 div (factor*factor);

    if c1<sw-1 then x3:=factor*pbcrgba(src)[idx+1][k] div 255 else x3:=factor*pbcrgba(src)[idx][k] div 255;
    x3:=dc*(factor-dr)*x3 div (factor*factor);

    if (c1<sw-1)and(r1<sh-1) then x4:=factor*pbcrgba(src)[idx+sw+1][k] div 255 else x4:=factor*pbcrgba(src)[idx][k] div 255;
    x4:=dc*dr*x4 div (factor*factor);

    f:=255*(x1+x2+x3+x4) div factor;
    if f<0 then f:=0; if f>255 then f:=255;
    pbcrgba(dst)[r*tw+c][k]:=f;
   end;
  end;
 end;
end;
//############################################################################//
//BROKEN for non-rectangular resizes!
procedure scale_spr_linear_32_direct(s:ptypspr;tw,th:integer);
var p:pbcrgba;
begin
 getmem(p,tw*th*4);  
 scale_spr_linear_32_direct_core(s.srf,p,s.xs,s.ys,tw,th);
 freemem(s.srf);
 s.srf:=p;
 s.xs:=tw;
 s.ys:=th;
end;
//############################################################################//
//BROKEN for non-rectangular resizes!
procedure scale_spr_linear_32_do_precompute(out scl:scale_rec;xs,ys,tw,th:integer);
const factor=1024;
var r,c,r1,c1,idx:integer;
ori_r,ori_c,dr,dc:integer;
begin
 scl.xs:=xs;
 scl.ys:=ys;
 scl.tw:=tw;
 scl.th:=th;
 setlength(scl.pix,tw*th);
 for r:=0 to th-1 do begin
  for c:=0 to tw-1 do begin
   ori_r:=round((r*factor)/(tw/xs));
   ori_c:=round((c*factor)/(th/ys));
   r1:=ori_r div factor;
   c1:=ori_c div factor;
   dr:=ori_r-r1*factor;
   dc:=ori_c-c1*factor;

   idx:=r1*xs+c1;

   scl.pix[r*tw+c].pos[0]:=idx;
   scl.pix[r*tw+c].mul[0]:=(factor-dr)*(factor-dc);

   if r1<ys-1 then scl.pix[r*tw+c].pos[1]:=idx+xs else scl.pix[r*tw+c].pos[1]:=idx;
   scl.pix[r*tw+c].mul[1]:=dr*(factor-dc);

   if c1<xs-1 then scl.pix[r*tw+c].pos[2]:=idx+1 else scl.pix[r*tw+c].pos[2]:=idx;
   scl.pix[r*tw+c].mul[2]:=dc*(factor-dr);

   if (c1<xs-1)and(r1<ys-1) then scl.pix[r*tw+c].pos[3]:=idx+xs+1 else scl.pix[r*tw+c].pos[3]:=idx;
   scl.pix[r*tw+c].mul[3]:=dc*dr;
  end;
 end;
end;
//############################################################################//
procedure scale_spr_linear_32_precomputed_direct_core(var scl:scale_rec;src,dst:pointer;sw,sh,tw,th:integer;do_alpha:boolean=true);
const factor=1024;  //shr 10
var i:integer;
mx,px:pinta;
cl:array[0..3]of crgba;
d:pcrgba;
begin
 if (scl.xs<>sw)or(scl.ys<>sh)or(scl.tw<>tw)or(scl.th<>th) then scale_spr_linear_32_do_precompute(scl,sw,sh,tw,th);

 d:=@pbcrgba(dst)[0]; 
 mx:=@scl.pix[0].mul[0];
 px:=@scl.pix[0].pos[0];
 for i:=0 to th*tw-1 do begin
  cl[0]:=pbcrgba(src)[px[0]];
  cl[1]:=pbcrgba(src)[px[1]];
  cl[2]:=pbcrgba(src)[px[2]];
  cl[3]:=pbcrgba(src)[px[3]];
  d[0]:=(mx[0]*cl[0][0]+mx[1]*cl[1][0]+mx[2]*cl[2][0]+mx[3]*cl[3][0]) shr 20;
  d[1]:=(mx[0]*cl[0][1]+mx[1]*cl[1][1]+mx[2]*cl[2][1]+mx[3]*cl[3][1]) shr 20;
  d[2]:=(mx[0]*cl[0][2]+mx[1]*cl[1][2]+mx[2]*cl[2][2]+mx[3]*cl[3][2]) shr 20;
  if do_alpha then d[3]:=(mx[0]*cl[0][3]+mx[1]*cl[1][3]+mx[2]*cl[2][3]+mx[3]*cl[3][3]) shr 20;
  d:=pointer(intptr(d)+4);
  px:=pointer(intptr(px)+sizeof(scale_pix));
  mx:=pointer(intptr(mx)+sizeof(scale_pix));
 end;
end;
//############################################################################//
procedure scale_spr_linear_32_precomputed_direct(var scl:scale_rec;s:ptypspr;tw,th:integer);
var p:pbcrgba;
begin
 getmem(p,tw*th*4);  
 scale_spr_linear_32_precomputed_direct_core(scl,s.srf,p,s.xs,s.ys,tw,th);
 freemem(s.srf);
 s.srf:=p;
 s.xs:=tw;
 s.ys:=th;
end;
//############################################################################//
procedure scale_spr_linear_32_precomputed(var scl:scale_rec;s:ptypspr;scale:integer);
begin
 scale_spr_linear_32_precomputed_direct(scl,s,s.xs*scale,s.ys*scale);
end;
//############################################################################//
procedure scale_spr_linear_32(s:ptypspr;scale:integer);
begin
 scale_spr_linear_32_direct(s,s.xs*scale,s.ys*scale);
end;
//############################################################################//
//Scale sprite
procedure scale_spr_nearest_32(s:ptypspr;tw,th:integer);
var x,y:integer;
p:pdworda;
wc,hc:integer;
begin
 if s=nil then exit;
 if s.srf=nil then exit;
 getmem(p,tw*th*4);
 wc:=(100*s.xs) div tw;
 hc:=(100*s.ys) div th;

 for y:=0 to th-1 do for x:=0 to tw-1 do p[x+y*tw]:=pdworda(s.srf)[(wc*x)div 100+((hc*y) div 100)*s.xs];

 freemem(s.srf);
 s.srf:=p;
 s.cx:=(s.cx*tw) div s.xs;
 s.cy:=(s.cy*th) div s.ys;
 s.xs:=tw;
 s.ys:=th;
end;
//############################################################################//
//Very slow, nearest_in_thepal takes a while
procedure scale_spr_linear_8(s:ptypspr;tw,th:integer);
const factor=1000;
var r,c,r1,c1,idx,k,f:integer;
ori_r,ori_c,dr,dc,x1,x2,x3,x4:integer;
xscale,yscale:integer;
p:pbytea;
cli:array[0..3]of crgb;
clo:crgb;
begin
 getmem(p,tw*th*4);
 xscale:=round((tw/s.xs)*factor);
 yscale:=round((th/s.ys)*factor);

 for r:=0 to th-1 do begin
  for c:=0 to tw-1 do begin
   ori_r:=(r*factor*factor) div yscale;
   ori_c:=(c*factor*factor) div xscale;
   r1:=ori_r div factor;
   c1:=ori_c div factor;
   dr:=ori_r-r1*factor;
   dc:=ori_c-c1*factor;

   idx:=r1*s.xs+c1;
   cli[0]:=thepal[pbytea(s.srf)[idx]];
   if r1<s.ys-1 then cli[1]:=thepal[pbytea(s.srf)[idx+s.xs]] else cli[1]:=cli[0];
   if c1<s.xs-1 then cli[2]:=thepal[pbytea(s.srf)[idx+1]] else cli[2]:=cli[0];
   if (c1<s.xs-1)and(r1<s.ys-1) then cli[3]:=thepal[pbytea(s.srf)[idx+s.xs+1]] else cli[3]:=cli[0];
   for k:=0 to 2 do begin
    x1:=factor*cli[0][k] div 255;x1:=(factor-dr)*(factor-dc)*x1 div (factor*factor);
    x2:=factor*cli[1][k] div 255;x2:=        dr *(factor-dc)*x2 div (factor*factor);
    x3:=factor*cli[2][k] div 255;x3:=(factor-dr)*        dc *x3 div (factor*factor);
    x4:=factor*cli[3][k] div 255;x4:=        dr *        dc *x4 div (factor*factor);

    f:=255*(x1+x2+x3+x4) div factor;
    if f<0 then f:=0;
    if f>255 then f:=255;
    clo[k]:=f;
   end;
   p[r*tw+c]:=nearest_in_thepal(clo);
  end;
 end;

 freemem(s.srf);
 s.srf:=p;
 s.xs:=tw;
 s.ys:=th;
end;
//############################################################################//
//Scale sprite
procedure scale_spr_nearest_8(s:ptypspr;tw,th:integer);
var x,y,o,sz:integer;
p:pbytea;
wc,hc:integer;
begin
 if s=nil then exit;
 if s.srf=nil then exit;
 getmem(p,tw*th);
 wc:=(100*s.xs) div tw;
 hc:=(100*s.ys) div th;

 sz:=s.xs*s.ys;

 for y:=0 to th-1 do for x:=0 to tw-1 do begin
  o:=(wc*x) div 100+((hc*y) div 100)*s.xs;
  if o<sz then p[x+y*tw]:=pbytea(s.srf)[o];
 end;
 freemem(s.srf);

 s.srf:=p;
 s.cx:=(s.cx*tw) div s.xs;
 s.cy:=(s.cy*th) div s.ys;
 s.xs:=tw;
 s.ys:=th;
end;
//############################################################################//
//Scale U-sprite for I-image
{$ifndef paser}
procedure scaleispr8(s:ptypuspr;siz:integer);
var x,y,i:integer;
p:pbytea;
begin
 if s=nil then exit;
 if siz=0 then siz:=1;
 if siz=1 then begin
  for i:=0 to s.cnt-1 do begin
   getmem(p,s.sprc[i].xs*s.sprc[i].ys div 4);
   for y:=0 to s.sprc[i].ys div 2-1 do for x:=0 to s.sprc[i].xs div 2-1 do
    p[x+y*(s.sprc[i].xs div 2)]:=pbytea(s.sprc[i].srf)[2*x+2*y*(s.sprc[i].xs)];
   freemem(s.sprc[i].srf);
   s.sprc[i].srf:=p;
   s.sprc[i].xs:=s.sprc[i].xs div 2;
   s.sprc[i].ys:=s.sprc[i].ys div 2;
   s.sprc[i].cx:=s.sprc[i].cx div 2;
   s.sprc[i].cy:=s.sprc[i].cy div 2;
  end;
 end;
 if siz=2 then begin
  for i:=0 to s.cnt-1 do begin
   getmem(p,s.sprc[i].xs*s.sprc[i].ys div 16);
   for y:=0 to s.sprc[i].ys div 4-1 do for x:=0 to s.sprc[i].xs div 4-1 do
    p[x+y*(s.sprc[i].xs div 4)]:=pbytea(s.sprc[i].srf)[4*x+4*y*(s.sprc[i].xs)];
   freemem(s.sprc[i].srf);
   s.sprc[i].srf:=p;
   s.sprc[i].xs:=s.sprc[i].xs div 4;
   s.sprc[i].ys:=s.sprc[i].ys div 4;
   s.sprc[i].cx:=s.sprc[i].cx div 4;
   s.sprc[i].cy:=s.sprc[i].cy div 4;
  end;
 end;
end;
//############################################################################//
//############################################################################//
//Scale U-sprite for I-image
procedure scaleispr32(s:ptypuspr;siz:integer);
var x,y,i:integer;
p:pbytea;
begin
 if s=nil then exit;
 if siz=1 then begin
  for i:=0 to s.cnt-1 do begin
   getmem(p,s.sprc[i].xs*s.sprc[i].ys div 4);
   for y:=0 to s.sprc[i].ys div 2-1 do for x:=0 to s.sprc[i].xs div 2-1 do
    p[x+y*(s.sprc[i].xs div 2)]:=pbytea(s.sprc[i].srf)[2*x+2*y*(s.sprc[i].xs)];
   freemem(s.sprc[i].srf);
   s.sprc[i].srf:=p;//p:=nil;
   s.sprc[i].xs:=s.sprc[i].xs div 2;
   s.sprc[i].ys:=s.sprc[i].ys div 2;
   s.sprc[i].cx:=s.sprc[i].cx div 2;
   s.sprc[i].cy:=s.sprc[i].cy div 2;
  end;
 end;
 if siz=2 then begin
  for i:=0 to s.cnt-1 do begin
   getmem(p,s.sprc[i].xs*s.sprc[i].ys div 16);
   for y:=0 to s.sprc[i].ys div 4-1 do for x:=0 to s.sprc[i].xs div 4-1 do
    p[x+y*(s.sprc[i].xs div 4)]:=pbytea(s.sprc[i].srf)[4*x+4*y*(s.sprc[i].xs)];
   freemem(s.sprc[i].srf);
   s.sprc[i].srf:=p;//p:=nil;
   s.sprc[i].xs:=s.sprc[i].xs div 4;
   s.sprc[i].ys:=s.sprc[i].ys div 4;
   s.sprc[i].cx:=s.sprc[i].cx div 4;
   s.sprc[i].cy:=s.sprc[i].cy div 4;
  end;
 end;
end;
{$endif}
//############################################################################//
procedure half_spr_8(s,d:ptypspr);
var x,y:integer;
p:pbytea;
begin
 if s=nil then exit;
 if s.srf=nil then exit;

 getmem(p,s.xs*s.ys div 4);
 if d.srf<>nil then freemem(d.srf);
 d.srf:=p;
 d.xs:=s.xs div 2;
 d.ys:=s.ys div 2;

 for y:=0 to s.ys div 2-1 do for x:=0 to s.xs div 2-1 do p[x+y*d.xs]:=pbytea(s.srf)[x*2+y*2*s.xs];
end;
//############################################################################//
procedure half_spr_8_flt(s,d:psinglea;sxs:integer);
var x,y,dxs:integer;
a,b:psinglea;
begin
 dxs:=sxs div 2;
 for y:=0 to sxs div 2-1 do begin
  a:=@d[y*dxs];
  b:=@s[2*y*sxs];
  for x:=0 to sxs div 2-1 do a[x]:=b[x*2];
 end;
end;
//############################################################################//
{$ifndef paser}
procedure img_rotate_area_cw_32(spr:ptypspr;xp,yp,xs,ys:integer);
var x,y,x1,y1:integer;
p:pbcrgba;
t:array of crgba;
begin
 if spr=nil then exit;
 if spr.srf=nil then exit;

 setlength(t,xs*ys);
 p:=spr.srf;
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  x1:=ys-1-y;
  y1:=x;
  t[x1+y1*xs]:=p[xp+x+(yp+y)*spr.xs];
 end;
 for y:=0 to ys-1 do for x:=0 to xs-1 do p[xp+x+(yp+y)*spr.xs]:=t[x+y*xs];
end;
//############################################################################//
procedure img_rotate_cw_32(spr:ptypspr);
var x,y,x1,y1:integer;
p:pbcrgba;
t:array of crgba;
begin
 if spr=nil then exit;
 if spr.srf=nil then exit;

 setlength(t,spr.xs*spr.ys);
 p:=spr.srf;
 for y:=0 to spr.ys-1 do for x:=0 to spr.xs-1 do begin
  x1:=spr.ys-1-y;
  y1:=x;
  t[x1+y1*spr.ys]:=p[x+y*spr.xs];
 end;
 for y:=0 to spr.xs-1 do for x:=0 to spr.ys-1 do p[x+y*spr.ys]:=t[x+y*spr.ys];

 x:=spr.xs;
 spr.xs:=spr.ys;
 spr.ys:=x;
end;
//############################################################################//
procedure img_rotate_ccw_32(spr:ptypspr);
var x,y,x1,y1:integer;
p:pbcrgba;
t:array of crgba;
begin
 if spr=nil then exit;
 if spr.srf=nil then exit;

 setlength(t,spr.xs*spr.ys);
 p:=spr.srf;
 for y:=0 to spr.ys-1 do for x:=0 to spr.xs-1 do begin
  x1:=y;
  y1:=spr.xs-1-x;
  t[x1+y1*spr.ys]:=p[x+y*spr.xs];
 end;
 for y:=0 to spr.xs-1 do for x:=0 to spr.ys-1 do p[x+y*spr.ys]:=t[x+y*spr.ys];

 x:=spr.xs;
 spr.xs:=spr.ys;
 spr.ys:=x;
end;
{$endif}
//############################################################################//
begin
end.
//############################################################################//
