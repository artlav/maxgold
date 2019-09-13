//############################################################################//
//Resource transfer menu
unit si_xfer;
interface
uses asys,strval,grph,graph8,sdigrtools,mgrecs,mgl_common,mgl_xfer,mgl_actions,sds_rec,sdirecs,sdiauxi,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation
//############################################################################//
var
xfer_menu_scroll:array[0..3]of pscrollbox_type; 
xfer_menu_scroll_areas:array[0..3]of pscrollarea_type;  
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin
 case par of
  62..69:recalc_xfer_menu(s.the_game,@xfer_menu);
 end;
end;
//############################################################################//
procedure proc_xfer_menu_scrollbars;
var i:integer;
begin
 for i:=0 to 2 do begin
  xfer_menu_scroll[i].bottom:=xfer_menu.max[i];
  xfer_menu_scroll[i].top:=xfer_menu.min[i];
  xfer_menu_scroll_areas[i].llim:=xfer_menu.max[i];
  xfer_menu_scroll_areas[i].ulim:=xfer_menu.min[i];
 end;
end;
//############################################################################//
procedure draw_xfer_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
const fonts:array [boolean] of byte=(3,2);
inons:array[0..3] of integer=(2,4,14,4);
var xh,i:integer;
ua,ub:ptypunits;
begin
 proc_xfer_menu_scrollbars;
 ua:=xfer_menu.ua;
 ub:=xfer_menu.ub;

 //Left unit
 i:=ua.grp_db;
 if i<>-1 then putsprtx8_uspr(s,dst,@s.eunitsdb[i].spr_list,xn+32 ,yn+34);
 tran_rect8(s.cg,dst,xn+10,yn+9,112,52,0);

 //Right unit
 i:=ub.grp_db;
 if i<>-1 then putsprtx8_uspr(s,dst,@s.eunitsdb[i].spr_list,xn+270,yn+34);
 tran_rect8(s.cg,dst,xn+187,yn+9,112,52,0);

 //Central bit
 tran_rect8(s.cg,dst,xn+127,yn+8,55,55,0);

 for i:=0 to 2 do begin
  wrtxtcnt8(s.cg,dst,xn+96 ,yn+16+12*i,stri(xfer_menu.era[i]-xfer_menu.cnt[i]),fonts[xfer_menu.naf[i]]);
  wrtxtcnt8(s.cg,dst,xn+227,yn+16+12*i,stri(xfer_menu.erb[i]+xfer_menu.cnt[i]),fonts[xfer_menu.naf[i]]);
  //Unit A icons
  putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[inons[i]],xn+58, yn+10+12*i);
  //Unit B icons
  putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[inons[i]],xn+192,yn+10+12*i);
  if not xfer_menu.naf[i] then begin
   wrtxtcnt8(s.cg,dst,xn+160,yn+16+i*12,stri(xfer_menu.cnt[i]),0);
   //Transfer label icons
   putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[inons[i]],xn+130,yn+11+i*12);
   //putsprt8(dst,@grapu[GRU_ICOS].sprc[inons[i]+1],xn+130,yn+11+i*12);
   xh:=s.cg.grapu[GRU_SMBAR].sprc[i].xs-round(xfer_menu.o[i]*224);
   //Control graphics
   putsprtcut8(dst,@s.cg.grapu[GRU_SMBAR].sprc[i],xn+44,yn+88+37*i,xh,0,1000,30,0);
   //Transfer control icons
   putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[inons[i]],xn+2  ,yn+88+37*i);
   putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[inons[i]],xn+292,yn+88+37*i);
  end;
 end;
 if s.the_game.info.rules.fuelxfer and s.the_game.info.rules.fueluse then begin
  i:=3;
  wrtxtcnt8(s.cg,dst,xn+96 ,yn+16+12*i,stri(ua.cur.fuel-xfer_menu.cnt[i]),fonts[xfer_menu.naf[i]]);
  wrtxtcnt8(s.cg,dst,xn+227,yn+16+12*i,stri(ub.cur.fuel+xfer_menu.cnt[i]),fonts[xfer_menu.naf[i]]);
  putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[inons[i]],xn+58 ,yn+10+12*i);
  //putsprt8(dst,@grapu[GRU_ICOS].sprc[inons[i]+1],xn+192,yn+10+12*i);
  if not xfer_menu.naf[i] then begin
   wrtxtcnt8(s.cg,dst,xn+209,yn+33,stri(xfer_menu.cnt[i]),0);
   xh:=s.cg.grapu[GRU_SMBAR].sprc[1].xs-round(xfer_menu.o[i]*224);
   putsprtcut8(dst,@s.cg.grapu[GRU_SMBAR].sprc[1],xn+44,yn+88+37*i,xh,0,1000,30,0);
  end;
 end;
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true;
 init_xfer_menu(s.the_game,@xfer_menu);
 recalc_xfer_menu(s.the_game,@xfer_menu);
 ////mods.trnmod:=false;
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg,i:integer;
begin
 result:=true;
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_XFER;
 pg:=0;

 add_button(mn,pg,077,237,76,22,7,5,po('Cancel'),on_cancel_btn,0);
 add_button(mn,pg,165,237,76,22,7,5,'OK',on_ok_btn,0);

 for i:=0 to 3 do begin
  if i=3 then if(not s.the_game.info.rules.fuelxfer)or(not s.the_game.info.rules.fueluse)then break;
  xfer_menu_scroll[i]      :=add_scrollbox(mn,pg,SCB_HORIZONTAL,017,089+37*i,278,089+37*i,18,17,1,0,1000,false,@xfer_menu.cnt[i],on_btn,62+i);
  xfer_menu_scroll_areas[i]:=add_scrolarea(mn,pg,2             ,044,086+37*i,224,20          ,5,5,0,1000,@xfer_menu.cnt[i],on_btn,62+i,xfer_menu_scroll[i]);
 end;
end;
//############################################################################//
function deinit(s:psdi_rec):boolean;
var i:integer;
begin
 result:=true; 
 for i:=0 to 3 do xfer_menu_scroll[i]:=nil;
 for i:=0 to 3 do xfer_menu_scroll_areas[i]:=nil;
end;
//############################################################################//
function ok(s:psdi_rec):boolean;
var ev:xfer_rec;
i:integer;
begin
 result:=true;
 ev.ua:=xfer_menu.ua.num;
 ev.ub:=xfer_menu.ub.num;
 for i:=0 to length(ev.cnt)-1 do ev.cnt[i]:=xfer_menu.cnt[i];
 act_xfer(s.the_game,ev);
 clear_menu(s);
end;
//############################################################################//
begin
 add_menu('Resource transfer menu',MG_XFER,154,137,BCK_SHADE,init,deinit,draw_xfer_menu,ok,nil,enter,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################// 
