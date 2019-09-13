//############################################################################//
unit sdiovermind;
interface
uses asys,grph,strval,mgrecs,mgl_common,sdirecs,sdicalcs,sdigrinit,sdiauxi;
//############################################################################// 
procedure so_reposition_map_pixels(s:psdi_rec;nx,ny:double);     
function so_in_game_navigation_mode(s:psdi_rec):boolean;
function so_range_by_zoom(s:psdi_rec;z:double):double;
function so_zoom_by_range(s:psdi_rec;z:double):double;  
procedure so_set_zoom(s:psdi_rec;z:double;xp,yp:integer); 
procedure so_screen_resize(s:psdi_rec);stdcall;
//############################################################################//
implementation
//############################################################################//
function so_range_by_zoom(s:psdi_rec;z:double):double;begin result:=(z-1)/(s.mainmap.maxzoom-1);end;
function so_zoom_by_range(s:psdi_rec;z:double):double;begin result:=1+z*(s.mainmap.maxzoom-1);end;
//############################################################################//
//Are we in a mode that expects or allows game view navigation?
function so_in_game_navigation_mode(s:psdi_rec):boolean;begin result:=(s.state=CST_THEGAME)and((s.cur_menu=MG_NOMENU)or((s.cur_menu=MG_DEBUG)and s.debug_placing));end;
//############################################################################//
procedure so_reposition_map_pixels(s:psdi_rec;nx,ny:double);
begin try
 s.clinfo.sopt.sx:=round(nx);
 s.clinfo.sopt.sy:=round(ny);

 calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);   
 s.mainmap.mapoxo:=s.clinfo.sopt.sx;
 s.mainmap.mapoyo:=s.clinfo.sopt.sy;
 
 event_frame(s);  
 except stderr(s,'sdiovermind','so_reposition_map_pixels, ('+stre(nx)+','+stre(ny)+')');end;
end;
//############################################################################//
//Set zoom, scaled to 0..1 range, centering at xp,yp
procedure so_set_zoom(s:psdi_rec;z:double;xp,yp:integer);
var z0:double;
x,y:double;
begin try
 if z<0 then z:=0;if z>1 then z:=1;
 event_frame(s);

 z0:=s.clinfo.sopt.zoom;
 s.clinfo.sopt.zoom:=so_zoom_by_range(s,z);
 calczoom(s,@s.mainmap,s.clinfo.sopt.zoom);
 if(xp<>-1)and(yp<>-1)then begin
  x:=(s.mainmap.mapl+xp)*z0;
  y:=(s.mainmap.mapt+yp)*z0;
  if s.center_zoom then so_reposition_map_pixels(s,x+(s.clinfo.sopt.sx-x)*(s.clinfo.sopt.zoom/z0),y+(s.clinfo.sopt.sy-y)*(s.clinfo.sopt.zoom/z0));
 end;
 if not s.center_zoom then calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);
 s.mainmap.oldzoom:=s.clinfo.sopt.zoom;

 except stderr(s,'sdiovermind','so_set_zoom, ('+stre(z)+','+stri(xp)+','+stri(yp)+')');end;
end;
//############################################################################//
procedure so_screen_resize(s:psdi_rec);stdcall;
var z:double;
begin try
 tolog('SDI','Resize ('+stri(scrx)+'x'+stri(scry)+')...');
 if s=nil then exit;

 z:=1;
 if s.the_game<>nil then if s.state=CST_THEGAME then begin
  z:=(s.clinfo.sopt.zoom-1)/(s.mainmap.maxzoom-1);  //Old zoom
  s.mainmap.maxzoom:=max_zoom(s);
 end;

 resize_planes(s,scrx,scry);
 event_map_reposition(s);
 event_frame(s);  

 if s.the_game<>nil then if s.state=CST_THEGAME then begin
  //If the window got resized up or for minimzp update
  so_set_zoom(s,z,-1,-1);
  calcmbrd(s,@s.mainmap,s.clinfo.sopt.zoom,s.clinfo.sopt.sx,s.clinfo.sopt.sy);
 end;

 s.pending_resize:=true;

 tolog('SDI','Resize ok (maxzoom='+stre(s.mainmap.maxzoom)+').');
 except stderr(s,'sdiovermind','so_screen_resize, ('+stri(scrx)+'x'+stri(scry)+')');end;
end;
//############################################################################//
begin
end.
//############################################################################//
