//############################################################################//
unit mgl_buy;
interface
uses asys,mgrecs,mgl_common,mgl_attr,mgl_stats,mgl_upgcalc,mgl_actions,mgl_res,mgl_land;
//############################################################################//
const
BUY_FLT_UPGRADE=4;

material_step=5;
//############################################################################//
type
//One upgrade menu pgrade element
upd_elem_rec=record
 vl,tp,cost:integer;
end;
//############################################################################//
//Purchase menu
buy_menu_rec=record
 isbuy,isupg:boolean;

 bought_sel,bought_off,bought_step:integer;
 mat_cur,mat_max,mat_kind:integer; //Kind is as in the image file

 pre_upgrades_gold,cur_gold:integer;
 upd_elems:array[0..8]of upd_elem_rec;

 filters:array[0..4]of boolean;
 list:array of integer;
 list_sel,list_off,list_step:integer;
end;
pbuy_menu_rec=^buy_menu_rec;
//############################################################################//   
procedure calc_buy_list(g:pgametyp;zm3:pbuy_menu_rec;tp,p:integer;rul:prulestyp);  

procedure clear_buy_menu(g:pgametyp;zm3:pbuy_menu_rec;rul:prulestyp);  
   
procedure reset_buy_menu(g:pgametyp;zm3:pbuy_menu_rec;rul:prulestyp);     
procedure recalc_buy_menu_list(g:pgametyp;zm3:pbuy_menu_rec;rul:prulestyp);
procedure fill_buy_menu_mat(g:pgametyp;zm3:pbuy_menu_rec);

procedure buy_menu_accept(g:pgametyp;zm3:pbuy_menu_rec);
procedure upg_menu_accept(g:pgametyp;zm3:pbuy_menu_rec);

procedure upg_menu_pre_init(g:pgametyp;zm3:pbuy_menu_rec;list_step:integer);    
procedure buy_menu_pre_init(g:pgametyp;zm3:pbuy_menu_rec;list_step,bought_step:integer;base:boolean);

procedure upg_menu_post_init(g:pgametyp;zm3:pbuy_menu_rec); 
procedure buy_menu_post_init(g:pgametyp;zm3:pbuy_menu_rec);  

procedure buy_menu_arrow(g:pgametyp;zm3:pbuy_menu_rec;tp,par:integer);   
procedure upg_menu_arrow(g:pgametyp;zm3:pbuy_menu_rec;tp,par:integer); 

procedure set_begin_mat(g:pgametyp;zm3:pbuy_menu_rec;par:integer);   
procedure begins_buy(g:pgametyp;zm3:pbuy_menu_rec;x,y,n:integer;is_full:boolean;rul:prulestyp);   
procedure begins_sell(g:pgametyp;zm3:pbuy_menu_rec;n:integer);
procedure begins_select_set(g:pgametyp;zm3:pbuy_menu_rec;n:integer);

function buy_compute_upgrades(g:pgametyp;zm:pbuy_menu_rec;p:ptyp_unupd;rul:prulestyp):integer;
//############################################################################// 
implementation
//############################################################################//
procedure calc_buy_list(g:pgametyp;zm3:pbuy_menu_rec;tp,p:integer;rul:prulestyp);
var i,c,n:integer;
ud:ptypunitsdb;

function chkutp:boolean;
begin
 result:=false;
 case tp of
  0:result:=true;
  1:if is_beginable_unit(g,rul,ud.num) then result:=true;
 end;
 if((p and  1)=0)and(ud.ptyp=pt_air)then result:=false;
 if((p and  2)=0)and(isadb(g,ud,a_building))then result:=false;
 if((p and  4)=0)and(ud.ptyp>pt_landcoast)and(ud.ptyp<pt_air)then result:=false;
 if((p and  8)=0)and(ud.ptyp<pt_landwater)then result:=false;
 if((p and 16)=1)and(ud.bas.shoot=0)then result:=false;
end;

begin
 if tp=9 then exit;
 c:=get_unitsdb_count(g);
 setlength(zm3.list,c);
 n:=0;
 for i:=0 to c-1 do begin
  ud:=get_unitsdb(g,i);
  if not isadb(g,ud,a_building) then if chkutp then begin
   zm3.list[n]:=i;
   n:=n+1;
  end;
 end;
 for i:=0 to c-1 do begin
  ud:=get_unitsdb(g,i);
  if isadb(g,ud,a_building) and(ud.siz=1)and(not isadb(g,ud,a_unselectable))then if chkutp then begin
   zm3.list[n]:=i;
   n:=n+1;
  end;
 end;
 for i:=0 to c-1 do begin
  ud:=get_unitsdb(g,i);
  if isadb(g,ud,a_building) and(ud.siz=2)and(not isadb(g,ud,a_unselectable))then if chkutp then begin
   zm3.list[n]:=i;
   n:=n+1;
  end;
 end;

 setlength(zm3.list,n);
 zm3.list_sel:=0;
 zm3.list_off:=0;
end;
//############################################################################//      
procedure clear_buy_menu(g:pgametyp;zm3:pbuy_menu_rec;rul:prulestyp);
var i:integer;    
begin         
 zm3.isbuy:=true;
 zm3.isupg:=false;
 for i:=0 to 3 do zm3.filters[i]:=true;
 zm3.filters[BUY_FLT_UPGRADE]:=false;
   
 for i:=0 to length(zm3.upd_elems)-1 do zm3.upd_elems[i].vl:=0;
   
 zm3.list_sel:=0;
 zm3.list_off:=0;
 zm3.bought_sel:=0;
 zm3.bought_off:=0;
 zm3.mat_cur:=0;
 if plr_begin.bgncnt<>0 then zm3.mat_cur:=plr_begin.bgn[0].mat;
 zm3.mat_kind:=0;
end;
//############################################################################//      
procedure reset_buy_menu(g:pgametyp;zm3:pbuy_menu_rec;rul:prulestyp);
begin
 calc_buy_list(g,zm3,9,$1E,rul);
 zm3.list_sel:=0;
 zm3.list_off:=0;
 zm3.bought_sel:=0;
 zm3.bought_off:=0;
 zm3.mat_cur:=0;
 if plr_begin.bgncnt<>0 then zm3.mat_cur:=plr_begin.bgn[0].mat;
 zm3.mat_kind:=0;
end;
//############################################################################//
function filters_to_dword(zm3:pbuy_menu_rec):dword;
begin
 result:=
  (ord(zm3.filters[0]) shl 0)+
  (ord(zm3.filters[1]) shl 1)+
  (ord(zm3.filters[2]) shl 2)+
  (ord(zm3.filters[3]) shl 3)+
  (ord(zm3.filters[4]) shl 4)
 ;
end;
//############################################################################//
procedure recalc_buy_menu_list(g:pgametyp;zm3:pbuy_menu_rec;rul:prulestyp);
begin    
 calc_buy_list(g,zm3,ord(zm3.isbuy),filters_to_dword(zm3),rul);
 zm3.list_sel:=0;
 zm3.list_off:=0;
end;
//############################################################################//
//Calc buys menu
procedure fill_buy_menu_mat(g:pgametyp;zm3:pbuy_menu_rec);
var ud:ptypunitsdb;
ri:integer;    
begin
 if zm3.bought_sel<0 then exit;
 if plr_begin.bgncnt=0 then exit;
 if zm3.list_off>=length(zm3.list) then
  zm3.list_off:=length(zm3.list)-zm3.list_step;
 if zm3.list_off<0 then
  zm3.list_off:=0;
 if zm3.bought_off>plr_begin.bgncnt then zm3.bought_off:=(plr_begin.bgncnt div zm3.bought_step)*zm3.bought_step;

 ud:=get_unitsdb(g,getdbnum(g,plr_begin.bgn[zm3.bought_sel].typ));

 zm3.mat_max:=0;
 for ri:=RES_MINING_MIN to RES_MINING_MAX do if(ud.prod.num[ri]<>0)then begin 
  zm3.mat_max:=ud.prod.num[ri];
  zm3.mat_kind:=ri-1;
 end;

 plr_begin.bgn[zm3.bought_sel].mat:=zm3.mat_cur;
end;
//############################################################################//
procedure common_pre_init(g:pgametyp;zm3:pbuy_menu_rec;list_step,bought_step:integer;upg:boolean); 
var i:integer;
begin   
 zm3.list_sel:=0;
 zm3.list_off:=0;
 zm3.list_step:=list_step;
 zm3.bought_sel:=0;
 zm3.bought_off:=0; 
 zm3.bought_step:=bought_step;
   
 zm3.isbuy:=not upg;
 zm3.isupg:=upg;

 for i:=0 to 3 do zm3.filters[i]:=true;
 zm3.filters[4]:=false;
 
 for i:=0 to length(zm3.upd_elems)-1 do begin
  zm3.upd_elems[i].vl:=0;
  zm3.upd_elems[i].tp:=-1;
  zm3.upd_elems[i].cost:=0;
 end;
end;
//############################################################################//
//Buys menu action
procedure common_post_init(g:pgametyp;zm3:pbuy_menu_rec;pl:pplrtyp;p:ptyp_unupd;clan:ptypclansdb;const sup:statrec);
var i,cur,base,upr,reslevel:integer;
upd:psmallint;
begin
 for i:=0 to length(zm3.upd_elems)-1 do begin
  if not get_full_pars(g,zm3.list[zm3.list_sel],zm3.upd_elems[i].tp,p,clan,sup,cur,base,upr,upd) then continue;
  reslevel:=0;
  if pl<>nil then if zm3.upd_elems[i].tp<8 then reslevel:=pl.rsrch_level[zm3.upd_elems[i].tp]*10;
  zm3.upd_elems[i].cost:=calc_upg_price(g,cur,base,zm3.upd_elems[i].tp,reslevel);
 end;
end;
//############################################################################//
//Buys menu action
procedure common_arrow(g:pgametyp;zm3:pbuy_menu_rec;tp,par:integer;clan:ptypclansdb;p:ptyp_unupd;const sup:statrec;reslevel:integer);
var d,cur,cost,base,upr:integer;
upd:psmallint;
begin
 d:=0;
 if tp=1 then d:=-1;
 if tp=2 then d:=1;

 if not get_full_pars(g,zm3.list[zm3.list_sel],zm3.upd_elems[par].tp,p,clan,sup,cur,base,upr,upd) then exit;

 if(upr<=0)and(d=-1)then exit;

 if d=1 then begin
  cost:=calc_upg_price(g,cur,base,zm3.upd_elems[par].tp,reslevel);
  if cost=-1 then exit;
  if cost>zm3.cur_gold then exit;

  zm3.cur_gold:=zm3.cur_gold-cost;
  upd^:=upd^+get_upg_inc(base);
 end else begin
  cost:=get_upg_cost(g,base,cur-get_upg_inc(base),cur,reslevel,zm3.upd_elems[par].tp);
  if cost=-1 then exit;

  zm3.cur_gold:=zm3.cur_gold+cost;
  upd^:=upd^-get_upg_inc(base);
 end;
end;
//############################################################################//
procedure upg_menu_accept(g:pgametyp;zm3:pbuy_menu_rec);
var i:integer;
pl:pplrtyp;
begin
 pl:=get_cur_plr(g);
 for i:=0 to length(pl.unupd)-1 do begin
  if non_zero_stats(pl.tmp_unupd[i].bas) then inc(pl.unupd[i].mk);
  pl.unupd[i].bas:=add_stats(pl.unupd[i].bas,pl.tmp_unupd[i].bas);
 end;
 pl.gold:=zm3.cur_gold;
 act_set_upgrades(g);
end;
//############################################################################//
//Buys menu action
procedure upg_menu_pre_init(g:pgametyp;zm3:pbuy_menu_rec;list_step:integer);
var i:integer;
pl:pplrtyp;
rul:prulestyp;
u:ptypunits;
begin
 common_pre_init(g,zm3,list_step,1,true);

 rul:=get_rules(g);
 pl:=get_cur_plr(g);
 zm3.mat_cur:=0;

 if rul.direct_gold then begin
  u:=get_sel_unit(g);
  zm3.pre_upgrades_gold:=get_rescount(g,u,RES_GOLD,GROP_NOW);
 end else zm3.pre_upgrades_gold:=pl.gold;
 zm3.cur_gold:=zm3.pre_upgrades_gold;

 for i:=0 to length(pl.tmp_unupd)-1 do begin
  pl.tmp_unupd[i]:=pl.unupd[i];
  zero_stats(pl.tmp_unupd[i].bas);
 end;
end;
//############################################################################//
//Buys menu action
procedure upg_menu_post_init(g:pgametyp;zm3:pbuy_menu_rec);
var p,pb:ptyp_unupd;
pl:pplrtyp;
un:integer;
begin
 pl:=get_cur_plr(g);
 un:=zm3.list[zm3.list_sel];
 p:=@pl.tmp_unupd[un];
 pb:=@pl.unupd[un];
 common_post_init(g,zm3,pl,p,get_clan(g,pl.info.clan),add_stats(p.bas,pb.bas));
end;
//############################################################################//
//Buys menu action
procedure upg_menu_arrow(g:pgametyp;zm3:pbuy_menu_rec;tp,par:integer); 
var un,reslevel:integer;
p:ptyp_unupd;
pl:pplrtyp;
sup:statrec;
begin   
 pl:=get_cur_plr(g);
 un:=zm3.list[zm3.list_sel];
 p:=@pl.tmp_unupd[un];
 sup:=add_stats(p.bas,pl.unupd[un].bas);
 if zm3.upd_elems[par].tp<8 then reslevel:=pl.rsrch_level[zm3.upd_elems[par].tp]*10 else reslevel:=0;

 common_arrow(g,zm3,tp,par,get_clan(g,pl.info.clan),p,sup,reslevel);
 upg_menu_post_init(g,zm3);
end; 
//############################################################################//
procedure buy_menu_accept(g:pgametyp;zm3:pbuy_menu_rec);
begin
 plr_begin.stgold:=zm3.cur_gold;  //FIXME: This should really be computed at the server...
end;
//############################################################################//
//Buys menu action
procedure buy_menu_pre_init(g:pgametyp;zm3:pbuy_menu_rec;list_step,bought_step:integer;base:boolean);
var i:integer;
begin
 common_pre_init(g,zm3,list_step,bought_step,false);

 zm3.mat_cur:=0;
 if plr_begin.bgncnt<>0 then zm3.mat_cur:=plr_begin.bgn[0].mat;

 zm3.pre_upgrades_gold:=plr_begin.stgold;
 zm3.cur_gold:=zm3.pre_upgrades_gold;

 for i:=0 to length(plr_begin.init_unupd)-1 do zero_stats(plr_begin.init_unupd[i].bas);
end;
//############################################################################//
//Buys menu action
procedure buy_menu_post_init(g:pgametyp;zm3:pbuy_menu_rec);
var p:ptyp_unupd;
begin
 p:=@plr_begin.init_unupd[zm3.list[zm3.list_sel]];
 common_post_init(g,zm3,nil,p,get_clan(g,plr_begin.clan),p.bas);
end;
//############################################################################//
//Buys menu action
procedure buy_menu_arrow(g:pgametyp;zm3:pbuy_menu_rec;tp,par:integer);
var p:ptyp_unupd;
begin
 p:=@plr_begin.init_unupd[zm3.list[zm3.list_sel]];
 common_arrow(g,zm3,tp,par,get_clan(g,plr_begin.clan),p,p.bas,0);
 buy_menu_post_init(g,zm3);
end;
//############################################################################//
procedure set_begin_mat(g:pgametyp;zm3:pbuy_menu_rec;par:integer);
var dx:integer;  
begin    
 if par<0 then exit;
 if par>zm3.mat_max then exit;

 dx:=(par-zm3.mat_cur) div material_step;
 if zm3.cur_gold>=dx then begin
  zm3.cur_gold:=zm3.cur_gold-dx;
  zm3.mat_cur:=par;
 end;
end;
//############################################################################//
procedure begins_buy(g:pgametyp;zm3:pbuy_menu_rec;x,y,n:integer;is_full:boolean;rul:prulestyp);
var i,r:integer;      
ud:ptypunitsdb;
begin   
 ud:=get_unitsdb(g,n);
 if not is_beginable_unit(g,rul,n) then exit;

 i:=ord(is_full)*begin_unit_res_capacity(g,n);
 if zm3.cur_gold<ud.bas.cost+i then exit;

 r:=add_begin_unit(g,rul,n,x,y,is_full);
 if r=-1 then exit;

 zm3.mat_cur:=plr_begin.bgn[r].mat;
 zm3.bought_sel:=r;
 zm3.bought_off:=(zm3.bought_sel div zm3.bought_step)*zm3.bought_step;
 zm3.cur_gold:=zm3.cur_gold-ud.bas.cost-i;
end;      
//############################################################################//
procedure begins_sell(g:pgametyp;zm3:pbuy_menu_rec;n:integer);
var ud:ptypunitsdb;
begin   
 ud:=get_unitsdb(g,getdbnum(g,plr_begin.bgn[n].typ));

 zm3.cur_gold:=zm3.cur_gold+ud.bas.cost+plr_begin.bgn[n].mat div material_step+ord((plr_begin.bgn[n].mat mod material_step)<>0);
 rem_begin_unit(g,n);

 if n>=zm3.bought_sel then begin
  zm3.bought_sel:=zm3.bought_sel-1;
  if (zm3.bought_off=plr_begin.bgncnt)and(zm3.bought_off>0) then zm3.bought_off:=zm3.bought_off-zm3.bought_step;
 end;    
 if zm3.bought_sel>=0 then zm3.mat_cur:=plr_begin.bgn[zm3.bought_sel].mat;
end;
//############################################################################//
procedure begins_select_set(g:pgametyp;zm3:pbuy_menu_rec;n:integer);
var i:integer;
begin     
 if(n>=0)and(n<=plr_begin.bgncnt-1)then begin
  zm3.bought_sel:=n;
  zm3.mat_cur:=plr_begin.bgn[zm3.bought_sel].mat;
  for i:=0 to length(zm3.list)-1 do if zm3.list[i]=getdbnum(g,plr_begin.bgn[zm3.bought_sel].typ) then begin zm3.list_sel:=i; break end;

  if zm3.list_sel<zm3.list_off then zm3.list_off:=zm3.list_sel;
  if zm3.list_sel>=zm3.list_off+zm3.list_step then zm3.list_off:=zm3.list_sel-zm3.list_step+1;

  if zm3.list_off>=length(zm3.list) then zm3.list_off:=length(zm3.list)-zm3.list_step;
  if zm3.list_off<0 then zm3.list_off:=0;
 end else begin
  zm3.bought_sel:=-1;
  zm3.mat_cur:=0;
 end;
 zm3.bought_off:=(zm3.bought_sel div zm3.bought_step)*zm3.bought_step;
end;
//############################################################################//
function buy_compute_upgrades(g:pgametyp;zm:pbuy_menu_rec;p:ptyp_unupd;rul:prulestyp):integer;
var i,c:integer;
ud:ptypunitsdb;
begin
 result:=0;
 if length(zm.list)=0 then exit;

 ud:=get_unitsdb(g,zm.list[zm.list_sel]);

 for i:=0 to length(zm.upd_elems)-1 do zm.upd_elems[i].tp:=-1;

 c:=0;
 if ud.bas.attk>0  then begin zm.upd_elems[c].vl:=p.bas.attk; zm.upd_elems[c].tp:=ut_attk; c:=c+1;end;
 if ud.bas.shoot>0 then begin zm.upd_elems[c].vl:=p.bas.shoot;zm.upd_elems[c].tp:=ut_shot; c:=c+1;end;
 if ud.bas.range>0 then begin zm.upd_elems[c].vl:=p.bas.range;zm.upd_elems[c].tp:=ut_range;c:=c+1;end;
 if ud.bas.ammo>0  then begin zm.upd_elems[c].vl:=p.bas.ammo; zm.upd_elems[c].tp:=ut_ammo; c:=c+1;end;
 if ud.bas.armr>0  then begin zm.upd_elems[c].vl:=p.bas.armr; zm.upd_elems[c].tp:=ut_armor;c:=c+1;end;
 if ud.bas.hits>0  then begin zm.upd_elems[c].vl:=p.bas.hits; zm.upd_elems[c].tp:=ut_hits; c:=c+1;end;
 if ud.bas.scan>0  then begin zm.upd_elems[c].vl:=p.bas.scan; zm.upd_elems[c].tp:=ut_scan; c:=c+1;end;
 if ud.bas.speed>0 then begin zm.upd_elems[c].vl:=p.bas.speed;zm.upd_elems[c].tp:=ut_speed;c:=c+1;end;
 if (ud.bas.fuel>0)and rul.fueluse then begin zm.upd_elems[c].vl:=p.bas.fuel; zm.upd_elems[c].tp:=ut_fuel;c:=c+1;end; //FIXME: Should get the right rusel

 result:=c;
end;
//############################################################################//
begin
end.
//############################################################################//
