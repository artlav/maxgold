//############################################################################//
// Made in 2003-2015 by Artyom Litvinovich
// AlgorLib: PNG loader
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit png;
interface
uses asys,vfsint,sysutils,grph,imglib,zlib,math;
//############################################################################//
function ldpngbuf   (buf:pointer;bs:integer;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;                  status:pdouble=nil):pointer;
function ldpngbuf_16(buf:pointer;bs:integer;                        out bx,by:integer;out p:pointer;                  status:pdouble=nil):pointer;
function ldpngbuf_8 (buf:pointer;bs:integer;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;out cpal:pallette;status:pdouble=nil):pointer;

function ispngbuf(buf:pointer;bs:integer):boolean;        
function ispng (fn:string):boolean;
function ispng8(fn:string):boolean;   
 
function ldpng (fn:string;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;                  status:pdouble=nil):pointer;
function ldpng8(fn:string;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;out cpal:pallette;status:pdouble=nil):pointer;
//############################################################################//
//############################################################################//
implementation
//############################################################################//
const pngid:array[0..7]of byte=(137,80,78,71,13,10,26,10);

type
a4c=array[0..3]of char;
pnghdr=array[0..7]of byte;
ppnghdr=^pnghdr;
pngchkhdr=record
 lng:dword;
 tp:a4c;
end;

pngchklf=record
 lng:dword;
 tp:a4c;
 aux,pri,res,stc:boolean;
 dat:pointer;
 crc:dword;
end;

pngihdr=packed record
 wid,hei:dword;
 bit,cltyp,comp,filt,intl:byte;
end;
ppngihdr=^pngihdr;

pngpaltyp=array of crgb;

type a4b=array[0..3]of byte;
//pa4b=^a4b;
//############################################################################//
//############################################################################//
function dwle2be(d:dword):dword;
var c:a4b;
begin
 c:=a4b(d);
 a4b(result)[0]:=c[3];
 a4b(result)[1]:=c[2];
 a4b(result)[2]:=c[1];
 a4b(result)[3]:=c[0];
end;
//############################################################################//
function PaethPredictor(a,b,c:Byte):Byte;
var p,pa,pb,pc:Integer;
begin
 //a=left, b=above, c=upper left
 p:=a+b-c;        //initial estimate
 pa:=abs(p-a);    //distances to a, b, c
 pb:=abs(p-b);
 pc:=abs(p-c);
 //return nearest of a, b, c, breaking ties in order a, b, c
 if(pa<=pb)and(pa<=pc)then result:=a else if pb<=pc then result:=b else result:=c;
end;
//############################################################################//
procedure pngApplyFilter(Filter:Byte;Line,PrevLine,Target:PByte;BPP,BytesPerRow:integer);
// Applies the filter given in Filter to all bytes in Line (eventually using PrevLine).
// Note: The filter type is assumed to be of filter mode 0, as this is the only one currently
//       defined in PNG.
//       in opposition to the PNG documentation different identifiers are used here.
//       Raw refers to the current, not yet decoded value. decoded refers to the current, already
//       decoded value (this one is called "raw" in the docs) and Prior is the current value in the
//       previous line. For the Paeth prediction scheme a fourth pointer is used (Priordecoded) to describe
//       the value in the previous line but less the BPP value (Prior[x - BPP]).      
var i:integer;
Raw,decoded,Prior,Priordecoded,TargetRun:PByte;
begin
 case Filter of
  //0:Move(Line^,Target^,BytesPerRow);//no filter, just copy data
  1:begin //subtraction filter
   Raw:=Line;
   TargetRun:=Target;
   //Transfer BPP bytes without filtering. This mimics the effect of bytes left to the
   //scanline being zero.
   //move(Raw^,TargetRun^,BPP);

   //Now do rest of the line
   decoded:=TargetRun;
   inc(Raw,BPP);
   inc(TargetRun,BPP);
   dec(BytesPerRow,BPP);
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+decoded^);
    inc(Raw);inc(decoded);inc(TargetRun);dec(BytesPerRow);
   end;
  end;
  2:begin //Up filter
   Raw:=Line;
   Prior:=PrevLine;
   TargetRun:=Target;
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+Prior^);
    inc(Raw);
    inc(Prior);
    inc(TargetRun);
    dec(BytesPerRow);
   end;
  end;
  3:begin //average filter
   //first handle BPP virtual pixels to the left
   Raw:=Line;
   decoded:=Line;
   Prior:=PrevLine;
   TargetRun:=Target;
   for i:=0 to BPP-1 do begin
    TargetRun^:=Byte(Raw^+Floor(Prior^/2));
    inc(Raw);inc(Prior);inc(TargetRun);
   end;
   dec(BytesPerRow,BPP);

   //now do rest of line
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+Floor((decoded^+Prior^)/2));
    inc(Raw);inc(decoded);inc(Prior);inc(TargetRun);dec(BytesPerRow);
   end;
  end;
  4:begin //paeth prediction
   //again, start with first BPP pixel which would refer to non-existing pixels to the left
   Raw:=Line;
   decoded:=Target;
   Prior:=PrevLine;
   Priordecoded:=PrevLine;
   TargetRun:=Target;
   for i:=0 to BPP-1 do begin
    TargetRun^:=Byte(Raw^+PaethPredictor(0,Prior^,0));
    inc(Raw);inc(Prior);inc(TargetRun);
   end;
   dec(BytesPerRow,BPP);

   //finally do rest of line
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+PaethPredictor(decoded^,Prior^,Priordecoded^));
    inc(Raw);inc(decoded);inc(Prior);inc(Priordecoded);inc(TargetRun);dec(BytesPerRow);
   end;
  end;
 end;
end;
//############################################################################//
procedure pngApplyFilter_zero(Filter:Byte;Line,Target:PByte;BPP,BytesPerRow:integer);
var i:integer;
Raw,decoded,TargetRun:PByte;
begin
 case Filter of
  //0:Move(Line^,Target^,BytesPerRow);//no filter, just copy data
  1:begin //subtraction filter
   Raw:=Line;
   TargetRun:=Target;
   //Transfer BPP bytes without filtering. This mimics the effect of bytes left to the
   //scanline being zero.
   //move(Raw^,TargetRun^,BPP);

   //Now do rest of the line
   decoded:=TargetRun;
   inc(Raw,BPP);
   inc(TargetRun,BPP);
   dec(BytesPerRow,BPP);
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+decoded^);
    inc(Raw);inc(decoded);inc(TargetRun);dec(BytesPerRow);
   end;
  end;
  2:begin //Up filter
   Raw:=Line;
   TargetRun:=Target;
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+0);
    inc(Raw);
    inc(TargetRun);
    dec(BytesPerRow);
   end;
  end;
  3:begin //average filter
   //first handle BPP virtual pixels to the left
   Raw:=Line;
   decoded:=Line;
   TargetRun:=Target;
   for i:=0 to BPP-1 do begin
    TargetRun^:=Byte(Raw^);
    inc(Raw);inc(TargetRun);
   end;
   dec(BytesPerRow,BPP);

   //now do rest of line
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+Floor((decoded^)/2));
    inc(Raw);inc(decoded);inc(TargetRun);dec(BytesPerRow);
   end;
  end;
  4:begin //paeth prediction
   //again, start with first BPP pixel which would refer to non-existing pixels to the left
   Raw:=Line;
   decoded:=Target;
   TargetRun:=Target;
   for i:=0 to BPP-1 do begin
    TargetRun^:=Byte(Raw^+PaethPredictor(0,0,0));
    inc(Raw);inc(TargetRun);
   end;
   dec(BytesPerRow,BPP);

   //finally do rest of line
   while BytesPerRow>0 do begin
    TargetRun^:=Byte(Raw^+decoded^);
    inc(Raw);inc(decoded);inc(TargetRun);dec(BytesPerRow);
   end;
  end;
 end;
end;
//############################################################################//
procedure filter_line(grdat:pointer;bpr,bpp,y:integer);
var fi:byte;
off,prev_off:integer;
g:pbytea;
begin
 g:=grdat;
 off:=y*(bpr+1);
 prev_off:=(y-1)*(bpr+1);
 fi:=g[off];
 if y<>0 then pngApplyFilter     (fi,@g[off+1],@g[prev_off+1],@g[off+1],bpp,bpr)
         else pngApplyFilter_zero(fi,@g[off+1],@g[off+1],bpp,bpr);
end;
//############################################################################//
//############################################################################//
//############################################################################//  
function ispng(fn:string):boolean;
var f:vfile;
pngh:pnghdr;
i:integer;
begin
 result:=true;  
 vfopen(f,fn,VFO_READ);
 
 if vffilesize(f)<=8 then begin vfclose(f); result:=false; exit; end;
 vfread(f,@pngh,8); 
 for i:=0 to 7 do if pngh[i]<>pngid[i] then result:=false;     
 vfclose(f);
end;
//############################################################################//  
function ispngbuf(buf:pointer;bs:integer):boolean;
var i:integer;
begin
 result:=false;
 if buf=nil then exit;
 if bs<=8 then exit;
 for i:=0 to 7 do if ppnghdr(buf)[i]<>pngid[i] then exit;
 result:=true;   
end;
//############################################################################//
//############################################################################//
function ispng8(fn:string):boolean;
var f:vfile;
pngh:pnghdr;
i:integer;
        
chh:pngchkhdr;
lng:integer;
 
begin
 result:=false;  
 if vfopen(f,fn,VFO_READ)<>VFERR_OK then exit;
 if vffilesize(f)<=8 then begin vfclose(f);exit; end;

 //Header
 vfread(f,@pngh,8);  
 for i:=0 to 7 do if pngh[i]<>pngid[i] then begin vfclose(f);exit;end;  
 
 //Sections
 repeat 
  vfread(f,@chh,8);
  lng:=dwle2be(chh.lng);
  if lng=0 then begin vfclose(f);exit;end;
  if chh.tp='IHDR' then begin  
   vfseek(f,dword(vffilepos(f))+dword(lng+4));
  end else if chh.tp='IDAT' then begin  
   vfseek(f,dword(vffilepos(f))+dword(lng+4));
  end else if chh.tp='PLTE' then begin   
   result:=true; 
   vfclose(f);  
   exit;
   vfseek(f,dword(vffilepos(f))+dword(lng+4));
  end else begin
   vfseek(f,dword(vffilepos(f))+dword(lng+4));
  end;
 until vfeof(f); 
 
 vfclose(f);  
end;
//###########################################################################//
function decompress_png(grdat,cmpdat:pointer;uds,cds:integer):boolean;
var res:integer;
cs,ds:dword;
begin
 cs:=cds;
 ds:=uds;
 res:=do_inflate_zlib(cmpdat,grdat,cs,ds);
 result:=res=0;
 {$ifdef pngdbg}if not result then writeln('Decompress error: ',res);{$endif}
end;
//###########################################################################//
procedure produce_crgba_image(grdat,p:pointer;t,w,h,bpp,bpr:integer;var pal:pngpaltyp;wtx,wa:boolean;trc:crgb);
var x,y:integer;
ci:pcrgb;
co,ci4:pcrgba;
cb:byte;
cbw:word;  
g,r:pbytea;
begin
 g:=grdat;
 r:=p;
 for y:=0 to h-1 do begin  
  filter_line(grdat,bpr,bpp,y);
  case t of
   28:for x:=0 to w-1 do begin
    ci:=@g[1+x*3+y*w*3+y];
    co:=@r[(x+y*w)*4];   
    
    {$ifdef BGR}   
    co[0]:=ci[2];co[1]:=ci[1];co[2]:=ci[0]; 
    {$else}    
    co[2]:=ci[2];co[1]:=ci[1];co[0]:=ci[0]; 
    {$endif} 
    co[3]:=ord(not wa)*$FF;
    if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
   end;
   68:for x:=0 to w-1 do begin        
    ci4:=@g[1+x*4+y*w*4+y];
    co:=@r[(x+y*w)*4];   
             
    {$ifdef BGR}   
    co[2]:=ci4[0];co[1]:=ci4[1];co[0]:=ci4[2]; 
    {$else}    
    co[2]:=ci4[2];co[1]:=ci4[1];co[0]:=ci4[0];
    {$endif} 
    //co[3]:=ord(not wa)*$FF;
    //if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
    //if wtx then co[3]:=ci4[3];
    co[3]:=ci4[3];
   end;
   38:for x:=0 to w-1 do begin 
    cb:=g[1+x+y*w+y];
    co:=@r[(x+y*w)*4];    
    
    {$ifdef BGR}   
    co[2]:=pal[cb][2];co[1]:=pal[cb][1];co[0]:=pal[cb][0];
    {$else}    
    co[0]:=pal[cb][2];co[1]:=pal[cb][1];co[2]:=pal[cb][0];
    {$endif} 
    co[3]:=ord(not wa)*$FF; 
    if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
   end;
   34:for x:=0 to w-1 do begin
    cb:=g[1+x div 2+y*bpr+y];
    if x mod 2=1 then cb:=cb and $0F else cb:=cb shr 4;
    co:=@r[(x+y*w)*4];    
    
    co[2]:=pal[cb][2];co[1]:=pal[cb][1];co[0]:=pal[cb][0];  
    co[3]:=ord(not wa)*$FF;
    if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
   end;
   32:for x:=0 to w-1 do begin           
    cb:=g[1+x div 4+y*bpr+y];
    cb:=(cb shr (2*(3-(x mod 4))))and $03;   
    co:=@r[(x+y*w)*4];  
    
    co[2]:=pal[cb][2];co[1]:=pal[cb][1];co[0]:=pal[cb][0];  
    co[3]:=ord(not wa)*$FF;
    if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
   end;
   31:for x:=0 to w-1 do begin       
    cb:=g[1+x div 8+y*bpr+y];
    cb:=(cb shr (7-(x mod 8)))and $01;  
    co:=@r[(x+y*w)*4];  
    
    co[2]:=pal[cb][2];co[1]:=pal[cb][1];co[0]:=pal[cb][0];  
    co[3]:=ord(not wa)*$FF;
    if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
   end;
   01,02,04,08,16:for x:=0 to w-1 do begin          
    co:=@r[(x+y*w)*4];

    case t of
     16:begin cbw:=pword(intptr(grdat)+intptr(y*(bpr+1)+1+x*2))^;co[2]:=cbw mod 256;end;
     08:begin cb:=g[1+x+y*bpr+y];co[2]:=cb;end;
     04:begin cb:=g[1+x div 4+y*(bpr+1)];if x mod 2=1 then cb:=cb and $0F else cb:=cb shr 4;co[2]:=16*cb;end;
     02:begin cb:=g[1+x div 4+y*(bpr+1)];cb:=(cb shr (2*(3-(x mod 4))))and $03;co[2]:=64*cb;end;
     01:begin 
      cb:=g[1+x div 8+y*(bpr+1)];
      cb:=(cb shr (7-(x mod 8)))and $01;
      co[2]:=255*cb;
     end;
    end;

    co[1]:=co[2];co[0]:=co[2];co[3]:=ord(not wa)*$FF;
    if wtx then if (trc[0]=co[0])and(trc[1]=co[1])and(trc[2]=co[2]) then co[3]:=$00;
   end;
  end;   
 end;
end;
//###########################################################################//
procedure produce_data16_image(grdat,p:pointer;w,h,bpp,bpr:integer);
var x,y:integer;
begin
 for y:=0 to h-1 do begin
  filter_line(grdat,bpr,bpp,y);
  for x:=0 to w-1 do pworda(p)[x+y*w]:=pword(intptr(grdat)+intptr(y*bpr+y+1+x*2))^;
 end; 
end;
//###########################################################################//
procedure produce_data8_image(grdat,p:pointer;t,w,h,bpp,bpr:integer;var pal:pngpaltyp;wtx,wa:boolean;trc:crgb);
var x,y:integer;  
cb:byte;
g,r:pbytea;
begin
 g:=grdat;
 r:=p;
 for y:=0 to h-1 do begin
  filter_line(grdat,bpr,bpp,y);
  case t of
   28:for x:=0 to w-1 do r[x+y*w]:=g[1+x*3+y*(w*3+1)];
   38:for x:=0 to w-1 do r[x+y*w]:=g[1+x+y*(bpr+1)];   
   34:for x:=0 to w-1 do begin
    cb:=g[1+x div 2+y*(bpr+1)];
    if x mod 2=1 then cb:=cb and $0F else cb:=cb shr 4;
    r[x+y*w]:=cb;
   end;
   32:for x:=0 to w-1 do begin
    cb:=g[1+x div 4+y*(bpr+1)];
    cb:=(cb shr (2*(3-(x mod 4))))and $03;
    r[x+y*w]:=cb;
   end;
   31:for x:=0 to w-1 do begin
    cb:=g[1+x div 8+y*(bpr+1)];
    cb:=(cb shr (7-(x mod 8)))and $01;
    r[x+y*w]:=cb;
   end;
   08:for x:=0 to w-1 do r[x+y*w]:=g[1+x+y*(bpr+1)];
   04:for x:=0 to w-1 do begin
    cb:=g[1+x div 2+y*(bpr+1)];
    if x mod 2=1 then cb:=cb and $0F else cb:=cb shr 4;
    r[x+y*w]:=cb;
   end;
   02:for x:=0 to w-1 do begin
    cb:=g[1+x div 4+y*(bpr+1)];
    cb:=(cb shr (2*(3-(x mod 4))))and $03;
    r[x+y*w]:=64*cb;
   end;
   01:for x:=0 to w-1 do begin
    cb:=g[1+x div 8+y*(bpr+1)];
    cb:=(cb shr (7-(x mod 8)))and $01;   
    r[x+y*w]:=255*cb;
   end;
  end;
 end;
end;
//############################################################################//   
function break_png(buf:pointer;bs:integer;out cmpdat:pointer;out cds,w,h:integer;out bc,ct:byte;out pal:pngpaltyp):boolean;
var pngh:pnghdr;
chh:pngchkhdr;
chs:array of pngchklf; 
idps,idls:array of integer; 
cpal:pngpaltyp;

bp:dword;
c,i:integer;

procedure bufread(p:pointer;l:dword);
begin
 move(pbytea(buf)[bp],p^,l);
 bp:=bp+l;
end;

begin
 result:=false;
 cmpdat:=nil;bc:=0;ct:=0;w:=-1;h:=-1;bp:=0;setlength(chs,0);   
 if bs<8 then exit;
 
 //Header
 bufread(@pngh,8);
 
 //Sections
 repeat 
  c:=length(chs);
  setlength(chs,c+1);
  chs[c].dat:=nil;
  
  bufread(@chh,8);
  chs[c].lng:=dwle2be(chh.lng);
  chs[c].tp:=chh.tp;
  chs[c].aux:=(byte(chh.tp[0])and 32<>0);
  chs[c].pri:=(byte(chh.tp[1])and 32<>0);
  chs[c].res:=(byte(chh.tp[2])and 32<>0);
  chs[c].stc:=(byte(chh.tp[3])and 32<>0);

  if chs[c].tp='IHDR' then begin  
   getmem(chs[c].dat,chs[c].lng);
  
   bufread(chs[c].dat,chs[c].lng);
   
   w:=dwle2be(ppngihdr(chs[c].dat).wid);
   h:=dwle2be(ppngihdr(chs[c].dat).hei);
   bc:=ppngihdr(chs[c].dat).bit;
   ct:=ppngihdr(chs[c].dat).cltyp;
   
   bufread(@chs[c].crc,4);
  end else if chs[c].tp='IDAT' then begin  
   setlength(idps,c+1);
   setlength(idls,c+1);
   idls[c]:=chs[c].lng;
   idps[c]:=bp;

   bp:=bp+chs[c].lng;

   bufread(@chs[c].crc,4);
  end else if chs[c].tp='PLTE' then begin    
   setlength(pal,chs[c].lng div 3);
   setlength(cpal,chs[c].lng div 3);
       
   bufread(@cpal[0],chs[c].lng);  
   for i:=0 to chs[c].lng div 3-1 do begin 
    pal[i][CLRED]:=cpal[i][0];
    pal[i][CLGREEN]:=cpal[i][1];
    pal[i][CLBLUE]:=cpal[i][2];
   end;
   setlength(cpal,0);
   
   bufread(@chs[c].crc,4); 
  end else begin
   if bp+chs[c].lng>dword(bs) then exit;
   bp:=bp+chs[c].lng;
   bufread(@chs[c].crc,4); 
  end;
 until bp>=dword(bs-4); 

 for i:=0 to length(chs)-1 do if chs[i].dat<>nil then freemem(chs[i].dat); 

 //Verify
 if w=-1 then exit;
       
 //Doload and process
 cds:=0;
 for i:=0 to length(idls)-1 do cds:=cds+idls[i];   
 getmem(cmpdat,cds);
 c:=0;
 for i:=0 to length(idls)-1 do begin 
  bp:=idps[i];
  bufread(@pbytea(cmpdat)[c],idls[i]); 
  c:=c+idls[i];
 end;

 result:=true;
end;
//############################################################################//   
function decode_ct_bc(ct,bc:byte;w,h:integer;out uds,bpr,bpp,t:integer):boolean;
begin
 result:=false;
 case ct of
  0:case bc of                                                                           
   16:begin bpr:=w*2;                    bpp:=2;t:=16;end;
    8:begin bpr:=w;                      bpp:=1;t:=08;end;
    4:begin bpr:=w div 2+ord(w mod 2<>0);bpp:=1;t:=04;end;
    2:begin bpr:=w div 4+ord(w mod 4<>0);bpp:=1;t:=02;end;
    1:begin bpr:=w div 8+ord(w mod 8<>0);bpp:=1;t:=01;end;
    else exit;
  end;
  2:case bc of                                                                           
    8:begin bpr:=3*w;                    bpp:=3;t:=28;end;
    else exit;
  end;
  3:case bc of  
    8:begin bpr:=w;                      bpp:=1;t:=38;end;
    4:begin bpr:=w div 2+ord(w mod 2<>0);bpp:=1;t:=34;end;
    2:begin bpr:=w div 4+ord(w mod 4<>0);bpp:=1;t:=32;end;
    1:begin bpr:=w div 8+ord(w mod 8<>0);bpp:=1;t:=31;end;
    else exit;
  end;  
  6:case bc of                                                                           
    8:begin bpr:=4*w;                    bpp:=4;t:=68;end;
    else exit;
  end;
  else exit;
 end;
 uds:=(bpr+1)*h;
 result:=true;
end;
//############################################################################//   
function decode_ct_bc_8(ct,bc:byte;w,h:integer;out uds,bpr,bpp,t:integer):boolean;
begin
 result:=false;

 case ct of
  0:case bc of
   8:begin bpr:=w;                      bpp:=1;t:=08;end; 
   4:begin bpr:=w div 2+ord(w mod 2<>0);bpp:=1;t:=04;end; 
   2:begin bpr:=w div 4+ord(w mod 4<>0);bpp:=1;t:=02;end; 
   1:begin bpr:=w div 8+ord(w mod 8<>0);bpp:=1;t:=01;end;
   else exit;
  end;  
  2:case bc of
   8:begin bpr:=3*w;                    bpp:=3;t:=28;end;
   else exit; 
  end;
  3:case bc of
   8:begin bpr:=w;                      bpp:=1;t:=38;end; 
   4:begin bpr:=w div 2+ord(w mod 2<>0);bpp:=1;t:=34;end; 
   2:begin bpr:=w div 4+ord(w mod 4<>0);bpp:=1;t:=32;end; 
   1:begin bpr:=w div 8+ord(w mod 8<>0);bpp:=1;t:=31;end; 
   else exit;
  end;
  else exit;
 end;

 uds:=(bpr+1)*h;
 result:=true;
end;
//############################################################################//   
function ldpngbuf(buf:pointer;bs:integer;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;status:pdouble=nil):pointer;
var bc,ct:byte;
t,w,h,cds,uds,bpr,bpp:integer;
cmpdat,grdat:pointer;
pal:pngpaltyp;
begin      
 result:=nil;
 wa:=not wa;
 bx:=0;
 by:=0;
 p:=nil;

 if not break_png(buf,bs,cmpdat,cds,w,h,bc,ct,pal) then exit;  
 
 //Decode  
 if not decode_ct_bc(ct,bc,w,h,uds,bpr,bpp,t) then begin freemem(cmpdat);exit;end;
 
 //Decompress  
 getmem(grdat,uds);
 if not decompress_png(grdat,cmpdat,uds,cds) then begin freemem(cmpdat);freemem(grdat);exit;end;
 freemem(cmpdat);
            
 //Process            
 getmem(p,w*h*4); 
 produce_crgba_image(grdat,p,t,w,h,bpp,bpr,pal,wtx,wa,trc);
        
 //Fin 
 bx:=w;
 by:=h;
 result:=p;
 freemem(grdat);            
end;   
//############################################################################//   
function ldpngbuf_16(buf:pointer;bs:integer;out bx,by:integer;out p:pointer;status:pdouble=nil):pointer;
var bc,ct:byte;
t,w,h,cds,uds,bpr,bpp:integer;
cmpdat,grdat:pointer;
pal:pngpaltyp;
begin      
 result:=nil;
 bx:=0;
 by:=0;
 p:=nil;

 if not break_png(buf,bs,cmpdat,cds,w,h,bc,ct,pal) then exit;  
 
 //Decode  
 if not decode_ct_bc(ct,bc,w,h,uds,bpr,bpp,t) then begin freemem(cmpdat);exit;end;
 
 //Decompress  
 getmem(grdat,uds);
 if not decompress_png(grdat,cmpdat,uds,cds) then begin freemem(cmpdat);freemem(grdat);exit;end;
 freemem(cmpdat);
            
 //Process            
 getmem(p,w*h*2); 
 produce_data16_image(grdat,p,w,h,bpp,bpr);
        
 //Fin 
 bx:=w;
 by:=h;
 result:=p;
 freemem(grdat);            
end;   
//############################################################################//  
function ldpngbuf_8(buf:pointer;bs:integer;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;out cpal:pallette;status:pdouble=nil):pointer;
var bc,ct:byte;
i,t,w,h,cds,uds,bpr,bpp:integer;
cmpdat,grdat:pointer;
pal:pngpaltyp;
begin 
 result:=nil;  
 bx:=0;
 by:=0;  
 p:=nil; 
 
 if not break_png(buf,bs,cmpdat,cds,w,h,bc,ct,pal) then exit;
 
 for i:=0 to length(pal)-1 do begin
  cpal[i][CLRED]:=pal[i][CLRED];
  cpal[i][CLGREEN]:=pal[i][CLGREEN];
  cpal[i][CLBLUE]:=pal[i][CLBLUE];
  cpal[i][3]:=255;
 end;
       
 //Decode  
 if not decode_ct_bc_8(ct,bc,w,h,uds,bpr,bpp,t) then begin freemem(cmpdat);exit;end;
 
 //Decompress  
 getmem(grdat,uds);
 if not decompress_png(grdat,cmpdat,uds,cds) then begin freemem(cmpdat);freemem(grdat);exit;end;
 freemem(cmpdat);
   
 //Process            
 getmem(p,w*h*4);  
 produce_data8_image(grdat,p,t,w,h,bpp,bpr,pal,wtx,wa,trc);
 
 //Fin. 
 bx:=w;
 by:=h;
 result:=p;
 freemem(grdat);         
end;   
//############################################################################//
//############################################################################//     
function ldpng(fn:string;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;status:pdouble=nil):pointer;
var bs:integer;
fif:vfile;
buf:pointer;
begin   
 vfopen(fif,fn,VFO_READ);
 bs:=vffilesize(fif);
 getmem(buf,bs+4);
 vfread(fif,buf,bs);
 vfclose(fif);
 result:=ldpngbuf(buf,bs,wtx,wa,trc,bx,by,p); 
 freemem(buf);
end;  
//############################################################################//     
function ldpng8(fn:string;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;out cpal:pallette;status:pdouble=nil):pointer;
var bs:integer;
fif:vfile;
buf:pointer;
begin
 vfopen(fif,fn,VFO_READ);
 bs:=vffilesize(fif);
 getmem(buf,bs+4);
 vfread(fif,buf,bs);
 vfclose(fif);
 result:=ldpngbuf_8(buf,bs,wtx,wa,trc,bx,by,p,cpal); 
 freemem(buf);
end;
//############################################################################//
begin  
 register_grfmt(ispng8,ispng,ldpng8,ldpng,nil,ispngbuf,nil,ldpngbuf);  
end.
//############################################################################//
