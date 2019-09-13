//############################################################################//
unit mgs_fetch;
interface    
uses asys,sysutils,strval,mgs_net,log,json
,mgrecs,mgl_common,mgl_json,mgl_attr,mgl_logs
,mgunits,mgproduct
,mgs_util,mgs_db
; 
//############################################################################// 
function fetch_clans(g:pgametyp):string;
function fetch_udb(g:pgametyp):string;
function fetch_resmap(g:pgametyp):string;
function fetch_passmap(g:pgametyp):string;
function fetch_units(g:pgametyp;js:pjs_node):string;
function fetch_ginfo(g:pgametyp):string;
function fetch_gstate(g:pgametyp):string;  
function fetch_log(g:pgametyp;js:pjs_node):string;
function fetch_cdata(g:pgametyp):string;    
function fetch_plrall(g:pgametyp):string;
function fetch_plrcomm(g:pgametyp):string;
function fetch_plrshort(g:pgametyp):string;
function do_land_player(g:pgametyp;js:pjs_node):string;
function do_end_turn(g:pgametyp;do_log:boolean):string;           
function do_surrender(g:pgametyp;do_log:boolean):string;
function set_cdata(g:pgametyp;js:pjs_node;do_log:boolean):string;
function do_add_comment(g:pgametyp;js:pjs_node):string;
//############################################################################//
implementation
//############################################################################//
function fetch_clans(g:pgametyp):string;
var i,n:integer;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 n:=length(g.clansdb);   
    
 result:=start_reply(MGSTATUS_OK)+',"clans":['+#$0A;
 for i:=0 to n-1 do begin
  result:=result+clan_to_json(@g.clansdb[i]);
  if i<>n-1 then result:=result+',';
  result:=result+#$0A;
 end;
 result:=result+']}'; 
end; 
//############################################################################//
function fetch_udb(g:pgametyp):string;
var i,n:integer;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 n:=length(g.unitsdb);   
    
 result:=start_reply(MGSTATUS_OK)+',"udb":['+#$0A;
 for i:=0 to n-1 do begin
  result:=result+unitsdb_to_json(@g.unitsdb[i],true,false);
  if i<>n-1 then result:=result+',';  
  result:=result+#$0A;
 end;
 result:=result+']}'; 
end;
//############################################################################//
function fetch_resmap(g:pgametyp):string;
var xs,ys,x,y,a,t:integer;
s:string;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 xs:=g.info.mapx; 
 ys:=g.info.mapy; 

 result:=start_reply(MGSTATUS_OK)+',"resmap":{';  
 result:=result+'"xsize":'+stri(xs)+',"ysize":'+stri(ys)+',"map":['+#$0A;
 for y:=0 to ys-1 do begin
  setlength(s,xs);
  for x:=0 to xs-1 do begin
   a:=g.resmap[x+y*g.info.mapx].amt;
   s[1+x]:=chr(a+ord('A'));
  end;
  result:=result+'"'+rle_map(s)+'",';
  for x:=0 to xs-1 do begin
   t:=g.resmap[x+y*g.info.mapx].typ;
   s[1+x]:=chr(t+ord('0'));
  end;
  result:=result+'"'+rle_map(s)+'"';
  if y<>ys-1 then result:=result+',';
  result:=result+#$0A;
 end;
 result:=result+']}}'; 
end;
//############################################################################//
function fetch_passmap(g:pgametyp):string;
var xs,ys,x,y,t:integer;
s:string;
c:char;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 xs:=g.info.mapx; 
 ys:=g.info.mapy; 
   
 result:=start_reply(MGSTATUS_OK)+',"passmap":{';  
 result:=result+'"xsize":'+stri(xs)+',"ysize":'+stri(ys)+',"map":['+#$0A;  
 setlength(s,xs);
 for y:=0 to ys-1 do begin
  for x:=0 to xs-1 do begin
   t:=g.passm[x+y*g.info.mapx];
   c:=chr(t+ord('0'));
   s[1+x]:=c;   
  end;
  result:=result+'"'+rle_map(s)+'"';
  if y<>ys-1 then result:=result+',';   
  result:=result+#$0A;
 end;
 result:=result+']}}'; 
end;     
//############################################################################//
function fetch_units(g:pgametyp;js:pjs_node):string;
var i,n,k:integer;
u:ptypunits;
cp:pplrtyp;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
   
 k:=js_get_node_length(js,'list');

 if fetch_debug then begin
  n:=0;
  for i:=0 to length(g.marks)-1 do if g.marks[i] then n:=n+1;
  if (k<>n)and(k<>0) then begin
   //writeln('need ',n,', fetched ',k);
   setlength(fetch_debug_list,n);
   n:=0;
   for i:=0 to length(g.marks)-1 do if g.marks[i] then begin
    fetch_debug_list[n]:=i;
    n:=n+1;
   end;
  end;
 end;

 clear_marks(g);

 cp:=get_cur_plr(g);
 if cp=nil then begin result:=nogame_reply;exit;end;
 
 if k=0 then begin
  n:=length(g.units);
  result:=start_reply(MGSTATUS_OK)+',"unit_count":"'+stri(length(g.units))+'","units":['+#$0A;
  for i:=0 to n-1 do begin     
   u:=nil;              
   if unave(g,i) then begin 
    if g.units[i].typ='nil' then g.units[i]:=nil;
    u:=g.units[i];
    if u<>nil then if not can_see(g,u.x,u.y,cp.num,u) and (cp.num<>u.own) then u:=nil;
   end;
   if u=nil then begin
    result:=result+'{"num":'+stri(i)+',"used":0}';
   end else begin
    result:=result+units_to_json(u);
   end;
   if i<>n-1 then result:=result+',';  
   result:=result+#$0A;
  end;
  result:=result+']}';
 end else begin
  result:=start_reply(MGSTATUS_OK)+',"unit_count":"'+stri(length(g.units))+'","units":['+#$0A;
  for i:=0 to k-1 do begin
   n:=vali(js_get_string(js,'list['+stri(i)+']'));
   u:=nil;    
   if unave(g,n) then begin 
    u:=g.units[n];
    if not can_see(g,u.x,u.y,cp.num,u) and (cp.num<>u.own) then u:=nil;
   end;
   if u=nil then begin
    result:=result+'{"num":'+stri(n)+',"used":0}';
   end else begin
    result:=result+units_to_json(u);
   end;
   if i<>k-1 then result:=result+',';  
   result:=result+#$0A;
  end;
  result:=result+']}';
 end;
end;    
//############################################################################//
function fetch_ginfo(g:pgametyp):string;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 result:=start_reply(MGSTATUS_OK)+',"game_info":'+ginfo_to_json(@g.info)+'}'; 
end;  
//############################################################################//
function fetch_gstate(g:pgametyp):string;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 result:=start_reply(MGSTATUS_OK)+',"game_state":'+gstate_to_json(@g.state)+'}'; 
end;
//############################################################################//
function fetch_plrshort(g:pgametyp):string;
var i,n:integer;
begin
 if g=nil then begin result:=nogame_reply;exit;end;

 n:=g.info.plr_cnt;   
    
 result:=start_reply(MGSTATUS_OK)+',"plr_short":['+#$0A;
 for i:=0 to n-1 do begin
  result:=result+pall_to_json(g,@g.plr[i],false,true);
  if i<>n-1 then result:=result+',';   
  result:=result+#$0A;
 end;
 result:=result+']}'; 
end;
//############################################################################//
function fetch_plrall(g:pgametyp):string;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 result:=start_reply(MGSTATUS_OK)+',"plr":'+pall_to_json(g,get_cur_plr(g),false,false)+'}';
end;
//############################################################################//
function fetch_plrcomm(g:pgametyp):string;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 result:=start_reply(MGSTATUS_OK)+',"plr_comm":'+pcomm_to_json(g,get_cur_plr(g))+'}';
end;
//############################################################################//
function fetch_log(g:pgametyp;js:pjs_node):string;
var i,n,k:integer;
cp:pplrtyp;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 cp:=get_cur_plr(g);    
 if cp=nil then begin result:=nogame_reply;exit;end;
 
 k:=vali(js_get_string(js,'from'));
 n:=length(cp.logmsg);   
 result:=start_reply(MGSTATUS_OK)+',"from":"'+stri(k)+'","log":['+#$0A;
 for i:=k to n-1 do begin
  result:=result+log_to_json(@cp.logmsg[i]);
  if i<>n-1 then result:=result+',';    
  result:=result+#$0A;
 end;
 result:=result+']}'; 
end;  
//############################################################################//
function fetch_cdata(g:pgametyp):string;
var cp:pplrtyp;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 cp:=get_cur_plr(g);
 if cp=nil then begin result:=nogame_reply;exit;end;
 result:=start_reply(MGSTATUS_OK)+',"cdata":['+cp.client_data+']}'; 
end;
//############################################################################//
function do_land_player(g:pgametyp;js:pjs_node):string;
var ng:player_start_rec;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 if g.state.status=GST_ENDGAME then begin result:=nogame_reply;exit;end;
 if vali(js_get_string(js,'num'))<>get_cur_plr_id(g) then begin
  result:=start_reply(MGSTATUS_ERR)+',"error":"Wrong player"}'; 
  exit;
 end;
 
 ng:=pstart_from_json(g,js_get_node(js,'start'));
 if not land_player(g,@ng) then begin      
  result:=start_reply(MGSTATUS_ERR)+',"error":"Some landing error"}'; 
 end else begin
  do_landing_request(g);
  result:=start_reply(MGSTATUS_OK)+',"game_state":'+gstate_to_json(@g.state)+'}'; 
 end;
end;   
//############################################################################//
function do_end_turn(g:pgametyp;do_log:boolean):string;
var r:boolean;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
    
 r:=do_end_turn_request(g,false,false);
 if not r then run_the_loop(g);

 if do_log then sync_one_games(g.remote_id,false,true);
 result:=start_reply(MGSTATUS_OK)+',"changeover":'+stri(ord(r))+',"game_state":'+gstate_to_json(@g.state)+event_result(g)+'}'; 
end;
//############################################################################//
function do_surrender(g:pgametyp;do_log:boolean):string;
var r:boolean;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
          
 surrender_current_player(g);  
 r:=do_end_turn_request(g,true,false);
 if not r then run_the_loop(g);

 if g.state.status=GST_ENDGAME then begin
  result:=start_reply(MGSTATUS_OK)+',"finish":1,"changeover":'+stri(ord(r))+',"game_state":'+gstate_to_json(@g.state)+event_result(g)+'}'; 
  //make_game_finished(g.remote_id,true);   //Should be in game_store, or the surrender event won't get stored.
 end else begin 
  if do_log then sync_one_games(g.remote_id,false,true);
  result:=start_reply(MGSTATUS_OK)+',"finish":0,"changeover":'+stri(ord(r))+',"game_state":'+gstate_to_json(@g.state)+event_result(g)+'}'; 
 end;
end;
//############################################################################//
function set_cdata(g:pgametyp;js:pjs_node;do_log:boolean):string;
var cp:pplrtyp;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 cp:=get_cur_plr(g);
 if cp=nil then begin result:=nogame_reply;exit;end;

 cp.client_data:=js_get_string(js,'cdata');
 if do_log then sync_one_games(g.remote_id,false,true);
 result:=start_reply(MGSTATUS_OK)+'}';
end;
//############################################################################//
function do_add_comment(g:pgametyp;js:pjs_node):string;
var cp:pplrtyp;
com:comment_typ;
begin
 if g=nil then begin result:=nogame_reply;exit;end;
 cp:=get_cur_plr(g);
 if cp=nil then begin result:=nogame_reply;exit;end;

 com:=comment_from_json(js_get_node(js,'comment'));
 if com.typ=0 then add_comment(g,cp,com.x,com.y,com.text)
              else add_comment(g,nil,com.x,com.y,com.text);

 result:=start_reply(MGSTATUS_OK)+'}';
end;
//############################################################################//
begin
end.   
//############################################################################//
