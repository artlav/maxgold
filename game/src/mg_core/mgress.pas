//############################################################################//
//Made by Artyom Litvinovich in 2003-2011
//MaxGold core resource handling
//############################################################################//
unit mgress;
interface
uses asys,maths,mgvars,mgrecs,mgauxi,mgl_common,mgl_attr,mgl_res,mgl_logs;     
//############################################################################//    
const                      
default_initial_res:res_info_rec=
(
 //material
 ( //MINE    CONC    NORM    DIFF
  ((10,10),( 8,12),( 0, 3),( 8, 0)), //R_POOR
  ((12,12),(13,16),( 1, 5),( 6, 0)), //R_MEDIUM
  ((14,14),(16,16),( 1, 5),( 4, 0))  //R_RICH
 ),
 //fuel
 ( //MINE    CONC    NORM    DIFF
  (( 7, 7),( 8,12),( 1, 2),( 8, 0)), //R_POOR
  (( 8, 8),(12,16),( 2, 3),( 6, 0)), //R_MEDIUM
  (( 9, 9),(16,16),( 2, 4),( 4, 0))  //R_RICH
 ),
 //gold
 ( //MINE    CONC    NORM    DIFF
  (( 0, 0),( 5, 9),( 0, 0),(12, 0)), //R_POOR
  (( 0, 0),( 8,12),( 0, 0),(10, 0)), //R_MEDIUM
  (( 1, 1),(12,16),( 0, 1),( 8, 0))  //R_RICH
 )
);
//############################################################################//
procedure initial_resource_placement(g:pgametyp;x,y:integer;fix:boolean);
procedure clear_resources(g:pgametyp);
procedure set_initial_resources(g:pgametyp);     
procedure refresh_domains(g:pgametyp); 
function  put_res_now(g:pgametyp;ut:ptypunits;rtyp,amt:integer;temp:boolean):integer;
procedure return_debt(g:pgametyp;ut:ptypunits;rtyp,amt:integer);       
procedure autolevel_res(g:pgametyp;u:ptypunits);
function  take_res_now_minding(g:pgametyp;ut:ptypunits;rtyp,amt:integer;temp:boolean=false):boolean;  
function  take_debt(g:pgametyp;ut:ptypunits;rtyp,amt:integer;start:boolean;except_for:ptypunits;temp:boolean):integer;
function  res_stop_lacking(g:pgametyp;ut:ptypunits;rtyp,amt:integer):boolean;
procedure calc_mining(g:pgametyp;own:integer;temp:boolean);    
procedure do_rebalance(g:pgametyp;u,sub:ptypunits);  
procedure rebalance_around(g:pgametyp;x,y,siz:integer;sub:ptypunits); 
function  res_endturn(g:pgametyp;own:integer;temp:boolean):boolean;     
procedure res_to_temp(g:pgametyp;dom:integer;do_mining:boolean);
//############################################################################// 
implementation
//############################################################################//
const
rptb1:array[0..3+4]of array[0..1]of integer=((0,-1),(-1,0),(0,1),(1,0),(-1,-1),(1,-1),(-1,1),(1,1));
rptb2:array[0..7+4]of array[0..1]of integer=((0,-1),(-1,0),(0,2),(2,0),(1,-1),(-1,1),(1,2),(2,1),(-1,-1),(2,-1),(-1,2),(2,2));
//############################################################################//
//############################################################################//
function celltp(x,y:integer):integer;
begin
 if y mod 2=0 then begin
  if x mod 2=0 then result:=2 else result:=0;
 end else begin        
  if x mod 2=0 then result:=3 else result:=1;
 end;
end;     
//############################################################################//
function get_amt(g:pgametyp;typ:integer;mode:integer):integer;
var r1,r2:integer;
begin
 if typ=0 then begin result:=0;exit;end;
 r1:=g.initial_res[typ-1,g.info.rules.res_levels[typ],mode,P_MIN];
 r2:=g.initial_res[typ-1,g.info.rules.res_levels[typ],mode,P_MAX];
 result:=r1+mgrandom_int(g,r2-r1+1);
end;
//############################################################################//
function get_dif(g:pgametyp;typ:integer):integer;
begin
 if typ=0 then begin result:=0;exit;end;
 result:=g.initial_res[typ-1,g.info.rules.res_levels[typ],M_DIFFUSION,P_MIN];
end;
//############################################################################//
function getrescell(g:pgametyp;x,y:integer;out r:presrec):boolean;
begin
 result:=false;
 if(x<0)or(y<0)or(x>=g.info.mapx)or(y>=g.info.mapy)then exit;
 r:=@g.resmap[x+y*g.info.mapx];
 result:=true;
end;
//############################################################################//
function getrescell_amt(g:pgametyp;x,y:integer):integer;
var r:presrec;
begin
 if getrescell(g,x,y,r) then result:=r.amt
                        else result:=0;
end;
//############################################################################//
//Resource distribution
//Needs fixing resource separation and diffusion
procedure initial_resource_placement(g:pgametyp;x,y:integer;fix:boolean);
var r:presrec;
i,j,typ,amt:integer;
begin
 if(x<0)or(y<0)or(x>=g.info.mapx)or(y>=g.info.mapy)then exit;

 if fix then begin
  //find material place (center of new resource placement)
  for i:=0 to 1 do for j:=0 to 1 do if celltp(x+i,y+j)=1 then begin
   initial_resource_placement(g,x+i,y+j,false);
   break;
  end;

  for i:=0 to 1 do for j:=0 to 1 do if getrescell(g,x+i,y+j,r) then begin
   r.typ:=celltp(x+i,y+j);
   amt:=get_amt(g,r.typ,M_MINE);
   if amt>0 then r.amt:=amt-1 else r.typ:=0;
  end;
 end else begin
  if getrescell(g,x,y,r) then begin
   typ:=r.typ;
   r.typ:=celltp(x,y);
   amt:=get_amt(g,r.typ,M_CONCENTRATE);
   if typ<>0 then amt:=round((r.amt+1+amt)/2);
   if amt>0 then r.amt:=amt-1 else r.typ:=0;
  end;

  for i:=-1 to 1 do for j:=-1 to 1 do if (i<>0)or(j<>0) then if getrescell(g,x+i,y+j,r) then begin
   typ:=r.typ;
   r.typ:=celltp(x+i,y+j);
   amt:=get_amt(g,r.typ,M_NORMAL);
   if typ<>0 then amt:=round((r.amt+1+amt)/2);
   if amt>0 then r.amt:=amt-1 else r.typ:=0;
  end;
 end;
end;
//############################################################################//
procedure clear_resources(g:pgametyp);
var i:integer;
begin try
 setlength(g.resmap,g.info.mapx*g.info.mapy);
 for i:=0 to g.info.mapx*g.info.mapy-1 do begin
  g.resmap[i].amt:=0;
  g.resmap[i].typ:=0;
 end;
 except stderr('Resman','clear_resources');end;
end;
//############################################################################//
procedure set_initial_resources(g:pgametyp);
var i,tp,resmax,x,y,x1,y1,d,okmax:integer;
is_ok:boolean;
rescount:array[1..3] of integer;
begin try
 clear_resources(g);
 resmax:=round(g.info.rules.resset*((g.info.mapx*g.info.mapy)/(112*112)));
 rescount[2]:=round(resmax*0.40);            //40% of fuel
 rescount[3]:=round(resmax*0.15);            //15% of gold
 rescount[1]:=resmax-rescount[2]-rescount[3];//45% of metal

 for i:=1 to resmax do begin
  for tp:=1 to 3 do begin
   if rescount[tp]>0 then begin
    okmax:=60;
    repeat
     //fuel cell by default
     x:=mgrandom_int(g,g.info.mapx div 2)*2;
     y:=mgrandom_int(g,g.info.mapy div 2)*2;
     case tp of
      1:begin x:=x+1;y:=y+1;end;//metal
      2:begin end;//fuel
      3:begin y:=y+1;end;//gold
     end;
     is_ok:=inrm(g,x,y);
     //check resource placement for obstacles
     if is_ok then for x1:=x-1 to x+1 do for y1:=y-1 to y+1 do if inrm(g,x1,y1) and(get_map_pass(g,x1,y1)=P_OBSTACLE) then is_ok:=false;
     //check around cells for same res
     if is_ok then begin
      d:=get_dif(g,tp);
      if okmax<20 then d:=d div 2;
      if okmax<10 then d:=d div 2;
      if d=0 then d:=1;
      if okmax>0 then for x1:=-d to +d do for y1:=-d to +d do if inrm(g,x+x1*2,y+y1*2)and(getrescell_amt(g,x+x1*2,y+y1*2)>=7)then is_ok:=false;
      dec(okmax);
     end;
    until(is_ok)and((y mod 2<>0)or(x mod 2=0));
    rescount[tp]:=rescount[tp]-1;
    initial_resource_placement(g,x,y,false);
   end;
  end;
 end;
 except stderr('Resman','set_initial_resources');end;
end;
//############################################################################//
//############################################################################//
//Resource processing - get next linked unit
//tp=0 - cross
//tp=1 - and diagonal + units
function next_recurse_unit(g:pgametyp;u:ptypunits;var looked:aoboolean;tp:integer=0):ptypunits;
var j,x,y,k,kx,ky:integer;
ut:ptypunits;
begin try
 result:=nil;
 x:=u.x;
 y:=u.y;
 if u.siz=1 then for k:=0 to 3+ord(tp=1)*4 do begin
  kx:=x+rptb1[k][0];ky:=y+rptb1[k][1];
  for j:=0 to get_unu_length(g,kx,ky)-1 do begin   //get_unu_length takes care of the bounds
   ut:=get_unu(g,kx,ky,j);
   if unav(ut) then if not looked[ut.num] then begin
    if ut.own<>u.own then continue;
    if tp=0 then if isa(g,ut,a_passes_res) then begin result:=ut;exit;end;
    if tp=1 then if ((isa(g,ut,a_passes_res) and isa(g,u,a_passes_res))or((not isa(g,ut,a_passes_res)) and (isa(g,u,a_passes_res)))) then begin result:=ut;exit;end;
   end;
  end;
 end;
 if u.siz=2 then for k:=0 to 7+ord(tp=1)*4 do begin
  kx:=x+rptb2[k][0];ky:=y+rptb2[k][1];
  for j:=0 to get_unu_length(g,kx,ky)-1 do begin
   ut:=get_unu(g,kx,ky,j);
   if unav(ut) then if not looked[ut.num] then begin
    if ut.own<>u.own then continue;
    if tp=0 then if isa(g,ut,a_passes_res) then begin result:=ut;exit;end;
    if tp=1 then if ((isa(g,ut,a_passes_res) and isa(g,u,a_passes_res))or((not isa(g,ut,a_passes_res)) and (isa(g,u,a_passes_res)))) then begin result:=ut;exit;end;
   end;
  end;
 end;

 except result:=nil;stderr('Resman','next_recurse_unit');end;
end;
//############################################################################// 
function refresh_domains_loop(g:pgametyp;var looked:aoboolean;u:ptypunits;dom:integer):boolean;
var nx:ptypunits;
begin
 result:=false;     
 if u=nil then exit;
 looked[u.num]:=true;
 if u.domain<>dom then mark_unit(g,u.num);
 u.domain:=dom;
 
 if isa(g,u,a_passes_res) then repeat
  nx:=next_recurse_unit(g,u,looked,0);
  if nx<>nil then refresh_domains_loop(g,looked,nx,dom);
 until nx=nil;
end;
//############################################################################//
//Update linkage
//FIXME: Make less brute-force
procedure refresh_domains(g:pgametyp);
var i,last_dom:integer;
looked:aoboolean;
u:ptypunits;
begin try
 last_dom:=-1;
 setlength(looked,get_units_count(g));
 for i:=0 to get_units_count(g)-1 do begin
  looked[i]:=false;
  u:=get_unit(g,i);
  if u<>nil then u.domain:=-1;
 end;
 for i:=0 to get_units_count(g)-1 do begin
  u:=get_unit(g,i);
  if u<>nil then if not looked[i] then if isa(g,u,a_resource_domainable) then begin
   last_dom:=last_dom+1;
   refresh_domains_loop(g,looked,u,last_dom);
  end;
 end;
 g.state.domains_cnt:=last_dom+1;

 except stderr('Resman','refresh_domains');end;
end;
//############################################################################// 
//Add immediate resources to complex
function put_res_now(g:pgametyp;ut:ptypunits;rtyp,amt:integer;temp:boolean):integer;
var i,dom:integer;  
u:ptypunits;     
p:pprodrec;  
begin result:=amt; try  
 if amt=0 then exit;
 if not(rtyp in [1..5])then exit;
 if not unav(ut) then exit;    

 dom:=ut.domain;
 //Unit
 if dom=-1 then begin
  p:=@ut.prod;  
  if(p.num[rtyp]=0)or(p.num[rtyp]=p.now[rtyp])then exit;  
  if p.now[rtyp]<p.num[rtyp] then begin
   if p.num[rtyp]-p.now[rtyp]>=result then begin
    p.now[rtyp]:=p.now[rtyp]+result;   
    mark_unit(g,ut.num);
    result:=0;
    exit;
   end else begin
    result:=result-(p.num[rtyp]-p.now[rtyp]);
    p.now[rtyp]:=p.num[rtyp];  
    mark_unit(g,ut.num);
    exit;
   end;
  end;  
 //Building
 end else for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if u.domain<>dom then continue;
  if temp then p:=@u.prod_temp else p:=@u.prod;  
  
  if(p.num[rtyp]=0)or(p.num[rtyp]=p.now[rtyp])then continue;
  if p.now[rtyp]<p.num[rtyp] then begin
   if p.num[rtyp]-p.now[rtyp]>=result then begin
    p.now[rtyp]:=p.now[rtyp]+result;  
    mark_unit(g,u.num);
    result:=0;
    break;
   end else begin
    result:=result-(p.num[rtyp]-p.now[rtyp]);
    p.now[rtyp]:=p.num[rtyp];   
    mark_unit(g,u.num);
    continue;
   end;
  end;
 end;
 except stderr('Resman','put_res_now');end;
end;
//############################################################################// 
//Subtracts resource debt from the complex
procedure return_debt(g:pgametyp;ut:ptypunits;rtyp,amt:integer);     
var i,dom,at:integer;  
u:ptypunits;     
p:pprodrec;  
begin try  
 if not unav(ut) then exit;    
 if not(rtyp in [1..5])then exit;  
 at:=amt;
 if at=0 then exit; 
     
 dom:=ut.domain;
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin  
  if dom=-1 then if i<>ut.num then continue;
  u:=get_unit(g,i);
  if u.domain<>dom then continue;
  p:=@u.prod;  
   
  if p.dbt[rtyp]=0 then continue;
  if p.dbt[rtyp]>0 then begin
   if p.dbt[rtyp]>=at then begin
    p.dbt[rtyp]:=p.dbt[rtyp]-at;
    break;
   end else begin
    at:=at-p.dbt[rtyp];
    p.dbt[rtyp]:=0;
    continue;
   end;
  end;
 end;

 except stderr('Resman','return_debt');end;
end;
//############################################################################// 
//Take immediate resources from complex
//Checks for debt depletion, takes action
function take_res_now_minding(g:pgametyp;ut:ptypunits;rtyp,amt:integer;temp:boolean=false):boolean;
var i,dom,at:integer;  
u:ptypunits;     
p:pprodrec;  
begin result:=false; try  
 if not unav(ut) then exit;    
 if not(rtyp in [1..5])then exit;  
 if amt=0 then exit; 
 at:=amt;
      
 dom:=ut.domain;

 if get_rescount(g,ut,rtyp,GROP_NOW,temp)<amt then exit; 
 result:=true;

 if dom=-1 then begin
  p:=@ut.prod;
  if p.now[rtyp]>=at then begin
   p.now[rtyp]:=p.now[rtyp]-at;
   p.dbt[rtyp]:=p.dbt[rtyp]-at;
   mark_unit(g,ut.num);
   if p.dbt[rtyp]<0 then p.dbt[rtyp]:=0;
  end else result:=false;
 end else for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if u.domain<>dom then continue;
  if temp then p:=@u.prod_temp else p:=@u.prod;  
   
  if(p.num[rtyp]=0)or(p.now[rtyp]=0)then continue;
  if p.now[rtyp]>0 then begin
   if p.now[rtyp]>=at then begin
    p.now[rtyp]:=p.now[rtyp]-at;
    p.dbt[rtyp]:=p.dbt[rtyp]-at;        
    mark_unit(g,u.num);
    if p.dbt[rtyp]<0 then p.dbt[rtyp]:=0;
    //at:=0;
    break;
   end else begin
    at:=at-p.now[rtyp];
    p.now[rtyp]:=0;  
    p.dbt[rtyp]:=0;   
    mark_unit(g,u.num);
    continue;
   end;
  end;
 end; 

 do_rebalance(g,ut,nil);
 //dbt:=-get_rescount(un,rtyp,GROP_AVLABS);
 //if dbt>0 then res_stop_lacking(un,rtyp,take_debt(un,rtyp,take_debt(un,rtyp,dbt,false,-1,false),true,un,false)); 
 
 except stderr('Resman','takeres');end;
end;
//############################################################################//
//Take resource debt from complex, starting if needed
function take_debt(g:pgametyp;ut:ptypunits;rtyp,amt:integer;start:boolean;except_for:ptypunits;temp:boolean):integer;
var i,s,dom,at:integer;  
u:ptypunits;     
p:pprodrec;  
begin result:=0; try  
 if not unav(ut) then exit;    
 if not(rtyp in [1..5])then exit;  
 if amt=0 then exit; 
 at:=amt;  
      
 dom:=ut.domain;
 for s:=0 to 1 do begin
  if(s=1)and(at=0)then break;
  for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin          
   if dom=-1 then if i<>ut.num then continue;
   u:=get_unit(g,i);
   if u.domain<>dom then continue;
   if temp then p:=@u.prod_temp else p:=@u.prod;  

   if(s=1)and start then 
    if(p.pro[rtyp]>0)and(except_for<>u)and(not u.isact) then 
     istartunit(g,u,false,true);

   if(p.pro[rtyp]*ord(u.isact)+p.now[rtyp]=0)then continue;
   if(p.pro[rtyp]*ord(u.isact)+p.now[rtyp]>p.dbt[rtyp])then begin
    if p.pro[rtyp]*ord(u.isact)+p.now[rtyp]-p.dbt[rtyp]>=at then begin
     p.dbt[rtyp]:=p.dbt[rtyp]+at;
     at:=0;
     break;
    end else begin
     at:=at-(p.pro[rtyp]*ord(u.isact)+p.now[rtyp]-p.dbt[rtyp]);
     p.dbt[rtyp]:=p.pro[rtyp]*ord(u.isact)+p.now[rtyp];
     continue;
    end;
   end;
   
  end; 
 end;
  
 result:=at;
  
 except stderr('Resman','takeres');end;
end;
//############################################################################// 
//Stop units for amt worth of resource rtyp
function res_stop_lacking(g:pgametyp;ut:ptypunits;rtyp,amt:integer):boolean;   
var i,j,dom,at:integer;  
u:ptypunits; 
ud:ptypunitsdb;    
p:pprodrec;  
begin result:=false; try  
 if not unav(ut) then exit;    
 if not(rtyp in [1..5])then exit;  
 if amt=0 then exit;
 at:=amt;
      
 dom:=ut.domain;

 for j:=0 to 9 do for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin     
  if dom=-1 then if i<>ut.num then continue;
  u:=get_unit(g,i);
  ud:=get_unitsdb(g,u.dbn);
  if u.domain<>dom then continue;
  if ud.priority<>j then continue;
  p:=@u.prod;  
   
  if(p.use[rtyp]=0)or(not u.isact)then continue;
  if p.use[rtyp]>=at then begin
   istopunit(g,u,false,true);    //FIXME: Look for unforseen consequences of autoleveling a potentially unbalanced domain
   result:=true;
   add_log_msgu(g,u.own,lmt_no_resources,u,nil,rtyp);
   exit;
  end else begin
   at:=at-p.use[rtyp];  
   istopunit(g,u,false,true);    //FIXME: Look for unforseen consequences of autoleveling a potentially unbalanced domain
   result:=true;
   add_log_msgu(g,u.own,lmt_no_resources,u,nil,rtyp);
   continue;
  end; 
 end; 
  
 except stderr('Resman','res_stop_lacking');end;
end;   
//############################################################################//  
//Rebalance the domain, "Obnovlenie"
//No need to recurse for chained situations.
//
//      G G
//      |-|
//     MM MM
//     MM MM
//3 fuel   1 fuel
//
//With left generator blown:
//When lack of power stops left mining it would check if it was supplying anything (in stopunit)
//Thus, right generator would stop, checking if it was supplying something
//Thus second mine stops.
//
//Suboptimal, but bug-free
procedure do_rebalance(g:pgametyp;u,sub:ptypunits);  
var avl,ri,amd:integer;
begin
 if not unav(u) then exit;
 if isa(g,u,a_resource_domainable) then for ri:=RES_MIN to RES_MAX do begin
  avl:=get_rescount(g,u,ri,GROP_BAL);                                             //Consumption minus debt
  if avl>0 then begin                                                           //Try to allocate more debt, starting producer units if needed. Stop consumer units for excess that cannot be allocated
   amd:=take_debt(g,u,ri,avl,true,sub,false);
   res_stop_lacking(g,u,ri,amd);
  end;
  if avl<0 then return_debt(g,u,ri,-avl);                                         //Else free excessive debt
 end;
end;
//############################################################################//
//Resource rebalancing, "Obnovlenie", for everyone around a given position and size
procedure rebalance_around(g:pgametyp;x,y,siz:integer;sub:ptypunits);
var i:integer;
begin 
 if not inrm(g,x,y) then exit;
 case siz of
  1:for i:=0 to 3 do if get_unu_length(g,x+rptb1[i][0],y+rptb1[i][1])<>0 then do_rebalance(g,get_unu(g,x+rptb1[i][0],y+rptb1[i][1],0),sub);
  2:for i:=0 to 7 do if get_unu_length(g,x+rptb2[i][0],y+rptb2[i][1])<>0 then do_rebalance(g,get_unu(g,x+rptb2[i][0],y+rptb2[i][1],0),sub);
 end;  
end;
//############################################################################// 
procedure autolevel_stopifidle(g:pgametyp;u,ut:ptypunits;dom:integer);
begin  
 if not unav(u) then exit;
 if u.domain<>dom then exit;

 if not u.isact then exit;
 if isa(g,u,a_always_active)or u.isbuild or isa(g,u,a_mining)then exit;
 if(u.prod.pro[RES_MAT]=0)and(u.prod.pro[RES_FUEL]=0)and(u.prod.pro[RES_GOLD]=0)and(u.prod.pro[RES_POW]=0)and(u.prod.pro[RES_HUMAN]=0)then exit;
 if(u.prod.dbt[RES_MAT]<>0)or(u.prod.dbt[RES_FUEL]<>0)or(u.prod.dbt[RES_GOLD]<>0)or(u.prod.dbt[RES_POW]<>0)or(u.prod.dbt[RES_HUMAN]<>0)then exit;

 //The unit have no debts, have production and is active
 //This assumes that nothing can produce storeable resources but mining
 //And that nothing producing non-storables is doing anything else useful
 if u.num<>ut.num then istopunit(g,u,false,true);  //Do not recurse autolevel_res!
end;
//############################################################################// 
{
procedure autolevel_shuffle_power(i,un,dom:integer);
var u:ptypunits;  
me,avl:
begin  
 if not unav(i) then exit;
 u:=get_unit(g,i);
 if u.domain<>dom then exit;
 
 if not u.isact then exit;
 if isa(g,u,a_always_active)or u.isbuild or isa(g,u,a_mining)then exit;
 
 if u.prod.pro[RES_POW]=0 then exit;

end;
}
//############################################################################// 
//Stop units without load
procedure autolevel_res(g:pgametyp;u:ptypunits);
var i,dom:integer;  
begin try  
 if not unav(u) then exit;    
 dom:=u.domain;
 for i:=0 to get_units_count(g)-1 do autolevel_stopifidle(g,get_unit(g,i),u,dom);
 //for i:=0 to get_units_count(g)-1 do autolevel_shuffle_power(g,i,un,dom);
 //for i:=0 to get_units_count(g)-1 do autolevel_stopifidle(g,i,un,dom);

 except stderr('Resman','autolevel_res');end;
end;
//############################################################################// 
//Calculate mining
//Needed only once, and when switching to temp
procedure calc_mining(g:pgametyp;own:integer;temp:boolean);
var i,x,y,ri:integer;
res:array[RES_MINING_MIN..RES_MINING_MAX] of byte;
r:presrec;
p:pprodrec;
u:ptypunits;
begin try   
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin 
  u:=get_unit(g,i);
  if(u.own=own)and isa(g,u,a_mining)then begin
   for ri:=RES_MINING_MIN to RES_MINING_MAX do res[ri]:=0;
   for x:=u.x to u.x+u.siz-1 do for y:=u.y to u.y+u.siz-1 do if getrescell(g,x,y,r)and(r.typ<>RES_NONE)then res[r.typ]:=res[r.typ]+r.amt+1;
   p:=@u.prod;
   if temp then p:=@u.prod_temp;
   for ri:=RES_MINING_MIN to RES_MINING_MAX do begin
    if p.mining[ri]>res[ri] then p.mining[ri]:=res[ri];
    p.pro[ri]:=min2i(res[ri],p.mining[ri]); 
    mark_unit(g,u.num);
   end;
  end;
 end;
 except stderr('Resman','calc_mining');end;
end;                
//############################################################################// 
procedure mining_to_temp(g:pgametyp);
var i:integer;
begin
 for i:=0 to get_plr_count(g)-1 do calc_mining(g,i,true);
end;
//############################################################################// 
//Actualize temporary scheme
procedure res_to_temp(g:pgametyp;dom:integer;do_mining:boolean);
var i:integer;
u:ptypunits;
begin
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if(u.domain=dom)then u.prod_temp:=u.prod;
 end;
 if do_mining then mining_to_temp(g);
end;
//############################################################################//
//Calculate end turn for buildings
function res_endturn(g:pgametyp;own:integer;temp:boolean):boolean;
var i,ri:integer;    
u:ptypunits;  
p:pprodrec;
excess:integer;
unitmp,domtmp:array of integer;
unicnt:integer;
pl:pplrtyp;
begin 
 result:=true;

 //Enumerate units and domains to be checked
 unicnt:=0;
 setlength(unitmp,get_units_count(g));
 setlength(domtmp,g.state.domains_cnt);
 for i:=0 to g.state.domains_cnt-1 do domtmp[i]:=-1;
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if(u.own=own)and isa(g,u,a_resource_domainable) then begin
   unitmp[unicnt]:=i;
   unicnt:=unicnt+1;
   if u.domain<>-1 then if domtmp[u.domain]=-1 then domtmp[u.domain]:=i;
  end;
 end;
 if temp then begin
  for i:=0 to g.state.domains_cnt-1 do res_to_temp(g,i,false);
  mining_to_temp(g);
 end;

 //Do the action
 for i:=0 to unicnt-1 do begin
  u:=get_unit(g,unitmp[i]);
  if temp then p:=@u.prod_temp else p:=@u.prod;
   
  //Step one - produce all 
  for ri:=RES_MIN to RES_MAX do p.now[ri]:=p.now[ri]+p.pro[ri]*ord(u.isact);
  //Refined gold
  if(not temp)and(u.own<>-1)and(p.refined_gold_pro*ord(u.isact)>0)then begin
   pl:=get_plr(g,u.own);
   pl.gold:=pl.gold+p.refined_gold_pro; 
  end;
        
  //Step two - debt relif 
  for ri:=RES_MIN to RES_MAX do begin
   p.now[ri]:=p.now[ri]-p.dbt[ri];
   p.dbt[ri]:=0;
   if p.now[ri]<0 then begin 
    //Something is wrong.
    //In M.A.X. original that would be what happens if we transfer resources out of a base and a factory finds itself without supply.
    //In M.A.X.G. this should no longer happen.
    result:=false;
    add_log_msgu(g,u.own,lmt_no_resources,u,nil,1);      
    do_rebalance(g,u,nil);
   end;
  end;
 end; 
 
 //Step three - truncate excess, reset usage
 for i:=0 to unicnt-1 do begin
  u:=get_unit(g,unitmp[i]);
  if temp then p:=@u.prod_temp else p:=@u.prod;

  for ri:=RES_MIN to RES_MAX do begin
   if p.now[ri]>p.num[ri] then begin
    excess:=p.now[ri]-p.num[ri];
    p.now[ri]:=p.num[ri];
    put_res_now(g,u,ri,excess,temp);
   end;
   if not temp then if(p.use[ri]<>0)and(p.next_use[ri]=0)then u.isact:=false;  //FIXME: Construction complete, a bit hackish
   p.use[ri]:=p.next_use[ri];
  end;
 end;
 
 //Step 4 - rebalance all
 for i:=0 to g.state.domains_cnt-1 do if domtmp[i]<>-1 then do_rebalance(g,get_unit(g,domtmp[i]),nil);
end;
//############################################################################//
begin
end.   
//############################################################################//