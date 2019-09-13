//############################################################################//
unit sds_util;
interface
uses asys,strval,grph,json,sdirecs,sds_net,mgrecs,mgl_common,mgl_unu;
//############################################################################//
function make_game_request(g:pgametyp;req,par:string):string;
function make_game_load_request(req,par:string):string;
function make_sys_request(req,par:string):string;
procedure alloc_clean_game(g:pgametyp);               
procedure alloc_clean_clinfo(s:psdi_rec;g:pgametyp);
procedure alloc_clean_plr(s:psdi_rec;g:pgametyp;pl:pplrtyp);
function list_to_list(js:pjs_node;s:string):string; 

function cdata_to_json(r:pplr_client_info):string;         
function cdata_from_json(js:pjs_node):plr_client_info;
//############################################################################//
var passhash:string='D41D8CD98F00B204E9800998ECF8427E';
load_id:string='';
//############################################################################//
implementation
//############################################################################//
function make_game_request(g:pgametyp;req,par:string):string;
begin
 result:='{"code":"'+gs_code+'","game_id":"'+g.remote_id+'","pass":"'+passhash+'","request":"'+req+'"'+par+'}';
end;
//############################################################################//
function make_game_load_request(req,par:string):string;
begin
 result:='{"code":"'+gs_code+'","game_id":"'+load_id+'","pass":"'+passhash+'","request":"'+req+'"'+par+'}';
end;
//############################################################################//
function make_sys_request(req,par:string):string;
begin
 result:='{"code":"'+gs_code+'","request":"'+req+'"'+par+'}';
end;
//############################################################################//
procedure alloc_clean_game(g:pgametyp);
begin
 alloc_unu(g);

 setlength(g.passm,g.info.mapx*g.info.mapy);
 fillchar(g.passm[0],g.info.mapx*g.info.mapy,0);
 
 setlength(g.resmap,g.info.mapx*g.info.mapy);  
 fillchar(g.resmap[0],g.info.mapx*g.info.mapy*2,0);
end;   
//############################################################################//
procedure alloc_clean_clinfo(s:psdi_rec;g:pgametyp);
var i:integer;
plj:pplrtyp;
begin
 s.clinfo.sopt.sx:=s.mapx*XHCX;
 s.clinfo.sopt.sy:=s.mapy*XHCX;
 s.clinfo.sopt.zoom:=s.mainmap.maxzoom; 

 setlength(s.clinfo.custom_color,get_plr_count(g)+1);
 for i:=0 to get_plr_count(g)-1 do begin
  plj:=get_plr(g,i);
  s.clinfo.custom_color[i+1]:=thepal[plj.info.color8];
 end;

 setlength(s.clinfo.custom_color8,get_plr_count(g)+1);
 s.clinfo.custom_color8[0]:=238;  //Grid default color
 s.clinfo.custom_color[0]:=thepal[238];

 s.clinfo.sel_unit_uid:=0;
 s.clinfo.lck_mode:=false;
 setlength(s.clinfo.locked_uids,0);
end;  
//############################################################################//
procedure alloc_clean_plr(s:psdi_rec;g:pgametyp;pl:pplrtyp);
var i:integer;
begin
 alloc_unu(g);

 pl.used:=true;
 pl.typ:=TP_HUMAN; //FIXME: For the future

 pl.selunit:=-1;

 setlength(pl.resmp,g.info.mapx*g.info.mapy);
 fillchar(pl.resmp[0],g.info.mapx*g.info.mapy,1);

 for i:=0 to SL_COUNT-1 do begin
  setlength(pl.scan_map[i],g.info.mapx*g.info.mapy);
  fillchar(pl.scan_map[i][0],2*g.info.mapx*g.info.mapy,1);
 end;

 alloc_and_clear_plr_razved(pl,s.the_game.info.mapx,s.the_game.info.mapy);
end;
//############################################################################//
function list_to_list(js:pjs_node;s:string):string;
var i,n:integer;
first:boolean;
begin
 result:='';
 first:=true;
 n:=js_get_node_length(js,s);
 for i:=0 to n-1 do begin
  if not first then result:=result+',';
  result:=result+js_get_string(js,s+'['+stri(i)+']');
  if first then first:=false;
 end; 
end;
//############################################################################//
//############################################################################//
function campos_to_json(r:pcampostyp):string;
var s:string;
begin
 s:='{';  
 s:=s+'"x":"'+stri(r.x)+'",';
 s:=s+'"y":"'+stri(r.y)+'",';   
 s:=s+'"zoom":"'+stre(r.zoom)+'"';
 s:=s+'}'; 
 result:=s;  
end;
//############################################################################//
function campos_from_json(js:pjs_node):campostyp;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;
 
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.zoom:=vale(js_get_string(js,'zoom'));
end;
//############################################################################//
function sopt_to_json(r:pscreenopt_rec):string;
var s:string;
i:integer;
begin
 s:='{';  
 s:=s+'"sx":"'+stri(r.sx)+'",';
 s:=s+'"sy":"'+stri(r.sy)+'",';  
 s:=s+'"xm":"'+stri(r.xm)+'",';
 s:=s+'"ym":"'+stri(r.ym)+'",';   
 s:=s+'"zoom":"'+stre(r.zoom)+'",';  
 s:=s+'"framebtn":[';
 for i:=0 to length(r.frame_btn)-1 do begin
  s:=s+stri(r.frame_btn[i]);
  if i<>length(r.frame_btn)-1 then s:=s+',';
 end;
 s:=s+']';
 s:=s+'}'; 
 result:=s;  
end;    
//############################################################################//
function sopt_from_json(js:pjs_node):screenopt_rec;
var i:integer;
begin        
 fillchar(result,sizeof(result),0);
 if js=nil then exit;
 
 result.sx:=vali(js_get_string(js,'sx'));
 result.sy:=vali(js_get_string(js,'sy'));
 result.xm:=vali(js_get_string(js,'xm'));
 result.ym:=vali(js_get_string(js,'ym'));
 result.zoom:=vale(js_get_string(js,'zoom'));
 for i:=0 to length(result.frame_btn)-1 do result.frame_btn[i]:=vali(js_get_string(js,'framebtn['+stri(i)+']'));
end;   
//############################################################################//
function cdata_to_json(r:pplr_client_info):string;
var i:integer;
s:string;
begin         
 s:='{';

 //FIXME: Todo?
 //sel_stored:array[0..MAX_PRESEL-1] of array of integer; //Stored unit selections

 s:=s+'"lck_mode":"'+stri(ord(r.lck_mode))+'",';
 s:=s+'"sel_unit_uid":"'+stri(r.sel_unit_uid)+'",';
 s:=s+'"sopt":'+sopt_to_json(@r.sopt)+'",';
 s:=s+'"cam_pos":[';
 for i:=0 to length(r.cam_pos)-1 do begin
  s:=s+campos_to_json(@r.cam_pos[i]);
  if i<>length(r.cam_pos)-1 then s:=s+',';
 end;
 s:=s+'],';
 s:=s+'"custom_color":[';
 for i:=0 to length(r.custom_color)-1 do begin
  s:=s+strhex2(r.custom_color[i][0])+strhex2(r.custom_color[i][1])+strhex2(r.custom_color[i][2]);
  if i<>length(r.custom_color)-1 then s:=s+',';
 end;
 s:=s+'],';
 s:=s+'"custom_color8":[';
 for i:=0 to length(r.custom_color8)-1 do begin
  s:=s+stri(r.custom_color8[i]);
  if i<>length(r.custom_color8)-1 then s:=s+',';
 end;
 s:=s+'],';
 s:=s+'"locked_uids":[';
 for i:=0 to length(r.locked_uids)-1 do begin
  s:=s+stri(r.locked_uids[i]);
  if i<>length(r.locked_uids)-1 then s:=s+',';
 end;
 s:=s+']';
 s:=s+'}'; 
 result:=s;
end;          
//############################################################################//
function cdata_from_json(js:pjs_node):plr_client_info;
var i,n:integer; 
s:string; 
begin        
 finalize(result);
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.lck_mode:=vali(js_get_string(js,'lck_mode'))<>0;
 result.sel_unit_uid:=vali(js_get_string(js,'sel_unit_uid'));
 result.sopt:=sopt_from_json(js_get_node(js,'sopt'));
 n:=length(result.cam_pos); 
 for i:=0 to n-1 do result.cam_pos[i]:=campos_from_json(js_get_node(js,'cam_pos['+stri(i)+']'));  
 
 n:=js_get_node_length(js,'custom_color');
 setlength(result.custom_color,n); 
 for i:=0 to n-1 do begin
  s:=js_get_string(js,'custom_color['+stri(i)+']');
  result.custom_color[i][0]:=valhex(s[1]+s[2]);
  result.custom_color[i][1]:=valhex(s[3]+s[4]);
  result.custom_color[i][2]:=valhex(s[5]+s[6]);
 end;

 n:=js_get_node_length(js,'custom_color8');
 setlength(result.custom_color8,n);
 for i:=0 to n-1 do result.custom_color8[i]:=vali(js_get_string(js,'custom_color8['+stri(i)+']'));

 n:=js_get_node_length(js,'locked_uids');
 setlength(result.locked_uids,n);
 for i:=0 to n-1 do result.locked_uids[i]:=vali(js_get_string(js,'locked_uids['+stri(i)+']'));
end;   
//############################################################################//
begin
end.     
//############################################################################//
