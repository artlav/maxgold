//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold loggings and messages
//############################################################################//
unit mgl_logs;
interface
uses strval,mgrecs,mgl_common;                                                                          
//############################################################################//
const
res_names:array[0..RS_COUNT-1]of string=('Attack','Shots','Range','Armor','Hits','Speed','Scan','Cost');
//res_ids:array[RES_MIN..RES_MAX]of string=('Materials','Fuel','Gold','Power','Man');
//############################################################################//
//Log messages types
lmt_endturn             =1;
lmt_build_completed     =2;
lmt_research_completed  =3;
lmt_no_resources        =4;   // msgu_set(g,'( '+stri(u.x)+','+stri(u.y)+') stopped for lack of '+res_ids[rtyp]);
lmt_unit_under_attack   =5;
lmt_unit_disabled       =6;
lmt_unit_stolen         =7;
lmt_enemy_unit_spoted   =8;
lmt_enemy_unit_hiden    =9;
lmt_enemy_unit_moved    =10;
lmt_aircrash            =11;
lmt_player_lost         =12;
lmt_unit_destroyed      =13;
lmt_unit_upgraded       =14;  // msgu_set(g,'Upgraded '+unit_name(g,u)+' to '+'Mk '+strlat(u.mk+1));
lmt_unit_upgrade_fail   =15;  // msgu_set(g,'Failed (lack of materials) to upgrade '+unit_name(g,u)+' to '+'Mk '+strlat(u.mk+1));
lmt_build_no_materials  =16;  // msgu_set(g,'('+stri(u.x)+','+stri(u.y)+') cannot start for lack of materials');
lmt_stop_need_materials =17;  // msgu_set(g,'Can not be stoped. Provides '+s1+'.');
lmt_start_no_materials  =18;  // msgu_set(g,'Not enough '+s1+'.');
//############################################################################//
procedure add_comment(g:pgametyp;pl:pplrtyp;x,y:integer;s:string);
procedure add_log_msg(g:pgametyp;whom:integer;mtp:byte;x1,y1:integer;mdbn1:integer=-1;mown1:integer=-1;mkind1:integer=-1;mtag1:integer=-1;x2:integer=-1;y2:integer=-1;mdbn2:integer=-1;mown2:integer=-1;mkind2:integer=-1;mtag2:integer=-1;muid1:integer=0;muid2:integer=0);
procedure add_log_msgu(g:pgametyp;whom:integer;mtp:byte;u1:ptypunits;u2:ptypunits=nil;mkind:integer=-1;mtag:integer=-1);
procedure add_log_msgself(g:pgametyp;mtp:byte;mtag:integer=-1);
procedure add_log_msgselfu(g:pgametyp;whom:integer;mtp:byte;u1,u2:ptypunits);     
function string_log_msg(g:pgametyp;lm:plogmsgtyp):string;  
//############################################################################//
implementation  
//############################################################################//
procedure add_one_comment(g:pgametyp;pl:pplrtyp;x,y:integer;s:string);
var c:pcomment_typ;
n,j:integer;
begin
 if pl=nil then exit;
      
 n:=-1;
 if(x<>-1)and(y<>-1)then for j:=0 to length(pl.comments)-1 do if(pl.comments[j].typ=1)and(pl.comments[j].x=x)and(pl.comments[j].y=y)then begin 
  n:=j;    
  if s='' then begin
   pl.comments[j].typ:=255;
   exit;
  end;
  break;
 end;
 
 if n=-1 then begin
  for j:=0 to length(pl.comments)-1 do if pl.comments[j].typ=255 then begin n:=j;break;end;
  if n=-1 then begin
   n:=length(pl.comments); 
   setlength(pl.comments,n+1);
  end;
 end;
 c:=@pl.comments[n];
 if(x=-1)and(y=-1)then c.typ:=0 else c.typ:=1;
 c.x:=x;
 c.y:=y;
 c.turn:=g.state.turn;
 c.text:=s;
end; 
//############################################################################//
procedure add_comment(g:pgametyp;pl:pplrtyp;x,y:integer;s:string);
var j:integer;
begin
 if pl=nil then for j:=0 to get_plr_count(g)-1 do add_one_comment(g,get_plr(g,j),x,y,s) else add_one_comment(g,pl,x,y,s);
end; 
//############################################################################//
procedure add_log_msg(g:pgametyp;whom:integer;mtp:byte;x1,y1:integer;mdbn1:integer=-1;mown1:integer=-1;mkind1:integer=-1;mtag1:integer=-1;x2:integer=-1;y2:integer=-1;mdbn2:integer=-1;mown2:integer=-1;mkind2:integer=-1;mtag2:integer=-1;muid1:integer=0;muid2:integer=0);
var pl:pplrtyp;
l:integer;
m:plogmsgtyp;
begin         
 pl:=get_plr(g,whom);
 if pl=nil then exit;
 
 l:=length(pl.logmsg);
 setlength(pl.logmsg,l+1);
 m:=@pl.logmsg[l];
 m.own:=whom;
 m.tp:=mtp;
 m.data[0].x:=x1;
 m.data[0].y:=y1;
 m.data[0].dbn:=mdbn1;
 m.data[0].uid:=muid1;
 m.data[0].own:=mown1;
 m.data[0].kind:=mkind1;
 m.data[0].tag:=mtag1;
 m.data[1].x:=x2;
 m.data[1].y:=y2;
 m.data[1].dbn:=mdbn2;
 m.data[1].uid:=muid2;
 m.data[1].own:=mown2;
 m.data[1].kind:=mkind2;
 m.data[1].tag:=mtag2;  
  
 mark_log(g);
end;
//############################################################################//   
//need to check u1 and u2 visibility for player whom and set coordinates to -1 accordintly
procedure add_log_msgu(g:pgametyp;whom:integer;mtp:byte;u1:ptypunits;u2:ptypunits=nil;mkind:integer=-1;mtag:integer=-1);
begin
 if u2=nil then add_log_msg(g,whom,mtp,u1.x,u1.y,u1.dbn,u1.own,mkind,mtag,-1,-1,-1,-1,-1,-1,u1.uid,0)
           else add_log_msg(g,whom,mtp,u1.x,u1.y,u1.dbn,u1.own,mkind,mtag,u2.x,u2.y,u2.dbn,u2.own,-1,-1,u1.uid,u2.uid);
end;
//############################################################################//
procedure add_log_msgselfu(g:pgametyp;whom:integer;mtp:byte;u1,u2:ptypunits);
var pl:pplrtyp;
begin
 pl:=get_cur_plr(g);
 add_log_msgu(g,pl.num,mtp,u1,u2);
end;
//############################################################################//
procedure add_log_msgself(g:pgametyp;mtp:byte;mtag:integer=-1);
var pl:pplrtyp;
begin
 pl:=get_cur_plr(g);
 add_log_msg(g,pl.num,mtp,pl.info.lndx,pl.info.lndy,-1,-1,-1,mtag);
end;  
//############################################################################//
function string_log_msg(g:pgametyp;lm:plogmsgtyp):string;         
var p:pplrtyp;
begin
 case lm.tp of
  lmt_endturn:begin
   if lm.data[0].tag=1 then result:=po('Landing')
                       else result:=po('Start of turn')+' #'+stri(lm.data[0].tag);
  end;
  lmt_build_completed:   result:=po('Build completed');
  lmt_research_completed:result:=po('Research completed')+': '+po(res_names[lm.data[0].kind])+'(+'+stri(lm.data[0].tag)+'%)';
  lmt_aircrash:          result:=po('Plane crashed');
  lmt_player_lost:begin
   p:=get_plr(g,lm.data[0].tag);
   result:=po('Player lost')+': '+p.info.name;
  end;
  lmt_unit_under_attack:result:=po('Unit under attack');
  lmt_unit_destroyed:   result:=po('Unit destroyed');
  lmt_no_resources:     result:=po('Stoped, not enough of resources');
  lmt_unit_disabled:    result:=po('Unit disabled')+' ('+stri(lm.data[0].tag)+')';
  lmt_unit_stolen:      result:=po('Unit stolen');
  lmt_enemy_unit_spoted:result:=po('Enemy unit spotted');
  lmt_enemy_unit_hiden: result:=po('Enemy unit hidden');
  lmt_enemy_unit_moved: result:=po('Enemy unit moved');

  lmt_unit_upgraded:      result:=po('Upgraded unit');
  lmt_unit_upgrade_fail:  result:=po('Failed (lack of materials) to upgrade');
  lmt_build_no_materials: result:=po('Cannot start for lack of ...');
  lmt_stop_need_materials:result:=po('Can not be stoped. Provides ...');
  lmt_start_no_materials: result:=po('Not enough ...');
  else result:=stri(lm.tp);
 end;
end;
//############################################################################//
begin
end.   
//############################################################################//
