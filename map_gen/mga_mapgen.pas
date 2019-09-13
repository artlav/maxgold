//############################################################################//
unit mga_mapgen;
interface
uses sysutils,asys,strval,strtool;
//############################################################################//
type
obstyp=record
 sx,sy:integer;
 arr:array of word;
end;
//############################################################################//
mapsdbtyp=record
 name:string;
 blockfile:string;

 rpallette:pbytea;
 rpal:pbytea;
 pass:pbytea;
 coast:pinta;

 coast_len:integer;

 land_min_tile,land_tiles_len,water_min_tile,water_tiles_len:integer;
 obs:array of obstyp;
end;
//############################################################################//
const
desert_rpal:array[0..7]of byte=(104,109,77,72,143,226,230,148);
desert_pal:array[0..767]of byte=(0,0,108,105,72,84,143,226,230,148,0,0,255,255,0,255,171,0,131,131,163,255,71,0,255,255,147,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,131,187,27,111,171,15,95,159,11,79,147,7,67,119,7,51,95,7,39,67,7,27,43,7,187,187,7,179,135,7,171,87,7,163,47,7,0,0,0,103,7,123,123,55,7,147,187,15,107,159,187,71,135,171,47,115,151,23,99,135,15,79,111,11,59,87,7,43,67,7,27,43,187,123,87,175,99,55,163,79,27,151,59,7,123,47,7,99,39,7,71,27,7,39,15,7,223,119,51,207,115,51,219,107,47,207,107,47,199,107,51,191,107,51,191,107,43,199,99,51,199,103,43,191,99,51,191,99,43,183,99,51,183,99,43,175,99,43,195,91,43,183,91,43,175,91,51,175,91,43,167,91,43,183,83,39,175,79,39,167,83,43,167,83,35,159,83,43,159,83,35,147,83,43,167,75,35,159,75,43,159,75,35,147,75,43,151,75,35,159,67,35,123,139,191,119,139,187,123,139,191,123,143,195,127,147,199,131,151,203,123,143,195,119,131,183,119,135,187,123,139,191,123,143,195,127,147,199,131,151,203,123,143,195,111,127,163,107,119,147,111,127,163,115,131,179,119,139,195,123,143,211,115,131,179,175,91,43,135,155,95,131,151,199,103,163,159,183,143,75,175,91,43,163,163,203,143,143,187,123,131,175,131,139,183,139,151,191,231,199,139,235,195,131,239,195,123,243,191,115,247,191,107,251,187,99,255,183,91,243,179,95,235,175,99,223,171,103,211,167,103,203,159,107,191,155,107,183,151,107,171,143,107,163,139,107,147,123,91,135,107,75,123,95,63,111,83,51,99,71,43,79,75,71,71,75,75,107,55,11,55,63,75,15,79,107,75,59,39,79,43,11,47,39,35,55,31,11,39,23,7,23,15,0,255,251,247,243,223,211,243,219,187,223,199,175,223,195,155,219,183,143,199,167,127,183,163,131,171,155,123,159,151,139,175,167,147,191,171,151,199,187,175,207,163,107,191,155,103,171,139,95,163,139,107,155,135,99,147,135,115,131,127,119,123,115,103,131,115,91,139,123,99,147,119,83,159,127,75,171,131,75,179,139,83,195,147,83,199,139,67,179,127,59,167,115,55,147,111,59,131,107,59,123,99,71,115,99,59,115,87,43,103,83,47,91,79,59,83,71,51,83,63,43,75,59,39,67,59,43,59,51,39,51,43,31,43,39,35,39,35,31,31,27,23,15,15,15,55,31,31,47,43,43,55,51,51,63,59,59,75,71,71,87,83,83,95,91,91,103,99,99,111,107,107,115,103,83,107,95,75,99,87,67,87,67,35,75,43,43,47,43,59,131,99,43,131,107,75,207,131,107,171,111,91,187,83,55,123,79,67,155,63,47,115,39,35,75,31,23,31,15,15,139,171,99,115,147,79,87,147,59,95,115,67,67,107,47,59,83,35,43,67,27,23,27,15,119,111,159,99,87,131,59,67,139,67,67,107,47,51,107,67,59,79,31,35,75,15,19,43,183,103,0,135,75,0,91,51,0,155,155,0,111,111,0,67,67,0,255,255,255);
green_rpal:array[0..7]of byte=(100,99,72,79,217,110,238,237);
green_pal:array[0..767]of byte=(0,0,0,255,0,0,215,7,255,215,7,255,255,255,0,255,171,0,131,131,163,255,71,0,255,255,147,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,215,7,255,131,187,27,111,171,15,95,159,11,79,147,7,67,119,7,51,95,7,39,67,7,27,43,7,187,187,7,179,135,7,171,87,7,163,47,7,0,0,0,103,7,123,123,55,7,147,187,15,107,159,187,71,135,171,47,115,151,23,99,135,15,79,111,11,59,87,7,43,67,7,27,43,187,123,87,175,99,55,163,79,27,151,59,7,123,47,7,99,39,7,71,27,7,39,15,7,103,151,55,91,151,51,91,143,59,91,143,51,87,143,43,83,143,51,91,135,51,91,135,43,83,135,51,87,131,59,83,135,43,75,135,43,83,123,51,83,123,43,75,123,51,75,123,43,75,119,35,75,115,51,75,115,43,67,115,43,67,115,35,67,107,43,67,107,35,59,103,35,187,215,243,183,207,231,175,207,235,175,199,231,175,199,223,167,199,223,167,191,223,167,191,215,175,139,191,175,139,191,175,143,195,179,143,195,179,147,199,183,151,203,179,143,195,171,131,183,171,135,187,175,139,191,175,143,195,179,147,199,183,151,203,175,143,195,163,127,163,159,119,147,163,127,163,171,131,179,175,139,195,175,143,211,171,131,179,139,87,43,183,115,123,179,147,199,183,127,123,159,99,83,139,87,43,191,159,211,183,147,199,175,139,191,171,135,187,183,147,199,231,199,139,235,195,131,239,195,123,243,191,115,247,191,107,251,187,99,255,183,91,243,179,95,235,175,99,223,171,103,211,167,103,203,159,107,191,155,107,183,151,107,171,143,107,163,139,107,147,123,91,135,107,75,123,95,63,111,83,51,99,71,43,79,75,71,71,75,75,107,55,11,55,63,75,15,79,107,75,59,39,79,43,11,47,39,35,55,31,11,39,23,7,23,15,0,255,251,247,243,223,211,243,219,187,223,199,175,223,195,155,219,183,143,199,167,127,183,163,131,171,155,123,159,151,139,175,167,147,191,171,151,199,187,175,207,163,107,191,155,103,171,139,95,163,139,107,155,135,99,147,135,115,131,127,119,123,115,103,131,115,91,139,123,99,147,119,83,159,127,75,171,131,75,179,139,83,195,147,83,199,139,67,179,127,59,167,115,55,147,111,59,131,107,59,123,99,71,115,99,59,115,87,43,103,83,47,91,79,59,83,71,51,83,63,43,75,59,39,67,59,43,59,51,39,51,43,31,43,39,35,39,35,31,31,27,23,15,15,15,55,31,31,47,43,43,55,51,51,63,59,59,75,71,71,87,83,83,95,91,91,103,99,99,111,107,107,115,103,83,107,95,75,99,87,67,87,67,35,75,43,43,47,43,59,131,99,43,131,107,75,207,131,107,171,111,91,187,83,55,123,79,67,155,63,47,115,39,35,75,31,23,31,15,15,139,171,99,115,147,79,87,147,59,95,115,67,67,107,47,59,83,35,43,67,27,23,27,15,119,111,159,99,87,131,59,67,139,67,67,107,47,51,107,67,59,79,31,35,75,15,19,43,183,103,0,135,75,0,91,51,0,155,155,0,111,111,0,67,67,0,255,255,255);

desert_pass:array[0..376-1]of byte=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,2,2,0,1,1,0,0,2,0,0,2,1,0,0,1,1,1,0,1,1,1,2,0,2,2,2,2,0,2,2,2,0,2,2,0,0,2,0,0,0,0,0,0,0,0,0,0,0,2,0,2,2,0,2,2,2,2,2,2,0,2,2,2,0,0,2,0,0,2,2,2,0,0,0,0,0,0,2,2,2,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,3,0,3,3,3,3,3,3,3,3,0,3,3,3,3,0,3,3,0,3,0,3,3,3,3,0,3,3,3,3,3,3,3,3,0,3,3,3,0,3,3,3,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,3,0,3,3,3,3,3,3,3,3,0,0,3,3,3,0,3,3,3,0,3,3,3,0,0,0,0,3,3,0,3,3,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,3,3,0,3,3,0,3,3,3,0,3,0,3,3,3,3,0,3,3,3,3,3,3,0,3,3,3,3,3,3,3,0,0,0,3,3,3,3);
green_pass:array[0..220-1]of byte=(1,1,1,1,1,1,1,1,1,2,2,2,2,0,2,2,0,0,0,0,0,2,2,0,0,0,0,0,0,2,2,2,2,2,0,0,2,0,0,2,0,2,2,0,2,2,0,0,2,2,2,0,2,0,2,0,2,0,2,2,0,2,0,0,2,2,2,2,0,2,2,0,2,0,2,0,0,0,2,0,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,3,3,3,3,0,3,3,0,3,3,3,3,3,3,3,3,3,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,3,3,0,0,3,3,0,0,0,0,3,3,0,3,3,0,0,0,3,3,3,0,3,3,0,0,0,3,0,3,0,0,0,0,3,3,3,0,3,3,3,3,0,0,3,0,3,0,0,0,3,0,0,0,3,3,0,3,0,3,0,0,3,0);

//Coasts
desert_coast:array[0..49]of array[0..3]of integer=((2,1,1,80),(2,1,4,81),(2,1,32,90),(2,1,128,38),(2,1,5,78),(2,1,33,137),(2,1,132,105),(2,1,160,46),(3,2,2,101),(3,2,3,48),(3,2,6,51),(3,2,7,95),(3,2,8,106),(3,2,9,69),(3,2,10,39),(3,2,11,62),(3,2,14,41),(3,2,15,41),(3,2,16,136),(3,2,19,89),(3,2,20,103),(3,2,22,92),(3,2,23,89),(3,2,40,96),(3,2,41,166),(3,2,42,39),(3,2,43,39),(3,2,47,64),(3,2,64,111),(3,2,72,94),(3,2,80,67),(3,2,84,66),(3,2,96,110),(3,2,104,94),(3,2,105,91),(3,2,131,48),(3,2,137,69),(3,2,139,62),(3,2,144,65),(3,2,148,73),(3,2,150,102),(3,2,151,97),(3,2,192,77),(3,2,208,67),(3,2,209,67),(3,2,212,66),(3,2,224,120),(3,2,232,109),(3,2,233,109),(3,2,240,71));
green_coast :array[0..131]of array[0..3]of integer=((2,1,1,53),(2,1,4,20),(2,1,128,40),(2,1,32,46),(2,1,5,13),(2,1,132,57),(2,1,33,62),(2,1,160,126),(2,2,244,53),(2,2,233,51),(2,2,47,40),(2,2,151,46),(2,2,212,53),(2,2,240,53),(2,2,232,20),(2,2,105,20),(2,2,43,40),(2,2,15,40),(2,2,22,46),(2,2,149,46),(2,2,224,13),(2,2,41,57),(2,2,7,126),(2,2,148,62),(2,2,150,60),(2,2,23,46),(2,2,6,126),(2,2,3,126),(2,2,104,20),(2,2,208,53),(2,2,21,71),(2,2,11,47),(2,2,144,62),(2,2,20,62),(2,2,9,57),(2,2,40,57),(2,2,145,71),(2,2,137,55),(2,2,192,13),(2,2,96,13),(2,2,84,34),(2,2,147,20),(2,2,201,51),(2,2,200,51),(2,2,116,34),(2,2,42,47),(2,2,146,71),(2,2,147,71),(2,2,46,63),(2,2,116,34),(2,2,16,62),(2,2,8,57),(2,2,14,47),(2,2,112,53),(2,2,72,51),(2,2,68,53),(2,2,2,126),(2,2,64,13),(2,2,48,34),(2,2,19,60),(2,2,10,47),(2,2,52,53),(2,2,130,71),(2,2,193,55),(2,2,100,53),(2,2,80,53),(3,2,104,14),(3,2,11,41),(3,2,22,45),(3,2,208,10),(3,2,72,14),(3,2,10,41),(3,2,18,45),(3,2,80,10),(3,2,240,12),(3,2,112,12),(3,2,232,11),(3,2,200,11),(3,2,212,33),(3,2,84,33),(3,2,150,36),(3,2,105,42),(3,2,43,44),(3,2,15,64),(3,2,146,36),(3,2,73,42),(3,2,42,44),(3,2,14,64),(3,2,19,65),(3,2,23,65),(3,2,192,21),(3,2,144,15),(3,2,40,29),(3,2,96,32),(3,2,9,48),(3,2,6,49),(3,2,20,59),(3,2,3,50),(3,2,224,80),(3,2,7,72),(3,2,148,78),(3,2,41,56),(3,2,64,9),(3,2,8,58),(3,2,16,61),(3,2,2,74),(3,2,244,22),(3,2,151,67),(3,2,233,70),(3,2,47,69),(3,2,31,151),(3,2,107,152),(3,2,214,43),(3,2,248,77),(3,2,46,69),(3,2,116,22),(3,2,147,67),(3,2,201,70),(3,2,108,14),(3,2,139,41),(3,2,54,45),(3,2,209,10),(3,2,131,5),(3,2,38,49),(3,2,193,21),(3,2,100,32),(3,2,44,29),(3,2,13,48),(3,2,145,15),(3,2,38,49),(3,2,131,50),(3,2,137,48));

//landcorr. Should be separate for green?
coast_fills:array[0..93]of byte=(1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2);
coast_types:array[0..93]of byte=(1,4,128,32,5,132,160,33,36,129,255,248,214,107,31,255,165,90,191,253,247,239,254,251,223,127,252,249,215,246,63,159,111,235,124,217,211,118,62,155,110,203,66,24,151,47,233,244,130,34,136,12,65,68,17,48,126,120,30,27,119,243,238,207,220,158,59,121,87,79,234,242,216,71,226,195,194,98,67,100,86,25,56,28,152,29,153,60,184,106,102,219,187,221);
//############################################################################//
var          
mapsdb:array of mapsdbtyp;

bigmap:array of word;
minimap:array of byte;
minimaprev:array of byte;

sizx,sizy,island_cnt,lake_cnt,island_size,lake_size,obstacle_cnt:integer;
edginess:double;
cur_map:integer;      
seed:integer;
map_name:string;
//############################################################################// 
procedure mapgen_init;
procedure mapgen_makemap; 
procedure mapgen_wrlasm(mpath,oud:string);
//############################################################################//
implementation
//############################################################################//
function calccoast(x,y,c:integer):integer;
var co:integer;                                  //    1  2  4
begin                                            //    8  X 16
 co:=0;                                          //   32 64 128
 if (y<sizy+1)and(y>=1)and(x<sizx+1)and(x>=1) then if (minimap[(y-1)*sizx+(x-1)]=c) then co:=co+1;
 if (y<sizy+1)and(y>=1)and(x<sizx)and(x>=0) then if (minimap[(y-1)*sizx+(x)]=c) then co:=co+2;
 if (y<sizy+1)and(y>=1)and(x<sizx-1)and(x>=-1) then if (minimap[(y-1)*sizx+(x+1)]=c) then co:=co+4;
 if (y<sizy)and(y>=0)and(x<sizx+1)and(x>=1) then if (minimap[(y)*sizx+(x-1)]=c) then co:=co+8;
 if (y<sizy)and(y>=0)and(x<sizx-1)and(x>=-1) then if (minimap[(y)*sizx+(x+1)]=c)then co:=co+16;
 if (y<sizy-1)and(y>=-1)and(x<sizx+1)and(x>=1) then if (minimap[(y+1)*sizx+(x-1)]=c) then co:=co+32;
 if (y<sizy-1)and(y>=-1)and(x<sizx)and(x>=0) then if (minimap[(y+1)*sizx+(x)]=c) then co:=co+64;
 if (y<sizy-1)and(y>=-1)and(x<sizx-1)and(x>=-1) then if (minimap[(y+1)*sizx+(x+1)]=c) then co:=co+128;
 calccoast:=co;
end;
//############################################################################//
procedure makecoast;
var x,y,i:integer;
begin
 with mapsdb[cur_map] do for y:=0 to sizy-1 do for x:=0 to sizx-1 do begin
  for i:=0 to coast_len-1 do if minimap[y*sizx+x]=coast[i*4+0] then if calccoast(x,y,coast[i*4+1])=coast[i*4+2] then bigmap[y*sizx+x]:=coast[i*4+3];
 end;
end;
//############################################################################//
procedure makemmap;
var x,y:integer;
begin
 for y:=0 to sizy-1 do for x:=0 to sizx-1 do begin
  if minimap[y*sizx+x]=1 then minimap[y*sizx+x]:=mapsdb[cur_map].rpal[0+random(2)];
  if minimap[y*sizx+x]=2 then minimap[y*sizx+x]:=mapsdb[cur_map].rpal[2+random(2)];
  if minimap[y*sizx+x]=3 then minimap[y*sizx+x]:=mapsdb[cur_map].rpal[4+random(2)];
  if minimap[y*sizx+x]=4 then minimap[y*sizx+x]:=mapsdb[cur_map].rpal[6+random(2)];
 end;
end;
//############################################################################//
procedure fillcr(x,y,c:integer);
var a:integer;
begin
 if minimaprev[y*sizx+x]<>c then begin
  a:=minimaprev[y*sizx+x];
  minimaprev[y*sizx+x]:=c;
  if (y<sizy)and(y>=0)and(x<sizx-1)and(x>=-1) then  if minimaprev[(y)*sizx+(x+1)]=a  then if (y<sizy)and(y>=0)and(x<sizx-1)and(x>=-1) then fillcr(x+1,y,c);
  if (y<sizy-1)and(y>=-1)and(x<sizx)and(x>=0) then  if minimaprev[(y+1)*sizx+(x)]=a  then fillcr(x,y+1,c);
  if (y<sizy)and(y>=0)and(x<sizx+1)and(x>=1) then  if minimaprev[(y)*sizx+(x-1)]=a  then fillcr(x-1,y,c);
  if (y<sizy+1)and(y>=1)and(x<sizx)and(x>=0) then  if minimaprev[(y-1)*sizx+(x)]=a  then fillcr(x,y-1,c);
 end;
end;
//############################################################################//
procedure mline(xa,ya,xb,yb,c:integer);
var xinc,yinc,dx,dy,di,cx,cy:integer;
begin
 dx:=xb-xa;
 if dx<0 then begin xinc:=1; dx:=-dx end else xinc:=-1;
 dy:=yb-ya;
 if dy<0 then begin yinc:=1; dy:=-dy end else yinc:=-1;
 dx:=dx*2;
 dy:=dy*2;
 if (yb<sizy)and(yb>=0)and(xb<sizx)and(xb>=0) then minimaprev[yb*sizx+xb]:=c;
 cx:=xb;
 cy:=yb;

 if dx=0 then repeat
  if cy=ya then begin if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c; exit; end;
  cy:=cy+yinc;
  if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
 until false;

 if dy=0 then repeat
  if cx=xa then begin if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c; exit; end;
  cx:=cx+xinc;
  if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
 until false;

 if dx>dy then begin
  di:=dy-(dx div 2);
  repeat
   if cx=xa then begin if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c; exit; end;
   if di>0 then begin
    cx:=cx+xinc;
    di:=di-dy;
    if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
   end else begin
    cy:=cy+yinc;
    di:=di+dx;
    cx:=cx+xinc;
    di:=di-dy;
    if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
   end;
  until false;
 end;

 if dx<dy then begin
  di:=dx-(dy div 2);
  repeat
   if cy=ya then begin if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c; exit; end;
   if di>0 then begin
    cy:=cy+yinc;
    di:=di-dx;
    if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
   end else begin
    cx:=cx+xinc;
    di:=di+dy;
    cy:=cy+yinc;
    di:=di-dx;
    if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
   end;
  until false;
 end;

 if dx=dy then repeat
  if cx=xa then begin if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c; exit; end;
  cy:=cy+yinc;
  cx:=cx+xinc;
  if (cy<sizy)and(cy>=0)and(cx<sizx)and(cx>=0) then minimaprev[cy*sizx+cx]:=c;
 until false;
end;
//############################################################################//
procedure onmmap(c:integer);
var x,y:integer;
begin
 for y:=0 to sizy-1 do for x:=0 to sizx-1 do begin
  if minimaprev[y*sizx+x]=c then minimap[y*sizx+x]:=c;
  minimaprev[y*sizx+x]:=0;
 end;
end;
//############################################################################//
procedure setmap;
var i:integer;
begin
 for i:=0 to sizx*sizy-1 do if minimap[i]=2 then bigmap[i]:=random(mapsdb[cur_map].land_tiles_len)+mapsdb[cur_map].land_min_tile;
 for i:=0 to sizx*sizy-1 do if minimap[i]=1 then bigmap[i]:=random(mapsdb[cur_map].water_tiles_len)+mapsdb[cur_map].water_min_tile;
end;
//############################################################################//
procedure genmap;
var x,y,r,xa,ya:integer;
x1,y1,x0,y0,p,phi,xb,yb:single;
i,j,i1:integer;
aaa,fail,chflg:boolean;
begin
 for i:=0 to island_cnt-1 do begin
  x:=random(sizx);
  y:=random(sizy);
  r:=island_size;
  x1:=island_size;
  y1:=0;
  xb:=0;
  yb:=0;
  aaa:=true;
  for i1:=0 to island_size do begin
   p:=r*(1+edginess*2*((random(10)/10)-0.5));
   phi:=(pi/180)*i1*(360/island_size);
   x0:=x1;
   y0:=y1;
   x1:=p*cos(phi);
   y1:=p*sin(phi);
   if aaa then begin x0:=x1;y0:=y1;xb:=x0;yb:=y0;aaa:=false;end;
   if i1=island_size then begin x1:=xb;y1:=yb;end;
   mline(x+trunc(x0),y+trunc(y0),x+trunc(x1),y+trunc(y1),2);
  end;
  fillcr(x,y,2);
  onmmap(2);
 end;

 for i:=0 to lake_cnt-1 do begin
  x:=random(sizx);
  y:=random(sizy);
  r:=lake_size;
  x1:=lake_size;
  y1:=0;
  xb:=0;
  yb:=0;
  aaa:=true;
  for i1:=0 to (lake_size+4) do begin
   p:=r*(1+edginess*2*((random(10)/10)-0.5));
   phi:=(pi/180)*i1*(360/(lake_size+4));
   x0:=x1;
   y0:=y1;
   x1:=p*cos(phi);
   y1:=p*sin(phi);
   if aaa then begin x0:=x1;y0:=y1;xb:=x0;yb:=y0;aaa:=false;end;
   if i1=(lake_size+4) then begin x1:=xb;y1:=yb;end;
   mline(x+trunc(x0),y+trunc(y0),x+trunc(x1),y+trunc(y1),1);
  end;
  fillcr(x,y,1);
  onmmap(1);
 end;

 repeat
  chflg:=false;
  with mapsdb[cur_map] do for y:=0 to sizy-1 do for x:=0 to sizx-1 do if (minimap[y*sizx+x]=1) and (calccoast(x,y,2)<>0) then begin
   for i:=0 to length(coast_types)-1 do if calccoast(x,y,2)=coast_types[i] then begin
    minimap[y*sizx+x]:=coast_fills[i];
    if coast_fills[i]=2 then chflg:=true;
   end;
  end;
 until not chflg;

 for y:=0 to sizy-1 do for x:=0 to sizx-1 do if (minimap[y*sizx+x]=1) and (calccoast(x,y,2)<>0) then minimap[y*sizx+x]:=3;

 setmap;
 makecoast;
 for i:=0 to sizx*sizy-1 do if (minimap[i]=3)and(bigmap[i]=0) then bigmap[i]:=random(mapsdb[cur_map].water_tiles_len)+mapsdb[cur_map].water_min_tile;

 for i:=0 to obstacle_cnt-1 do begin
  x:=random(sizx);
  y:=random(sizy);
  if y<1 then y:=1;
  if x<1 then x:=1;
  if y>sizy-5 then y:=sizy-5;
  if x>sizx-5 then x:=sizx-5;
  j:=random(length(mapsdb[cur_map].obs));
  fail:=false;
  with mapsdb[cur_map].obs[j] do begin
   for xa:=x to x+sx-1 do for ya:=y to y+sy-1 do if minimap[ya*sizx+xa]<>2 then fail:=true;
   if not fail then begin
    for xa:=x to x+sx-1 do for ya:=y to y+sy-1 do minimap[ya*sizx+xa]:=4;
    i1:=0;
    for ya:=y to y+sy-1 do for xa:=x to x+sx-1 do begin
     bigmap[ya*sizx+xa]:=arr[i1];
     i1:=i1+1;
    end;
   end;
  end;
 end;
 makemmap;
end;
//############################################################################//
procedure mapgen_wrlasm(mpath,oud:string);
var zag:array[0..4]of byte;
size:array[0..1]of word;
elen:word;
mapsiz:integer;
f:file;

ebitmaps:array of byte;
begin
 zag[0]:=ord('W');
 zag[1]:=ord('R');
 zag[2]:=ord('L');
 zag[3]:=1;
 zag[4]:=0;

 size[0]:=sizx;
 size[1]:=sizy;
 mapsiz:=size[0]*size[1];

 assignfile(f,ce_curdir+mpath+mapsdb[cur_map].blockfile);
 reset(f,1);
 blockread(f,elen{%H-},2);
 setlength(ebitmaps,elen*4096);
 blockread(f,ebitmaps[0],elen*4096);
 closefile(f);

 assignfile(f,ce_curdir+oud);
 rewrite(f,1);
 blockwrite(f,zag,5);
 blockwrite(f,size,4);
 blockwrite(f,minimap[0],mapsiz);
 blockwrite(f,bigmap[0],mapsiz*2);
 blockwrite(f,elen,2);
 blockwrite(f,ebitmaps[0],4096*elen);
 blockwrite(f,mapsdb[cur_map].rpallette[0],768);
 blockwrite(f,mapsdb[cur_map].pass[0],elen);
 close(f);
end;
//############################################################################//
procedure add_obstacle(mc:integer;xs,ys:integer;s:string);
var n,i,k:integer;
begin
 n:=length(mapsdb[mc].obs);  
 setlength(mapsdb[mc].obs,n+1);

 mapsdb[mc].obs[n].sx:=xs;
 mapsdb[mc].obs[n].sy:=ys;
 setlength(mapsdb[mc].obs[n].arr,xs*ys);

 for i:=0 to xs*ys-1 do begin
  k:=getfsymp(s,',');
  if k=0 then k:=length(s)+1;
  mapsdb[mc].obs[n].arr[i]:=vali(copy(s,1,k-1));
  s:=copy(s,k+1,length(s));
 end;
end;
//############################################################################//
procedure set_maps_db;
begin   
 setlength(mapsdb,2);
 mapsdb[0].name:='Desert';  
 mapsdb[0].blockfile:='desert.tiles';
 mapsdb[0].land_min_tile:=0;
 mapsdb[0].land_tiles_len:=30;
 mapsdb[0].water_min_tile:=55;
 mapsdb[0].water_tiles_len:=3;
              
 mapsdb[0].rpal:=@desert_rpal[0];
 mapsdb[0].rpallette:=@desert_pal[0];
 mapsdb[0].pass:=@desert_pass[0];
 mapsdb[0].coast:=@desert_coast[0][0];
 mapsdb[0].coast_len:=length(desert_coast);

 mapsdb[1].name:='Green';
 mapsdb[1].blockfile:='green.tiles';
 mapsdb[1].land_min_tile:=23;
 mapsdb[1].land_tiles_len:=5;
 mapsdb[1].water_min_tile:=0;
 mapsdb[1].water_tiles_len:=8;

 mapsdb[1].rpal:=@green_rpal[0];
 mapsdb[1].rpallette:=@green_pal[0];
 mapsdb[1].pass:=@green_pass[0];   
 mapsdb[1].coast:=@green_coast[0][0];
 mapsdb[1].coast_len:=length(green_coast);

 add_obstacle(0,1,1,'206');
 add_obstacle(0,1,1,'329');
 add_obstacle(0,1,1,'326');
 add_obstacle(0,1,1,'355');
 add_obstacle(0,1,1,'375');
 add_obstacle(0,1,1,'374');
 add_obstacle(0,1,1,'58');
 add_obstacle(0,1,1,'75');
 add_obstacle(0,1,1,'34');
 add_obstacle(0,1,1,'36');
 add_obstacle(0,1,1,'161');
 add_obstacle(0,2,1,'327,328');
 add_obstacle(0,2,1,'187,188');
 add_obstacle(0,2,1,'315,316');
 add_obstacle(0,1,2,'372,373');
 add_obstacle(0,1,2,'356,357');
 add_obstacle(0,1,2,'339,338');
 add_obstacle(0,2,2,'351,352,353,354');
 add_obstacle(0,2,2,'49,50,53,54');
 add_obstacle(0,2,2,'340,0,341,342');
 add_obstacle(0,3,2,'358,359,360,0,361,362');
 add_obstacle(0,3,2,'154,155,156,157,158,159');
 add_obstacle(0,2,3,'170,171,172,173,174,175');
 add_obstacle(0,3,3,'82,83,84,85,86,0,87,88,80');
 add_obstacle(0,3,3,'127,128,129,130,131,132,134,135,0');
 add_obstacle(0,3,3,'363,364,365,366,367,368,369,370,371');
 add_obstacle(0,3,3,'306,307,308,309,310,311,312,313,314');
 add_obstacle(0,3,3,'0,335,336,0,330,331,332,333,334');
 add_obstacle(0,4,4,'222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237');
 add_obstacle(0,5,3,'208,209,210,211,0,213,214,215,216,217,0,218,219,220,221');

 add_obstacle(1,1,1,'123');
 add_obstacle(1,1,1,'83');
 add_obstacle(1,1,1,'84');
 add_obstacle(1,1,1,'85');
 add_obstacle(1,1,1,'174');
 add_obstacle(1,1,1,'175');
 add_obstacle(1,2,1,'176,177');
 add_obstacle(1,2,1,'183,184');
 add_obstacle(1,2,1,'213,214');
 add_obstacle(1,2,1,'200,201');
 add_obstacle(1,2,1,'114,115');
 add_obstacle(1,2,2,'185,186,187,188');
 add_obstacle(1,2,2,'202,203,204,205');
 add_obstacle(1,2,2,'117,118,124,125');
 add_obstacle(1,3,2,'128,129,130,132,133,134');
 add_obstacle(1,3,3,'196,179,180,197,181,182,198,175,199');
 add_obstacle(1,3,3,'86,87,88,89,90,91,92,93,23');
 add_obstacle(1,5,4,'94,95,96,23,23,97,98,99,100,101,102,103,104,105,106,23,107,108,109,110');
end;    
//############################################################################//
procedure mapgen_makemap;
var i:integer;
begin         
 randseed:=seed;

 if island_cnt>200 then island_cnt:=200;
 if lake_cnt>200 then lake_cnt:=200;
 if obstacle_cnt>1000 then obstacle_cnt:=1000;
 if island_size>200 then island_size:=200;
 if lake_size>200 then lake_size:=200;
 if cur_map>1 then cur_map:=1;

 setlength(bigmap,0);
 setlength(minimap,0);
 setlength(minimaprev,0);

 setlength(bigmap,sizx*sizy+1);
 setlength(minimap,sizx*sizy+1);
 setlength(minimaprev,sizx*sizy+1);
 for i:=0 to sizx*sizy-1 do bigmap[i]:=0;
 for i:=0 to sizx*sizy-1 do minimap[i]:=1;
 for i:=0 to sizx*sizy-1 do minimaprev[i]:=1;

 genmap;
end;
//############################################################################//
procedure mapgen_init;
begin
 map_name:='random';
 sizx:=112;
 sizy:=112; 
 cur_map:=0;
 randomize;
 seed:=random(65535);   

 island_cnt:=25;
 lake_cnt:=13;
 island_size:=10;
 lake_size:=4;
 obstacle_cnt:=100;

 edginess:=0.3;

 set_maps_db;
end;       
//############################################################################//
begin
end.
//############################################################################//

