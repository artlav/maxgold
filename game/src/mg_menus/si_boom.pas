//############################################################################//
//Deconstruction menu
unit si_boom;
interface
uses mgrecs,mgl_common,mgl_actions,sds_rec,sdirecs,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation                                                           
//############################################################################//
function init(s:psdi_rec):boolean;      
var mn,pg:integer;
begin         
 result:=true;      
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_BOOM;   
 pg:=0;
 
 add_button(mn,pg,089,014,76,22,7,5,po('Boom it'),on_ok_btn,0);
 add_button(mn,pg,089,045,76,22,7,5,po('Cancel'),on_cancel_btn,0);
end;      
//############################################################################//
function ok(s:psdi_rec):boolean; 
var u:ptypunits;
begin 
 result:=true;   
 if sds_is_replay(@s.steps) then exit;
 u:=get_sel_unit(s.the_game);
 if u<>nil then act_dbg_boom_unit(s.the_game,u.num);
 clear_menu(s);
end;    
//############################################################################//
begin      
 add_menu('Deconstruction menu',MG_BOOM,87,42,GRP_SELFDSTR,init,nil,nil,ok,nil,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//  
