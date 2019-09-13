//############################################################################//
unit mgl_json;
interface
uses asys,grph,maths,vfsint,strval,strtool,mgrecs,sds_rec,json,mgl_common,mgl_stats,mgl_unu,lzw,b64;
//############################################################################//
function rle_map(s:string):string;
function unrle_map(s:string;sz:integer):string;

function rules_from_json(js:pjs_node):rulestyp;
function rules_to_json(r:prulestyp):string;

function newgame_from_json(js:pjs_node):gamestart_rec;
function newgame_to_json(ng:pgamestart_rec):string;

function initres_to_json(var st:res_info_rec):string;
function initres_from_json(js:pjs_node):res_info_rec;

function stat_to_json(st:pstatrec):string;
function stat_from_json(js:pjs_node):statrec;

function xfer_to_json(st:pxfer_rec):string;
function xfer_from_json(js:pjs_node):xfer_rec;

function sew_to_json(const st:psew_rec):string;
function sew_from_json(js:pjs_node):sew_rec;

function tool_to_json(st:ptool_rec):string;
function tool_from_json(js:pjs_node):tool_rec;

function research_rec_to_json(st:presearch_rec):string;
function research_rec_from_json(js:pjs_node):research_rec;

function fire_to_json(st:pfire_rec):string;
function fire_from_json(js:pjs_node):fire_rec;

function builds_to_json(st:pbuildrec):string;
function builds_from_json(js:pjs_node):buildrec;

function razved_to_json(st:prazvedtyp;x,y:integer):string;
function razved_from_json(js:pjs_node;out x,y:integer):razvedtyp;

function comment_to_json(st:pcomment_typ):string;
function comment_from_json(js:pjs_node):comment_typ;

function log_to_json(st:plogmsgtyp):string;
function log_from_json(js:pjs_node):logmsgtyp;

function prod_to_json(p:pprodrec;full:boolean):string;
function prod_from_json(js:pjs_node):prodrec;

function unupd_to_json(u:ptyp_unupd):string;
function unupd_from_json(js:pjs_node):typ_unupd;

function clan_to_json(cl:ptypclansdb):string;
function clan_from_json(js:pjs_node):typclansdb;

function unitsdb_to_json(ud:ptypunitsdb;num,pretty:boolean):string;
function unitsdb_from_json(js:pjs_node):typunitsdb;

function prec_to_json(p:pprec):string;
function prec_from_json(js:pjs_node):prec;

function units_to_json(u:ptypunits):string;
function units_from_json(js:pjs_node):typunits;

function beg_to_json(st:ptypbeg):string;
function beg_from_json(js:pjs_node):typbeg;

function pstart_to_json(g:pgametyp;st:pplayer_start_rec;hash:boolean):string;
function pstart_from_json(g:pgametyp;js:pjs_node):player_start_rec;

function research_to_json(g:pgametyp;p:pplrtyp):string;
function research_from_json(g:pgametyp;p:pplrtyp;js:pjs_node):boolean;

function pcomm_to_json(g:pgametyp;p:pplrtyp):string;
function pcomm_from_json(g:pgametyp;p:pplrtyp;js:pjs_node):boolean;

function pall_to_json(g:pgametyp;p:pplrtyp;hash,short:boolean):string;
function pall_from_json(g:pgametyp;p:pplrtyp;js:pjs_node;short:boolean):boolean;

function ginfo_to_json(st:pgame_info):string;
function ginfo_from_json(js:pjs_node):game_info;

function gstate_to_json(st:pgame_state):string;
function gstate_from_json(js:pjs_node):game_state;

function move_to_json(st:pmove_rec):string;
function move_from_json(js:pjs_node):move_rec;

function dbgev_to_json(st:pdbgev_rec):string;
function dbgev_from_json(js:pjs_node):dbgev_rec;

function startstop_to_json(st:pstartstop_rec):string;
function startstop_from_json(js:pjs_node):startstop_rec;

function compress_string(s:string):string;
function decompress_string(s:string;original_size:integer):string;

function map_file_open(fn:string;full:boolean):pjs_node;
procedure map_file_get_map(js:pjs_node;map:pworda);
procedure map_file_get_passability(js:pjs_node;map:pworda;passmap:pbytea);
procedure map_file_get_pal(js:pjs_node;out pal:pallette3);
procedure map_file_get_minimap(js:pjs_node;minimap:pbytea);
procedure map_file_get_blocks(js:pjs_node;blk:ptypspr);
//############################################################################//
var mgl_json_rle:boolean=true;
//############################################################################//
implementation
//############################################################################//
function rle_map(s:string):string;
var c:char;
i,j,n:integer;
same:boolean;
begin
 result:=s;
 if not mgl_json_rle then exit;
 if length(s)<3 then exit;
 c:=s[1];
 same:=true;
 for i:=1 to length(s) do if s[i]<>c then begin same:=false;break;end;
 if same then begin result:='x'+c;exit;end;

 result:='';
 c:=s[1];
 n:=1;
 for i:=2 to length(s) do begin
  if s[i]=c then begin
   n:=n+1;
   if n=22 then begin
    result:=result+chr(n+ord('a'))+c;
    n:=0;
   end;
   continue;
  end else begin
   if n<3 then begin
    for j:=0 to n-1 do result:=result+c;
   end else begin
    result:=result+chr(n+ord('a'))+c;
   end;
   c:=s[i];
   n:=1;
  end;
 end;
 if n<>0 then begin
  if n<3 then begin
   for j:=0 to n-1 do result:=result+c;
  end else begin
   result:=result+chr(n+ord('a'))+c;
  end;
 end;
end;
//############################################################################//
function unrle_map(s:string;sz:integer):string;
var i,n,j:integer;
c:char;
begin
 result:=s;
 if s='' then exit;
 if s[1]='x' then begin
  setlength(result,sz);
  for i:=1 to sz do result[i]:=s[2];
  exit;
 end;

 result:='';
 i:=1;
 while i<=length(s) do case s[i] of
  'a'..'w':begin
   n:=ord(s[i])-ord('a');
   c:=s[i+1];
   for j:=0 to n-1 do result:=result+c;
   i:=i+2;
  end;
  else begin result:=result+s[i];i:=i+1;end;
 end;
end;
//############################################################################//
function rules_from_json(js:pjs_node):rulestyp;
var i:integer;
f:dword;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.uniset:=js_get_string(js,'uniset');
 result.moratorium:=vali(js_get_string(js,'moratorium'));
 result.moratorium_range:=vali(js_get_string(js,'moratorium_range'));
 result.resset:=vali(js_get_string(js,'resset'));
 result.goldset:=vali(js_get_string(js,'goldset'));
 f:=valhex(js_get_string(js,'flags'));
 dword_to_rules(@result,f);
 for i:=0 to 9 do result.ut_factors[i]:=vali(js_get_string(js,'ut_factors['+stri(i)+']'));
 for i:=0 to 3 do result.res_levels[i]:=vali(js_get_string(js,'res_levels['+stri(i)+']'));
end;
//############################################################################//
function rules_to_json(r:prulestyp):string;
var f:dword;
i:integer;
s:string;
begin
 f:=rules_to_dword(r);
 s:='{';
 s:=s+'"uniset":"'+r.uniset+'",';
 s:=s+'"moratorium":'+stri(r.moratorium)+',';
 s:=s+'"moratorium_range":'+stri(r.moratorium_range)+',';
 s:=s+'"resset":'+stri(r.resset)+',';
 s:=s+'"goldset":'+stri(r.goldset)+',';
 s:=s+'"flags":"'+strhex(f)+'",';
 s:=s+'"ut_factors":[';
 for i:=0 to 9 do begin
  s:=s+stri(r.ut_factors[i]);
  if i<>9 then s:=s+',';
 end;
 s:=s+'],';
 s:=s+'"res_levels":[';
 for i:=0 to 3 do begin
  s:=s+stri(r.res_levels[i]);
  if i<>3 then s:=s+',';
 end;
 s:=s+']';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function newgame_from_json(js:pjs_node):gamestart_rec;
var i:integer;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.name:=js_get_string(js,'name');
 result.map_name:=js_get_string(js,'map_name');
 result.plr_cnt:=vali(js_get_string(js,'plr_cnt'));
 result.rules:=rules_from_json(js_get_node(js,'rules'));
 for i:=0 to result.plr_cnt-1 do result.plr_names[i]:=js_get_string(js,'plr_names['+stri(i)+']');
end;
//############################################################################//
function newgame_to_json(ng:pgamestart_rec):string;
var s:string;
i:integer;
begin
 s:='{';
 s:=s+'"name":"'+ng.name+'",';
 s:=s+'"map_name":"'+ng.map_name+'",';
 s:=s+'"plr_cnt":'+stri(ng.plr_cnt)+',';
 s:=s+'"rules":'+rules_to_json(@ng.rules)+',';
 s:=s+'"plr_names":[';
 for i:=0 to ng.plr_cnt-1 do begin
  s:=s+'"'+ng.plr_names[i]+'"';
  if i<>(ng.plr_cnt-1) then s:=s+',';
 end;
 s:=s+']';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function initres_to_json(var st:res_info_rec):string;
var s,ts:string;
a,b:integer;
begin
 s:='';
 s:=s+'{'+#$0A;
 for a:=0 to 2 do begin
  case a of
   0:ts:='mats';
   1:ts:='fuel';
   2:ts:='gold';
   else ts:='huh';
  end;
  s:=s+'"'+ts+'":[';
  for b:=0 to 2 do begin
   s:=s+'[';
   s:=s+'['+trimsl(stri(st[a][b][0][0]),2,'0')+','+trimsl(stri(st[a][b][0][1]),2,'0')+'],';
   s:=s+'['+trimsl(stri(st[a][b][1][0]),2,'0')+','+trimsl(stri(st[a][b][1][1]),2,'0')+'],';
   s:=s+'['+trimsl(stri(st[a][b][2][0]),2,'0')+','+trimsl(stri(st[a][b][2][1]),2,'0')+'],';
   s:=s+'['+trimsl(stri(st[a][b][3][0]),2,'0')+','+trimsl(stri(st[a][b][3][1]),2,'0')+']';
   s:=s+']';
   if b<>2 then s:=s+',';
  end;
  s:=s+']';
  if a<>2 then s:=s+',';
  s:=s+#$0A;
 end;
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function initres_from_json(js:pjs_node):res_info_rec;
var b,c,d:integer;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 for b:=0 to 2 do for c:=0 to 3 do for d:=0 to 1 do result[0][b][c][d]:=vali(js_get_string(js,'mats['+stri(b)+']['+stri(c)+']['+stri(d)+']'));
 for b:=0 to 2 do for c:=0 to 3 do for d:=0 to 1 do result[1][b][c][d]:=vali(js_get_string(js,'fuel['+stri(b)+']['+stri(c)+']['+stri(d)+']'));
 for b:=0 to 2 do for c:=0 to 3 do for d:=0 to 1 do result[2][b][c][d]:=vali(js_get_string(js,'gold['+stri(b)+']['+stri(c)+']['+stri(d)+']'));
end;
//############################################################################//
function stat_to_json(st:pstatrec):string;
var s:string;
begin
 s:='{';
 if st.hits<>0  then s:=s+'"hits":"'+stri(st.hits)+'",';
 if st.cost<>0  then s:=s+'"cost":"'+stri(st.cost)+'",';
 if st.scan<>0  then s:=s+'"scan":"'+stri(st.scan)+'",';
 if st.armr<>0  then s:=s+'"armr":"'+stri(st.armr)+'",';
 if st.speed<>0 then s:=s+'"speed":"'+stri(st.speed)+'",';
 if st.attk<>0  then s:=s+'"attk":"'+stri(st.attk)+'",';
 if st.shoot<>0 then s:=s+'"shoot":"'+stri(st.shoot)+'",';
 if st.fuel<>0  then s:=s+'"fuel":"'+stri(st.fuel)+'",';
 if st.range<>0 then s:=s+'"range":"'+stri(st.range)+'",';
 if st.ammo<>0  then s:=s+'"ammo":"'+stri(st.ammo)+'",';
 if st.area<>0  then s:=s+'"area":"'+stri(st.area)+'",';
 s:=s+'"mat_turn":"'+stri(st.mat_turn)+'"';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function stat_from_json(js:pjs_node):statrec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.speed:=vali(js_get_string(js,'speed'));
 result.hits :=vali(js_get_string(js,'hits'));
 result.armr :=vali(js_get_string(js,'armr'));
 result.attk :=vali(js_get_string(js,'attk'));
 result.shoot:=vali(js_get_string(js,'shoot'));
 result.fuel :=vali(js_get_string(js,'fuel'));
 result.range:=vali(js_get_string(js,'range'));
 result.scan :=vali(js_get_string(js,'scan'));
 result.cost :=vali(js_get_string(js,'cost'));
 result.ammo :=vali(js_get_string(js,'ammo'));
 result.area :=vali(js_get_string(js,'area'));
 result.mat_turn:=vali(js_get_string(js,'mat_turn'));
end;
//############################################################################//
function xfer_to_json(st:pxfer_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"ua":"'+stri(st.ua)+'",';
 s:=s+'"ub":"'+stri(st.ub)+'",';
 s:=s+'"cnt":["'+stri(st.cnt[0])+'","'+stri(st.cnt[1])+'","'+stri(st.cnt[2])+'","'+stri(st.cnt[3])+'"]';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function xfer_from_json(js:pjs_node):xfer_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.ua:=vali(js_get_string(js,'ua'));
 result.ub:=vali(js_get_string(js,'ub'));
 result.cnt[0]:=vali(js_get_string(js,'cnt[0]'));
 result.cnt[1]:=vali(js_get_string(js,'cnt[1]'));
 result.cnt[2]:=vali(js_get_string(js,'cnt[2]'));
 result.cnt[3]:=vali(js_get_string(js,'cnt[3]'));
end;
//############################################################################//
function sew_to_json(const st:psew_rec):string;
begin
 result:='{'+'"typ":"'+stri(st.typ)+'",'+'"ua":"'+stri(st.ua)+'",'+'"ub":"'+stri(st.ub)+'",'+'"x":"'+stri(st.x)+'",'+'"y":"'+stri(st.y)+'",'+'"n":"'+stri(st.n)+'",'+'"msg":"'+st.msg+'"'+'}';
end;
//############################################################################//
function sew_from_json(js:pjs_node):sew_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=vali(js_get_string(js,'typ'));
 result.ua:=vali(js_get_string(js,'ua'));
 result.ub:=vali(js_get_string(js,'ub'));
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.n:=vali(js_get_string(js,'n'));
 result.msg:=js_get_string(js,'msg');
 if result.msg='nil' then result.msg:='';
end;
//############################################################################//
function tool_to_json(st:ptool_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"typ":"'+stri(st.typ)+'",';
 s:=s+'"ua":"'+stri(st.ua)+'",';
 s:=s+'"ub":"'+stri(st.ub)+'"';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function tool_from_json(js:pjs_node):tool_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=vali(js_get_string(js,'typ'));
 result.ua:=vali(js_get_string(js,'ua'));
 result.ub:=vali(js_get_string(js,'ub'));
end;
//############################################################################//
function research_rec_to_json(st:presearch_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"change":"'+stri(ord(st.change))+'",';
 s:=s+'"a":"'+stri(st.a)+'",';
 s:=s+'"b":"'+stri(st.b)+'"';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function research_rec_from_json(js:pjs_node):research_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.change:=js_get_string(js,'change')='1';
 result.a:=vali(js_get_string(js,'a'));
 result.b:=vali(js_get_string(js,'b'));
end;
//############################################################################//
function fire_to_json(st:pfire_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"typ":"'+stri(st.typ)+'",';
 s:=s+'"ua":"'+stri(st.ua)+'",';
 s:=s+'"ub":"'+stri(st.ub)+'",';
 s:=s+'"x":"'+stri(st.x)+'",';
 s:=s+'"y":"'+stri(st.y)+'",';
 s:=s+'"act":"'+stri(ord(st.act))+'"';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function fire_from_json(js:pjs_node):fire_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=vali(js_get_string(js,'typ'));
 result.ua:=vali(js_get_string(js,'ua'));
 result.ub:=vali(js_get_string(js,'ub'));
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.act:=vali(js_get_string(js,'act'))<>0;
end;
//############################################################################//
function builds_to_json(st:pbuildrec):string;
var s:string;
begin
 s:='{';
 s:=s+'"typ":"'+st.typ+'",';
 s:=s+'"typ_db":"'+stri(st.typ_db)+'",';
 s:=s+'"x":"'+stri(st.x)+'",';
 s:=s+'"y":"'+stri(st.y)+'",';
 s:=s+'"sz":"'+stri(st.sz)+'",';
 s:=s+'"rept":"'+stri(ord(st.rept))+'",';
 s:=s+'"reverse":"'+stri(ord(st.reverse))+'",';
 s:=s+'"left_turns":"'+stri(st.left_turns)+'",';
 s:=s+'"left_to_build":"'+stri(st.left_to_build)+'",';
 s:=s+'"left_mat":"'+stri(st.left_mat)+'",';
 s:=s+'"cur_speed":"'+stri(st.cur_speed)+'",';
 s:=s+'"cur_use":"'+stri(st.cur_use)+'",';
 s:=s+'"cur_take":"'+stri(st.cur_take)+'",';
 s:=s+'"given_speed":"'+stri(st.given_speed)+'",';
 s:=s+'"base":"'+stri(st.base)+'",';
 s:=s+'"tape":"'+stri(st.tape)+'",';
 s:=s+'"cones":"'+stri(st.cones)+'"';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function builds_from_json(js:pjs_node):buildrec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=js_get_string(js,'typ');
 result.typ_db:=vali(js_get_string(js,'typ_db'));
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.sz:=vali(js_get_string(js,'sz'));
 result.rept:=vali(js_get_string(js,'rept'))<>0;
 result.reverse:=vali(js_get_string(js,'reverse'))<>0;

 result.left_turns:=vali(js_get_string(js,'left_turns'));
 result.left_to_build:=vali(js_get_string(js,'left_to_build'));
 result.left_mat:=vali(js_get_string(js,'left_mat'));
 result.cur_speed:=vali(js_get_string(js,'cur_speed'));
 result.cur_use:=vali(js_get_string(js,'cur_use'));
 result.cur_take:=vali(js_get_string(js,'cur_take'));
 result.given_speed:=vali(js_get_string(js,'given_speed'));

 result.base:=vali(js_get_string(js,'base'));
 result.tape:=vali(js_get_string(js,'tape'));
 result.cones:=vali(js_get_string(js,'cones'));
end;
//############################################################################//
function razved_to_json(st:prazvedtyp;x,y:integer):string;
var s:string;
i:integer;
begin
 s:='{';
 s:=s+'"x":"'+stri(x)+'",';
 s:=s+'"y":"'+stri(y)+'",';
 s:=s+'"blds":[';
 for i:=0 to length(st.blds)-1 do begin  
  s:=s+'{';
  s:=s+'"id":"'+stri(st.blds[i].id)+'",';
  s:=s+'"level":"'+stri(st.blds[i].level)+'",';
  s:=s+'"own":"'+stri(st.blds[i].own)+'"'; 
  s:=s+'}';
  if i<>length(st.blds)-1 then s:=s+',';
 end; 
 s:=s+']';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function razved_from_json(js:pjs_node;out x,y:integer):razvedtyp;
var i,n:integer;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.seen:=true;
           
 x:=vali(js_get_string(js,'x'));
 y:=vali(js_get_string(js,'y'));

 n:=js_get_node_length(js,'blds');
 setlength(result.blds,n);
 for i:=0 to n-1 do begin
  result.blds[i].id:=vali(js_get_string(js,'blds['+stri(i)+'].id'));
  result.blds[i].level:=vali(js_get_string(js,'blds['+stri(i)+'].level'));
  result.blds[i].own:=vali(js_get_string(js,'blds['+stri(i)+'].own'));
 end;
end;
//############################################################################//
function comment_to_json(st:pcomment_typ):string;
var s:string;
begin
 s:='{';
 s:=s+'"typ":"'+stri(st.typ)+'",';
 s:=s+'"x":"'+stri(st.x)+'",';
 s:=s+'"y":"'+stri(st.y)+'",';
 s:=s+'"turn":"'+stri(st.turn)+'",';
 s:=s+'"text":"'+b64_enc_str(st.text)+'"';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function comment_from_json(js:pjs_node):comment_typ;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=vali(js_get_string(js,'typ'));
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.turn:=vali(js_get_string(js,'turn'));
 result.text:=b64_dec_str(js_get_string(js,'text'));
end;
//############################################################################//
function log_to_json(st:plogmsgtyp):string;
var s:string;
begin
 s:='{';

 s:=s+'"own":"'+stri(st.own)+'",';
 s:=s+'"tp":"'+stri(st.tp)+'",';
 s:=s+'"data":[';

 s:=s+'{';
 s:=s+'"x":"'+stri(st.data[0].x)+'",';
 s:=s+'"y":"'+stri(st.data[0].y)+'",';
 s:=s+'"dbn":"'+stri(st.data[0].dbn)+'",';
 s:=s+'"uid":"'+stri(st.data[0].uid)+'",';
 s:=s+'"own":"'+stri(st.data[0].own)+'",';
 s:=s+'"kind":"'+stri(st.data[0].kind)+'",';
 s:=s+'"tag":"'+stri(st.data[0].tag)+'",';
 s:=s+'},';

 s:=s+'{';
 s:=s+'"x":"'+stri(st.data[1].x)+'",';
 s:=s+'"y":"'+stri(st.data[1].y)+'",';
 s:=s+'"dbn":"'+stri(st.data[1].dbn)+'",';
 s:=s+'"uid":"'+stri(st.data[1].uid)+'",';
 s:=s+'"own":"'+stri(st.data[1].own)+'",';
 s:=s+'"kind":"'+stri(st.data[1].kind)+'",';
 s:=s+'"tag":"'+stri(st.data[1].tag)+'",';
 s:=s+'}';

 s:=s+']';

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function log_from_json(js:pjs_node):logmsgtyp;
var i:integer;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.own:=vali(js_get_string(js,'own'));
 result.tp:=vali(js_get_string(js,'tp'));
 for i:=0 to 1 do begin
  result.data[i].x:=vali(js_get_string(js,'data['+stri(i)+'].x'));
  result.data[i].y:=vali(js_get_string(js,'data['+stri(i)+'].y'));
  result.data[i].dbn:=vali(js_get_string(js,'data['+stri(i)+'].dbn'));
  result.data[i].own:=vali(js_get_string(js,'data['+stri(i)+'].own'));
  result.data[i].kind:=vali(js_get_string(js,'data['+stri(i)+'].kind'));
  result.data[i].tag:=vali(js_get_string(js,'data['+stri(i)+'].tag'));
 end;
end;
//############################################################################//
function prod_to_json(p:pprodrec;full:boolean):string;
var s:string;
i:integer;
begin
 s:='{';
 s:=s+'"num":[';for i:=RES_MIN to RES_MAX do begin s:=s+stri(p.num[i]);if i<>RES_MAX then s:=s+',';end;s:=s+'],';
 s:=s+'"use":[';for i:=RES_MIN to RES_MAX do begin s:=s+stri(p.use[i]);if i<>RES_MAX then s:=s+',';end;s:=s+'],';
 s:=s+'"pro":[';for i:=RES_MIN to RES_MAX do begin s:=s+stri(p.pro[i]);if i<>RES_MAX then s:=s+',';end;s:=s+'],';
 if full then begin
  s:=s+'"now":[';for i:=RES_MIN to RES_MAX do begin s:=s+stri(p.now[i]);if i<>RES_MAX then s:=s+',';end;s:=s+'],';
  s:=s+'"dbt":[';for i:=RES_MIN to RES_MAX do begin s:=s+stri(p.dbt[i]);if i<>RES_MAX then s:=s+',';end;s:=s+'],';
  s:=s+'"next_use":[';for i:=RES_MIN to RES_MAX do begin s:=s+stri(p.next_use[i]);if i<>RES_MAX then s:=s+',';end;s:=s+'],';
  s:=s+'"mining":[';for i:=RES_MINING_MIN to RES_MINING_MAX do begin s:=s+stri(p.mining[i]);if i<>RES_MINING_MAX then s:=s+',';end;s:=s+'],';
 end;
 s:=s+'"score_pro":'+stri(p.score_pro)+',';
 s:=s+'"refined_gold_pro":'+stri(p.refined_gold_pro);
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function prod_from_json(js:pjs_node):prodrec;
var i:integer;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 for i:=RES_MIN to RES_MAX do result.num[i]:=vali(js_get_string(js,'num['+stri(i-RES_MIN)+']'));
 for i:=RES_MIN to RES_MAX do result.use[i]:=vali(js_get_string(js,'use['+stri(i-RES_MIN)+']'));
 for i:=RES_MIN to RES_MAX do result.pro[i]:=vali(js_get_string(js,'pro['+stri(i-RES_MIN)+']'));
 for i:=RES_MIN to RES_MAX do result.dbt[i]:=vali(js_get_string(js,'dbt['+stri(i-RES_MIN)+']'));
 for i:=RES_MIN to RES_MAX do result.now[i]:=vali(js_get_string(js,'now['+stri(i-RES_MIN)+']'));
 for i:=RES_MIN to RES_MAX do result.next_use[i]:=vali(js_get_string(js,'next_use['+stri(i-RES_MIN)+']'));
 for i:=RES_MINING_MIN to RES_MINING_MAX do result.mining[i]:=vali(js_get_string(js,'mining['+stri(i-RES_MINING_MIN)+']'));

 result.score_pro:=vali(js_get_string(js,'score_pro'));
 result.refined_gold_pro:=vali(js_get_string(js,'refined_gold_pro'));
end;
//############################################################################//
function unupd_to_json(u:ptyp_unupd):string;
var s:string;
begin
 if not((u.mk=0)and(u.nu=0)and(u.cas=0)and not non_zero_stats(u.bas)) then begin
  s:='{';
  s:=s+'"typ":"'+u.typ+'",';
  if u.mk<>0  then s:=s+'"mk":'+stri(u.mk)+',';
  if u.nu<>0  then s:=s+'"nu":'+stri(u.nu)+',';
  if u.cas<>0 then s:=s+'"cas":'+stri(u.cas)+',';
  s:=s+'"bas":'+stat_to_json(@u.bas);
 s:=s+'}';
 end else s:='';
 result:=s;
end;
//############################################################################//
function unupd_from_json(js:pjs_node):typ_unupd;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=js_get_string(js,'typ');
 result.mk:=vali(js_get_string(js,'mk'));
 result.nu:=vali(js_get_string(js,'nu'));
 result.cas:=vali(js_get_string(js,'cas'));
 result.bas:=stat_from_json(js_get_node(js,'bas'));
end;
//############################################################################//
function clan_to_json(cl:ptypclansdb):string;
var s,sx:string;
i,k:integer;
begin
 s:='{';
 s:=s+'"name":"'+cl.name+'",';
 s:=s+'"desc_eng":"'+cl.desc_eng+'",';
 s:=s+'"desc_rus":"'+cl.desc_rus+'",';
 s:=s+'"flags":"'+strhex(cl.flags)+'",';
 s:=s+'"unupd":[';
 k:=0;
 for i:=0 to length(cl.unupd)-1 do begin
  sx:=unupd_to_json(@cl.unupd[i]);
  if sx<>'' then begin
   if k<>0 then s:=s+',';
   s:=s+sx;
   k:=k+1;
  end;
 end;
 s:=s+']';
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function clan_from_json(js:pjs_node):typclansdb;
var i,n:integer;
begin
 finalize(result);
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.name:=js_get_string(js,'name');
 result.desc_eng:=js_get_string(js,'desc_eng');
 if result.desc_eng='nil' then result.desc_eng:=js_get_string(js,'desc');   if result.desc_eng='nil' then result.desc_eng:='';
 result.desc_rus:=js_get_string(js,'desc_rus');   if result.desc_rus='nil' then result.desc_rus:='';
 result.flags:=valhex(js_get_string(js,'flags'));
 n:=js_get_node_length(js,'unupd');
 setlength(result.unupd,n);
 for i:=0 to n-1 do result.unupd[i]:=unupd_from_json(js_get_node(js,'unupd['+stri(i)+']'));
end;
//############################################################################//
function unitsdb_to_json(ud:ptypunitsdb;num,pretty:boolean):string;
var s:string;
begin
 s:='{';
 if num then s:=s+'"num":'+stri(ud.num)+',';

 if pretty then s:=s+'"typ":'+trimsl('"'+ud.typ+'"',13,' ')+','
           else s:=s+'"typ":"'+ud.typ+'",';
 s:=s+'"siz":'+stri(ud.siz)+',';
 s:=s+'"ptyp":'+stri(ud.ptyp)+',';
 s:=s+'"level":'+stri(ud.level)+',';
 s:=s+'"ord":'+trimsl(stri(ud.ord),3,' ')+',';
 s:=s+'"priority":'+stri(ud.priority)+',';
 s:=s+'"flags":"'+strhex(ud.flags)+'",';
 s:=s+'"flags2":"'+strhex(ud.flags2)+'",';
 s:=s+'"bldby":'+trimsl(stri(ud.bldby),2,' ')+',';
 s:=s+'"canbuild":'+stri(ord(ud.canbuild))+',';
 s:=s+'"canbuildtyp":'+trimsl(stri(ud.canbuildtyp),3,' ')+',';
 s:=s+'"isgun":'+stri(ord(ud.isgun))+',';
 s:=s+'"firemov":'+stri(ord(ud.firemov))+',';
 s:=s+'"fire_type":'+stri(ud.fire_type)+',';
 s:=s+'"weapon_type":'+stri(ud.weapon_type)+',';
 s:=s+'"store_lnd":'+stri(ud.store_lnd)+',';
 s:=s+'"store_wtr":'+stri(ud.store_wtr)+',';
 s:=s+'"store_air":'+stri(ud.store_air)+',';
 s:=s+'"store_hmn":'+stri(ud.store_hmn)+',';
 s:=s+'"bas":'+stat_to_json(@ud.bas)+',';
 s:=s+'"prod":'+prod_to_json(@ud.prod,false)+',';
 s:=s+'"name_eng":"'+ud.name_eng+'",';
 s:=s+'"name_rus":"'+ud.name_rus+'",';
 s:=s+'"descr_eng":"'+json_escape(ud.descr_eng)+'",';
 s:=s+'"descr_rus":"'+json_escape(ud.descr_rus)+'"';

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function unitsdb_from_json(js:pjs_node):typunitsdb;
var s:string;
begin
 finalize(result);
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.num:=vali(js_get_string(js,'num'));
 result.typ:=js_get_string(js,'typ');

 result.name_eng:=js_get_string(js,'name_eng');
 if result.name_eng='nil' then result.name_eng:=js_get_string(js,'name');
 if result.name_eng='nil' then result.name_eng:='';

 result.name_rus:=js_get_string(js,'name_rus');
 if result.name_rus='nil' then result.name_rus:=js_get_string(js,'name');
 if result.name_rus='nil' then result.name_rus:='';

 s:=js_get_string(js,'descr_eng');
 if s='nil' then s:=js_get_string(js,'descr');
 if s='nil' then s:='';
 result.descr_eng:=s;

 s:=js_get_string(js,'descr_rus');
 if s='nil' then s:=js_get_string(js,'descr');
 if s='nil' then s:='';
 result.descr_rus:=s;

 result.ptyp:=vali(js_get_string(js,'ptyp'));
 result.level:=vali(js_get_string(js,'level'));
 result.ord:=vali(js_get_string(js,'ord'));
 result.siz:=vali(js_get_string(js,'siz'));
 result.priority:=vali(js_get_string(js,'priority'));
 result.bldby:=vali(js_get_string(js,'bldby'));
 result.canbuild:=vali(js_get_string(js,'canbuild'))<>0;
 result.canbuildtyp:=vali(js_get_string(js,'canbuildtyp'));
 result.flags:=valhex(js_get_string(js,'flags'));
 result.flags2:=valhex(js_get_string(js,'flags2'));
 result.isgun:=vali(js_get_string(js,'isgun'))<>0;
 result.firemov:=vali(js_get_string(js,'firemov'))<>0;
 result.fire_type:=vali(js_get_string(js,'fire_type'));
 result.weapon_type:=vali(js_get_string(js,'weapon_type'));
 result.store_lnd:=vali(js_get_string(js,'store_lnd'));
 result.store_wtr:=vali(js_get_string(js,'store_wtr'));
 result.store_air:=vali(js_get_string(js,'store_air'));
 result.store_hmn:=vali(js_get_string(js,'store_hmn'));
 result.bas:=stat_from_json(js_get_node(js,'bas'));
 result.prod:=prod_from_json(js_get_node(js,'prod'));
end;
//############################################################################//
function prec_to_json(p:pprec):string;
var s:string;
begin
 s:='{';
 s:=s+'"px":'+stri(p.px)+',';
 s:=s+'"py":'+stri(p.py)+',';
 s:=s+'"pval":"'+stre(p.pval)+'",';
 s:=s+'"rpval":"'+stre(p.rpval)+'",';
 s:=s+'"dir":'+stri(p.dir);
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function prec_from_json(js:pjs_node):prec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.px:=vali(js_get_string(js,'px'));
 result.py:=vali(js_get_string(js,'py'));
 result.pval:=vale(js_get_string(js,'pval'));
 result.rpval:=vale(js_get_string(js,'rpval'));
 result.dir:=vali(js_get_string(js,'dir'));
end;
//############################################################################//
function units_to_json(u:ptypunits):string;
var s:string;
i:integer;
begin
 s:='{';
 s:=s+'"used":1,';
 s:=s+'"num":'+stri(u.num)+',';
 s:=s+'"uid":'+stri(u.uid)+',';
 s:=s+'"typ":"'+u.typ+'",';
 s:=s+'"name":"'+u.name+'",';

 s:=s+'"dbn":'+stri(u.dbn)+',';
 s:=s+'"cln":"'+stri(u.cln)+'",';
 s:=s+'"mk":'+stri(u.mk)+',';
 s:=s+'"nm":'+stri(u.nm)+',';

 s:=s+'"ptyp":'+stri(u.ptyp)+',';
 s:=s+'"level":'+stri(u.level)+',';
 s:=s+'"siz":'+stri(u.siz)+',';
 s:=s+'"cur_siz":'+stri(u.cur_siz)+',';
 if u.clrval<>0 then s:=s+'"clrval":"'+stri(u.clrval)+'",';

 if u.alt<>0 then s:=s+'"alt":'+stri(u.alt)+',';
 s:=s+'"own":'+stri(u.own)+',';
 s:=s+'"x":"'+stri(u.x)+'",';
 s:=s+'"y":"'+stri(u.y)+'",';
 if u.prior_x<>0 then s:=s+'"prior_x":"'+stri(u.prior_x)+'",';
 if u.prior_y<>0 then s:=s+'"prior_y":"'+stri(u.prior_y)+'",';
 s:=s+'"rot":"'+stri(u.rot)+'",';
 s:=s+'"grot":"'+stri(u.grot)+'",';

 if u.xt<>0 then s:=s+'"xt":"'+stri(u.xt)+'",';
 if u.yt<>0 then s:=s+'"yt":"'+stri(u.yt)+'",';
 if u.xnt<>0 then s:=s+'"xnt":"'+stri(u.xnt)+'",';
 if u.ynt<>0 then s:=s+'"ynt":"'+stri(u.ynt)+'",';

 if u.pstep<>0 then s:=s+'"pstep":"'+stri(u.pstep)+'",';
 if u.plen<>0 then s:=s+'"plen":"'+stri(u.plen)+'",';

 if length(u.path)<>0 then begin
  s:=s+'"path_len":'+stri(length(u.path))+',';
  s:=s+'"path":[';
  for i:=0 to length(u.path)-1 do begin
   s:=s+prec_to_json(@u.path[i]);
   if i<>length(u.path)-1 then s:=s+',';
  end;
  s:=s+'],';
 end;

 s:=s+'"cur":'+stat_to_json(@u.cur)+',';
 s:=s+'"bas":'+stat_to_json(@u.bas)+',';
 s:=s+'"prod":'+prod_to_json(@u.prod,true)+',';
 s:=s+'"domain":"'+stri(u.domain)+'",';
 if u.researching<>0 then s:=s+'"researching":'+stri(u.researching)+',';

 if u.clrturns<>0 then s:=s+'"clrturns":"'+stri(u.clrturns)+'",';
 s:=s+'"clr_unit":"'+stri(u.clr_unit)+'",';
 s:=s+'"clr_tape":"'+stri(u.clr_tape)+'",';

 s:=s+'"stored_in":"'+stri(u.stored_in)+'",';
 if u.currently_stored<>0 then s:=s+'"currently_stored":'+stri(u.currently_stored)+',';
 if u.disabled_for<>0 then s:=s+'"disabled_for":'+stri(u.disabled_for)+',';

 if u.stop_task<>0 then s:=s+'"stop_task":"'+stri(u.stop_task)+'",';
 s:=s+'"stop_target":"'+stri(u.stop_target)+'",';
 if u.stop_param<>0 then s:=s+'"stop_param":"'+stri(u.stop_param)+'",';
 if u.stop_task_pending then s:=s+'"stop_task_pending":"'+stri(ord(u.stop_task_pending))+'",';

 if u.reserve<>0 then s:=s+'"reserve":"'+stri(u.reserve)+'",';
 if u.builds_cnt<>0 then begin
  s:=s+'"builds_cnt":"'+stri(u.builds_cnt)+'",';
  s:=s+'"builds":[';
  for i:=0 to u.builds_cnt-1 do begin
   s:=s+builds_to_json(@u.builds[i]);
   if i<>u.builds_cnt-1 then s:=s+',';
  end;
  s:=s+'],';
 end;

 s:=s+'"stealth_detected":[';
 for i:=0 to length(u.stealth_detected)-1 do begin
  s:=s+stri(u.stealth_detected[i]);
  if i<>length(u.stealth_detected)-1 then s:=s+',';
 end;
 s:=s+'],';

 s:=s+'"feats":"'+strhex(unifeat_to_dword(u))+'"';

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function units_from_json(js:pjs_node):typunits;
var i,n:integer;
f:dword;
begin
 fillchar(result,sizeof(result),0);
 result.grp_db:=-1;
 if js=nil then exit;

 result.num:=vali(js_get_string(js,'num'));
 result.uid:=vali(js_get_string(js,'uid'));
 result.typ:=js_get_string(js,'typ');
 result.name:=js_get_string(js,'name');

 result.dbn:=vali(js_get_string(js,'dbn'));
 result.cln:=vali(js_get_string(js,'cln'));
 result.mk:=vali(js_get_string(js,'mk'));
 result.nm:=vali(js_get_string(js,'nm'));

 result.ptyp:=vali(js_get_string(js,'ptyp'));
 result.level:=vali(js_get_string(js,'level'));
 result.siz:=vali(js_get_string(js,'siz'));
 result.cur_siz:=vali(js_get_string(js,'cur_siz'));
 result.clrval:=vali(js_get_string(js,'clrval'));

 result.alt:=vali(js_get_string(js,'alt'));
 result.own:=vali(js_get_string(js,'own'));
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.prior_x:=vali(js_get_string(js,'prior_x'));
 result.prior_y:=vali(js_get_string(js,'prior_y'));

 result.rot:=vali(js_get_string(js,'rot'));
 result.grot:=vali(js_get_string(js,'grot'));

 result.xt:=vali(js_get_string(js,'xt'));
 result.yt:=vali(js_get_string(js,'yt'));
 result.xnt:=vali(js_get_string(js,'xnt'));
 result.ynt:=vali(js_get_string(js,'ynt'));

 result.plen:=vali(js_get_string(js,'plen'));
 result.pstep:=vali(js_get_string(js,'pstep'));
 n:=vali(js_get_string(js,'path_len'));
 setlength(result.path,n);
 for i:=0 to n-1 do result.path[i]:=prec_from_json(js_get_node(js,'path['+stri(i)+']'));

 result.cur:=stat_from_json(js_get_node(js,'cur'));
 result.bas:=stat_from_json(js_get_node(js,'bas'));
 result.prod:=prod_from_json(js_get_node(js,'prod'));

 result.domain:=vali(js_get_string(js,'domain'));
 result.researching:=vali(js_get_string(js,'researching'));

 result.clrturns:=vali(js_get_string(js,'clrturns'));
 result.clr_unit:=vali(js_get_string(js,'clr_unit'));
 result.clr_tape:=vali(js_get_string(js,'clr_tape'));

 result.stored_in:=vali(js_get_string(js,'stored_in'));
 result.currently_stored:=vali(js_get_string(js,'currently_stored'));
 result.disabled_for:=vali(js_get_string(js,'disabled_for'));


 result.stop_task:=vali(js_get_string(js,'stop_task'));
 result.stop_target:=vali(js_get_string(js,'stop_target'));
 result.stop_param:=vali(js_get_string(js,'stop_param'));
 result.stop_task_pending:=vali(js_get_string(js,'stop_task_pending'))<>0;

 result.reserve:=vali(js_get_string(js,'reserve'));
 result.builds_cnt:=vali(js_get_string(js,'builds_cnt'));
 if result.builds_cnt>=length(result.builds) then result.builds_cnt:=length(result.builds)-1;
 for i:=0 to result.builds_cnt-1 do result.builds[i]:=builds_from_json(js_get_node(js,'builds['+stri(i)+']'));

 for i:=0 to length(result.stealth_detected)-1 do result.stealth_detected[i]:=vali(js_get_string(js,'stealth_detected['+stri(i)+']'));

 f:=valhex(js_get_string(js,'feats'));
 dword_to_unifeat(@result,f);
end;
//############################################################################//
function beg_to_json(st:ptypbeg):string;
var s:string;
begin
 s:='{';
 s:=s+'"typ":"'+st.typ+'",';
 s:=s+'"x":"'+stri(st.x)+'",';
 s:=s+'"y":"'+stri(st.y)+'",';
 s:=s+'"mat":'+stri(st.mat)+',';
 s:=s+'"locked":'+stri(ord(st.locked));
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function beg_from_json(js:pjs_node):typbeg;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.typ:=js_get_string(js,'typ');
 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.mat:=vali(js_get_string(js,'mat'));
 result.locked:=vali(js_get_string(js,'locked'))<>0;
end;
//############################################################################//
function pstart_to_json(g:pgametyp;st:pplayer_start_rec;hash:boolean):string;
var s,sx:string;
i,k:integer;
ud:ptypunitsdb;
begin
 s:='{'+#$0A;

 s:=s+'"stgold":"'+stri(st.stgold)+'",';
 s:=s+'"clan":"'+stri(st.clan)+'",';
 s:=s+'"color":['+stri(st.color[0])+','+stri(st.color[1])+','+stri(st.color[2])+'],';
 s:=s+'"color8":'+stri(st.color8)+',';
 s:=s+'"lndx":"'+stri(st.lndx)+'",';
 s:=s+'"lndy":"'+stri(st.lndy)+'",';
 s:=s+'"name":"'+st.name+'",';
 s:=s+'"passhash":"'+st.passhash+'",'+#$0A;

 s:=s+'"init_unupd":['+#$0A;
 k:=0;
 for i:=0 to length(st.init_unupd)-1 do begin
  ud:=get_unitsdb(g,i);
  if ud<>nil then begin
   st.init_unupd[i].typ:=ud.typ;
   sx:=unupd_to_json(@st.init_unupd[i]);
   if sx<>'' then begin
    if k<>0 then s:=s+','+#$0A;
    s:=s+sx;
    k:=k+1;
   end;
  end;
 end;
 s:=s+#$0A;
 s:=s+'],'+#$0A;

 s:=s+'"bgn":['+#$0A;
 for i:=0 to st.bgncnt-1 do begin
  s:=s+beg_to_json(@st.bgn[i]);
  if i<>st.bgncnt-1 then s:=s+',';
  s:=s+#$0A;
 end;
 s:=s+']'+#$0A;

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function pstart_from_json(g:pgametyp;js:pjs_node):player_start_rec;
var n,i,k:integer;
u:typ_unupd;
begin
 finalize(result);
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 n:=get_unitsdb_count(g);
 setlength(result.init_unupd,n);
 fillchar(result.init_unupd[0],sizeof(result.init_unupd[0])*n,0);

 n:=js_get_node_length(js,'init_unupd');
 for i:=0 to n-1 do begin
  u:=unupd_from_json(js_get_node(js,'init_unupd['+stri(i)+']'));
  k:=getdbnum(g,u.typ);
  if k<>-1 then result.init_unupd[k]:=u;
 end;

 result.bgncnt:=js_get_node_length(js,'bgn');
 for i:=0 to result.bgncnt-1 do result.bgn[i]:=beg_from_json(js_get_node(js,'bgn['+stri(i)+']'));

 result.stgold:=vali(js_get_string(js,'stgold'));
 result.clan:=vali(js_get_string(js,'clan'));
 result.color[0]:=vali(js_get_string(js,'color[0]'));
 result.color[1]:=vali(js_get_string(js,'color[1]'));
 result.color[2]:=vali(js_get_string(js,'color[2]'));
 result.color8:=vali(js_get_string(js,'color8'));
 result.lndx:=vali(js_get_string(js,'lndx'));
 result.lndy:=vali(js_get_string(js,'lndy'));
 result.name:=js_get_string(js,'name');
 result.passhash:=js_get_string(js,'passhash');
end;
//############################################################################//
function research_to_json(g:pgametyp;p:pplrtyp):string;
var s:string;
i:integer;
begin
 s:='';
 s:=s+'"rsrch_spent":[';for i:=0 to RS_COUNT-1 do begin s:=s+stri(p.rsrch_spent[i]);if i<>RS_COUNT-1 then s:=s+',';end;s:=s+'],';
 s:=s+'"rsrch_level":[';for i:=0 to RS_COUNT-1 do begin s:=s+stri(p.rsrch_level[i]);if i<>RS_COUNT-1 then s:=s+',';end;s:=s+'],';
 s:=s+'"rsrch_labs":[';for i:=0 to RS_COUNT-1 do begin s:=s+stri(p.rsrch_labs[i]);if i<>RS_COUNT-1 then s:=s+',';end;s:=s+'],';
 s:=s+'"rsrch_left":[';for i:=0 to RS_COUNT-1 do begin s:=s+stri(p.rsrch_left[i]);if i<>RS_COUNT-1 then s:=s+',';end;s:=s+'],';
 s:=s+'"labs_free":'+stri(p.labs_free);

 result:=s;
end;
//############################################################################//
function research_from_json(g:pgametyp;p:pplrtyp;js:pjs_node):boolean;
var i:integer;
begin
 result:=false;
 if js=nil then exit;
 if p=nil then exit;

 for i:=0 to RS_COUNT-1 do p.rsrch_spent[i]:=vali(js_get_string(js,'rsrch_spent['+stri(i)+']'));
 for i:=0 to RS_COUNT-1 do p.rsrch_level[i]:=vali(js_get_string(js,'rsrch_level['+stri(i)+']'));
 for i:=0 to RS_COUNT-1 do p.rsrch_labs[i]:=vali(js_get_string(js,'rsrch_labs['+stri(i)+']'));
 for i:=0 to RS_COUNT-1 do p.rsrch_left[i]:=vali(js_get_string(js,'rsrch_left['+stri(i)+']'));

 p.labs_free:=vali(js_get_string(js,'labs_free'));

 result:=true;
end;
//############################################################################//
function pcomm_to_json(g:pgametyp;p:pplrtyp):string;
var s:string;
i,x,y:integer;
begin
 s:='{'+#$0A;
 s:=s+'"num":'+stri(p.num)+',';

 s:=s+'"razved":['+#$0A;
 i:=0;
 for x:=0 to length(p.razvedmp)-1 do for y:=0 to length(p.razvedmp[x])-1 do begin
  if p.razvedmp[x,y].seen and (length(p.razvedmp[x,y].blds)<>0) then begin
   if i<>0 then s:=s+','+#$0A;
   i:=i+1;
   s:=s+razved_to_json(@p.razvedmp[x,y],x,y);
  end;
 end;
 s:=s+#$0A+'],'+#$0A;

 s:=s+'"comments":['+#$0A;
 for i:=0 to length(p.comments)-1 do begin
  s:=s+comment_to_json(@p.comments[i]);
  if i<>length(p.comments)-1 then s:=s+',';
  s:=s+#$0A;
 end;
 s:=s+']'+#$0A;

 s:=s+'}';
 result:=s;
end; 
//############################################################################//
function pcomm_from_json(g:pgametyp;p:pplrtyp;js:pjs_node):boolean;
var n,i,x,y:integer;
rz:razvedtyp;
begin
 result:=false;
 if js=nil then exit;
 if p=nil then exit;
 if p.num<>vali(js_get_string(js,'num')) then exit;
    
 n:=js_get_node_length(js,'razved');
 for i:=0 to n-1 do begin
  rz:=razved_from_json(js_get_node(js,'razved['+stri(i)+']'),x,y);
  p.razvedmp[x,y]:=rz;
 end;

 n:=js_get_node_length(js,'comments');
 setlength(p.comments,n);
 for i:=0 to n-1 do p.comments[i]:=comment_from_json(js_get_node(js,'comments['+stri(i)+']'));

 result:=true;
end;
//############################################################################//
function pall_to_json(g:pgametyp;p:pplrtyp;hash,short:boolean):string;
var s,st:string;
i,xs,ys,x,y,t,k:integer;
c:char;
ud:ptypunitsdb;
begin
 //FIXME...
 xs:=112;
 ys:=length(p.resmp) div xs;

 s:='{'+#$0A;
 s:=s+'"typ":'+stri(p.typ)+',';
 s:=s+'"used":'+stri(ord(p.used))+',';
 s:=s+'"num":'+stri(p.num)+',';
 s:=s+'"allies":[';for i:=0 to MAX_PLR-1 do begin s:=s+stri(ord(p.allies[i]));if i<>MAX_PLR-1 then s:=s+',';end;s:=s+'],'+#$0A;
 s:=s+'"info":'+pstart_to_json(g,@p.info,hash)+','+#$0A;
 if not short then begin
  s:=s+'"unupd":['+#$0A;
  k:=0;
  for i:=0 to length(p.unupd)-1 do begin
   ud:=get_unitsdb(g,i);
   if ud<>nil then begin
    p.unupd[i].typ:=ud.typ;
    st:=unupd_to_json(@p.unupd[i]);
    if st<>'' then begin
     if k<>0 then s:=s+','+#$0A;
     s:=s+st;
     k:=k+1;
    end;
   end;
  end;
  s:=s+#$0A;
  s:=s+'],'+#$0A;

  s:=s+'"resmp_count":'+stri(length(p.resmp))+',';
  s:=s+'"resmp":['+#$0A;
  setlength(st,xs);
  for y:=0 to ys-1 do begin
   for x:=0 to xs-1 do begin
    t:=p.resmp[x+y*xs];
    c:=chr(t+ord('0'));
    st[1+x]:=c;
   end;
   s:=s+'"'+rle_map(st)+'"';
   if y<>ys-1 then s:=s+',';
   s:=s+#$0A;
  end;
  s:=s+'],'+#$0A;

  s:=s+'"gold":'+stri(p.gold)+',';
  s:=s+'"client_data":"'+p.client_data+'",'+#$0A;

  s:=s+'"log":['+#$0A;
  for i:=0 to length(p.logmsg)-1 do begin
   s:=s+log_to_json(@p.logmsg[i]);
   if i<>length(p.logmsg)-1 then s:=s+',';
   s:=s+#$0A;
  end;
  s:=s+'],'+#$0A;

  s:=s+research_to_json(g,p)+','+#$0A;

  s:=s+'"comm":'+pcomm_to_json(g,p)+','+#$0A;
 end;
 s:=s+'"u_num":[';for i:=0 to length(p.u_num)-1 do begin s:=s+stri(p.u_num[i]);if i<>length(p.u_num)-1 then s:=s+',';end;s:=s+'],'+#$0A;
 s:=s+'"u_cas":[';for i:=0 to length(p.u_cas)-1 do begin s:=s+stri(p.u_cas[i]);if i<>length(p.u_cas)-1 then s:=s+',';end;s:=s+']'+#$0A;

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function pall_from_json(g:pgametyp;p:pplrtyp;js:pjs_node;short:boolean):boolean;
var n,i,xs,ys,x,y,k:integer;
s:string;
u:typ_unupd;
begin
 result:=false;
 if js=nil then exit;
 if p=nil then exit;

 if short then if p.num<>vali(js_get_string(js,'num')) then exit;

 if not short then begin
  finalize(p^);
  fillchar(p^,sizeof(p^),0);

  n:=get_unitsdb_count(g);
  setlength(p.unupd,n);
  setlength(p.tmp_unupd,n);
  setlength(p.u_num,n);
  setlength(p.u_cas,n);
  fillchar(p.unupd[0],sizeof(p.unupd[0])*n,0);
  fillchar(p.tmp_unupd[0],sizeof(p.tmp_unupd[0])*n,0);
  fillchar(p.u_num[0],sizeof(p.u_num[0])*n,0);
  fillchar(p.u_cas[0],sizeof(p.u_cas[0])*n,0);

  alloc_and_clear_plr_razved(p,g.info.mapx,g.info.mapy);
 end;

 p.typ:=vali(js_get_string(js,'typ'));
 p.used:=vali(js_get_string(js,'used'))<>0;
 p.num:=vali(js_get_string(js,'num'));
 p.info:=pstart_from_json(g,js_get_node(js,'info'));

 for i:=0 to MAX_PLR-1 do p.allies[i]:=vali(js_get_string(js,'allies['+stri(i)+']'))<>0;

 n:=get_unitsdb_count(g);
 for i:=0 to n-1 do p.u_num[i]:=vali(js_get_string(js,'u_num['+stri(i)+']'));
 for i:=0 to n-1 do p.u_cas[i]:=vali(js_get_string(js,'u_cas['+stri(i)+']'));


 if not short then begin
  n:=js_get_node_length(js,'unupd');
  for i:=0 to n-1 do begin
   u:=unupd_from_json(js_get_node(js,'unupd['+stri(i)+']'));
   k:=getdbnum(g,u.typ);
   if k<>-1 then p.unupd[k]:=u
  end;

  n:=vali(js_get_string(js,'resmp_count'));
  //FIXME...
  xs:=112;
  ys:=n div xs;
  setlength(p.resmp,n);
  for y:=0 to ys-1 do begin
   s:=js_get_string(js,'resmp['+stri(y)+']');
   s:=unrle_map(s,xs);
   if length(s)<xs then continue;
   for x:=0 to xs-1 do p.resmp[x+y*xs]:=ord(s[1+x])-ord('0');
  end;

  p.gold:=vali(js_get_string(js,'gold'));
  p.client_data:=js_get_string(js,'client_data');
  if p.client_data='nil' then p.client_data:='';

  n:=js_get_node_length(js,'log');
  setlength(p.logmsg,n);
  for i:=0 to n-1 do p.logmsg[i]:=log_from_json(js_get_node(js,'log['+stri(i)+']'));

  research_from_json(g,p,js);  
  pcomm_from_json(g,p,js_get_node(js,'comm'));
 end;

 result:=true;
end;
//############################################################################//
function ginfo_to_json(st:pgame_info):string;
var s:string;
begin
 s:='{';

 s:=s+'"game_name":"'+st.game_name+'",';
 s:=s+'"map_name":"'+st.map_name+'",';
 s:=s+'"descr":"'+json_escape(st.descr)+'",';
 s:=s+'"rules":'+rules_to_json(@st.rules)+',';
 s:=s+'"mapx":'+stri(st.mapx)+',';
 s:=s+'"mapy":'+stri(st.mapy)+',';
 s:=s+'"plr_cnt":'+stri(st.plr_cnt)+',';
 s:=s+'"unitsdb_cnt":'+stri(st.unitsdb_cnt);

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function ginfo_from_json(js:pjs_node):game_info;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.game_name:=js_get_string(js,'game_name');
 result.map_name:=js_get_string(js,'map_name');
 result.descr:=js_get_string(js,'descr');
 result.rules:=rules_from_json(js_get_node(js,'rules'));
 result.mapx:=vali(js_get_string(js,'mapx'));
 result.mapy:=vali(js_get_string(js,'mapy'));
 result.plr_cnt:=vali(js_get_string(js,'plr_cnt'));
 result.unitsdb_cnt:=vali(js_get_string(js,'unitsdb_cnt'));
end;
//############################################################################//
function gstate_to_json(st:pgame_state):string;
var s:string;
i:integer;
begin
 s:='{';

 s:=s+'"date":'+stri(st.date)+',';
 s:=s+'"status":'+stri(st.status)+',';
 s:=s+'"cur_plr":'+stri(st.cur_plr)+',';
 s:=s+'"turn":'+stri(st.turn)+',';
 s:=s+'"domains_cnt":'+stri(st.domains_cnt)+',';
 s:=s+'"mor_done":'+stri(ord(st.mor_done))+',';
 s:=s+'"landed":[';
 for i:=0 to length(st.landed)-1 do begin
  s:=s+stri(ord(st.landed[i]));
  if i<>length(st.landed)-1 then s:=s+',';
 end;
 s:=s+'],';
 s:=s+'"lost":[';
 for i:=0 to length(st.lost)-1 do begin
  s:=s+stri(ord(st.lost[i]));
  if i<>length(st.lost)-1 then s:=s+',';
 end;
 s:=s+']';

 s:=s+'}';
 result:=s;
end;
//############################################################################//
function gstate_from_json(js:pjs_node):game_state;
var i:integer;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.date:=vali(js_get_string(js,'date'));
 result.status:=vali(js_get_string(js,'status'));
 result.cur_plr:=vali(js_get_string(js,'cur_plr'));
 result.turn:=vali(js_get_string(js,'turn'));
 result.domains_cnt:=vali(js_get_string(js,'domains_cnt'));
 result.mor_done:=vali(js_get_string(js,'mor_done'))<>0;
 for i:=0 to length(result.landed)-1 do result.landed[i]:=vali(js_get_string(js,'landed['+stri(i)+']'))<>0;
 for i:=0 to length(result.lost)-1 do result.lost[i]:=vali(js_get_string(js,'lost['+stri(i)+']'))<>0;
end;
//############################################################################//
function move_to_json(st:pmove_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"un":'+stri(st.un)+',';
 s:=s+'"xt":'+stri(st.xt)+',';
 s:=s+'"yt":'+stri(st.yt)+',';
 s:=s+'"isstd":'+stri(ord(st.isstd))+',';
 s:=s+'"stop_task":'+stri(st.stop_task)+',';
 s:=s+'"stop_target":'+stri(st.stop_target)+',';
 s:=s+'"stop_param":'+stri(st.stop_param);
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function move_from_json(js:pjs_node):move_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.un:=vali(js_get_string(js,'un'));
 result.xt:=vali(js_get_string(js,'xt'));
 result.yt:=vali(js_get_string(js,'yt'));
 result.isstd:=vali(js_get_string(js,'isstd'))<>0;
 result.stop_task:=vali(js_get_string(js,'stop_task'));
 result.stop_target:=vali(js_get_string(js,'stop_target'));
 result.stop_param:=vali(js_get_string(js,'stop_param'));
end;
//############################################################################//
function dbgev_to_json(st:pdbgev_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"x":'+stri(st.x)+',';
 s:=s+'"y":'+stri(st.y)+',';
 s:=s+'"un":'+stri(st.un)+',';
 s:=s+'"full":'+stri(ord(st.full))+',';
 s:=s+'"delete":'+stri(ord(st.delete))+',';
 s:=s+'"boom":'+stri(ord(st.boom));
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function dbgev_from_json(js:pjs_node):dbgev_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.x:=vali(js_get_string(js,'x'));
 result.y:=vali(js_get_string(js,'y'));
 result.un:=vali(js_get_string(js,'un'));
 result.full:=vali(js_get_string(js,'full'))<>0;
 result.delete:=vali(js_get_string(js,'delete'))<>0;
 result.boom:=vali(js_get_string(js,'boom'))<>0;
end;
//############################################################################//
function startstop_to_json(st:pstartstop_rec):string;
var s:string;
begin
 s:='{';
 s:=s+'"un":'+stri(st.un)+',';
 s:=s+'"motion":'+stri(ord(st.motion))+',';
 s:=s+'"start":'+stri(ord(st.start))+',';
 s:=s+'"done":'+stri(ord(st.done))+',';
 s:=s+'"doze":'+stri(ord(st.doze))+',';
 s:=s+'"mine_add":'+stri(ord(st.mine_add))+',';
 s:=s+'"mine_rem":'+stri(ord(st.mine_rem))+',';
 s:=s+'"anyway":'+stri(ord(st.anyway));
 s:=s+'}';
 result:=s;
end;
//############################################################################//
function startstop_from_json(js:pjs_node):startstop_rec;
begin
 fillchar(result,sizeof(result),0);
 if js=nil then exit;

 result.un:=vali(js_get_string(js,'un'));
 result.motion:=vali(js_get_string(js,'motion'))<>0;
 result.start:=vali(js_get_string(js,'start'))<>0;
 result.done:=vali(js_get_string(js,'done'))<>0;
 result.doze:=vali(js_get_string(js,'doze'))<>0;
 result.mine_add:=vali(js_get_string(js,'mine_add'))<>0;
 result.mine_rem:=vali(js_get_string(js,'mine_rem'))<>0;
 result.anyway:=vali(js_get_string(js,'anyway'))<>0;
end;
//############################################################################//
function compress_string(s:string):string;
var cbuf:pointer;
csz,sz,osz:integer;
begin
 osz:=length(s);
 getmem(cbuf,osz);
 csz:=encodeLZW(@s[1],cbuf,osz,osz);

 setlength(result,csz*3);
 sz:=b64_enc(cbuf,csz,@result[1],length(s),false);
 setlength(result,sz);

 freemem(cbuf);
end;
//############################################################################//
function decompress_string(s:string;original_size:integer):string;
var cbuf:pointer;
csz:integer;
begin
 setlength(result,original_size);

 getmem(cbuf,3*length(s));
 csz:=b64_dec(@s[1],length(s),cbuf,3*length(s));
 decodeLZW(cbuf,@result[1],csz,original_size);
 freemem(cbuf);
end;
//############################################################################//
function map_file_open(fn:string;full:boolean):pjs_node;
var f:vfile;
sz:integer;
s:string;
begin
 result:=nil;
 if vfopen(f,fn,VFO_READ)<>VFERR_OK then exit;
 sz:=vffilesize(f);
 if not full then sz:=min2i(1024*1024,sz);  //FIXME: Hack.
 setlength(s,sz);
 vfread(f,@s[1],sz);
 vfclose(f);

 if full then result:=js_parse(s)
         else result:=js_parse_until(s,'blocks');
end;
//############################################################################//
procedure map_file_get_map(js:pjs_node;map:pworda);
var i,xs,ys:integer;
begin
 xs:=vali(js_get_string(js,'width'));
 ys:=vali(js_get_string(js,'height'));
 for i:=0 to xs*ys-1 do map[i]:=vali(js_get_string(js,'map['+stri(i)+']'));
end;
//############################################################################//
procedure map_file_get_minimap(js:pjs_node;minimap:pbytea);
var i,xs,ys:integer;
begin
 xs:=vali(js_get_string(js,'width'));
 ys:=vali(js_get_string(js,'height'));
 for i:=0 to xs*ys-1 do minimap[i]:=vali(js_get_string(js,'mini_map['+stri(i)+']'));
end;
//############################################################################//
procedure map_file_get_passability(js:pjs_node;map:pworda;passmap:pbytea);
var i,n,xs,ys:integer;
s:string;
begin
 n:=js_get_node_length(js,'passability');
 xs:=vali(js_get_string(js,'width'));
 ys:=vali(js_get_string(js,'height'));

 s:='';
 for i:=0 to n-1 do s:=s+js_get_string(js,'passability['+stri(i)+']');
 for i:=0 to xs*ys-1 do passmap[i]:=ord(s[1+map[i]])-ord('0');
end;
//############################################################################//
procedure map_file_get_pal(js:pjs_node;out pal:pallette3);
var x:integer;
begin
 for x:=0 to 255 do begin
  pal[x][CLRED]  :=vali(js_get_string(js,'pal['+stri(x)+'][0]'));
  pal[x][CLGREEN]:=vali(js_get_string(js,'pal['+stri(x)+'][1]'));
  pal[x][CLBLUE] :=vali(js_get_string(js,'pal['+stri(x)+'][2]'));
 end;
end;
//############################################################################//
procedure map_file_get_blocks(js:pjs_node;blk:ptypspr);
var i,elem_count,blocks_size,sz:integer;
s,s1:string;
begin
 elem_count:=js_get_node_length(js,'blocks');
 blocks_size:=elem_count*64*64;

 blk.tp:=1;
 blk.xs:=64;
 blk.ys:=blocks_size div 64;
 blk.cx:=blk.xs div 2;
 blk.cy:=blk.ys div 2;

 getmem(blk.srf,blocks_size);
 for i:=0 to elem_count-1 do begin
  s:=js_get_string(js,'blocks['+stri(i)+']');

  setlength(s1,length(s));
  sz:=b64_dec(@s[1],length(s),@s1[1],length(s1));
  setlength(s1,sz);
  decodeLZW(@s1[1],@pbytea(blk.srf)[i*64*64],sz,64*64);
 end;
end;
//############################################################################//
begin
end.
//############################################################################//
