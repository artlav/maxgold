//############################################################################//
program mga_rnd;
uses sysutils,asys,strval,strtool,mga_mapgen;
//############################################################################//
procedure main;
var map_name:string;
k,f:integer;
begin
 mapgen_init;

 if paramcount<4 then begin
  writeln('mga_rnd map_name xs ys type [option_name value]');  
  writeln('Possible options: seed island_cnt lake_cnt island_size lake_size obstacle_cnt');
  {$ifdef win32}readln;{$endif}
  exit;
 end;

 map_name:=paramstr(1);
 sizx:=vali(paramstr(2));
 sizy:=vali(paramstr(3));
      if paramstr(4)='desert' then cur_map:=0
 else if paramstr(4)='green' then cur_map:=1
 else begin
  writeln('Unknown map type: "',paramstr(4),'". Possible types: desert green');
  {$ifdef win32}readln;{$endif}
  exit;
 end;

 k:=5;
 f:=paramcount;
 while true do begin
  if k=f then begin
   writeln('Option "',paramstr(k),'" lacks value');
   {$ifdef win32}readln;{$endif}
   exit;
  end;
       if paramstr(k)='seed' then seed:=vali(paramstr(k+1))
  else if paramstr(k)='island_cnt' then island_cnt:=vali(paramstr(k+1))
  else if paramstr(k)='lake_cnt' then lake_cnt:=vali(paramstr(k+1))
  else if paramstr(k)='island_size' then island_size:=vali(paramstr(k+1))
  else if paramstr(k)='lake_size' then lake_size:=vali(paramstr(k+1))
  else if paramstr(k)='obstacle_cnt' then obstacle_cnt:=vali(paramstr(k+1))
  else begin
   writeln('Unknown option: "',paramstr(k),'". Possible options: seed island_cnt lake_cnt island_size lake_size obstacle_cnt');
   {$ifdef win32}readln;{$endif}
   exit;
  end;
  k:=k+2;
  if k>f then break;
 end;

 writeln('Making ',mapsdb[cur_map].name,' ("',map_name,'",',sizx,'x',sizy,'), seed=',seed,', island_cnt=',island_cnt,', island_size=',island_size,', lake_cnt=',lake_cnt,', lake_size=',lake_size,', obstacle_cnt=',obstacle_cnt);

 mapgen_makemap;
 mapgen_wrlasm('maps/','maps/'+map_name+'.wrl');

 {$ifdef win32}writeln('Done');readln;{$endif}
end;       
//############################################################################//
begin
 main;
end.
//############################################################################//

