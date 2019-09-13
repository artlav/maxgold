//############################################################################//
program max_map;
{$ifdef mswindows}{$apptype console}{$endif}
uses sysutils,asys,maths,strval,strtool,filef,b64,lzw,utf;
//############################################################################//
procedure convert_one_map(fn:string);
var x,y,elem_count:word;
hdr:array[0..4]of byte;
s,s1,s2,name:string;
f:file;
i,n,pck_sz:integer;
mpallette:array[0..767]of byte;
minimap:array of byte;
passmap:array of byte;
map:array of word;
blocks:array of array[0..64*64-1]of byte;
pck_blk:array[0..64*64-1]of byte;
begin try
 n:=getfsymp(fn,'.');
 name:=copy(fn,1,n-1);

 assignfile(f,name+'.wrl');
 reset(f,1);
 blockread(f,hdr,5);
 blockread(f,x,2);
 blockread(f,y,2);
 setlength(map,x*y);
 setlength(minimap,x*y);
 blockread(f,minimap[0],x*y);
 blockread(f,map[0],2*x*y);

 blockread(f,elem_count{%H-},2);
 setlength(blocks,elem_count);
 blockread(f,blocks[0],elem_count*64*64);
 blockread(f,{%H-}mpallette[0],256*3);
 setlength(passmap,elem_count);
 blockread(f,passmap[0],elem_count);

 closefile(f);

 s:='';
 s:=s+'{'+#$0A;
 s:=s+' "name_rus":"'+name+'",'+#$0A;
 s:=s+' "name_eng":"'+name+'",'+#$0A;
 s:=s+' "description_rus":"'+cp1251_to_utf('Нет описания')+'",'+#$0A;
 s:=s+' "description_eng":"No description",'+#$0A;
 s:=s+' "width":'+stri(x)+','+#$0A;
 s:=s+' "height":'+stri(y)+','+#$0A;

 s1:='';
 for i:=0 to length(mpallette) div 3-1 do begin
  if (i mod 8)=0 then s1:=s1+'  ';
  s1:=s1+'['+trimsl(stri(mpallette[i*3+0]),3,' ')+','+trimsl(stri(mpallette[i*3+1]),3,' ')+','+trimsl(stri(mpallette[i*3+2]),3,' ')+']';
  if i<>length(mpallette) div 3-1 then s1:=s1+',';
  if ((i mod 8)=7)or(i=length(mpallette) div 3-1) then s1:=s1+#$0A;
 end;
 s:=s+' "pal":['+#$0A+s1+' ],'+#$0A;

 s1:='';
 for i:=0 to elem_count-1 do begin
  if (i mod 128)=0 then s1:=s1+'  "';
  s1:=s1+stri(passmap[i]);
  if ((i mod 128)=127)or(i=elem_count-1) then s1:=s1+'"';
  if ((i mod 128)=127)or(i=elem_count-1) then begin
   if i<>elem_count-1 then s1:=s1+',';
   s1:=s1+#$0A;
  end;
 end;
 s:=s+' "passability":['+#$0A+s1+' ],'+#$0A;

 s1:='';
 for i:=0 to x*y-1 do begin
  if (i mod x)=0 then s1:=s1+'  ';
  s1:=s1+trimsl(stri(minimap[i]),3,' ');
  if i<>x*y-1 then s1:=s1+',';
  if ((i mod x)=(x-1))or(i=x*y-1) then s1:=s1+#$0A;
 end;
 s:=s+' "mini_map":['+#$0A+s1+' ],'+#$0A;

 n:=1;
 for i:=0 to x*y-1 do begin
  if map[i]>=   10 then n:=max2i(n,2);
  if map[i]>=  100 then n:=max2i(n,3);
  if map[i]>= 1000 then n:=max2i(n,4);
  if map[i]>=10000 then n:=max2i(n,5);
 end;
 s1:='';
 for i:=0 to x*y-1 do begin
  if (i mod x)=0 then s1:=s1+'  ';
  s1:=s1+trimsl(stri(map[i]),n,' ');
  if i<>x*y-1 then s1:=s1+',';
  if ((i mod x)=(x-1))or(i=x*y-1) then s1:=s1+#$0A;
 end;
 s:=s+' "map":['+#$0A+s1+' ],'+#$0A;

 s1:='';
 for i:=0 to elem_count-1 do begin
  pck_sz:=encodeLZW(@blocks[i][0],@pck_blk[0],64*64,64*64);

  setlength(s2,pck_sz*2);
  n:=b64_enc(@pck_blk[0],pck_sz,@s2[1],length(s2),false);
  setlength(s2,n);

  s1:=s1+'  "'+s2+'"';
  if i<>elem_count-1 then s1:=s1+',';
  s1:=s1+#$0A;
 end;
 s:=s+' "blocks":['+#$0A+s1+' ]'+#$0A;

 s:=s+'}'+#$0A;

 assignfile(f,name+'.txt');
 rewrite(f,1);
 blockwrite(f,s[1],length(s));
 closefile(f);

 except end;
end;
//############################################################################//
var all:astr;
i:integer;
begin
{
 all:=filelist('*.wrl',faanyfile);
 for i:=0 to length(all)-1 do begin
  writeln(all[i]);
  convert_one_map(all[i]);
 end;
 //convert_one_map('green_1');
 }
 if paramcount<>1 then begin
  writeln('max_map map.wrl');
  readln;
  halt;
 end;
 convert_one_map(paramstr(1));
 writeln('Done');
end.
//############################################################################//
