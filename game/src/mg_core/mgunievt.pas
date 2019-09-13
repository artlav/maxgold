//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core Units handling functions
//############################################################################//
unit mgunievt;
interface
uses maths,mgvars,mgrecs,sds_rec,mgauxi,mgmotion,mgunits,mgl_logs,mgl_common,mgl_scan,mgl_attr,mgl_tests,mgl_unu,mgl_path;
//############################################################################//
function game_main_loop(g:pgametyp):boolean;
//############################################################################//
implementation
//############################################################################//
procedure surveyor_tick(g:pgametyp;u:ptypunits);
var x,y:integer;
cp:pplrtyp;
begin
 if not unav(u) then exit;
 if not(isa(g,u,a_surveyor) and cur_plr_unit(g,u))then exit;
 cp:=get_plr(g,u.own);

 for x:=-1 to 1 do for y:=-1 to 1 do if inrm(g,u.x+x,u.y+y) then cp.resmp[u.x+x+(u.y+y)*g.info.mapx]:=1;
end;
//############################################################################//
procedure miner_tick(g:pgametyp;u:ptypunits);
var j:integer;
typ:string;
uy,ux:ptypunits;
fnd:boolean;
begin
 if not unav(u) then exit;

 if u.is_bomb_placing then begin
  ux:=nil;
  for j:=0 to get_unu_length(g,u.x,u.y)-1 do if isa(g,get_unu(g,u.x,u.y,j),a_bomb) then begin ux:=get_unu(g,u.x,u.y,j);break;end;
  if ux=nil then begin
   if u.ptyp<=pt_landwater then typ:='landmine' else typ:='seamine';
   uy:=create_unit(g,typ,u.x,u.y,u.own);
   uy.isact:=true;
   addunu(g,uy);
   addscan(g,uy,uy.x,uy.y);
   dec(u.prod.now[RES_MAT]);
   if u.prod.now[RES_MAT]=0 then u.is_bomb_placing:=false;
  end else if plr_are_enemies(g,ux.own,u.own) then begin
   ux.is_sentry:=true;
   add_log_msgu(g,ux.own,lmt_unit_destroyed,ux,u);  
   boom_unit(g,ux);
  end;
 end;
 if u.is_bomb_removing then begin
  uy:=nil;                  
  fnd:=false;
  for j:=0 to get_unu_length(g,u.x,u.y)-1 do if isa(g,get_unu(g,u.x,u.y,j),a_bomb) then begin fnd:=true;uy:=get_unu(g,u.x,u.y,j);end;
  if fnd then if((u.ptyp<=pt_landwater )and(uy.typ='landmine'))or
                ((u.ptyp>=pt_watercoast)and(uy.typ='seamine'))then if uy.own=u.own then begin                   

   delete_unit(g,uy,false,true);
   
   inc(u.prod.now[RES_MAT]);
   if u.prod.now[RES_MAT]=u.prod.num[RES_MAT] then u.is_bomb_removing:=false;
  end;
 end;
end;
//############################################################################//
//Process autofire
procedure do_autofire(g:pgametyp;t:ptypunits);
var i,trot:integer;
u:ptypunits;
ud:ptypunitsdb;
gone:boolean;
begin try
 if not unav(t) then exit;
                
 t.triggered_auto_fire:=false;
 for i:=0 to get_units_count(g)-1 do if unav(g,i) and(i<>t.num)then begin     
  u:=get_unit(g,i);
  ud:=get_unitsdb(g,u.dbn);
  if not can_see(g,t.x,t.y,u.own,t) then continue;
  if not plr_are_enemies(g,t.own,u.own) then continue;

  if not isa(g,u,a_can_fire) then continue;
  if not isa(g,u,a_would_autofire) then continue;

  if sqr(u.x-t.x)+sqr(u.y-t.y)>sqr(u.bas.range) then continue;
  if not fire_possible(g,u,t) then continue;

  //Stop the unit if moving
  clear_motion(g,t,true);
 
  trot:=u.rot;
  u.rot:=getdirbydp(t.x,u.x,t.y,u.y);
  if ud.isgun then begin u.grot:=u.rot;u.rot:=trot;end;
  trigger_autofire(g,t);  //Trigger first, then make it fire
  
  do_fire(g,u,tivec2(t.x,t.y),gone); 
  if gone then break;
 end;
  
 except stderr('Units','do_autofire');end;
end;      
//############################################################################//
//Process fire
function mainloop_autofire(g:pgametyp):boolean;
var i:integer;
u:ptypunits;
begin result:=false; try
 if not precalc_autofire(g) then exit;

 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if u.triggered_auto_fire then do_autofire(g,u);
 end;
 
 except stderr('Units','DoFire');end;
end;
//############################################################################//
//Calculate the path
function mainloop_calcmoves(g:pgametyp):boolean;
var i:integer;
u:ptypunits;
begin result:=false; try
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  //Check for actions at destination
  //FIXME: Fixes bug 8508, at cost of...?
  if u.stop_task_pending then begin
   do_destination_reached(g,u);
   result:=true;
  end;
  
  //Check for motion
  if u.is_moving and(u.plen=0)then begin     
   result:=true;
   if not test_pass(g,u.xt,u.yt,u,false,1) then begin clear_motion(g,u,true);continue;end;
   if not pf_calc_path(g,u,0) then clear_motion(g,u,true);
   u.pstep:=0;
  end;
 end;

 except stderr('Units','CalcMoves');end;
end;   
//############################################################################//
//Set the next move segment, check path and conditions     
function mainloop_setmoves(g:pgametyp):boolean;
var i:integer;
u:ptypunits;
begin result:=false; try
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if u.is_moving and(not u.is_moving_now)and(not u.isstd)and(u.plen>0) then begin
   result:=true;
   if move_check_for_mines(g,u) then continue;
   case move_get_case(g,u) of
    1:move_do_normal_move_step(g,u);
    2:move_do_prestop_move(g,u);  
    3:move_do_last_move(g,u);
    else continue;
   end;
  end;
 end;
 except stderr('Units','SetMoves');end;
end;
//############################################################################//
//############################################################################//
//Do the actual move of the unit
function mainloop_domoves(g:pgametyp;dt:double):boolean;
var i,j,dx,dy,nx,ny:integer;
u:ptypunits;
pv:array [0..MAX_PLR-1] of boolean;
begin result:=false; try
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if (not u.is_moving_now) or u.isstd then continue;                                                   
  result:=true;
  if (not test_pass(g,u.xnt,u.ynt,u))and not u.is_moving_build then begin u.is_moving_now:=false;continue;end;  
                   
  for j:=0 to get_plr_count(g)-1 do pv[j]:=can_see(g,u.x,u.y,j,u); 
   
  dx:=u.xnt-u.x;
  dy:=u.ynt-u.y;
  nx:=u.x;
  ny:=u.y;
  if dx<>0 then nx:=u.x+sgn(dx);
  if dy<>0 then ny:=u.y+sgn(dy);
               
  addscan(g,u,nx,ny);
  subscan(g,u);
  remunuc(g,u.x,u.y,u);
  u.x:=nx;
  u.y:=ny;
  addunu(g,u); 
   
  add_sew(g,sew_move,u.num,0,u.pstep,u.x,u.y);
   
  for j:=0 to get_plr_count(g)-1 do if(u.own<>j)and(pv[j]<>can_see(g,u.x,u.y,j,u))then begin
   if pv[j] then add_log_msgu(g,j,lmt_enemy_unit_hiden, u)
            else add_log_msgu(g,j,lmt_enemy_unit_spoted,u);
  end;
   
  if(u.xnt=u.x)and(u.ynt=u.y)then u.is_moving_now:=false;
   
 end;
 except stderr('Units','mainloop_domoves');end;
end;
//############################################################################//
//Tick processor
function mainloop_ticks(g:pgametyp;dt:double):boolean;
var i:integer;
begin result:=false; try
 for i:=0 to get_units_count(g)-1 do begin
  miner_tick(g,get_unit(g,i));
  surveyor_tick(g,get_unit(g,i));
 end; 

 except stderr('Units','DoTsk');end;
end;      
//############################################################################//
function game_main_loop(g:pgametyp):boolean;
begin result:=false; try
 if g.state.status<>GST_THEGAME then exit;
 if get_units_count(g)=0 then exit;

 result:=mainloop_calcmoves(g) or result;     //473 ms on average
 result:=mainloop_ticks(g,1) or result;       //23 ms on average
 result:=mainloop_setmoves(g) or result;      //6 ms on average
 result:=mainloop_autofire(g) or result;      //7 ms on average
 result:=mainloop_domoves(g,1) or result;     //47 ms on average

 except stderr('MGA','Error in game_main_loop'); end;
end;
//############################################################################//
begin
end.   
//############################################################################//
