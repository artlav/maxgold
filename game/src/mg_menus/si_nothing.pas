//############################################################################//
//Interface "menu"
unit si_nothing;
interface
uses asys,maths,strval,grph,graph8,sdi_rec
,mgrecs,mgl_common,mgl_rmnu,mgl_buy,mgl_land
,sdirecs,sdimenu,sdigui,sdigrtools,sdicalcs,sdisound,sdi_int_elem,sdiauxi
,sds_util,sds_rec,sds_replay;
//############################################################################//
var btnx,btny,btnz,btnhlp,btnupg:pbutton_type;
btn_rep:array[0..4]of pbutton_type;
btn_rep_step:array[0..1]of pbutton_type;
no_reset:boolean=false;
//############################################################################//
implementation
//############################################################################//
const
stats_xs=250;
stats_ys=11*upg_step+9;
//############################################################################//
var unit_list:unit_list_rec;
mat_elem,gold_elem:material_bit_rec;
buy_menu:buy_menu_rec;
upgraders:upgrade_block_rec;

upg_xp,upg_txt_xp,upg_txt_yp:integer;
show_upg:boolean=false;
upg_cnt:integer=0;
//############################################################################//
function buys_active(s:psdi_rec):boolean;
var cp:pplrtyp;
rul:prulestyp;
begin
 result:=false;

 rul:=get_rules(s.the_game);
 cp:=get_cur_plr(s.the_game);
 if is_landed(s.the_game,cp) then exit;
 if not rul.direct_land then exit;
 if sds_is_replay(@s.steps) then exit;

 result:=true;
end;
//############################################################################//
procedure on_scr_land(s:psdi_rec;par,px:dword);
begin
 case par of
  33:begin
   buy_menu.list_off:=unit_list.off;
   buy_menu.list_sel:=unit_list.sel;
   calcmnuinfo(s,s.cur_menu);
   event_frame(s);
  end;
  34:begin
   set_begin_mat(s.the_game,@buy_menu,mat_elem.cur);
   calcmnuinfo(s,s.cur_menu);
   event_frame(s);
  end;
  41..49:begin
   buy_menu.upd_elems[par-41].vl:=upgraders.vl[par-41];
   buy_menu_arrow(s.the_game,@buy_menu,px,par-41);
   calcmnuinfo(s,s.cur_menu);
  end;
 end;
end;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin
 case par of
  601:set_game_menu(s.the_game,MG_FNC);
  602:begin
   set_game_menu(s.the_game,MG_FNC);
   s.cur_menu_page:=1;
  end;
  603:begin
   set_game_menu(s.the_game,MG_FNC);
   s.cur_menu_page:=3;
   plr_begin.stgold:=buy_menu.cur_gold;   //FIXME: This should really be computed at the server...
  end;
  604:begin
   set_game_menu(s.the_game,MS_HELP);
   s.cur_menu_page:=0;
  end;

  701:begin
   mutex_lock(sds_mx);
   rep_prev_turn(s,false);
   mutex_release(sds_mx);
  end;
  702:s.rep.paused:=not s.rep.paused;
  704:begin if not s.rep.fast_replay then s.rep.paused:=false;s.rep.fast_replay:=not s.rep.fast_replay;end;
  705:begin
   mutex_lock(sds_mx);
   rep_next_turn(s);
   mutex_release(sds_mx);
  end;
  706:if s.rep.plr<>-1 then s.rep.plr:=-1 else s.rep.plr:=s.the_game.state.cur_plr;

  711:begin
   mutex_lock(sds_mx);
   s.rep.paused:=true;
   rep_prev_turn(s,true);
   mutex_release(sds_mx);
  end;
  712:begin
   mutex_lock(sds_mx);
   s.rep.paused:=true;
   s.rep.single_step:=true;
   mutex_release(sds_mx);
  end;

  801:begin
   show_upg:=not show_upg;
   calcmnuinfo(s,s.cur_menu);
  end;
 end;
end;
//############################################################################//
procedure set_common(s:psdi_rec);
var cp:pplrtyp;
begin
 cp:=get_cur_plr(s.the_game);

 btnx.vis:=is_landed(s.the_game,cp);
 btnx.xs:=min2i(scrx div 8,100);
 btnx.ys:=min2i(scry div 8,100);
 btnx.x:=scrx-btnx.xs-5;
 btnx.y:=scry-btnx.ys-5;

 btny.vis:=is_landed(s.the_game,cp);
 btny.xs:=min2i(scrx div 8,100);
 btny.ys:=min2i(scry div 8,100);
 btny.x:=scrx-btny.xs-5;
 btny.y:=scry-btny.ys-5-btnx.ys-5;

 btnhlp.vis:=true;
 btnhlp.xs:=min2i(scrx div 8,100);
 btnhlp.ys:=min2i(scry div 8,100);
 btnhlp.x:=scrx-btnhlp.xs-5;
 btnhlp.y:=scry-btnhlp.ys-5-btny.ys-5-btnx.ys-5;

 btnz.vis:=buys_active(s);
 btnz.xs:=min2i(scrx div 8,100);
 btnz.ys:=min2i(scry div 8,100);
 btnz.x:=scrx-btnz.xs-5;
 btnz.y:=scry-btnz.ys-5;

 btnupg.vis:=buys_active(s);
 btnupg.xs:=88;
 btnupg.ys:=20;
 btnupg.x:=gold_elem.xp-30+4;
 btnupg.y:=gold_elem.yp+gold_elem.ys+5;
end;
//############################################################################//
procedure set_replay(s:psdi_rec;dst:ptypspr);
var i,n,cnt,tc,cc:integer;
xp,yp,xs,ys:integer;
rxs,rys,rtyo:integer;
begin
 for i:=0 to length(btn_rep)-1 do btn_rep[i].vis:=false;
 for i:=0 to length(btn_rep_step)-1 do btn_rep_step[i].vis:=false;
 if s.the_game=nil then exit;
 if not sds_is_replay(@s.steps) then exit;
 for i:=0 to length(btn_rep)-1 do btn_rep[i].vis:=true;
 for i:=0 to length(btn_rep_step)-1 do btn_rep_step[i].vis:=true;

 ys:=btnx.ys;
 xp:=gcrx(s.cg.intf.rmnu)+gcrxs(s.cg.intf.rmnu)+5;
 yp:=scry-ys-5;
 xs:=scrx-xp-btnx.xs-5-5;

 btn_rep[1].set_stat:=not s.rep.paused;
 btn_rep[2].set_stat:=s.rep.fast_replay;
 btn_rep[4].set_stat:=s.rep.plr<>-1;

 for i:=0 to length(btn_rep)-1 do begin
  btn_rep[i].x:=xp+5+(xs div length(btn_rep))*i;
  btn_rep[i].y:=yp+25;
  btn_rep[i].xs:=xs div length(btn_rep)-5;
  btn_rep[i].ys:=ys-25;
 end;

 xp:=xp+5;
 xs:=xs-5;
 ys:=20;

 puttran8(s.cg,dst,xp,yp,xs,ys,0);
 tc:=s.rep.sz;
 if tc<=0 then tc:=1;
 cc:=s.rep.pos;
 if cc<0 then cc:=0;
 if cc>tc then cc:=tc;
 puttran8(s.cg,dst,xp,yp,round(xs*cc/tc),ys,1);
 drrectx8(dst,xp,yp,xs,ys,line_color);


    
 rmnu_sizes(s.cg,rxs,rys,rtyo);

 xp:=gcrx(s.cg.intf.rmnu);
 yp:=gcry(s.cg.intf.rmnu)+elem_gap+rys+elem_gap;
 xs:=gcrxs(s.cg.intf.rmnu);
 ys:=scry-yp-elem_gap-3*scroller_sz-elem_gap-5;
 cnt:=ys div 16;

 btn_rep_step[0].x:=xp;
 btn_rep_step[0].y:=yp+ys+5;
 btn_rep_step[0].xs:=xs div 2-5;
 btn_rep_step[0].ys:=3*scroller_sz;

 btn_rep_step[1].x:=xp+xs div 2+5;
 btn_rep_step[1].y:=yp+ys+5;
 btn_rep_step[1].xs:=xs div 2-5;
 btn_rep_step[1].ys:=3*scroller_sz;

 tran_rect8(s.cg,dst,xp-1,yp-1,xs+2,ys+2,0);
 for i:=0 to cnt-1 do begin
  n:=s.rep.pos+i-cnt div 2;
  if (n<0)or(n>=s.rep.sz) then continue;
                                            
  if i=(cnt div 2) then tran_rect8(s.cg,dst,xp-1,yp+16*i,xs+2,16,ord(s.active_events));
  wrtxtrmg8(s.cg,dst,xp+2+25,yp+2+16*i,stri(n),0);
  wrtxtmg8 (s.cg,dst,xp+2+30,yp+2+16*i,s.rep.events[n],0);
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
procedure draw_landing(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var xp,yp,ys:integer;
begin
 vis_unit_list(unit_list,true);
 vis_material_bit(gold_elem,true);
 vis_material_bit(mat_elem,plr_land.sel_unit<>-1);

 ys:=scry-unit_list.yp-elem_gap-scroller_sz-elem_gap-5;
 reloc_unit_list(unit_list,unit_list.xp,unit_list.yp,unit_list.xs,ys,ys div list_elem_ys);
 fill_list(s,@buy_menu,unit_list);
 draw_unit_list(s,dst,xn,yn,unit_list,get_cur_plr_id(s.the_game));

 tran_rect8(s.cg,dst,xn+gold_elem.xp-30,yn+gold_elem.yp-30,gold_elem.xs+130,gold_elem.ys+scroller_sz+40,0);

 //Gold
 set_material_bit(gold_elem,buy_menu.cur_gold,buy_menu.pre_upgrades_gold,2);
 draw_material_bit(s,dst,xn,yn,gold_elem);

 //Cargo
 if plr_land.sel_unit<>-1 then begin
  //reloc_material_bit(mat_elem,unit_list.xp,unit_list.yp,unit_list.xs,ys,ys div list_elem_ys);
  set_material_bit(mat_elem,buy_menu.mat_cur,buy_menu.mat_max,buy_menu.mat_kind);
  draw_material_bit(s,dst,xn,yn,mat_elem);
 end;

 if show_upg then begin
  vis_upgrade_block(upgraders,upg_cnt,true);

  xp:=xn+upg_xp;
  yp:=yn+upgraders.yp;
  tran_rect8(s.cg,dst,xp-1,yp-1,stats_xs+90+2,stats_ys+2,0);
  tran_rect8(s.cg,dst,xp,yp,stats_xs,stats_ys,0);
  draw_stats_ng(s,dst,xp,yp,stats_xs,stats_ys,get_unitsdb(s.the_game,buy_menu.list[buy_menu.list_sel]),get_rules(s.the_game),@plr_begin);
  draw_upgrade_controls(s,dst,xn,yn);
 end;
end;
//############################################################################//
procedure draw(s:psdi_rec;dst:ptypspr;xn,yn:integer);
begin
 set_common(s);
 set_replay(s,dst);

 vis_unit_list(unit_list,false);
 vis_material_bit(gold_elem,false);
 vis_material_bit(mat_elem,false);

 vis_upgrade_block(upgraders,length(buy_menu.upd_elems),false);

 if not buys_active(s) then exit;

 draw_landing(s,dst,xn,yn);
end;
//############################################################################//
procedure land_update(g:pgametyp);
var rul:prulestyp;
i:integer;
p:ptyp_unupd;
begin
 vis_upgrade_block(upgraders,length(buy_menu.upd_elems),false);

 rul:=get_rules(g);

 fill_buy_menu_mat(g,@buy_menu);

 if length(buy_menu.list)<>0 then p:=@plr_begin.init_unupd[buy_menu.list[buy_menu.list_sel]] else p:=nil;

 upg_cnt:=buy_compute_upgrades(g,@buy_menu,p,rul);
 if length(buy_menu.list)<>0 then buy_menu_post_init(g,@buy_menu);

 vis_upgrade_block(upgraders,upg_cnt,true);
 for i:=0 to upg_cnt-1 do upgraders.vl[i]:=buy_menu.upd_elems[i].vl;
end;
//############################################################################//
procedure direct_buysell(g:pgametyp;rul:prulestyp;evt,x,y,n:integer;shift:boolean);
begin
 case evt of
  0:begins_buy(g,@buy_menu,x,y,n,shift,rul);
  1:if n<>-1 then if not plr_begin.bgn[n].locked then begins_sell(g,@buy_menu,n);
  2:begins_select_set(g,@buy_menu,n);
 end;
 if n<>-1 then land_update(g);
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:dword;
xp,yp,xs,ys:integer;
begin
 result:=true;
 no_reset:=false;

 cbk_buysell:=direct_buysell;

 mn:=MG_NOMENU;
 pg:=0;

 //Common
 btnx:=add_button(mn,pg,0,0,0,0,19,20,po('Menu'),on_btn,601);
 btny:=add_button(mn,pg,0,0,0,0,19,20,po('UT'),on_btn,602);
 btnz:=add_button(mn,pg,0,0,0,0,19,20,po('Done'),on_btn,603);
 btnhlp:=add_button(mn,pg,0,0,0,0,19,20,'?',on_btn,604);

 //Replay
 btn_rep[0]:=add_button(mn,pg,0,0,0,0,19,20,po('|<'),on_btn,701);
 btn_rep[1]:=add_button(mn,pg,0,0,0,0,19,20,po('|| >') ,on_btn,702);
 btn_rep[2]:=add_button(mn,pg,0,0,0,0,19,20,po('>>') ,on_btn,704);
 btn_rep[3]:=add_button(mn,pg,0,0,0,0,19,20,po('>|'),on_btn,705);
 btn_rep[4]:=add_button(mn,pg,0,0,0,0,19,20,po('PL'),on_btn,706);

 btn_rep_step[0]:=add_button(mn,pg,0,0,0,0,19,20,po('<|'),on_btn,711);
 btn_rep_step[1]:=add_button(mn,pg,0,0,0,0,19,20,po('|>') ,on_btn,712);

 //Landing
 btnupg:=add_button(mn,pg,0,0,0,0,0,5,po('Upgrades'),on_btn,801);

 xp:=gcrx(s.cg.intf.rmnu);
 yp:=gcry(s.cg.intf.rmnu)+caption_ys+elem_gap;
 xs:=gcrxs(s.cg.intf.rmnu);
 ys:=100;
 init_unit_list(unit_list,mn,pg,xp,yp,xs,ys,10,po('Available'),true,6,2,text_color,on_scr_land,33);

 xp:=gcrx(s.cg.intf.stats)+gcrxs(s.cg.intf.stats)+elem_gap+30;
 yp:=gcry(s.cg.intf.stats)+30;
 xs:=20;
 ys:=gcrys(s.cg.intf.stats);
 init_material_bit(gold_elem,mn,pg,xp,yp,xs,ys,2,1,po('Credit'),true,false,nil,0);
 xp:=xp+xs+60;
 init_material_bit(mat_elem,mn,pg,xp,yp,xs,ys,0,material_step,po('Cargo'),false,true,on_scr_land,34);

 upg_xp:=unit_list.xp+unit_list.xs+2*elem_gap;
 xp:=upg_xp+stats_xs+2*elem_gap;
 yp:=unit_list.yp;
 init_upgrade_block(upgraders,mn,pg,xp,yp,upg_step,on_scr_land,41);

 upg_txt_xp:=xp+scroller_sz+elem_gap+scroller_sz+elem_gap+upg_txt_xs;
 upg_txt_yp:=yp+6;
end;
//############################################################################//
function deinit(s:psdi_rec):boolean;
var i:integer;
begin
 result:=true;
 for i:=0 to length(upgraders.scr)-1 do upgraders.scr[i]:=nil;
 unit_list.sc:=nil;
 unit_list.cs:=nil;
 unit_list.ml:=nil;
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
var cp:pplrtyp;
rul:prulestyp;
begin
 result:=true;
 if not buys_active(s) then exit;
 if no_reset then begin no_reset:=false;exit;end;

 rul:=get_rules(s.the_game);
 cp:=get_cur_plr(s.the_game);
 cp.info.clan:=plr_begin.clan;

 clear_buy_menu(s.the_game,@buy_menu,rul);
 buy_menu_pre_init(s.the_game,@buy_menu,unit_list.step,1,rul.direct_land);
 calcmnuinfo(s,s.cur_menu);

 recalc_buy_menu_list(s.the_game,@buy_menu,rul);
 buy_menu_post_init(s.the_game,@buy_menu);
 calcmnuinfo(s,s.cur_menu);

 show_upg:=false;
 upg_cnt:=0;
end;
//############################################################################//
function calc(s:psdi_rec;par:integer):boolean;
begin
 result:=true;
 vis_upgrade_block(upgraders,length(buy_menu.upd_elems),false);

 if not buys_active(s) then exit;
 land_update(s.the_game);
end;
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var double:boolean;
begin
 result:=false;
 if not buys_active(s) then exit;

 event_frame(s);

 //Main list
 if mouse_unit_list(s,unit_list,0,x-xn,y-yn,0,double) then begin
  buy_menu.list_sel:=unit_list.sel;
  buy_menu.list_off:=unit_list.off;

  plr_land.sel_unit:=-1;
  plr_land.sel_db_unit:=buy_menu.list[buy_menu.list_sel];

  event_map_reposition(s);
  calcmnuinfo(s,s.cur_menu);
  result:=true;
 end;

 //Materials
 if plr_land.sel_unit<>-1 then if mouse_material_bit(mat_elem,0,x-xn,y-yn,0) then begin
  set_begin_mat(s.the_game,@buy_menu,mat_elem.cur);
  calcmnuinfo(s,s.cur_menu);
  result:=true;
 end;
end;
//############################################################################//
function mousewheel(s:psdi_rec;shift:dword;dir,null,xn,yn:integer):boolean;
begin
 result:=false;
 if not buys_active(s) then exit;

 event_frame(s);

 //Material scroll
 if mouse_material_bit(mat_elem,2,curx-xn,cury-yn,dir) then begin
  set_begin_mat(s.the_game,@buy_menu,mat_elem.cur);
  calcmnuinfo(s,s.cur_menu);
  event_frame(s);
  result:=true;
 end;
end;
//############################################################################//
begin
 add_menu('Interface "menu"',MG_NOMENU,0,0,BCK_NONE,init,deinit,draw,nil,nil,enter,nil,calc,nil,mousedown,nil,nil,mousewheel);
end.
//############################################################################//
