//############################################################################//
//Main menu
unit si_main;
interface
uses asys,grph
{$ifdef update},upd_cli{$endif}
,mgrecs,mgl_common,sdirecs,sdiauxi,sdicalcs,sdimenu,sdigui,sdisound;
//############################################################################//
//Where data is, set in sdimaxg_main
var data_location:integer=-1;
//############################################################################//
implementation
//############################################################################//
var
menu:integer;
btn:array[0..5] of pbutton_type;
//############################################################################//
procedure translocate_buttons; 
var bx,by,xo,yo,gap:integer;
begin
 xo:=10;
 yo:=60;
 gap:=5;
 bx:=(scrx-10-2*xo-3*gap) div 2;
 by:=scry div 3-2*xo-3*gap;
 
 btn[0].x:=xo+(bx+gap)*0;btn[0].y:=yo+(by+gap)*0;btn[0].xs:=bx;btn[0].ys:=by;
 btn[1].x:=xo+(bx+gap)*1;btn[1].y:=yo+(by+gap)*0;btn[1].xs:=bx;btn[1].ys:=by;
 btn[2].x:=xo+(bx+gap)*1;btn[2].y:=yo+(by+gap)*1;btn[2].xs:=bx;btn[2].ys:=by;
 if btn[3]<>nil then begin btn[3].x:=xo+round((bx+gap)*0.5);btn[3].y:=yo+(by+gap)*1;btn[3].xs:=bx div 2;btn[3].ys:=by;end;
 btn[4].x:=xo+(bx+gap)*0;btn[4].y:=yo+(by+gap)*1;btn[4].xs:=bx div 2;btn[4].ys:=by;

 btn[5].x:=xo+(bx+gap)*2-gap-100;
 btn[5].y:=10;
 btn[5].xs:=100;
 btn[5].ys:=yo-10-gap;
end;
//############################################################################//
//Draws end turn menu
procedure draw_main_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer); 
begin
 if menu_list[menu].xn<>(scrx div 2-10) then event_frame(s);
 menu_list[menu].xn:=scrx div 2-10;
 menu_list[menu].yn:=scry div 3;
 translocate_buttons; 
end;   
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin 
 case par of  
  0:enter_menu(s,MS_MULTIPLAYER);
  1:enter_menu(s,MS_ABOUT);
  2:enter_menu(s,MG_LOADSAVE);
  3:enter_menu(s,MS_OPTIONS);
  4:begin haltprog;exit;end; 
  5:begin   
   {$ifdef update}
   if not upd_can_we_update then begin mbox(s,po('Cannot update - Disk not writable'),po('Update'));exit;end;
   enter_menu(s,MS_UPDATE);
   {$endif}
  end;
 end;
end;
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;
 case key of
  {$ifdef update}key_u:begin enter_menu(s,MS_UPDATE,SND_BUTTON);exit;end;{$endif}
  key_y,key_n:begin enter_menu(s,MS_MULTIPLAYER,SND_BUTTON);exit;end;
  key_p,key_l:begin enter_menu(s,MG_LOADSAVE,SND_BUTTON);exit;end;
  key_g,key_o:begin enter_menu(s,MS_OPTIONS,SND_BUTTON);exit;end;
  key_d,key_e:begin snd_click(SND_BUTTON);haltprog;exit;end;  //Why sound? No time to make it anyway.
 end;
end; 
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;

 mn:=MS_MAINMENU;
 pg:=0;
  
 add_label (mn,pg,110-23,015,1,'M.A.X.',1,162,151,0);
 add_label (mn,pg,110+23,015,1,'Gold',1,4,151,0);
 add_label (mn,pg,110,035,1,sdi_progver,1,162,151,0);

 {$ifdef linkdirect}add_label (mn,pg,110+70,035,0,po('Server included'),1,162,151,0);{$endif}
 case data_location of
  LOC_DIR:  add_label(mn,pg,110+70,015,0,po('Data unpacked'),1,162,151,0);
  LOC_ZIP:  add_label(mn,pg,110+70,015,0,po('Data extracted'),1,162,151,0);
  LOC_INNER:;//add_label(mn,pg,110+70,015,0,po('Internal data'),1,162,151,0);
  else      add_label(mn,pg,110+70,015,0,po('Data location unknown!'),1,162,151,0);
 end;

 btn[0]:=add_button(mn,pg,0,0,0,0,19,20,po('New game'),on_btn,0);
 btn[1]:=add_button(mn,pg,0,0,0,0,19,20,po('Network Games'),on_btn,2);
 btn[2]:=add_button(mn,pg,0,0,0,0,19,20,po('Options'),on_btn,3);
 {$ifdef update}btn[3]:=add_button(mn,pg,0,0,0,0,19,20,po('Update'),on_btn,5);{$else}btn[3]:=nil;{$endif}
 btn[4]:=add_button(mn,pg,0,0,0,0,19,20,po('Exit game'),on_btn,4);

 btn[5]:=add_button(mn,pg,0,0,0,0,19,20,po('About'),on_btn,1);
       
 translocate_buttons; 
end;    
//############################################################################//
function cancel(s:psdi_rec):boolean;  
begin 
 result:=true;
 haltprog;   
end;    
//############################################################################//
begin      
 menu:=add_menu('Main menu',MS_MAINMENU,150,-250,BCK_SHADE,init,nil,draw_main_menu,nil,cancel,nil,nil,nil,keydown,nil,nil,nil,nil);
end.
//############################################################################//
