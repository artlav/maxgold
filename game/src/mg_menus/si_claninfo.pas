//############################################################################//
//Clan info menu
unit si_claninfo;
interface
uses asys,grph,graph8,sdigrtools,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui,sdi_int_elem,si_nothing;
//############################################################################//
implementation  
//############################################################################//
procedure draw_claninfomnu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var c,dx,dy:integer;
clan:ptypclansdb;
cp:pplrtyp;
begin
 no_reset:=true; //Prevents gold hike in direct landing (si_nothing)

 cp:=get_cur_plr(s.the_game);
 c:=cp.info.clan+1;
 clan:=get_clan(s.the_game,c-1);
                    
 dx:=s.cg.clns[c].xs+10;
 dy:=s.cg.clns[c].ys+10;
 drfrectx8(dst,xn+400-15-s.cg.clns[c].xs-5,yn+15,dx,dy,178);
 putsprt8(dst,s.cg.clns[c],xn+400-15-s.cg.clns[c].xs,yn+15);
 wrtxtcnt8(s.cg,dst,xn+200,yn+18,clannames[c],3);

 drut_clan_info(s,dst,clan,xn+15,yn+40);
end;
//##########p##################################################################//
function init(s:psdi_rec):boolean;
var mn,pg:integer;
begin
 result:=true;
 
 mn:=MG_CLAN_INFO;  
 pg:=0;
 
 add_button(mn,pg,165,380,76,22,7,5,'OK',on_ok_btn,0);
end;
//############################################################################//
begin
 add_menu('Clan info menu',MG_CLAN_INFO,200,211,BCK_SHADE,init,nil,draw_claninfomnu,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//   
