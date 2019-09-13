//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core Units handling functions
//############################################################################//
unit mg_builds;
interface
uses asys,mgvars,mgrecs,mgauxi,mgunits,mgress,mgl_common,mgl_attr,mgl_tests,mgl_scan,mgl_buildcalc,mgl_unu,mgl_logs;
//############################################################################//   
function  re_set_build              (g:pgametyp;u:ptypunits):boolean;  
procedure stop_construction_building(g:pgametyp;u:ptypunits;autolevel:boolean);   
procedure stop_construction_unit    (g:pgametyp;u:ptypunits);       
function  finish_build              (g:pgametyp;ox,oy:integer;u:ptypunits):boolean;   
function  set_build                 (g:pgametyp;u:ptypunits;res_mat:integer):boolean;        
//############################################################################//   
implementation    
//############################################################################//
//Recalc construction
function re_set_build(g:pgametyp;u:ptypunits):boolean;
var avl_mat,cost,will_take_turns,will_mat,will_speed,will_cost,will_speed_nml:integer;
begin   
 result:=false;                           
 if u=nil then exit;
 result:=true;
 
 //Buildings assume materials are unlimited, the limits are handled in resman
 avl_mat:=1000;
 if not isa(g,u,a_building) then begin
  get_mat_avl_turn(g,u,u.builds[0].typ_db,avl_mat,cost);
  avl_mat:=avl_mat-u.reserve;
 end;
 
 if u.builds[0].left_to_build<u.bas.mat_turn then u.builds[0].left_to_build:=0;
                                                                                                                                                                       
 calc_build_params(u.builds[0].given_speed,u.builds[0].left_to_build,10000  ,u.bas.mat_turn,u.builds[0].reverse,false,will_take_turns,will_mat,will_speed_nml,will_cost); 
 calc_build_params(u.builds[0].given_speed,u.builds[0].left_to_build,avl_mat,u.bas.mat_turn,u.builds[0].reverse,false,will_take_turns,will_mat,will_speed,will_cost);
         
 u.builds[0].left_turns:=will_take_turns;
 if isa(g,u,a_building) and(will_speed<>will_speed_nml) then begin result:=false;exit;end;
 u.builds[0].cur_speed:=will_speed;  
 u.builds[0].cur_take:=will_cost;
 calc_build_params(will_speed,0,avl_mat,u.bas.mat_turn,u.builds[0].reverse,true,will_take_turns,will_mat,will_speed,will_cost);
 u.builds[0].cur_use:=will_mat;
 u.prod.use[RES_MAT]:=u.builds[0].cur_use;    

 //Next turn consumption
 calc_build_params(u.builds[0].given_speed,u.builds[0].left_to_build-will_cost,avl_mat,u.bas.mat_turn,u.builds[0].reverse,false,will_take_turns,will_mat,will_speed,will_cost);      
 calc_build_params(will_speed,0,avl_mat,u.bas.mat_turn,u.builds[0].reverse,true,will_take_turns,will_mat,will_speed,will_cost);
 u.prod.next_use[RES_MAT]:=will_mat; 
end; 
//############################################################################//
procedure stop_construction_building(g:pgametyp;u:ptypunits;autolevel:boolean);   
var ri:integer;
begin try       
 if not unav(u) then exit;  
 
 if not isa(g,u,a_building) then exit;
 for ri:=RES_MIN to RES_MAX do if u.prod.use[ri]>0 then return_debt(g,u,ri,u.prod.use[ri]);
 if autolevel then autolevel_res(g,u);
                    
 u.prod.use[RES_MAT]:=0;
 u.isact:=false;       
 
 except stderr('Units','stop_construction_building');end;  
end; 
//############################################################################//
procedure stop_construction_unit(g:pgametyp;u:ptypunits);   
begin try          
 if not unav(u) then exit;    
 if isa(g,u,a_building) then exit; 
 
 subscan(g,u);
 remunuc(g,u.x,u.y,u);  
  
 if u.isbuild and(u.builds_cnt>0)then begin
  if u.builds[0].base>=0  then delete_unit(g,get_unit(g,u.builds[0].base) ,false,false);
  if u.builds[0].tape>=0  then delete_unit(g,get_unit(g,u.builds[0].tape) ,false,false);
  if u.builds[0].cones>=0 then delete_unit(g,get_unit(g,u.builds[0].cones),false,false); 
  u.builds[0].base:=-1;u.builds[0].tape:=-1;u.builds[0].cones:=-1;   
  u.builds[0].typ:='';
  if u.cur_siz=2 then begin u.x:=u.prior_x;u.y:=u.prior_y;u.prior_x:=0;u.prior_y:=0;end;
  u.cur_siz:=0;    
  u.isbuild:=false;   
  u.builds_cnt:=0;
  u.reserve:=0;
 end;

 u.isbuildfin:=false; 
  
 addunu(g,u);
 addscan(g,u,u.x,u.y);   //FIXME: Net order bad
 except stderr('Units','stop_construction_unit');end;   
end;
//############################################################################//
procedure putplat(g:pgametyp;u:ptypunits;x,y:integer;tp:string;ch:integer;scan:boolean);
var uc:ptypunits;
begin
 if u.builds_cnt=0 then exit;
 uc:=create_unit(g,tp,x,y,u.own,false);
 if scan then addscan(g,uc,uc.x,uc.y);
 case ch of
  0:u.builds[0].base:=uc.num;
  1:u.builds[0].tape:=uc.num;
  2:u.builds[0].cones:=uc.num;
 end;
end;
//############################################################################//
//Begin build a unit
function set_build_by_building(g:pgametyp;u:ptypunits;res_mat:integer):boolean;
var what:integer;
begin result:=false; try
 if not unav(u) then exit;
 if u.builds_cnt=0 then exit;
 what:=getdbnum(g,u.builds[0].typ);
 if not unavdb(g,what) then exit;
 if not isa(g,u,a_building) then exit;

 if can_build(g,u,u.builds[0].typ,u.builds[0].reverse,res_mat,u.builds[0].cur_speed,-1,-1) then begin
  u.isbuild:=true;
  u.prod.use[RES_MAT]:=u.builds[0].cur_use;
  if not istartunit(g,u,true,false) then begin
   u.isbuild:=false;
   exit;
  end;
  result:=true;
 end else add_log_msgu(g,u.own,lmt_build_no_materials,u);

 except stderr('Units','set_build_by_building');end;
end;
//############################################################################//
//Begin build a building
function set_build_by_unit(g:pgametyp;u:ptypunits;res_mat:integer):boolean;
var what:integer;
b:ptypunitsdb;
begin result:=false; try
 if not unav(u) then exit;
 if u.builds_cnt=0 then exit;
 what:=getdbnum(g,u.builds[0].typ);
 if not unavdb(g,what) then exit;
 b:=get_unitsdb(g,what); 
 if isa(g,u,a_building) then exit;

 //Can be built?
 if not can_build(g,u,u.builds[0].typ,u.builds[0].reverse,res_mat,u.builds[0].cur_speed,u.x,u.y)then begin
  if b.siz=2 then begin
   addscan(g,u,u.prior_x,u.prior_y);
   subscan(g,u);
   remunuc(g,u.x,u.y,u);
   u.x:=u.prior_x;
   u.y:=u.prior_y;
   u.prior_x:=0;
   u.prior_y:=0;
   addunu(g,u);
  end; 
  result:=false;
  exit;
 end;

 if b.siz=2 then begin
  subscan(g,u);
  remunuc(g,u.x,u.y,u);
 end;
 clear_motion(g,u,true);
 u.rot:=0;
 u.isbuild:=true;
 u.cur_siz:=b.siz;

 //Add plates if needed
 if b.siz=2 then begin
  addunu(g,u);
  addscan(g,u,u.x,u.y);

  u.builds[0].base:=-1;
  if b.ptyp<pt_landwater then begin
   if isadb(g,b,a_bld_on_plate) then putplat(g,u,u.x,u.y,'bigplate',0,true);
   putplat(g,u,u.x,u.y,'bigrope',1,false);
   putplat(g,u,u.x,u.y,'bigcone',2,false);
  end;
  if b.ptyp>pt_landcoast then putplat(g,u,u.x,u.y,'bigrope',1,false);
 end;

 if b.siz=1 then begin
  u.builds[0].base:=-1;
  if b.ptyp<pt_landwater then begin
   if isadb(g,b,a_bld_on_plate) then putplat(g,u,u.x,u.y,'smlplate',0,true);
   putplat(g,u,u.x,u.y,'smlrope',1,false);
   putplat(g,u,u.x,u.y,'smlcone',2,false);
  end;
  if b.ptyp>pt_landcoast then putplat(g,u,u.x,u.y,'smlrope',1,false);
 end;

 //Insta-build connectors if defined
 if g.info.rules.lay_connectors then begin
  if u.builds[0].typ='conn' then begin
   iunit_endturn_build(g,u,0);
   iunit_endturn_build(g,u,1);
  end;
 end;

 //Insta-build roads
 if u.builds[0].typ='road' then begin
  iunit_endturn_build(g,u,0);
  iunit_endturn_build(g,u,1);
 end;

 result:=true;

 except stderr('Units','set_build_by_unit');end;
end;
//############################################################################//
//Begin build
function set_build(g:pgametyp;u:ptypunits;res_mat:integer):boolean;
begin
 if not unav(u) then exit;
 if isa(g,u,a_building) then result:=set_build_by_building(g,u,res_mat)
                        else result:=set_build_by_unit(g,u,res_mat);
end;
//############################################################################//
procedure post_built_building(g:pgametyp;u:ptypunits);
begin
 addunu(g,u);
 refresh_domains(g);
 addscan(g,u,u.x,u.y);
 if isa(g,u,a_run_on_completion) then istartunit(g,u,true,false);   //AHA!
end;
//############################################################################//
//Process build
function finish_build(g:pgametyp;ox,oy:integer;u:ptypunits):boolean;
var i,x,y,d:integer;
b:ptypunitsdb;
uj:ptypunits;

const mota:array[0..11]of array[0..11]of integer=
((0,0, 1, 1,2,0,0,7,0,0,7,0),
 (1,1,-1,-1,3,1,1,7,0,0,0,0),
 (0,1, 1,-1,3,0,1,1,1,0,0,0),
 (1,0,-1, 1,2,1,0,1,0,0,0,1),
 (1,1,-1,-1,3,1,1,7,0,0,6,6),
 (0,1, 1,-1,3,0,1,1,1,0,2,2),
 (1,0,-1, 1,3,1,0,5,0,1,6,6),
 (0,0, 1, 1,3,0,0,3,1,1,2,2),
 (0,1, 1,-1,2,0,1,5,0,0,0,5),
 (1,0,-1, 1,3,1,0,5,0,1,4,4),
 (0,0, 1, 1,3,0,0,3,1,1,4,4),
 (1,1,-1,-1,2,1,1,3,0,0,0,3)
);

begin try
 result:=false; 
 if not unav(u) then exit;
 if u.builds_cnt=0 then exit;     
 mark_unit(g,u.num);
 
 //For units
 if not isa(g,u,a_building) then begin
  x:=u.x;
  y:=u.y;
  d:=getdbnum(g,u.builds[0].typ);
  b:=get_unitsdb(g,d);
  if b=nil then exit;
   
  if u.builds[0].base>=0  then delete_unit(g,get_unit(g,u.builds[0].base) ,false,false);
  if u.builds[0].tape>=0  then delete_unit(g,get_unit(g,u.builds[0].tape) ,false,false);
  if u.builds[0].cones>=0 then delete_unit(g,get_unit(g,u.builds[0].cones),false,false);
  u.builds[0].base:=-1;u.builds[0].tape:=-1;u.builds[0].cones:=-1; 

  u.isbuildfin:=false;
   
  //Engineer-kind
  if u.builds[0].sz=1 then begin
   uj:=place_full_unit(g,b.typ,u.x,u.y,u.own);
   post_built_building(g,uj);
   
   if u.builds_cnt>1 then begin
    if test_pass(g,u.builds[1].x,u.builds[1].y,u) then begin
     u.xt:=u.builds[1].x;
     u.yt:=u.builds[1].y;
     u.is_moving:=true;
     u.isstd:=false;   
     u.stpmov:=false;
     u.plen:=0;
     u.pstep:=0;
    end else begin
     u.isbuild:=true;            //FIXME: Avoiding check in stop_construction_unit
     stop_construction_unit(g,u);
     u.builds_cnt:=1;            //FIXME: Avoiding check in result=true
    end;
   end else begin
    if isa(g,uj,a_bld_on_plate) then begin
     u.is_moving:=true;   
     u.is_moving_build:=true;  
     setlength(u.path,2);
     u.plen:=2;u.pstep:=0;
     u.path[0].px:=x;u.path[0].py:=y;u.path[0].pval:=2*(1+0.42*ord((x<>ox)and(y<>oy)));
     u.path[1].px:=ox;u.path[1].py:=oy;u.path[1].pval:=2*(1+0.42*ord((x<>ox)and(y<>oy)));
     u.path[0].dir:=getdirbydp(ox,x,oy,y);
     u.path[1].dir:=u.path[0].dir;
    end;
   end;    
   result:=true;
  end;

  //Constructor-kind
  if u.builds[0].sz=2 then begin    
   subscan(g,u);
   remunuc(g,x,y,u);

   uj:=place_full_unit(g,b.typ,u.x,u.y,u.own);
   post_built_building(g,uj);
                   
   u.cur_siz:=u.siz; 
   u.is_moving:=true;
   u.stpmov:=false;
   u.is_moving_build:=true;
   d:=0;
   if(ox=x-1)and(oy=y-1)then d:=0;
   if(ox=x  )and(oy=y-1)then d:=1;
   if(ox=x+1)and(oy=y-1)then d:=2;
   if(ox=x+2)and(oy=y-1)then d:=3;
   if(ox=x-1)and(oy=y  )then d:=4;
   if(ox=x+2)and(oy=y  )then d:=5;
   if(ox=x-1)and(oy=y+1)then d:=6;
   if(ox=x+2)and(oy=y+1)then d:=7;
   if(ox=x-1)and(oy=y+2)then d:=8;
   if(ox=x  )and(oy=y+2)then d:=9;
   if(ox=x+1)and(oy=y+2)then d:=10;
   if(ox=x+2)and(oy=y+2)then d:=11;
   u.pstep:=0;
 
   u.x:=x+mota[d][0];u.y:=y+mota[d][1];
   u.plen:=mota[d][4]; 
   setlength(u.path,mota[d][4]); 
   for i:=0 to mota[d][4]-2 do begin
    u.path[i].px:=x+mota[d][5+i*3];u.path[i].py:=y+mota[d][6+i*3];
    u.path[i].dir:=mota[d][7+i*3];u.path[i].pval:=2*(1+0.42*ord((x<>ox)and(y<>oy)));
   end;           
   u.path[mota[d][4]-1].px:=ox;u.path[mota[d][4]-1].py:=oy;
   u.path[mota[d][4]-1].dir:=mota[d][11];
   u.path[mota[d][4]-1].pval:=2*(1+0.42*ord((x<>ox)and(y<>oy)));

   addunu(g,u);
   addscan(g,u,u.x,u.y); //FIXME: Net order
   result:=true;
  end;
 end;

 //For buildings
 if isa(g,u,a_building) then begin   
  if test_pass_db(g,ox,oy,u.builds[0].typ_db,nil) then begin
   uj:=place_full_unit(g,u.builds[0].typ,ox,oy,u.own);
   unit_newpos(g,uj,ox,oy);
   u.isbuildfin:=false;
   u.prod.use[RES_MAT]:=0;
   result:=true;
  end;
 end;
 
 if result then begin
  if u.builds_cnt>1 then for i:=0 to u.builds_cnt-2 do u.builds[i]:=u.builds[i+1];
  u.builds_cnt:=u.builds_cnt-1;
  if isa(g,u,a_building) and(u.builds_cnt>0) then set_build(g,u,0);
 end;
  
 except result:=false;stderr('Units','finish_build');end;
end;
//############################################################################//
begin
end.   
//############################################################################//
