//############################################################################//
unit sdimouseup;
interface
uses asys,grph,mgrecs,mgl_common,mgl_cursors,mgl_mapclick,sdirecs,sdiauxi,sdicalcs,sdigui,sdikeyinput,sdimenu,sds_rec;
//############################################################################//                                             
procedure mg_msup(s:psdi_rec;shift:dword;x,y:integer);
//############################################################################//
implementation  
//############################################################################//
procedure mg_selects(s:psdi_rec;shift:dword;x,y:integer);
begin try
 if click_rmnu(s,x,y,shift,false) then exit;
 
 if s.cur_menu=MG_NOMENU then if not s.rmov then begin
  event_frame(s);
  event_minimap(s);
  do_mouse_event(s.the_game,s.cur_map_x,s.cur_map_y,1*ord(isf(shift,sh_left) or isf(shift,sh_middle))+2*ord(isf(shift,sh_right))*ord(not s.rmov)+4*ord(isf(shift,sh_shift) or isf(shift,sh_middle))+8*ord(isf(shift,sh_alt))+16*ord(isf(shift,sh_ctrl))+32*1,s.active_events or sds_is_replay(@s.steps));
  curs_calc(s.the_game,s.cur_map_x,s.cur_map_y,isf(shift,sh_shift));
 end;
 except stderr(s,'sdimouseup','mg_selects'); end;
end;
//############################################################################//
procedure mouseup_game(s:psdi_rec;shift:dword;x,y:integer);
begin try
 if inrectv(x,y,s.cg.intf.mmap) then begin minimap_pos(s,x,y);exit;end;     
 if click_rmnu(s,x,y,shift,true) then exit;
 if not s.ignore_mouseup then mg_selects(s,s.down_shift,x,y);
 except stderr(s,'sdimouseup','mouseup_game'); end;
end;
//############################################################################//
procedure mg_msup(s:psdi_rec;shift:dword;x,y:integer);
label fin;
var xn,yn:integer;
begin try
 if s.mbox_on then exit;
 
 calc_menuframe_pos(s.cur_menu,xn,yn);  
                
 move_curs(s,shift,x,y);
 
 event_frame(s);               
 event_map_reposition(s);
 
 if ibxm then goto fin;
 if gui_mouse_up(s,shift,x,y) then goto fin;
 
 if s.state=CST_THEGAME then if isf(shift,sh_right) or isf(shift,sh_left) then begin
  if s.rmov then shift:=shift and not sh_left;
  if s.cur_menu=MG_NOMENU then s.gm_comment_mode:=false;
 end;   
 s.rmov:=false;

 case s.state of
  CST_THEMENU:if isf(shift,sh_left) then mu_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn);
  CST_INSGAME:if isf(shift,sh_left) then mu_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn);
  CST_THEGAME:if s.cur_menu<>MG_NOMENU then mu_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn) else mouseup_game(s,shift,x,y);
 end;

fin:
 s.ignore_mouseup:=false;
 s.ignore_mousemove:=false;

 except stderr(s,'sdimouseup','mg_msup'); end;
end;
//############################################################################//
begin
end.
//############################################################################//
