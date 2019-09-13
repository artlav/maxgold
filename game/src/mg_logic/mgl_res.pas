//############################################################################//
unit mgl_res;
interface        
uses mgrecs,mgl_common,mgl_attr;
//############################################################################//  
const      
GROP_NOW    =0;
GROP_MAX    =1;
GROP_NEED   =2;
GROP_MAXNEED=3;
GROP_MAXAVL =4;
GROP_AVL    =5;
GROP_PRO    =6;
GROP_DBT    =7;
GROP_BAL    =8;
GROP_MINING =9;
GROP_AVLABS =10;
//############################################################################//   
function get_rescount(g:pgametyp;ut:ptypunits;rtyp,op:integer;temp:boolean=false):integer; 
   
function is_something_to_transfer(g:pgametyp;ua,ub:ptypunits):boolean;
function is_have_something_to_transfer(g:pgametyp;u:ptypunits):boolean;
function is_have_material_to_transfer(g:pgametyp;u:ptypunits):boolean;       
//############################################################################// 
implementation 
//############################################################################// 
//Get parameters of a domain
function get_rescount(g:pgametyp;ut:ptypunits;rtyp,op:integer;temp:boolean=false):integer;
var i,dom:integer;   
p:pprodrec;  
u:ptypunits;
begin 
 result:=0;
 if not unav(ut) then exit;    
 if not(rtyp in [1..5])then exit;
 dom:=ut.domain;
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  if dom=-1 then if i<>ut.num then continue;
  u:=get_unit(g,i);
  if u.domain<>dom then continue;
  if temp then p:=@u.prod_temp else p:=@u.prod;  
  case op of
   //Get now present resources of the complex
   GROP_NOW    :if p.num[rtyp]>0 then result:=result+p.now[rtyp];  
   //Get maximum for resources of the complex
   GROP_MAX    :if p.num[rtyp]>0 then result:=result+p.num[rtyp];  
   //Get need for resources of the complex 
   GROP_NEED   :if u.isact then result:=result+p.use[rtyp]; 
   //Get maximum need for resources of the complex
   GROP_MAXNEED:result:=result+p.use[rtyp];
   //Get maximum available resources of the complex
   GROP_MAXAVL :if(p.num[rtyp]>0)or(p.pro[rtyp]>0) then result:=result+p.num[rtyp]+p.pro[rtyp];
   //Get available resources of the complex
   GROP_AVL,GROP_AVLABS:if p.num[rtyp]+p.pro[rtyp]*ord(u.isact)>0 then result:=result+p.now[rtyp]-p.dbt[rtyp]+p.pro[rtyp]*ord(u.isact);
   //Get resource production of the complex
   GROP_PRO    :if u.isact then result:=result+p.pro[rtyp];
   //Get debt of the complex
   GROP_DBT    :result:=result+p.dbt[rtyp];   
   //Get balancing resources of the complex
   GROP_BAL    :result:=result+p.use[rtyp]*ord(u.isact)-p.dbt[rtyp];
   //Get mining in the complex
   GROP_MINING :if isa(g,u,a_mining) then result:=result+p.mining[rtyp];
  end;
 end;
 if op in [GROP_DBT,GROP_AVL] then if result<0 then result:=0;
end;        
//############################################################################//
function is_something_to_transfer(g:pgametyp;ua,ub:ptypunits):boolean;
var ri:integer;  
rul:prulestyp;
begin
 result:=false;   
 rul:=get_rules(g);
 if(not unav(ua))or(not unav(ub))then exit;
 if isa(g,ua,a_build_not_building) then exit;
 if isa(g,ub,a_build_not_building) then exit;
 if isa(g,ua,a_disabled)then exit;
 if isa(g,ub,a_disabled)then exit;

 for ri:=RES_MINING_MIN to RES_MINING_MAX do if(ua.prod.num[ri]<>0)and(ub.prod.num[ri]<>0)then result:=true;
 if rul.fuelxfer and rul.fueluse then if(ua.bas.fuel<>0)and(ub.bas.fuel<>0)and(((ua.ptyp<>PT_AIR)and(ub.ptyp<>PT_AIR))or(ua.ptyp=ub.ptyp))then result:=true;
     
 for ri:=RES_MINING_MIN to RES_MINING_MAX do begin
  if(ua.prod.num[ri]=0)and isa(g,ua,a_building)and isa(g,ua,a_passes_res)and(ub.prod.num[ri]<>0)and(not isa(g,ub,a_building))then result:=true;
  if(ub.prod.num[ri]=0)and isa(g,ub,a_building)and isa(g,ub,a_passes_res)and(ua.prod.num[ri]<>0)and(not isa(g,ua,a_building))then result:=true;
 end; 
end;
//############################################################################//
function is_have_something_to_transfer(g:pgametyp;u:ptypunits):boolean;
var ri:integer;  
rul:prulestyp;
begin
 result:=false;  
 rul:=get_rules(g);
 if not unav(u) then exit;
 if isa(g,u,a_build_not_building) then exit;
 if isa(g,u,a_disabled)then exit;

 for ri:=RES_MINING_MIN to RES_MINING_MAX do if(u.prod.num[ri]<>0)then result:=true;
 if rul.fuelxfer and rul.fueluse then if(u.bas.fuel<>0)then result:=true;

 if isa(g,u,a_building)and isa(g,u,a_passes_res) then for ri:=RES_MINING_MIN to RES_MINING_MAX do if(get_rescount(g,u,ri,GROP_MAX)<>0)then result:=true;
end;
//############################################################################//
function is_have_material_to_transfer(g:pgametyp;u:ptypunits):boolean;         
var rul:prulestyp;
begin
 result:=false;    
 rul:=get_rules(g);
 if not unav(u) then exit;
 if isa(g,u,a_build_not_building) then exit;
 if isa(g,u,a_disabled)then exit;

 if(u.prod.num[RES_MAT]<>0)then result:=true;
 if rul.fuelxfer and rul.fueluse then if(u.bas.fuel<>0)then result:=true;

 if isa(g,u,a_building)and isa(g,u,a_passes_res) then if(get_rescount(g,u,RES_MAT,GROP_MAX)<>0)then result:=true;
end;
//############################################################################//
begin
end.     
//############################################################################//