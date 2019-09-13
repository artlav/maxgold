//############################################################################//
unit sdiauxi;
interface
uses {$ifdef mswindows}windows,{$endif}sysutils,asys,grph,vfsint,bmp,sdisdl,graph8,log
{$ifdef update},upd_cli{$endif}
,mgrecs,mgl_common,sdirecs
{$ifdef android},and_log{$endif}
;
//############################################################################//
var 
img_mainloop:procedure(ct,dt:double); 
savsetup:procedure(s:psdi_rec);
iresetgui:procedure(s:psdi_rec);
//############################################################################//
procedure tolog(devnam,inp:string); 
procedure mbox(s:psdi_rec;st,c:string);
procedure stderr(s:psdi_rec;dev,proc:string);
procedure stderr2(s:psdi_rec;dev,proc,dsc:string);
procedure resetprog(s:psdi_rec;t:integer);
procedure haltprog;

function get_map_by_name(s:psdi_rec;nm:string):integer;
function get_player_color8(s:psdi_rec;own:integer):byte;
function get_grid_color8(s:psdi_rec):byte;
function get_player_palpx(s:psdi_rec;own:integer):pointer;   
procedure putsprtx8_uspr(s:psdi_rec;dst:ptypspr;uspr:ptypuspr;xn,yn:integer;own:integer=-1);

procedure clear_load_box(s:psdi_rec);                       
procedure set_load_box_caption(s:psdi_rec;name:string);
procedure write_load_box(s:psdi_rec;inp:string); 
procedure set_load_bar_pos(s:psdi_rec;pos:single);

procedure clean_to_menu(s:psdi_rec;mn:integer);  
 
function get_edb(s:psdi_rec;typ:string):ptypeunitsdb;

procedure event_map_reposition(s:psdi_rec);  
procedure event_units(s:psdi_rec);  
procedure event_minimap(s:psdi_rec);
procedure event_map_scroll(s:psdi_rec);    
procedure event_frame_map(s:psdi_rec);
procedure event_frame(s:psdi_rec);

function any_anim_units(s:psdi_rec):boolean;
function add_anim_unit(s:psdi_rec):panim_unit_typ; 
procedure clear_anim_units(s:psdi_rec);
procedure clear_evented_units(s:psdi_rec);

function get_moving_unit(s:psdi_rec):ptypunits; 
function unit_in_lock(s:psdi_rec;u:ptypunits):boolean; 
procedure toggle_unit_in_lock(s:psdi_rec;u:ptypunits);
//############################################################################//
implementation
//############################################################################//
//############################################################################//  
//############################################################################//
{$ifdef android}
function trims(s:string;n:integer):string;
begin
 result:=s;
 while length(result)<n do result:=result+' ';
end;
{$endif}
//############################################################################//
procedure tolog(devnam,inp:string);
{$ifdef android}var s:string;{$endif}
begin
 {$ifdef android}
 s:=DateToStr(date)+'-'+TimeToStr(time)+':['+trims(devnam,10)+']:'+inp;
 android_log_write(ANDROID_LOG_INFO,'MAXGold',pchar(s));
 {$endif}
 wr_log(devnam,inp);
end;
//############################################################################//
procedure mbox(s:psdi_rec;st,c:string);
begin
 s.mbox_on:=true;
 s.mbox_nam:=c;
 s.mbox_msg:=st;
 tolog(c,' '+st);
end;
//############################################################################//
procedure stderr(s:psdi_rec;dev,proc:string);
begin       
 tolog(dev,po('stderr')+' '+proc);
 mbox(s,dev+': '+po('stderr')+' '+proc,po('err'));
 savescreen8(mgrootdir+'crash.bmp');    
 halt;
end;
//############################################################################//
procedure stderr2(s:psdi_rec;dev,proc,dsc:string);
begin
 tolog(dev,po('stderr')+' '+proc+': '+dsc);
 mbox(s,dev+': '+po('stderr')+' '+proc+': '+dsc,po('err'));
 savescreen8(mgrootdir+'error.bmp');
 //halt;
end;
//############################################################################//
procedure resetprog(s:psdi_rec;t:integer);
begin try 
 sdisdlquit;
 tolog('SDI','Graphics closed.');
 savsetup(s);
 {$ifdef update}upd_resetprog(t<>0);{$endif}
 halt;
 
 except stderr(s,'SDI','ResetProg');halt;end;
end;
//############################################################################//
procedure haltprog;
begin 
 halting:=true;
 {$ifdef android}sleep(1000);pdword(0)^:=123;{$endif}
 {$ifdef unix}halt;{$endif}
end;   
//############################################################################//
procedure clear_load_box(s:psdi_rec);
var i:integer;
begin
 for i:=1 to LD_CNT-1 do s.load_box_str[i]:=''; 
 s.load_bar_pos:=0;
end;
//############################################################################//
procedure write_load_box(s:psdi_rec;inp:string);
var i:integer;
begin
 for i:=1 to LD_CNT-2 do s.load_box_str[i]:=s.load_box_str[i+1];
 s.load_box_str[LD_CNT-1]:=inp;
 tolog('SDIInit',inp);
end;
//############################################################################//
procedure set_load_box_caption(s:psdi_rec;name:string);begin s.load_box_str[0]:=name;end;
procedure set_load_bar_pos(s:psdi_rec;pos:single);begin s.load_bar_pos:=pos;end;
//############################################################################//
procedure clean_to_menu(s:psdi_rec;mn:integer);
begin    
 s.cur_menu:=mn; 
 s.now_loading:=false;
 s.ng_map_id:=get_map_by_name(s,s.newgame.map_name);
 if s.ng_map_id=-1 then s.ng_map_id:=0;
 clear_load_box(s);
end;        
//############################################################################//
function get_map_by_name(s:psdi_rec;nm:string):integer;
var i:integer;
begin
 result:=-1;
 for i:=0 to length(s.map_list)-1 do if trim(lowercase(s.map_list[i].file_name))=trim(lowercase(nm)) then begin result:=i; break; end;
end;   
//############################################################################//
function get_grid_color8(s:psdi_rec):byte;
begin
 result:=s.clinfo.custom_color8[0];
end;
//############################################################################//
function get_player_color8(s:psdi_rec;own:integer):byte;
begin
 if(own>=0)and(own<get_plr_count(s.the_game))then result:=s.clinfo.custom_color8[own+1]
                                             else result:=4; //default color for unknown owner
end;
//############################################################################//
function get_player_palpx(s:psdi_rec;own:integer):pointer;
begin
 if(own>=0)and(own<get_plr_count(s.the_game))then result:=@s.colors.palpx[own]
                                             else result:=@s.colors.al_palpx;
end;     
//############################################################################//
//Sprite draw utility functions
procedure putsprtx8_uspr(s:psdi_rec;dst:ptypspr;uspr:ptypuspr;xn,yn:integer;own:integer=-1);
var i:integer;
spr:ptypspr;
palx:ppalxtyp;
begin
 palx:=get_player_palpx(s,own);
 for i:=0 to uspr.cnt-1 do begin
  spr:=@uspr.sprc[i];
  if s<>nil then putsprtx8(dst,spr,xn-spr.cx,yn-spr.cy,palx);
 end;
end;  
//############################################################################//
//Find unit type typ in eDB
function get_edb(s:psdi_rec;typ:string):ptypeunitsdb;
var i:integer;
begin
 result:=nil;
 for i:=0 to length(s.eunitsdb)-1 do if s.eunitsdb[i]<>nil then if s.eunitsdb[i].typ=typ then begin result:=s.eunitsdb[i]; exit; end;
end;  
//############################################################################//
procedure event_map_reposition(s:psdi_rec);
begin
 s.map_event:=true;
 s.ut_event:=true;
 s.unev:=true;
end; 
//############################################################################//
procedure event_map_scroll(s:psdi_rec);
begin
 s.map_scroll_ev:=true;
end; 
//############################################################################//
procedure event_units(s:psdi_rec);
begin
 s.unev:=true;
 s.minimap_event:=true;
end;
//############################################################################//
procedure event_minimap(s:psdi_rec);
begin
 s.minimap_event:=true;
end; 
//############################################################################//
procedure event_frame_map(s:psdi_rec);
begin
 s.frame_map_ev:=true;
 s.frame_mmap_ev:=true;
end; 
//############################################################################//
procedure event_frame(s:psdi_rec);
begin
 event_frame_map(s);  
 s.frameev:=true;
 s.minimap_event:=true;
end;         
//############################################################################//
function any_anim_units(s:psdi_rec):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to length(s.anim_units)-1 do if s.anim_units[i].used then begin result:=true;exit;end;
end;
//############################################################################//
function add_anim_unit(s:psdi_rec):panim_unit_typ;
var i,c:integer;
begin
 result:=nil;
 c:=-1;
 for i:=0 to length(s.anim_units)-1 do if not s.anim_units[i].used then begin c:=i;break;end;
 if c=-1 then exit;

 result:=@s.anim_units[c];
end;
//############################################################################//
procedure clear_anim_units(s:psdi_rec);
var i:integer;
begin
 for i:=0 to length(s.anim_units)-1 do s.anim_units[i].used:=false;
end;
//############################################################################//
procedure clear_evented_units(s:psdi_rec);
var i:integer;
u:ptypunits;
begin
 for i:=0 to get_units_count(s.the_game)-1 do begin
  u:=get_unit(s.the_game,i);
  if unav(u) then begin
   u.move_anim:=false;
   u.fires:=false;
  end;
 end;
end;
//############################################################################//
function get_moving_unit(s:psdi_rec):ptypunits;
var i:integer;
u:ptypunits;
begin
 result:=nil;
 for i:=0 to get_units_count(s.the_game)-1 do begin
  u:=get_unit(s.the_game,i);
  if unav(u) then if u.move_anim then begin result:=u;exit;end;
 end;
end;
//############################################################################//
function unit_in_lock(s:psdi_rec;u:ptypunits):boolean;
var i:integer;
begin
 result:=false;
 for i:=0 to length(s.clinfo.locked_uids)-1 do if s.clinfo.locked_uids[i]=u.uid then begin result:=true;exit;end;
end;
//############################################################################//
procedure toggle_unit_in_lock(s:psdi_rec;u:ptypunits);
var i,n:integer;
begin
 n:=-1;
 for i:=0 to length(s.clinfo.locked_uids)-1 do if s.clinfo.locked_uids[i]=u.uid then begin
  n:=i;
  break;
 end;

 if n<>-1 then begin
  for i:=n to length(s.clinfo.locked_uids)-2 do s.clinfo.locked_uids[i]:=s.clinfo.locked_uids[i+1];
  n:=length(s.clinfo.locked_uids);
  setlength(s.clinfo.locked_uids,n-1);
 end else begin
  n:=length(s.clinfo.locked_uids);
  setlength(s.clinfo.locked_uids,n+1);
  s.clinfo.locked_uids[n]:=u.uid
 end;
end;
//############################################################################//
begin
end.
//############################################################################//
