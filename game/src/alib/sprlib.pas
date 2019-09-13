//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit sprlib;
interface
uses asys,grph,maths,strval,imglib,palutil;
//############################################################################//
function genspr8(ifil:string;status:pdouble=nil):ptypspr;                overload;
function genspr8(ifil:string;var c:pallette3;status:pdouble=nil):ptypspr;overload;
function genspr8_dither(ifil:string;trans:boolean):ptypspr;
function genspr32(ifil:string;status:pdouble=nil):ptypspr;
function genspr32_memfile(ip:pointer;bs:integer;status:pdouble=nil):ptypspr;
function genuspr32(ifil:string;xs,ys:integer):ptypuspr;

procedure copy_spr_32(const s:typspr;var d:typspr);
procedure copy_spr_8(const s:typspr;var d:typspr);
procedure copy_spr_32_8(const s:typspr;var d:typspr);
function cpspr32(s:ptypspr):ptypspr;
function cpspr8(s:ptypspr):ptypspr;

procedure im_copy(src,dst:ptypspr;sz,src_off:ivec2);
procedure im_copy_byte(src,dst:pbytea;sxs,dxs:integer;sz,src_off:ivec2);
procedure im_copy_flt(src,dst:psinglea;sxs,dxs:integer;sz,src_off:ivec2);

procedure delspr(var s:typspr);
procedure deluspr(var s:typuspr);
procedure delusprv(var s:shortvid8typ); overload;
procedure delusprv(var s:shortvid32typ);overload;
function print_spr(nam:string;spr:ptypspr):string;
//############################################################################//
implementation
//############################################################################//
//Get sprite from modern type image
function genspr8(ifil:string;status:pdouble=nil):ptypspr;overload;
var wid,hei:integer;
p:pointer;
pal:pallette;
begin
 if img_load_file_8(ifil,wid,hei,p,pal,status)=nil then begin result:=nil;exit;end;
 new(result);
 set_spr(result^,p,wid,hei);
end;
//############################################################################//
//Get sprite from modern type image
function genspr32(ifil:string;status:pdouble=nil):ptypspr;
var wid,hei:integer;
p:pointer;
begin
 if img_load_file_32(ifil,wid,hei,p,status)=nil then begin result:=nil;exit;end;
 new(result);
 set_spr(result^,p,wid,hei);
end;
//############################################################################//
//Get sprite from modern type image
function genspr32_memfile(ip:pointer;bs:integer;status:pdouble=nil):ptypspr;
var wid,hei:integer;
p:pointer;
begin
 if img_load_mem_32(ip,bs,wid,hei,p,status)=nil then begin result:=nil;exit;end;
 new(result);

 set_spr(result^,p,wid,hei);
end;
//############################################################################//
//Get sprite from modern type image returning pallette
function genspr8(ifil:string;var c:pallette3;status:pdouble=nil):ptypspr;overload;
var wid,hei:integer;
p:pointer;
begin
 if img_load_file_8(ifil,wid,hei,p,c,status)=nil then begin result:=nil;exit;end;
 new(result);

 set_spr(result^,p,wid,hei);
end;
//############################################################################//
//Get sprite from modern type image dithering into current pallette
function genspr8_dither(ifil:string;trans:boolean):ptypspr;
var wid,hei:integer;
p,r:pointer;
pal:pallette3;
begin
 if img_load_file_8(ifil,wid,hei,p,pal)=nil then begin
  if img_load_file_32(ifil,wid,hei,p)=nil then begin
   result:=nil;
   exit;
  end;
  dither_img_32_to_pal(pbcrgba(p),pbytea(r),wid,hei,thepal);
  freemem(p);
  p:=r;r:=nil;
 end else dither_img_8_to_pal(pbytea(p),wid,hei,pal,thepal,trans);
 new(result);

 set_spr(result^,p,wid,hei);
end;
//############################################################################//
function genuspr32(ifil:string;xs,ys:integer):ptypuspr;
var wid,hei,i,y,xo,yo:integer;
p:pbcrgba;
begin
 result:=nil;
 p:=nil;

 if img_load_file_32(ifil,wid,hei,pointer(p))=nil then exit;
 if(wid mod xs)<>0 then begin freemem(p);exit;end;
 if(hei mod ys)<>0 then begin freemem(p);exit;end;

 new(result);
 result.cnt:=(wid div xs)*(hei div ys);

 setlength(result.sprc,result.cnt);
 for i:=0 to result.cnt-1 do begin
  getmem(result.sprc[i].srf,xs*ys*4);
  xo:=xs*(i mod (wid div xs));
  yo:=ys*(i div (wid div xs));
  for y:=0 to ys-1 do begin
   move(p[xo+(y+yo)*wid],pbcrgba(result.sprc[i].srf)[y*xs],xs*4);
  end;
  result.sprc[i].tp:=1;
  result.sprc[i].xs:=xs;
  result.sprc[i].ys:=ys;
  result.sprc[i].cx:=xs div 2;
  result.sprc[i].cy:=ys div 2;
 end;
 freemem(p);

 result.ex:=true;
end;
//############################################################################//
procedure copy_spr_32(const s:typspr;var d:typspr);
begin
 if d.srf<>nil then freemem(d.srf);
 getmem(d.srf,s.xs*s.ys*4);
 fastmove(s.srf^,d.srf^,s.xs*s.ys*4);
 d.tp:=s.tp;
 d.xs:=s.xs;
 d.ys:=s.ys;
end;
//############################################################################//
procedure copy_spr_8(const s:typspr;var d:typspr);
begin
 if d.srf<>nil then freemem(d.srf);
 getmem(d.srf,s.xs*s.ys);
 fastmove(s.srf^,d.srf^,s.xs*s.ys);
 d.tp:=s.tp;
 d.xs:=s.xs;
 d.ys:=s.ys;
end;
//############################################################################//
procedure copy_spr_32_8(const s:typspr;var d:typspr);
var i:integer;
begin
 if d.srf<>nil then freemem(d.srf);
 getmem(d.srf,s.xs*s.ys);
 for i:=0 to s.xs*s.ys-1 do pbytea(d.srf)[i]:=(pbcrgba(s.srf)[i][0]+pbcrgba(s.srf)[i][1]+pbcrgba(s.srf)[i][2])div 3;
 d.tp:=s.tp;
 d.xs:=s.xs;
 d.ys:=s.ys;
end;
//############################################################################//
//Copy sprite 32
function cpspr32(s:ptypspr):ptypspr;
begin
 result:=nil;
 if s=nil then exit;
 if s.srf=nil then exit;
 new(result);
 getmem(result.srf,s.xs*s.ys*4);
 fastmove(s.srf^,result.srf^,s.xs*s.ys*4);
 result.tp:=s.tp;
 result.xs:=s.xs;
 result.ys:=s.ys;
end;
//############################################################################//
//Copy sprite 8
function cpspr8(s:ptypspr):ptypspr;
begin
 result:=nil;
 if s=nil then exit;
 new(result);
 getmem(result.srf,s.xs*s.ys);
 fastmove(s.srf^,result.srf^,s.xs*s.ys);
 result.tp:=s.tp;
 result.xs:=s.xs;
 result.ys:=s.ys;
end;
//############################################################################//
procedure im_copy(src,dst:ptypspr;sz,src_off:ivec2);
var y:integer;
begin
 for y:=0 to sz.y-1 do move(pbytea(src.srf)[src_off.x+(src_off.y+y)*src.xs],pbytea(dst.srf)[y*dst.xs],sz.x);
end;
//############################################################################//
procedure im_copy_byte(src,dst:pbytea;sxs,dxs:integer;sz,src_off:ivec2);
var y:integer;
begin
 for y:=0 to sz.y-1 do move(src[src_off.x+(src_off.y+y)*sxs],dst[y*dxs],sz.x);
end;
//############################################################################//
procedure im_copy_flt(src,dst:psinglea;sxs,dxs:integer;sz,src_off:ivec2);
var y:integer;
begin
 for y:=0 to sz.y-1 do move(src[src_off.x+(src_off.y+y)*sxs],dst[y*dxs],sz.x*4);
end;
//############################################################################//
//Delete sprite
procedure delspr(var s:typspr);
begin
 if s.srf<>nil then freemem(s.srf);
 s.srf:=nil;
 s.tp:=0;
 s.xs:=0;
 s.ys:=0;
 s.cx:=0;
 s.cy:=0;
end;
//############################################################################//
//Delete U-sprite
procedure deluspr(var s:typuspr);
var i:integer;
begin
 if not s.ex then exit;

 for i:=0 to s.cnt-1 do begin
  if s.sprc[i].srf<>nil then freemem(s.sprc[i].srf);
  s.sprc[i].tp:=0;
  s.sprc[i].xs:=0;
  s.sprc[i].ys:=0;
  s.sprc[i].cx:=0;
  s.sprc[i].cy:=0;
 end;

 setlength(s.sprc,0);
 s.cnt:=0;
 s.ex:=false;
end;
//############################################################################//
//Delete Video sprite
procedure delusprv(var s:shortvid8typ);overload;
var i:integer;
begin
 if s.used=false then exit;
 for i:=0 to s.frmc-1 do if s.frms[i].frm<>nil then freemem(s.frms[i].frm);
 setlength(s.frms,0);
 s.frmc:=0; s.used:=false;
 s.wid:=0;s.hei:=0;s.dtms:=0;
end;
//############################################################################//
//Delete Video sprite 32
procedure delusprv(var s:shortvid32typ);overload;
var i:integer;
begin
 if s.used=false then exit;
 for i:=0 to s.frmc-1 do if s.frms[i].frm<>nil then freemem(s.frms[i].frm);
 setlength(s.frms,0);
 s.frmc:=0;s.used:=false;
 s.wid:=0;s.hei:=0;s.dtms:=0;
end;
//############################################################################//
function print_spr(nam:string;spr:ptypspr):string;
var x,y:integer;
s:string;
c:crgba;
p:pbcrgba;
begin
 result:='';
 if spr=nil then exit;
 p:=spr.srf;
 if p=nil then exit;

 result:='const '+nam+':array[0..'+stri(spr.xs*spr.ys)+'*4-1]of byte=('+#$0A;
 for y:=0 to spr.ys-1 do begin
  s:=' ';
  for x:=0 to spr.xs-1 do begin
   c:=p[x+y*spr.xs];
   if x<>0then s:=s+',';
   s:=s+'$'+strhex2(c[CLRED])+',$'+strhex2(c[CLGREEN])+',$'+strhex2(c[CLBLUE])+',$'+strhex2(c[3]);
  end;
  result:=result+s;
  if y<>spr.ys-1 then result:=result+',';
  result:=result+#$0A;
 end;
 result:=result+');'+#$0A;
end;
//############################################################################//
begin
end.
//############################################################################//
