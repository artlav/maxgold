//############################################################################//
//Rules menu
unit si_rules;
interface
uses asys,maths,grph,graph8,sdigrtools,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui,sds_rec;
//############################################################################//
implementation
//############################################################################//
const
uni_ys=30;
xs=420;
ys=400;
//############################################################################//
var menu_active:boolean=false;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin 
 case par of
  10:calcmnuinfo(s,MG_LOADSAVE);
  461:calcmnuinfo(s,MG_LOADSAVE);
 end;
end;
//############################################################################/
procedure draw_rules_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,k,yoff:integer;
r:prulestyp;
begin
 yoff:=ys-80;
 if not menu_active then begin
  if s.unisets_loaded then begin
   for i:=0 to length(s.unitsets)-1 do add_label(MS_RULES,0,105,60+i*uni_ys,LB_CENTER,0,s.unitsets[i].name);
   menu_active:=true;
  end;
 end;
 r:=@s.newgame.rules;
 drline8(dst,xn+5       ,yn+55  ,xn+xs div 2-5,yn+55    ,5);
 drline8(dst,xn+5       ,yn+30  ,xn+xs-5      ,yn+30    ,5);
 drline8(dst,xn+5       ,yn+yoff,xn+xs-5      ,yn+yoff  ,5);
 drline8(dst,xn+xs div 2,yn+35  ,xn+xs div 2  ,yn+yoff-5,5);
 
 k:=-1;
 for i:=0 to length(s.unitsets)-1 do if s.unitsets[i].name=r.uniset then begin
  k:=i;
  break;
 end;
 if k<>-1 then drrectx8(dst,xn+5-1,yn+060+k*uni_ys-(uni_ys-16) div 2,200,uni_ys-2,255);
 
 if(k>=0)and(k<length(s.unitsets))then begin
  if lrus then wrtxtxbox8(s.cg,dst,xn+5,yn+yoff+5,xs-10,ys-yoff-10,s.unitsets[k].descr_rus,4)
          else wrtxtxbox8(s.cg,dst,xn+5,yn+yoff+5,xs-10,ys-yoff-10,s.unitsets[k].descr_eng,4);
 end;
end;
//############################################################################//
function mousedwn(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i:integer;
r:prulestyp;
begin
 result:=true;
 r:=@s.newgame.rules;
 for i:=0 to length(s.unitsets)-1 do if inrects(x,y,xn+5-1,yn+60+i*uni_ys-(uni_ys-16) div 2,200,uni_ys-2)then begin
  r.uniset:=s.unitsets[i].name;
  add_step(@s.steps,sts_save_def_rules);
  break;
 end;
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;

 mn:=MS_RULES; 
 pg:=0;
 calcmnuinfo(s,mn);

 //Title
 add_label(mn,pg,210,013,1,2,po('Unisets'));
 add_button(mn,pg,220,40,190,50,0,5,po('Back'),on_cancel_btn,0);

 //Units Set setup
 add_label(mn,pg,105,040,1,2,po('Uniset'));
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true;
 calcmnuinfo(s,MS_MULTIPLAYER);
end;
//############################################################################//
function cancel(s:psdi_rec):boolean;
begin 
 result:=true;
 enter_menu(s,MS_MULTIPLAYER);
end;
//############################################################################//
begin
 add_menu('Rules menu',MS_RULES,xs div 2,ys div 2,BCK_SHADE,init,nil,draw_rules_menu,nil,cancel,enter,nil,nil,nil,mousedwn,nil,nil,nil);
end.
//############################################################################//

