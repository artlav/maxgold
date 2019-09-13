//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core structures definitions
//############################################################################//
unit mgrecs;
interface
uses asys,grph{$ifdef srv_stat},tim{$endif};
//############################################################################//
const
core_progver:string='2019.09.10.0';             //Displayed version, means nothing
core_progvernum         :integer=201909100;     //Compatibility definition version for save files
core_progvernum_baseline:integer=201705100;     //Baseline for updates
//############################################################################// 
//Basic types
type
stringmg=string[64];
pstringmg=^stringmg;
//############################################################################//
const  
MAX_PLR=20;

mgrootdir_loc='';
mgrootdir=mgrootdir_loc;//+'/';
     
VFS_GLOBAL_DOMAIN=true;       //Allow other thread to access VFS
//############################################################################//
//Minimum distance between players
taint_threshold=20;
//############################################################################//
//Research
RS_COUNT=8;
//############################################################################//
//Upgrades
def_ut_factors:array[0..9]of integer=(16,16,8,32,32,16,8,8,32,8);
  
ut_attk =0;  
ut_shot =1;  
ut_range=2;  
ut_armor=3;  
ut_hits =4; 
ut_speed=5;  
ut_scan =6;
ut_cost =7;
ut_ammo =8;  
ut_fuel =9; 
//############################################################################//
//States
GST_THEGAME=1;        //The game as played
GST_SETGAME=3;        //Pre-game setup
GST_ENDGAME=5;        //Finished game
GST_TAINT=6;          //Landing intersected
//############################################################################// 
tool_none  =0;
tool_reload=1;
tool_repair=2;
tool_refuel=3;
tool_xfer2 =4;
tool_upgrade=5;
tool_steal  =6;
tool_disable=7;
//############################################################################//
stsk_none =0;
stsk_load =1;
stsk_shoot=2;
stsk_enter=3;  
stsk_shoot_place=4;  
stsk_refuel=5;  
stsk_reload=6;  
stsk_repair=7;   
stsk_xfer2 =8;
//############################################################################//
MAX_BEGINS=100;  //Initial purchases count
//############################################################################//
//Game menus
MG_NOMENU     =$00000000;
MG_DEBUG      =$00000001;
MG_BUILD      =$00000002;
MG_XFER       =$00000004;
MG_DEPOT      =$00000008;
MG_BOOM       =$00000010;
MG_UPGRLAB    =$00000020;
MG_MINE       =$00000040;
MG_UNITINFO   =$00000080;
MG_ESCSAVE    =$00000100;
MG_REPORT     =$00000200;
MG_UNIT_RENAME=$00000400;
MG_CLAN_INFO  =$00000800;
MG_CUSTOM_CLRS=$00001000;
MG_DIPLOMACY  =$00002000;
MG_LOADSAVE   =$00004000;
MG_UPGRMONEY  =$00008000;
MG_COMMENT    =$00010000;
MG_SET_TURN   =$00020000;
MG_FNC        =$00040000;
//############################################################################//
//Setup menus
MS_MULTIPLAYER=$00080000;
MS_OPTIONS    =$00100000;
MS_CLANSELECT =$00200000;
MS_ABOUT      =$00400000;
MS_PLAYERSETUP=$00800000;
MS_MAPSELECT  =$01000000;
MS_MAINMENU   =$02000000;
MS_RULES      =$04000000;
MS_INTERTURN  =$08000000;
MS_BUYINIT    =$10000000;
MS_UPDATE     =$20000000;
MS_HELP       =$40000000;
MS_CHANGES    =$80000000;
//############################################################################//
UQ_UP_LEFT=1;
UQ_UP_RIGHT=2;
UQ_DWN_RIGHT=3;
UQ_DWN_LEFT=4;
//############################################################################//
//Resource levels      
R_RICH=2;
R_MEDIUM=1;
R_POOR=0;

M_MINE=0;
M_CONCENTRATE=1;
M_NORMAL=2;
M_DIFFUSION=3;

P_MIN=0;
P_MAX=1;
//############################################################################//
TP_HUMAN=1;     
//############################################################################//
//Scan Map levels
SL_NORMAL=0;
SL_UNDERWATER=1;
SL_STEALTH=2;
SL_COUNT=SL_STEALTH+1;         
//############################################################################//
RES_NONE =0;
RES_MAT  =1;
RES_FUEL =2;
RES_GOLD =3;
RES_POW  =4;
RES_HUMAN=5;

//That hurts... But no better idea
RES_MINING_MIN=1; //RES_MAT
RES_MINING_MAX=3; //RES_GOLD
RES_MIN=1; //RES_MAT
RES_MAX=5; //RES_HUMAN
//############################################################################//
type
//Path
prec=record
 px,py,dir:integer;
 //pval - computing value, rpval - actual terrain value
 pval,rpval:single;
end;
pprec=^prec;
pathtyp=array of prec;
//############################################################################//
//Building
buildrec=record
 typ:stringmg;
 typ_db:integer;
 x,y,sz:integer;
 rept,reverse:boolean;

 left_turns,left_to_build,left_mat,cur_speed,cur_use,cur_take,given_speed:integer; 
 base,tape,cones:integer;
end;
pbuildrec=^buildrec;
//############################################################################//
prodrec=record
 num,use,now,pro,dbt:array[RES_MIN..RES_MAX] of int16;     
 refined_gold_pro,score_pro:int16;    
 mining:array[RES_MINING_MIN..RES_MINING_MAX]of int16;   
 next_use:array[RES_MIN..RES_MAX] of int16; 
end;
pprodrec=^prodrec;    
//############################################################################//
statrec=record
 speed,hits,armr,attk,shoot,fuel,range,scan,cost,ammo,area,mat_turn:int16;
end;
pstatrec=^statrec;
//############################################################################//
//The unit type
typunits=record       
 num:integer;                          //Index
 uid:integer;                          //Unique ID

 //Info
 typ,name:stringmg;                    //Type and name
 dbn,cln:int16;                        //DB num, Clan num       
 ptyp,level,siz:byte;                  //Passage type, level, size  
 clrval:int16;        

 //Core     
 triggered_auto_fire:boolean;      
 was_fired_on:boolean;                 //Was fired on last turn  
 prod_temp:prodrec;                    //Resources - computational  
 
 //State
 nm,mk:int16;                          //number of same model, model  
 cur_siz:byte;                         //current size   
 alt:int16;                            //Altitude
 own,x,y:int16;                        //Owner, x,y position   
 prior_x,prior_y:int16;                             
 rot,grot:byte;                        //Orientation, gun orientation  

 is_unselectable,is_sentry,is_moving,is_moving_build,is_moving_now:boolean;
 isact,strtmov,stpmov,stlmov,isstd,isclrg,stored,isbuild,isbuildfin:boolean;
 is_bomb_placing,is_bomb_removing:boolean;
 
 xt,yt,xnt,ynt:int16;                  //Target, next cell target
 path:pathtyp;                         //Path
 pstep,plen:integer;                   //Step and length of the path     
 
 cur,bas:statrec;                      //Stats - current, basic
 prod:prodrec;                         //Resources - current, computational
 domain:integer;
 researching:int16;                    //Reseacrh topic
         
 clrturns,clr_unit,clr_tape:integer;
 stored_in,currently_stored,disabled_for:integer;
              
 builds:array[0..50]of buildrec;       //Builds
 builds_cnt:integer;
 reserve:integer;                      //Materials Reserve 
 
 stop_task,stop_target,stop_param:integer; //Stopping event
 stop_task_pending:boolean;  
  
 stealth_detected:array[0..MAX_PLR-1]of shortint;
 
 //Client stuff
 grp_db:integer;                          //Graphics pointer for client  
 //water-air kachania
 wave_step:byte;
 wave_timer:double;  
 dmx,dmy:integer;     
 //Drawing the fire 
 fires:boolean;  
 fire_timer:double;
 //Motion
 move_anim:boolean;
 move_vel:double;  
 mox,moy:integer;
end;        
ptypunits=^typunits;    
aptypunits=array of ptypunits;
//############################################################################//
//The unit info type
typunitsdb=record
 num:integer;
 typ:stringmg;                //Class
 name_eng:stringmg;           //name
 name_rus:stringmg;           //name
 descr_eng:string;            //Description
 descr_rus:string;            //Description

 ptyp,level,ord,siz:byte;     //Passability, level, number, size
 priority:byte;               //Priority of the unit

 //Built by who, defined in uniset
 //0 - Не строимый
 //1 - Инжинер
 //2 - Конструктор
 //3 - Лёгкий
 //4 - Тяжелый
 //5 - Авиа
 //6 - Морской
 //7 - Пехотный
 //8 - Инопланетный
 bldby:integer;
        
 flags:dword;                 //Attributes
 flags2:dword;                //Attributes, part 2
 isgun:boolean;               //Separate gun
 
 bas:statrec;                 //Basic stats    
 prod:prodrec;                //Basic resources

 canbuild:boolean;            //Builder
 canbuildtyp:int16;           //What can it build

 firemov:boolean;             //Fires and moves?
 fire_type,weapon_type:byte;  //Firing type, shoots type

 //Storage
 store_lnd,store_wtr,store_air,store_hmn:int16;
end;          
ptypunitsdb=^typunitsdb;      
//############################################################################//
//Updates
typ_unupd=record
 typ:stringmg;
 mk,nu,cas:int16;
 bas:statrec;
end;
ptyp_unupd=^typ_unupd;

//Begin set
typbeg=record
 typ:stringmg;  
 x,y,mat:integer;
 locked:boolean;
end; 
ptypbeg=^typbeg;

//Clans
typclansdb=record
 name,desc_eng,desc_rus:string;
 flags:dword;
 unupd:array of typ_unupd;
end; 
ptypclansdb=^typclansdb;
//############################################################################//
//Razvedka
razvedtyp=record
 seen:boolean;
 blds:array of record
  id,level,own:integer;
 end;
end;
razveds=array of array of razvedtyp;
prazvedtyp=^razvedtyp;
//############################################################################//
//Log message data
logmsgtyp=record
 own:int16;                             //who can read message
 tp:byte;                               //message type
 data:array[0..1]of record
  x,y:int16;                            //coordinates for units/events
  dbn:int16;                            //unit DB num
  uid:integer;                          //UID of the unit involved
  own:int16;                            //unit owner
  kind:int16;                           //kind of resources/researches
  tag:int16;                            //reserved
 end;
end;
plogmsgtyp=^logmsgtyp;
//############################################################################//
//Comment data
comment_typ=record
 typ:integer;      //0 - global, 1 - on the map
 x,y:integer;     //position for 1
 turn:integer;    //-1 - for all turns, otherwise - turn
 text:string;
end;
pcomment_typ=^comment_typ;
//############################################################################//
player_start_rec=record
 init_unupd:array of typ_unupd;
 bgn:array[0..MAX_BEGINS-1]of typbeg;            //Initial purchases list
 bgncnt:integer;                                 //Number of initially bought units
 stgold,clan:integer;                            //Current gold, clan id
 color:crgb;                                     //RGB of player color
 color8:byte;                                    //Index of player color
 lndx,lndy:int16;                                //landing coordinates
 name,passhash:stringmg;                         //Name and password hash
end;
pplayer_start_rec=^player_start_rec;
//############################################################################//
//Players
plrtyp=record
 //Internal
 typ:int16;                             //Type of player  
 used:boolean;                          //Presence   
 num:integer;       

 //Info
 info:player_start_rec;

 //Client stuff     
 selunit:integer;                              //Selected units array

 client_data:string;
 
 //State          
 u_num,u_cas:array of integer;                   //Casulates, count
 unupd,tmp_unupd:array of typ_unupd;             //Unit upgrades   
 resmp:array of byte;                            //Resource visibility map  
 allies:array[0..MAX_PLR-1]of boolean;                  //Allied with or not?
 rsrch_spent:array[0..RS_COUNT-1]of integer;     //Total turns spent on current research
 rsrch_level:array[0..RS_COUNT-1]of integer;     //Research level
 rsrch_labs :array[0..RS_COUNT-1]of integer;     //Labs on topic
 rsrch_left :array[0..RS_COUNT-1]of integer;     //Turns left (indication)
 gold:integer;                                   //current gold
 labs_free:integer;                                       
 logmsg:array of logmsgtyp;                             //Log messages
  
 //Unsynced
 scan_map:array[0..SL_COUNT-1]of array of int16; //Scan maps, 0 - normal, 1 - underwater, 2 - stealth  
 razvedmp:razveds;                               //Recon map
 comments:array of comment_typ;                  //Comments
end;        
pplrtyp=^plrtyp;
//############################################################################//
//Rules
type rulestyp=record
 uniset:stringmg; 
 moratorium,moratorium_range,resset,goldset:integer;
 debug,fueluse,fuelxfer,unload_all_shots,unload_all_speed,unload_one_speed:boolean;
 load_sub_one_speed,load_onpad_only,startradar,no_survey,direct_land,nopaswds,fuel_shot,no_buy_atk:boolean;
 expensive_refuel,center_4x_scan,direct_gold,lay_connectors:boolean;
 ut_factors:array[0..9]of integer;
 res_levels:array[0..3]of integer;
end;
prulestyp=^rulestyp;
//############################################################################//
//Resources
type resrec=record
 amt,typ:byte;
end;    
presrec=^resrec;  
//############################################################################//
//UNU's
type unutyp=record
 qtr:byte;
 u:ptypunits;
end;
aunu=array of unutyp;
unus=array of array of aunu;
//############################################################################//
//############################################################################//
res_info_rec=array[0..2]of array[R_POOR..R_RICH]of array[M_MINE..M_DIFFUSION]of array[P_MIN..P_MAX] of integer;
//############################################################################//
uniset_rec=record
 name:stringmg;
 descr_rus:string;
 descr_eng:string;
              
 unitsdb:array of typunitsdb;           //Units info DB
 clansdb:array of typclansdb;           //Clans info DB   
 initial_res:res_info_rec;
end;
puniset_rec=^uniset_rec;
//############################################################################//
gamestart_rec=record
 name:stringmg;    
 map_name:stringmg;
 rules:rulestyp;
 
 plr_cnt:integer;  
 plr_names:array[0..MAX_PLR-1]of stringmg;
end;
pgamestart_rec=^gamestart_rec;
//############################################################################//
game_info=record      
 game_name,map_name:stringmg;
 descr:stringmg;                        //Short description    
 rules:rulestyp;                                        
 mapx,mapy:integer;                     //Map size - wid,hei
 plr_cnt,unitsdb_cnt:integer;
end;
pgame_info=^game_info;
//############################################################################//
game_state=record
 date:dword;   
 status:integer;
 turn,cur_plr:integer;
 mor_done:boolean;
 domains_cnt:integer;
 landed,lost:array[0..MAX_PLR-1]of boolean;
end;
pgame_state=^game_state;
//############################################################################//
sew_rec=record
 typ:integer;
 ua,ub:integer;
 x,y,n:integer;
 msg:stringmg;
end;
psew_rec=^sew_rec;
//############################################################################//
//Pathfinding tile
pf_tile=record
 done:boolean;
 ttype,stts:integer;
 value,rvalue,gval,fval:single;
 path:prec;
end;
ppf_tile=^pf_tile;
aopf_tile=array of pf_tile;
//############################################################################//
//Game info
gametyp=record
 //Internal   
 remote_id:stringmg;                    //ID for remote game, -1 for local.
 make_reply:boolean;                    //If set, no reply-specific stuff is done. Used for faster regen of current state

 save_name:stringmg; 
 rcc:integer;  
 seed:dword;

 last_uid:integer;
 
 //Event markers
 marks:array of boolean;
 plr_event,log_event:boolean;
 sews:array[0..100]of sew_rec;
 sew_cnt:integer;   

 //Client pointer
 grp_1,grp_2:pointer;  //1 is the main record, 2 is steps

 //Info      
 info:game_info;

 //State      
 state:game_state;
 
 //DBs         
 initial_res:res_info_rec;
 unitsdb:array of typunitsdb;           //Units info DB
 clansdb:array of typclansdb;           //Clans info DB    
 resmap:array of resrec;                //Resursmap
 passm:abyte;                           //Passage map (as in wrl)

 //Deep state
 units:array of ptypunits;              //Units
 plr:array[0..MAX_PLR-1]of plrtyp;           
 unu:unus;                              //UNU's
 pathing_map:aopf_tile;                 //Pathfinding utility map
end;
pgametyp=^gametyp;
//############################################################################// 
game_db_rec=record
 id:string;
 date,save_date:dword;
 cur_plr,cur_color:string;
 info:game_info;
 state:game_state;
 gam:pgametyp;
end;
pgame_db_rec=^game_db_rec; 
//############################################################################// 
map_list_rec=record
 file_name,name,descr:string;
end;
//############################################################################//
{$ifdef srv_stat}
//############################################################################//
type stat_rec=record
 t:int64;
 cnt:integer;
 nam:string;
end;
//############################################################################//
var
stat_dt,stat_dt2:integer;
t_req,t_a,t_b,t_c,t_d,t_e,t_f:int64;
reqs:array of stat_rec;
//############################################################################// 
procedure add_req(nam:string;t:int64);
procedure zero_stat;
procedure print_stat(tag:string);
//############################################################################//
{$endif}
//############################################################################//   
implementation
//############################################################################//
{$ifdef srv_stat}
//############################################################################//
procedure add_req(nam:string;t:int64);
var i,c:integer;
begin
 c:=-1;
 for i:=0 to length(reqs)-1 do if reqs[i].nam=nam then begin c:=i;break;end;
 if c=-1 then begin
  c:=length(reqs);
  setlength(reqs,c+1);
  reqs[c].nam:=nam;
  reqs[c].cnt:=0;
  reqs[c].t:=0;
 end;
 reqs[c].t:=reqs[c].t+t;
 reqs[c].cnt:=reqs[c].cnt+1;
end;
//############################################################################//
procedure zero_stat;
begin      
 t_req:=0;
 t_a:=0;
 t_b:=0;
 t_c:=0;
 t_d:=0;
 t_e:=0;
 t_f:=0;
 setlength(reqs,0);
end;
//############################################################################//
procedure print_stat(tag:string);
var i:integer;
begin
 writeln(tag,': req=',t_req,' a=',t_a,' b=',t_b,' c=',t_c,' d=',t_d,' e=',t_e,' f=',t_f);
 for i:=0 to length(reqs)-1 do begin
  write(reqs[i].nam:14,' ',reqs[i].t:7,' ');
  if reqs[i].cnt<>0 then writeln(reqs[i].t/reqs[i].cnt:9:2) else writeln;
 end;
end;
//############################################################################//
{$endif}
//############################################################################//
begin
 {$ifdef srv_stat}stat_dt:=getdt;stat_dt2:=getdt;{$endif}
end.
//############################################################################//
