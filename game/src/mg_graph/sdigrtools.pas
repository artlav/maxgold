//############################################################################// 
unit sdigrtools;
interface 
uses asys,grph,palutil,imglib,graph8,sdi_rec,bmp,png,sdirecs,utf;
//############################################################################//  
const 
mgfmsk:array[0..31]of byte=($80,$40,$20,$10,$08,$04,$02,$01,$80,$40,$20,$10,$08,$04,$02,$01,$80,$40,$20,$10,$08,$04,$02,$01,$80,$40,$20,$10,$08,$04,$02,$01);

//Font settings
fntpr:array[0..20]of array[0..3]of byte=
 //Star'yo
((0,162,151,  0),
 (0,163,  2,  0),
 (0,  1,  0,  0),
 (0,  2,  0,  0),
 (0,163,  0,  0),
 (0,  5,199, 56),
 (0,  4,  0,  0),
 (0,165,200,175),
 (0, 31,  0,  0),
 
 //Main menu btn
 (4,162,151,  0),
 (4,  5,199, 56),
 
 //Stats
 (2,162,  0,  0),
 (2,  1,  0,  0),
 (2,  2,  0,  0),
 (2,  4,  0,  0),
 
 //rmnu
 (2,162,151,  0),
 (2,163,  2,  0),
 
 //Saveload
 (3,162,151,  0),
 (3,163,  2,  0),
 
 //Big text
 (1,162,151,  0),
 (1,  5,199,  0));
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
procedure genusprvid8(ifil:string;frmc:integer;var s:shortvid8typ);

procedure init_grtools(s:psdi_rec);

procedure sdi_calczoomer(s:psdi_rec;zoom:double);
function basmmap8(s:psdi_rec;m:ptypspr;pal:pallette3;clr:boolean=false):ptypspr;
function sclmmap8(s:psdi_rec;m:ptypspr;clr:boolean=false):ptypspr;
procedure fill_transparency_cache(cg:psdi_grap_rec);

procedure loadmgfnt(buf:pointer;var font:mgfont);

function gettxtmglen(cg:psdi_grap_rec;fn:integer;text:string):integer;

procedure puttran8(cg:psdi_grap_rec;dst:ptypspr;xp,yp,xs,ys,c:integer); 
procedure tran_rect8(cg:psdi_grap_rec;dst:ptypspr;xp,yp,xs,ys,tr:integer);

procedure putsprszoomt8(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer);
procedure putsprzoomt8(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer);
procedure putsprzoomt8x(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer;palx:ppalxtyp);
procedure putsprzoomt8xtra(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer;palx:ppalxtyp);
procedure putsprmczoomt8(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer;col:byte);
procedure wrtxtmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0);overload;
procedure wrtxtmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fp:integer);overload;
function wrtxtcntmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0):integer;overload;
function wrtxtcntmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fp:integer):integer;overload;
procedure wrtxtrmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0);overload;
procedure wrtxtrmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fp:integer);overload;

procedure wrtxtboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xl,yl:integer;text:ansistring;fn:integer;fc,bc:byte;mc:byte=0);overload;
procedure wrtxtboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xl,yl:integer;text:ansistring;fp:integer);overload;   
procedure wrtxtxboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xs,ys:integer;center:boolean;text:ansistring;fn:integer;fcol,bcol:byte;mc:byte=0);overload;
procedure wrtxtxboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xs,ys:integer;center:boolean;text:ansistring;fp:integer);overload;

procedure wrtxt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte);
procedure wrtxtr8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte);
function wrtxtcnt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte):integer;    
procedure wrtxtbox8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xl,yl:integer;text:ansistring;font:byte);
procedure wrtxtxbox8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xs,ys:integer;text:ansistring;font:byte);
procedure wrbgtxt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte);
procedure wrbgtxtr8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte); 
function wrbgtxtcnt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte):integer;
//############################################################################//
implementation   
//############################################################################// 
type prctexrec=record
 c:byte;
 width:integer;
 break:boolean;
end;
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
 if img_load_file_8(ifil,wid,hei,p,pal)=nil then begin
  if img_load_file_32(ifil,wid,hei,p)=nil then begin
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
 if img_load_file_8(ifil,wid,hei,p,pal)=nil then begin
  if img_load_file_32(ifil,wid,hei,p)=nil then begin
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
 if img_load_file_8(ifil,wid,hei,p,pal)=nil then begin
  if img_load_file_32(ifil,wid,hei,p)=nil then begin
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
 if img_load_file_8(ifil,wid,hei,p,pal)=nil then begin
  if img_load_file_32(ifil,wid,hei,p)=nil then begin
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
 if img_load_file_8(ifil,wid,hei,p,pal)=nil then begin
  if img_load_file_32(ifil,wid,hei,p)=nil then begin
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
procedure sdi_calczoomer(s:psdi_rec;zoom:double);
var i,c,n:integer;
d,e:double;
begin
 for i:=0 to 999 do s.zoomer[i]:=true;
 for i:=0 to 999 do s.zoomsc[i]:=i;
 for i:=0 to 999 do s.zoomof[i]:=1;
 for i:=0 to 999 do s.azoomsc[i]:=i;
 if zoom<=1.01 then exit;

 c:=1000-round(1000/zoom);
 d:=1000/c;
 e:=0;    
 for i:=0 to c do begin
  e:=e+d; 
  if e<1000 then s.zoomer[round(e)]:=false;
 end;
 
 c:=0;
 s.zoomsc[0]:=0;
 s.azoomsc[0]:=0;
 for i:=1 to 999 do begin
  c:=c+ord(s.zoomer[i-1]);
  s.zoomsc[i]:=c; 
  s.azoomsc[c]:=i+1-ord(s.zoomer[i]); 
 end;  
 c:=1;
 n:=0; 
 for i:=1 to 999 do begin
  if not s.zoomer[i] then c:=c+1;
  if s.zoomer[i] then begin 
   s.zoomof[n]:=c;
   c:=1;
   n:=n+1;
  end;
 end;
end;   
//############################################################################//
//BaseMake minimap
function basmmap8(s:psdi_rec;m:ptypspr;pal:pallette3;clr:boolean=false):ptypspr;
var x,y:integer;
d,ms:pbytea;
cl:crgb;
i,l:integer;
begin      
 result:=nil;        
 if m=nil then exit;
 for i:=0 to 255 do begin 
  cl:=pal[i]; 
  l:=round((cl[2]*0.3/255+cl[1]*0.59/255+cl[0]*0.11/255)*255); 
  if l>255 then l:=255;
  s.cg.minimap_shade[i]:=maxg_nearest_in_thepal(tcrgb(l,l,l));
 end;
 new(result);
 result.xs:=112;result.ys:=112;
 getmem(result.srf,112*112);
 d:=result.srf;
 ms:=m.srf;
 for x:=0 to 112-1 do for y:=0 to 112-1 do d[x+y*112]:=s.cg.minimap_shade[ms[x+y*112]];    
 if clr then freemem(m.srf);
end;  
//############################################################################//
//Scale minimap
function sclmmap8(s:psdi_rec;m:ptypspr;clr:boolean=false):ptypspr;
var x,y,idxd,idxm,dx,dy:integer;
xx,yy,xxm,yym:single;
d,ms:pbytea;
begin
 result:=nil;  
 if m=nil then exit;
 if(m.xs=112)and(m.ys=112)then begin result:=m;exit;end;

 new(result);
 result.xs:=112;
 result.ys:=112;
 getmem(result.srf,result.xs*result.ys);
 d:=result.srf;
 ms:=m.srf;
 xx:=112/m.xs;
 yy:=112/m.ys;
 xxm:=xx;
 yym:=yy;
 if xx<yy then yy:=xx else xx:=yy;
 if (xx>1) or (xxm<>yym) then for x:=0 to 112-1 do for y:=0 to 112-1 do d[x+y*112]:=0; // clear map for small and non square maps
 if xx>1 then begin xx:=1;yy:=1; end; // correct aspect ratio
 dx:=round(112-m.xs*xx) div 2;
 dy:=round(112-m.ys*yy) div 2;

 for x:=0 to m.xs-1 do for y:=0 to m.ys-1 do begin
  idxd:=trunc(x*xx+dx)+trunc(y*yy+dy)*112;
  idxm:=trunc(x)+trunc(y)*m.xs;
  d[idxd]:=ms[idxm];
 end;
 if clr then begin
  freemem(m.srf);
  dispose(m);
 end;
end;
//############################################################################//
//Fill transparencies
procedure fill_transparency_cache(cg:psdi_grap_rec);
var i:integer;
cl:crgb;
begin
 for i:=0 to 255 do begin 
  cl:=thepal[i]; 
  cg.shadow_shade[i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*cg.shadow_density),round(cl[1]*cg.shadow_density),round(cl[0]*cg.shadow_density)));
 
  cg.msg_shade[0][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*cg.msg_density),round(cl[1]*cg.msg_density),round(cl[0]*cg.msg_density)));
  cg.msg_shade[1][i]:=maxg_nearest_in_thepal(tcrgb(cl[0] or $C0,cl[0],cl[0]));
  cg.msg_shade[2][i]:=maxg_nearest_in_thepal(tcrgb(cl[0] or $C0,0,0));
  cg.msg_shade[3][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*cg.fow_density),round(cl[1]*cg.fow_density),round(cl[0]*cg.fow_density)));

  cg.msg_shade[4][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*8),round(cl[1]*2),round(cl[0]*2)));
  cg.msg_shade[5][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*8),round(cl[1]*8),round(cl[0]*2)));
  cg.msg_shade[6][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*2),round(cl[1]*4),round(cl[0]*2)));
  cg.msg_shade[7][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*2),round(cl[1]*2),round(cl[0]*4)));

  //IOS needs overflow checking...
  if i>=10 then cg.msg_shade[8][i]:=i-10 else cg.msg_shade[8][i]:=0;
 
  cg.minimap_shade[i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*0.3),round(cl[1]*0.59),round(cl[0]*0.11)));
 end;
end;   
//############################################################################//
procedure loadmgfnt(buf:pointer;var font:mgfont);
var last,size:integer;
b:pbytea;
begin
 b:=buf;
 move(b[0],font,20);

 getmem(font.info,8*font.num);
 move(b[20],font.info^,8*font.num);
 
 last:=font.num-1;
 size:=font.info[last].offset+(font.info[last].width+7) div 8*font.height;

 getmem(font.data,size);
 move(b[20+8*font.num],font.data^,size);

 //0 - 162 151   x
 //1 - 163   2   x
 //2 -   1   0   x
 //3 -   2   0   x
 //4 - 163   0   x
 //5 -   5 199  56
 //6 -   4   0   x
 //////////////////////7 -   5 199  56
 //8 -  31   0   x
end;     
//############################################################################//
//Get text length, big font
function gettxtmglen(cg:psdi_grap_rec;fn:integer;text:string):integer;
var i:integer;
c:byte;
begin
 result:=0;
 for i:=1 to length(text) do begin
  c:=cg.mgfxlat[ord(text[i])];
  if c>=cg.mgfnt[fn].num then begin result:=result+4; continue; end;
  if cg.mgfnt[fn].height*cg.mgfnt[fn].info[c].width=0 then begin result:=result+4; continue; end;
  result:=result+cg.mgfnt[fn].info[c].width+cg.mgfnt[fn].spacing;
 end;
end;           
//############################################################################//
//Put transparency for note
procedure puttran8(cg:psdi_grap_rec;dst:ptypspr;xp,yp,xs,ys,c:integer);
var d:pbytea;
n:pbyte;
y,x:integer;
yso,x2:integer;
begin     
 if(dst.srf=nil)then exit;
 if xp<0 then begin xs:=xs+xp;xp:=0;end;
 if yp<0 then begin ys:=ys+yp;yp:=0;end;
 if xp+xs>=dst.xs then xs:=dst.xs-xp-1;
 if yp+ys>=dst.ys then ys:=dst.ys-yp-1;
 d:=dst.srf; x2:=xp+xs-1;
 for y:=yp to yp+ys-1 do begin
  yso:=y*dst.xs;
  for x:=xp to x2 do begin n:=@d^[x+yso];n^:=cg.msg_shade[c][n^]; end;
 end;
 tdu:=tdu+ys*xs*4*2;
end;
//############################################################################// 
procedure tran_rect8(cg:psdi_grap_rec;dst:ptypspr;xp,yp,xs,ys,tr:integer);
begin
 puttran8(cg,dst,xp+1,yp+1,xs-2,ys-2,tr);
 drrectx8(dst,xp,yp,xs,ys,line_color);
end;
//############################################################################//
//Put shadow scaled, transparent
procedure putsprszoomt8(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer);{$ifdef aaa}begin end;{$endif}
{$define sprs}{$i scaler8.pas}{$undef sprs}
//############################################################################//
//Put sprite zoomed, transparent
procedure putsprzoomt8(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer);{$ifdef aaa}begin end;{$endif}
{$define sprt}{$i scaler8.pas}{$undef sprt}             
//############################################################################//
//Put sprite masked, zoomed, transparent
//Any faster ways?
//for k:=0 to 10000 do putsprzoomt8x (@thscrp,s,xn,yn,@palpx[u.own]);  base landing
//edge: 3.19s
//med: 1.54s
procedure putsprzoomt8x(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer;palx:ppalxtyp);{$ifdef aaa}begin end;{$endif}
{$define sprx}{$i scaler8.pas}{$undef sprx}
//############################################################################//
//Put sprite masked, zoomed, the transparent
//Any faster ways?
//for k:=0 to 10000 do putsprzoomt8x (@thscrp,s,xn,yn,@palpx[u.own]);  base landing
//edge: 3.19s
//med: 1.54s
procedure putsprzoomt8xtra(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer;palx:ppalxtyp);{$ifdef aaa}begin end;{$endif}
{$define sprtra}{$i scaler8.pas}{$undef sprtra}
//############################################################################//
//Put sprite zoomed, transparent, mono color
procedure putsprmczoomt8(s:psdi_rec;dst,spr:ptypspr;xp,yp:integer;col:byte);{$ifdef aaa}begin end;{$endif}
{$define sprm}{$i scaler8.pas}{$undef sprm}
//############################################################################//
procedure wrtxtmg8_raw(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0);overload;
var i,off,bpl,j,h,x0,hei:integer;
font:pmgfont;
c:byte;
begin
 //if bc<>0 then wr_utxt_8(spr,x+1,y+1,text,bc);
 //wr_utxt_8(spr,x,y,text,fc);

 if not cg.mg_font_loaded then exit;
 font:=@cg.mgfnt[fn];
 if(x<0)or(y<0)or(x>=spr.xs-font.height)or(y>=spr.ys-font.height)then exit;
 x0:=x;

 hei:=1;
 for i:=1 to length(text) do if text[i]='&' then hei:=hei+1;
 if hei<>1 then y:=y-font.height*hei div 2;

 for i:=1 to length(text) do begin
  if text[i]='&' then begin
   y:=y+font.height;
   x:=x0;
   continue;
  end;
  c:=cg.mgfxlat[ord(text[i])];
  if c>=font.num then begin x:=x+4; continue; end;
  if font.height*font.info[c].width=0 then begin x:=x+4; continue; end;
  off:=font.info[c].offset;
  bpl:=(font.info[c].width+7)div 8;

  for h:=0 to font.height-1 do begin
   for j:=0 to font.info[c].width-1 do begin
    if bc<>0 then if font.data[off+h*bpl+(j shr 3)] and mgfmsk[j]<>0 then pbytea(spr.srf)[x+1+j+(y+1+h)*spr.xs]:=bc;
    if font.data[off+h*bpl+(j shr 3)] and mgfmsk[j]<>0 then pbytea(spr.srf)[x+j+(y+h)*spr.xs]:=fc;
    if mc<>0 then if(h<>0)and(j<>0)then begin
     if (font.data[off+h*bpl+(j shr 3)] and mgfmsk[j]<>0)
     and(font.data[off+(h-1)*bpl+((j-1) shr 3)] and mgfmsk[j-1]<>0) then pbytea(spr.srf)[x+j+(y+h)*spr.xs]:=mc;
    end;
   end
  end;
  x:=x+font.info[c].width+font.spacing;
  //if x>scrx-50 then begin x:=10;y:=y+15; end;
 end;

 tdu:=tdu+length(text)*font.height*font.height*3;
end;
//############################################################################//
procedure wrtxtmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0);overload;
begin wrtxtmg8_raw(cg,spr,x,y,utf_to_cp1251(text),fn,fc,bc,mc);end;
//############################################################################//
procedure wrtxtmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fp:integer);overload;
begin wrtxtmg8(cg,spr,x,y,text,fntpr[fp][0],fntpr[fp][1],fntpr[fp][2],fntpr[fp][3]);end;                                                                            
//############################################################################// 
function wrtxtcntmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0):integer;overload;
begin
 if not cg.mg_font_loaded then begin result:=0;exit;end;
 text:=utf_to_cp1251(text);
 result:=gettxtmglen(cg,fn,text) div 2;
 wrtxtmg8_raw(cg,spr,x-result,y,text,fn,fc,bc,mc);
end;
function wrtxtcntmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fp:integer):integer;overload;
begin result:=wrtxtcntmg8(cg,spr,x,y,text,fntpr[fp][0],fntpr[fp][1],fntpr[fp][2],fntpr[fp][3]);end;                                                                          
//############################################################################// 
procedure wrtxtrmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fn:integer;fc,bc:byte;mc:byte=0);overload;
begin
 if not cg.mg_font_loaded then exit;  
 text:=utf_to_cp1251(text);
 wrtxtmg8_raw(cg,spr,x-gettxtmglen(cg,fn,text),y,text,fn,fc,bc,mc);
end;
procedure wrtxtrmg8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;fp:integer);overload;
begin wrtxtrmg8(cg,spr,x,y,text,fntpr[fp][0],fntpr[fp][1],fntpr[fp][2],fntpr[fp][3]);end;          
//############################################################################//
//############################################################################//  
procedure wrtxtxboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xs,ys:integer;center:boolean;text:ansistring;fn:integer;fcol,bcol:byte;mc:byte=0);overload;
var i,y,x,lines,l,lsp,lspwid:integer;
writ:array of prctexrec;
begin
 if not cg.mg_font_loaded then exit; 
 text:=utf_to_cp1251(text);
 setlength(writ,length(text));
 lines:=1;l:=0;lsp:=0;lspwid:=0;
 for i:=0 to length(text)-1 do begin
  writ[i].break:=false;
  if text[i+1]='&' then begin
   lines:=lines+1;
   writ[i].break:=true;
   l:=0;
   lsp:=0;
   lspwid:=0;
   continue;
  end;     
  
  if text[i+1]=' ' then begin
   lsp:=i;
   lspwid:=l;
   writ[i].width:=4;
   l:=l+4;
   continue;
  end;

  writ[i].c:=cg.mgfxlat[ord(text[i+1])];
  if writ[i].c>=cg.mgfnt[fn].num then writ[i].width:=4 else
   if cg.mgfnt[fn].height*cg.mgfnt[fn].info[writ[i].c].width=0 then writ[i].width:=4 else
    writ[i].width:=cg.mgfnt[fn].info[writ[i].c].width+cg.mgfnt[fn].spacing;

  l:=l+writ[i].width;  
  
  if l>xs then begin
   if lsp=0 then begin
    writ[i].break:=true;  
    l:=0;
   end else begin
    writ[lsp].break:=true;
    l:=l-lspwid;
   end;
   lsp:=0;
   lspwid:=0;
   lines:=lines+1;
  end;
 end;

 y:=0;
 if center then y:=round(((ys/(cg.mgfnt[fn].height+1))-lines)*(cg.mgfnt[fn].height+1)/2);
 x:=0;   
 for i:=0 to length(text)-1 do begin
  if writ[i].break then begin
   x:=0;
   y:=y+cg.mgfnt[fn].height+1;  
   if text[i+1]=' ' then continue;
  end;
  if text[i+1]='&' then continue;
  if y+cg.mgfnt[fn].height>ys then exit;
  wrtxtmg8_raw(cg,spr,xh+x,yh+y,text[i+1],fn,fcol,bcol,mc);
  x:=x+writ[i].width;
 end;
end;  
procedure wrtxtxboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xs,ys:integer;center:boolean;text:ansistring;fp:integer);overload;   
begin wrtxtxboxmg8(cg,spr,xh,yh,xs,ys,center,text,fntpr[fp][0],fntpr[fp][1],fntpr[fp][2],fntpr[fp][3]);end;
//############################################################################//
procedure wrtxtboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xl,yl:integer;text:ansistring;fn:integer;fc,bc:byte;mc:byte=0);overload;
begin wrtxtxboxmg8(cg,spr,xh,yh,xl-xh,yl-yh,false,text,fn,fc,bc,mc);end;                
//############################################################################//
procedure wrtxtboxmg8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xl,yl:integer;text:ansistring;fp:integer);overload;
begin wrtxtboxmg8(cg,spr,xh,yh,xl,yl,text,fntpr[fp][0],fntpr[fp][1],fntpr[fp][2],fntpr[fp][3]);end;
//############################################################################// 
//############################################################################//
//Write text, big font
procedure wrtxt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte);
begin wrtxtmg8(cg,spr,x,y-2,text,font);end;
//############################################################################//
//Write text right align, big font
procedure wrtxtr8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte);
begin wrtxtrmg8(cg,spr,x,y-2,text,font);end;
//############################################################################//
//Write text centered, big font
function wrtxtcnt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte):integer;    
begin result:=wrtxtcntmg8(cg,spr,x,y-2,text,font);end;
//############################################################################//
//Write boxed text, big font
procedure wrtxtbox8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xl,yl:integer;text:ansistring;font:byte);
begin wrtxtboxmg8(cg,spr,xh,yh-2,xl,yl-2,text,font);end;
//############################################################################//
//Write new boxed text, big font
procedure wrtxtxbox8(cg:psdi_grap_rec;spr:ptypspr;xh,yh,xs,ys:integer;text:ansistring;font:byte);
begin wrtxtxboxmg8(cg,spr,xh,yh,xs,ys,false,text,font);end;
//############################################################################//
//Write text, big font
procedure wrbgtxt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte); 
begin wrtxtmg8(cg,spr,x,y,text,1,fntpr[font][1],fntpr[font][2],fntpr[font][3]);end;
//############################################################################//
//Write text right align, big font
procedure wrbgtxtr8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte);   
begin wrtxtrmg8(cg,spr,x,y,text,1,fntpr[font][1],fntpr[font][2],fntpr[font][3]);end;
//############################################################################//
//Write text centered, big font
function wrbgtxtcnt8(cg:psdi_grap_rec;spr:ptypspr;x,y:integer;text:string;font:byte):integer;  
begin result:=wrtxtcntmg8(cg,spr,x,y,text,1,fntpr[font][1],fntpr[font][2],fntpr[font][3]);end;
//############################################################################//
procedure init_grtools(s:psdi_rec);
var i:integer;
begin
 for i:=0 to 255 do begin
  s.cg.mgfxlat[i]:=i;
  if(i>=224)and(i<=239)then s.cg.mgfxlat[i]:=i-64;
  if(i>=240)and(i<=255)then s.cg.mgfxlat[i]:=i-16;  
  if(i>=192)and(i<=223)then s.cg.mgfxlat[i]:=i-64;
  if i=184 then s.cg.mgfxlat[i]:=165;
  if i=168 then s.cg.mgfxlat[i]:=133;
 end;
 //Zoomer init
 for i:=0 to 999 do s.zoomer[i]:=true;
 for i:=0 to 999 do s.zoomsc[i]:=i;
 for i:=0 to 999 do s.zoomof[i]:=1;       
end;      
//############################################################################//
begin
end.
//############################################################################// 
