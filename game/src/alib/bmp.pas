//############################################################################//
//Made in 2003-2016 by Artyom Litvinovich
//AlgorLib: BMP Loader
//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit bmp;
interface
uses asys,vfsint,grph,imglib;
//############################################################################//
type
bmp_filehdr=packed record
 typ:word;
 size:dword;
 reserved1,reserved2:word;
 off_bits:dword;
end;
bmp_infohdr=packed record
 size:dword;
 wid,hei:integer;
 planes:word;
 bit_count:word;
 compression,img_size:dword;
 xpels_per_meter,ypels_per_meter:integer;
 clr_used,clr_important:dword;
end;
//############################################################################//
procedure storebmp_rgb_buf(bpp:integer;p:pointer;xr,yr:integer;rev,bgr:boolean;var ob:pointer;var obs:integer);
function  isbmp(fn:string):boolean;
function  isbmp8(fn:string):boolean;
procedure loadbmp32(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei,bd:integer;out data:pointer);
procedure loadbmp8 (fn:string;wtx,wa:boolean;trc:crgb;out wid,hei,bd:integer;out data:pointer;out pal:pallette);
procedure make_bmp_headers(xr,yr,bpp:integer;out fh:bmp_filehdr;out ih:bmp_infohdr);
function  storebmp32(fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean):boolean;
function  storebmp24(fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean):boolean;
function  storebmp8(fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean;pal:pallette):boolean;
function  ldbmp8(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei:integer;out data:pointer;out cl:pallette;status:pdouble=nil):pointer;
function  ldbmp32(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei:integer;out data:pointer;status:pdouble=nil):pointer;
//############################################################################//
implementation
//############################################################################//
function do_isbmp(fn:string;bit8:boolean):boolean;
var f:vfile;
fh:bmp_filehdr;
ih:bmp_infohdr;
begin
 result:=false;
 if vfopen(f,fn,VFO_READ)<>VFERR_OK then exit;
 if vffilesize(f)<sizeof(fh)+sizeof(ih) then begin vfclose(f);exit; end;
 vfread(f,@fh,sizeof(fh));
 vfread(f,@ih,sizeof(ih));
 vfclose(f);

 if bit8 then result:=(ih.bit_count in [8,4,1])      and(fh.typ=$4D42)
         else result:=(ih.bit_count in [32,24,8,4,1])and(fh.typ=$4D42);
end;
//############################################################################//
function isbmp (fn:string):boolean;begin result:=do_isbmp(fn,false);end;
function isbmp8(fn:string):boolean;begin result:=do_isbmp(fn,true);end;
//############################################################################//
function loadbmp_common(fn:string;out wid,hei,bd:integer;out indat:pointer;out pal:pallette;bit8:boolean):boolean;
var f:vfile;
fh:bmp_filehdr;
ih:bmp_infohdr;
bmp_length,pal_length:integer;
begin
 result:=false;
 if vfopen(f,fn,VFO_READ)<>VFERR_OK then exit;

 vfread(f,@fh,sizeof(fh));
 vfread(f,@ih,sizeof(ih));

 bd:=ih.bit_count;
 if bit8 then begin if not(bd in [8,4,1])then begin vfclose(f);exit;end; end
         else begin if not(bd in [32,24,8,4,1])then begin vfclose(f);exit;end;end;

 pal_length:=ih.clr_used*4;
 if ih.bit_count=8 then if pal_length=0 then pal_length:=256*4;
 if ih.bit_count=4 then if pal_length=0 then pal_length:=16*4;
 if ih.bit_count=1 then if pal_length=0 then pal_length:=2*4;
 vfread(f,@pal[0],pal_length);

 wid:=ih.wid;
 hei:=ih.hei;
 bmp_length:=ih.img_size;
 //if ih.bit_count=8 then begin
 // if bmp_length=0 then bmp_length:=fh.size-(fh.off_bits-dword(pal_length)-sizeof(ih)-sizeof(fh));
 //end else begin
 // if bmp_length=0 then bmp_length:=fh.size-fh.off_bits;
 //end;
 if bmp_length=0 then bmp_length:=vffilesize(f)-vffilepos(f);

 getmem(indat,bmp_length);
 vfread(f,indat,bmp_length);
 vfclose(f);
 result:=true;
end;
//############################################################################//
procedure loadbmp32(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei,bd:integer;out data:pointer);
var pal:pallette;
x,y:integer;
indat:pointer;
ysrc_pos,ydst_pos,mid_pos:intptr;

c1,c11:pcrgba;
c2:pcrgb;
c3:pbyte;
c:byte;
begin
 wid:=0;hei:=0;bd:=0;data:=nil;
 if not loadbmp_common(fn,wid,hei,bd,indat,pal,false) then exit;

 getmem(data,wid*hei*4);
 case bd of
  1:for y:=0 to hei-1 do begin
   ysrc_pos:=intptr(indat)+intptr(y*((wid div 32)*4+4*ord(wid mod 32<>0)));
   ydst_pos:=intptr(data)+intptr((hei-y-1)*wid*4);
   for x:=0 to wid-1 do begin
    c1:=pointer(ydst_pos+intptr(x shl 2));
    mid_pos:=ysrc_pos+intptr((x shr 3)and $FC);
    c3:=pointer(mid_pos+intptr((x shr 3)and $3));
    if c3^ and ($80 shr (x mod 8))=0 then begin;
     c1[0]:=$00;
     c1[1]:=$00;
     c1[2]:=$00;
    end else begin
     c1[0]:=$FF;
     c1[1]:=$FF;
     c1[2]:=$FF;
    end;
    c1[3]:=ord(wa)*$FF;
    if wtx then if (trc[0]=c1[0])and(trc[1]=c1[1])and(trc[2]=c1[2]) then c1[3]:=$00;
   end;
  end;
  4:for y:=0 to hei-1 do begin
   for x:=0 to wid-1 do begin
    c1:=pointer(intptr(data)+intptr((hei-y-1)*wid*4+x*4));
    mid_pos:=intptr(indat)+intptr(y*((wid div 8)*4+4*ord(wid mod 8 <>0))+(x div 8)*4);
    c3:=pointer(mid_pos+intptr((x div 2)mod 4));
    c:=0;
    if x mod 2=0 then c:=c3^ shr 4;
    if x mod 2=1 then c:=c3^and $0F;

    c1[CLRED  ]:=pal[c][2];
    c1[CLGREEN]:=pal[c][1];
    c1[CLBLUE ]:=pal[c][0];

    c1[3]:=ord(wa)*$FF;
    if wtx then if (trc[0]=c1[0])and(trc[1]=c1[1])and(trc[2]=c1[2]) then c1[3]:=$00;
   end;
  end;
  8:for y:=0 to hei-1 do begin
   for x:=0 to wid-1 do begin
    c1:=pointer(intptr(data)+intptr((hei-y-1)*wid*4+x*4));
    //FIXME: WTF with the padding?
    //c3:=pointer(intptr(indat)+intptr(y*wid+x+(wid mod 4)*y));
    c3:=pointer(intptr(indat)+intptr(y*wid+x+(wid mod 2)*y));

    c1[CLRED  ]:=pal[c3^][2];
    c1[CLGREEN]:=pal[c3^][1];
    c1[CLBLUE ]:=pal[c3^][0];
    c1[3]:=ord(wa)*$FF;
    if wtx then if (trc[0]=c1[0])and(trc[1]=c1[1])and(trc[2]=c1[2]) then c1[3]:=$00;
   end;
  end;
  24:for y:=0 to hei-1 do begin
   ysrc_pos:=intptr(indat)+intptr(y*wid*3+(wid mod 4)*y);
   ydst_pos:=intptr(data)+intptr((hei-y-1)*wid*4);
   for x:=0 to wid-1 do begin
    c1:=pointer(ydst_pos+intptr(x*4));
    c2:=pointer(ysrc_pos+intptr(x*3));
    c1[CLRED  ]:=c2[2];
    c1[CLGREEN]:=c2[1];
    c1[CLBLUE ]:=c2[0];
    c1[3]:=ord(wa)*$FF;
    if wtx then if (trc[0]=c2[0])and(trc[1]=c2[1])and(trc[2]=c2[2]) then c1[3]:=$00;
   end;
  end;
  32:for y:=0 to hei-1 do begin
   ysrc_pos:=intptr(indat)+intptr(y*wid*4{+(wid mod 4)*y});  //FIXME: WTF was that?
   ydst_pos:=intptr(data)+intptr((hei-y-1)*wid*4);
   for x:=0 to wid-1 do begin
    c1 :=pointer(ydst_pos+intptr(x*4));
    c11:=pointer(ysrc_pos+intptr(x*4));
    c1[CLRED  ]:=c11[2];
    c1[CLGREEN]:=c11[1];
    c1[CLBLUE ]:=c11[0];
    c1[3]:=c11[3];
   end;
  end;
 end;

 freemem(indat);
end;
//############################################################################//
//FIXME...
procedure loadbmp8(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei,bd:integer;out data:pointer;out pal:pallette);
var x,y,rwid:integer;
indat:pointer;
ysrc_pos,ydst_pos,mid_pos:intptr;
c1,c2:pbyte;
begin
 wid:=0;hei:=0;bd:=0;data:=nil;
 if not loadbmp_common(fn,wid,hei,bd,indat,pal,true) then exit;

 rwid:=wid;
 if wid mod 4<>0 then rwid:=wid+4-(wid mod 4);

 getmem(data,wid*hei);
 case bd of
  1:for y:=0 to hei-1 do begin
   ysrc_pos:=intptr(indat)+intptr(y*((wid div 32)*4+4*ord(wid mod 32 <>0)));
   ydst_pos:=intptr(data)+intptr((hei-y-1)*wid);
   for x:=0 to wid-1 do begin
    c1:=pointer(ydst_pos+intptr(x));
    mid_pos:=ysrc_pos+intptr((x div 32)*4);
    c2:=pointer(mid_pos+intptr((x div 8)mod 4));
    c1^:=ord(c2^ and ($80 shr (x mod 8))<>0);
   end;
  end;
  4:for y:=0 to hei-1 do begin
   ysrc_pos:=intptr(indat)+intptr(y*((wid div 8)*4+4*ord(wid mod 8 <>0)));
   ydst_pos:=intptr(data)+intptr((hei-y-1)*wid);
   for x:=0 to wid-1 do pbyte(ydst_pos+intptr(x))^:=pbyte(ysrc_pos+intptr((x div 8)*4))^;
  end;
  8:for y:=0 to hei-1 do
   move(pbytea(indat)[(hei-y-1)*rwid],pbytea(data)[y*wid],wid);
 end;
 freemem(indat);
end;
//############################################################################//
procedure make_bmp_headers(xr,yr,bpp:integer;out fh:bmp_filehdr;out ih:bmp_infohdr);
var pcnt:integer;
begin
 fh.typ:=19778;
 fh.reserved1:=0;
 fh.reserved2:=0;
 fh.off_bits:=54;

 ih.wid:=xr;
 ih.hei:=yr;
 ih.size:=sizeof(ih);
 ih.planes:=1;
 ih.compression:=0;
 ih.xpels_per_meter:=1000;
 ih.ypels_per_meter:=1000;
 ih.clr_used:=0;
 ih.clr_important:=0;

 case bpp of
  32:begin
   fh.size:=xr*yr*4;
   ih.bit_count:=32;
   ih.img_size:=xr*yr*4;
  end;
  24:begin
   fh.size:=xr*yr*3;
   ih.bit_count:=24;
   ih.img_size:=xr*yr*3;
  end;
  8:begin
   pcnt:=0;
   if (xr mod 4)<>0 then pcnt:=4-(xr mod 4);
   fh.size:=(xr+pcnt)*yr;
   fh.off_bits:=54+1024;
   ih.bit_count:=8;
   ih.img_size:=0;
  end;
 end;
end;
//############################################################################//
//############################################################################//
function storebmp_rgb(bpp:integer;fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean):boolean;
var f:vfile;
fh:bmp_filehdr;
ih:bmp_infohdr;
i,j:integer;
pp:pointer;
c1,c2:pcrgba;
begin
 result:=false;
 if vfopen(f,fn,VFO_WRITE)<>VFERR_OK then exit;

 make_bmp_headers(xr,yr,bpp*8,fh,ih);

 vfwrite(f,@fh,sizeof(Fh));
 vfwrite(f,@ih,sizeof(Ih));
 if bgr then begin
  getmem(pp,xr*bpp);
  for i:=yr-1 downto 0 do begin
   for j:=0 to xr-1 do begin
    c1:=pointer(intptr(p)+intptr((j+i*xr)*bpp));
    c2:=pointer(intptr(pp)+intptr(j*bpp));
    c2[0]:=c1[2];
    c2[1]:=c1[1];
    c2[2]:=c1[0];
    if bpp=4 then c2[3]:=c1[3];
   end;
   vfwrite(f,pp,xr*bpp);
  end;
  freemem(pp);
 end else begin
  if not rev then vfwrite(f,p,xr*yr*bpp) else for i:=yr-1 downto 0 do vfwrite(f,pointer(intptr(p)+intptr(i*xr*bpp)),xr*bpp);
 end;
 vfclose(f);
 result:=true;
end;
//############################################################################//
procedure storebmp_rgb_buf(bpp:integer;p:pointer;xr,yr:integer;rev,bgr:boolean;var ob:pointer;var obs:integer);
var fh:bmp_filehdr;
ih:bmp_infohdr;
i,j,bp:integer;
pp:pointer;
c1,c2:pcrgba;
begin
 obs:=sizeof(Fh)+sizeof(Ih)+xr*yr*bpp;
 getmem(ob,obs);
 bp:=0;
 make_bmp_headers(xr,yr,bpp*8,fh,ih);

 move(fh,pbytea(ob)[bp],sizeof(Fh));bp:=bp+sizeof(Fh);
 move(ih,pbytea(ob)[bp],sizeof(Ih));bp:=bp+sizeof(ih);
 if bgr then begin
  getmem(pp,xr*bpp);
  for i:=yr-1 downto 0 do begin
   for j:=0 to xr-1 do begin
    c1:=pointer(intptr(p)+intptr((j+i*xr)*4));
    c2:=pointer(intptr(pp)+intptr(j*bpp));
    c2[0]:=c1[2];
    c2[1]:=c1[1];
    c2[2]:=c1[0];
    if bpp=4 then c2[3]:=c1[3];
   end;
   move(pp^,pbytea(ob)[bp],xr*bpp);bp:=bp+xr*bpp;
  end;
  freemem(pp);
 end else begin
  if not rev then begin
   move(p^,pbytea(ob)[bp],xr*yr*bpp);//bp:=bp+xr*yr*bpp;
  end else for i:=yr-1 downto 0 do begin
   move(pointer(intptr(p)+intptr(i*xr*bpp))^,pbytea(ob)[bp],xr*bpp);bp:=bp+xr*bpp;
  end;
 end;
end;
//############################################################################//
function storebmp8(fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean;pal:pallette):boolean;
var f:vfile;
fh:bmp_filehdr;
ih:bmp_infohdr;
pcnt,i:integer;
cl:byte;
pad:dword;
begin
 result:=false;
 if vfopen(f,fn,VFO_WRITE)<>VFERR_OK then exit;

 pad:=0;
 pcnt:=0;
 if (xr mod 4)<>0 then pcnt:=4-(xr mod 4);
 make_bmp_headers(xr,yr,8,fh,ih);

 vfwrite(f,@fh,sizeof(Fh));
 vfwrite(f,@ih,sizeof(Ih));


 if bgr then for i:=0 to 255 do begin
  cl:=pal[i][0];
  pal[i][0]:=pal[i][2];
  pal[i][2]:=cl;
 end;

 vfwrite(f,@pal,1024);
 if not rev then begin
  for i:=0 to yr-1 do begin
   vfwrite(f,pointer(intptr(p)+intptr(i*xr)),xr);
   if pcnt<>0 then vfwrite(f,@pad,pcnt);
  end;
 end else begin
  for i:=yr-1 downto 0 do begin
   vfwrite(f,@pbytea(p)[i*xr],xr);
   if pcnt<>0 then vfwrite(f,@pad,pcnt);
  end;
 end;

 vfclose(f);
 result:=true;
end;
//############################################################################//
function storebmp32(fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean):boolean;
begin
 result:=storebmp_rgb(4,fn,p,xr,yr,rev,bgr);
end;
//############################################################################//
function storebmp24(fn:string;p:pointer;xr,yr:integer;rev,bgr:boolean):boolean;
begin
 result:=storebmp_rgb(3,fn,p,xr,yr,rev,bgr);
end;
//############################################################################//
//############################################################################//
function ldbmp8(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei:integer;out data:pointer;out cl:pallette;status:pdouble):pointer;
var bd:integer;
begin
 loadbmp8(fn,wtx,wa,trc,wid,hei,bd,data,cl);
 result:=data;
end;
//############################################################################//
function ldbmp32(fn:string;wtx,wa:boolean;trc:crgb;out wid,hei:integer;out data:pointer;status:pdouble):pointer;
var bd:integer;
begin
 loadbmp32(fn,wtx,wa,trc,wid,hei,bd,data);
 result:=data;
end;
//############################################################################//
begin
 register_grfmt(isbmp8,isbmp,ldbmp8,ldbmp32,nil,nil,nil,nil);
end.
//############################################################################//
