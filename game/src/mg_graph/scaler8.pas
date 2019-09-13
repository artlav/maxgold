//############################################################################//
//Main Sprite scaler
var x,y,xo,yo:integer;
sd,sd1,xs,ys,zxs,zys:integer;
psrc,pdst:pchar;
psrcp:intptr;
begin         
 if(spr=nil)or(dst=nil)then exit;
 if(spr.srf=nil)or(dst.srf=nil)then exit; 
 if(xp<-spr.xs)or(xp>=dst.xs)or(yp<-spr.ys)or(yp>=dst.ys)then exit;
 
 xs:=spr.xs;
 ys:=spr.ys;           
 zxs:=s.zoomsc[spr.xs];
 zys:=s.zoomsc[spr.ys]; 
 psrc:=spr.srf;
 pdst:=@pbytea(dst.srf)[xp+yp*dst.xs];
 sd:=dst.xs-zxs;
 sd1:=0;
 if((xp+zxs)<dst.xs)and((yp+zys)<dst.ys)and(xp>0)and(yp>0)then begin
  xo:=s.zoomsc[xs]; 
  yo:=s.zoomsc[ys];  
  y:=0;      
  repeat
   x:=0;
   psrcp:=intptr(psrc);
   repeat
    {$ifdef sprs}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=s.cg.shadow_shade[pbyte(pdst)^];{$endif}
    {$ifdef sprt}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=pbyte(psrc)^;{$endif}
    {$ifdef sprx}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=palx^[pbyte(psrc)^];{$endif}
    {$ifdef sprtra}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=s.cg.shadow_shade[palx^[pbyte(psrc)^]];{$endif}
    {$ifdef sprm}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=col;{$endif}  
    pdst:=pdst+1;
    psrc:=psrc+s.zoomof[x];
    x:=x+1;
   until x>=xo;
   psrc:=pointer(psrcp+intptr(xs*(s.zoomof[y]))); 
   pdst:=pdst+sd;  
   y:=y+1;  
  until y>=yo; 
  tdu:=tdu+xo*yo; 
 end else begin
  xp:=xp;yp:=yp;
  if((xp+zxs)>=dst.xs)then zxs:=xs-s.azoomsc[(xp+zxs)-dst.xs] else zxs:=xs;
  if((yp+zys)>=dst.ys)then zys:=ys-s.azoomsc[(yp+zys)-dst.ys] else zys:=ys;
  if xp>0 then xp:=0;xp:=s.azoomsc[-xp];
  if yp>0 then yp:=0;yp:=s.azoomsc[-yp];
  
  for y:=0 to ys-1 do if (y>=yp) then begin 
   if y>=zys then break;
   if s.zoomer[y] then begin
    for x:=0 to xs-1 do if s.zoomer[x] then begin  
     if(x>xp)and(x<zxs)then  
     {$ifdef sprs}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=s.cg.shadow_shade[pbyte(pdst)^];{$endif}
     {$ifdef sprt}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=pbyte(psrc)^;{$endif}
     {$ifdef sprx}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=palx^[pbyte(psrc)^];{$endif} 
     {$ifdef sprtra}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=s.cg.shadow_shade[palx^[pbyte(psrc)^]];{$endif}
     {$ifdef sprm}if(pbyte(psrc)^ xor 0)<>0 then pbyte(pdst)^:=col;{$endif}  
     psrc:=psrc+1;pdst:=pdst+1;
    end else psrc:=psrc+1;  
    psrc:=psrc+sd1;
    pdst:=pdst+sd; 
   end else psrc:=psrc+spr.xs;
  end else begin psrc:=psrc+spr.xs;pdst:=pdst+dst.xs*ord(s.zoomer[y]);  end;     
  tdu:=tdu+ys*xs; 
 end;
end;  
//############################################################################//
