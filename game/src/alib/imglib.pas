//############################################################################//
// Made in 2003-2018 by Artyom Litvinovich
// AlgorLib: Image wrapper lib
//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit imglib;
interface
uses asys,grph,vfsint;
//############################################################################//
//Former names: LoadBitmap*
function img_load_file_32      (filename:string;out width,height:integer;         out pdata:pointer;status:pdouble=nil):pointer;
function img_load_file_trans_32(filename:string;out width,height:integer;trc:crgb;out pdata:pointer;status:pdouble=nil):pointer;
function img_load_mem_32  (b:pointer;bs:integer;out width,height:integer;         out pdata:pointer;status:pdouble=nil):pointer;

function img_load_file_8(filename:string;out width,height:integer;out pData:pointer;out cl:pallette;status:pdouble=nil):pointer; overload;
function img_load_file_8(filename:string;out width,height:integer;out pData:pointer;out cl:pallette3;status:pdouble=nil):pointer;overload;

function img_load_file_trans_8(filename:string;out width,height:integer;trc:crgb;out pData:pointer;out cl:pallette;status:pdouble=nil):pointer; overload;
function img_load_file_trans_8(filename:string;out width,height:integer;trc:crgb;out pData:pointer;out cl:pallette3;status:pdouble=nil):pointer;overload;
//############################################################################//
type
grfmt_is=function(fn:string):boolean;
grfmt_ld8=function(fn:string;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;out cpal:pallette;status:pdouble):pointer;
grfmt_ld32=function(fn:string;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;status:pdouble):pointer;
grfmt_memis  =function(b:pointer;bs:integer):boolean;
grfmt_memld8 =function(b:pointer;bs:integer;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;out cpal:pallette;status:pdouble):pointer;
grfmt_memld32=function(b:pointer;bs:integer;wtx,wa:boolean;trc:crgb;out bx,by:integer;out p:pointer;status:pdouble):pointer;

grfmt_rec=record
 is32,is8:grfmt_is;
 ld32:grfmt_ld32;
 ld8:grfmt_ld8;

 memis32,memis8:grfmt_memis;
 memld32:grfmt_memld32;
 memld8:grfmt_memld8;
end;

var
grfmt:array of grfmt_rec;
//############################################################################//
procedure register_grfmt(i8,i32:grfmt_is;l8:grfmt_ld8;l32:grfmt_ld32;mi8,mi32:grfmt_memis;ml8:grfmt_memld8;ml32:grfmt_memld32);
//############################################################################//
implementation
//############################################################################//
procedure register_grfmt(i8,i32:grfmt_is;l8:grfmt_ld8;l32:grfmt_ld32;mi8,mi32:grfmt_memis;ml8:grfmt_memld8;ml32:grfmt_memld32);
var c:integer;
begin
 c:=length(grfmt);
 setlength(grfmt,c+1);
 grfmt[c].is32:=i32;
 grfmt[c].is8 :=i8;
 grfmt[c].ld32:=l32;
 grfmt[c].ld8 :=l8;
 grfmt[c].memis32:=mi32;
 grfmt[c].memis8 :=mi8;
 grfmt[c].memld32:=ml32;
 grfmt[c].memld8 :=ml8;
end;
//############################################################################//
function img_load_mem_32(b:pointer;bs:integer;out width,height:integer;out pdata:pointer;status:pdouble=nil):pointer;
var i:integer;
begin
 pdata:=nil;result:=nil;
 if b=nil then exit;
 for i:=0 to length(grfmt)-1 do if assigned(grfmt[i].memis32) then if grfmt[i].memis32(b,bs) then begin
  result:=grfmt[i].memld32(b,bs,false,true,gclz,width,height,pdata,status);
  exit;
 end;
end;
//############################################################################//
function img_load_file_trans_32(filename:string;out width,height:integer;trc:crgb;out pdata:pointer;status:pdouble=nil):pointer;
var i:integer;
begin
 pdata:=nil;result:=nil;
 if not vfexists(filename) then exit;
 for i:=0 to length(grfmt)-1 do if assigned(grfmt[i].is32) then if grfmt[i].is32(filename) then begin
  result:=grfmt[i].ld32(filename,true,true,trc,width,height,pdata,status);
  exit;
 end;
end;
//############################################################################//
function img_load_file_32(filename:string;out width,height:integer;out pData:pointer;status:pdouble=nil):pointer;
begin
 result:=img_load_file_trans_32(filename,width,height,gclz,pdata,status);
end;
//############################################################################//
function img_load_file_trans_8(filename:string;out width,height:integer;trc:crgb;out pData:pointer;out cl:pallette;status:pdouble=nil):pointer; overload;
var i:integer;
begin
 pdata:=nil;result:=nil;
 if not vfexists(filename) then exit;
 for i:=0 to length(grfmt)-1 do if assigned(grfmt[i].is8) then if grfmt[i].is8(filename) then begin
  result:=grfmt[i].ld8(filename,true,true,trc,width,height,pdata,cl,status);
  exit;
 end;
end;
//############################################################################//
function img_load_file_8(filename:string;out width,height:integer;out pData:pointer;out cl:pallette;status:pdouble=nil):pointer; overload;
begin
 result:=img_load_file_trans_8(filename,width,height,gclz,pData,cl,status);
end;
//############################################################################//
function img_load_file_8(filename:string;out width,height:integer;out pData:pointer;out cl:pallette3;status:pdouble=nil):pointer; overload;
var pl:pallette;
i:integer;
begin
 result:=img_load_file_8(filename,width,height,pData,pl,status);
 for i:=0 to 255 do begin cl[i][0]:=pl[i][0];cl[i][1]:=pl[i][1];cl[i][2]:=pl[i][2];end;
end;
//############################################################################//
function img_load_file_trans_8(filename:string;out width,height:integer;trc:crgb;out pData:pointer;out cl:pallette3;status:pdouble=nil):pointer; overload;
var pl:pallette;
i:integer;
begin
 result:=img_load_file_trans_8(filename,width,height,trc,pData,pl,status);
 for i:=0 to 255 do begin cl[i][0]:=pl[i][0];cl[i][1]:=pl[i][1];cl[i][2]:=pl[i][2];end;
end;
//############################################################################//
begin
end.
//############################################################################//
