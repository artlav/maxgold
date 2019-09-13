//############################################################################//
unit sdi_scale;
interface
uses asys,grph,grpop,sdi_rec;
//############################################################################//
procedure xlat8to8_scale(k:integer;a2,a1:pchar);
procedure xlat8to32(a2,a1:pchar);
procedure xlat8to32_scale(k:integer;a2,a1:pchar);
procedure xlat8to16(a2,a1:pchar);
procedure xlat8to16_scale(k:integer;a2,a1:pchar); 
procedure xlat16to16_scale(k:integer;a2,a1:pchar);
procedure xlat32to16(a2,a1:pchar);
procedure xlat32to16_scale(k:integer;a2,a1:pchar);
procedure xlat32to32(a2,a1:pchar);
procedure xlat32to32_scale(k:integer;a2,a1:pchar);

procedure sdi_calc_scaling;
procedure sdi_set_scaling;
procedure sdi_pre_flip;
procedure sdi_post_flip(real:pointer);
//############################################################################//
implementation
//############################################################################//
procedure xlat8to8_scale(k:integer;a2,a1:pchar);
var x,y,ky,kx:integer;
c:byte;
tmp:pchar;
begin
 if(a1=nil)or(a2=nil)then exit;

 if use_scale2x then begin
  scale_2x_8(scrx,scry,pointer(a1),pointer(a2));
  exit;
 end;

 for y:=0 to scry-1 do begin
  tmp:=a1;
  for ky:=0 to k-1 do begin
   a1:=tmp;
   for x:=0 to scrx-1 do begin
    c:=pbyte(a1)^;
    for kx:=0 to k-1 do begin pbyte(a2)^:=c;a2:=a2+1;end;
    a1:=a1+1;
   end;
  end;
 end;
end;
//############################################################################//
procedure xlat16to16_scale(k:integer;a2,a1:pchar);
var x,y,ky,kx:integer;
c:word;
tmp:pchar;
begin
 if(a1=nil)or(a2=nil)then exit;
           
 if use_scale2x then begin
  scale_2x_16(scrx,scry,pointer(a1),pointer(a2));
  exit;
 end;

 for y:=0 to scry-1 do begin
  tmp:=a1;
  for ky:=0 to k-1 do begin
   a1:=tmp;
   for x:=0 to scrx-1 do begin
    c:=pword(a1)^;
    for kx:=0 to k-1 do begin pword(a2)^:=c;a2:=a2+2;end;
    a1:=a1+2;
   end;
  end;
 end;
end;
//############################################################################//
//ARGB_8888
procedure xlat32to32_scale(k:integer;a2,a1:pchar);
var x,y,ky,kx:integer;
c:crgba;
tmp:pchar;
begin
 if(a1=nil)or(a2=nil)then exit;

 if use_scale2x then begin
  scale_2x_32(scrx,scry,pointer(a1),pointer(a2));
 end else begin
  for y:=0 to scry-1 do begin
   tmp:=a1;
   for ky:=0 to k-1 do begin
    a1:=tmp;
    for x:=0 to scrx-1 do begin
     {$ifdef BGR}
     c[0]:=pcrgba(a1)^[0];
     c[1]:=pcrgba(a1)^[1];
     c[2]:=pcrgba(a1)^[2];
     {$else}
     c[0]:=pcrgba(a1)^[2];
     c[1]:=pcrgba(a1)^[1];
     c[2]:=pcrgba(a1)^[0];
     {$endif}
     c[3]:=pcrgba(a1)^[3];
     for kx:=0 to k-1 do begin pcrgba(a2)^:=c;a2:=a2+4;end;
     a1:=a1+4;
    end;
   end;
  end;
 end;
end;
//############################################################################//
//ARGB_8888
procedure xlat32to32_scale_linear(k:integer;a2,a1:pchar);
begin
 if(a1=nil)or(a2=nil)then exit;

 if use_scale15x then begin
  scale_15x_32(scrx,scry,pointer(a1),pointer(a2),false);
 end else begin
  scale_spr_linear_32_precomputed_direct_core(scl,a1,a2,scrx,scry,real_scrx,real_scry,false);
 end;
end;
//############################################################################//
//ARGB_8888
procedure xlat8to32(a2,a1:pchar);
var i,j:integer;
c:crgba;
begin
 if(a1=nil)or(a2=nil)then exit;

 for j:=0 to scry-1 do for i:=0 to scrx-1 do begin
  c[0]:=thepal[pbyte(a1)^][2];
  c[1]:=thepal[pbyte(a1)^][1];
  c[2]:=thepal[pbyte(a1)^][0];
  c[3]:=255;

  pcrgba(a2)^:=c;
  a2:=a2+4;
  a1:=a1+1;
 end;
end;
//############################################################################//
//ARGB_8888
procedure xlat8to32_scale(k:integer;a2,a1:pchar);
var x,y,ky,kx:integer;
c:crgba;
tmp:pchar;
begin
 if(a1=nil)or(a2=nil)then exit;

 for y:=0 to scry-1 do begin
  tmp:=a1;
  for ky:=0 to k-1 do begin
   a1:=tmp;
   for x:=0 to scrx-1 do begin
    c[0]:=thepal[pbyte(a1)^][2];
    c[1]:=thepal[pbyte(a1)^][1];
    c[2]:=thepal[pbyte(a1)^][0];
    c[3]:=255;
    for kx:=0 to k-1 do begin pcrgba(a2)^:=c;a2:=a2+4;end;
    a1:=a1+1;
   end;
  end;
 end;
end;
//############################################################################//
//RGB_565
procedure xlat8to16(a2,a1:pchar);
var i:integer;
c:word;
begin
 if(a1=nil)or(a2=nil)then exit;

 for i:=0 to scry*scrx-1 do begin
  c:=(thepal[pbyte(a1)^][2] shr 3) shl 11+(thepal[pbyte(a1)^][1] shr 3) shl 6+(thepal[pbyte(a1)^][0] shr 3);
  pword(a2)^:=c;
  a2:=a2+2;
  a1:=a1+1;
 end;
end;
//############################################################################//
//RGB_565
procedure xlat8to16_scale(k:integer;a2,a1:pchar);
var x,y,ky,kx:integer;
c:word;
tmp:pchar;
begin
 if(a1=nil)or(a2=nil)then exit;

 for y:=0 to scry-1 do begin
  tmp:=a1;
  for ky:=0 to k-1 do begin
   a1:=tmp;
   for x:=0 to scrx-1 do begin
    c:=(thepal[pbyte(a1)^][2] shr 3) shl 11+(thepal[pbyte(a1)^][1] shr 3) shl 6+(thepal[pbyte(a1)^][0] shr 3);
    for kx:=0 to k-1 do begin pword(a2)^:=c;a2:=a2+2;end;
    a1:=a1+1;
   end;
  end;
 end;
end;
//############################################################################//
//RGB_565
procedure xlat32to16(a2,a1:pchar);
var i:integer;
c:word;
begin
 if(a1=nil)or(a2=nil)then exit;

 for i:=0 to scry*scrx-1 do begin
  c:=(pcrgba(a1)^[2] shr 3) shl 11+(pcrgba(a1)^[1] shr 3) shl 6+(pcrgba(a1)^[0] shr 3);
  pword(a2)^:=c;
  a2:=a2+2;
  a1:=a1+4;
 end;
end;
//############################################################################//
//RGB_565
procedure xlat32to16_scale(k:integer;a2,a1:pchar);
var x,y,ky,kx:integer;
c:word;
tmp:pchar;
begin
 if(a1=nil)or(a2=nil)then exit;

 for y:=0 to scry-1 do begin
  tmp:=a1;
  for ky:=0 to k-1 do begin
   a1:=tmp;
   for x:=0 to scrx-1 do begin
    c:=(pcrgba(a1)^[2] shr 3) shl 11+(pcrgba(a1)^[1] shr 3) shl 6+(pcrgba(a1)^[0] shr 3);
    for kx:=0 to k-1 do begin pword(a2)^:=c;a2:=a2+2;end;
    a1:=a1+4;
   end;
  end;
 end;
end;
//############################################################################//
//ARGB_8888
procedure xlat32to32(a2,a1:pchar);
var i:integer;
c:crgba;
begin
 if(a1=nil)or(a2=nil)then exit;

 for i:=0 to scry*scrx-1 do begin
  c[0]:=pcrgba(a1)^[2];
  c[1]:=pcrgba(a1)^[1];
  c[2]:=pcrgba(a1)^[0];
  c[3]:=pcrgba(a1)^[3];
  pcrgba(a2)^:=c;
  a2:=a2+4;
  a1:=a1+4;
 end;
end;
//############################################################################//
procedure sdi_calc_scaling;
begin
 real_scrx:=scrx;
 real_scry:=scry;
 if direct_scale_10x=1 then direct_scale_10x:=10;
 if override_scale<10 then override_scale:=override_scale*10;
 if use_scaling then begin
  if (scry>=1400)or(scrx>=1400) then direct_scale_10x:=20 else direct_scale_10x:=10;
 end else direct_scale_10x:=10;
 if override_scale<>0 then direct_scale_10x:=override_scale;
 use_scale2x:=direct_scale_10x=20;
 use_scale15x:=direct_scale_10x=15;
 scrx:=(10*real_scrx) div direct_scale_10x;
 scry:=(10*real_scry) div direct_scale_10x;
 if use_scale15x then begin
  if scrx mod 2=1 then scrx:=scrx+1;
  if scry mod 2=1 then scry:=scry+1;
 end;
 real_scrx:=(direct_scale_10x*scrx) div 10;
 real_scry:=(direct_scale_10x*scry) div 10;
end;
//############################################################################//
procedure sdi_set_scaling;
begin
 sdiscrp.xs:=scrx;
 sdiscrp.ys:=scry;

 if sdiscr_alloc<>nil then begin
  freemem(sdiscr_alloc);
  sdiscr_alloc:=nil;
 end;

 if direct_scale_10x<>10 then begin
  getmem(sdiscr,scrx*scry*scrbitbin);
  fillchar(sdiscr^,scrx*scry*scrbitbin,0);
  sdiscrp.srf:=sdiscr;
  sdiscr_alloc:=sdiscr;
 end else begin
  if doublebuf then begin
   getmem(sdiscr,scrx*scry*scrbitbin);
   fillchar(sdiscr^,scrx*scry*scrbitbin,0);
   sdiscr_alloc:=sdiscr;
  end else sdiscr:=sdiscr_real;
  sdiscrp.srf:=sdiscr;
 end;
end;
//############################################################################//
procedure sdi_pre_flip;
begin
 if direct_scale_10x<>10 then begin
  if direct_scale_10x mod 10=0 then begin
   case scrbit of
     8:xlat8to8_scale  (direct_scale_10x div 10,sdiscr_real,sdiscrp.srf);
    16:xlat16to16_scale(direct_scale_10x div 10,sdiscr_real,sdiscrp.srf);
    32:xlat32to32_scale(direct_scale_10x div 10,sdiscr_real,sdiscrp.srf);
   end;
  end else begin
   case scrbit of
    // 8:xlat8to8_scale  (direct_scale_10x div 10,sdiscr_real,sdiscrp.srf);
    //16:xlat16to16_scale(direct_scale_10x div 10,sdiscr_real,sdiscrp.srf);
    32:xlat32to32_scale_linear(direct_scale_10x,sdiscr_real,sdiscrp.srf);
   end;
  end;
 end;
end;
//############################################################################//
procedure sdi_post_flip(real:pointer);
begin
 sdiscr_real:=real;
 if doublebuf then move(sdiscrp.srf^,sdiscr_real^,scrx*scry*scrbitbin) else if direct_scale_10x=10 then sdiscrp.srf:=sdiscr_real;
end;
//############################################################################//
begin
end.
//############################################################################//

