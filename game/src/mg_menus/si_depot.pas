//############################################################################//
//Depot menu
unit si_depot;
interface
uses asys,strval,grph,graph8,sdigrtools,
mgrecs,mgl_common,mgl_attr,mgl_depot,mgl_actions,mgl_mapclick
,sds_rec,sdirecs,sdicalcs,sdisound,sdimenu,sdigui,sdi_int_elem;
//############################################################################//
implementation                                                                
//############################################################################//
const
xs=640;
ys=514;
//############################################################################//
DBTN_EX =0;       //Exit
DBTN_RL =1;       //Reload
DBTN_RP =2;       //Repair
DBTN_RF =3;       //Refuel
DBTN_UG =4;       //Upgrade
DBTN_COUNT=DBTN_UG+1;
DBTN_CNT=6; //max number of buttons on page
DBTN_NA=-1;
DBTN_DN=1;
DBTN_UP=0;           
//############################################################################//
//Depot commands
DP_EXIT_ALL=0;
DP_RELOAD_ALL=1;
DP_REFUEL_ALL=2;
DP_REPAIR_ALL=3;
DP_UPGRADE_ALL=4;
//############################################################################//
var 
depot_pgscr:pscrollbox_type;  //page scroller id    

depot_btn:array[0..DBTN_COUNT-1]of pbutton_type;

depot_bst:array[0..DBTN_CNT-1,0..DBTN_COUNT-1]of integer;//Unit buttons status
depot_bfr:array[0..DBTN_CNT-1,0..DBTN_COUNT-1]of vcomp;  //Unit buttons frame
depot_bt:array[0..DBTN_COUNT-1]of string;                //Unit buttons Text
depot_line:integer;  //number of units in one line (hangar=2, others=3)         
//############################################################################//
depot_menu:gm_depot_rec;                 //Depot menu                
//############################################################################//
procedure depot_forall(s:psdi_rec;typ:integer);
var i:integer;
u,su:ptypunits;
begin      
 su:=get_sel_unit(s.the_game);    
 if not isa(s.the_game,su,a_building) then exit;
 if typ=DP_EXIT_ALL then begin
  do_depot_release_all(s.the_game,su);
  clear_menu(s);
  exit;
 end;
 for i:=0 to get_units_count(s.the_game)-1 do begin
  u:=get_unit(s.the_game,i);
  if u=nil then continue;
  if u.stored and(u.stored_in=su.num) then case typ of
   DP_RELOAD_ALL:act_toolunit(s.the_game,tool_reload,su,u);
   DP_REFUEL_ALL:act_toolunit(s.the_game,tool_refuel,su,u);
   DP_REPAIR_ALL:act_toolunit(s.the_game,tool_repair,su,u);
   DP_UPGRADE_ALL:act_toolunit(s.the_game,tool_upgrade,su,u); 
  end;
 end;   
 update_depot_menu_mat(s.the_game,@depot_menu,su);
end;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin 
 if sds_is_replay(@s.steps) then exit;
 case par of
  39:; 
  501:depot_forall(s,DP_EXIT_ALL);
  502:depot_forall(s,DP_RELOAD_ALL);
  503:depot_forall(s,DP_REPAIR_ALL);
  504:depot_forall(s,DP_REFUEL_ALL);
  505:depot_forall(s,DP_UPGRADE_ALL);
 end;
end;    
//############################################################################//
procedure draw_depot_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var su,u:ptypunits;
ud:ptypunitsdb;
i,j,sn,x,y,xh,yh,st,c,pcnt,cx,cy,blk_xs,blk_ys,tp,xoff,yoff,btn_gap:integer;
f:vcomp;
begin
 su:=get_sel_unit(s.the_game);
 if su=nil then exit;
 ud:=get_unitsdb(s.the_game,su.dbn);

 xoff:=5;
 yoff:=10;
 btn_gap:=2;
 if ud.store_air=0 then begin depot_line:=3;blk_xs:=128;end else begin depot_line:=2;blk_xs:=200;end;
 blk_ys:=128;
 cx:=blk_xs+5;
 cy:=blk_ys+5+5+80; //grid column width
 pcnt:=depot_line*2; //slot count on one page

 for i:=0 to 4 do depot_btn[i].vis:=isa(s.the_game,su,a_building);
 
 ///WTF!?!
 //init unit buttons
 for i:=0 to pcnt-1 do for j:=0 to DBTN_COUNT-1 do begin
  depot_bfr[i,j].sx:=(blk_xs-btn_gap*3) div 2;
  depot_bfr[i,j].sy:=20;
  depot_bfr[i,j].x:=xn+xoff+btn_gap+cx*(i mod depot_line)+(j div 2)*(depot_bfr[i,j].sx+1);
  depot_bfr[i,j].y:=yn+yoff+     16+cy*(i div depot_line)+(j mod 2)*(depot_bfr[i,j].sy+1);
  if j=DBTN_UG then begin //Upgrade has same position as Repair   
   depot_bfr[i,j].x:=depot_bfr[i,DBTN_RP].x;
   depot_bfr[i,j].y:=depot_bfr[i,DBTN_RP].y;
  end;
 end;

 tp:=GRP_EDEPOT;
 if ud.store_wtr>0 then tp:=GRP_EDOCK;
 if ud.store_air>0 then tp:=GRP_EHANGAR;

 for i:=0 to pcnt-1 do begin
  tran_rect8(s.cg,dst,      xn+xoff+cx*(i mod depot_line)-1,yn+yoff+cy*(i div depot_line)-1,blk_xs+2,blk_ys+2,0);
  putspr8(dst,s.cg.grap[tp],xn+xoff+cx*(i mod depot_line)  ,yn+yoff+cy*(i div depot_line));
 end;

 depot_pgscr.bottom:=depot_menu.ucnt div pcnt-ord((depot_menu.ucnt mod pcnt)=0);
 if depot_menu.ucnt<=pcnt then depot_menu.pg:=0;
 for i:=pcnt*depot_menu.pg to pcnt*(depot_menu.pg+1)-1 do if i<depot_menu.ucnt then begin
  sn:=i-pcnt*depot_menu.pg; //slot numbet
  u:=get_unit(s.the_game,depot_menu.ulst[i]);
  xh:=xn+xoff+cx*(sn mod depot_line);
  yh:=yn+yoff+cy*(sn div depot_line);

  if u.grp_db<>-1 then if s.eunitsdb[u.grp_db].img_depot.ex then putspr8(dst,@s.eunitsdb[u.grp_db].img_depot.sprc[0],xh,yh);
  wrtxtxbox8(s.cg,dst,xh+btn_gap,yh+btn_gap,blk_xs,24,unit_mk(u)+unit_name(s.the_game,u)+base_mk(s.the_game,u,true),17);

  //check exit available
  if s.the_game.info.rules.unload_one_speed and(u.cur.speed<10)then depot_bst[sn,DBTN_EX]:=DBTN_NA else if depot_bst[sn,DBTN_EX]=DBTN_NA then depot_bst[sn,DBTN_EX]:=DBTN_UP;
  //check resources available
  if depot_menu.mat<=0 then begin
   depot_bst[sn,DBTN_RL]:=DBTN_NA;
   depot_bst[sn,DBTN_RP]:=DBTN_NA;
   depot_bst[sn,DBTN_UG]:=DBTN_NA;
  end else begin
   //check unit status
   if u.cur.hits<u.bas.hits then begin
    if depot_bst[sn,DBTN_RP]=DBTN_NA then depot_bst[sn,DBTN_RP]:=DBTN_UP;
    depot_bst[sn,DBTN_UG]:=DBTN_NA; //hide upgrade because repair needed
   end else begin
    depot_bst[sn,DBTN_RP]:=DBTN_NA; //hide repair button
         if not isa(s.the_game,u,a_upgradable) then depot_bst[sn,DBTN_UG]:=DBTN_NA
    else if(depot_bst[sn,DBTN_UG]=DBTN_NA)     then depot_bst[sn,DBTN_UG]:=DBTN_UP;
   end;
        if(u.bas.ammo=0)or(u.cur.ammo=u.bas.ammo)then depot_bst[sn,DBTN_RL]:=DBTN_NA
   else if depot_bst[sn,DBTN_RL]=DBTN_NA         then depot_bst[sn,DBTN_RL]:=DBTN_UP;
  end;
  
  if not s.the_game.info.rules.fueluse or (depot_menu.fuel<=0) then begin
   depot_bst[sn,DBTN_RF]:=DBTN_NA
  end else begin
   if depot_bst[sn,DBTN_RF]=DBTN_NA then depot_bst[sn,DBTN_RF]:=DBTN_UP;
   if (u.bas.fuel=0)or(u.cur.fuel=u.bas.fuel*10) then depot_bst[sn,DBTN_RF]:=DBTN_NA;
  end;
  
  //Draw Unit buttons
  for j:=0 to DBTN_COUNT-1 do if depot_bst[sn,j]<>DBTN_NA then begin //DBTN_NA mean button is not available
   f:=depot_bfr[sn,j];
   case depot_bst[sn,j] of
    -1,0:st:=0;
    else st:=1;
   end;
   gcrxy(f,x,y);
   tran_rect8(s.cg,dst,x,y,depot_bfr[sn,j].sx,depot_bfr[sn,j].sy,ord(st));

   case depot_bst[sn,j] of
    -1,0:c:=0;
    else c:=5;
   end;
   gcrmxy(f,x,y);
   if j=DBTN_UG then wrtxtcnt8(s.cg,dst,x,y-2,depot_bt[j]+'('+stri(u.bas.cost div 4)+')',c)
                else wrtxtcnt8(s.cg,dst,x,y-2,depot_bt[j],c);
  end;

  //Statictics 
  tran_rect8(s.cg,dst,xh        ,yh+blk_ys+  btn_gap,blk_xs          ,cy-2*btn_gap-blk_ys,0);
  draw_stats_un(s,dst,xh+btn_gap,yh+blk_ys+2*btn_gap,blk_xs-2*btn_gap,cy-2*btn_gap-blk_ys-2*btn_gap,u,false,2);
 end;
 
 if(depot_menu.mat<>0)and(depot_menu.mattot<>0)then begin
  xh:=round((depot_menu.mat/depot_menu.mattot)*115);
  yh:=115-xh;
  putsprtcut8(dst,@s.cg.grapu[GRU_VERTBAR].sprc[0],xn+565,yn+123+yh,0,0,1000,xh,0);
 end;
 if(depot_menu.fuel<>0)and(depot_menu.fueltot<>0)then begin
  xh:=round((depot_menu.fuel/depot_menu.fueltot)*115);
  yh:=115-xh;
  putsprtcut8(dst,@s.cg.grapu[GRU_VERTBAR].sprc[1],xn+527,yn+123+yh,0,0,1000,xh,0);
 end;
 wrtxtcnt8(s.cg,dst,xn+586,yn+085,stri(depot_menu.mat),4);
 wrtxtcnt8(s.cg,dst,xn+526,yn+085,stri(depot_menu.fuel),4);
end;     
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;
 enter_depot_menu(s.the_game,@depot_menu,get_sel_unit(s.the_game));
end;                                             
//############################################################################//
function init(s:psdi_rec):boolean;   
const depotutil:array[0..4]of string=('Activate','Reload','Repair','Refuel','Upgrade');   
var mn,pg,i,j:integer;
begin         
 result:=true;    
 if s.state<>CST_THEGAME then exit;

 //Game
 for i:=0 to DBTN_CNT-1 do for j:=0 to DBTN_COUNT-1 do depot_bst[i,j]:=0;
 depot_bt[DBTN_EX]:=po('Leave');
 depot_bt[DBTN_RL]:=po('Reload');
 depot_bt[DBTN_RF]:=po('Refuel');
 depot_bt[DBTN_RP]:=po('Repair');
 depot_bt[DBTN_UG]:=po('Upgrade');
 
 mn:=MG_DEPOT;
 pg:=0;
 add_label    (mn,pg,586,056,1,4,po('Raw'));
 add_label    (mn,pg,526,056,1,4,po('Fuel'));
 add_label    (mn,pg,586,070,1,4,po('in complex'));
 add_label    (mn,pg,526,070,1,4,po('in complex')); 
   
 add_label    (mn,pg,552,243,1,4,po('For all'));
 
 add_button   (mn,pg,511,388,94,24,0,5,po('Back'),on_cancel_btn,0);
 for i:=0 to 4 do depot_btn[i]:=add_button(mn,pg,511,257+i*25,94,24,0,5,po(depotutil[i]),on_btn,501+i);

 depot_pgscr:=add_scrollbox(mn,pg,SCB_VERTICAL,505,461,531,461,24,25,1,0,2,false,@depot_menu.pg,on_btn,39);
end;
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i,j:integer;
begin
 result:=true;
 for i:=0 to depot_line*2-1 do for j:=0 to DBTN_COUNT-1 do if(depot_bst[i,j]<>DBTN_NA)and inrectv(x,y,depot_bfr[i,j]) then begin
  snd_click(SND_ACCEPT);
  depot_bst[i,j]:=DBTN_DN;
 end;
end;
//############################################################################//
function mouseup(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i,j,un:integer;
su,u:ptypunits;
begin    
 result:=true;
 for i:=0 to depot_line*2-1 do for j:=0 to DBTN_COUNT-1 do begin
  if (depot_bst[i,j]=1) and inrectv(x,y,depot_bfr[i,j]) then begin
   u:=get_unit(s.the_game,depot_menu.ulst[i]);
   if i<depot_menu.ucnt then if u.stored then begin
    su:=get_sel_unit(s.the_game);
    un:=depot_menu.ulst[i+depot_menu.pg*depot_line*2];
    case j of
     DBTN_EX:begin do_depot_release(s.the_game,get_unit(s.the_game,un));clear_menu(s);end;
     DBTN_RL:act_toolunit(s.the_game,tool_reload,su,get_unit(s.the_game,un));
     DBTN_RF:act_toolunit(s.the_game,tool_refuel,su,get_unit(s.the_game,un));
     DBTN_RP:act_toolunit(s.the_game,tool_repair,su,get_unit(s.the_game,un));
     DBTN_UG:act_toolunit(s.the_game,tool_upgrade,su,get_unit(s.the_game,un));
    end;
    update_depot_menu_mat(s.the_game,@depot_menu,su);
   end;
  end;
  depot_bst[i,j]:=0;
 end;
end;
//############################################################################//
begin      
 add_menu('Depot menu',MG_DEPOT,xs div 2,ys div 2,BCK_SHADE,init,nil,draw_depot_menu,nil,nil,enter,nil,nil,nil,mousedown,mouseup,nil,nil);
end.
//############################################################################//
