//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core Units handling functions
//############################################################################//
unit mgmotion;
interface
uses asys,maths,strval,mgvars,mgrecs,sds_rec,mgauxi,mgunits,mgress,mg_builds,mgl_logs,mgl_common,mgl_attr,mgl_res,mgl_tests,mgl_unu,mgl_scan,mgl_stats,mgl_path;
//############################################################################//
function  do_order_firing_to(g:pgametyp;u:ptypunits;x,y:integer;doit:boolean):boolean;  
function  do_move_closeup(g:pgametyp;u,ut:ptypunits;range:integer):boolean; 
procedure do_toolunit(g:pgametyp;typ:integer;u,ut:ptypunits);
procedure do_research(g:pgametyp); 
procedure do_change_research(g:pgametyp;par,par2:integer);
function  do_store(g:pgametyp;u,ut:ptypunits):boolean;
function  do_unstore(g:pgametyp;u:ptypunits;x,y:integer):boolean; 
function  do_order_firing_at(g:pgametyp;u,t:ptypunits;x:integer=0;y:integer=0;move:boolean=true):boolean;
procedure set_move_unit(g:pgametyp;u:ptypunits;xt,yt:integer;isstd:boolean=false;stop_task:integer=stsk_none;stop_target:integer=0;stop_param:integer=0);
                  
function do_fire(g:pgametyp;u:ptypunits;firing_at:ivec2;out gone:boolean):boolean;
                 
procedure do_destination_reached(g:pgametyp;u:ptypunits);  
function  area_value(g:pgametyp;x,y,area,attk:integer):integer;      

function  precalc_autofire(g:pgametyp):boolean;

function  move_check_for_mines(g:pgametyp;u:ptypunits):boolean;   
function  move_get_case(g:pgametyp;u:ptypunits):integer;
procedure move_do_normal_move_step(g:pgametyp;u:ptypunits);
procedure move_do_last_move(g:pgametyp;u:ptypunits);
procedure move_do_prestop_move(g:pgametyp;u:ptypunits);
//############################################################################//
implementation   
//############################################################################//  
procedure consume_speed(g:pgametyp;u:ptypunits;spd:single); 
var ud:ptypunitsdb;
begin
 if not unav(u) then exit;
 ud:=get_unitsdb(g,u.dbn);

 u.cur.speed:=round(u.cur.speed-spd);
 if g.info.rules.fueluse and(u.bas.fuel>0)then u.cur.fuel:=round(u.cur.fuel-spd);
 if(not ud.firemov)and(u.bas.shoot>0)and(u.bas.speed>0)then u.cur.shoot:=max2i(trunc(((u.cur.speed/10)/(u.bas.speed/u.bas.shoot))),0);

 //Avoid rounding errors                                                   
 if u.cur.fuel<0 then u.cur.fuel:=0;
 if u.cur.shoot<0 then u.cur.shoot:=0;
 if u.cur.speed<0 then u.cur.speed:=0;
 if(u.cur.fuel=0)or(u.cur.speed=0)then if g.info.rules.fuel_shot then u.cur.shoot:=0; 
 mark_unit(g,u.num);
end;
//############################################################################//
function do_unstore(g:pgametyp;u:ptypunits;x,y:integer):boolean;
var hu:ptypunits;
air_store:boolean;
begin
 result:=false;
 if u=nil then exit;
 
 //FIXME: Should be unstore_test_pass, but that makes units exit ontop of a submarine
 if test_pass(g,x,y,u)and u.stored and unstorable(g,u,x,y) then begin
  hu:=get_unit(g,u.stored_in);

  air_store:=is_air_store(g,hu,u);
  if not check_air_storage(g,u,hu,air_store) then exit;
  mark_unit(g,u.num);  
  mark_unit(g,hu.num);    
  add_sew(g,sew_unstored,u.num,hu.num,0,0,0);
  u.stored:=false;
  u.stored_in:=-1;
  hu.currently_stored:=hu.currently_stored-1;
  u.x:=x;
  u.y:=y;
  trigger_autofire(g,u);
  trigger_autofire(g,hu);
  set_move_unit(g,u,u.x,u.y);
  if g.info.rules.unload_one_speed then consume_speed(g,u,min2i(u.cur.speed,10));    
  if g.info.rules.unload_all_shots then u.cur.shoot:=0;
  if g.info.rules.unload_all_speed then u.cur.speed:=0;
  unit_newpos(g,u,x,y);

  if u.ptyp=pt_air then u.alt:=1;
  move_check_for_mines(g,u);
  result:=true;
 end;
end;
//############################################################################//
//Strore u into ut
function do_store(g:pgametyp;u,ut:ptypunits):boolean;
var air_store:boolean;
begin
 result:=false;
 if(not unav(u))or(not unav(ut))then exit; 
  
 air_store:=is_air_store(g,ut,u);
 if not air_store then if not is_units_touching(g,u,ut) then exit;
 if storable(g,ut,u)and((u.cur.speed>=10)or air_store)then begin
  if g.info.rules.load_sub_one_speed then consume_speed(g,u,min2i(u.cur.speed,10));   //Stored already! Won't pass unav.
  if not check_air_storage(g,u,ut,air_store) then exit;
  unit_newpos(g,u,ut.x,ut.y,-1);   
  mark_unit(g,u.num);  
  mark_unit(g,ut.num);    
  add_sew(g,sew_stored,u.num,ut.num,0,0,0);
  u.stored:=true;
  u.stored_in:=ut.num;
  ut.currently_stored:=ut.currently_stored+1;
  trigger_autofire(g,u);
  if u.ptyp=pt_air then u.alt:=0;
  trigger_autofire(g,ut);
  result:=true;
 end;
end;    
//############################################################################//
function precalc_autofire(g:pgametyp):boolean;
var i:integer;
u:ptypunits;
begin 
 result:=false;
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if u.triggered_auto_fire then begin
   if isa(g,u,a_minor) then u.triggered_auto_fire:=false;
   if u.cur.hits<=0 then u.triggered_auto_fire:=false;
   if u.triggered_auto_fire then result:=true;
  end;
 end;
end;
//############################################################################//
//############################################################################//
function can_fire_to(g:pgametyp;u:ptypunits;x,y:integer):boolean;  
var ud:ptypunitsdb;
begin
 result:=false;
 if not unav(u) then exit;
 ud:=get_unitsdb(g,u.dbn);
 if(x=u.x)and(y=u.y)then exit;
 if ud.fire_type=FT_WATER_COAST then if(get_map_pass(g,x,y)<>P_WATER)and(get_map_pass(g,x,y)<>P_COAST) then exit;  
 result:=isa(g,u,a_can_fire);
end;    
//############################################################################//
function can_fire_at(g:pgametyp;u,t:ptypunits):boolean;  
begin
 result:=false;
 if not unav(u) then exit;
 if not unav(t) then exit;
 if not fire_possible(g,u,t) then exit;
 result:=isa(g,u,a_can_fire);
end;  
//############################################################################//
//Order unit to meve to within range of position (1,2 - close up to a unit/building)
function do_move_inrange(g:pgametyp;u:ptypunits;x,y,range:integer):boolean;  
begin       
 result:=false;
 if not unav(u) then exit;

 set_move_unit(g,u,x,y);

 if not pf_calc_path(g,u,range) then begin
  clear_motion(g,u,true);
 end else result:=true;
end;
//############################################################################//
//Order unit to move to within range of another unit (1,2 - close up to a unit/building)
function do_move_closeup(g:pgametyp;u,ut:ptypunits;range:integer):boolean; 
begin
 result:=false;
 if not unav(u) then exit;
 if not unav(ut) then exit;
 result:=do_move_inrange(g,u,ut.x,ut.y,range);
end;
//############################################################################//
procedure set_move_unit(g:pgametyp;u:ptypunits;xt,yt:integer;isstd:boolean=false;stop_task:integer=stsk_none;stop_target:integer=0;stop_param:integer=0);
var equ:boolean;
begin
 if not unav(u) then exit;
 clear_motion(g,u,true);      
 mark_unit(g,u.num);
 equ:=(u.xt=xt)and(u.yt=yt);
 u.xt:=xt;
 u.yt:=yt;  
 if isstd and not equ then u.rot:=getdirbydp(u.xt,u.x,u.yt,u.y);
 u.stop_task:=stop_task;
 u.stop_target:=stop_target;
 u.stop_param:=stop_param;
 u.isstd:=isstd and not equ;

 u.is_moving:=(u.x<>u.xt)or(u.y<>u.yt);
 u.stpmov:=false;
end;     
//############################################################################//
procedure upgrade_unit(g:pgametyp;par,par2:integer);
var c,h,f,a:integer;
pl:pplrtyp;
u:ptypunits; 
up:ptyp_unupd;
ud:ptypunitsdb;
begin
 //par-who;par2-target unit   
 if not unav(g,par)then exit;
 if not unave(g,par2)then exit;
 u:=get_unit(g,par2);   
 pl:=get_plr(g,u.own); 
 up:=@pl.unupd[u.dbn];
 ud:=get_unitsdb(g,u.dbn);
 if u.mk=up.mk then exit;
 c:=u.bas.cost div 4;
 if get_rescount(g,get_unit(g,par),RES_MAT,GROP_AVL)>=c then begin
  if(c>0)and(not take_res_now_minding(g,get_unit(g,par),RES_MAT,c)) then exit;

  subscan(g,u);
  u.mk:=up.mk;
  h:=u.bas.hits-u.cur.hits;
  f:=u.bas.fuel*10-u.cur.fuel;
  a:=u.bas.ammo-u.cur.ammo;
  if u.cln<>-1 then u.bas:=add_stats(add_stats(ud.bas,up.bas),g.clansdb[pl.info.clan].unupd[u.cln].bas)
               else u.bas:=          add_stats(ud.bas,up.bas);

  u.cur.ammo:=u.bas.ammo-a;
  u.cur.hits:=u.bas.hits-h;
  u.cur.fuel:=u.bas.fuel*10-f;

  add_log_msgu(g,u.own,lmt_unit_upgraded,u);
  addscan(g,u,u.x,u.y,true);  //FIXME: Net order, somehow

 end else add_log_msgu(g,u.own,lmt_unit_upgrade_fail,u);
end;
//############################################################################//
procedure disable_unit(g:pgametyp;par,par2:integer);
var u,ut:ptypunits;
begin
 //par-who;par2-target unit
 if not unav (g,par)  then exit;
 if not unave(g,par2) then exit;

 u:=get_unit(g,par);
 ut:=get_unit(g,par2);

 ut.xt:=ut.x;
 ut.yt:=ut.y;
 if ut.is_moving then clear_motion(g,ut,true);
 istopunit(g,ut,true,true);
 subscan(g,ut);
 ut.disabled_for:=3;

 u.cur.shoot:=u.cur.shoot-1;
 add_log_msgu(g,ut.own,lmt_unit_disabled,ut,u,-1,ut.disabled_for);
end;
//############################################################################//
procedure steal_unit(g:pgametyp;par,par2:integer);
var u,ut,u2:ptypunits;
i:integer;
begin
 //par-who;par2-target unit
 if not unav (g,par)  then exit;
 if not unave(g,par2) then exit;

 u:=get_unit(g,par);
 ut:=get_unit(g,par2);

 ut.xt:=ut.x;
 ut.yt:=ut.y;
 if ut.is_moving then clear_motion(g,ut,true);
 istopunit(g,ut,true,true);
 subscan(g,ut);

 ut.own:=u.own;
 //Kill the content
 for i:=0 to get_units_count(g)-1 do if unave(g,i) then begin
  u2:=get_unit(g,i);
  if u2.stored and(u2.stored_in=ut.num)then delete_unit(g,u2,false,false);
 end;
 ut.currently_stored:=0;
 if ut.disabled_for<>0 then ut.disabled_for:=0;

 addscan(g,ut,ut.x,ut.y);

 u.cur.shoot:=u.cur.shoot-1;
 add_log_msgu(g,ut.own,lmt_unit_stolen,ut,u);
end;
//############################################################################//
//Tool units actions
procedure do_toolunit(g:pgametyp;typ:integer;u,ut:ptypunits);
var c:integer;
begin             
 if not unav(u) then exit;
 if ut=nil then exit;
 mark_unit(g,u.num);  
 mark_unit(g,ut.num);

 if typ=tool_upgrade then begin upgrade_unit(g,u.num,ut.num);exit;end;
 if typ=tool_disable then begin disable_unit(g,u.num,ut.num);exit;end;
 if typ=tool_steal   then begin steal_unit  (g,u.num,ut.num);exit;end;

 if(not(ut.stored or(u=ut)))and(not isa(g,u,a_building))then begin
  if not is_units_touching(g,u,ut) then begin
   if do_move_closeup(g,u,ut,ut.siz) then begin    
    case typ of
     tool_reload:u.stop_task:=stsk_reload;
     tool_xfer2 :u.stop_task:=stsk_xfer2;
     tool_refuel:u.stop_task:=stsk_refuel;
     tool_repair:u.stop_task:=stsk_repair;
    end;
    u.stop_target:=ut.num;
   end;  
   exit;
  end;
 end;
   
 if (not are_linked(g,u,ut))and(not ut.stored) then exit;
 
 if is_toolapplicable(g,u,ut,typ) then case typ of
  tool_reload:if take_res_now_minding(g,u,RES_MAT,1) then ut.cur.ammo:=ut.bas.ammo;
  tool_xfer2:if take_res_now_minding(g,u,RES_MAT,2) then begin
   c:=put_res_now(g,ut,RES_MAT,2,false);
   if c<>0 then put_res_now(g,u,RES_MAT,2-c,false);
  end;
  tool_refuel:begin
   if g.info.rules.expensive_refuel then begin
    c:=round(ut.bas.fuel/ut.bas.speed*4)*10;
    while ut.cur.fuel<ut.bas.fuel*10 do begin
     if take_res_now_minding(g,u,RES_FUEL,1) then ut.cur.fuel:=ut.cur.fuel+c else break;
     if ut.cur.fuel>ut.bas.fuel*10 then begin ut.cur.fuel:=ut.bas.fuel*10;break;end;
    end;
   end else begin
    if take_res_now_minding(g,u,RES_FUEL,1) then ut.cur.fuel:=ut.bas.fuel*10;
   end;
  end;
  tool_repair:begin
   c:=round(ut.bas.hits/ut.bas.cost*4);
   while ut.cur.hits<ut.bas.hits do begin
    if take_res_now_minding(g,u,RES_MAT,1) then ut.cur.hits:=ut.cur.hits+c else break;
    if ut.cur.hits>ut.bas.hits then begin ut.cur.hits:=ut.bas.hits;break;end;
   end;
  end;
 end;
end;
//############################################################################//
procedure do_research(g:pgametyp);
begin
 update_research(g);
end;
//############################################################################//
procedure do_change_research(g:pgametyp;par,par2:integer);
var p:pplrtyp;
u:ptypunits;
i:integer;
begin
 if par2=0 then exit;
 p:=get_cur_plr(g);
 if par2>0 then begin
  if p.labs_free=0 then exit;
  for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
   u:=get_unit(g,i);
   if not cur_plr_unit(g,u) then continue;
   if u.isact and isa(g,u,a_research)and(u.researching=0) then begin
    u.researching:=par+1;
    break;
   end;
  end;
 end else begin
  for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
   u:=get_unit(g,i);
   if not cur_plr_unit(g,u) then continue;
   if u.isact and isa(g,u,a_research)and(u.researching=par+1) then begin
    u.researching:=0;
    break;
   end;
  end;
 end;
 update_research(g);
end;
//############################################################################//
//Do the task at arriving to the destination successfuly
procedure do_destination_reached(g:pgametyp;u:ptypunits);  
var st:ptypunits;
begin    
 if not unav(u) then exit;
 mark_unit(g,u.num);
 u.stop_task_pending:=true; 
 if precalc_autofire(g) then exit;  //FIXME: HUH?
 st:=get_unit(g,u.stop_target);     //FIXME: NOT ALWAYS!
 case u.stop_task of
  stsk_load:       if(u.x=st.x)and(u.y=st.y)then do_store(g,st,u);
  stsk_shoot:      do_order_firing_at(g,u,st);
  stsk_shoot_place:do_order_firing_to(g,u,u.stop_target,u.stop_param,true);   //What was that there for? The coordinates are mis-stored.
  stsk_enter:      do_store(g,u,st);
  stsk_refuel:     do_toolunit(g,tool_refuel,u,st);
  stsk_reload:     do_toolunit(g,tool_reload,u,st);
  stsk_xfer2 :     do_toolunit(g,tool_xfer2 ,u,st);
  stsk_repair:     do_toolunit(g,tool_repair,u,st);
 end; 
 u.stop_task:=stsk_none;
 u.stop_task_pending:=false;
 if u.builds_cnt<>0 then if not set_build(g,u,0) then begin u.builds_cnt:=0;end;
end;
//############################################################################// 
//Test if unit un can pass tx,ty
function about_to_block_pass(g:pgametyp;tx,ty:integer;u:ptypunits):boolean;
var n:integer;
bu:ptypunits;
begin result:=false; try
 if u=nil then exit;
 for n:=0 to get_units_count(g)-1 do if n<>u.num then begin
  if not unav(g,n) then continue;  
  bu:=get_unit(g,n);
  if bu.is_moving and(not bu.isstd)then if(bu.pstep>=bu.plen-4)and(bu.xt=tx)and(bu.yt=ty)then begin result:=true;break;end;
 end;

 except result:=false;stderr('Units','about_to_block_pass');end;
end;   
//############################################################################//
//Check for autofire
function would_be_autofired(g:pgametyp;t:ptypunits):boolean;
var i:integer;
u:ptypunits;
begin result:=false; try
 if not unav(t) then exit;
 if not t.triggered_auto_fire then exit;
 
 for i:=0 to get_units_count(g)-1 do if unav(g,i) and(i<>t.num)then begin     
  u:=get_unit(g,i);
  if not can_see(g,t.x,t.y,u.own,t) then continue;
  if not plr_are_enemies(g,t.own,u.own) then continue;

  if not isa(g,u,a_can_fire) then continue;
  if not isa(g,u,a_would_autofire) then continue;

  if sqr(u.x-t.x)+sqr(u.y-t.y)>sqr(u.bas.range) then continue;
  if not fire_possible(g,u,t) then continue;
  result:=true;
 end;
 exit;
  
 except stderr('Units','would_be_autofired');end;
end;                                                             
//############################################################################//
function get_actual_attk(g:pgametyp;u,t:ptypunits;attk:integer):integer;
var ud:ptypunitsdb;
begin
 result:=attk;
 if(t.ptyp=pt_wateronly)and isa(g,t,a_underwater)then begin
  ud:=get_unitsdb(g,u.dbn);
  if(ud.weapon_type=WT_BOMB)then result:=attk div 2;
 end;
end;
//############################################################################//
function do_fire_and_damage(g:pgametyp;x,y:integer;u:ptypunits;attk:integer;sub_shoot:boolean):boolean;
var t:ptypunits;
ud:ptypunitsdb;
numu,i,actual_attk:integer;
begin
 result:=false;
 if not unav(u) then exit;
 ud:=get_unitsdb(g,u.dbn);
 if attk=0 then exit;

 //Event sequencing: First fire
 add_sew(g,sew_fire,u.num,0,0,x,y);

 //Then hit
 add_sew(g,sew_hit,0,0,0,x,y);

 //Then boom
 numu:=get_unu_length(g,x,y);
 for i:=0 to numu-1 do if can_fire_at(g,u,get_unu(g,x,y,i)) then begin
  t:=get_unu(g,x,y,i);
  actual_attk:=get_actual_attk(g,u,t,attk);
  if ud.isgun then u.grot:=getdirbydp(t.x,u.x,t.y,u.y);
  if actual_attk-t.bas.armr> 0 then t.cur.hits:=t.cur.hits-actual_attk+t.bas.armr;
  if actual_attk-t.bas.armr<=0 then t.cur.hits:=t.cur.hits-1;
         
  set_detected_stealth(g,get_unu(g,x,y,i),u.own);  
  t.was_fired_on:=true;
  
  if t.cur.hits<=0 then begin
   add_log_msgu(g,t.own,lmt_unit_destroyed,t,u);
   if(not cur_plr_unit(g,u))and(u.own<>t.own)then add_log_msgu(g,u.own,lmt_unit_destroyed,t,u);
   boom_unit(g,t);
   result:=true;
  end else begin
   add_log_msgu(g,t.own,lmt_unit_under_attack,t,u);
   if(not cur_plr_unit(g,u))and(u.own<>t.own)then add_log_msgu(g,u.own,lmt_unit_under_attack,t,u);
  end;
        
  break;
 end; 
 
 if sub_shoot then begin
  u.cur.ammo:=u.cur.ammo-1;
  u.cur.shoot:=u.cur.shoot-1;
  if not ud.firemov then u.cur.speed:=u.cur.speed-((u.bas.speed*10) div u.bas.shoot);
  if u.cur.ammo<0 then u.cur.ammo:=0;
  if u.cur.shoot<0 then u.cur.shoot:=0;
  if u.cur.speed<0 then u.cur.speed:=0;   
  mark_unit(g,u.num); 
 end;  
end;             
//############################################################################//
//Process fire
function do_fire(g:pgametyp;u:ptypunits;firing_at:ivec2;out gone:boolean):boolean;
var pn,x,y:integer;
begin result:=false;gone:=false; try
 if u.bas.shoot=0 then exit;
 result:=true;
 //Why Fuel affects Firing?
 //Why not?
 if g.info.rules.fuel_shot and g.info.rules.fueluse then if(u.cur.fuel<5)and(u.bas.fuel>0) then begin 
  u.cur.shoot:=0;
  result:=false;
  exit;
 end;
    
 for pn:=0 to get_plr_count(g)-1 do set_detected_stealth(g,u,pn);
   
 if u.bas.area<>0 then for x:=-u.bas.area to u.bas.area do for y:=-u.bas.area to +u.bas.area do if abs(x)+abs(y)<>0 then begin
  gone:=do_fire_and_damage(g,firing_at.x+x,firing_at.y+y,u,area_value(g,x,y,u.bas.area,u.bas.attk),false);
 end;
 gone:=do_fire_and_damage(g,firing_at.x,firing_at.y,u,u.bas.attk,true);

 except stderr('Units','DoFire');end;
end;  
//############################################################################//
//Set the fire at location
function do_order_firing_to(g:pgametyp;u:ptypunits;x,y:integer;doit:boolean):boolean;
var trot:integer;
ud:ptypunitsdb;
gone:boolean;
begin  
 result:=false;  
 if not can_fire_to(g,u,x,y) then exit;
 ud:=get_unitsdb(g,u.dbn); 
 mark_unit(g,u.num);  

 trot:=u.rot;    
 
 u.rot:=getdirbydp(x,u.x,y,u.y);
 if ud.isgun then begin u.grot:=u.rot; u.rot:=trot; end;

 if (sqr(u.x-x)+sqr(u.y-y)<=sqr(u.bas.range)) and doit then begin    
  trigger_autofire(g,u); 
  result:=do_fire(g,u,tivec2(x,y),gone);
 end else if(not isa(g,u,a_building)) then begin
  if do_move_inrange(g,u,x,y,u.bas.range)then begin
   u.stop_task:=stsk_shoot_place;
   u.stop_target:=x;
   u.stop_param:=y;
   u.isstd:=not doit;
   result:=true;
  end;
 end;
end;  
//############################################################################//
//Set the fire at unit
function do_order_firing_at(g:pgametyp;u,t:ptypunits;x:integer=0;y:integer=0;move:boolean=true):boolean;
begin  
 result:=false;
 if can_fire_at(g,u,t) then result:=do_order_firing_to(g,u,t.x+x,t.y+y,move);
end;  
//############################################################################//
//Area fire value
function area_value(g:pgametyp;x,y,area,attk:integer):integer;      
var r:double;
begin
 result:=0;
 if area<>2 then begin
  r:=sqrt(sqr(x)+sqr(y));         
  if r<=area then result:=round(attk*(1-min2(r/area,0.85)));
 end else begin
  if(x=0)and(y=0)then result:=attk;
  if(abs(x)+abs(y)=1)then result:=3*attk div 4;
  if(abs(x)=1)and(abs(y)=1)then result:=2*attk div 4;
  if(abs(x)=2)or(abs(y)=2)then result:=1*attk div 4;
  if(abs(x)+abs(y)>2)then result:=0;
 end;
end;      
//############################################################################//
function set_move_away(g:pgametyp;u:ptypunits):boolean; 
var a,b,i:integer;
ao,bo:array of integer;
spd:single;
begin   
 result:=false;
 if not unav(u) then exit;
 
 //if u.is_moving then begin result:=true;exit;end;
 if(u.bas.speed=0)or(u.cur.speed=0)then exit;
 
 setlength(ao,0);
 setlength(bo,0);
 for a:=-1 to 1 do for b:=-1 to 1 do if(a<>0)or(b<>0)then if test_pass(g,u.x+a,u.y+b,u) then begin
  i:=length(ao);
  setlength(ao,i+1);
  setlength(bo,i+1);
  ao[i]:=a;
  bo[i]:=b;
 end;
            
 i:=length(ao);
 if i=0 then exit;
 i:=mgrandom_int(g,i); 
 spd:=10*(1+0.42*ord((u.x<>u.x+ao[i])and(u.y<>u.y+bo[i])));
 if spd>u.cur.speed then exit;
          
 mark_unit(g,u.num);  
 u.rot:=getdirbydp(u.x+ao[i],u.x,u.y+bo[i],u.y);
           
 addscan(g,u,u.x+ao[i],u.y+bo[i],true);
 subscan(g,u,true);
 remunuc(g,u.x,u.y,u);
 u.x:=u.x+ao[i];
 u.y:=u.y+bo[i];
 addunu(g,u); 

 //Detection by other players is not needed? It's stealth anyway.
 //FIXME: What if it dodged into a scan of stealth-seer?
    
 consume_speed(g,u,spd); 
 
 result:=true;
end;      
//############################################################################//
function move_check_for_mines(g:pgametyp;u:ptypunits):boolean;
var n:integer;
um:ptypunits;
begin         
 result:=false;
 if u.ptyp=pt_air then exit;
 if get_unu_length(g,u.x,u.y)<=1 then exit;
 for n:=1 to get_unu_length(g,u.x,u.y)-1 do begin
  um:=get_unu(g,u.x,u.y,n);
  if isa(g,um,a_bomb) and are_enemies(g,um,u)and(um.is_sentry)then begin   
   set_detected_stealth(g,um,u.own);
   clear_motion(g,u,true);
   add_log_msgu(g,um.own,lmt_unit_destroyed,um);
   boom_unit(g,um);
   result:=true;
   break;
  end;
 end;
end;                     
//############################################################################//
function move_get_case(g:pgametyp;u:ptypunits):integer;
var fu:boolean;
sc,fc,f:integer;
v1,v2:double;
begin                     
 result:=-1;
 sc:=u.cur.speed;
 fc:=u.cur.fuel;
 f:=u.bas.fuel;
 fu:=g.info.rules.fueluse;

 if (u.plen>=2)        and(u.pstep=0)then begin v1:=u.path[        1].pval;                                                  if (sc>=v1           )and((fu and((fc>=v1            )or(f=0)) )or(not fu) ) then result:=1;end;
 if (u.pstep< u.plen-2)and(u.pstep>0)then begin v1:=u.path[u.pstep+1].pval+u.path[u.pstep+2].pval;                           if (sc>=v1           )and((fu and((fc>=v1            )or(f=0)) )or(not fu) ) then result:=1;end;
 if  u.pstep< u.plen-2               then begin v1:=u.path[u.pstep+1].pval;v2:=u.path[u.pstep+1].pval+u.path[u.pstep+2].pval;if((sc>=v1)and(sc<v2))or ( fu and((fc>=v1)and(fc<v2))and(f>0))               then result:=1;end;
 if  u.pstep<=u.plen-2               then begin v1:=u.path[u.pstep+1].pval;                                                  if (sc< v1           )or ( fu and( fc< v1           )and(f>0))               then result:=2;end;
 if  u.pstep =u.plen-2               then begin v1:=u.path[u.pstep+1].pval;                                                  if (sc>=v1           )and((fu and((fc>=v1            )or(f=0)) )or(not fu) ) then result:=1;end;
 if  u.pstep =u.plen-1 then result:=3;
 if result=-1 then begin 
  stderr2('Units','SetMoves','The state is undefined: '+stri(result));
  clear_motion(g,u,true);
 end;
end;       
//############################################################################//
procedure move_do_normal_move_step(g:pgametyp;u:ptypunits);
var atbp:boolean;
un:ptypunits;
begin       
 mark_unit(g,u.num);
 
 //Orientation
 u.grot:=u.grot-u.rot;
 u.rot:=u.path[u.pstep].dir;
 u.grot:=(u.grot+u.rot)and 7;

 //Next motion
 u.xnt:=u.path[u.pstep+1].px;
 u.ynt:=u.path[u.pstep+1].py;

 //Would intersect with something?
 atbp:=about_to_block_pass(g,u.xnt,u.ynt,u);
 if((not test_pass(g,u.xnt,u.ynt,u))or atbp)and(not u.is_moving_build)then begin
  if not u.isbuild then begin
  
   //Would blocker move aside?
   if get_unu_length(g,u.xnt,u.ynt)<>0 then begin   
    un:=get_unu(g,u.xnt,u.ynt,0);   

    //Stealth unit would step aside, current unit would hang in current state until unobstructed
    if(un.stealth_detected[u.own]=0)and(isa(g,un,a_stealth_or_underw))then if set_move_away(g,un) then begin 
     u.is_moving_now:=false;
     exit;
    end;

    //Otherwise, stop other unit if moving
    set_detected_stealth(g,un,u.own);
    clear_motion(g,un,true);
   end;

   //Stop our unit
   clear_motion(g,u,false);
   //If it's not about blocking then ask for repath  
   if not atbp then u.is_moving:=true;
  end else clear_motion(g,u,false);
 end else begin
  //Clear road, proceed with next step

  //Proceed with motion
  u.is_moving_now:=true;

  //Take off a plane if landed
  if u.ptyp=pt_air then if u.alt=0 then u.alt:=1; 
  //No moving through range
  trigger_autofire(g,u);

  if not would_be_autofired(g,u) then begin
   //Advance path, consume speed for motion to be carried out                        
   u.pstep:=u.pstep+1;
   consume_speed(g,u,u.path[u.pstep].pval); 
  end;
 end;
end;  
//############################################################################//
procedure move_do_last_move(g:pgametyp;u:ptypunits);
var j:integer;
begin        
 mark_unit(g,u.num);
 
 //Orientation
 u.grot:=u.grot-u.rot;
 u.rot:=u.path[u.pstep].dir;
 u.grot:=(u.grot+u.rot)and 7;
    
 //Clear path, stop motion
 clear_motion(g,u,true);
                     
 //Stealth detected?
 for j:=0 to get_plr_count(g)-1 do if not stealthdet(g,u.x,u.y,j,u) then u.stealth_detected[j]:=0;
 u.stealth_detected[u.own]:=0;
 
 //Triggered autofire?
 if not isa(g,u,a_stealthed) then trigger_autofire(g,u); 
 
 //Add message
 for j:=0 to get_plr_count(g)-1 do if(u.own<>j)and can_see(g,u.x,u.y,j,u) then add_log_msgu(g,j,lmt_enemy_unit_moved,u);
 
 //Do actions at the end
 do_destination_reached(g,u);

 //If a plane, check for landing pad and initiate landing if true
 if u.ptyp=pt_air then if get_unu_length(g,u.x,u.y)>1 then if isa(g,get_unu(g,u.x,u.y,1),a_landing_pad) and not are_enemies(g,get_unu(g,u.x,u.y,1),u) then begin
  u.alt:=0;
  trigger_autofire(g,u);
 end;
end; 
//############################################################################//
procedure move_do_prestop_move(g:pgametyp;u:ptypunits);
begin
 //Triggered autofire?
 if not isa(g,u,a_stealthed) then trigger_autofire(g,u); 
 
 //Is other unit there?
 if length(u.path)>u.pstep+1 then if u.path[u.pstep+1].pval>2000 then begin
  //Stop if yes
  if test_pass(g,u.path[u.pstep+1].px,u.path[u.pstep+1].py,u) then u.path[u.pstep+1].pval:=u.path[u.pstep+1].rpval else clear_motion(g,u,true);
  exit;
 end;
 
 //Standing with move orders
 u.isstd:=true;    
 mark_unit(g,u.num);
end;
//############################################################################//
begin
end.   
//############################################################################//
