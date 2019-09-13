//############################################################################//
//Made by Artyom Litvinovich in 2003-2010
//MaxGold core Units handling functions
//############################################################################//
unit mgl_upgcalc;
interface
uses math,mgrecs,mgl_common;
//############################################################################//
const
max_upgrade_price=1000;
research_increase=10;
//############################################################################//
function calc_res_change(base_val,reslv:integer;utyp:integer=ut_attk;mat_turn:integer=2):integer; 
function calc_res_add(base_val,reslv:integer;utyp:integer=ut_attk;mat_turn:integer=2):integer;
function calc_res_turns(g:pgametyp;reslv,utyp:integer;delta:integer=0):integer;
function calc_upg_price(g:pgametyp;cur_val,base_val,utyp,reslv:integer):integer;
function get_upg_cost(g:pgametyp;base_val,cur_val,new_val,reslv,utyp:integer):integer;
function round_cost(cost:double;mat_turn:integer=2):integer;
function get_upg_inc(base_val:integer):integer;
function calc_abs_price(g:pgametyp;gold_val,base_val,utyp:integer):double;
//############################################################################//
implementation 
//############################################################################//
//Calculates the price (gold) to upgrade from the given value.
//Return the costs for this upgrade or NO_PRICE_AVAILABLE if no upgrade
//cur_val the value the unit currently has (without research bonus but with clan bonus)
//base_val the value the unit has as a base value (with clan bonus)
function calc_upg_price(g:pgametyp;cur_val,base_val,utyp,reslv:integer):integer;
var bonusByResearch,goldOnlyValue,price,d:integer;
begin
 bonusByResearch:=calc_res_change(base_val,reslv);
 goldOnlyValue:=cur_val-bonusByResearch;

 d:=get_upg_inc(base_val);
 price:=trunc(calc_abs_price(g,goldOnlyValue+d,base_val,utyp)-calc_abs_price(g,goldOnlyValue,base_val,utyp));

 if price<max_upgrade_price then result:=price else result:=-1;
end;
//############################################################################//
//Calculates the price  for upgrading a unit
function get_upg_cost(g:pgametyp;base_val,cur_val,new_val,reslv,utyp:integer):integer;
var dcost,upg_val:integer;
begin
 result:=0;
 if(base_val<=cur_val)and(cur_val<new_val) then begin
  upg_val:=cur_val;
  while upg_val<new_val do begin
   dcost:=calc_upg_price(g,upg_val,base_val,utyp,reslv);
   if dcost<>-1 then begin
    result:=result+dcost;
    upg_val:=upg_val+get_upg_inc(base_val);
    if upg_val>new_val then begin result:=-1;break;end;
   end else begin result:=-1;break;end;
  end;
 end;
end;
//############################################################################//    
//Calculates the change of the given base_val,with the given reslv
function calc_res_change(base_val,reslv:integer;utyp:integer=ut_attk;mat_turn:integer=2):integer;
var cost:double;
begin
 if reslv<=0 then begin result:=0;exit;end;
 if utyp<>ut_cost then begin 
  result:=trunc((base_val*(100+reslv))/100)-base_val;
 end else begin
  cost:=base_val*100/(100+reslv);
  result:=round_cost(cost,mat_turn)-base_val;
 end;
end;                
//############################################################################//  
function calc_res_add(base_val,reslv:integer;utyp:integer=ut_attk;mat_turn:integer=2):integer;
begin
 result:=calc_res_change(base_val,reslv,utyp,mat_turn)-calc_res_change(base_val,reslv-10,utyp,mat_turn);
end;
//############################################################################//
//Calculate the absolute turns for achive level reslv from 0
function calc_abs_res(g:pgametyp;reslv,utyp:integer):integer;
var rul:prulestyp;
begin
 rul:=get_rules(g);
 result:=trunc(power(1+reslv/100,7.5)*256/rul.ut_factors[utyp]);
end;
//############################################################################// 
//Calculates the turns needed for one research center to reach the next level
//Return the turns needed to reach the next level with one research center
function calc_res_turns(g:pgametyp;reslv,utyp:integer;delta:integer=0):integer;
var d:integer;
begin
 if delta=0 then d:=research_increase 
            else d:=delta;
            
 if(delta<0)or(reslv<0)then result:=-1
                       else result:=calc_abs_res(g,reslv+d,utyp)-calc_abs_res(g,reslv,utyp);
end;
//############################################################################//
function round_cost(cost:double;mat_turn:integer=2):integer;
begin
 if mat_turn<=0 then result:=trunc(cost)
                else result:=round(cost/mat_turn)*mat_turn;
 if result<=0 then result:=mat_turn;
end;
//############################################################################//
//Calculates the absolute cost of value
//Return price
//gold_val the value,the unit has made upgrades with gold only
function calc_abs_price(g:pgametyp;gold_val,base_val,utyp:integer):double;
var rul:prulestyp;
begin
 if base_val=0 then begin result:=9999;exit;end;
 rul:=get_rules(g);
 result:=power(gold_val/base_val,7.5)*64/rul.ut_factors[utyp];
end;
//############################################################################//     
//Calculates the increase of a unit value,when an upgrade is bought.
function get_upg_inc(base_val:integer):integer;
begin
      if base_val<10 then result:=1
 else if base_val<25 then result:=2
 else if base_val<50 then result:=5
                     else result:=10;
end;
//############################################################################//     
//Calculates the raw-material needed for upgrading a unit
function get_mat_for_upgr(cost:integer):integer;
begin
 result:=ord(cost>=4)*(cost div 4);
end;  
//############################################################################//
begin
end.   
//############################################################################//
