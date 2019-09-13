//############################################################################//
//Set turn menu
unit si_setturn;
interface
uses asys,grph,strval,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation          
//############################################################################//
var
gm_rename_nm:string;
gm_rename_num:integer;  
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin 
 case par of  
  80:gm_rename_nm:=stri(gm_rename_num);
 end;
end;       
//############################################################################//
procedure on_inputbox(s:psdi_rec;ib:pinputbox_type);
begin
 case ib.par of
  0:begin
   gm_rename_num:=vali(gm_rename_nm);
   gm_rename_nm:=stri(gm_rename_num);
  end;
 end;
end;  
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;

 case key of       
  KEY_UP:if isf(shift,sh_shift) then begin
   if gm_rename_num<999-10 then gm_rename_num:=gm_rename_num+10;
  end else begin
   if gm_rename_num<999 then gm_rename_num:=gm_rename_num+1;
  end;
  KEY_DWN:if isf(shift,sh_shift) then begin
   if gm_rename_num>10 then gm_rename_num:=gm_rename_num-10;
  end else begin
   if gm_rename_num>0 then gm_rename_num:=gm_rename_num-1;
  end;
 end;
 on_btn(s,80,0);
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;
 
 mn:=MG_SET_TURN;
 pg:=0;
 
 add_label    (mn,pg,150,037,1,3,po('Set turn'));

 add_inputbox (mn,pg,060,080,170,0,@gm_rename_nm,on_inputbox,0,'');
 add_scrollbox(mn,pg,SCB_HORIZONTAL,060+80 ,109,060+55,109,24,25,1,0,999,false,@gm_rename_num,on_btn,80);

 add_button   (mn,pg,060,180,76,22,7,5,po('Cancel'),on_cancel_btn,0);
 add_button   (mn,pg,165,180,76,22,7,5,'OK',on_ok_btn,0);
end;
//############################################################################//
function ok(s:psdi_rec):boolean;
begin 
 result:=true;
 ////FIXME
 s.the_game.state.turn:=gm_rename_num;
 go_end_turn(s,false);
end;
//############################################################################//
function enter(s:psdi_rec):boolean; 
begin
 result:=true;
 
 gm_rename_num:=s.the_game.state.turn;
 gm_rename_nm:=stri(gm_rename_num);
end;
//############################################################################//
begin
 add_menu('Set turn menu',MG_SET_TURN,150,115,BCK_SHADE,init,nil,nil,ok,nil,enter,nil,nil,keydown,nil,nil,nil,nil);
end.
//############################################################################//
