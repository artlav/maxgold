//############################################################################//
unit sdirecs;
interface
uses asys,grph,mgrecs,maths,json,sds_rec;
//############################################################################//
const
sdi_progver:string='2019.09.10.0';
sdi_progvernum:integer=201909100;
sdi_log_console:boolean=false;
//############################################################################//
const
//Global cell scale (64) and in's half
XCX=64;
XHCX=32;

def_map='112x112'; 

base_dir='maxg_data';
graph_dir=  base_dir+'/grp';
sound_dir0= base_dir+'/snd';
sound_dir1= base_dir+'/snd_units';
sound_dir2= base_dir+'/snd_voice';
musdir=     base_dir+'/music';
flicdir=    base_dir+'/anim';
unitsgrpdir=base_dir+'/unitsgrp'; 
mapsdir=    'cache';
//############################################################################//
//Data locations
LOC_DIR=0;
LOC_ZIP=1;
LOC_INNER=2;
//############################################################################//
MAX_PRESEL=10;   //Stored unit selections
MAX_CAMPOS=4;    //Stored camera positions
//############################################################################//
line_color=5;             //I.e. for menus
text_color=4;
text_box_hei=23;
scroller_hei=17;
fire_length:double=0.25;
track_decay_time=150;
msgu_yoff=22;

doubleclick_time=0.5;
//############################################################################//
//States
CST_THEMENU=0;        //Main menus
CST_THEGAME=1;        //The game as played
CST_INSGAME=2;        //Between turns
//############################################################################//
LD_CNT=9;   
  
BCK_NONE=-1;
BCK_SHADE=-2;
//############################################################################//
zsc_off=60;
zsc_siz=40;      
//############################################################################//
uevt_stored   =1;
uevt_unstored =2;
uevt_boom     =3;
uevt_stopped  =4; 
uevt_started  =5;  
uevt_fire     =6;  
uevt_hit      =7;
//############################################################################//
//Single-element sprites
GRP_EHANGAR    = 0;   //Empty hangar/store/barrack slot
GRP_EDOCK      = 1;   //Empty dock slot 
GRP_EDEPOT     = 2;   //Empty depot slot
GRP_TSTIMG     = 3;   //Test image for options
GRP_SURVRES    = 4;
GRP_UNITMEN    = 5;   //remove
GRP_SELFDSTR   = 6;
GRP_ALLOCFRM   = 7;
GRP_RSRCHPIC   = 8;
//############################################################################//
//Multi-element sprites
gru_count=35;

GRU_PATH=0;
GRU_TRACKS=1;
GRU_ICOS=2;  

GRU_DISABLED=3;
GRU_BUILDMARK=4;

GRU_BLDEXP=5;
GRU_LANDEXP=6;
GRU_AIREXP=7;
GRU_SEAEXP=8;

GRU_BAR=9;
GRU_SMBAR=10;
GRU_VERTBAR=11;

GRU_DEMO_POWGEN=12;
GRU_DEMO_S_POWGEN=13;
GRU_DEMO_SMLSLAB=14;

GRU_HIT=34;
//############################################################################//
//Cursors
CUR_NONE=-1;
CUR_POINTER     =0;
CUR_SELECT      =1;
CUR_TRANSFER    =2;
CUR_EXIT        =3;
CUR_ENTER       =4;
CUR_NOTAVAILABLE=5;
CUR_MOVE        =6;
CUR_ATTACK      =7;
CUR_REFUEL      =8;
CUR_GOTO        =9;
CUR_BUILDTO     =10;
CUR_RELOAD      =11;
CUR_DISABLE     =12;
CUR_DISABLEF    =12;
CUR_REPAIR      =13;
CUR_STEAL       =14;
CUR_STEALF      =14;
CUR_COUNT=CUR_STEALF+1;
//############################################################################//
UN_BIGROPE=0;
UN_SMLROPE=1;
UN_BIGPLATE=2;
UN_SMLPLATE=3;
UN_MINING=4;
UN_CNT=UN_MINING+1;
//############################################################################//
//Frame buttons
fb_survey    =0;
fb_grid      =1;
fb_speedrange=2;
fb_scan      =3;
fb_range     =4;
fb_colors    =5;
fb_hits      =6;
fb_status    =7;
fb_ammo      =8;
fb_fuel      =9;
fb_names     =10;
fb_build     =11;

fb_count     =12; 
//############################################################################// 
clannames:array[1..8]of string=('The Chosen','Crimson Path','Von Griffin','Ayer''s Hand','Musashi','Sacred Eights','7 Knights','Axis Inc.');
//############################################################################//
SND_TCK        =0;
SND_BUTTON     =1;
SND_DENY       =2;
SND_TOGGLE     =3;  //switch flip sound
SND_ACCEPT     =4;  //dual tck
SND_ENTER      =5; //"scale" sound
SND_HIT_MED    =6;
SND_EXPLODE_MED=7;
//############################################################################//
VOI_READY_1=0;
VOI_READY_2=1;
VOI_READY_3=2;
VOI_READY_4=3;

VOI_AMMO_LOW=4;
VOI_AMMO_GONE=5;
VOI_MOVE_GONE=6;
VOI_HIT_MED_1=7;
VOI_HIT_MED_2=8;
VOI_HIT_BAD_1=9;
VOI_HIT_BAD_2=10;

VOI_SENTRY=11;
//############################################################################//  
type
fontinfo=packed record
 width,offset:integer;
end;
afontinfo=array[0..1000000]of fontinfo;
pafontinfo=^afontinfo;

mgfont=packed record
 num,height,spacing:integer;
 info:pafontinfo;
 data:pbytea;
end;
pmgfont=^mgfont;   
//############################################################################//
typsnds=record
 nam:string;
 snd:pointer;
 ex,copy:boolean;
end;

typeunitsdb=record
 typ,name_rus,name_eng:string;
 udb_num:integer;
     
 img_poster,img_depot:typuspr;
 spr_base,spr_list,spr_shadow:typuspr;
 video:shortvid8typ;
 
 base_frames,active_frames:vec;
 water_base_frames,water_active_frames:vec;  
 animation_frames,firing_base_frames,connector_frames,gun_frames,firing_gun_frames:vec;

 active_snd,water_active_snd,boom_snd,stop_snd,start_snd,fire_snd:typsnds;
end;        
ptypeunitsdb=^typeunitsdb;

type vcomp=record
 x,y,sx,sy:integer;
end;

type intftyp=record
 mmap,coord,stats,uview,rmnu:vcomp;
end;
//############################################################################//
//A map window
type map_window_rec=record
 mapoxo,mapoyo:integer;    
 mapl,mapr,mapt,mapb:integer;       
 colorzoom,oldzoom,maxzoom,bld_zoom_1,bld_zoom_2:double;  
 gfcx,gfcy:integer; 

 background_fill_color:byte;
 offset_xlate_x,offset_xlate_y,block_xlate:array of dword;

 ssx,ssy,psx,psy:integer; 
end;
pmap_window_rec=^map_window_rec;    
//############################################################################//
//############################################################################//
type
anim_unit_typ=record       
 used:boolean;
 x,y,siz:integer;
 
 spr:ptypuspr;
                                                                
 anim_timer:double;
 animation_frames:vec;
end;
panim_unit_typ=^anim_unit_typ;   
//############################################################################//    
trktyp=record
 x,y,d,dx,dy:int16;
 t:single;
end;
atrktyp=array of trktyp;
patrktyp=^atrktyp;
//############################################################################//
//Saved camera positions
campostyp=record
 x,y:integer;                           //x=-1 mean position is not stored
 zoom:single;
end;
pcampostyp=^campostyp;
//############################################################################//
screenopt_rec=record
 zoom:single;                                 //Zoom
 sx,sy,xm,ym:int16;                           //Upper corner - cell x,y, offset in cell x,y       
 frame_btn:array[0..fb_count-1]of byte;          //Frame buttons states
end;       
pscreenopt_rec=^screenopt_rec;  
//############################################################################//
plr_client_info=record  
 lck_mode:boolean;                               //zamok mode flag
 sel_unit_uid:integer;                           //selected unit
 custom_color:array of crgb;                     //RGB of customized colors   
 custom_color8:array of byte;                    //Index of customized colors
 sopt:screenopt_rec;
 cam_pos:array[0..MAX_CAMPOS-1] of campostyp;    //Stored camera positions  
 locked_uids:array of integer;                   //A list of units in a lock

 //FIXME: Todo?
 //sel_stored:array[0..MAX_PRESEL-1] of array of integer; //Stored unit selections
end;
pplr_client_info=^plr_client_info;
//############################################################################//
sdi_grap_rec=record
 //Font
 mgfxlat:array[0..255]of byte;
 mgfnt:array of mgfont;   
 mg_font_loaded:boolean;  

 //Basic pallette
 base_pal:pallette3;    

 //Global graphics
 curs,grap:array of ptypspr;       //Cursors, graphics
 raw_bkgr,scaled_bkgr:array[0..9]of ptypspr;       //Backgrounds, raw and rescaled
 clns:array[0..8]of ptypspr;       //Clans
 grapu:array of ptypuspr;          //Dynamics
   
 mapedge:boolean;
 load_unit_sounds:boolean;
 fog_of_war,unit_shadows,show_cursor:boolean;

 //General interface
 intf:intftyp;
 lang:string; //uniset specified unit graphics which are the same for many mg_sys unisets

 //Shades
 msg_shade:array[0..8]of array[0..255]of byte;
 shadow_shade,minimap_shade:array[0..255]of byte;
 shadow_density,msg_density,fow_density:single;    
end;
psdi_grap_rec=^sdi_grap_rec;    
//############################################################################//  
replay_rec=record
 st:string;  
 js:pjs_node;
 init_step,passmap_step,udb_step,reentry_step,color_step:integer;
 turns:array of integer;
 events,reqs:array of string;
 endturn_count,sz:integer;

 turn_count,plr,pos:integer;
 fast_replay,skip_replay,paused,single_step,skip_fetches:boolean;
end;
//############################################################################//
colors_rec=record
 //Colors cache
 clr_speed,clr_scan,clr_scan_det,clr_range_land,clr_range_water,clr_range_air,clr_range_all:byte;

 //Player pallettes xchange
 palpx:array[0..20]of palxtyp;
 al_palpx:palxtyp;
end;
//############################################################################//
sdi_rec=record
 cg:psdi_grap_rec;
 inited:boolean;

 //Step system
 steps:sds_sys;

 //Game
 the_game:pgametyp;
 def_rules:rulestyp;
 got_def_rules:boolean;
                  
 //Map plane, UT plane, minimap plane
 map_plane,ut_plane,minimap_plane:typspr;

 //Player palettes and special colors
 colors:colors_rec;

 //Debug menu placing flag
 debug_placing:boolean;
 //Which unit is being placed
 debug_placed_unit:integer;

 //Password the user gave
 entered_password:string;

 //Draw comments on screen
 show_comments:boolean;

 //Don't show any menus
 hide_interface:boolean;

 //State of rmnu buttons
 rmnu_state:array of byte;

 //Animations
 anim_units:array[0..100]of anim_unit_typ;

 //Current state
 state:integer; 
 cur_menu,cur_menu_page:dword;    //Curernt menu
 cur_cur:integer;                 //Current cursor
 bkgr_image:integer;              //Current background image  
 surrender_count:integer;    
 clinfo:plr_client_info;

 active_events:boolean;           //Something is happening, don't let the comms and input continue until done

 //Replay
 rep:replay_rec;

 //Previous states
 pstate:integer;
 prcur:array of byte;
 prcx,prcy,prcxs,prcys:integer;
 pcur_menu:dword; 

 //Event prev stats
 selunit_old,unit_count_old:integer;  
 move_old,move_old_2:boolean;

 down_shift:dword;
 ignore_mouseup,ignore_mousemove:boolean;

 //Events
 map_event,ut_event,unev,minimap_event,map_scroll_ev,plane_ev:boolean;   
 frameev,frame_map_ev,frame_mmap_ev:boolean;  

 //Animation dt, error dt global ct, global dt 
 anim_dt,msd_dt,gct,gdt:double;
 
 //Loading menu
 now_loading:boolean;
 pending_resize:boolean;
 picked_loading_bkgr:boolean;
 load_bar_pos:single;                   //Loading bar
 load_box_str:array[0..LD_CNT-1]of string;     //Loading strings

 //Message box
 mbox_on:boolean;
 mbox_nam,mbox_msg:string;

 //Map pallette, offset to blocks map of loaded map, resource offsets map
 map_pal:pallette3;
 pmap:array of integer;
 rpmap:array of dword;

 //Tracks   
 trk:atrktyp;
 
 //Loaded map and minimap and their FOW parts
 map_tileset,map_tileset_fow,mm_tileset,mm_tileset_fow:ptypspr; 

 //Scroll stuff
 scroll_right,scroll_left,scroll_up,scroll_down:boolean;  
 rmxo,rmyo:integer;
 rmov:boolean;

 //Cursor 
 cur_map_x,cur_map_y:integer; 

 //Main map window
 mainmap:map_window_rec;  
 mapx,mapy:integer;

 //Zoomer lineyka
 //+100 to avoid rounding errors-induced overdraw (Hvostiki massivov!)
 zoomer:array[0..999+100]of boolean;
 zoomof,zoomsc,azoomsc:array[0..999+100]of integer;

 //UT options
 ut_at_end_move:boolean;         //Offset toggle for uts
 ut_circles,ut_squares:boolean;  //Unit descriptions in menus, UT circles on, squares on
 center_zoom:boolean;            //Use cursor zoom   
 zoomspd:single;                 //Zoom speed  
 
 //Debug
 resdbg:boolean;
 runcnt:integer;                 //Run count
            
 //Comments
 gm_comment_mode:boolean;
 gm_comment_x,gm_comment_y:integer;
 gm_comment_text:string;
 gm_comment_num:integer;

 //The game start

 //Multiplayer start menu
 newgame:gamestart_rec;
 ng_cur_plr:integer;
 ng_curplr_name:stringmg;
 ng_map_id:integer;
 ng_map_name:string;
 
 //Unisets
 unisets_loaded:boolean;
 uniset_count:integer;
 unitsets:array of uniset_rec;

 //Uniset graphics
 loaded_uniset:boolean;
 auxun:array[0..UN_CNT-1]of ptypeunitsdb;   //Auxillary units ids   
 eunitsdb:array of ptypeunitsdb;            //Unit graphics db
 
 //Map list
 map_list:array of map_list_rec;
 map_pal_list:array of pallette3; 
 total_maps:integer;
 mmapbmp,mmapbmpbw:array of ptypspr;  //Minimaps, B/W minimaps
end;
psdi_rec=^sdi_rec;
//############################################################################//
implementation
//############################################################################//
begin
end.
//############################################################################//

