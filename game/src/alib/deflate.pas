//############################################################################//
//Deflate algorithm
//Based on PasZip
//############################################################################//  
{$ifdef fpc}{$mode delphi}{$endif}
{$Q-,R-}  //Turn range checking and overflow checking off        
//############################################################################//
unit deflate;
interface
uses asys;
//############################################################################//
function do_deflate(src,dst:pointer;srcLen,dstLen:integer;max_compress:boolean=false):integer;
//############################################################################//
implementation
//############################################################################//
const
CMemLevel=8;
CWindowBits=15;
//############################################################################//
const
//three kinds of block type
sTORED_BLOCK=0;
sTATIC_TREEs=1;
DYN_TREEs=2;

//minimum and maximum match lengths
MIN_MATCH=3;
MAX_MATCH=258;
//############################################################################//
length_CODEs=29;         //number of length codes,not counting the special end_BLOCK code
LITERALs=256;            //number of literal bytes 0..255
L_CODEs=(LITERALs+1+length_CODEs);
                           //number of literal or length codes,including the end_BLOCK code
D_CODEs=30;              //number of distance codes
BL_CODEs=19;             //number of codes used to transfer the bit lengths
HEAP_sIZE=(2*L_CODEs+1); //maximum heap size
MAX_BITs=15;             //all codes must not exceed MAX_BITs bits
//############################################################################//
type
PZstate=^TZstate;

//data structure describing a single value and its code string
//PTreeEntry=^TTreeEntry;
TTreeEntry=record
 fc:record
  case byte of
   0:(Frequency:word); //frequency count
   1:(Code:word); //bit string
 end;
 dl:record
  case byte of
   0:(dad:word);  //father node in Huffman tree
   1:(Len:word);  //length of bit string
 end;
end;
TLiteralTree=array[0..HEAP_sIZE-1]of TTreeEntry; //literal and length tree
TDistanceTree=array[0..2*D_CODEs]of TTreeEntry; //distance tree
THuffmanTree=array[0..2*BL_CODEs]of TTreeEntry; //Huffman tree for bit lengths
PTree=^TTree;
TTree=array[0..(MaxInt div sizeof(TTreeEntry))-1]of TTreeEntry; //generic tree type

PstaticTreeDescriptor=^TstaticTreeDescriptor;
TstaticTreeDescriptor=record
 staticTree:PTree;        //static tree or nil
 ExtraBits:pinta; //extra bits for each code or nil
 ExtraBase:integer;       //base index for ExtraBits
 Elements:integer;        //max number of elements in the tree
 Maxlength:integer;       //max bit length for the codes
end;

//PTreeDescriptor=^TTreeDescriptor;
TTreeDescriptor=record
 DynamicTree:PTree;
 MaxCode:integer;                        //largest code with non zero frequency
 staticDescriptor:PstaticTreeDescriptor; //the corresponding static tree
end;

PDeflatestate=^TDeflatestate;
TDeflatestate=record
 Zstate:PZstate;            //pointer back to this zlib stream
 PendingBuffer:pbytea;  //output still pending
 PendingBuffersize:integer;
 PendingOutput:Pbyte;       //next pending byte to output to the stream
 Pending:integer;           //nb of bytes in the pending buffer
 Windowsize:dword;       //LZ77 window size (32K by default)
 WindowBits:dword;       //log2(Windowsize) (8..16)
 WindowMask:dword;       //Windowsize-1

 //sliding window. Input bytes are read into the second half of the window,
 //and move to the first half later to keep a dictionary of at least Wsize
 //bytes. With this organization,matches are limited to a distance of
 //Wsize-MAX_MATCH bytes,but this ensures that IO is always
 //performed with a length multiple of the block size. Also,it limits
 //the window size to 64K,which is quite useful on MsDOs.
 //To do:use the user input buffer as sliding window.
 Window:pbytea;

 //Actual size of Window:2*Wsize,except when the user input buffer
 //is directly used as sliding window.
 CurrentWindowsize:integer;

 //Link to older string with same hash index. to limit the size of this
 //array to 64K,this link is maintained only for the last 32K strings.
 //An index in this array is thus a window index modulo 32K.
 Previous:pworda;
 Head:pworda;           //heads of the hash chains or nil
 InsertHash:dword;       //hash index of string to be inserted
 Hashsize:dword;         //number of elements in hash table
 HashBits:dword;         //log2(Hashsize)
 HashMask:dword;         //Hashsize-1

 //Number of bits by which InsertHash must be shifted at each input step.
 //It must be such that after MIN_MATCH steps,the oldest byte no longer
 //takes part in the hash key,that is:
 //Hashshift*MIN_MATCH>=HashBits
 Hashshift:dword;

 //Window position at the beginning of the current output block. Gets
 //negative when the window is moved backwards.
 Blockstart:integer;
 matchlength:dword;      //length of best match
 Previousmatch:dword;    //previous match
 matchAvailable:boolean;    //set if previous match exists
 stringstart:dword;      //start of string to insert
 matchstart:dword;       //start of matching string
 Lookahead:dword;        //number of valid bytes ahead in window

 //length of the best match at previous step. matches not greater than this
 //are discarded. This is used in the lazy match evaluation.
 Previouslength:dword;
 LiteralTree:TLiteralTree;  //literal and length tree
 DistanceTree:TDistanceTree; //distance tree
 BitlengthTree:THuffmanTree; //Huffman tree for bit lengths

 LiteralDescriptor:TTreeDescriptor; //Descriptor for literal tree
 DistanceDescriptor:TTreeDescriptor; //Descriptor for distance tree
 BitlengthDescriptor:TTreeDescriptor; //Descriptor for bit length tree

 BitlengthCounts:array[0..MAX_BITs]of word; //number of codes at each bit length for an optimal tree

 Heap:array[0..2*L_CODEs]of integer; //heap used to build the Huffman trees
 Heaplength:integer;        //number of elements in the heap
 HeapMaximum:integer;       //element of largest frequency
 //The sons of Heap[N] are Heap[2*N] and Heap[2*N+1]. Heap[0] is not used.
 //The same heap array is used to build all trees.

 Depth:array[0..2*L_CODEs]of byte; //depth of each subtree used as tie breaker for trees of equal frequency

 LiteralBuffer:pbytea;       //buffer for literals or lengths

 //size of match buffer for literals/lengths. There are 4 reasons for limiting LiteralBuffersize to 64K:
 //-frequencies can be kept in 16 bit counters
 //-if compression is not successful for the first block,all input
 //  data is still in the window so we can still emit a stored block even
 //  when input comes from standard input. This can also be done for
 //  all blocks if LiteralBuffersize is not greater than 32K.
 //-if compression is not successful for a file smaller than 64K,we can
 //  even emit a stored file instead of a stored block (saving 5 bytes).
 //  This is applicable only for zip (not gzip or zlib).
 //-creating new Huffman trees less frequently may not provide fast
 //  adaptation to changes in the input data statistics. (Take for
 //  example a binary file with poorly compressible code followed by
 //  a highly compressible string table.) smaller buffer sizes give
 //  fast adaptation but have of course the overhead of transmitting
 //  trees more frequently.
 //-I can't count above 4
 LiteralBuffersize:dword;
 LastLiteral:dword;      //running index in LiteralBuffer

 //Buffer for distances. To simplify the code,DistanceBuffer and LiteralBuffer have
 //the same number of elements. To use different lengths,an extra flag array would be necessary.
 DistanceBuffer:pworda;
 Optimallength:integer;     //bit length of current block with optimal trees
 staticlength:integer;      //bit length of current block with static trees
 Compressedlength:integer;  //total bit length of compressed file
 matches:dword;          //number of string matches in current block
 LastEOBlength:integer;     //bit length of EOB code for last block
 BitsBuffer:word;           //Output buffer. Bits are inserted starting at the bottom (least significant bits).
 ValidBits:integer;         //Number of valid bits in BitsBuffer. All Bits above the last valid bit are always zero.
end;
//############################################################################//
//The application must update NextInput and AvailableInput when AvailableInput has dropped to zero. It must update
//NextOutput and AvailableOutput when AvailableOutput has dropped to zero. All other fields are set by the
//compression library and must not be updated by the application.
//
//The fields TotalInput and TotalOutput can be used for statistics or progress reports. After compression,TotalInput
//holds the total size of the uncompressed data and may be saved for use in the decompressor
//(particularly if the decompressor wants to decompress everything in a single step).
TZstate=record
 NextInput:Pbyte;           //next input byte
 AvailableInput:dword;   //number of bytes available at NextInput
 TotalInput:dword;       //total number of input bytes read so far
 NextOutput:Pbyte;          //next output byte should be put there
 AvailableOutput:dword;  //remaining free space at NextOutput
 TotalOutput:dword;      //total number of bytes output so far
 state:PDeflatestate; //not visible by applications
end;
//############################################################################//
//Huffmann trees
const
DIsT_CODE_LEN=512; //see definition of array dist_code below

//The static literal tree. since the bit lengths are imposed,there is no need for the L_CODEs Extra codes used
//during heap construction. However the codes 286 and 287 are needed to build a canonical tree (see TreeInit below).
staticLiteralTree:array[0..L_CODEs+1]of TTreeEntry=(
 (fc:(Frequency: 12); dl:(Len:8)),(fc:(Frequency:140); dl:(Len:8)),(fc:(Frequency: 76); dl:(Len:8)),
 (fc:(Frequency:204); dl:(Len:8)),(fc:(Frequency: 44); dl:(Len:8)),(fc:(Frequency:172); dl:(Len:8)),
 (fc:(Frequency:108); dl:(Len:8)),(fc:(Frequency:236); dl:(Len:8)),(fc:(Frequency: 28); dl:(Len:8)),
 (fc:(Frequency:156); dl:(Len:8)),(fc:(Frequency: 92); dl:(Len:8)),(fc:(Frequency:220); dl:(Len:8)),
 (fc:(Frequency: 60); dl:(Len:8)),(fc:(Frequency:188); dl:(Len:8)),(fc:(Frequency:124); dl:(Len:8)),
 (fc:(Frequency:252); dl:(Len:8)),(fc:(Frequency:  2); dl:(Len:8)),(fc:(Frequency:130); dl:(Len:8)),
 (fc:(Frequency: 66); dl:(Len:8)),(fc:(Frequency:194); dl:(Len:8)),(fc:(Frequency: 34); dl:(Len:8)),
 (fc:(Frequency:162); dl:(Len:8)),(fc:(Frequency: 98); dl:(Len:8)),(fc:(Frequency:226); dl:(Len:8)),
 (fc:(Frequency: 18); dl:(Len:8)),(fc:(Frequency:146); dl:(Len:8)),(fc:(Frequency: 82); dl:(Len:8)),
 (fc:(Frequency:210); dl:(Len:8)),(fc:(Frequency: 50); dl:(Len:8)),(fc:(Frequency:178); dl:(Len:8)),
 (fc:(Frequency:114); dl:(Len:8)),(fc:(Frequency:242); dl:(Len:8)),(fc:(Frequency: 10); dl:(Len:8)),
 (fc:(Frequency:138); dl:(Len:8)),(fc:(Frequency: 74); dl:(Len:8)),(fc:(Frequency:202); dl:(Len:8)),
 (fc:(Frequency: 42); dl:(Len:8)),(fc:(Frequency:170); dl:(Len:8)),(fc:(Frequency:106); dl:(Len:8)),
 (fc:(Frequency:234); dl:(Len:8)),(fc:(Frequency: 26); dl:(Len:8)),(fc:(Frequency:154); dl:(Len:8)),
 (fc:(Frequency: 90); dl:(Len:8)),(fc:(Frequency:218); dl:(Len:8)),(fc:(Frequency: 58); dl:(Len:8)),
 (fc:(Frequency:186); dl:(Len:8)),(fc:(Frequency:122); dl:(Len:8)),(fc:(Frequency:250); dl:(Len:8)),
 (fc:(Frequency:  6); dl:(Len:8)),(fc:(Frequency:134); dl:(Len:8)),(fc:(Frequency: 70); dl:(Len:8)),
 (fc:(Frequency:198); dl:(Len:8)),(fc:(Frequency: 38); dl:(Len:8)),(fc:(Frequency:166); dl:(Len:8)),
 (fc:(Frequency:102); dl:(Len:8)),(fc:(Frequency:230); dl:(Len:8)),(fc:(Frequency: 22); dl:(Len:8)),
 (fc:(Frequency:150); dl:(Len:8)),(fc:(Frequency: 86); dl:(Len:8)),(fc:(Frequency:214); dl:(Len:8)),
 (fc:(Frequency: 54); dl:(Len:8)),(fc:(Frequency:182); dl:(Len:8)),(fc:(Frequency:118); dl:(Len:8)),
 (fc:(Frequency:246); dl:(Len:8)),(fc:(Frequency: 14); dl:(Len:8)),(fc:(Frequency:142); dl:(Len:8)),
 (fc:(Frequency: 78); dl:(Len:8)),(fc:(Frequency:206); dl:(Len:8)),(fc:(Frequency: 46); dl:(Len:8)),
 (fc:(Frequency:174); dl:(Len:8)),(fc:(Frequency:110); dl:(Len:8)),(fc:(Frequency:238); dl:(Len:8)),
 (fc:(Frequency: 30); dl:(Len:8)),(fc:(Frequency:158); dl:(Len:8)),(fc:(Frequency: 94); dl:(Len:8)),
 (fc:(Frequency:222); dl:(Len:8)),(fc:(Frequency: 62); dl:(Len:8)),(fc:(Frequency:190); dl:(Len:8)),
 (fc:(Frequency:126); dl:(Len:8)),(fc:(Frequency:254); dl:(Len:8)),(fc:(Frequency:  1); dl:(Len:8)),
 (fc:(Frequency:129); dl:(Len:8)),(fc:(Frequency: 65); dl:(Len:8)),(fc:(Frequency:193); dl:(Len:8)),
 (fc:(Frequency: 33); dl:(Len:8)),(fc:(Frequency:161); dl:(Len:8)),(fc:(Frequency: 97); dl:(Len:8)),
 (fc:(Frequency:225); dl:(Len:8)),(fc:(Frequency: 17); dl:(Len:8)),(fc:(Frequency:145); dl:(Len:8)),
 (fc:(Frequency: 81); dl:(Len:8)),(fc:(Frequency:209); dl:(Len:8)),(fc:(Frequency: 49); dl:(Len:8)),
 (fc:(Frequency:177); dl:(Len:8)),(fc:(Frequency:113); dl:(Len:8)),(fc:(Frequency:241); dl:(Len:8)),
 (fc:(Frequency:  9); dl:(Len:8)),(fc:(Frequency:137); dl:(Len:8)),(fc:(Frequency: 73); dl:(Len:8)),
 (fc:(Frequency:201); dl:(Len:8)),(fc:(Frequency: 41); dl:(Len:8)),(fc:(Frequency:169); dl:(Len:8)),
 (fc:(Frequency:105); dl:(Len:8)),(fc:(Frequency:233); dl:(Len:8)),(fc:(Frequency: 25); dl:(Len:8)),
 (fc:(Frequency:153); dl:(Len:8)),(fc:(Frequency: 89); dl:(Len:8)),(fc:(Frequency:217); dl:(Len:8)),
 (fc:(Frequency: 57); dl:(Len:8)),(fc:(Frequency:185); dl:(Len:8)),(fc:(Frequency:121); dl:(Len:8)),
 (fc:(Frequency:249); dl:(Len:8)),(fc:(Frequency:  5); dl:(Len:8)),(fc:(Frequency:133); dl:(Len:8)),
 (fc:(Frequency: 69); dl:(Len:8)),(fc:(Frequency:197); dl:(Len:8)),(fc:(Frequency: 37); dl:(Len:8)),
 (fc:(Frequency:165); dl:(Len:8)),(fc:(Frequency:101); dl:(Len:8)),(fc:(Frequency:229); dl:(Len:8)),
 (fc:(Frequency: 21); dl:(Len:8)),(fc:(Frequency:149); dl:(Len:8)),(fc:(Frequency: 85); dl:(Len:8)),
 (fc:(Frequency:213); dl:(Len:8)),(fc:(Frequency: 53); dl:(Len:8)),(fc:(Frequency:181); dl:(Len:8)),
 (fc:(Frequency:117); dl:(Len:8)),(fc:(Frequency:245); dl:(Len:8)),(fc:(Frequency: 13); dl:(Len:8)),
 (fc:(Frequency:141); dl:(Len:8)),(fc:(Frequency: 77); dl:(Len:8)),(fc:(Frequency:205); dl:(Len:8)),
 (fc:(Frequency: 45); dl:(Len:8)),(fc:(Frequency:173); dl:(Len:8)),(fc:(Frequency:109); dl:(Len:8)),
 (fc:(Frequency:237); dl:(Len:8)),(fc:(Frequency: 29); dl:(Len:8)),(fc:(Frequency:157); dl:(Len:8)),
 (fc:(Frequency: 93); dl:(Len:8)),(fc:(Frequency:221); dl:(Len:8)),(fc:(Frequency: 61); dl:(Len:8)),
 (fc:(Frequency:189); dl:(Len:8)),(fc:(Frequency:125); dl:(Len:8)),(fc:(Frequency:253); dl:(Len:8)),
 (fc:(Frequency: 19); dl:(Len:9)),(fc:(Frequency:275); dl:(Len:9)),(fc:(Frequency:147); dl:(Len:9)),
 (fc:(Frequency:403); dl:(Len:9)),(fc:(Frequency: 83); dl:(Len:9)),(fc:(Frequency:339); dl:(Len:9)),
 (fc:(Frequency:211); dl:(Len:9)),(fc:(Frequency:467); dl:(Len:9)),(fc:(Frequency: 51); dl:(Len:9)),
 (fc:(Frequency:307); dl:(Len:9)),(fc:(Frequency:179); dl:(Len:9)),(fc:(Frequency:435); dl:(Len:9)),
 (fc:(Frequency:115); dl:(Len:9)),(fc:(Frequency:371); dl:(Len:9)),(fc:(Frequency:243); dl:(Len:9)),
 (fc:(Frequency:499); dl:(Len:9)),(fc:(Frequency: 11); dl:(Len:9)),(fc:(Frequency:267); dl:(Len:9)),
 (fc:(Frequency:139); dl:(Len:9)),(fc:(Frequency:395); dl:(Len:9)),(fc:(Frequency: 75); dl:(Len:9)),
 (fc:(Frequency:331); dl:(Len:9)),(fc:(Frequency:203); dl:(Len:9)),(fc:(Frequency:459); dl:(Len:9)),
 (fc:(Frequency: 43); dl:(Len:9)),(fc:(Frequency:299); dl:(Len:9)),(fc:(Frequency:171); dl:(Len:9)),
 (fc:(Frequency:427); dl:(Len:9)),(fc:(Frequency:107); dl:(Len:9)),(fc:(Frequency:363); dl:(Len:9)),
 (fc:(Frequency:235); dl:(Len:9)),(fc:(Frequency:491); dl:(Len:9)),(fc:(Frequency: 27); dl:(Len:9)),
 (fc:(Frequency:283); dl:(Len:9)),(fc:(Frequency:155); dl:(Len:9)),(fc:(Frequency:411); dl:(Len:9)),
 (fc:(Frequency: 91); dl:(Len:9)),(fc:(Frequency:347); dl:(Len:9)),(fc:(Frequency:219); dl:(Len:9)),
 (fc:(Frequency:475); dl:(Len:9)),(fc:(Frequency: 59); dl:(Len:9)),(fc:(Frequency:315); dl:(Len:9)),
 (fc:(Frequency:187); dl:(Len:9)),(fc:(Frequency:443); dl:(Len:9)),(fc:(Frequency:123); dl:(Len:9)),
 (fc:(Frequency:379); dl:(Len:9)),(fc:(Frequency:251); dl:(Len:9)),(fc:(Frequency:507); dl:(Len:9)),
 (fc:(Frequency:  7); dl:(Len:9)),(fc:(Frequency:263); dl:(Len:9)),(fc:(Frequency:135); dl:(Len:9)),
 (fc:(Frequency:391); dl:(Len:9)),(fc:(Frequency: 71); dl:(Len:9)),(fc:(Frequency:327); dl:(Len:9)),
 (fc:(Frequency:199); dl:(Len:9)),(fc:(Frequency:455); dl:(Len:9)),(fc:(Frequency: 39); dl:(Len:9)),
 (fc:(Frequency:295); dl:(Len:9)),(fc:(Frequency:167); dl:(Len:9)),(fc:(Frequency:423); dl:(Len:9)),
 (fc:(Frequency:103); dl:(Len:9)),(fc:(Frequency:359); dl:(Len:9)),(fc:(Frequency:231); dl:(Len:9)),
 (fc:(Frequency:487); dl:(Len:9)),(fc:(Frequency: 23); dl:(Len:9)),(fc:(Frequency:279); dl:(Len:9)),
 (fc:(Frequency:151); dl:(Len:9)),(fc:(Frequency:407); dl:(Len:9)),(fc:(Frequency: 87); dl:(Len:9)),
 (fc:(Frequency:343); dl:(Len:9)),(fc:(Frequency:215); dl:(Len:9)),(fc:(Frequency:471); dl:(Len:9)),
 (fc:(Frequency: 55); dl:(Len:9)),(fc:(Frequency:311); dl:(Len:9)),(fc:(Frequency:183); dl:(Len:9)),
 (fc:(Frequency:439); dl:(Len:9)),(fc:(Frequency:119); dl:(Len:9)),(fc:(Frequency:375); dl:(Len:9)),
 (fc:(Frequency:247); dl:(Len:9)),(fc:(Frequency:503); dl:(Len:9)),(fc:(Frequency: 15); dl:(Len:9)),
 (fc:(Frequency:271); dl:(Len:9)),(fc:(Frequency:143); dl:(Len:9)),(fc:(Frequency:399); dl:(Len:9)),
 (fc:(Frequency: 79); dl:(Len:9)),(fc:(Frequency:335); dl:(Len:9)),(fc:(Frequency:207); dl:(Len:9)),
 (fc:(Frequency:463); dl:(Len:9)),(fc:(Frequency: 47); dl:(Len:9)),(fc:(Frequency:303); dl:(Len:9)),
 (fc:(Frequency:175); dl:(Len:9)),(fc:(Frequency:431); dl:(Len:9)),(fc:(Frequency:111); dl:(Len:9)),
 (fc:(Frequency:367); dl:(Len:9)),(fc:(Frequency:239); dl:(Len:9)),(fc:(Frequency:495); dl:(Len:9)),
 (fc:(Frequency: 31); dl:(Len:9)),(fc:(Frequency:287); dl:(Len:9)),(fc:(Frequency:159); dl:(Len:9)),
 (fc:(Frequency:415); dl:(Len:9)),(fc:(Frequency: 95); dl:(Len:9)),(fc:(Frequency:351); dl:(Len:9)),
 (fc:(Frequency:223); dl:(Len:9)),(fc:(Frequency:479); dl:(Len:9)),(fc:(Frequency: 63); dl:(Len:9)),
 (fc:(Frequency:319); dl:(Len:9)),(fc:(Frequency:191); dl:(Len:9)),(fc:(Frequency:447); dl:(Len:9)),
 (fc:(Frequency:127); dl:(Len:9)),(fc:(Frequency:383); dl:(Len:9)),(fc:(Frequency:255); dl:(Len:9)),
 (fc:(Frequency:511); dl:(Len:9)),(fc:(Frequency:  0); dl:(Len:7)),(fc:(Frequency: 64); dl:(Len:7)),
 (fc:(Frequency: 32); dl:(Len:7)),(fc:(Frequency: 96); dl:(Len:7)),(fc:(Frequency: 16); dl:(Len:7)),
 (fc:(Frequency: 80); dl:(Len:7)),(fc:(Frequency: 48); dl:(Len:7)),(fc:(Frequency:112); dl:(Len:7)),
 (fc:(Frequency:  8); dl:(Len:7)),(fc:(Frequency: 72); dl:(Len:7)),(fc:(Frequency: 40); dl:(Len:7)),
 (fc:(Frequency:104); dl:(Len:7)),(fc:(Frequency: 24); dl:(Len:7)),(fc:(Frequency: 88); dl:(Len:7)),
 (fc:(Frequency: 56); dl:(Len:7)),(fc:(Frequency:120); dl:(Len:7)),(fc:(Frequency:  4); dl:(Len:7)),
 (fc:(Frequency: 68); dl:(Len:7)),(fc:(Frequency: 36); dl:(Len:7)),(fc:(Frequency:100); dl:(Len:7)),
 (fc:(Frequency: 20); dl:(Len:7)),(fc:(Frequency: 84); dl:(Len:7)),(fc:(Frequency: 52); dl:(Len:7)),
 (fc:(Frequency:116); dl:(Len:7)),(fc:(Frequency:  3); dl:(Len:8)),(fc:(Frequency:131); dl:(Len:8)),
 (fc:(Frequency: 67); dl:(Len:8)),(fc:(Frequency:195); dl:(Len:8)),(fc:(Frequency: 35); dl:(Len:8)),
 (fc:(Frequency:163); dl:(Len:8)),(fc:(Frequency: 99); dl:(Len:8)),(fc:(Frequency:227); dl:(Len:8))
);

//The static distance tree. (Actually a trivial tree since all lens use 5 Bits.)
staticDescriptorTree:array[0..D_CODEs-1]of TTreeEntry=(
 (fc:(Frequency: 0); dl:(Len:5)),(fc:(Frequency:16); dl:(Len:5)),(fc:(Frequency: 8); dl:(Len:5)),
 (fc:(Frequency:24); dl:(Len:5)),(fc:(Frequency: 4); dl:(Len:5)),(fc:(Frequency:20); dl:(Len:5)),
 (fc:(Frequency:12); dl:(Len:5)),(fc:(Frequency:28); dl:(Len:5)),(fc:(Frequency: 2); dl:(Len:5)),
 (fc:(Frequency:18); dl:(Len:5)),(fc:(Frequency:10); dl:(Len:5)),(fc:(Frequency:26); dl:(Len:5)),
 (fc:(Frequency: 6); dl:(Len:5)),(fc:(Frequency:22); dl:(Len:5)),(fc:(Frequency:14); dl:(Len:5)),
 (fc:(Frequency:30); dl:(Len:5)),(fc:(Frequency: 1); dl:(Len:5)),(fc:(Frequency:17); dl:(Len:5)),
 (fc:(Frequency: 9); dl:(Len:5)),(fc:(Frequency:25); dl:(Len:5)),(fc:(Frequency: 5); dl:(Len:5)),
 (fc:(Frequency:21); dl:(Len:5)),(fc:(Frequency:13); dl:(Len:5)),(fc:(Frequency:29); dl:(Len:5)),
 (fc:(Frequency: 3); dl:(Len:5)),(fc:(Frequency:19); dl:(Len:5)),(fc:(Frequency:11); dl:(Len:5)),
 (fc:(Frequency:27); dl:(Len:5)),(fc:(Frequency: 7); dl:(Len:5)),(fc:(Frequency:23); dl:(Len:5))
);

//Distance codes. The first 256 values correspond to the distances 3 .. 258,the last 256 values correspond to the
//top 8 Bits of the 15 bit distances.
DistanceCode:array[0..DIsT_CODE_LEN-1]of byte=(
  0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8,
  8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9,10,10,10,10,10,10,10,10,
 10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,
 11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,
 12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,
 13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,
 13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,14,
 14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,
 14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,
 14,14,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,
 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,
 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,
 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15, 0, 0,16,17,
 18,18,19,19,20,20,20,20,21,21,21,21,22,22,22,22,22,22,22,22,
 23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,24,24,24,
 24,24,24,24,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,
 26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,
 26,26,26,26,26,26,26,26,26,26,26,26,27,27,27,27,27,27,27,27,
 27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,
 27,27,27,27,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,
 28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,
 28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,
 28,28,28,28,28,28,28,28,29,29,29,29,29,29,29,29,29,29,29,29,
 29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,
 29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,
 29,29,29,29,29,29,29,29,29,29,29,29
);

//length code for each normalized match length (0=MIN_MATCH)
lengthCode:array[0..MAX_MATCH-MIN_MATCH]of byte=(
  0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9,10,10,11,11,12,12,12,12,
 13,13,13,13,14,14,14,14,15,15,15,15,16,16,16,16,16,16,16,16,
 17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,19,19,19,19,
 19,19,19,19,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,
 21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,22,22,22,22,
 22,22,22,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,
 23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,24,24,24,
 24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,
 25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,
 25,25,25,25,25,25,25,25,25,25,25,25,26,26,26,26,26,26,26,26,
 26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,
 26,26,26,26,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,
 27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,28
);

//first normalized length for each code (0=MIN_MATCH)
Baselength:array[0..length_CODEs-1]of byte=(
 0,1,2,3,4,5,6,7,8,10,12,14,16,20,24,28,32,40,48,56,
 64,80,96,112,128,160,192,224,0
);

//first normalized distance for each code (0=distance of 1)
BaseDistance:array[0..D_CODEs-1]of integer=(
    0,    1,    2,    3,    4,    6,    8,   12,   16,   24,
   32,   48,   64,   96,  128,  192,  256,  384,  512,  768,
 1024, 1536, 2048, 3072, 4096, 6144, 8192,12288,16384,24576
);

MIN_LOOKAHEAD=(MAX_MATCH+MIN_MATCH+1);
MAX_BL_BITs=7;  //bit length codes must not exceed MAX_BL_BITs bits
end_BLOCK=256;  //end of block literal code
REP_3_6=16;     //repeat previous bit length 3-6 times (2 Bits of repeat count)
REPZ_3_10=17;   //repeat a zero length 3-10 times  (3 Bits of repeat count)
REPZ_11_138=18; //repeat a zero length 11-138 times  (7 Bits of repeat count)

//extra bits for each length code
ExtralengthBits:array[0..length_CODEs-1]of integer=(
 0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0
);

//extra bits for each distance code
ExtraDistanceBits:array[0..D_CODEs-1]of integer=(
 0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10 ,10,11,11,12,12,13,13
);

//extra bits for each bit length code
ExtraBitlengthBits:array[0..BL_CODEs-1]of integer=(
 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,3,7
);

//The lengths of the bit length codes are sent in order of decreasing probability,
//to avoid transmitting the lengths for unused bit length codes.
BitlengthOrder:array[0..BL_CODEs-1]of byte=(
 16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15
);

//Number of bits used within BitsBuffer. (BitsBuffer might be implemented on more than 16 bits on some systems.)
Buffersize=16;

staticLiteralDescriptor:TstaticTreeDescriptor=(
 staticTree:@staticLiteralTree;  //pointer to array of TTreeEntry
 ExtraBits:@ExtralengthBits;     //pointer to array of integer
 ExtraBase:LITERALs+1;
 Elements:L_CODEs;
 Maxlength:MAX_BITs
);

staticDistanceDescriptor:TstaticTreeDescriptor=(
 staticTree:@staticDescriptorTree;
 ExtraBits:@ExtraDistanceBits;
 ExtraBase:0;
 Elements:D_CODEs;
 Maxlength:MAX_BITs
);

staticBitlengthDescriptor:TstaticTreeDescriptor=(
 staticTree:nil;
 ExtraBits:@ExtraBitlengthBits;
 ExtraBase:0;
 Elements:BL_CODEs;
 Maxlength:MAX_BL_BITs
);
//############################################################################//
//faster routine by AB
function scan_fast(scan,match,str_end:pbyte):integer;
begin
 inc(scan,2);
 inc(match);
 //We check for insufficient lookahead only every 8th comparison, the 256th check will be made at stringstart+258.
 repeat
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
  inc(scan);inc(match);if (scan^<>match^) then break;
 until intptr(scan)>=intptr(str_end);
 result:=MAX_MATCH-integer(intptr(str_end)-intptr(scan));
end;
//############################################################################//   
//sets matchstart to the longest match starting at the given string and returns its length. matches shorter or equal to
//Previouslength are discarded,in which case the result is equal to Previouslength and matchstart is garbage.
//Currentmatch is the head of the hash chain for the current string (stringstart) and its distance is <= MaxDistance,
//and Previouslength>=1.
//The match length will not be greater than s.Lookahead.
function Longestmatch(var s:TDeflatestate; Currentmatch:dword):dword;
const CGoodLen=4;
CNiceLen=16;
CMaxChain=8;
var Chainlength:dword; //max hash chain length
scan:Pbyte;           //current string
match:Pbyte;          //matched string
Len:dword;         //length of current match
BestLen:dword;     //best match length so far
Nicematch:dword;
Limit:dword;
Previous:pworda;
WMask:dword;
strend:Pbyte;
scanend1:byte;
scanend:byte;
MaxDistance:dword;
begin
 Chainlength:=CMaxChain;
 scan:=@s.Window[s.stringstart];
 BestLen:=s.Previouslength;
 Nicematch:=CNiceLen;
 MaxDistance:=s.Windowsize-MIN_LOOKAHEAD;

 //In order to simplify the code,match distances are limited to MaxDistance instead of Wsize.
 if s.stringstart>MaxDistance then Limit:=s.stringstart-MaxDistance
                              else Limit:=0;

 //stop when Currentmatch becomes <= Limit. To simplify the Code we prevent matches with the string of window index 0.
 Previous:=s.Previous;
 WMask:=s.WindowMask;

 strend:=@s.Window[s.stringstart+MAX_MATCH];
 scanend1:=pbytea(scan)[BestLen-1];
 scanend:=pbytea(scan)[BestLen];

 //The code is optimized for HashBits>=8 and MAX_MATCH-2 multiple of 16.
 //It is easy to get rid of this optimization if necessary.
 //Do not waste too much time if we already have a good match.
 if s.Previouslength>=CGoodLen then Chainlength:=Chainlength shr 2;

 //Do not look for matches beyond the end of the input. This is necessary to make Deflate deterministic.
 if Nicematch>s.Lookahead then Nicematch:=s.Lookahead;

 repeat
  match:=@s.Window[Currentmatch];
  //skip to next match if the match length cannot increase or if the match length is less than 2.
  if (pbytea(match)[BestLen]=scanend) and (pbytea(match)[BestLen-1]=scanend1)and(match^=scan^) then begin
   inc(match);
   if match^=pbytea(scan)[1] then begin
    //The Check at BestLen-1 can be removed because it will be made again later (this heuristic is not always a win).
    //It is not necessary to compare scan[2] and match[2] since they are always equal when the other bytes match,
    //given that the hash keys are equal and that HashBits>=8.
    Len:=scan_fast(scan,match,strend); //faster routine by AB
    scan:=strend;
    dec(scan,MAX_MATCH);
    if Len>BestLen then begin
     s.matchstart:=Currentmatch;
     BestLen:=Len;
     if Len>=Nicematch then break;
     scanend1:=pbytea(scan)[BestLen-1];
     scanend:=pbytea(scan)[BestLen];
    end;
   end;
  end;
  Currentmatch:=Previous[Currentmatch and WMask];
  dec(Chainlength);
 until (Currentmatch <= Limit) or (Chainlength=0);

 if BestLen<=s.Lookahead then result:=BestLen
                         else result:=s.Lookahead;
end;
//############################################################################//   
//Reads a new buffer from the current input stream,updates the Adler32 and total number of bytes read.  All Deflate
//input goes through this function so some applications may wish to modify it to avoid allocating a large
//Zstate.NextInput buffer and copying from it (see also FlushPending).
function ReadBuffer(Zstate:PZstate; Buffer:Pbyte; size:dword):integer;
var len:dword;
begin
 Len:=Zstate.AvailableInput;
 if Len>size then Len:=size;
 if Len=0 then begin result:=0;exit;end;
 dec(Zstate.AvailableInput,Len);
 move(Zstate.NextInput^,Buffer^,Len);
 inc(Zstate.NextInput,Len);
 inc(Zstate.TotalInput,Len);
 result:=Len;
end;
//############################################################################//    
//Fills the window when the lookahead becomes insufficient,updates stringstart and Lookahead.
//Lookahead must be less than MIN_LOOKAHEAD.
//stringstart will be <= CurrentWindowsize-MIN_LOOKAHEAD on exit.
//On exit at least one byte has been read,or AvailableInput=0. Reads are performed for at least two bytes (required
//for the zip translate_eol option-> not supported here).
procedure FillWindow(var s:TDeflatestate);
var N,M:dword;
P:pword;
More:dword; //amount of free space at the end of the window
begin
 repeat
  More:=s.CurrentWindowsize-integer(s.Lookahead)-integer(s.stringstart);
  if (More=0)and(s.stringstart=0)and(s.Lookahead=0) then begin
   More:=s.Windowsize
  end else if More=dword(-1) then begin
   //Very unlikely,but sometimes possible if stringstart=0 and Lookahead=1 (input done one byte at time)
   dec(More);
   //if the Window is almost full and there is insufficient lookahead,
   //move the upper half to the lower one to make room in the upper half.
  end else if s.stringstart>=s.Windowsize+(s.Windowsize-MIN_LOOKAHEAD) then begin
   move(s.Window[s.Windowsize],s.Window^,s.Windowsize);
   dec(s.matchstart,s.Windowsize);
   dec(s.stringstart,s.Windowsize);
   //we now have stringstart>=MaxDistance
   dec(s.Blockstart,integer(s.Windowsize));

   //slide the hash table (could be avoided with 32 bit values at the expense of memory usage). We slide even when
   //Level=0 to keep the hash table consistent if we switch back to Level>0 later. (Using Level 0 permanently
   //is not an optimal usage of zlib,so we don't care about this pathological case.)
   P:=@s.Head[s.Hashsize];
   for N:=1 to s.Hashsize do begin
    dec(P);
    M:=P^;
    if M>=s.Windowsize then P^:=M-s.Windowsize
                       else P^:=0;
   end;
   P:=@s.Previous[s.Windowsize];
   for N:=1 to s.Windowsize do begin
    dec(P);
    M:=P^;
    if M>=s.Windowsize then P^:=M-s.Windowsize
                       else P^:=0;
    //if N is not on any hash chain Previous[N] is garbage but its value will never be used
   end;
   inc(More,s.Windowsize);
  end;

  if s.Zstate.AvailableInput=0 then exit;

  //if there was no sliding:
  //  stringstart <= s.Windowsize+MaxDistance-1 and Lookahead <= MIN_LOOKAHEAD-1 and
  //  More=CurrentWindowsize-Lookahead-stringstart
  //=> More>=CurrentWindowsize-(MIN_LOOKAHEAD-1+s.Windowsize+MaxDistance-1)
  //=> More>=CurrentWindowsize-2*s.Windowsize+2
  //In the BIG_MEM or MMAP case (not yet supported),
  //  CurrentWindowsize=input_size+MIN_LOOKAHEAD  and
  //  stringstart+s.Lookahead <= input_size => More>=MIN_LOOKAHEAD.
  //Otherwise,CurrentWindowsize=2*s.Windowsize so More>=2.
  //if there was sliding More>=s.Windowsize. so in all cases More>=2.
  N:=ReadBuffer(s.Zstate,@s.Window[s.stringstart+s.Lookahead],More);
  inc(s.Lookahead,N);

  //Initialize the hash Value now that we have some input:
  if s.Lookahead>=MIN_MATCH then begin
   s.InsertHash:=s.Window[s.stringstart];
   s.InsertHash:=((s.InsertHash shl s.Hashshift) xor s.Window[s.stringstart+1]) and s.HashMask;
  end;
  //if the whole input has less than MIN_MATCH bytes,InsertHash is garbage,
  //but this is not important since only literal bytes will be emitted.
 until (s.Lookahead>=MIN_LOOKAHEAD) or (s.Zstate.AvailableInput=0);
end;
//############################################################################//    
procedure InitializeBlock(var s:TDeflatestate);
var n:integer;
begin
 //initialize the trees
 for N:=0 to L_CODEs-1 do s.LiteralTree[N].fc.Frequency:=0;
 for N:=0 to D_CODEs-1 do s.DistanceTree[N].fc.Frequency:=0;
 for N:=0 to BL_CODEs-1 do s.BitlengthTree[N].fc.Frequency:=0;
 s.LiteralTree[end_BLOCK].fc.Frequency:=1;
 s.staticlength:=0;
 s.Optimallength:=0;
 s.matches:=0;
 s.LastLiteral:=0;
end;
//############################################################################//     
//Flushs as much pending output as possible. All Deflate output goes through this function so some applications may
//wish to modify it to avoid allocating a large Zstate.NextOutput buffer and copying into it
//(see also ReadBuffer).
procedure FlushPending(var Zstate:TZstate);
var len:dword;
s:PDeflatestate;
begin
 s:=PDeflatestate(Zstate.state);
 Len:=s.Pending;

 if Len>Zstate.AvailableOutput then Len:=Zstate.AvailableOutput;
 if Len>0 then begin
  move(s.PendingOutput^,Zstate.NextOutput^,Len);
  inc(Zstate.NextOutput,Len);
  inc(s.PendingOutput,Len);
  inc(Zstate.TotalOutput,Len);
  dec(Zstate.AvailableOutput,Len);
  dec(s.Pending,Len);
  if s.Pending=0 then s.PendingOutput:=Pbyte(s.PendingBuffer);
 end;
end;
//############################################################################//    
//Reverses the first Len bits of Code,using straightforward code (a faster imMethod would use a table)
function BitReverse(Code:word; Len:integer):word;
begin
 result:=0;
 repeat
  result:=result or (Code and 1);
  Code:=Code shr 1;
  result:=result shl 1;
  dec(Len);
 until Len <= 0;
 result:=result shr 1;
end;
//############################################################################//
//Generates the codes for a given tree and bit counts (which need not be optimal).
//The array BitlengthCounts contains the bit length statistics for the given tree and the field Len is set for all
//Tree elements. MaxCode is the largest code with non zero frequency and BitlengthCounts are the number of codes at each bit length.
//On exit the field code is set for all tree elements of non zero code length.
procedure GenerateCodes(Tree:PTree; MaxCode:integer;const BitlengthCounts:array of word);
var NextCode:array[0..MAX_BITs]of word; //next code value for each bit length
Code:word;      //running code value
Bits:integer;   //bit Index
N:integer;      //code Index
Len:integer;
begin
 Code:=0;
 //The distribution counts are first used to generate the code values without bit reversal.
 for Bits:=1 to MAX_BITs do begin
  Code:=(Code+BitlengthCounts[Bits-1]) shl 1;
  NextCode[Bits]:=Code;
 end;
 //Check that the bit counts in BitlengthCounts are consistent. The last code must be all ones.
 for N:=0 to MaxCode do begin
  Len:=Tree[N].dl.Len;
  if Len=0 then continue;
  Tree[N].fc.Code:=BitReverse(NextCode[Len],Len);
  inc(NextCode[Len]);
 end;
end;
//############################################################################//   
//Restores the heap property by moving down tree starting at node K,
//exchanging a Node with the smallest of its two sons if necessary,stopping
//when the heap property is re-established (each father smaller than its two sons).
procedure RestoreHeap(var s:TDeflatestate; const Tree:TTree; K:integer);
var V,J:integer;
begin
 V:=s.Heap[K];
 J:=K shl 1;  //left son of K
 while J <= s.Heaplength do begin
  //set J to the smallest of the two sons:
  if
   (J<s.Heaplength) and
   ((Tree[s.Heap[J+1]].fc.Frequency<Tree[s.Heap[J]].fc.Frequency) or
   ((Tree[s.Heap[J+1]].fc.Frequency=Tree[s.Heap[J]].fc.Frequency) and
   (s.Depth[s.Heap[J+1]] <= s.Depth[s.Heap[J]])))
  then inc(J);

  //exit if V is smaller than both sons
  if
   ((Tree[V].fc.Frequency<Tree[s.Heap[J]].fc.Frequency) or
   ((Tree[V].fc.Frequency=Tree[s.Heap[J]].fc.Frequency) and
   (s.Depth[V] <= s.Depth[s.Heap[J]])))
  then break;

  //exchange V with the smallest son
  s.Heap[K]:=s.Heap[J];
  K:=J;

  //and xontinue down the tree,setting J to the left son of K
  J:=J shl 1;
 end;
 s.Heap[K]:=V;
end;
//############################################################################//  
//Computes the optimal bit lengths for a tree and update the total bit length for the current block.
//The fields Frequency and dad are set,Heap[HeapMaximum] and above are the tree nodes sorted by increasing frequency.
//result:The field Len is set to the optimal bit length,the array BitlengthCounts contains the frequencies for each
//bit length. The length Optimallength is updated. staticlength is also updated if sTree is not nil.
procedure GenerateBitlengths(var s:TDeflatestate; var Descriptor:TTreeDescriptor);
var Tree:PTree;
MaxCode:integer;
sTree:PTree;
Extra:pinta;
Base:integer;
Maxlength:integer;
H:integer;          //heap Index
N,M:integer;       //iterate over the tree elements
Bits:word;          //bit length
ExtraBits:integer;
F:word;             //frequency
Overflow:integer;   //number of elements with bit length too large
begin
 Tree:=Descriptor.DynamicTree;
 MaxCode:=Descriptor.MaxCode;
 sTree:=Descriptor.staticDescriptor.staticTree;
 Extra:=Descriptor.staticDescriptor.ExtraBits;
 Base:=Descriptor.staticDescriptor.ExtraBase;
 Maxlength:=Descriptor.staticDescriptor.Maxlength;
 Overflow:=0;

 Fillchar(s.BitlengthCounts,sizeof(s.BitlengthCounts),0);

 //in a first pass,compute the optimal bit lengths (which may overflow in the case of the bit length tree)
 Tree[s.Heap[s.HeapMaximum]].dl.Len:=0; //root of the heap

 for H:=s.HeapMaximum+1 to HEAP_sIZE-1 do begin
  N:=s.Heap[H];
  Bits:=Tree[Tree[N].dl.Dad].dl.Len+1;
  if Bits>Maxlength then begin
   Bits:=Maxlength;
   inc(Overflow);
  end;
  Tree[N].dl.Len:=Bits;

  //overwrite Tree[N].dl.Dad which is no longer needed
  if N>MaxCode then continue; //not a leaf node

  inc(s.BitlengthCounts[Bits]);
  ExtraBits:=0;
  if N>=Base then ExtraBits:=Extra[N-Base];
  F:=Tree[N].fc.Frequency;
  inc(s.Optimallength,integer(F)*(Bits+ExtraBits));
  if Assigned(sTree) then inc(s.staticlength,integer(F)*(sTree[N].dl.Len+ExtraBits));
 end;

 //This happens for example on obj2 and pic of the Calgary corpus
 if Overflow=0 then exit;

 //find the first bit length which could increase
 repeat
  Bits:=Maxlength-1;
  while (s.BitlengthCounts[Bits]=0) do dec(Bits);
  //move one leaf down the tree
  dec(s.BitlengthCounts[Bits]);
  //move one overflow item as its brother
  inc(s.BitlengthCounts[Bits+1],2);
  //The brother of the overflow item also movels one step up,
  //but this does not affect BitlengthCounts[Maxlength]
  dec(s.BitlengthCounts[Maxlength]);
  dec(Overflow,2);
 until (Overflow<=0);

 //Now recompute all bit lengths,scanning in increasing frequency.
 //H is still equal to HEAP_sIZE. (It is simpler to reconstruct all
 //lengths instead of fixing only the wrong ones. This idea is taken
 //from 'ar' written by Haruhiko Okumura.)
 H:=HEAP_sIZE;
 for Bits:=Maxlength downto 1 do begin
  N:=s.BitlengthCounts[Bits];
  while N<>0 do begin
   dec(H);
   M:=s.Heap[H];
   if M>MaxCode then continue;
   if Tree[M].dl.Len<>Bits then begin
    inc(s.Optimallength,(Bits-Tree[M].dl.Len)*Tree[M].fc.Frequency);
    Tree[M].dl.Len:=word(Bits);
   end;
   dec(N);
  end;
 end;
end;
//############################################################################//
//constructs a Huffman tree and assigns the code bit strings and lengths.
//Updates the total bit length for the current block. The field Frequency must be set for all tree elements on entry.
//result:the fields Len and Code are set to the optimal bit length and corresponding Code. The length Optimallength
//is updated; staticlength is also updated if sTree is not nil. The field MaxCode is set.
procedure BuildTree(var s:TDeflatestate; var Descriptor:TTreeDescriptor);
var Tree:PTree;
sTree:PTree;
Elements:integer;
N,M:integer;    //iterate over heap elements
MaxCode:integer; //largest code with non zero frequency
Node:integer;    //new node being created
begin
 Tree:=Descriptor.DynamicTree;
 sTree:=Descriptor.staticDescriptor.staticTree;
 Elements:=Descriptor.staticDescriptor.Elements;
 MaxCode:=-1;

 //construct the initial Heap,with least frequent element in Heap[sMALLEsT].
 //The sons of Heap[N] are Heap[2*N] and Heap[2*N+1]. Heap[0] is not used.
 s.Heaplength:=0;
 s.HeapMaximum:=HEAP_sIZE;

 for N:=0 to Elements-1 do begin
  if Tree[N].fc.Frequency=0 then begin
   Tree[N].dl.Len:=0
  end else begin
   MaxCode:=N;
   inc(s.Heaplength);
   s.Heap[s.Heaplength]:=N;
   s.Depth[N]:=0;
  end;
 end;

 //The pkzip format requires that at least one distance code exists and that at least one bit
 //should be sent even if there is only one possible code. so to avoid special checks later on we force at least
 //two codes of non zero frequency.
 while s.Heaplength<2 do begin
  inc(s.Heaplength);
  if MaxCode<2 then begin
   inc(MaxCode);
   s.Heap[s.Heaplength]:=MaxCode;
   Node:=MaxCode;
  end else begin
   s.Heap[s.Heaplength]:=0;
   Node:=0;
  end;
  Tree[Node].fc.Frequency:=1;
  s.Depth[Node]:=0;
  dec(s.Optimallength);
  if sTree<>nil then dec(s.staticlength,sTree[Node].dl.Len);
  //Node is 0 or 1 so it does not have extra bits
 end;
 Descriptor.MaxCode:=MaxCode;

 //The elements Heap[Heaplength/2+1 .. Heaplength] are leaves of the Tree,
 //establish sub-heaps of increasing lengths.
 for N:=s.Heaplength div 2 downto 1 do RestoreHeap(s,Tree^,N);

 //construct the Huffman tree by repeatedly combining the least two frequent nodes
 Node:=Elements; //next internal node of the tree
 repeat
  N:=s.Heap[1];
  s.Heap[1]:=s.Heap[s.Heaplength];
  dec(s.Heaplength);
  RestoreHeap(s,Tree^,1);

  //M:=node of next least frequency
  M:=s.Heap[1];
  dec(s.HeapMaximum);
  //keep the nodes sorted by frequency
  s.Heap[s.HeapMaximum]:=N;
  dec(s.HeapMaximum);
  s.Heap[s.HeapMaximum]:=M;

  //create a new node father of N and M
  Tree[Node].fc.Frequency:=Tree[N].fc.Frequency+Tree[M].fc.Frequency;
  //maximum
  if s.Depth[N]>=s.Depth[M] then s.Depth[Node]:=byte(s.Depth[N]+1)
                            else s.Depth[Node]:=byte(s.Depth[M]+1);

  Tree[M].dl.Dad:=word(Node);
  Tree[N].dl.Dad:=word(Node);
  //and insert the new node in the heap
  s.Heap[1]:=Node;
  inc(Node);
  RestoreHeap(s,Tree^,1);
 until s.Heaplength<2;

 dec(s.HeapMaximum);
 s.Heap[s.HeapMaximum]:=s.Heap[1];

 //At this point the fields Frequency and dad are set.
 //We can now generate the bit lengths.
 GenerateBitlengths(s,Descriptor);

 //The field Len is now set,we can generate the bit codes
 GenerateCodes(Tree,MaxCode,s.BitlengthCounts);
end;    
//############################################################################//      
//flushs the bit buffer and aligns the output on a byte boundary
procedure BitsWindup(var s:TDeflatestate);
begin
 if s.ValidBits>8 then begin
  s.PendingBuffer[s.Pending]:=byte(s.BitsBuffer and $FF);
  inc(s.Pending);
  s.PendingBuffer[s.Pending]:=byte(word(s.BitsBuffer) shr 8);
  inc(s.Pending);
 end else if s.ValidBits>0 then begin
  s.PendingBuffer[s.Pending]:=byte(s.BitsBuffer);
  inc(s.Pending);
 end;
 s.BitsBuffer:=0;
 s.ValidBits:=0;
end;
//############################################################################//  
//Value contains what is to be sent
//length is the number of bits to send
procedure sendBits(var s:TDeflatestate; Value:word; length:integer);
begin
 //if there's not enough room in BitsBuffer use (valid) bits from BitsBuffer and (16-ValidBits) bits from Value,leaving (width-(16-ValidBits)) unused bits in Value.
 if s.ValidBits>integer(Buffersize)-length then begin
  s.BitsBuffer:=s.BitsBuffer or (Value shl s.ValidBits);
  s.PendingBuffer[s.Pending]:=s.BitsBuffer and $FF;
  inc(s.Pending);
  s.PendingBuffer[s.Pending]:=s.BitsBuffer shr 8;
  inc(s.Pending);
  s.BitsBuffer:=Value shr (Buffersize-s.ValidBits);
  inc(s.ValidBits,length-Buffersize);
 end else begin
  s.BitsBuffer:=s.BitsBuffer or (Value shl s.ValidBits);
  inc(s.ValidBits,length);
 end;
end;
//############################################################################//
//sends the given tree in compressed form using the codes in BitlengthTree.
//MaxCode is the tree's largest code of non zero frequency.
procedure sendTree(var s:TDeflatestate; const Tree:array of TTreeEntry;MaxCode:integer);
var N:integer;       //iterates over all tree elements
PreviousLen:integer; //last emitted length
CurrentLen:integer;  //length of current code
NextLen:integer;     //length of next code
Count:integer;       //repeat count of the current code
MaxCount:integer;    //max repeat count
Mincount:integer;    //min repeat count
begin
 PreviousLen:=-1;
 NextLen:=Tree[0].dl.Len;
 Count:=0;
 MaxCount:=7;
 Mincount:=4;

 //guard is already set
 if NextLen=0 then begin
  MaxCount:=138;
  Mincount:=3;
 end;

 for N:=0 to MaxCode do begin
  CurrentLen:=NextLen;
  NextLen:=Tree[N+1].dl.Len;
  inc(Count);
  if (Count<MaxCount)and(CurrentLen=NextLen) then begin
   continue;
  end else if Count<Mincount then begin
   repeat
    sendBits(s,s.BitlengthTree[CurrentLen].fc.Code,s.BitlengthTree[CurrentLen].dl.Len);
    dec(Count);
   until (Count=0);
  end else if CurrentLen<>0 then begin
   if CurrentLen<>PreviousLen then begin
    sendBits(s,s.BitlengthTree[CurrentLen].fc.Code,s.BitlengthTree[CurrentLen].dl.Len);
    dec(Count);
   end;
   sendBits(s,s.BitlengthTree[REP_3_6].fc.Code,s.BitlengthTree[REP_3_6].dl.Len);
   sendBits(s,Count-3,2);
  end else if Count<=10 then begin
   sendBits(s,s.BitlengthTree[REPZ_3_10].fc.Code,s.BitlengthTree[REPZ_3_10].dl.Len);
   sendBits(s,Count-3,3);
  end else begin
   sendBits(s,s.BitlengthTree[REPZ_11_138].fc.Code,s.BitlengthTree[REPZ_11_138].dl.Len);
   sendBits(s,Count-11,7);
  end;
  Count:=0;
  PreviousLen:=CurrentLen;
  if NextLen=0 then begin
   MaxCount:=138;
   Mincount:=3;
  end else if CurrentLen=NextLen then begin
   MaxCount:=6;
   Mincount:=3;
  end else begin
   MaxCount:=7;
   Mincount:=4;
  end;
 end;
end;
//############################################################################//
//sends the header for a block using dynamic Huffman trees:the counts,the lengths of the bit length codes,the literal tree and the distance tree.
//lcodes must be>=257,dcodes>=1 and blcodes>=4
procedure sendAllTrees(var s:TDeflatestate; lcodes,dcodes,blcodes:integer);
var Rank:integer;
begin
 sendBits(s,lcodes-257,5); //not+255 as stated in appnote.txt
 sendBits(s,dcodes-1,5);
 sendBits(s,blcodes-4,4); //not-3 as stated in appnote.txt
 for Rank:=0 to blcodes-1 do sendBits(s,s.BitlengthTree[BitlengthOrder[Rank]].dl.Len,3);
 sendTree(s,s.LiteralTree,lcodes-1);
 sendTree(s,s.DistanceTree,dcodes-1);
end;  
//############################################################################//   
//scans a given tree to determine the frequencies of the codes in the bit length tree. MaxCode is the tree's largest code of non zero frequency.
procedure scanTree(var s:TDeflatestate; var Tree:array of TTreeEntry;MaxCode:integer);
var N:integer;           //iterates over all tree elements
PreviousLen:integer; //last emitted length
CurrentLen:integer;  //length of current code
NextLen:integer;     //length of next code
Count:integer;       //repeat count of the current xode
MaxCount:integer;    //max repeat count
Mincount:integer;    //min repeat count
begin
 PreviousLen:=-1;
 NextLen:=Tree[0].dl.Len;
 Count:=0;
 MaxCount:=7;
 Mincount:=4;

 if NextLen=0 then begin
  MaxCount:=138;
  Mincount:=3;
 end;
 Tree[MaxCode+1].dl.Len:=word($FFFF); //guard

 for N:=0 to MaxCode do begin
  CurrentLen:=NextLen;
  NextLen:=Tree[N+1].dl.Len;
  inc(Count);
  if (Count<MaxCount)and(CurrentLen=NextLen) then begin
   continue;
  end else if Count<Mincount then begin
   inc(s.BitlengthTree[CurrentLen].fc.Frequency,Count);
  end else if CurrentLen<>0 then begin
   if (CurrentLen<>PreviousLen) then inc(s.BitlengthTree[CurrentLen].fc.Frequency);
   inc(s.BitlengthTree[REP_3_6].fc.Frequency);
  end else if Count<=10 then begin
   inc(s.BitlengthTree[REPZ_3_10].fc.Frequency)
  end else begin
   inc(s.BitlengthTree[REPZ_11_138].fc.Frequency);
  end;
  Count:=0;
  PreviousLen:=CurrentLen;
  if NextLen=0 then begin
   MaxCount:=138;
   Mincount:=3;
  end else if CurrentLen=NextLen then begin
   MaxCount:=6;
   Mincount:=3;
  end else begin
   MaxCount:=7;
   Mincount:=4;
  end;
 end;
end;
//############################################################################//
//constructs the Huffman tree for the bit lengths and returns the Index in BitlengthOrder of the last bit length code to send.
function BuildBitlengthTree(var s:TDeflatestate):integer;
begin
 //determine the bit length frequencies for literal and distance trees
 scanTree(s,s.LiteralTree,s.LiteralDescriptor.MaxCode);
 scanTree(s,s.DistanceTree,s.DistanceDescriptor.MaxCode);

 //build the bit length tree
 BuildTree(s,s.BitlengthDescriptor);
 //Optimallength now includes the length of the tree representations,except
 //the lengths of the bit lengths codes and the 5+5+4 (= 14) bits for the counts.

 //Determine the number of bit length codes to send. The pkzip format requires that at least 4 bit length codes
 //be sent. (appnote.txt says 3 but the actual value used is 4.)
 for result:=BL_CODEs-1 downto 3 do if s.BitlengthTree[BitlengthOrder[result]].dl.Len<>0 then break;

 //update Optimallength to include the bit length tree and counts
 inc(s.Optimallength,3*(result+1)+14);
end;             
//############################################################################//  
//copies a stored block,storing first the length and its one's complement if requested
//Buffer contains the input data,Len the buffer length and Header is true if the block Header must be written too.
procedure CopyBlock(var s:TDeflatestate; Buffer:Pbyte; Len:dword;Header:boolean);
begin
 BitsWindup(s);        //align on byte boundary
 s.LastEOBlength:=8; //enough lookahead for Inflate

 if Header then begin
  s.PendingBuffer[s.Pending]:=byte(word(Len) and $FF);
  inc(s.Pending);
  s.PendingBuffer[s.Pending]:=byte(word(Len) shr 8);
  inc(s.Pending);
  s.PendingBuffer[s.Pending]:=byte(word(not Len) and $FF);
  inc(s.Pending);
  s.PendingBuffer[s.Pending]:=byte(word(not Len) shr 8);
  inc(s.Pending);
 end;

 while Len>0 do begin
  dec(Len);
  s.PendingBuffer[s.Pending]:=Buffer^;
  inc(Buffer);
  inc(s.Pending);
 end;
end;
//############################################################################//    
//sends a stored block
//Buffer contains the input data,Len the buffer length and EOF is true if this is the last block for a file.
procedure TreestroredBlock(var s:TDeflatestate; Buffer:Pbyte;storedlength:integer; EOF:boolean);
begin
 sendBits(s,(sTORED_BLOCK shl 1)+Ord(EOF),3);  //send block type
 s.Compressedlength:=(s.Compressedlength+10) and integer(not 7);
 inc(s.Compressedlength,(storedlength+4) shl 3);

 //copy with header
 CopyBlock(s,Buffer,dword(storedlength),true);
end;
//############################################################################//    
//sends the block data compressed using the given Huffman trees
procedure CompressBlock(var s:TDeflatestate; const LiteralTree,DistanceTree:array of TTreeEntry);
var Distance:dword; //distance of matched string
lc:integer;        //match length or unmatched char (if Distance=0)
I:dword;
Code:dword;     //the code to send
Extra:integer;     //number of extra bits to send
begin
 I:=0;
 if s.LastLiteral<>0 then repeat
  Distance:=s.DistanceBuffer[I];
  lc:=s.LiteralBuffer[I];
  inc(I);
  if Distance=0 then begin
   //send a literal byte
   sendBits(s,LiteralTree[lc].fc.Code,LiteralTree[lc].dl.Len);
  end else begin
   //Here,lc is the match length-MIN_MATCH
   Code:=lengthCode[lc];
   //send the length code
   sendBits(s,LiteralTree[Code+LITERALs+1].fc.Code,LiteralTree[Code+LITERALs+1].dl.Len);
   Extra:=ExtralengthBits[Code];
   if Extra<>0 then begin
    dec(lc,Baselength[Code]);
    //send the extra length bits
    sendBits(s,lc,Extra);
   end;
   dec(Distance); //Distance is now the match distance-1
   if Distance<256 then Code:=DistanceCode[Distance]
                   else Code:=DistanceCode[256+(Distance shr 7)];

   //send the distance code
   sendBits(s,DistanceTree[Code].fc.Code,DistanceTree[Code].dl.Len);
   Extra:=ExtraDistanceBits[Code];
   if Extra<>0 then begin
    dec(Distance,BaseDistance[Code]);
    sendBits(s,Distance,Extra);   //send the extra distance bits
   end;
  end; //literal or match pair?
  //Check that the overlay between PendingBuffer and DistanceBuffer+LiteralBuffer is ok
 until I>=s.LastLiteral;

 sendBits(s,LiteralTree[end_BLOCK].fc.Code,LiteralTree[end_BLOCK].dl.Len);
 s.LastEOBlength:=LiteralTree[end_BLOCK].dl.Len;
end;
//############################################################################//
//Determines the best encoding for the current block:dynamic trees,static trees or store,and outputs the encoded
//block. Buffer contains the input block (or nil if too old),storedlength the length of this block and EOF if this is the last block.
//Returns the total compressed length so far.
function TreeFlushBlock(var s:TDeflatestate; Buffer:Pbyte; storedlength:integer; EOF:boolean):integer;
var Optimalbytelength,staticbytelength:integer; //Optimallength and staticlength in bytes
MacBLIndex:integer;  //index of last bit length code of non zero frequency
begin
 //construct the literal and distance trees
 //After this,Optimallength and staticlength are the total bit lengths of
 //the compressed block data,excluding the tree representations.
 BuildTree(s,s.LiteralDescriptor);
 BuildTree(s,s.DistanceDescriptor);

 //Build the bit length tree for the above two trees and get the index
 //in BitlengthOrder of the last bit length code to send.
 MacBLIndex:=BuildBitlengthTree(s);

 //determine the best encoding,compute first the block length in bytes
 Optimalbytelength:=(s.Optimallength+10) shr 3;
 staticbytelength:=(s.staticlength+10) shr 3;
 if staticbytelength<=Optimalbytelength then Optimalbytelength:=staticbytelength;

 //if compression failed and this is the first and last block,
 //and if the .zip file can be seeked (to rewrite the local header),
 //the whole file is transformed into a stored file.
 //(4 are the two words for the lengths)
 if (storedlength+4<=Optimalbytelength) and Assigned(Buffer) then begin
  //The test Buffer<>nil is only necessary if LiteralBuffersize>Wsize.
  //Otherwise we can't have processed more than Wsize input bytes since
  //the last block dlush,because compression would have been successful.
  //if LiteralBuffersize <= Wsize,it is never too late to transform a block into a stored block.
  TreestroredBlock(s,Buffer,storedlength,EOF);
 end else if staticbytelength=Optimalbytelength then begin
  //force static trees
  sendBits(s,(sTATIC_TREEs shl 1)+Ord(EOF),3);
  CompressBlock(s,staticLiteralTree,staticDescriptorTree);
  inc(s.Compressedlength,3+s.staticlength);
 end else begin
  sendBits(s,(DYN_TREEs shl 1)+Ord(EOF),3);
  sendAllTrees(s,s.LiteralDescriptor.MaxCode+1,s.DistanceDescriptor.MaxCode+1,MacBLIndex+1);
  CompressBlock(s,s.LiteralTree,s.DistanceTree);
  inc(s.Compressedlength,3+s.Optimallength);
 end;
 InitializeBlock(s);

 if EOF then begin
  BitsWindup(s);
  //align on byte boundary
  inc(s.Compressedlength,7);
 end;

 result:=s.Compressedlength shr 3;
end;
//############################################################################//
//Flushs the current block with given end-of-file flag.
//stringstart must be set to the end of the current match.
procedure FlushBlockOnly(var s:TDeflatestate;EOF:boolean);
begin
 if s.Blockstart>=0 then TreeFlushBlock(s,@s.Window[dword(s.Blockstart)],integer(s.stringstart)-s.Blockstart,EOF)
                    else TreeFlushBlock(s,nil,integer(s.stringstart)-s.Blockstart,EOF);
 s.Blockstart:=s.stringstart;
 FlushPending(s.Zstate^);
end;
//############################################################################// 
//saves the match info and tallies the frequency counts. Returns true if the current block must be flushed.
//Distance is the distance of the matched string and lc either match length minus MIN_MATCH or the unmatch character (if Distance=0).
function TreeTally(var s:TDeflatestate; Distance:dword; lc:dword):boolean;
var Code:word;
begin
 s.DistanceBuffer[s.LastLiteral]:=word(Distance);
 s.LiteralBuffer[s.LastLiteral]:=byte(lc);
 inc(s.LastLiteral);
 if (Distance=0) then begin
  //lc is the unmatched char
  inc(s.LiteralTree[lc].fc.Frequency);
 end else begin
  inc(s.matches);
  //here,lc is the match length-MIN_MATCH
  dec(Distance);
  if Distance<256 then Code:=DistanceCode[Distance]
                  else Code:=DistanceCode[256+(Distance shr 7)];
  inc(s.LiteralTree[lengthCode[lc]+LITERALs+1].fc.Frequency);
  inc(s.DistanceTree[Code].fc.Frequency);
 end;

 result:=(s.LastLiteral=s.LiteralBuffersize-1);
 //We avoid equality with LiteralBuffersize because stored blocks are restricted to 64K-1 bytes.
end;
//############################################################################//  
//Inserts str into the dictionary and sets matchHead to the previous head of the hash chain (the most recent string
//with same hash key). All calls to to Insertstring are made with consecutive input characters and the first MIN_MATCH
//bytes of str are valid (except for the last MIN_MATCH-1 bytes of the input file).
//Returns the previous length of the hash chain.
procedure Insertstring(var s:TDeflatestate; str:dword; var matchHead:dword);
begin
 s.InsertHash:=((s.InsertHash shl s.Hashshift) xor (s.Window[(str)+(MIN_MATCH-1)])) and s.HashMask;
 matchHead:=s.Head[s.InsertHash];
 s.Previous[(str) and s.WindowMask]:=matchHead;
 s.Head[s.InsertHash]:=word(str);
end;
//############################################################################//
function do_deflate(src,dst:pointer;srcLen,dstLen:integer;max_compress:boolean=false):integer;
const CMaxInsertLen=5;
var Z:TZstate;
Overlay:pworda;
//We overlay PendingBuffer and DistanceBuffer+LiteralBuffer. This works since the average
//output size for (length,distance) codes is <= 24 Bits.
HashHead:dword;  //head of the hash chain
BlockFlush:boolean; //set if current block must be flushed
s:TDeflatestate;
begin
 result:=0;
 Fillchar(Z,sizeof(Z),0);
 Z.NextInput:=src;
 Z.AvailableInput:=srcLen;
 Z.NextOutput:=dst;
 Z.AvailableOutput:=dstLen;
 Z.TotalInput:=Z.TotalOutput;
 Fillchar(s,sizeof(TDeflatestate),0);

 try
  Z.state:=@s;
  s.Zstate:=@Z;
  s.Windowsize:=1 shl CWindowBits;
  s.WindowMask:=s.Windowsize-1;
  s.HashBits:=CMemLevel+7;
  s.Hashsize:=1 shl s.HashBits;
  s.HashMask:=s.Hashsize-1;
  s.Hashshift:=(s.HashBits+MIN_MATCH-1) div MIN_MATCH;
  getmem(s.Window,s.Windowsize*(2*sizeof(byte)));
  getmem(s.Previous,s.Windowsize*sizeof(word));
  getmem(s.Head,s.Hashsize*sizeof(word));
  s.LiteralBuffersize:=1 shl (CMemLevel+6); //16K elements by default
  getmem(Overlay,s.LiteralBuffersize*(sizeof(word)+2));
  s.PendingBuffer:=pbytea(Overlay);
  s.PendingBuffersize:=s.LiteralBuffersize*(sizeof(word)+2);
  s.DistanceBuffer:=@Overlay[s.LiteralBuffersize div sizeof(word)];
  s.LiteralBuffer:=@s.PendingBuffer[(1+sizeof(word))*s.LiteralBuffersize];
  s.PendingOutput:=Pbyte(s.PendingBuffer);
  s.LiteralDescriptor.DynamicTree:=@s.LiteralTree;
  s.LiteralDescriptor.staticDescriptor:=@staticLiteralDescriptor;
  s.DistanceDescriptor.DynamicTree:=@s.DistanceTree;
  s.DistanceDescriptor.staticDescriptor:=@staticDistanceDescriptor;
  s.BitlengthDescriptor.DynamicTree:=@s.BitlengthTree;
  s.BitlengthDescriptor.staticDescriptor:=@staticBitlengthDescriptor;
  s.LastEOBlength:=8; //enough Lookahead for Inflate
  InitializeBlock(s);
  s.CurrentWindowsize:=2*s.Windowsize;
  s.Head[s.Hashsize-1]:=0;
  Fillchar(s.Head^,(s.Hashsize-1)*sizeof(s.Head[0]),0);
  s.Previouslength:=MIN_MATCH-1;
  s.matchlength:=MIN_MATCH-1;

  HashHead:=0;
  while true do begin
   //Make sure that we always have enough lookahead,except at the end of the input file. We need MAX_MATCH bytes
   //for the next match plus MIN_MATCH bytes to insert the string following the next match.
   if s.Lookahead<MIN_LOOKAHEAD then begin
    FillWindow(s);

    //flush the current block
    if s.Lookahead=0 then begin
     FlushBlockOnly(s,true);
     if Z.AvailableOutput<>0 then result:=Z.TotalOutput;
     break;
    end;
   end;

   //Insert the string Window[stringstart .. stringstart+2] in the
   //dictionary and set HashHead to the head of the hash chain.
   if s.Lookahead>=MIN_MATCH then Insertstring(s,s.stringstart,HashHead);

   //Find the longest match,discarding those <= Previouslength.
   //At this point we have always matchlength<MIN_MATCH.
   if (HashHead<>0)and(s.stringstart-HashHead <= (s.Windowsize-MIN_LOOKAHEAD)) then s.matchlength:=Longestmatch(s,HashHead);
   if s.matchlength>=MIN_MATCH then begin
    BlockFlush:=TreeTally(s,s.stringstart-s.matchstart,s.matchlength-MIN_MATCH);
    dec(s.Lookahead,s.matchlength);

    //Insert new strings in the hash table only if the match length is not too large. This saves time but degrades compression.
    if ((s.matchlength<=CMaxInsertLen) or max_compress)and(s.Lookahead>=MIN_MATCH) then begin
     //string at stringstart already in hash table
     dec(s.matchlength);
     repeat
      inc(s.stringstart);
      Insertstring(s,s.stringstart,HashHead);
      //stringstart never exceeds Wsize-MAX_MATCH,so there are always MIN_MATCH bytes ahead.
      dec(s.matchlength);
     until s.matchlength=0;
     inc(s.stringstart);
    end else begin
     inc(s.stringstart,s.matchlength);
     s.matchlength:=0;
     s.InsertHash:=s.Window[s.stringstart];
     s.InsertHash:=((s.InsertHash shl s.Hashshift) xor s.Window[s.stringstart+1]) and s.HashMask;
     //if Lookahead<MIN_MATCH,InsertHash is garbage,but it does not
     //matter since it will be recomputed at next Deflate call.
    end;
   end else begin
    //no match,output a literal byte
    BlockFlush:=TreeTally(s,0,s.Window[s.stringstart]);
    dec(s.Lookahead);
    inc(s.stringstart);
   end;
   if BlockFlush then begin
    FlushBlockOnly(s,false);
    if s.Zstate.AvailableOutput=0 then break;
   end;
  end;
 except
  result:=0;
 end;
 freemem(s.PendingBuffer);
 freemem(s.Head);
 freemem(s.Previous);
 freemem(s.Window);
end;
//############################################################################//
begin
end. 
//############################################################################//


