//############################################################################//  
unit mgl_attr;
interface
uses maths,strval,mgrecs,mgl_common;           
//############################################################################//
//Features
const
a_building       =0;            //Is immovable, a building
a_bld_on_plate   =1;            //Building that needs a concrete plate below it
a_always_active  =2;            //Cannot be turned off
a_half_selectable=3;            //Low priority in selection (roads, platforms, etc)
a_unselectable   =4;            //Can never be selected, decorations
a_stealth        =5;            //Stealth unit
a_see_stealth    =6;            //Can see stealth units
a_mining         =7;            //Mines resources
a_human          =8;
a_connector      =9;            
a_can_build_on   =10;
a_bridge         =11;           //Bridge. Allows walking over water and swimming under itself, but can't be built on
a_road           =12;           //Road. Speeds unit motion by a factor of 2
a_passes_res     =13;           //Permeable to resources
a_cleaner        =14;           //Bulldozer, removes debris
a_repair         =15;           //Can repair units
a_infiltrator    =16;
a_bomb           =17;           //A land/sea mine
a_bomb_placer    =18;           //Thing that places mines
a_self_repair    =19;           //Fixes itself over time
a_ecosphere      =20;           //Produces score?
a_reloader       =21;           //Can reload units
a_research       =22;           //Can do research
a_landing_pad    =23;           //Planes can land on that
a_surveyor       =24;           //Sees geology
a_disableable    =25;           //Can be disabled by an infiltrator
a_upgrader       =26;           
a_begin_buyable  =27;           //Can be bought at landing time
//a_animation      =28;         //Used to mean utility unit that is just an animation  
a_underwater     =29;           //Submarine
a_see_underwater =30;           //Can see submarines
a_see_mines      =31;           //Can see mines

//Features2, offset +32
a_exit_on_pad    =32;
a_exit_empty     =33;
a_direct_buyable =34;
  
//Combined attributes
a_effectively_bridge =1000;
a_solid_building     =1001;
a_fair_game          =1002;
a_ours               =1003;
a_our_builder_working=1004;
a_overbuild_disabled =1005;

a_minor              =1007;
a_positive_fuel      =1008;

a_would_autofire     =1010;
a_was_detected       =1011;
a_survives_overblast =1012;
a_bor                =1013;
a_leaves_decay       =1014;     //Leaves debris on destruction
a_can_fire           =1015;
a_landed             =1016;     //Sitting on a pad
a_disabled           =1017;     //Disabled by an infil
a_sentry_or_not_bomb =1018;
a_stealth_or_underw  =1019;
a_exclude_from_report=1020;
a_stealthed          =1021;
a_build_not_building =1022;
a_upgradable         =1023;
a_run_on_completion  =1024;
a_can_start_moving   =1025;
a_would_fire         =1026;
a_no_overblast       =1027;     
a_resource_domainable=1028;     //A unit that should be added into a resource domain. Does not equal to ability to pass resources. 
//############################################################################//
//Cell attributes
CA_ANY_UNIT  =1;
CA_ENEMY_UNIT=2;
CA_PLANE     =3;
CA_SMALLPLAT =4;
CA_BOMB      =5;
CA_BRIDGE    =6;
CA_ROAD      =7;
CA_RUBBLE    =8;
CA_BIGPLAT   =9;    
//############################################################################//
//Fire type
FT_NONE            =0;
FT_LAND_WATER_COAST=1;
FT_WATER_COAST     =2;
FT_AIR             =3;
FT_ALL             =4; 
//############################################################################//
//Pass map
P_LAND    =0;
P_WATER   =1;
P_COAST   =2;
P_OBSTACLE=3;     
//############################################################################//
//Unit pass type
pt_landonly  =0;
pt_landcoast =1;
pt_landwater =2;
pt_watercoast=3;
pt_wateronly =4;
pt_air       =5;
//############################################################################//
//Weapons
WT_NONE       =0;
WT_GUN        =1;
WT_CASSETTE   =2;
WT_ROCKET     =3;
WT_AA         =4;
WT_TORPEDO    =5;
WT_ALIEN      =6;
WT_INFILTRATOR=7;
WT_BOMB       =8;
//############################################################################//  
function stealthvis(g:pgametyp;x,y,p:integer;u:ptypunits):boolean;
function stealthdet(g:pgametyp;x,y,p:integer;u:ptypunits):boolean;  
function fast_can_see(g:pgametyp;x,y,p:integer):boolean;      
function can_see(g:pgametyp;x,y,p:integer;u:ptypunits):boolean;

function plr_are_enemies(g:pgametyp;a,b:integer):boolean;
function are_enemies(g:pgametyp;ua,ub:ptypunits):boolean;   

function are_linked(g:pgametyp;ua,ub:ptypunits;recurse:boolean=false):boolean;
function mine_fine(g:pgametyp;u:ptypunits):boolean;
function is_units_touching(g:pgametyp;u,ut:ptypunits):boolean;

procedure shift_to_inrau_2x2(x,y:integer;var xns,yns:integer);
function inrau(g:pgametyp;x,y:integer;u:ptypunits;unit_pos_allowed:boolean=false):boolean;
function isadb(g:pgametyp;u:ptypunitsdb;attr:integer):boolean;
function isa(g:pgametyp;u:ptypunits;attr:integer):boolean;
function cell_attrib(g:pgametyp;x,y,what:integer):boolean;   
 
procedure enum_units_in_cell(g:pgametyp;x,y:integer;out umu:aptypunits);
    
procedure select_unit(g:pgametyp;new:integer;msg:boolean);
procedure select_nothing(g:pgametyp;cp:pplrtyp);   
procedure change_selection(g:pgametyp;cur,n:ptypunits);

function is_ammo_red(u:ptypunits):boolean;
function is_ammo_yellow(u:ptypunits):boolean;
function is_hits_red(u:ptypunits):boolean;
function is_hits_yellow(u:ptypunits):boolean;
function is_ammo_low(u:ptypunits):boolean;
function is_hits_low(u:ptypunits):boolean;
//############################################################################//  
implementation    
//############################################################################//
function stealthvis(g:pgametyp;x,y,p:integer;u:ptypunits):boolean;
var pl:pplrtyp;
begin
 result:=true;
 if u=nil then exit;
 if u.own=p then exit;
 pl:=get_plr(g,p);
 if isa(g,u,a_underwater) then if get_map_pass(g,x,y)=P_WATER then if(pl.scan_map[SL_UNDERWATER][x+y*get_map_x(g)]<=0)and(u.stealth_detected[p]=0)then result:=false;
 if isa(g,u,a_stealth)    then if(pl.scan_map[SL_STEALTH][x+y*get_map_x(g)]<=0)and(u.stealth_detected[p]=0)then result:=false;
 if isa(g,u,a_bomb)       then if(u.stealth_detected[p]=0)then result:=false;
end;
//############################################################################//
function stealthdet(g:pgametyp;x,y,p:integer;u:ptypunits):boolean;      
var pl:pplrtyp;
begin
 result:=true;
 if u=nil then exit;
 if u.own=p then exit;   
 pl:=get_plr(g,p);
 if isa(g,u,a_underwater) then if get_map_pass(g,x,y)=P_WATER then if(pl.scan_map[SL_UNDERWATER][x+y*get_map_x(g)]<=0)then result:=false;
 if isa(g,u,a_stealth)    then if(pl.scan_map[SL_STEALTH][x+y*get_map_x(g)]<=0)then result:=false;
end; 
//############################################################################//
function fast_can_see(g:pgametyp;x,y,p:integer):boolean;
var i,vc,m:integer;
pl:pplrtyp;
begin
 result:=false;
 if p=-1 then exit;
 vc:=0;
 for i:=0 to get_plr_count(g)-1 do begin
  pl:=get_plr(g,i);
  if not plr_are_enemies(g,i,p) then for m:=0 to SL_COUNT-1 do vc:=vc+pl.scan_map[m][x+y*get_map_x(g)];
 end;
 result:=vc>0;
end; 
//############################################################################//
function can_see(g:pgametyp;x,y,p:integer;u:ptypunits):boolean;
var i,vc,m:integer;
pl:pplrtyp;
begin
 result:=false;
 if p=-1 then exit;
 if not inrm(g,x,y)then exit;
 vc:=0;
 for i:=0 to get_plr_count(g)-1 do begin
  pl:=get_plr(g,i);
  if not plr_are_enemies(g,i,p) then for m:=0 to SL_COUNT-1 do vc:=vc+pl.scan_map[m][x+y*get_map_x(g)];
 end;
 result:=vc>0;
 if result then result:=stealthvis(g,x,y,p,u);
end; 
//############################################################################//
function plr_are_enemies(g:pgametyp;a,b:integer):boolean;
var pa,pb:pplrtyp;
begin
 pa:=get_plr(g,a);
 pb:=get_plr(g,b);
 result:=pa<>pb;
 if result then result:=not (pa.allies[b] and pb.allies[a]);
 //For alliances, truses, etc.
end; 
//############################################################################//   
//Are the units enemies?
function are_enemies(g:pgametyp;ua,ub:ptypunits):boolean;
begin
 result:=false;
 if not unav(ua) then exit;
 if not unav(ub) then exit;
 result:=plr_are_enemies(g,ua.own,ub.own);
end;
//############################################################################//
//Return upper-left corner, i.e. for constructor's rect
procedure shift_to_inrau_2x2(x,y:integer;var xns,yns:integer);
begin
 if xns<x-1 then xns:=x-1;
 if yns<y-1 then yns:=y-1;
 if xns>x then xns:=x;
 if yns>y then yns:=y;
end;
//############################################################################//
//Around of unit n
function inrau(g:pgametyp;x,y:integer;u:ptypunits;unit_pos_allowed:boolean=false):boolean;
var size:integer;
begin
 size:=max2i(u.siz,u.cur_siz);
 result:=inrect(x,y,u.x-1,u.y-1,u.x+size,u.y+size)and(unit_pos_allowed or not inrect(x,y,u.x,u.y,u.x+size-1,u.y+size-1));
end;                
//############################################################################//
//Check if linked
function are_linked(g:pgametyp;ua,ub:ptypunits;recurse:boolean=false):boolean;
var i,dom:integer;
b,u,ui:ptypunits;
begin
 result:=false;
 if not(unav(ua)and unav(ub))then exit;
 if are_enemies(g,ua,ub) then exit;
 
 if isa(g,ua,a_building) and isa(g,ub,a_building) then begin
  if ua=ub then result:=true
           else result:=(ua.domain=ub.domain)and(ua.domain<>-1);
 end else begin
  result:=inrau(g,ua.x,ua.y,ub)or inrau(g,ub.x,ub.y,ua)or(ub=ua);

  //Parse domain for a link to the unit
  if not result then if(isa(g,ua,a_building) or isa(g,ub,a_building))and(not recurse)then begin
   if isa(g,ua,a_building) then begin b:=ua;u:=ub;end else begin b:=ub;u:=ua;end;
   dom:=b.domain;
   for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
    ui:=get_unit(g,i);
    if ui.domain=dom then begin
     if are_linked(g,ui,u,true) then begin result:=true;exit;end;
    end;
   end;
  end;
 end;
end;   
//############################################################################//
function mine_fine(g:pgametyp;u:ptypunits):boolean;
begin
 result:=u<>nil;
 if result then result:=cur_plr_unit(g,u);
end;
//############################################################################//  
//Are the units standing next to each other?
function is_units_touching(g:pgametyp;u,ut:ptypunits):boolean;
begin      
 result:=false;
 if not unav(u) then exit;
 result:=inrau(g,u.x,u.y,ut,u.ptyp=5);
end;
//############################################################################//
function  isadb(g:pgametyp;u:ptypunitsdb;attr:integer):boolean;
begin
 result:=false;   
 if u=nil then exit;
 if attr<64 then begin
  if attr<32 then result:=(u.flags  and (1 shl attr))<>0
             else result:=(u.flags2 and (1 shl (attr-32)))<>0;
 end else case attr of
  a_effectively_bridge :result:=(isadb(g,u,a_can_build_on) and (not isadb(g,u,a_connector))) or isadb(g,u,a_bridge);
  a_overbuild_disabled :result:=isadb(g,u,a_half_selectable)and(not isadb(g,u,a_bridge))and(not isadb(g,u,a_connector));
  a_minor              :result:=isadb(g,u,a_half_selectable)or isadb(g,u,a_unselectable);
  a_survives_overblast :result:=isadb(g,u,a_bomb)or(u.ptyp=pt_air)or isadb(g,u,a_connector)or isadb(g,u,a_human)or(u.typ='bigrubble')or(u.typ='smlrubble');
  a_no_overblast       :result:=isadb(g,u,a_bomb)or(u.ptyp=pt_air)or isadb(g,u,a_connector)or isadb(g,u,a_human)or(u.typ='bigrubble')or(u.typ='smlrubble')or(u.typ='bridge');
  a_leaves_decay       :result:=not(isadb(g,u,a_bomb)or isadb(g,u,a_human)or(u.ptyp=pt_air)or isadb(g,u,a_connector));
  a_run_on_completion  :result:=isadb(g,u,a_mining)or isadb(g,u,a_ecosphere)or isadb(g,u,a_research)or isadb(g,u,a_upgrader);
  a_resource_domainable:result:=isadb(g,u,a_building) and not isadb(g,u,a_unselectable) and not isadb(g,u,a_half_selectable);
 end;
end;       
//############################################################################//
function  isa(g:pgametyp;u:ptypunits;attr:integer):boolean;
var i:integer;
cp:pplrtyp;    
rul:prulestyp;
ud:ptypunitsdb;
begin 
 cp:=get_cur_plr(g);
 rul:=get_rules(g);
 ud:=get_unitsdb(g,u.dbn);
 case attr of
  a_ours:result:=cur_plr_unit(g,u);
  a_our_builder_working:result:=u.isbuild and isa(g,u,a_ours)and(u.isact or(not isa(g,u,a_building)));
  a_fair_game          :result:=plr_are_enemies(g,u.own,cp.num) and not isa(g,u,a_ours) and not isa(g,u,a_half_selectable); 
  a_unselectable       :result:=u.is_unselectable;     
  a_solid_building     :result:=isa(g,u,a_building)and(not isa(g,u,a_connector))and(not isa(g,u,a_road))and(not isa(g,u,a_bridge))and(not isa(g,u,a_can_build_on))and(not isa(g,u,a_unselectable));
  a_was_detected       :begin
   result:=false;
   for i:=0 to get_plr_count(g)-1 do if i<>u.own then result:=result or(u.stealth_detected[i]<>0);
  end;
  a_would_autofire     :result:=(u.is_sentry or(not isa(g,u,a_building)))and(not isa(g,u,a_stealthed));
  a_would_fire         :result:=(not isa(g,u,a_disabled))and(not isa(g,u,a_stealthed))and isa(g,u,a_ours)and(not u.is_moving_now);
  a_positive_fuel      :result:=((u.cur.fuel>0)and(u.bas.fuel>0))or(u.bas.fuel=0)or(isa(g,u,a_building))or(not rul.fueluse);
  a_can_fire           :result:=(ud.fire_type<>FT_NONE)and(u.cur.shoot>0)and(u.cur.ammo>0)and isa(g,u,a_positive_fuel)and not isa(g,u,a_disabled);
  a_bor                :result:=isa(g,u,a_build_not_building)and(u.cur_siz=2);
  a_build_not_building :result:=(not isa(g,u,a_building))and(u.isbuild or u.isbuildfin);
  a_landed             :result:=u.alt=0;
  a_disabled           :result:=u.disabled_for>0;
  a_stealthed          :result:=(not isa(g,u,a_was_detected))and isa(g,u,a_stealth_or_underw);   
  a_sentry_or_not_bomb :result:=u.is_sentry or(not isa(g,u,a_bomb));
  a_stealth_or_underw  :result:=isa(g,u,a_stealth) or(isa(g,u,a_underwater) and (get_map_pass(g,u.x,u.y)=P_WATER));
  a_exclude_from_report:result:=isa(g,u,a_unselectable)or isa(g,u,a_bomb);
  a_upgradable         :result:=cur_plr_unit(g,u) and(u.mk<>cp.unupd[u.dbn].mk);
  a_can_start_moving   :result:=isa(g,u,a_ours)and(not u.is_moving_now)and(not u.isbuildfin)and(not isa(g,u,a_building))and(not u.isbuild)and(not isa(g,u,a_disabled))and(not u.isclrg)and(u.bas.speed>0);
  else result:=isadb(g,ud,attr);
 end;
end;    
//############################################################################//
//Test for stuff at x,y
function cell_attrib(g:pgametyp;x,y,what:integer):boolean;
var i,xo,yo:integer;
u:ptypunits;
cp:pplrtyp;
begin 
 result:=false;
 if not inrm(g,x,y) then exit;   
 if what<>CA_BIGPLAT then begin
  if get_unu_length(g,x,y)=0 then exit;
  u:=get_unu(g,x,y,0);
 end else u:=nil;
 
 cp:=get_cur_plr(g);
 case what of
  CA_ANY_UNIT  :result:=unav(u);
  CA_ENEMY_UNIT:if unav(u)then result:=plr_are_enemies(g,u.own,cp.num);
  CA_BIGPLAT   :begin
   i:=0; 
   for xo:=0 to 1 do for yo:=0 to 1 do begin
    if not inrm(g,x+xo,y+yo)then continue;
    if(get_map_pass(g,x+xo,y+yo)=P_LAND)or((get_unu_length(g,x+xo,y+yo)>0) and cell_attrib(g,x+xo,y+yo,CA_SMALLPLAT)) then i:=i+1;
   end;
   result:=i=4;
  end;
  else for i:=0 to get_unu_length(g,x,y)-1 do begin  
   u:=get_unu(g,x,y,i);
   if unav(u) then case what of
    CA_PLANE    :result:=result or(u.ptyp=pt_air);
    CA_SMALLPLAT:result:=result or(isa(g,u,a_can_build_on)and(not isa(g,u,a_connector)));
    CA_BOMB     :result:=result or(plr_are_enemies(g,u.own,cp.num)and isa(g,u,a_bomb)and u.is_sentry and(u.stealth_detected[cp.num]>0));
    CA_BRIDGE   :result:=result or isa(g,u,a_effectively_bridge);
    CA_ROAD     :result:=result or isa(g,u,a_road);
    CA_RUBBLE   :result:=result or(u.typ='smlrubble')or(u.typ='bigrubble');
   end;
  end;
 end;      
end;   
//############################################################################//
procedure enum_units_in_cell(g:pgametyp;x,y:integer;out umu:aptypunits);
var i,n:integer;
begin
 n:=get_unu_length(g,x,y); 
 setlength(umu,n);
 if n=0 then exit;
 
 n:=0;
 for i:=0 to length(umu)-1 do if unav(get_unu(g,x,y,i)) then if not isa(g,get_unu(g,x,y,i),a_unselectable) then begin
  umu[n]:=get_unu(g,x,y,i);
  n:=n+1;
 end;
 setlength(umu,n);
end;     
//############################################################################//
////FIXME: Interlanguage
procedure selection_message(g:pgametyp;su:ptypunits);
var ud:ptypunitsdb;
begin
 msgu.p:=false;
 msgu.txt:='';
 if su=nil then exit;
 if isa(g,su,a_ours) then begin
  ud:=get_unitsdb(g,getdbnum(g,su.builds[0].typ));
  if isa(g,su,a_our_builder_working) then msgu_set('Строится '+ud.name_rus+', ходов до окончания: '+stri(su.builds[0].left_turns));
  if su.isbuildfin then begin
   msgu_set('Строительство '+ud.name_rus+' завершено.');
  end;  
  if isa(g,su,a_cleaner) and su.isclrg then msgu_set('Чистит, ходов до окончания: '+stri(su.clrturns));
 end;
 if su.disabled_for<>0 then msgu_set('Вырублен на '+stri(su.disabled_for)+' ходов.');
end;
//############################################################################//       
procedure select_unit(g:pgametyp;new:integer;msg:boolean);
var ////mods:pmods_rec;   
pl:pplrtyp;
i:integer;
begin           
 ////FIXME
 ////mods:=get_mods(g);
 ////mods.extmod:=false;   
 ////mg_menu.rmnu:=false;
 pl:=get_cur_plr(g);
 i:=pl.selunit;
 pl.selunit:=new;
 if(new<>-1)and msg then selection_message(g,get_unit(g,new));
 if assigned(on_selection_changed) then on_selection_changed(g.grp_1,get_unit(g,i),get_unit(g,new));   
end;   
//############################################################################//
procedure select_nothing(g:pgametyp;cp:pplrtyp);
begin
 if cp=get_cur_plr(g) then select_unit(g,-1,false) else begin
  cp.selunit:=-1;
 end;
end;      
//############################################################################//
//Select unit n only if no selection or cur is currently selected
procedure change_selection(g:pgametyp;cur,n:ptypunits);
var cp:pplrtyp;
begin
 cp:=get_cur_plr(g);
 if cp.selunit=cur.num then select_unit(g,n.num,true);
end;
//############################################################################//
function is_ammo_red(u:ptypunits):boolean;
begin
 result:=false;
 if not unav(u) then exit;
 if u.bas.ammo=0 then exit;
 result:=u.cur.ammo/u.bas.ammo<=0.25;
end;
//############################################################################//
function is_ammo_yellow(u:ptypunits):boolean;
begin
 result:=false;
 if not unav(u) then exit;
 if u.bas.ammo=0 then exit;
 result:=(u.cur.ammo/u.bas.ammo<=0.5) and not is_ammo_red(u);
end;
//############################################################################//
function is_hits_red(u:ptypunits):boolean;
begin
 result:=false;
 if not unav(u) then exit;
 if u.bas.hits=0 then exit;
 result:=u.cur.hits/u.bas.hits<=0.25;
end;
//############################################################################//
function is_hits_yellow(u:ptypunits):boolean;
begin
 result:=false;
 if not unav(u) then exit;
 if u.bas.hits=0 then exit;
 result:=(u.cur.hits/u.bas.hits<=0.5) and not is_hits_red(u);
end;
//############################################################################//
function is_ammo_low(u:ptypunits):boolean;begin result:=is_ammo_yellow(u) or is_ammo_red(u);end;
function is_hits_low(u:ptypunits):boolean;begin result:=is_hits_yellow(u) or is_hits_red(u);end;
//############################################################################//
begin
end.   
//############################################################################//  
