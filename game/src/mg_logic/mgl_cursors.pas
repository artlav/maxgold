//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//Cursor calcs
//############################################################################//
unit mgl_cursors;
interface
uses mgrecs,mgl_common,mgl_attr,mgl_res,mgl_tests,mgl_build,mgl_rmnu;
//############################################################################//
procedure curs_calc(g:pgametyp;xns,yns:integer;sshift:boolean);
function get_active_tool(g:pgametyp):integer;
//############################################################################//
implementation
//############################################################################//
function get_active_tool(g:pgametyp):integer;
var mods:pmods_rec;
begin
 mods:=get_mods(g);
 result:=tool_none;
 if mods.refuel then result:=tool_refuel;
 if mods.repair then result:=tool_repair;
 if mods.reload then result:=tool_reload;
 if mods.give_two then result:=tool_xfer2;
end;
//############################################################################//
function any_tool_mods(mods:pmods_rec):boolean;
begin
 result:=true;
 if mods.move_command or mods.fetch_command or mods.enter_command or mods.xfer or mods.build_rect then exit;
 if mods.refuel or mods.repair or mods.reload or mods.give_two then exit;
 result:=false;
end;
//############################################################################//
function eval_attack(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
var tu:ptypunits;
ud:ptypunitsdb;
vis:boolean;
i:integer;
begin
 result:=false;
 if any_tool_mods(mods) then exit;

 if su=nil then exit;
 ud:=get_unitsdb(g,su.dbn);
 if su.disabled_for<>0 then exit;
 if(su.cur.shoot=0)or(su.cur.ammo=0) then exit;

 //Visibility
 if cell_attrib(g,xns,yns,CA_ANY_UNIT) then vis:=can_see(g,xns,yns,su.own,get_unu(g,xns,yns,0))
                                       else vis:=can_see(g,xns,yns,su.own,nil);

 //Ordered attack
 if mods.attack_command then begin
  if (sqr(su.x-xns)+sqr(su.y-yns)<=sqr(su.bas.range))and(not((su.x=xns)and(su.y=yns))) then result:=true;
  if ud.fire_type=FT_WATER_COAST then if(get_map_pass(g,xns,yns)<>P_WATER)and(get_map_pass(g,xns,yns)<>P_COAST) then result:=false;
  if cell_attrib(g,xns,yns,CA_ANY_UNIT) and(not cell_attrib(g,xns,yns,CA_RUBBLE)) and vis then begin
   if not cursor_fire_possible(g,su,get_unu(g,xns,yns,0)) then result:=false;
   if not fire_possible(g,su,get_unu(g,xns,yns,0)) then result:=false;
  end;
 end;

 //Apply action to an enemy
 if cell_attrib(g,xns,yns,CA_ENEMY_UNIT)and cur_plr_unit(g,su) and vis then begin
  for i:=0 to get_unu_length(g,xns,yns)-1 do if fire_possible(g,su,get_unu(g,xns,yns,i))and are_enemies(g,su,get_unu(g,xns,yns,i)) then begin
   tu:=get_unu(g,xns,yns,i);
   if(not isa(g,su,a_building))or(sqr(su.x-xns)+sqr(su.y-yns)<=sqr(su.bas.range))then begin
    //Attack
    result:=true;

    //Infiltrator, not ordered to fire
    if isa(g,su,a_infiltrator)and(not mods.attack_command)then begin
     if (not(mods.steal_default))and(not(mods.steal_command)) then begin
      if inrau(g,xns,yns,su)and(isa(g,tu,a_disableable))and(not isa(g,tu,a_disabled)) then result:=false;
     end;
    end;

    //Stealthed - don't attack
    if isa(g,su,a_stealthed)and(not mods.attack_command)then result:=false;

    if isa(g,tu,a_unselectable)and(not mods.attack_command) then result:=false;
    if result then break;
   end;
  end;
 end;

 //Don't fire on planes if not zenit  //FIXME: Classes of weapons needed
 if not mods.attack_command then if test_pass(g,xns,yns,su)and((((su.ptyp<>pt_air)and (not cell_attrib(g,xns,yns,CA_PLANE))))or(test_plane_casual_pass(g,xns,yns)))and(not isa(g,su,a_building)) then begin
  if not(cell_attrib(g,xns,yns,CA_PLANE)and(ud.fire_type=FT_AIR))then result:=false;
 end;
end;
//############################################################################//
function eval_select(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
var vis:boolean;
begin
 result:=false;
 if any_tool_mods(mods) then exit;

 if su=nil then begin result:=true;exit;end;

 //Visibility
 if cell_attrib(g,xns,yns,CA_ANY_UNIT) then vis:=can_see(g,xns,yns,su.own,get_unu(g,xns,yns,0))
                                       else vis:=can_see(g,xns,yns,su.own,nil);

 //If there is anything we can see
 if cell_attrib(g,xns,yns,CA_ANY_UNIT)and vis then begin
  result:=true;
  if isa(g,get_unu(g,xns,yns,0),a_unselectable) then result:=false;
  if cell_attrib(g,xns,yns,CA_ENEMY_UNIT)and cur_plr_unit(g,su) and vis then result:=false;
 end;
end;
//############################################################################//
function eval_unstore(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
begin
 result:=false;
 if su=nil then exit;
 if mods.store_exit then result:=unstore_test_pass(g,xns,yns,get_unit(g,mods.exit_storage_unit));
end;
//############################################################################//
function eval_bldexit(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
begin
 result:=false;
 if su=nil then exit;

 if mods.build_exit and inrau(g,xns,yns,su) then begin
  if isa(g,su,a_building) then begin
   if test_pass_db(g,xns,yns,getdbnum(g,su.builds[0].typ),nil) then result:=true;
  end else begin
   if test_pass(g,xns,yns,su) then result:=true;
  end;
 end;
end;
//############################################################################//
function eval_tools(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
var i,tool:integer;
begin
 result:=false;
 if su=nil then exit;

 //Enter, grab, transfer
 if inrm(g,xns,yns) and(get_unu_length(g,xns,yns)>0)then begin
  if mods.fetch_command then for i:=0 to get_unu_length(g,xns,yns)-1 do if storable  (g,su,get_unu(g,xns,yns,i)) then begin result:=true;break;end;
  if mods.enter_command then for i:=0 to get_unu_length(g,xns,yns)-1 do if storable  (g,get_unu(g,xns,yns,i),su) then begin result:=true;break;end;
  if mods.xfer          then for i:=0 to get_unu_length(g,xns,yns)-1 do if are_linked(g,su,get_unu(g,xns,yns,i)) and is_something_to_transfer(g,su,get_unu(g,xns,yns,i)) then begin result:=true;break;end;
 end;

 //refuel/repair/reload
 if (mods.refuel or mods.repair or mods.reload or mods.give_two)and cell_attrib(g,xns,yns,CA_ANY_UNIT) then begin
  tool:=get_active_tool(g);
  for i:=0 to get_unu_length(g,xns,yns)-1 do if unav(get_unu(g,xns,yns,i)) then if is_toolapplicable(g,su,get_unu(g,xns,yns,i),tool)and are_linked(g,su,get_unu(g,xns,yns,i)) then begin
   result:=true;
   break;
  end;
 end;

 //Constructor positioning
 if mods.build_rect then begin
  result:=true;
  mods.not_available:=true;
  if not can_build_rect_here(g,su,xns,yns,builds_menu.what) then exit;
  mods.not_available:=false;
 end;
end;
//############################################################################//
function eval_move(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
var vis:boolean;
begin
 result:=false;
 if su=nil then exit;

 if isa(g,su,a_building) then exit;                      //Buildings don't move
 if not cur_plr_unit(g,su) then exit;                    //Enemy can't be moved
 if su.isbuild and(not isa(g,su,a_building)) then exit;  //Constructors at work can't move

 //Visibility
 if cell_attrib(g,xns,yns,CA_ANY_UNIT) then vis:=can_see(g,xns,yns,su.own,get_unu(g,xns,yns,0))
                                       else vis:=can_see(g,xns,yns,su.own,nil);

 //If not ordered, don't walk over
 if not mods.move_command then if((su.ptyp=pt_air)and((not test_plane_casual_pass(g,xns,yns))and vis))or((su.ptyp<pt_air)and(not terrain_test_pas(g,xns,yns,su))) then exit;

 //Cell is passable
 if test_pass(g,xns,yns,su) then result:=true;

 //If cannot see, walk there
 if((su.ptyp=pt_air)and(not vis))or((su.ptyp<pt_air)and terrain_test_pas(g,xns,yns,su)and(not vis)) then result:=true;
end;
//############################################################################//
function eval_infil(g:pgametyp;su:ptypunits;xns,yns:integer;sshift:boolean;mods:pmods_rec):boolean;
var tu:ptypunits;
vis:boolean;
i:integer;
begin
 result:=false;
 if su=nil then exit;
 if su.cur.shoot=0 then exit;
 if not isa(g,su,a_infiltrator) then exit;
 if mods.attack_command then exit;
 if not cur_plr_unit(g,su) then exit;
 if not inrau(g,xns,yns,su) then begin
  if mods.steal_command or mods.disabe_command then mods.not_available:=true;
  exit;
 end;

 //Visibility
 if cell_attrib(g,xns,yns,CA_ANY_UNIT) then vis:=can_see(g,xns,yns,su.own,get_unu(g,xns,yns,0))
                                     else vis:=can_see(g,xns,yns,su.own,nil);

 //Apply action to an enemy
 if cell_attrib(g,xns,yns,CA_ENEMY_UNIT)and vis then begin
  for i:=0 to get_unu_length(g,xns,yns)-1 do if fire_possible(g,su,get_unu(g,xns,yns,i))and are_enemies(g,su,get_unu(g,xns,yns,i)) then begin
   tu:=get_unu(g,xns,yns,i);
   if isa(g,tu,a_human) then continue;
   if(not isa(g,su,a_building))or(sqr(su.x-xns)+sqr(su.y-yns)<=sqr(su.bas.range))then begin
    result:=true;
    if (not(mods.steal_default))and(not(mods.steal_command)) then if inrau(g,xns,yns,su)and(isa(g,tu,a_disableable))and(not isa(g,tu,a_disabled)) then begin
     mods.disabe_default:=true;
    end;
    if (mods.steal_default)or(mods.steal_command)or((not isa(g,tu,a_building))and isa(g,tu,a_disabled)and isa(g,tu,a_disableable))and(not mods.disabe_command) then begin
     mods.disabe_default:=false;
     mods.disabe_command:=false;
    end;
    if (not isa(g,tu,a_building))and isa(g,tu,a_disabled)and(not mods.disabe_command) then begin
     mods.disabe_default:=false;
     mods.disabe_command:=false;
     mods.steal_default:=true;
    end;
   end;
  end;
 end;

 //Can/can't do ordered action
 if mods.steal_command  and(not mods.steal_default ) then begin result:=false;mods.not_available:=true;end;
 if mods.disabe_command and(not mods.disabe_default) then begin result:=false;mods.not_available:=true;end;
end;
//############################################################################//
//Cursor shape and action capabilities calc
procedure curs_calc(g:pgametyp;xns,yns:integer;sshift:boolean);
var i:integer;
su:ptypunits;
cp:pplrtyp;
mods:pmods_rec;
begin
 mods:=get_mods(g);

 //Area check
 if not inrm(g,xns,yns) then begin mods.not_available:=true;exit;end;
 //Landing check
 cp:=get_cur_plr(g);
 if not is_landed(g,cp) then begin mods.not_available:=not landing_pass_test(g,xns-1,yns-1,xns+1,yns+1,i);exit;end;

 //Selection
 su:=get_sel_unit(g);
 if not unav(su) then su:=nil;

 //Reset
 mods.disabe_default:=false;
 mods.steal_default :=false;
 mods.move_path     :=sshift;
 mods.not_available :=false;
 mods.select_default:=false;
 mods.attack_default:=false;
 mods.move_default  :=false;

 //If no specific orders, check for infiltration, check for attack, check for movtion, check for selectability
 //If any succeed - it is the action, if none succeed - it's no action allowed (navmod)
          if eval_unstore(g,su,xns,yns,sshift,mods) then begin
 end else if eval_bldexit(g,su,xns,yns,sshift,mods) then begin
 end else if eval_tools  (g,su,xns,yns,sshift,mods) then begin
 end else if eval_infil  (g,su,xns,yns,sshift,mods) then begin
 end else if eval_attack (g,su,xns,yns,sshift,mods) then begin
  mods.attack_default:=true;
  mods.not_available :=false;
 end else if eval_move(g,su,xns,yns,sshift,mods) then begin
  mods.move_default :=true;
  mods.not_available:=false;
 end else if eval_select(g,su,xns,yns,sshift,mods) then begin
  mods.select_default:=true;
 end else mods.not_available:=true;
end;
//############################################################################//
begin
end.
//############################################################################//
