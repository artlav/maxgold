//############################################################################//
unit graph8;
{$ifdef FPC}{$MODE delphi}{$endif}
interface
uses math,asys,maths,grph,palutil,grpop;
//############################################################################//
procedure putspr8(dst,spr:ptypspr;xp,yp:integer);
procedure putdoublespr8(dst,spr:ptypspr;xp,yp:integer);
procedure puthalfspr8(dst,spr:ptypspr;xp,yp:integer);
procedure putsprsten8(dst,spr:ptypspr;xp,yp,xh,yh,xos,yos:integer);

procedure putsprt8(dst,spr:ptypspr;xp,yp:integer;palo:shortint=0;trans_color:byte=0);
procedure putsprtx8(dst,spr:ptypspr;xp,yp:integer;palx:ppalxtyp);
procedure putsprt8z(dst,spr:ptypspr;xp,yp:integer);

procedure putsprtcut8(dst,spr:ptypspr;xp,yp,xh,yh,xs,ys:integer;key:byte);
procedure putsprcut8(dst,spr:ptypspr;xp,yp,xh,yh,xs,ys:integer);
procedure putmov8(dst:ptypspr;spr:pshortvid8typ;xp,yp,fr:integer);

procedure draaline8(dst:ptypspr;x1,y1,x2,y2:double;col:byte);
procedure drline8(dst:ptypspr;x1,y1,x2,y2:integer;col:byte);
procedure drline8_skip(dst:ptypspr;x1,y1,x2,y2,nc:integer;col:byte);
procedure dr_line_thk_8(dst:ptypspr;x1,y1,x2,y2,t:integer;col:byte);

procedure drfrect8(dst:ptypspr;x1,y1,x2,y2:integer;col:byte);
procedure drfrectx8(dst:ptypspr;x,y,xs,ys:integer;col:byte);
procedure drrect8(dst:ptypspr;x1,y1,x2,y2:integer;col:byte);
procedure drrectx8(dst:ptypspr;x,y,xs,ys:integer;col:byte);
procedure drxrect8(dst:ptypspr;xh,yh,xl,yl:integer;cl:byte);

procedure drcirc8(dst:ptypspr;x,y,r:integer;col:byte);
procedure drcirc8_skip(dst:ptypspr;x,y,r,nc:integer;col:byte);
procedure drfcirc8(dst:ptypspr;x,y,r:integer;col:byte);
procedure dr_circ_thk_8(dst:ptypspr;x,y,r,t:integer;col:byte);

procedure drtriangle8(dst:ptypspr;x1,y1,x2,y2,x3,y3:integer;col:byte);

procedure drsphcf8(dst:ptypspr;x,y,r:integer;sun:vec;col:byte);
//procedure drellp(x1,y1,x2,y2:integer;col:crgba); overload;
procedure drpix8(dst:ptypspr;x,y:integer;col:byte);
procedure drpolyflat8(dst:ptypspr;x1,y1,x2,y2,x3,y3:integer;col:byte;tx:ptypspr=nil);
procedure drpolyflatf8(dst:ptypspr;x1,y1,x2,y2,x3,y3:double;col:byte;tx:ptypspr=nil);
//############################################################################//
implementation
//############################################################################//
//Put sprite flat
procedure putspr8(dst,spr:ptypspr;xp,yp:integer);
var y,dst_line,src_line,line_siz,ys,xs:integer;
psrc,pdst:pchar;
begin
 if dst=nil then exit;
 if spr=nil then exit;
 if not calc_border(dst,spr,xp,yp,1,1,psrc,pdst,xs,ys,dst_line,src_line,line_siz) then exit;
 for y:=0 to ys-1 do begin fastmove(psrc^,pdst^,line_siz);psrc:=psrc+src_line;pdst:=pdst+dst_line;end;
 tdu:=tdu+ys*xs;
end;
//############################################################################//
//FIXME: Optimize!
procedure putdoublespr8(dst,spr:ptypspr;xp,yp:integer);
var x,y,s,sd,ys,xs:integer;
a1,a2:pbytea;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<0)or(xp>=dst.xs-spr.xs*2)or(yp<0)or(yp>=dst.ys-spr.ys*2)then exit;

 a1:=spr.srf;
 a2:=@pbytea(dst.srf)[xp+yp*dst.xs];
 s:=spr.xs;
 sd:=dst.xs;
 xs:=spr.xs*2;
 ys:=spr.ys*2;

 for y:=0 to ys-1 do for x:=0 to xs-1 do a2[x+y*sd]:=a1[x shr 1+(y shr 1)*s];
 tdu:=tdu+ys*xs*4;
end;
//############################################################################//
//FIXME: Optimize!
procedure puthalfspr8(dst,spr:ptypspr;xp,yp:integer);
var x,y,s,sd,ys,xs:integer;
a1,a2:pbytea;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<0)or(xp>=dst.xs-spr.xs div 2)or(yp<0)or(yp>=dst.ys-spr.ys div 2)then exit;

 a1:=spr.srf;
 a2:=@pbytea(dst.srf)[xp+yp*dst.xs];
 s:=spr.xs;
 sd:=dst.xs;
 xs:=spr.xs div 2;
 ys:=spr.ys div 2;

 for y:=0 to ys-1 do for x:=0 to xs-1 do a2[x+y*sd]:=a1[x shl 1+(y shl 1)*s];
 tdu:=tdu+ys*xs div 4;
end;
//############################################################################//
//Put sprite flat stencil (SLOW)
procedure putsprsten8(dst,spr:ptypspr;xp,yp,xh,yh,xos,yos:integer);
var x,y,dst_line,src_line,line_siz,ys,xs:integer;
psrc,pdst:pchar;
begin
 if not calc_border(dst,spr,xp,yp,1,1,psrc,pdst,xs,ys,dst_line,src_line,line_siz) then exit;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   if(x+xp>=xh)and(x+xp<xh+xos)and(y+yp>=yh)and(y+yp<yh+yos)then pdst^:=psrc^;
   psrc:=psrc+1;pdst:=pdst+1;
  end;
  psrc:=psrc+src_line-line_siz;
  pdst:=pdst+dst_line-line_siz;
 end;
 tdu:=tdu+ys*xs;
end;
//############################################################################//
//Put sprite transparent for non 0-prevail sprites
procedure putsprt8(dst,spr:ptypspr;xp,yp:integer;palo:shortint=0;trans_color:byte=0);
var x,y,dst_line,src_line,line_siz,ys,xs:integer;
psrc,pdst:pchar;
begin
 if dst=nil then exit;
 if spr=nil then exit;
 if not calc_border(dst,spr,xp,yp,1,1,psrc,pdst,xs,ys,dst_line,src_line,line_siz) then exit;
 if palo=0 then begin
  for y:=0 to ys-1 do begin
   for x:=0 to xs-1 do begin
    if byte(psrc^)<>trans_color then pdst^:=psrc^;
    psrc:=psrc+1;pdst:=pdst+1;
   end;
   psrc:=psrc+src_line-line_siz;
   pdst:=pdst+dst_line-line_siz;
  end;
 end else begin
  for y:=0 to ys-1 do begin
   for x:=0 to xs-1 do begin
    if byte(psrc^)<>trans_color then begin
     if pbyte(psrc)^ and $0F+palo<16 then pbyte(pdst)^:=pbyte(psrc)^+palo
                                     else pbyte(pdst)^:=0;
    end;
    psrc:=psrc+1;
    pdst:=pdst+1;
   end;
   psrc:=psrc+src_line-line_siz;
   pdst:=pdst+dst_line-line_siz;
  end;
 end;

 tdu:=tdu+ys*xs;
end;
//############################################################################//
//Put sprite transparent for non 0-prevail sprites
procedure putsprtx8(dst,spr:ptypspr;xp,yp:integer;palx:ppalxtyp);
var x,y,dst_line,src_line,line_siz,ys,xs:integer;
psrc,pdst:pchar;
begin
 if not calc_border(dst,spr,xp,yp,1,1,psrc,pdst,xs,ys,dst_line,src_line,line_siz) then exit;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   if psrc^<>#0 then pbyte(pdst)^:=palx^[pbyte(psrc)^];
   psrc:=psrc+1;pdst:=pdst+1;
  end;
  psrc:=psrc+src_line-line_siz;
  pdst:=pdst+dst_line-line_siz;
 end;

 tdu:=tdu+ys*xs;
end;
//############################################################################//
//Put sprite transparent for 0-prevail sprites
procedure putsprt8z(dst,spr:ptypspr;xp,yp:integer);
var x,y,dst_line,src_line,line_siz,ys,xs:integer;
psrc,pdst:pchar;
begin
 if not calc_border(dst,spr,xp,yp,1,1,psrc,pdst,xs,ys,dst_line,src_line,line_siz) then exit;

 for y:=0 to ys-1 do begin
  x:=0;
  repeat
   {$ifndef wince}
   if(x<xs-4)and(pdword(psrc)^=0) then begin
    psrc:=psrc+4;pdst:=pdst+4;x:=x+4;
   end else begin
   {$endif}
    if psrc^<>#0 then pdst^:=psrc^;
    psrc:=psrc+1;pdst:=pdst+1;x:=x+1;
   {$ifndef wince}end;{$endif}
  until x>=xs;
  psrc:=psrc+src_line-line_siz;
  pdst:=pdst+dst_line-line_siz;
 end;

 tdu:=tdu+ys*xs;
end;
//############################################################################//
//Put sprite cut and transparent
procedure putsprtcut8(dst,spr:ptypspr;xp,yp,xh,yh,xs,ys:integer;key:byte);
var x,y:integer;
a1,a2:pchar;
s,sd:integer;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<0)or(xp>=dst.xs)or(yp<0)or(yp>=dst.ys)then exit;
 if(xs+xh>spr.xs)then xs:=spr.xs-xh;if(ys+yh>spr.ys)then ys:=spr.ys-yh;
 if(xs<=0)or(ys<=0)then exit;
 if(xp+xs>dst.xs)or(yp+ys>dst.ys)then exit;

 a1:=@pbytea(spr.srf)[xh+yh*spr.xs];a2:=@pbytea(dst.srf)[xp+yp*dst.xs];

 sd:=dst.xs-xs;
 s:=spr.xs-xs;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   if (pbyte(a1)^ xor key)<>0 then pbyte(a2)^:=pbyte(a1)^;
   a1:=a1+1;a2:=a2+1;
  end;
  a2:=a2+sd;
  a1:=a1+s;
 end;
 tdu:=tdu+ys*xs;
end;
//############################################################################//
//Put sprite cut
procedure putsprcut8(dst,spr:ptypspr;xp,yp,xh,yh,xs,ys:integer);
var x,y:integer;
a1,a2:pchar;
s,sd:integer;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit;
 if(xp<0)or(xp>=dst.xs)or(yp<0)or(yp>=dst.ys)then exit;
 if(xs+xh>spr.xs)then xs:=spr.xs-xh;if(ys+yh>spr.ys)then ys:=spr.ys-yh;
 if(xs<=0)or(ys<=0)then exit;
 if(xp+xs>dst.xs)or(yp+ys>dst.ys)then exit;

 a1:=@pbytea(spr.srf)[xh+yh*spr.xs];a2:=@pbytea(dst.srf)[xp+yp*dst.xs];

 sd:=dst.xs-xs;
 s:=spr.xs-xs;

 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   pbyte(a2)^:=pbyte(a1)^;
   a1:=a1+1;a2:=a2+1;
  end;
  a2:=a2+sd;
  a1:=a1+s;
 end;
 tdu:=tdu+ys*xs;
end;
//############################################################################//
//############################################################################//
//Put video frame
procedure putmov8(dst:ptypspr;spr:pshortvid8typ;xp,yp,fr:integer);
var y,s,sd,ys,xs,c,sd1:integer;
a1,a2:pchar;
begin
 if(spr=nil)or(dst=nil)then exit;
 if(not spr.used)or(dst.srf=nil)then exit;
 if(xp<-spr.wid)or(xp>=dst.xs)or(yp<-spr.hei)or(yp>=dst.ys)then exit;
 if (fr<0)or(fr>=spr.frmc)then exit;

 a1:=@spr.frms[fr].frm[0];a2:=@pbytea(dst.srf)[xp+yp*dst.xs];
 s:=spr.wid;sd:=dst.xs;sd1:=s;
 xs:=spr.wid; ys:=spr.hei;

 if(xp<0)then begin xs:=xs+xp;a1:=a1-xp;            a2:=a2-xp;           s:=spr.wid+xp; sd1:=spr.wid; end;
 if(yp<0)then begin ys:=ys+yp;a1:=a1+(-yp)*spr.wid; a2:=a2+(-yp)*dst.xs; end;
 if((xp+spr.wid)>=dst.xs)then begin c:=-((xp+spr.wid)-dst.xs); xs:=xs+c;s:=spr.wid+c; sd1:=spr.wid; end;
 if((yp+spr.hei)>=dst.ys)then begin c:=-((yp+spr.hei)-dst.ys); ys:=ys+c; end;

 for y:=0 to ys-1 do begin fastmove(a1^,a2^,s);a1:=a1+sd1;a2:=a2+sd;end;
 tdu:=tdu+ys*xs;
end;
//############################################################################//
//############################################################################//
//Draw AA line
//Unused
procedure draaline8(dst:ptypspr;x1,y1,x2,y2:double;col:byte);
var grad,xd,yd,xgap,xend,yend,yf:double;
br1,br2:double;
x,ix1,ix2,iy1,iy2:integer;
wasexchange:boolean;
tmpreal:double;
co,cl:crgb;
function myfrac(x:double):double;begin result:=x-floor(x);end;
procedure colal(x,y:integer;r:double);
begin
 co:=thepal[pbytea(dst.srf)[x+y*dst.xs]];
 cl:=thepal[col];
 pbytea(dst.srf)[x+y*dst.xs]:=nearest_in_pal(tcrgb(round((cl[2]+co[2])*r*0.5),round((cl[1]+co[1])*r*0.5),round((cl[0]+co[0])*r*0.5)),thepal);
end;
begin
 xd := x2-x1;
 yd := y2-y1;
 if(xd=0)and(yd=0)then exit;
 if abs(xd)>abs(yd) then wasexchange:=false else begin
  wasexchange:=true;
  tmpreal:=x1;x1:=y1;y1:=tmpreal;
  tmpreal:=x2;x2:=y2;y2:=tmpreal;
  tmpreal:=xd;xd:=yd;yd:=tmpreal;
 end;
 if x1>x2 then begin
  tmpreal:=x1;x1:=x2;x2:=tmpreal;tmpreal:=y1;
  y1:=y2;y2:=tmpreal;xd:=x2-x1;yd:=y2-y1;
 end;
 grad:=yd/xd;
 xend:=floor(x1+0.5);yend:=y1+grad*(xend-x1);
 xgap:=1-myfrac(x1+0.5);
 ix1:=floor(x1+0.5);iy1:=floor(yend);
 br1:=(1-myfrac(yend))*xgap;br2:=myfrac(yend)*xgap;
 if wasexchange then begin
  colal(iy1,ix1,br1);colal(iy1+1,ix1,br2);
 end else begin
  colal(ix1,iy1,br1);colal(ix1,iy1+1,br2);
 end;
 yf:=yend+grad;
 xend:=floor(x2+0.5);yend:=y2+grad*(xend-x2);
 xgap:=1-myfrac(x2-0.5);
 ix2:=floor(x2+0.5);iy2:=floor(yend);
 br1:=(1-myfrac(yend))*xgap;br2:=myfrac(yend)*xgap;
 if wasexchange then begin
  colal(iy2,ix2,br1);colal(iy2+1,ix2,br2);
 end else begin
  colal(ix2,iy2,br1);colal(ix2,iy2+1,br2);
 end;
 x:=ix1+1;
 while x<=ix2-1 do begin
  br1:=1-myfrac(yf);br2:=myfrac(yf);
  if wasexchange then begin
   colal(floor(yf),x,br1);colal(floor(yf)+1,x,br2);
  end else begin
   colal(x,floor(yf),br1);colal(x,floor(yf)+1,br2);
  end;
  yf:=yf+grad;inc(x);
 end;
end;
//############################################################################//
//############################################################################//
//Draw line
//for i:=0 to 1000000 do drline(@thscrp,curx-20,cury-15,curx+20,cury+15,1);
//mid: 0.38
//edge: 0.50
procedure drline8_base(dst:ptypspr;x1,y1,x2,y2,nc:integer;col:byte);
var x,y,dx,dy,sx,sy,z,e,i,gex,gey,n:integer;
ch:boolean;
begin
 n:=0;
 gex:=dst.xs;gey:=dst.ys;
 if(x1>0)and(x1<gex)and(y1>0)and(y1<gey)and(x2>0)and(x2<gex)and(y2>0)and(y2<gey)then begin
  x:=x1;y:=y1;
  dx:=abs(x2-x1);dy:=abs(y2-y1);
  sx:=sign(x2-x1);sy:=sign(y2-y1);
  if(dx=0)and(dy=0)then begin pbytea(dst.srf)[x1+y1*dst.xs]:=col; exit;end;
  if dy>dx then begin z:=dx;dx:=dy;dy:=z;ch:=true; end else ch:=false;
  e:=2*dy-dx;i:=1;
  repeat
   n:=n+1;
   if n mod 10<nc then pbytea(dst.srf)[x+y*dst.xs]:=col;
   while e>=0 do begin if ch then x:=x+sx else y:=y+sy; e:=e-2*dx; end;
   if ch then y:=y+sy else x:=x+sx;
   e:=e+2*dy;i:=i+1;
  until i>dx;
  pbytea(dst.srf)[x+y*dst.xs]:=col;
 end else begin
  x:=x1;y:=y1;
  dx:=abs(x2-x1);dy:=abs(y2-y1);
  sx:=sign(x2-x1);sy:=sign(y2-y1);
  if(dx=0)and(dy=0)then begin if(x1>0)and(x1<gex)and(y1>0)and(y1<gey)then pbytea(dst.srf)[x1+y1*dst.xs]:=col; exit;end;
  if dy>dx then begin z:=dx;dx:=dy;dy:=z;ch:=true; end else ch:=false;
  e:=2*dy-dx;i:=1;
  repeat
   n:=n+1;
   if n mod 10<nc then if(x>0)and(x<gex)and(y>0)and(y<gey)then pbytea(dst.srf)[x+y*dst.xs]:=col;
   while e>=0 do begin if ch then x:=x+sx else y:=y+sy; e:=e-2*dx; end;
   if ch then y:=y+sy else x:=x+sx;
   e:=e+2*dy;i:=i+1;
  until i>dx;
  if(x>0)and(x<gex)and(y>0)and(y<gey)then pbytea(dst.srf)[x+y*dst.xs]:=col;
 end;
end;
//############################################################################//
procedure drline8(dst:ptypspr;x1,y1,x2,y2:integer;col:byte);begin drline8_base(dst,x1,y1,x2,y2,10,col);end;
procedure drline8_skip(dst:ptypspr;x1,y1,x2,y2,nc:integer;col:byte);begin drline8_base(dst,x1,y1,x2,y2,nc,col);end;
//############################################################################//
procedure dr_line_thk_8(dst:ptypspr;x1,y1,x2,y2,t:integer;col:byte);
var kx,ky:integer;
begin
 for kx:=-t to t do for ky:=-t to t do drline8(dst,x1+kx,y1+ky,x2+kx,y2+ky,col);
end;
//############################################################################//
//############################################################################//
//Draw filled rectangle, screen limit
procedure drfrect8(dst:ptypspr;x1,y1,x2,y2:integer;col:byte); 
var x,y,yo:integer;
begin
 if x1>x2 then begin x:=x2; x2:=x1; x1:=x;end;if y1>y2 then begin x:=y2; y2:=y1; y1:=x;end;
 if x1<0 then x1:=0; if x2>=dst.xs then x2:=dst.xs-1;
 if y1<0 then y1:=0; if y2>=dst.ys then y2:=dst.ys-1;
 if x2<0 then x2:=0; if x1>=dst.xs then x1:=dst.xs-1;
 if y2<0 then y2:=0; if y1>=dst.ys then y1:=dst.ys-1;
 for y:=y1 to y2 do begin
  yo:=y*dst.xs;
  for x:=x1 to x2 do pbytea(dst.srf)[x+yo]:=col;
 end;
 tdu:=tdu+(x2-x1)*(y2-y1);
end;
//############################################################################//
//############################################################################//
//Draw filled rectangle, screen limit
procedure drfrectx8(dst:ptypspr;x,y,xs,ys:integer;col:byte);
begin drfrect8(dst,x,y,x+xs-1,y+ys-1,col); end;
//############################################################################//
//############################################################################//
//Draw rectangle, screen limit
procedure drrect8(dst:ptypspr;x1,y1,x2,y2:integer;col:byte);
var x,y:integer;
begin
 if x1>x2 then begin x:=x2; x2:=x1; x1:=x;end;if y1>y2 then begin x:=y2; y2:=y1; y1:=x;end;
 if x1<0 then x1:=0; if x2>=dst.xs then x2:=dst.xs-1;
 if y1<0 then y1:=0; if y2>=dst.ys then y2:=dst.ys-1;
 if x2<0 then x2:=0; if x1>=dst.xs then x1:=dst.xs-1;
 if y2<0 then y2:=0; if y1>=dst.ys then y1:=dst.ys-1;
 for y:=y1 to y2 do pbytea(dst.srf)[x1+y*dst.xs]:=col;
 for y:=y1 to y2 do pbytea(dst.srf)[x2+y*dst.xs]:=col;
 for x:=x1 to x2 do pbytea(dst.srf)[x+y1*dst.xs]:=col;
 for x:=x1 to x2 do pbytea(dst.srf)[x+y2*dst.xs]:=col;
 tdu:=tdu+(x2-x1)*2+(y2-y1)*2;
end;
procedure drrectx8(dst:ptypspr;x,y,xs,ys:integer;col:byte);
begin drrect8(dst,x,y,x+xs-1,y+ys-1,col);end;
//############################################################################//
//############################################################################//
//Draw x rectangle, screen limit
procedure drxrect8(dst:ptypspr;xh,yh,xl,yl:integer;cl:byte);
begin
 drrect8(dst,xh,yh,xh,yh+10,cl);
 drrect8(dst,xh,yh,xh+10,yh,cl);
 drrect8(dst,xh,yl,xh,yl-10,cl);
 drrect8(dst,xh,yl,xh+10,yl,cl);
 drrect8(dst,xl,yl,xl,yl-10,cl);
 drrect8(dst,xl,yl,xl-10,yl,cl);
 drrect8(dst,xl,yh,xl,yh+10,cl);
 drrect8(dst,xl,yh,xl-10,yh,cl);
end;
//############################################################################//
//############################################################################//
procedure drcirc8_base(dst:ptypspr;x,y,r,nc:integer;col:byte);
var xi,yi,xin,yin,yd,gex,gey,d,n:integer;
begin
 n:=0;
 yd:=y*dst.xs;
 gex:=dst.xs;gey:=dst.ys;
 if(x-r>0)and(x+r<gex)and(y-r>0)and(y+r<gey)then begin
  xi:=0;yi:=r;
  xin:=0;yin:=r*dst.xs;
  d:=3-2*r;
  while yi>=xi do begin
   n:=n+1;
   if n mod 10<nc then begin
    pbytea(dst.srf)[(xi+x)+(yin+yd)]:=col;
    pbytea(dst.srf)[(xi+x)+(-yin+yd)]:=col;
    pbytea(dst.srf)[(-xi+x)+(yin+yd)]:=col;
    pbytea(dst.srf)[(-xi+x)+(-yin+yd)]:=col;
    pbytea(dst.srf)[(yi+x)+(xin+yd)]:=col;
    pbytea(dst.srf)[(yi+x)+(-xin+yd)]:=col;
    pbytea(dst.srf)[(-yi+x)+(xin+yd)]:=col;
    pbytea(dst.srf)[(-yi+x)+(-xin+yd)]:=col;
   end;
   if d<0 then d:=d+4*xi+6 else begin
    d:=d+4*(xi-yi)+10;
    yi:=yi-1;
    yin:=yin-dst.xs
   end;
   xi:=xi+1;
   xin:=xin+dst.xs;
  end;
 end else begin
  xi:=0;yi:=r;
  xin:=0;yin:=r*dst.xs;
  d:=3-2*r;
  while yi>=xi do begin
   n:=n+1;
   if n mod 10<nc then begin
    if(x+xi>0)and(x+xi<gex)and(y+yi>0)and(y+yi<gey)then pbytea(dst.srf)[(xi+x)+(yin+yd)]:=col;
    if(x+xi>0)and(x+xi<gex)and(y-yi>0)and(y-yi<gey)then pbytea(dst.srf)[(xi+x)+(-yin+yd)]:=col;
    if(x-xi>0)and(x-xi<gex)and(y+yi>0)and(y+yi<gey)then pbytea(dst.srf)[(-xi+x)+(yin+yd)]:=col;
    if(x-xi>0)and(x-xi<gex)and(y-yi>0)and(y-yi<gey)then pbytea(dst.srf)[(-xi+x)+(-yin+yd)]:=col;
    if(x+yi>0)and(x+yi<gex)and(y+xi>0)and(y+xi<gey)then pbytea(dst.srf)[(yi+x)+(xin+yd)]:=col;
    if(x+yi>0)and(x+yi<gex)and(y-xi>0)and(y-xi<gey)then pbytea(dst.srf)[(yi+x)+(-xin+yd)]:=col;
    if(x-yi>0)and(x-yi<gex)and(y+xi>0)and(y+xi<gey)then pbytea(dst.srf)[(-yi+x)+(xin+yd)]:=col;
    if(x-yi>0)and(x-yi<gex)and(y-xi>0)and(y-xi<gey)then pbytea(dst.srf)[(-yi+x)+(-xin+yd)]:=col;
   end;
   if d<0 then d:=d+4*xi+6 else begin
    d:=d+4*(xi-yi)+10;
    yi:=yi-1;
    yin:=yin-dst.xs
   end;
   xi:=xi+1;
   xin:=xin+dst.xs;
  end;
 end;
end;
//############################################################################//
procedure drcirc8(dst:ptypspr;x,y,r:integer;col:byte);begin drcirc8_base(dst,x,y,r,10,col);end;
procedure drcirc8_skip(dst:ptypspr;x,y,r,nc:integer;col:byte);begin drcirc8_base(dst,x,y,r,nc,col);end;
//############################################################################//
//Draw filled circle
procedure drfcirc8(dst:ptypspr;x,y,r:integer;col:byte);
var xi,yi,xin,yin,yd,gex,gey,d,i,a,b,yp:integer;
skip:boolean;
begin
 yd:=y*dst.xs;
 gex:=scrx;gey:=scry;
 if(x-r>0)and(x+r<gex)and(y-r>0)and(y+r<gey)then begin
  xi:=0;yi:=r;
  xin:=0;yin:=r*dst.xs;
  d:=3-2*r;
  while yi>=xi do begin
   for i:=x-xi to x+xi do begin
    pbytea(dst.srf)[i+( yin+yd)]:=col;
    pbytea(dst.srf)[i+(-yin+yd)]:=col;
   end;
   for i:=x-yi to x+yi do begin
    pbytea(dst.srf)[i+( xin+yd)]:=col;
    pbytea(dst.srf)[i+(-xin+yd)]:=col;
   end;
   if d<0 then d:=d+4*xi+6 else begin
    d:=d+4*(xi-yi)+10;
    yi:=yi-1;
    yin:=yin-dst.xs
   end;
   xi:=xi+1;
   xin:=xin+dst.xs;
  end;
 end else begin
  xi:=0;yi:=r;
  xin:=0;yin:=r*dst.xs;
  d:=3-2*r;
  while yi>=xi do begin
   skip:=false;
   a:=x-xi;
   b:=x+xi;
   if a<0 then a:=0;if a>dst.xs-1 then skip:=true;
   if b<0 then skip:=true;if b>dst.xs-1 then b:=dst.xs-1;
   if not skip then begin
    yp:= yin+yd;if (yp>=0)and(yp<dst.xs*dst.ys) then for i:=a to b do pbytea(dst.srf)[i+yp]:=col;
    yp:=-yin+yd;if (yp>=0)and(yp<dst.xs*dst.ys) then for i:=a to b do pbytea(dst.srf)[i+yp]:=col;
   end;

   skip:=false;
   a:=x-yi;
   b:=x+yi;
   if a<0 then a:=0;if a>dst.xs-1 then skip:=true;
   if b<0 then skip:=true;if b>dst.xs-1 then b:=dst.xs-1;
   if not skip then begin
    yp:= xin+yd;if (yp>=0)and(yp<dst.xs*dst.ys) then for i:=a to b do pbytea(dst.srf)[i+yp]:=col;
    yp:=-xin+yd;if (yp>=0)and(yp<dst.xs*dst.ys) then for i:=a to b do pbytea(dst.srf)[i+yp]:=col;
   end;

   if d<0 then d:=d+4*xi+6 else begin
    d:=d+4*(xi-yi)+10;
    yi:=yi-1;
    yin:=yin-dst.xs
   end;
   xi:=xi+1;
   xin:=xin+dst.xs;
  end;
 end;
end;
//############################################################################//
procedure dr_circ_thk_8(dst:ptypspr;x,y,r,t:integer;col:byte);
var kx,ky:integer;
begin
 for kx:=-t to t do for ky:=-t to t do drcirc8(dst,x+kx,y+ky,r,col);
end;
//############################################################################//
procedure drtriangle8(dst:ptypspr;x1,y1,x2,y2,x3,y3:integer;col:byte);
begin
 drline8(dst,x1,y1,x2,y2,col);
 drline8(dst,x2,y2,x3,y3,col);
 drline8(dst,x3,y3,x1,y1,col);
end;
//############################################################################//
//############################################################################//
//Draw sphere with light
procedure drsphcf8(dst:ptypspr;x,y,r:integer;sun:vec;col:byte);
var xp,yp:integer;
v:vec;
b:integer;
begin
 for yp:=y-r to y+r do for xp:=x-r to x+r do begin
  if sqr(yp-y)+sqr(xp-x)<sqr(r) then if(xp>0)and(xp<dst.xs)and(yp>0)and(yp<dst.ys)then begin
   v.x:=(xp-x)/90;
   v.y:=(yp-y)/90;
   v.z:=sqrt(1-(sqr(v.x)+sqr(v.y)));

   b:=round((v.x*sun.x+v.y*sun.y+v.z*sun.z)*128+16);
   if b<0 then b:=31 else begin
    if b>31 then b:=31;
    b:=31-b;
   end;

   pbytea(dst.srf)[xp+yp*dst.xs]:=col+b;
  end;
 end;
end;
//############################################################################//
//############################################################################//
//Draw ellipse
//Unimplemented
//procedure drellp(x1,y1,x2,y2:integer;col:crgba);
//begin
//end;
//############################################################################//
//############################################################################//
//Draw Polygon
//Unused
//for i:=0 to 100000 do drpolyflat(@thscrp,curx-20,cury-15,curx+20,cury-15,curx,cury+25,1);
//med: 0.75
procedure drpolyflat8(dst:ptypspr;x1,y1,x2,y2,x3,y3:integer;col:byte;tx:ptypspr=nil);
var xedge:array[0..2000]of array[0..1]of integer;
minx,maxx,miny,maxy,y:integer;

procedure drawedge(x1,y1,x2,y2:integer);
var side,y,temp:integer;
xslope,x1n:double;
begin
 side:=0;
 if (y2-y1)=0 then xslope:=(x2-x1)/0.001 else xslope:=(x2-x1)/(y2-y1);
 if y1>=y2 then begin
  side:=1;
  x1:=x2;temp:=y1;
  y1:=y2;y2:=temp;
 end;
 x1n:=x1;
 for y:=y1 to y2 do begin
  if y>=0 then xedge[y][side]:=round(x1n);
  x1n:=x1n+xslope;
 end;
end;

procedure hline(x1,x2,y:integer;col:byte);
var i,wherey,ymw:integer;
begin
 if x1>=x2 then begin i:=x1;x1:=x2;x2:=i;end;
 wherey:=y*dst.xs;
 if tx=nil then begin
  for i:=x1 to x2 do if(i>=0)and(y>=0)and(i<dst.xs)and(y<dst.ys)then pbytea(dst.srf)[i+wherey]:=col
 end else begin
  ymw:=(y mod tx.ys)*tx.xs;
  for i:=x1 to x2 do if(i>=0)and(y>=0)and(i<dst.xs)and(y<dst.ys)then pbytea(dst.srf)[i+wherey]:=pbytea(tx.srf)[i mod tx.xs+ymw]+col;
 end;
end;

begin
 drawedge(x1,y1,x2,y2);
 drawedge(x2,y2,x3,y3);
 drawedge(x3,y3,x1,y1);
 miny:=y1;
 if miny>y2 then miny:=y2;
 if miny>y3 then miny:=y3;
 maxy:=y1;
 if maxy<y2 then maxy:=y2;
 if maxy<y3 then maxy:=y3;
 minx:=x1;
 if minx>x2 then minx:=x2;
 if minx>x3 then minx:=x3;
 maxx:=x1;
 if maxx<x2 then maxx:=x2;
 if maxx<x3 then maxx:=x3;
 if maxy=miny then hline(minx,maxx,miny,col) else for y:=miny to maxy do if y>=0 then hline(xedge[y][0],xedge[y][1],y,col);
end;
procedure drpolyflatf8(dst:ptypspr;x1,y1,x2,y2,x3,y3:double;col:byte;tx:ptypspr=nil);
begin
 drpolyflat8(dst,round(x1),round(y1),round(x2),round(y2),round(x3),round(y3),col,tx);
end;
//############################################################################//
//############################################################################//
//Put pixel
//Unused
procedure drpix8(dst:ptypspr;x,y:integer;col:byte);begin pbytea(dst.srf)[x+y*dst.xs]:=col;tdu:=tdu+1;end;
//############################################################################//
begin
end.
//############################################################################//
