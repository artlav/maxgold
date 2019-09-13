//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//Max saves data
//############################################################################/
unit maxsavesrec;
interface
uses asys;
//############################################################################//
type header156=packed record
 game_type:byte;
 game_name:array[0..29]of char;
 map_id_1:byte;
 level_num:word;
 plr_name:array[0..3]of array[0..29]of char;
 plr_type:array[0..3]of byte;
 alien_type:byte;
 creation_time:dword;
 cpuiq1:byte;
 time_of_turn_1,time_of_end_turn_1:word;
 turn_mode_1:byte;
 map_id_2:dword;
 time_of_turn_2:dword;
 time_of_end_turn_2:dword;
 sgold:dword;
 turn_mode_2:dword;
 type_of_end:dword;
 amt_to_end:dword;
 cpuiq2:dword;
 start_raw:dword;
 start_fuel:dword;
 start_gold:dword;
 start_alien:dword;
end;
//############################################################################//
type header104=packed record
 game_type:byte;
 game_name:array[0..29]of char;
 map_id_1:byte;
 level_num:word;
 plr_name:array[0..3]of array[0..29]of char;
 plr_type:array[0..3]of byte;
 alien_type:byte;
 unk104:array[0..4]of byte;
 creation_time:dword;
 cpuiq1:byte;
 time_of_turn_1,time_of_end_turn_1:word;
 turn_mode_1:byte;
 map_id_2:dword;
 time_of_turn_2:dword;
 time_of_end_turn_2:dword;
 sgold:dword;
 turn_mode_2:dword;
 type_of_end:dword;
 amt_to_end:dword;
 cpuiq2:dword;
 start_raw:dword;
 start_fuel:dword;
 start_gold:dword;
 start_alien:dword;
end;
//############################################################################//
resinfo=packed record
 now,unk,labs:dword;
end;
ob_word=packed record
 ob:word;
 full:boolean;
end;
//############################################################################//
player_info=packed record
 FF1:array[0..39]of byte;
 plr_type:byte;
 unk0:byte;
 clan:byte;
 research:array[0..7]of resinfo;
 score:dword;
 object_count:word;
 unit_counters:array[0..92]of byte;   //"Connector x is done"
 FF2:array[0..11]of byte;
 scoregraph:array[0..49]of word;  //Scoore graph?//Each Point takes up two bytes. Thus, on 100 bytes, 50 Points can be stored for the graph. The Points seems to be signed values.
 selunit:word;
 zoom,xoff,yoff:word;
 buttons:array[0..10]of byte;
 factories_built,mines_built,buildings_built,units_built:word;
 loses:array[0..185]of byte;
 goldused:word;
end;
pplayer_info=^player_info;
//############################################################################//
mesgrec=record
 len:word;
 msg:string;
end;
pptrec=packed record
 x,y:shortint;
end;

unk_1_rec=packed record
 a,b,c:word;
end;
//############################################################################//
//Object 3
post_updates_record=packed record
 val:array[0..14-1]of byte;
end;
ppost_updates_record=^post_updates_record;
//############################################################################//
//Object 4
path_def_block=packed record
 target_x,target_y,zero1:word;
 cnt:word;
 path:array of pptrec;
end;
ppath_def_block=^path_def_block;
//############################################################################//
//Object 5     //154b
unit_def_record=packed record
 unid:word;

 unk_byte_1,unk_byte_2:byte;

 flags:dword;
//          Bit7 (0x80)	       Bit6 (0x40)	     Bit5 (0x20)	     Bit4 (0x10)	  Bit3 (0x08)	      Bit2 (0x04)	    Bit1 (0x02)	       Bit0 (0x01)
//018	FLAGS	mobile_sea_unit	   mobile_air_unit	 missile_unit	    building	     connector_unit	   animated	       exploding	         ground_cover
//019	FLAGS	-	                 upgradeable	     -	               -	            -	                -	              stationary	        mobile_land_unit
//020	FLAGS	standalone	        selectable	      electronic_unit	 -	            constructor_unit	 fires_missiles	 has_firing_sprite	 hovering
//021	FLAGS	-	                 -	               -	               -            	spinning_turret	  sentry_unit	    turret_sprite	     requires_slab

 x_graphic,y_graphic,x_pos,y_pos:word;

 //14
 custom_name_length:word;
 custom_name:string;

 //16
 shadow_center_x_off,shadow_center_y_off:smallint;
 owner:byte;
 unit_number:byte;
 brightness:byte;
 rot:byte;

 vis_red,vis_green,vis_blue,vis_gray,vis_alien:byte;
 spotted_red,spotted_green,spotted_blue,spotted_gray,spotted_alien:byte;
 ubv5,velocity:byte;
 state:byte;
 is_stored:byte;

 udv1:array[0..7]of dword;

 gun_rot:byte;
 ub2v2,ub2v3:byte;

 total_images,image_base,turret_image_base,firing_image_base,connector_image_base:word;

 base_sprite:byte; //(rot, water, active,...)

 uwv6b:byte;
 anim_sprite_1:word;
 uwv8:word;

 orders,state_done,prior_orders,prior_state,ub2v8:byte;
 target_x,target_y:word;

 //100
 turns_left_base:byte;
 mining_tot_sel,mining_res_sel,mining_ful_sel,mining_gld_sel,mining_res_avl,mining_ful_avl,mining_gld_avl:byte;

 hitsnow,speednow,shotnow,shotmove:byte;
 cargonow:word;
 ammonow:byte;

 targeting_mode,enter_mode,cursor:byte;
 //118
 recoil_delay,delayed_reaction,damaged_this_turn,research_topic:byte;

 unk_arr_4:array[0..9-1]of byte;
 repeat_build,bld_speed:byte;

 //Objects
 unk_obj_1:ob_word;
 unk_obj_2:ob_word;
 unk_obj_3:ob_word;
 //140
 pathobj:ob_word;
 connectors:word;
 object_used:ob_word;
 unk_obj_4:ob_word;
 inside_obj:ob_word;
 unk_obj_5:ob_word;

 is_build_n:word;
 build_unit_num:array of word;
end;
punit_def_record=^unit_def_record;
//############################################################################//
//Object 6
unit_pars_record=packed record
 cost,hits,armr,attk,speed,range,shot:word;
 movnf:byte;
 scan,store,ammo,area:word;
 z31:byte;
 unk0,unk1,unk2,unk3:byte;
end;
punit_pars_record=^unit_pars_record;
//############################################################################//
//Object list
objlstrec=record
 id,tp:word;
 info:pointer;
end;
//############################################################################//
//############################################################################//
//############################################################################//
const
btnames :   array[0..10]of string=('Range','Scan','Status','Colors','Hits','Ammo','Names','2X','TNT','Grid','Survey');
clannames:  array[1.. 8]of string=('The Chosen','Crimson Path','Von Griffin','Ayer''s Hand','Musashi','Sacred Eights','7 Knights','Axis Inc.');
resrchnames:array[0.. 7]of string=('Attack','Shot','Range','Armor','Hits','Speed','Scan','Cost');

def_maps:   array[0.. 23]of string=(
'Snow_1'  ,'Snow_2'  ,'Snow_3'  ,'Snow_4'  ,'Snow_5'  ,'Snow_6',
'Crater_1','Crater_2','Crater_3','Crater_4','Crater_5','Crater_6',
'Green_1' ,'Green_2' ,'Green_3' ,'Green_4' ,'Green_5' ,'Green_6',
'Desert_1','Desert_2','Desert_3','Desert_4','Desert_5','Desert_6'
);

x_buttons:array[0..11]of integer=(10,9,-1,1,0,3,4,2,5,-1,6,-1);
x_clans:array[1..8]of integer=(0,1,2,3,4,5,6,7);

plr_color:array[0..3]of array[0..2]of byte=((252,0,0),(0,252,0),(0,0,252),(128,128,160));

HD104=$0046;
HD156=$0045;

uninames:array[0..93-1]of array[0..3]of string=(
('COMM_TOWER'      ,'Gold Refinery'   ,'gref'       ,'B2'),
('POWER_STN'       ,'Power Plant'     ,'Powerpl'    ,'B2'),
('POWER_GEN'       ,'Power Generator' ,'Powergen'   ,'B1'),
('BARRACKS'        ,'Barracks'        ,'barrak'     ,'B2'),
('SHIELD_GEN'      ,'Shield Generator',''           ,'B2'),
('RADAR'           ,'Radar'           ,'Radar'      ,'B1'),
('SMALL STORAGE'   ,'Material Store'  ,'Matstore'   ,'B1'),
('SMALL FUEL_TANK' ,'Fuel Store'      ,'Fuelstore'  ,'B1'),
('SMALL GOLD VAULT','Gold Store'      ,'Goldstore'  ,'B1'),
('DEPOT'           ,'Depot'           ,'Store'      ,'B2'),
('HANGAR'          ,'Hangar'          ,'Hang'       ,'B2'),
('DOCK'            ,'Dock'            ,'Dock'       ,'B2'),
('CONNECTOR_4W'    ,'Connector'       ,'Conn'       ,'B1'),
('LARGE_RUBBLE'    ,'Big Rubble'      ,'Bigrubble'  ,'B2'),
('SMALL_RUBBLE'    ,'Small rubble'    ,'Smlrubble'  ,'B1'),
('LARGE_TAPE'      ,'Big Rope'        ,'Bigrope'    ,'B2'),
('SMALL_TAPE'      ,'Small Rope'      ,'Smlrope'    ,'B1'),
('LARGE_SLAB'      ,'Big Plate'       ,'Bigplate'   ,'B2'),
('SMALL_SLAB'      ,'Small Plate'     ,'Smlplate'   ,'B1'),
('LARGE_CONES'     ,'Big Cones'       ,'Bigcone'    ,'B2'),
('SMALL_CONES'     ,'Small Cones'     ,'Smlcone'    ,'B1'),
('ROAD'            ,'Road'            ,'Road'       ,'B1'),
('LANDING_PAD'     ,'Landing pad'     ,'landpad'    ,'B1'),
('SHIPYARD'        ,'Shipyard'        ,'Shipyard'   ,'B2'),
('LIGHT_UNIT_PLANT','Light Plant'     ,'Lightplant' ,'B2'),
('LAND_UNIT_PLANT' ,'Heavy Plant'     ,'Hvplant'    ,'B2'),    //25 //26
('SUPPORT_PLANT'   ,'Support Plant'   ,''           ,'B2'),
('AIR_UNIT_PLANT'  ,'Air Plant'       ,'Airplant'   ,'B2'),
('HABITAT'         ,'Habitat'         ,'Habitat'    ,'B2'),
('RESEARCH_CENTER' ,'Lab'             ,'research'   ,'B2'),
('GREEN HOUSE'     ,'Ecosphere'       ,'Ecosphere'  ,'B2'),
('REC CENTER'      ,'Recr Center'     ,''           ,'B2'),
('TRAINING HALL'   ,'Training Hall'   ,'pehplant'   ,'B2'),
('SEA RIG'         ,'Sea Platform'    ,'Plat'       ,'B1'),
('Gun Turret'      ,'Gun Turret'      ,'turret'     ,'B1'),
('ANTI_AIRCRAFT'   ,'AA Turret'       ,'Zenit'      ,'B1'),
('artillery turret','Artillery Turret','Arturret'   ,'B1'),
('Missile turret'  ,'Missile Turret'  ,'misturret'  ,'B1'),
('BLOCK'           ,'Block'           ,'Conblock'   ,'B1'),
('BRIDGE'          ,'Bridge'          ,'Bridge'     ,'B1'),
('MINING_STATION'  ,'Mining'          ,'Mining'     ,'B2'),    //40  //41
('LAND MINE'       ,'Land Mine'       ,'landmine'   ,'B1'),
('SEA MINE'        ,'Sea Mine'        ,'seamine'    ,'B1'),
('LAND EXPLOSION'  ,'Land Boom'       ,'-'          ,'A1'),
('AIR EXPLOSION'   ,'Air Boom'        ,'-'          ,'A1'),
('SEA EXPLOSION'   ,'Sea Boom'        ,'-'          ,'A1'),
('BUILDING EXPLO'  ,'Bld Boom'        ,'-'          ,'A2'),
('HIT EXPLOSION'   ,'Hit Boom'        ,'-'          ,'A1'),
('MASTER_UNIT'     ,'Master Unit'     ,'-'          ,'A1'),
('CONSTRUCTOR'     ,'Constructor'     ,'Constructor','U1'), //49 //50   $32
('SCOUT'           ,'Scout'           ,'Scout'      ,'U1'),
('TANK'            ,'Tank'            ,'Tank'       ,'U1'),
('ASSUALT GUN'     ,'Assault Gun'     ,'Asgun'      ,'U1'),
('Rocket launcher' ,'Rocketter'       ,'Rocket'     ,'U1'),
('MISSLE_LAUNCHER' ,'Grad Launcher'   ,'Crawler'    ,'U1'),
('MOBILE AA'       ,'Mobile AA Gun'   ,'Aagunm'     ,'U1'),
('MINE_LAYER'      ,'Mine Layer'      ,'Miner'      ,'U1'),
('SURVEYOR'        ,'Surveyor'        ,'Surveyor'   ,'U1'),     //58   $3A
('SCANNER'         ,'Scanner'         ,'Scanner'    ,'U1'),
('SUPPLY TRUCK'    ,'Material Truck'  ,'Truck'      ,'U1'),
('GOLD TRUCK'      ,'Gold Truck'      ,'Gtruck'     ,'U1'),
('ENGINEER'        ,'Engineer'        ,'Engineer'   ,'U1'),
('BULLDOZER'       ,'Bulldozer'       ,'Dozer'      ,'U1'),
('REPAIR'          ,'Repair Unit'     ,'Repair'     ,'U1'),
('FUEL TRUCK'      ,'Fuel Truck'      ,'Fueltruck'  ,'U1'),
('COLONIST TRANS'  ,'Personnel Car'   ,'pcan'       ,'U1'),
('COMMANDO'        ,'Infiltrator'     ,'Infil'      ,'U1'),
('INFANTRY'        ,'Infantry'        ,'infantry'   ,'U1'),
('AA BOAT'         ,'Escort'          ,'Escort'     ,'U1'),
('CORVETTE'        ,'Corvette'        ,'Corvette'   ,'U1'),
('GUNBOAT'         ,'Gunboat'         ,'Gunboat'    ,'U1'),
('SUBMARINE'       ,'Submarine'       ,'sub'        ,'U1'),
('SEA_TRANSPORT'   ,'Sea Transport'   ,'Seatrans'   ,'U1'),
('MISSLE_BOAT'     ,'Rocket Boat'     ,'Rokcr'      ,'U1'),
('SEA MINE LAYER'  ,'Sea Mine Layer'  ,'seaminelay' ,'U1'),
('CARGO SHIP'      ,'Cargo Ship'      ,'Seacargo'   ,'U1'),
('FIGHTER'         ,'Interceptor'     ,'Inter'      ,'U1'),
('BOMBER'          ,'Bomber'          ,'Bomber'     ,'U1'),
('AIR_TRANSPORT'   ,'Air Transport'   ,'Airtrans'   ,'U1'),
('AWAC'            ,'AWAC'            ,'Awac'       ,'U1'),
('ALIEN GUN BOAT'  ,'Alien Gunboat'   ,'juger'      ,'U1'),
('ALIEN TANK'      ,'Alien Tank'      ,'alntank'    ,'U1'),
('ALIEN ASSGUN'    ,'Alien Assgun'    ,'alnasgun'   ,'U1'),
('ALIEN ATTPLANE'  ,'Alien Bomber'    ,'alnplane'   ,'U1'),
('ROCKET'          ,'Rocket'          ,'-'          ,'A1'),
('TORPEDO'         ,'Torpedo'         ,'-'          ,'A1'),
('ALIEN MISSLE'    ,'Alien Missile'   ,'-'          ,'A1'),
('ALIEN TANK PBALL','Alien Tank PBall','-'          ,'A1'),
('ALIEN ART PBALL' ,'Alien Art PBall' ,'-'          ,'A1'),
('SMOKE_TRAIL'     ,'Smoke Trail'     ,'-'          ,'A1'),
('BUBBLE_TRAIL'    ,'Bubble Trail'    ,'-'          ,'A1'),
('HARVESTER'       ,'Harvester'       ,'-'          ,'A1'),
('WALDO'           ,'Waldo'           ,'-'          ,'A1')
);
//############################################################################//
type saveorec=record
 id:word;
 head:header104;

 pasmap:array[0..12543]of byte;
 resmap:array[0..25087]of byte;

 pi:array[0..3]of player_info;

 doing_turn:byte;   //Who is actually taking it's turn. If Player 1 is active, the value is 0.
 turn_status:byte;  //Is the Turn already started?
 cur_turn:dword;
 game_state:word;
//0-7	Exit to main menu
//8	Player takes it's turn
//9	Next player comes
//10	Game hangs
//11+	Exit to main menu
 victory_state:word;

 anim_effects:dword;//0 = OFF ; 1 = ON (Animate effects)
 click_scroll:dword;//0 = OFF ; 1 = ON (Click to scroll)
 scroll_speed:dword;//4 - 128 (Scroll speed); >4 default speed -> 16; <128 max speed;
 double_steps:dword;//0 = OFF ; 1 = ON (Double unit steps)
 track_selected:dword;//0 = OFF ; 1 = ON (Track selected unit)
 auto_select:dword;//0 = OFF ; 1 = ON (Auto select unit)
 enemy_halt:dword;//0 = OFF ; 1 = ON (Auto select unit)

 objlst:array of objlstrec;
 last_obj:integer;

 update_cnt,plr_gold:array[0..3]of word;
 plr_obs_a:array[0..3]of array[0..93*2-1]of ob_word;
 plr_obs_b:array[0..3]of array of ob_word;
 unsel_count,moving_count,bldg_count,air_count:word;
 unsel_obs,moving_obs,bldg_obs,air_obs:array of ob_word;

 //plr_start:array[0..3]of integer;
 unitcnt,mg_unitcnt,unitstart:integer;
 plr_count:integer;

 postunits_unk:array[0..7]of byte;

 unk_post_1:array of unk_1_rec;

 scan_map:array[0..3]of array[0..12543]of byte;
 corvett_map:array[0..3]of array[0..12543]of byte;
 infantry_map:array[0..3]of array[0..12543]of byte;

 msg_cnt:array[0..3]of word;
 mesgs:array[0..3]of array of mesgrec;

 //Score graph record
 //Messages
 //Etc?

 restof:pointer;
 restsize:dword;
end;
//############################################################################//
implementation
//############################################################################//
begin
end.
//############################################################################//
