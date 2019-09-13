//############################################################################//
unit mgl_land;
interface
uses mgrecs,mgl_common,mgl_attr,mgl_stats,mgl_tests,mgl_actions;
//############################################################################//
const
LND_SELECT=1;
LND_ADD=2;
LND_DELETE=3;
//############################################################################//
type
landing_editor_rec=record
 mode:integer;
 sel_db_unit:integer;
 sel_unit:integer;
 range:integer;
end;
planding_editor_rec=^landing_editor_rec;
//############################################################################//    
var
plr_land:landing_editor_rec;
plr_begin:player_start_rec;
cbk_buysell:procedure(g:pgametyp;rul:prulestyp;evt,x,y,n:integer;shift:boolean)=nil;
//############################################################################//
function is_beginable_unit(g:pgametyp;rul:prulestyp;n:integer):boolean;
function begin_unit_res_capacity(g:pgametyp;n:integer):integer;
function add_begin_unit(g:pgametyp;rul:prulestyp;n,x,y:integer;is_full:boolean):integer;
procedure rem_begin_unit(g:pgametyp;k:integer);
procedure plr_set_default_begins(var info:player_start_rec;const rules:rulestyp);
procedure do_direct_landing(g:pgametyp;xns,yns:integer;btn:byte);
function do_landing(g:pgametyp;xns,yns:integer;btn:byte):boolean;
//############################################################################//
implementation
//############################################################################//
procedure set_bgn(var bgn:typbeg;typ:string;locked:boolean;mat,x,y:integer);
begin
 bgn.typ:=typ;
 bgn.mat:=mat;
 bgn.locked:=locked;
 bgn.x:=x;
 bgn.y:=y;
end;
//############################################################################//
function is_beginable_unit(g:pgametyp;rul:prulestyp;n:integer):boolean;
var ud:ptypunitsdb;
begin
 result:=false;
 ud:=get_unitsdb(g,n);
 if ud=nil then exit;

 if isadb(g,ud,a_building) and not rul.direct_land then exit;
 if (ud.ptyp>=pt_watercoast) and not rul.direct_land then exit;
 if (not isadb(g,ud,a_begin_buyable))and(not(isadb(g,ud,a_direct_buyable)and(rul.direct_land))) then exit;
 if rul.no_buy_atk and(ud.bas.attk<>0) then exit;
 result:=true;
end;
//############################################################################//
function begin_unit_res_capacity(g:pgametyp;n:integer):integer;
var r:integer;
ud:ptypunitsdb;
begin
 result:=0;
 ud:=get_unitsdb(g,n);
 if ud=nil then exit;

 for r:=RES_MINING_MIN to RES_MINING_MAX do if ud.prod.num[r]<>0 then result:=ud.prod.num[r];
 result:=result div 5+ord((result mod 5)<>0);
end;
//############################################################################//
function add_begin_unit(g:pgametyp;rul:prulestyp;n,x,y:integer;is_full:boolean):integer;
var ud:ptypunitsdb;
begin
 result:=-1;
 if plr_begin.bgncnt>=MAX_BEGINS then exit;

 if not is_beginable_unit(g,rul,n) then exit;
 ud:=get_unitsdb(g,n);
 if ud=nil then exit;

 result:=plr_begin.bgncnt;
 plr_begin.bgncnt:=plr_begin.bgncnt+1;
                         
 set_bgn(plr_begin.bgn[result],ud.typ,false,ord(is_full)*begin_unit_res_capacity(g,n)*5,x,y);
end;
//############################################################################//
procedure rem_begin_unit(g:pgametyp;k:integer);
var i:integer;
begin
 for i:=k to plr_begin.bgncnt-2 do plr_begin.bgn[i]:=plr_begin.bgn[i+1];
 plr_begin.bgncnt:=plr_begin.bgncnt-1;
end;
//############################################################################//
procedure plr_set_default_begins(var info:player_start_rec;const rules:rulestyp);
var k,j:integer;
begin
 for j:=0 to length(info.init_unupd)-1 do zero_stats(info.init_unupd[j].bas);
 if rules.direct_land then begin
  info.bgncnt:=0;
  exit;
 end;

 k:=0;
 set_bgn(info.bgn[k],'constructor',true,0,-1,-1);k:=k+1;
 set_bgn(info.bgn[k],'engineer'   ,true,0, 0,-1);k:=k+1;
 if not rules.no_survey then begin set_bgn(info.bgn[k],'surveyor',true,0,1,-1);k:=k+1;end;
 info.bgncnt:=k;
end; 
//############################################################################//
procedure do_direct_landing(g:pgametyp;xns,yns:integer;btn:byte);
var prleft,prright,sshift:boolean;
cp:pplrtyp;
rul:prulestyp;
n,i:integer;
ud:ptypunitsdb;
begin
 prleft:=btn and 1<>0;
 prright:=btn and 2<>0;
 sshift:=btn and 4<>0;

 cp:=get_cur_plr(g);
 if is_landed(g,cp) then exit;
 rul:=get_rules(g);

 n:=-1;
 for i:=0 to plr_begin.bgncnt-1 do begin
  ud:=get_unitsdb(g,getdbnum(g,plr_begin.bgn[i].typ));
  if ud=nil then continue;
  if (xns=plr_begin.bgn[i].x+plr_begin.lndx)and(yns=plr_begin.bgn[i].y+plr_begin.lndy) then begin n:=i;break;end;
  if ud.siz=2 then begin
   if (xns=plr_begin.bgn[i].x+plr_begin.lndx+1)and(yns=plr_begin.bgn[i].y+plr_begin.lndy  ) then begin n:=i;break;end;
   if (xns=plr_begin.bgn[i].x+plr_begin.lndx  )and(yns=plr_begin.bgn[i].y+plr_begin.lndy+1) then begin n:=i;break;end;
   if (xns=plr_begin.bgn[i].x+plr_begin.lndx+1)and(yns=plr_begin.bgn[i].y+plr_begin.lndy+1) then begin n:=i;break;end;
  end;
 end;

 if prleft then begin
  if (plr_land.sel_db_unit<>-1)and(n=-1) then begin
   if sqr(xns-plr_begin.lndx)+sqr(yns-plr_begin.lndy)<sqr(plr_land.range) then begin
    if test_pass_db(g,xns,yns,plr_land.sel_db_unit,nil) then begin
     if assigned(cbk_buysell) then cbk_buysell(g,rul,0,xns-plr_begin.lndx,yns-plr_begin.lndy,plr_land.sel_db_unit,sshift);
    end;
   end;
  end else begin
   if n<>-1 then begin
    plr_land.sel_unit:=n;
    plr_land.sel_db_unit:=-1;
    if n<>-1 then if assigned(cbk_buysell) then cbk_buysell(g,rul,2,0,0,n,sshift);
   end;
  end;
 end;

 if prright then begin
  if plr_land.sel_db_unit<>-1 then begin
   plr_land.sel_db_unit:=-1;
  end else begin
   if n<>-1 then if assigned(cbk_buysell) then cbk_buysell(g,rul,1,0,0,n,sshift);
   plr_land.sel_unit:=-1;
   if n<>-1 then if assigned(cbk_buysell) then cbk_buysell(g,rul,2,0,0,-1,sshift);
  end;
 end;
end; 
//############################################################################//
function do_landing(g:pgametyp;xns,yns:integer;btn:byte):boolean;
var x,y,m:integer;
prleft:boolean;
cp:pplrtyp;
rul:prulestyp;
begin
 result:=false;
 prleft:=btn and 1<>0;

 cp:=get_cur_plr(g);
 if is_landed(g,cp) then exit;
 rul:=get_rules(g);
 result:=true;

 if not g.info.rules.direct_land then begin
  plr_begin.lndx:=xns;
  plr_begin.lndy:=yns;
  if prleft then act_land_player(g,@plr_begin);
 end else begin
  if plr_begin.lndx=-1 then begin
   plr_begin.lndx:=xns;
   plr_begin.lndy:=yns;
   if assigned(on_selection_changed) then on_selection_changed(g.grp_1,nil,nil);

   plr_land.range:=rul.moratorium_range;
   plr_land.mode:=0;
   plr_land.sel_db_unit:=-1;
   plr_land.sel_unit:=-1;

   for m:=0 to SL_COUNT-1 do for y:=0 to g.info.mapy-1 do for x:=0 to g.info.mapx-1 do begin
    if sqr(xns-x)+sqr(yns-y)<sqr(plr_land.range) then cp.scan_map[m][x+y*g.info.mapx]:=1
                                                 else cp.scan_map[m][x+y*g.info.mapx]:=0;
   end;
  end else begin
   do_direct_landing(g,xns,yns,btn);
  end;
 end;
end;
//############################################################################//
begin
end.      
//############################################################################//
