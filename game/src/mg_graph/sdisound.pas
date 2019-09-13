//############################################################################//
{$ifdef mswindows}{$define can_sound}{$endif}
{$ifdef linux}{$define can_sound}{$endif}
{$ifdef darwin}{$undef can_sound}{$endif}
{$ifdef ios}{$undef can_sound}{$endif}
unit sdisound;
interface
uses sysutils,asys,maths,vfsint,mgrecs,sdirecs,sdiauxi,mgl_common
{$ifdef can_sound},sound{$endif};
//############################################################################//
function  gensnd(s:psdi_rec;fn:string;loop:boolean;skip,len:double):typsnds;
procedure free_snd(var snd:typsnds);

procedure snd_click(tp:integer);
procedure snd_voice(tp:integer);
procedure initsound(s:psdi_rec;mode:byte);
procedure clear_sound;
procedure play_running_snd(s:psdi_rec;u:ptypunits);
procedure stop_running_snd(s:psdi_rec);
procedure play_fire_snd(s:psdi_rec;u:ptypunits);
procedure play_boom_snd(s:psdi_rec;u:ptypunits);
procedure play_stop_snd(s:psdi_rec;u:ptypunits);
procedure play_start_snd(s:psdi_rec;u:ptypunits);

procedure set_music(n:integer);
procedure handle_background_sounds;
//############################################################################//
var
snd_on:boolean=false;
snd_muson:boolean=false;
def_boom:typsnds;                          //Default boom sound
//############################################################################//
implementation
//############################################################################//
var snd_ptr:array of pointer;
snd_count:integer=0;
snd_inited:boolean=false;

running_snd,on_snd:typsnds; 
snd_arr,snd_voice_arr:array of typsnds;//Sounds array
snd_muslst:astr;                       //List of music
snd_cmus:integer;                      //Current music
snd_bkgrmus:pointer=nil;               //Background music ptr
//############################################################################//
{$ifdef can_sound}
function ogg_vfsload(fn:string;skip,len:double):pchannel;
var f:vfile;
ptr:pointer;
ok:boolean;
samp,samp0:aosingle;
size,channels,sample_rate,a,b:integer;
begin
 result:=nil;
 if not vfexists(fn) then exit;

 vfopen(f,fn,VFO_READ);
 size:=vffilesize(f);
 getmem(ptr,size);
 vfread(f,ptr,size);
 vfclose(f);
 setlength(samp,0);
 sample_rate:=0;
 channels:=0;
 ok:=false;//decode_ogg_vorbis(ptr,size,samp,channels,sample_rate);
 freemem(ptr);
 if not ok then exit;

 if (skip>eps)or(len>eps) then begin
  setlength(samp0,length(samp));
  move(samp[0],samp0[0],length(samp)*sizeof(single));

  if skip>eps then begin
   a:=round(sample_rate*channels*skip);
   a:=a-(a mod channels);
  end else a:=0;
  if len>eps then begin
   b:=round(sample_rate*channels*len); 
   b:=b-(b mod channels);
  end else b:=length(samp);

  if a+b>length(samp) then b:=length(samp)-a;
  if b<0 then b:=0;

  move(samp0[a],samp[0],b*sizeof(single));
  setlength(samp,b);
 end;
 
 getmem(ptr,length(samp)*sizeof(single));
 move(samp[0],ptr^,length(samp)*sizeof(single));

 result:=sound_get_new_channel;
 result.fmt:=0;//SND_FMT_F32;
 result.rate:=sample_rate;
 result.ch_cnt:=channels;
 result.len:=length(samp);
 result.buf:=ptr;

 setlength(snd_ptr,snd_count+1);
 snd_ptr[snd_count]:=ptr;
 snd_count:=snd_count+1;
end;
{$endif}
//############################################################################//
function gensnd(s:psdi_rec;fn:string;loop:boolean;skip,len:double):typsnds;
var nam,dir0,dir1,dir2:string;
begin try
 result.ex:=false;
 result.copy:=false;
 result.snd:=nil;
 if not snd_on then exit;

 {$ifdef can_sound}
 dir0:=mgrootdir+sound_dir0+'/';
 dir1:=mgrootdir+sound_dir1+'/';
 dir2:=mgrootdir+sound_dir2+'/';
 nam:='';
 if vfexists(dir0+fn+'.ogg') then nam:=dir0+fn+'.ogg' else
 if vfexists(dir1+fn+'.ogg') then nam:=dir1+fn+'.ogg' else
 if vfexists(dir2+fn+'.ogg') then nam:=dir2+fn+'.ogg' else exit;
 result.ex:=true;
 result.nam:=nam;
 result.snd:=ogg_vfsload(nam,skip,len);
 if loop then sound_ch_set_loop(result.snd,true);
 {$endif}

 except stderr(s,'SDISound','gensnd');end; 
end;
//############################################################################//
procedure initsound(s:psdi_rec;mode:byte);
var mdir:string;
i:integer;
l:avdir;
begin l:=nil; try
 if snd_inited then exit;
 tolog('SDISound','Loading sounds');

 snd_cmus:=-1;
 running_snd.ex:=false;
 running_snd.copy:=false;
 on_snd.ex:=false;
 on_snd.copy:=false;
 def_boom.ex:=false;
 def_boom.copy:=false;

 {$ifdef can_sound}
 mdir:=mgrootdir+musdir+'/';
 if not vfexists(mgrootdir+sound_dir0+'/nosnd.ogg') then snd_on:=false;

 if snd_on then begin
  if not sound_init('default',22050,2) then begin snd_on:=false; tolog('SDIINIT','Sound card not found');exit;end;
  tolog('SDISound','Searching for music');
  
  setlength(snd_arr,8);
  snd_arr[SND_TCK]        :=gensnd(s,'kbuy0',false,0,0);
  snd_arr[SND_BUTTON]     :=gensnd(s,'menu38',false,0,0);
  snd_arr[SND_DENY]       :=gensnd(s,'mengens3',false,0,0);
  snd_arr[SND_TOGGLE]     :=gensnd(s,'ihits0',false,0,0);
  snd_arr[SND_ACCEPT]     :=gensnd(s,'mengens4',false,0,0);
  snd_arr[SND_HIT_MED]    :=gensnd(s,'hitmed',false,0,0);
  snd_arr[SND_ENTER]      :=gensnd(s,'scale',false,0,0);
  snd_arr[SND_EXPLODE_MED]:=gensnd(s,'explmed',false,0,0);
  //snd_arr[00]:=gensnd(s,'ksel0',false,0,0);
  //snd_arr[06]:=gensnd(s,'hitsmal',false,0,0);
  //snd_arr[08]:=gensnd(s,'hitlarge',false,0,0);
  //snd_arr[09]:=gensnd(s,'ping',false,0,0);
   
  def_boom:=snd_arr[SND_EXPLODE_MED];
  
  setlength(snd_voice_arr,39);
  snd_voice_arr[ 0]:=gensnd(s,'f001',false,0,0);//Ready
  snd_voice_arr[ 1]:=gensnd(s,'f004',false,0,0);//All systems go
  snd_voice_arr[ 2]:=gensnd(s,'f005',false,0,0);//Standing by
  snd_voice_arr[ 3]:=gensnd(s,'f006',false,0,0);//Awaiting orders
  snd_voice_arr[ 4]:=gensnd(s,'f138',false,0,0);//Ammunition is low
  snd_voice_arr[ 5]:=gensnd(s,'f142',false,0,0);//Ammo depleted
  snd_voice_arr[ 6]:=gensnd(s,'f145',false,0,0);//Movement exhausted
  snd_voice_arr[ 7]:=gensnd(s,'f150',false,0,0);//Status yellow
  snd_voice_arr[ 8]:=gensnd(s,'f151',false,0,0);//Status caution
  snd_voice_arr[ 9]:=gensnd(s,'f154',false,0,0);//Status red
  snd_voice_arr[10]:=gensnd(s,'f155',false,0,0);//Status critical
  snd_voice_arr[11]:=gensnd(s,'f158',false,0,0);//On sentry
  snd_voice_arr[12]:=gensnd(s,'f171',false,0,0);//Clearing area
  snd_voice_arr[13]:=gensnd(s,'f181',false,0,0);//Laying mines
  snd_voice_arr[14]:=gensnd(s,'f182',false,0,0);//Dropping mines
  snd_voice_arr[15]:=gensnd(s,'f186',false,0,0);//Removing mines
  snd_voice_arr[16]:=gensnd(s,'f187',false,0,0);//Picking up mines
  snd_voice_arr[17]:=gensnd(s,'f191',false,0,0);//Surveying
  snd_voice_arr[18]:=gensnd(s,'f192',false,0,0);//Searching
  snd_voice_arr[19]:=gensnd(s,'f196',false,0,0);//Attacking
  snd_voice_arr[20]:=gensnd(s,'f198',false,0,0);//Engaging enemy

  snd_voice_arr[21]:=gensnd(s,'f162',false,0,0);//Construction complete
  snd_voice_arr[22]:=gensnd(s,'f165',false,0,0);//Building finished
  snd_voice_arr[23]:=gensnd(s,'f166',false,0,0);//Unit completed
  snd_voice_arr[24]:=gensnd(s,'f169',false,0,0);//Unit finished

  snd_voice_arr[25]:=gensnd(s,'f070',false,0,0);//Enemy detected
  snd_voice_arr[26]:=gensnd(s,'f071',false,0,0);//Enemy spotted
  snd_voice_arr[27]:=gensnd(s,'f085',false,0,0);//Reloaded
  snd_voice_arr[28]:=gensnd(s,'f089',false,0,0);//General reload succesful
  snd_voice_arr[29]:=gensnd(s,'f094',false,0,0);//No path to destination
  snd_voice_arr[30]:=gensnd(s,'f095',false,0,0);//No path to destination

  snd_voice_arr[31]:=gensnd(s,'f176',false,0,0);//Select site
  snd_voice_arr[32]:=gensnd(s,'f177',false,0,0);//Choose site
  snd_voice_arr[33]:=gensnd(s,'f224',false,0,0);//Transfer complete

  snd_voice_arr[34]:=gensnd(s,'f053',false,0,0);//Begin
  snd_voice_arr[35]:=gensnd(s,'f093',false,0,0);//Research complete
  snd_voice_arr[36]:=gensnd(s,'f057',false,0,0);//Fuel storage is full
  snd_voice_arr[37]:=gensnd(s,'f061',false,0,0);//Raw material storage is full
  snd_voice_arr[38]:=gensnd(s,'f066',false,0,0);//Gold storage is full


  l:=vffind_arr(mdir+'*.ogg',attall);
  setlength(snd_muslst,length(l));
  for i:=0 to length(l)-1 do snd_muslst[i]:=l[i].name;
  if length(snd_muslst)>0 then set_music(random(length(snd_muslst)));
 end;
 snd_inited:=true;
 {$endif}

 except stderr(s,'SDISound','InitSound');end; 
end;
//############################################################################//
procedure snd_click(tp:integer);
begin
 if not snd_on then exit;
 if tp<0 then exit;
 if tp>=length(snd_arr) then exit;
 if snd_arr[tp].snd=nil then exit;

 {$ifdef can_sound}
 sound_ch_replay(snd_arr[tp].snd);
 {$endif}
end;
//############################################################################//
procedure snd_voice(tp:integer);
begin
 if not snd_on then exit;
 if tp<0 then exit;
 if tp>=length(snd_voice_arr) then exit;
 if snd_voice_arr[tp].snd=nil then exit;

 {$ifdef can_sound}
 sound_ch_vol(snd_voice_arr[tp].snd,0.5);
 sound_ch_replay(snd_voice_arr[tp].snd);
 {$endif}
end;
//############################################################################//
procedure play_eu_snd(s:psdi_rec;u:ptypunits;tp:integer);
var ud:ptypunitsdb;
eu:ptypeunitsdb;
begin try
 if s=nil then exit;
 if not snd_on then exit;
 if u=nil then exit;

 ud:=get_unitsdb(s.the_game,u.dbn);
 eu:=get_edb(s,ud.typ);
 if eu=nil then exit;

 {$ifdef can_sound}
 case tp of
  1:begin
   running_snd:=eu.active_snd;
   if running_snd.ex then sound_ch_replay(running_snd.snd);
  end;
  2:if eu.boom_snd.ex then sound_ch_replay(eu.boom_snd.snd);
  3:if eu.stop_snd.ex then sound_ch_replay(eu.stop_snd.snd);
  4:if eu.fire_snd.ex then sound_ch_replay(eu.fire_snd.snd);
  5:begin
   on_snd:=eu.start_snd;
   if on_snd.ex then sound_ch_replay(on_snd.snd);
  end;
 end;
 {$endif}

 except stderr(s,'SDISound','play_eu_snd');end;
end;
//############################################################################//
procedure play_running_snd(s:psdi_rec;u:ptypunits);begin play_eu_snd(s,u,1);end;
procedure play_boom_snd   (s:psdi_rec;u:ptypunits);begin play_eu_snd(s,u,2);end;
procedure play_stop_snd   (s:psdi_rec;u:ptypunits);begin play_eu_snd(s,u,3);end;
procedure play_fire_snd   (s:psdi_rec;u:ptypunits);begin play_eu_snd(s,u,4);end;
procedure play_start_snd  (s:psdi_rec;u:ptypunits);begin play_eu_snd(s,u,5);end;
//############################################################################//
procedure stop_running_snd(s:psdi_rec);
begin try  
 if not running_snd.ex and not on_snd.ex then exit;
 running_snd.ex:=false;
 on_snd.ex:=false;     
 {$ifdef can_sound}
 if running_snd.snd<>nil then sound_ch_stop(running_snd.snd);
 if on_snd.snd<>nil then sound_ch_stop(on_snd.snd);
 {$endif}

 except stderr(s,'SDISound','stop_running_snd');end;
end;
//############################################################################//
procedure set_music(n:integer);
var mdir:string;
begin
 {$ifdef can_sound}
 mdir:=mgrootdir+musdir+'/';
 if (n<0)or(n>=length(snd_muslst)) then exit;

 if snd_on and snd_muson then begin
  if snd_bkgrmus<>nil then sound_ch_free(snd_bkgrmus);
  snd_bkgrmus:=ogg_vfsload(mdir+snd_muslst[n],0,0);
  if snd_bkgrmus<>nil then sound_ch_play(snd_bkgrmus); 
  snd_cmus:=n;
 end;
 {$endif}
end;
//############################################################################//
procedure handle_background_sounds;
begin
 {$ifdef can_sound}
 if snd_on and snd_muson and(snd_cmus<>-1)and(snd_bkgrmus<>nil) then if not sound_ch_is_play(snd_bkgrmus) then begin
  snd_cmus:=(snd_cmus+1) mod length(snd_muslst);
  set_music(snd_cmus);
 end;
 {$endif}
end;     
//############################################################################//
procedure free_snd(var snd:typsnds);
begin
 if not snd.ex then exit;
 if snd.copy then begin  
  snd.ex:=false;
  snd.snd:=nil;
  snd.copy:=false;
  snd.nam:='';
  exit;
 end;
 {$ifdef can_sound}if snd.snd<>nil then sound_ch_free(snd.snd);{$endif} 
 snd.ex:=false;
 snd.snd:=nil;
 snd.copy:=false;
 snd.nam:='';
end;
//############################################################################//
procedure clear_sound;
var i:integer;
begin
 if not snd_inited then exit;
 snd_inited:=false;
 {$ifdef can_sound}sound_deinit;{$endif}
 for i:=0 to length(snd_ptr)-1 do if snd_ptr[i]<>nil then freemem(snd_ptr[i]);
 for i:=0 to length(snd_arr)-1 do free_snd(snd_arr[i]);
 for i:=0 to length(snd_voice_arr)-1 do free_snd(snd_voice_arr[i]);
 {$ifdef can_sound}if snd_bkgrmus<>nil then sound_ch_free(snd_bkgrmus);{$endif}
 setlength(snd_ptr,0);
 setlength(snd_arr,0);
 setlength(snd_voice_arr,0);
 setlength(snd_muslst,0);
 snd_count:=0;
 snd_bkgrmus:=nil;
end;
//############################################################################//
begin
end.   
//############################################################################//
