//############################################################################//
unit si_about;
interface
uses asys,grph,sdigrtools,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation
//############################################################################//
const
xs=500;
ys=250;
//############################################################################/
procedure draw_about_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var st:string;
begin
 if lrus then begin
  st:='M.A.X.Gold&Римейк игры 1996 года от Interplay.&&Большая часть графики заимствована из оригинала.&Фоновые изображения от Оливера (khesm).&&';
  st:=st+'Программирование и алгоритмы:&Артем Литвинович (Artlav)&Помощь от Алексея Малышко (Hruks)&&';
  st:=st+'Игровая логика дорабатывалась всем Российским Клубом игроков M.A.X.';
 end else begin
  st:='M.A.X.Gold&Remake of a 1996-vintage game by Interplay.&&Most of the media is borrowed from the original.&Backgrounds by Oliver (khesm).&&';
  st:=st+'Programming and algorithms:&Artem Litvinovich (Artlav)&With help by Alexey Malyshko (Hruks)&&';
  st:=st+'Game logic designed and improved by Russian M.A.X. Players Club';
 end;

 wrtxtbox8(s.cg,dst,xn+5,yn+5+5,xn+5+xs-2*5,yn+5+ys-3*5,st,4);
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;

 mn:=MS_ABOUT;
 pg:=0;
 calcmnuinfo(s,mn);

 add_button(mn,pg,5,ys-5-50,xs-2*5,50,0,5,po('Back'),on_cancel_btn,0);
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true;
end;
//############################################################################//
function cancel(s:psdi_rec):boolean;  
begin 
 result:=true;
 enter_menu(s,MS_MAINMENU);
end;
//############################################################################//
begin
 add_menu('About menu',MS_ABOUT,xs div 2,ys div 2,BCK_SHADE,init,nil,draw_about_menu,nil,cancel,enter,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//

