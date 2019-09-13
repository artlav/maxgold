//############################################################################//
//-Mdelphi -Fualib -Fualib/sdisdl -Fualib/pck -FUunits -dBGR -dsdi_deffont
//############################################################################//
program mga_rnd_gui;
{$ifdef mswindows}{$APPTYPE console}{$R std.res}{$endif} 
uses sysutils,maths,strtool,strval,asys,grph,sdisdl,sdi_rec,graph32,text32,text_common
,mga_mapgen,gui,gui_all,meb;
//############################################################################//
var root:pwidget_rec=nil;
anim_dt:single=0;
thepal:ppallette3;
pal:pallette3;
size_idx:integer=1;
//############################################################################//
procedure palshiftd(pal:ppallette3;s,e:integer);
var cl:crgb;
i:integer;
begin
 cl:=pal[s];
 for i:=s to e-1 do pal[i]:=pal[i+1];
 pal[e]:=cl;
end;
//############################################################################//
procedure palshiftu(pal:ppallette3;s,e:integer);
var cl:crgb;
i:integer;
begin
 cl:=pal[e];
 for i:=e downto s+1 do pal[i]:=pal[i-1];
 pal[s]:=cl;
end;
//############################################################################//
procedure palblnkd(pal:ppallette3;s:integer;t:double;cs:crgba);
var cl:crgb;
begin
 cl:=pal[s];
 cl[0]:=round(cs[0]*t);
 cl[1]:=round(cs[1]*t);
 cl[2]:=round(cs[2]*t);
 pal[s]:=cl;
end;
//############################################################################//
procedure palanim(ct,dt:double);
begin
 anim_dt:=anim_dt+dt;
 if anim_dt>0.15 then begin
  anim_dt:=0;

  palshiftd(thepal,  9, 12);
  palshiftu(thepal, 13, 16);
  palshiftu(thepal, 17, 20);
  palshiftu(thepal, 21, 24);

  palshiftu(thepal, 25, 30);
  palblnkd (thepal, 31, 1-frac(ct),gclgreen);

  palshiftu(thepal, 96,102);
  palshiftu(thepal,103,109);
  palshiftu(thepal,110,116);
  palshiftu(thepal,117,122);
  palshiftu(thepal,123,127);
 end;
end;
//############################################################################//
procedure draw_minimap(xo,yo:integer;k:single);      
var x,y,kx,ky,px,py,dx,dy:integer;
scl:single;
cl:crgba;
b:byte;
begin
 scl:=(sizx/112)/k;
 for y:=0 to round(112*k)-1 do for x:=0 to round(112*k)-1 do begin
  px:=trunc(x*scl);
  py:=trunc(y*scl);
  if px>=sizx then px:=sizx-1;
  if py>=sizy then px:=sizy-1;
  b:=minimap[px+py*sizx];
  cl[CLRED]  :=pal[b][0];
  cl[CLGREEN]:=pal[b][1];
  cl[CLBLUE] :=pal[b][2];
  for ky:=0 to trunc(1/scl) do for kx:=0 to trunc(1/scl) do begin
   dx:=xo+x+kx;
   dy:=yo+y+ky;
   if (dx<scrx)and(dy<scry) then pbcrgba(sdiscrp.srf)[dx+dy*scrx]:=cl;
  end;
 end;
end;
//############################################################################//
procedure maintim(ct,dt:double);
var xo,yo:integer;
k:single;
begin
 try if not sdilock then exit;sdicursor(1);fpsc:=fpsc+1;
  
 drfrect32(@sdiscrp,0,0,scrx-1,scry-1,gclblack);
 draw_widget(root,@sdiscrp,0,0,ct);

 thepal:=@pal[0];
 palanim(ct,dt);

 xo:=scrx-224;
 yo:=0;
 k:=2;
 draw_minimap(xo,yo,k);

 {
 drfrect32(@sdiscrp,100,100,200,200,tcrgba(0,128,0,255));
 drline32(@sdiscrp,10,10,scrx-10,scry-10,tcrgba(132,132,132,255));  
 draaline32(@sdiscrp,20,10,scrx-10,scry-10,tcrgba(132,132,132,255));  
 drrect32(@sdiscrp,90,90,210,210,tcrgba(0,128,0,255));
 drxrect32(@sdiscrp,88,88,212,212,tcrgba(0,128,0,255));     
 puttran32(@sdiscrp,50,50,200,200,tcrgba(0,0,255,255),0.5);

 drfrect32(@sdiscrp,40,300,200,400,tcrgba(0,128,0,255));
 wrftxt32(@sdiscrp,80,350,'Test',gclred);
 wrftxtr32(@sdiscrp,80,370,'Test',gclred);
 wrftxtcnt32(@sdiscrp,80,390,'Test',gclred);
 wrftxtbox32(@sdiscrp,80,310,180,350,'Test&Test 2',gclcyan);

 drfrectx32(@sdiscrp,240,310,160,100,tcrgba(0,128,0,255));
 wrfbgtxt32(@sdiscrp,280,360,'Test',gclred);
 wrfbgtxtr32(@sdiscrp,280,380,'Test',gclred);
 wrfbgtxtcnt32(@sdiscrp,280,400,'Test',gclred);
 wrfbgtxtbox32(@sdiscrp,280,320,380,360,'Test&Test 2',gclcyan);

 wrfbgx4txt32(@sdiscrp,280,460,'Test',gclwhite);

 putspr32(@sdiscrp,aj,300,10);
 putspr32(@sdiscrp,aj,curx-aj.xs div 2,cury-aj.ys div 2);
 drcirc32(@sdiscrp,curx,cury,100,tcrgba(110,255,110,255));   
 
 drrect32(@sdiscrp,0,0,scrx-1,scry-1,gclgreen);
 }
 if fpsdbg then begin ducnt:=tdu div 1000;tdu:=0;end;sdiunlock;sdiflip;except halt;end;
end;
//############################################################################//
procedure mainevent(evt,x,y:integer;key:word;shift:dword);
begin
 if root<>nil then if event_widget(root,evt,x,y,key,shift) then exit;
 case evt of
  glgr_evclose :halt;
  glgr_evresize:if root<>nil then resize_widget(root,x,y);
  glgr_evmsup  :;
  glgr_evmsdwn :;
  glgr_evmsmove:;
  glgr_evkeyup :;
  glgr_evkeydwn:case key of
   ukey_f4:if isf(shift,sh_alt) then halt;
   ukey_esc:halt;
  end;
 end;
end;
//############################################################################//
procedure upd_gui_values(n:integer);
begin
 widget_set_param(root,'cbx_56.dwn','0');
 widget_set_param(root,'cbx_112.dwn','0');
 widget_set_param(root,'cbx_224.dwn','0');
 widget_set_param(root,'cbx_448.dwn','0');
 case n of
  0:widget_set_param(root,'cbx_56.dwn','1');
  1:widget_set_param(root,'cbx_112.dwn','1');
  2:widget_set_param(root,'cbx_224.dwn','1');
  3:widget_set_param(root,'cbx_448.dwn','1');
 end;

 widget_set_param(root,'lbl_islands.name',stri(island_cnt));
 widget_set_param(root,'scb_islands.current',stri(island_cnt));
 widget_set_param(root,'lbl_lakes.name',stri(lake_cnt));
 widget_set_param(root,'scb_lakes.current',stri(lake_cnt));
 widget_set_param(root,'lbl_obs.name',stri(obstacle_cnt));
 widget_set_param(root,'scb_obs.current',stri(obstacle_cnt));

 widget_set_param(root,'lbl_islands_size.name',stri(island_size));
 widget_set_param(root,'scb_islands_size.current',stri(island_size));
 widget_set_param(root,'lbl_lakes_size.name',stri(lake_size));
 widget_set_param(root,'scb_lakes_size.current',stri(lake_size));

 widget_set_param(root,'lbl_edges.name',stri(round(edginess*100)));
 widget_set_param(root,'scb_edges.current',stri(round(edginess*100)));

 widget_set_param(root,'map_name.text',map_name);
end;
//############################################################################//
procedure change_map_size(n:integer);
begin
 case n of
  0:begin sizx:=56; sizy:=56; seed:=-2031466625;island_cnt:=14;lake_cnt:=13;island_size:=10;lake_size:=4; obstacle_cnt:=100;end;
  1:begin sizx:=112;sizy:=112;seed:=-1070622240;island_cnt:=25;lake_cnt:=13;island_size:=10;lake_size:=4; obstacle_cnt:=100;end;
  2:begin sizx:=224;sizy:=224;seed:=936559803;  island_cnt:=31;lake_cnt:=19;island_size:=20;lake_size:=19;obstacle_cnt:=606;end;
  3:begin sizx:=448;sizy:=448;seed:=-781212928; island_cnt:=34;lake_cnt:=13;island_size:=40;lake_size:=30;obstacle_cnt:=816;end;
 end;
 size_idx:=n;
 mapgen_makemap;
 upd_gui_values(size_idx);
end;
//############################################################################//
procedure change_cur_map(n:integer);
begin
 cur_map:=n;
 move(mapsdb[cur_map].rpallette[0],pal[0],768);
end;
//############################################################################//
procedure press_cbk(p:pointer;par:pointer);
begin
 case intptr(par) of
  0:begin seed:=random(65535);mapgen_makemap;end;
  1:mapgen_makemap;
  2:mapgen_wrlasm('maps/','maps/'+map_name+'.wrl');
  3:halt;
 end;
end;
//############################################################################//
procedure change_cbk(p:pointer;par:pointer;dwn:boolean);
begin
 case intptr(par) of
  0:begin widget_set_param(root,'cbx_green.dwn','0');change_cur_map(0);end;
  1:begin widget_set_param(root,'cbx_desert.dwn','0');change_cur_map(1);end;
  10,11,12,13:change_map_size(intptr(par)-10);
 end;
end;         
//############################################################################//
procedure scroll_cbk(c:pointer;par:pointer;pos:integer);
begin
 case intptr(par) of
  0:begin island_cnt:=pos;upd_gui_values(size_idx);end;
  1:begin lake_cnt:=pos;upd_gui_values(size_idx);end;
  2:begin obstacle_cnt:=pos;upd_gui_values(size_idx);end;
  3:begin island_size:=pos;upd_gui_values(size_idx);end;
  4:begin lake_size:=pos;upd_gui_values(size_idx);end;
  5:begin edginess:=pos/100;upd_gui_values(size_idx);end;
 end;
end;                                                                 
//############################################################################//
procedure meb_change(b:pedit_box_rec;par:pointer;evt,start,len:integer);
begin
 map_name:=trim(meb_save_text(b));
end;
//############################################################################//
procedure main;
var yo,cbx_step,size_xo,type_xo,scb_step,scb_xo,scb_xo2,scb_yo,scb_val_off,scb_xs,btn_xs,btn_ys,btn_off,btn_step,btn_xo,btn_yo:integer;
begin
 sdi_full_keys:=true;
 setsdi(800,226,32,false,'MAP generator',@maintim,@mainevent);fpsdbg:=false; max_fps:=30;

 root:=blank_widget('root');root.xs:=scrx;root.ys:=scry;
 mapgen_init;

 yo:=5;
 cbx_step:=20;
 size_xo:=110;
 type_xo:=10;

 scb_xs:=170;
 scb_step:=42;
 scb_yo:=5;
 scb_xo:=210;
 scb_xo2:=scb_xo+scb_xs+10;
 scb_val_off:=130;

 btn_xo:=5;  
 btn_yo:=180;
 btn_xs:=136;
 btn_ys:=40;
 btn_off:=5;
 btn_step:=btn_xs+btn_off;

 add_widget(root,'cbx_label','cbx_desert',type_xo,yo+cbx_step*0,cbx_step-1,cbx_step-1);
  widget_set_param(root,'cbx_desert.name','Пустыня');
  widget_set_param(root,'cbx_desert.change_cbk',strhex16(intptr(@change_cbk)));
  widget_set_param(root,'cbx_desert.cb_par',strhex16(0));
  widget_set_param(root,'cbx_desert.dwn','1');
 add_widget(root,'cbx_label','cbx_green',type_xo,yo+cbx_step*1,cbx_step-1,cbx_step-1);
  widget_set_param(root,'cbx_green.name','Зеленая');
  widget_set_param(root,'cbx_green.change_cbk',strhex16(intptr(@change_cbk)));
  widget_set_param(root,'cbx_green.cb_par',strhex16(1));
  widget_set_param(root,'cbx_green.dwn','0');

 add_widget(root,'cbx_label','cbx_56',size_xo,yo+cbx_step*0,cbx_step-1,cbx_step-1);
  widget_set_param(root,'cbx_56.name','56x56');
  widget_set_param(root,'cbx_56.change_cbk',strhex16(intptr(@change_cbk)));
  widget_set_param(root,'cbx_56.cb_par',strhex16(10));
 add_widget(root,'cbx_label','cbx_112',size_xo,yo+cbx_step*1,cbx_step-1,cbx_step-1);
  widget_set_param(root,'cbx_112.name','112x112');
  widget_set_param(root,'cbx_112.change_cbk',strhex16(intptr(@change_cbk)));
  widget_set_param(root,'cbx_112.cb_par',strhex16(11));
 add_widget(root,'cbx_label','cbx_224',size_xo,yo+cbx_step*2,cbx_step-1,cbx_step-1);
  widget_set_param(root,'cbx_224.name','224x224');
  widget_set_param(root,'cbx_224.change_cbk',strhex16(intptr(@change_cbk)));
  widget_set_param(root,'cbx_224.cb_par',strhex16(12));
 add_widget(root,'cbx_label','cbx_448',size_xo,yo+cbx_step*3,cbx_step-1,cbx_step-1);
  widget_set_param(root,'cbx_448.name','448x448');
  widget_set_param(root,'cbx_448.change_cbk',strhex16(intptr(@change_cbk)));
  widget_set_param(root,'cbx_448.cb_par',strhex16(13));

 add_widget(root,'scroll','scb_islands',scb_xo,scb_yo+20+0*scb_step,scb_xs,20);
  widget_set_param(root,'scb_islands.change_cbk',strhex16(intptr(@scroll_cbk)));
  widget_set_param(root,'scb_islands.cb_par',strhex16(0));
  widget_set_param(root,'scb_islands.size','200');
  widget_set_param(root,'scb_islands.screen','0');
 add_widget(root,'label','lbl_islands2',scb_xo,scb_yo+0*scb_step,100,20);widget_set_param(root,'lbl_islands2.name','Острова: ');
 add_widget(root,'label','lbl_islands',scb_xo+scb_val_off,scb_yo+0*scb_step,100,20);
 add_widget(root,'scroll','scb_lakes',scb_xo,scb_yo+20+1*scb_step,scb_xs,20);
  widget_set_param(root,'scb_lakes.change_cbk',strhex16(intptr(@scroll_cbk)));
  widget_set_param(root,'scb_lakes.cb_par',strhex16(1));
  widget_set_param(root,'scb_lakes.size','200');
  widget_set_param(root,'scb_lakes.screen','0');
 add_widget(root,'label','lbl_lakes2',scb_xo,scb_yo+1*scb_step+2,100,20);widget_set_param(root,'lbl_lakes2.name','Озера: ');
 add_widget(root,'label','lbl_lakes',scb_xo+scb_val_off,scb_yo+1*scb_step+2,100,20);
 add_widget(root,'scroll','scb_obs',scb_xo,scb_yo+20+2*scb_step,scb_xs,20);
  widget_set_param(root,'scb_obs.change_cbk',strhex16(intptr(@scroll_cbk)));
  widget_set_param(root,'scb_obs.cb_par',strhex16(2));
  widget_set_param(root,'scb_obs.size','1000');
  widget_set_param(root,'scb_obs.screen','0');
 add_widget(root,'label','lbl_obs2',scb_xo,scb_yo+2*scb_step+2,100,20);widget_set_param(root,'lbl_obs2.name','Горы: ');
 add_widget(root,'label','lbl_obs',scb_xo+scb_val_off,scb_yo+2*scb_step+2,100,20);

 add_widget(root,'scroll','scb_islands_size',scb_xo2,scb_yo+20+0*scb_step,scb_xs,20);
  widget_set_param(root,'scb_islands_size.change_cbk',strhex16(intptr(@scroll_cbk)));
  widget_set_param(root,'scb_islands_size.cb_par',strhex16(3));
  widget_set_param(root,'scb_islands_size.size','200');
  widget_set_param(root,'scb_islands_size.screen','0');
 add_widget(root,'label','lbl_islands_size2',scb_xo2,scb_yo+0*scb_step,100,20);widget_set_param(root,'lbl_islands_size2.name','Размер: ');
 add_widget(root,'label','lbl_islands_size',scb_xo2+scb_val_off,scb_yo+0*scb_step,100,20);
 add_widget(root,'scroll','scb_lakes_size',scb_xo2,scb_yo+20+1*scb_step,scb_xs,20);
  widget_set_param(root,'scb_lakes_size.change_cbk',strhex16(intptr(@scroll_cbk)));
  widget_set_param(root,'scb_lakes_size.cb_par',strhex16(4));
  widget_set_param(root,'scb_lakes_size.size','200');
  widget_set_param(root,'scb_lakes_size.screen','0');
 add_widget(root,'label','lbl_lakes_size2',scb_xo2,scb_yo+1*scb_step+2,100,20);widget_set_param(root,'lbl_lakes_size2.name','Размер: ');
 add_widget(root,'label','lbl_lakes_size',scb_xo2+scb_val_off,scb_yo+1*scb_step+2,100,20);
 add_widget(root,'scroll','scb_edges',scb_xo2,scb_yo+20+2*scb_step,scb_xs,20);
  widget_set_param(root,'scb_edges.change_cbk',strhex16(intptr(@scroll_cbk)));
  widget_set_param(root,'scb_edges.cb_par',strhex16(5));
  widget_set_param(root,'scb_edges.size','50');
  widget_set_param(root,'scb_edges.screen','0');
 add_widget(root,'label','lbl_edges2',scb_xo2,scb_yo+2*scb_step+2,100,20);widget_set_param(root,'lbl_edges2.name','Антигладкость: ');
 add_widget(root,'label','lbl_edges',scb_xo2+scb_val_off,scb_yo+2*scb_step+2,100,20);

 add_widget(root,'button','btn_regen',btn_xo+0*btn_step,btn_yo,btn_xs,btn_ys);
  widget_set_param(root,'btn_regen.name','Пересоздать');
  widget_set_param(root,'btn_regen.press_cbk',strhex16(intptr(@press_cbk)));
  widget_set_param(root,'btn_regen.cb_par',strhex16(0));
 add_widget(root,'button','btn_regen_this',btn_xo+1*btn_step,btn_yo,btn_xs,btn_ys);
  widget_set_param(root,'btn_regen_this.name','Пересоздать эту');
  widget_set_param(root,'btn_regen_this.press_cbk',strhex16(intptr(@press_cbk)));
  widget_set_param(root,'btn_regen_this.cb_par',strhex16(1));
 add_widget(root,'button','btn_save',btn_xo+2*btn_step,btn_yo,btn_xs,btn_ys);
  widget_set_param(root,'btn_save.name','Сохранить');
  widget_set_param(root,'btn_save.press_cbk',strhex16(intptr(@press_cbk)));
  widget_set_param(root,'btn_save.cb_par',strhex16(2));
 add_widget(root,'button','btn_exit',btn_xo+3*btn_step,btn_yo,btn_xs,btn_ys);
  widget_set_param(root,'btn_exit.name','Выход');
  widget_set_param(root,'btn_exit.press_cbk',strhex16(intptr(@press_cbk)));
  widget_set_param(root,'btn_exit.cb_par',strhex16(3));
                                                           
 add_widget(root,'label','lbl_name',5,150,40,20);widget_set_param(root,'lbl_name.name','Имя: ');
 add_widget(root,'editbox','map_name',45,150,scb_xo-10,16);
  widget_set_param(root,'map_name.text','');
  widget_set_param(root,'map_name.add_cb',stri(MEB_CB_CHANGE)+','+strhex16(intptr(@meb_change)));



 change_cur_map(0);
 change_map_size(1);

 sdiloop;
end;
//############################################################################//
begin
 main;
end. 
//############################################################################//

