//############################################################################//
//Diplomacy menu
unit si_diplomat;
interface
uses asys,grph,graph8,sdigrtools,mgrecs,mgl_common,sdirecs,sdicalcs,sdimenu,sdigui;
//############################################################################//
implementation  
//############################################################################//
var   
dipl_menu_cb:array[0..MAX_PLR-1]of array[0..MAX_PLR-1]of pcheckbox_type;
dipl_menu_lab,dipl_menu_reclab:array[0..MAX_PLR-1]of array[0..MAX_PLR-1]of plabel_type; 
//############################################################################//
procedure draw_diplomacy_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,j,n:integer;
cp,pli,plj:pplrtyp;
begin
 cp:=get_cur_plr(s.the_game);
 wrtxtcnt8(s.cg,dst,xn+200,yn+18,po('Select your allies'),3);
 wrtxtcnt8(s.cg,dst,xn+200,yn+38,po('The enemy must do the same to become an friend'),0);
 wrtxtcnt8(s.cg,dst,xn+100,yn+58,po('Your opinion')+':',0);
 wrtxtcnt8(s.cg,dst,xn+300,yn+58,po('Their opinion')+':',0);
                    
 n:=0;
 for i:=0 to get_plr_count(s.the_game)-1 do for j:=0 to get_plr_count(s.the_game)-1 do begin
  if i=j then continue;
  pli:=get_plr(s.the_game,i);
  plj:=get_plr(s.the_game,j);
  if n<>0 then drline8(dst,xn+10,yn+dipl_menu_lab[i][j].y+16,xn+390,yn+dipl_menu_lab[i][j].y+16,maxg_nearest_in_thepal(tcrgb(200,$FF,$00)));
  dipl_menu_cb[i][j].vis:=i=cp.num;
  dipl_menu_lab[i][j].vis:=i=cp.num;
  dipl_menu_reclab[i][j].vis:=i=cp.num; 
  if i=cp.num then begin
   if plj.allies[i] and pli.allies[j] then begin
    dipl_menu_reclab[i][j].txt:=po('Allied');
    dipl_menu_reclab[i][j].fc:=2;
   end else if plj.allies[i] or pli.allies[j] then begin
    dipl_menu_reclab[i][j].txt:=po('Wannabe');
    dipl_menu_reclab[i][j].fc:=4;
   end else begin
    dipl_menu_reclab[i][j].txt:=po('Enemy');
    dipl_menu_reclab[i][j].fc:=1;
   end;
   n:=n+1;
  end;
 end;
end;                                                           
//############################################################################//
function init(s:psdi_rec):boolean;      
var mn,pg,i,j,k:integer;
pli,plj:pplrtyp;
begin         
 result:=true;
 if s.state<>CST_THEGAME then exit;
 
 mn:=MG_DIPLOMACY;   
 pg:=0;
 
 add_button(mn,pg,165,320,100,70,19,20,'OK',on_ok_btn,0);  
 for i:=0 to get_plr_count(s.the_game)-1 do begin
  k:=0;
  //FIXME: Это работать не должно, переписать
  for j:=0 to get_plr_count(s.the_game)-1 do if i<>j then begin
   pli:=get_plr(s.the_game,i);
   plj:=get_plr(s.the_game,j);
   dipl_menu_cb [i][j]:=add_checkbox(mn,pg, 20,70+25*k,16,16,nil,@pli.allies[j],nil,0);
   dipl_menu_lab[i][j]:=add_label   (mn,pg, 45,73+25*k,0,0,plj.info.name);
   dipl_menu_reclab[i][j]:=add_label(mn,pg,300,73+25*k,1,2,po('Enemy'));
   k:=k+1;
  end;
 end;                        
end;                                                            
//############################################################################//
function deinit(s:psdi_rec):boolean;      
var i,j:integer;
begin         
 result:=true; 
            
 for i:=0 to MAX_PLR-1 do for j:=0 to MAX_PLR-1 do begin
  dipl_menu_lab[i][j]:=nil;
  dipl_menu_reclab[i][j]:=nil;
  dipl_menu_cb[i][j]:=nil;
 end;                           
end;  
//############################################################################//
begin      
 add_menu('Diplomacy menu',MG_DIPLOMACY,200,211,BCK_SHADE,init,deinit,draw_diplomacy_menu,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil);
end.
//############################################################################//  
