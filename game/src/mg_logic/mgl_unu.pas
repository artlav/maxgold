//############################################################################//
//Made by Artyom Litvinovich in 2003-2013
//MaxGold scan, unu, razv - cell maps
//############################################################################//
unit mgl_unu;
interface
uses mgrecs,mgl_common,mgl_attr;  
//############################################################################//  
procedure addunu(g:pgametyp;u:ptypunits);
procedure remunuc(g:pgametyp;x,y:integer;u:ptypunits);
procedure alloc_unu(g:pgametyp);
procedure setunu(g:pgametyp);
procedure clrunu(g:pgametyp);

procedure alloc_and_clear_all_razved(g:pgametyp);
procedure alloc_and_clear_plr_razved(pl:pplrtyp;xs,ys:integer);
procedure razved_reset(pl:pplrtyp);
procedure razved_on_scan_add(pl:pplrtyp;x,y:integer);
procedure razved_on_scan_sub(g:pgametyp;pl:pplrtyp;u:ptypunits;x,y:integer);
//############################################################################//
implementation  
//############################################################################//
procedure sortunu(g:pgametyp;x,y:integer);
var ja:aunu;
un,i,ii:integer;
begin   
 if not inrm(g,x,y) then exit;  
 if get_unu_length(g,x,y)<2 then exit;
 setlength(ja,get_unu_length(g,x,y));
 for i:=0 to length(ja)-1 do ja[i]:=g.unu[x,y,i];
 un:=0;
 for i:=6 downto 0 do for ii:=0 to length(ja)-1 do if ja[ii].u<>nil then if (ja[ii].u.level=i)and(not isa(g,ja[ii].u,a_building)) then begin
  g.unu[x,y,un]:=ja[ii];
  un:=un+1;
 end;
 for i:=6 downto 0 do for ii:=0 to length(ja)-1 do if ja[ii].u<>nil then if (ja[ii].u.level=i)and isa(g,ja[ii].u,a_building) then begin
  g.unu[x,y,un]:=ja[ii];
  un:=un+1;
 end;
end;
//############################################################################//
procedure addunu(g:pgametyp;u:ptypunits);
var l,l1,l2,l3,x,y:integer;
begin
 if not unav(u) then exit;
 x:=u.x;
 y:=u.y;
 if not inrm(g,x,y) then exit;
 l:=length(g.unu[x,y]);
 setlength(g.unu[x,y],l+1);
 g.unu[x,y,l].u:=u;
 g.unu[x,y,l].qtr:=UQ_UP_LEFT;
 if (u.siz=2)or((u.cur_siz=2)and(u.isbuild or u.isbuildfin or u.isclrg)) then begin
  l1:=length(g.unu[x+1,y]);
  l2:=length(g.unu[x+1,y+1]);
  l3:=length(g.unu[x,y+1]);
  setlength(g.unu[x+1,y],l1+1);
  setlength(g.unu[x+1,y+1],l2+1);
  setlength(g.unu[x,y+1],l3+1);
      
  g.unu[x+1,y,l1].u:=u;
  g.unu[x+1,y,l1].qtr:=UQ_UP_RIGHT;
                                   
  g.unu[x+1,y+1,l2].u:=u;
  g.unu[x+1,y+1,l2].qtr:=UQ_DWN_RIGHT;
                                  
  g.unu[x,y+1,l3].u:=u;
  g.unu[x,y+1,l3].qtr:=UQ_DWN_LEFT;  
  
  sortunu(g,x+1,y);
  sortunu(g,x+1,y+1);
  sortunu(g,x,y+1);
 end;
 sortunu(g,x,y);
end;
//############################################################################//
procedure rmiisj(g:pgametyp;x,y:integer;u:ptypunits);
var l,j,jj:integer;
begin
 if not inrm(g,x,y) then exit;
 l:=length(g.unu[x,y]);
 for j:=0 to l-1 do if g.unu[x,y,j].u=u then begin
  if j=l-1 then begin
   setlength(g.unu[x,y],l-1);
   sortunu(g,x,y);
   exit;
  end else begin
   for jj:=j+1 to l-1 do g.unu[x,y,jj-1]:=g.unu[x,y,jj];
   if l>0 then setlength(g.unu[x,y],l-1);
   sortunu(g,x,y);
   exit;
  end;
 end;
end;      
//############################################################################//
procedure remunuc(g:pgametyp;x,y:integer;u:ptypunits);
begin
 if u=nil then exit;
 rmiisj(g,x,y,u);
 if (u.siz=2)or(u.cur_siz=2) then begin
  rmiisj(g,x+1,y,u);
  rmiisj(g,x,y+1,u);
  rmiisj(g,x+1,y+1,u);
  rmiisj(g,x-1,y,u);
  rmiisj(g,x,y-1,u);
  rmiisj(g,x-1,y-1,u);
  rmiisj(g,x-1,y+1,u);
  rmiisj(g,x+1,y-1,u);  
  sortunu(g,x+1,y);
  sortunu(g,x+1,y+1);
  sortunu(g,x,y+1);
 end;
 sortunu(g,x,y);
end;     
//############################################################################//
procedure alloc_unu(g:pgametyp);
var i,j:integer;
begin
 setlength(g.unu,g.info.mapx);
 for i:=0 to g.info.mapx-1 do begin 
  setlength(g.unu[i],g.info.mapy);
  for j:=0 to g.info.mapy-1 do setlength(g.unu[i,j],0);
 end; 
end;
//############################################################################//
procedure setunu(g:pgametyp);
var i,x,y:integer;
begin
 for x:=0 to g.info.mapx-1 do for y:=0 to g.info.mapy-1 do setlength(g.unu[x,y],0);
 if get_units_count(g)>0 then for i:=0 to get_units_count(g)-1 do if unav(g,i) then addunu(g,get_unit(g,i));
 for x:=0 to g.info.mapx-1 do for y:=0 to g.info.mapy-1 do sortunu(g,x,y);
end;
//############################################################################//
procedure clrunu(g:pgametyp);
begin
 finalize(g.unu);
end;
//############################################################################//
procedure razved_reset(pl:pplrtyp);
var x,y:integer;
begin
 for x:=0 to length(pl.razvedmp)-1 do begin
  for y:=0 to length(pl.razvedmp[x])-1 do begin
   setlength(pl.razvedmp[x,y].blds,0);
   pl.razvedmp[x,y].seen:=false;
  end;
 end;
end;
//############################################################################//
procedure razved_reset_by_can_see(g:pgametyp;pl:pplrtyp);
var x,y:integer;
begin
 for x:=0 to length(pl.razvedmp)-1 do begin
  for y:=0 to length(pl.razvedmp[x])-1 do begin
   setlength(pl.razvedmp[x,y].blds,0);
   pl.razvedmp[x,y].seen:=can_see(g,x,y,pl.num,nil);
  end;
 end;
end;
//############################################################################//
procedure alloc_and_clear_plr_razved(pl:pplrtyp;xs,ys:integer);
var x,y:integer;
begin
 setlength(pl.razvedmp,xs);
 for x:=0 to xs-1 do begin   
  setlength(pl.razvedmp[x],ys);
  for y:=0 to ys-1 do begin
   setlength(pl.razvedmp[x,y].blds,0);
   pl.razvedmp[x,y].seen:=false;
  end;
 end; 
end;
//############################################################################//
procedure alloc_and_clear_all_razved(g:pgametyp);
var p:integer;
pl:pplrtyp;
begin
 for p:=0 to get_plr_count(g)-1 do begin
  pl:=get_plr(g,p);
  alloc_and_clear_plr_razved(pl,g.info.mapx,g.info.mapy);
  razved_reset_by_can_see(g,pl);
 end;
end;
//############################################################################//
procedure razved_on_scan_add(pl:pplrtyp;x,y:integer);
begin
 pl.razvedmp[x,y].seen:=true;
 setlength(pl.razvedmp[x,y].blds,0);
end;
//############################################################################//
procedure razved_on_scan_sub(g:pgametyp;pl:pplrtyp;u:ptypunits;x,y:integer);
var rz:prazvedtyp;
uv:ptypunits;
i,n,k:integer;
used:boolean;
begin
 n:=get_unu_length(g,x,y);
 if n=0 then exit;

 rz:=@pl.razvedmp[x,y];

 rz.seen:=true;
 setlength(rz.blds,n);
 k:=0;
 for i:=0 to n-1 do begin
  uv:=get_unu(g,x,y,i);
  used:=(uv.own<>u.own)and isa(g,uv,a_building)and(get_unu_qtr(g,x,y,i)=UQ_UP_LEFT)and not isa(g,uv,a_bomb);
  if not used then continue;

  rz.blds[k].id:=uv.dbn;
  rz.blds[k].level:=uv.level;
  rz.blds[k].own:=uv.own;
  k:=k+1;
 end;
 setlength(rz.blds,k);
end;
//############################################################################//
begin
end.   
//############################################################################//
