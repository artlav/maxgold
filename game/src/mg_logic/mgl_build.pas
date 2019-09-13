//############################################################################//
unit mgl_build;
interface  
uses mgrecs,mgl_common,mgl_attr,mgl_buildcalc,mgl_actions,mgl_rmnu,mgl_tests;
//############################################################################//
type
//Build menu queue element
bldq_menu_rec=record
 sunit,cost:integer;
 cs:array[0..3]of integer;
 sp:array[0..3]of integer;
end;

gm_builds_rec=record
 off,sel:integer;              //Offset, selection
 qoff,qsel:integer;            //Offset, selection
 brk,qbrk,speed:integer;       //Bracketed, speed
 reverse:boolean;
 reserve:integer;

 what,given_speed:integer;           //Build selected unit and speed (for constructor and path), set in build_building and build_building_path
 och_cnt:integer; 
 och:array[0..255]of bldq_menu_rec;
 och_cur:bldq_menu_rec;
end;   
pgm_builds_rec=^gm_builds_rec;                  
//############################################################################//  
var builds_menu:gm_builds_rec;
//############################################################################//   
procedure build_building(g:pgametyp;gm_builds:pgm_builds_rec;u:ptypunits;what,speed:integer);     
procedure build_building_path(g:pgametyp;gm_builds:pgm_builds_rec;who,what,speed:integer);   

procedure update_och_build_menu(g:pgametyp;gm_builds:pgm_builds_rec;reserve:integer);
procedure enter_build_menu(g:pgametyp;gm_builds:pgm_builds_rec);       

procedure build_sel_unit_on_list(g:pgametyp;gm_builds:pgm_builds_rec;par:integer);    
procedure build_sel_unit_on_build_queue(g:pgametyp;gm_builds:pgm_builds_rec;par:integer); 
procedure build_set_cur_build_unit_speed(g:pgametyp;gm_builds:pgm_builds_rec;par,par2:integer);        
procedure build_add_build_unit_cur(g:pgametyp;gm_builds:pgm_builds_rec);      
procedure build_rem_build_unit_cur(g:pgametyp;gm_builds:pgm_builds_rec);                
procedure build_add_sel_unit_to_queues(g:pgametyp;gm_builds:pgm_builds_rec);            
procedure building_build_ok(g:pgametyp;gm_builds:pgm_builds_rec;u:ptypunits);          
procedure build_change_sel_unit_speed(g:pgametyp;gm_builds:pgm_builds_rec;par,par2:integer);
//############################################################################//  
implementation  
//############################################################################//
procedure build_building(g:pgametyp;gm_builds:pgm_builds_rec;u:ptypunits;what,speed:integer);
var ud:ptypunitsdb;
mods:pmods_rec;
begin  
 if not unav(u) then exit;
 ud:=get_unitsdb(g,what);
 mods:=get_mods(g);

 //Without it things like constructor would get multiple items in their build q from repeated exits/entires (right-click the rect select case)
 clear_build(g,u);

 if ud.siz=1 then if not add_build(g,u,ud.typ,false,gm_builds.reserve,speed,u.x,u.y) then exit;
 if ud.siz=2 then if not add_build(g,u,ud.typ,false,gm_builds.reserve,speed,-1,-1) then exit;

 //Engineers build at once, constructors would build in mgl_mapclick.build_positioning_cmd
 if ud.siz=1 then act_set_build(g,u,gm_builds.reserve);
 if ud.siz=2 then begin u.reserve:=gm_builds.reserve;mods.build_rect:=true;end;

 set_game_menu(g,MG_NOMENU);
 gm_builds.what:=what;
end;
//############################################################################//
procedure build_building_path(g:pgametyp;gm_builds:pgm_builds_rec;who,what,speed:integer);   
var ud:ptypunitsdb;
mods:pmods_rec;
begin  
 if not unav(g,who)then exit;   
 ud:=get_unitsdb(g,what);
 if ud.siz<>1 then exit;

 mods:=get_mods(g);
 mods.build_path:=true;

 gm_builds.what:=what;
 gm_builds.given_speed:=speed;
 
 set_game_menu(g,MG_NOMENU);
end;
//############################################################################//
//Calc build menu
procedure update_och_build_menu(g:pgametyp;gm_builds:pgm_builds_rec;reserve:integer);
var i,k,j:integer;
u:ptypunits;
begin
 gm_builds.reserve:=reserve;
 u:=get_sel_unit(g);
 
 k:=-1;
 for j:=0 to gm_builds.och_cnt-1 do begin
  for i:=0 to 3 do if i<>2 then get_build_params(g,u,gm_builds.och[j].sunit,i+1,reserve,false,gm_builds.och[j].sp[i],gm_builds.och[j].cs[i],k);
  if gm_builds.och[j].sp[3]=gm_builds.och[j].sp[1] then begin gm_builds.och[j].sp[3]:=0;gm_builds.och[j].cs[3]:=0;end;
  if gm_builds.och[j].sp[1]=gm_builds.och[j].sp[0] then begin gm_builds.och[j].sp[1]:=0;gm_builds.och[j].cs[1]:=0;end;
 end;
end;
//############################################################################//
procedure enter_build_menu(g:pgametyp;gm_builds:pgm_builds_rec);
var j:integer;
u:ptypunits;
ud:ptypunitsdb;
c,cost:integer;
p:pplrtyp;
cl:ptypclansdb;
begin
 gm_builds.reserve:=0;
 gm_builds.och_cnt:=0;
 u:=get_sel_unit(g);
 for j:=0 to get_unitsdb_count(g)-1 do begin
  ud:=get_unitsdb(g,j);
  if can_u_build_ud(g,u,ud) then begin
   gm_builds.och_cnt:=gm_builds.och_cnt+1;
   gm_builds.och[gm_builds.och_cnt-1].sunit:=j;

   cost:=ud.bas.cost;
   c:=gettypclan(g,u.own,ud.typ);
   if c<>-1 then if u.own<>-1 then begin
    p:=get_plr(g,u.own);
    cl:=get_clan(g,p.info.clan);
    cost:=cost+cl.unupd[c].bas.cost;
   end;
   gm_builds.och[gm_builds.och_cnt-1].cost:=cost;
  end;
 end;

 update_och_build_menu(g,gm_builds,0);

 gm_builds.sel:=0;gm_builds.off:=0;gm_builds.brk:=0;
 gm_builds.qsel:=0;gm_builds.qoff:=0;gm_builds.qbrk:=0;

 gm_builds.speed:=1;
 gm_builds.reverse:=false;
 if u.builds_cnt<>0 then begin
  gm_builds.speed:=u.builds[0].given_speed;
  gm_builds.reverse:=u.builds[0].reverse;
 end;
end;
//############################################################################//
procedure build_sel_unit_on_list(g:pgametyp;gm_builds:pgm_builds_rec;par:integer);
begin
 if par<0 then exit;
 if par>gm_builds.och_cnt-1 then exit;
 gm_builds.sel:=par;
 //gm_builds.off:=(gm_builds.sel div 10)*10;  //Makes the menus jump around
 gm_builds.brk:=gm_builds.sel-gm_builds.off;
 if (gm_builds.och[gm_builds.sel].cs[3]=0)and(gm_builds.speed=4)then gm_builds.speed:=2;
 if (gm_builds.och[gm_builds.sel].cs[1]=0)and(gm_builds.speed=2)then gm_builds.speed:=1;
end;
//############################################################################//
procedure build_sel_unit_on_build_queue(g:pgametyp;gm_builds:pgm_builds_rec;par:integer);
var u:ptypunits; 
i:integer; 
begin
 u:=get_sel_unit(g);
 if not unav(u) then exit;
   
 if par>u.builds_cnt-1 then par:=u.builds_cnt-1;
 if par<0 then par:=0;
 gm_builds.qsel:=par;
 //gm_builds.qoff:=(par div 5)*5;   //Makes the menus jump around
 gm_builds.qbrk:=gm_builds.qsel-gm_builds.qoff;
 gm_builds.speed:=u.builds[gm_builds.qsel].given_speed;
 gm_builds.reverse:=u.builds[gm_builds.qsel].reverse;
 for i:=0 to gm_builds.och_cnt-1 do if gm_builds.och[i].sunit=u.builds[gm_builds.qsel].typ_db then begin
  build_sel_unit_on_list(g,gm_builds,i);
  break;
 end;
end;  
//############################################################################//
procedure build_set_cur_build_unit_speed(g:pgametyp;gm_builds:pgm_builds_rec;par,par2:integer);
var u:ptypunits; 
begin
 u:=get_sel_unit(g);
 if not unav(u) then exit;
 
 if add_build(g,u,u.builds[par2].typ,u.builds[par2].reverse,gm_builds.reserve,par,-2,par2) then begin
  u.builds[par2]:=u.builds[u.builds_cnt-1];   
  u.builds_cnt:=u.builds_cnt-1;
 end;
end;
//############################################################################//
procedure build_add_build_unit_cur(g:pgametyp;gm_builds:pgm_builds_rec);
var u:ptypunits;        
ud:ptypunitsdb;
b:buildrec;
i,j,par,par2,par3,par4:integer;
begin
 u:=get_sel_unit(g);
 if not unav(u) then exit;
 i:=u.builds_cnt;

 par:=gm_builds.och[gm_builds.sel].sunit;
 par2:=gm_builds.speed;
 par3:=gm_builds.qbrk+gm_builds.qoff+1;
 par4:=ord(gm_builds.reverse);
 
 ud:=get_unitsdb(g,par);

 if add_build(g,u,ud.typ,par4<>0,gm_builds.reserve,par2,-1,-1) then if par3<>u.builds_cnt-1 then begin
  b:=u.builds[u.builds_cnt-1];   
  for j:=u.builds_cnt-1 downto par3+1 do u.builds[j]:=u.builds[j-1];
  u.builds[par3]:=b;
 end;
 
 if u.builds_cnt<>i then begin
  gm_builds.qbrk:=gm_builds.qbrk+1;
  if gm_builds.qbrk>=u.builds_cnt then gm_builds.qbrk:=u.builds_cnt-1;
  if gm_builds.qbrk>5 then begin
   gm_builds.qbrk:=1;
   gm_builds.qoff:=gm_builds.qoff+5;
  end;
  gm_builds.qsel:=gm_builds.qbrk+gm_builds.qoff;
 end;
end;      
//############################################################################//
procedure build_rem_build_unit_cur(g:pgametyp;gm_builds:pgm_builds_rec);
var u:ptypunits;  
i,j:integer;
begin
 u:=get_sel_unit(g);
 if not unav(u) then exit;
   
 if u.builds_cnt=0 then exit;
              
 i:=gm_builds.qbrk+gm_builds.qoff;
 for j:=i to u.builds_cnt-2 do u.builds[j]:=u.builds[j+1];
 u.builds_cnt:=u.builds_cnt-1;

 if gm_builds.qbrk+gm_builds.qoff>=u.builds_cnt then gm_builds.qbrk:=u.builds_cnt-gm_builds.qoff-1;
 if(gm_builds.qbrk<0)and(gm_builds.qoff<>0)then begin 
  gm_builds.qoff:=gm_builds.qoff-5;
  gm_builds.qbrk:=gm_builds.qbrk+5;
 end;
 gm_builds.qsel:=gm_builds.qbrk+gm_builds.qoff;
end;
//############################################################################//
procedure build_add_sel_unit_to_queues(g:pgametyp;gm_builds:pgm_builds_rec);
var u:ptypunits;  
begin
 u:=get_sel_unit(g);
 if not unav(u) then exit;  
  
 if not isa(g,u,a_building) then build_building(g,gm_builds,u,gm_builds.och[gm_builds.sel].sunit,gm_builds.speed)
                            else build_add_build_unit_cur(g,gm_builds);
end;     
//############################################################################//
procedure building_build_ok(g:pgametyp;gm_builds:pgm_builds_rec;u:ptypunits);      
begin 
 act_set_build(g,u,gm_builds.reserve);
 set_game_menu(g,MG_NOMENU);
end;                      
//############################################################################//
procedure build_change_sel_unit_speed(g:pgametyp;gm_builds:pgm_builds_rec;par,par2:integer);
var u:ptypunits;  
begin  
 u:=get_sel_unit(g);
 if not unav(u) then exit;
   
 if par=4 then if gm_builds.och[gm_builds.sel].cs[3]<=0 then par:=2;
 if par=2 then if gm_builds.och[gm_builds.sel].cs[1]<=0 then if gm_builds.och[gm_builds.sel].cs[3]>0 then par:=4 else par:=1;
 if(par2<>0)and isa(g,u,a_building)and(u.builds_cnt>0)then begin
  gm_builds.speed:=par;
  if u.builds[gm_builds.qsel].cur_speed<>par then begin
   u.builds[gm_builds.qsel].cur_speed:=par;
   build_set_cur_build_unit_speed(g,gm_builds,par,gm_builds.qsel);
  end;
 end else if gm_builds.speed<>par then begin
  gm_builds.speed:=par;
  if(par2<>0)then build_set_cur_build_unit_speed(g,gm_builds,par,gm_builds.qsel);
 end;
end; 
//############################################################################//
begin
end.
//############################################################################//
