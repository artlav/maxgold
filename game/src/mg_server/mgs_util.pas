//############################################################################//
unit mgs_util;
interface
uses asys,sysutils,strval,mgs_net,log
,mgrecs,mgunievt,mgl_common,mgl_json,mgl_attr
,mgunits,mgproduct
;
//############################################################################//
const lf=#$0A;
//############################################################################//
const
GSOP_SYS=10;
GSOP_GAME=11;

MGSTATUS_ERR=0;
MGSTATUS_OK=1;
MGSTATUS_AUTHERR=2;
//############################################################################//
procedure run_the_loop(g:pgametyp);

function nogame_reply:string;
function start_reply(status:integer):string;

function marks_to_list(g:pgametyp):string;
function event_result(g:pgametyp):string;
function produce_result(g:pgametyp;r:boolean):string;
procedure stop_motion(g:pgametyp;u:ptypunits);
function stop_action(g:pgametyp;u:ptypunits;anyway:boolean):boolean;
//############################################################################//
implementation
//############################################################################//
procedure run_the_loop(g:pgametyp);
var i:integer;
begin
 ////FIXME: Roll the moves and return results
 for i:=0 to 1000 do if not game_main_loop(g) then break;
end;
//############################################################################//
function nogame_reply:string;
begin
 result:='"status":0,"error":"Server misplaced the game...?"}';
end;
//############################################################################//
function start_reply(status:integer):string;
begin
 result:='"status":"'+stri(status)+'"';
end;
//############################################################################//
function marks_to_list(g:pgametyp):string;
var i:integer;
first:boolean;
begin
 result:='';
 first:=true;
 for i:=0 to length(g.marks)-1 do if g.marks[i] then begin
  if not first then result:=result+',';
  result:=result+stri(i);
  if first then first:=false;
 end;
end;
//############################################################################//
function sew_to_list(g:pgametyp):string;
var i:integer;
first:boolean;
begin
 result:='';
 first:=true;
 for i:=0 to g.sew_cnt-1 do begin
  if not first then result:=result+',';
  result:=result+sew_to_json(@g.sews[i]);
  if first then first:=false;
 end;
end;
//############################################################################//
function event_result(g:pgametyp):string;
var s:string;
begin
 result:='';
 if g.plr_event then result:=result+',"plr_event":1';
 if g.log_event then result:=result+',"log_event":1';
 s:=sew_to_list(g);
 if s<>'' then result:=result+',"events":['+s+']';
 s:=marks_to_list(g);
 if s<>'' then result:=result+',"update_list":['+s+']';
end;
//############################################################################//
function produce_result(g:pgametyp;r:boolean):string;
begin
 run_the_loop(g);
 if g.make_reply then result:=start_reply(MGSTATUS_OK)+',"success":'+stri(ord(r))+event_result(g)+'}'
                 else result:='';
end;
//############################################################################//
procedure stop_motion(g:pgametyp;u:ptypunits);
begin
 if not unav(u) then exit;
 u.xt:=u.x;
 u.yt:=u.y;
 if u.is_moving then clear_motion(g,u,true);
end;
//############################################################################//
function stop_action(g:pgametyp;u:ptypunits;anyway:boolean):boolean;
begin
 result:=false;
 if not unav(u) then exit;
 result:=stopunit(g,u,true,anyway or isa(g,u,a_mining));
end;
//############################################################################//
begin
end.
//############################################################################//
