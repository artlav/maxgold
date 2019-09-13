//############################################################################//
unit mgl_tests;
interface    
uses mgrecs,mgl_common,mgl_attr,mgl_res;   
//############################################################################//   
function terrain_test_pas(g:pgametyp;tx,ty:integer;u:ptypunits):boolean;    
function test_pass(g:pgametyp;tx,ty:integer;u:ptypunits;ign:boolean=false;typ:integer=0):boolean;   
function test_pass_db(g:pgametyp;tx,ty,un:integer;su:ptypunits):boolean;  
function landing_pass_test(g:pgametyp;x1,y1,x2,y2:integer;out r:integer):boolean;
              
function test_plane_casual_pass(g:pgametyp;xcr,ycr:integer):boolean;
function fire_possible(g:pgametyp;u,t:ptypunits):boolean;
function cursor_fire_possible(g:pgametyp;u,t:ptypunits):boolean;   

function only_landed_storable(g:pgametyp;ut,u:ptypunits):boolean;
function storable(g:pgametyp;ut,u:ptypunits):boolean;  
function unstorable(g:pgametyp;u:ptypunits;x,y:integer):boolean;

function is_air_store(g:pgametyp;ut,u:ptypunits):boolean;
function is_air_unstore(g:pgametyp;ut,u:ptypunits):boolean;
function check_air_storage(g:pgametyp;u,hu:ptypunits;air_store:boolean):boolean;

function unstore_test_pass(g:pgametyp;xns,yns:integer;u:ptypunits):boolean;   

function is_toolapplicable(g:pgametyp;u,ut:ptypunits;typ:integer):boolean;

function can_u_build_ud(g:pgametyp;u:ptypunits;ud:ptypunitsdb):boolean;
function can_u_build_n(g:pgametyp;u:ptypunits;n:integer):boolean; 
function can_build_rect_here(g:pgametyp;su:ptypunits;xns,yns:integer;what:integer):boolean;
//############################################################################//
implementation  
//############################################################################//
//Absolute test if unit un can pass tx,ty
function terrain_test_pas(g:pgametyp;tx,ty:integer;u:ptypunits):boolean;    
begin 
 result:=false;
 if u=nil then exit;
      
 result:=true;
 if u.ptyp<>pt_air then begin
  if get_map_pass(g,tx,ty)=P_OBSTACLE then result:=false;
  if (u.siz=2)and((get_map_pass(g,tx+1,ty)=P_OBSTACLE)or(get_map_pass(g,tx,ty+1)=P_OBSTACLE)or(get_map_pass(g,tx+1,ty+1)=P_OBSTACLE)) then result:=false;
 end;
 if not isa(g,u,a_building) then begin
  if u.ptyp=pt_landonly   then if(get_map_pass(g,tx,ty)<>P_LAND )and(not cell_attrib(g,tx,ty,CA_BRIDGE)) then result:=false;
  if u.ptyp=pt_landcoast  then if(get_map_pass(g,tx,ty)<>P_LAND )and(get_map_pass(g,tx,ty)<>P_COAST)and(not cell_attrib(g,tx,ty,CA_BRIDGE)) then result:=false;
  if u.ptyp=pt_watercoast then if(get_map_pass(g,tx,ty)<>P_WATER)and(get_map_pass(g,tx,ty)<>P_COAST) then result:=false;
  if u.ptyp=pt_wateronly  then if get_map_pass(g,tx,ty)<>P_WATER then result:=false;
 end else begin
  if u.ptyp=pt_landonly   then if(get_map_pass(g,tx,ty)<>P_LAND )and(not cell_attrib(g,tx,ty,CA_SMALLPLAT)) then result:=false;
  if u.ptyp=pt_landcoast  then if(get_map_pass(g,tx,ty)<>P_LAND )and(get_map_pass(g,tx,ty)<>P_COAST)and(not cell_attrib(g,tx,ty,CA_SMALLPLAT)) then result:=false;
  if u.ptyp=pt_watercoast then if(get_map_pass(g,tx,ty)<>P_WATER)and(get_map_pass(g,tx,ty)<>P_COAST) then result:=false;
  if u.ptyp=pt_wateronly  then if get_map_pass(g,tx,ty)<>P_WATER then result:=false;
  if u.siz=2 then begin
   if u.ptyp=pt_landonly   then if((get_map_pass(g,tx+1,ty)<>P_LAND )or(get_map_pass(g,tx,ty+1)<>P_LAND )or(get_map_pass(g,tx+1,ty+1)<>P_LAND ))and(not cell_attrib(g,tx,ty,CA_BIGPLAT)) then result:=false;
   if u.ptyp=pt_landcoast  then if((get_map_pass(g,tx+1,ty)<>P_LAND )or(get_map_pass(g,tx,ty+1)<>P_LAND )or(get_map_pass(g,tx+1,ty+1)<>P_LAND ))and((get_map_pass(g,tx+1,ty)<>P_COAST)or(get_map_pass(g,tx,ty+1)<>P_COAST)or(get_map_pass(g,tx+1,ty+1)<>P_COAST))and(not cell_attrib(g,tx,ty,CA_BIGPLAT)) then result:=false;
   if u.ptyp=pt_watercoast then if((get_map_pass(g,tx+1,ty)<>P_WATER)or(get_map_pass(g,tx,ty+1)<>P_WATER)or(get_map_pass(g,tx+1,ty+1)<>P_WATER))and((get_map_pass(g,tx+1,ty)<>P_COAST)or(get_map_pass(g,tx,ty+1)<>P_COAST)or(get_map_pass(g,tx+1,ty+1)<>P_COAST)) then result:=false;
   if u.ptyp=pt_wateronly  then if((get_map_pass(g,tx+1,ty)<>P_WATER)or(get_map_pass(g,tx,ty+1)<>P_WATER)or(get_map_pass(g,tx+1,ty+1)<>P_WATER)) then result:=false;
  end;
 end;
end;            
//############################################################################//
//Test for effective unit present at xcr,ycr
function int_test_unit_here(g:pgametyp;xcr,ycr:integer;u:ptypunits;ign:boolean=false;bldg_only:boolean=false):boolean;
var n,j,a,b:integer;
c:ptypunits;
begin 
 a:=0;
 b:=0;
 result:=false;
 if u=nil then exit; 
 result:=true;
 if u.siz=1 then if not inrm(g,xcr,ycr) then exit;
 if u.siz=2 then if (not inrm(g,xcr+1,ycr))or(not inrm(g,xcr,ycr+1))or(not inrm(g,xcr+1,ycr+1)) then exit;
 result:=false;
 if u.siz=1 then if get_unu_length(g,xcr,ycr)=0 then exit;
 if u.siz=2 then if(get_unu_length(g,xcr+1,ycr)=0)and(get_unu_length(g,xcr,ycr+1)=0)and(get_unu_length(g,xcr+1,ycr+1)=0) then exit;

 for j:=0 to 3 do begin
  case j of
   0:begin a:=0;b:=0;end;
   1:if u.siz=2 then begin a:=1;b:=0;end else exit;
   2:if u.siz=2 then begin a:=0;b:=1;end else exit;
   3:if u.siz=2 then begin a:=1;b:=1;end else exit;
  end;
  for n:=0 to get_unu_length(g,xcr+a,ycr+b)-1 do begin
   c:=get_unu(g,xcr+a,ycr+b,n); 
   if not unav(c) then continue;
   if ign then if c=u then continue;
   if(not isa(g,c,a_building))and bldg_only then continue;
   if u.typ=c.typ then result:=true;
   if u.ptyp=pt_landonly   then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge))and(not isa(g,c,a_can_build_on))and(not isa(g,c,a_road))and(not isa(g,c,a_unselectable)) then result:=true;
   if u.ptyp=pt_landcoast  then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge))and(not isa(g,c,a_can_build_on))and(not isa(g,c,a_road))and(not isa(g,c,a_unselectable)) then result:=true;
   if u.ptyp=pt_landwater  then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge))and(not isa(g,c,a_can_build_on))and(not isa(g,c,a_road))and(not isa(g,c,a_unselectable)) then result:=true;
   if u.ptyp=pt_watercoast then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_wateronly  then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_air        then if c.ptyp=pt_air then result:=true;
  end;
 end;
end;    
//############################################################################//
//Test for effective unit present at xcr,ycr for database unit un, excluding sn
function int_test_unit_here_db(g:pgametyp;xcr,ycr,un:integer;su:ptypunits):boolean;
var n,j,a,b:integer;
u:ptypunitsdb;
c:ptypunits;
begin
 a:=0;
 b:=0;
 u:=get_unitsdb(g,un);
 
 result:=true;
 if u.siz=1 then if not inrm(g,xcr,ycr) then exit;
 if u.siz=2 then if (not inrm(g,xcr+1,ycr))or(not inrm(g,xcr,ycr+1))or(not inrm(g,xcr+1,ycr+1)) then exit;
 result:=false;
 if u.siz=1 then if get_unu_length(g,xcr,ycr)=0 then exit;
 if u.siz=2 then if(get_unu_length(g,xcr+1,ycr)=0)and(get_unu_length(g,xcr,ycr+1)=0)and(get_unu_length(g,xcr+1,ycr+1)=0) then exit;

 for j:=0 to 3 do begin
  case j of
   0:begin a:=0;b:=0;end;
   1:if u.siz=2 then begin a:=1;b:=0;end else exit;
   2:if u.siz=2 then begin a:=0;b:=1;end else exit;
   3:if u.siz=2 then begin a:=1;b:=1;end else exit;
  end;
  for n:=0 to get_unu_length(g,xcr+a,ycr+b)-1 do begin
   c:=get_unu(g,xcr+a,ycr+b,n);  
   if not unav(c) then continue;
   if c=su then continue;
   if u.typ=c.typ then result:=true;
   
   if u.ptyp=pt_landonly   then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_can_build_on))and(not isa(g,c,a_road))and(not isa(g,c,a_unselectable))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_landcoast  then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_can_build_on))and(not isa(g,c,a_road))and(not isa(g,c,a_unselectable))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_landwater  then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_can_build_on))and(not isa(g,c,a_road))and(not isa(g,c,a_unselectable))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_watercoast then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_wateronly  then if(c.ptyp<>pt_air)and(not isa(g,c,a_bomb))and(not isa(g,c,a_connector))and(not isa(g,c,a_bridge)) then result:=true;
   if u.ptyp=pt_air        then if c.ptyp=pt_air then result:=true;
  end;
 end;
end;      
//############################################################################//
//Test if unit un can pass tx,ty
function test_pass(g:pgametyp;tx,ty:integer;u:ptypunits;ign:boolean=false;typ:integer=0):boolean;
var tp00,tp01,tp10,tp11:integer;
nun:ptypunits;
begin
 result:=false;
 if not inrm(g,tx,ty) then exit;
 if u=nil then exit;
 
 result:=true;
 tp00:=get_map_pass(g,tx,ty);tp10:=get_map_pass(g,tx+1,ty);tp01:=get_map_pass(g,tx,ty+1);tp11:=get_map_pass(g,tx+1,ty+1);
 if u.ptyp<>pt_air then begin
  if tp00=P_OBSTACLE then result:=false;
  if (u.siz=2)and((tp10=P_OBSTACLE)or(tp01=P_OBSTACLE)or(tp11=P_OBSTACLE)) then result:=false;
 end;
                         
 nun:=nil;
 if get_unu_length(g,tx,ty)<>0 then nun:=get_unu(g,tx,ty,0);

 if(typ=0)or((typ=1)and(can_see(g,tx,ty,u.own,nun)))then if int_test_unit_here(g,tx,ty,u,ign)then result:=false;
 if(typ=2)and(can_see(g,tx,ty,u.own,nun))then if int_test_unit_here(g,tx,ty,u,ign,true)then result:=false;    
 if typ=3 then if cell_attrib(g,tx,ty,CA_BOMB) and(u.ptyp<>pt_air)then result:=false;
  
 if not isa(g,u,a_building) then begin
  if u.ptyp=pt_landonly   then if(tp00<>P_LAND )and(not cell_attrib(g,tx,ty,CA_BRIDGE)) then result:=false;
  if u.ptyp=pt_landcoast  then if(tp00<>P_LAND )and(tp00<>P_COAST)and(not cell_attrib(g,tx,ty,CA_BRIDGE)) then result:=false;
  if u.ptyp=pt_watercoast then if(tp00<>P_WATER)and(tp00<>P_COAST) then result:=false;
  if u.ptyp=pt_wateronly  then if tp00<>P_WATER then result:=false;
 end else begin
  if u.ptyp=pt_landonly   then if(tp00<>P_LAND )and(not cell_attrib(g,tx,ty,CA_SMALLPLAT)) then result:=false;
  if u.ptyp=pt_landcoast  then if(tp00<>P_LAND )and(tp00<>P_COAST)and(not cell_attrib(g,tx,ty,CA_SMALLPLAT)) then result:=false;
  if u.ptyp=pt_watercoast then if(tp00<>P_WATER)and(tp00<>P_COAST) then result:=false;
  if u.ptyp=pt_wateronly  then if tp00<>P_WATER then result:=false;
  if u.siz=2 then begin
   if u.ptyp=pt_landonly   then if((tp10<>P_LAND )or(tp01<>P_LAND )or(tp11<>P_LAND ))and(not cell_attrib(g,tx,ty,CA_BIGPLAT)) then result:=false;
   if u.ptyp=pt_landcoast  then if((tp10<>P_LAND )or(tp01<>P_LAND )or(tp11<>P_LAND ))and((tp10<>P_COAST)or(tp01<>P_COAST)or(tp11<>P_COAST))and(not cell_attrib(g,tx,ty,CA_BIGPLAT)) then result:=false;
   if u.ptyp=pt_watercoast then if((tp10<>P_WATER)or(tp01<>P_WATER)or(tp11<>P_WATER))and((tp10<>P_COAST)or(tp01<>P_COAST)or(tp11<>P_COAST)) then result:=false;
   if u.ptyp=pt_wateronly  then if((tp10<>P_WATER)or(tp01<>P_WATER)or(tp11<>P_WATER)) then result:=false;
  end;
 end;
end;     
//############################################################################//
//Test if database unit un can pass tx,ty, ignoring sn
function test_pass_db(g:pgametyp;tx,ty,un:integer;su:ptypunits):boolean;
var rb:boolean;  
t:ptypunitsdb;
begin
 result:=false;
 if(un>-1)and(un<get_unitsdb_count(g))then begin
  t:=get_unitsdb(g,un);
  result:=true;
  if t.ptyp<>pt_air then begin
   if get_map_pass(g,tx,ty)=P_OBSTACLE then result:=false;
   if (t.siz=2)and((get_map_pass(g,tx+1,ty)=P_OBSTACLE)or(get_map_pass(g,tx,ty+1)=P_OBSTACLE)or(get_map_pass(g,tx+1,ty+1)=P_OBSTACLE)) then result:=false;
   if int_test_unit_here_db(g,tx,ty,un,su)then result:=false;
   if isadb(g,t,a_building) then begin
    rb:=cell_attrib(g,tx,ty,CA_RUBBLE);
    if t.siz=2 then rb:=rb or cell_attrib(g,tx+1,ty,CA_RUBBLE) or cell_attrib(g,tx,ty+1,CA_RUBBLE) or cell_attrib(g,tx+1,ty+1,CA_RUBBLE);
    if rb and not isadb(g,t,a_connector) then result:=false;
   end;
  end;
  if t.ptyp=pt_landonly   then if(get_map_pass(g,tx,ty)<>P_LAND )and(not cell_attrib(g,tx,ty,CA_SMALLPLAT))and(not cell_attrib(g,tx,ty,CA_BRIDGE)) then result:=false;
  if t.ptyp=pt_landcoast  then if(get_map_pass(g,tx,ty)<>P_LAND )and(get_map_pass(g,tx,ty)<>P_COAST)and(not cell_attrib(g,tx,ty,CA_SMALLPLAT))and(not cell_attrib(g,tx,ty,CA_BRIDGE)) then result:=false;
  if t.ptyp=pt_watercoast then if(get_map_pass(g,tx,ty)<>P_WATER)and(get_map_pass(g,tx,ty)<>P_COAST) then result:=false;
  if t.ptyp=pt_wateronly  then if get_map_pass(g,tx,ty)<>P_WATER then result:=false;
  if t.siz=2 then begin
   if t.ptyp=pt_landonly   then if(not cell_attrib(g,tx,ty,CA_BIGPLAT)) then result:=false;
   if t.ptyp=pt_landcoast  then if((get_map_pass(g,tx+1,ty)<>P_LAND )or(get_map_pass(g,tx,ty+1)<>P_LAND )or(get_map_pass(g,tx+1,ty+1)<>P_LAND ))and((get_map_pass(g,tx+1,ty)<>P_COAST)or(get_map_pass(g,tx,ty+1)<>P_COAST)or(get_map_pass(g,tx+1,ty+1)<>P_COAST))and(not cell_attrib(g,tx,ty,CA_BIGPLAT)) then result:=false;
   if t.ptyp=pt_watercoast then if((get_map_pass(g,tx+1,ty)<>P_WATER)or(get_map_pass(g,tx,ty+1)<>P_WATER)or(get_map_pass(g,tx+1,ty+1)<>P_WATER))and((get_map_pass(g,tx+1,ty)<>P_COAST)or(get_map_pass(g,tx,ty+1)<>P_COAST)or(get_map_pass(g,tx+1,ty+1)<>P_COAST)){and not testchnlishere(tx,ty)} then result:=false;
   if t.ptyp=pt_wateronly  then if((get_map_pass(g,tx+1,ty)<>P_WATER)or(get_map_pass(g,tx,ty+1)<>P_WATER)or(get_map_pass(g,tx+1,ty+1)<>P_WATER)) then result:=false;
  end;
 end;
end;         
//############################################################################//
//LandPlayer pass test exclude Player pn. pn can be -1
function landing_pass_test(g:pgametyp;x1,y1,x2,y2:integer;out r:integer):boolean;
var x,y:integer;
begin
 result:=true;
 r:=0;
 for x:=x1 to x2 do for y:=y1 to y2 do begin
  if not inrm(g,x,y) then begin result:=false;r:=1;exit;end;
  if get_map_pass(g,x,y)=P_OBSTACLE then begin result:=false;r:=2;exit;end;
 end;
end;     
//############################################################################//
function int_fire_possible(g:pgametyp;u,t:ptypunits):boolean;     
var ud:ptypunitsdb;
begin 
 result:=false;
 if not unav(u) then exit;     
 if not unav(t) then exit;
 ud:=get_unitsdb(g,u.dbn);  
 
 case ud.fire_type of
  FT_LAND_WATER_COAST:if (t.ptyp<>pt_air)or isa(g,t,a_landed)then result:=true;
  FT_WATER_COAST     :if((t.ptyp<>pt_air)or isa(g,t,a_landed))and((get_map_pass(g,t.x,t.y)=P_WATER)or(get_map_pass(g,t.x,t.y)=P_COAST)) then result:=true;
  FT_AIR             :if (t.ptyp=pt_air)and(not isa(g,t,a_landed)) then result:=true;
  FT_ALL             :result:=true;
 end;
 if(t.ptyp=pt_wateronly)and isa(g,t,a_underwater)then if(ud.weapon_type<>WT_TORPEDO)and(ud.weapon_type<>WT_BOMB)then result:=false;
end;      
//############################################################################//
//Test if plane would got to xcr,ycr if just clicked there
function test_plane_casual_pass(g:pgametyp;xcr,ycr:integer):boolean;
var u:ptypunits;
cp:pplrtyp;
begin
 result:=true;                    
 if get_unu_length(g,xcr,ycr)=0 then exit;
 u:=get_unu(g,xcr,ycr,0);
 if not unav(u) then exit;
 cp:=get_cur_plr(g);
  
 if not can_see(g,u.x,u.y,cp.num,u) then exit;
 if(not isa(g,u,a_road))and(not isa(g,u,a_unselectable))then begin
  if u.siz=1 then begin
   if(u.x=xcr)and(u.y=ycr)and(not isa(g,u,a_can_build_on))and(not isa(g,u,a_bridge))and(not isa(g,u,a_landing_pad))and(not isa(g,u,a_bomb)) then result:=false;
  end;
  if u.siz=2 then begin
   if(u.x=xcr)  and(u.y=ycr)  then result:=false;
   if(u.x=xcr)  and(u.y=ycr-1)then result:=false;
   if(u.x=xcr-1)and(u.y=ycr)  then result:=false;
   if(u.x=xcr-1)and(u.y=ycr-1)then result:=false;
  end;
 end;
end;      
//############################################################################//
//Is fire from un into tn possible?
function fire_possible(g:pgametyp;u,t:ptypunits):boolean;
begin      
 result:=false;
 if not unav(t) then exit;
 
 result:=int_fire_possible(g,u,t); 
 if t.typ='smlrubble' then result:=false;
 if t.typ='bigrubble' then result:=false;
end;                        
//############################################################################//
//Is fire from un into tn possible as shown in a cursor?
function cursor_fire_possible(g:pgametyp;u,t:ptypunits):boolean;     
begin 
 result:=int_fire_possible(g,u,t);
end; 
//############################################################################//
function only_landed_storable(g:pgametyp;ut,u:ptypunits):boolean;
var rul:prulestyp;
begin
 result:=false; 
 if u=nil then exit;
 if ut=nil then exit;
 rul:=get_rules(g);
 
 if ut.ptyp<>pt_air then exit;
 if not rul.load_onpad_only then exit;
 if not isa(g,u,a_exit_on_pad) then exit;

 result:=true;
end; 
//############################################################################//
//Check if gu could be put into depot ho
function storable(g:pgametyp;ut,u:ptypunits):boolean;       
var rul:prulestyp;
utd:ptypunitsdb;
begin 
 result:=false;
 if (not unav(u))or(not unav(ut))then exit; 
 rul:=get_rules(g);    
 utd:=get_unitsdb(g,ut.dbn);
  
 if isa(g,u,a_disabled)then exit;
 if isa(g,ut,a_disabled)then exit;
 if (utd.store_lnd>0)and(ut.currently_stored<utd.store_lnd)and(not isa(g,u,a_human))and(u.ptyp<=pt_landwater) then result:=true;
 if (utd.store_wtr>0)and(ut.currently_stored<utd.store_wtr)and(u.ptyp>=pt_watercoast)and(u.ptyp<=pt_wateronly) then result:=true;
 if (utd.store_air>0)and(ut.currently_stored<utd.store_air)and(u.ptyp=pt_air) then result:=true;
 if ((utd.store_hmn>0)or((utd.store_lnd>0)and(not isa(g,ut,a_building))))and((ut.currently_stored<utd.store_hmn)or((ut.currently_stored<utd.store_lnd)and(not isa(g,ut,a_building))))and(isa(g,u,a_human)) then result:=true;
 if are_enemies(g,ut,u) then result:=false;
 if isa(g,u,a_building) then result:=false;
 if u.isbuild or u.isbuildfin then result:=false;
 if rul.load_sub_one_speed and(u.cur.speed<10)then result:=false;
end;        
//############################################################################//
//Check if gu could be romoved from depot to x,y
function unstorable(g:pgametyp;u:ptypunits;x,y:integer):boolean;
var ho:integer;
ut:ptypunits;
rul:prulestyp;
begin
 result:=false;
 if u=nil then exit;  
 rul:=get_rules(g);
 
 ho:=u.stored_in;
 if not unav(g,ho) then exit;
 ut:=get_unit(g,ho);
 if inrau(g,x,y,ut,ut.ptyp=pt_air) then result:=true;
 if rul.unload_one_speed and(u.cur.speed<10)then result:=false;
end;    
//############################################################################//
function is_air_store(g:pgametyp;ut,u:ptypunits):boolean;     
begin
 result:=(ut.ptyp=pt_air) and not only_landed_storable(g,ut,u) and (ut.alt>0);
end;    
//############################################################################//
function is_air_unstore(g:pgametyp;ut,u:ptypunits):boolean;
begin               
 result:=(ut.ptyp=pt_air) and (ut.alt>0);
end;   
//############################################################################//
function check_air_storage(g:pgametyp;u,hu:ptypunits;air_store:boolean):boolean;
begin
 result:=false;
 if (not air_store)and(hu.ptyp=pt_air)and(hu.alt<>0) then begin
  if g.info.rules.load_onpad_only and isa(g,u,a_exit_on_pad) and (not isa(g,u,a_exit_empty) or (u.currently_stored>0)) then exit;
 end;
 result:=true;
end;
//############################################################################//
function unstore_test_pass(g:pgametyp;xns,yns:integer;u:ptypunits):boolean; 
var vis:boolean;
begin
 result:=false;
 //Visibility 
 if cell_attrib(g,xns,yns,CA_ANY_UNIT) then vis:=can_see(g,xns,yns,u.own,get_unu(g,xns,yns,0))
                                     else vis:=can_see(g,xns,yns,u.own,nil);
                                  
 if test_pass(g,xns,yns,u)and u.stored and unstorable(g,u,xns,yns) then result:=true;
 if((u.ptyp=pt_air)and(not vis))or((u.ptyp<pt_air)and terrain_test_pas(g,xns,yns,u)and(not vis)) then result:=true;
end;    
//############################################################################//
//Check if unit u can refuel unit ut
function is_toolapplicable(g:pgametyp;u,ut:ptypunits;typ:integer):boolean;
var nr,mr:integer;
begin
 result:=true;
 result:=result and not plr_are_enemies(g,u.own,ut.own)and
 (
  ((u.ptyp=pt_air )and(u.alt>0)and(ut.ptyp=pt_air)and(ut.alt>0))or //air to air
  ((u.ptyp=pt_air )and(u.alt=0)and(ut.ptyp<>pt_air))or             //air landed to ground
  ((u.ptyp=pt_air )and(u.alt=0)and(ut.ptyp=pt_air)and(ut.alt=0))or //air landed to air landed
  ((u.ptyp<>pt_air)and(ut.ptyp<>pt_air))or                         //ground to ground
  ((u.ptyp<>pt_air)and(ut.ptyp=pt_air)and(ut.alt=0))               //ground to air landed
 );
 if result then case typ of
  tool_xfer2 :begin
   nr:=get_rescount(g,ut,RES_MAT,GROP_NOW);
   mr:=get_rescount(g,ut,RES_MAT,GROP_MAX);
   result:=(mr>=2)and(nr<=mr-2)and(isa(g,u,a_passes_res)or(get_rescount(g,u,RES_MAT,GROP_NOW)>=2));
  end;
  tool_reload:result:=(ut.bas.ammo>0)and(ut.cur.ammo<ut.bas.ammo   )and(isa(g,u,a_passes_res)or(u.prod.now[RES_MAT]>0));
  tool_repair:result:=(ut.bas.hits>0)and(ut.cur.hits<ut.bas.hits   )and(isa(g,u,a_passes_res)or(u.prod.now[RES_MAT]>0));
  tool_refuel:result:=(ut.bas.fuel>0)and(ut.cur.fuel<ut.bas.fuel*10)and(isa(g,u,a_passes_res)or(u.prod.now[RES_FUEL]>0));
 end;
end;
//############################################################################//
//Can unit u build unit db ud, in principle (right kind of factory/constructor)
function can_u_build_ud(g:pgametyp;u:ptypunits;ud:ptypunitsdb):boolean;
var d:ptypunitsdb;
begin
 result:=false;
 if not unav(u) then exit;
 d:=get_unitsdb(g,u.dbn);
 result:=(ud.bldby=d.canbuildtyp) and not isadb(g,ud,a_unselectable);
end;
//############################################################################//
//Can unit u build unit db index n, in principle (right kind of factory/constructor)
function can_u_build_n(g:pgametyp;u:ptypunits;n:integer):boolean;
begin
 result:=false;
 if not unavdb(g,n) then exit;
 result:=can_u_build_ud(g,u,get_unitsdb(g,n))
end;
//############################################################################//
//Can a constructor's build rect be placed here
function can_build_rect_here(g:pgametyp;su:ptypunits;xns,yns:integer;what:integer):boolean;
var i:integer;
ud:ptypunitsdb;
begin
 result:=false;
 ud:=get_unitsdb(g,what);
 if ud=nil then exit;
 i:=getdbnum(g,ud.typ);
 if i=-1 then exit;

 if not inrau(g,xns,yns,su,true) then exit;  //Allow it to build on it's current position, needed for the check on server.
 if not unavdb(g,i) then exit;

 shift_to_inrau_2x2(su.x,su.y,xns,yns);
 if not test_pass_db(g,xns,yns,i,su) then exit;
 result:=true;
end;
//############################################################################//
begin
end.
//############################################################################//
