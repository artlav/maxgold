//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit palutil;
interface
uses asys,grph;
//############################################################################//
const
pal_arr8:array[0..7]of byte=(0,36,72,108,144,180,216,255);
pal_arr4:array[0..3]of byte=(0,85,170,255);  
//############################################################################// 
function make_884_pal:pallette3;
function color_distance(const a,b:crgb ):integer;overload;
function color_distance(const a,b:crgba):integer;overload;
function nearest_in_pal(const c:crgb; const p:pallette3):byte;overload;
function nearest_in_pal(const c:crgba;const p:pallette3):byte;overload;
function nearest_in_thepal(const c:crgb ):byte;overload;
function nearest_in_thepal(const c:crgba):byte;overload;

procedure dither_img_fog(var p:pbytea;const xs,ys:integer;const trans:single;const pl:pallette3);
procedure dither_img_8_to_pal(const p:pbytea;const xs,ys:integer;const pli,plo:pallette3;const trans:boolean);  
{$ifndef paser}procedure dither_img_32_to_pal(const p:pbcrgba;out r:pbytea;const xs,ys:integer;const pl:pallette3);{$endif}

procedure dither32_884(var p:pbcrgba;out r:pbytea;xs,ys:integer);
//############################################################################//
implementation 
//############################################################################//
function make_884_pal:pallette3;
var i:integer;
begin
 for i:=0 to 255 do result[i]:=tcrgb(pal_arr8[i and $07],pal_arr8[(i shr 3)and $07],pal_arr4[(i shr 6)and $03]);
end;
//############################################################################//
//Reference: https://www.compuphase.com/cmetric.htm
function color_distance(const a,b:crgb):integer;overload;  
var rd,gd,bd,rmean:integer;
begin
 rd:=a[CLRED]-b[CLRED];
 gd:=a[CLGREEN]-b[CLGREEN];
 bd:=a[CLBLUE]-b[CLBLUE]; 
 rmean:=(a[CLRED]+b[CLRED]) div 2;
 //result:=30*sqr(rd)+59*sqr(gd)+11*sqr(bd);  //Old one
 //result:=sqr(rd)+sqr(gd)+sqr(bd); //Flat one
 result:=(((512+rmean)*rd*rd)shr 8)+4*gd*gd+(((767-rmean)*bd*bd) shr 8);
end;
//############################################################################//
function color_distance(const a,b:crgba):integer;overload;begin result:=color_distance(atna(a),atna(b));end;
//############################################################################//
//Get nearest color in p
function nearest_in_pal(const c:crgb;const p:pallette3):byte;overload;
var i,n:integer;
d,l:integer;
begin
 n:=-1;
 d:=maxint;
 for i:=0 to 255 do begin
  l:=color_distance(c,p[i]);
  if l<d then begin d:=l;n:=i;if l=0 then break;end;
 end;
 if n<0 then n:=0;      //WTF?
 if n>255 then n:=255;  //WTF?
 result:=n;
end;
//############################################################################//
function nearest_in_pal(const c:crgba;const p:pallette3):byte;overload;begin result:=nearest_in_pal(atna(c),p);end;
function nearest_in_thepal(const c:crgb):byte;overload;begin result:=nearest_in_pal(c,thepal);end;
function nearest_in_thepal(const c:crgba):byte;overload;begin result:=nearest_in_pal(atna(c),thepal);end;
//############################################################################//
procedure dither_img_fog(var p:pbytea;const xs,ys:integer;const trans:single;const pl:pallette3);
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
   clb[b]:=nearest_in_pal(tcrgb(round(cl[2]*trans),round(cl[1]*trans),round(cl[0]*trans)),pl);
   clu[b]:=true;
   b:=clb[b];   
  end;
  if (pl[b][0]<>0)and(pl[b][1]<>0)and(pl[b][2]<>0) then p[x+y*xs]:=b;
 end;  
end;
//############################################################################//
procedure dither_img_8_to_pal(const p:pbytea;const xs,ys:integer;const pli,plo:pallette3;const trans:boolean);
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
   clb[b]:=nearest_in_pal(cl,plo);
   clu[b]:=true;
   b:=clb[b];   
  end;
  p[x+y*xs]:=b;
 end;  
end; 
//############################################################################//
{$ifndef paser}
procedure dither_img_32_to_pal(const p:pbcrgba;out r:pbytea;const xs,ys:integer;const pl:pallette3);
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
   colsb[c]:=nearest_in_pal(cl,pl);
  end;
  
  r[x+y*xs]:=colsb[c];
 end;
end;
{$endif}
//############################################################################//
procedure dither32_884(var p:pbcrgba;out r:pbytea;xs,ys:integer);
var x,y:integer;
cl:crgba;
begin
 getmem(r,xs*ys);
 for y:=0 to ys-1 do for x:=0 to xs-1 do begin
  cl:=p[x+y*xs];
  r[x+y*xs]:=(cl[CLRED] div 32)or((cl[CLGREEN] div 32) shl 3)or((cl[CLBLUE] div 64) shl 6);
 end;
end;
//############################################################################//
begin
end.
//############################################################################//
