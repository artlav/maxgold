//############################################################################//
//Build menu
unit si_build;
interface
uses asys,maths,strval,grph,graph8,sdigrtools,
mgrecs,mgl_common,mgl_attr,mgl_build,sdirecs,sdiauxi,sdicalcs,sdisound,sdimenu,sdigui,sdi_int_elem;
//############################################################################//
implementation
//############################################################################//
const
menu_xs=635;
menu_ys=470;

unit_list_step=12;
build_list_step=6;

img_xp=10;
img_yp=10;
img_xs=300;
img_ys=240;
        
bld_xp=img_xp+img_xs+5;
bld_yp=img_yp+caption_ys;
bld_xs=120;
bld_ys=build_list_step*list_elem_ys+2*elem_gap;
      
list_xp=img_xp+img_xs+5+bld_xs+5;
list_yp=50;
list_xs=180;
list_ys=unit_list_step*list_elem_ys+2*elem_gap;

stats_xp=img_xp;
stats_yp=img_yp+img_ys+5;
stats_xs=250;
stats_ys=11*upg_step+9;

speed_xp=stats_xp+stats_xs+8;
speed_yp=343;
speed_xs=80;
speed_ys=22;
speed_elem_xs=40;
speed_step=speed_ys+elem_gap;

path_xp=speed_xp;
path_yp=speed_yp+speed_step*3+elem_gap;
path_xs=speed_xs+elem_gap+speed_elem_xs+elem_gap+speed_elem_xs;
path_ys=22;
//############################################################################//
var
build_reservesb:pscrollbox_type;
build_reverselab:plabel_type;
build_reversecb:pcheckbox_type;     
build_reservetb:ptextbox_type;   
build_pthbtn:pbutton_type;  

build_showdesc:boolean;   
build_reservestr:string;

unit_list,build_list:unit_list_rec;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
var u:ptypunits;
begin 
 case par of
  36:begin
   builds_menu.qsel:=build_list.sel;
   builds_menu.qoff:=build_list.off;
   builds_menu.sel:=unit_list.sel;
   builds_menu.off:=unit_list.off;
   calcmnuinfo(s,s.cur_menu);
   event_frame(s);
  end;
  //Reverse build
  70:begin
   u:=get_sel_unit(s.the_game);
   u.builds[builds_menu.qsel].reverse:=builds_menu.reverse;
   build_set_cur_build_unit_speed(s.the_game,@builds_menu,builds_menu.speed,builds_menu.qsel);
  end;
  //Build path
  37:begin
   builds_menu.sel:=builds_menu.brk+builds_menu.off;
                
   u:=get_sel_unit(s.the_game);
   build_building_path(s.the_game,@builds_menu,u.num,builds_menu.och[builds_menu.sel].sunit,builds_menu.speed);  

   event_frame(s);
   event_map_reposition(s);
   
  end;                                 
  201:update_och_build_menu(s.the_game,@builds_menu,builds_menu.reserve);
 end;
end;
//############################################################################//
procedure draw_poster(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var ud:ptypunitsdb;
en:ptypeunitsdb;
begin
 if builds_menu.sel>=get_unitsdb_count(s.the_game) then exit;

 ud:=get_unitsdb(s.the_game,builds_menu.och[builds_menu.sel].sunit);
 en:=get_edb(s,ud.typ);

 drrectx8(dst,xn+img_xp-1,yn+img_yp-1,img_xs+2,img_ys+2,line_color);
 if en<>nil then if length(en.img_poster.sprc)<>0 then putspr8(dst,@en.img_poster.sprc[0],xn+img_xp,yn+img_yp);
 if build_showdesc then begin
  if lrus then wrtxtxbox8(s.cg,dst,xn+img_xp+10,yn+img_yp+10,img_xs-20,img_ys-20,ud.descr_rus,0)
          else wrtxtxbox8(s.cg,dst,xn+img_xp+10,yn+img_yp+10,img_xs-20,img_ys-20,ud.descr_eng,0);
 end;
end;
//############################################################################//
procedure fill_build_list(s:psdi_rec;var z:unit_list_rec);
var su:ptypunits;
i:integer;
b:pbuildrec;
st:string;
begin
 su:=get_sel_unit(s.the_game);
 if su=nil then exit;

 setlength(z.list,su.builds_cnt);
 for i:=0 to length(z.list)-1 do begin
  b:=@su.builds[i+builds_menu.qoff];

  z.list[i].dbn:=b.typ_db;
  z.list[i].cost:=0;
  z.list[i].idx:='';

  st:=stri(b.left_turns)+' ('+stri(b.left_mat)+') '+stri(b.given_speed)+'X';
  if b.reverse then st:=st+'*';
  z.list[i].par:=st;
 end;

 set_unit_list(z,builds_menu.qsel,builds_menu.qoff,1);
end;
//############################################################################//
{
 cl:=0;
 if not isa(s.the_game,su,a_building) then begin
  if builds_menu.och[i].cost<=su.prod.now[RES_MAT]-builds_menu.reserve then cl:=text_color else cl:=2;
 end;
 j:=builds_menu.och[i].cost;
 if j mod su.bas.mat_turn<>0 then j:=j div su.bas.mat_turn+1 else j:=j div su.bas.mat_turn;
 wrtxt8(s.cg,dst,xh+32+95,yh+10,stri(j),cl);
}
//############################################################################//
procedure fill_unit_list(s:psdi_rec;var z:unit_list_rec);
var i,n:integer;
su:ptypunits;
begin
 su:=get_sel_unit(s.the_game);
 if su=nil then exit;

 setlength(z.list,builds_menu.och_cnt);
 for i:=0 to length(z.list)-1 do begin
  n:=builds_menu.och[i].sunit;
  z.list[i].dbn:=n;
  z.list[i].cost:=builds_menu.och[i].cost;
  z.list[i].idx:=type_mk(s.the_game,n,0,true);
  z.list[i].par:='';
 end;

 set_unit_list(z,builds_menu.sel,builds_menu.off,su.prod.now[RES_MAT]-builds_menu.reserve);
end;
//############################################################################//
procedure set_elems(s:psdi_rec);
var su:ptypunits;
ud:ptypunitsdb;
begin   
 su:=get_sel_unit(s.the_game);
 if su=nil then exit;

 if build_reversecb<>nil then build_reversecb.vis:=isa(s.the_game,su,a_building);
 if build_reverselab<>nil then build_reverselab.vis:=isa(s.the_game,su,a_building);
 vis_unit_list(build_list,isa(s.the_game,su,a_building));
 if build_reservetb<>nil then build_reservetb.vis:=not isa(s.the_game,su,a_building);
 if build_reservesb<>nil then build_reservesb.vis:=not isa(s.the_game,su,a_building);

 ud:=get_unitsdb(s.the_game,builds_menu.och[0].sunit);
 if build_pthbtn<>nil then build_pthbtn.vis:=(builds_menu.reserve=0)and(not isa(s.the_game,su,a_building))and(ud.siz=1);

 if not isa(s.the_game,su,a_building) then begin
  build_reservesb.bottom:=su.prod.now[RES_MAT];
  build_reservestr:=stri(builds_menu.reserve)+'/'+stri(su.prod.now[RES_MAT]);
 end;
end;
//############################################################################//
procedure draw_builds_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);  
var su:ptypunits;
i,k,yo,xo:integer;
can:boolean;
begin
 su:=get_sel_unit(s.the_game);
 if su=nil then exit;

 //Set element visibility, i.e. for factory vs unit
 set_elems(s);

 //Speed buttons 
 wrtxtcnt8(s.cg,dst,xn+speed_xp+speed_xs+elem_gap                       +speed_elem_xs div 2,yn+speed_yp-speed_step+speed_ys div 2,po('Turns'),text_color);
 wrtxtcnt8(s.cg,dst,xn+speed_xp+speed_xs+elem_gap+speed_elem_xs+elem_gap+speed_elem_xs div 2,yn+speed_yp-speed_step+speed_ys div 2,po('Cost'),text_color);
 for i:=0 to 2 do begin
  case i of
   0:begin k:=1;can:=true;end;
   1:begin k:=2;can:=builds_menu.och[builds_menu.sel].cs[k-1]>0;end;
   2:begin k:=4;can:=builds_menu.och[builds_menu.sel].cs[k-1]>0;end;
   else halt;
  end;
  yo:=yn+speed_yp+speed_step*i;
  tran_rect8(s.cg,dst,xn+speed_xp,yo,speed_xs,speed_ys,ord(builds_menu.speed=k));

  if can then begin
   wrtxtcnt8(s.cg,dst,xn+speed_xp+speed_xs div 2,yo+speed_ys div 2-4,po('Build X'+stri(k)),7-ord(builds_menu.speed=k)*2);

   xo:=xn+speed_xp+speed_xs+elem_gap;
   tran_rect8(s.cg,dst,xo,yo,speed_elem_xs,speed_ys,0);
   wrtxtcnt8(s.cg,dst,xo+speed_elem_xs div 2,yo+speed_ys div 2-4,stri(builds_menu.och[builds_menu.sel].sp[k-1]),4-ord(builds_menu.speed=k));
                                            
   xo:=xn+speed_xp+speed_xs+elem_gap+speed_elem_xs+elem_gap;
   tran_rect8(s.cg,dst,xo,yo,speed_elem_xs,speed_ys,0);
   wrtxtcnt8(s.cg,dst,xo+speed_elem_xs div 2,yo+speed_ys div 2-4,stri(builds_menu.och[builds_menu.sel].cs[k-1]),4-ord(builds_menu.speed=k));
  end;
 end;

 //Stats
 tran_rect8(s.cg,dst,xn+stats_xp-1,yn+stats_yp-1,stats_xs+2,stats_ys+2,0);
 draw_stats_db(s,dst,xn+stats_xp,yn+stats_yp,stats_xs,stats_ys,get_unitsdb(s.the_game,builds_menu.och[builds_menu.sel].sunit),get_rules(s.the_game),false);

 //Unit lsit
 fill_unit_list(s,unit_list);
 draw_unit_list(s,dst,xn,yn,unit_list,su.own);

 //Build list
 if isa(s.the_game,su,a_building) then begin
  fill_build_list(s,build_list);
  draw_unit_list(s,dst,xn,yn,build_list,su.own);
 end;

 draw_poster(s,dst,xn,yn);
end;
//############################################################################//
function calc(s:psdi_rec;par:integer):boolean;      
var su:ptypunits;
begin   
 result:=true;

 if builds_menu.brk>unit_list_step then builds_menu.brk:=unit_list_step;
 if builds_menu.brk<0 then builds_menu.brk:=0;
    
 if builds_menu.off>builds_menu.och_cnt-unit_list_step then builds_menu.off:=builds_menu.och_cnt-unit_list_step;
 if builds_menu.off<0 then builds_menu.off:=0;

 builds_menu.brk:=builds_menu.sel-builds_menu.off;
 builds_menu.qbrk:=builds_menu.qsel-builds_menu.qoff;

 su:=get_sel_unit(s.the_game);
 if su=nil then exit;
 if builds_menu.qoff>=su.builds_cnt then builds_menu.qoff:=(su.builds_cnt div build_list_step)*build_list_step;
end;  
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
var un:ptypunits;
i:integer; 
begin
 result:=true;
 event_frame(s);

 un:=get_sel_unit(s.the_game);
 //Speed
 i:=builds_menu.speed;
 case key of
  key_1:i:=1;
  key_2:i:=2;
  key_3,key_4:i:=4;
  KEY_LEFT:case i of
   2:i:=1;
   4:i:=2;
  end;
  KEY_RIGHT:case i of
   1:i:=2;
   2:i:=4;
  end;
 end;
 if i<>builds_menu.speed then begin build_change_sel_unit_speed(s.the_game,@builds_menu,i,ord(isf(shift,sh_shift)));snd_click(SND_ACCEPT);end;
 //Query and unit list
 case key of
  KEY_SPACE:begin build_add_sel_unit_to_queues(s.the_game,@builds_menu);snd_click(SND_BUTTON);end;
  KEY_DEL:if isa(s.the_game,un,a_building) then begin build_rem_build_unit_cur(s.the_game,@builds_menu);snd_click(SND_BUTTON);end;
  KEY_UP:if isf(shift,sh_shift) then begin
   if isa(s.the_game,un,a_building) then if builds_menu.qsel>0 then begin build_sel_unit_on_build_queue(s.the_game,@builds_menu,builds_menu.qsel-1);snd_click(SND_TCK);end;
  end else begin
   if builds_menu.sel>0 then begin build_sel_unit_on_list(s.the_game,@builds_menu,builds_menu.sel-1);snd_click(SND_TCK);end;
  end;
  KEY_DWN:if isf(shift,sh_shift) then begin
   if isa(s.the_game,un,a_building) then if builds_menu.qsel<un.builds_cnt-1 then begin build_sel_unit_on_build_queue(s.the_game,@builds_menu,builds_menu.qsel+1);snd_click(SND_TCK);end;
  end else begin
   if builds_menu.sel<builds_menu.och_cnt-1 then begin build_sel_unit_on_list(s.the_game,@builds_menu,builds_menu.sel+1);snd_click(SND_TCK);end;
  end;
 end;
end; 
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var un:ptypunits;
double:boolean;
begin
 result:=true;
 event_frame(s);
 
 un:=get_sel_unit(s.the_game);
 if not unav(un) then exit;

 //Speed
 if inrects(x,y,xn+speed_xp,yn+speed_yp+speed_step*0,speed_xs,speed_ys) then begin build_change_sel_unit_speed(s.the_game,@builds_menu,1,1);snd_click(SND_ACCEPT);end;
 if inrects(x,y,xn+speed_xp,yn+speed_yp+speed_step*1,speed_xs,speed_ys) then begin build_change_sel_unit_speed(s.the_game,@builds_menu,2,1);snd_click(SND_ACCEPT);end;
 if inrects(x,y,xn+speed_xp,yn+speed_yp+speed_step*2,speed_xs,speed_ys) then begin build_change_sel_unit_speed(s.the_game,@builds_menu,4,1);snd_click(SND_ACCEPT);end;

 calcmnuinfo(s,MG_BUILD);

 //Main list
 if mouse_unit_list(s,unit_list,0,x-xn,y-yn,0,double) then begin
  build_sel_unit_on_list(s.the_game,@builds_menu,unit_list.sel);
  if double then build_add_sel_unit_to_queues(s.the_game,@builds_menu);
  event_map_reposition(s);
 end;

 //queues
 if mouse_unit_list(s,build_list,0,x-xn,y-yn,0,double) then begin
  build_sel_unit_on_build_queue(s.the_game,@builds_menu,build_list.sel);
  if double then begin 
   //Cycle speed with shift, delete if not
   if isf(shift,sh_shift) then begin 
    builds_menu.speed:=un.builds[builds_menu.qsel].given_speed;
    case builds_menu.speed of
     1:builds_menu.speed:=2;
     2:builds_menu.speed:=4;
     4:builds_menu.speed:=1;
    end;
    build_change_sel_unit_speed(s.the_game,@builds_menu,builds_menu.speed,1);
   end else build_rem_build_unit_cur(s.the_game,@builds_menu);
  end;
  event_map_reposition(s);
 end;
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true; 
 enter_build_menu(s.the_game,@builds_menu);
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;
 if s.state<>CST_THEGAME then exit;

 build_showdesc:=true;

 mn:=MG_BUILD;
 pg:=0;

 add_label(mn,pg,list_xp+list_xs div 2,img_yp-2,LB_BIG_CENTER,0,po('Build'));

 init_unit_list(unit_list,mn,pg,list_xp,list_yp,list_xs,list_ys,unit_list_step,po('Available'),true,4,2,4,on_btn,36);
 init_unit_list(build_list,mn,pg,bld_xp,bld_yp,bld_xs,bld_ys,build_list_step,po('Build'),false,0,0,2,on_btn,36);
 
 add_label   (mn,pg,img_xp+5+20,img_yp+img_ys-16-5+5,LB_LEFT  ,7,po('Description'));
 add_checkbox(mn,pg,img_xp+5   ,img_yp+img_ys-16-5  ,16,16,nil,@build_showdesc,nil);

 add_button  (mn,pg,path_xp                       ,path_yp+path_ys+elem_gap,path_xs div 2-elem_gap,path_ys,7,5,po('Cancel'),on_cancel_btn,0);
 add_button  (mn,pg,path_xp+path_xs div 2+elem_gap,path_yp+path_ys+elem_gap,path_xs div 2-elem_gap,path_ys,7,5,'OK',on_ok_btn,0);

 build_pthbtn    :=add_button  (mn,pg,path_xp,path_yp,path_xs,path_ys,7,5,po('Path'),on_btn,37);

 build_reversecb :=add_checkbox(mn,pg,bld_xp+bld_xs-16  ,bld_yp+bld_ys+5  ,16,16,nil,@builds_menu.reverse,on_btn,70);
 build_reverselab:=add_label   (mn,pg,bld_xp+bld_xs-16-2,bld_yp+bld_ys+5+2,LB_RIGHT,7,po('Reverse'));

 build_reservetb:=add_textbox  (mn,pg,376,300,040,true,2,@build_reservestr,'');
 build_reservesb:=add_scrollbox(mn,pg,SCB_HORIZONTAL,322,300,347,300,scroller_sz,scroller_sz,1,0,60,false,@builds_menu.reserve,on_btn,201);
end;
//############################################################################//
function deinit(s:psdi_rec):boolean;
begin
 result:=true; 
 build_reverselab:=nil;
 build_reservesb:=nil;
 build_pthbtn:=nil;
 build_reversecb:=nil;
 build_reservetb:=nil;

 unit_list.sc:=nil;
 unit_list.cs:=nil;
 unit_list.ml:=nil;
 build_list.sc:=nil;
 build_list.cs:=nil;
 build_list.ml:=nil;
end;
//############################################################################//
function ok(s:psdi_rec):boolean;   
var su:ptypunits;
begin 
 result:=true;

 builds_menu.sel:=builds_menu.brk+builds_menu.off;
 su:=get_sel_unit(s.the_game);
 if not isa(s.the_game,su,a_building) then build_building(s.the_game,@builds_menu,su,builds_menu.och[builds_menu.sel].sunit,builds_menu.speed)
                                   else building_build_ok(s.the_game,@builds_menu,su);

 event_frame(s);
 event_map_reposition(s);
end;
//############################################################################//
begin      
 add_menu('Build menu',MG_BUILD,menu_xs div 2,menu_ys div 2,BCK_SHADE,init,deinit,draw_builds_menu,ok,nil,enter,nil,calc,keydown,mousedown,nil,nil,nil);
end.
//############################################################################//    
