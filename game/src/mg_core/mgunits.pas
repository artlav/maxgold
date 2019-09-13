//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core Units handling functions
//############################################################################//
unit mgunits;
interface
uses sysutils,asys,maths,strval,mgrecs,sds_rec,mgvars,mgauxi,mgress,mgl_logs,mgl_common,mgl_attr,mgl_scan,mgl_upgcalc,mgl_stats,mgl_tests,mgl_unu;
//############################################################################//
procedure clear_motion(g:pgametyp;u:ptypunits;and_build:boolean);

procedure rm_connectors(g:pgametyp;x,y:integer);

function landing_detect_intersect(g:pgametyp):boolean;

function  create_unit(g:pgametyp;typ:string;x,y,owner:integer;incr_count:boolean=true):ptypunits;
procedure delete_unit(g:pgametyp;u:ptypunits;delete_in_cell,remove_scan:boolean;no_plane_mine_check:boolean=true;dont_stop:boolean=false);
function  place_full_unit(g:pgametyp;typ:string;x,y,own:integer):ptypunits;

procedure trigger_autofire(g:pgametyp;u:ptypunits);
procedure set_detected_stealth(g:pgametyp;u:ptypunits;by:integer);
procedure boom_unit(g:pgametyp;u:ptypunits);

function  land_player(g:pgametyp;lnd:pplayer_start_rec):boolean;
procedure land_one_player(g:pgametyp;pn:integer);

procedure update_research(g:pgametyp);

procedure unit_newpos(g:pgametyp;u:ptypunits;x,y:integer;kind:integer=1);
procedure do_xfer(g:pgametyp;ua,ub:ptypunits;cnt:pinta);
procedure dbg_place_unit(g:pgametyp;xns,yns,j:integer;p:boolean);
//############################################################################//
implementation
//############################################################################//
//Get free units slot
function getfreeunit(g:pgametyp):integer;
var i:integer;
begin try
 for i:=0 to get_units_count(g)-1 do if g.units[i]=nil then begin
  result:=i;
  exit;
 end;

 result:=length(g.units);
 setlength(g.units,result+1);
 g.units[result]:=nil;

 except result:=-1;stderr('Units','GetFreeUnit');end;
end;
//############################################################################//
procedure clear_motion(g:pgametyp;u:ptypunits;and_build:boolean);
begin
 u.pstep:=0;
 u.plen:=0;
 setlength(u.path,0);
 u.is_moving:=false;
 if and_build then u.is_moving_build:=false;
 u.is_moving_now:=false;
 u.isstd:=false;
 mark_unit(g,u.num);
end;
//############################################################################//
//Creation of unit
function create_unit(g:pgametyp;typ:string;x,y,owner:integer;incr_count:boolean=true):ptypunits;
var i,n,k,cn,ri:integer;
eud:typ_unupd;
clp:ptyp_unupd;
u:ptypunits;
ud:ptypunitsdb;
p:pplrtyp;
begin result:=nil; try
 ud:=nil;
 for n:=0 to get_unitsdb_count(g)-1 do begin
  ud:=get_unitsdb(g,n);
  if ud.typ=typ then break;
 end;
 if ud=nil then exit;

 clp:=@eud;
 typ:=lowercase(typ);
 fillchar(eud,sizeof(eud),0);eud.typ:='';
 i:=getfreeunit(g);
 if i=-1 then exit;

 new(g.units[i]);
 result:=g.units[i];
 u:=result;
 p:=get_plr(g,owner);

 cn:=-1;
 if p<>nil then begin
  if incr_count then inc(p.u_num[ud.num]);
  for k:=0 to length(g.clansdb[p.info.clan].unupd)-1 do if g.clansdb[p.info.clan].unupd[k].typ=typ then begin
   clp:=@g.clansdb[p.info.clan].unupd[k];
   cn:=k;
   break;
  end;
  if clp=@eud then cn:=-1;
 end;

 fillchar(u^,sizeof(u^),0); //All zeros

 u.uid:=g.last_uid;
 g.last_uid:=g.last_uid+1;

 u.dbn:=n;
 u.grp_db:=-1;
 u.cln:=cn;
 u.num:=i;
 u.typ:=typ;
 u.domain:=-1;

 u.level:=ud.level;
 u.ptyp:=ud.ptyp;
 u.siz:=ud.siz;
 u.cur_siz:=ud.siz;

 u.name:='';
 if p<>nil then u.nm:=p.u_num[ud.num];
 if p<>nil then u.mk:=p.unupd[u.dbn].mk;
 u.is_unselectable:=isadb(g,ud,a_unselectable);

 u.own:=owner;
 u.x:=x;
 u.y:=y;
 u.xt:=x;
 u.yt:=y;
 u.stop_task:=stsk_none;
 u.stop_task_pending:=false;

 u.stored_in:=-1;
 u.clr_unit:=-1;
 u.clr_tape:=-1;

 if not isa(g,u,a_stealth_or_underw) then trigger_autofire(g,u);
 u.is_sentry:=true;

 u.was_fired_on:=false;

 u.isact:=isadb(g,ud,a_always_active);
 if not isa(g,u,a_building) then u.isact:=true;

 if p<>nil then u.bas:=add_stats(add_stats(ud.bas,p.unupd[n].bas),clp.bas) else u.bas:=ud.bas;
 u.cur:=u.bas;
 u.cur.speed:=u.bas.speed*10;
 u.cur.fuel:=u.bas.fuel*10;

 //Materials, mining, storage
 for ri:=RES_MIN to RES_MAX do begin
  u.prod.num[ri]:=ud.prod.num[ri];
  u.prod.use[ri] :=ud.prod.use[ri];
  u.prod.pro[ri] :=ud.prod.pro[ri];
 end;
 u.prod.refined_gold_pro:=ud.prod.refined_gold_pro;
 u.prod.score_pro:=ud.prod.score_pro;

 for ri:=RES_MINING_MIN to RES_MINING_MAX do u.prod.mining[ri]:=16;

 u.reserve:=0;
 if isa(g,u,a_mining) then calc_mining(g,u.own,false);

 mark_unit(g,u.num);
 mark_players(g);

 except stderr('Units','CreateUnit');end;
end;
//############################################################################//
//The end of unit's life
//############################################################################//
procedure delete_unit(g:pgametyp;u:ptypunits;delete_in_cell,remove_scan:boolean;no_plane_mine_check:boolean=true;dont_stop:boolean=false);
var j,x,y,s,domain:integer;
uj:ptypunits;
cp:pplrtyp;
ud:ptypunitsdb;
begin try
 if u=nil then exit;
 g.rcc:=g.rcc+1;

 mark_unit(g,u.num);
 mark_players(g);
 domain:=u.domain;

 if isa(g,u,a_research) then update_research(g);

 if not dont_stop then istopunit(g,u,false,true);
 if remove_scan then subscan(g,u,true);
 remunuc(g,u.x,u.y,u);

 g.units[u.num]:=nil;

 x:=u.x;
 y:=u.y;
 s:=u.siz;
 u.grp_db:=-1;
 u.is_moving:=false; u.is_moving_build:=false;u.is_moving_now:=false;u.isstd:=false;u.stored:=false;
 u.isbuild:=false;u.isbuildfin:=false;u.isact:=false;
 u.is_sentry:=false;
 u.domain:=-1;

 if u.own<>-1 then for j:=0 to get_unitsdb_count(g)-1 do begin
  ud:=get_unitsdb(g,j);
  if ud.typ=u.typ then begin
   cp:=get_plr(g,u.own);
   inc(cp.u_cas[ud.num]);
   break;
  end;
 end;

 for j:=0 to get_units_count(g)-1 do if unave(g,j) then begin
  uj:=get_unit(g,j);
  if uj.builds[0].base=u.num  then uj.builds[0].base:=-1;
  if uj.builds[0].tape=u.num  then uj.builds[0].tape:=-1;
  if uj.builds[0].cones=u.num then uj.builds[0].cones:=-1;
  if uj.stored and(uj.stored_in=u.num) then delete_unit(g,uj,false,false);
 end;

 if delete_in_cell then for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
  uj:=get_unit(g,j);
  //if uj.rot<>16 then  is for boom
  if uj.rot<>16 then if((uj.ptyp<>pt_air)and(not isa(g,uj,a_bomb)))or no_plane_mine_check then begin
   if(u.siz=1)and(uj.x=u.x)and(uj.y=u.y)and(uj.typ<>'smlrubble')and(uj.typ<>'bigrubble') then begin
    delete_unit(g,uj,false,remove_scan);
   end else if(u.siz=2)and( ((uj.x=u.x)and(uj.y=u.y))or((uj.x=u.x+1)and(uj.y=u.y))or((uj.x=u.x)and(uj.y=u.y+1))or((uj.x=u.x+1)and(uj.y=u.y+1)) )and(uj.typ<>'bigrubble')and(uj.typ<>'smlrubble')then begin
    delete_unit(g,uj,false,remove_scan);
   end;
  end;
 end;

 //Clear
 fillchar(u^,sizeof(u^),0);
 dispose(u);
 if domain<>-1 then refresh_domains(g);

 g.rcc:=g.rcc-1;
 if not dont_stop then if g.rcc=0 then rebalance_around(g,x,y,s,nil);

 except g.rcc:=g.rcc-1; stderr('Units','DeleteUnit');end;
end;
//############################################################################//
function place_full_unit(g:pgametyp;typ:string;x,y,own:integer):ptypunits;
var ud:ptypunitsdb;
ut:ptypunits;
i:integer;
begin
 result:=nil;
 ud:=get_unitsdb(g,getdbnum(g,typ));
 if ud=nil then exit;

 //If it's a vehicle
 if not isadb(g,ud,a_building) then begin
  result:=create_unit(g,typ,x,y,own);
  exit;
 end;

 //If it's a building
 if ud.siz=1 then begin
  if (not isadb(g,ud,a_connector))and(not isadb(g,ud,a_road))and(not isadb(g,ud,a_bridge))and(not isadb(g,ud,a_can_build_on)) then rm_connectors(g,x,y);
  if isadb(g,ud,a_bld_on_plate) and (not ud.ptyp>pt_landwater) then begin
   ut:=create_unit(g,'smlplate',x,y,own);
   ut.isact:=true;
   ut.is_unselectable:=true;
   addscan(g,ut,ut.x,ut.y);
  end;
  for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
   ut:=get_unit(g,i);
   if isa(g,ut,a_overbuild_disabled)and(ut.x=x)and(ut.y=y)then ut.is_unselectable:=true;
  end;
 end else begin
  if (not isadb(g,ud,a_connector))and(not isadb(g,ud,a_road))and(not isadb(g,ud,a_bridge))and(not isadb(g,ud,a_can_build_on)) then begin
   rm_connectors(g,x  ,y  );
   rm_connectors(g,x+1,y  );
   rm_connectors(g,x  ,y+1);
   rm_connectors(g,x+1,y+1);
  end;
  if isadb(g,ud,a_bld_on_plate) and(ud.ptyp<pt_watercoast) then begin
   ut:=create_unit(g,'bigplate',x,y,own);
   ut.isact:=true;
   ut.is_unselectable:=true;
   addscan(g,ut,ut.x,ut.y);
  end;
  for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
   ut:=get_unit(g,i);
   if isa(g,ut,a_overbuild_disabled) then begin
    if((ut.x=x  )and(ut.y=y  ))or
      ((ut.x=x+1)and(ut.y=y  ))or
      ((ut.x=x  )and(ut.y=y+1))or
      ((ut.x=x+1)and(ut.y=y+1))then ut.is_unselectable:=true;
   end;
  end;
 end;

 result:=create_unit(g,typ,x,y,own);
end;
//############################################################################//
//Remove connectors at x,y
procedure rm_connectors(g:pgametyp;x,y:integer);
var i:integer;
u:ptypunits;
begin
 for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
  u:=get_unit(g,i);
  if (u.x=x)and(u.y=y)and isa(g,u,a_connector) then delete_unit(g,u,false,true,true,true);
 end;
end;
//############################################################################//
//Mark the unit as to be fired at by autofire
procedure trigger_autofire(g:pgametyp;u:ptypunits);
begin
 if not unav(u) then exit;
 u.triggered_auto_fire:=true;
end;
//############################################################################//
//Set stealth unit as detected by player by
procedure set_detected_stealth(g:pgametyp;u:ptypunits;by:integer);
begin
 if not unav(u) then exit;
 mark_unit(g,u.num);
 u.stealth_detected[by]:=2;
end;
//############################################################################//
procedure do_collateral_blast(g:pgametyp;ui:ptypunits);
var bor,j,i,a,x,y,own,siz:integer;
uj:ptypunits;
add:boolean;
begin
 if ui=nil then exit;
 i:=ui.num;
 bor:=ord(isa(g,ui,a_bor));

 if not isa(g,ui,a_survives_overblast) and not isa(g,ui,a_no_overblast) then for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
  uj:=get_unit(g,j);
  if((ui.siz+bor=1)and(  uj.x=ui.x  )and(uj.y=ui.y  ))
  or((ui.siz+bor=2)and(((uj.x=ui.x  )and(uj.y=ui.y  ))
                     or((uj.x=ui.x+1)and(uj.y=ui.y  ))
                     or((uj.x=ui.x  )and(uj.y=ui.y+1))
                     or((uj.x=ui.x+1)and(uj.y=ui.y+1)) ))then if(not isa(g,uj,a_survives_overblast))or(uj.ptyp=pt_air)then begin
   if uj.ptyp=pt_air then begin
    if not isa(g,ui,a_landing_pad) then continue;
    if uj.alt<>0 then continue;
    //FIXME: recursion...
    add_log_msg(g,uj.own,lmt_unit_destroyed,uj.x,uj.y,uj.dbn);
    boom_unit(g,uj);
   end else begin
    //FIXME: What was that about with rot=16?
    //Something important, but forgotten.

    //FIXME: Remove scan if not unselectable, should be no scan if unselectable
    if j<>i then delete_unit(g,uj,false,not isa(g,uj,a_unselectable));
   end;
  end;
 end;

 if isa(g,ui,a_bomb) then for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
  uj:=get_unit(g,j);
  if((ui.siz+bor=1)and(  uj.x=ui.x  )and(uj.y=ui.y  ))
  or((ui.siz+bor=2)and(((uj.x=ui.x  )and(uj.y=ui.y  ))
                     or((uj.x=ui.x+1)and(uj.y=ui.y  ))
                     or((uj.x=ui.x  )and(uj.y=ui.y+1))
                     or((uj.x=ui.x+1)and(uj.y=ui.y+1)) ))then if(not isa(g,uj,a_survives_overblast))or(isa(g,uj,a_human))then begin
   a:=ui.bas.attk-uj.bas.armr;
   if a<=0 then a:=1;
   uj.cur.hits:=uj.cur.hits-a;
   if uj.cur.hits<=0 then begin
    uj.cur.hits:=0;
    add_log_msgu(g,uj.own,lmt_unit_destroyed,uj,ui);
    boom_unit(g,uj);
   end;
  end;
 end;


 //FIXME: Should full transports leave more debris?
 if isa(g,ui,a_leaves_decay) and not ui.stored then begin
  x:=ui.x;
  y:=ui.y;
  own:=ui.own;
  siz:=ui.siz;
  add:=false;
  uj:=nil;
  if siz+bor=1 then if get_map_pass(g,x,y)=P_LAND then begin
   for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
    uj:=get_unit(g,j);
    if
    (
     ((uj.x=ui.x)and(uj.y=ui.y))
     or
     (
      (uj.siz=2)and(
       ((uj.x=ui.x-1)and(uj.y=ui.y))
       or
       ((uj.x=ui.x)and(uj.y=ui.y-1))
       or
       ((uj.x=ui.x-1)and(uj.y=ui.y-1))
      )
     )
    )and((uj.typ='bigrubble')or(uj.typ='smlrubble'))then begin
     uj.clrval:=uj.clrval+max2i(ui.bas.cost div 2+ui.prod.now[RES_MAT],2);
     add:=true;
     break;
    end;
   end;
   if not add then uj:=create_unit(g,'smlrubble',x,y,own);
   uj.isact:=true;
   uj.own:=own;
   uj.is_unselectable:=true;
   if uj.siz=1 then uj.rot:=mgrandom_int(g,5) else uj.rot:=mgrandom_int(g,2);
   if not add then uj.clrval:=max2i(ui.bas.cost div 2+ui.prod.now[RES_MAT],2);
   if not add then addunu(g,uj);
  end;
  if siz+bor=2 then if (get_map_pass(g,x,y)=P_LAND)and(get_map_pass(g,x+1,y)=P_LAND)and(get_map_pass(g,x,y+1)=P_LAND)and(get_map_pass(g,x+1,y+1)=P_LAND) then begin
   uj:=create_unit(g,'bigrubble',x,y,own);
   uj.isact:=true;
   uj.is_unselectable:=true;
   uj.rot:=mgrandom_int(g,2);
   uj.clrval:=max2i(ui.bas.cost div 2+ui.prod.now[RES_MAT],2);
   addunu(g,uj);
  end;
 end;
end;
//############################################################################//
//Blow the unit
procedure do_blast(g:pgametyp;ui:ptypunits);
var i,j:integer;
uj:ptypunits;
begin try
 if ui=nil then exit;
 i:=ui.num;

 for j:=0 to get_plr_count(g)-1 do set_detected_stealth(g,ui,j);

 ui.isact:=false;
 ui.rot:=16;
 ui.grot:=16;

 if ui.stored_in=-1 then do_collateral_blast(g,ui);

 for j:=0 to get_units_count(g)-1 do if unave(g,j) then begin
  uj:=get_unit(g,j);
  if uj.stored_in=i then begin
   uj.x:=ui.x;
   uj.y:=ui.y;
   add_log_msgu(g,uj.own,lmt_unit_destroyed,uj,ui);
   //boom_unit(g,uj);    //This won't work! It's stored. And not checking for that would cause weird bugs and inner booms
   mark_unit(g,uj.num);
  end;
 end;

 if isa(g,ui,a_survives_overblast) or isa(g,ui,a_no_overblast) or(ui.stored_in<>-1)then delete_unit(g,ui,false,true) else delete_unit(g,ui,true,true,false);

 except stderr('Units','DoBlast');end;
end;
//############################################################################//
procedure boom_unit(g:pgametyp;u:ptypunits);
var k:integer;
begin
 if not unav(u) then exit;
 mark_unit(g,u.num);

 k:=0;
 if isa(g,u,a_bor) or (u.siz=2) then k:=1 else
 if u.ptyp=pt_air then k:=2 else
 if (u.ptyp=pt_landwater)or((u.ptyp<pt_watercoast)and(get_map_pass(g,u.x,u.y)=P_WATER))then k:=3;

 add_sew(g,sew_boom,u.num,u.siz,k,u.x,u.y);
 do_blast(g,u);
end;
//############################################################################//
function landing_detect_intersect(g:pgametyp):boolean;
var i,j,th:integer;
p1,p2:pplrtyp;
begin
 result:=false;
 th:=taint_threshold;
 if g.info.rules.direct_land then if g.info.rules.moratorium_range>th then th:=g.info.rules.moratorium_range;
 for i:=0 to get_plr_count(g)-1 do for j:=i+1 to get_plr_count(g)-1 do begin
  p1:=get_plr(g,i);
  p2:=get_plr(g,j);
  if (i<>j)and is_landed(g,p1)and is_landed(g,p2) then if sqrt(sqr(p1.info.lndx-p2.info.lndx)+sqr(p1.info.lndy-p2.info.lndy))<th then result:=true;
 end;
end;
//############################################################################//
procedure spiral_land(g:pgametyp;var px,py,d,n,r:integer;pn,nm:integer);
var u:ptypunits;
begin
 while not test_pass_db(g,px,py,nm,nil) do begin
  if inrm(g,px,py) then if ((get_map_pass(g,px,py)=P_WATER)or(get_map_pass(g,px,py)=P_COAST))and(get_unu_length(g,px,py)=0) then begin
   u:=place_full_unit(g,'plat',px,py,pn);
   addunu(g,u);
   if get_unu_length(g,px,py)<>0 then continue;
  end;
  case d of
   0:begin px:=px+1; py:=py+0;end;
   1:begin px:=px+0; py:=py+1;end;
   2:begin px:=px-1; py:=py+0;end;
   3:begin px:=px+0; py:=py-1;end;
  end;
  n:=n+1;
  if n>r then begin
   n:=0;
   d:=d+1;
   if d=2 then r:=r+1;
   if d>=4 then d:=0;
   if d=0 then r:=r+1;
  end;
 end;
end;
//############################################################################//
//Land player
procedure land_one_player(g:pgametyp;pn:integer);
var j,x,y,px,py,d,r,ir,n,nm,xns,yns,ri:integer;
u:ptypunits;
p:pplrtyp;
begin
 p:=get_plr(g,pn);
 xns:=p.info.lndx;
 yns:=p.info.lndy;

 //Initial base
 if not g.info.rules.direct_land then begin
  if not landing_pass_test(g,xns-1,yns-1,xns+1,yns+1,ir) then exit;

  //Water platforms for initial base
  for x:=-3 to 3 do for y:=-2 to 3 do if(get_map_pass(g,xns+x,yns+y)=P_WATER)or(get_map_pass(g,xns+x,yns+y)=P_COAST)then place_full_unit(g,'plat',xns+x,yns+y,pn);

  u:=place_full_unit(g,'mining',xns,yns,pn);      u.isact:=true;u.prod.dbt[RES_FUEL]:=2;
  u:=place_full_unit(g,'powergen',xns-1,yns+1,pn);u.isact:=true;u.prod.dbt[RES_POW]:=1;

  if g.info.rules.startradar then place_full_unit(g,'radar',xns-1,yns,pn);

  //Put resources under first Mining
  initial_resource_placement(g,xns,yns,true);
 end;

 setunu(g);

 //Initial units
 //FIXME: Check for passability
 px:=xns-1;
 py:=yns-1;
 d:=0;
 r:=2;
 n:=0;
 for j:=0 to p.info.bgncnt-1 do begin
  nm:=getdbnum(g,p.info.bgn[j].typ);
  if nm=-1 then continue;

  if g.info.rules.direct_land then begin
   px:=xns+p.info.bgn[j].x;
   py:=yns+p.info.bgn[j].y;
  end else begin
   spiral_land(g,px,py,d,n,r,pn,nm);
  end;

  u:=place_full_unit(g,p.info.bgn[j].typ,px,py,pn);
  addunu(g,u);
  for ri:=RES_MINING_MIN to RES_MINING_MAX do if u.prod.num[ri]<>0 then u.prod.now[ri]:=p.info.bgn[j].mat;
 end;

 //Survey initial resources
 for x:=-1 to 1 do for y:=-1 to 1 do p.resmp[xns+x+(yns+y)*g.info.mapx]:=1;

 setunu(g);
 refresh_domains(g);
end;
//############################################################################//
//Mark player landed
function land_player(g:pgametyp;lnd:pplayer_start_rec):boolean;
var r,i:integer;
cp:pplrtyp;
begin result:=false; try
 result:=false;
 cp:=get_cur_plr(g);
 if g.info.rules.direct_land or landing_pass_test(g,lnd.lndx-1,lnd.lndy-1,lnd.lndx+1,lnd.lndy+1,r) then begin
  set_landed(g,cp);
  cp.info:=lnd^;
  cp.gold:=cp.info.stgold;

  //FIXME: Size check
  for i:=0 to length(cp.unupd)-1 do cp.unupd[i]:=cp.info.init_unupd[i];

  add_comment(g,get_cur_plr(g),lnd.lndx,lnd.lndy,'Landing&site&PLR '+stri(cp.num)+'&'+stri(lnd.lndx)+':'+stri(lnd.lndy));
  result:=true;
 end else begin
  ////case r of
  //// 1:msgu_set(g,'Посадка за край карты не допустима.');
  //// 2:msgu_set(g,'Посадка на препятствия не допустима.');
  ////end;
 end;

 except stderr('Units','LandPlayer');end;
end;
//############################################################################//
//#kind= -1 for hide unit only, 0 for move, and +1 for show only
//? WTF ?
procedure unit_newpos(g:pgametyp;u:ptypunits;x,y:integer;kind:integer=1);
var pv:array [0..MAX_PLR-1] of boolean;
j:integer;
begin
 for j:=0 to get_plr_count(g)-1 do pv[j]:=can_see(g,u.x,u.y,j,u);
 if kind<=0 then begin
  if kind=0 then addscan(g,u,x,y,true);
  subscan(g,u);
  remunuc(g,u.x,u.y,u);
  if kind=-1 then for j:=0 to get_plr_count(g)-1 do if(j<>u.own)and pv[j]then add_log_msgu(g,j,lmt_enemy_unit_hiden, u);
 end;
 u.x:=x;u.y:=y;
 if kind>=0 then begin
  addunu(g,u);
  if kind>0 then addscan(g,u,x,y,true);
  if kind=1 then for j:=0 to get_plr_count(g)-1 do if(j<>u.own)and can_see(g,u.x,u.y,j,u)then add_log_msgu(g,j,lmt_enemy_unit_spoted, u);
 end;
 if kind=0 then for j:=0 to get_plr_count(g)-1 do if(u.own<>j)and(pv[j]<>can_see(g,u.x,u.y,j,u))then
  if pv[j] then add_log_msgu(g,j,lmt_enemy_unit_hiden, u)
           else add_log_msgu(g,j,lmt_enemy_unit_spoted,u);
end;
//############################################################################//
procedure update_research(g:pgametyp);
var i,j,k:integer;
p:pplrtyp;
u:ptypunits;
begin
 for i:=0 to get_plr_count(g)-1 do begin
  p:=get_plr(g,i);
  for j:=0 to RS_COUNT-1 do p.rsrch_labs[j]:=0;
  for j:=0 to RS_COUNT-1 do p.rsrch_left[j]:=0;
  p.labs_free:=0;

  for j:=0 to get_units_count(g)-1 do if unav(g,j) then begin
   u:=get_unit(g,j);
   if u.own<>i then continue;
   if isa(g,u,a_research)and u.isact then begin
    if u.researching=0 then begin
     p.labs_free:=p.labs_free+1;
    end else begin
     p.rsrch_labs[u.researching-1]:=p.rsrch_labs[u.researching-1]+1;
    end;
   end;
  end;

  for j:=0 to RS_COUNT-1 do if p.rsrch_labs[j]<>0 then begin
   k:=calc_res_turns(g,p.rsrch_level[j]*10,j,0)-p.rsrch_spent[j];
   p.rsrch_left[j]:=k div p.rsrch_labs[j];
   if k mod p.rsrch_labs[j]<>0 then p.rsrch_left[j]:=p.rsrch_left[j]+1;
  end;

 end;
end;
//############################################################################//
//Transfer menu action
procedure do_xfer(g:pgametyp;ua,ub:ptypunits;cnt:pinta);
var ri:integer;
amt:integer;
//,avl:integer;
//ps,pd:pprodrec;
us,ud:ptypunits;
begin try
 if ua=nil then exit;
 if ub=nil then exit;
 mark_unit(g,ua.num);
 mark_unit(g,ub.num);
 for ri:=RES_MINING_MIN to RES_MINING_MAX do begin
  amt:=cnt[ri-1];
  if amt>=0 then begin
   us:=ua;
   ud:=ub;
  end else begin
   us:=ub;
   ud:=ua;
   amt:=-amt;
  end;
  //FIXME: This was for allowing inter-complex transfers. It causes absurd anomalies as is, like resources appearing from nowhere.
  //ps:=@us.prod;
  //pd:=@ud.prod;
  {
  if us.domain=ud.domain then begin
   if(ps.num[ri]=0)or(pd.num[ri]=0)then continue; //Transfer allowed only between two explicit stores in one complex.
   ps.now[ri]:=ps.now[ri]-amt;
   pd.now[ri]:=pd.now[ri]+amt;
   avl:=ps.now[ri]+ps.pro[ri]*ord(us.isact);
   if ps.dbt[ri]>avl then begin
    amt:=ps.dbt[ri]-avl;
    ps.dbt[ri]:=ps.dbt[ri]-amt;
    pd.dbt[ri]:=pd.dbt[ri]+amt;
   end;
  end else begin
  }
   if take_res_now_minding(g,us,ri,amt) then put_res_now(g,ud,ri,amt,false);
  //end;
 end;

 if g.info.rules.fuelxfer and g.info.rules.fueluse then begin
  us:=ua;
  ud:=ub;
  amt:=cnt[3];
  amt:=(2*ord(amt>=0)-1)*amt;
  us.cur.fuel:=us.cur.fuel-amt;
  ud.cur.fuel:=ud.cur.fuel+amt;
 end;
 except stderr('Input','do_gm3');end;
end;
//############################################################################//
//Create unit menu action
procedure dbg_place_unit(g:pgametyp;xns,yns,j:integer;p:boolean);
var i,ri:integer;
typ:string;
ud:ptypunitsdb;
u,ui:ptypunits;
cp:pplrtyp;
begin try
 if xns<0 then exit;
 cp:=get_cur_plr(g);
 if j=-1 then if inrm(g,xns,yns) then if get_unu_length(g,xns,yns)>0 then delete_unit(g,get_unu(g,xns,yns,0),true,true);

 if j>=0 then begin
  if not test_pass_db(g,xns,yns,j,nil) then exit;
  ud:=get_unitsdb(g,j);
  if isadb(g,ud,a_building) then begin
   if ud.siz=1 then if isadb(g,ud,a_solid_building)then rm_connectors(g,xns,yns);
   if ud.siz=2 then begin
    rm_connectors(g,xns,yns);
    rm_connectors(g,xns+1,yns);
    rm_connectors(g,xns,yns+1);
    rm_connectors(g,xns+1,yns+1);
   end;
  end;

  if isadb(g,ud,a_bld_on_plate) and (ud.ptyp<pt_watercoast) then begin
   if ud.siz=1 then typ:='smlplate' else typ:='bigplate';
   u:=create_unit(g,typ,xns,yns,cp.num);
   u.isact:=true;
   u.is_unselectable:=true;
   addscan(g,u,u.x,u.y,true);
  end;

  if (ud.siz=1)and(isadb(g,ud,a_building)) then for i:=0 to get_units_count(g)-1 do if unav(g,i) then begin
   ui:=get_unit(g,i);
   if isa(g,ui,a_half_selectable) and (not isadb(g,ud,a_half_selectable)) and(ui.x=xns)and(ui.y=yns)then ui.is_unselectable:=true;
  end;

  u:=create_unit(g,ud.typ,xns,yns,cp.num);
  unit_newpos(g,u,xns,yns);
  refresh_domains(g);

  if p then begin
   for ri:=RES_MINING_MIN to RES_MINING_MAX do if u.prod.num[ri]>0 then u.prod.now[ri]:=u.prod.num[ri];
  end;
 end;

 except stderr('Input','do_menu1');end;
end;
//############################################################################//
begin
end.
//############################################################################//
