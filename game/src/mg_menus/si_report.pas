//############################################################################//
//Report menu
unit si_report;
interface
uses asys,maths,strval,grph,graph8,sdigrtools,
mgrecs,mgl_common,mgl_attr,mgl_rmnu,mgl_logs,sdirecs,sdiauxi,sdicalcs,sdisound,sdimenu,sdigui,sdiovermind,sdi_int_elem;
//############################################################################//
implementation
//############################################################################//
const
menu_xs=640;
menu_ys=480;

block_xp=10;
block_yp=10;
block_xs=menu_xs-170-block_xp;
block_ys=menu_ys-20-block_yp;
//############################################################################//
//Report
var
report_cur:integer=0;  //current tab of reports
report_pos:integer=0;  //current page unit number
report_cnt:integer=-1; //units count in report list
report_find_current:boolean=false; //mode for find current unit and set report_pos. Applicable only for unit list
report_chk:array[0..9]of boolean;

report_list_scr:pscrollbox_type;
report_btns:array[0..4]of pbutton_type;
//############################################################################//
procedure on_btn(s:psdi_rec;par,px:dword);
begin
 case par of
  131:if report_cnt<>-1 then begin
   if report_pos>report_cnt then report_pos:=(report_cnt div 8)*8;
   report_list_scr.bottom:=(report_cnt div 8)*8;
  end;
  800:begin
   report_pos:=0;
   report_cnt:=-1;
   report_list_scr.bottom:=0;
  end;
  801..806:if dword(report_cur)<>par-801 then begin
   report_pos:=0;
   report_cnt:=-1;
   report_list_scr.bottom:=0;
   report_cur:=par-801;
   report_btns[0].stat:=false;
   report_btns[1].stat:=false;
   report_btns[2].stat:=false;
   report_btns[3].stat:=false;
   report_btns[4].stat:=false;
   report_btns[report_cur].stat:=true;
   report_find_current:=false;
  end;
 end;
end;
//############################################################################//
function isincat_report(bld,bldr,stealth,ismov:boolean;ptyp,attk,hits,bldby:integer):boolean;
begin
 result:=false;
 if report_chk[0] then if ptyp in [5]    then result:=true; // air units
 if report_chk[1] then if ptyp in [0..2] then result:=true; // ground
 if report_chk[2] then if ptyp in [2..4] then result:=true; // sea
 if bld then result:=report_chk[3];                         // buildings
 if not report_chk[8] then if bldby=1 then result:=false;   // engineering
 //TODO: bldby=1 should be changed to correct get Engineer's ID (cashed to some var)

 if report_chk[4] then if not bldr then result:=false;     // builder
 if report_chk[5] then if attk=0   then result:=false;     // attacker
 if result then if hits<>-1 then begin
  if report_chk[6] then if hits=0   then result:=false;    // damaged
 end;
 if report_chk[7] then if not stealth then result:=false;  // stealth
 if report_chk[9] then if not ismov then result:=false;  // stealth
end;
//############################################################################//
// check if unitdb choult be presented in casuality report
function is_unitdbcasrep(s:psdi_rec;ud:ptypunitsdb;is_catcheck:boolean=true):boolean;
begin
 result:=not isadb(s.the_game,ud,a_unselectable) and ((ud.bas.cost>3)or(isadb(s.the_game,ud,a_human)));
 //category check
 if is_catcheck then result:=result and isincat_report(isadb(s.the_game,ud,a_building),ud.canbuild,isadb(s.the_game,ud,a_stealth)or isadb(s.the_game,ud,a_underwater),false,ud.ptyp,ud.bas.attk,-1,ud.bldby);
end;
//############################################################################//
procedure get_unitcas(s:psdi_rec;pn:integer;var scnt,scost:integer);
var i:integer;
ud:ptypunitsdb;
p:pplrtyp;
begin try
 scnt:=0;scost:=0;
 for i:=0 to get_unitsdb_count(s.the_game)-1 do begin
  ud:=get_unitsdb(s.the_game,i);
  p:=get_plr(s.the_game,pn);
  if not is_unitdbcasrep(s,ud,false) then continue;
  if p.u_cas[i]<>0 then begin
   scost:=scost+p.u_cas[i]*ud.bas.cost;
   scnt:=scnt+p.u_cas[i];
  end;
 end;
 except end;      ///WTF?
end;
//############################################################################//
//check if unit choult be presented in unit list report
function is_unitlistrep(s:psdi_rec;u:ptypunits;is_enemy:boolean):boolean;
var ud:ptypunitsdb;
cp:pplrtyp;
begin
 cp:=get_cur_plr(s.the_game);
 result:=not isa(s.the_game,u,a_exclude_from_report);
 if is_enemy then result:=result and(u.own<>cp.num)and not u.stored and can_see(s.the_game,u.x,u.y,cp.num,u)
             else result:=result and(u.own=cp.num);
 //category check
 ud:=get_unitsdb(s.the_game,u.dbn);
 result:=result and isincat_report(isa(s.the_game,u,a_building),ud.canbuild,isa(s.the_game,u,a_stealth_or_underw),u.is_moving and not u.is_moving_now,u.ptyp,u.bas.attk,u.bas.hits-u.cur.hits,ud.bldby);
end;
//############################################################################//
procedure draw_report_unitlist(s:psdi_rec;dst:ptypspr;xn,yn:integer;is_enemy:boolean=false);
//1-unit sprite,2-name,3-stats,4-coord,5-text
const col:array [1..5] of integer=(21,55,136,136+145+5,136+145+5+50);
var i,j,k,c,b,idx,vi,fnt,dxicon,clr,n,off:integer;
un,su,u:ptypunits;
ud:ptypunitsdb;
en:ptypeunitsdb;
p,cp:pplrtyp;
st:string;
begin
 off:=15;
 idx:=-1;
 su:=get_sel_unit(s.the_game);
 cp:=get_cur_plr(s.the_game);
 for j:=0 to get_unitsdb_count(s.the_game)-1 do begin
  n:=0;
  for i:=0 to get_units_count(s.the_game)-1 do begin
   if not unave(s.the_game,i) then continue;
   un:=get_unit(s.the_game,i);
   u:=get_unit(s.the_game,un.stored_in);
   if un.dbn<>j then continue; //proseed only current unit type
   if not is_unitlistrep(s,un,is_enemy) then continue;
   idx:=idx+1;
   n:=n+1;

   if report_find_current then begin
    if su<>nil then if un<>su then continue;
    report_find_current:=false;
    report_pos:=idx-idx mod 8;
    exit;
   end;

   if idx<report_pos then continue; //in prev pages
   if report_cnt<idx+1 then begin report_cnt:=idx+1;report_list_scr.bottom:=(report_cnt div 8)*8; end;
   if idx>report_pos+7 then exit; //page completed

   vi:=idx-report_pos;
   //col 1
   c:=xn+off+col[1];
   b:=yn+16+56*vi;
   k:=un.grp_db;
   if k<>-1 then putsprtx8_uspr(s,dst,@s.eunitsdb[k].spr_list,c+16,b+28);
   if su<>nil then if un=su then draw_unitframe(dst,c,b+28-16,c+32,b+28+16,255);
   if is_enemy then begin
    clr:=get_player_color8(s,un.own);
    drrect8(dst,c+1,b+28-16+1,c+32-1,b+28+16-1,clr);
   end;
   wrtxtxbox8(s.cg,dst,xn+off+col[1]-6,b,20,56,stri(n),0);
   //col 2
   wrtxtxbox8(s.cg,dst,xn+off+col[2],b,80,56,unit_mk(un)+unit_name(s.the_game,un)+base_mk(s.the_game,un,true),0);
   //col 3
   draw_stats_un(s,dst,xn+off+col[3],b,145,yn+22+36+56*vi-b,un,false,0);
   //col 4
   if un.stored and (u<>nil) then begin un.x:=u.x; un.y:=u.y; end;
   wrtxtxbox8(s.cg,dst,xn+off+col[4],b,50,56,stri(un.x)+':'+stri(un.y),0);
   //col 5
   st:='';fnt:=0;dxicon:=0;
   if is_enemy then begin
    if un.disabled_for>0 then st:=st+'Вырублен на '+stri(un.disabled_for)+'# ';
   end else begin
    if isa(s.the_game,un,a_building) and(not isa(s.the_game,un,a_always_active)) then if not un.isact and not un.isbuildfin then st:=st+'Выключено# ';
    if un.is_moving then st:=st+'Двигается в ('+stri(un.x)+':'+stri(un.y)+')# ';
    if un.is_moving and(un.stop_task=stsk_shoot_place) then st:=st+'Атакует ('+stri(un.stop_target)+':'+stri(un.stop_param)+')# ';
    if un.disabled_for>0 then st:=st+'Вырублен на '+stri(un.disabled_for)+'# ';
    if un.stored and (u<>nil)then st:=st+'Спрятан в "'+unit_name(s.the_game,u)+'"# ';
    if un.isclrg then st:=st+'Чистит, ходов до окончания: '+stri(un.clrturns)+'# ';
    if isa(s.the_game,un,a_stealth_or_underw)then for k:=0 to get_plr_count(s.the_game)-1 do begin
     p:=get_plr(s.the_game,k);
     if p<>cp then if un.stealth_detected[p.num]>0 then begin st:=st+'виден для '+p.info.name+'# ';fnt:=6; end;
    end;
    if un.isbuildfin then begin
     dxicon:=32;
     ud:=get_unitsdb(s.the_game,un.builds[0].typ_db);
     en:=get_edb(s,ud.typ);
     if en<>nil then putsprtx8_uspr(s,dst,@en.spr_list,xn+off+col[5]+16,b+28);
     st:=st+'Построено# '; fnt:=6;
    end else if un.isbuild and (un.builds_cnt>0) then begin
     dxicon:=32;
     ud:=get_unitsdb(s.the_game,un.builds[0].typ_db);
     en:=get_edb(s,ud.typ);
     if en<>nil then putsprtx8_uspr(s,dst,@en.spr_list,xn+off+col[5]+16,b+28);
     st:=st+'Ходов: '+stri(un.builds[0].left_turns)+'# ';
     if isa(s.the_game,un,a_building) then begin
      if un.isact then st:=st+'Потребляет: '+stri(max2i(un.prod.use[RES_MAT],un.bas.mat_turn))+'# '
                  else fnt:=6;
     end;
    end;
   end;

   c:=0;
   for k:=1 to length(st) do if st[k]='#' then c:=c+1;
   for k:=1 to length(st) do if st[k]='#' then begin
    if c>1 then begin st[k]:=',';c:=c-1;end else st[k]:=' ';
   end;

   wrtxtxbox8(s.cg,dst,xn+off+col[5]+dxicon,b,120-dxicon,56,st,fnt);
   //puttran8(dst,xn+off+21,yn+16+56*vi,456,56-2,0); //mouse up test
  end;
 end;
 report_find_current:=false;
end;
//############################################################################//
procedure draw_report_cas(s:psdi_rec;dst:ptypspr;xn,yn:integer);
var i,k,idx,vi:integer;
pb,pe:integer; //Player begin and end idx. Reserved for future player list managment
ud:ptypunitsdb;
en:ptypeunitsdb;
newline:boolean;
scst,scnt:array of integer;
p:pplrtyp;
begin try
 pb:=0;
 pe:=get_plr_count(s.the_game)-1;
 if pe>3 then pe:=3; //current limitation: report dlg supports only 4 players
 setlength(scst,pe-pb+1);
 setlength(scnt,pe-pb+1);
 for k:=pb to pe do begin scst[k]:=0; scnt[k]:=0; end;
 idx:=-1;vi:=-1;
 for i:=0 to get_unitsdb_count(s.the_game)-1 do begin
  ud:=get_unitsdb(s.the_game,i);
  if not is_unitdbcasrep(s,ud) then continue;
  newline:=false;
  for k:=pb to pe do begin
   p:=get_plr(s.the_game,k);
   if p.u_cas[i]<>0 then begin
    scst[k]:=scst[k]+p.u_cas[i]*ud.bas.cost;
    scnt[k]:=scnt[k]+p.u_cas[i];
    if vi=-2 then continue; //do not display - only calculate cost
    if not newline then begin
     newline:=true;
     idx:=idx+1;
     if report_cnt<idx+1 then begin report_cnt:=idx+1;report_list_scr.bottom:=(report_cnt div 8)*8; end;
     if idx<report_pos then continue; //in prev pages
     if idx>report_pos+7 then begin vi:=-2; continue; end; //page completed
     vi:=vi+1;
     en:=get_edb(s,ud.typ);
     if en<>nil then begin
      putsprtx8_uspr(s,dst,@en.spr_list,xn+21+16,yn+40+12+43*vi);
      if lrus then wrtxt8(s.cg,dst,xn+55,yn+50+43*vi,en.name_rus,0)
              else wrtxt8(s.cg,dst,xn+55,yn+50+43*vi,en.name_eng,0);
     end;
    end;
    if idx in [report_pos..report_pos+7] then wrtxtcnt8(s.cg,dst,xn+220+k*72,yn+50+43*vi,stri(p.u_cas[i]),0);
   end;
  end;
 end;
 //Players names and score
 for k:=pb to pe do begin
  p:=get_plr(s.the_game,k);
  wrtxtcnt8(s.cg,dst,xn+220+k*72,yn+21   ,p.info.name,0);
  wrtxtcnt8(s.cg,dst,xn+220+k*72,yn+21+10,stri(scnt[k])+' ('+stri(scst[k])+')',0);
 end;
 except end;
end;
//############################################################################//
procedure draw_report_msg(s:psdi_rec;dst:ptypspr;xn,yn:integer);
const rowsize=56;
cols:array[1..5]of integer=(21,30,80,286,420);
off=5;
var i,len,xo,yo:integer;
color:byte;
st:string;
ud:ptypunitsdb;
edb:ptypeunitsdb;
cp:pplrtyp;
begin
 cp:=get_cur_plr(s.the_game);
 len:=length(cp.logmsg);
 report_cnt:=len;
 if len=0 then exit;
 for i:=len-report_pos-1 downto len-report_pos-7-1 do begin
  if i<0 then break;
  yo:=yn+16+((len-report_pos-1)-i)*rowsize;
  //ud:=get_unitsdb(p.logmsg[i].data[0].dbn);
  //s:=s+' - '+ud.name;
  //column 1
  xo:=xn+off+cols[1];
  wrtxtxbox8(s.cg,dst,xo,yo,20,rowsize,stri(i+1),0);
  //column 2
  xo:=xn+off+cols[2];
  if cp.logmsg[i].data[0].dbn<>-1 then begin
   if(cp.logmsg[i].data[0].own<>-1)and(cp.logmsg[i].data[0].own<>cp.num)then begin
    color:=get_player_color8(s,cp.logmsg[i].data[0].own);
    drrect8(dst,xo+4+1,yo+28-16+1,xo+4+32-1,yo+28+16-1,color);
   end;
   ud:=get_unitsdb(s.the_game,cp.logmsg[i].data[0].dbn);
   edb:=get_edb(s,ud.typ);
   if edb<>nil then begin
    putsprtx8_uspr(s,dst,@edb.spr_list,xo+20,yo+28);
    //wrtxtxbox8(dst,xo,row,80,16,edb.name,0);
   end;
  end;
  //column 3
  xo:=xn+off+cols[3];
  color:=0;
  st:=string_log_msg(s.the_game,@cp.logmsg[i]);
  wrtxtxbox8(s.cg,dst,xo,yo,320,rowsize,st,color);
  //column 5
  xo:=xn+off+cols[5];
  if cp.logmsg[i].data[1].dbn<>-1 then begin
   if(cp.logmsg[i].data[1].own<>-1)and(cp.logmsg[i].data[1].own<>cp.num)then begin
    color:=get_player_color8(s,cp.logmsg[i].data[1].own);
    drrect8(dst,xo+4+1,yo+28-16+1,xo+4+32-1,yo+28+16-1,color);
   end;
   ud:=get_unitsdb(s.the_game,cp.logmsg[i].data[1].dbn);
   edb:=get_edb(s,ud.typ);
   if edb<>nil then begin
    putsprtx8_uspr(s,dst,@edb.spr_list,xo+20,yo+28);
    //wrtxtxbox8(s.cg,dst,xo,row,80,16,edb.name,0);
   end;
  end;
 end;
end;
//############################################################################//
procedure draw_report_menu(s:psdi_rec;dst:ptypspr;xn,yn:integer);
begin
 tran_rect8(s.cg,dst,xn+block_xp,yn+block_yp,block_xs,block_ys,0);
 report_btns[report_cur].stat:=true;
 case report_cur of
  0:draw_report_unitlist(s,dst,xn,yn);
  1:draw_report_cas(s,dst,xn,yn);
  2:wrtxt8(s.cg,dst,xn+100,yn+100,'Under construction',2);
  3:draw_report_msg(s,dst,xn,yn);
  4:draw_report_unitlist(s,dst,xn,yn,true);
 end;
end;
//############################################################################//
function keydown(s:psdi_rec;key,shift:dword):boolean;
begin
 result:=true;
 case key of
  KEY_R:set_game_menu(s.the_game,MG_NOMENU);
  KEY_F:report_find_current:=true;
 end;
end;
//############################################################################//
function mouseup(s:psdi_rec;shift:dword;x,y,xn,yn:integer):boolean;
var i,j,idx,vi,ux,uy:integer;
u,u2:ptypunits;
cp:pplrtyp;
begin
 result:=true;
 cp:=get_cur_plr(s.the_game);
 //Messages
 if report_cur=3 then if isf(shift,sh_left) or isf(shift,sh_right) or isf(shift,sh_middle) then begin
  j:=length(cp.logmsg);
  for i:=report_pos to report_pos+7 do begin
   vi:=i-report_pos;
   idx:=j-i-1;
   if idx<0 then break;
   if inrects(x,y,xn+21,yn+16+56*vi,456,56)then begin
    //delete message
    if isf(shift,sh_alt) then begin
     for vi:=idx to j-2 do cp.logmsg[vi]:=cp.logmsg[vi+1];
     j:=j-1;
     setlength(cp.logmsg,j);
     if report_pos>j-1 then report_pos:=max2i(j-7-1,0);
     if report_cnt>j then begin
      report_cnt:=j-1;
      report_list_scr.bottom:=report_cnt-1;
     end;
     exit;
    end;
    ux:=cp.logmsg[idx].data[1].x;
    uy:=cp.logmsg[idx].data[1].y;
    if inrects(x,y,xn+21,yn+16+56*vi,456 div 2,56)or(ux=-1)or(uy=-1)then begin
     ux:=cp.logmsg[idx].data[0].x;
     uy:=cp.logmsg[idx].data[0].y;
    end;
    if(ux<>-1)and(uy<>-1)then begin
     snd_click(SND_ACCEPT);
     clear_menu(s);
     so_reposition_map_pixels(s,-(ux+1),-(uy+1));
     //select builder
     if cp.logmsg[idx].tp=lmt_build_completed then begin
      for vi:=0 to get_unu_length(s.the_game,ux,uy)-1 do begin
       u:=get_unu(s.the_game,ux,uy,vi);
       if u<>nil then if u.dbn=cp.logmsg[idx].data[0].dbn then begin
        select_unit(s.the_game,u.num,false);
        break;
       end;
      end;
     end;
     event_units(s);
    end else snd_click(SND_TOGGLE);
    exit;
   end;
  end;
 end;

 if report_cur in [0,4] then if isf(shift,sh_left) or isf(shift,sh_right) or isf(shift,sh_middle) then begin
  if isf(shift,sh_right) then begin on_btn(s,800,0);exit;end;
  idx:=-1;
  for j:=0 to get_unitsdb_count(s.the_game)-1 do for i:=0 to get_units_count(s.the_game)-1 do begin
   if not unave(s.the_game,i) then continue;
   u:=get_unit(s.the_game,i);
   u2:=u;
   if u.dbn<>j then continue; //proseed only current unit type
   if not is_unitlistrep(s,u,report_cur=4) then continue;
   idx:=idx+1;
   if idx<report_pos then continue; //in prev pages
   if idx>report_pos+7 then exit;   //page completed

   vi:=idx-report_pos;
   if inrects(x,y,xn+21,yn+16+56*vi,456,56)then begin
    if cp.selunit=u.num then begin
     if u.stored and unave(s.the_game,u.stored_in) then begin u2:=get_unit(s.the_game,u.stored_in);u.x:=u2.x; u.y:=u2.y; end;
     select_unit(s.the_game,u2.num,false);
     snd_click(SND_ACCEPT);
     so_reposition_map_pixels(s,-(u.x+1),-(u.y+1));
     clear_menu(s);
     event_units(s);
     exit;
    end else begin
     select_unit(s.the_game,u2.num,false);
     if isf(shift,sh_middle) then so_reposition_map_pixels(s,-(u.x+1),-(u.y+1));
    end;
   end;
  end;
 end;
end;
//############################################################################//
function enter(s:psdi_rec):boolean;
begin
 result:=true;
 if get_sel_unit(s.the_game)=nil then begin
  if report_cur<>3 then report_pos:=0;
  report_find_current:=false;
 end else report_find_current:=true;
end;
//############################################################################//
function init(s:psdi_rec):boolean;
var mn,pg,i,off1,off2:integer;
begin
 result:=true;
 if s.state<>CST_THEGAME then exit;

 mn:=MG_REPORT;
 pg:=0;

 add_label (mn,pg,532,018,0,3,po('Reports'));
 add_button(mn,pg,509,398,94,24,7,5,'OK',on_ok_btn,0);

 for i:=0 to 4 do report_btns[i]:=add_button(mn,pg,509,51+i*29,94,24,7,5,'-',on_btn,801+i);
 report_btns[0].txt:=po('Units');
 report_btns[1].txt:=po('Casualties');
 report_btns[2].txt:=po('Score');
 report_btns[3].txt:=po('Messages');
 report_btns[4].txt:=po('Enemy');

 report_list_scr:=add_scrollbox(mn,pg,SCB_VERTICAL,487,426,516,426,24,25,8,0,1000,false,@report_pos,on_btn,131);
 add_scrolarea(mn,pg,-1,0,10,500,400,1,50,0,1000,@report_pos,on_btn,131,report_list_scr);

 off1:=208;
 add_label    (mn,pg,497,off1-13,  0,7,po('Including'));
 add_label    (mn,pg,517,off1+0*18,0,7,po('Air'));        add_checkbox (mn,pg,496,off1-4+0*18,16,16,nil,@report_chk[0],on_btn,800);
 add_label    (mn,pg,517,off1+1*18,0,7,po('Ground'));     add_checkbox (mn,pg,496,off1-4+1*18,16,16,nil,@report_chk[1],on_btn,800);
 add_label    (mn,pg,517,off1+2*18,0,7,po('Sea'));        add_checkbox (mn,pg,496,off1-4+2*18,16,16,nil,@report_chk[2],on_btn,800);
 add_label    (mn,pg,517,off1+3*18,0,7,po('Buildings'));  add_checkbox (mn,pg,496,off1-4+3*18,16,16,nil,@report_chk[3],on_btn,800);
 add_label    (mn,pg,517,off1+4*18,0,7,po('Engineering'));add_checkbox (mn,pg,496,off1-4+4*18,16,16,nil,@report_chk[8],on_btn,800);
 for i:=0 to 3 do report_chk[i]:=true;
 report_chk[8]:=true;

 off2:=312;
 add_label    (mn,pg,497,off2-16,  0,7,po('Filter'));
 add_label    (mn,pg,517,off2+0*18,0,7,po('Builder')); add_checkbox (mn,pg,496,off2-4+0*18,16,16,nil,@report_chk[4],on_btn,800);
 add_label    (mn,pg,517,off2+1*18,0,7,po('Attacker'));add_checkbox (mn,pg,496,off2-4+1*18,16,16,nil,@report_chk[5],on_btn,800);
 add_label    (mn,pg,517,off2+2*18,0,7,po('Damaged')); add_checkbox (mn,pg,496,off2-4+2*18,16,16,nil,@report_chk[6],on_btn,800);
 add_label    (mn,pg,517,off2+3*18,0,7,po('Stealth')); add_checkbox (mn,pg,496,off2-4+3*18,16,16,nil,@report_chk[7],on_btn,800);
 add_label    (mn,pg,517,off2+4*18,0,7,po('Moving'));  add_checkbox (mn,pg,496,off2-4+4*18,16,16,nil,@report_chk[9],on_btn,800);

end;
//############################################################################//
function deinit(s:psdi_rec):boolean;
begin
 result:=true;
 report_list_scr:=nil;
end;
//############################################################################//
begin
 add_menu('Report menu',MG_REPORT,menu_xs div 2,menu_ys div 2,BCK_SHADE,init,deinit,draw_report_menu,nil,nil,enter,nil,nil,keydown,nil,mouseup,nil,nil);
end.
//############################################################################//
