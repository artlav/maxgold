//############################################################################//
{$H+}
{$ifdef FPC}{$MODE delphi}{$endif}
unit vfsint;
interface
uses sysutils,asys;
//############################################################################//
const
attstandard =32768;
atthidden   =16384;
attsystem   =8192;
attdir      =4096;
attlink     =2048;
attsmall    =1024;
attspecial  =512;
attsymlink  =256;
attreadonly =128;
attwriteonly=64;
attpacked   =32;
attres4     =16;
attres3     =8;
attres2     =4;
attres1     =2;
attres0     =1;
attall      =$FFFF;
//############################################################################//
VFERR_ETC     =9999;
VFERR_OK      =0;
VFERR_WRPATH  =1;
VFERR_SYMLINK =2;
VFERR_BUFFER  =3;
VFERR_FNF     =4;
VFERR_FEATURE =5;
VFERR_HANDLE  =6;
VFERR_RO      =7;
VFERR_NONEMPTY=8;
//############################################################################//
VFO_READ=1;
VFO_WRITE=2;
VFO_RW=3;
//############################################################################//
MAX_PATH=1024;
VF_MAGIC=$DEAB75CD;
//############################################################################//
BAD_VFILE=$FFFFFFFF;
//############################################################################//
//Search
STG_INIT=0;
STG_DISPOSE=1;
STG_ONE_FILE=2;

SRCH_ERR=0;
SRCH_OK=1;
SRCH_LAST=2;
//############################################################################//
type
vdirsrctyp=packed record
 ex:byte;
 attr:word;
 size:qword;
 timestamp:dword;
 name_lng:dword;
end;
pvdirsrctyp=^vdirsrctyp;

vdir=record
 name:string;
 attr:word;
 size:qword;
 timestamp:dword;
 db:array of byte;
end;
avdir=array of vdir;
pvdir=^vdir;
pavdir=^avdir;

findrec=record
 r:avdir;
 root:string;
 cur,total:dword;
end;
pfindrec=^findrec;
//############################################################################//
vfresult=dword;
vfile=file;
//############################################################################//  
function  vferror_to_str(const err:dword):string;

function  vfopen  (out f:vfile;const nam:string;mode:byte):vfresult;
function  vfexists(const nam:string):boolean;
function  vfmkdir (const nam:string):boolean;
function  vffind_arr(const nam:string;attr:word):avdir;

function  vfclose   (var f:vfile):vfresult;
function  vfread    (var f:vfile;p:pointer;s:qword):qword;
function  vfwrite   (var f:vfile;p:pointer;s:qword):qword;
function  vfeof     (var f:vfile):boolean;
function  vfseek    (var f:vfile;np:qword):boolean;
function  vffilesize(var f:vfile):qword;
function  vffilepos (var f:vfile):qword;
//############################################################################//
implementation
//############################################################################//
{$I-}
function vfopen(out f:vfile;const nam:string;mode:byte):vfresult;
var fn:string;
begin
 result:=VFERR_ETC;
 fn:=nam;
 {$ifndef unix}if fn[1]='/' then fn:=copy(fn,2,length(fn));{$endif}
 if mode=VFO_READ then if not fileexists(fn) then exit;
 assignfile(f,fn);
 if ioresult<>0 then exit;
 filemode:=0;
 if mode=VFO_READ then reset(f,1);
 if mode=VFO_WRITE then rewrite(f,1);
 if ioresult<>0 then exit;
 result:=VFERR_OK;
end;
function  vfclose  (var f:vfile):vfresult;begin result:=VFERR_OK; closefile(f);end;
function  vfread   (var f:vfile;p:pointer;s:qword):qword;begin blockread(f,p^,s);if ioresult<>0 then result:=0 else result:=s;end;
function  vfwrite  (var f:vfile;p:pointer;s:qword):qword;begin blockwrite(f,p^,s);if ioresult<>0 then result:=0 else result:=s;end;
function  vfseek   (var f:vfile;np:qword):boolean;begin seek(f,np);result:=true;end;
function  vfeof    (var f:vfile):boolean;begin result:=eof(f);end;
function vffilepos (var f:vfile):qword;begin result:=filepos(f);end;
function vffilesize(var f:vfile):qword;begin result:=filesize(f);end;

{$WARN SYMBOL_PLATFORM OFF}
function vffind(nam:string;attr:word):avdir;
var srch:TSearchRec;
mc:integer;
localoff:integer;
begin
 if findfirst(nam,faanyfile or fasymlink,srch)<>0 then begin findclose(srch);setlength(result,0);exit;end;
 mc:=0;
 setlength(result,10);
 localoff:={$ifdef win32}0;{$else}GetLocalTimeOffset*60;{$endif}
 repeat
  if (srch.name<>'.')and(srch.name<>'..')and((srch.attr and attr)<>0) then begin
   if mc>=length(result) then setlength(result,mc*2+1);
   result[mc].name:=srch.name;
   result[mc].size:=srch.size;
   result[mc].timestamp:=srch.time-localoff;
   result[mc].attr:=0;
   result[mc].attr:=result[mc].attr or (attreadonly*ord((srch.attr and faReadOnly )<>0));
   result[mc].attr:=result[mc].attr or (atthidden  *ord((srch.attr and faHidden   )<>0));
   result[mc].attr:=result[mc].attr or (attsystem  *ord((srch.attr and faSysFile  )<>0));
   result[mc].attr:=result[mc].attr or (attdir     *ord((srch.attr and fadirectory)<>0));
   result[mc].attr:=result[mc].attr or (attsymlink *ord((srch.attr and fasymlink  )<>0));

   //result[mc].attr:=result[mc].attr or (               (srch.attr and $400       )<>0));     //symlink?

   if ((result[mc].attr and attdir)<>0)and((result[mc].attr and attsymlink)=0) then result[mc].size:=0;

   mc:=mc+1;
  end;
  if findnext(srch)<>0 then begin findclose(srch);break;end;
 until false;
 setlength(result,mc);
end;
function vffind_arr(const nam:string;attr:word):avdir;begin result:=vffind(nam,attr);end;
function vfexists(const nam:string):boolean;begin if nam='' then begin result:=false;exit;end; {$ifndef unix}if nam[1]='/' then result:=fileexists(copy(nam,2,length(nam))) else{$endif} result:=fileexists(nam);end;
function vfmkdir(const nam:string):boolean;begin result:=true;mkdir(nam);if ioresult<>0 then result:=false;end;
{$I+}
//############################################################################//
function vferror_to_str(const err:dword):string;
begin
 case err of
  VFERR_OK     :result:='Success';
  VFERR_WRPATH :result:='Wrong path specified';
  VFERR_SYMLINK:result:='Symlink in request';
  VFERR_BUFFER :result:='Buffer size error';
  VFERR_FNF    :result:='File not found';
  VFERR_FEATURE:result:='Feature not implemented in the FS driver';
  VFERR_HANDLE :result:='File handle is wrong';
  else result:='Unknown error';
 end;
end;
//############################################################################//
begin
end.
//############################################################################//
