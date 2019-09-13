//############################################################################//
//Made by Artyom Litvinovich in 2003-2013
//MaxGold core data loading routines
//############################################################################//
unit mgloads;
interface
uses sysutils,asys,vfsint,strval,strtool,mgrecs,mgvars,mgauxi,mgress,mgl_scan,mgl_common,mgl_unu,mgl_json,json;
//############################################################################//
procedure getmaps;
procedure load_def_rules;
function  loadmap(g:pgametyp;mapname:string):boolean;  

function set_uniset(g:pgametyp;name:string):boolean;

procedure set_player_dyn_info(g:pgametyp;i:integer);  
procedure clear_player_dyn_info(g:pgametyp;i:integer);  
procedure make_blank_game(g:pgametyp);
procedure loadunisets;    
procedure clear_units(g:pgametyp);  
procedure clear_game(g:pgametyp);         
procedure dispose_game(g:pgametyp);

procedure clear_player_info(g:pgametyp;i:integer);  
//############################################################################//
implementation
//############################################################################//
//Load minimaps and map list
procedure getmaps;
var i,lng,n:integer;
nam,dir:string;
l:avdir;
js:pjs_node;
begin l:=nil; try    
 tolog('MGAInit','Checking maps');
 
 dir:=mgrootdir+mg_core.maps_dir+'/';
 l:=vffind_arr(dir+'*.txt',attall);
 lng:=length(l);
 setlength(mg_core.map_list,lng);
      
 n:=0;
 for i:=0 to lng-1 do begin
  nam:=lowercase(copy(l[i].name,1,length(l[i].name)-4));
  mg_core.map_list[n].file_name:=nam;
  mg_core.map_list[n].name:=nam;  
  mg_core.map_list[n].descr:='';
  if vfexists(dir+nam+'.txt') then n:=n+1;
 end;
                                                     
 setlength(mg_core.map_list,n);
 
 for i:=0 to n-1 do begin
  js:=map_file_open(dir+mg_core.map_list[i].file_name+'.txt',false);
  if js=nil then continue; 
 
  //if mg_core.language='eng' then begin
   mg_core.map_list[i].descr:=js_get_string(js,'description_eng'); 
   mg_core.map_list[i].name:=js_get_string(js,'name_eng'); 
  //end; 

  free_js(js);
 end;
 
 except stderr('LoadSav','GetMaps');end;
end;
//############################################################################//
//Load the map in full
function loadmap(g:pgametyp;mapname:string):boolean;
var dir,nam:string; 
i,n:integer;
map:array of word;
js:pjs_node;
begin try
 result:=false;
 dir:=mgrootdir+mg_core.maps_dir+'/';
 nam:=lowercase(mapname);

 g.info.mapx:=0;
 g.info.mapy:=0;
 n:=-1;
 for i:=0 to length(mg_core.map_list)-1 do if mg_core.map_list[i].file_name=nam then begin n:=i; break; end;
 if n=-1 then exit;

 js:=map_file_open(dir+nam+'.txt',false);
 if js=nil then begin tolog('LoadSav','Error loading map');exit;end;
 g.info.mapx:=vali(js_get_string(js,'width'));
 g.info.mapy:=vali(js_get_string(js,'height'));
 setlength(map,g.info.mapx*g.info.mapy);
 setlength(g.passm,g.info.mapx*g.info.mapy);
 map_file_get_map(js,@map[0]);
 map_file_get_passability(js,@map[0],@g.passm[0]);
 free_js(js);
 
 result:=true;

 except result:=false;stderr('LoadSav','LoadMap');end;
end;
//############################################################################// 
procedure sortunitsdb(g:pgametyp);
var i,j,k,last,num,pos:integer;   
udb:array of typunitsdb;
udb_used:array of boolean;
begin
 //Merge updated ones in uniset      
 for i:=0 to g.info.unitsdb_cnt-1 do begin
  for j:=i+1 to g.info.unitsdb_cnt-1 do begin
   if g.unitsdb[i].typ=g.unitsdb[j].typ then begin
    g.unitsdb[i]:=g.unitsdb[j];
    for k:=j to g.info.unitsdb_cnt-2 do g.unitsdb[k]:=g.unitsdb[k+1];
    g.info.unitsdb_cnt:=g.info.unitsdb_cnt-1;
   end;                                 
   if j>=g.info.unitsdb_cnt-1 then break;
  end;
  if i>=g.info.unitsdb_cnt-1 then break;
 end;
 
 //Sort uniset by num
 setlength(udb,g.info.unitsdb_cnt);
 setlength(udb_used,g.info.unitsdb_cnt);
 for i:=0 to g.info.unitsdb_cnt-1 do udb[i]:=g.unitsdb[i];
 for i:=0 to g.info.unitsdb_cnt-1 do udb_used[i]:=true;
 
 last:=0;
 pos:=0;
 for i:=0 to g.info.unitsdb_cnt-1 do begin
  num:=100000;
  for j:=0 to g.info.unitsdb_cnt-1 do if (udb[j].ord<num)and(udb[j].ord>=last)and(udb_used[j]) then begin
   num:=udb[j].ord;
   pos:=j;
  end;
  g.unitsdb[i]:=udb[pos];
  udb_used[i]:=udb_used[pos];
  udb_used[pos]:=false;
  last:=num;
 end;  
 setlength(udb,0);
 setlength(udb_used,0);

 setlength(g.unitsdb,g.info.unitsdb_cnt);
 for i:=0 to g.info.unitsdb_cnt-1 do g.unitsdb[i].num:=i;
end;
//############################################################################//
procedure loadunisets;
var dirf,str1,s,st:string;
l:avdir;
i,j,c,sz,n:integer;
f:vfile;    
 
js:pjs_node;
begin l:=nil; try
 str1:=mg_core.units_dir+'/';
 dirf:=mgrootdir+str1;
 l:=vffind_arr(dirf+'*.txt',attall);
 
 setlength(mg_core.unitsets,0);
 c:=0;
 for j:=0 to length(l)-1 do if l[j].name[1]<>'.' then begin
  if vfopen(f,dirf+l[j].name,VFO_READ)<>VFERR_OK then continue;
  sz:=vffilesize(f);
  setlength(s,sz);  
  vfread(f,@s[1],sz);   
  vfclose(f);
  js:=js_parse(s);
  if js=nil then continue;

  setlength(mg_core.unitsets,c+1);

  st:=l[j].name;
  i:=getlsymp(st,'.');
  if i<>0 then st:=copy(st,1,i-1);
  mg_core.unitsets[c].name:=st;   
  mg_core.unitsets[c].initial_res:=default_initial_res; 
  if js_get_node(js,'res')<>nil then mg_core.unitsets[c].initial_res:=initres_from_json(js_get_node(js,'res'));    
  mg_core.unitsets[c].descr_rus:=js_get_string(js,'desc_rus');
  mg_core.unitsets[c].descr_eng:=js_get_string(js,'desc_eng');
  
  n:=js_get_node_length(js,'clans');   
  setlength(mg_core.unitsets[c].clansdb,n);  
  for i:=0 to n-1 do mg_core.unitsets[c].clansdb[i]:=clan_from_json(js_get_node(js,'clans['+stri(i)+']'));
 
  n:=js_get_node_length(js,'udb');  
  setlength(mg_core.unitsets[c].unitsdb,n);  
  for i:=0 to n-1 do mg_core.unitsets[c].unitsdb[i]:=unitsdb_from_json(js_get_node(js,'udb['+stri(i)+']')); 

  c:=c+1;

  free_js(js);
 end;
 except stderr('LoadSav','loadunitssets');end;
end;   
//############################################################################//               
function set_uniset(g:pgametyp;name:string):boolean;
var i,c,n:integer;  
pl:pplrtyp;
begin result:=false;try
 g.info.unitsdb_cnt:=0;
 setlength(g.clansdb,0);
 setlength(g.unitsdb,0);
 g.initial_res:=default_initial_res;

 c:=-1;
 for i:=0 to length(mg_core.unitsets)-1 do if mg_core.unitsets[i].name=name then begin c:=i;break;end;
 if c=-1 then exit;

 n:=length(mg_core.unitsets[c].clansdb);
 if n<>0 then begin
  setlength(g.clansdb,n);
  for i:=0 to n-1 do g.clansdb[i]:=mg_core.unitsets[c].clansdb[i];
 end;

 n:=length(mg_core.unitsets[c].unitsdb);   
 setlength(g.unitsdb,g.info.unitsdb_cnt+n);    
 for i:=g.info.unitsdb_cnt to g.info.unitsdb_cnt+n-1 do g.unitsdb[i]:=mg_core.unitsets[c].unitsdb[i-g.info.unitsdb_cnt];  
 g.info.unitsdb_cnt:=g.info.unitsdb_cnt+n;    

 g.initial_res:=mg_core.unitsets[c].initial_res;

 sortunitsdb(g);

 for i:=0 to get_plr_count(g)-1 do begin
  pl:=get_plr(g,i);
  setlength(pl.u_num,g.info.unitsdb_cnt);
  setlength(pl.u_cas,g.info.unitsdb_cnt);
  fillchar(pl.u_num[0],sizeof(pl.u_num[0])*g.info.unitsdb_cnt,0);
  fillchar(pl.u_cas[0],sizeof(pl.u_cas[0])*g.info.unitsdb_cnt,0);
 end;
 
 result:=true;
 
 except stderr('LoadSav','set_uniset');end;
end;
//############################################################################//
//############################################################################//
//Load rules.cfg
procedure load_def_rules;
var sz:integer;
js:pjs_node;
fn,s:string;
f:vfile;
begin js:=nil; try
 tolog('MGAInit','Loading default rules');
 fn:='';
 if vfexists(mgrootdir+mg_core.base_dir+'def_rules.txt') then begin
  fn:=mgrootdir+mg_core.base_dir+'def_rules.txt';
 end else begin
  if vfexists(mgrootdir+'maxgold/'+mg_core.base_dir+'def_rules.txt') then begin
   fn:=mgrootdir+'maxgold/'+mg_core.base_dir+'def_rules.txt';
  end else exit; 
 end;
 if fn='' then exit;

 if vfopen(f,fn,VFO_READ)<>VFERR_OK then exit;
 sz:=vffilesize(f);
 setlength(s,sz);
 vfread(f,@s[1],sz);
 vfclose(f);

 js:=js_parse(s);
 if js=nil then exit;

 s:=js_get_string(js,'uniset');           if s<>'nil' then mg_core.rules_def.uniset:=s;                     //Unit set
 s:=js_get_string(js,'debug');            if s<>'nil' then mg_core.rules_def.debug:=vali(s)<>0;             //Debug mode
 s:=js_get_string(js,'mor_turns');        if s<>'nil' then mg_core.rules_def.moratorium:=vali(s);           //Moratorium duration
 s:=js_get_string(js,'mor_range');        if s<>'nil' then mg_core.rules_def.moratorium_range:=vali(s);     //Moratorium range
 s:=js_get_string(js,'res_set');          if s<>'nil' then mg_core.rules_def.resset:=vali(s);               //Resource spots
 s:=js_get_string(js,'gold_set');         if s<>'nil' then mg_core.rules_def.goldset:=vali(s);              //Initial gold
 s:=js_get_string(js,'start_with_radar'); if s<>'nil' then mg_core.rules_def.startradar:=vali(s)<>0;        //Radar by default on landing
 s:=js_get_string(js,'direct_land');      if s<>'nil' then mg_core.rules_def.direct_land:=vali(s)<>0;       //Place units on landing
 s:=js_get_string(js,'no_survey');        if s<>'nil' then mg_core.rules_def.no_survey:=vali(s)<>0;         //All resources open from the start
 s:=js_get_string(js,'fuel');             if s<>'nil' then mg_core.rules_def.fueluse:=vali(s)<>0;           //Fuel mode. 0 - no fuel
 s:=js_get_string(js,'fuel_xfer');        if s<>'nil' then mg_core.rules_def.fuelxfer:=vali(s)<>0;          //Fuel transfer. 0 - disabled
 s:=js_get_string(js,'fuel_shot');        if s<>'nil' then mg_core.rules_def.fuel_shot:=vali(s)<>0;         //Need fuel for firing
 s:=js_get_string(js,'unloading');                                                                          //Flags: 0 - M.A.X., 1 - lose all speed, 2 - lose all shots, 4 - lose one speed, 8 - lose one speed on load, 16 - load/unload on pads only
 if s<>'nil' then begin
  mg_core.rules_def.unload_all_shots  :=(vali(s) and 1)=1;
  mg_core.rules_def.unload_all_speed  :=(vali(s) and 2)=2;
  mg_core.rules_def.unload_one_speed  :=(vali(s) and 4)=4;
  mg_core.rules_def.load_sub_one_speed:=(vali(s) and 8)=8;
  mg_core.rules_def.load_onpad_only   :=(vali(s) and 16)=16;
 end;
 s:=js_get_string(js,'no_military_buys'); if s<>'nil' then mg_core.rules_def.no_buy_atk:=vali(s)<>0;        //Can not land attack-capable units
 s:=js_get_string(js,'expensive_refuel'); if s<>'nil' then mg_core.rules_def.expensive_refuel:=vali(s)<>0;  //Takes more then 1 fuel to refuel
 s:=js_get_string(js,'direct_gold');      if s<>'nil' then mg_core.rules_def.direct_gold:=vali(s)<>0;       //No gold refining, upgrades directly on accumulated raw gold
 s:=js_get_string(js,'lay_connectors');   if s<>'nil' then mg_core.rules_def.lay_connectors:=vali(s)<>0;    //Connectors are laid like mines
 s:=js_get_string(js,'center_4x_scan');   if s<>'nil' then mg_core.rules_def.center_4x_scan:=vali(s)<>0;    //Scan originates in the center of 2x2 building instead of upper-left corner

 //UT factors
 s:=js_get_string(js,'hits');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_hits ]:=vali(s);
 s:=js_get_string(js,'armor');            if s<>'nil' then mg_core.rules_def.ut_factors[ut_armor]:=vali(s);
 s:=js_get_string(js,'ammo');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_ammo ]:=vali(s);
 s:=js_get_string(js,'attk');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_attk ]:=vali(s);
 s:=js_get_string(js,'speed');            if s<>'nil' then mg_core.rules_def.ut_factors[ut_speed]:=vali(s);
 s:=js_get_string(js,'shot');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_shot ]:=vali(s);
 s:=js_get_string(js,'range');            if s<>'nil' then mg_core.rules_def.ut_factors[ut_range]:=vali(s);
 s:=js_get_string(js,'scan');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_scan ]:=vali(s);
 s:=js_get_string(js,'fuel');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_fuel ]:=vali(s);
 s:=js_get_string(js,'cost');             if s<>'nil' then mg_core.rules_def.ut_factors[ut_cost ]:=vali(s);

 //Resource richness
 s:=js_get_string(js,'res_mat');          if s<>'nil' then mg_core.rules_def.res_levels[1]:=vali(s);
 s:=js_get_string(js,'res_fuel');         if s<>'nil' then mg_core.rules_def.res_levels[2]:=vali(s);
 s:=js_get_string(js,'res_gold');         if s<>'nil' then mg_core.rules_def.res_levels[3]:=vali(s);

 free_js(js);

 except stderr('LoadSav','load_def_rules');end;
end;                                             
//############################################################################//
procedure set_player_dyn_info(g:pgametyp;i:integer);  
var pl:pplrtyp;
n:integer;
begin     
 pl:=get_plr(g,i);  
 pl.num:=i;

 alloc_and_clear_plr_razved(pl,g.info.mapx,g.info.mapy);
 for n:=0 to SL_COUNT-1 do setlength(pl.scan_map[n],g.info.mapx*g.info.mapy);
 setlength(pl.resmp,g.info.mapx*g.info.mapy); 
 
 setlength(pl.unupd,g.info.unitsdb_cnt);
 setlength(pl.tmp_unupd,g.info.unitsdb_cnt);
 for n:=0 to g.info.unitsdb_cnt-1 do begin
  fillchar(pl.unupd[n],sizeof(typ_unupd),0);
  fillchar(pl.tmp_unupd[n],sizeof(typ_unupd),0);
 end;
end;
//############################################################################//
procedure clear_player_dyn_info(g:pgametyp;i:integer);  
var pl:pplrtyp;
n:integer;
begin
 pl:=get_plr(g,i);    
 pl.num:=i;
 
 pl.info.lndx:=-1;
 pl.info.lndy:=-1;
 pl.used:=true;
 pl.typ:=TP_HUMAN; 
 pl.info.bgncnt:=0;   

 setlength(pl.logmsg,0);
 for n:=0 to RS_COUNT-1 do pl.rsrch_spent[n]:=0;
 for n:=0 to RS_COUNT-1 do pl.rsrch_level[n]:=0;
 for n:=0 to RS_COUNT-1 do pl.rsrch_labs [n]:=0;
 for n:=0 to RS_COUNT-1 do pl.rsrch_left [n]:=0; 
end;     
//############################################################################//
procedure clear_player_info(g:pgametyp;i:integer);  
var pl:pplrtyp;
begin
 clear_player_dyn_info(g,i);
 pl:=get_plr(g,i);
 pl.used:=false;
 pl.num:=i;
 pl.info.color8:=i+1;
 pl.info.name:='plr'+stri(i+1);
 pl.gold:=250;
 pl.info.stgold:=250;
end;
//############################################################################//
procedure make_blank_game(g:pgametyp);
var i:integer;
begin
 g.info.game_name:='Game'; 
 g.state.status:=GST_SETGAME;
 g.state.turn:=0;
 g.info.rules:=mg_core.rules_def;
 g.state.mor_done:=true;
 g.info.descr:='No description';
 g.sew_cnt:=0;
 g.last_uid:=1;
 g.seed:=0;
 
 g.info.plr_cnt:=2;
 for i:=0 to get_plr_count(g)-1 do clear_player_info(g,i);
end;
//############################################################################//
procedure clear_units(g:pgametyp);
var i:integer;
begin try
 for i:=0 to get_units_count(g)-1 do if g.units[i]<>nil then begin
  finalize(g.units[i]^);
  dispose(g.units[i]);
  g.units[i]:=nil;
 end;
 setlength(g.units,0);
 clrunu(g);
 except stderr('MGA','clear_units');end;
end;
//############################################################################//
procedure dispose_game(g:pgametyp);
begin try
 clear_units(g);

 except stderr('MGA','clear_planet');end;
end;      
//############################################################################//
procedure clear_game(g:pgametyp);
var i,j:integer;
pl:pplrtyp;
begin try
 clear_units(g);
 g.state.cur_plr:=0;  
 alloc_unu(g);
 setunu(g);     
 for i:=0 to get_plr_count(g)-1 do begin
  pl:=get_plr(g,i);
  reset_scan(g,pl,true);
  //Zero the unit numbers and causalties
  for j:=0 to get_unitsdb_count(g)-1 do begin 
   pl.u_num[j]:=0;
   pl.u_cas[j]:=0;
  end;
 end; 
  
 except stderr('MGA','clear_planet');end;
end;     
//############################################################################//
begin
end.  
//############################################################################//
