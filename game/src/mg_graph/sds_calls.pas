//############################################################################//
unit sds_calls;
interface
uses asys,strval,sdirecs,sds_net,sds_util,sds_rec,sds_replies,mgrecs,mgl_common,mgl_json,mgl_land,si_loadsave;
//############################################################################//  
procedure game_request(s:psdi_rec;req,data:string);
procedure sys_request(s:psdi_rec;req,data:string);

procedure do_land_player(s:psdi_rec);
procedure fetch_log(s:psdi_rec);  
procedure set_cdata(s:psdi_rec);
procedure do_fetch_units(s:psdi_rec;lst:string);
procedure set_build(s:psdi_rec;var evt:event_rec);    
procedure set_upgrades(s:psdi_rec;var evt:event_rec);
//############################################################################//
implementation
//############################################################################//
procedure game_request(s:psdi_rec;req,data:string);
var st,rs:string;
begin                                                          
 st:=make_game_request(s.the_game,req,data);
 sds_json_exchange(st,rs,@s.steps.step_progress);
 proc_reply(s,rs,false);
end;
//############################################################################//
procedure sys_request(s:psdi_rec;req,data:string);
var st,rs:string;
begin                                                          
 st:=make_sys_request(req,data);
 sds_json_exchange(st,rs,@s.steps.step_progress);
 proc_reply(s,rs,false);
end;
//############################################################################// 
//############################################################################//
procedure fetch_log(s:psdi_rec);
var cp:pplrtyp;
begin                
 sds_set_message(@s.steps,'Fetching log');
 if s.the_game=nil then exit;  
 cp:=get_cur_plr(s.the_game);   
 if cp=nil then exit;
 game_request(s,'fetch_log',',"from":"'+stri(length(cp.logmsg))+'"');
end;
//############################################################################//
procedure do_fetch_units(s:psdi_rec;lst:string);
begin            
 sds_set_message(@s.steps,'Fetching units');           
 if s.the_game=nil then exit;   
 if lst='' then game_request(s,'fetch_units','')
           else game_request(s,'fetch_units',',"list":['+lst+']');
end;
//############################################################################//
procedure do_land_player(s:psdi_rec);
var cp:pplrtyp;
begin           
 cp:=get_cur_plr(s.the_game);    
 game_request(s,'land_player',',"num":'+stri(cp.num)+',"start":'+pstart_to_json(s.the_game,@plr_begin,true));
end;   
//############################################################################//
procedure set_cdata(s:psdi_rec);
begin                    
 if s.the_game=nil then exit;  
 if get_cur_plr(s.the_game)=nil then exit;
 game_request(s,'set_cdata',',"cdata":"'+bytefy(cdata_to_json(@s.clinfo))+'"');
end;
//############################################################################//
procedure set_build(s:psdi_rec;var evt:event_rec);
var st:string;
u:ptypunits;
i:integer;
begin       
 u:=get_unit(s.the_game,evt.un); 
 if u=nil then exit;                                             
 st:=',"num":'+stri(u.num)+',"reserve":'+stri(u.reserve)+',"builds_cnt":'+stri(u.builds_cnt)+',"builds":['+#$0A;
 for i:=0 to u.builds_cnt-1 do begin  
  st:=st+builds_to_json(@u.builds[i]);    
  if i<>u.builds_cnt-1 then st:=st+','+#$0A;
 end;
 st:=st+']';
          
 game_request(s,'set_build',st);
end; 
//############################################################################//
procedure set_upgrades(s:psdi_rec;var evt:event_rec);
var st,sx:string;
cp:pplrtyp;
i,k:integer;         
rul:prulestyp;
ud:ptypunitsdb; 
u:ptypunits;
begin       
 cp:=get_cur_plr(s.the_game);
 if cp=nil then exit;
 rul:=get_rules(s.the_game);
                               
 st:=',"gold":"'+stri(cp.gold)+'"';
 if rul.direct_gold then begin
  u:=get_sel_unit(s.the_game);
  st:=st+',"unit":"'+stri(u.num)+'"';
 end;
 st:=st+',"unupd":['+#$0A;
 k:=0;
 for i:=0 to length(cp.unupd)-1 do begin
  ud:=get_unitsdb(s.the_game,i);
  if ud<>nil then begin
   cp.unupd[i].typ:=ud.typ;
   sx:=unupd_to_json(@cp.unupd[i]);
   if sx<>'' then begin
    if k<>0 then st:=st+','; 
    st:=st+sx;
    k:=k+1;
   end;
  end;
 end;
 st:=st+']';
          
 game_request(s,'set_upgrades',st);
end; 
//############################################################################//
begin
end.
//############################################################################//
