//############################################################################//    
unit mgl_common;
interface         
uses sysutils,asys,strval,maths,mgrecs;
//############################################################################//
const
//Pass map
P_INVALID =255;
//############################################################################//      
procedure msgu_set(s:string;c:byte=0;p:boolean=true);

function getdirbydp(ox,x,oy,y:integer):integer;

function inrm(g:pgametyp;x,y:integer):boolean;     
function get_map_pass(g:pgametyp;x,y:integer):byte;  
function get_map_x(g:pgametyp):integer;
function get_map_y(g:pgametyp):integer;
                                     
function get_rules(g:pgametyp):prulestyp;

function get_plr(g:pgametyp;n:integer):pplrtyp;  
function get_plr_count(g:pgametyp):integer;
function get_cur_plr(g:pgametyp):pplrtyp;    
function get_cur_plr_id(g:pgametyp):integer;
function get_next_plr(g:pgametyp):integer;   
   
function  is_landed(g:pgametyp;p:pplrtyp):boolean; 
procedure set_landed(g:pgametyp;p:pplrtyp); 
function  is_lost(g:pgametyp;p:pplrtyp):boolean;
procedure set_lost(g:pgametyp;p:pplrtyp);

function get_sel_unit(g:pgametyp):ptypunits;
function get_unu(g:pgametyp;x,y,n:integer):ptypunits;
function get_unu_qtr(g:pgametyp;x,y,n:integer):byte;
function get_unu_length(g:pgametyp;x,y:integer):integer;
function get_unit(g:pgametyp;n:integer):ptypunits;
function get_units_count(g:pgametyp):integer;    
 
function get_clans_count(g:pgametyp):integer;
function get_clan(g:pgametyp;n:integer):ptypclansdb;

function unavdb(g:pgametyp;i:integer):boolean;
function unav(g:pgametyp;i:integer):boolean;overload;
function unav(u:ptypunits):boolean;overload;
function unave(g:pgametyp;i:integer):boolean;

function cur_plr_unit(g:pgametyp;u:ptypunits):boolean;
function get_unitsdb(g:pgametyp;n:integer):ptypunitsdb;
function get_unitsdb_count(g:pgametyp):integer;    

function getdbnum(g:pgametyp;typ:string):integer;   
function gettypclan(g:pgametyp;p:integer;tp:string):integer;

function unit_mk(u:ptypunits):string;
function unit_name(g:pgametyp;u:ptypunits):string;
function base_mk(g:pgametyp;u:ptypunits;new_line:boolean=false):string;
function type_mk(g:pgametyp;t:integer;current_mk:integer=0;new_line:boolean=false):string;   

function rules_to_dword(r:prulestyp):dword;     
procedure dword_to_rules(r:prulestyp;f:dword); 
              
function unifeat_to_dword(u:ptypunits):dword;
procedure dword_to_unifeat(u:ptypunits;f:dword);
                                
procedure mark_log(g:pgametyp);
procedure mark_players(g:pgametyp);
procedure mark_unit(g:pgametyp;n:integer);
procedure add_sew(g:pgametyp;typ,ua,ub,n,x,y:integer); 
procedure add_sew_msg(g:pgametyp;typ,ua,ub,n,x,y:integer;msg:string);
procedure clear_marks(g:pgametyp);       

function po(inp:string):string;  
//############################################################################//
type
msgutyp=record
 p:boolean;
 c:byte;
 txt:string;
end;
//############################################################################//  
var
on_selection_changed:procedure(s:pointer;was,now:ptypunits)=nil;
menu_callback:procedure(s:pointer;n:dword)=nil;
on_unit_event:procedure(s:pointer;u:ptypunits;evt:integer)=nil;  

lang:array of array[0..1]of stringmg=nil;  //PO's
lrus:boolean=false;
leng:boolean=true; 
cur_lng:byte=0;
prv_lng:byte=0;                  //Current lang, previous lang

msgu:msgutyp;        //The transparent message
//############################################################################//  
implementation
//############################################################################//  
procedure msgu_set(s:string;c:byte=0;p:boolean=true);
begin
 //if color changed - replace old messages
 if msgu.c=c then msgu.txt:=msgu.txt+'&'+s
             else msgu.txt:=s;
 msgu.c:=c;
 msgu.p:=p;
end;
//############################################################################//
//Dir by diff
function getdirbydp(ox,x,oy,y:integer):integer;
const rt:array[0..8]of integer=(7,0,1,6,0,2,5,4,3);
var dx,dy:integer;
begin
 if inrect(ox,oy,x-1,y-1,x+1,y+1) then begin
  result:=rt[(sgna(oy-y)+1)*3+(sgna(ox-x)+1)]
 end else begin
  result:=0;
  dx:=ox-x;
  dy:=oy-y;
  if (dx>=0)and(dy>=0)then begin
        if(dx<dy div 2)then result:=4
   else if(dy<dx div 2)then result:=2
                       else result:=3;
  end else if (dx<0)and(dy>=0)then begin
        if(-dx<dy div 2)then result:=4
   else if(dy<-dx div 2)then result:=6
                        else result:=5;
  end else if (dx<0)and(dy<0)then begin
        if(-dx<-dy div 2)then result:=0
   else if(-dy<-dx div 2)then result:=6
                         else result:=7;
  end else if (dx>=0)and(dy<0)then begin
        if(dx<-dy div 2)then result:=0
   else if(-dy<dx div 2)then result:=2
                        else result:=1;
  end;
 end;
end;
//############################################################################//
function get_rules(g:pgametyp):prulestyp;
begin
 result:=@g.info.rules;
end;
//############################################################################//
//In the map
function inrm(g:pgametyp;x,y:integer):boolean;
begin 
 result:=(x>=0)and(x<=g.info.mapx-1)and(y>=0)and(y<=g.info.mapy-1);
end;    
//############################################################################//
function get_map_x(g:pgametyp):integer;
begin
 result:=g.info.mapx;
end;
//############################################################################//
function get_map_y(g:pgametyp):integer;
begin
 result:=g.info.mapy;
end;
//############################################################################//
function get_map_pass(g:pgametyp;x,y:integer):byte;
begin
 result:=P_INVALID;
 if inrm(g,x,y) then result:=g.passm[y*g.info.mapx+x];
end;
//############################################################################//
function get_plr(g:pgametyp;n:integer):pplrtyp;
begin
 result:=@g.plr[n];     
end;          
//############################################################################//
function get_plr_count(g:pgametyp):integer;
begin
 result:=g.info.plr_cnt;     
end;
//############################################################################//
function get_cur_plr(g:pgametyp):pplrtyp;
begin
 result:=nil;
 if g=nil then exit;
 result:=get_plr(g,g.state.cur_plr);     
end;   
//############################################################################//
function get_cur_plr_id(g:pgametyp):integer;
begin
 result:=g.state.cur_plr;     
end;   
//############################################################################//
//Next player
//FIXME: Next turn detector needed
function get_next_plr(g:pgametyp):integer;
begin
 result:=(g.state.cur_plr+1)mod get_plr_count(g);
 while result<>g.state.cur_plr do if is_lost(g,@g.plr[result]) then result:=(result+1)mod get_plr_count(g) else break;
end;        
//############################################################################//
function is_landed(g:pgametyp;p:pplrtyp):boolean;
begin
 result:=g.state.landed[p.num];     
end;     
//############################################################################//
procedure set_landed(g:pgametyp;p:pplrtyp);
begin
 g.state.landed[p.num]:=true;
end;         
//############################################################################//
function is_lost(g:pgametyp;p:pplrtyp):boolean;
begin
 result:=g.state.lost[p.num];     
end;     
//############################################################################//
procedure set_lost(g:pgametyp;p:pplrtyp);
begin
 g.state.lost[p.num]:=true;
end;     
//############################################################################//
function get_sel_unit(g:pgametyp):ptypunits;
var pl:pplrtyp;
sn:integer;
begin
 result:=nil;
 pl:=get_cur_plr(g);
 if pl=nil then exit;
 sn:=pl.selunit;
 if sn=-1 then exit;
 result:=get_unit(g,sn);    
end;
//############################################################################//
function get_unu(g:pgametyp;x,y,n:integer):ptypunits;
begin
 result:=nil;
 if not inrm(g,x,y) then exit;
 if n>=length(g.unu[x,y]) then exit;
 result:=g.unu[x,y,n].u;   
end;
//############################################################################//
function get_unu_qtr(g:pgametyp;x,y,n:integer):byte;
begin
 result:=0;
 if not inrm(g,x,y) then exit;
 if n>=length(g.unu[x,y]) then exit;
 result:=g.unu[x,y,n].qtr;   
end;         
//############################################################################//
function get_unu_length(g:pgametyp;x,y:integer):integer;
begin
 result:=0;
 if not inrm(g,x,y) then exit;
 result:=length(g.unu[x,y]);   
end;      
//############################################################################//
function get_unit(g:pgametyp;n:integer):ptypunits;
begin
 result:=nil;
 if n<0 then exit;
 if n>=length(g.units) then exit;
 result:=g.units[n];   
end; 
//############################################################################//
function get_units_count(g:pgametyp):integer;
begin
 result:=length(g.units);   
end; 
//############################################################################//
function get_clans_count(g:pgametyp):integer;
begin
 result:=length(g.clansdb);
end;
//############################################################################//
function get_clan(g:pgametyp;n:integer):ptypclansdb;
begin
 result:=nil;
 if n<0 then exit;
 if n>=get_clans_count(g) then exit;
 result:=@g.clansdb[n]
end;
//############################################################################//
//############################################################################//
function unavdb(g:pgametyp;i:integer):boolean;
begin
 result:=(i>-1)and(i<length(g.unitsdb));
end;
//############################################################################//
function unav(g:pgametyp;i:integer):boolean;overload;
var u:ptypunits;
begin
 result:=false;
 u:=get_unit(g,i); 
 if u=nil then exit;
 result:=not u.stored;
end;      
//############################################################################//   
function unav(u:ptypunits):boolean;overload;
begin
 result:=false;
 if u=nil then exit;
 result:=not u.stored;
end;
//############################################################################//
function unave(g:pgametyp;i:integer):boolean;
var u:ptypunits;
begin
 u:=get_unit(g,i);
 result:=u<>nil;
end;   
//############################################################################//
function cur_plr_unit(g:pgametyp;u:ptypunits):boolean;
begin
 result:=false;
 if u=nil then exit;
 result:=u.own=g.state.cur_plr
end;   
//############################################################################//
function get_unitsdb(g:pgametyp;n:integer):ptypunitsdb;
begin
 result:=nil;
 if not unavdb(g,n) then exit;
 result:=@g.unitsdb[n];
end;
//############################################################################//
function get_unitsdb_count(g:pgametyp):integer;
begin
 result:=length(g.unitsdb);
end;       
//############################################################################//
//Find unit type typ in DB
function getdbnum(g:pgametyp;typ:string):integer;
var i:integer;
ud:ptypunitsdb;
begin
 result:=-1;
 for i:=0 to get_unitsdb_count(g)-1 do begin
  ud:=get_unitsdb(g,i);
  if ud=nil then continue;
  if trim(ud.typ)=trim(typ) then begin result:=i; exit; end;    
 end;
end;                  
//############################################################################//
//Get unitdb clan upds
function gettypclan(g:pgametyp;p:integer;tp:string):integer;
var k:integer;
pl:pplrtyp;
begin
 result:=-1;
 pl:=get_plr(g,p);
 if pl=nil then exit;
 for k:=0 to length(g.clansdb[pl.info.clan].unupd)-1 do if g.clansdb[pl.info.clan].unupd[k].typ=tp then begin
  result:=k;
  exit;
 end;
end;
//############################################################################//
function unit_mk(u:ptypunits):string;
begin
 result:='Mk '+strlat(u.mk+1)+' ';
end;
//############################################################################//
function unit_name(g:pgametyp;u:ptypunits):string;
var ud:ptypunitsdb;
begin
 ud:=get_unitsdb(g,u.dbn);
 if u.name<>'' then result:=u.name else begin
  if lrus then result:=ud.name_rus else result:=ud.name_eng;
 end;
 result:=result+' '+stri(u.nm);
end;  
//############################################################################//
function base_mk(g:pgametyp;u:ptypunits;new_line:boolean=false):string;
var cp:pplrtyp;
begin
 cp:=get_cur_plr(g);
 if(u.own=cp.num) then result:=type_mk(g,u.dbn,u.mk,new_line)
                  else result:='';
end;
//############################################################################//
function type_mk(g:pgametyp;t:integer;current_mk:integer=0;new_line:boolean=false):string;
var cp:pplrtyp;
begin
 cp:=get_cur_plr(g);
 if cp.unupd[t].mk<>current_mk then begin
  result:='( Mk '+strlat(cp.unupd[t].mk+1)+' )';
  if new_line then result:='&'+result;
 end else result:=''; 
end;      
//############################################################################//  
//############################################################################//
function rules_to_dword(r:prulestyp):dword;
begin
 result:=             
 (ord(r.debug) shl 0)or
 (ord(r.fueluse) shl 1)or
 (ord(r.fuelxfer) shl 2)or
 (ord(r.unload_all_shots) shl 3)or
 (ord(r.unload_all_speed) shl 4)or
 (ord(r.unload_one_speed) shl 5)or
 (ord(r.load_sub_one_speed) shl 6)or
 (ord(r.load_onpad_only) shl 7)or
 (ord(r.startradar) shl 8)or
 (ord(r.no_survey) shl 9)or
 (ord(r.direct_land) shl 10)or
 (ord(r.nopaswds) shl 11)or
 (ord(r.fuel_shot) shl 12)or
 (ord(r.no_buy_atk) shl 13)or
 (ord(r.expensive_refuel) shl 14)or
 (ord(r.center_4x_scan) shl 15)or
 (ord(r.direct_gold) shl 16)or
 (ord(r.lay_connectors) shl 17);
end;
//############################################################################//
procedure dword_to_rules(r:prulestyp;f:dword);
begin
 r.debug:=(f and $0001)<>0;
 r.fueluse:=(f and $0002)<>0;
 r.fuelxfer:=(f and $0004)<>0;
 r.unload_all_shots:=(f and $0008)<>0;
 r.unload_all_speed:=(f and $0010)<>0;
 r.unload_one_speed:=(f and $0020)<>0;
 r.load_sub_one_speed:=(f and $0040)<>0;
 r.load_onpad_only:=(f and $0080)<>0;
 r.startradar:=(f and $0100)<>0;
 r.no_survey:=(f and $0200)<>0;
 r.direct_land:=(f and $0400)<>0;
 r.nopaswds:=(f and $0800)<>0;
 r.fuel_shot:=(f and $1000)<>0;
 r.no_buy_atk:=(f and $2000)<>0;
 r.expensive_refuel:=(f and $4000)<>0;
 r.center_4x_scan:=(f and $8000)<>0;
 r.direct_gold:=(f and $10000)<>0;
 r.lay_connectors:=(f and $20000)<>0;
end; 
//############################################################################//
function unifeat_to_dword(u:ptypunits):dword;
begin
 result:=    
 (ord(u.is_unselectable) shl 0)or
 (ord(u.is_sentry) shl 1)or
 (ord(u.is_moving) shl 2)or
 (ord(u.is_moving_build) shl 3)or
 (ord(u.is_moving_now) shl 4)or
 (ord(u.isact) shl 5)or
 (ord(u.strtmov) shl 6)or
 (ord(u.stpmov) shl 7)or
 (ord(u.stlmov) shl 8)or
 //(ord(u.isboom) shl 9)or
 (ord(u.isstd) shl 10)or
 //(ord(u.isauto) shl 11)or
 (ord(u.isclrg) shl 12)or
 (ord(u.stored) shl 13)or
 (ord(u.isbuild) shl 14)or
 (ord(u.isbuildfin) shl 15)or
 //(ord(u.isinlnd) shl 16)or
 (ord(u.is_bomb_placing) shl 17)or
 (ord(u.is_bomb_removing) shl 18);
end;       
//############################################################################//
procedure dword_to_unifeat(u:ptypunits;f:dword);
begin
 u.is_unselectable:=(f and $0001)<>0;
 u.is_sentry:=(f and $0002)<>0;
 u.is_moving:=(f and $0004)<>0;  
 u.is_moving_build:=(f and $0008)<>0;
 u.is_moving_now:=(f and $0010)<>0; 
 u.isact:=(f and $0020)<>0;    
 u.strtmov:=(f and $0040)<>0;
 u.stpmov:=(f and $0080)<>0;
 u.stlmov:=(f and $0100)<>0;
 //u.isboom:=(f and $0200)<>0;  
 u.isstd:=(f and $0400)<>0;
 //u.isauto:=(f and $0800)<>0;
 u.isclrg:=(f and $1000)<>0;   
 u.stored:=(f and $2000)<>0;
 u.isbuild:=(f and $4000)<>0;
 u.isbuildfin:=(f and $8000)<>0;
 //u.isinlnd:=(f and $10000)<>0;
 u.is_bomb_placing:=(f and $20000)<>0;
 u.is_bomb_removing:=(f and $40000)<>0;
end;
//############################################################################//   
procedure mark_players(g:pgametyp);
begin
 if g=nil then exit;
 g.plr_event:=true;
end;
//############################################################################//
procedure mark_log(g:pgametyp);
begin
 if g=nil then exit;
 g.log_event:=true;
end;
//############################################################################//   
procedure mark_unit(g:pgametyp;n:integer);
var k,i:integer;
begin
 if g=nil then exit;
 if(n<0)or(n>=length(g.units))then exit;
 
 k:=length(g.marks);
 if n>=k then begin
  setlength(g.marks,n+1);
  //for i:=k to n do g.marks[i]:=true;   //Overtraffic on reload. Shouldn't be a problem anyway.
  for i:=k to n do g.marks[i]:=false;
 end;
 g.marks[n]:=true;
end;
//############################################################################//   
procedure add_sew(g:pgametyp;typ,ua,ub,n,x,y:integer);
var k:integer;
begin
 if g=nil then exit;
 k:=g.sew_cnt;
 if k>=length(g.sews) then exit;
 g.sew_cnt:=g.sew_cnt+1;
 
 g.sews[k].typ:=typ;
 g.sews[k].ua:=ua;
 g.sews[k].ub:=ub;
 g.sews[k].n:=n;
 g.sews[k].x:=x;
 g.sews[k].y:=y;
 g.sews[k].msg:='';
end;
//############################################################################//   
procedure add_sew_msg(g:pgametyp;typ,ua,ub,n,x,y:integer;msg:string);
var k:integer;
begin
 if g=nil then exit;
 k:=g.sew_cnt;
 if k>=length(g.sews) then exit;
 g.sew_cnt:=g.sew_cnt+1;
 
 g.sews[k].typ:=typ;
 g.sews[k].ua:=ua;
 g.sews[k].ub:=ub;
 g.sews[k].n:=n;
 g.sews[k].x:=x;
 g.sews[k].y:=y;
 g.sews[k].msg:=msg;
end;
//############################################################################//   
procedure clear_marks(g:pgametyp);            
var i:integer;
begin
 for i:=0 to length(g.marks)-1 do g.marks[i]:=false;    
 g.sew_cnt:=0;
 g.plr_event:=false;
 g.log_event:=false;
end;     
//############################################################################//
function po(inp:string):string;
var i,n,d,k:integer;
begin
 result:=inp;  
 inp:=lowercase(inp);

 n:=length(lang)-1;
 i:=n div 2;  
 d:=0;
 while lang[i][0]<>inp do begin
  if n=d then exit;
  if n-d=1 then begin
   if lang[i][0]=inp then break;  
   if lang[n][0]=inp then begin i:=n;break;end;
   exit;
  end;  
  k:=(n-d)div 2+d;
  if inp<lang[i][0] then n:=k else d:=k;
  i:=(n-d)div 2+d;
 end;
 result:=lang[i][1];
end; 
//############################################################################//   
begin
end.
//############################################################################//    
