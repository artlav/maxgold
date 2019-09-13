//############################################################################//
unit sdigrinit;
interface
uses asys,grph,strval,sprlib,grpop,sdisdl,mgrecs,sdirecs,sdiauxi,sdigrtools,sdigui,sdimenu,sds_util,sds_rec;
//############################################################################//  
const curs_lst:array[0..CUR_COUNT-1]of string=(
 'ptr_hand','ptr_frnd','ptr_frnd_xfr','ptr_actvt'   ,'ptr_frnd_lod','ptr_unit_ngo','ptr_unit_go','ptr_enmy','ptr_frnd_fue','ptr_way',
 'ptr_map' ,'ptr_rld' ,'ptr_disbl'   ,'ptr_frnd_fix','ptr_steal'
); 
//############################################################################//
const grap_lst:array[0..8]of string=('e_hangar','e_dock','e_depot','tstimg.png','survey','frm_debug','frm_blowup','frm_alloc','frm_rsrch');
//############################################################################// 
procedure resize_planes(s:psdi_rec;xs,ys:integer);
procedure init_graph(s:psdi_rec);
procedure clear_graph(s:psdi_rec);
procedure bkgr_resize(s:psdi_rec);

procedure load_pal(s:psdi_rec);
procedure load_fonts(cg:psdi_grap_rec);
//############################################################################//
implementation
//############################################################################//
procedure free_planes(s:psdi_rec);
begin
 if s.map_plane.srf<>nil then freemem(s.map_plane.srf);
 if s.ut_plane.srf<>nil then freemem(s.ut_plane.srf);
 if s.minimap_plane.srf<>nil then freemem(s.minimap_plane.srf);
end;
//############################################################################//
procedure resize_planes(s:psdi_rec;xs,ys:integer);
begin
 free_planes(s);
 
 getmem(s.map_plane.srf,xs*ys);
 s.map_plane.xs:=xs;
 s.map_plane.ys:=ys;
 
 getmem(s.ut_plane.srf,xs*ys);
 s.ut_plane.xs:=xs;
 s.ut_plane.ys:=ys;
 
 getmem(s.minimap_plane.srf,112*112);
 s.minimap_plane.xs:=112;
 s.minimap_plane.ys:=112;
end;
//############################################################################//
procedure clear_graph(s:psdi_rec);
var i:integer;
begin           
 for i:=0 to length(s.cg.mgfnt)-1 do begin
  if s.cg.mgfnt[i].info<>nil then freemem(s.cg.mgfnt[i].info);
  if s.cg.mgfnt[i].data<>nil then freemem(s.cg.mgfnt[i].data);
 end;

 for i:=0 to length(s.cg.curs)-1 do if s.cg.curs[i]<>nil then begin delspr(s.cg.curs[i]^);dispose(s.cg.curs[i]);end;
 for i:=0 to length(s.cg.grap)-1 do if s.cg.grap[i]<>nil then begin delspr(s.cg.grap[i]^);dispose(s.cg.grap[i]);end;
 for i:=0 to length(s.cg.raw_bkgr)-1 do if s.cg.raw_bkgr[i]<>nil then begin delspr(s.cg.raw_bkgr[i]^);dispose(s.cg.raw_bkgr[i]);end;
 for i:=0 to length(s.cg.scaled_bkgr)-1 do if s.cg.scaled_bkgr[i]<>nil then begin delspr(s.cg.scaled_bkgr[i]^);dispose(s.cg.scaled_bkgr[i]);end;
 for i:=0 to length(s.cg.clns)-1 do if s.cg.clns[i]<>nil then begin delspr(s.cg.clns[i]^);dispose(s.cg.clns[i]);end;
 for i:=0 to length(s.cg.grapu)-1 do if s.cg.grapu[i]<>nil then begin deluspr(s.cg.grapu[i]^);dispose(s.cg.grapu[i]);end;
 for i:=0 to length(s.mmapbmp)-1 do if s.mmapbmp[i]<>nil then begin delspr(s.mmapbmp[i]^);dispose(s.mmapbmp[i]);end;
 for i:=0 to length(s.mmapbmpbw)-1 do if s.mmapbmpbw[i]<>nil then begin delspr(s.mmapbmpbw[i]^);dispose(s.mmapbmpbw[i]);end;

 free_planes(s);
end;
//############################################################################//  
procedure do_ld(s:psdi_rec;var spr:ptypspr;name:string);
var grdir:string;
begin
 spr:=nil;
 if name='' then exit;  
 grdir:=mgrootdir+graph_dir+'/';
 
                 spr:=genspr8(grdir+name);
 if spr=nil then spr:=maxg_genspr8_dither(grdir+name+'.png',false);
 
 if spr=nil then tolog('SDIInit','Cannot load "'+name+'"');
end;
//############################################################################//
procedure load_pal(s:psdi_rec);    
{$i max_pal.inc}
var i,j:integer;
begin  
 //Main pallette                    
 for i:=0 to length(thepal)-1 do for j:=0 to 2 do thepal[i][j]:=max_pal[i][j];
 for i:=0 to length(thepal)-1 do s.cg.base_pal[i]:=thepal[i];
 setsdlpal;  
end;
//############################################################################//
procedure load_fonts(cg:psdi_grap_rec);
{$i font0.inc}
{$i font1.inc}
{$i font2.inc}
{$i font3.inc}
{$i font4.inc}
{$i font5.inc}
{$i font6.inc}
begin   
 setlength(cg.mgfnt,7);
 loadmgfnt(@font0[0],cg.mgfnt[0]);
 loadmgfnt(@font1[0],cg.mgfnt[1]);
 loadmgfnt(@font2[0],cg.mgfnt[2]);
 loadmgfnt(@font3[0],cg.mgfnt[3]);
 loadmgfnt(@font4[0],cg.mgfnt[4]);
 loadmgfnt(@font5[0],cg.mgfnt[5]);
 loadmgfnt(@font6[0],cg.mgfnt[6]);  

 cg.mg_font_loaded:=true;
end;     
//############################################################################//   
procedure load_statics(s:psdi_rec);     
var i:integer;
begin
 //Cursors     
 for i:=0 to length(curs_lst)-1 do do_ld(s,s.cg.curs[i],curs_lst[i]); 
       
 //Static graphics    
 for i:=0 to length(grap_lst)-1 do begin
  do_ld(s,s.cg.grap[i],grap_lst[i]);
  set_load_bar_pos(s,0.1+0.3*(i/length(grap_lst))); 
 end;
end;
//############################################################################//   
procedure bkgr_resize(s:psdi_rec);
var i,x,y:integer;
k:double;
b:ptypspr;
begin
 if (scrx=0)or(scry=0) then exit;
 for i:=0 to 9 do if s.cg.raw_bkgr[i]<>nil then begin
  b:=cpspr8(s.cg.raw_bkgr[i]);
  k:=b.xs/b.ys;
  if scrx/scry>k then begin
   x:=round(scry*k);
   y:=scry;
  end else begin
   x:=scrx;
   y:=round(scrx/k);
  end;
  if x>scrx then x:=scrx;
  if y>scry then y:=scry;

  scale_spr_nearest_8(b,x,y);

  mutex_lock(sds_mx);
   if s.cg.scaled_bkgr[i]<>nil then begin delspr(s.cg.scaled_bkgr[i]^);dispose(s.cg.scaled_bkgr[i]);end;
   s.cg.scaled_bkgr[i]:=b;
  mutex_release(sds_mx);
 end;
end;
//############################################################################//  
//Background images
procedure load_backgrounds(s:psdi_rec);
var grdir:string;
i:integer;
begin
 grdir:=mgrootdir+graph_dir+'/';
 for i:=0 to length(s.cg.raw_bkgr)-1 do begin
  s.cg.raw_bkgr[i]:=maxg_genspr8_dither(grdir+'back_'+stri(i)+'.png',false);
  set_load_bar_pos(s,0.42+i*0.02);
 end;
 bkgr_resize(s);
end;
//############################################################################//   
procedure load_clans(s:psdi_rec);   
var grdir:string;
i:integer;
begin
 grdir:=mgrootdir+graph_dir+'/';
 //Clans
 for i:=0 to length(s.cg.clns)-1 do begin
  s.cg.clns[i]:=maxg_genspr8_dither(grdir+'cln'+stri(i)+'logo.png',false);
  set_load_bar_pos(s,0.64+i*0.02);
 end;
end;
//############################################################################//   
procedure load_dynamics(s:psdi_rec);
var i:integer;
grdir,ugrdir:string;  
begin        
 grdir:=mgrootdir+graph_dir+'/';
 ugrdir:=mgrootdir+unitsgrpdir+'/';
 
 //Dynamic graphics
 for i:=0 to length(s.cg.grapu)-1 do begin new(s.cg.grapu[i]);s.cg.grapu[i].ex:=false; end; 

 genuspr8(grdir+'patha.png',s.cg.grapu[GRU_PATH],0);
 genuspr8(grdir+'icons.png',s.cg.grapu[GRU_ICOS],0);
 genuspr8(grdir+'tracks.png',s.cg.grapu[GRU_TRACKS],0);

 set_load_bar_pos(s,0.90); 

 genuspr8(grdir+'disables.png',s.cg.grapu[GRU_DISABLED],3);
 genuspr8(grdir+'build_mark.png',s.cg.grapu[GRU_BUILDMARK],5);
 
 genuspr_sqr8(grdir+'anim_bldexp.png',s.cg.grapu[GRU_BLDEXP]);
 genuspr_sqr8(grdir+'anim_landexp.png',s.cg.grapu[GRU_LANDEXP]);
 genuspr_sqr8(grdir+'anim_airexp.png',s.cg.grapu[GRU_AIREXP]);
 genuspr_sqr8(grdir+'anim_seaexp.png',s.cg.grapu[GRU_SEAEXP]);
 genuspr_sqr8(grdir+'anim_hit.png',s.cg.grapu[GRU_HIT]);


 genuspr_sqr8(ugrdir+'b_powgen.png',s.cg.grapu[GRU_DEMO_POWGEN]);
 genuspr_sqr8(ugrdir+'s_powgen.png',s.cg.grapu[GRU_DEMO_S_POWGEN]);
 genuspr_sqr8(ugrdir+'b_smlslab.png',s.cg.grapu[GRU_DEMO_SMLSLAB]);
 set_load_bar_pos(s,0.95); 

 genuspr8(grdir+'bar.png',s.cg.grapu[GRU_BAR],4);
 genuspr8(grdir+'small_bar.png',s.cg.grapu[GRU_SMBAR],4);
 genuspr8(grdir+'vertical_bar.png',s.cg.grapu[GRU_VERTBAR],3);

 set_load_bar_pos(s,0.98);
end;
//############################################################################//
procedure init_graph(s:psdi_rec);
begin try  
 tolog('SDIGraph','Loading basic graphics');

 set_load_bar_pos(s,0.10); 
 write_load_box(s,'Loading statics');  
 load_statics(s);  
 write_load_box(s,'Loading backgrounds');   
 load_backgrounds(s); 
 write_load_box(s,'Loading clans');   
 load_clans(s); 
 write_load_box(s,'Loading dynamics');   
 load_dynamics(s);   

 write_load_box(s,'Game loaded');   
 set_load_bar_pos(s,1);

 except stderr2(s,'SDIGraph','InitGraph','Failed to load graphic(s). Halting.'); halt;end;
end;
//############################################################################//
begin    
end.
//############################################################################//
