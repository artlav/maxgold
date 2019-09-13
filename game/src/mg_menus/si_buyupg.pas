//############################################################################//
//Purchases and upgrades menu
unit si_buyupg;
interface
uses sysutils,asys,strval,grph,graph8,sdigrtools,
mgrecs,mgl_common,mgl_buy,mgl_land,sdirecs,sdiauxi,sdicalcs,sdimenu,sdigui,sdisound,sdi_int_elem
,sdi_rec
;
//############################################################################//
var buy_menu:buy_menu_rec;
//############################################################################//
implementation
//############################################################################//
const
menu_xs=607;
menu_ys=500;

unit_list_step=9;
bought_list_step=6;

filter_sz=28;

img_xp=10;
img_yp=10;
img_xs=300;
img_ys=240;

stats_xp=img_xp;
stats_yp=img_yp+img_ys+5+text_box_hei+5;
stats_xs=250;
stats_ys=11*upg_step+9;

upg_xp=stats_xp+stats_xs+2*elem_gap;
upg_yp=stats_yp+4;
upg_txt_xp=upg_xp+scroller_sz+elem_gap+scroller_sz+elem_gap+upg_txt_xs;
upg_txt_yp=upg_yp+6;

beg_xp=img_xp+img_xs+5;
beg_yp=img_yp+caption_ys;
beg_xs=130;
beg_ys=bought_list_step*list_elem_ys+2*elem_gap;

list_xp=img_xp+img_xs+5+beg_xs+5;
list_yp=50;
list_xs=150;
list_ys=unit_list_step*list_elem_ys+2*elem_gap;
 
gold_xp=upg_txt_xp+20;
gold_yp=stats_yp;
gold_xs=20;
gold_ys=115;

mat_xp=gold_xp+50;
mat_yp=gold_yp;
mat_xs=gold_xs;
mat_ys=gold_ys;
//############################################################################//
var
common_inited:boolean=false;
plr_tb:ptextbox_type;
buyupg_showdesc:boolean=true;

mat_elem,gold_elem:material_bit_rec;
unit_list,begin_list:unit_list_rec;
upgraders:upgrade_block_rec;
//############################################################################//
procedure on_scr_buyupg(s:psdi_rec;par,px:dword);
begin 
 case par of
  33:begin
   buy_menu.list_off:=unit_list.off;
   buy_menu.list_sel:=unit_list.sel;
   calcmnuinfo(s,s.cur_menu);
  end;
  34:begin
   set_begin_mat(s.the_game,@buy_menu,mat_elem.cur);
   calcmnuinfo(s,s.cur_menu);
  end;
  35:begin 
   buy_menu.list_off:=unit_list.off;
   buy_menu.list_sel:=unit_list.sel;
   buy_menu.bought_off:=begin_list.off;
   buy_menu.bought_sel:=begin_list.sel;
   calcmnuinfo(s,s.cur_menu);
   event_frame(s);
  end;
  //buy upgrades
  41..49:begin  
   buy_menu.upd_elems[par-41].vl:=upgraders.vl[par-41];
   case s.cur_menu of
    MS_BUYINIT:  buy_menu_arrow(s.the_game,@buy_menu,px,par-41);
    MG_UPGRMONEY:upg_menu_arrow(s.the_game,@buy_menu,px,par-41);
   end;
   calcmnuinfo(s,s.cur_menu);
  end;
 end;
end;
//############################################################################//
procedure on_cbx_buyupg(s:psdi_rec;par,px:dword);
begin 
 case par of  
  //Upgrades chng
  35:recalc_buy_menu_list(s.the_game,@buy_menu,get_rules(s.the_game));
 end;
end;
//############################################################################//
procedure draw_upgrade_controls(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,j:integer;
begin
 j:=0;
 for i:=0 to 8 do if buy_menu.upd_elems[i].tp<>-1 then begin 
  upgraders.vl[i]:=buy_menu.upd_elems[i].vl;
  if buy_menu.upd_elems[i].cost<>-1 then wrtxtr8(s.cg,dst,xn+upg_txt_xp,yn+upg_txt_yp+j*upg_step,stri(buy_menu.upd_elems[i].cost),6);
  if (buy_menu.upd_elems[i].cost>buy_menu.cur_gold)or(buy_menu.upd_elems[i].cost=-1) then begin
   if (buy_menu.upd_elems[i].cost=-1)then wrtxtr8(s.cg,dst,xn+upg_txt_xp,yn+upg_txt_yp+j*upg_step,'>>',2)
                                     else wrtxtr8(s.cg,dst,xn+upg_txt_xp,yn+upg_txt_yp+j*upg_step,stri(buy_menu.upd_elems[i].cost),2);

   if upgraders.scr[i]<>nil then upgraders.scr[i].bottom:=buy_menu.upd_elems[i].vl;
  end else begin
   if upgraders.scr[i]<>nil then upgraders.scr[i].bottom:=1000;
  end;
  if upgraders.scr[i]<>nil then upgraders.scr[i].top:=0;
  j:=j+1;
 end;
end; 
//############################################################################//
procedure draw_poster(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var ud:ptypunitsdb;
en:ptypeunitsdb;
begin
 if buy_menu.list_sel>=get_unitsdb_count(s.the_game) then exit;

 ud:=get_unitsdb(s.the_game,buy_menu.list[buy_menu.list_sel]);
 en:=get_edb(s,ud.typ);

 drrectx8(dst,xn+img_xp-1,yn+img_yp-1,img_xs+2,img_ys+2,line_color);
 if en<>nil then if length(en.img_poster.sprc)<>0 then putspr8(dst,@en.img_poster.sprc[0],xn+img_xp,yn+img_yp);
 if buyupg_showdesc then begin
  if lrus then wrtxtxbox8(s.cg,dst,xn+img_xp+10,yn+img_yp+10,img_xs-20,img_ys-20,ud.descr_rus,0)
          else wrtxtxbox8(s.cg,dst,xn+img_xp+10,yn+img_yp+10,img_xs-20,img_ys-20,ud.descr_eng,0);
 end;
end;
//############################################################################//
procedure fill_list(s:psdi_rec;buy:pbuy_menu_rec;var z:unit_list_rec);
var i:integer;
ud:ptypunitsdb;
begin
 setlength(z.list,length(buy.list));
 for i:=0 to length(z.list)-1 do begin
  ud:=get_unitsdb(s.the_game,buy.list[i]);
  z.list[i].dbn:=buy.list[i];
  z.list[i].cost:=ud.bas.cost;
  z.list[i].par:='';
  z.list[i].idx:='';
 end;

 set_unit_list(z,buy.list_sel,buy.list_off,buy.cur_gold);
end;
//############################################################################//
procedure fill_begin_list(s:psdi_rec;buy:pbuy_menu_rec;var z:unit_list_rec);
var i,j,n,k,uidx,ri,mat:integer;
ud:ptypunitsdb;
st:string;
begin
 setlength(z.list,plr_begin.bgncnt);
 for i:=0 to length(z.list)-1 do begin
  n:=getdbnum(s.the_game,plr_begin.bgn[i].typ);
  ud:=get_unitsdb(s.the_game,n);
  z.list[i].dbn:=n;
  z.list[i].cost:=ud.bas.cost;

  uidx:=1;
  for k:=0 to i-1 do if plr_begin.bgn[k].typ=plr_begin.bgn[i].typ then uidx:=uidx+1;
  z.list[i].idx:=stri(uidx);

  j:=0;
  for ri:=RES_MINING_MIN to RES_MINING_MAX do if ud.prod.num[ri]<>0 then j:=ud.prod.num[ri];
  if j<>0 then begin
   mat:=plr_begin.bgn[i].mat;
   st:='('+stri(mat)+' <';
   k:=0;
   if mat=0 then k:=0;
   if mat>0 then k:=1;
   if mat>=(j/2) then k:=2;
   if mat=j then k:=3;
   case k of
    0:st:=st+'   ';
    1:st:=st+'-  ';
    2:st:=st+'-- ';
    3:st:=st+'===';
   end;
   st:=st+'>)';

   z.list[i].par:=st;
  end else z.list[i].par:='';
 end;

 set_unit_list(z,buy.bought_sel,buy.bought_off,buy.cur_gold);
end;
//############################################################################//
procedure draw_upg_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var pl:pplrtyp;
begin
 if not s.frame_map_ev then exit;
 pl:=get_cur_plr(s.the_game);

 //Gold
 set_material_bit(gold_elem,buy_menu.cur_gold,buy_menu.pre_upgrades_gold,2);
 draw_material_bit(s,dst,xn,yn,gold_elem);
  
 //Main
 if length(buy_menu.list)<>0 then begin
  tran_rect8(s.cg,dst,xn+stats_xp-1,yn+stats_yp-1,stats_xs+2,stats_ys+2,0);
  draw_stats_db(s,dst,xn+stats_xp,yn+stats_yp,stats_xs,stats_ys,get_unitsdb(s.the_game,buy_menu.list[buy_menu.list_sel]),get_rules(s.the_game),true);
  draw_upgrade_controls(s,dst,xn,yn);

  unit_list.show_cost:=false;
  fill_list(s,@buy_menu,unit_list);
  draw_unit_list(s,dst,xn,yn,unit_list,pl.num);

  draw_poster(s,dst,xn,yn);
 end;
end;
//############################################################################//  
procedure draw_buys_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var cp:pplrtyp;
begin
 if s.the_game=nil then exit;
 if not s.frame_map_ev then exit;
 cp:=get_cur_plr(s.the_game);
 if cp=nil then exit;

 if plr_tb=nil then exit;
 plr_tb.vr^:=cp.info.name;

 //Gold         
 set_material_bit(gold_elem,buy_menu.cur_gold,buy_menu.pre_upgrades_gold,2);
 draw_material_bit(s,dst,xn,yn,gold_elem);

 //Selected
 fill_begin_list(s,@buy_menu,begin_list);
 draw_unit_list(s,dst,xn,yn,begin_list,get_cur_plr_id(s.the_game));

 //Cargo  
 set_material_bit(mat_elem,buy_menu.mat_cur,buy_menu.mat_max,buy_menu.mat_kind);
 draw_material_bit(s,dst,xn,yn,mat_elem);

 //Main
 if length(buy_menu.list)<>0 then begin      
  tran_rect8(s.cg,dst,xn+stats_xp-1,yn+stats_yp-1,stats_xs+2,stats_ys+2,0);
  draw_stats_ng(s,dst,xn+stats_xp,yn+stats_yp,stats_xs,stats_ys,get_unitsdb(s.the_game,buy_menu.list[buy_menu.list_sel]),get_rules(s.the_game),@plr_begin);
  draw_upgrade_controls(s,dst,xn,yn);

  unit_list.show_cost:=true;
  fill_list(s,@buy_menu,unit_list);
  draw_unit_list(s,dst,xn,yn,unit_list,get_cur_plr_id(s.the_game));

  draw_poster(s,dst,xn,yn);
 end;
end;
//############################################################################//
function keydown_buy(s:psdi_rec;key,shift:dword):boolean;
//var ud:ptypunitsdb;
begin
 result:=true;
 event_frame(s);

 case key of
  KEY_UP:if isf(shift,sh_shift) then begin
   begins_select_set(s.the_game,@buy_menu,buy_menu.bought_sel-1);
   snd_click(SND_DENY);
   calcmnuinfo(s,MS_BUYINIT);
  end else begin
   if buy_menu.list_sel>0 then begin
    buy_menu.list_sel:=buy_menu.list_sel-1;
    snd_click(SND_TCK);
   end;
   buy_menu.list_off:=(buy_menu.list_sel div buy_menu.list_step)*buy_menu.list_step;
  end;
  KEY_DWN:if isf(shift,sh_shift) then begin 
   begins_select_set(s.the_game,@buy_menu,buy_menu.bought_sel+1);
   snd_click(SND_DENY);
   calcmnuinfo(s,MS_BUYINIT);
  end else begin
   if buy_menu.list_sel<length(buy_menu.list)-1 then begin
    buy_menu.list_sel:=buy_menu.list_sel+1;
    snd_click(SND_TCK);
   end;
   buy_menu.list_off:=(buy_menu.list_sel div buy_menu.list_step)*buy_menu.list_step;
  end;
  KEY_LEFT:begin //dec materials
   //if isf(shift,sh_shift) then begin snd_click(SND_ACCEPT);set_begin_mat(s.the_game,@buy_menu,buy_materials.top);end
   //                       else begin snd_click(SND_TCK);   set_begin_mat(s.the_game,@buy_menu,buy_menu.mat_cur-material_step);end;
   calcmnuinfo(s,MS_BUYINIT);
  end;
  KEY_RIGHT:begin //inc materials
   //ud:=get_unitsdb(s.the_game,buy_menu.list[buy_menu.list_sel]);
   //if isf(shift,sh_shift) then begin snd_click(SND_ACCEPT);set_begin_mat(s.the_game,@buy_menu,max3i(ud.prod.num[RES_MAT],ud.prod.num[RES_FUEL],ud.prod.num[RES_GOLD]));end
   //                       else begin snd_click(SND_TCK);   set_begin_mat(s.the_game,@buy_menu,buy_menu.mat_cur+material_step);end;
   calcmnuinfo(s,MS_BUYINIT);
  end;
  KEY_SPACE:if plr_begin.bgncnt<100 then begin //Buy selected
   snd_click(SND_BUTTON);
   begins_buy(s.the_game,@buy_menu,0,0,buy_menu.list[buy_menu.list_sel],isf(shift,sh_shift),get_rules(s.the_game));
   calcmnuinfo(s,MS_BUYINIT);
  end;
  KEY_DEL:if buy_menu.bought_sel>=0 then if not plr_begin.bgn[buy_menu.bought_sel].locked then begin  //Remove selected
   snd_click(SND_BUTTON);
   begins_sell(s.the_game,@buy_menu,buy_menu.bought_sel);
  end;
 end;
end;
//############################################################################//
function keydown_upg(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;
 event_frame(s);

 case key of
  KEY_UP:begin
   if buy_menu.list_sel>0                       then begin buy_menu.list_sel:=buy_menu.list_sel-1;snd_click(SND_TCK);end;
   buy_menu.list_off:=(buy_menu.list_sel div buy_menu.list_step)*buy_menu.list_step;
  end;
  KEY_DWN:begin
   if buy_menu.list_sel<length(buy_menu.list)-1 then begin buy_menu.list_sel:=buy_menu.list_sel+1;snd_click(SND_TCK);end;
   buy_menu.list_off:=(buy_menu.list_sel div buy_menu.list_step)*buy_menu.list_step;
  end;
 end;
end;
//############################################################################//
function mousedown_buy(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var double:boolean;
begin
 result:=true;
 event_frame(s);

 //Bought list
 if mouse_unit_list(s,begin_list,0,x-xn,y-yn,0,double) then begin 
  begins_select_set(s.the_game,@buy_menu,begin_list.sel);
  if double then if buy_menu.bought_sel>=0 then if not plr_begin.bgn[buy_menu.bought_sel].locked then begins_sell(s.the_game,@buy_menu,buy_menu.bought_sel);
  event_map_reposition(s);
 end;

 //Main list 
 if mouse_unit_list(s,unit_list,0,x-xn,y-yn,0,double) then begin
  buy_menu.list_sel:=unit_list.sel;
  if double then begins_buy(s.the_game,@buy_menu,0,0,buy_menu.list[buy_menu.list_sel],isf(shift,sh_shift),get_rules(s.the_game));
  event_map_reposition(s);
 end;

 //Materials
 calcmnuinfo(s,MS_BUYINIT);
 if mouse_material_bit(mat_elem,0,x-xn,y-yn,0) then begin
  set_begin_mat(s.the_game,@buy_menu,mat_elem.cur);
  calcmnuinfo(s,MS_BUYINIT);
 end;
end;
//############################################################################//
function mousewheel_bgn(s:psdi_rec;shift:dword;dir,null,xn,yn:integer):boolean;
begin
 result:=true;

 //Material scroll
 if mouse_material_bit(mat_elem,2,curx-xn,cury-yn,dir) then begin
  set_begin_mat(s.the_game,@buy_menu,mat_elem.cur);
  calcmnuinfo(s,MS_BUYINIT);
  event_frame(s);
 end;
end;
//############################################################################//
function mousedown_upg(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var double:boolean;
begin
 result:=true;

 //Main list
 if mouse_unit_list(s,unit_list,0,x-xn,y-yn,0,double) then begin
  buy_menu.list_sel:=unit_list.sel;
  event_frame(s);
  event_map_reposition(s);
 end;

 calcmnuinfo(s,MG_UPGRMONEY);
end;
//############################################################################//
procedure init_common(s:psdi_rec);
var pg,i:integer;
mn:dword;
begin
 if common_inited then exit;
 common_inited:=true;
 pg:=0;

 mn:=MG_UPGRMONEY or MS_BUYINIT;

 add_label   (mn,pg,img_xp+5+20,img_yp+img_ys-16-5+5,LB_LEFT  ,7,po('Description'));
 add_checkbox(mn,pg,img_xp+5   ,img_yp+img_ys-16-5  ,16,16,nil,@buyupg_showdesc,nil);

 init_unit_list(unit_list,mn,pg,list_xp,list_yp,list_xs,list_ys,unit_list_step,po('Available'),true,6,2,text_color,on_scr_buyupg,33);
 init_material_bit(gold_elem,mn,pg,gold_xp,gold_yp,gold_xs,gold_ys,2,1,po('Credit'),true,false,nil,0);
 init_upgrade_block(upgraders,mn,pg,upg_xp,upg_yp,upg_step,on_scr_buyupg,41);

 for i:=0 to length(buy_menu.filters)-1 do begin
  add_checkbox(mn,pg,list_xp+i*(filter_sz+elem_gap),
                     list_yp+list_ys+elem_gap+scroller_sz+scroller_sz div 2,
                     filter_sz,filter_sz,nil,@buy_menu.filters[i],on_cbx_buyupg,35);
 end;

 add_button(mn,pg,gold_xp,menu_ys-35,75,28,0,5,po('Cancel'),on_cancel_btn,0);
 add_button(mn,pg,gold_xp,menu_ys-65,75,28,0,5,po('Done'),on_ok_btn,0);
end;
//############################################################################//
function init_buy(s:psdi_rec):boolean;
var mn,pg,yp:integer;
cb1,cb2:pcheckbox_type;
begin
 result:=true;

 mn:=MS_BUYINIT;
 pg:=0;

 init_common(s);
 add_label(mn,pg,list_xp+list_xs div 2,img_yp-2,LB_BIG_CENTER,0,po('Purchases'));

 add_label(mn,pg,img_xp,img_yp+img_ys+5+8,LB_LEFT,0,po('Player')+':');
 plr_tb:=add_textbox(mn,pg,img_xp+65,img_yp+img_ys+5,img_xs-65,true,2,nil,'player_name');

 init_unit_list(begin_list,mn,pg,beg_xp,beg_yp,beg_xs,beg_ys,bought_list_step,po('Purchased'),false,0,0,text_color,on_scr_buyupg,35);
 init_material_bit(mat_elem,mn,pg,mat_xp,mat_yp,mat_xs,mat_ys,0,material_step,po('Cargo'),false,true,on_scr_buyupg,34);

 yp:=list_yp+list_ys+elem_gap+scroller_sz+scroller_sz div 2+filter_sz+scroller_sz div 2;
 add_label(mn,pg,list_xp+filter_sz+5,yp+filter_sz div 2-5                   ,LB_LEFT,7,po('Buy'));
 add_label(mn,pg,list_xp+filter_sz+5,yp+filter_sz div 2-5+filter_sz+elem_gap,LB_LEFT,7,po('Upgrade'));
 cb1:=add_checkbox(mn,pg,list_xp,yp                   ,filter_sz,filter_sz,nil,@buy_menu.isbuy,on_cbx_buyupg,35);
 cb2:=add_checkbox(mn,pg,list_xp,yp+filter_sz+elem_gap,filter_sz,filter_sz,cb1,@buy_menu.isupg,on_cbx_buyupg,35);
 cb1.linked_cb:=cb2;
end;
//############################################################################//
function init_upg(s:psdi_rec):boolean;
begin
 result:=true;
 init_common(s);
 add_label(MG_UPGRMONEY,0,list_xp+list_xs div 2,img_yp-2,LB_BIG_CENTER,0,po('Upgrades'));
end;
//############################################################################//
procedure deinit_common(s:psdi_rec);
var i:integer;
begin
 if not common_inited then exit;
 common_inited:=false;
 for i:=0 to length(upgraders.scr)-1 do upgraders.scr[i]:=nil;
 unit_list.sc:=nil;
 unit_list.cs:=nil;
 unit_list.ml:=nil;
 begin_list.sc:=nil;
 begin_list.cs:=nil;
 begin_list.ml:=nil;
end;
//############################################################################//
function deinit_buy(s:psdi_rec):boolean;
begin
 result:=true; 
 deinit_common(s);
end;
//############################################################################//
function deinit_upg(s:psdi_rec):boolean;
begin
 result:=true;
 deinit_common(s);
end;
//############################################################################//
function enter_buy(s:psdi_rec):boolean;
var rul:prulestyp;
begin
 result:=true;
 rul:=get_rules(s.the_game);

 clear_buy_menu(s.the_game,@buy_menu,rul);
 buy_menu_pre_init(s.the_game,@buy_menu,unit_list_step,bought_list_step,rul.direct_land);
 calcmnuinfo(s,MS_BUYINIT);
 recalc_buy_menu_list(s.the_game,@buy_menu,rul);
 buy_menu_post_init(s.the_game,@buy_menu);  
 calcmnuinfo(s,MS_BUYINIT);
end;
//############################################################################//
function enter_upg(s:psdi_rec):boolean; 
var rul:prulestyp;
begin
 result:=true;  
 rul:=get_rules(s.the_game);

 clear_buy_menu(s.the_game,@buy_menu,rul);
 upg_menu_pre_init(s.the_game,@buy_menu,unit_list_step);
 calcmnuinfo(s,MG_UPGRMONEY);
 recalc_buy_menu_list(s.the_game,@buy_menu,rul);
 upg_menu_post_init(s.the_game,@buy_menu); 
 calcmnuinfo(s,MG_UPGRMONEY);
end;
//############################################################################//
function ok_buy(s:psdi_rec):boolean;
begin 
 result:=true;
 buy_menu_accept(s.the_game,@buy_menu);  //FIXME: This thing's part should really be computed at the server...
 begin_player_landing(s);
end;
//############################################################################//
function ok_upg(s:psdi_rec):boolean;
begin 
 result:=true;
 upg_menu_accept(s.the_game,@buy_menu);
 clear_menu(s);
end;  
//############################################################################//
function cancel_buy(s:psdi_rec):boolean; 
begin
 result:=true;
 enter_menu(s,MS_CLANSELECT);
end;
//############################################################################//
function cancel_upg(s:psdi_rec):boolean; 
begin
 result:=true;
 clear_menu(s);
end;
//############################################################################//
procedure calc_common(s:psdi_rec;p:ptyp_unupd);
var i,c:integer;
begin     
 vis_upgrade_block(upgraders,length(buy_menu.upd_elems),false);
 c:=buy_compute_upgrades(s.the_game,@buy_menu,p,get_rules(s.the_game));
 vis_upgrade_block(upgraders,c,true);
 for i:=0 to c-1 do upgraders.vl[i]:=buy_menu.upd_elems[i].vl;
end;
//############################################################################//
function calc_buy(s:psdi_rec;par:integer):boolean;
var p:ptyp_unupd;
begin
 result:=true;

 fill_buy_menu_mat(s.the_game,@buy_menu);

 if length(buy_menu.list)<>0 then p:=@plr_begin.init_unupd[buy_menu.list[buy_menu.list_sel]] else p:=nil;
 calc_common(s,p);
 if length(buy_menu.list)<>0 then buy_menu_post_init(s.the_game,@buy_menu);
end;
//############################################################################//
function calc_upg(s:psdi_rec;par:integer):boolean;    
var pl:pplrtyp;
p:ptyp_unupd;
begin
 pl:=get_cur_plr(s.the_game);
 result:=true;

 if length(buy_menu.list)<>0 then p:=@pl.tmp_unupd[buy_menu.list[buy_menu.list_sel]] else p:=nil;
 calc_common(s,p);
 if length(buy_menu.list)<>0 then upg_menu_post_init(s.the_game,@buy_menu);
end;
//############################################################################//
begin
 add_menu('Purchases menu',MS_BUYINIT  ,menu_xs div 2,menu_ys div 2,BCK_SHADE,init_buy,deinit_buy,draw_buys_menu,ok_buy,cancel_buy,enter_buy,nil,calc_buy,keydown_buy,mousedown_buy,nil,nil,mousewheel_bgn);
 add_menu('Upgrades menu' ,MG_UPGRMONEY,menu_xs div 2,menu_ys div 2,BCK_SHADE,init_upg,deinit_upg,draw_upg_menu ,ok_upg,cancel_upg,enter_upg,nil,calc_upg,keydown_upg,mousedown_upg,nil,nil,nil);
end.
//############################################################################//   
