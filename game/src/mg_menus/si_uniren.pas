//############################################################################//
//Unit rename menu
unit si_uniren;
interface
uses asys,grph,strval,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation          
//############################################################################//
var
gm_rename_name:string;
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
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;

 case key of       
  KEY_R:if isf(shift,sh_alt) then clear_menu(s);
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
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_UNIT_RENAME;
 pg:=0;
 
 add_label    (mn,pg,150,037,1,3,po('Unit Rename'));

 add_inputbox (mn,pg,060,080,170,0,@gm_rename_name,nil,0,'');
 add_textbox  (mn,pg,060,110,040,true,2,@gm_rename_nm,'');
 add_scrollbox(mn,pg,SCB_HORIZONTAL,060+80 ,109,060+55,109,24,25,1,0,999,false,@gm_rename_num,on_btn,80);

 add_button   (mn,pg,060,180,76,22,7,5,po('Cancel'),on_cancel_btn,0);
 add_button   (mn,pg,165,180,76,22,7,5,'OK',on_ok_btn,0);
end;
//############################################################################//
function ok(s:psdi_rec):boolean;
var su:ptypunits;
ud:ptypunitsdb;
begin 
 result:=true;

 su:=get_sel_unit(s.the_game);
 if su=nil then exit;
 
 ud:=get_unitsdb(s.the_game,su.dbn);
 if lrus then begin
  if ud.name_rus<>gm_rename_name then su.name:=gm_rename_name else su.name:='';
 end else begin                                                            
  if ud.name_eng<>gm_rename_name then su.name:=gm_rename_name else su.name:='';
 end;
 su.nm:=gm_rename_num;
 clear_menu(s);
end;
//############################################################################//
function enter(s:psdi_rec):boolean; 
var su:ptypunits;
ud:ptypunitsdb;
cp:pplrtyp;
begin   
 result:=true;
 
 su:=get_sel_unit(s.the_game);
 if su=nil then exit;
 
 cp:=get_cur_plr(s.the_game);
 if su.own=cp.num then begin
  ud:=get_unitsdb(s.the_game,su.dbn);
  if su.name<>'' then gm_rename_name:=su.name else begin
   if lrus then gm_rename_name:=ud.name_rus
           else gm_rename_name:=ud.name_eng;
  end;
  gm_rename_num:=su.nm;
  gm_rename_nm:=stri(gm_rename_num);
 end;
end;    
//############################################################################//
begin      
 add_menu('Unit rename menu',MG_UNIT_RENAME,150,115,BCK_SHADE,init,nil,nil,ok,nil,enter,nil,nil,keydown,nil,nil,nil,nil);
end.
//############################################################################//   
