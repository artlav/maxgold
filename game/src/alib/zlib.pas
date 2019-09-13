//############################################################################//
//Zlib stream formatting for inflate/deflate
//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit zlib;
interface    
uses asys,inflate,deflate,crc32;
//############################################################################//
//ZLIB format:
// CMF              1 byte
// FLG              1 byte
// <DICT>           if set
// compressed data  * bytes
// CRC32            4 bytes

// CMF (Compression Method and flags) This byte is divided into a 4-bit compression method and a 4-bit information field depending on the compression method.
//  bits 0 to 3  CM     Compression method
//  bits 4 to 7  CINFO  Compression info
// CM (Compression method)
//  This identifies the compression method used in the file.
//  CM = 8 denotes the "deflate" compression method with a window size up to 32K. This is the method used by gzip and PNG (see references [1] and [2] in Chapter 3, below, for the reference documents).
//  CM = 15 is reserved.  It might be used in a future version of this specification to indicate the presence of an extra field before the compressed data.
// CINFO (Compression info)
//  For CM = 8, CINFO is the base-2 logarithm of the LZ77 window size, minus eight (CINFO=7 indicates a 32K window size).
//  Values of CINFO above 7 are not allowed in this version of the specification.
//  CINFO is not defined in this specification for CM not equal to 8.

// FLG (flags) This flag byte is divided as follows:
//  bits 0 to 4  FCHECK  (check bits for CMF and FLG)
//  bit  5       FDICT   (preset dictionary)
//  bits 6 to 7  FLEVEL  (compression level)
//
// FCHECK value must be such that CMF and FLG, when viewed as a 16-bit unsigned integer stored in MSB order (CMF*256 + FLG), is a multiple of 31.
// FDICT (Preset dictionary)
//  If FDICT is set, a DICT dictionary identifier is present immediately after the FLG byte.
//  The dictionary is a sequence of bytes which are initially fed to the compressor without producing any compressed output.
//  DICT is the Adler-32 checksum of this sequence of bytes (see the definition of ADLER32 below).
//  The decompressor can use this identifier to determine which dictionary has been used by the compressor.
// FLEVEL (Compression level) These flags are available for use by specific compression methods.  The "deflate" method (CM = 8) sets these flags as follows:
//  0 - compressor used fastest algorithm
//  1 - compressor used fast algorithm
//  2 - compressor used default algorithm
//  3 - compressor used maximum compression, slowest algorithm
//  The information in FLEVEL is not needed for decompression; it is there to indicate if recompression might be worthwhile.
//ADLER32 (Adler-32 checksum)
// This contains a checksum value of the uncompressed data (excluding any dictionary data) computed according to Adler-32 algorithm.
// This algorithm is a 32-bit extension and improvement of the Fletcher algorithm, used in the ITU-T X.224 / ISO 8073 standard. See references [4] and [5] in Chapter 3, below)
// Adler-32 is composed of two sums accumulated per byte: s1 is the sum of all bytes, s2 is the sum of all s1 values. Both sums are done modulo 65521. s1 is initialized to 1, s2 to zero.
// The Adler-32 checksum is stored as s2*65536 + s1 in most-significant-byte first (network) order.
//############################################################################// 
function do_inflate_zlib(src,dst:pointer;const srclen:dword;var dstlen:dword):integer;
function do_deflate_zlib(src,dst:pointer;srcLen,dstLen:integer):integer;
//############################################################################//
implementation
//############################################################################//
function do_inflate_zlib(src,dst:pointer;const srclen:dword;var dstlen:dword):integer;
var sl:dword;
begin
 result:=-20;
 sl:=srclen-2-4;
 if (pbytea(src)[0] and $0F)<>$08 then exit;  //Non-default compression?
 if (pbytea(src)[1] and $20)<>0 then exit;    //Dictionary present?
 result:=do_inflate(@pbytea(src)[2],dst,sl,dstlen);
 //Check CRC
 if result=0 then if pdword(@pbytea(src)[srclen-4])^<>adler32_zlib(1,dst,dstlen) then result:=-10;
end;
//############################################################################//
function do_deflate_zlib(src,dst:pointer;srcLen,dstLen:integer):integer;
var d:array of byte;
begin
 setlength(d,dstlen);
 result:=do_deflate(src,@d[2],srcLen,dstLen-6);
 if result<>0 then begin
  d[0]:=$78;
  d[1]:=$01;
  pdword(@d[result+2])^:=adler32_zlib(1,src,srclen);
  move(d[0],dst^,result+6);
  result:=result+6;
 end;
end;
//############################################################################//
begin
end.   
//############################################################################//

