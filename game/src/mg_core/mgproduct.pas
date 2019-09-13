//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core Units handling functions
//############################################################################//
unit mgproduct;
interface
uses asys,crc32,
mgvars,mgrecs,sds_rec,mgauxi,mgunits,mgress,mgloads,mg_builds,mgl_logs,mgl_common,mgl_scan,mgl_upgcalc,mgl_attr,mgl_res,mgl_tests,mgl_unu;
//############################################################################//

function  startunit(g:pgametyp;u:ptypunits;first_run,no_auto:boolean):boolean;
function  stopunit(g:pgametyp;u:ptypunits;autolevel:boolean=true;stop_anyway:boolean=false):boolean;

function  next_turn(g:pgametyp):boolean;
function  do_end_turn_request(g:pgametyp;lost,of_player:boolean):boolean;
procedure do_landing_request(g:pgametyp);
//procedure do_prev_turn_request(g:pgametyp;of_player:boolean);
procedure do_land_players(g:pgametyp);      
procedure surrender_current_player(g:pgametyp);

procedure setdoze(g:pgametyp;u:ptypunits);
//############################################################################//
implementation
//############################################################################//
//Start button
function startunit(g:pgametyp;u:ptypunits;first_run,no_auto:boolean):boolean;
var an,ri:integer;
enough:array[RES_MIN..RES_MAX]of boolean;
label 1;
begin result:=false; try
 if not unav(u) then exit;  
 mark_unit(g,u.num);  

 if u.disabled_for<>0 then exit;
 if isa(g,u,a_building)and u.isbuild and (u.builds_cnt>0) then if not re_set_build(g,u) then exit;
        
 u.isact:=true;
 
 for ri:=RES_MIN to RES_MAX do enough[ri]:=get_rescount(g,u,ri,GROP_AVL)>=u.prod.use[ri];
 result:=enough[RES_MAT] and enough[RES_FUEL] and enough[RES_GOLD] and enough[RES_HUMAN];

 ri:=RES_POW;
 if result then begin
  if not enough[ri] then begin
   if not isa(g,u,a_building) then begin result:=false;goto 1;end;                  
   if first_run then res_to_temp(g,u.domain,true);
   an:=take_debt(g,u,ri,u.prod.use[ri],true,nil,true);
   if an<>0 then begin result:=false;goto 1;end else take_debt(g,u,ri,u.prod.use[ri],true,nil,false);
  end else take_debt(g,u,ri,u.prod.use[ri],false,nil,false);

  for ri:=RES_MIN to RES_MAX do if ri<>RES_POW then take_debt(g,u,ri,u.prod.use[ri],false,nil,false);
  if not no_auto then autolevel_res(g,u);
 end;
 1:   

 u.isact:=result;
 
 if isa(g,u,a_research) then begin
  if u.researching=0 then u.researching:=1;
  update_research(g);
 end;

 if not result then begin
  //s1:='';
  //for ri:=RES_MIN to RES_MAX do if not enough[ri] then begin if s1<>'' then s1:=s1+', ';s1:=s1+res_ids[ri];end;
  //if cur_plr_unit(g,u) then msgu_set(g,'Not enough '+s1+'.');
  if cur_plr_unit(g,u) then add_log_msgu(g,u.own,lmt_start_no_materials,u);
 end else add_sew(g,sew_act_start,u.num,0,0,0,0);
 
 except stderr('Units','StartUnit');end;
end;
//############################################################################//
procedure stop_clearing(g:pgametyp;u:ptypunits);   
begin try          
 if not unav(u) then exit;   
 if not u.isclrg then exit;
            
 addscan(g,u,u.prior_x,u.prior_y); 
 subscan(g,u);
 remunuc(g,u.x,u.y,u);     
   
 u.isclrg:=false;      
 if u.clr_tape>=0 then delete_unit(g,get_unit(g,u.clr_tape),false,false); 
 u.cur_siz:=1;
 u.x:=u.prior_x;
 u.y:=u.prior_y;
 u.prior_x:=0;
 u.prior_y:=0;
 u.clr_unit:=-1; 
   
 addunu(g,u);

 except stderr('Units','stop_clearing');end;   
end;       
//############################################################################//
//Stop production building.
//Production units support dropped
function stop_production(g:pgametyp;u:ptypunits;autolevel,stop_anyway:boolean):boolean;
var ri:integer; 
have_debt:boolean;
debt:array[RES_MIN..RES_MAX]of boolean;
begin result:=false;try
 if not unav(u) then exit;

 for ri:=RES_MIN to RES_MAX do debt[ri]:=u.prod.dbt[ri]>0;
 have_debt:=debt[RES_MAT] or debt[RES_FUEL] or debt[RES_GOLD] or debt[RES_POW] or debt[RES_HUMAN];
 
 u.isact:=false;
 if not have_debt then begin
  result:=true;       
  add_sew(g,sew_act_stop,u.num,0,0,0,0);
  for ri:=RES_MIN to RES_MAX do return_debt(g,u,ri,u.prod.use[ri]);
 end else begin
  for ri:=RES_MIN to RES_MAX do debt[ri]:=get_rescount(g,u,ri,GROP_AVL)<u.prod.dbt[ri];
   
  have_debt:=debt[RES_MAT] or debt[RES_FUEL] or debt[RES_GOLD] or debt[RES_POW] or debt[RES_HUMAN];
  if(not have_debt)or stop_anyway then begin
   result:=true;               
   u.isact:=false;    
   add_sew(g,sew_act_stop,u.num,0,0,0,0);
   for ri:=RES_MIN to RES_MAX do return_debt(g,u,ri,u.prod.use[ri]);
   for ri:=RES_MIN to RES_MAX do begin
    res_stop_lacking(g,u,ri,take_debt(g,u,ri,take_debt(g,u,ri,u.prod.dbt[ri],false,nil,false),true,u,false));
    u.prod.dbt[ri]:=0;
   end;
  end else begin
   u.isact:=true;
   //s1:='';
   //for ri:=RES_MIN to RES_MAX do if debt[ri] then begin if s1<>'' then s1:=s1+', ';s1:=s1+res_ids[ri];end;
   //if cur_plr_unit(g,u) then msgu_set(g,'Can not be stoped. Provides '+s1+'.');
   if cur_plr_unit(g,u) then add_log_msgu(g,u.own,lmt_stop_need_materials,u);
  end;
 end;
 
 if isa(g,u,a_research) then update_research(g);
 if autolevel then autolevel_res(g,u);  
 
 except stderr('Units','stop_production');end;
end;
//############################################################################//
//Stop button
function stopunit(g:pgametyp;u:ptypunits;autolevel:boolean=true;stop_anyway:boolean=false):boolean;
begin result:=false; try
 if not unav(u) then exit;  
 mark_unit(g,u.num);  
 if not u.isbuild then begin
  result:=true;
  if u.isclrg then stop_clearing(g,u) 
              else result:=stop_production(g,u,autolevel,stop_anyway);
 end else begin      
  result:=true; 
  if isa(g,u,a_building) then begin stop_construction_building(g,u,autolevel);exit;end;
  stop_construction_unit(g,u);  
 end;    
 
 except stderr('Units','StopUnit');end;
end;       
//############################################################################//
procedure unit_endturn_process(g:pgametyp;u:ptypunits);
var pn:integer;
cu:ptypunits;
begin
 if u=nil then exit;

 //Bulldozer
 if u.isclrg and u.isact then begin
  u.clrturns:=u.clrturns-1;
  if u.clrturns=0 then begin
   cu:=get_unit(g,u.clr_unit);
   if cu<>nil then begin        
    u.prod.now[RES_MAT]:=u.prod.now[RES_MAT]+cu.clrval;
    if u.prod.now[RES_MAT]>u.prod.num[RES_MAT] then u.prod.now[RES_MAT]:=u.prod.num[RES_MAT];
    delete_unit(g,cu,false,false);  
   end;     
   stop_clearing(g,u); 
  end;
 end;

 if u.bas.speed>0 then begin
  //Motion    
  if g.info.rules.fueluse then if (u.ptyp=pt_air)and(u.bas.fuel>0) then if u.alt<>0 then begin
   u.cur.fuel:=u.cur.fuel-10; //Decrement fuel for air unit without additional condition!
   if u.cur.fuel<=0 then begin
    add_log_msg(g,u.own,lmt_aircrash,u.x,u.y,u.dbn);
    boom_unit(g,u);
    exit;
   end;
  end;
  //Path from old turn calculations
  if u.is_moving and (length(u.path)>0) then begin
   if(u.path[u.pstep+1].rpval<>0)then begin
    u.cur.speed:=u.cur.speed mod round(u.path[u.pstep+1].rpval*10)+u.bas.speed*10;
   end else u.cur.speed:=u.bas.speed*10;
  end else u.cur.speed:=u.bas.speed*10;
 end;
 //Reset current params
 u.cur.shoot:=u.bas.shoot;
 //Stealth detection calculation
 for pn:=0 to get_plr_count(g)-1 do if pn<>u.own then if(u.stealth_detected[pn]>=1)and(not stealthdet(g,u.x,u.y,pn,u))and(not isa(g,u,a_building)) then begin
  u.stealth_detected[pn]:=u.stealth_detected[pn]-2;
  if u.stealth_detected[pn]<0 then u.stealth_detected[pn]:=0;
 end;
 u.stealth_detected[u.own]:=0;
 //Disable calculations
 if u.disabled_for>0 then begin
  u.disabled_for:=u.disabled_for-1;
  if u.disabled_for=0 then begin
   if isa(g,u,a_always_active) then u.isact:=true;
   addscan(g,u,u.x,u.y,true);
  end;
 end;
 //Unit Flags calculations
 if(u.is_moving and (u.builds_cnt=0))then u.isstd:=true;
end;   
//############################################################################//
procedure unit_endturn_building_autorepair(g:pgametyp;u:ptypunits);
var h:integer;
begin
 if u=nil then exit;
 if not isa(g,u,a_building) then exit;
 if u.bas.hits=u.cur.hits then exit;
 if u.was_fired_on then exit;

 h:=u.bas.hits div u.bas.cost*4;
 if h=0 then h:=1;
 if get_rescount(g,u,RES_MAT,GROP_AVL)>=1 then if take_res_now_minding(g,u,RES_MAT,1) then begin
  u.cur.hits:=u.cur.hits+h;
  if u.cur.hits>u.bas.hits then u.cur.hits:=u.bas.hits;
 end;
end;
//############################################################################//
procedure unit_endturn_selfrepair(g:pgametyp;u:ptypunits);
var h:integer;
begin
 if u=nil then exit;
 if not isa(g,u,a_self_repair) then exit;
 if u.bas.hits=u.cur.hits then exit;
 if u.was_fired_on then exit;

 h:=u.bas.hits div u.bas.cost*4;
 if h=0 then h:=1;

 u.cur.hits:=u.cur.hits+h;
 if u.cur.hits>u.bas.hits then u.cur.hits:=u.bas.hits;
end;
//############################################################################//
function unit_endturn_build(g:pgametyp;u:ptypunits;md:integer):boolean;
var dn:integer;
d:ptypunitsdb;
begin
 result:=false;
 if u=nil then exit;
 
 //Construction
 if u.isbuild and(u.builds_cnt>0)then begin
  if u.isact and(u.builds[0].left_to_build>0)then begin  
   if md=0 then begin
    u.builds[0].left_to_build:=u.builds[0].left_to_build-u.builds[0].cur_take;
    u.builds[0].left_turns:=u.builds[0].left_turns-1;
    u.builds[0].left_mat:=u.builds[0].left_mat-u.builds[0].cur_use;
    if u.builds[0].left_to_build=0 then u.prod.next_use[RES_MAT]:=0;
    //Get resources if unit
    if not isa(g,u,a_building)then if u.isact and(not u.isbuildfin)then u.prod.now[RES_MAT]:=u.prod.now[RES_MAT]-u.builds[0].cur_use;
   end else if not re_set_build(g,u) then istopunit(g,u);
  end;
  if md=1 then if u.builds[0].left_to_build=0 then begin
   dn:=getdbnum(g,u.builds[0].typ);
   d:=get_unitsdb(g,dn);   
   if d=nil then exit;
                      
   u.isbuildfin:=true;
   u.isbuild:=false;
   if isa(g,u,a_building) then result:=true; //Autolevel power
   add_log_msg(g,u.own,lmt_build_completed,u.x,u.y,u.dbn,u.own,-1,-1,u.x,u.y,dn,u.own);
   if(not isadb(g,d,a_bld_on_plate))and(isadb(g,d,a_building))and(d.siz=1) then begin
    u.isbuildfin:=false;
    finish_build(g,u.x,u.y,u);
   end;  
   if(isadb(g,d,a_bld_on_plate))and(isadb(g,d,a_building))and(u.builds_cnt>1)then begin
    if test_pass(g,u.builds[1].x,u.builds[1].y,u) then begin
     u.isbuildfin:=false;
     finish_build(g,u.x,u.y,u);
    end else u.builds_cnt:=1;
   end;
  end;
 end;
end;     
//############################################################################//
procedure do_land_players(g:pgametyp);
var i,ri:integer;
u:ptypunits;
begin
 if not g.info.rules.direct_land then set_initial_resources(g);
 //Land all players
 for i:=0 to get_plr_count(g)-1 do land_one_player(g,i);
 for i:=0 to get_plr_count(g)-1 do calc_scan_full(g,get_plr(g,i),true);
   
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  for ri:=RES_MINING_MIN to RES_MINING_MAX do u.prod.mining[ri]:=16; //Cause createunit think we have nothing below. No resources were added, and that's locked in by calcmine.
 end;
 for i:=0 to get_plr_count(g)-1 do calc_mining(g,i,false);
end;
//############################################################################//
//End turn pressed
function do_end_turn_request(g:pgametyp;lost,of_player:boolean):boolean;
var i,st:integer;
u:ptypunits;
cp:pplrtyp;
begin result:=true; try
 cp:=get_cur_plr(g);
 if not is_landed(g,cp) then exit;
 
 if not lost then for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if cur_plr_unit(g,u) and(u.is_moving)then begin
   if u.is_moving_now then result:=false;
   if u.is_moving and(not u.isstd)then result:=false;
   if u.isstd and(u.cur.speed>=u.path[u.pstep+1].rpval)and(((u.cur.fuel>0)or(u.bas.fuel=0))or(not g.info.rules.fueluse))then begin
    st:=0;
    if u.plen>0 then if u.pstep<=u.plen-2 then st:=u.pstep+1;
    if u.pstep=0 then st:=2;
    if st<u.plen then if u.path[st].pval=0 then st:=st+1;
    if st<u.plen then if not((u.cur.speed<u.path[st].rpval)or( g.info.rules.fueluse and(u.cur.fuel<u.path[st].rpval)and(u.bas.fuel>0)) ) then begin
     u.isstd:=false;
     result:=false;
    end;
   end;
  end;
 end;

 if not lost then begin
  if not result then exit;
  //FIXME: Should be made redundand
  if not res_endturn(g,g.state.cur_plr,true) then exit;
 end;

 next_turn(g);
 
 except stderr('Units','do_end_turn_request');end;
end;
//############################################################################//
//Actual landing
procedure do_landing_request(g:pgametyp);
var cp:pplrtyp;
begin  try
 cp:=get_cur_plr(g);
 if not is_landed(g,cp) then exit;

 if(g.state.turn=0)and(g.state.cur_plr=get_plr_count(g)-1)then do_land_players(g);
 next_turn(g);
 
 except stderr('Units','do_landing_request');end;
end;
//############################################################################//
procedure do_research(g:pgametyp;n:integer);
var p:pplrtyp;
u:ptypunits;
up:ptyp_unupd;
ud,dnud:ptypunitsdb;
eud:typ_unupd;
clp:ptyp_unupd;
i,j,k,dn,mpt:integer;
crc:dword;
cl:ptypclansdb;
begin
 update_research(g);  
 
 fillchar(eud,sizeof(eud),0);
 eud.typ:='';
 
 p:=get_plr(g,n); 
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);   
  if u.own<>n then continue;
  if isa(g,u,a_research)and u.isact and(u.researching<>0)then p.rsrch_spent[u.researching-1]:=p.rsrch_spent[u.researching-1]+1;
  if isa(g,u,a_research)and u.isact and(u.researching=0)then stopunit(g,u);
 end;  
 
 for i:=0 to RS_COUNT-1 do if p.rsrch_spent[i]>=calc_res_turns(g,p.rsrch_level[i]*10,i,0)then begin
  p.rsrch_spent[i]:=p.rsrch_spent[i]-calc_res_turns(g,p.rsrch_level[i]*10,i,0);
  p.rsrch_level[i]:=p.rsrch_level[i]+1; 
  
  for j:=0 to get_unitsdb_count(g)-1 do begin  
   up:=@p.unupd[j];
   ud:=get_unitsdb(g,j);
   cl:=get_clan(g,p.info.clan);
   clp:=@eud;
   for k:=0 to length(cl.unupd)-1 do if cl.unupd[k].typ=ud.typ then begin
    clp:=@cl.unupd[k];
    break;
   end;

   //A way to detect changes without too many comparisons
   crc:=crc32_buf(up,sizeof(up^));
   case i of
    0:up.bas.attk :=up.bas.attk +calc_res_add(clp.bas.attk +ud.bas.attk ,p.rsrch_level[i]*10,ut_attk);
    1:up.bas.shoot:=up.bas.shoot+calc_res_add(clp.bas.shoot+ud.bas.shoot,p.rsrch_level[i]*10,ut_shot);
    2:up.bas.range:=up.bas.range+calc_res_add(clp.bas.range+ud.bas.range,p.rsrch_level[i]*10,ut_range);
    3:up.bas.armr :=up.bas.armr +calc_res_add(clp.bas.armr +ud.bas.armr ,p.rsrch_level[i]*10,ut_armor);
    4:up.bas.hits :=up.bas.hits +calc_res_add(clp.bas.hits +ud.bas.hits ,p.rsrch_level[i]*10,ut_hits);
    5:up.bas.speed:=up.bas.speed+calc_res_add(clp.bas.speed+ud.bas.speed,p.rsrch_level[i]*10,ut_speed);
    6:up.bas.scan :=up.bas.scan +calc_res_add(clp.bas.scan +ud.bas.scan ,p.rsrch_level[i]*10,ut_scan);
    7:begin
     mpt:=2;
     for dn:=0 to get_unitsdb_count(g)-1 do begin
      dnud:=get_unitsdb(g,dn);
      if ud.bldby=dnud.canbuildtyp then begin
       mpt:=dnud.bas.mat_turn;
       break;
      end;                 // + ?
     end;
     up.bas.cost:=up.bas.cost+calc_res_add(clp.bas.cost +ud.bas.cost,p.rsrch_level[i]*10,ut_cost,mpt);
    end;
   end;
   if crc<>crc32_buf(up,sizeof(up^)) then inc(up.mk);  //Things changed? Increase mk
  end;

  add_log_msg(g,n,lmt_research_completed,p.info.lndx,p.info.lndy,-1,n,i,p.rsrch_level[i]*10);
 end;
          
 update_research(g);
end;       
//############################################################################//
procedure set_game_finished(g:pgametyp);
begin
 g.state.status:=GST_ENDGAME;
end;    
//############################################################################//
procedure surrender_current_player(g:pgametyp);
var cp:pplrtyp;
i:integer;
begin
 cp:=get_cur_plr(g);
 set_lost(g,cp);
 for i:=0 to get_plr_count(g)-1 do add_log_msg(g,i,lmt_player_lost,cp.info.lndx,cp.info.lndy,-1,-1,-1,cp.num);
end;
//############################################################################//
//Next turn
function next_turn(g:pgametyp):boolean;
var i,ri,next_plr:integer;
do_next:boolean;       //WTF was that? function and var of same name?
u:ptypunits;
active_cnt:integer;
begin result:=false; try
 g.state.status:=GST_THEGAME;

 active_cnt:=0;
 for i:=0 to get_plr_count(g)-1 do begin
  if not is_lost(g,get_plr(g,i)) then active_cnt:=active_cnt+1;
 end;

 if active_cnt<=1 then begin
  set_game_finished(g);
  exit;
 end;
 
 if(not g.state.mor_done)and(g.state.turn<>0)then begin
  if g.state.turn>=g.info.rules.moratorium then begin
   next_plr:=get_next_plr(g);
   if next_plr=0 then g.state.mor_done:=true;  
   g.state.turn:=1;  
   do_next:=next_plr<=g.state.cur_plr;
  end else begin
   next_plr:=g.state.cur_plr;
   do_next:=true;
  end;
 end else begin     
  next_plr:=get_next_plr(g);
  do_next:=next_plr<=g.state.cur_plr;  
 end;     

 g.state.cur_plr:=next_plr;

 if do_next and(g.state.turn=0)then if landing_detect_intersect(g) then begin
  g.state.status:=GST_TAINT;   //Needed for the client to be able to detect the intersection
  clear_game(g);
  exit;
 end;
 if do_next then g.state.turn:=g.state.turn+1;
 
 //Process unit motions
 for i:=0 to get_units_count(g)-1 do if mine_fine(g,get_unit(g,i)) then unit_endturn_process(g,get_unit(g,i));
 setunu(g);
            
 //Process research
 if g.state.turn>1 then do_research(g,next_plr);

 //Process buildings working
 //cleanup_balance(next_plr,false);
 for i:=0 to get_units_count(g)-1 do begin   
  u:=get_unit(g,i);
  if mine_fine(g,u) then begin
   for ri:=RES_MIN to RES_MAX do if(ri<>RES_MAT)or(not u.isbuild)then u.prod.next_use[ri]:=u.prod.use[ri];
   unit_endturn_build(g,u,0);
  end;
 end;
 
 //The longest part
 if g.state.turn>1 then res_endturn(g,next_plr,false);   

 for i:=0 to get_units_count(g)-1 do if mine_fine(g,get_unit(g,i)) then if unit_endturn_build(g,get_unit(g,i),1) then autolevel_res(g,get_unit(g,i));       
 for i:=0 to get_units_count(g)-1 do if mine_fine(g,get_unit(g,i)) then begin
  unit_endturn_building_autorepair(g,get_unit(g,i));
  unit_endturn_selfrepair(g,get_unit(g,i));
 end;
 for i:=0 to get_units_count(g)-1 do begin
  u:=get_unit(g,i);
  if mine_fine(g,u) then u.was_fired_on:=false;
 end;
  
 if not is_landed(g,@g.plr[next_plr]) then g.state.status:=GST_SETGAME;  //Next player setup needed         
 
 result:=true;
 add_log_msgself(g,lmt_endturn,g.state.turn);

 except stderr('Units','next_turn');end;
end;
//############################################################################//
//Begin dozing
procedure setdoze(g:pgametyp;u:ptypunits);
var x,y,x1,y1,j,n:integer;
ui,cn:ptypunits;
q:byte;
begin try
 if not unav(u) then exit;
 x:=u.x;
 y:=u.y;
 mark_unit(g,u.num);
 
 n:=get_unu_length(g,x,y);
 if isa(g,u,a_cleaner) then if n>1 then for j:=1 to n-1 do begin
  cn:=get_unu(g,x,y,j);
  if cn.typ='smlrubble' then begin
   if not test_pass(g,x,y,u,true)then exit;
   ui:=create_unit(g,'smlrope',x,y,u.own,false);
   u.clr_tape:=ui.num;
   u.isclrg:=true;
   u.clrturns:=1;
   u.clr_unit:=cn.num;
   u.rot:=0;u.grot:=0;  
   u.prior_x:=x;
   u.prior_y:=y;
   u.cur_siz:=1;
   break;
  end;  
  if cn.typ='bigrubble' then begin
   x1:=0;
   y1:=0;
   
   q:=get_unu_qtr(g,x,y,1);
   if q=UQ_UP_LEFT   then begin x1:=x;  y1:=y;  end;  
   if q=UQ_UP_RIGHT  then begin x1:=x-1;y1:=y;  end;  
   if q=UQ_DWN_RIGHT then begin x1:=x-1;y1:=y-1;end;  
   if q=UQ_DWN_LEFT  then begin x1:=x;  y1:=y-1;end;  
   
   if not test_pass(g,x1  ,y1  ,u,true)then exit;    
   if not test_pass(g,x1+1,y1  ,u,true)then exit;    
   if not test_pass(g,x1  ,y1+1,u,true)then exit;    
   if not test_pass(g,x1+1,y1+1,u,true)then exit;   
             
   addscan(g,u,x1,y1); 
   subscan(g,u);
   remunuc(g,u.x,u.y,u);
     
   ui:=create_unit(g,'bigrope',x1,y1,u.own,false);
   u.clr_tape:=ui.num;
   u.isclrg:=true;
   u.clrturns:=4;
   u.clr_unit:=cn.num;
   u.rot:=0;u.grot:=0;
   u.x:=x1;
   u.y:=y1;
   u.prior_x:=x;
   u.prior_y:=y; 
   u.cur_siz:=2;  
   
   addunu(g,u);
   break;
  end;
 end;

 except stderr('Units','SetDoze');end;
end;    
//############################################################################//
begin
 istopunit:=@stopunit;
 istartunit:=@startunit;
 iunit_endturn_build:=@unit_endturn_build;
end.   
//############################################################################//
