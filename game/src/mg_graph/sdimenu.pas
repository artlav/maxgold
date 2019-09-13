//############################################################################//
unit sdimenu;
interface   
uses asys,grph,sdirecs,graph8,sdigrtools;
//############################################################################//       
type
init_menu_proc=function(s:psdi_rec):boolean;
draw_menu_proc=procedure(s:psdi_rec;dst:ptypspr;xn,yn:integer);
ok_menu_proc=function(s:psdi_rec):boolean;
enter_menu_proc=function(s:psdi_rec):boolean;
clear_menu_proc=function(s:psdi_rec):boolean;
calc_menu_proc=function(s:psdi_rec;par:integer):boolean;  
keydown_menu_proc=function(s:psdi_rec;key,shift:dword):boolean;
mouse_menu_proc=function(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
callback_menu_proc=procedure(s:psdi_rec);
menu_rec=record
 name:string;
 id:dword;
 xn,yn:integer;                  //Half-sizes
 bck:integer;                    //Background
 init_proc:init_menu_proc;
 deinit_proc:init_menu_proc;
 draw_proc:draw_menu_proc;
 enter_proc:enter_menu_proc;
 clear_proc:clear_menu_proc;
 ok_proc:ok_menu_proc;
 cancel_proc:ok_menu_proc;
 calc_proc:calc_menu_proc;
 keydown_proc:keydown_menu_proc;
 mousedown_proc:mouse_menu_proc;
 mouseup_proc:mouse_menu_proc;
 mousemove_proc:mouse_menu_proc;
 mousewheel_proc:mouse_menu_proc;
end;  
//############################################################################//
function add_menu(
 name:string;id:dword;xn,yn,bck:integer;
 init_proc:init_menu_proc;     
 deinit_proc:init_menu_proc;
 draw_proc:draw_menu_proc;
 ok_proc:ok_menu_proc;
 cancel_proc:ok_menu_proc;
 enter_proc:enter_menu_proc;
 clear_proc:clear_menu_proc;
 calc_proc:calc_menu_proc;
 keydown_proc:keydown_menu_proc;
 mousedown_proc:mouse_menu_proc;
 mouseup_proc:mouse_menu_proc;
 mousemove_proc:mouse_menu_proc;
 mousewheel_proc:mouse_menu_proc
):integer;
//############################################################################// 
procedure calc_menuframe_pos(id:dword;out xn,yn:integer);
procedure menu_all_clear(s:psdi_rec);   
procedure menu_all_init(s:psdi_rec); 
procedure menu_all_deinit(s:psdi_rec);

function enter_menu_by_id(s:psdi_rec;id:dword):boolean;
function cancel_menu_by_id(s:psdi_rec;id:dword):boolean;
function ok_menu_by_id(s:psdi_rec;id:dword):boolean;
function calc_menu_by_id(s:psdi_rec;id:dword):boolean;
procedure keydown_menu_by_id(s:psdi_rec;id:dword;key,shift:dword);
procedure mm_menu_by_id(s:psdi_rec;id:dword;shift:dword;x,y,xn,yn:integer);
function md_menu_by_id(s:psdi_rec;id:dword;shift:dword;x,y,xn,yn:integer):boolean;
procedure mu_menu_by_id(s:psdi_rec;id:dword;shift:dword;x,y,xn,yn:integer);
function mw_menu_by_id(s:psdi_rec;id:dword;shift:dword;dir,xn,yn:integer):boolean;
function draw_menu_by_id(s:psdi_rec;id:dword;dst:ptypspr;xn,yn:integer):boolean;
//############################################################################//
var
menu_list:array of menu_rec=nil;
//############################################################################//  
implementation
//############################################################################//
function match_id(a,b:dword):boolean;
begin
 result:=a=b;//((a and b)<>0)or((a=0)and(b=0));
end;
//############################################################################//
procedure calc_menuframe_pos(id:dword;out xn,yn:integer);
var i:integer;
begin
 xn:=0;
 yn:=0;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then begin
  if menu_list[i].xn<>0 then xn:=(scrx div 2)-menu_list[i].xn;
  if menu_list[i].yn<>0 then yn:=(scry div 2)-menu_list[i].yn;
  if menu_list[i].yn<0 then yn:=scry-(-menu_list[i].yn);
  exit;
 end; 
end;   
//############################################################################//   
procedure menu_all_clear(s:psdi_rec);
var i:integer;
begin
 for i:=0 to length(menu_list)-1 do if assigned(menu_list[i].clear_proc) then menu_list[i].clear_proc(s);
end;        
//############################################################################//   
procedure menu_all_init(s:psdi_rec);
var i:integer;
begin
 for i:=0 to length(menu_list)-1 do if assigned(menu_list[i].init_proc) then menu_list[i].init_proc(s);
end;                    
//############################################################################//   
procedure menu_all_deinit(s:psdi_rec);
var i:integer;
begin
 for i:=0 to length(menu_list)-1 do if assigned(menu_list[i].deinit_proc) then menu_list[i].deinit_proc(s);
end;
//############################################################################//
function enter_menu_by_id(s:psdi_rec;id:dword):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then if assigned(menu_list[i].enter_proc) then begin
  menu_list[i].enter_proc(s);
  result:=true;
  exit;
 end;
end;   
//############################################################################//
function cancel_menu_by_id(s:psdi_rec;id:dword):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then if assigned(menu_list[i].cancel_proc) then begin
  menu_list[i].cancel_proc(s);
  result:=true;
  exit;
 end;  
end;   
//############################################################################//
function ok_menu_by_id(s:psdi_rec;id:dword):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then if assigned(menu_list[i].ok_proc) then begin
  menu_list[i].ok_proc(s);
  result:=true;
  exit;
 end;  
end;    
//############################################################################//
function calc_menu_by_id(s:psdi_rec;id:dword):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then if assigned(menu_list[i].calc_proc) then begin
  menu_list[i].calc_proc(s,0);
  result:=true;
  exit;
 end;  
end;    
//############################################################################//
procedure keydown_menu_by_id(s:psdi_rec;id:dword;key,shift:dword);
var i:integer;
begin      
 if s.hide_interface then exit;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then begin
  if assigned(menu_list[i].keydown_proc) then begin menu_list[i].keydown_proc(s,key,shift);exit;end;
 end;
end;
//############################################################################//
procedure mm_menu_by_id(s:psdi_rec;id:dword;shift:dword;x,y,xn,yn:integer);
var i:integer;
begin         
 if s.hide_interface then exit;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then begin
  if assigned(menu_list[i].mousemove_proc) then begin menu_list[i].mousemove_proc(s,shift,x,y,xn,yn);exit;end;
 end;
end;
//############################################################################//
function md_menu_by_id(s:psdi_rec;id:dword;shift:dword;x,y,xn,yn:integer):boolean;
var i:integer;
begin
 result:=false;  
 if s.hide_interface then exit;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then begin
  if assigned(menu_list[i].mousedown_proc) then begin result:=menu_list[i].mousedown_proc(s,shift,x,y,xn,yn);exit;end;
 end;
end;  
//############################################################################//
procedure mu_menu_by_id(s:psdi_rec;id:dword;shift:dword;x,y,xn,yn:integer);
var i:integer;
begin
 if s.hide_interface then exit;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then begin
  if assigned(menu_list[i].mouseup_proc) then menu_list[i].mouseup_proc(s,shift,x,y,xn,yn);
 end;
end; 
//############################################################################//
function mw_menu_by_id(s:psdi_rec;id:dword;shift:dword;dir,xn,yn:integer):boolean;
var i:integer;
begin
 result:=false; 
 if s.hide_interface then exit;
 for i:=0 to length(menu_list)-1 do if match_id(menu_list[i].id,id) then begin
  if assigned(menu_list[i].mousewheel_proc) then begin result:=menu_list[i].mousewheel_proc(s,shift,dir,0,xn,yn);exit;end;
 end;
end;
//############################################################################//
function draw_menu_by_id(s:psdi_rec;id:dword;dst:ptypspr;xn,yn:integer):boolean;
var i:integer;
one_back:boolean;
begin
 result:=false;  
 if s.hide_interface then exit;
 one_back:=false;
 for i:=0 to length(menu_list)-1 do begin
  if match_id(menu_list[i].id,id) then begin
   //Background
   if not one_back then begin
    if menu_list[i].bck>BCK_NONE then begin
     if s.frame_map_ev then putspr8(dst,s.cg.grap[menu_list[i].bck],xn,yn);
    end else if menu_list[i].bck=BCK_SHADE then if s.frame_map_ev then begin
     tran_rect8(s.cg,dst,xn,yn,2*(scrx div 2-xn),2*(scry div 2-yn),0);
    end;
    one_back:=true;
   end;
   //Menu's draw call
   if assigned(menu_list[i].draw_proc) then begin
    menu_list[i].draw_proc(s,dst,xn,yn);
    if id<>0 then result:=true;
   end;
  end;
 end;
end; 
//############################################################################//
function add_menu(
 name:string;id:dword;xn,yn,bck:integer;
 init_proc:init_menu_proc;
 deinit_proc:init_menu_proc;
 draw_proc:draw_menu_proc;
 ok_proc:ok_menu_proc;
 cancel_proc:ok_menu_proc;
 enter_proc:enter_menu_proc;    
 clear_proc:clear_menu_proc;
 calc_proc:calc_menu_proc;
 keydown_proc:keydown_menu_proc;
 mousedown_proc:mouse_menu_proc;
 mouseup_proc:mouse_menu_proc;
 mousemove_proc:mouse_menu_proc;
 mousewheel_proc:mouse_menu_proc
):integer;
var i:integer;
begin
 i:=length(menu_list);
 setlength(menu_list,i+1);
 menu_list[i].name:=name;
 menu_list[i].id:=id;
 menu_list[i].xn:=xn;
 menu_list[i].yn:=yn;
 menu_list[i].bck:=bck;
 menu_list[i].init_proc:=init_proc;
 menu_list[i].deinit_proc:=deinit_proc;
 menu_list[i].draw_proc:=draw_proc;
 menu_list[i].ok_proc:=ok_proc;
 menu_list[i].cancel_proc:=cancel_proc;
 menu_list[i].enter_proc:=enter_proc;
 menu_list[i].clear_proc:=clear_proc;
 menu_list[i].calc_proc:=calc_proc;
 menu_list[i].keydown_proc:=keydown_proc;
 menu_list[i].mousedown_proc:=mousedown_proc;
 menu_list[i].mouseup_proc:=mouseup_proc;
 menu_list[i].mousemove_proc:=mousemove_proc;
 menu_list[i].mousewheel_proc:=mousewheel_proc;
 result:=i;
end;
//############################################################################//
begin
end.
//############################################################################//
