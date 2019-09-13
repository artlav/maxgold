//############################################################################//
//Options menu
unit si_options;
interface
uses asys,strval,grph,graph8,sdigrtools,sdi_rec,sdisdl,
mgrecs,mgl_common,sdirecs,sdisound,sdiauxi,sdicalcs,sdimenu,sdigui,sdiinit,sdiloads,sdiovermind;
//############################################################################//
implementation
//############################################################################//
const
page_count=2;
map_zoom=1.3;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin
 case par of
  91:if s.cur_menu_page>0 then s.cur_menu_page:=s.cur_menu_page-1;
  92:if s.cur_menu_page<page_count-1 then s.cur_menu_page:=s.cur_menu_page+1;
 end;
end;
//############################################################################//
procedure on_cbx(s:psdi_rec;par,px:dword);
begin
 case par of
  11:begin
   sdi_touch_params;
   so_screen_resize(s);
  end;
 end;
end;
//############################################################################//
//Draw test scene
procedure draw_optstscene(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer);
var x,y:integer;
zoom:double;
begin
 x:=xh+50;y:=yh+50;

 drrect8(dst,xh-1,yh-1,xh+xs,yh+ys,1);
 drfrect8(dst,xh,yh,xh+xs-1,yh+ys-1,0);
 putspr8(dst,s.cg.grap[GRP_TSTIMG],xh,yh);

 fill_transparency_cache(s.cg);
 zoom:=map_zoom;
 
 sdi_calczoomer(s,zoom);

 if (length(s.cg.grapu[GRU_DEMO_SMLSLAB ].sprc)<>0)and(length(s.cg.grapu[GRU_DEMO_S_POWGEN].sprc)<>0)and(length(s.cg.grapu[GRU_DEMO_POWGEN  ].sprc)<>0) then begin                  
                            putsprzoomt8 (s,dst,@s.cg.grapu[GRU_DEMO_SMLSLAB ].sprc[0],round(x-s.cg.grapu[GRU_DEMO_SMLSLAB ].sprc[0].cx/zoom),round(y-s.cg.grapu[GRU_DEMO_SMLSLAB ].sprc[0].cy/zoom));
  if s.cg.unit_shadows then putsprszoomt8(s,dst,@s.cg.grapu[GRU_DEMO_S_POWGEN].sprc[0],round(x-s.cg.grapu[GRU_DEMO_S_POWGEN].sprc[0].cx/zoom),round(y-s.cg.grapu[GRU_DEMO_S_POWGEN].sprc[0].cy/zoom));
                            putsprzoomt8 (s,dst,@s.cg.grapu[GRU_DEMO_POWGEN  ].sprc[0],round(x-s.cg.grapu[GRU_DEMO_POWGEN  ].sprc[0].cx/zoom),round(y-s.cg.grapu[GRU_DEMO_POWGEN  ].sprc[0].cy/zoom));
 end;
 if s.cg.fog_of_war then puttran8(s.cg,dst,xh+150,yh,xs-150,ys,3);

 if s.ut_squares then begin
  drline8(dst,xh+100,yh+100,xh+100 ,yh+ys-1,maxg_nearest_in_thepal(tcrgb(200,$FF,$00)));
  drline8(dst,xh+100,yh+100,xh+150 ,yh+100 ,maxg_nearest_in_thepal(tcrgb(200,$FF,$00)));
  drline8(dst,xh+150,yh+100,xh+150 ,yh+050 ,maxg_nearest_in_thepal(tcrgb(200,$FF,$00)));
  drline8(dst,xh+150,yh+050,xh+xs-1,yh+050 ,maxg_nearest_in_thepal(tcrgb(200,$FF,$00)));
 end;
  
 if s.ut_circles then drcirc8(dst,x,y,45,maxg_nearest_in_thepal(tcrgb(200,$FF,$00)));
end;
//############################################################################/
procedure draw_options_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
begin
 wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+ 8,po('All options'),0);  
 wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+30,po('Page')+' '+stri(s.cur_menu_page+1)+'/'+stri(page_count),0);

 case s.cur_menu_page of
  0:wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Common'),0);
  1:begin
   wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Map'),0);
   draw_optstscene(s,dst,xn+200,yn+190,186,140);
  end;
 end;
end;
//############################################################################//
function mouseup(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
begin
 result:=true;
 calcmnuinfo(s,MS_OPTIONS);
end;
//############################################################################//   
function init(s:psdi_rec):boolean;
var mn,pg:integer;
cb1,cb2:pcheckbox_type;

procedure set_page_buttons;
begin
 add_button(mn,pg,            5,5,100,50,19,20,po('Prev'),on_btn,91);
 add_button(mn,pg,menu_xs-100-5,5,100,50,19,20,po('Next'),on_btn,92);

 add_button(mn,pg,menu_xs div 2-50,menu_ys-50-5,100,50,19,20,'OK',on_ok_btn,0);
end;

begin
 result:=true;
 
 mn:=MS_OPTIONS;
 pg:=0;

 //1
 pg:=0;
 set_page_buttons;      
 cb1:=add_clickbox(mn,pg,0,0,'Русский',nil,@lrus,nil);
 cb2:=add_clickbox(mn,pg,0,1,'English',nil,@leng,nil);
 cb1.linked_cb:=cb2;
 {$ifndef embedded}
  add_clickbox(mn,pg,0,2,po('Sound'),nil,@snd_on,nil);
  add_clickbox(mn,pg,0,3,po('Music'),nil,@snd_muson,nil);
  //Add s.cg.load_unit_sounds
 {$endif}
 add_clickbox(mn,pg,0,4,po('Scale2x')+' -->',nil,@use_scale2x,nil);

 add_clickbox(mn,pg,1,0,po('Show FPS')  ,nil,@fpsdbg,nil);
 add_clickbox(mn,pg,1,1,po('Cursor')    ,nil,@s.cg.show_cursor,nil);
 add_clickbox(mn,pg,1,2,po('Fog Of War'),nil,@s.cg.fog_of_war,nil);
 add_clickbox(mn,pg,1,3,po('Shadows')   ,nil,@s.cg.unit_shadows,nil);
 add_clickbox(mn,pg,1,4,po('Scale')     ,nil,@use_scaling,on_cbx,11);

 //2
 pg:=1;
 set_page_buttons;
 add_clickbox(mn,pg,0,0,po('Square Range'),nil,@s.ut_squares,nil);
 add_clickbox(mn,pg,0,1,po('Circle Range'),nil,@s.ut_circles,nil);
 add_clickbox(mn,pg,1,0,po('Range on Destination'),nil,@s.ut_at_end_move,nil);
 add_clickbox(mn,pg,1,1,po('Zoom to Cursor'),nil,@s.center_zoom,nil);

 add_label(mn,pg,010,200,0,0,po('Shadow density'));add_scrollbar(mn,pg,10,223,100,0,1,@s.cg.shadow_density);
 add_label(mn,pg,010,250,0,0,po('FoW density'));   add_scrollbar(mn,pg,10,273,100,0,1,@s.cg.fow_density);
 add_label(mn,pg,010,300,0,0,po('Zoom Speed'));    add_scrollbar(mn,pg,10,323,100,0,3,@s.zoomspd);
end;
//############################################################################//
function deinit(s:psdi_rec):boolean;
begin
 result:=true;
end;
//############################################################################//
function calc(s:psdi_rec;par:integer):boolean;
begin
 result:=true;

 clear_minimap_pal(s);
 
 if lrus then s.cg.lang:='rus';if leng then s.cg.lang:='eng';
 cur_lng:=ord(lrus)+(ord(leng) shl 1);
 if cur_lng<>prv_lng then begin
  loadlang(s);
  prv_lng:=cur_lng;
  resetgui(s);
 end else prv_lng:=cur_lng;
end;
//############################################################################//
function ok(s:psdi_rec):boolean;
begin
 result:=true;
 savsetup(s);
 enter_menu(s,MS_MAINMENU);
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true;
 calcmnuinfo(s,MS_OPTIONS);
end;
//############################################################################//
begin
 add_menu('Options menu',MS_OPTIONS,menu_xs div 2,menu_ys div 2,BCK_SHADE,init,deinit,draw_options_menu,ok,nil,enter,nil,calc,nil,nil,mouseup,nil,nil);
end.
//############################################################################//

