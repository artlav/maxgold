//############################################################################//
program max_save;
uses sysutils,asys,strval,strtool,maxsaves,maxsavesrec;//,mgsaveload;
//############################################################################//
const nl=#$0A;
//############################################################################//
function str_ob(const o:ob_word):string;
begin
 result:='{"ob":'+trimsl('"'+stri(o.ob)+'"',5,' ')+',"full":'+stri(ord(o.full))+'}';
end;
//############################################################################//
procedure convert_one_save(dir,fn,ext:string);
var f:file;
savo:saveorec;
s,s1:string;
i,j:integer;
upr:punit_pars_record;
udr:punit_def_record;
pur:ppost_updates_record;
begin
 if not fileexists(dir+fn+'.'+ext) then exit;
 loadmaxosave(savo,dir+fn+'.'+ext);

 s:='{'+nl;
 s:=s+'"source":"'+fn+'.'+ext+'",'+nl;
 if savo.id=HD104 then s:=s+'"id":"1.04",'+nl;
 if savo.id=HD156 then s:=s+'"id":"1.56",'+nl;
 s:=s+'"header":{'+nl;
 s:=s+' "game_name":"'+savo.head.game_name+'",'+nl;
 s:=s+' "plr_name":["'+savo.head.plr_name[0]+'","'+savo.head.plr_name[1]+'","'+savo.head.plr_name[2]+'","'+savo.head.plr_name[3]+'"],'+nl;
 s:=s+' "plr_type":['+stri(savo.head.plr_type[0])+','+stri(savo.head.plr_type[1])+','+stri(savo.head.plr_type[2])+','+stri(savo.head.plr_type[3])+'],'+nl;
 s:=s+' "game_type":"'+stri(savo.head.game_type)+'",'+nl;
 s:=s+' "map_id_1":"'+stri(savo.head.map_id_1)+'",'+nl;
 s:=s+' "map_id_2":"'+stri(savo.head.map_id_2)+'",'+nl;
 s:=s+' "level_num":"'+stri(savo.head.level_num)+'",'+nl;
 s:=s+' "alien_type":"'+stri(savo.head.alien_type)+'",'+nl;
 s:=s+' "creation_time":"'+stri(savo.head.creation_time)+'",'+nl;
 s:=s+' "cpuiq1":"'+stri(savo.head.cpuiq1)+'",'+nl;
 s:=s+' "cpuiq2":"'+stri(savo.head.cpuiq2)+'",'+nl;
 s:=s+' "time_of_turn_1":"'+stri(savo.head.time_of_turn_1)+'",'+nl;
 s:=s+' "time_of_turn_2":"'+stri(savo.head.time_of_turn_2)+'",'+nl;
 s:=s+' "time_of_end_turn_1":"'+stri(savo.head.time_of_end_turn_1)+'",'+nl;
 s:=s+' "time_of_end_turn_2":"'+stri(savo.head.time_of_end_turn_2)+'",'+nl;
 s:=s+' "turn_mode_1":"'+stri(savo.head.turn_mode_1)+'",'+nl;
 s:=s+' "turn_mode_2":"'+stri(savo.head.turn_mode_2)+'",'+nl;
 s:=s+' "sgold":"'+stri(savo.head.sgold)+'",'+nl;
 s:=s+' "type_of_end":"'+stri(savo.head.type_of_end)+'",'+nl;
 s:=s+' "amt_to_end":"'+stri(savo.head.amt_to_end)+'",'+nl;
 s:=s+' "start_raw":"'+stri(savo.head.start_raw)+'",'+nl;
 s:=s+' "start_fuel":"'+stri(savo.head.start_fuel)+'",'+nl;
 s:=s+' "start_gold":"'+stri(savo.head.start_gold)+'",'+nl;
 s:=s+' "start_alien":"'+stri(savo.head.start_alien)+'"'+nl;
 s:=s+'},'+nl;
 s:=s+'"map":"'+def_maps[savo.head.map_id_1]+'",'+nl;
 s:=s+'"plr_count":"'+stri(savo.plr_count)+'",'+nl;
 s:=s+'"unitcnt":"'+stri(savo.unitcnt)+'",'+nl;
 s:=s+'"unitstart":"'+stri(savo.unitstart)+'",'+nl;

 s:=s+'"game_state":"'+stri(savo.game_state)+'",'+nl;
 s:=s+'"victory_state":"'+stri(savo.victory_state)+'",'+nl;
 s:=s+'"cur_turn":"'+stri(savo.cur_turn)+'",'+nl;
 s:=s+'"doing_turn":"'+stri(savo.doing_turn)+'",'+nl;
 s:=s+'"turn_status":"'+stri(savo.turn_status)+'",'+nl;
 s:=s+'"anim_effects":"'+stri(savo.anim_effects)+'",'+nl;
 s:=s+'"click_scroll":"'+stri(savo.click_scroll)+'",'+nl;
 s:=s+'"scroll_speed":"'+stri(savo.scroll_speed)+'",'+nl;
 s:=s+'"double_steps":"'+stri(savo.double_steps)+'",'+nl;
 s:=s+'"track_selected":"'+stri(savo.track_selected)+'",'+nl;
 s:=s+'"auto_select":"'+stri(savo.auto_select)+'",'+nl;
 s:=s+'"enemy_halt":"'+stri(savo.enemy_halt)+'",'+nl;
 s:=s+'"enemy_halt":"'+stri(savo.enemy_halt)+'",'+nl;

 s1:='['+nl;
 for i:=0 to 3 do begin
  s1:=s1+' {'+nl;
  s1:=s1+'  "plr_type":"'+stri(savo.pi[i].plr_type)+'",'+nl;
  s1:=s1+'  "unk0":"'+stri(savo.pi[i].unk0)+'",'+nl;
  s1:=s1+'  "clan":"'+stri(savo.pi[i].clan)+'",'+nl;
  s1:=s1+'  "score":"'+stri(savo.pi[i].score)+'",'+nl;
  s1:=s1+'  "object_count":"'+stri(savo.pi[i].object_count)+'",'+nl;
  s1:=s1+'  "selunit":"'+stri(savo.pi[i].selunit)+'",'+nl;
  s1:=s1+'  "zoom":"'+stri(savo.pi[i].zoom)+'",'+nl;
  s1:=s1+'  "xoff":"'+stri(savo.pi[i].xoff)+'",'+nl;
  s1:=s1+'  "yoff":"'+stri(savo.pi[i].yoff)+'",'+nl;
  s1:=s1+'  "factories_built":"'+stri(savo.pi[i].factories_built)+'",'+nl;
  s1:=s1+'  "mines_built":"'+stri(savo.pi[i].mines_built)+'",'+nl;
  s1:=s1+'  "buildings_built":"'+stri(savo.pi[i].buildings_built)+'",'+nl;
  s1:=s1+'  "units_built":"'+stri(savo.pi[i].units_built)+'",'+nl;
  s1:=s1+'  "goldused":"'+stri(savo.pi[i].goldused)+'",'+nl;
  s1:=s1+'  "buttons":[';for j:=0 to 10 do begin if j<>0 then s1:=s1+',';s1:=s1+stri(savo.pi[i].buttons[j]);end;s1:=s1+'],'+nl;
  s1:=s1+'  "loses":[';for j:=0 to 185 do begin if j<>0 then s1:=s1+',';s1:=s1+stri(savo.pi[i].loses[j]);end;s1:=s1+'],'+nl;
  s1:=s1+'  "scoregraph":[';for j:=0 to 49 do begin if j<>0 then s1:=s1+',';s1:=s1+stri(savo.pi[i].scoregraph[j]);end;s1:=s1+'],'+nl;
  s1:=s1+'  "unit_counters":[';for j:=0 to 92 do begin if j<>0 then s1:=s1+',';s1:=s1+stri(savo.pi[i].unit_counters[j]);end;s1:=s1+'],'+nl;
  s1:=s1+'  "FF1":[';for j:=0 to 39 do begin if j<>0 then s1:=s1+',';s1:=s1+'"'+strhex2(savo.pi[i].FF1[j])+'"';end;s1:=s1+'],'+nl;
  s1:=s1+'  "FF2":[';for j:=0 to 11 do begin if j<>0 then s1:=s1+',';s1:=s1+'"'+strhex2(savo.pi[i].FF2[j])+'"';end;s1:=s1+'],'+nl;
  s1:=s1+'  "research":[';for j:=0 to 7 do begin if j<>0 then s1:=s1+',';s1:=s1+'{"now":'+stri(savo.pi[i].research[j].now)+',"unk":'+stri(savo.pi[i].research[j].unk)+',"labs":'+stri(savo.pi[i].research[j].labs)+'}';end;s1:=s1+']'+nl;
  s1:=s1+' },'+nl;
 end;
 s1:=s1+'],'+nl;
 s:=s+'"player_info":'+s1;

 s:=s+'"update_cnt":[';for i:=0 to 3 do begin if i<>0 then s:=s+',';s:=s+stri(savo.update_cnt[i]);end;s:=s+'],'+nl;
 s:=s+'"plr_gold":[';for i:=0 to 3 do begin if i<>0 then s:=s+',';s:=s+stri(savo.plr_gold[i]);end;s:=s+'],'+nl;
 s:=s+'"unsel_count":"'+stri(savo.unsel_count)+'",'+nl;
 s:=s+'"moving_count":"'+stri(savo.moving_count)+'",'+nl;
 s:=s+'"bldg_count":"'+stri(savo.bldg_count)+'",'+nl;
 s:=s+'"air_count":"'+stri(savo.air_count)+'",'+nl;
 s:=s+'"postunits_unk":[';for i:=0 to 7 do begin if i<>0 then s:=s+',';s:=s+stri(savo.postunits_unk[i]);end;s:=s+'],'+nl;
 s:=s+'"msg_cnt":[';for i:=0 to 3 do begin if i<>0 then s:=s+',';s:=s+stri(savo.msg_cnt[i]);end;s:=s+'],'+nl;
 s:=s+'"restsize":"'+stri(savo.restsize)+'",'+nl;

 s1:='['+nl;
 for i:=0 to length(savo.objlst)-1 do begin
  if i<>0 then s1:=s1+','+nl;
  s1:=s1+' {';
  s1:=s1+'"id":' +trimsl('"'+stri(savo.objlst[i].id)+'"',5,' ')+',';
  s1:=s1+'"tp":"'+stri(savo.objlst[i].tp)+'"';
  case savo.objlst[i].tp of
   3:begin
    pur:=savo.objlst[i].info;
    s1:=s1+',post_updates:[';
    for j:=0 to 13 do begin if j<>0 then s1:=s1+',';s1:=s1+stri(pur.val[j]);end;
    s1:=s1+']';
   end;
   5:begin
    udr:=savo.objlst[i].info;
    s1:=s1+',unit_def:{';
    s1:=s1+'"unid":'+trimsl('"'+stri(udr.unid)+'"',5,' ')+',';
    s1:=s1+'"flags":"'+strhex(udr.flags)+'",';
    s1:=s1+'"owner":"'+stri(udr.owner)+'",';
    s1:=s1+'"rot":"'+stri(udr.rot)+'",';
    s1:=s1+'"gun_rot":'+trimsl('"'+stri(udr.gun_rot)+'"',5,' ')+',';
    s1:=s1+'"unit_number":'+trimsl('"'+stri(udr.unit_number)+'"',5,' ')+',';
    s1:=s1+'"state":"'+stri(udr.state)+'",';
    s1:=s1+'"x_pos":'+trimsl('"'+stri(udr.x_pos)+'"',5,' ')+',';
    s1:=s1+'"y_pos":'+trimsl('"'+stri(udr.y_pos)+'"',5,' ')+',';
    s1:=s1+'"x_graphic":'+trimsl('"'+stri(udr.x_graphic)+'"',6,' ')+',';
    s1:=s1+'"y_graphic":'+trimsl('"'+stri(udr.y_graphic)+'"',6,' ')+',';
    s1:=s1+'"shadow_center_x_off":'+trimsl('"'+stri(udr.shadow_center_x_off)+'"',5,' ')+',';
    s1:=s1+'"shadow_center_y_off":'+trimsl('"'+stri(udr.shadow_center_y_off)+'"',5,' ')+',';
    s1:=s1+'"hitsnow":'+trimsl('"'+stri(udr.hitsnow)+'"',5,' ')+',';
    s1:=s1+'"speednow":'+trimsl('"'+stri(udr.speednow)+'"',5,' ')+',';
    s1:=s1+'"shotnow":'+trimsl('"'+stri(udr.shotnow)+'"',5,' ')+',';
    s1:=s1+'"shotmove":'+trimsl('"'+stri(udr.shotmove)+'"',5,' ')+',';
    s1:=s1+'"cargonow":'+trimsl('"'+stri(udr.cargonow)+'"',5,' ')+',';
    s1:=s1+'"ammonow":'+trimsl('"'+stri(udr.ammonow)+'"',5,' ')+',';
    s1:=s1+'"unk_byte_1":'+trimsl('"'+stri(udr.unk_byte_1)+'"',5,' ')+',';
    s1:=s1+'"unk_byte_2":'+trimsl('"'+stri(udr.unk_byte_2)+'"',5,' ')+',';
    s1:=s1+'"brightness":"'+stri(udr.brightness)+'",';
    s1:=s1+'"vis_red":"'+stri(udr.vis_red)+'",';
    s1:=s1+'"vis_green":"'+stri(udr.vis_green)+'",';
    s1:=s1+'"vis_blue":"'+stri(udr.vis_blue)+'",';
    s1:=s1+'"vis_gray":"'+stri(udr.vis_gray)+'",';
    s1:=s1+'"vis_alien":"'+stri(udr.vis_alien)+'",';
    s1:=s1+'"spotted_red":"'+stri(udr.spotted_red)+'",';
    s1:=s1+'"spotted_green":"'+stri(udr.spotted_green)+'",';
    s1:=s1+'"spotted_blue":"'+stri(udr.spotted_blue)+'",';
    s1:=s1+'"spotted_gray":"'+stri(udr.spotted_gray)+'",';
    s1:=s1+'"spotted_alien":"'+stri(udr.spotted_alien)+'",';
    s1:=s1+'"ubv5":'+trimsl('"'+stri(udr.ubv5)+'"',5,' ')+',';
    s1:=s1+'"velocity":'+trimsl('"'+stri(udr.velocity)+'"',4,' ')+',';
    s1:=s1+'"is_stored":"'+stri(udr.is_stored)+'",';
    s1:=s1+'"udv1":[';for j:=0 to 7 do begin if j<>0 then s1:=s1+',';s1:=s1+trimsl('"'+stri(udr.udv1[j])+'"',6,' ');end;s1:=s1+'],';
    s1:=s1+'"ub2v2":'+trimsl('"'+stri(udr.ub2v2)+'"',5,' ')+',';
    s1:=s1+'"ub2v3":'+trimsl('"'+stri(udr.ub2v3)+'"',5,' ')+',';
    s1:=s1+'"total_images":'+trimsl('"'+stri(udr.total_images)+'"',6,' ')+',';
    s1:=s1+'"image_base":'+trimsl('"'+stri(udr.image_base)+'"',4,' ')+',';
    s1:=s1+'"turret_image_base":'+trimsl('"'+stri(udr.turret_image_base)+'"',4,' ')+',';
    s1:=s1+'"firing_image_base":'+trimsl('"'+stri(udr.firing_image_base)+'"',4,' ')+',';
    s1:=s1+'"connector_image_base":'+trimsl('"'+stri(udr.connector_image_base)+'"',4,' ')+',';
    s1:=s1+'"base_sprite":'+trimsl('"'+stri(udr.base_sprite)+'"',4,' ')+',';
    s1:=s1+'"uwv6b":'+trimsl('"'+stri(udr.uwv6b)+'"',4,' ')+',';
    s1:=s1+'"anim_sprite_1":'+trimsl('"'+stri(udr.anim_sprite_1)+'"',5,' ')+',';
    s1:=s1+'"uwv8":'+trimsl('"'+stri(udr.uwv8)+'"',7,' ')+',';
    s1:=s1+'"orders":'+trimsl('"'+stri(udr.orders)+'"',4,' ')+',';
    s1:=s1+'"state_done":"'+stri(udr.state_done)+'",';
    s1:=s1+'"prior_orders":'+trimsl('"'+stri(udr.prior_orders)+'"',4,' ')+',';
    s1:=s1+'"prior_state":"'+stri(udr.prior_state)+'",';
    s1:=s1+'"ub2v8":"'+stri(udr.ub2v8)+'",';
    s1:=s1+'"target_x":'+trimsl('"'+stri(udr.target_x)+'"',5,' ')+',';
    s1:=s1+'"target_y":'+trimsl('"'+stri(udr.target_y)+'"',5,' ')+',';
    s1:=s1+'"turns_left_base":"'+stri(udr.turns_left_base)+'",';
    s1:=s1+'"mining_tot_sel":'+trimsl('"'+stri(udr.mining_tot_sel)+'"',4,' ')+',';
    s1:=s1+'"mining_res_sel":'+trimsl('"'+stri(udr.mining_res_sel)+'"',4,' ')+',';
    s1:=s1+'"mining_ful_sel":'+trimsl('"'+stri(udr.mining_ful_sel)+'"',4,' ')+',';
    s1:=s1+'"mining_gld_sel":'+trimsl('"'+stri(udr.mining_gld_sel)+'"',4,' ')+',';
    s1:=s1+'"mining_res_avl":'+trimsl('"'+stri(udr.mining_res_avl)+'"',4,' ')+',';
    s1:=s1+'"mining_ful_avl":'+trimsl('"'+stri(udr.mining_ful_avl)+'"',4,' ')+',';
    s1:=s1+'"mining_gld_avl":'+trimsl('"'+stri(udr.mining_gld_avl)+'"',4,' ')+',';
    s1:=s1+'"targeting_mode":'+trimsl('"'+stri(udr.targeting_mode)+'"',5,' ')+',';
    s1:=s1+'"enter_mode":'+trimsl('"'+stri(udr.enter_mode)+'"',5,' ')+',';
    s1:=s1+'"cursor":"'+stri(udr.cursor)+'",';
    s1:=s1+'"recoil_delay":'+trimsl('"'+stri(udr.recoil_delay)+'"',5,' ')+',';
    s1:=s1+'"delayed_reaction":"'+stri(udr.delayed_reaction)+'",';
    s1:=s1+'"damaged_this_turn":"'+stri(udr.damaged_this_turn)+'",';
    s1:=s1+'"research_topic":"'+stri(udr.research_topic)+'",';
    s1:=s1+'"repeat_build":"'+stri(udr.repeat_build)+'",';
    s1:=s1+'"bld_speed":"'+stri(udr.bld_speed)+'",';
    s1:=s1+'"connectors":'+trimsl('"'+stri(udr.connectors)+'"',5,' ')+',';
    s1:=s1+'"is_build_n":"'+stri(udr.is_build_n)+'",';
    s1:=s1+'"unk_arr_4":[';for j:=0 to 8 do begin if j<>0 then s1:=s1+',';s1:=s1+trimsl(stri(udr.unk_arr_4[j]),3,' ');end;s1:=s1+'],';
    s1:=s1+'"unk_obj_1":'+str_ob(udr.unk_obj_1)+',';
    s1:=s1+'"unk_obj_2":'+str_ob(udr.unk_obj_2)+',';
    s1:=s1+'"unk_obj_3":'+str_ob(udr.unk_obj_3)+',';
    s1:=s1+'"pathobj":'+str_ob(udr.pathobj)+',';
    s1:=s1+'"object_used":'+str_ob(udr.object_used)+',';
    s1:=s1+'"unk_obj_4":'+str_ob(udr.unk_obj_4)+',';
    s1:=s1+'"inside_obj":'+str_ob(udr.inside_obj)+',';
    s1:=s1+'"unk_obj_5":'+str_ob(udr.unk_obj_5)+',';
    s1:=s1+'"build_unit_num":[';for j:=0 to length(udr.build_unit_num)-1 do begin if j<>0 then s1:=s1+',';s1:=s1+stri(udr.build_unit_num[j]);end;s1:=s1+'],';
    s1:=s1+'"custom_name":"'+udr.custom_name+'",';
    s1:=s1+'"typ":"'+uninames[udr.unid][0]+'"';
    s1:=s1+'}';
   end;
   6:begin
    upr:=savo.objlst[i].info;
    s1:=s1+',unit_pars:{';
    s1:=s1+'"cost":' +trimsl('"'+stri(upr.cost )+'"',4,' ')+',';
    s1:=s1+'"hits":' +trimsl('"'+stri(upr.hits )+'"',4,' ')+',';
    s1:=s1+'"armr":' +trimsl('"'+stri(upr.armr )+'"',4,' ')+',';
    s1:=s1+'"attk":' +trimsl('"'+stri(upr.attk )+'"',4,' ')+',';
    s1:=s1+'"speed":'+trimsl('"'+stri(upr.speed)+'"',4,' ')+',';
    s1:=s1+'"range":'+trimsl('"'+stri(upr.range)+'"',4,' ')+',';
    s1:=s1+'"shot":' +trimsl('"'+stri(upr.shot )+'"',4,' ')+',';
    s1:=s1+'"movnf":'+trimsl('"'+stri(upr.movnf)+'"',4,' ')+',';
    s1:=s1+'"scan":' +trimsl('"'+stri(upr.scan )+'"',4,' ')+',';
    s1:=s1+'"store":'+trimsl('"'+stri(upr.store)+'"',4,' ')+',';
    s1:=s1+'"ammo":' +trimsl('"'+stri(upr.ammo )+'"',4,' ')+',';
    s1:=s1+'"area":' +trimsl('"'+stri(upr.area )+'"',4,' ')+',';
    s1:=s1+'"z31":'  +trimsl('"'+stri(upr.z31  )+'"',4,' ')+',';
    s1:=s1+'"unk0":' +trimsl('"'+stri(upr.unk0 )+'"',4,' ')+',';
    s1:=s1+'"unk1":' +trimsl('"'+stri(upr.unk1 )+'"',4,' ')+',';
    s1:=s1+'"unk2":' +trimsl('"'+stri(upr.unk2 )+'"',4,' ')+',';
    s1:=s1+'"unk3":' +trimsl('"'+stri(upr.unk3 )+'"',4,' ')+'';
    s1:=s1+'}';
   end;
   //else begin writeln('Error: Unknown object(tp=',tp,', id=',id,')');halt;end;
  end;
  s1:=s1+'}';
 end;
 s1:=s1+nl+'],'+nl;
 s:=s+'"objlst":'+s1;

 s:=s+'}'+nl;

 free_maxsave(savo);

 {
 plr_obs_a:array[0..3]of array[0..93*2-1]of ob_word;
 plr_obs_b:array[0..3]of array of ob_word;
 unsel_obs,moving_obs,bldg_obs,air_obs:array of ob_word;
 unk_post_1:array of unk_1_rec;
 scan_map:array[0..3]of array[0..12543]of byte;
 corvett_map:array[0..3]of array[0..12543]of byte;
 infantry_map:array[0..3]of array[0..12543]of byte;
 mesgs:array[0..3]of array of mesgrec;
 restof:pointer;
 }

 assignfile(f,ext+'_'+fn+'.txt');
 rewrite(f,1);
 blockwrite(f,s[1],length(s));
 closefile(f);
end;
//############################################################################//
procedure main;
var i:integer;
begin
 for i:=1 to  9 do convert_one_save('saves/cam/','save'+stri(i),'cam');

 convert_one_save('saves/dmo/','save1','dmo');

 for i:=1 to  6 do convert_one_save('saves/cam/','save'+stri(i),'cam');
 for i:=1 to 24 do convert_one_save('saves/sce/','save'+stri(i),'sce');
 for i:=1 to 14 do convert_one_save('saves/tra/','save'+stri(i),'tra');
 for i:=1 to 100 do convert_one_save('saves/hot/','save'+stri(i),'hot');

 writeln('Done.');
end;
//############################################################################//
begin
 main;
end.
//############################################################################//
