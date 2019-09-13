//############################################################################//
//Setup menus
unit si_setup;
interface
uses asys,maths,grph,graph8,sdigrtools,md5
,mgrecs,mgl_common,mgl_buy,mgl_land
,sdirecs,sdiauxi,sdicalcs,sdisound,sdimenu,sdigui,sdiinit,sdi_int_elem,si_buyupg;
//############################################################################//
implementation
//############################################################################//
const
clan_xs=400;
clan_ys=400;
clan_sz=86;
//############################################################################//
var
plr_name,plr_pass:string;     //Player name and password in setup
plr_tb:ptextbox_type;
//############################################################################//
procedure on_box(s:psdi_rec;ib:pinputbox_type);
begin 
 //if ib.par=2 then 
end;
//############################################################################//
procedure clan_pos(out x,y:integer;xn,yn,i,j:integer);
begin
 x:=xn+10+(clan_sz+11)*i;
 y:=yn+42+(clan_sz+11+7)*j;
end;
//############################################################################//
procedure draw_clansel_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var clan:ptypclansdb;
cur_clan,i,j,x,y,xsz,ysz:integer;
sel:boolean;
cp:pplrtyp;
begin try
 if s.the_game=nil then exit;
 cp:=get_cur_plr(s.the_game);
 if cp=nil then exit;

 if plr_tb=nil then exit;
 plr_tb.vr^:=cp.info.name;

 if not s.frame_map_ev then exit;

 cur_clan:=plr_begin.clan;
 clan:=get_clan(s.the_game,cur_clan); 
 if clan=nil then exit;

 for i:=0 to 3 do for j:=0 to 1 do begin
  clan_pos(x,y,xn,yn,i,j);
  sel:=cur_clan=(i+4*j);
  tran_rect8(s.cg,dst,x-1,y-1,clan_sz+2,clan_sz+2,ord(sel));
  putsprt8(dst,s.cg.clns[i+1+4*j],x+clan_sz div 2-s.cg.clns[i+1+4*j].xs div 2,y+clan_sz div 2-s.cg.clns[i+1+4*j].ys div 2);
  wrtxtcnt8(s.cg,dst,x+clan_sz div 2,y+clan_sz+5,clannames[i+1+4*j],4-ord(sel));
 end;

 xsz:=clan_xs-20;
 ysz:=4+11*10;
 x:=xn+(clan_xs-xsz) div 2;
 y:=yn+clan_ys-ysz-text_box_hei-5-5;
 tran_rect8(s.cg,dst,x-1,y-1,xsz+2,ysz+2,0);
 drut_clan_info(s,dst,clan,x+2,y+2);

 except stderr(s,'SDIDraws','draw_clansel_menu');end;
end;
//############################################################################/
procedure draw_playersetup_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,x,y:integer;
begin
 if s.frame_map_ev then tran_rect8(s.cg,dst,xn+12,yn+177,301,231,0);
 calcmnuinfo(s,MS_PLAYERSETUP);

 drfrect8(dst,xn+14,yn+310-195,xn+204,yn+330-195,plr_begin.color8);
 for y:=0 to 15 do for x:=0 to 15 do begin
  i:=x+y*16;
  if((i>=0)and(i<=6))or((i>=32)and(i<64))or(i>=160)then drfrect8(dst,xn+30+12+x*15,yn+40+177+y*10,xn+30+12+x*15+15,yn+40+177+y*10+10,i)
                                                   else drfrect8(dst,xn+30+12+x*15,yn+40+177+y*10,xn+30+12+x*15+15,yn+40+177+y*10+10,0);
 end;
end;
//############################################################################//
function init_clan(s:psdi_rec):boolean;     
var mn,pg:integer;   
begin      
 result:=true;   
 mn:=MS_CLANSELECT;
 pg:=0;

 add_label  (mn,pg,clan_xs div 2,13,LB_BIG_CENTER,0,po('Select Clan'));

         add_label  (mn,pg,          150,clan_ys-text_box_hei-5+6,LB_RIGHT,0,po('Player'));
 plr_tb:=add_textbox(mn,pg,          155,clan_ys-text_box_hei-5  ,150,true,2,nil,'player_name');
         add_button (mn,pg,clan_xs-70-10,clan_ys-text_box_hei-5  , 70,text_box_hei,0,5,po('Accept'),on_ok_btn,0);
         add_button (mn,pg,           10,clan_ys-text_box_hei-5  , 70,text_box_hei,0,5,po('Back'),on_cancel_btn,0);
end;
//############################################################################//
function init_setup(s:psdi_rec):boolean;      
var mn,pg:integer;
begin    
 result:=true;  
 
 mn:=MS_PLAYERSETUP;  
 pg:=0;
 
 calcmnuinfo(s,MS_PLAYERSETUP);

 add_label    (mn,pg,200,013,LB_BIG_CENTER,0,po('Player setup'));
                                                         
 add_label    (mn,pg,020,55+6,0,0,po('Name'));
 //add_textbox  (mn,pg,110,035,170,true,2,@plr_name,'');  
 add_inputbox (mn,pg,100,55,170,0,@plr_name,on_box,3,'');
 
 add_label    (mn,pg,110,105,1,0,po('Player Color'));
 add_label    (mn,pg,150+12,20+177,1,0,po('Select Player Color'));

 add_label    (mn,pg,020,77+6,0,0,po('Password'));
 add_inputbox (mn,pg,100,77,170,0,@plr_pass,on_box,2,'');

 add_button   (mn,pg,315,355,76,22,0,5,'OK',on_ok_btn,0);
 add_button   (mn,pg,315,380,76,22,0,5,po('Cancel'),on_cancel_btn,0);
end;            
//############################################################################//
function enter_setup(s:psdi_rec):boolean;
var n:integer;
rul:prulestyp;
begin
 result:=true;
 rul:=get_rules(s.the_game);

 reset_buy_menu(s.the_game,@buy_menu,rul);
 calcmnuinfo(s,MS_PLAYERSETUP);
 n:=get_cur_plr_id(s.the_game);
 plr_name:=s.newgame.plr_names[n];   
 plr_pass:='';  

 setlength(plr_begin.init_unupd,get_unitsdb_count(s.the_game));
 plr_begin.bgncnt:=0;
 plr_begin.clan:=random(8);
 plr_begin.stgold:=rul.goldset;
 plr_begin.color8:=n+1;         
 plr_begin.color:=thepal[plr_begin.color8];
 //plr_begin.sopt.sx:=mapx*XHCX;
 //plr_begin.sopt.sy:=mapy*XHCX;
 //plr_begin.sopt.zoom:=mainmap.maxzoom;   
 plr_begin.lndx:=-1;
 plr_begin.lndy:=-1;
 plr_begin.name:=plr_name;
 plr_begin.passhash:=str_md5_hash(md5_str(plr_pass));
end;   
//############################################################################//
function clear_setup(s:psdi_rec):boolean;
begin   
 result:=true; 
 plr_pass:='';
 plr_name:='';
end;
//############################################################################//
function ok_setup(s:psdi_rec):boolean;      
var cl:crgb;
i,n:integer;
begin 
 result:=true;  
 n:=get_cur_plr_id(s.the_game);

 enter_menu(s,MS_CLANSELECT); 
 
 cl:=plr_begin.color;
 plr_begin.name:=plr_name;
 plr_begin.passhash:=str_md5_hash(md5_str(plr_pass));
 plr_pass:='';
    
 for i:=0 to 255 do s.colors.palpx[n][i]:=i;
 for i:=32 to 39 do s.colors.palpx[n][i]:=maxg_nearest_in_thepal(tcrgb(round(cl[2]*((40-i)/8*200)/255),
                                                                       round(cl[1]*((40-i)/8*200)/255),
                                                                       round(cl[0]*((40-i)/8*200)/255)));
end;
//############################################################################//
function cancel_setup(s:psdi_rec):boolean;      
begin 
 result:=true;
 clear_menu(s);
 haltgame(s);
end; 
//############################################################################//
function cancel_clan(s:psdi_rec):boolean;      
begin 
 result:=true;
 enter_menu(s,MS_PLAYERSETUP); 
end;
//############################################################################//
procedure set_clan(s:psdi_rec;cl:integer);
begin 
 plr_begin.clan:=cl;
 plr_set_default_begins(plr_begin,get_rules(s.the_game)^);
end;
//############################################################################//
function ok_clan(s:psdi_rec):boolean;      
var rul:prulestyp;
begin
 result:=true;
 rul:=get_rules(s.the_game);

 set_clan(s,plr_begin.clan);  
 if (rul.goldset=0)or rul.direct_land then begin
  begin_player_landing(s);
 end else enter_menu(s,MS_BUYINIT); 
end;
//############################################################################//
function keydown_setup(s:psdi_rec;key,shift:dword):boolean;
var i,f:integer;
begin
 result:=true;
 
 i:=plr_begin.color8;
 f:=i;
 case key of
  key_1..key_7:i:=key-key_1;
  KEY_LEFT: if i>0 then if i<7 then i:=i-1 else i:=6;
  KEY_RIGHT:if i<6 then i:=i+1;
 end;
 if i<>f then begin 
  plr_begin.color8:=i;
  plr_begin.color:=thepal[i];
  event_frame(s);
 end;
end;   
//############################################################################//
function keydown_clan(s:psdi_rec;key,shift:dword):boolean;
var i,f:integer;
begin
 result:=true;
 
 i:=plr_begin.clan;
 f:=i;
 case key of
  key_1..key_8:i:=key-key_1;
  KEY_UP :  if i>3 then i:=i-4;
  KEY_DWN:  if i<4 then i:=i+4;
  KEY_LEFT: if i>0 then i:=i-1;
  KEY_RIGHT:if i<7 then i:=i+1;
 end;
 if i<>f then begin plr_begin.clan:=i; snd_click(SND_TCK);end;
end;
//############################################################################//
function mousedown_setup(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i:integer;
begin      
 result:=true;
 //Color selector
 if inrects(x,y,xn+30+12,yn+40+177,240,150) then begin
  i:=(x-xn-30-12)div 15+((y-yn-40-177)div 10)*16;
  if((i>=0)and(i<=6))or((i>=32)and(i<64))or(i>=160)then begin plr_begin.color8:=i; plr_begin.color:=thepal[i]; end;
 end;
 event_frame(s);
end;
//############################################################################//
function mousedown_clan(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i,j,xx,yy:integer;
begin      
 result:=true;    
 for i:=0 to 3 do for j:=0 to 1 do begin
  clan_pos(xx,yy,xn,yn,i,j);
  if inrects(x,y,xx,yy,clan_sz,clan_sz)then begin
   snd_click(SND_TCK);
   plr_begin.clan:=i+4*j;
  end;
 end;
end;
//############################################################################//
begin   
 plr_name:='';
 plr_pass:='';
 add_menu('Clan select menu' ,MS_CLANSELECT ,clan_xs div 2,clan_ys div 2,BCK_SHADE,init_clan ,nil,draw_clansel_menu    ,ok_clan ,cancel_clan ,nil        ,nil        ,nil,keydown_clan ,mousedown_clan ,nil,nil,nil);
 add_menu('Player setup menu',MS_PLAYERSETUP,          200,          211,BCK_SHADE,init_setup,nil,draw_playersetup_menu,ok_setup,cancel_setup,enter_setup,clear_setup,nil,keydown_setup,mousedown_setup,nil,nil,nil);
end.
//############################################################################//

