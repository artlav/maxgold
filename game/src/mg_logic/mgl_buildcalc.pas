//############################################################################// 
unit mgl_buildcalc;
interface  
uses asys,maths,mgrecs,mgl_common,mgl_attr,mgl_res,mgl_tests;   
//############################################################################//   
procedure get_mat_avl_turn (g:pgametyp;u:ptypunits;what:integer;out avl_mat,cost:integer);
procedure calc_build_params(speed,cost,avl_mat,mat_turn:integer;reverse,end_turn:boolean;out will_take_turns,will_mat,will_speed,will_cost:integer);
function  can_build        (g:pgametyp;u:ptypunits;what:string;reverse:boolean;res_mat,speed,x,y:integer):boolean;  
function  get_build_params (g:pgametyp;u:ptypunits;what,speed,reserve:integer;reverse:boolean;out res_time,res_cost:integer;cost_ovr:integer):boolean;
function  add_build        (g:pgametyp;u:ptypunits;what:string;reverse:boolean;res_mat,speed,x,y:integer):boolean;
procedure clear_build      (g:pgametyp;u:ptypunits);
//############################################################################// 
implementation
//############################################################################// 
procedure get_mat_avl_turn(g:pgametyp;u:ptypunits;what:integer;out avl_mat,cost:integer);
var b:ptypunitsdb;
c:integer;
p:pplrtyp;
cl:ptypclansdb;
begin       
 if not unav(u) then exit;
 b:=get_unitsdb(g,what); 
 if b=nil then exit;

 avl_mat:=0;

 cost:=b.bas.cost;
 if u.own<>-1 then begin
  c:=gettypclan(g,u.own,b.typ);
  p:=get_plr(g,u.own);
  cl:=get_clan(g,p.info.clan);
  if c<>-1 then cost:=cost+cl.unupd[c].bas.cost;
  cost:=cost+p.unupd[what].bas.cost;
 end;
 if u.bas.mat_turn<>0 then if cost mod u.bas.mat_turn<>0 then cost:=(cost div u.bas.mat_turn+1)*u.bas.mat_turn;
 if not isa(g,u,a_building) then avl_mat:=u.prod.now[RES_MAT];
 if isa(g,u,a_building) then avl_mat:=get_rescount(g,u,RES_MAT,GROP_AVL);
end;      
//############################################################################//
//Calculate build (Courtesy Hruks)
procedure calc_build_params(speed,cost,avl_mat,mat_turn:integer;reverse,end_turn:boolean;out will_take_turns,will_mat,will_speed,will_cost:integer);
const speed_by_index:array[1..3]of integer=(1,2,4);
index_by_speed:array[1..4]of integer=(1,2,0,3);
res_consume:array[1..3]of integer=(1,4,12); 
var count,                      //Count for resources consume speeds
maxI,                           //Maximum for each count
resSpent,                       //Resources spend per turn based on speed
resBuild:array[1..3]of integer; //Resources build per turn based on speed
i:integer;

//Fill only one array value and return 1 or 0 if build is possible
function GetCurrent(var will_mat:integer): integer;
var i:integer;
begin
 result:=0;
 for i:=1 to 3 do begin
  if(maxI[i]>0)and(cost<=resSpent[i])then begin
   result:=1;
   count[i]:=1;
   will_mat:=resSpent[i];
   break;
  end;
 end;
end;

//Fill count array and return sum of this array
function GetTurns(var will_mat:integer):integer;
var resNeeded:integer;    //resources needed for build
resNeededCurrent:integer; //resources spent for build
i1,i2,i4:integer;         //counters
turns:integer;
begin
 resNeeded:=MaxInt;
 turns:=MaxInt;
 for i4:=maxI[3] downto 0 do for i2:=maxI[2] downto 0 do begin
  i1:=(cost-i2*resBuild[2]-i4*resBuild[3]) div mat_turn;
  if i1<0 then i1:=0;
  resNeededCurrent:=i4*resSpent[3]+i2*resSpent[2]+i1*resSpent[1];
  if resNeededCurrent<=avl_mat then if (i4+i2+i1)<=turns then if resNeeded>=resNeededCurrent then begin
   resNeeded:=resNeededCurrent;
   count[1]:=i1;
   count[2]:=i2;
   count[3]:=i4;
   turns:=count[1]+count[2]+count[3];
  end;
 end;

 result:=count[1]+count[2]+count[3];
 if result>0 then will_mat:=resNeeded;
end;
  
begin
 speed:=index_by_speed[speed]; 
 if mat_turn=1 then speed:=1;
 if end_turn then cost:=mat_turn*res_consume[speed];    
 will_mat:=0; 
 will_take_turns:=0;  
 will_speed:=0;
 will_cost:=0;

 for i:=1 to 3 do begin
  count[i]:=0;
  resSpent[i]:=mat_turn*res_consume[i];
  resBuild[i]:=mat_turn*speed_by_index[i];
  maxI[i]:=0;
 end;

 //if speed>=3 then if resSpent[3]=0 then exit;
 //if speed>=2 then if resSpent[2]=0 then exit;
 //if speed>=1 then if resSpent[1]=0 then exit;

 if speed>=3 then maxI[3]:=avl_mat div resSpent[3];
 if speed>=2 then maxI[2]:=avl_mat div resSpent[2];
 if speed>=1 then maxI[1]:=avl_mat div resSpent[1];
 
 if avl_mat>=resSpent[1] then begin
  if end_turn then will_take_turns:=GetCurrent(will_mat)
              else will_take_turns:=GetTurns(will_mat);
 end;

 if reverse then begin for i:=1     to 3 do if count[i]>0 then begin will_speed:=speed_by_index[i];break;end;end
            else begin for i:=3 downto 1 do if count[i]>0 then begin will_speed:=speed_by_index[i];break;end;end;
  
 if will_speed<>0 then will_cost:=resBuild[index_by_speed[will_speed]];
 will_cost:=min2i(cost,will_cost);
end;      
//############################################################################//
//X=-1 - only check if materials are enough
//speed=-1 - only check position;
function can_build(g:pgametyp;u:ptypunits;what:string;reverse:boolean;res_mat,speed,x,y:integer):boolean;       
var cost,avl_mat,will_take_turns,will_mat,will_speed,will_cost,i:integer;
begin
 result:=false;
 if not unav(u) then exit;

 i:=getdbnum(g,what);
 if i=-1 then exit;
 if not can_u_build_n(g,u,i) then exit;
 if x<>-1 then if not test_pass_db(g,x,y,i,u) then exit;
 if speed=-1 then begin result:=true;exit;end;

 get_mat_avl_turn(g,u,i,avl_mat,cost);
 if isa(g,u,a_building) then begin
  calc_build_params(speed,cost,avl_mat,u.bas.mat_turn,reverse,true,will_take_turns,will_mat,will_speed,will_cost);
  if avl_mat<will_mat then exit;
  if will_take_turns=0 then exit;
 end else begin
  avl_mat:=avl_mat-res_mat;
  calc_build_params(speed,cost,avl_mat,u.bas.mat_turn,reverse,false,will_take_turns,will_mat,will_speed,will_cost);
  if avl_mat<will_mat then exit;
  if will_take_turns=0 then exit;
  if will_speed<>speed then exit;
 end;
 result:=true;
end;  
//############################################################################//   
function get_build_params(g:pgametyp;u:ptypunits;what,speed,reserve:integer;reverse:boolean;out res_time,res_cost:integer;cost_ovr:integer):boolean;
var cost,avl_mat,will_speed,will_cost:integer;
begin
 result:=false;

 get_mat_avl_turn(g,u,what,avl_mat,cost);
 avl_mat:=avl_mat-reserve;
 if isa(g,u,a_building) then avl_mat:=1000;

 if cost_ovr<>-1 then cost:=cost_ovr;

 calc_build_params(speed,cost,avl_mat,u.bas.mat_turn,reverse,false,res_time,res_cost,will_speed,will_cost);
 if res_cost=0 then res_cost:=cost;  
 if res_time=0 then begin res_time:=cost div u.bas.mat_turn+ord((cost mod u.bas.mat_turn)<>0);exit;end;
 if avl_mat<res_cost then exit;

 result:=true;
end;
//############################################################################//
procedure clear_build(g:pgametyp;u:ptypunits);
begin
 if not unav(u) then exit;
 u.builds_cnt:=0;
end;
//############################################################################//
function add_build(g:pgametyp;u:ptypunits;what:string;reverse:boolean;res_mat,speed,x,y:integer):boolean;
var b:ptypunitsdb;
r:pbuildrec;
cost,avl_mat,i,will_take_turns,will_mat,will_speed,will_cost:integer;
begin
 result:=false;   
 if not unav(u) then exit;
 if u.builds_cnt>=length(u.builds)-1 then exit;
 i:=getdbnum(g,what);            
 b:=get_unitsdb(g,i); 
 if b=nil then exit;
 if x>=0 then if not test_pass_db(g,x,y,i,u) then exit;

 get_mat_avl_turn(g,u,i,avl_mat,cost);
 if not isa(g,u,a_building) then begin
  avl_mat:=avl_mat-res_mat;
  u.reserve:=res_mat;
 end; 
 if x=-2 then cost:=u.builds[y].left_to_build;
 if cost mod u.bas.mat_turn<>0 then cost:=(cost div u.bas.mat_turn+1)*u.bas.mat_turn;
         
 r:=@u.builds[u.builds_cnt];
 if isa(g,u,a_building) then begin
  calc_build_params(speed,cost,10000,u.bas.mat_turn,reverse,false,will_take_turns,will_mat,will_speed,will_cost);    
  if will_take_turns=0 then exit;
 
  r.left_to_build:=cost;    
  r.left_mat:=will_mat;   
  r.cur_take:=will_cost; 
  r.left_turns:=will_take_turns;          
  r.cur_speed:=will_speed;    
  calc_build_params(will_speed,0,10000,u.bas.mat_turn,reverse,true,will_take_turns,will_mat,will_speed,will_cost);
  r.cur_use:=will_mat;
 end else begin
  calc_build_params(speed,cost,avl_mat,u.bas.mat_turn,reverse,false,will_take_turns,will_mat,will_speed,will_cost);    
  if avl_mat<will_mat then exit;
  if will_take_turns=0 then exit;
 
  r.left_to_build:=cost;    
  r.left_mat:=will_mat;   
  r.cur_take:=will_cost; 
  r.left_turns:=will_take_turns;  
  calc_build_params(speed,0,avl_mat,u.bas.mat_turn,reverse,true,will_take_turns,will_mat,will_speed,will_cost);      
  r.cur_speed:=will_speed; 
  r.cur_use:=will_mat;
 end;  
 r.typ:=what;
 r.typ_db:=i;
 r.reverse:=reverse;
 r.x:=x;
 r.y:=y;
 r.sz:=b.siz;
 r.rept:=false;       
 r.base:=-1;
 r.tape:=-1;
 r.cones:=-1;        
 r.given_speed:=speed; 
 result:=true;

 u.builds_cnt:=u.builds_cnt+1;
end;
//############################################################################// 
begin
end.
//############################################################################// 
