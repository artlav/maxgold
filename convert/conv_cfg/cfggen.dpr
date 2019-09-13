//############################################################################//
program cfggen;
uses sysutils,strutils,strval,strtool,asys,filef,parser,grph,maths,sdigrtools,imglib,png,bmp;
{$ifdef mswindows}{$apptype console}{$endif}
//############################################################################//
type
typsnds=record
 nam:string;
 len,skip:double;
end;

typeunitsdb=record
 typ:string;
 i_size:integer;

 img_poster,img_depot:string;
 spr_base,spr_list,spr_shadow:string;
 video:string;

 base_frames,active_frames:vec;
 water_base_frames,water_active_frames:vec;
 animation_frames,firing_base_frames,connector_frames,gun_frames,firing_gun_frames:vec;

 active_snd,water_active_snd,boom_snd,stop_snd,start_snd,fire_snd:typsnds;
end;
ptypeunitsdb=^typeunitsdb;
//############################################################################//
procedure proc_snd_par(var snd:typsnds;s:string);
var k:integer;
begin
 snd.len:=0;
 snd.skip:=0;
 snd.nam:=s;
 k:=getfsymp(s,',');

 if k<>0 then begin
  snd.nam:=copy(s,1,k-1);
  s:=copy(s,k+1,length(s));
  k:=getfsymp(s,',');
  if k=0 then begin
   snd.skip:=vale(s);
  end else begin
   snd.skip:=vale(copy(s,1,k-1));
   snd.len:=vale(copy(s,k+1,length(s)));
  end;
 end;
end;
//############################################################################//
function posvec_to_json(v:vec):string;
begin
 result:='['+stre(v.x)+','+stre(v.y)+','+stre(v.z)+']';
end;
//############################################################################//
function snds_to_json(v:typsnds):string;
begin
 result:='{"name":"'+v.nam+'"';
 if v.len<>0 then result:=result+',"len":"'+stre(v.len)+'"';
 if v.skip<>0 then result:=result+',"skip":"'+stre(v.skip)+'"';
 result:=result+'}';
end; 
//############################################################################//
function proc_one_eunitsdb(fn:string):string;
var eud:typeunitsdb;
i,k:integer;
psr:preca;
st:string;
begin
 psr:=nil;
 fillchar(eud,sizeof(eud),0);

 eud.i_size:=1;

 eud.base_frames        :=tvec( 0 ,0,2);
 eud.active_frames      :=tvec(-1,-1,2);
 eud.water_base_frames  :=tvec( 0 ,0,2);
 eud.water_active_frames:=tvec(-1,-1,2);
 eud.animation_frames   :=tvec(-1,-1,2);
 eud.firing_base_frames :=tvec(-1,-1,2);
 eud.connector_frames   :=tvec(-1,-1,2);
 eud.gun_frames         :=tvec(-1,-1,2);
 eud.firing_gun_frames  :=tvec(-1,-1,2);

 psr:=parsecfg(fn,false,'=');
 for i:=0 to length(psr)-1 do with psr[i] do begin
  if copy(props,length(props)-3,4)='.png' then props:=copy(props,1,length(props)-4);
  if par='type'                then begin eud.typ:=lowercase(props);continue;end;
  if par='base_frames'         then begin eud.base_frames        :=propv; continue; end;
  if par='active_frames'       then begin eud.active_frames      :=propv; continue; end;
  if par='water_base_frames'   then begin eud.water_base_frames  :=propv; continue; end;
  if par='water_active_frames' then begin eud.water_active_frames:=propv; continue; end;
  if par='animation_frames'    then begin eud.animation_frames   :=propv; continue; end;
  if par='firing_base_frames'  then begin eud.firing_base_frames :=propv; continue; end;
  if par='connector_frames'    then begin eud.connector_frames   :=propv; continue; end;
  if par='gun_frames'          then begin eud.gun_frames         :=propv; continue; end;
  if par='firing_gun_frames'   then begin eud.firing_gun_frames  :=propv; continue; end;

  if par='spr_base'   then begin eud.spr_base:=props;continue;end;
  if par='spr_shadow' then begin eud.spr_shadow:=props;continue;end;
  if par='spr_list'   then begin
   k:=vali(copy(props,length(props),1));
   eud.i_size:=k;
   if copy(props,1,length(props)-2)<>'' then eud.spr_list:=copy(props,1,length(props)-2);
   continue;
  end;

  if par='img_poster' then begin eud.img_poster:=props;continue;end;
  if par='img_depot'  then begin eud.img_depot:=props;continue;end;
  if par='video'      then begin eud.video:=props;continue;end;

  if par='active_snd'       then begin proc_snd_par(eud.active_snd,props);continue;end;
  if par='water_active_snd' then begin proc_snd_par(eud.water_active_snd,props);continue;end;
  if par='boom_snd'         then begin proc_snd_par(eud.boom_snd,props);continue;end;
  if par='fire_snd'         then begin proc_snd_par(eud.fire_snd,props);continue;end;
  if par='stop_snd'         then begin proc_snd_par(eud.stop_snd,props);continue;end;
  if par='start_snd'        then begin proc_snd_par(eud.start_snd,props);continue;end;
 end;

 st:=trimsr('{"type":"'+eud.typ+'",',22,' ');
 if eud.spr_list<>''   then st:=st+trimsr('"i_size":'+stri(eud.i_size)+',',11,' ') else st:=st+trimsr('',11,' ');
 st:=st+trimsr('"spr_base":"'+eud.spr_base+'",',24,' ');
 if eud.spr_shadow<>'' then st:=st+trimsr('"spr_shadow":"'+eud.spr_shadow+'",',26,' ') else st:=st+trimsr('',26,' ');
 if eud.spr_list<>''   then st:=st+trimsr('"spr_list":"'+eud.spr_list+'",'    ,24,' ') else st:=st+trimsr('',24,' ');
 if eud.img_poster<>'' then st:=st+trimsr('"img_poster":"'+eud.img_poster+'",',26,' ') else st:=st+trimsr('',26,' ');
 if eud.img_depot<>''  then st:=st+trimsr('"img_depot":"'+eud.img_depot+'",'  ,24,' ') else st:=st+trimsr('',24,' ');
 if eud.video<>''      then st:=st+trimsr('"video":"'+eud.video+'",'          ,21,' ') else st:=st+trimsr('',21,' ');

 if not((eud.base_frames.x=0)and(eud.base_frames.y=0)and(eud.base_frames.z=2)) then st:=st+'"base_frames":'+posvec_to_json(eud.base_frames)+',';
 if not((eud.water_base_frames.x=0)and(eud.water_base_frames.y=0)and(eud.water_base_frames.z=2)) then st:=st+'"water_base_frames":'+posvec_to_json(eud.water_base_frames)+',';
 if eud.active_frames.x<>-1       then st:=st+'"active_frames":'+posvec_to_json(eud.active_frames)+',';
 if eud.water_active_frames.x<>-1 then st:=st+'"water_active_frames":'+posvec_to_json(eud.water_active_frames)+',';
 if eud.animation_frames.x<>-1    then st:=st+'"animation_frames":'+posvec_to_json(eud.animation_frames)+',';
 if eud.firing_base_frames.x<>-1  then st:=st+'"firing_base_frames":'+posvec_to_json(eud.firing_base_frames)+',';
 if eud.connector_frames.x<>-1    then st:=st+'"connector_frames":'+posvec_to_json(eud.connector_frames)+',';
 if eud.firing_gun_frames.x<>-1   then st:=st+'"gun_frames":'+posvec_to_json(eud.gun_frames)+',';
 if eud.firing_gun_frames.x<>-1   then st:=st+'"firing_gun_frames":'+posvec_to_json(eud.firing_gun_frames)+',';

 if eud.active_snd.nam<>'' then st:=st+'"active_snd":'+snds_to_json(eud.active_snd)+',';
 if eud.water_active_snd.nam<>'' then st:=st+'"water_active_snd":'+snds_to_json(eud.water_active_snd)+',';
 if eud.boom_snd.nam<>'' then st:=st+'"boom_snd":'+snds_to_json(eud.boom_snd)+',';
 if eud.stop_snd.nam<>'' then st:=st+'"stop_snd":'+snds_to_json(eud.stop_snd)+',';
 if eud.start_snd.nam<>'' then st:=st+'"start_snd":'+snds_to_json(eud.start_snd)+',';
 if eud.fire_snd.nam<>'' then st:=st+'"fire_snd":'+snds_to_json(eud.fire_snd)+',';

 st:=trim(st);
 if copy(st,length(st),1)=',' then st:=copy(st,1,length(st)-1);
 st:=' '+st+'}';

 result:=st;
end;
//############################################################################//
procedure proc_eunitsdb;
var i:integer;
l:astr;
eudb,st:string;
f:text;
begin
 l:=filelist('cfg/*.cfg',faanyfile);

 eudb:='';
 for i:=0 to length(l)-1 do begin
  st:=proc_one_eunitsdb('cfg/'+l[i]);
  if i<>0 then eudb:=eudb+','+#$0D#$0A;
  eudb:=eudb+st;
 end;
 eudb:='{"eunits_db":['+#$0D#$0A+eudb+#$0D#$0A+']}';

 assignfile(f,'eunits_db.txt');
 rewrite(f);
 writeln(f,eudb);
 closefile(f);
end;
//############################################################################//
procedure load_pal;
{$i max_pal.inc}
var i,j:integer;
begin
 for i:=0 to length(thepal)-1 do for j:=0 to 2 do thepal[i][j]:=max_pal[i][j];
end;
//############################################################################//
procedure regen_pal;
var s:ptypspr;
width,height,i:integer;
p:pointer;
pal:pallette3;
pal4:pallette;
begin
 load_pal;
 for i:=0 to length(thepal)-1 do pal4[i]:=tcrgba(thepal[i][0],thepal[i][1],thepal[i][2],255);

 if Loadbitmap8('b_jaeger.bmp',width,height,p,pal)<>nil then begin
  maxg_dither_img_8_to_pal(pbytea(p),width,height,pal,thepal,false);
  storebmp8('b_jaeger.bmp',p,width,height,true,true,pal4);
 end;
end;
//############################################################################//
begin
 //proc_eunitsdb;
 regen_pal;
end.
//############################################################################//
