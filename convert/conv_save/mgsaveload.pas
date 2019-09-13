//############################################################################//
//Made by Artyom Litvinovich in 2003-2013
//MaxGold core saves loading routines
//############################################################################//
unit mgsaveload;
interface
uses sysutils,asys,vfsint,maths,strval,strtool,lzw,b64,crc32
//,mgl_json
,maxsaves,maxsavesrec;
//############################################################################//
function  load_savefile(g:pgametyp;fnm:string;md:integer):boolean;
procedure save_game(g:pgametyp;fn:string);
//############################################################################//
implementation
//############################################################################//
//Save game
function form_save_game(g:pgametyp):string;
var s,info,state,plr,udb,resmap,passmap,clans,units:string;
i,n,xs,ys,x,y,a,t:integer;
c:char;
u:ptypunits;
begin try
 result:='';
 if g=nil then exit;
               
 xs:=g.info.mapx; 
 ys:=g.info.mapy; 

 info:=ginfo_to_json(@g.info) ;
 state:=gstate_to_json(@g.state);

 n:=g.info.plr_cnt;
 plr:='['+#$0A;for i:=0 to n-1 do begin plr:=plr+pstart_to_json(@g.plr[i].info)+#$0A;if i<>n-1 then plr:=plr+',';end;plr:=plr+']'; 

 n:=length(g.clansdb);      
 clans:='['+#$0A;for i:=0 to n-1 do begin clans:=clans+clan_to_json(@g.clansdb[i])+#$0A;if i<>n-1 then clans:=clans+',';end;clans:=clans+']}}'; 

 n:=length(g.unitsdb);
 udb:='['+#$0A;for i:=0 to n-1 do begin udb:=udb+unitsdb_to_json(@g.unitsdb[i])+#$0A;if i<>n-1 then udb:=udb+',';end;udb:=udb+']'; 

 resmap:='['+#$0A;
 for y:=0 to ys-1 do begin
  setlength(s,xs*2);
  for x:=0 to xs-1 do begin
   a:=g.resmap[x+y*g.info.mapx].amt;
   t:=g.resmap[x+y*g.info.mapx].typ;
   s[1+x*2+0]:=chr(t+ord('0'));
   s[1+x*2+1]:=chr(a+ord('A'));
  end;
  resmap:=resmap+'"'+s+'"'+#$0A;
  if y<>ys-1 then resmap:=resmap+',';
 end;
 resmap:=resmap+#$0A+']'; 
 
 passmap:='['+#$0A;  
 setlength(s,xs);
 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   t:=g.passm[x+y*g.info.mapx];
   c:=chr(t+ord('0'));
   s[1+x]:=c;   
  end;
  passmap:=passmap+'"'+s+'"'+#$0A;
  if y<>ys-1 then passmap:=passmap+',';
 end;
 passmap:=passmap+#$0A+']'; 
   
 n:=length(g.units);
 units:='['+#$0A;
 for i:=0 to n-1 do begin     
  u:=nil;              
  if unave(g,i) then u:=g.units[i];
  if u=nil then begin
   units:=units+'{"num":'+stri(i)+',"used":0}'+#$0A;
  end else begin
   units:=units+units_to_json(u)+#$0A;
  end;
  if i<>n-1 then units:=units+',';
 end;
 units:=units+']';
 
 
 s:='{'+#$0A;
 s:=s+'"save_ver":"'+'MGS-'+stri(progvernum_save)+'",'+#$0A;
 s:=s+'"server_id":"'+g.server_id+'",'+#$0A;
 s:=s+'"remote_id":"'+g.remote_id+'",'+#$0A;
 s:=s+'"info":'+info+','+#$0A;
 s:=s+'"state":'+state+','+#$0A;
 s:=s+'"plr":'+plr+','+#$0A;
 s:=s+'"clans":'+clans+','+#$0A;
 s:=s+'"udb":'+udb+','+#$0A;
 s:=s+'"resmap":'+resmap+','+#$0A;
 s:=s+'"passmap":'+passmap+','+#$0A;
 s:=s+'"units":'+units+''+#$0A;
 s:=s+'}';
     
 //Not sure
 //trk:atrktyp;                           //Tracks  
 //plr:array[0..MAX_PLR-1]of plrtyp;
 
 result:=s;
 
 except stderr('LoadSav','form_save_game');end;
end;
//############################################################################//
function read_save_unit(gam:pgametyp;i:integer;buf:pointer;var bp:dword;save_version:integer):boolean;
var k:integer;
u:ptypunits;
{$i readut.inc}
begin
 result:=false;
 k:=readint;
 if k=$0BCDEF11 then begin gam.units[i]:=nil;exit;end;
 new(gam.units[i]);
 u:=gam.units[i];
 fillchar(u^,sizeof(u^),0); //All zeros

 u.typ:=lowercase(readstr);

 u.name  :=readstr;
 u.nm:=readint;
 u.cln    :=readint;u.mk     :=readint;u.own:=readint;
 u.x      :=readint;u.y      :=readint;u.xt     :=readint;u.yt :=readint;
 u.prior_x:=readint;u.prior_y:=readint;u.cur_siz:=readint;u.mox:=readint;
 u.moy    :=readint;u.rot    :=readint;u.grot   :=readint;u.alt:=readint;
 u.vel    :=readext;

 u.is_unselectable:=readbool;
 u.is_moving      :=readbool;
 u.is_moving_now  :=readbool;
   
 u.isact:=readbool;u.strtmov:=readbool;u.stpmov :=readbool;u.stlmov :=readbool;
 u.isstd:=readbool;
 //u.isboom :=readbool;
 u.isbmbpl:=readbool;u.isbmbrm:=readbool;
 for k:=0 to max_plr-1 do u.in_lock[k]:=readbool;
 u.isauto   :=readbool;u.isclrg   :=readbool;u.stored:=readbool;
 u.stored_in:=readint; u.is_sentry:=readbool;u.was_fired_on:=readbool;

 readblock(@u.bas,sizeof(u.bas));
 readblock(@u.cur,sizeof(u.cur));
 readblock(@u.prod,sizeof(u.prod));  
 
 u.disabled_for:=readint;//u.firing_at.x:=readint;
 //u.firing_at.y:=readint;
 u.stop_task   :=readint;u.stop_target:=readint;
 if save_version>=20110905 then u.stop_task_pending:=readbool else u.stop_task_pending:=false;
 u.stop_param :=readint;
 for k:=0 to max_plr-1 do u.stealth_detected[k]:=readint;
 u.triggered_auto_fire:=readbool;
 
 //u.afireip:=
 readbool;
 
 u.clrturns:=readint;
 u.clr_unit  :=readint; u.clr_tape  :=readint; u.clrval  :=readint;
 u.isbuild   :=readbool;u.isbuildfin:=readbool;

 u.builds_cnt:=readint;
 for k:=0 to u.builds_cnt-1 do begin
  u.builds[k].typ:=lowercase(readstr);
  u.builds[k].typ_db:=getdbnum(gam,u.builds[k].typ);
  
  u.builds[k].x            :=readint; u.builds[k].y          :=readint;
  u.builds[k].sz           :=readint; u.builds[k].rept       :=readbool;
  u.builds[k].reverse      :=readbool;u.builds[k].left_turns :=readint;
  u.builds[k].left_to_build:=readint; u.builds[k].left_mat   :=readint;
  u.builds[k].cur_speed    :=readint; u.builds[k].cur_use    :=readint;
  u.builds[k].cur_take     :=readint; u.builds[k].given_speed:=readint;
  u.builds[k].base         :=readint; u.builds[k].tape       :=readint;
  u.builds[k].cones        :=readint;
 end;
 u.reserve:=readint;
 u.researching:=readint;
 result:=true;
end;
//############################################################################//
function read_save_unitdb(gam:pgametyp;i:integer;buf:pointer;var bp:dword;save_version:integer):boolean;
var ud:ptypunitsdb;
s:string;
{$i readut.inc}
begin
 ud:=@gam.unitsdb[i];
 fillchar(ud^,sizeof(ud^),0); //All zeros  

 ud.num:=i;  
   
 setlength(ud.u_num,gam.info.plr_cnt);
 setlength(ud.u_cas,gam.info.plr_cnt);

 ud.typ:=readstr;
 ud.name:=readstr;
 s:=readstr;
 mspc(ud.descr,255,s);

 ud.ptyp:=readbyte;
 ud.level:=readbyte;
 ud.ord:=readbyte;
 ud.siz:=readbyte;
  
 ud.priority:=readbyte;
 ud.bldby:=readsml;

 ud.flags:=readint;
 ud.flags2:=readint;
 ud.isgun:=readbool;
 
 readblock(@ud.bas,sizeof(ud.bas)); 
 readblock(@ud.prod,sizeof(ud.prod)); 

 ud.canbuild:=readbool;
 ud.canbuildtyp:=readsml;

 ud.firemov:=readbool;
 ud.fire_type:=readbyte;
 ud.weapon_type:=readbyte;
 ud.blastlen:=readext;
 ud.firlen:=readext;

 ud.store_lnd:=readsml;
 ud.store_wtr:=readsml;
 ud.store_air:=readsml;
 ud.store_hmn:=readsml;
  
 result:=true;
end;
//############################################################################//
procedure read_save_player_base(gam:pgametyp;i:integer;buf:pointer;var bp:dword;save_version:integer);
var n,j:integer;
pl:pplrtyp;
{$i readut.inc}
begin         
 pl:=@gam.plr[i]; 
 pl.num:=i;
  
 pl.typ   :=readint; pl.info.name  :=readstr; pl.info.passhash:=readstr;
 pl.used  :=readbool;
 //pl.landed:=readbool;
 //pl.init    :=readbool;
 //pl.inited:=readbool;
 pl.info.clan  :=readint; pl.lck_mode:=readbool; 
 for n:=0 to MAX_PLR-1 do pl.allies[n]:=readbool;
 //pl.lost:=readbool;
                
 pl.sopt.zoom:=readext;pl.sopt.sx  :=readint;pl.sopt.sy  :=readint;pl.sopt.xm  :=readint;
 pl.sopt.ym  :=readint;pl.info.lndx:=readint;pl.info.lndy:=readint;
 for n:=1 to fb_count do pl.sopt.framebtn[n]:=readint;

 for n:=0 to 2 do pl.info.color[n]:=readint;
 setlength(pl.custom_color, gam.info.plr_cnt+1);
 for j:=0 to gam.info.plr_cnt-1+1 do for n:=0 to 2 do pl.custom_color[j][n]:=readint;

 pl.gold  :=readint;
 pl.info.stgold:=readint;
 //pl.nselu :=readint;

 //setlength(pl.selunit,pl.nselu);
 //for n:=0 to pl.nselu-1 do pl.selunit[n]:=readint;

 for j:=0 to MAX_PRESEL-1 do begin
  setlength(pl.sel_stored[j],readint);
  for n:=0 to length(pl.sel_stored[j])-1 do pl.sel_stored[j][n]:=readint;
 end;

 for j:=0 to MAX_CAMPOS-1 do begin
  pl.cam_pos[j].x:=readint;
  pl.cam_pos[j].y:=readint;
  pl.cam_pos[j].zoom:=readext;
 end;

 pl.info.bgncnt:=readint;
 for n:=0 to pl.info.bgncnt-1 do begin pl.info.bgn[n].typ:=lowercase(readstr);pl.info.bgn[n].mat:=readint;end;

 for n:=0 to RS_COUNT-1 do pl.rsrch_labs[n]:=0;
 for n:=0 to RS_COUNT-1 do pl.rsrch_spent[n]:=readint;
 for n:=0 to RS_COUNT-1 do pl.rsrch_level[n]:=readint;

    
 if save_version>=20130122 then begin
  n:=readint;
  setlength(pl.comments,n);
  for n:=0 to length(pl.comments)-1 do begin
   pl.comments[n].typ:=readint;
   pl.comments[n].x:=readint;
   pl.comments[n].y:=readint;
   pl.comments[n].turn:=readint;
   pl.comments[n].text:=readstr;
  end;
 end;
  
end;
//############################################################################//
procedure read_save_player_rest(gam:pgametyp;i:integer;buf:pointer;var bp:dword;save_version:integer);
var n,j,x,y:integer;
p:pplrtyp;
{$i readut.inc}
begin         
 p:=@gam.plr[i];

 setlength(p.unupd,gam.info.unitsdb_cnt);
 setlength(p.tmp_unupd,gam.info.unitsdb_cnt);
 for n:=0 to gam.info.unitsdb_cnt-1 do begin
  p.unupd[n].typ:=lowercase(readstr);
  p.unupd[n].mk:=readint;
  p.unupd[n].nu:=readint;
  readblock(@p.unupd[n].bas,sizeof(p.unupd[n].bas));
  p.unupd[n].cas:=readint;
 end;

 setlength(p.logmsg,readint);
 for n:=0 to length(p.logmsg)-1 do begin
  p.logmsg[n].own:=readint;
  p.logmsg[n].tp:=readbyte;
  for j:=0 to 1 do begin
   p.logmsg[n].data[j].x:=readint;
   p.logmsg[n].data[j].y:=readint;
   p.logmsg[n].data[j].dbn:=readint;
   p.logmsg[n].data[j].own:=readint;
   p.logmsg[n].data[j].kind:=readint;
   p.logmsg[n].data[j].tag:=readint;
  end;
 end;

 x:=readint;
 y:=readint;
 clrrazvp(p.razvedmp,x,y);
 for n:=0 to x*y-1 do begin
  p.razvedmp[n mod x,n div x].seen:=readbool;
  if p.razvedmp[n mod x,n div x].seen then begin     
   setlength(p.razvedmp[n mod x,n div x].blds,readint);
   for j:=0 to length(p.razvedmp[n mod x,n div x].blds)-1 do begin
    p.razvedmp[n mod x,n div x].blds[j].used:=readbool;  
    //FIXME: replace id with typ.
    p.razvedmp[n mod x,n div x].blds[j].id:=readint;
    if save_version>=20110905 then p.razvedmp[n mod x,n div x].blds[j].level:=readint else p.razvedmp[n mod x,n div x].blds[j].level:=0;
    p.razvedmp[n mod x,n div x].blds[j].own:=readint;
   end;
  end;
 end; 
 
 for n:=0 to SL_COUNT-1 do setlength(p.scan_map[n],x*y); 
          
 setlength(p.resmp,readint);   
 for n:=0 to length(p.resmp)-1 do p.resmp[n]:=readint; 
end;
//############################################################################//
function decompress_save_file(fname:string;var buf:pointer;var bufsz,hsz,date:dword):boolean;
var f:vfile;
sgn,off,bsz,comphsz:dword;
k:integer;
st:string;
tmp1,tmp2,header,body:pointer;
alg,szhdr,szcomphdr,szbas:byte;
begin
 result:=false;
    
 vfopen(f,fname,VFO_READ);   
 date:=vffiledate(f);

 
 vfread(f,@sgn,4);
 if sgn<>MGSAVE_BASE_SGN then begin vfclose(f);exit;end; 
 vfread(f,@alg,1); //Algorithm  
 vfread(f,@szhdr,1);  //Size of header size string
 vfread(f,@szcomphdr,1);  //Size of compressed header size string
 alg:=alg-ord('0');
 szhdr:=szhdr-ord('0');
 szcomphdr:=szcomphdr-ord('0');
 setlength(st,szhdr);    vfread(f,@st[1],szhdr);    hsz    :=vali(st); 
 setlength(st,szcomphdr);vfread(f,@st[1],szcomphdr);comphsz:=vali(st); 
 
 case alg of 
  3:begin  
   //Find header
   off:=vffilepos(f);
   while dword(vffilesize(f)-vffilepos(f))>=comphsz do begin
    vfseek(f,off);
    sgn:=0;
    vfread(f,@sgn,1);
    if sgn<>10 then begin sgn:=$FFFF00FF;break;end;
    off:=off+1;
   end;
   if sgn<>$FFFF00FF then begin vfclose(f);exit;end; 
   vfseek(f,off);
   
   //Header
   getmem(tmp1,comphsz);
   getmem(tmp2,comphsz*2);
   getmem(header,hsz+10);
   vfread(f,tmp1,comphsz); 
   off:=b64decbuf(tmp1,comphsz,tmp2,comphsz*2);  
   decodeLZW(tmp2,header,off,hsz);
   freemem(tmp1);
   freemem(tmp2);

   //Body
   off:=vffilepos(f);
   while vffilesize(f)-vffilepos(f)>4 do begin
    vfseek(f,off);
    vfread(f,@sgn,4);
    if sgn=MGSAVE_REST_SGN then break;
    off:=off+1;
   end;

   //No body?
   if sgn<>MGSAVE_REST_SGN then begin   
    bufsz:=hsz;
    getmem(buf,bufsz);
    move(header^,buf^,hsz);
    freemem(header); 
    vfclose(f);  
    result:=true; 
    exit;
   end;

   //Read body
   vfread(f,@szbas,1);  //Size of base size string
   szbas:=szbas-ord('0');
   setlength(st,szbas);vfread(f,@st[1],szbas);bsz:=vali(st); 
   k:=dword(vffilesize(f)-vffilepos(f)); 
    
   //Decode body
   getmem(tmp1,k);
   getmem(tmp2,k*2);
   getmem(body,bsz+10);
   vfread(f,tmp1,k); 
   off:=b64decbuf(tmp1,k,tmp2,k*2);  
   decodeLZW(tmp2,body,off,bsz);
   freemem(tmp1);
   freemem(tmp2);

   //Assemble
   bufsz:=bsz+hsz;
   getmem(buf,bufsz);
   move(header^,buf^,hsz);
   move(body^,pointer(dword(buf)+hsz)^,bsz);
   freemem(header); 
   freemem(body); 
  end;
  else begin vfclose(f);exit;end;
 end; 
 vfclose(f); 
     
 result:=true; 
end;
//############################################################################//
function do_load_savefile(gam:pgametyp;fname:string;md:integer):boolean;
var i,j,n,save_version,units_cnt:integer;
buf:pointer;
bp,crcbp,bs,hsz:dword;      
cl:ptypclansdb;
pl:pplrtyp;
{$i readut.inc}
procedure load_error(msg:string = '');
begin
 freemem(buf);
 if(md=1)or(md=2)then begin
  tolog('LoadSav',msg);
  if assigned(imbox) then imbox(msg,'Error');
  mg_haltgame(gam);
 end;
end;

begin try
 result:=false;
 bp:=0;
 if not decompress_save_file(fname,buf,bs,hsz,gam.state.date) then exit;

 save_version:=vali(copy(readstr,5,1000)); //Version
 if(save_version<progvernum_compat)or((save_version>progvernum_save)and(save_version<201304170))then begin load_error('Error in '+fname+' or the version is wrong');exit;end;
 gam.info.rules.debug:=readbool; //Debug mode
 gam.info.map_name:=readstr;     //Basic info
 
 ////gam.autofiring_at:=-1;
 ////gam.fire_in_progress:=-1;     
 gam.info.rules.load_onpad_only:=false;

 //Checksum
 crcbp:=bp;
 //gam.hdrcrc:=readint;
 //gam.bascrc:=readint;
 pdword(intptr(buf)+crcbp)^:=0;
 pdword(intptr(buf)+crcbp+4)^:=0;

 //crc:=not crc32_buf(buf,hsz);  //CRC32A=not CRC32 ... Legacy stuff.
 //if gam.hdrcrc<>crc then begin load_error('Error in '+fname+' or the version is wrong');exit;end;
 if md<>0 then begin
  //crc:=not crc32_buf(pointer(dword(buf)+hsz),bs-hsz);  //CRC32A=not CRC32 ... Legacy stuff.
 // if gam.bascrc<>crc then begin load_error('Error in '+fname+' or the version is wrong');exit;end;
 end;

 if(md<>0)and (bs=hsz) then begin load_error('Error in '+fname+' no body');exit;end;

 gam.state.status    :=readint;
 
 if save_version>=20130122 then begin
  gam.server_id  :=readstr;
  ////gam.is_finished:=readbool;
  gam.info.descr      :=readstr;
 end;
 
 gam.info.game_name:=readstr;gam.state.turn       :=readint;gam.state.cur_plr  :=readint;
 gam.info.plr_cnt  :=readint;gam.info.unitsdb_cnt:=readint;

 units_cnt:=readint;
 
 gam.state.date:=readint;

 //Game Rules
 gam.info.rules.uniset:=lowercase(readstr);

 //Old moratorium
 readint;
 readint;

 //check unitset exist
 ////if save_version<20150905 then begin
  ////gam.unitset_exist:=false;
  ////for i:=0 to length(mg_core.unitsets)-1 do if mg_core.unitsets[i].name=gam.rules.uniset then begin gam.unitset_exist:=true;break;end;
  ////if md>=1 then if not gam.unitset_exist then begin load_error('UnitSet not found: '+gam.rules.uniset);exit;end;
 ////end else gam.unitset_exist:=true;

 gam.info.rules.resset    :=readint ;gam.info.rules.goldset   :=readint ;gam.info.rules.fueluse   :=readbool;
 gam.info.rules.fuelxfer  :=readbool;gam.info.rules.fuel_shot :=readbool;gam.info.rules.startradar:=readbool;
 gam.info.rules.no_survey :=readbool;gam.info.rules.build_base:=readbool;gam.info.rules.no_buy_atk:=readbool;
 gam.info.rules.nopaswds  :=readbool;
 gam.info.rules.expensive_refuel:=readbool;gam.info.rules.center_4x_scan  :=readbool; 
 if save_version>=20110214 then gam.info.rules.moratorium:=readint;
 if save_version>=20110214 then gam.state.mor_done:=readbool;
 
 gam.info.rules.unload_all_shots:=readbool;gam.info.rules.unload_all_speed:=readbool;
 gam.info.rules.unload_one_speed:=readbool;gam.info.rules.load_sub_one_speed:=readbool;
 if(save_version>=20130423)and(save_version<201304170) then gam.info.rules.load_onpad_only:=readbool;
 
 for i:=0 to 9 do gam.info.rules.ut_factors[i]:=readint;
 for i:=1 to 3 do gam.info.rules.res_levels[i]:=readint;
 if not readmarker then begin load_error('Critical error: rules');exit;end;

 //check map exist
 ////gam.map_exist:=false;
 ////for i:=0 to mg_core.nummaps-1 do if lowercase(mg_core.map_names_list[i])=lowercase(gam.map_name) then begin gam.map_exist:=true;break;end;

 if md<>0 then begin
  setlength(gam.units,units_cnt);

  //Map
  if not loadmap(gam,gam.info.map_name) then begin load_error('Error loading map - file(s) not found: '+gam.info.map_name);gam.info.map_name:='';exit;end;

  setlength(gam.resmap,gam.info.mapx*gam.info.mapy);
  setlength(gam.unu,gam.info.mapx);
  for i:=0 to gam.info.mapx-1 do setlength(gam.unu[i],gam.info.mapy);
 end;

 //Players
 for i:=0 to gam.info.plr_cnt-1 do begin
  read_save_player_base(gam,i,buf,bp,save_version);
  if not readmarker then begin load_error('Critical error: players');exit;end;
 end;

 //For the full game
 if md>=1 then begin
  for i:=0 to gam.info.plr_cnt-1 do begin
   read_save_player_rest(gam,i,buf,bp,save_version);
   if not readmarker then begin load_error('Critical error: players');exit;end;
  end;
        
  //uniset
  if save_version>=20150905 then begin
   setlength(gam.unitsdb,gam.info.unitsdb_cnt);
   for i:=0 to gam.info.unitsdb_cnt-1 do if not read_save_unitdb(gam,i,buf,bp,save_version)then continue;
   if not readmarker then begin load_error('Critical error: unitsdb');exit;end;

   //Clans                          
   setlength(gam.clansdb,readint);
   for i:=0 to length(gam.clansdb)-1 do begin
    cl:=@gam.clansdb[i];
                 
    cl.name:=readstr;
    cl.desc:=readstr;
    cl.flags:=readint;
                  
    setlength(cl.unupd,readint);
    for j:=0 to length(cl.unupd)-1 do readblock(@cl.unupd[j],sizeof(cl.unupd[j]));
   end;  
   if not readmarker then begin load_error('Critical error: clans');exit;end;
  end;
  
  postprocess_loaded_save(gam,0,save_version);     //Preprocess
  
  for i:=0 to gam.info.mapx*gam.info.mapy-1 do begin gam.resmap[i].amt:=readint;gam.resmap[i].typ:=readint;end; //Resources
  if not readmarker then begin load_error('Critical error: res');exit;end;
                                     
  //Scan
  if(save_version>=20130419)and(save_version<201304170) then begin
   for i:=0 to get_plr_count(gam)-1 do begin
    pl:=get_plr(gam,i);
    for j:=0 to SL_COUNT-1 do for n:=0 to gam.info.mapx*gam.info.mapy-1 do pl.scan_map[j][n]:=readsml;
   end;
   if not readmarker then begin load_error('Critical error: scan');exit;end;
  end;
     
  for i:=0 to length(gam.units)-1 do if not read_save_unit(gam,i,buf,bp,save_version)then continue; //Units
  if not readmarker then begin load_error('Critical error: units');exit;end;
  
  postprocess_loaded_save(gam,1,save_version);                                                  //Postprocess
 end;
 
 freemem(buf);
 result:=true;
 except result:=false;stderr('LoadSav','do_load_savefile');end;
end;
//############################################################################//
function do_load_max_savefile(gam:pgametyp;fname:string;md:integer):boolean;
label 1;
var tinf:vfile;
i,n,k,x,y,j,c,ri:integer;
st:string;
und:array of typ_unupd;
u:ptypunits;        
units_cnt:integer;
////////////////////////////////////////////////////////////////////////////////
buf:pointer;bs:dword;
savo:saveorec;
xplr:array[0..3]of integer;
xuni:array of integer;
p:pplayer_info;
pl:pplrtyp;

plr,amt,tp:integer;

un:punit_def_record;
pth:ppath_def_block;
mov:boolean;
////////////////////////////////////////////////////////////////////////////////
begin try
 result:=false;
 filemode:=0;
 vfopen(tinf,fname,1);              
 bs:=tinf.inf.size; 
 getmem(buf,bs);
 vfread(tinf,buf,bs);    
 vfclose(tinf);

 if(pword(buf)^<>HD104)and(pword(buf)^<>HD156) then begin freemem(buf);exit;end;

 loadmaxosave_mem(savo,buf,bs);
 freemem(buf); 

 gam.info.rules:=mg_core.rules_def;
 gam.info.rules.debug:=true;
 
 i:=0;
 xplr[0]:=i;if savo.head.plr_type[0]<>0 then i:=i+1;
 xplr[1]:=i;if savo.head.plr_type[1]<>0 then i:=i+1;
 xplr[2]:=i;if savo.head.plr_type[2]<>0 then i:=i+1;
 xplr[3]:=i;
             
 //////-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+///////
 //Basic info
 gam.info.map_name:=def_maps[savo.head.map_id_1];
 //gam.hdrcrc:=0;
 //gam.bascrc:=0;
 gam.server_id:='';
 ////gam.is_finished:=false;
 ////gam.fire_in_progress:=-1;
 ////gam.autofiring_at:=-1;
 gam.info.descr:='Converted from '+fname;
 ////gam.map_exist:=false;
 ////gam.unitset_exist:=false;
 gam.state.status:=GST_THEGAME;
 gam.info.game_name:=savo.head.game_name;
 gam.state.turn:=savo.cur_turn;
 gam.state.cur_plr:=xplr[savo.doing_turn];
 gam.info.plr_cnt:=savo.plr_count;
 if gam.state.cur_plr>=gam.info.plr_cnt then gam.state.cur_plr:=0;
 gam.info.unitsdb_cnt:=78;
 units_cnt:=savo.mg_unitcnt;  
 gam.info.mapx:=112;
 gam.info.mapy:=112;
 gam.state.mor_done:=true;
                
 gam.info.rules.uniset:='original';
 
 //check unitset exist
 ////for i:=0 to length(mg_core.unitsets)-1 do if mg_core.unitsets[i].name=gam.rules.uniset then begin gam.unitset_exist:=true;break;end;
 ////if md>=1 then if not gam.unitset_exist then begin tolog('LoadSav','UnitSet not found: '+gam.rules.uniset);mg_haltgame(gam);exit;end;
                       
 gam.info.rules.moratorium:=0;
 gam.info.rules.resset:=50;
 gam.info.rules.goldset:=savo.head.sgold;
 gam.info.rules.fueluse:=false;
 gam.info.rules.fuelxfer:=false;   
 gam.info.rules.fuel_shot:=false;
 gam.info.rules.unload_all_shots:=false;
 gam.info.rules.unload_all_speed:=false;
 gam.info.rules.unload_one_speed:=false;
 gam.info.rules.load_sub_one_speed:=false;
 gam.info.rules.load_onpad_only:=false;
 gam.info.rules.startradar:=false;
 gam.info.rules.no_buy_atk:=false;
 gam.info.rules.expensive_refuel:=false;
 gam.info.rules.center_4x_scan:=true;
 ////for i:=0 to mg_core.nummaps-1 do if lowercase(mg_core.map_names_list[i])=lowercase(gam.map_name) then begin gam.map_exist:=true;break;end;

 if md>=1 then begin
  setlength(gam.units,units_cnt);

  //////-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+///////
  //Map
  if not loadmap(gam,gam.info.map_name) then begin
   tolog('LoadSav','Map '+gam.info.map_name+' not found or load error');
   gam.info.map_name:='';
   mg_haltgame(gam);
   exit;
  end;
  
  setlength(gam.resmap,gam.info.mapx*gam.info.mapy);
  setlength(gam.unu,gam.info.mapx);
  for i:=0 to gam.info.mapx-1 do setlength(gam.unu[i],gam.info.mapy);
 end;
                     
 //////-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+///////
 //Players
 for i:=0 to 4-1 do if savo.head.plr_type[i]<>0 then begin
  pl:=@gam.plr[xplr[i]];
  p:=@savo.pi[i];
           
  pl.num:=xplr[i];
  
  pl.typ:=1;
  pl.info.name:=trim(savo.head.plr_name[i]);
  pl.info.passhash:='D41D8CD98F00B204E9800998ECF8427E';
  pl.used:=true;
  pl.info.clan:=x_clans[p.clan];

  if p.zoom=0 then p.zoom:=mg_core.XCX;
  pl.sopt.zoom:=mg_core.XCX/p.zoom;
  pl.sopt.sx:=p.xoff*mg_core.XCX;pl.sopt.sy:=p.yoff*mg_core.XCX;
  pl.sopt.xm:=0;pl.sopt.ym:=0;
  pl.info.lndx:=-1;pl.info.lndy:=-1;

  //Translation goes across all, no need to limit anything
  for n:=1 to fb_count do if x_buttons[n-1]<>-1 then pl.sopt.framebtn[n]:=p.buttons[x_buttons[n-1]]
                                                else pl.sopt.framebtn[n]:=0;
  for n:=0 to 2 do pl.info.color[n]:=plr_color[i][2-n];
  setlength(pl.custom_color,4+1);setlength(pl.custom_color8,4+1);
  for j:=0 to 3 do for n:=0 to 2 do pl.custom_color[j+1][n]:=plr_color[j][2-n];
  pl.custom_color[0][0]:=35;
  pl.custom_color[0][1]:=83;
  pl.custom_color[0][2]:=59;
  pl.custom_color8[0]:=238;

  pl.gold:=savo.plr_gold[i];
  pl.info.stgold:=savo.head.sgold;
  //pl.nselu:=1;

  //setlength(pl.selunit,pl.nselu);
  //for n:=0 to pl.nselu-1 do pl.selunit[n]:=-1;
  for j:=0 to MAX_PRESEL-1 do setlength(pl.sel_stored[j],0);
  for j:=0 to MAX_CAMPOS-1 do pl.cam_pos[j].x:=-1;
  setlength(pl.logmsg,0);

  setlength(pl.unupd,gam.info.unitsdb_cnt);
  setlength(pl.tmp_unupd,gam.info.unitsdb_cnt);
  for n:=0 to gam.info.unitsdb_cnt-1 do begin
   pl.unupd[n].typ:='';
   pl.unupd[n].mk :=0;
   pl.unupd[n].nu :=0;
   zero_stats(pl.unupd[n].bas);
  end;  

  pl.info.bgncnt:=0;
  for n:=0 to pl.info.bgncnt-1 do begin
   pl.info.bgn[n].typ:=''; 
   pl.info.bgn[n].mat:=0;
  end;

  x:=gam.info.mapx;y:=gam.info.mapy;
  clrrazvp(pl.razvedmp,x,y);
  for n:=0 to x*y-1 do pl.razvedmp[n mod x,n div x].seen:=false;
    
  for n:=0 to SL_COUNT-1 do setlength(pl.scan_map[n],gam.info.mapx*gam.info.mapy);
 
  setlength(pl.resmp,gam.info.mapx*gam.info.mapy); 
  for n:=0 to gam.info.mapx*gam.info.mapy-1 do begin                
   getres(savo,i mod gam.info.mapx,i div gam.info.mapy,plr,amt,tp); 
   if plr and(1 shl xplr[i])<>0 then pl.resmp[n]:=1 else pl.resmp[n]:=0;
  end;

  //FIXME: Xlate from save  
  for n:=0 to RS_COUNT-1 do pl.rsrch_spent[n]:=0;
  for n:=0 to RS_COUNT-1 do pl.rsrch_level[n]:=0; 
  for n:=0 to RS_COUNT-1 do pl.rsrch_labs [n]:=0;
 end;  
      
 if md>=1 then begin
  postprocess_loaded_save(gam,0,0);
  //Resources  
  for i:=0 to gam.info.mapx*gam.info.mapy-1 do begin     
   getres(savo,i mod gam.info.mapx,i div gam.info.mapy,plr,amt,tp); 
   gam.resmap[i].amt:=amt;
   gam.resmap[i].typ:=tp;
  end;
  
  //Units
  k:=0;
  setlength(xuni,length(savo.objlst));
  for i:=savo.unitstart to length(savo.objlst)-1 do begin
   if savo.objlst[i].tp<>5 then continue;
   un:=savo.objlst[i].info;
   if uninames[un.unid][2]='-' then continue;
   if uninames[un.unid][2]='' then continue;

   new(gam.units[k]); 
   u:=gam.units[k];   
   fillchar(u^,sizeof(u^),0); //All zeros
   
   u.num:=k;
   xuni[i]:=k;
   
   u.is_unselectable:=false;
   u.mk:=0;
   
   u.isbmbpl:=false;u.isbmbrm:=false;
   
   if(savo.objlst[un.object_used.ob].tp=6)and(un.hitsnow=0)and(punit_pars_record(savo.objlst[un.object_used.ob].info)^.hits<>0)then u.num:=-1; 
   
   u.typ:=lowercase(uninames[un.unid][2]);
   u.name:=uninames[un.unid][1];
   u.nm:=un.unit_number;
   if un.owner<>4 then u.cln:=x_clans[savo.pi[un.owner].clan] else u.cln:=0;
   if un.owner<>4 then u.own:=xplr[un.owner] else u.own:=-1;

   
   //Pos   
   if(un.is_build_n<>0)and(uninames[un.unid][3][1]='U')then begin
    c:=0;
    for j:=i-1 downto savo.unitstart do if(savo.objlst[j].tp=5)and(punit_def_record(savo.objlst[j].info).inside_obj.ob=i)then begin c:=j;break;end;
    if c<>0 then begin   
     u.x:=punit_def_record(savo.objlst[j].info).x_pos;
     u.y:=punit_def_record(savo.objlst[j].info).y_pos;
    end;
   end else begin u.x:=un.x_pos;u.y:=un.y_pos;end;
                                  
   //Move target
   mov:=false;
   if un.pathobj.ob<>0 then if savo.objlst[un.pathobj.ob].tp=4 then mov:=true;
   if mov then begin 
    pth:=savo.objlst[un.pathobj.ob].info;
    u.xt:=pth.target_x;
    u.yt:=pth.target_y;
   end else begin 
    u.xt:=u.x;
    u.yt:=u.y;
   end; 
   //Prior pos
   u.prior_x:=un.x_pos;u.prior_y:=un.y_pos;
   for n:=0 to max_plr-1 do u.in_lock[n]:=false;

   //cur_siz
   if(un.is_build_n<>0)and(uninames[un.unid][3][1]='U')then begin
    u.cur_siz:=ord(uninames[un.build_unit_num[0]][3][2])-ord('0');
   end else u.cur_siz:=ord(uninames[un.unid][3][2])-ord('0');
  
   u.mox:=0;u.moy:=0;
   u.rot:=un.rot;
   u.grot:=un.gun_rot;
   u.alt:=0;
   u.vel:=0;

   if mov then u.is_moving:=true else u.is_moving:=false;
   u.is_moving_now:=false;
   u.isact  :=true;
   u.strtmov:=false;
   u.stpmov :=false;
   u.stlmov :=false;
   if mov then u.isstd:=true else u.isstd:=false;
   u.isauto:=false;
   u.is_sentry:=true;
  
   u.isclrg:=false;
   u.stored:=un.is_stored<>0;
   u.stored_in:=un.inside_obj.ob;

   if (savo.objlst[un.object_used.ob].info<>nil)and(savo.objlst[un.object_used.ob].tp=6) then begin     
    u.bas.speed:=punit_pars_record(savo.objlst[un.object_used.ob].info)^.speed;
    u.bas.hits :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.hits;
    u.bas.armr :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.armr;
    u.bas.attk :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.attk;
    u.bas.shoot:=punit_pars_record(savo.objlst[un.object_used.ob].info)^.shot;
    u.bas.fuel :=0;
    u.bas.range:=punit_pars_record(savo.objlst[un.object_used.ob].info)^.range;
    u.bas.scan :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.scan;
    u.bas.cost :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.cost;
    u.bas.ammo :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.ammo;  
    u.bas.area :=0;
   end else zero_stats(u.bas);
   u.disabled_for:=0;

   for ri:=RES_MIN to RES_MAX do begin
    u.prod.now[ri]:=0;
    u.prod.dbt[ri]:=0;
   end;

   if un.unid in [6,40,49,56,59,61,62,63,74,75] then u.prod.now[RES_MAT]:=un.cargonow else u.prod.now[RES_MAT]:=0;
   if un.unid in [7,64] then u.prod.now[RES_FUEL]:=un.cargonow else u.prod.now[RES_FUEL]:=0;
   if un.unid in [8,60] then u.prod.now[RES_GOLD]:=un.cargonow else u.prod.now[RES_GOLD]:=0;

   //Current state
   if (savo.objlst[un.object_used.ob].info<>nil)and(savo.objlst[un.object_used.ob].tp=6) then begin     
    u.cur.speed:=un.speednow*10;
    u.cur.hits :=un.hitsnow;
    u.cur.armr :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.armr;
    u.cur.attk :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.attk;
    u.cur.shoot:=un.shotnow;
    u.cur.fuel :=0;
    u.cur.range:=punit_pars_record(savo.objlst[un.object_used.ob].info)^.range;
    u.cur.scan :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.scan;
    u.cur.cost :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.cost;
    u.cur.ammo :=punit_pars_record(savo.objlst[un.object_used.ob].info)^.ammo;
    u.cur.area :=0;   
   end else begin   
    u.cur.speed:=un.speednow*10;
    u.cur.hits :=un.hitsnow;
    u.cur.armr :=0;
    u.cur.attk :=0;
    u.cur.shoot:=un.shotnow;
    u.cur.fuel :=0;
    u.cur.range:=0;
    u.cur.scan :=0;
    u.cur.cost :=0;
    u.cur.ammo :=0;
    u.cur.area :=0; 
   end;
   
   //u.firing_at.x:=0;u.firing_at.y:=0;
   u.stop_task:=stsk_none;u.stop_target:=0;u.stop_param:=0;
   u.stop_task_pending:=false;
   for n:=0 to max_plr-1 do u.stealth_detected[n]:=0;
   u.triggered_auto_fire:=false;
   u.clrturns:=0;u.clr_unit:=0;u.clr_tape:=0;u.clrval:=0;
  
   //Build
   if un.is_build_n<>0 then begin
    if uninames[un.unid][3][1]='U' then begin  
     u.isbuild:=true;
     u.isbuildfin:=false;
     u.builds_cnt:=1;   
     
     n:=0;
   
     u.builds[n].typ:=lowercase(uninames[un.build_unit_num[0]][2]);
     u.builds[n].typ_db:=getdbnum(gam,u.builds[n].typ);                      
     u.builds[n].x:=un.x_pos;
     u.builds[n].y:=un.y_pos;    
     u.builds[n].sz:=1+ord(uninames[un.build_unit_num[0]][3][2]='2');  
                   
     u.builds[n].left_turns:=un.turns_left_base; 
     u.builds[n].given_speed:=un.bld_speed;
     //-----FIXME-----Ot baldy-------
     u.builds[n].left_to_build:=3;
     u.builds[n].left_mat:=3;
     u.builds[n].cur_use:=3;
     u.builds[n].cur_take:=3;   
     u.builds[n].cur_speed:=un.bld_speed;  
     //-----FIXME-----Ot baldy-------
     
     u.builds[n].rept:=false; 
     u.builds[n].reverse:=false;
                                
     u.builds[n].base:=0;
     //c:=0;
     //for j:=i-1 downto savo.unitstart do if(savo.objlst[j].tp=5)and(punit_def_record(savo.objlst[j].info).inside_obj.ob=i)then begin c:=j;break;end;
     u.builds[n].tape:=k-1;    
     u.builds[n].cones:=0;
    end else goto 1;
   end else begin
    1: 
    u.isbuild:=false;
    u.isbuildfin:=false;
    u.builds_cnt:=0; 
   end;                
   u.reserve:=0;
   u.researching:=0;   //FIXME: Xlate from save

   if u.num=-1 then begin
    gam.units[k]:=nil;
    dispose(u);
    xuni[i]:=-1;
   end;
   
   k:=k+1;
  end;
  units_cnt:=k;
  for i:=0 to k-1 do if gam.units[i]<>nil then if gam.units[i].stored then begin
   gam.units[i].stored_in:=xuni[gam.units[i].stored_in];
  end;
  
  postprocess_loaded_save(gam,1,0);
  //?   
  for i:=0 to k-1 do if gam.units[i]<>nil then rebalance_around(gam,gam.units[i].x,gam.units[i].y,gam.units[i].siz,nil);
 end;
 free_maxsave(savo);
 result:=true; 
 except result:=false;stderr('LoadSav','do_load_max_savefile');end;
end;
//############################################################################//
begin
end.  
//############################################################################//
