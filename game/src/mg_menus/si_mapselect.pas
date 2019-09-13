//############################################################################//
//Map select menu
unit si_mapselect;
interface
uses asys,maths,grph,graph8,sdigrtools,
mgrecs,mgl_common,sdirecs,sdicalcs,sdisound,sdimenu,sdigui,sds_rec;
//############################################################################//
implementation
//############################################################################//
const
xs=540;
ys=460;
//############################################################################//
var map_select_off:integer=0;
map_lbl:plabel_type;
//############################################################################//
procedure map_pos(out x,y:integer;xn,yn,i,j:integer);
begin
 x:=xn+140+i*120;
 y:=yn+50+j*130;
end;
//############################################################################//
procedure draw_mapselect_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,j,x,y,xp:integer;
st:string;
begin
 if map_lbl=nil then exit;
 map_lbl.txt:=s.ng_map_name;

 if s.frame_map_ev and (s.total_maps>0) then begin
  for i:=0 to 2 do for j:=0 to 1 do begin
   map_pos(x,y,xn,yn,i,j);
   tran_rect8(s.cg,dst,x-1,y-1,112+2,112+2,0);

   if map_select_off+i+j*3<s.total_maps then begin
    if map_select_off+i+j*3=s.ng_map_id then begin putspr8(dst,s.mmapbmp  [map_select_off+i+j*3],x,y);drxrect8(dst,x,y,x+112-1,y+112-1,1);drxrect8(dst,x+1,y+1,x+112-2,y+112-2,1);end
                                        else       putspr8(dst,s.mmapbmpbw[map_select_off+i+j*3],x,y);
    wrtxt8(s.cg,dst,x+5,y-10,s.map_list[map_select_off+i+j*3].name,2);
   end;
  end;

  x:=xn+10;
  y:=yn+110;
  drrectx8(dst,x-1,y-1,112+2,112+2,line_color);
  putspr8(dst,s.mmapbmp[s.ng_map_id],x,y);

  xp:=10;
  x:=xn+xp;
  y:=yn+ys-150;
  tran_rect8(s.cg,dst,x-1,y-1,xs-2*xp+2,90+2,0);
  st:=s.map_list[s.ng_map_id].descr;
  if st<>'' then wrtxtxbox8(s.cg,dst,x+5,y+5,xs-2*xp,80,st,4);
 end;
end;   
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
sb:pscrollbox_type;
begin 
 result:=true;

 mn:=MS_MAPSELECT; 
 pg:=0;

 add_label (mn,pg,xs div 2,013,LB_BIG_CENTER,0,po('Map'));

          add_button(mn,pg,5,ys-5-50,xs-2*5,50,0,5,po('Select'),on_ok_btn,0);
 map_lbl:=add_label (mn,pg,66,98,LB_CENTER,2,'map_name');

 sb:=add_scrollbox(mn,pg,SCB_VERTICAL,500,50,500,265,24,25,6,0,(s.total_maps div 6)*6-6*ord(s.total_maps mod 6=0),false,@map_select_off,nil,0);
     add_scrolarea(mn,pg,-1,0,0,xs,ys,6,112,0,sb.bottom,@map_select_off,nil,0,sb);
end;
//############################################################################//
function ok(s:psdi_rec):boolean;  
begin 
 result:=true;
 enter_menu(s,MS_MULTIPLAYER);
end;  
//############################################################################//
function cancel(s:psdi_rec):boolean;  
begin 
 result:=true;
 add_step(@s.steps,sts_save_def_rules);
 enter_menu(s,MS_MULTIPLAYER);   
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;
 map_select_off:=0;
 calcmnuinfo(s,MS_MAPSELECT);
end;   
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
var i,f:integer;
begin      
 result:=true;
 i:=s.ng_map_id;
 f:=i;
 case key of
  key_1..key_6:if map_select_off+integer(key-key_1)<s.total_maps then i:=map_select_off+integer(key-key_1);
  KEY_UP :  if i>2 then i:=i-3;
  KEY_DWN:  if i<s.total_maps-3 then i:=i+3 else i:=s.total_maps-1;
  KEY_LEFT: if i>0 then i:=i-1;
  KEY_RIGHT:if i<s.total_maps-1 then i:=i+1;
 end;
 if i<>f then begin // next code used 3 times. To extract to new function
  s.ng_map_id:=i;
  map_select_off:=(s.ng_map_id div 6)*6;
  upd_minimap_pal(s,s.ng_map_id);
  calcmnuinfo(s,MS_MULTIPLAYER);
  s.newgame.map_name:=s.map_list[s.ng_map_id].file_name;
  add_step(@s.steps,sts_save_def_rules);
  snd_click(SND_TCK);
 end;
end; 
//############################################################################//
function mouseup(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i,j,xx,yy:integer;
begin
 result:=true;
 for i:=0 to 2 do for j:=0 to 1 do begin
  map_pos(xx,yy,xn,yn,i,j);
  if inrects(x,y,xx,yy,112,112)then if map_select_off+i+3*j<s.total_maps then begin
   if map_select_off+i+3*j<>s.ng_map_id then begin
    snd_click(SND_TCK);
    s.ng_map_id:=map_select_off+i+3*j;   
    s.newgame.map_name:=s.map_list[s.ng_map_id].file_name;   
    add_step(@s.steps,sts_save_def_rules);
    upd_minimap_pal(s,s.ng_map_id);
    calcmnuinfo(s,MS_MULTIPLAYER);
   end else if s.msd_dt<0.5 then menu_ok(s);
  end;
 end;
end; 
//############################################################################//
begin
 add_menu('Map select menu',MS_MAPSELECT,xs div 2,ys div 2,BCK_SHADE,init,nil,draw_mapselect_menu,ok,cancel,enter,nil,nil,keydown,nil,mouseup,nil,nil);
end.
//############################################################################//

