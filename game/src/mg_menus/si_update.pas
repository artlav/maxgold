//############################################################################//
//Update menu
unit si_update;
interface
uses asys,strval,grph,graph8,sdigrtools,mgrecs,mgl_common,sdirecs,sdiauxi,sdicalcs,sdimenu,sdigui,upd_cli,sds_rec;
//############################################################################//
implementation
//############################################################################//
procedure draw_update_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var c:integer;
begin     
 wrtxt8(s.cg,dst,xn+20,yn+055,po('Current version')+': '+stri(sdi_progvernum),0);

 
 if s.steps.last_step_read<>s.steps.last_step_write then begin
  wrtxt8(s.cg,dst,xn+20,yn+070,po('Online version')+': '+po('Checking')+'...',5);
 end else begin    
  if upd_online_version=0 then begin
   wrtxt8(s.cg,dst,xn+20,yn+070,po('Online version')+': '+po('Cannot reach server'),2);
  end else begin  
   if upd_online_version>sdi_progvernum then c:=3 else c:=0;
   wrtxt8(s.cg,dst,xn+20,yn+070,po('Online version')+': '+stri(upd_online_version),c);
  end;
 end;
end;     
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin
 case par of
  1:enter_menu(s,MS_CHANGES);
 end;
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:dword;
begin
 result:=true;
 
 mn:=MS_UPDATE;
 pg:=0;
 
 add_label (mn,pg,150,20,1,3,po('Update')+' M.A.X.G.'); 
 add_button(mn,pg,155,125,140,100,19,20,po('Update'),on_ok_btn,0); 
 add_button(mn,pg,005,125,140,100,19,20,po('Log'),on_btn,1);
 add_button(mn,pg,005,230,290,100,19,20,po('Cancel'),on_cancel_btn,0);
end;
//############################################################################//
function ok(s:psdi_rec):boolean; 
begin 
 result:=true;
 if upd_online_version>sdi_progvernum then add_step(@s.steps,sts_get_updates) else mbox(s,po('Cannot update - Nothing to update'),po('Update'));
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin   
 result:=true;
 add_step(@s.steps,sts_check_updates);
end;      
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;
 case key of                                                      
  key_stroke:upd_make_version;
 end;
end; 
//############################################################################//
begin
 add_menu('Update menu',MS_UPDATE,150,168,BCK_SHADE,init,nil,draw_update_menu,ok,nil,enter,nil,nil,keydown,nil,nil,nil,nil);
end.
//############################################################################// 
