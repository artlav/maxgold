//############################################################################//
//Made by Artyom Litvinovich in 2003-2017
//MaxGold path finding
//############################################################################//
unit mgl_path;
interface
uses asys,maths,mgrecs,mgl_common,mgl_attr,mgl_tests;
//############################################################################//  
function pf_calc_path(g:pgametyp;u:ptypunits;rng:integer):boolean;
//############################################################################//
implementation  
//############################################################################//
const
pf_courses:array[1..8]of ivec2a=(( 0,-1),( 1,-1),( 1, 0),( 1, 1),( 0, 1),(-1, 1),(-1, 0),(-1,-1));
pf_angles:array[0..1]of single=(1.42,1);  

PF_NORMAL=2;
PF_GOAL=6;
PF_ORIGIN=3;
PF_USED=4;    
//############################################################################//
type
pf_bound_arr=array[0..10000]of ivec2a;
//############################################################################//
procedure pf_one_mapa(const g:pgametyp;const u:ptypunits;var mapa:aopf_tile;const x,y,rng,ptyp:integer);
var p,k:integer;
m:ppf_tile;  
uj:ptypunits; 
//ud:ptypunitsdb;
begin
 m:=@mapa[x+y*g.info.mapx];
 if m.done then exit;
 m.done:=true;

 p:=g.passm[x+y*g.info.mapx];

 //setlength(m.path,0);
 //m.pl:=0;
 m.stts:=PF_NORMAL;  
 m.ttype:=5;
 m.value:=2;

 if ptyp<>pt_air then begin
  if p=P_WATER    then if ptyp<pt_watercoast then begin m.ttype:=2;m.value:=6;end;     //4
  if p=P_COAST    then begin m.ttype:=4;m.value:=2;end;      //2.2
  if p=P_OBSTACLE then m.ttype:=0;
  {
  if cp.razvedmp[x,y].seen then for ii:=0 to length(cp.razvedmp[x,y].blds)-1 do if cp.razvedmp[x,y].blds[ii].used then begin
   k:=cp.razvedmp[x,y].blds[ii].id;
   ud:=get_unitsdb(g,k);
   if ud=nil then continue;
   if isadb(g,ud,a_half_selectable) or isadb(g,ud,a_unselectable) then continue;
   if isadb(g,ud,a_building)then begin
    m.ttype:=0;
    if ud.siz=2 then begin
     mapa[d+1].ttype:=0;
     mapa[d+g.info.mapx].ttype:=0;
     mapa[d+g.info.mapx+1].ttype:=0;
    end;
   end else begin
    m.value:=200000;
    if ud.siz=2 then begin
     mapa[d+1].value:=200000;
     mapa[d+g.info.mapx].value:=200000;
     mapa[d+g.info.mapx+1].value:=200000;
    end;
   end;
  end;
  }
 end;

 if rng=1 then if inrects(x,y,u.xt-1,u.yt-1,2,2)    then m.stts:=PF_GOAL;
 if rng=2 then if inrects(x,y,u.xt-1,u.yt-1,3,3)    then m.stts:=PF_GOAL;
 if rng>2 then if sqr(x-u.xt)+sqr(y-u.yt)<=sqr(rng) then m.stts:=PF_GOAL;

 if ptyp<>pt_air then begin
  for k:=get_unu_length(g,x,y)-1 downto 0 do begin
   uj:=get_unu(g,x,y,k);
   if fast_can_see(g,uj.x,uj.y,u.own) then begin
    if uj.siz=1 then begin
     if isa(g,uj,a_road) then begin m.ttype:=6;m.value:=1;end;
     if (isa(g,uj,a_bridge))or((isa(g,uj,a_can_build_on))and(not isa(g,uj,a_connector))) then begin m.ttype:=5;m.value:=2;end;
     if (ptyp> pt_landwater)and(isa(g,uj,a_bridge)) then begin m.ttype:=2;m.value:=2;end; //2.2
     if (ptyp<=pt_landwater)and(isa(g,uj,a_bridge)) then begin m.ttype:=6;m.value:=1;end;
    end;
   end;
  end;
 end;

 m.rvalue:=m.value;
end;
//############################################################################//
function pf_findmin(const mapa:aopf_tile;const bound:pf_bound_arr;const bsize,mapx,mapy:integer):integer;
var i,n:integer;
begin
 n:=1;
 for i:=1 to bsize do if mapa[bound[n][0]+bound[n][1]*mapx].fval>mapa[bound[i][0]+bound[i][1]*mapx].fval then n:=i;
 result:=n;
end;
//############################################################################//
function pf_hest(const x,y,tx,ty:integer;const dx2,dy2:single):single;
var dx,dy,cross:single;
begin
 dx:=x-tx;
 dy:=y-ty;
 cross:=dx*dy2-dx2*dy;
 if cross<0 then cross:=-cross;
 result:=max2(abs(dx),abs(dy))+cross*0.001;
end; 
//############################################################################//
procedure pf_fill_path(const mapa:aopf_tile;const end_x,end_y,bsize,mapx:integer;const u:ptypunits);
var n,i,x,y,pos:integer;
gen:array of prec;
m:ppf_tile;
begin
 n:=0;
 setlength(gen,bsize+10);
 x:=end_x;
 y:=end_y;
 while true do begin
  pos:=x+y*mapx;    
  m:=@mapa[pos];

  if (x=u.x)and(y=u.y) then begin
   gen[n].px   :=x;
   gen[n].py   :=y;
   gen[n].pval :=0;
   gen[n].rpval:=0;
   gen[n].dir  :=0;
   n:=n+1;
   break;
  end else begin
   gen[n].px   :=x;
   gen[n].py   :=y;
   gen[n].pval :=m.path.pval;
   gen[n].rpval:=m.path.rpval;
   gen[n].dir  :=0;
   x:=m.path.px;
   y:=m.path.py;
   n:=n+1;
  end;
 end;

 setlength(u.path,n);
 for i:=0 to n-1 do u.path[i]:=gen[n-i-1];
 u.plen:=n;
end;
//############################################################################//
function pf_one_direction(const g:pgametyp;var mapa:aopf_tile;const u:ptypunits;const x,y,k,rng,ptyp:integer;const dxl,dyl:single;var bound:pf_bound_arr;var bsize:integer):boolean;
var m:ppf_tile;
tp,tpa:boolean;
pos,dpos,dx,dy:integer;
begin
 result:=false;

 dx:=x+pf_courses[k][0];
 dy:=y+pf_courses[k][1];
 if (dx<0)or(dx>=g.info.mapx) then exit;
 if (dy<0)or(dy>=g.info.mapy) then exit;  
 pos:=x+y*g.info.mapx;
 dpos:=dx+dy*g.info.mapx;

 pf_one_mapa(g,u,mapa,dx,dy,rng,ptyp);
 m:=@mapa[dpos];

 tp :=test_pass(g,dx,dy,u,false,1); //Can pass
 tpa:=test_pass(g,dx,dy,u,false,2); //Can pass ignoring units
 if tpa and not tp then begin
  if m.stts=PF_GOAL then tpa:=false; //For inranging and units on targets
  m.value:=200000;
 end;
 if tpa and (not test_pass(g,dx,dy,u,false,3)) then m.value:=200000;
 if m.ttype<>0 then if tpa then if(m.stts=PF_NORMAL)or(m.stts=PF_GOAL)then begin
  m.path.px:=x;
  m.path.py:=y;  
  m.path.pval :=(m.value *pf_angles[k mod 2])*5;
  m.path.rpval:=(m.rvalue*pf_angles[k mod 2])*5;

  if m.stts=PF_NORMAL then begin
   m.gval:=mapa[pos].gval+m.value*pf_angles[k mod 2];
   m.fval:=m.gval+pf_hest(dx,dy,u.xt,u.yt,dxl,dyl);
   m.stts:=PF_ORIGIN;  //WTF?
   if bsize<10000 then begin
    bsize:=bsize+1;
    bound[bsize][0]:=dx;
    bound[bsize][1]:=dy;
   end;
  end;

  if m.stts=PF_GOAL then begin
   pf_fill_path(mapa,dx,dy,bsize,g.info.mapx,u);
   result:=true;
   if rng<>0 then begin
    u.xt:=u.path[u.plen-1].px;
    u.yt:=u.path[u.plen-1].py;
   end;
   exit;
  end;
 end;
end;
//############################################################################//
//Calculate the path
function pf_calc_path(g:pgametyp;u:ptypunits;rng:integer):boolean;
var i,ii,x,y,k:integer;
dxl,dyl:single;
ptyp:byte;
m:ppf_tile;
bound:pf_bound_arr;
bsize:integer;
begin
 result:=false;
 if not unav(u) then exit;
 if length(g.pathing_map)=0 then exit;

 ptyp:=u.ptyp;
 if isa(g,u,a_surveyor) then ptyp:=6;

 for i:=0 to g.info.mapy*g.info.mapx-1 do g.pathing_map[i].done:=false;

 pf_one_mapa(g,u,g.pathing_map,u.x ,u.y ,rng,ptyp);
 pf_one_mapa(g,u,g.pathing_map,u.xt,u.yt,rng,ptyp);
 g.pathing_map[u.xt+u.yt*g.info.mapx].stts:=PF_GOAL;

 dxl:=u.x-u.xt;
 dyl:=u.y-u.yt;
 bound[1][0]:=u.x;
 bound[1][1]:=u.y;
 bsize:=1;

 m:=@g.pathing_map[u.x+u.y*g.info.mapx];
 m.stts:=PF_ORIGIN;
 m.gval:=0;
 m.fval:=m.gval+pf_hest(u.x,u.y,u.xt,u.yt,dxl,dyl);

 while (bsize>0)and not result do begin
  for i:=1 to bsize do pf_one_mapa(g,u,g.pathing_map,bound[i][0],bound[i][1],rng,ptyp);
  k:=pf_findmin(g.pathing_map,bound,bsize,g.info.mapx,g.info.mapy);
  x:=bound[k][0];
  y:=bound[k][1];
  g.pathing_map[x+y*g.info.mapx].stts:=PF_USED;
  bound[k]:=bound[bsize];
  bsize:=bsize-1;
  for k:=1 to 8 do if pf_one_direction(g,g.pathing_map,u,x,y,k,rng,ptyp,dxl,dyl,bound,bsize) then begin
   result:=true;
   break;
  end;
 end;

 if result then begin
  for ii:=0 to u.plen-2 do u.path[ii].dir:=getdirbydp(u.path[ii+1].px,u.path[ii].px,u.path[ii+1].py,u.path[ii].py);
  u.path[u.plen-1].dir:=u.path[u.plen-2].dir;
 end;
end;
//############################################################################//
begin
end.   
//############################################################################//
