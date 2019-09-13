//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit lzw;
interface
//############################################################################//
type //lossrange=0..4;
{$ifndef fpc}dword=cardinal;pdword=^dword;qword=int64;{$endif}
{$ifndef CPUX86_64}
intptr=dword;
{$else}
intptr=PtrUInt;
{$endif}
function decodeLZW(src,dst:pointer;siz,dstsiz:integer):integer;
function encodeLZW(src,dst:pointer;siz,dstsiz:dword;smooth_range:integer=0):integer;
{$ifndef paser}
function gif_lzw_decode(codesize,bpp:integer;data,out_data:pointer):integer;  
function gif_lzw_encode(code_size:integer;data,out_data:pointer;in_sz,out_sz:integer):integer;
{$endif}

{$ifdef self_tests}procedure lzw_test;{$endif}
//############################################################################//
implementation
//############################################################################//
type
bytea=array[0..maxint-1]of byte;
pbytea=^bytea;
//############################################################################//
const
powers2 :array[0..16]of integer=(1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,0,0);
powers  :array[0..8] of integer=(0,1,2,4,8,16,32,64,128);
maxcodes:array[0..12]of integer=(4,8,16,32,64,128,256,512,1024,2048,4096,8192,0);
codemask:array[0..8] of integer=(0,1,3,7,15,31,63,127,255);      
//############################################################################//
type
lzwtrec=record
 index,prefix:word;
 suffix,firstbyte:byte;
end;
pcluster=^tcluster;
tcluster=record
 index:word;
 next:pcluster;
end;
lzwrec=record
 clearcode,eoicode:integer;
 code_addr,dest:pbyte;
 code_len,init_code_len,borrowed_bits:byte;
 last_entry:dword;
 btrd:dword;
 lzwtable:array[0..4095]of lzwtrec;
 clusters:array[0..4095]of pcluster;
end;
plzwrec=^lzwrec;   
//############################################################################//    
gif_cls_rec=record
 idx,nxt:integer;
end;
gif_tab_rec=record
 sym,pref,cls:integer;
end;
gif_lzw_rec=record
 out_data:pointer;
 out_sz:integer;
 
 codesize:integer;
 clearcode,eofcode,init_codesize,first_code:integer;  
 cur_str:array[0..1024]of integer;
 tab:array[0..4096]of gif_tab_rec;  
 cls:array[0..4096]of gif_cls_rec;
 last_cls:integer;
 
 tc,bitsin:integer;  
 cp,ts,op:integer;
end;
//############################################################################//
function concatenation(var lzw:lzwrec;pprefix:word;lastbyte:byte;index:word):lzwtrec;
begin         
 result.suffix:=lastbyte;
 if pprefix=lzw.clearcode then begin
  result.index:=lastbyte;
  result.firstbyte:=lastbyte;
  result.prefix:=pprefix;
 end else begin
  result.index:=index;
  result.firstbyte:=lzw.lzwtable[pprefix].firstbyte;
  result.prefix:=lzw.lzwtable[pprefix].index;
 end;   
end;
//############################################################################//
procedure initialize(var lzw:lzwrec);
var i:integer;
begin                
 lzw.code_len:=lzw.init_code_len;
 lzw.clearcode:=powers2[lzw.code_len-1];
 lzw.eoicode:=lzw.clearcode+1;
 lzw.last_entry:=lzw.eoicode;
 for i:=0 to lzw.clearcode-1 do begin
  lzw.lzwtable[i].index:=i;
  lzw.lzwtable[i].prefix:=lzw.clearcode;
  lzw.lzwtable[i].suffix:=i;
  lzw.lzwtable[i].firstbyte:=i;
 end;
 for i:=lzw.clearcode to 4095 do begin
  lzw.lzwtable[i].index:=i;
  lzw.lzwtable[i].prefix:=lzw.clearcode;
  lzw.lzwtable[i].suffix:=0;
  lzw.lzwtable[i].firstbyte:=0;
 end;      
end;
//############################################################################//
procedure releaseclusters(var lzw:lzwrec);
var i:integer;
workcluster:pcluster;
begin
 for i:=0 to 4095 do begin
  while assigned(lzw.clusters[i]) do begin
  {
   workcluster:=lzw.clusters[i];
   lzw.clusters[i]:=lzw.clusters[i].next;
   dispose(workcluster);
  }     
   workcluster:=lzw.clusters[i].next;
   lzw.clusters[i].next:=nil;
   dispose(lzw.clusters[i]);
   lzw.clusters[i]:=workcluster;
  end;
 end;   
end;
//############################################################################//
procedure clearclusters(var lzw:lzwrec);
var i:integer;
begin
 for i:=0 to 4095 do lzw.clusters[i]:=nil;   
end;      
//############################################################################//
procedure writebytes(var lzw:lzwrec;entry:lzwtrec);
begin
 if entry.prefix=lzw.clearcode then begin   
  lzw.dest^:=entry.suffix;
  inc(lzw.dest);
 end else begin
  writebytes(lzw,lzw.lzwtable[entry.prefix]);    
  lzw.dest^:=entry.suffix;  
  inc(lzw.dest);
 end;    
end;  
//############################################################################//
procedure addentry(var lzw:lzwrec;entry:lzwtrec);
begin
 lzw.lzwtable[entry.index]:=entry;
 lzw.last_entry:=entry.index;
 case lzw.last_entry of
  510,1022,2046:inc(lzw.code_len);
  4093:lzw.code_len:=lzw.init_code_len;
 end;
end;
//############################################################################//
function get_next_code(var lzw:lzwrec):word;
var cnt,a,b:byte;
begin
 cnt:=16+lzw.borrowed_bits-lzw.code_len;
 if cnt>8 then begin             
  a:=pbyte(intptr(lzw.code_addr)+0)^;
  b:=pbyte(intptr(lzw.code_addr)+1)^;
  
  a:=a and($FF shr(8-lzw.borrowed_bits));
  lzw.borrowed_bits:=8+lzw.borrowed_bits-lzw.code_len;    
  b:=b and($FF shl lzw.borrowed_bits);

  result:=(b+a shl 8) shr lzw.borrowed_bits;
  lzw.code_addr:=pointer(intptr(lzw.code_addr)+1);
 end else begin
  result:=pbyte(intptr(lzw.code_addr)+1)^+pbyte(intptr(lzw.code_addr)+0)^ shl 8;
  result:=result and($FFFF shr (8-lzw.borrowed_bits));
  result:=(result shl (8-cnt))or (pbyte(intptr(lzw.code_addr)+2)^ shr cnt);
  
  lzw.borrowed_bits:=cnt;
  lzw.code_addr:=pointer(intptr(lzw.code_addr)+2);
 end;
end;
//############################################################################//
function decodeLZW(src,dst:pointer;siz,dstsiz:integer):integer;
var lzw:plzwrec;
fcode,oldcode:word;
begin
 new(lzw);
 lzw.dest:=dst;
 lzw.borrowed_bits:=8;
 lzw.btrd:=0;
 lzw.code_addr:=src;
 lzw.init_code_len:=9;
 
 initialize(lzw^);
 oldcode:=lzw.clearcode;
 
 repeat
  fcode:=get_next_code(lzw^);  
  if (integer(intptr(lzw.code_addr)-intptr(src))>=siz)or(integer(intptr(lzw.dest)-intptr(dst))>=dstsiz) then begin 
   result:=integer(intptr(lzw.dest)-intptr(dst)); 
   //pbyte(src)^:=0;  //WTF?
   dispose(lzw);
   exit;
  end;
  
  if fcode=lzw.clearcode then begin
   initialize(lzw^);
   fcode:=get_next_code(lzw^);     
   if fcode=lzw.eoicode then break;
   writebytes(lzw^,lzw.lzwtable[fcode]);
   oldcode:=fcode;
  end else begin
   if fcode<=lzw.last_entry then begin   
    writebytes(lzw^,lzw.lzwtable[fcode]);
    addentry  (lzw^,concatenation(lzw^,oldcode,lzw.lzwtable[fcode].firstbyte,lzw.last_entry+1));
    oldcode:=fcode;
   end else begin
    if fcode>(lzw.last_entry+1) then begin
     break;
    end else begin   
     writebytes(lzw^,concatenation(lzw^,oldcode,lzw.lzwtable[oldcode].firstbyte,lzw.last_entry+1));
     addentry  (lzw^,concatenation(lzw^,oldcode,lzw.lzwtable[oldcode].firstbyte,lzw.last_entry+1));
     oldcode:=fcode;
    end;
   end;
  end;
 until fcode=lzw.eoicode;
 result:=integer(intptr(lzw.dest)-intptr(dst));   
 dispose(lzw);
end;
//############################################################################//
procedure writecodetostream(var lzw:lzwrec;code:word);
var t1,t2:word;
tb:byte;
begin
 if lzw.code_len>=lzw.borrowed_bits+8 then begin
  t1:=lzw.code_len-lzw.borrowed_bits-8; 
  tb:=((code-(code and($FFFF shl t1)))and $FF)shl(8-t1);
  t2:=code shr t1;

  lzw.dest^:=lzw.dest^ or (t2 shr 8);
  inc(lzw.dest); 
  lzw.dest^:=lzw.dest^ or (t2 and $FF);   
  inc(lzw.dest); 
  lzw.dest^:=lzw.dest^ or tb; 
  
  lzw.borrowed_bits:=8-t1;
 end else begin
  t2:=lzw.borrowed_bits-lzw.code_len+8;
  t1:=code shl t2;
  lzw.dest^:=lzw.dest^ or (t1 shr 8);
  inc(lzw.dest);      
  lzw.dest^:=lzw.dest^ or (t1 and $FF);
  lzw.borrowed_bits:=t2;
 end;
end;
//############################################################################//
function codefromstring(var lzw:lzwrec;str:lzwtrec):word;
var workcluster:pcluster;
begin
 if str.prefix=256 then result:=str.index else begin
  workcluster:=lzw.clusters[str.prefix];
  if workcluster=nil then result:=4095 else begin  
   while assigned(workcluster.next)do begin
    if str.suffix<>lzw.lzwtable[workcluster.index].suffix then workcluster:=workcluster.next else break;
   end;    
   if str.suffix=lzw.lzwtable[workcluster.index].suffix then result:=workcluster.index else result:=4095;   
  end;
 end;
end;
//############################################################################//
procedure addtableentry(var lzw:lzwrec;entry:lzwtrec);
var workcluster:pcluster;
begin
 lzw.lzwtable[entry.index]:=entry;
 lzw.last_entry:=entry.index;
 if lzw.clusters[lzw.lzwtable[lzw.last_entry].prefix]=nil then begin
  new(lzw.clusters[lzw.lzwtable[lzw.last_entry].prefix]);
  lzw.clusters[lzw.lzwtable[lzw.last_entry].prefix].index:=lzw.last_entry;
  lzw.clusters[lzw.lzwtable[lzw.last_entry].prefix].next:=nil;
 end else begin
  workcluster:=lzw.clusters[lzw.lzwtable[lzw.last_entry].prefix];
  while assigned(workcluster.Next) do workcluster:=workcluster.next;
  new(workcluster.next);
  workcluster.next.index:=lzw.last_entry;
  workcluster.next.next:=nil;
 end;
end;
//############################################################################//
function encodeLZW(src,dst:pointer;siz,dstsiz:dword;smooth_range:integer=0):integer;
var cbyte,byte_mask:byte;
vprefix,currentry:lzwtrec;
currcode:word;
i:integer;
stream:pbytea;
lzw:lzwrec;
begin    
 byte_mask:=($FF shr smooth_range) shl smooth_range;  
 fillchar(lzw,sizeof(lzw),0);
 lzw.dest:=dst;
 lzw.init_code_len:=9;
 fillchar(lzw.dest^,dstsiz,0);
 initialize(lzw);
 clearclusters(lzw);
 lzw.borrowed_bits:=8;
 writecodetostream(lzw,lzw.clearcode);
 lzw.code_addr:=src;
 stream:=src;
 lzw.btrd:=0;
 vprefix:=lzw.lzwtable[lzw.clearcode];
 for i:=0 to siz-1 do begin 
  cbyte:=stream[i] and byte_mask;
  currentry:=concatenation(lzw,vprefix.index,cbyte,lzw.last_entry+1);
  currcode:=codefromstring(lzw,currentry);
  if currcode<=lzw.last_entry then vprefix:=lzw.lzwtable[currcode] else begin
   writecodetostream(lzw,vprefix.index);
   Addtableentry(lzw,currentry);
   vprefix:=lzw.lzwtable[cbyte];
   case lzw.last_entry of
    511,1023,2047:inc(lzw.code_len);
    4093:begin
     writecodetostream(lzw,lzw.clearcode);
     lzw.code_len:=lzw.init_code_len;
     Releaseclusters(lzw);
     lzw.last_entry:=lzw.eoicode;
    end;
   end;
  end;
 end;
 writecodetostream(lzw,codefromstring(lzw,vprefix));
 writecodetostream(lzw,lzw.eoicode);
 releaseclusters(lzw);
 result:=1+intptr(lzw.dest)-intptr(dst);
end; 
//############################################################################//
{$ifndef paser}
function fetch_code(buf:pointer;var bp:integer;codesize:integer;var tc,bitsIn:integer):integer;
var i:integer;
begin
 result:=0; 
 for i:=0 to codesize-1 do begin
  inc(bitsIn);
  if bitsIn=9 then begin
   tc:=pbytea(buf)[bp];
   bp:=bp+1;
   bitsIn:=1;
  end;
  if (tc and powers[bitsIn])>0 then result:=result+powers2[i];
 end;
end;
//############################################################################//
function gif_lzw_decode(codesize,bpp:integer;data,out_data:pointer):integer;
var i:integer;
clearcode,eofcode:integer;
firstfree,initcodesize,bitmask:integer;
maxcode,freecode:integer;
bitsin,tc,out_cnt:integer;
code,prev_code,tmp_code,finchar:integer;

prefix,suffix:array[0..4096] of integer;
outcode:array[0..1024] of integer;

dp,op:integer;
begin
 dp:=0;
 op:=0;

 clearcode:=powers2[codesize];
 eofcode:=clearcode+1;
 firstfree:=clearcode+2; 
 initcodesize:=codesize+1;    
 bitmask:=codeMask[bpp];
 
 freecode:=firstfree;
 maxcode:=maxcodes[codesize-1];  
 codesize:=codesize+1;

 bitsin:=8;
 out_cnt:=0;
 tc:=0;
 finchar:=0;
 prev_code:=0;

 repeat
  code:=fetch_code(data,dp,codesize,tc,bitsIn);
  if code=eofcode then break;
  if code=clearcode then begin
   codesize:=Initcodesize;
   maxcode:=maxcodes[codesize-2];
   freecode:=firstfree;   
   code:=fetch_code(data,dp,codesize,tc,bitsIn);    
   prev_code:=code;
   finchar:=code and bitmask;    
   pbytea(out_data)[op]:=finchar;     
   op:=op+1;      
   if code=eofcode then break;
  end else begin
   tmp_code:=code;
   if code>=freecode then begin
    code:=prev_code;
    outcode[out_cnt]:=finchar;
    out_cnt:=out_cnt+1;
   end;
   if code>bitmask then repeat
    outcode[out_cnt]:={%H-}suffix[code];   
    out_cnt:=out_cnt+1;
    code:={%H-}prefix[code];
   until code<=bitmask;
   finchar:=code and bitmask;
   outcode[out_cnt]:=finchar;
   out_cnt:=out_cnt+1;
   for i:=out_cnt-1 downto 0 do begin
    pbytea(out_data)[op]:=outcode[i];   
    op:=op+1;
   end;
   out_cnt:=0;
   prefix[freecode]:=prev_code;
   suffix[freecode]:=finchar;

   prev_code:=tmp_code;
   freecode:=freecode+1;
   if (freecode>=maxcode) and (codesize<12) then begin
    codesize:=codesize+1;
    maxcode:=maxcode+maxcode;
   end;
  end;
 until false;

 result:=op;
end;
//############################################################################//
procedure dump_code(var lzw:gif_lzw_rec;code:integer);
var i:integer;
begin       
 for i:=0 to lzw.codesize-1 do begin
  lzw.tc:=lzw.tc shr 1;
  lzw.tc:=lzw.tc or ((code shl 7)and $80);
  code:=code shr 1;
  inc(lzw.bitsin);
  if lzw.bitsin=8 then begin
   pbytea(lzw.out_data)[lzw.op]:=lzw.tc;
   inc(lzw.op);
   lzw.bitsin:=0;
   lzw.tc:=0;
  end;
 end;
end;
//############################################################################//
function find_in_tab(var lzw:gif_lzw_rec;k,cc:integer):integer;
var i:integer;
begin
 result:=-1;
 
 if lzw.cp=0 then begin
  result:=k;
  exit;
 end;
 
 i:=lzw.tab[cc].cls;
 while i<>-1 do begin
  if lzw.tab[lzw.cls[i].idx].sym<>k then begin
   i:=lzw.cls[i].nxt;
   continue;
  end;
  result:=lzw.cls[i].idx;
  exit;
 end;
end;
//############################################################################//
procedure add_tab(var lzw:gif_lzw_rec;k,cur_code:integer);
var i:integer;
begin
 lzw.tab[lzw.ts].sym:=k;
 lzw.tab[lzw.ts].pref:=cur_code;
 lzw.tab[lzw.ts].cls:=-1;
 i:=lzw.tab[cur_code].cls;
 if i=-1 then begin
  i:=lzw.last_cls;
  lzw.tab[cur_code].cls:=i;
  lzw.last_cls:=lzw.last_cls+1;
  if lzw.last_cls>=length(lzw.cls) then halt;////writeln('Oops.'); //FIXME!
  
  lzw.cls[i].idx:=lzw.ts;
  lzw.cls[i].nxt:=-1;
 end else begin
  while lzw.cls[i].nxt<>-1 do i:=lzw.cls[i].nxt;
  lzw.cls[i].nxt:=lzw.last_cls;  
  lzw.cls[lzw.last_cls].idx:=lzw.ts;
  lzw.cls[lzw.last_cls].nxt:=-1; 
  lzw.last_cls:=lzw.last_cls+1;  
 end; 
 lzw.ts:=lzw.ts+1;  
end;
//############################################################################//
function gif_lzw_encode(code_size:integer;data,out_data:pointer;in_sz,out_sz:integer):integer;
var i,x,dp:integer;    
k,cur_code:integer;
lzw:gif_lzw_rec;
begin
 fillchar(out_data^,out_sz,0);

 lzw.out_data:=out_data;
 lzw.out_sz:=out_sz;   
 lzw.op:=0;
 
 lzw.codesize:=code_size;
 lzw.clearcode:=powers2[code_size];
 lzw.eofcode:=lzw.clearcode+1;
 lzw.first_code:=lzw.clearcode+2;
 lzw.codesize:=lzw.codesize+1;
 lzw.init_codesize:=lzw.codesize;

 lzw.tc:=0;
 lzw.bitsin:=0;
 lzw.last_cls:=0;
         
 for i:=0 to lzw.first_code-1 do begin 
  lzw.tab[i].sym:=i;    
  lzw.tab[i].pref:=-1;  
  lzw.tab[i].cls:=-1;
 end;
 
 dp:=0;
 lzw.cp:=0;
 lzw.ts:=lzw.first_code;
           
 dump_code(lzw,lzw.clearcode);
 cur_code:=0;    
 while dp<in_sz do begin
  k:=pbytea(data)[dp];dp:=dp+1;
  if dp=1 then cur_code:=k;
    
  x:=find_in_tab(lzw,k,cur_code);

  //FIXME: if cp>=1024...
  if x<>-1 then begin
   lzw.cur_str[lzw.cp]:=k;
   lzw.cp:=lzw.cp+1;
   cur_code:=x;
  end else begin
   add_tab(lzw,k,cur_code);
   
   //FIXME: possible 13 bit code for 2 steps?
   if lzw.ts-1>powers2[lzw.codesize] then lzw.codesize:=lzw.codesize+1;
             
   dump_code(lzw,cur_code);
   cur_code:=k;
   lzw.cur_str[0]:=k;
   lzw.cp:=1;

   if lzw.ts>4096 then begin      
    dump_code(lzw,lzw.clearcode);
    lzw.codesize:=lzw.init_codesize;
    lzw.ts:=lzw.first_code;
    for i:=0 to lzw.ts-1 do lzw.tab[i].cls:=-1;
    lzw.last_cls:=0;
   end;
  end;
 end;

 dump_code(lzw,cur_code);
 dump_code(lzw,lzw.eofcode);   
 if lzw.bitsin<>0 then begin pbytea(lzw.out_data)[lzw.op]:=lzw.tc shr (8-lzw.bitsin);lzw.op:=lzw.op+1;end;
 result:=lzw.op; 
end;
{$endif}
//############################################################################//  
{$ifdef self_tests}
const test_arr:array[0..143-1]of byte=(
$80,$00,$00,$20,$20,$18,$10,$0A,$06,$03,$82,$01,$20,$A0,$58,$30,$1A,$0E,$07,$84,
$02,$21,$20,$98,$50,$2A,$16,$0B,$86,$03,$21,$A0,$D8,$70,$3A,$1E,$0F,$88,$04,$22,
$21,$18,$90,$4A,$26,$13,$8A,$05,$22,$A1,$58,$B0,$5A,$2E,$17,$8C,$06,$23,$21,$98,
$D0,$6A,$36,$1B,$8E,$07,$23,$A1,$D8,$F0,$7A,$3E,$1F,$90,$08,$24,$22,$19,$10,$8A,
$46,$23,$92,$09,$24,$A2,$59,$30,$9A,$4E,$27,$94,$0A,$25,$22,$99,$50,$AA,$56,$2B,
$96,$0B,$25,$A2,$D9,$70,$BA,$5E,$2F,$98,$0C,$26,$23,$19,$90,$CA,$66,$33,$9A,$0D,
$26,$A3,$59,$B0,$DA,$6E,$37,$9C,$0E,$27,$23,$99,$D0,$EA,$76,$3B,$9E,$0F,$27,$A3,
$D9,$F2,$02);
//############################################################################//  
procedure lzw_test;
var inb,codeb,outb:pbytea;
sz,code_sz:integer;
i,j:integer;
begin
 //randomize;
   
 writeln('LZW: Initial...');
 sz:=125;
 getmem(inb,sz+10); 
 getmem(outb,2*sz);
 getmem(codeb,2*sz);
 for i:=0 to sz+10-1 do inb[i]:=i;
 code_sz:=encodeLZW(inb,codeb,sz,2*sz);  
 if code_sz<>143 then writeln('LZW: enc Size didn''t match');
 for i:=0 to 143-1 do if codeb[i]<>test_arr[i] then begin writeln('LZW: enc data didn''t match at ',i);break; end;
 //i:=
 decodeLZW(@test_arr[0],outb,code_sz,2*sz);
 //if i<>sz then writeln('Size didn''t match');
 for i:=0 to sz-1 do if inb[i]<>outb[i] then begin writeln('LZW: data didn''t match at ',i,' ',inb[i],' ',outb[i]);break;end;  
 //for i:=sz to sz+10-1 do if inb[i]<>outb[i] then begin writeln('LZW: tail data didn''t match');break;end;  
 freemem(inb);
 freemem(outb);
 freemem(codeb);
 
 
 writeln('LZW: Buffer...');
 for j:=0 to 30 do begin
  writeln('LZW: ',j,'/',30);
  sz:=random(124)*random(14)+10;
  getmem(inb,sz+10);
  getmem(outb,2*sz);
  for i:=0 to sz+10-1 do inb[i]:=random(256);
  for i:=0 to sz+10-1 do outb[i]:=inb[i];
  getmem(codeb,2*sz);
  code_sz:=encodeLZW(inb,codeb,sz,2*sz); 
  //i:=
  decodeLZW(codeb,outb,code_sz,2*sz);
  //if i<>sz then writeln('Size didn''t match');
  for i:=0 to sz-1 do if inb[i]<>outb[i] then begin writeln('LZW: data didn''t match at ',i,' ',inb[i],' ',outb[i]);break;end;
  //for i:=sz to sz+10-1 do if inb[i]<>outb[i] then begin writeln('LZW: tail data didn''t match');break;end;
  freemem(inb);
  freemem(outb);
  freemem(codeb);
 end;
 
 writeln('LZW: Done.');
end;
{$endif}
//############################################################################//
begin
end.
//############################################################################//
