//############################################################################//  
unit mgl_stats;
interface      
uses asys,maths,mgrecs,mgl_common,mgl_attr,mgl_res; 
//############################################################################//
//Stats transfer record
type mstt=record
 bas,cur,upd:statrec;
 store,storecnt:int16;
 matnum,matnow,matall,matallcur:int16;
 fuelnum,fuelnow,fuelall,fuelallcur:int16;
 pow,pownow,powall,powallpro,powuse,powuseneed:int16;
 gold,goldnow,goldall,goldallcur:int16;
 man,manpro,manall,manallpro,manuse:int16;
 shootcur:int16;
end;
pmstt=^mstt;
//############################################################################//
function stat_by_typ(const a:statrec;tp:integer):psmallint;

function non_zero_stats(const a:statrec):boolean;
procedure zero_stats(var a:statrec);
function add_stats(a,b:statrec):statrec;
function sub_stats(a,b:statrec):statrec;   

procedure get_stats_db(g:pgametyp;ud:ptypunitsdb;st:pmstt;tp:integer;rul:prulestyp);  
procedure get_stats_ng(g:pgametyp;ud:ptypunitsdb;st:pmstt;rul:prulestyp;plr:pplayer_start_rec);
procedure get_stats_un(g:pgametyp;u:ptypunits;st:pmstt;tp:integer);

function get_full_pars(g:pgametyp;un,tp:integer;p:ptyp_unupd;clan:ptypclansdb;const sup:statrec;out cur,base,upr:integer;out upd:psmallint):boolean;
//############################################################################//
implementation 
//############################################################################//
function stat_by_typ(const a:statrec;tp:integer):psmallint;
begin
 result:=nil;
 case tp of
  ut_attk :result:=@a.attk;
  ut_shot :result:=@a.shoot;
  ut_range:result:=@a.range;
  ut_ammo :result:=@a.ammo;
  ut_armor:result:=@a.armr;
  ut_hits :result:=@a.hits;
  ut_scan :result:=@a.scan;
  ut_speed:result:=@a.speed;
  ut_fuel :result:=@a.fuel;
 end;
end;
//############################################################################//
function non_zero_stats(const a:statrec):boolean;
begin
 result:=(
  abs(a.attk )+
  abs(a.shoot)+
  abs(a.range)+
  abs(a.ammo )+
  abs(a.armr )+
  abs(a.hits )+
  abs(a.scan )+
  abs(a.speed)+
  abs(a.fuel )+
  abs(a.area )+
  abs(a.cost )+
  abs(a.mat_turn)
 )<>0;
end;    
//############################################################################//
procedure zero_stats(var a:statrec);
begin
 a.attk :=0;
 a.shoot:=0;
 a.range:=0;
 a.ammo :=0;
 a.armr :=0;
 a.hits :=0;
 a.scan :=0;
 a.speed:=0;
 a.fuel :=0;
 a.area :=0;
 a.cost :=0;
 a.mat_turn:=0;
end;     
//############################################################################//
function add_stats(a,b:statrec):statrec;
begin
 result.attk :=a.attk +b.attk;
 result.shoot:=a.shoot+b.shoot;
 result.range:=a.range+b.range;
 result.ammo :=a.ammo +b.ammo;
 result.armr :=a.armr +b.armr;
 result.hits :=a.hits +b.hits;
 result.scan :=a.scan +b.scan;
 result.speed:=a.speed+b.speed;
 result.fuel :=a.fuel +b.fuel;
 result.area :=a.area +b.area;
 result.cost :=a.cost +b.cost;
 result.mat_turn:=a.mat_turn+b.mat_turn;
end;   
//############################################################################//
function sub_stats(a,b:statrec):statrec;
begin
 result.attk :=a.attk -b.attk;
 result.shoot:=a.shoot-b.shoot;
 result.range:=a.range-b.range;
 result.ammo :=a.ammo -b.ammo;
 result.armr :=a.armr -b.armr;
 result.hits :=a.hits -b.hits;
 result.scan :=a.scan -b.scan;
 result.speed:=a.speed-b.speed;
 result.fuel :=a.fuel -b.fuel;
 result.area :=a.area -b.area;
 result.cost :=a.cost -b.cost;
 result.mat_turn:=a.mat_turn-b.mat_turn;
end;
//############################################################################//
procedure get_stats_db(g:pgametyp;ud:ptypunitsdb;st:pmstt;tp:integer;rul:prulestyp);
var clp,p:ptyp_unupd;
eud:typ_unupd;
k:integer;
cp:pplrtyp;
cl:ptypclansdb;
begin
 fillchar(st^,sizeof(st^),0);
 
 if(tp=2)or(tp=4)then begin
  if ud=nil then exit;
  cp:=get_cur_plr(g);
   
  if tp=2 then p:=@cp.unupd[ud.num]
          else p:=@cp.tmp_unupd[ud.num];
  st^.upd:=p.bas;  
  if tp=4 then st^.upd:=add_stats(p.bas,cp.unupd[ud.num].bas);


  fillchar(eud,sizeof(eud),0);eud.typ:='';
  clp:=@eud;
  cl:=get_clan(g,cp.info.clan);
  for k:=0 to length(cl.unupd)-1 do if cl.unupd[k].typ=ud.typ then begin
   clp:=@cl.unupd[k];
   break;
  end;

  st^.bas:=add_stats(add_stats(ud.bas,st^.upd),clp.bas);   
  if not rul.fueluse then st^.bas.fuel:=0;  
 end;
end;
//############################################################################//
procedure get_stats_ng(g:pgametyp;ud:ptypunitsdb;st:pmstt;rul:prulestyp;plr:pplayer_start_rec);
var clp,p:ptyp_unupd;
eud:typ_unupd;
k:integer;
cl:ptypclansdb;
begin
 fillchar(st^,sizeof(st^),0);
 
 if ud=nil then exit;
   
 p:=@plr.init_unupd[ud.num];
 st^.upd:=p.bas;  

 fillchar(eud,sizeof(eud),0);eud.typ:='';
 clp:=@eud;
 cl:=get_clan(g,plr.clan);
 for k:=0 to length(cl.unupd)-1 do if cl.unupd[k].typ=ud.typ then begin
  clp:=@cl.unupd[k];
  break;
 end;

 st^.bas:=add_stats(add_stats(ud.bas,st^.upd),clp.bas);   
 if not rul.fueluse then st^.bas.fuel:=0;  
end;
//############################################################################//
procedure get_stats_un(g:pgametyp;u:ptypunits;st:pmstt;tp:integer);
var ud:ptypunitsdb;
clp:ptyp_unupd;
eud:typ_unupd;
k:integer;
p,cp:pplrtyp;  
rul:prulestyp;   
cl:ptypclansdb;
begin
 rul:=get_rules(g);
 cp:=get_cur_plr(g);
 fillchar(st^,sizeof(st^),0);
 if(tp=0)or(tp=3) then begin
  if u=nil then exit; 
  ud:=get_unitsdb(g,u.dbn);
   
  st^.bas:=u.bas;
  st^.cur:=u.cur;     
  st^.cur.speed:=min2i(u.cur.speed div 10,u.bas.speed);  
           
  if not plr_are_enemies(g,u.own,cp.num) then begin
   if rul.fueluse then st^.cur.fuel:=u.cur.fuel div 10 else begin st^.cur.fuel:=0;st^.bas.fuel:=0;end;
   st^.matnum :=u.prod.num[RES_MAT];
   st^.matnow :=u.prod.now[RES_MAT];
   st^.fuelnum:=u.prod.num[RES_FUEL];
   st^.fuelnow:=u.prod.now[RES_FUEL];
   st^.gold   :=u.prod.num[RES_GOLD];
   st^.goldnow:=u.prod.now[RES_GOLD];
   if(u.prod.num[RES_MAT]>0)and(isa(g,u,a_passes_res)) then begin
    st^.matall   :=get_rescount(g,u,RES_MAT,GROP_MAX);
    st^.matallcur:=get_rescount(g,u,RES_MAT,GROP_NOW);
   end;
   if(u.prod.num[RES_FUEL]>0)and(isa(g,u,a_passes_res)) then begin
    st^.fuelall   :=get_rescount(g,u,RES_FUEL,GROP_MAX);
    st^.fuelallcur:=get_rescount(g,u,RES_FUEL,GROP_NOW);
   end;
   if(u.prod.num[RES_GOLD]>0)and(isa(g,u,a_passes_res)) then begin
    st^.goldall   :=get_rescount(g,u,RES_GOLD,GROP_MAX);
    st^.goldallcur:=get_rescount(g,u,RES_GOLD,GROP_NOW);
   end;
   st^.pow:=u.prod.pro[RES_POW]+u.prod.num[RES_POW];
   if u.isact then st^.pownow:=u.prod.pro[RES_POW]+u.prod.now[RES_POW] else st^.pownow:=u.prod.now[RES_POW];
   if (u.prod.pro[RES_POW]>0)or(u.prod.num[RES_POW]>0)and(isa(g,u,a_passes_res)) then begin
    st^.powall    :=get_rescount(g,u,RES_POW,GROP_MAXAVL);
    st^.powallpro :=get_rescount(g,u,RES_POW,GROP_PRO);
    st^.powuse    :=get_rescount(g,u,RES_POW,GROP_MAXNEED);
    st^.powuseneed:=get_rescount(g,u,RES_POW,GROP_NEED);
   end;
   st^.man   :=u.prod.num[RES_HUMAN];
   st^.manpro:=u.prod.pro[RES_HUMAN];
   if (u.prod.pro[RES_HUMAN]>0)or(u.prod.num[RES_HUMAN]>0)or(u.prod.use[RES_HUMAN]>0)and(isa(g,u,a_passes_res)) then begin
    st^.manallpro:=get_rescount(g,u,RES_HUMAN,GROP_PRO);
    st^.manuse   :=get_rescount(g,u,RES_HUMAN,GROP_MAXNEED);
    st^.manall   :=get_rescount(g,u,RES_HUMAN,GROP_NEED);
   end;   
   if(ud.store_lnd>0)or(ud.store_wtr>0)or(ud.store_air>0)or(ud.store_hmn>0) then begin
    st^.store:=ud.store_lnd+ud.store_wtr+ud.store_air+ud.store_hmn;
    st^.storecnt:=u.currently_stored;
   end;
  end else begin
   st^.cur.ammo:=0;  
   st^.cur.fuel:=0; 
   st^.bas.ammo:=0;  
   st^.bas.fuel:=0; 
  end;
 end;
 //###############################################//
 if tp=1 then begin   
  if u=nil then exit;
  
  st^.bas:=u.bas;
  if not rul.fueluse then st^.bas.fuel:=0;

  if u.own<>-1 then begin
   ud:=get_unitsdb(g,u.dbn);
   p:=get_plr(g,u.own);

   fillchar(eud,sizeof(eud),0);
   eud.typ:='';
   clp:=@eud;
   
   cl:=get_clan(g,p.info.clan);
   for k:=0 to length(cl.unupd)-1 do if cl.unupd[k].typ=ud.typ then begin
    clp:=@cl.unupd[k];
    break;
   end;
   
   st^.upd:=sub_stats(u.bas,add_stats(ud.bas,clp.bas));
   st^.upd.area:=0;
  end;
 end;
end; 
//############################################################################//
function get_full_pars(g:pgametyp;un,tp:integer;p:ptyp_unupd;clan:ptypclansdb;const sup:statrec;out cur,base,upr:integer;out upd:psmallint):boolean;
var eud:typ_unupd;
cl:ptyp_unupd;
ud:ptypunitsdb;
i:integer;
begin
 result:=false;

 base:=0;
 upd:=nil;
 upr:=0;
 cur:=0;

 ud:=get_unitsdb(g,un);

 fillchar(eud,sizeof(eud),0);
 eud.typ:='';
 cl:=@eud;
 for i:=0 to length(clan.unupd)-1 do if clan.unupd[i].typ=ud.typ then begin cl:=@clan.unupd[i];break;end;

 upd:=stat_by_typ(p.bas,tp);
 if upd=nil then exit;
 upr:=stat_by_typ(sup,tp)^;
 base:=stat_by_typ(ud.bas,tp)^+stat_by_typ(cl.bas,tp)^;

 cur:=base+upr;

 result:=true;
end;
//############################################################################//  
begin
end.
//############################################################################//  
