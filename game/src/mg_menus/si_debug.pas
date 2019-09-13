//############################################################################//
//Debug menu
unit si_debug;
interface
uses asys,maths,grph,graph8,sdigrtools,mgrecs,mgl_common,mgl_rmnu,mgl_actions,sds_rec,sdirecs,sdiauxi,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation
//############################################################################//
var dbg_off:integer;
//############################################################################//
procedure draw_debug_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
const cols=3;rows=2;
var i,j,n:integer;
spr:ptypspr;
ud:ptypunitsdb;
edb:ptypeunitsdb;
begin     
 if sds_is_replay(@s.steps) then begin
  clear_menu(s);
  exit;
 end;
 if s.debug_placing then exit;
 
 putspr8(dst,s.cg.grap[GRP_UNITMEN],xn,yn);
 
 for i:=0 to cols-1 do for j:=0 to rows-1 do begin
  n:=dbg_off*cols*rows+i+j*cols;
  if n>=get_unitsdb_count(s.the_game) then continue;  
  ud:=get_unitsdb(s.the_game,n);
  if ud=nil then continue;
  edb:=get_edb(s,ud.typ);
  if edb=nil then continue;
   
  if lrus then wrtxt8(s.cg,dst,xn+6+i*138,yn+138+j*160,edb.name_rus+' '+type_mk(s.the_game,n),17)
          else wrtxt8(s.cg,dst,xn+6+i*138,yn+138+j*160,edb.name_eng+' '+type_mk(s.the_game,n),17);
  if edb.video.used then begin
   putmov8(dst,@edb.video,xn+6+i*136,yn+6+j*160,(round(s.gct*1000)div edb.video.dtms)mod edb.video.frmc)
  end else if edb.spr_base.ex then begin
   spr:=@edb.spr_base.sprc[0];
   putspr8(dst,@edb.spr_base.sprc[0],xn+6+i*136+XCX-spr.cx,yn+6+j*160+XCX-spr.cy);
  end;

 end;
end;
//############################################################################//
function mousedown(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
const cols=3; rows=2;
var i,j,uidx:integer;
begin
 result:=true;

 if s.debug_placing then if isf(shift,sh_left) or isf(shift,sh_right) then act_dbg_place_unit(s.the_game,s.cur_map_x,s.cur_map_y,s.debug_placed_unit,isf(shift,sh_shift),isf(shift,sh_right));
 if s.debug_placing then exit;

 if inrect(x,y,xn+321,yn+315,xn+344,yn+338) then if (dbg_off+1)*cols*rows<get_unitsdb_count(s.the_game) then dbg_off:=dbg_off+1;
 if inrect(x,y,xn+353,yn+315,xn+376,yn+338) then if dbg_off>0 then dbg_off:=dbg_off-1;
 if inrect(x,y,xn+385,yn+315,xn+408,yn+338) then clear_menu(s);

 for i:=0 to cols-1 do for j:=0 to rows-1 do if inrect(x,y,xn+6+i*136,yn+6+j*160,xn+6+i*136+127,yn+6+j*160+143) then begin
  uidx:=dbg_off*cols*rows+i+j*cols;
  if uidx<length(s.eunitsdb) then begin
   s.debug_placing:=true;
   s.debug_placed_unit:=uidx;
   event_frame(s);
   event_map_reposition(s);
   break;
  end;
 end;
end;
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;

 case key of
  KEY_Z:if isf(shift,sh_alt) then begin
   if s.debug_placing then s.debug_placing:=false
                      else set_game_menu(s.the_game,MG_NOMENU);
  end;
 end;
end;    
//############################################################################//
function mousewheel(s:psdi_rec;shift:dword;dir,nul,xn,yn:integer):boolean;
begin
 result:=true;

 if dir=-1 then if not s.debug_placing then if dbg_off>0 then dbg_off:=dbg_off-1;
 if dir= 1 then if not s.debug_placing then if (dbg_off+1)*3*2<get_unitsdb_count(s.the_game) then dbg_off:=dbg_off+1;
end;
//############################################################################//
begin      
 add_menu('Debug menu',MG_DEBUG,206,171,BCK_NONE,nil,nil,draw_debug_menu,nil,nil,nil,nil,nil,keydown,mousedown,nil,nil,mousewheel);
end.
//############################################################################//  
