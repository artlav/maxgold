//############################################################################//
//Made by Artyom Litvinovich in 2003-2013
//MaxGold core saves loading routines
//############################################################################//
unit mgsaveload;
interface
uses asys,vfsint,strval,mgrecs,mgvars,mgauxi,mgloads,mgress,mgunits,mgl_common,mgl_scan,mgl_unu,mgl_land,mgl_json,json;
//############################################################################//  
procedure set_plr_default_begins(g:pgametyp;pl:pplrtyp);

function  load_game_file(fn:string):pgametyp; 
function  load_savegame(var s:string):pgametyp;

function  form_save_game(g:pgametyp):string;
procedure save_game_file(g:pgametyp;fn:string);  
   
function  init_new_game(gs:pgamestart_rec;seed:dword):pgametyp;
//############################################################################//
implementation        
//############################################################################//
procedure set_plr_default_begins(g:pgametyp;pl:pplrtyp);
var j:integer;
begin  
 if pl=nil then exit;
 for j:=0 to MAX_PLR-1 do pl.allies[j]:=false;
 pl.gold:=pl.info.stgold;

 plr_set_default_begins(pl.info,g.info.rules);
end;
//############################################################################//
//Save game
function form_save_game(g:pgametyp):string;
var s,info,state,plr,udb,resmap,passmap,clans,units,initres:string;
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
 initres:=initres_to_json(g.initial_res);
 
 n:=length(g.clansdb);      
 clans:='['+#$0A;for i:=0 to n-1 do begin clans:=clans+clan_to_json(@g.clansdb[i]);if i<>n-1 then clans:=clans+',';clans:=clans+#$0A;end;clans:=clans+']'; 
 
 n:=length(g.unitsdb);
 udb:='['+#$0A;for i:=0 to n-1 do begin udb:=udb+unitsdb_to_json(@g.unitsdb[i],true,false);if i<>n-1 then udb:=udb+',';udb:=udb+#$0A;end;udb:=udb+']'; 
 
 n:=g.info.plr_cnt;
 plr:='['+#$0A;for i:=0 to n-1 do begin plr:=plr+pall_to_json(g,@g.plr[i],true,false);if i<>n-1 then plr:=plr+',';plr:=plr+#$0A;end;plr:=plr+']'; 

 resmap:='['+#$0A;
 for y:=0 to ys-1 do begin
  setlength(s,xs);
  for x:=0 to xs-1 do begin
   a:=g.resmap[x+y*g.info.mapx].amt;
   s[1+x]:=chr(a+ord('A'));
  end;
  resmap:=resmap+'"'+rle_map(s)+'",';
  for x:=0 to xs-1 do begin
   t:=g.resmap[x+y*g.info.mapx].typ;
   s[1+x]:=chr(t+ord('0'));
  end;
  resmap:=resmap+'"'+rle_map(s)+'"';
  if y<>ys-1 then resmap:=resmap+',';
  resmap:=resmap+#$0A;
 end;
 resmap:=resmap+']'; 
 
 passmap:='['+#$0A;  
 setlength(s,xs);
 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   t:=g.passm[x+y*g.info.mapx];
   c:=chr(t+ord('0'));
   s[1+x]:=c;   
  end;
  passmap:=passmap+'"'+rle_map(s)+'"';
  if y<>ys-1 then passmap:=passmap+',';
  passmap:=passmap+#$0A;
 end;
 passmap:=passmap+']'; 
   
 n:=length(g.units);
 units:='['+#$0A;
 for i:=0 to n-1 do begin     
  u:=nil;              
  if unave(g,i) then u:=g.units[i];
  if u=nil then begin
   units:=units+'{"used":0,"num":'+stri(i)+'}';
  end else begin
   units:=units+units_to_json(u);
  end;
  if i<>n-1 then units:=units+',';
  units:=units+#$0A;
 end;
 units:=units+']';
 
 s:='{'+#$0A;
 s:=s+'"remote_id":"'+g.remote_id+'",'+#$0A;
 s:=s+'"seed":"'+strhex(g.seed)+'",'+#$0A;
 s:=s+'"last_uid":"'+stri(g.last_uid)+'",'+#$0A;
 s:=s+'"info":'+info+','+#$0A;
 s:=s+'"state":'+state+','+#$0A;   
 s:=s+'"initres":'+initres+','+#$0A;
 s:=s+'"clans":'+clans+','+#$0A;
 s:=s+'"udb":'+udb+','+#$0A;
 s:=s+'"plr":'+plr+','+#$0A;
 s:=s+'"resmap":'+resmap+','+#$0A;
 s:=s+'"passmap":'+passmap+','+#$0A;
 s:=s+'"units":'+units+''+#$0A;
 s:=s+'}';
     
 result:=s;
 
 except stderr('LoadSav','form_save_game');end;
end;      
//############################################################################//
//Save game
procedure save_game_file(g:pgametyp;fn:string);
var f:vfile;
s:string;
begin try
 if g=nil then exit;
 
 s:=form_save_game(g);
 
 if vfopen(f,mgrootdir+mg_core.save_dir+'/'+fn,VFO_WRITE)<>VFERR_OK then exit;
 vfwrite(f,@s[1],length(s));
 vfclose(f);

 except stderr('LoadSav','save_game');end;
end;     
//############################################################################//
function load_savegame(var s:string):pgametyp;
var g:pgametyp;  
js:pjs_node;
i,n,xs,ys,x,y:integer;
//save_ver:string;
pl:pplrtyp;
begin result:=nil; try   
 js:=js_parse(s);
 if js=nil then exit;
 
 new(result);
 g:=result;   
 fillchar(g^,sizeof(g^),0);  


 //save_ver:=js_get_string(js,'save_ver');    
 g.remote_id:=js_get_string(js,'remote_id');
 g.seed:=valhex(js_get_string(js,'seed'));
 g.last_uid:=vali(js_get_string(js,'last_uid'));
 
 g.info:=ginfo_from_json(js_get_node(js,'info'));
 g.state:=gstate_from_json(js_get_node(js,'state'));
 g.initial_res:=default_initial_res;
 if js_get_node(js,'initres')<>nil then g.initial_res:=initres_from_json(js_get_node(js,'initres'));  
 
          
 xs:=g.info.mapx; 
 ys:=g.info.mapy; 
          
 n:=js_get_node_length(js,'clans');   
 setlength(g.clansdb,n);  
 for i:=0 to n-1 do g.clansdb[i]:=clan_from_json(js_get_node(js,'clans['+stri(i)+']'));
 
 n:=js_get_node_length(js,'udb');  
 g.info.unitsdb_cnt:=n; 
 setlength(g.unitsdb,n);  
 for i:=0 to n-1 do g.unitsdb[i]:=unitsdb_from_json(js_get_node(js,'udb['+stri(i)+']')); 

 n:=js_get_node_length(js,'plr');  
 for i:=0 to n-1 do pall_from_json(g,@g.plr[i],js_get_node(js,'plr['+stri(i)+']'),false);
 
 setlength(g.resmap,xs*ys);  
 for y:=0 to ys-1 do begin
  s:=js_get_string(js,'resmap['+stri(y*2+0)+']');  
  s:=unrle_map(s,xs);
  if length(s)<xs then continue;
  for x:=0 to xs-1 do g.resmap[x+y*xs].amt:=ord(s[1+x])-ord('A');
  
  s:=js_get_string(js,'resmap['+stri(y*2+1)+']');      
  s:=unrle_map(s,xs);
  if length(s)<xs then continue;
  for x:=0 to xs-1 do g.resmap[x+y*xs].typ:=ord(s[1+x])-ord('0');
 end;
 

 setlength(g.passm,xs*ys);  
 for y:=0 to ys-1 do begin
  s:=js_get_string(js,'passmap['+stri(y)+']');
  s:=unrle_map(s,xs);
  if length(s)<xs then continue;
  for x:=0 to xs-1 do g.passm[x+y*xs]:=ord(s[1+x])-ord('0');
 end;

 n:=js_get_node_length(js,'units');  
 setlength(g.units,n);  
 for i:=0 to n-1 do begin
  g.units[i]:=nil;
  if vali(js_get_string(js,'units['+stri(i)+'].used'))<>0 then begin
   new(g.units[i]);
   g.units[i]^:=units_from_json(js_get_node(js,'units['+stri(i)+']'));
   if g.units[i].typ='nil' then begin
    dispose(g.units[i]);
    g.units[i]:=nil;
   end;
  end;
 end;

 for i:=0 to g.info.plr_cnt-1 do begin      
  pl:=get_plr(g,i);   
  for x:=0 to SL_COUNT-1 do begin
   setlength(pl.scan_map[x],g.info.mapx*g.info.mapy);
   fillchar(pl.scan_map[x][0],2*g.info.mapx*g.info.mapy,1);
  end;
 end;
         
 alloc_unu(g);
 setunu(g);

 //Pathfinding map
 setlength(g.pathing_map,g.info.mapx*g.info.mapy);

 for i:=0 to g.info.plr_cnt-1 do calc_scan_full(g,get_plr(g,i),false);

 refresh_domains(g);
 update_research(g);
 for i:=0 to g.info.plr_cnt-1 do calc_mining(g,i,false);

 clear_marks(g);
        
 free_js(js);
 
 except stderr('LoadSav','load_savegame');end;
end;      
//############################################################################//
function load_game_file(fn:string):pgametyp;
var f:vfile;
sz:integer;
s:string;
begin result:=nil; try 
  
 if vfopen(f,mgrootdir+mg_core.save_dir+'/'+fn,VFO_READ)=VFERR_OK then begin
  sz:=vffilesize(f);
  setlength(s,sz);
  vfread(f,@s[1],sz);
  vfclose(f);

  result:=load_savegame(s);
 end;
 
 except stderr('LoadSav','load_game_file');end;
end;
//############################################################################//
//Init new game in core
function init_new_game(gs:pgamestart_rec;seed:dword):pgametyp;
var i:integer;
pl:pplrtyp;
g:pgametyp;
begin result:=nil;try 
 new(result);
 g:=result;
 fillchar(g^,sizeof(g^),0);
 
 make_blank_game(g); 

 g.seed:=seed;
 g.info.rules:=gs.rules;
 g.info.map_name:=gs.map_name; 
 g.info.game_name:=gs.name; 
 g.info.plr_cnt:=gs.plr_cnt;
 for i:=0 to get_plr_count(g)-1 do begin  
  clear_player_info(g,i); 
  pl:=get_plr(g,i);  
  pl.info.stgold:=g.info.rules.goldset;
  pl.gold:=g.info.rules.goldset; 
  pl.info.name:=gs.plr_names[i];
 end;

 if not set_uniset(g,g.info.rules.uniset) then begin tolog('LoadSav','Cannot find uniset(s)');dispose_game(g);dispose(g);result:=nil;exit;end;
 if not loadmap(g,g.info.map_name)        then begin tolog('LoadSav','Cannot load map');      dispose_game(g);dispose(g);result:=nil;exit;end;
 
 clear_resources(g);
 if g.info.rules.direct_land then set_initial_resources(g);
 alloc_unu(g);

 //Pathfinding map
 setlength(g.pathing_map,g.info.mapx*g.info.mapy);
 
 g.state.mor_done:=g.info.rules.moratorium=0;
 g.state.cur_plr:=0;
 for i:=0 to get_plr_count(g)-1 do begin  
  pl:=get_plr(g,i); 
  pl.info.clan:=random(8);
  clear_player_dyn_info(g,i);
  set_player_dyn_info(g,i);  
  set_plr_default_begins(g,pl);
 end;        

 g.state.status:=GST_SETGAME;  
 
 except stderr('Init','InitGame');end;
end; 
//############################################################################//
begin
end.  
//############################################################################//
