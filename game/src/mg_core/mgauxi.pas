//############################################################################//
//Made by Artyom Litvinovich in 2003-2011
//MaxGold core auxillary functions
//############################################################################//
unit mgauxi;
interface
uses asys,mgvars,mgrecs,mgl_common,sysutils{$ifdef android},and_log{$endif};
//############################################################################//   
function mgrandom_dbl(g:pgametyp):double;
function mgrandom_int(g:pgametyp;l:integer):integer;

procedure tolog(devnam,inp:string);
procedure stderr(dev,proc:string);
procedure stderr2(dev,proc,dsc:string); 
//############################################################################//
var                   
istopunit:function(g:pgametyp;u:ptypunits;autolevel:boolean=true;stop_anyway:boolean=false):boolean;
istartunit:function(g:pgametyp;u:ptypunits;first_run,no_auto:boolean):boolean;
//############################################################################//
implementation
//############################################################################//
{$Q-}    
//############################################################################//
function mgrandom_dbl(g:pgametyp):double;
begin
 g.seed:=g.seed*1103515245+12345;
 result:=(g.seed/4294967296);
end;           
//############################################################################//
function mgrandom_int(g:pgametyp;l:integer):integer;begin result:=round(mgrandom_dbl(g)*(l-1));end;  
//############################################################################//
{$Q+}
//############################################################################//
//Write to log
procedure tolog(devnam,inp:string);
var i:byte;
begin try
{$I-}
 {$ifndef android}
  {$ifndef darwin}
  if mg_core.logable then begin
   append(mg_core.logf);
   if ioresult<>0 then begin mg_core.logable:=false;exit;end;
   for i:=length(devnam)+1 to 11 do devnam:=' '+devnam;
   inp:=getdate+'|'+devnam+'| '+inp;
   writeln(mg_core.logf,inp);                                
   if ioresult<>0 then begin mg_core.logable:=false;exit;end;
   closefile(mg_core.logf);                                  
   if ioresult<>0 then begin mg_core.logable:=false;exit;end;
  end else begin
   {$ifdef ape3}
   for i:=length(devnam)+1 to 11 do devnam:=' '+devnam;
   inp:=getdate+'|'+devnam+'| '+inp;
   writeln(inp);
   {$endif}
  end;
  {$endif}
 {$else}         
  android_log_write(ANDROID_LOG_INFO,'MAXGold',pchar(devnam+'| '+inp));
 {$endif}
{$I+}
 except end;
end;
//############################################################################//
//Standard error
procedure stderr(dev,proc:string);
begin
 tolog(dev,'Error in procedure '+proc);
end;
//############################################################################//  
//Standard bad error
procedure stderr2(dev,proc,dsc:string);
begin
 tolog(dev,'Error in procedure '+proc+': '+dsc);
end;    
//############################################################################//
//############################################################################//
begin
end.  
//############################################################################//
