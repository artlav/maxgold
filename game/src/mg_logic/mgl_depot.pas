//############################################################################//
unit mgl_depot;
interface
uses asys,mgrecs,mgl_common,mgl_attr,mgl_res;  
//############################################################################//
type
gm_depot_rec=record
 ulst:array[0..24-1]of dword;        //List of stored units
 ucnt:integer;                       //Stored units
 mat,mattot,fuel,fueltot,pg:integer;    
end;  
pgm_depot_rec=^gm_depot_rec;                                  
//############################################################################//  
procedure enter_depot_menu(g:pgametyp;dep:pgm_depot_rec;u:ptypunits);  
procedure update_depot_menu_mat(g:pgametyp;dep:pgm_depot_rec;u:ptypunits);
//############################################################################//
implementation     
//############################################################################//
//Calc unstore menu
procedure update_depot_menu_mat(g:pgametyp;dep:pgm_depot_rec;u:ptypunits);
begin
 dep.mat    :=get_rescount(g,u,RES_MAT,GROP_NOW);
 dep.mattot :=get_rescount(g,u,RES_MAT,GROP_MAX);
 dep.fuel   :=get_rescount(g,u,RES_FUEL,GROP_NOW);
 dep.fueltot:=get_rescount(g,u,RES_FUEL,GROP_MAX);
end;
//############################################################################//
//Calc unstore menu
procedure enter_depot_menu(g:pgametyp;dep:pgm_depot_rec;u:ptypunits);
var ui:ptypunits;
i:integer;
begin
 if not unav(u) then exit; 
 dep.pg:=0;
 dep.ucnt:=0;
 for i:=0 to get_units_count(g)-1 do begin
  ui:=get_unit(g,i);
  if ui<>nil then if ui.stored and(ui.stored_in=u.num)and(not are_enemies(g,ui,u)) then begin
   dep.ulst[dep.ucnt]:=i;
   dep.ucnt:=dep.ucnt+1;
  end;
 end;   
 update_depot_menu_mat(g,dep,u);
end;  
//############################################################################//
begin
end.
//############################################################################//
