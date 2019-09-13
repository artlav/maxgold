//############################################################################//  
unit mgl_rmnu;
interface  
uses asys,strval,mgrecs,mgl_common,mgl_attr,mgl_res,mgl_actions;       
//############################################################################//
const
//RMNU functions
RMNU_BUILD=1;
RMNU_STOP_BUILD=2;
RMNU_STOP_MOVE=3;
RMNU_START=4;
RMNU_BLOW=5;
RMNU_ACTIVATE=6;
RMNU_ENTER=7;
RMNU_LOAD=8;
RMNU_DONE=9;
RMNU_XFER=10;
RMNU_REFUEL=11;
RMNU_ATTACK=12;
RMNU_DOZE=13;
RMNU_PUT_MINES=14;
RMNU_REPAIR=15;
RMNU_RELOAD=16;
RMNU_RESEARCH=18;
RMNU_ALLOCATE=19;
RMNU_UPGRADES=20;
RMNU_GET_MINES=21;
RMNU_SENTRY=22;
RMNU_STEAL=23;
RMNU_DISABLE=24;
RMNU_UPDATE=25;
RMNU_UPDATEALL=26;
RMNU_MOVE=27;
RMNU_GIVE_2=28;
//############################################################################//  
//Rmenu info
type rmrec=record
 func,key:integer;
 nam:stringmg;
end;

rmnu_rec=record
 fnc:array[0..15]of rmrec;   //Function list
 cnt:integer;                //Function count (interface)
end;    

mods_rec=record
 //Mouse control modes
 attack_default,attack_command:boolean;
 enter_command,fetch_command,store_exit:boolean;
 xfer,refuel,reload,repair,give_two:boolean;
 build_exit,build_rect,build_path:boolean;
 disabe_default,disabe_command:boolean;
 steal_default,steal_command:boolean;
 move_default,move_command,move_path:boolean;
 select_default,not_available:boolean;

 exit_storage_unit:integer;             //Activate what
end;
pmods_rec=^mods_rec;
//############################################################################//  
var r_menu:rmnu_rec;
//############################################################################//  
function  get_mods(g:pgametyp):pmods_rec;     
procedure blank_modes(g:pgametyp);

procedure set_game_menu(g:pgametyp;n:dword);
procedure calc_rmnu(g:pgametyp;u:ptypunits;no_action:boolean);
procedure do_rmnu(g:pgametyp;pos:integer;no_action:boolean);

procedure check_unit_mods(g:pgametyp;no_action:boolean);
//############################################################################//  
implementation   
//############################################################################//
var mods:mods_rec;       //Mouse control modes
//############################################################################//
function get_mods(g:pgametyp):pmods_rec;
begin
 result:=@mods;
end;            
//############################################################################//
procedure blank_modes(g:pgametyp);
var mods:pmods_rec;
begin
 mods:=get_mods(g);
 fillchar(mods^,sizeof(mods^),0);
end;      
//############################################################################//
procedure set_game_menu(g:pgametyp;n:dword);
begin           
 if assigned(menu_callback) then menu_callback(g.grp_1,n);
end;
//############################################################################//
procedure add_rmnu_fnc(fnc:integer);
var key:integer;
nam:string;
begin
 key:=-1;
 nam:='WTF';

 case fnc of   
  RMNU_RESEARCH:  begin key:=1;nam:=po('Research');end;
  RMNU_ALLOCATE:  begin key:=1;nam:=po('Balance');end;
  RMNU_ACTIVATE:  begin key:=1;nam:=po('Activate');end;
  RMNU_UPGRADES:  begin key:=1;nam:=po('Upgrades');end; 
  RMNU_ATTACK:    begin key:=3;nam:=po('Attack');end;  
  RMNU_DOZE:      begin key:=1;nam:=po('Clean');end;
  RMNU_BUILD:     begin key:=1;nam:=po('Build');end;
                                                         
  RMNU_DISABLE:   begin key:=2;nam:=po('Disable');end;
  RMNU_PUT_MINES: begin key:=2;nam:=po('Put mines');end;

  RMNU_STEAL:     begin key:=3;nam:=po('Steal');end;
  RMNU_GET_MINES: begin key:=3;nam:=po('Unmine');end;
  RMNU_REPAIR:    begin key:=3;nam:=po('Repair');end;
  RMNU_RELOAD:    begin key:=3;nam:=po('Reload');end;
  RMNU_REFUEL:    begin key:=3;nam:=po('Refuel');end;

  RMNU_MOVE:      begin key:=4;nam:=po('Move');end;
  RMNU_UPDATE:    begin key:=4;nam:=po('Upgrade');end;
  RMNU_UPDATEALL: begin key:=4;nam:=po('Upgrade all');end;

  RMNU_GIVE_2:    begin key:=5;nam:=po('Give 2');end;  
  RMNU_LOAD:      begin key:=5;nam:=po('Load');end;

  RMNU_XFER:      begin key:=6;nam:=po('X-fer');end;

  RMNU_START:     begin key:=7;nam:=po('Start');end;
  RMNU_ENTER:     begin key:=7;nam:=po('Enter');end;

  RMNU_STOP_BUILD:begin key:=8;nam:=po('Stop');end;
  RMNU_STOP_MOVE: begin key:=8;nam:=po('Stop');end;
  RMNU_SENTRY:    begin key:=8;nam:=po('Sentry');end;

  RMNU_BLOW:      begin key:=9;nam:=po('Remove');end;

  RMNU_DONE:      begin key:=0;nam:=po('Done');end;
 end;

 nam:='['+stri(key)+'] '+nam;

 r_menu.fnc[r_menu.cnt].func:=fnc;
 r_menu.fnc[r_menu.cnt].nam:=nam;
 r_menu.fnc[r_menu.cnt].key:=key;
 r_menu.cnt:=r_menu.cnt+1;
end;     
//############################################################################//
procedure add_rmnu_note(s:string);
begin
 r_menu.fnc[r_menu.cnt-1].nam:=r_menu.fnc[r_menu.cnt-1].nam+' '+s;
end;
//############################################################################//
//Calc repeat-menu
procedure calc_rmnu(g:pgametyp;u:ptypunits;no_action:boolean);
var u2:ptypunits;
ud:ptypunitsdb;
j,cost:integer;
rul:prulestyp;
begin
 if not unav(u) then exit;
 
 rul:=get_rules(g);
 ud:=get_unitsdb(g,u.dbn);
 r_menu.cnt:=0;
 if cur_plr_unit(g,u) then begin
  if not isa(g,u,a_disabled) then begin
   if isa(g,u,a_research)and u.isact then add_rmnu_fnc(RMNU_RESEARCH);
   if isa(g,u,a_mining)  and u.isact then add_rmnu_fnc(RMNU_ALLOCATE);
   if(ud.store_lnd>0)or(ud.store_wtr>0)or(ud.store_air>0)or(ud.store_hmn>0)then begin add_rmnu_fnc(RMNU_ACTIVATE);if not no_action then add_rmnu_fnc(RMNU_LOAD);end;
   if ud.canbuild and not u.isbuildfin and(not u.isbuild or isa(g,u,a_building))then add_rmnu_fnc(RMNU_BUILD);
   if not no_action then begin
    if isa(g,u,a_infiltrator) then begin add_rmnu_fnc(RMNU_STEAL);add_rmnu_fnc(RMNU_DISABLE); end;
    if isa(g,u,a_upgrader)then add_rmnu_fnc(RMNU_UPGRADES);
    if isa(g,u,a_repair)  then add_rmnu_fnc(RMNU_REPAIR);
    if isa(g,u,a_reloader)then add_rmnu_fnc(RMNU_RELOAD);
    if(u.prod.num[RES_FUEL]>0)then add_rmnu_fnc(RMNU_REFUEL);
    if(ud.fire_type>FT_NONE)and(u.cur.shoot>0)and(u.cur.ammo>0)then add_rmnu_fnc(RMNU_ATTACK);
    if not isa(g,u,a_building) and not u.isbuild and not u.isbuildfin and(not rul.load_sub_one_speed or(u.cur.speed>=10))then add_rmnu_fnc(RMNU_ENTER);
    if not isa(g,u,a_building) and not u.isbuild and not u.isbuildfin then add_rmnu_fnc(RMNU_MOVE);
    if u.is_moving or(u.x<>u.xt)or(u.y<>u.yt)then add_rmnu_fnc(RMNU_STOP_MOVE);
    if isa(g,u,a_cleaner) and u.isclrg then add_rmnu_fnc(RMNU_STOP_BUILD);
    if((u.isact)and(isa(g,u,a_building))and(not isa(g,u,a_always_active)))or((u.isbuild)and(not isa(g,u,a_building)))then add_rmnu_fnc(RMNU_STOP_BUILD);
    if (not u.isact)and(not isa(g,u,a_always_active))and(isa(g,u,a_building))and(not ud.canbuild) then add_rmnu_fnc(RMNU_START);
    if (not u.isact)and(not isa(g,u,a_always_active))and(isa(g,u,a_building))and(ud.canbuild)and(not u.isbuildfin)and(u.builds_cnt<>0) then add_rmnu_fnc(RMNU_START);
    if is_have_something_to_transfer(g,u) then add_rmnu_fnc(RMNU_XFER);
    if is_have_material_to_transfer(g,u) then add_rmnu_fnc(RMNU_GIVE_2);
    if isa(g,u,a_cleaner) and cell_attrib(g,u.x,u.y,CA_RUBBLE) and(not u.isclrg)then add_rmnu_fnc(RMNU_DOZE);
    if isa(g,u,a_bomb_placer) and(u.prod.now[RES_MAT]>0) then add_rmnu_fnc(RMNU_PUT_MINES);
    if isa(g,u,a_bomb_placer) and(u.prod.now[RES_MAT]<u.prod.num[RES_MAT]) then add_rmnu_fnc(RMNU_GET_MINES);
    if isa(g,u,a_building)and(u.bas.attk<>0)then add_rmnu_fnc(RMNU_SENTRY);
    if (not isa(g,u,a_building))and u.isstd then add_rmnu_fnc(RMNU_DONE);
    if isa(g,u,a_building)and isa(g,u,a_road) then add_rmnu_fnc(RMNU_DONE);
    if isa(g,u,a_building)and not isa(g,u,a_road) then add_rmnu_fnc(RMNU_BLOW);
    if isa(g,u,a_building)and isa(g,u,a_upgradable)then begin add_rmnu_fnc(RMNU_UPDATE);add_rmnu_note('('+stri(u.bas.cost div 4)+')');end;
    if isa(g,u,a_building)and isa(g,u,a_upgradable)then begin
     cost:=0;
     for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
      u2:=get_unit(g,j);
      if u2.own<>u.own then continue;
      if u2.typ<>u.typ then continue;
      if not isa(g,u2,a_upgradable) then continue;
      if u2.bas.cost>=4 then cost:=cost+u2.bas.cost;
     end;      
     cost:=cost div 4;
     add_rmnu_fnc(RMNU_UPDATEALL);
     add_rmnu_note('('+stri(cost)+')');
    end;
   end;
  end;
  if r_menu.cnt=0 then add_rmnu_fnc(RMNU_DONE);
 end;  
end;     
//############################################################################//
//############################################################################//
//do repeat-click menu action
procedure do_rmnu(g:pgametyp;pos:integer;no_action:boolean);
var j:integer;
u,ut:ptypunits;
ud:ptypunitsdb;   
mods:pmods_rec;
begin      
 u:=get_sel_unit(g);
 if not unav(u) then exit;  
 mods:=get_mods(g);
 ud:=get_unitsdb(g,u.dbn); 
 if (pos<=0) or (pos>length(r_menu.fnc)) then exit;
 
 case r_menu.fnc[pos-1].func of
  RMNU_BUILD:if ud.canbuild then begin
   if not no_action then if isa(g,u,a_building) and u.isact then act_stop_action(g,u,false);
   set_game_menu(g,MG_BUILD);
   exit;
  end;
  RMNU_RESEARCH:set_game_menu(g,MG_UPGRLAB);
  RMNU_ALLOCATE:set_game_menu(g,MG_MINE);   
  RMNU_ACTIVATE:set_game_menu(g,MG_DEPOT);
 end;
          
 if not no_action then case r_menu.fnc[pos-1].func of
  RMNU_STOP_BUILD:act_stop_action(g,u,false);
  RMNU_STOP_MOVE: act_stop_motion(g,u);
  RMNU_START:     if isa(g,u,a_building) then begin if(ud.canbuildtyp<>0)and(u.builds_cnt<>0)then begin act_set_build(g,u,0);end else begin act_startunit(g,u);end;end;
  RMNU_UPDATE:    act_toolunit(g,tool_upgrade,u,u);
  RMNU_UPDATEALL: for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
   ut:=get_unit(g,j);
   if ut.own<>u.own then continue;
   if ut.typ<>u.typ then continue;
   if not isa(g,ut,a_upgradable) then continue;
   act_toolunit(g,tool_upgrade,ut,ut);
  end;
  RMNU_SENTRY:   u.is_sentry:=not u.is_sentry;
  RMNU_BLOW:     set_game_menu(g,MG_BOOM);
  RMNU_UPGRADES: set_game_menu(g,MG_UPGRMONEY);
  RMNU_ENTER:    mods.enter_command:=not mods.enter_command;
  RMNU_MOVE:     mods.move_command:=not mods.move_command;
  RMNU_LOAD:     mods.fetch_command:=not mods.fetch_command;
  RMNU_XFER:     mods.xfer:=not mods.xfer;
  RMNU_REFUEL:   mods.refuel:=not mods.refuel;
  RMNU_ATTACK:   mods.attack_command:=not mods.attack_command;
  RMNU_RELOAD:   mods.reload:=not mods.reload;
  RMNU_GIVE_2:   mods.give_two:=not mods.give_two;
  RMNU_REPAIR:   mods.repair:=not mods.repair;
  RMNU_DISABLE:  begin mods.steal_command :=false;mods.disabe_command:=true;end;
  RMNU_STEAL:    begin mods.disabe_command:=false;mods.steal_command :=true;end;
  RMNU_PUT_MINES:act_unit_mining(g,u);
  RMNU_GET_MINES:act_unit_unmining(g,u);
  RMNU_DONE:     act_unit_done(g,u);
  RMNU_DOZE:     act_unit_doze(g,u);
 end;
end;
//############################################################################//
//Check the active modes, disable if not applicable any more
procedure check_unit_mods(g:pgametyp;no_action:boolean);
var mods:pmods_rec;
su:ptypunits;
begin
 su:=get_sel_unit(g);
 if not unav(su) then exit;
 mods:=get_mods(g);

 mods.build_exit:=su.isbuildfin and cur_plr_unit(g,su);
 if su.cur.shoot=0 then mods.attack_command:=false;

 //Tools
 if mods.reload then if su.prod.now[RES_MAT ]<=0 then mods.reload:=false;
 if mods.give_two then if get_rescount(g,su,RES_MAT,GROP_NOW)<=1 then mods.give_two:=false;
 if mods.refuel then if su.prod.now[RES_FUEL]<=0 then mods.refuel:=false;
 if mods.repair then if su.prod.now[RES_MAT ]<=0 then mods.repair:=false;

 //Update the menu, in case something changed
 calc_rmnu(g,su,no_action);
end;
//############################################################################//  
begin
end.
//############################################################################//  
