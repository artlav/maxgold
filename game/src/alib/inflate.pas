//############################################################################//
//Inflate algorithm
//Based on Puff by Mark Adler
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit inflate;
interface
uses asys;
//############################################################################//
function do_inflate(src,dst:pointer;var srclen,dstlen:dword;report:boolean=false):integer;
//############################################################################//
implementation
//############################################################################//
const
MAXBITS  =15;                  //maximum bits in a code
MAXLCODES=286;                 //maximum number of literal/length codes
MAXDCODES=30;                  //maximum number of distance codes
MAXCODES =MAXLCODES+MAXDCODES; //maximum codes lengths to read
FIXLCODES=288;                 //number of fixed literal/length codes
//############################################################################//
//Size base for length codes 257..285
lens:array[0..29-1]of smallint=(3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258);
//Extra bits for length codes 257..285
lext:array[0..29-1]of smallint=(0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0);
//Offset base for distance codes 0..29
dists:array[0..30-1]of smallint=(1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577);
//Extra bits for distance codes 0..29
dext:array[0..30-1]of smallint=(0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
//permutation of code length codes
order:array[0..19-1]of smallint=(16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);
//############################################################################//
type
inf_state=record
 outb,inb:pbytea;
 outlen,outcnt,inlen,incnt:dword;
 bitbuf,bitcnt:integer;
end;
pinf_state=^inf_state;
//############################################################################//
inf_huffman=record
 count:psmallinta;    //number of symbols of each length
 symbol:psmallinta;   //canonically ordered symbols
end;
pinf_huffman=^inf_huffman;    
//############################################################################//
var 
virgin:integer=1;
lencnt:array[0..MAXBITS]of smallint;
lensym:array[0..FIXLCODES-1]of smallint;
distcnt:array[0..MAXBITS]of smallint;
distsym:array[0..MAXDCODES-1]of smallint;
lencode,distcode:inf_huffman; 
//############################################################################//
//############################################################################//
function bits(s:pinf_state;need:integer):integer;
var val:integer;  //bit accumulator(can use up to 20 bits)
begin
 //load at least need bits into val
 val:=s.bitbuf;
 while s.bitcnt<need do begin
  //if s.incnt=s.inlen then longjmp(s.env,1);   //out of input
  if s.incnt=s.inlen then begin
   writeln('Error in bits');
   halt;   //out of input
  end;
  val:=val or(s.inb[s.incnt] shl s.bitcnt);  //load eight bits
  s.incnt:=s.incnt+1;
  s.bitcnt:=s.bitcnt+8;
 end;

 //drop need bits and update buffer,always zero to seven bits left
 s.bitbuf:=val shr need;
 s.bitcnt:=s.bitcnt-need;

 //return need bits,zeroing the bits above that
 result:=val and((1 shl need)-1);
end;
//############################################################################//
function stored(s:pinf_state):integer;
var len:dword;
i:integer;
begin
 //discard leftover bits from current byte(assumes s.bitcnt<8)
 s.bitbuf:=0;
 s.bitcnt:=0;

 //get length and check against its one's complement
 if s.incnt+4>s.inlen then begin result:=2;exit;end;
 len:=s.inb[s.incnt] or(s.inb[s.incnt+1] shl 8);
 s.incnt:=s.incnt+2;
                     
 //didn't match complement?
 s.incnt:=s.incnt+1;
 if s.inb[s.incnt-1]<>(not len and $ff) then begin result:=-2;exit;end;    
 s.incnt:=s.incnt+1;
 if s.inb[s.incnt-1]<>((not len shr 8)and $ff) then begin result:=-2;exit;end;

 //copy len bytes from in to out
 if s.incnt+len>s.inlen then begin result:=2;exit;end;
 if s.outb<>nil then begin
  if s.outcnt+len>s.outlen then begin result:=1;exit;end;
  for i:=0 to len-1 do s.outb[s.outcnt+dword(i)]:=s.inb[s.incnt+dword(i)];
  s.outcnt:=s.outcnt+len;
  s.incnt:=s.incnt+len;
 end else begin //just scanning
  s.outcnt:=s.outcnt+len;
  s.incnt:=s.incnt+len;
 end;
 //done with a valid stored block
 result:=0;
end;
//############################################################################//
function decode(s:pinf_state;h:pinf_huffman):integer;      
var len,code,first,count,index,bitbuf,left:integer;
next:psmallinta;
begin
 bitbuf:=s.bitbuf;
 left:=s.bitcnt;
 code:=0;
 first:=0;
 index:=0;
 len:=1;
 next:=@h.count[1];
 repeat
  repeat
   if left=0 then break;
   left:=left-1;
   code:=code or(bitbuf and 1);
   bitbuf:=bitbuf shr 1;
   count:=next[0];
   next:=@next[1];
   if code-count<first then begin //if length len, return symbol
    s.bitbuf:=bitbuf;
    s.bitcnt:=(s.bitcnt-len)and 7;
    result:=h.symbol[index+(code-first)];
    exit;
   end;
   index:=index+count;    //else update for next length
   first:=first+count;
   first:=first shl 1;
   code:=code shl 1;
   len:=len+1;
  until false;
  left:=MAXBITS+1-len;
  if left=0 then break;
  //if s.incnt=s.inlen then longjmp(s.env,1);   //out of input
  if s.incnt=s.inlen then begin
   writeln('Error in decode');
   halt;   //out of input
  end;
  bitbuf:=s.inb[s.incnt];
  s.incnt:=s.incnt+1;
  if left>8 then left:=8;
 until false;
 result:=-10;       //ran out of codes
end;
//############################################################################//
function construct(h:pinf_huffman;length:psmallinta;n:integer):integer;
var symbol,len,left:integer;
offs:array[0..MAXBITS]of smallint;   //offsets in symbol table for each length
begin
 //count number of codes of each length
 for len:=0 to MAXBITS do h.count[len]:=0;
 for symbol:=0 to n-1 do inc(h.count[length[symbol]]);   //assumes lengths are within bounds
 if h.count[0]=n then begin result:=0;exit;end;     //no codes! complete,but decode()will fail

 //check for an over-subscribed or incomplete set of lengths
 left:=1;         //one possible code of zero length
 for len:=1 to MAXBITS do begin
  left:=left shl 1;      //one more bit,double codes left
  left:=left-h.count[len];    //deduct count from possible codes
  if left<0 then begin result:=left;exit;end;   //over-subscribed--return negative
 end;           //left>0 means incomplete

 //generate offsets into symbol table for each length for sorting
 offs[1]:=0;
 for len:=1 to MAXBITS-1 do offs[len+1]:=offs[len]+h.count[len];

 for symbol:=0 to n-1 do if length[symbol]<>0 then begin 
  h.symbol[offs[length[symbol]]]:=symbol;
  inc(offs[length[symbol]]);
 end;

 //return zero for complete set,positive for incomplete set
 result:=left;
end;
//############################################################################//
function codes(s:pinf_state;lencode,distcode:pinf_huffman):integer;      
var symbol,len,i:integer;
dist:dword;
begin
 //decode literals and length/distance pairs
 repeat
  symbol:=decode(s,lencode);
  if symbol<0 then begin result:=symbol;exit;end;  //invalid symbol
  if symbol<256 then begin    //literal: symbol is the byte
   //write out the literal
   if s.outb<>nil then begin
    if s.outcnt=s.outlen then begin result:=1;exit;end;
    s.outb[s.outcnt]:=symbol;
   end;
   s.outcnt:=s.outcnt+1;
  end else if symbol>256 then begin  //length
   //get and compute length
   symbol:=symbol-257;
   if symbol>=29 then begin result:=-10;exit;end;    //invalid fixed code
   len:=lens[symbol]+bits(s,lext[symbol]);

   //get and check distance
   symbol:=decode(s,distcode);
   if symbol<0 then begin result:=symbol;exit;end;   //invalid symbol
   dist:=dists[symbol]+bits(s,dext[symbol]);

   //copy length bytes from distance bytes back
   if s.outb<>nil then begin
    if s.outcnt+dword(len)>s.outlen then begin result:=1;exit;end;
    for i:=0 to len-1 do begin
     if dist>s.outcnt then s.outb[s.outcnt]:=0 else s.outb[s.outcnt]:=s.outb[s.outcnt-dist];
     s.outcnt:=s.outcnt+1;
    end;
   end else s.outcnt:=s.outcnt+dword(len);
  end;
 until symbol=256;   //end of block symbol

 //done with a valid fixed or dynamic block
 result:=0;
end;    
//############################################################################//
function fixed(s:pinf_state):integer;  
var symbol:integer;
lengths:array[0..FIXLCODES-1]of smallint;
begin
 //build fixed huffman tables if first call(may not be thread safe)*/
 if virgin<>0 then begin  
  lencode.count:=@lencnt[0];
  lencode.symbol:=@lensym[0];
  distcode.count:=@distcnt[0];
  distcode.symbol:=@distsym[0];

  //literal/length table
  for symbol:=0 to 144-1 do lengths[symbol]:=8;
  for symbol:=144 to 256-1 do lengths[symbol]:=9;
  for symbol:=256 to 280-1 do lengths[symbol]:=7;
  for symbol:=280 to FIXLCODES-1 do lengths[symbol]:=8;
  construct(@lencode,@lengths[0],FIXLCODES);

  //distance table
  for symbol:=0 to MAXDCODES-1 do lengths[symbol]:=5;
  construct(@distcode,@lengths[0],MAXDCODES);

  //do this just once
  virgin:=0;
 end;

 //decode data until end-of-block code
 result:=codes(s,@lencode,@distcode);
end;    
//############################################################################//
function xdynamic(s:pinf_state):integer;
var nlen,ndist,ncode,index,err:integer;  
symbol,len,i:integer;
lengths:array[0..MAXCODES]of smallint;
lencnt:array[0..MAXBITS]of smallint;
lensym:array[0..MAXLCODES-1]of smallint;
distcnt:array[0..MAXBITS]of smallint;
distsym:array[0..MAXDCODES-1]of smallint;
lencode,distcode:inf_huffman;
begin
 //construct lencode and distcode
 lencode.count:=@lencnt[0];
 lencode.symbol:=@lensym[0];
 distcode.count:=@distcnt[0];
 distcode.symbol:=@distsym[0];

 //get number of lengths in each table,check lengths
 nlen:=bits(s,5)+257;
 ndist:=bits(s,5)+1;
 ncode:=bits(s,4)+4;
 if(nlen>MAXLCODES)or(ndist>MAXDCODES)then begin result:=-3;exit;end;       //bad counts

 //read code length code lengths(really),missing lengths are zero
 for index:=0 to ncode-1 do lengths[order[index]]:=bits(s,3);
 for index:=ncode to 19-1 do lengths[order[index]]:=0;

 //build huffman table for code lengths codes(use lencode temporarily)
 err:=construct(@lencode,@lengths[0],19);
 if err<>0 then begin result:=-4;exit;end;   //require complete code set here

 //read length/literal and distance code length tables
 index:=0;
 while index<nlen+ndist do begin
  symbol:=decode(s,@lencode);
  if symbol<16 then begin  //length in 0..15
   lengths[index]:=symbol;
   index:=index+1;
  end else begin        //repeat instruction
   len:=0;     //assume repeating zeros
   if symbol=16 then begin   //repeat last length 3..6 times
    if index=0 then begin result:=-5;exit;end;   //no last length!
    len:=lengths[index-1];    //last length
    symbol:=3+bits(s,2);
   end else if symbol=17 then symbol:=3+bits(s,3) else symbol:=11+bits(s,7);
   if index+symbol>nlen+ndist then begin result:=-6;exit;end;     //too many lengths!
   for i:=0 to symbol-1 do begin  //repeat last or zero symbol times
    lengths[index]:=len;
    index:=index+1;
   end;
   //symbol:=0;
  end;
 end;

 //check for end-of-block code -- there better be one!
 if lengths[256]=0 then begin result:=-9;exit;end;

 //build huffman table for literal/length codes
 err:=construct(@lencode,@lengths[0],nlen);
 if(err<0)or((err>0) and (nlen-lencode.count[0]<>1))then begin result:=-7;exit;end;   //only allow incomplete codes if just one code

 //build huffman table for distance codes
 err:=construct(@distcode,@lengths[nlen],ndist);
 if(err<0)or((err>0)and(ndist-distcode.count[0]<>1))then begin result:=-8;exit;end;   //only allow incomplete codes if just one code

 //decode data until end-of-block code
 result:=codes(s,@lencode,@distcode);
end;  
//############################################################################//
function do_inflate(src,dst:pointer;var srclen,dstlen:dword;report:boolean=false):integer;
var s:inf_state;
last,typ:integer;
begin
 result:=-20;
 if src=nil then exit;
 fillchar(s,sizeof(s),0);
 s.outb:=dst;      
 s.inb:=src;
 s.outlen:=dstlen;
 s.inlen:=srclen;

 //process blocks until last block or error
 repeat
  last:=bits(@s,1);   //one if last block
  typ:=bits(@s,2);    //block type 0..3
  case typ of
   0:result:=stored(@s);
   1:result:=fixed(@s);
   2:result:=xdynamic(@s);
   else result:=-1;
  end;
  if result<>0 then break;
 until last<>0;

 if (result<=0)or report then begin
  dstlen:=s.outcnt;
  srclen:=s.incnt;
 end;
end;
//############################################################################//
begin
end.
//############################################################################//

