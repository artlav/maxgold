//############################################################################//
unit sdiloads;
interface
uses sysutils,asys,vfsint,strval,grph,maths,sprlib,grpop,json,b64,lzw
,sdirecs,mgrecs,mgl_common,mgl_json,sdiauxi,sdigrtools,sdi_rec,sdisound,sds_util,sds_rec,sds_net;
//############################################################################//
function loadmap(s:psdi_rec;name:string):boolean;   
procedure loadunits_grpdb(s:psdi_rec;signal:boolean);
procedure getmaps(s:psdi_rec);
procedure loadsetup(s:psdi_rec);
procedure loadlang(s:psdi_rec);
procedure loadint(s:psdi_rec);
procedure savesetup(s:psdi_rec);
procedure clear_units_grpdb(s:psdi_rec);   
procedure clear_map(s:psdi_rec);
//############################################################################//
implementation  
//############################################################################//
procedure make_abstract_map(s:psdi_rec);     
var i,x,y,xs,ys:integer;
map:array of word;
spr:ptypspr;
clr:array[0..3]of byte;
begin        
 xs:=s.mapx;
 ys:=s.mapy;

 clr[0]:=35;
 clr[1]:=51;
 clr[2]:=166;
 clr[3]:=251; 
 
 //Pallette     
 for x:=0 to 255 do begin 
  s.map_pal[x][0]:=thepal[x][0];
  s.map_pal[x][1]:=thepal[x][1];
  s.map_pal[x][2]:=thepal[x][2];
 end;  
        
 setlength(map,xs*ys);
 setlength(s.pmap,xs*ys);

 for i:=0 to length(map)-1 do map[i]:=s.the_game.passm[i];

 //Minimap 
 new(spr);
 getmem(spr.srf,xs*ys);
 spr.tp:=1;
 spr.xs:=xs;
 spr.ys:=ys;   
 spr.cx:=xs div 2;
 spr.cy:=ys div 2;
 
 for i:=0 to xs*ys-1 do pbytea(spr.srf)[i]:=clr[s.the_game.passm[i]];
 
 s.mm_tileset:=sclmmap8(s,spr); 

 //Minimap FOW       
 s.mm_tileset_fow:=cpspr8(s.mm_tileset);     
 maxg_dither_img_fog(pbytea(s.mm_tileset_fow.srf),s.mm_tileset_fow.xs,s.mm_tileset_fow.ys,s.cg.fow_density,s.map_pal);
 
 //Blocks    
 
 new(s.map_tileset);
 i:=64*64*4;
 getmem(s.map_tileset.srf,i);  

 for y:=0 to 64*4-1 do for x:=0 to 63 do begin 
  pbytea(s.map_tileset.srf)[x+y*64]:=clr[y div 64];
 end;
 
 s.map_tileset.tp:=1;
 s.map_tileset.xs:=64;
 s.map_tileset.ys:=i div 64;   
 s.map_tileset.cx:=s.map_tileset.xs div 2;
 s.map_tileset.cy:=s.map_tileset.ys div 2;

 //FOW
 s.map_tileset_fow:=cpspr8(s.map_tileset);   
 maxg_dither_img_fog(pbytea(s.map_tileset_fow.srf),s.map_tileset_fow.xs,s.map_tileset_fow.ys,s.cg.fow_density,s.map_pal);
  
 //Drawings 
 for x:=0 to xs-1 do for y:=0 to ys-1 do s.pmap[x+y*xs]:=map[x+y*xs]*dword(XCX*XCX);

 //Transparencies
 fill_transparency_cache(s.cg);

 setlength(map,0);
end;
//############################################################################//
function download_map(s:psdi_rec;nam:string):boolean;
var st,rs,map,fn:string;
js:pjs_node;
osz,sz,csz:integer;
buf,cbuf:pointer;
f:vfile;
begin            
 result:=false;
 sds_set_message(@s.steps,po('Downloading the map'));
 st:=make_sys_request('get_the_map',',"name":"'+nam+'"}');
 sds_json_exchange(st,rs,@s.steps.step_progress);
 js:=js_parse(rs);
 map:=js_get_string(js,'map');
 osz:=vali(js_get_string(js,'size'));
 
 if map='nil' then begin free_js(js);exit;end;
 fn:=mgrootdir+mapsdir+'/'+nam+'.txt';
 //if vfexists(fn) then exit;
 if vfopen(f,fn,VFO_WRITE)<>VFERR_OK then begin free_js(js);exit;end;
           
 getmem(cbuf,length(map));
 getmem(buf,osz);
 csz:=b64_dec(@map[1],length(map),cbuf,length(map));   

 sz:=decodeLZW(cbuf,buf,csz,osz);
 
 vfwrite(f,buf,sz);
 vfclose(f); 
 freemem(buf);
 freemem(cbuf);
 result:=true;

 free_js(js);
end;
//############################################################################//
function loadmap(s:psdi_rec;name:string):boolean;
var x,y,xs,ys:integer;
map:array of word;  
fn:string;
mmap_spr:ptypspr;
js:pjs_node;   
mm:pointer; 
begin try
 result:=false;

 fn:=mgrootdir+mapsdir+'/'+name+'.txt';

 js:=map_file_open(fn,true);
 if js=nil then begin
  sds_set_message(@s.steps,po('Downloading the map'));
  if not download_map(s,name) then begin if s.the_game<>nil then begin make_abstract_map(s);result:=true;end;exit;end;
  js:=map_file_open(fn,true);
  if js=nil then begin if s.the_game<>nil then begin make_abstract_map(s);result:=true;end;exit;end;
 end;

 xs:=vali(js_get_string(js,'width'));
 ys:=vali(js_get_string(js,'height'));
                        
 setlength(map,xs*ys);
 setlength(s.pmap,xs*ys);
 getmem(mm,xs*ys);
            
 map_file_get_pal(js,s.map_pal);
 
 //Map            
 map_file_get_map(js,@map[0]);

 //Minimap        
 map_file_get_minimap(js,mm);
 mmap_spr:=genspr_mem(mm,xs,ys);
 s.mm_tileset:=sclmmap8(s,mmap_spr);   
 
 new(s.map_tileset);
 map_file_get_blocks(js,s.map_tileset);
 
 free_js(js);
 
 //Minimap FOW       
 s.mm_tileset_fow:=cpspr8(s.mm_tileset);     
 maxg_dither_img_fog(pbytea(s.mm_tileset_fow.srf),s.mm_tileset_fow.xs,s.mm_tileset_fow.ys,s.cg.fow_density,s.map_pal);
 
 //Pallette     
 for x:=64 to 159 do begin 
  thepal[x][0]:=s.map_pal[x][0];
  thepal[x][1]:=s.map_pal[x][1];
  thepal[x][2]:=s.map_pal[x][2];
 end;  

 //FOW
 s.map_tileset_fow:=cpspr8(s.map_tileset);   
 maxg_dither_img_fog(pbytea(s.map_tileset_fow.srf),s.map_tileset_fow.xs,s.map_tileset_fow.ys,s.cg.fow_density,s.map_pal);
  
 //Drawings 
 for x:=0 to xs-1 do for y:=0 to ys-1 do s.pmap[x+y*xs]:=map[x+y*xs]*dword(XCX*XCX);

 //Transparencies
 fill_transparency_cache(s.cg);

 s.mapx:=xs;
 s.mapy:=ys; 

 setlength(map,0); 
 result:=true;

 except result:=false;stderr(s,'SDILoadSav','LoadMap');end;
end;   
//############################################################################//     
procedure clear_map(s:psdi_rec);
begin
 if s.map_tileset<>nil     then begin delspr(s.map_tileset^);    freemem(s.map_tileset);    s.map_tileset:=nil;end; 
 if s.map_tileset_fow<>nil then begin delspr(s.map_tileset_fow^);freemem(s.map_tileset_fow);s.map_tileset_fow:=nil;end; 
 if s.mm_tileset<>nil      then begin delspr(s.mm_tileset^);     freemem(s.mm_tileset);     s.mm_tileset:=nil;end; 
 if s.mm_tileset_fow<>nil  then begin delspr(s.mm_tileset_fow^); freemem(s.mm_tileset_fow); s.mm_tileset_fow:=nil;end; 
end;
//############################################################################//     
//############################################################################//
//Clean up unitsdb sprite memory
procedure clean_one_gr(ud:ptypeunitsdb);
begin 
 if ud=nil then exit;
 deluspr(ud.img_poster);
 deluspr(ud.img_depot);
 deluspr(ud.spr_base);
 deluspr(ud.spr_list);
 deluspr(ud.spr_shadow);
 delusprv(ud.video);

 free_snd(ud.active_snd);
 free_snd(ud.water_active_snd); 
 free_snd(ud.boom_snd);
 free_snd(ud.stop_snd);
 free_snd(ud.start_snd);
 free_snd(ud.fire_snd);
  
 ud^.video.used:=false;
end;      
//############################################################################//
procedure cleangr(s:psdi_rec);
var i:integer; 
begin
 for i:=0 to length(s.eunitsdb)-1 do if s.eunitsdb[i]<>nil then begin
  clean_one_gr(s.eunitsdb[i]);
  dispose(s.eunitsdb[i]);
 end;
end;   
//############################################################################//
procedure clear_units_grpdb(s:psdi_rec);
begin           
 cleangr(s);
 setlength(s.eunitsdb,0);
end;
//############################################################################//
procedure fetch_vec(js:pjs_node;st:string;var v:vec);
begin  
 if js_get_node(js,st)=nil then exit;
 v.x:=vali(js_get_string(js,st+'[0]'));
 v.y:=vali(js_get_string(js,st+'[1]'));
 v.z:=vali(js_get_string(js,st+'[2]'));
end;
//############################################################################//
procedure proc_snd_par(s:psdi_rec;js:pjs_node;st:string;var snd:typsnds;loop:boolean);
var skip,len:double;
nam:string;
begin
 if js_get_node(js,st)=nil then exit;
 skip:=vale(js_get_string(js,st+'.skip'));
 len:=vale(js_get_string(js,st+'.len'));
 nam:=js_get_string(js,st+'.name'); 
 snd:=gensnd(s,nam,loop,skip,len);
end;
//############################################################################//
procedure ldgr(s:psdi_rec;spr:ptypuspr;fs:string;tp:integer);
begin
 spr.ex:=true;
 if vfexists(fs) then case tp of
  0:genuspr_sqr8(fs,spr);     //Base
  1:genuspr_sqr8(fs,spr);     //Shadow
  2:genuspr8(fs,spr,0);       //Poster and depot
  3:genuspr_one8(fs,spr);     //List view
 end else spr.ex:=false;
end;
//############################################################################//
function load_one_eunitsdb(s:psdi_rec;js:pjs_node):ptypeunitsdb;
var anim_dir,gr_dir,fn:string;
eud:ptypeunitsdb;
ud:ptypunitsdb;
begin result:=nil;try 
 new(eud);
 fillchar(eud^,sizeof(eud^),0);
 eud.udb_num:=-1;
 eud.spr_base.cnt:=1;
 eud.spr_list.cnt:=1;
 eud.spr_shadow.cnt:=1;
 
 eud.base_frames        :=tvec(0 ,0 ,2);
 eud.active_frames      :=tvec(-1,-1,2);
 eud.water_base_frames  :=tvec(0 ,0 ,2);
 eud.water_active_frames:=tvec(-1,-1,2);
 eud.animation_frames   :=tvec(-1,-1,2);
 eud.firing_base_frames :=tvec(-1,-1,2);
 eud.connector_frames   :=tvec(-1,-1,2);
 eud.gun_frames         :=tvec(-1,-1,2);
 eud.firing_gun_frames  :=tvec(-1,-1,2);;

 eud.typ:=lowercase(js_get_string(js,'type'));
 if eud.typ='nil' then begin dispose(eud);exit;end;
 eud.udb_num:=getdbnum(s.the_game,eud.typ);
 if eud.udb_num=-1 then begin dispose(eud);exit;end;
   
 gr_dir:=mgrootdir+unitsgrpdir+'/';  
 anim_dir:=mgrootdir+flicdir+'/';

 fetch_vec(js,'base_frames',eud.base_frames);
 fetch_vec(js,'active_frames',eud.active_frames);
 fetch_vec(js,'water_base_frames',eud.water_base_frames);
 fetch_vec(js,'water_active_frames',eud.water_active_frames);
 fetch_vec(js,'animation_frames',eud.animation_frames);
 fetch_vec(js,'firing_base_frames',eud.firing_base_frames);
 fetch_vec(js,'connector_frames',eud.connector_frames);
 fetch_vec(js,'gun_frames',eud.gun_frames);
 fetch_vec(js,'firing_gun_frames',eud.firing_gun_frames);

 fn:=js_get_string(js,'spr_base');  if fn<>'nil' then ldgr(s,@eud.spr_base,  gr_dir+fn+'.png',0);
 fn:=js_get_string(js,'spr_shadow');if fn<>'nil' then ldgr(s,@eud.spr_shadow,gr_dir+fn+'.png',1);
 fn:=js_get_string(js,'spr_list');  if fn<>'nil' then ldgr(s,@eud.spr_list,  gr_dir+fn+'.png',3); 
 if eud.spr_list.ex then scaleispr8(@eud.spr_list,vali(js_get_string(js,'i_size')));

 fn:=js_get_string(js,'img_poster');if fn<>'nil' then ldgr(s,@eud.img_poster,gr_dir+fn+'.png',2);
 fn:=js_get_string(js,'img_depot'); if fn<>'nil' then ldgr(s,@eud.img_depot, gr_dir+fn+'.png',2);
 fn:=js_get_string(js,'video');if fn<>'nil' then genusprvid8(anim_dir+fn+'.png',maxint,eud.video);

 if s.cg.load_unit_sounds then begin
  proc_snd_par(s,js,'active_snd',eud.active_snd,true);
  proc_snd_par(s,js,'water_active_snd',eud.water_active_snd,true);

  proc_snd_par(s,js,'boom_snd',eud.boom_snd,false);
  proc_snd_par(s,js,'fire_snd',eud.fire_snd,false);
  proc_snd_par(s,js,'stop_snd',eud.stop_snd,false);
  proc_snd_par(s,js,'start_snd',eud.start_snd,false);
 end;
    
 if eud.udb_num<>-1 then begin   
  if not eud.boom_snd.ex then begin
   eud.boom_snd:=def_boom;
   eud.boom_snd.copy:=true;
  end;
  ud:=get_unitsdb(s.the_game,eud.udb_num);
  eud.name_rus:=ud.name_rus;
  eud.name_eng:=ud.name_eng;
 end else begin 
  dispose(eud);
  eud:=nil;
 end;
 
 result:=eud;
  
 except stderr(s,'SDILoadSav','load_one_eunitsdb');end;
end;
//############################################################################//
procedure loadunits_grpdb(s:psdi_rec;signal:boolean);
var sz,i:integer;  
eud:ptypeunitsdb;
js:pjs_node;
f:vfile;
rs:string;
begin try
 if s.loaded_uniset then exit;
    
 if vfopen(f,mgrootdir+base_dir+'/eunits_db.txt',VFO_READ)<>VFERR_OK then exit;
 sz:=vffilesize(f);
 setlength(rs,sz);
 vfread(f,@rs[1],sz);
 vfclose(f);
 
 js:=js_parse(rs);
 if js=nil then exit;
 sz:=js_get_node_length(js,'eunits_db');
                        
 setlength(s.eunitsdb,sz);
 for i:=0 to length(s.eunitsdb)-1 do s.eunitsdb[i]:=nil;
 s.loaded_uniset:=true;
 
 for i:=0 to sz-1 do begin
  set_load_bar_pos(s,0.1+(i/sz)*0.9);
  s.steps.step_progress:=(i+1)/sz;
  eud:=load_one_eunitsdb(s,js_get_node(js,'eunits_db['+stri(i)+']'));  
  if eud<>nil then s.eunitsdb[i]:=eud;
 end;
  
 s.auxun[UN_BIGROPE]:=get_edb(s,'bigrope');
 s.auxun[UN_SMLROPE]:=get_edb(s,'smlrope');
 s.auxun[UN_BIGPLATE]:=get_edb(s,'bigplate');
 s.auxun[UN_SMLPLATE]:=get_edb(s,'smlplate');
 s.auxun[UN_MINING]:=get_edb(s,'mining');

 free_js(js);

 except stderr(s,'SDILoadSav','loadunits_grpdb');end;
end;
//############################################################################//
//############################################################################//
procedure js_to_minimap(s:psdi_rec;js:pjs_node;n:integer);
var map:string;
osz,csz,i,xs,ys:integer;
buf,cbuf:pointer;
mmap_spr:ptypspr; 
pal:pallette3;
begin
 map:=js_get_string(js,'minimap');
 osz:=vali(js_get_string(js,'size'));
 xs:=vali(js_get_string(js,'xs'));
 ys:=vali(js_get_string(js,'ys'));
 
 if map='nil' then exit;
    
 getmem(cbuf,3*length(map));
 getmem(buf,osz+10);
 csz:=b64_dec(@map[1],length(map),cbuf,3*length(map));   
 
 decodeLZW(cbuf,buf,csz,osz);
 
 for i:=0 to 255 do begin
  pal[i][CLRED]  :=vali(js_get_string(js,'pal['+stri(i)+'][0]'));
  pal[i][CLGREEN]:=vali(js_get_string(js,'pal['+stri(i)+'][1]'));
  pal[i][CLBLUE] :=vali(js_get_string(js,'pal['+stri(i)+'][2]'));
 end;
 
 s.map_pal_list[n]:=pal; 
 mmap_spr:=genspr_mem(buf,xs,ys);
 s.mmapbmp[n]:=sclmmap8(s,mmap_spr,true);
 s.mmapbmpbw[n]:=basmmap8(s,s.mmapbmp[n],s.map_pal_list[n]);
         
 freemem(cbuf);  
end;
//############################################################################//
function download_minimap(s:psdi_rec;nam:string;n:integer):boolean;
var st,rs:string;
js:pjs_node;
begin            
 sds_set_message(@s.steps,po('Downloading minimap'));
 st:=make_sys_request('get_minimap',',"name":"'+nam+'"}');
 sds_json_exchange(st,rs,nil);
 js:=js_parse(rs);
 
 js_to_minimap(s,js,n);

 free_js(js);
 
 result:=true;
end;     
//############################################################################//
procedure download_minimaps(s:psdi_rec;nummaps:integer);
var st,rs:string;
js:pjs_node;
i:integer;
begin            
 sds_set_dual_message(@s.steps,po('Server is indexing the maps')+'...',po('Downloading minimaps'));
 st:=make_sys_request('get_minimaps','');
 sds_json_exchange(st,rs,@s.steps.step_progress);
 js:=js_parse(rs);

 if js_get_node_length(js,'minimaps')<>nummaps then begin free_js(js);exit;end;

 for i:=0 to nummaps-1 do js_to_minimap(s,js_get_node(js,'minimaps['+stri(i)+']'),i);

 free_js(js);
end;
//############################################################################//
procedure getmaps(s:psdi_rec);
var i:integer;
nummaps:integer;
begin try 
 tolog('SDILoadSav','Getting maps');
                
 mutex_lock(sds_mx);
 nummaps:=length(s.map_list);
 
 setlength(s.mmapbmp,nummaps);
 setlength(s.mmapbmpbw,nummaps);
 setlength(s.map_pal_list,nummaps); 
 for i:=0 to nummaps-1 do begin      
  s.mmapbmp[i]:=nil;
  s.mmapbmpbw[i]:=nil;
 end;        
 mutex_release(sds_mx);   
 if nummaps=0 then exit;
 
 download_minimaps(s,nummaps);
 
 s.total_maps:=nummaps;
    
 except stderr(s,'SDILoadSav','GetMaps');end;
end;
//############################################################################//     
//############################################################################//
procedure sortlang(l,r:integer);
var i,j:integer;
p,t0,t1:string;
begin
 repeat
  i:=l;j:=r;
  p:=lang[(i+j)div 2][0];
  repeat
   while (i<r)and(p>lang[i][0]) do i:=i+1;
   while (i<r)and(p<lang[j][0]) do j:=j-1;
   if i<=j then begin  
    if i<j then begin
     t0:=lang[i][0];
     t1:=lang[i][1]; 
     lang[i][0]:=lang[j][0];
     lang[i][1]:=lang[j][1];
     lang[j][0]:=t0;
     lang[j][1]:=t1;  
    end;
    i:=i+1;
    j:=j-1;
   end;
  until i>j;
  if j>l then sortlang(l,j);
  if i<r then sortlang(i,r);
  l:=i;
 until i>=r;
end;
//############################################################################//
procedure add_lang(s:psdi_rec;e,r:string);
var i:integer;
begin
 for i:=0 to length(lang)-1 do if lang[i][0]=lowercase(e) then exit;
 i:=length(lang);
 setlength(lang,i+1);
 lang[i][0]:=lowercase(e);
 if s.cg.lang='eng' then lang[i][1]:=e;
 if s.cg.lang='rus' then lang[i][1]:=r;
end;  
//############################################################################//
procedure loadlang(s:psdi_rec);
begin
 tolog('SDI','Setting language');  
 
 setlength(lang,0);

 add_lang(s,'Cancel','Отмена');
 add_lang(s,'Close','Закрыть');
 add_lang(s,'Back','Назад');   
 add_lang(s,'Exit','Выход');
 add_lang(s,'Refresh','Обновить');
 add_lang(s,'Continue','Продолжить');
 add_lang(s,'Description','Описание');
 add_lang(s,'Done','Готово');
 add_lang(s,'Upgrades','Улучшения');
 add_lang(s,'Player','Игрок');    
 add_lang(s,'Players','Игроки');
 add_lang(s,'Begin','Начать');
 add_lang(s,'Map','Карта');   
 add_lang(s,'Unisets','Юнисеты');
 add_lang(s,'Uniset','Юнисет');
 add_lang(s,'Select','Выбрать');
 add_lang(s,'Casualties','Потери');
 add_lang(s,'Status','Статус');    
 add_lang(s,'Turn','Ход');
 add_lang(s,'Error','Ошибка');
 add_lang(s,'Accept','Принять');
 add_lang(s,'Page','Стр.');
 add_lang(s,'Prev','Пред.');
 add_lang(s,'Next','След.');
 add_lang(s,'Game','Партия');
 add_lang(s,'Lost','Проиграл');
 add_lang(s,'Won','Выиграл');
            
 add_lang(s,'Cost','Цена');
 add_lang(s,'Fuel','Топливо');
 add_lang(s,'Raw','Железо');
 add_lang(s,'Gold','Золото');
 add_lang(s,'Poor','Бедно');
 add_lang(s,'Medium','Средне');
 add_lang(s,'Rich','Много'); 

 add_lang(s,'Allies','Союзники');
 add_lang(s,'Colors','Цвета');
 add_lang(s,'Reports','Отчёты');
 add_lang(s,'End turn','Кон. хода');
 add_lang(s,'File','Файл');

 add_lang(s,'Server included','Встроенный сервер');
 add_lang(s,'Data unpacked','Данные распакованы');
 add_lang(s,'Data extracted','Данные извлечены');
 add_lang(s,'Internal data','Данные в комплекте');
 add_lang(s,'Data location unknown!','Данные в неизвестном месте!');

 add_lang(s,'New game','Новая игра'); 
 add_lang(s,'Options','Параметры');   
 add_lang(s,'Network games','Сетевые игры'); 
 
 add_lang(s,'Exit game','Выйти из игры');
 add_lang(s,'Back to menu','Назад в меню');
 add_lang(s,'Surrender','Сдаться');
 add_lang(s,'Press 2 more times to confirm','Нажмите ещё 2 раза чтобы подтвердить');
 add_lang(s,'Press 1 more times to confirm','Нажмите ещё 1 раз чтобы подтвердить');
 add_lang(s,'You have surrendered','Вы сдались');    
 add_lang(s,'Change password','Сменить пароль');
 add_lang(s,'Set','Установить');  
        
 add_lang(s,'Build','Строить');   
 add_lang(s,'Reverse','Наоборот');   
 add_lang(s,'Path','Путь');   
 add_lang(s,'Turns','Ходов');
 add_lang(s,'Build X1','Строить X1');
 add_lang(s,'Build X2','Строить X2');
 add_lang(s,'Build X4','Строить X4');
 
 add_lang(s,'Purchases','Закупки');
 add_lang(s,'Buy','Купить');
 add_lang(s,'Purchased','Куплено');
 add_lang(s,'Cargo','Груз');
 add_lang(s,'Available','Доступно');
 add_lang(s,'Credit','Деньги'); 
 
 add_lang(s,'Update','Обновить');  
 add_lang(s,'Cannot update - Disk not writable','Нельзя обновить - диск не пишется');  
 add_lang(s,'Current version','Локальная версия');
 add_lang(s,'Online version','Последняя версия');
 add_lang(s,'Checking','Проверяю');
 add_lang(s,'Cannot reach server','Сервер не отвечает');
 add_lang(s,'Cannot update - Nothing to update','Нельзя обновить - нечего обновлять');
 add_lang(s,'Checking for updates','Проверка обновлений');
 add_lang(s,'Downloading updates','Скачивание обновлений');
 
 add_lang(s,'All options','Все настройки');
 add_lang(s,'General','Общее');
 add_lang(s,'Common','Общее');
 add_lang(s,'Graphics & Sound','Графика и звук');
 add_lang(s,'Window size','Окно');
 add_lang(s,'Visuals','Видимости');
 add_lang(s,'Preview','Предпросмотр');
 add_lang(s,'Interface','Интерфейс');
 add_lang(s,'Language','Язык');
 add_lang(s,'Sound','Звук');
 add_lang(s,'Music','Музыка');
 add_lang(s,'Small RAM','Мало памяти');
 add_lang(s,'Scale down','Уменьшить');
 add_lang(s,'Scale up','Увеличить');
 add_lang(s,'Show FPS','Показывать FPS');
 add_lang(s,'Cursor','Курсор');
 add_lang(s,'Fog Of War','Туман войны');
 add_lang(s,'Shadows','Тени');
 add_lang(s,'Scale','Масштабирование');
 add_lang(s,'Size','Размер');
 add_lang(s,'Apply','Применить');
 add_lang(s,'Double buffering','Double buffering');
 add_lang(s,'Map edges','Края карты');
 add_lang(s,'FOW density','Плотность FOW');
 add_lang(s,'Shadow density','Плотность теней');
 add_lang(s,'Square Range','Квадраты диап.');
 add_lang(s,'Circle Range','Круги диап.');
 add_lang(s,'Range on Destination','Диап. в конце пути');
 add_lang(s,'Zoom to Cursor','Зум по курсору');
 add_lang(s,'Zoom Speed','Скорость зума');
     
 add_lang(s,'Players Parameters','Параметры игроков');
 add_lang(s,'Number of Players','Кол-во игроков');
 add_lang(s,'Player name','Имя игрока');
 add_lang(s,'Game settings','Настройки партии');
 add_lang(s,'Game name','Имя партии');
 add_lang(s,'Starting gold','Начальные деньги');
 add_lang(s,'Moratorium','Мораторий');
 add_lang(s,'Moratorium range','Диапазон моратория');
 add_lang(s,'Rules','Правила');
 add_lang(s,'Fuel exchange','Передача бензина');
 add_lang(s,'No Passwords','Без паролей');
 add_lang(s,'Debug mode','Отладочный режим');
 add_lang(s,'Start with radar','Начальный радар');
 add_lang(s,'Direct landing','Прямая высадка');
 add_lang(s,'Direct gold','Прямые обновления');
 add_lang(s,'Lay connectors','Быстрые коннекторы');
 add_lang(s,'No survey','Без геолога');
 add_lang(s,'Center 4X scan','Центр скана 4Х');
 add_lang(s,'Expensive refuel','Дорогое топливо');
 add_lang(s,'No military purchases','Без военных закупок');
 add_lang(s,'Unloading','Выгрузка');
 add_lang(s,'No Speed','Без скорости');
 add_lang(s,'No Shots','Без выстрелов');
 add_lang(s,'-1 Speed (Unloading)','-1 скорости (выход)');
 add_lang(s,'-1 Speed (Loading)','-1 скорости (вход)');
 add_lang(s,'On landing pads','Только на площадках');
 add_lang(s,'Resources','Ресурсы');
 add_lang(s,'Resource fields','Месторождения');
 add_lang(s,'No maps','Нет карт');

 add_lang(s,'Player setup','Установки игрока');
 add_lang(s,'Name','Имя');
 add_lang(s,'Player Color','Цвет игрока');
 add_lang(s,'Select Player Color','Выбор цвета игрока');
 add_lang(s,'Password','Пароль');
                       
 add_lang(s,'Playback','Воспроизвести');
 add_lang(s,'Continue','Продолжить');
 add_lang(s,'Server','Сервер');
 add_lang(s,'Game name','Имя партии');
 add_lang(s,'State','Состояние');
 add_lang(s,'Now','Сейчас');
 add_lang(s,'Active','Активна');
 add_lang(s,'Landing','Высадка');
 add_lang(s,'Finished','Закончена');
 add_lang(s,'Intersected','Пресечение');
 add_lang(s,'Finished ones','Закончившиеся');  
  
 add_lang(s,'Set turn','Установить ход');

 add_lang(s,'Information','Информация');

 add_lang(s,'Unit Rename','Переименование юнита');

 add_lang(s,'Resource balance','Баланс ресурсов');
 add_lang(s,'Usage','Требуется');
 add_lang(s,'Reserve','Хранится');

 add_lang(s,'Map grid color','Цвет сетки карты');
 add_lang(s,'Change color settings','Смена настроек цвета');

 add_lang(s,'Game entry','Вход в игру');
 add_lang(s,'Enter game','Войти в игру');
 add_lang(s,'Enter password','Введите пароль');
 add_lang(s,'Landed','Высадился');
 add_lang(s,'In Orbit','На орбите');
 add_lang(s,'Complete','Закончил');  
 add_lang(s,'Waiting for landing','Ожидает высадки');
 add_lang(s,'Waiting','Ожидает');
 add_lang(s,'Ready for landing','Готов к высадке');
 add_lang(s,'Next Player','Следующий');
              
 add_lang(s,'Allied','Союзник');
 add_lang(s,'Wannabe','Просится');
 add_lang(s,'Enemy','Враг');    
 add_lang(s,'Select your allies','Выберите, с кем дружить');
 add_lang(s,'The enemy must do the same to become an friend','Враг должен сделать то же, чтобы стать другом');
 add_lang(s,'Your opinion','Ваше мнение');
 add_lang(s,'Their opinion','Их мнение');

 add_lang(s,'Select Clan','Выбор клана');
 add_lang(s,'Bonus engineers','Бонус инженеры'); 
 add_lang(s,'Bonus constructors','Бонус конструкторы');
 
 add_lang(s,'Title','Заголовок');
 add_lang(s,'Global','Глобальный');

 add_lang(s,'Boom it','Подорвать');
 
 add_lang(s,'Research','Исследования');
 add_lang(s,'Labs','Лабы');
 add_lang(s,'Topics','Темы');
 
 add_lang(s,'Total','Всего');
 add_lang(s,'Used','Испол');
 add_lang(s,'Energ','Энерг');
 add_lang(s,'Man','Людей');  
 add_lang(s,'Store','Мест');
 add_lang(s,'Hits','УДП');
 add_lang(s,'Shot','Выстр');
 add_lang(s,'Attack','Атака');
 add_lang(s,'Shots','Выстрелы');
 add_lang(s,'Range','Диапазон');
 add_lang(s,'Ammo','Патрн');
 add_lang(s,'Armor','Броня');
 add_lang(s,'Scan','Скан');
 add_lang(s,'Speed','Скорость');
 add_lang(s,'Spd','Скор');
 add_lang(s,'Gas','Бензин');
 add_lang(s,'Cost','Цена');
 add_lang(s,'Area','Зона');

 add_lang(s,'Maxgold launched','Maxgold запущен');
 add_lang(s,'Error loading minimap of','Ошибка загрузки миникарты от');
 add_lang(s,'Start of turn','Начало хода');
 add_lang(s,'Select landing position','Выберите место для посадки');
 add_lang(s,'Confirm landing','Подтвердите высадку');
 add_lang(s,'Loading units','Загрузка юнитов');
 add_lang(s,'Postinit','Послезагрузка');
 add_lang(s,'Cleaning up','Очистка');
 add_lang(s,'Starting game on the map','Начинаем игру на карте');
 add_lang(s,'Reading','Читаем');
 add_lang(s,'Loading map','Загрузка карты');
 add_lang(s,'Starting game','Начинаем игру');
 add_lang(s,'Setting settings','Чистим настройки');
 add_lang(s,'Configuring players','Настройка игроков');
 add_lang(s,'Error loading map','Ошибка загрузки карты');

 add_lang(s,'Steal','Угнать');
 add_lang(s,'Disable','Отрубить');
 add_lang(s,'Autorun','Автопоиск');  
 add_lang(s,'Repair','Чинить');
 add_lang(s,'Reload','Заряд');
 add_lang(s,'Refuel','Заправ');
 add_lang(s,'Research','Исследовать');
 add_lang(s,'Balance','Баланс');
 add_lang(s,'Activate','Выпустить');
 add_lang(s,'Load','Погрузить');
 add_lang(s,'Attack','Атака');
 add_lang(s,'Enter','Войти');
 add_lang(s,'Move','Двигать');
 add_lang(s,'Stop','Стоп');
 add_lang(s,'Start','Старт');
 add_lang(s,'X-fer','Передача'); 
 add_lang(s,'Give 2','Дать 2');
 add_lang(s,'Clean','Очистка');
 add_lang(s,'Put mines','Минировать');
 add_lang(s,'Unmine','Разминир.');
 add_lang(s,'Sentry','Страж');                                
 add_lang(s,'Remove','Подрыв');
 add_lang(s,'Upgrade','Обновить'); 
 add_lang(s,'Upgrade all','Обновить все');
 add_lang(s,'Done','Готово');
 

 add_lang(s,'Units','Юниты');
 add_lang(s,'Casualties','Потери');
 add_lang(s,'Score','Очки');
 add_lang(s,'Messages','Сообщения');
 add_lang(s,'Enemy','Враг');
 add_lang(s,'Including','Включая');
 add_lang(s,'Air','Воздух');
 add_lang(s,'Ground','Земля');
 add_lang(s,'Sea','Море'); 
 add_lang(s,'Buildings','Здания');
 add_lang(s,'Engineering','Строители');
 add_lang(s,'Filter','Фильтр');
 add_lang(s,'Builder','Строитель');
 add_lang(s,'Attacker','Атакующий');
 add_lang(s,'Damaged','Поврежден');
 add_lang(s,'Stealth','Стелс');
 add_lang(s,'Moving','Двигается');
 add_lang(s,'Landing','Высадка');
 add_lang(s,'Start of turn','Начало хода');
 add_lang(s,'Build completed','Строительство закончено');
 add_lang(s,'Research completed','Исследование закончено');
 add_lang(s,'Plane crashed','Самолёт разбился');
 add_lang(s,'Player lost','Игрок проиграл');
 add_lang(s,'Unit under attack','Юнит атакован');
 add_lang(s,'Unit destroyed','Юнит уничтожен');
 add_lang(s,'Stoped, not enough of resources','Остановлен, не хватает ресурсов');
 add_lang(s,'Unit disabled','Юнит вырублен');
 add_lang(s,'Unit stolen','Юнит угнан');
 add_lang(s,'Enemy unit spotted','Замечен вражеский юнит');
 add_lang(s,'Enemy unit hidden','Упущен вражеский юнит');
 add_lang(s,'Enemy unit moved','Вражеский юнит сдвинулся');
 
 add_lang(s,'Leave','Выйти');
 add_lang(s,'in complex','в комплексе');
 add_lang(s,'For all','Для всех');
 
 add_lang(s,'Communicating','Связь и обработка');
 
 add_lang(s,'Survey','Геолог');
 add_lang(s,'Grid','Сетка');
 add_lang(s,'Moves','Ходы');
 add_lang(s,'Colors','Цвета');
 add_lang(s,'Names','Имена');
 add_lang(s,'Builds','Стройка');
 
 add_lang(s,'Menu','Меню');
 add_lang(s,'Confirm end of turn','Подтвердите конец хода');

 add_lang(s,'About','Об игре');


 add_lang(s,'Server is generating the replay','Ждём пока сервер вычислит риплей');
 add_lang(s,'Downloading the replay','Скачиваем риплей');
 add_lang(s,'Parsing the replay','Индексируем риплей');
 add_lang(s,'Server is indexing the maps','Сервер индексирует карты');
 add_lang(s,'Downloading minimaps','Скачиваем миникарты');
 add_lang(s,'Downloading the map','Скачиваем карту');
 add_lang(s,'Downloading minimap','Скачиваем миникарту');

 sortlang(0,length(lang)-1);
end;
//############################################################################//     
procedure set_vcomp(var v:vcomp;x,y,xs,ys:integer);
begin
 v.x:=x;
 v.y:=y;
 v.sx:=xs;
 v.sy:=ys;
end;
//############################################################################//
procedure loadint(s:psdi_rec);
begin
 tolog('SDI','Setting interface config');

 set_vcomp(s.cg.intf.uview,10,10,128,128);    
 set_vcomp(s.cg.intf.mmap,10+128+5,10,112,112);  
 
 set_vcomp(s.cg.intf.stats,10+128+5+112+5,10,175,92);  
 set_vcomp(s.cg.intf.coord,10+128+5+112+5,10+5+92,175,30);
 
 set_vcomp(s.cg.intf.rmnu,10,10+128+5,65*2,25*2);
end;   
//############################################################################//
procedure loadsetup(s:psdi_rec);
var i,sz:integer;
js:pjs_node;
st:string;
f:vfile;
begin js:=nil; try
 if vfexists(mgrootdir+'maxg.txt') then if vfopen(f,mgrootdir+'maxg.txt',VFO_READ)=VFERR_OK then begin
  sz:=vffilesize(f);
  setlength(st,sz);
  vfread(f,@st[1],sz);
  vfclose(f);

  js:=js_parse(st);
  if js<>nil then begin
   st:=js_get_string(js,'fps_limit');       if st<>'nil' then max_fps              :=vali(st);
   st:=js_get_string(js,'scale_screen');    if st<>'nil' then use_scaling          :=vali(st)<>0;
   st:=js_get_string(js,'mapedge');         if st<>'nil' then s.cg.mapedge         :=vali(st)<>0;
   st:=js_get_string(js,'sounds');          if st<>'nil' then snd_on               :=vali(st)<>0;
   st:=js_get_string(js,'music');           if st<>'nil' then snd_muson            :=vali(st)<>0;
   st:=js_get_string(js,'unit_sounds');     if st<>'nil' then s.cg.load_unit_sounds:=vali(st)<>0;
   st:=js_get_string(js,'fps');             if st<>'nil' then fpsdbg               :=vali(st)<>0;
   st:=js_get_string(js,'runcnt');          if st<>'nil' then s.runcnt             :=vali(st);
   st:=js_get_string(js,'fow');             if st<>'nil' then s.cg.fog_of_war      :=vali(st)<>0;
   st:=js_get_string(js,'fow_density');     if st<>'nil' then s.cg.fow_density     :=vali(st)/100;
   st:=js_get_string(js,'shadow_density');  if st<>'nil' then s.cg.shadow_density  :=vali(st)/100;
   st:=js_get_string(js,'ut_circle');       if st<>'nil' then s.ut_circles         :=vali(st)<>0;
   st:=js_get_string(js,'ut_square');       if st<>'nil' then s.ut_squares         :=vali(st)<>0;
   st:=js_get_string(js,'ut_at_end_move');  if st<>'nil' then s.ut_at_end_move     :=vali(st)<>0;
   st:=js_get_string(js,'cursor');          if st<>'nil' then s.cg.show_cursor     :=vali(st)<>0;
   st:=js_get_string(js,'center_zoom');     if st<>'nil' then s.center_zoom        :=vali(st)<>0;
   st:=js_get_string(js,'zoom_speed');      if st<>'nil' then s.zoomspd            :=vale(st);
   st:=js_get_string(js,'shadows');         if st<>'nil' then s.cg.unit_shadows    :=vali(st)<>0;
   st:=js_get_string(js,'language');        if st<>'nil' then s.cg.lang            :=trim(st);
   st:=js_get_string(js,'game_server');     if st<>'nil' then gs_server            :=st;
   st:=js_get_string(js,'game_server_port');if st<>'nil' then gs_port              :=vali(st);
   st:=js_get_string(js,'game_server_code');if st<>'nil' then gs_code              :=st;
   free_js(js);
  end;
 end;  
        
 if paramcount<>0 then for i:=0 to paramcount-1 do if paramstr(i+1)='--lang' then begin 
  if paramcount<i+1 then break;
  s.cg.lang:=paramstr(i+2);
  break;
 end;
 
 except stderr(s,'SDILoadSav','LoadSetup');end;
end;
//############################################################################//
procedure savesetup(s:psdi_rec);
var f:vfile;
st,sp,nl:string;
begin try
 sp:='';
 nl:=#$0A;
 st:='';

 js_add_int (st,sp,nl,'fps_limit'      ,max_fps);
 js_add_bool(st,sp,nl,'scale_screen'   ,use_scaling);
 js_add_bool(st,sp,nl,'mapedge'        ,s.cg.mapedge);
 js_add_bool(st,sp,nl,'fow'            ,s.cg.fog_of_war);
 js_add_int (st,sp,nl,'fow_density'    ,round(s.cg.fow_density*100));
 js_add_int (st,sp,nl,'shadow_density' ,round(s.cg.shadow_density*100));
 js_add_bool(st,sp,nl,'ut_circle'      ,s.ut_circles);
 js_add_bool(st,sp,nl,'ut_square'      ,s.ut_squares);
 js_add_bool(st,sp,nl,'ut_at_end_move' ,s.ut_at_end_move);
 js_add_bool(st,sp,nl,'shadows'        ,s.cg.unit_shadows);

 js_add_str (st,sp,nl,'game_server'     ,gs_server);
 js_add_int (st,sp,nl,'game_server_port',gs_port);
 js_add_str (st,sp,nl,'game_server_code',gs_code);

 js_add_bool(st,sp,nl,'sounds'     ,snd_on);
 js_add_bool(st,sp,nl,'music'      ,snd_muson);
 js_add_bool(st,sp,nl,'unit_sounds',s.cg.load_unit_sounds);

 js_add_bool(st,sp,nl,'fps'        ,fpsdbg);

 js_add_bool(st,sp,nl,'cursor'     ,s.cg.show_cursor);
 js_add_bool(st,sp,nl,'center_zoom',s.center_zoom);
 js_add_dbl (st,sp,nl,'zoom_speed' ,s.zoomspd);
 js_add_str (st,sp,nl,'language'   ,s.cg.lang);
 js_add_int (st,sp,nl,'runcnt'     ,s.runcnt);

 js_finish(st,sp,nl);

 if vfopen(f,mgrootdir+'maxg.txt',VFO_WRITE)<>VFERR_OK then exit;
 vfwrite(f,@st[1],length(st));
 vfclose(f);

 except stderr(s,'LoadSav','SaveSetup');end;
end;    
//############################################################################//
begin
 savsetup:=savesetup;
end.
//############################################################################//
