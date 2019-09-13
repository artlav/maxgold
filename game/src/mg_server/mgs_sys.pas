//############################################################################//
unit mgs_sys;
interface    
uses asys,grph,sysutils,strval,mgs_net,log,json,vfsint,b64,lzw
,mgrecs,mgvars,mgl_common,mgl_json
,mgproduct
,mgs_util,mgs_db
;           
//############################################################################//
function get_unisets:string;
function get_maps:string;    
function get_games(js:pjs_node):string;
function get_def_rules:string;
function new_game(js:pjs_node;id:string;print:boolean):string;
function get_replay(js:pjs_node):string;  
function get_the_map(js:pjs_node):string;      
function get_minimap(js:pjs_node):string;      
function get_minimaps(js:pjs_node):string;
//############################################################################//
implementation
//############################################################################//
var minimaps_cached:string='';
//############################################################################//
function get_unisets:string;
var i,n:integer;
u:puniset_rec;
begin         
 n:=length(mg_core.unitsets);
 
 result:=start_reply(MGSTATUS_OK)+',"unisets":['+#$0A;
 for i:=0 to n-1 do begin
  u:=@mg_core.unitsets[i];
  result:=result+'{"name":"'+u.name+'","desc_rus":"'+u.descr_rus+'","desc_eng":"'+u.descr_eng+'"}';
  if i<>n-1 then result:=result+','; 
  result:=result+#$0A;
 end;
 result:=result+']}'; 
end;
//############################################################################//
function get_maps:string;
var i,n:integer;
nam,fn,desc:string;
begin         
 n:=length(mg_core.map_list);
 result:=start_reply(MGSTATUS_OK)+',"maps":['+#$0A;
 for i:=0 to n-1 do begin
  nam:=mg_core.map_list[i].name;
  fn:=mg_core.map_list[i].file_name;
  desc:=mg_core.map_list[i].descr;
  result:=result+'{"file_name":"'+fn+'","name":"'+nam+'","descr":"'+desc+'"}';
  if i<>n-1 then result:=result+','; 
  result:=result+#$0A;
 end;
 result:=result+']}'; 
end;
//############################################################################//
function get_games(js:pjs_node):string;
var i,n:integer;
finished:boolean;
g:pgame_db_rec;
begin    
 finished:=vali(js_get_string(js,'finished'))<>0;
 
 result:=start_reply(MGSTATUS_OK)+',"games":['+#$0A;
 n:=0;
 for i:=0 to length(games)-1 do begin
  g:=games[i];
  if g=nil then continue;
  if finished then if g.state.status<>GST_ENDGAME then continue;
  if not finished then if g.state.status=GST_ENDGAME then continue;
  if n<>0 then result:=result+','+#$0A;
  result:=result+'{"id":"'+g.id+'","cur_plr":"'+g.cur_plr+'","cur_color":"'+g.cur_color+'","game_info":'+ginfo_to_json(@g.info)+',"game_state":'+gstate_to_json(@g.state)+'}';
  n:=n+1;
 end;          
 result:=result+#$0A;
 result:=result+']}'; 
end;
//############################################################################//
function get_def_rules:string;
var r:rulestyp;
begin         
 r:=mg_core.rules_def;  
 result:=start_reply(MGSTATUS_OK)+',"rules":'+rules_to_json(@r)+'}'; 
end;
//############################################################################//
function new_game(js:pjs_node;id:string;print:boolean):string;
var ng:gamestart_rec;
g:pgametyp;
begin         
 ng:=newgame_from_json(js_get_node(js,'newgame'));
 g:=make_new_game(@ng,id,print);
 if g=nil then begin
  result:=nogame_reply;
 end else begin 
  result:=start_reply(MGSTATUS_OK)+',"game_id":"'+g.remote_id+'"}'; 
 end;
end;
//############################################################################//
function get_replay(js:pjs_node):string;
var id,s:string;     
g:pgametyp;
begin    
 result:=nogame_reply;

 id:=js_get_string(js,'game_id');  
           
 g:=game_by_id(id,false); 
 if g.state.status<>GST_ENDGAME then begin  
  result:=nogame_reply;
 end;
  
 s:=read_game_replay(id);
 if s<>'' then begin
  result:=start_reply(MGSTATUS_OK)+',"game_id":"'+id+'","size":"'+stri(length(s))+'","compressed_log":"'+compress_string(s)+'"}';
 end else begin
  result:=nogame_reply;
 end;
end;
//############################################################################//
function get_the_map(js:pjs_node):string;
var nam,dir,s:string;
f:vfile;
map,cmap:pointer;
csz,sz,osz:integer;
begin    
 result:=nogame_reply;

 nam:=js_get_string(js,'name');
 dir:=mgrootdir+mg_core.maps_dir+'/';
 if not vfexists(dir+nam+'.txt') then begin result:=nogame_reply;exit;end;
 if vfopen(f,dir+nam+'.txt',VFO_READ)<>VFERR_OK then begin result:=nogame_reply;exit;end;
 osz:=vffilesize(f);
 getmem(map,osz);
 vfread(f,map,osz);
 vfclose(f); 
                   
 getmem(cmap,osz);
 csz:=encodeLZW(map,cmap,osz,osz);

 setlength(s,csz*3);
 sz:=b64_enc(cmap,csz,@s[1],length(s),false);
 setlength(s,sz);

 result:=start_reply(MGSTATUS_OK)+',"name":"'+nam+'","size":"'+stri(osz)+'","map":"'+s+'"}';
 freemem(cmap);
end;
//############################################################################//
function minimap_to_string(nam:string):string;
var dir,s,pals:string;
cmap:pointer;
csz,sz,osz,i,xs,ys:integer;     
pal:pallette3;
mm:array of byte; 
js:pjs_node;
begin   
 result:=''; 
 dir:=mgrootdir+mg_core.maps_dir+'/';

 js:=map_file_open(dir+nam+'.txt',false);
 if js=nil then exit;  
 
 xs:=vali(js_get_string(js,'width'));
 ys:=vali(js_get_string(js,'height'));
 osz:=xs*ys;
 setlength(mm,osz);
 
 map_file_get_pal(js,pal);
 map_file_get_minimap(js,@mm[0]);

 free_js(js);

 pals:=''; 
 for i:=0 to 255 do begin
  if i<>0 then pals:=pals+',';
  pals:=pals+'['+stri(pal[i][CLRED])+','+stri(pal[i][CLGREEN])+','+stri(pal[i][CLBLUE])+']';
 end;
             
 getmem(cmap,osz);
 csz:=encodeLZW(@mm[0],cmap,osz,osz);

 setlength(s,csz*3);
 sz:=b64_enc(cmap,csz,@s[1],length(s),false);
 setlength(s,sz);

 result:='{"name":"'+nam+'","size":"'+stri(osz)+'","xs":"'+stri(xs)+'","ys":"'+stri(ys)+'","pal":['+pals+'],"minimap":"'+s+'"}';
 freemem(cmap);
end;
//############################################################################//
function get_minimap(js:pjs_node):string;
var nam,s:string;
begin    
 result:=nogame_reply;

 nam:=js_get_string(js,'name');

 s:=minimap_to_string(nam);
 if s='' then exit;

 result:=start_reply(MGSTATUS_OK)+','+copy(s,2,length(s));
end;
//############################################################################//
function get_minimaps(js:pjs_node):string;
var i,n:integer;
nam:string;
begin
 if minimaps_cached='' then begin
  wr_log('SYS','Caching minimaps...');
  n:=length(mg_core.map_list);
  for i:=0 to n-1 do begin
   nam:=mg_core.map_list[i].file_name;
   minimaps_cached:=minimaps_cached+minimap_to_string(nam);
   if i<>n-1 then minimaps_cached:=minimaps_cached+',';
   minimaps_cached:=minimaps_cached+#$0A;
  end; 
  wr_log('SYS','Minimaps cached');
 end;

 result:=start_reply(MGSTATUS_OK)+',"minimaps":['+#$0A+minimaps_cached+']}';
end;
//############################################################################//
begin
end.   
//############################################################################//
