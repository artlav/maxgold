//############################################################################//  
unit mgl_mapclick;
interface
uses mgrecs,mgl_common,mgl_attr,mgl_tests,mgl_xfer,mgl_res,mgl_cursors,mgl_rmnu,mgl_buildcalc,mgl_build,mgl_actions,mgl_land;
//############################################################################//    
procedure do_depot_release(g:pgametyp;u:ptypunits);
procedure do_depot_release_all(g:pgametyp;u:ptypunits); 
procedure do_mouse_event(g:pgametyp;xns,yns:integer;btn:byte;no_act:boolean);
//############################################################################//  
implementation      
//############################################################################//
const
//Infiltrator commands
IC_DISABLE=0;
IC_STEAL=1;
//############################################################################//
//Unstore menu action
procedure do_depot_release(g:pgametyp;u:ptypunits);  
var hu:ptypunits; 
air_store,air_unstore:boolean;
mods:pmods_rec;
begin
 if u=nil then exit;
 if not u.stored then exit;
 mods:=get_mods(g);

 hu:=get_unit(g,u.stored_in);
 air_store:=is_air_store(g,hu,u);
 air_unstore:=is_air_unstore(g,hu,u);
 
 //FIXME: use check_air_storage?
 if (g.info.rules.load_onpad_only)and(isa(g,u,a_exit_on_pad))and (not isa(g,u,a_exit_empty) or (u.currently_stored>0)) then if(hu.ptyp=pt_air)and(not air_store)then if hu.alt=0 then air_unstore:=false;

 if air_unstore then begin    
  act_unstore(g,u,hu.x,hu.y);
 end else begin  
  mods.store_exit:=true;
  //Bug 8526
  mods.fetch_command:=false;
  mods.exit_storage_unit:=u.num;
 end;  
end;
//############################################################################//
//Unstore all
procedure do_depot_release_all(g:pgametyp;u:ptypunits); 
var i,x,y:integer;
ui:ptypunits;
mods:pmods_rec;
begin
 if not unav(u) then exit;
 if u.ptyp=pt_air then exit;
 mods:=get_mods(g);

 for i:=0 to get_units_count(g)-1 do begin
  ui:=get_unit(g,i);
  if ui<>nil then if ui.stored and(ui.stored_in=u.num)then begin
   for y:=-1 to u.siz do for x:=-1 to u.siz do act_unstore(g,ui,u.x+x,u.y+y);
  end;
 end;

 mods.fetch_command:=false;
end;     
//############################################################################//
function recall_to_store_cmd(g:pgametyp;xns,yns:integer;su:ptypunits;var umu:aptypunits):boolean;
var i:integer;
tu:ptypunits;
air_store:boolean;
begin
 result:=false;
 for i:=0 to length(umu)-1 do begin
  tu:=umu[i];
  if storable(g,su,tu) then begin  
   air_store:=is_air_store(g,su,tu);
   if(isa(g,su,a_building)or(not air_store))then begin
    if is_units_touching(g,tu,su) then begin
     act_store(g,tu,su);
     result:=true;
    end else begin
     act_move_close(g,tu,su,su.siz);
     result:=true;
    end;
   end else if(not isa(g,su,a_building))and(su.ptyp=pt_air)then begin act_set_move_unit(g,su,xns,yns,false,stsk_load,tu.num);result:=true;end;
  end;
  if result then break;
 end;
end;
//############################################################################//
function enter_cmd(g:pgametyp;xns,yns:integer;u:ptypunits;var umu:aptypunits):boolean;
var i:integer;
ut:ptypunits;     
air_store:boolean;
mods:pmods_rec;
begin
 result:=false;
 mods:=get_mods(g);
 for i:=0 to length(umu)-1 do if umu[i]=get_sel_unit(g) then begin result:=true; exit;end;
 for i:=0 to length(umu)-1 do begin
  ut:=umu[i];
  if ut<>nil then if storable(g,ut,u) then begin                    
   air_store:=is_air_store(g,ut,u);
   if (not air_store) and is_units_touching(g,u,ut)then begin
    act_store(g,u,ut);    
    result:=true;
   end else begin
    if (isa(g,ut,a_building)or(not air_store)) then begin
     act_move_close(g,u,ut,ut.siz);
     result:=true;
    end else begin act_set_move_unit(g,ut,u.x,u.y,false,stsk_load,u.num);result:=true;end;
   end; 
  end;
  if result then break;
 end;
 if result then mods.enter_command:=false;
end;
//############################################################################//
function move_cmd(g:pgametyp;xns,yns:integer;u:ptypunits;var umu:aptypunits):boolean;
begin
 result:=test_pass(g,xns,yns,u);
 if result then act_set_move_unit(g,u,xns,yns);
end;
//############################################################################//
procedure clear_infil_mods(g:pgametyp);
var mods:pmods_rec;
begin
 mods:=get_mods(g);
 mods.steal_command :=false;
 mods.disabe_command:=false;
end;                      
//############################################################################//
function infil_cmd(g:pgametyp;typ,xns,yns:integer;su:ptypunits;var umu:aptypunits):boolean;
var i:integer;
ut:ptypunits;
begin
 result:=false;
 if not unav(su) then begin clear_infil_mods(g);result:=true;exit;end;
 if su.cur.shoot=0 then begin clear_infil_mods(g);result:=true;exit;end;

 for i:=0 to length(umu)-1 do begin
  ut:=umu[i];
  if not unav(ut) then continue;
  if is_units_touching(g,su,ut)and are_enemies(g,su,ut) and((ut.alt=0)or(ut.ptyp<>PT_AIR))then case typ of
   IC_DISABLE:if not isa(g,ut,a_disabled)and isa(g,ut,a_disableable)and(not isa(g,ut,a_stealthed))then begin
    act_toolunit(g,tool_disable,su,ut);
    result:=true;
   end;
   IC_STEAL:if not isa(g,ut,a_building) and isa(g,ut,a_disabled) then begin
    act_toolunit(g,tool_steal,su,ut);
    result:=true;
   end;
  end;
  if result then break;
 end;
 if result then clear_infil_mods(g);
end;
//############################################################################//
function transfer_cmd(g:pgametyp;xns,yns:integer;su:ptypunits;var umu:aptypunits):boolean;
var i:integer;
tu:ptypunits;
mods:pmods_rec;
begin
 result:=false;
 mods:=get_mods(g);
 for i:=0 to length(umu)-1 do if umu[i]=su then begin mods.xfer:=false;result:=true;exit;end;
 for i:=0 to length(umu)-1 do begin
  tu:=umu[i];
  if are_linked(g,su,tu)and is_something_to_transfer(g,su,tu) then begin
   xfer_menu.ua:=su;
   xfer_menu.ub:=tu;
   set_game_menu(g,MG_XFER);
   result:=true;
  end;
  if result then break;
 end;
 if result then mods.xfer:=false;
end;   
//############################################################################//
function build_exit_cmd(g:pgametyp;xns,yns:integer;su:ptypunits):boolean;
begin
 result:=false;
 if su=nil then exit;
 if not su.isbuildfin then exit;
 if not inrau(g,xns,yns,su) then exit;
 if not isa(g,su,a_building) then if not test_pass(g,xns,yns,su)then exit;
 if     isa(g,su,a_building)and(su.builds_cnt<>0)then if not test_pass_db(g,xns,yns,getdbnum(g,su.builds[0].typ),su)then exit;
 
 act_finish_build(g,xns,yns,su);
 result:=true;
end;
//############################################################################//
//For constructor building a 2z2 building
function build_positioning_cmd(g:pgametyp;xns,yns:integer;su:ptypunits):boolean;
begin
 result:=true;
 if not can_build_rect_here(g,su,xns,yns,builds_menu.what) then exit;
 shift_to_inrau_2x2(su.x,su.y,xns,yns);

 act_set_build(g,su,su.reserve);
 act_set_move_unit(g,su,xns,yns,false);
 result:=true;
end;
//############################################################################//
function build_path_cmd(g:pgametyp;xns,yns:integer;su:ptypunits):boolean;
var i:integer;
bx:boolean;   
ud:ptypunitsdb;
mods:pmods_rec;
begin
 result:=true;

 //Reset mode on attempt
 mods:=get_mods(g);
 mods.build_path:=false;

 bx:=true;
 if(xns<>su.x)and(yns<>su.y)then exit;

 ud:=get_unitsdb(g,builds_menu.what);

 if (xns=su.x)and(yns>su.y) then for i:=su.y     to yns do bx:=bx and add_build(g,su,ud.typ,false,builds_menu.reserve,builds_menu.given_speed,xns,i);
 if (xns=su.x)and(yns<su.y) then for i:=su.y downto yns do bx:=bx and add_build(g,su,ud.typ,false,builds_menu.reserve,builds_menu.given_speed,xns,i);
 if (yns=su.y)and(xns>su.x) then for i:=su.x     to xns do bx:=bx and add_build(g,su,ud.typ,false,builds_menu.reserve,builds_menu.given_speed,i,yns);
 if (yns=su.y)and(xns<su.x) then for i:=su.x downto xns do bx:=bx and add_build(g,su,ud.typ,false,builds_menu.reserve,builds_menu.given_speed,i,yns);

 if bx then act_set_build(g,su,0);
end; 
//############################################################################//
function mouse_event_action(g:pgametyp;su:ptypunits;xns,yns:integer;sshift,saux:boolean;var umu:aptypunits):boolean;
label 1;
var i,j,tool:integer;
tu:ptypunits;
cp:pplrtyp;
mods:pmods_rec;
begin
 result:=false;
 
 mods:=get_mods(g);
 if not unav(su) then su:=nil;
 cp:=get_cur_plr(g);

 //Exit storage
 if mods.store_exit then begin act_unstore(g,get_unit(g,mods.exit_storage_unit),xns,yns); mods.store_exit:=false;goto 1;end;
 
 //Selected unit actions
 if su<>nil then begin
  //Actions on other units
  if length(umu)>0 then begin
   if mods.disabe_default or mods.disabe_command then if infil_cmd(g,IC_DISABLE,xns,yns,su,umu) then goto 1;   //Disable
   if mods.steal_default  or mods.steal_command  then if infil_cmd(g,IC_STEAL  ,xns,yns,su,umu) then goto 1;   //Steal
   if mods.enter_command then if enter_cmd          (g,xns,yns,su,umu) then goto 1;                            //Enter storage
   if mods.move_command  then if move_cmd           (g,xns,yns,su,umu) then goto 1;                            //Move to
   if mods.fetch_command then if recall_to_store_cmd(g,xns,yns,su,umu) then goto 1;                            //Ask to go to storage
   if mods.xfer          then if transfer_cmd       (g,xns,yns,su,umu) then goto 1;                            //Transfer
   //Other tools
   if mods.refuel or mods.reload or mods.repair or mods.give_two then begin
    tool:=get_active_tool(g);
    for i:=0 to length(umu)-1 do if unav(umu[i]) then if is_toolapplicable(g,su,umu[i],tool) then begin act_toolunit(g,tool,su,umu[i]);goto 1;end;
   end;
  end;
  
  //Construction tools
  if mods.build_exit then if build_exit_cmd       (g,xns,yns,su) then goto 1;      //Build finish exit
  if mods.build_rect then if build_positioning_cmd(g,xns,yns,su) then goto 1;      //Build rectangle selection
  if mods.build_path then if build_path_cmd       (g,xns,yns,su) then goto 1;      //Build path selection

  //Blind shooting
  if mods.attack_command then begin act_fire_to(g,su,xns,yns,not sshift); goto 1;end;

  //Move units
  if(not mods.attack_default)and isa(g,su,a_can_start_moving)and(su.ptyp<>pt_air)and test_pass(g,xns,yns,su,false,1)and(not cell_attrib(g,xns,yns,CA_PLANE)) then begin act_set_move_unit(g,su,xns,yns,sshift or saux);goto 1;end;

  //Fire
  if (length(umu)>0) and isa(g,su,a_would_fire) and isa(g,su,a_can_fire) then for j:=0 to length(umu)-1 do begin
   tu:=umu[j]; 
   if can_see(g,xns,yns,cp.num,tu)and (isa(g,tu,a_fair_game) or mods.attack_command) and not isa(g,tu,a_unselectable) then begin
    act_fire_at(g,su,tu,xns,yns,not sshift);
    goto 1;
   end;
  end;
  
  //Move planes
  if isa(g,su,a_can_start_moving)and(su.ptyp=pt_air)and test_plane_casual_pass(g,xns,yns) then begin act_set_move_unit(g,su,xns,yns,sshift or saux);goto 1;end;
 end;

 exit;
 1:
 result:=true;  
end;    
//############################################################################//
procedure mouse_event_right(g:pgametyp;su:ptypunits;xns,yns:integer;var umu:aptypunits);
var i:integer;
s:ptypunits;
cp:pplrtyp;
mods:pmods_rec;
begin
 cp:=get_cur_plr(g);
 mods:=get_mods(g); 
 if mods.enter_command  then begin mods.enter_command:=false;exit;end;
 if mods.fetch_command  then begin mods.fetch_command:=false;exit;end;
 if mods.store_exit     then begin mods.store_exit:=false;exit;end;
 if mods.xfer           then begin mods.xfer:=false;exit;end;
 if mods.attack_command then begin mods.attack_command:=false;mods.attack_default:=false;mods.not_available:=false;exit;end;
 if mods.refuel         then begin mods.refuel:=false;exit;end;
 if mods.reload         then begin mods.reload:=false;exit;end;
 if mods.give_two       then begin mods.give_two:=false;exit;end;
 if mods.repair         then begin mods.repair:=false;exit;end;
 if mods.build_rect     then begin mods.build_rect:=false;builds_menu.reserve:=0;exit;end;
 if mods.build_path     then begin mods.build_path:=false;builds_menu.reserve:=0;exit;end;
 if mods.disabe_command then begin mods.disabe_command:=false;exit;end;
 if mods.steal_command  then begin mods.steal_command :=false;exit;end;
 if mods.move_command   then begin mods.move_command:=false;exit;end;

 if length(umu)>0 then begin
  //Display Unit info if right mouse pressed on selected unit
  if su<>nil then for i:=0 to length(umu)-1 do if(umu[i]=su)and can_see(g,xns,yns,cp.num,su) then begin set_game_menu(g,MG_UNITINFO);exit;end;
  //Select another unit by right mouse
  for i:=0 to length(umu)-1 do begin
   s:=umu[i];
   if can_see(g,xns,yns,cp.num,s)then begin
    blank_modes(g);
    select_unit(g,s.num,true);
    exit;
   end;
  end;
 end;   
end;     
//############################################################################//
procedure mouse_event_select(g:pgametyp;su:ptypunits;xns,yns:integer;sshift,sctrl:boolean;var umu:aptypunits);
var i,j:integer;
cp:pplrtyp;
tu:ptypunits;
mods:pmods_rec;
begin
 if not unav(su) then su:=nil;
 cp:=get_cur_plr(g);
 mods:=get_mods(g);

 //Double click on the unit already selected:
 //Cycle through units if there is more than one, disable exit/enter modes if active
 for i:=0 to length(umu)-1 do if su<>nil then if umu[i]=su then begin
  j:=i;
  while j<length(umu) do begin
   if j<length(umu)-1 then tu:=umu[j+1] else tu:=umu[0];
   j:=j+1;
   if can_see(g,xns,yns,cp.num,tu) then begin
    blank_modes(g);
    select_unit(g,tu.num,true);
    break;
   end;
  end;
  mods.build_exit:=false;
  mods.store_exit:=false;
  mods.attack_command:=false;
  exit;
 end;

 //If clicked on an unselected unit, select it
 if not sshift then for i:=0 to length(umu)-1 do begin
  tu:=umu[i];
  if cur_plr_unit(g,tu) or can_see(g,xns,yns,cp.num,tu) then begin
   blank_modes(g);
   select_unit(g,tu.num,true);
   mods.attack_command:=false;
   exit;
  end;
 end;
end;
//############################################################################//
procedure do_mouse_event(g:pgametyp;xns,yns:integer;btn:byte;no_act:boolean);
var prleft,prright,sshift,sctrl,saux:boolean;
umu:aptypunits;
su:ptypunits;
begin
 if not inrm(g,xns,yns) then exit;
 su:=get_sel_unit(g);
 if not unav(su) then su:=nil;

 prleft:=btn and 1<>0;
 prright:=btn and 2<>0;
 sshift:=btn and 4<>0;
 sctrl:=btn and 16<>0;  
 saux:=btn and 32<>0;  

 if prleft then begin msgu.p:=false;msgu.txt:='';end;

 //Landing
 if do_landing(g,xns,yns,btn) then exit;

 //Units there
 enum_units_in_cell(g,xns,yns,umu);

 //If ctrl-clicked on an empty space, unselect units
 if sctrl then if length(umu)=0 then begin select_unit(g,-1,false);exit;end;

 //Utils
 if prright then begin mouse_event_right(g,su,xns,yns,umu);exit;end;

 //Actions
 if not no_act then if prleft and(not sctrl)then if mouse_event_action(g,su,xns,yns,sshift,saux,umu) then exit;

 //Selection
 if prleft and(length(umu)>0)then mouse_event_select(g,su,xns,yns,sshift,sctrl,umu); 
end;
//############################################################################//  
begin
end.
//############################################################################//  
