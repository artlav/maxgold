//############################################################################//
unit mgl_convert;
interface    
uses sysutils,asys,parser,strval,strtool,mgl_json,maths,json,mgrecs,mgvars,vfsint;
//############################################################################//   
procedure util_stuff;  
//############################################################################//
implementation                    
//############################################################################//
function xadd_dir(var lookup_dirs:astr;new:string):boolean;
var k:integer;
strx,dirf:string;
begin
 result:=false;
 k:=length(lookup_dirs);
 setlength(lookup_dirs,k+1);
 strx:=mg_core.units_dir+'/'+new;
 dirf:=mgrootdir+strx;   
 if not vfexists(dirf+'/uniset.cfg') then dirf:=mgrootdir+'maxgold/'+strx;   
 if not vfexists(dirf+'/uniset.cfg') then exit;
 lookup_dirs[k]:=dirf;
 result:=true;
end;     
//############################################################################//     
function convert_one_unitdb(path:string):string;     
var descwas_r,descmode_r,descwas_e,descmode_e:boolean;
ud:ptypunitsdb; 
psr:preca;
i,j:integer;  
feata:numa;
strx:string;
begin 
 psr:=nil;
 descwas_r:=false;  
 descwas_e:=false;  
 descmode_r:=false;
 descmode_e:=false;
 new(ud);   
 fillchar(ud^,sizeof(ud^),0);  
 
 ud.descr_eng:='';
 ud.descr_rus:='';
 
 psr:=parsecfg(path,true,'=');
 for i:=0 to length(psr)-1 do with psr[i] do begin
  par:=trim(par);
  if (not descmode_r)and(not descmode_e) then begin
   if par='Тип' then begin ud.typ:=lowercase(props); continue; end;
   if par='Имя' then begin ud.name_rus:=props; continue; end;
   if par='Имя-Eng' then begin ud.name_eng:=props; continue; end;
  
   if par='Basics' then begin
    valnuma(props,feata);
    if length(feata)<6 then continue;                                
    ud.siz  :=feata[0];
    ud.ptyp :=feata[1];
    ud.level:=feata[2];
    ud.ord  :=feata[3];
    ud.bldby:=feata[4];
    ud.canbuildtyp:=feata[5];
    ud.canbuild:=ud.canbuildtyp<>0;  
    if length(feata)>=7 then ud.priority:=feata[6] else ud.priority:=1;
    continue;
   end;   
   if par='Features' then begin
    ud.flags:=valbinrev(props);
    continue;
   end;    
   if par='Features2' then begin
    ud.flags2:=valbinrev(props);
    continue;
   end;    
   if par='Parameters' then begin
    valnuma(props,feata);
    if length(feata)<16 then continue;                                
    ud.bas.speed   :=feata[ 0];
    ud.bas.hits    :=feata[ 1];
    ud.bas.armr    :=feata[ 2];
    ud.bas.attk    :=feata[ 3];
    ud.bas.shoot   :=feata[ 4];
    ud.bas.fuel    :=feata[ 5];
    ud.bas.range   :=feata[ 6];
    ud.bas.scan    :=feata[ 7];
    ud.bas.ammo    :=feata[ 8];
    ud.bas.cost    :=feata[ 9];
    ud.bas.area    :=feata[10];
    ud.firemov     :=feata[11]=1;
    ud.fire_type   :=feata[12];
    ud.weapon_type :=feata[13];
    ud.isgun       :=feata[14]=1;   
    ud.bas.mat_turn:=feata[15];  
    continue;
   end;   
   if par='Resources' then begin
    valnuma(props,feata);
    if length(feata)<>5 then continue;
    for j:=RES_MIN to RES_MAX do ud.prod.num[j]:=feata[j-1];
    continue;
   end;   
   if par='Store' then begin
    valnuma(props,feata);
    if length(feata)<>4 then continue;                                
    ud.store_lnd:=feata[0];                                
    ud.store_air:=feata[1];                                
    ud.store_wtr:=feata[2];                                
    ud.store_hmn:=feata[3];
    continue;
   end;  
   if par='Needs' then begin
    valnuma(props,feata);
    if length(feata)<>6 then continue;                                
    for j:=RES_MIN to RES_MAX do if j<=3 then ud.prod.use[j]:=feata[j-1] else ud.prod.use[j]:=feata[j];
    ud.prod.rgoluse:=feata[3];
    continue;
   end;
   if par='Returns' then begin
    valnuma(props,feata);
    if length(feata)<>6 then continue;
    for j:=RES_MIN to RES_MAX do if j<=3 then ud.prod.pro[j]:=feata[j-1] else ud.prod.pro[j]:=feata[j];
    ud.prod.rgolpro:=feata[3];
    continue;
   end;
   if copy(lowercase(trim(par)),1,20)='##begin_description(' then begin
    if copy(lowercase(trim(par)),21,3)='rus' then begin strx:=''; descmode_r:=true;end;
    if copy(lowercase(trim(par)),21,3)='eng' then begin strx:=''; descmode_e:=true;end;
   end;
  end else if par='##end_description' then begin 
   if descmode_r then begin
    descmode_r:=false;
    mspc(ud.descr_rus,length(strx)+1,strx);
    descwas_r:=true;
   end else begin
    descmode_e:=false;
    mspc(ud.descr_eng,length(strx)+1,strx);
    descwas_e:=true;
   end
  end else begin      
   strx:=strx+src+'&';      
  end;   
 end;
 
 if not descwas_r then mspc(ud.descr_rus,255,'Не описан.');
 if not descwas_e then mspc(ud.descr_eng,255,'No description.');
 
 if ud.siz=0 then ud.siz:=1;
 

 result:=unitsdb_to_json(ud,false);
 dispose(ud);
 
end;
//############################################################################//
function convert_udb(uniset:string):string;
var l:avdirtyp;
i,j,lc:integer;
lookup_dirs:astr;   
psr:preca;

unitsdb_cnt:integer;   
unitsdb:array of typunitsdb;
begin 
 result:='';
 
 l:=nil;
 psr:=nil;
 
 unitsdb_cnt:=0;
 
 setlength(lookup_dirs,0);
 if not xadd_dir(lookup_dirs,uniset) then exit;
                         
 if vfexists(lookup_dirs[0]+'/uniset.cfg') then begin
  psr:=parsecfg(lookup_dirs[0]+'/uniset.cfg',true,'=');
  for i:=0 to length(psr)-1 do with psr[i] do begin
   par:=trim(par);
   ////if par='Add_to' then if not add_dir(lookup_dirs,props) then exit;
  end; 
 end;

 result:='['+#$0A;
 for i:=length(lookup_dirs)-1 downto 0 do begin
  l:=vffind_arr(lookup_dirs[i]+'/units/*.cfg',attall);
  lc:=unitsdb_cnt;
  unitsdb_cnt:=unitsdb_cnt+length(l); 
  setlength(unitsdb,unitsdb_cnt); 
  for j:=lc to length(unitsdb)-1 do fillchar(unitsdb[j],sizeof(unitsdb[j]),0);
  for j:=0 to length(l)-1 do begin
   result:=result+convert_one_unitdb(lookup_dirs[i]+'/units/'+l[j].name);
   if j<>length(l)-1 then result:=result+',';
   result:=result+#$0A;
  end;
 end;   
 result:=result+']';
 //sortunitsdb(g);


end;  
//############################################################################//
function convert_resource_info(fn:string):string;  
var f:vfile;
i,md,k,a,b,c:integer;
buf:pbytea;
bs,bp:integer;
s,ts:string;
initial_res:res_info_rec;

//var js:pjs_node;
 
begin
 result:='';
 if not vfexists(fn) then exit;
 
 if vfopen(f,fn,VFO_READ)<>VFERR_OK then exit;  
 bs:=vffilesize(f);
 getmem(buf,bs);
 vfread(f,buf,bs);
 vfclose(f);
      
 md:=0;
 bp:=0;
 s:='';
 a:=0;
 b:=0;

 while true do begin
  case md of
   0:if buf[bp]=ord('#') then md:=1 else if buf[bp]=$0A then md:=2 else if buf[bp]<>$0D then s:=s+chr(buf[bp]);
   1:if buf[bp]=$0A then md:=2;
   2:begin     
    ts:=trim(s);
    if ts<>'' then begin
     s:='';
     for i:=1 to length(ts) do if ts[i]<>' ' then s:=s+ts[i];

     for c:=0 to 3 do begin
      k:=getfsymp(s,'(');if k=0 then break;                  s:=copy(s,k+1,length(s));
      k:=getfsymp(s,',');if k=0 then break;ts:=copy(s,1,k-1);s:=copy(s,k+1,length(s));initial_res[a][b][c][0]:=vali(ts);
      k:=getfsymp(s,')');if k=0 then break;ts:=copy(s,1,k-1);s:=copy(s,k+1,length(s));initial_res[a][b][c][1]:=vali(ts);
     end;
     b:=b+1;
     if b>2 then begin
      b:=0;
      a:=a+1;
      if a>2 then break;
     end;  
    end;    
    s:='';
    md:=0;  
    bp:=bp-1; 
   end;
  end;
  bp:=bp+1;
  if bp>=bs then break;
 end;
    
 freemem(buf);
      
 result:=initres_to_json(initial_res);
 {
 js:=js_parse(result);
 initial_res:=initres_from_json(js);    
 result:=initres_to_json(initial_res);
 }
end; 
//############################################################################//               
function convert_clans(uniset:string):string;
var i,c,n,k:integer;  
parserec:preca;
s,path:string;
sn,st:string;
clansdb:array of typclansdb;

begin 
 result:='';
 parserec:=nil; 
 c:=0;
 setlength(clansdb,0);
 s:=mg_core.units_dir+'/'+uniset+'/';
 path:=mgrootdir+s+'clans.cfg'; 
 if not vfexists(path) then path:=mgrootdir+'maxgold/'+s+'clans.cfg';   
 if not vfexists(path) then exit;   
 parserec:=parsecfg(path,true);

 for i:=0 to length(parserec)-1 do with parserec[i] do begin
  if copy(par,1,5)='[Clan' then begin
   c:=vali(copy(par,7,1));
   if length(clansdb)<=c then setlength(clansdb,c+1);
   setlength(clansdb[c].unupd,0);
   clansdb[c].flags:=0;
   continue;
  end;
  if par='Name'     then begin clansdb[c].name:=props; continue;end;
  if par='Text'     then begin clansdb[c].desc_eng:=props; continue;end;   
  if par='Text-Rus' then begin clansdb[c].desc_rus:=props; continue;end;   
  if par='Flags'    then begin clansdb[c].flags:=propn;continue;end;

  if trim(par)='' then continue; 
   
  k:=length(clansdb[c].unupd);
  setlength(clansdb[c].unupd,k+1);
  clansdb[c].unupd[k].typ:=lowercase(par);  
       
  s:=trim(props);          
  repeat                
   sn:=copy(s,1,3);   
   n:=getfsymp(s,',');    
   if n=0 then begin      
    n:=getfsymp(trim(s),' ');   
    st:=copy(trim(s),n+1,length(s)); 
    sn:=copy(trim(s),1,n);      
    n:=0;                 
   end else st:=copy(s,4,n-4);  
   st:=trim(lowercase(st));  
   if st='ammo'   then clansdb[c].unupd[k].bas.ammo:=vali(sn); 
   if st='scan'   then clansdb[c].unupd[k].bas.scan:=vali(sn);  
   if st='speed'  then clansdb[c].unupd[k].bas.speed:=vali(sn); 
   if st='hits'   then clansdb[c].unupd[k].bas.hits:=vali(sn); 
   if st='armor'  then clansdb[c].unupd[k].bas.armr:=vali(sn); 
   if st='attack' then clansdb[c].unupd[k].bas.attk:=vali(sn); 
   if st='shot'   then clansdb[c].unupd[k].bas.shoot:=vali(sn); 
   if st='fuel'   then clansdb[c].unupd[k].bas.fuel:=vali(sn); 
   if st='cost'   then clansdb[c].unupd[k].bas.cost:=vali(sn); 
   if st='area'   then clansdb[c].unupd[k].bas.area:=vali(sn); 
   if st='range'  then clansdb[c].unupd[k].bas.range:=vali(sn);  
   if st='prod'   then clansdb[c].unupd[k].bas.mat_turn:=vali(sn);  
    
   if n=0 then break;   
   s:=copy(s,n+1,length(s)); 
  until false;     
 end;

 n:=length(clansdb);      
 result:='['+#$0A;
 for i:=0 to n-1 do begin 
  result:=result+clan_to_json(@clansdb[i]);
  if i<>n-1 then result:=result+',';
  result:=result+#$0A;
 end;
 result:=result+']'; 
 
end;  
//############################################################################//
procedure convert_uniset(fn,uniset:string);  
var f:vfile;
s,clans,udb,res:string;
begin
 clans:=convert_clans(uniset);
 udb:=convert_udb(uniset);    
 res:=convert_resource_info(mgrootdir+'data/unitset/'+uniset+'/resources.cfg');

 s:='{'+#$0A;      
 s:=s+'"res":'+res+','+#$0A;
 s:=s+'"clans":'+clans+','+#$0A;
 s:=s+'"udb":'+udb+#$0A;
 s:=s+'}';
 
 if vfopen(f,fn,VFO_WRITE)=VFERR_OK then begin
  vfwrite(f,@s[1],length(s));
  vfclose(f);
 end;
end;
//############################################################################//
procedure util_stuff;  
begin
 convert_uniset(mgrootdir+'out/fuel_and_2air.txt','fuel_and_2air');
end;
//############################################################################//
begin
end.   
//############################################################################//
