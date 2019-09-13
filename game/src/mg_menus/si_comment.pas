//############################################################################//
//Comments menu
unit si_comment;
interface
uses mgrecs,mgl_common,mgl_actions,sdirecs,sdicalcs,sdimenu,sdigui,sds_rec;
//############################################################################//
implementation
//############################################################################//
var global_comment:boolean=false;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_COMMENT;
 pg:=0;
 
 add_button   (mn,pg,060,180,76,22,7,5,po('Cancel'),on_cancel_btn,0);
 add_button   (mn,pg,165,180,76,22,7,5,'OK',on_ok_btn,0);
 
 add_label    (mn,pg,150,037,1,3,po('Title'));
 add_inputbox (mn,pg,060,080,170,0,@s.gm_comment_text,nil,0,'');
 
 add_label    (mn,pg,080,113,0,0,po('Global'));
 add_checkbox (mn,pg,060,110,16,16,nil,@global_comment,nil);
end;      
//############################################################################//
function ok(s:psdi_rec):boolean;  
begin 
 result:=true;
 act_add_comment(s.the_game,global_comment,s.gm_comment_x,s.gm_comment_y,s.gm_comment_text);
 add_step(@s.steps,sts_fetch_plrcomm);
 global_comment:=false;
 clear_menu(s);
end;
//############################################################################//
begin
 add_menu('Comments menu',MG_COMMENT,150,115,BCK_SHADE,init,nil,nil,ok,nil,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//
