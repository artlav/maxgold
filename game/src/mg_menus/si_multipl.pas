//############################################################################//
//Multiplayer setup menu
unit si_multipl;
interface
uses asys,maths,strval,grph,graph8,sdigrtools,
mgrecs,mgl_common,sdirecs,sdiauxi,sdicalcs,sdimenu,sdiinit,sdigui,sdisound,sds_rec;
//############################################################################//   
procedure default_newgame(s:psdi_rec);
//############################################################################//   
implementation  
//############################################################################/
const
x_off=20;
y_off=0;

total_pages=7;
 
R_TXT:array[0..2]of string=('Raw','Fuel','Gold');
R_INT:array[0..2]of string=('Poor','Medium','Rich');
//############################################################################/
var
newgame_game_name_ib:pinputbox_type;  
newgame_curplr_btn:pscrollbox_type;
map_btn:pbutton_type;

last_page:integer=0;
menu_active:boolean=false;   
res_state:array[0..2]of array[0..2]of boolean;
//############################################################################//
procedure default_newgame(s:psdi_rec);
var i:integer;
begin
 s.newgame.plr_cnt:=2;
 s.ng_cur_plr:=0;
 for i:=0 to s.newgame.plr_cnt-1 do s.newgame.plr_names[i]:='plr'+stri(i+1);
 mk_gamename(s); 
 s.ng_curplr_name:=s.newgame.plr_names[s.ng_cur_plr];   
 
 s.newgame.rules:=s.def_rules;   
 s.newgame.map_name:=def_map;
 s.ng_map_id:=get_map_by_name(s,s.newgame.map_name);
 if s.ng_map_id=-1 then s.ng_map_id:=0;   
                              
 if newgame_game_name_ib<>nil then newgame_game_name_ib.vr^:=s.newgame.name;
 
 calcmnuinfo(s,MS_MULTIPLAYER);
 reup_gui(s);
 gui_mouse_up(s,0,-1,-1);
end;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);  
var i,x,y:integer;
r:prulestyp;
begin 
 case par of       
  5:enter_menu(s,MS_RULES);
  //Map select
  22:enter_menu(s,MS_MAPSELECT);    
  //Player count scroll
  23:begin
   if s.newgame.plr_cnt>20 then s.newgame.plr_cnt:=20;
   if s.newgame.plr_cnt<2 then s.newgame.plr_cnt:=2;
   if s.ng_cur_plr>s.newgame.plr_cnt then s.ng_cur_plr:=s.newgame.plr_cnt-1;
   calcmnuinfo(s,MS_MULTIPLAYER);
   s.ng_curplr_name:=s.newgame.plr_names[s.ng_cur_plr];
  end;   
  //Player current scroll
  24:begin
   if s.ng_cur_plr>s.newgame.plr_cnt then s.ng_cur_plr:=s.newgame.plr_cnt-1;
   if s.ng_cur_plr<0 then s.ng_cur_plr:=0;  
   calcmnuinfo(s,MS_MULTIPLAYER);                   
   s.ng_curplr_name:=s.newgame.plr_names[s.ng_cur_plr];
  end;

  70..90:begin
   x:=(par-70) div 3;
   y:=(par-70) mod 3;
   r:=@s.newgame.rules; 
   for i:=0 to 2 do res_state[x][i]:=false;
   res_state[x][y]:=true;
   r.res_levels[x+1]:=y;
  end;

  91:if s.cur_menu_page>0 then s.cur_menu_page:=s.cur_menu_page-1;
  92:if s.cur_menu_page<total_pages-1 then s.cur_menu_page:=s.cur_menu_page+1;
 end;
 add_step(@s.steps,sts_save_def_rules);
end;      
//############################################################################//
procedure on_box(s:psdi_rec;ib:pinputbox_type);
begin 
 case ib.par of
  0:s.newgame.name:=ib.vr^;
  1:begin
   s.newgame.plr_names[s.ng_cur_plr]:=s.ng_curplr_name;
   mk_gamename(s);
   newgame_game_name_ib.vr^:=s.newgame.name;
  end;
 end;
 add_step(@s.steps,sts_save_def_rules);
end;
//############################################################################/
procedure draw_multipl_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,j:integer;
r:prulestyp;
begin
 if map_btn=nil then exit;
 map_btn.txt:=s.ng_map_name;

 last_page:=s.cur_menu_page;
 wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+ 8,po('New game'),0);  
 wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+30,po('Page')+' '+stri(s.cur_menu_page+1)+'/'+stri(total_pages),0);

 case s.cur_menu_page of
  0:wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Players Parameters'),0);  
  1:begin         
   wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Map'),0);  
   if s.frame_map_ev then drrectx8(dst,xn+menu_xs div 2-56-1,yn+data_off-1,112+2,112+2,line_color);
   if s.frame_mmap_ev and(s.total_maps>0)then putspr8(dst,s.mmapbmp[s.ng_map_id],xn+menu_xs div 2-56,yn+data_off);
  end;       
  2:wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Game settings'),0);  
  3:wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Rules'),0);
  4:wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Rules'),0);
  5:begin
   wrbgtxtcnt8(s.cg,dst,xn+menu_xs div 2,yn+cap_off,po('Resources'),0);
   r:=@s.newgame.rules;
   for i:=0 to 2 do for j:=0 to 2 do res_state[i][j]:=r.res_levels[i+1]=j;
  end;
 end;
end;
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
var i,f:integer;
begin
 result:=true;
 //map select
 i:=s.ng_map_id;
 f:=i;
 case key of
  key_m:begin snd_click(SND_BUTTON);on_btn(s,22,0);end;
  KEY_LEFT: begin s.cur_menu_page:=s.cur_menu_page-1;if s.cur_menu_page<=0 then s.cur_menu_page:=0;end;
  KEY_RIGHT:begin s.cur_menu_page:=s.cur_menu_page+1;if s.cur_menu_page>total_pages-1 then s.cur_menu_page:=total_pages-1;end;
 end;
 if i<>f then begin
  s.ng_map_id:=i;
  upd_minimap_pal(s,s.ng_map_id);
  calcmnuinfo(s,MS_MULTIPLAYER);
  snd_click(SND_TCK);
 end;
 if isf(shift,sh_shift) then begin
  //Player count
  i:=s.newgame.plr_cnt;
  f:=i;
  case key of
   key_2..key_9:if key-key_1<20 then i:=key-key_1+1;
   KEY_DWN:if i>2 then i:=i-1;
   KEY_UP :if i<20 then i:=i+1;
  end;
  if i<>f then begin 
   s.newgame.plr_cnt:=i;
   on_btn(s,24,0);
   snd_click(SND_ACCEPT);
  end; //visual bug here - scroll buttons disabled
 end else begin
  //Player current
  i:=s.ng_cur_plr;
  f:=i;
  case key of
   key_1..key_9:if integer(key-key_1)<s.newgame.plr_cnt then i:=key-key_1;
   KEY_DWN:if i>0 then i:=i-1;
   KEY_UP :if i<s.newgame.plr_cnt-1 then i:=i+1;
  end;
  if i<>f then begin 
   s.ng_cur_plr:=i;
   on_btn(s,24,0);
   snd_click(SND_ACCEPT);
  end; //visual bug here - scroll buttons disabled
 end;
 add_step(@s.steps,sts_save_def_rules);
end;
//############################################################################//
function mouseup(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
begin    
 result:=true;
 case s.cur_menu_page of
  1:if inrects(x,y,xn+262,yn+79,112,112) then enter_menu(s,MS_MAPSELECT,SND_BUTTON);
 end;  
 add_step(@s.steps,sts_save_def_rules);
end;   
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
begin    
 result:=true;
 calcmnuinfo(s,MS_MULTIPLAYER);
end;     
//############################################################################//
function ok(s:psdi_rec):boolean;   
begin 
 result:=true;
 menu_active:=false;
 if s.got_def_rules then add_step(@s.steps,sts_save_def_rules);
 if (s.total_maps>0)and s.got_def_rules then begin
  set_load_box_caption(s,'');
  clear_load_box(s);
  init_new_game(s);
 end;
end;
//############################################################################// 
procedure set_page_buttons(mn,pg:integer);
begin  
 add_button(mn,pg,            5,5,100,50,19,20,po('Prev'),on_btn,91);
 add_button(mn,pg,menu_xs-100-5,5,100,50,19,20,po('Next'),on_btn,92);
 
 add_button(mn,pg,5               ,menu_ys-50-5,100,50,19,20,po('Back'),on_cancel_btn,0);
 add_button(mn,pg,menu_xs-100-5   ,menu_ys-50-5,100,50,19,20,po('Begin'),on_ok_btn,0);
 add_button(mn,pg,menu_xs div 2-50,menu_ys-50-5,100,50,19,20,po('Unisets'),on_btn,5);
end;
//############################################################################// 
function init(s:psdi_rec):boolean;      
var mn,pg,i,j:integer;
rul:prulestyp;
begin         
 result:=true;
 rul:=@s.newgame.rules;
 
 mn:=MS_MULTIPLAYER;
 
 //Players setup
 pg:=0;
 set_page_buttons(mn,pg);
 add_numeric_input(mn,pg,x_off,y_off+070,po('Number of Players'),1,2,20,@s.newgame.plr_cnt,on_btn,23);
 newgame_curplr_btn:=add_numeric_input(mn,pg,x_off,y_off+120,po('Player'),1,0,20,@s.ng_cur_plr,on_btn,24);
 add_text_input(mn,pg,x_off,y_off+170,170,3,po('Player name'),@s.ng_curplr_name,on_box,1,'');

 //Map
 pg:=1;      
 set_page_buttons(mn,pg);
 map_btn:=add_button(mn,pg,menu_xs div 2-60,data_off+112+5,120,50,19,20,'map_name',on_btn,22);

 //Parameters    
 pg:=2;    
 set_page_buttons(mn,pg);
 add_numeric_input(mn,pg,x_off,y_off+120,po('Starting gold'),50,0,2000,@rul.goldset,nil,0);
 add_numeric_input(mn,pg,x_off,y_off+160,po('Moratorium'),10,0,200,@rul.moratorium,nil,0);
 add_numeric_input(mn,pg,x_off,y_off+200,po('Moratorium range'),1,0,200,@rul.moratorium_range,nil,0);
 newgame_game_name_ib:=add_text_input(mn,pg,x_off,y_off+75,170,0,po('Game name'),nil,on_box,0,s.newgame.name);

 //Rules
 pg:=3;      
 set_page_buttons(mn,pg);
 add_clickbox(mn,pg,0,0,po('Fuel')              ,nil,@rul.fueluse,nil);
 add_clickbox(mn,pg,0,1,po('Fuel exchange')     ,nil,@rul.fuelxfer,nil);
 add_clickbox(mn,pg,0,2,po('No Passwords')      ,nil,@rul.nopaswds,nil);
 add_clickbox(mn,pg,0,3,po('Debug mode')        ,nil,@rul.debug,nil); 
 
 add_clickbox(mn,pg,1,0,po('Start with radar')   ,nil,@rul.startradar,nil);
 add_clickbox(mn,pg,1,2,po('No survey')          ,nil,@rul.no_survey,nil);
 add_clickbox(mn,pg,1,3,po('Center 4X scan')     ,nil,@rul.center_4x_scan,nil);

 //Rules continue
 pg:=4;
 set_page_buttons(mn,pg);
 add_clickbox(mn,pg,0,0,po('Expensive refuel')     ,nil,@rul.expensive_refuel,nil);
 add_clickbox(mn,pg,0,1,po('No military purchases'),nil,@rul.no_buy_atk,nil);
 add_clickbox(mn,pg,0,2,po('On landing pads')      ,nil,@rul.load_onpad_only,nil);

 add_clickbox(mn,pg,1,0,po('No Speed')             ,nil,@rul.unload_all_speed,nil);
 add_clickbox(mn,pg,1,1,po('No Shots')             ,nil,@rul.unload_all_shots,nil);
 add_clickbox(mn,pg,1,2,po('-1 Speed (Unloading)') ,nil,@rul.unload_one_speed,nil);
 add_clickbox(mn,pg,1,3,po('-1 speed (Loading)')   ,nil,@rul.load_sub_one_speed,nil);

 //Rules continue
 pg:=5;
 set_page_buttons(mn,pg);
 add_clickbox(mn,pg,0,0,po('Direct gold')          ,nil,@rul.direct_gold,nil);

 add_clickbox(mn,pg,1,0,po('Lay connectors')       ,nil,@rul.lay_connectors,nil);  
 add_clickbox(mn,pg,1,1,po('Direct landing')       ,nil,@rul.direct_land,nil);
 
 //Resourses
 pg:=6;
 set_page_buttons(mn,pg);
 add_numeric_input(mn,pg,x_off,y_off+80,po('Resource fields'),10,0,200,@rul.resset,nil,0);
 for i:=0 to 2 do for j:=0 to 2 do add_clickbox_3(mn,pg,j,i+2,po(R_TXT[i])+'&'+po(R_INT[j]),nil,@res_state[i][j],on_btn,70+i*3+j);   

 if newgame_game_name_ib<>nil then newgame_game_name_ib.vr^:=s.newgame.name;
end;                                            
//############################################################################//
function deinit(s:psdi_rec):boolean;     
begin   
 result:=true; 
 
 newgame_curplr_btn:=nil;
 newgame_game_name_ib:=nil;      
end;  
//############################################################################//
function calc(s:psdi_rec;par:integer):boolean;      
var i:integer;
begin   
 result:=true;

 if s.total_maps>0 then s.ng_map_name:=s.map_list[s.ng_map_id].file_name else s.ng_map_name:=po('No maps');
 if(s.total_maps<>0)and(s.ng_map_id<s.total_maps)then upd_minimap_pal(s,s.ng_map_id);

 for i:=0 to s.newgame.plr_cnt-1 do begin
  if s.newgame.plr_names[i]='' then s.newgame.plr_names[i]:='plr'+stri(i+1);
 end;
    
 if newgame_curplr_btn<>nil then newgame_curplr_btn.bottom:=s.newgame.plr_cnt-1;
end;            
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;
 s.cur_menu_page:=last_page;
 if not menu_active then begin
  s.got_def_rules:=false;
  add_step(@s.steps,sts_get_maps);
  add_step(@s.steps,sts_get_def_rules);
  add_step(@s.steps,sts_get_unisets);
  add_step(@s.steps,sts_def_newgame);
  menu_active:=true;
 end;
 calcmnuinfo(s,MS_MULTIPLAYER);
end;   
//############################################################################//
begin      
 add_menu('Multiplayer setup menu',MS_MULTIPLAYER,menu_xs div 2,menu_ys div 2,BCK_SHADE,init,deinit,draw_multipl_menu,ok,nil,enter,nil,calc,keydown,mousedown,mouseup,nil,nil);
end.
//############################################################################//

