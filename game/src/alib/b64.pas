//############################################################################//  
//Made in 2003-2016 by Artyom Litvinovich
//AlgorLib: B64
//############################################################################//  
{$ifdef fpc}{$mode delphi}{$endif} 
unit b64;
interface
uses asys;
//############################################################################//
function b64_enc(src:pointer;src_sz:dword;dst:pointer;dst_sz:dword;newlines:boolean):dword; 
function b64_dec(src:pointer;src_sz:dword;dst:pointer;dst_sz:dword):dword;  
function b64_dec_str(s:string):string;
function b64_enc_str(s:string):string;
function b64_enc_buf_str(src:pointer;src_sz:dword):string;

{$ifdef self_tests}procedure b64_test;{$endif}
//############################################################################//  
implementation
//############################################################################//  
const 
keytab:array[0..63]of char=
(
 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
 'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
 'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
 'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
);
//############################################################################//  
rev_map:array[0..255]of byte=(
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  62, 255, 255, 255,  63,
  52,  53,  54,  55,  56,  57,  58,  59,  60,  61, 255, 255, 255,  64, 255, 255,
 255,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,
  15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 255, 255, 255, 255, 255,
 255,  26,  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40,
  41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
);
//############################################################################//  
function b64_enc(src:pointer;src_sz:dword;dst:pointer;dst_sz:dword;newlines:boolean):dword;  
var tbo:array[0..2]of byte;
tc:array[0..3]of char;
i,out_pos:dword; 
pdst,psrc:pbytea;
begin
 result:=$FFFFFFFF;
 pdst:=dst;
 psrc:=src;
 
 i:=src_sz div 3;
 if (src_sz mod 3)<>0 then i:=i+1;
 if newlines then i:=i*4+(i div 19) else i:=i*4;
 if dst_sz<i then exit;
 
 {$ifndef paser}try{$endif}
  i:=0;
  out_pos:=0;
  repeat
   pdst[out_pos+0]:=ord(keytab[     psrc[i*3+0]        shr 2]);
   pdst[out_pos+1]:=ord(keytab[byte(psrc[i*3+0] shl 6) shr 2+psrc[i*3+1] shr 4]);
   pdst[out_pos+2]:=ord(keytab[byte(psrc[i*3+1] shl 4) shr 2+psrc[i*3+2] shr 6]);
   pdst[out_pos+3]:=ord(keytab[byte(psrc[i*3+2] shl 2) shr 2]);

   out_pos:=out_pos+4;
   i:=i+1;
   if newlines then if i mod 19=0 then begin pdst[out_pos]:=$0A;out_pos:=out_pos+1;end;
  until i>=src_sz div 3;
 
  if src_sz mod 3<>0 then begin
   i:=src_sz mod 3;
   if i>0 then tbo[0]:=psrc[src_sz-i+0] else tbo[0]:=0;
   if i>1 then tbo[1]:=psrc[src_sz-i+1] else tbo[1]:=0;
   if i>2 then tbo[2]:=psrc[src_sz-i+2] else tbo[2]:=0;

   tc[0]:=keytab[     tbo[0]        shr 2];
   tc[1]:=keytab[byte(tbo[0] shl 6) shr 2+tbo[1] shr 4];
   tc[2]:=keytab[byte(tbo[1] shl 4) shr 2+tbo[2] shr 6];
   tc[3]:=keytab[byte(tbo[2] shl 2) shr 2];

   if i=1 then begin tc[2]:='=';tc[3]:='=';end;
   if i=2 then tc[3]:='=';
 
   move(tc,pdst[out_pos],4);
   out_pos:=out_pos+4;
  end;
  result:=out_pos;
 {$ifndef paser}except end;{$endif}
end;
//############################################################################// 
function b64_dec(src:pointer;src_sz:dword;dst:pointer;dst_sz:dword):dword; 
var psrc,pdst:pbytea;
t:dword;
c:byte;
i,out_pos,fin_limit,sym_cnt:integer;
begin
 result:=$FFFFFFFF;   
   
 psrc:=src;
 pdst:=dst;
 
 if src=nil then exit;
 if dst=nil then exit;
 if dst_sz=0 then exit;

 fin_limit:=3;
 
 sym_cnt:=0;
 out_pos:=0;
 t:=0;
 
 for i:=0 to src_sz-1 do begin
  c:=rev_map[psrc[i]];
  if c=255 then continue;

  if c=64 then begin
   c:=0;
   fin_limit:=fin_limit-1;
   if fin_limit<0 then exit;
  end else if fin_limit<>3 then exit;

  t:=(t shl 6) or c;

  sym_cnt:=sym_cnt+1;
  if sym_cnt=4 then begin
   if dword(out_pos+fin_limit)>dst_sz then exit;
   
                             pdst[out_pos]:=t shr 16;out_pos:=out_pos+1;
   if fin_limit>1 then begin pdst[out_pos]:=t shr 8; out_pos:=out_pos+1;end;
   if fin_limit>2 then begin pdst[out_pos]:=t;       out_pos:=out_pos+1;end;
   
   sym_cnt:=0;
   t:=0;
  end;
 end;
 //if sym_cnt<>0 then exit;
 
 result:=out_pos;
end;  
//############################################################################//   
function b64_enc_str(s:string):string;
var sz:dword;
begin
 if s='' then begin result:='';exit;end;
 setlength(result,length(s)*2);
 sz:=b64_enc(@s[1],length(s),@result[1],length(result),false);
 setlength(result,sz);
end;  
//############################################################################//   
function b64_dec_str(s:string):string;
var sz:dword;
begin
 if s='' then begin result:='';exit;end;
 setlength(result,length(s)*2);
 sz:=b64_dec(@s[1],length(s),@result[1],length(result));
 if sz=$FFFFFFFF then begin result:=s;exit;end;
 setlength(result,sz);
end;
//############################################################################//
function b64_enc_buf_str(src:pointer;src_sz:dword):string;
var sz:dword;
begin
 setlength(result,10+src_sz*2);
 sz:=b64_enc(src,src_sz,@result[1],length(result),false);
 setlength(result,sz);
end;
//############################################################################//
{$ifdef self_tests}
procedure b64_test;
var inb,codeb,outb:pbytea;
sz,code_sz:integer;
i,j:integer;
ins,codes,outs:string;
begin
 randomize;
 writeln('B64: Buffer...');
 for j:=0 to 100 do begin
  sz:=random(1024){$ifndef paser}{$ifndef cpumips}*random(1024){$endif}{$endif}+100;
  getmem(inb,sz+10);
  getmem(outb,2*sz);
  for i:=0 to sz+10-1 do inb[i]:=random(256);
  for i:=0 to sz+10-1 do outb[i]:=inb[i];

  getmem(codeb,2*sz);
 
  code_sz:=b64_enc(inb,sz,codeb,2*sz,true);
  if b64_dec(codeb,code_sz,outb,2*sz)<>dword(sz) then writeln('B64: Size didn''t match');
 
  for i:=0 to sz-1 do if inb[i]<>outb[i] then begin
   writeln('B64: data didn''t match');
   break;
  end;
  
  for i:=sz to sz+10-1 do if inb[i]<>outb[i] then begin
   writeln('B64: tail data didn''t match');
   break;
  end;
  
  freemem(inb);
  freemem(outb);
  freemem(codeb);
 end;
 {$ifndef paser}
 writeln('B64: String...');
 for j:=0 to 100 do begin
  sz:=random(1024)+100;
  
  setlength(ins,sz);
  for i:=0 to sz-1 do ins[i+1]:=chr(random(256));

  codes:=b64_enc_str(ins);
  outs:=b64_dec_str(codes);
 
  for i:=0 to sz-1 do if ins[i+1]<>outs[i+1] then begin
   writeln('B64: data didn''t match');
   break;
  end;
 end;
 {$endif}

 writeln('B64: Done.');
end;
{$endif}
//############################################################################//  
begin
end.  
//############################################################################//  
