//############################################################################//
unit sdimousedwn;
interface
uses asys,maths,grph,mgrecs,mgl_common,mgl_rmnu,mgl_attr,sdirecs,sdiauxi,sdisound,sdicalcs,sdigui,sdikeyinput,sdimenu;
//############################################################################//
procedure mg_msdown(s:psdi_rec;shift:dword;x,y:integer);
//############################################################################//
implementation  
//############################################################################//
function md_mainint(s:psdi_rec;shift:dword;x,y:integer):boolean;
//var i:integer;
//d:single;
begin result:=false; try
 if s.cur_menu<>MG_NOMENU then exit;  

 if isf(shift,sh_right) then event_minimap(s);
 if inrect(x,y,0,0,scrx-1,scry-1) then snd_click(SND_TCK);

 ////FIXME?
 {
 //Selection and position saves
 if isf(shift,sh_left) or isf(shift,sh_right) then begin
  if inrectv(x,y,s.cg.intf.stored_pos) then begin
   if s.cg.intf.stored_pos.sx>s.cg.intf.stored_pos.sy then d:=s.cg.intf.stored_pos.sx/MAX_PRESEL
                                                      else d:=s.cg.intf.stored_pos.sy/MAX_PRESEL;
   for i:=0 to MAX_CAMPOS-1 do begin
    if((s.cg.intf.stored_pos.sx> s.cg.intf.stored_pos.sy)and(x>=gcrx(s.cg.intf.stored_pos)+i*d)and(x<=gcrx(s.cg.intf.stored_pos)+(i+1)*d))or
      ((s.cg.intf.stored_pos.sx<=s.cg.intf.stored_pos.sy)and(y>=gcry(s.cg.intf.stored_pos)+i*d)and(y<=gcry(s.cg.intf.stored_pos)+(i+1)*d))then begin
     menu_cam_position(s,i,isf(shift,sh_right));
     if isf(shift,sh_right) then snd_click(SND_TOGGLE) else snd_click(SND_ACCEPT);
     result:=true;
     exit;
    end;
   end;
  end;
 end;
 }
 except stderr(s,'sdimousedwn','md_mainint'); end;
end;
//############################################################################//
procedure mg_selects(s:psdi_rec;shift:dword;x,y:integer);
begin
 if click_rmnu(s,x,y,shift,false) then begin s.ignore_mouseup:=true;exit;end;
end;
//############################################################################//
procedure md_game(s:psdi_rec;shift:dword;x,y:integer);
begin try
 if s.gm_comment_mode then menu_comment(s,s.cur_map_x,s.cur_map_y);
 if inrectv(x,y,s.cg.intf.mmap) then begin 
  minimap_pos(s,x,y);
  s.ignore_mouseup:=true;
  exit;
 end;
 except stderr(s,'sdimousedwn','md_game'); end;
end; 
//############################################################################//
procedure md2_game(s:psdi_rec;shift:dword;x,y:integer);
var un:ptypunits;
begin try
 if s.debug_placing then exit;
 
 if inrectv(x,y,s.cg.intf.uview) then begin
  un:=get_sel_unit(s.the_game);
  if un<>nil then begin
   if isf(shift,sh_left) then begin
    if isa(s.the_game,un,a_ours) then set_game_menu(s.the_game,MG_UNIT_RENAME); 
   end else if isf(shift,sh_right) then set_game_menu(s.the_game,MG_UNITINFO);
  end else set_game_menu(s.the_game,MG_CLAN_INFO);
  s.ignore_mouseup:=true;
  exit;
 end else if inrectv(x,y,s.cg.intf.stats) then begin
  if get_sel_unit(s.the_game)<>nil then if isf(shift,sh_left) then set_game_menu(s.the_game,MG_UNITINFO);
  s.ignore_mouseup:=true;
  exit;
 end;
 
 //Selections
 mg_selects(s,shift,x,y);
 except stderr(s,'sdimousedwn','md2_game'); end;
end;
//############################################################################//
procedure mg_msdown(s:psdi_rec;shift:dword;x,y:integer);
var xn,yn:integer;
begin try 
 if s.mbox_on then begin 
  s.mbox_on:=false;
  event_frame(s);
  exit; 
 end;
 calc_menuframe_pos(s.cur_menu,xn,yn);  
                         
 move_curs(s,shift,x,y);
 
 s.rmxo:=x;
 s.rmyo:=y;
 s.down_shift:=shift;

 //Main interface
 if gui_mouse_dwn(s,shift,x,y) then begin s.ignore_mouseup:=true;exit;end;
           
 if isf(shift,sh_right) then if ((s.cur_menu and (MG_UNITINFO or MG_XFER or MG_BOOM or MG_MINE or MG_REPORT or MG_UNIT_RENAME or MG_CLAN_INFO or MG_CUSTOM_CLRS or MG_DIPLOMACY or MG_COMMENT))<>0) and (not s.debug_placing) then begin
  clear_menu(s);
  s.ignore_mouseup:=true;
  exit;
 end;     
 
 //Game interface  
 case s.state of  
  //Game
  CST_THEGAME:if not md_mainint(s,shift,x,y) then begin   
   if not(not isf(shift,sh_left) and (s.cur_menu<>MG_DEBUG)) then begin
    if s.cur_menu<>MG_NOMENU then begin
     md_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn);
     s.ignore_mouseup:=true;
     exit;
    end else begin
     if md_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn) then begin
      s.ignore_mouseup:=true;
      exit;
     end else begin
      md_game(s,shift,x,y);
     end;
    end;
   end;
   md2_game(s,shift,x,y);
  end;
  //Menus main
  CST_INSGAME,CST_THEMENU:begin md_menu_by_id(s,s.cur_menu,shift,x,y,xn,yn);s.ignore_mouseup:=true;end;
 end;
     
 except stderr(s,'sdimousedwn','mg_msdown');end;
end;
//############################################################################//
begin
end.
//############################################################################//
