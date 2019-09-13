//############################################################################//
unit si_changes;
interface
uses asys,grph,graph8,sdigrtools,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui,upd_cli,sds_rec;
//############################################################################//
implementation
//############################################################################//
const
xs=500;
ys=580;
//############################################################################/
procedure draw_changes_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var st:string;
i:integer;
begin
 st:=upd_changes;
 for i:=1 to length(st) do if st[i]=#$0A then st[i]:='&';
 wrtxtbox8(s.cg,dst,xn+5,yn+5+5,xn+5+xs-2*5,yn+5+ys-3*5-50,st,4);
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:dword;
begin
 result:=true;

 mn:=MS_CHANGES;
 pg:=0;
 calcmnuinfo(s,mn);

 add_button(mn,pg,5,ys-5-50,xs-2*5,50,0,5,po('Back'),on_cancel_btn,0);
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true;
 add_step(@s.steps,sts_check_updlog);
end;
//############################################################################//
function cancel(s:psdi_rec):boolean;
begin
 result:=true;
 enter_menu(s,MS_UPDATE);
end;
//############################################################################//
begin
 add_menu('Changelog menu',MS_CHANGES,xs div 2,ys div 2,BCK_SHADE,init,nil,draw_changes_menu,nil,cancel,enter,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//

