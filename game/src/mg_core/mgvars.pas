//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core variables
//############################################################################//
unit mgvars;
interface
uses mgrecs;
//############################################################################//  
type
mg_core_rec=record
 //DBs
 rules_def:rulestyp;                    //Pravila    
 unitsets:array of uniset_rec;
 
 //Dirs
 maps_dir,save_dir,units_dir,base_dir:stringmg;
          
 //Maps info     
 map_list:array of map_list_rec;
      
 //Log
 logf:text;                             //File
 logable:boolean;                       //ON switch
end;  
//############################################################################//
var
mg_core:mg_core_rec;
mgseted:boolean=false;    //Are systems on?
iunit_endturn_build:function(g:pgametyp;u:ptypunits;md:integer):boolean;
//############################################################################//
implementation  

initialization

finalization
 {$I-}
 closefile(mg_core.logf); 
 if ioresult<>0 then ;
 {$I+}
end.
//############################################################################//
