//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//Max saves loading
//############################################################################/
unit maxsaves;
interface
uses asys,strval,maxsavesrec;
//############################################################################//
procedure loadmaxosave(out savo:saveorec;s:string);
procedure loadmaxosave_mem(out savo:saveorec;buf:pointer;bs:integer);
procedure writemaxosave(var savo:saveorec;s:string);
procedure free_maxsave(var savo:saveorec);

procedure getres(var savo:saveorec;x,y:integer;var plr,amt,tp:integer);
function  str_state(n:byte):string;
//############################################################################//
implementation
//############################################################################//
function readobj(var savo:saveorec;buf:pointer;var bp:integer):ob_word;forward;
procedure writeobj(n:integer;full:boolean;var savo:saveorec;var inf:file);forward;
//############################################################################//
//############################################################################//
//############################################################################//
procedure readunidefpath(var savo:saveorec;buf:pointer;var bp:integer;var p:path_def_block);
var i:integer;
//z:word;
procedure bread(p:pointer;sz:integer);begin move(pdword(intptr(buf)+dword(bp))^,p^,sz);bp:=bp+sz;end;
begin
 bread(@p.target_x,2);
 bread(@p.target_y,2);
 bread(@p.zero1,2);
 bread(@p.cnt,2);
 setlength(p.path,p.cnt);
 for i:=0 to p.cnt-1 do bread(@p.path[i],2);
end;
//############################################################################//
procedure readunidef(var savo:saveorec;buf:pointer;var bp:integer;var u:unit_def_record);
var i:integer;
procedure bread(p:pointer;sz:integer);begin move(pdword(intptr(buf)+dword(bp))^,p^,sz);bp:=bp+sz;end;
begin
 bread(@u.unid,18);
 if u.custom_name_length<>0 then begin
  setlength(u.custom_name,u.custom_name_length);
  bread(@u.custom_name[1],u.custom_name_length);
 end;
 bread(@u.shadow_center_x_off,134-18);

 bread(@u.unk_obj_1,2);
 bread(@u.unk_obj_2,2);
 bread(@u.unk_obj_3,2);
 u.pathobj:=readobj(savo,buf,bp);
 bread(@u.connectors,2);
 u.object_used:=readobj(savo,buf,bp);
 u.unk_obj_4:=readobj(savo,buf,bp);
 u.inside_obj:=readobj(savo,buf,bp);
 u.unk_obj_5:=readobj(savo,buf,bp);

 bread(@u.is_build_n,2);
 setlength(u.build_unit_num,u.is_build_n);
 for i:=0 to u.is_build_n-1 do bread(@u.build_unit_num[i],2);
end;
//############################################################################//
//############################################################################//
//############################################################################//
//############################################################################//
function readobj(var savo:saveorec;buf:pointer;var bp:integer):ob_word;
var id,tp,n:word;
upr:punit_pars_record;
pur:ppost_updates_record;
udr:punit_def_record;
pdb:ppath_def_block;
p:pointer;
procedure bread(p:pointer;sz:integer);begin move(pdword(intptr(buf)+dword(bp))^,p^,sz);bp:=bp+sz;end;
begin
 bread(@id,2);
 result.ob:=id;
 result.full:=false;
 if id<>savo.last_obj+1 then begin
  //writeln(id,' ',savo.last_obj+1);
  exit;
 end;
 result.full:=true;
 bread(@tp,2);

 n:=savo.last_obj;
 setlength(savo.objlst,n+1);
 savo.last_obj:=savo.last_obj+1;

 savo.objlst[n].id:=id;
 savo.objlst[n].tp:=tp;

 case tp of
  1:begin getmem(p,27);bread(p,27);savo.objlst[n].info:=p;end;
  3:begin new(pur);bread(pur,14);savo.objlst[n].info:=pur;end;
  4:begin new(pdb);readunidefpath(savo,buf,bp,pdb^);savo.objlst[n].info:=pdb;end;
  5:begin new(udr);readunidef(savo,buf,bp,udr^);savo.objlst[n].info:=udr;end;
  6:begin new(upr);bread(upr,28);savo.objlst[n].info:=upr;end;
  else begin writeln('Error: Unknown object(tp=',tp,', id=',id,')');halt;end;
  //else halt;
 end;
end;
//############################################################################//
//############################################################################//
//############################################################################//
procedure writeunidefpath(var savo:saveorec;var inf:file;var p:path_def_block);
var i:integer;
begin
 blockwrite(inf,p.target_x,2);
 blockwrite(inf,p.target_y,2);
 blockwrite(inf,p.zero1,2);
 blockwrite(inf,p.cnt,2);
 for i:=0 to p.cnt-1 do blockwrite(inf,p.path[i],2);
end;
//############################################################################//
procedure writeunidef(var savo:saveorec;var inf:file;var u:unit_def_record);
var i:integer;
begin
 blockwrite(inf,u.unid,18);
 if u.custom_name_length<>0 then blockwrite(inf,u.custom_name[1],u.custom_name_length);
 blockwrite(inf,u.shadow_center_x_off,134-18);

 blockwrite(inf,u.unk_obj_1,2);
 blockwrite(inf,u.unk_obj_2,2);
 blockwrite(inf,u.unk_obj_3,2);
 writeobj(u.pathobj.ob,u.pathobj.full,savo,inf);
 blockwrite(inf,u.connectors,2);
 writeobj(u.object_used.ob,u.object_used.full,savo,inf);
 writeobj(u.unk_obj_4.ob,u.unk_obj_4.full,savo,inf);
 writeobj(u.inside_obj.ob,u.inside_obj.full,savo,inf);
 writeobj(u.unk_obj_5.ob,u.unk_obj_5.full,savo,inf);

 blockwrite(inf,u.is_build_n,2);
 for i:=0 to u.is_build_n-1 do blockwrite(inf,u.build_unit_num[i],2);
end;
//############################################################################//
//############################################################################//
//############################################################################//
procedure writeobj(n:integer;full:boolean;var savo:saveorec;var inf:file);
begin
 if(n<0)or(n>=length(savo.objlst))then exit;
 blockwrite(inf,savo.objlst[n].id,2);
 if not full then exit;
 blockwrite(inf,savo.objlst[n].tp,2);

 case savo.objlst[n].tp of
  1:blockwrite(inf,savo.objlst[n].info^,27);
  3:blockwrite(inf,savo.objlst[n].info^,14);
  4:writeunidefpath(savo,inf,ppath_def_block(savo.objlst[n].info)^);
  5:writeunidef(savo,inf,punit_def_record(savo.objlst[n].info)^);
  6:blockwrite(inf,savo.objlst[n].info^,28);
 end;
end;
//############################################################################//
//############################################################################//
//############################################################################//
procedure loadmaxosave_mem(out savo:saveorec;buf:pointer;bs:integer);
var head156:header156;
head104:header104;
i,j,bp:integer;
procedure bread(p:pointer;sz:integer);begin move(pdword(intptr(buf)+dword(bp))^,p^,sz);bp:=bp+sz;end;
begin
 bp:=0;
 savo.last_obj:=0;
 setlength(savo.objlst,0);

 //Header
 bread(@savo.id,2);
 case savo.id of
  HD104:bread(@head104,sizeof(head104));
  HD156:bread(@head156,sizeof(head156));
 end;
 case savo.id of
  HD104:savo.head:=head104;
  HD156:begin
   move(head156,savo.head,$9E);
   move(pbyte(intptr(@head156)+$9F)^,pbyte(intptr(@savo.head)+$A4)^,$3A);
  end;
 end;

 savo.plr_count:=ord(savo.head.plr_type[0]>0)+ord(savo.head.plr_type[1]>0)+ord(savo.head.plr_type[2]>0)+ord(savo.head.plr_type[3]>0);

 //Maps
 bread(@savo.pasmap,12544);
 bread(@savo.resmap,25088);

 //Player info
 for i:=0 to 3 do bread(@savo.pi[i],sizeof(player_info));

 //Status
 bread(@savo.doing_turn,1);
 bread(@savo.turn_status,1);
 bread(@savo.cur_turn,4);
 bread(@savo.game_state,2);
 bread(@savo.victory_state,2);

 //Options
 bread(@savo.anim_effects,4);
 bread(@savo.click_scroll,4);
 bread(@savo.scroll_speed,4);
 bread(@savo.double_steps,4);
 bread(@savo.track_selected,4);
 bread(@savo.auto_select,4);
 if savo.id=HD104 then bread(@savo.enemy_halt,4);

 //Player records
 for j:=0 to 3 do begin
  bread(@savo.plr_gold[j],2);
  for i:=0 to 93*2-1 do savo.plr_obs_a[j][i]:=readobj(savo,buf,bp);
  bread(@savo.update_cnt[j],2);
  setlength(savo.plr_obs_b[j],savo.update_cnt[j]);
  for i:=0 to savo.update_cnt[j]-1 do savo.plr_obs_b[j][i]:=readobj(savo,buf,bp);
 end;

 savo.unitstart:=savo.last_obj;
 //Unit objects
 bread(@savo.unsel_count,2); setlength(savo.unsel_obs ,savo.unsel_count); for i:=0 to savo.unsel_count-1  do savo.unsel_obs[i] :=readobj(savo,buf,bp);
 bread(@savo.moving_count,2);setlength(savo.moving_obs,savo.moving_count);for i:=0 to savo.moving_count-1 do savo.moving_obs[i]:=readobj(savo,buf,bp);
 bread(@savo.bldg_count,2);  setlength(savo.bldg_obs  ,savo.bldg_count);  for i:=0 to savo.bldg_count-1   do savo.bldg_obs[i]  :=readobj(savo,buf,bp);
 bread(@savo.air_count,2);   setlength(savo.air_obs   ,savo.air_count);   for i:=0 to savo.air_count-1    do savo.air_obs[i]   :=readobj(savo,buf,bp);

 savo.unitcnt:=savo.unsel_count+savo.moving_count+savo.bldg_count+savo.air_count;
 savo.mg_unitcnt:=0;
 for i:=savo.unitstart to length(savo.objlst)-1 do begin
  if savo.objlst[i].tp<>5 then continue;
  //if savo.objlst[i].unkf17<>0 then continue;
  if uninames[punit_def_record(savo.objlst[i].info).unid][2]='-' then continue;
  if uninames[punit_def_record(savo.objlst[i].info).unid][2]='' then continue;
  savo.mg_unitcnt:= savo.mg_unitcnt+1;
 end;

 bread(@savo.postunits_unk[0],8);

 setlength(savo.unk_post_1,1);
 j:=0;
 repeat
  if j>=length(savo.unk_post_1) then setlength(savo.unk_post_1,2*j);
  bread(@savo.unk_post_1[j],6);
  if(savo.unk_post_1[j].a=$0200)and(savo.unk_post_1[j].b=$0002)then break;
  j:=j+1;
 until j>10000;
 setlength(savo.unk_post_1,j);

 //if savo.maphead.pltr<>0 then bread(@savo.scanmapr,12544);
 //if savo.maphead.pltr<>0 then bread(@savo.hz1mapr,12544);
 //if savo.maphead.pltr<>0 then bread(@savo.hz2mapr,12544);
 //if savo.maphead.pltg<>0 then bread(@savo.scanmapg,12544);
 //if savo.maphead.pltg<>0 then bread(@savo.hz1mapg,12544);
 //if savo.maphead.pltg<>0 then bread(@savo.hz2mapg,12544);
 //if savo.maphead.pltb<>0 then bread(@savo.scanmapb,12544);
 //if savo.maphead.pltb<>0 then bread(@savo.hz1mapb,12544);
 //if savo.maphead.pltb<>0 then bread(@savo.hz1mapb,12544);
 //if savo.maphead.plty<>0 then bread(@savo.scanmapy,12544);
 //if savo.maphead.plty<>0 then bread(@savo.hz1mapy,12544);
 //if savo.maphead.plty<>0 then bread(@savo.hz2mapy,12544);


 savo.restsize:=bs-bp;
 getmem(savo.restof,savo.restsize);
 bread(savo.restof,savo.restsize);
end;
//############################################################################//
procedure loadmaxosave(out savo:saveorec;s:string);
var inf:file;
buf:pointer;
bs:integer;
begin
 assignfile(inf,s);
 FileMode:=0;
 reset(inf,1);

 bs:=filesize(inf);
 getmem(buf,bs);
 blockread(inf,buf^,bs);
 if ioresult<>0 then begin end;
 closefile(inf);

 loadmaxosave_mem(savo,buf,bs);
 freemem(buf);
end;
//############################################################################//
procedure free_maxsave(var savo:saveorec);
var n:integer;
//upr:punit_pars_record;
//pur:ppost_updates_record;
//udr:punit_def_record;
//pdb:ppath_def_block;
begin
 for n:=0 to length(savo.objlst)-1 do case savo.objlst[n].tp of
  1:freemem(savo.objlst[n].info,27);
  3:dispose(ppost_updates_record(savo.objlst[n].info));
  4:dispose(ppath_def_block(savo.objlst[n].info));
  5:dispose(punit_def_record(savo.objlst[n].info));
  6:dispose(punit_pars_record(savo.objlst[n].info));
 end;
 freemem(savo.restof);
end;
//############################################################################//
//############################################################################//
procedure writemaxosave(var savo:saveorec;s:string);
var inf:file;
i,j:integer;
begin
 assignfile(inf,s);
 rewrite(inf,1);


 savo.id:=HD104;

 savo.head.creation_time:=0;
 savo.head.game_name:='Testus';

 for i:=0 to 3 do begin
  //savo.pi[i].unk0:=0;
  //savo.pi[i].object_count:=0;
  //savo.pi[i].selunit:=0;
 end;

 for i:=0 to length(savo.objlst)-1 do begin
  if savo.objlst[i].tp=6 then begin
   punit_pars_record(savo.objlst[i].info)^.z31:=0;
   punit_pars_record(savo.objlst[i].info)^.unk0:=0;
   punit_pars_record(savo.objlst[i].info)^.unk1:=0;
   punit_pars_record(savo.objlst[i].info)^.unk2:=0;
   punit_pars_record(savo.objlst[i].info)^.unk3:=0;
  end;
  if savo.objlst[i].tp=5 then begin
   punit_def_record(savo.objlst[i].info)^.unk_byte_1:=0;
   punit_def_record(savo.objlst[i].info)^.unk_byte_2:=0;
   punit_def_record(savo.objlst[i].info)^.unit_number:=i;
   punit_def_record(savo.objlst[i].info)^.ubv5:=0;
   //punit_def_record(savo.objlst[i].info)^.
  end;
 end;


 //Header
 blockwrite(inf,savo.id,2);
 case savo.id of
  HD104:blockwrite(inf,savo.head,sizeof(header104));
  HD156:begin
   blockwrite(inf,savo.head,$9F);
   blockwrite(inf,savo.head.creation_time,$3A);
  end;
 end;

 //Maps
 blockwrite(inf,savo.pasmap,12544);
 blockwrite(inf,savo.resmap,25088);

 //Player info
 for i:=0 to 3 do blockwrite(inf,savo.pi[i],sizeof(player_info));

 //Status
 blockwrite(inf,savo.doing_turn,1);
 blockwrite(inf,savo.turn_status,1);
 blockwrite(inf,savo.cur_turn,4);
 blockwrite(inf,savo.game_state,2);
 blockwrite(inf,savo.victory_state,2);

 //Options
 blockwrite(inf,savo.anim_effects,4);
 blockwrite(inf,savo.click_scroll,4);
 blockwrite(inf,savo.scroll_speed,4);
 blockwrite(inf,savo.double_steps,4);
 blockwrite(inf,savo.track_selected,4);
 blockwrite(inf,savo.auto_select,4);
 if savo.id=HD104 then blockwrite(inf,savo.enemy_halt,4);

 //c:=0;
 for j:=0 to 3 do begin
  blockwrite(inf,savo.plr_gold[j],2);
  for i:=0 to 93*2-1 do writeobj(savo.plr_obs_a[j][i].ob,savo.plr_obs_a[j][i].full,savo,inf);
  blockwrite(inf,savo.update_cnt[j],2);
  for i:=0 to savo.update_cnt[j]-1 do writeobj(savo.plr_obs_b[j][i].ob,savo.plr_obs_b[j][i].full,savo,inf);
 end;

 blockwrite(inf,savo.unsel_count,2); for i:=0 to savo.unsel_count-1  do writeobj(savo.unsel_obs [i].ob,savo.unsel_obs [i].full,savo,inf);
 blockwrite(inf,savo.moving_count,2);for i:=0 to savo.moving_count-1 do writeobj(savo.moving_obs[i].ob,savo.moving_obs[i].full,savo,inf);
 blockwrite(inf,savo.bldg_count,2);  for i:=0 to savo.bldg_count-1   do writeobj(savo.bldg_obs  [i].ob,savo.bldg_obs  [i].full,savo,inf);
 blockwrite(inf,savo.air_count,2);   for i:=0 to savo.air_count-1    do writeobj(savo.air_obs   [i].ob,savo.air_obs   [i].full,savo,inf);




 blockwrite(inf,savo.restof^,savo.restsize);

 if ioresult<>0 then begin end;
 closefile(inf);
end;
//############################################################################//
procedure getres(var savo:saveorec;x,y:integer;var plr,amt,tp:integer);
var i:integer;
begin
 i:=x+y*112;
 tp:=0;amt:=0;plr:=0;
 if(savo.resmap[i*2]<>$80)and(savo.resmap[i*2]<>0)then begin
  if(savo.resmap[i*2]>$20)and(savo.resmap[i*2]<$31)then begin tp:=2; amt:=savo.resmap[i*2]-$20-1; end;
  if(savo.resmap[i*2]>$40)and(savo.resmap[i*2]<$51)then begin tp:=3; amt:=savo.resmap[i*2]-$40-1; end;
  if(savo.resmap[i*2]>$80)and(savo.resmap[i*2]<$91)then begin tp:=1; amt:=savo.resmap[i*2]-$80-1; end;
 end;
 plr:=0;
 if savo.resmap[i*2+1]<>0 then begin
  if(savo.resmap[i*2+1] shl 5)shr 7=1 then plr:=plr+1;
  if(savo.resmap[i*2+1] shl 4)shr 7=1 then plr:=plr+2;
  if(savo.resmap[i*2+1] shl 3)shr 7=1 then plr:=plr+4;
  if(savo.resmap[i*2+1] shl 2)shr 7=1 then plr:=plr+8;
 end;
end;
//############################################################################//
function str_state(n:byte):string;
begin
 case n of
   1:result:='Default unit';
   8:result:='Construction';
  16:result:='Default building';
  15:result:='Active building';
  else result:=stri(n);
 end;
end;
//############################################################################//
begin
end.
//############################################################################//
