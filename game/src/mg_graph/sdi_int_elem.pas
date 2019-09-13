//############################################################################//
unit sdi_int_elem;
interface
uses asys,strval,maths,grph,graph8
,sdirecs,sdiauxi,sdigrtools,sdigui,sdisound
,mgrecs,mgl_common,mgl_stats,mgl_land;
//############################################################################//
const
elem_gap=2;
caption_ys=20;
scroller_sz=20;

stat_left_gap=85;

stat_short_txt_off=50;
stat_short_txt_num_off=25;
stat_short_gap=16;
stat_short_ico_off=85;
stat_short_max_ico=30;

stat_full_gap=18;
stat_full_ico_off=70;
stat_full_txt_num_off=24;
stat_full_max_ico=80;

upg_step=stat_full_gap;
upg_scroller_sz=upg_step-1; 
upg_txt_xs=28;

list_cost_xs=14;
list_elem_ys=32;
//############################################################################//
type
material_bit_rec=record
 xp,yp,xs,ys:integer;
 cur,total:integer;
 kind,step:integer;
 show_zero,input:boolean;

 sc:pscrollbox_type;
 ml:plabel_type;
end;
//############################################################################//
unit_list_elem=record
 dbn:integer;
 cost:integer;
 par,idx:string;
end;
//############################################################################//
unit_list_rec=record  
 xp,yp,xs,ys:integer;
 step,off,sel:integer;
 list:array of unit_list_elem;
 show_cost:boolean;
 cost_color,high_color,par_color:byte;
 afford:integer;

 sc:pscrollbox_type;
 sca:pscrollarea_type;
 cs,ml:plabel_type;
end;
//############################################################################//
upgrade_block_rec=record
 xp,yp,step:integer;
 vl:array[0..8]of integer;
 scr:array[0..8]of pscrollbox_type;
end;
//############################################################################//
procedure draw_unitframe(dst:ptypspr;xh,yh,xl,yl,cl:integer;kind:boolean=true);

procedure draw_stats_un(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer;u:ptypunits;full:boolean;frm:byte);
procedure draw_stats_db(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer;ud:ptypunitsdb;rul:prulestyp;buy:boolean);
procedure draw_stats_ng(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer;ud:ptypunitsdb;rul:prulestyp;plr:pplayer_start_rec);

procedure drut_clan_info(s:psdi_rec;dst:ptypspr;clan:ptypclansdb;xn,yn:integer);

procedure drut_descr_box(s:psdi_rec;dst:ptypspr;u:ptypunits;x,y,xs,ys:integer);
procedure drut_poster_box(s:psdi_rec;dst:ptypspr;u:ptypunits;x,y,xs,ys:integer);
procedure drut_full_stats_box(s:psdi_rec;dst:ptypspr;u:ptypunits;x,y,xs,ys:integer);

procedure draw_material_bit(s:psdi_rec;dst:ptypspr;xn,yn:integer;var m:material_bit_rec);
procedure init_material_bit(out m:material_bit_rec;mn,pg:dword;xp,yp,xs,ys,kind,step:integer;name:string;show_zero,input:boolean;event:onevent_scroll;par:dword);
procedure set_material_bit(var m:material_bit_rec;cur,total,kind:integer);
procedure vis_material_bit(var m:material_bit_rec;vis:boolean); 
procedure reloc_material_bit(var m:material_bit_rec;xp,yp,xs,ys:integer);
function mouse_material_bit(var m:material_bit_rec;evt,x,y,dir:integer):boolean;

procedure draw_unit_list(s:psdi_rec;dst:ptypspr;xn,yn:integer;var z:unit_list_rec;plr_n:integer);
procedure init_unit_list(out z:unit_list_rec;mn,pg:dword;xp,yp,xs,ys,step:integer;name:string;show_cost:boolean;cost_color,high_color,par_color:byte;event:onevent_scroll;par:dword);
procedure set_unit_list(var z:unit_list_rec;sel,off,afford:integer);
procedure vis_unit_list(var z:unit_list_rec;vis:boolean);
procedure reloc_unit_list(var z:unit_list_rec;xp,yp,xs,ys,step:integer);
function mouse_unit_list(s:psdi_rec;var z:unit_list_rec;evt,x,y,dir:integer;out double:boolean):boolean;

procedure init_upgrade_block(out z:upgrade_block_rec;mn,pg:dword;xp,yp,step:integer;event:onevent_scroll;par:dword);
procedure vis_upgrade_block(var z:upgrade_block_rec;c:integer;vis:boolean);
//############################################################################//
implementation
//############################################################################//
procedure draw_unitframe(dst:ptypspr;xh,yh,xl,yl,cl:integer;kind:boolean=true);
const d:array[0..1] of integer=(1,-1);
var i:integer;
begin
 if kind then begin
  drrect8(dst,xh,yh,xh,yh+10,cl);drrect8(dst,xh,yh,xh+10,yh,cl);
  drrect8(dst,xh,yl,xh,yl-10,cl);drrect8(dst,xh,yl,xh+10,yl,cl);
  drrect8(dst,xl,yl,xl,yl-10,cl);drrect8(dst,xl,yl,xl-10,yl,cl);
  drrect8(dst,xl,yh,xl,yh+10,cl);drrect8(dst,xl,yh,xl-10,yh,cl);
 end else for i:=0 to 1 do begin
  drrect8(dst,xh+d[i],yh+d[i],xh+d[i],yh+10,cl);drrect8(dst,xh+d[i],yh+d[i],xh+10,yh+d[i],cl);
  drrect8(dst,xh+d[i],yl-d[i],xh+d[i],yl-10,cl);drrect8(dst,xh-d[i],yl+d[i],xh+10,yl+d[i],cl);
  drrect8(dst,xl+d[i],yl+d[i],xl+d[i],yl-10,cl);drrect8(dst,xl+d[i],yl+d[i],xl-10,yl+d[i],cl);
  drrect8(dst,xl+d[i],yh-d[i],xl+d[i],yh+10,cl);drrect8(dst,xl-d[i],yh+d[i],xl-10,yh+d[i],cl);
 end;
end;
//############################################################################//
procedure parcor(var par,pars:integer;ic:integer);
var dlt:integer;
b:boolean;
begin
 case ic of
   0:dlt:=4;
   2:dlt:=10;
  14:dlt:=10;
   4:dlt:=10;
  else dlt:=1;
 end;
 b:=pars<>par;
 par :=par  div dlt+ord((par  mod dlt)<>0);
 pars:=pars div dlt+ord((pars mod dlt)<>0);
 if b and (pars=par) and (pars>0) then pars:=pars-1;
end;
//############################################################################//
procedure dodrstats(s:psdi_rec;dst:ptypspr;x,y,xs,ys:integer;var j:integer;nm:string;par,pars,ic,sz:integer;revcol,full:boolean;ic2:integer=0);
var i:integer;
k,l:real;
begin
 if not full then begin
  if par>0 then begin
   if pars/par>0.5  then wrtxtcntmg8(s.cg,dst,x+stat_short_txt_num_off,y+j*stat_short_gap-2,stri(pars)+'/'+stri(par),13-ord(revcol)) else
   if pars/par>0.25 then wrtxtcntmg8(s.cg,dst,x+stat_short_txt_num_off,y+j*stat_short_gap-2,stri(pars)+'/'+stri(par),14) else
                         wrtxtcntmg8(s.cg,dst,x+stat_short_txt_num_off,y+j*stat_short_gap-2,stri(pars)+'/'+stri(par),12+ord(revcol));
   wrtxtmg8(s.cg,dst,x+stat_short_txt_off,y+j*stat_short_gap-2,nm,11);

   parcor(par,pars,ic);
   if par>stat_short_max_ico then begin
    l:=stat_short_max_ico/par;
    par:=stat_short_max_ico;
    pars:=round(pars*l);
   end;
   k:=(xs-stat_left_gap-10)/par;if k>sz then k:=sz;

   if pars<>par then for i:=pars to par-1 do putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[ic+1],x+round(i*k)+stat_short_ico_off,y+j*stat_short_gap-5);
                       for i:=0 to pars-1 do putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[ic  ],x+round(i*k)+stat_short_ico_off,y+j*stat_short_gap-5);

   if j<>0 then drline8(dst,x,y+j*stat_short_gap-6,x+xs,y+j*stat_short_gap-6,line_color);
   inc(j);
  end;
 end else begin
  wrtxtrmg8(s.cg,dst,x+stat_full_txt_num_off-1,y+j*stat_full_gap,stri(par),14);
  wrtxtmg8 (s.cg,dst,x+stat_full_txt_num_off+1,y+j*stat_full_gap,nm,11);

  if par>stat_full_max_ico then par:=stat_full_max_ico;
  if pars<0 then k:=(xs-stat_left_gap-5)/(par-pars)
            else k:=(xs-stat_left_gap-5)/par;
  if k>sz then k:=sz;

  if pars<0 then for i:=0 to par-pars-1 do begin
                  if i<par then putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[ic], x+round(i*k)+stat_full_ico_off                                ,y+j*stat_full_gap-5+(i mod 5))
                           else putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[ic2],x+round(i*k)+stat_full_ico_off+round(k)                       ,y+j*stat_full_gap-5+(i mod 5));
  end else for i:=0 to par-1 do putsprt8(dst,@s.cg.grapu[GRU_ICOS].sprc[ic], x+round(i*k)+stat_full_ico_off+round(ord(i>=(par-pars))*(k+1)),y+j*stat_full_gap-5+(i mod 5));

  if pars<0 then i:=x+round((par)*k)+stat_full_ico_off+8
            else i:=x+round((par-pars)*k)+stat_full_ico_off+8;

  if pars<>0 then drline8(dst,i,y+j*stat_full_gap-1,   i,y+j*stat_full_gap+10,line_color);
  if    j<>0 then drline8(dst,x,y+j*stat_full_gap-4,x+xs,y+j*stat_full_gap-4 ,line_color);
  inc(j);
 end;
end;
//############################################################################//
//Draw stats of units and in info/buy
procedure draw_stats_base(s:psdi_rec;dst:ptypspr;xh,yh,xl,yl:integer;st:pmstt;full,buy:boolean;frm:byte);
var j,x,y,xs,ys:integer;
begin try
 j:=0;

 x:=xh+2;
 y:=yh+2+5;
 xs:=xl-x-3;
 ys:=yl-y;

 if not full then begin
  if frm=0 then with st^ do begin
   if bas.hits>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Hits') ,bas.hits ,cur.hits   , 0, 8,false,false);
   if bas.ammo>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Ammo') ,bas.ammo ,cur.ammo   , 8,10,false,false);
   if store>0     then dodrstats(s,dst,x,y,xs,ys,j,po('Store'),store    ,storecnt   ,28, 8,false,false);
   if matnum>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Raw')  ,matnum   ,matnow     , 2,10,false,false);
   if matall>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Total'),matall   ,matallcur  , 2,10,false,false);
   if fuelnum>0   then dodrstats(s,dst,x,y,xs,ys,j,po('Fuel') ,fuelnum  ,fuelnow    , 4, 8,false,false);
   if fuelall>0   then dodrstats(s,dst,x,y,xs,ys,j,po('Total'),fuelall  ,fuelallcur , 4, 8,false,false);
   if pow>0       then dodrstats(s,dst,x,y,xs,ys,j,po('Energ'),pow      ,pownow     ,12, 8,false,false);
   if powall>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Total'),powall   ,powallpro  ,12, 8, true,false);
   if powuse>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Used') ,powuse   ,powuseneed ,12, 8,false,false);
   if gold>0      then dodrstats(s,dst,x,y,xs,ys,j,po('Gold') ,gold     ,goldnow    ,14,10,false,false);
   if goldall>0   then dodrstats(s,dst,x,y,xs,ys,j,po('Total'),goldall  ,goldallcur ,14,10,false,false);
   if manpro>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Man')  ,manpro   ,manpro     ,22,10,false,false);
   if manallpro>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Total'),manallpro,manallpro  ,22,10,false,false);
   if manuse>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Used') ,manuse   ,manall     ,22,10,false,false);
   if bas.fuel>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Gas')  ,bas.fuel ,cur.fuel   , 4, 8,false,false);
   if bas.speed>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Spd')  ,bas.speed,cur.speed  , 6, 8,false,false);
   if bas.shoot>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Shot') ,bas.shoot,cur.shoot  ,10,14,false,false);
  end;
  if frm=2 then with st^ do begin
   if bas.hits>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Hits') ,bas.hits ,cur.hits  , 0, 8,false,false);
   if bas.ammo>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Ammo') ,bas.ammo ,cur.ammo  , 8,10,false,false);
   if matnum>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Raw')  ,matnum   ,matnow    , 2,10,false,false);
   if fuelnum>0   then dodrstats(s,dst,x,y,xs,ys,j,po('Fuel') ,fuelnum  ,fuelnow   , 4, 8,false,false);
   if gold>0      then dodrstats(s,dst,x,y,xs,ys,j,po('Gold') ,gold     ,goldnow   ,14,10,false,false);
   if bas.fuel>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Gas')  ,bas.fuel ,cur.fuel  , 4, 8,false,false);
   if bas.shoot>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Shot') ,bas.shoot,cur.shoot ,10,14,false,false);
   if store>0     then dodrstats(s,dst,x,y,xs,ys,j,po('Store'),store    ,storecnt  ,28, 8,false,false);
   if bas.speed>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Spd')  ,bas.speed,cur.speed , 6, 8,false,false);
  end;
  if frm=3 then with st^ do begin
   if bas.hits>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Hits') ,bas.hits ,cur.hits  , 0, 8,false,false);
   if store>0     then dodrstats(s,dst,x,y,xs,ys,j,po('Store'),store    ,storecnt  ,28, 8,false,false);
   if matnum>0    then dodrstats(s,dst,x,y,xs,ys,j,po('Raw')  ,matnum   ,matnow    , 2,10,false,false);
   if fuelnum>0   then dodrstats(s,dst,x,y,xs,ys,j,po('Fuel') ,fuelnum  ,fuelnow   , 4, 8,false,false);
   if gold>0      then dodrstats(s,dst,x,y,xs,ys,j,po('Gold') ,gold     ,goldnow   ,14,10,false,false);
   if store>0     then dodrstats(s,dst,x,y,xs,ys,j,po('Store'),store    ,storecnt  ,28, 8,false,false);
   if bas.ammo>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Ammo') ,bas.ammo ,cur.ammo  , 8,10,false,false);
   if bas.shoot>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Shot') ,bas.shoot,cur.shoot ,10,14,false,false);
   if bas.fuel>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Gas')  ,bas.fuel ,cur.fuel  , 4, 8,false,false);
  end;
 end;
 if full then with st^ do begin
  if bas.attk>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Attack'),bas.attk ,upd.attk ,20,10,false,true);
  if bas.shoot>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Shots') ,bas.shoot,upd.shoot,10,14,false,true);
  if bas.range>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Range') ,bas.range,upd.range,24,10,false,true);
  if bas.ammo>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Ammo')  ,bas.ammo ,upd.ammo , 8,10,false,true);
  if bas.armr>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Armor') ,bas.armr ,upd.armr ,16,10,false,true);
  if bas.hits>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Hits')  ,bas.hits ,upd.hits , 0,10,false,true);
  if bas.scan>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Scan')  ,bas.scan ,upd.scan ,18,14,false,true);
  if bas.speed>0 then dodrstats(s,dst,x,y,xs,ys,j,po('Speed') ,bas.speed,upd.speed, 6,10,false,true);
  if bas.fuel>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Gas')   ,bas.fuel ,upd.fuel , 4,10,false,true);
  if bas.cost>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Cost')  ,bas.cost ,upd.cost , 2+12*ord(buy),12,false,true,3);
  if bas.area>0  then dodrstats(s,dst,x,y,xs,ys,j,po('Area')  ,bas.area ,upd.area ,26,12,false,true);
 end;

 except stderr(s,'sdidraw_int','draw_stats_base');end;
end;
//############################################################################//
//Draw stats of units and in info/buy
procedure draw_stats_un(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer;u:ptypunits;full:boolean;frm:byte);
var st:mstt;
tp:integer;
begin try
 if s.cur_menu=MG_DEBUG then exit;
 if u=nil then exit;

 tp:=ord(full)+frm;
 if frm=2 then tp:=0;

 get_stats_un(s.the_game,u,@st,tp);
 draw_stats_base(s,dst,xh,yh,xh+xs,yh+ys,@st,full,false,frm);

 except stderr(s,'sdidraw_int','draw_stats_un');end;
end;
//############################################################################//
//Draw stats of units and in info/buy
procedure draw_stats_db(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer;ud:ptypunitsdb;rul:prulestyp;buy:boolean);
var st:mstt;
tp:integer;
begin try
 if s.cur_menu=MG_DEBUG then exit;
 if ud=nil then exit;

 tp:=2;
 if buy then tp:=4;

 get_stats_db(s.the_game,ud,@st,tp,rul);
 draw_stats_base(s,dst,xh,yh,xh+xs,yh+ys,@st,true,buy,1);

 except stderr(s,'sdidraw_int','draw_stats_db');end;
end;
//############################################################################//
//Draw stats of units and in info/buy
procedure draw_stats_ng(s:psdi_rec;dst:ptypspr;xh,yh,xs,ys:integer;ud:ptypunitsdb;rul:prulestyp;plr:pplayer_start_rec);
var st:mstt;
begin try
 if s.cur_menu=MG_DEBUG then exit;
 if ud=nil then exit;

 get_stats_ng(s.the_game,ud,@st,rul,plr);
 draw_stats_base(s,dst,xh,yh,xh+xs,yh+ys,@st,true,true,1);

 except stderr(s,'sdidraw_int','draw_stats_ng');end;
end;
//############################################################################//
procedure drut_clan_info(s:psdi_rec;dst:ptypspr;clan:ptypclansdb;xn,yn:integer);
var st:string;
unupd:typ_unupd;
ud:ptypunitsdb;
n,x,y,p,i,k:integer;
begin
 st:=clan.desc_eng;
 if lrus then st:=clan.desc_rus;
 wrtxt8(s.cg,dst,xn,yn,st,3);
 x:=0;
 p:=0;
 y:=0;

 for i:=0 to length(clan.unupd)-1 do begin
  unupd:=clan.unupd[i];
  n:=getdbnum(s.the_game,unupd.typ);
  if not unavdb(s.the_game,n) then continue;

  ud:=get_unitsdb(s.the_game,n);
  if lrus then st:=ud.name_rus+': ' else st:=ud.name_eng+': ';

  k:=unupd.bas.ammo;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Ammo');   end;
  k:=unupd.bas.scan;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Scan');   end;
  k:=unupd.bas.speed; if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Speed');  end;
  k:=unupd.bas.range; if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Range');  end;
  k:=unupd.bas.hits;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Hits');   end;
  k:=unupd.bas.armr;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Armor');  end;
  k:=unupd.bas.attk;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Attack'); end;
  k:=unupd.bas.shoot; if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Shots');  end;
  k:=unupd.bas.fuel;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Gas');    end;
  k:=unupd.bas.cost;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Cost');   end;
  k:=unupd.bas.area;  if k<>0 then begin if p=1 then st:=st+','; p:=1; if k>0 then st:=st+' +' else st:=st+' '; st:=st+stri(k)+' '+po('Area');   end;

  wrtxt8(s.cg,dst,xn+x,yn+11+y,st,4);
  y:=y+11;
 end;
end;
//############################################################################//
procedure drut_descr_box(s:psdi_rec;dst:ptypspr;u:ptypunits;x,y,xs,ys:integer);
var ud:ptypunitsdb;
begin
 ud:=get_unitsdb(s.the_game,u.dbn);
 if ud=nil then exit;

 tran_rect8(s.cg,dst,x-1,y-1,xs+2,ys+2,0);
 wrtxt8(s.cg,dst,x+5,y+5,unit_mk(u)+unit_name(s.the_game,u)+' '+base_mk(s.the_game,u),2);
 if lrus then wrtxtxbox8(s.cg,dst,x+5,y+20,xs-5,ys-20,ud.descr_rus,0)
         else wrtxtxbox8(s.cg,dst,x+5,y+20,xs-5,ys-20,ud.descr_eng,0);
end;
//############################################################################//
procedure drut_poster_box(s:psdi_rec;dst:ptypspr;u:ptypunits;x,y,xs,ys:integer);
var g:integer;
begin
 g:=u.grp_db;
 if g<>-1 then begin
  if s.eunitsdb[g]<>nil then begin
   putspr8(dst,@s.eunitsdb[g].img_poster.sprc[0],x,y);
  end else begin
   puttran8(s.cg,dst,x,y,xs,ys,0);
  end;
 end  else puttran8(s.cg,dst,x,y,xs,ys,0);
 drrectx8(dst,x-1,y-1,xs+2,ys+2,line_color);
end;
//############################################################################//
procedure drut_full_stats_box(s:psdi_rec;dst:ptypspr;u:ptypunits;x,y,xs,ys:integer);
begin
 tran_rect8(s.cg,dst,x-1,y-1,xs+2,ys+2,0);
 draw_stats_un(s,dst,x,y,xs,ys,u,true,0);
end;
//############################################################################//
//A vertical fill scroller, i.e. materials or gold in the buy/upgrade menu
procedure draw_material_bit(s:psdi_rec;dst:ptypspr;xn,yn:integer;var m:material_bit_rec);
var yh:integer;
cl:integer;
begin
 if m.show_zero then wrtxtcnt8(s.cg,dst,xn+m.xp+m.xs div 2,yn+m.yp-25,stri(m.cur),6);
 tran_rect8(s.cg,dst,xn+m.xp-1,yn+m.yp-1,m.xs+2,m.ys+2,0);
 if m.total<>0 then begin
  if not m.show_zero then wrtxtcnt8(s.cg,dst,xn+m.xp+m.xs div 2,yn+m.yp-25,stri(m.cur),6);
  yh:=round((m.cur/m.total)*m.ys);
  case m.kind of
   0:cl:=6;
   1:cl:=2;
   2:cl:=4;
  end;
  drfrectx8(dst,xn+m.xp,yn+m.yp+m.ys-yh,m.xs,yh,cl);
 end;
end;
//############################################################################//
procedure init_material_bit(out m:material_bit_rec;mn,pg:dword;xp,yp,xs,ys,kind,step:integer;name:string;show_zero,input:boolean;event:onevent_scroll;par:dword);
begin
 m.xp:=xp;
 m.yp:=yp;
 m.xs:=xs;
 m.ys:=ys;
 m.kind:=kind;
 m.step:=step;
 m.show_zero:=show_zero;
 m.input:=input;
 m.sc:=nil;

 m.ml:=add_label(mn,pg,xp+xs div 2,yp-15,LB_CENTER,7,name);
 if m.input then begin
  m.sc:=add_scrollbox(mn,pg,SCB_VERTICAL,m.xp+m.xs div 2-scroller_sz-elem_gap,
                                         m.yp+m.ys+5,
                                         m.xp+m.xs div 2+elem_gap,
                                         m.yp+m.ys+5,
                                         scroller_sz,scroller_sz,m.step,0,1000,true,@m.cur,event,par);
 end;
end;
//############################################################################//
procedure set_material_bit(var m:material_bit_rec;cur,total,kind:integer);
begin
 m.cur:=cur;
 m.total:=total;
 m.kind:=kind;

 if m.input then begin
  m.sc.bottom:=(m.total div m.step)*m.step;
  m.sc.top:=0;
  m.sc.a_dwn:=false;
  m.sc.b_dwn:=false;
 end;
end;
//############################################################################//
procedure vis_material_bit(var m:material_bit_rec;vis:boolean);
begin
 if m.ml<>nil then m.ml.vis:=vis;
 if m.sc<>nil then m.sc.vis:=vis;
end; 
//############################################################################//
procedure reloc_material_bit(var m:material_bit_rec;xp,yp,xs,ys:integer);
begin
 m.xp:=xp;
 m.yp:=yp;
 m.xs:=xs;
 m.ys:=ys;

 if m.ml<>nil then begin
  m.ml.x:=xp+xs div 2;
  m.ml.y:=yp-15;
 end;
 if m.sc<>nil then begin
  m.sc.xa:=m.xp+m.xs div 2-scroller_sz-elem_gap;
  m.sc.ya:=m.yp+m.ys+5;
  m.sc.xb:=m.xp+m.xs div 2+elem_gap;
  m.sc.yb:=m.yp+m.ys+5;
 end;
end;
//############################################################################//
function mouse_material_bit(var m:material_bit_rec;evt,x,y,dir:integer):boolean;
var i,j:integer;
begin
 result:=false;
 case evt of
  0:if inrects(x,y,m.xp,m.yp,m.xs,m.ys) then begin
   j:=y-m.yp-5;
   i:=(round(m.total*(1-j/(m.ys+5))) div m.step)*m.step;
   if j>m.ys-10 then i:=0;
   if j<3 then i:=m.total;
   m.cur:=i;
   result:=true;
  end;
  1:;
  2:if inrects(x,y,m.xp,m.yp,m.xs,m.ys) then begin m.cur:=m.cur-dir*m.step;result:=true;end;
 end;
end;
//############################################################################//
procedure draw_unit_list(s:psdi_rec;dst:ptypspr;xn,yn:integer;var z:unit_list_rec;plr_n:integer);
var i,xh,yh,xl,yl,j,txt_xp,txt_xs,cost_xp,cl:integer;
ud:ptypunitsdb;
en:ptypeunitsdb;
st:string;
begin
 tran_rect8(s.cg,dst,xn+z.xp-1,yn+z.yp-caption_ys-1,z.xs+2,z.ys+caption_ys+2,0);
 drline8(dst,xn+z.xp+elem_gap,yn+z.yp-caption_ys+12,xn+z.xp+z.xs-elem_gap-1,yn+z.yp-caption_ys+12,maxg_nearest_in_thepal(tcrgb(252,168,0)));
 for i:=0 to z.step-1 do if z.off+i<length(z.list) then begin
  xh:=xn+z.xp+2*elem_gap;
  yh:=yn+z.yp+list_elem_ys*i;
  xl:=xh+30;
  yl:=yh+30;
  txt_xp:=xh+list_elem_ys+elem_gap;
  txt_xs:=z.xs-list_elem_ys-2*elem_gap-list_cost_xs-elem_gap;
  cost_xp:=xn+z.xp+z.xs-2*elem_gap;
     
  if i<>0 then drline8(dst,xh,yh-1,xh+z.xs-4*elem_gap,yh-1,60);

  j:=z.list[z.off+i].dbn;
  ud:=get_unitsdb(s.the_game,j);
  en:=get_edb(s,ud.typ);

  if en<>nil then begin
   putsprtx8_uspr(s,dst,@en.spr_list,xh+list_elem_ys div 2,yh+list_elem_ys div 2,plr_n);
   st:='';
   if z.list[z.off+i].idx<>'' then st:=' '+z.list[z.off+i].idx;
   if lrus then wrtxtxbox8(s.cg,dst,txt_xp,yh-1,txt_xs,24,en.name_rus+st,text_color)
           else wrtxtxbox8(s.cg,dst,txt_xp,yh-1,txt_xs,24,en.name_eng+st,text_color);
  end;
  if z.list[z.off+i].par<>'' then  wrtxt8(s.cg,dst,txt_xp,yh+22,z.list[z.off+i].par,z.par_color);
  if z.show_cost then begin
   cl:=z.cost_color;
   if z.afford<z.list[z.off+i].cost then cl:=z.high_color;
   wrtxtr8(s.cg,dst,cost_xp,yh+10,stri(z.list[z.off+i].cost),cl);
  end;
  if z.off+i=z.sel then draw_unitframe(dst,xh-elem_gap,yh-elem_gap,xl,yl,255);
 end;
end;
//############################################################################//
procedure init_unit_list(out z:unit_list_rec;mn,pg:dword;xp,yp,xs,ys,step:integer;name:string;show_cost:boolean;cost_color,high_color,par_color:byte;event:onevent_scroll;par:dword);
begin
 z.xp:=xp;
 z.yp:=yp;
 z.xs:=xs;
 z.ys:=ys;
 z.step:=step;
 z.show_cost:=show_cost;
 z.cost_color:=cost_color;
 z.high_color:=high_color;
 z.par_color:=par_color;
 z.cs:=nil;

 z.ml:=add_label(mn,pg,xp+2*elem_gap,yp-caption_ys+1,LB_LEFT,text_color,name);
 if show_cost then z.cs:=add_label(mn,pg,xp+xs-2*elem_gap,yp-caption_ys+1,LB_RIGHT,6,po('Cost'));
 z.sc:=add_scrollbox(mn,pg,SCB_VERTICAL,z.xp,
                                        z.yp+z.ys+elem_gap,
                                        z.xp+scroller_sz+elem_gap,
                                        z.yp+z.ys+elem_gap,
                                        scroller_sz,scroller_sz,z.step,0,1000,false,@z.off,event,par);
 z.sca:=add_scrolarea(mn,pg,-1,z.xp,z.yp,z.xs,z.ys,1,32,0,1000,@z.off,event,par,z.sc);
end;
//############################################################################//
procedure set_unit_list(var z:unit_list_rec;sel,off,afford:integer);
begin
 z.sel:=sel;
 z.off:=off;
 z.afford:=afford;

 z.sc.bottom:=(length(z.list) div z.step)*z.step;
 if (length(z.list) mod z.step)=0 then z.sc.bottom:=z.sc.bottom-z.step;
 z.sc.top:=0;
 z.sc.a_dwn:=false;
 z.sc.b_dwn:=false;

 if z.cs<>nil then z.cs.vis:=z.show_cost;
end;
//############################################################################//
procedure vis_unit_list(var z:unit_list_rec;vis:boolean);
begin
 if z.sc<>nil then z.sc.vis:=vis;
 if z.cs<>nil then z.cs.vis:=vis;
 if z.ml<>nil then z.ml.vis:=vis;
end;  
//############################################################################//
procedure reloc_unit_list(var z:unit_list_rec;xp,yp,xs,ys,step:integer);
begin
 z.xp:=xp;
 z.yp:=yp;
 z.xs:=xs;
 z.ys:=ys;
 z.step:=step;

 if z.ml<>nil then begin
  z.ml.x:=xp+2*elem_gap;
  z.ml.y:=yp-caption_ys+1;
 end;
 if z.cs<>nil then begin
  z.cs.x:=xp+xs-2*elem_gap;
  z.cs.y:=yp-caption_ys+1;
 end;
 if z.sc<>nil then begin
  z.sc.xa:=z.xp;
  z.sc.ya:=z.yp+z.ys+elem_gap;
  z.sc.xb:=z.xp+scroller_sz+elem_gap;
  z.sc.yb:=z.yp+z.ys+elem_gap;
  z.sc.step:=z.step;

  z.sca.x:=z.xp;
  z.sca.y:=z.yp;
  z.sca.xs:=z.xs;
  z.sca.ys:=z.ys;
 end;
end;
//############################################################################//
function mouse_unit_list(s:psdi_rec;var z:unit_list_rec;evt,x,y,dir:integer;out double:boolean):boolean;
var i:integer;
begin
 result:=false;
 double:=false;
 case evt of
  0:for i:=0 to z.step-1 do if z.off+i<length(z.list) then if inrects(x,y,z.xp,z.yp+list_elem_ys*i,z.xs,list_elem_ys-1) then begin
   if z.off+i<>z.sel then begin
    snd_click(SND_TCK);
    z.sel:=z.off+i;
    s.msd_dt:=0;
   end else if s.msd_dt<doubleclick_time then begin
    snd_click(SND_BUTTON);
    double:=true;
   end;
   result:=true;
  end;
  1:;
  2:;
 end;
end;
//############################################################################//
procedure init_upgrade_block(out z:upgrade_block_rec;mn,pg:dword;xp,yp,step:integer;event:onevent_scroll;par:dword);
var i:integer;
begin
 z.xp:=xp;
 z.yp:=yp;
 z.step:=step;
   
 for i:=0 to length(z.scr)-1 do begin
  z.vl[i]:=0;
  z.scr[i]:=add_scrollbox(mn,pg,SCB_HORIZONTAL,xp,
                                               yp+step*i,
                                               xp+upg_scroller_sz+elem_gap,
                                               yp+step*i,
                                               upg_scroller_sz,upg_scroller_sz,1,0,100,false,@z.vl[i],event,par+i);
 end;
end;
//############################################################################//
procedure vis_upgrade_block(var z:upgrade_block_rec;c:integer;vis:boolean);
var i:integer;
begin
 if c>length(z.scr) then c:=length(z.scr);
 for i:=0 to c-1 do if z.scr[i]<>nil then z.scr[i].vis:=vis;
end;
//############################################################################//
begin
end.
//############################################################################//
