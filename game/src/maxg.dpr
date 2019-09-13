//############################################################################//
//M.A.X. Gold game client
//
//All hope abandon ye who enter here.
//
//Defines: BGR VFS
//linkdirect  for direct connection
//mgnet_tcp   for TCP
//mgnet_rob   for local
//update      for update and versioning
//can_sound   for sound
//embedded    for tablet interface (ignore move events, etc)
//no_internal to not pack the data into the executable
//############################################################################//
program maxg;
//{$ifdef mswindows}{$R std.res}{$endif}
uses
{$ifdef unix}cthreads,{$endif}
{$ifdef mswindows}{$ifndef fpc}fastmm4,{$endif}{$endif}
{$ifdef linkdirect}
//For browsing
mgl_actions,mgl_buildcalc,mgl_buy,mgl_land,mgl_depot,mgl_logs,mgl_path,mgl_rmnu,mgl_stats,mgl_unu,mgl_xfer,
mgl_attr,mgl_build,mgl_common,mgl_cursors,mgl_mapclick,mgl_res,mgl_scan,mgl_tests,mgl_upgcalc,mgl_json,
sds_rec,sds_net,
mgrecs,mgvars,mgauxi,mginit,mgloads,mg_builds,mgmotion,mgproduct,mgress,mgsaveload,mgunievt,mgunits,
sdiauxi,sdigrtools,sdigui,sdisound,
sdiinit,sdigrinit,sdiloads,
sdicalcs,sdiovermind,
sdikeyinput,sdimousedwn,sdimouseup,
sdidraw_int,sdidraw_game,sdi_int_elem,sdimenu,
{$endif}
//############################################################################//
sdimaxg_main,sdirecs;
//############################################################################//
//Can not be a local variable because run_mg will return on Android.
var sdi:sdi_rec;
//############################################################################//
procedure run_mg;
begin
 fillchar(sdi,sizeof(sdi),0);
 new(sdi.cg);
 fillchar(sdi.cg^,sizeof(sdi.cg^),0);

 sdimaxg_start(@sdi);
end;
//############################################################################//
begin
 run_mg;
end.
//############################################################################//

