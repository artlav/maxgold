//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core initialisation routines
//############################################################################//
unit mginit;
interface
uses {$ifdef mswindows}windows,{$endif}asys,mgrecs,mgvars,mgloads,mgauxi
//,mgl_convert
;
//############################################################################//
procedure mg_init_core;  
//############################################################################//
implementation    
//############################################################################//
procedure make_default_settings;
var i:integer;
begin
 mg_core.save_dir :='maxg_srv_data/games';
 mg_core.base_dir :='maxg_srv_data/';
 mg_core.maps_dir :='maxg_srv_data/maps';
 mg_core.units_dir:='maxg_srv_data/unitset';

 mg_core.rules_def.uniset          :='original';
 mg_core.rules_def.moratorium      := 0;
 mg_core.rules_def.moratorium_range:=10;
 mg_core.rules_def.resset          :=120;
 mg_core.rules_def.startradar      :=false;
 mg_core.rules_def.direct_land     :=false;
 mg_core.rules_def.debug           :=false;
 mg_core.rules_def.no_survey       :=false;
 mg_core.rules_def.fueluse         :=true;
 mg_core.rules_def.fuelxfer        :=false;
 mg_core.rules_def.unload_all_shots:=false;
 mg_core.rules_def.unload_all_speed:=false;
 mg_core.rules_def.unload_one_speed:=false;
 mg_core.rules_def.load_sub_one_speed:=false;  
 mg_core.rules_def.load_onpad_only :=false;  
 mg_core.rules_def.nopaswds        :=false;
 mg_core.rules_def.no_buy_atk      :=false;
 mg_core.rules_def.expensive_refuel:=false;
 mg_core.rules_def.center_4x_scan  :=false;
 mg_core.rules_def.direct_gold     :=false;
 mg_core.rules_def.lay_connectors  :=false;

 for i:=0 to 9 do mg_core.rules_def.ut_factors[i]:=def_ut_factors[i];
 for i:=0 to 3 do mg_core.rules_def.res_levels[i]:=R_RICH;
end;
//############################################################################//
procedure mgsetup;
begin
 if mgseted then exit;
 mgseted:=true;
end;
//############################################################################//
procedure mg_init_core;
var was_seted:boolean;
s:string;
begin try
 was_seted:=mgseted;
 if was_seted then finalize(mgvars.mg_core);

 assignfile(mg_core.logf,ce_curdir+'mga.log');
 rewrite(mg_core.logf);
 if ioresult<>0 then mg_core.logable:=false else begin mg_core.logable:=true;closefile(mg_core.logf);end;

 randomize;
 tolog('MGA','#################################################');
 s:='M.A.X.G. V'+core_progver+' core';
 tolog('MGA',s);
 tolog('','');
 tolog('MGAInit','Loading setup');

 if not mgseted then mgsetup; 
 
 tolog('MGAInit','Continuing setup');
 make_default_settings;
 loadunisets;
 
 load_def_rules;
 getmaps;
 tolog('MGAInit','Loading complete');

 //util_stuff;
 
 except halt; end;
end;
//############################################################################//
begin
end.
//############################################################################//
