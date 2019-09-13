//############################################################################//
unit sdigrtools;
interface
uses asys,grph,palutil,imglib,graph8,sdi_rec,bmp,png{$ifdef VFS},vfsint{$endif},utf;
//############################################################################//
function maxg_nearest_in_pal(const c:crgb;const pl:pallette3):byte;
function maxg_nearest_in_thepal(const c:crgb):byte;
function maxg_nearest_in_pal_with_map(const c:crgb;const pl:pallette3):byte;
procedure maxg_dither_img_fog(var p:pbytea;const xs,ys:integer;const trans:single;const pl:pallette3);
procedure maxg_dither_img_8_to_pal(const p:pbytea;const xs,ys:integer;const pli,plo:pallette3;const trans:boolean);
procedure maxg_dither_img_32_to_pal(const p:pbcrgba;out r:pbytea;const xs,ys:integer;const pl:pallette3);

function maxg_genspr8_dither(ifil:string;trans:boolean):ptypspr;

procedure genuspr8(ifil:string;s:ptypuspr;cnt:integer);
procedure genuspr_sqr8(ifil:string;s:ptypuspr);
procedure genuspr_one8(ifil:string;s:ptypuspr);
//############################################################################//
implementation
//############################################################################//
//Get nearest color in mainpal
function maxg_nearest_in_pal(const c:crgb;const pl:pallette3):byte;
var i,n:integer;
d,l:integer;
begin
 n:=-1;
 d:=maxint;
 for i:=0 to 255 do if ((i>=0)and(i<=6))or((i>=32)and(i<64))or(i>=160) then begin
  l:=color_distance(c,pl[i]);
  if l<d then begin d:=l;n:=i;if l=0 then break;end;
 end;
 if n<0 then n:=0;
 if n>255 then n:=255;
 result:=n;
end;
//############################################################################//
//Get nearest color in mainpal
function maxg_nearest_in_pal_with_map(const c:crgb;const pl:pallette3):byte;
var i,n:integer;
d,l:integer;
begin
 n:=-1;
 d:=maxint;
 for i:=0 to 255 do if ((i>=0)and(i<=6))or((i>=32)and(i<96))or(i>=128) then begin
  l:=color_distance(c,pl[i]);
  if l<d then begin d:=l;n:=i;if l=0 then break;end;
 end;
 if n<0 then n:=0;
 if n>255 then n:=255;
 result:=n;
end;
//############################################################################//
function maxg_nearest_in_thepal(const c:crgb):byte;begin result:=maxg_nearest_in_pal(c,thepal);end;
//############################################################################//
procedure maxg_dither_img_fog(var p:pbytea;const xs,ys:integer;const trans:single;const pl:pallette3);
var x,y:integer;
cl:crgb;
b:byte;
clu:array[0..255]of boolean;
clb:array[0..255]of byte;
begin
 for x:=0 to 255 do clu[x]:=false;
 for x:=0 to 255 do clb[x]:=0;
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  b:=p[x+y*xs];
  if clu[b] then begin
   b:=clb[b];
  end else begin
   cl:=pl[b];
   clb[b]:=maxg_nearest_in_pal_with_map(tcrgb(round(cl[2]*trans),round(cl[1]*trans),round(cl[0]*trans)),pl);
   clu[b]:=true;
   b:=clb[b];
  end;
  if(pl[b][0]<>0)and(pl[b][1]<>0)and(pl[b][2]<>0) then p[x+y*xs]:=b;
 end;
end;
//############################################################################//
procedure maxg_dither_img_8_to_pal(const p:pbytea;const xs,ys:integer;const pli,plo:pallette3;const trans:boolean);
var x,y:integer;
cl:crgb;
b:byte;
clu:array[0..255]of boolean;
clb:array[0..255]of byte;
begin
 for x:=0 to 255 do clu[x]:=false;
 for x:=0 to 255 do clb[x]:=0;
 if trans then begin
  clu[0]:=true;
  clb[0]:=0;
 end;
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  b:=p[x+y*xs];
  if clu[b] then begin
   b:=clb[b];
  end else begin
   cl:=pli[b];
   clb[b]:=maxg_nearest_in_pal(cl,plo);
   clu[b]:=true;
   b:=clb[b];
  end;
  p[x+y*xs]:=b;
 end;
end;
//############################################################################//
procedure maxg_dither_img_32_to_pal(const p:pbcrgba;out r:pbytea;const xs,ys:integer;const pl:pallette3);
var x,y,c,i:integer;
cl:crgba;
cols:array of crgba;
colsb:array of byte;
begin
 setlength(cols,0);
 setlength(colsb,0);

 getmem(r,xs*ys);
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  cl:=p[x+y*xs];

  c:=-1;
  for i:=0 to length(cols)-1 do if(cols[i][0]=cl[0])and(cols[i][1]=cl[1])and(cols[i][2]=cl[2]) then begin c:=i; break; end;
  if c=-1 then begin
   c:=length(cols);
   setlength(cols,c+1);
   setlength(colsb,c+1);
   cols[c]:=cl;
   colsb[c]:=maxg_nearest_in_pal(atna(cl),pl);
  end;

  r[x+y*xs]:=colsb[c];
 end;
end;
//############################################################################//
//Get sprite from modern type image dithering into current pallette
function maxg_genspr8_dither(ifil:string;trans:boolean):ptypspr;
var wid,hei:integer;
p,r:pointer;
pal:pallette3;
begin
 if Loadbitmap8(ifil,wid,hei,p,pal)=nil then begin
  if Loadbitmap(ifil,wid,hei,p)=nil then begin
   result:=nil;
   exit;
  end;
  maxg_dither_img_32_to_pal(pbcrgba(p),pbytea(r),wid,hei,thepal);
  freemem(p);
  p:=r;r:=nil;
 end else maxg_dither_img_8_to_pal(pbytea(p),wid,hei,pal,thepal,trans);
 new(result);

 set_spr(result^,p,wid,hei);
end;
//############################################################################//
procedure genuspr_one8(ifil:string;s:ptypuspr);
var wid,hei,i,th:integer;
p,r:pointer;
pal:pallette3;
begin
 p:=nil;
 r:=nil;
 if Loadbitmap8(ifil,wid,hei,p,pal)=nil then begin
  if Loadbitmap(ifil,wid,hei,p)=nil then begin
   s.ex:=false;
   exit;
  end;
  maxg_dither_img_32_to_pal(pbcrgba(p),pbytea(r),wid,hei,thepal);
  freemem(p);
  p:=r;r:=nil;
 end;

 th:=hei;
 s.cnt:=1;

 setlength(s.sprc,s.cnt);
 for i:=0 to s.cnt-1 do begin
  getmem(s.sprc[i].srf,wid*th);
  move(pointer(intptr(p)+intptr(wid*th*i))^,s.sprc[i].srf^,wid*th);
  s.sprc[i].tp:=1;
  s.sprc[i].xs:=wid;
  s.sprc[i].ys:=th;
  s.sprc[i].cx:=wid div 2;
  s.sprc[i].cy:=th div 2;
 end;
 freemem(p);

 s.ex:=true;
end;
//############################################################################//
//Get U-sprite from modern type image, classic frame split
procedure genuspr8(ifil:string;s:ptypuspr;cnt:integer);
var wid,hei,i,th:integer;
p,r:pointer;
pal:pallette3;
begin
 p:=nil;
 r:=nil;
 if Loadbitmap8(ifil,wid,hei,p,pal)=nil then begin
  if Loadbitmap(ifil,wid,hei,p)=nil then begin
   s.ex:=false;
   exit;
  end;
  maxg_dither_img_32_to_pal(pbcrgba(p),pbytea(r),wid,hei,thepal);
  freemem(p);
  p:=r;r:=nil;
 end else maxg_dither_img_8_to_pal(pbytea(p),wid,hei,pal,thepal,false);

 th:=hei;
 if cnt=0 then begin
  if hei<2*wid then s.cnt:=1 else begin  s.cnt:=8;th:=hei div 8;end;
  if hei=wid*16 then begin s.cnt:=16; th:=hei div 16;end;
  if hei=wid*24 then begin s.cnt:=24; th:=hei div 24;end;
  if hei=wid*4  then begin s.cnt:=4; th:=hei div 4;end;
  if hei=wid*32  then begin s.cnt:=32; th:=hei div 32;end;
 end else begin
  s.cnt:=cnt;
  th:=hei div cnt;
 end;
 setlength(s.sprc,s.cnt);
 for i:=0 to s.cnt-1 do begin
  getmem(s.sprc[i].srf,wid*th);
  move(pointer(intptr(p)+intptr(wid*th*i))^,s.sprc[i].srf^,wid*th);
  s.sprc[i].tp:=1;
  s.sprc[i].xs:=wid;
  s.sprc[i].ys:=th;
  s.sprc[i].cx:=wid div 2;
  s.sprc[i].cy:=th div 2;
 end;
 freemem(p);

 s.ex:=true;
end;
//############################################################################//
//Get U-sprite from modern type image, classic frame split
procedure genuspr_sqr8(ifil:string;s:ptypuspr);
var wid,hei,i,th:integer;
p,r:pointer;
pal:pallette3;
begin
 p:=nil;
 r:=nil;
 if Loadbitmap8(ifil,wid,hei,p,pal)=nil then begin
  if Loadbitmap(ifil,wid,hei,p)=nil then begin
   s.ex:=false;
   exit;
  end;
  maxg_dither_img_32_to_pal(pbcrgba(p),pbytea(r),wid,hei,thepal);
  freemem(p);
  p:=r;r:=nil;
 end;// else maxg_dither_img_8_to_pal(pbytea(p),wid,hei,pal,thepal,false);

 s.cnt:=hei div wid;
 th:=wid;

 setlength(s.sprc,s.cnt);
 for i:=0 to s.cnt-1 do begin
  getmem(s.sprc[i].srf,wid*th);
  move(pointer(intptr(p)+intptr(wid*th*i))^,s.sprc[i].srf^,wid*th);
  s.sprc[i].tp:=1;
  s.sprc[i].xs:=wid;
  s.sprc[i].ys:=th;
  s.sprc[i].cx:=wid div 2;
  s.sprc[i].cy:=th div 2;
 end;
 freemem(p);

 s.ex:=true;
end;
//############################################################################//
//Get flc convert video sprite from modern type image, classic frame split
procedure genusprvid8(ifil:string;frmc:integer;var s:shortvid8typ);
var wid,hei,i:integer;
p,r:pointer;
pal:pallette3;
begin
 if Loadbitmap8(ifil,wid,hei,p,pal)=nil then begin
  if Loadbitmap(ifil,wid,hei,p)=nil then begin
   s.used:=false;
   exit;
  end;
  maxg_dither_img_32_to_pal(pbcrgba(p),pbytea(r),wid,hei,thepal);
  freemem(p);
  p:=r;r:=nil;
 end else maxg_dither_img_8_to_pal(pbytea(p),wid,hei,pal,thepal,false);

 s.frmc:=hei div wid;
 setlength(s.frms,s.frmc);
 for i:=0 to s.frmc-1 do begin
  getmem(s.frms[i].frm,wid*wid);
  move(pointer(intptr(p)+intptr(wid*wid*i))^,s.frms[i].frm^,wid*wid);
 end;
 freemem(p);

 s.used:=true;
 s.wid:=wid;
 s.hei:=wid;
 //s.dtms:=47;
 s.dtms:=71;
end;
//############################################################################//
begin
end.
//############################################################################//
