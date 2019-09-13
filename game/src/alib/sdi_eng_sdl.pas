//############################################################################// 
{$ifdef FPC}{$MODE delphi}{$endif}   
unit sdi_eng_sdl;
interface
uses asys,grph,tim,sdi_scale,sdi_rec,SDL;
//############################################################################//
procedure eng_sdwinunfoc;
procedure eng_sdwinfoc;
procedure eng_sdwinmousein;
procedure eng_sdwinmouseout;
procedure eng_settitle(a:string);
procedure eng_setsdlpal;
procedure eng_sditestscreenset(var fs:boolean);
procedure eng_sdi_handleinput;
procedure eng_sdiloop;
procedure eng_setsdi(x,y,b:integer;f:boolean;cap:string;tim,evt:pointer);
procedure eng_sdiset_win_pos(x,y:integer);
procedure eng_sdisdlquit;
procedure eng_sdiflip;
function eng_sdilock:boolean;
function eng_sdicursor(n:integer):integer;
procedure eng_sdiunlock;
procedure eng_sdi_touch_params;
//############################################################################//
implementation                                         
//############################################################################//
function stri(par:int64):string;begin str(par,result);end;
//############################################################################//
var
sdquit:boolean;
pks:array[0..65535]of boolean;  
mbtns:array[0..2]of boolean;   
sdlpScr:PSDL_Surface;
codes:array[0..255]of word;    //Translates scancodes into unicodes, as a buffer for keyup, sice SDL does not provede proper unicede on up.
//############################################################################//
procedure eng_sdwinunfoc;
begin   {
 if sdifocusoff then begin
  sdifocus:=false;
  eng_sdiflip;
 end;   }
end;
//############################################################################//
procedure eng_sdwinfoc;
begin    {
 if sdifocusoff then begin
  sdiev:=true;
  sdifocus:=true;
 end;  }
end;    
//############################################################################//
procedure eng_sdwinmousein;begin end;
procedure eng_sdwinmouseout;begin end;  
procedure eng_settitle(a:string);begin SDL_WM_SetCaption(pansichar(a),nil);end;  
procedure eng_setsdlpal;begin SDL_SetPalette(sdlpScr,SDL_LOGPAL or SDL_PHYSPAL,@sdipal4[0],0,255);end;       
procedure eng_sditestscreenset(var fs:boolean);begin end;
//############################################################################//
procedure sdinit(fs:boolean);
//var i:integer;
begin
 ExitProc:=@SDL_Quit;
 eng_sditestscreenset(fs); 
 
 if SDL_Init(SDL_INIT_VIDEO)<0 then begin 
  {$ifndef mswindows}writeln(SDL_geterror);{$endif}
  halt(1);
 end;
 SDL_EnableUNICODE(1);
 SDL_EnableKeyRepeat(400,50);

 sdi_calc_scaling;
  
 if     fs then sdlpScr:=SDL_SetVideoMode(real_scrx,real_scry,scrbit,SDL_HWSURFACE or SDL_HWPALETTE or SDL_DOUBLEBUF or SDL_NOFRAME);
 if not fs then sdlpScr:=SDL_SetVideoMode(real_scrx,real_scry,scrbit,SDL_HWSURFACE or SDL_HWPALETTE or SDL_DOUBLEBUF or SDL_RESIZABLE);
 if sdlpScr=nil then begin {writeln('Error: Unable create surface: ',scrx,' ',scry,' ',scrbit);}halt(1);end;
 sdiscr_real:=sdlpScr^.pixels;
 scrbitbin:=ord(scrbit>=8)+ord(scrbit>=16)+ord(scrbit>=24)+ord(scrbit>=32);

 sdi_set_scaling;

 {$ifndef cpu64}SDL_FillRect(sdlpScr,nil,SDL_MapRGB(psdl_pixelformat(sdlpScr.format),1,1,1)); {$endif}
 SDL_SetColors(sdlpScr,@sdipal4[0],0,256); 
end;
//############################################################################//
const
VK_Controll=306;
VK_Controlr=305;
VK_menu=307;
VK_menul=308;
VK_SHIFTl=304;
VK_SHIFTr=303;
//############################################################################//
procedure docsh(out cshift:dword);
begin
 cshift:=0;
 if pks[VK_SHIFTl]   then setf(cshift,sh_shift);
 if pks[VK_SHIFTr]   then setf(cshift,sh_shift);
 if pks[VK_Controlr] then setf(cshift,sh_ctrl);
 if pks[VK_Controll] then setf(cshift,sh_ctrl);
 if pks[VK_menu]     then setf(cshift,sh_alt);
 if pks[VK_menul]    then setf(cshift,sh_alt);
 if mbtns[0]         then setf(cshift,sh_left);
 if mbtns[1]         then setf(cshift,sh_right);
 if mbtns[2]         then setf(cshift,sh_middle);
end;    
//############################################################################//
function xlate_key(var event:tSDL_Event):word;
begin
 if not sdi_full_keys then begin
  sdi_key_uni:=event.key.keysym.unicode+dword(ord(event.key.keysym.unicode=0))*event.key.keysym.sym; 
       if sdi_uni then result:=sdi_key_uni
  else if sdi_sc  then result:=event.key.keysym.scancode
                  else result:=event.key.keysym.sym;   
  exit;
 end;

 result:=event.key.keysym.unicode;
 if event.type_=SDL_KEYUP then begin
  if result=0 then result:=codes[event.key.keysym.scancode];
 end else begin
  if result=0 then result:=event.key.keysym.sym or $E000;
  if sdi_keys_lower then begin
   if pks[VK_SHIFTl] or pks[VK_SHIFTr] then if (event.key.keysym.sym<=255) and (char(event.key.keysym.sym) in ['a'..'z','0','1'..'9','-','=','`',',','.']) then result:=dword(lowercase(char(event.key.keysym.sym)));
   if pks[VK_Controlr] or pks[VK_Controll] then if (event.key.keysym.sym<=255) and (char(event.key.keysym.sym) in ['a'..'z','0','1'..'9','-','=','`',',','.']) then result:=event.key.keysym.sym;
  end else case result of
   key_tab:result:=ukey_tab;
  end;
  if event.type_=SDL_KEYDOWN then codes[event.key.keysym.scancode]:=result;
 end;
end;
//############################################################################//
procedure eng_sdi_handleinput;
var event:tSDL_Event;
cshift,key:dword;
begin
 while ( SDL_PollEvent( @event )>0 ) do begin
  case event.type_ of
   SDL_KEYDOWN:if sdifocus then begin   
    pks[event.key.keysym.sym]:=true; 
    docsh(cshift);
    key:=xlate_key(event);
    if assigned(sdi_event) then sdi_event(glgr_evkeydwn,0,0,key,cshift);
   end;
   SDL_KEYUP:if sdifocus then begin
    pks[event.key.keysym.sym]:=false;
    docsh(cshift);
    key:=xlate_key(event);
    if assigned(sdi_event) then sdi_event(glgr_evkeyup,0,0,key,cshift); 
   end;
   SDL_QUITEV:begin
    if assigned(sdi_event) then sdi_event(glgr_evclose,0,0,0,0);
    sdquit:=true;
   end;
   SDL_MOUSEMOTION:if sdifocus then begin
    docsh(cshift);   
    curx:=(10*event.motion.x) div direct_scale_10x;
    cury:=(10*event.motion.y) div direct_scale_10x;
    if assigned(sdi_event) then sdi_event(glgr_evmsmove,curx,cury,0,cshift);
    sdifocus:=true;
   end;
   SDL_MOUSEBUTTONUP:if sdifocus then begin 
    docsh(cshift);   
    case event.button.button of
     4:if assigned(sdi_event) then sdi_event(glgr_evmsdwn,curx,cury,0,cshift or sh_up);
     5:if assigned(sdi_event) then sdi_event(glgr_evmsdwn,curx,cury,0,cshift or sh_down);
    end;   
    if event.button.button<4 then if assigned(sdi_event) then sdi_event(glgr_evmsup,(10*event.motion.x) div direct_scale_10x,10*(event.motion.y) div direct_scale_10x,0,cshift);
    case event.button.button of
     1:mbtns[0]:=false;
     2:mbtns[2]:=false;
     3:mbtns[1]:=false;
    end;              
    docsh(cshift);
   end;
   SDL_MOUSEBUTTONDOWN:if sdifocus then begin
    case event.button.button of
     1:mbtns[0]:=true;
     2:mbtns[2]:=true;
     3:mbtns[1]:=true;
    end;     
    docsh(cshift);
    if event.button.button<4 then if assigned(sdi_event) then sdi_event(glgr_evmsdwn,(10*event.motion.x) div direct_scale_10x,10*(event.motion.y) div direct_scale_10x,0,cshift);
   end;
   SDL_VIDEORESIZE:begin
    scrx:=event.resize.w;
    scry:=event.resize.h;
    scrx:=scrx-scrx mod 4;
    if scrx=0 then scrx:=4;
    if scry=0 then scry:=4;

    sdi_calc_scaling;

    sdlpScr:=SDL_SetVideoMode(real_scrx,real_scry,scrbit,SDL_HWSURFACE or SDL_HWPALETTE or SDL_DOUBLEBUF or SDL_RESIZABLE);
    sdiscr_real:=sdlpScr^.pixels;
    if scrbit=8 then eng_setsdlpal;

    sdi_set_scaling;

    if assigned(sdi_event) then sdi_event(glgr_evresize,scrx,scry,0,0);
    sdifocus:=true;
   end;
   SDL_ACTIVEEVENT:begin
    if (event.active.gain=0)and(event.active.state=6) then eng_sdwinunfoc;
    if (event.active.gain=1)and(event.active.state=6) then eng_sdwinfoc;
    if (event.active.gain=0)and(event.active.state=2) then eng_sdwinunfoc;

    if (event.active.gain=1)and(event.active.state=1) then eng_sdwinmousein;
    if (event.active.gain=0)and(event.active.state=1) then eng_sdwinmouseout;
    //writeln('a:',event.active.gain,':',event.active.state);
   end;
  end;
 end;
 eng_sdiflip; //To update the screen for async event handling calls
end;
//############################################################################//
procedure eng_sdiloop;
var lds,eft:int64;
ct,dt:double;
xdt:integer;
fpttk,tcpv,mdt,fptk:int64;
begin
 xdt:=getdt;
 stdt(xdt);
 lds:=rtdt(xdt); 
 fptk:=0;fpttk:=0;tcpv:=0;
 while not(sdquit or halting) do begin
  while (rtdt(xdt)-tcpv)<(1000000 div max_fps) do sleep(1);
  mdt:=rtdt(xdt)-tcpv;
  tcpv:=rtdt(xdt);
  
  if (rtdt(xdt)-fptk)>=1000000 then begin
   fps:=fpsc;
   fpsc:=0;
   fptk:=rtdt(xdt);
  end;   
  if (rtdt(xdt)-fpttk)>=100000 then begin  
   if fpsdbg then begin
    eng_settitle(sdbasetitle+' ['+stri(fps)+' fps, '+stri(round(mdt/1000))+'ms]');
   end;// else eng_settitle(sdbasetitle);
   fpttk:=rtdt(xdt);
  end;  

  eng_sdi_handleinput;
  if halting or sdquit then exit;

  eft:=rtdt(xdt)-lds;
  ct:=eft/1000000;
  dt:=mdt/1000000;
  if dt<0.001 then dt:=0.001;
  if sdifocus then sdi_mainloop(ct,dt);
 end;
end;
//############################################################################//
procedure eng_setsdi(x,y,b:integer;f:boolean;cap:string;tim,evt:pointer);
begin         
 sdquit:=false;    

 sdiscr_alloc:=nil;
 sdlpScr:=nil;    
 sdinit(fullscreen); 
 eng_settitle(sdbasetitle);
       
 if(SDL_MUSTLOCK(sdlpScr))then if(SDL_LockSurface(sdlpScr)<0)then Exit;   
 {$ifndef cpu64}SDL_FillRect(sdlpScr,nil,SDL_MapRGB(psdl_pixelformat(sdlpScr.format),0,0,0));{$endif}
 if (SDL_MUSTLOCK(sdlpScr)) then SDL_UnlockSurface(sdlpScr);
 SDL_Flip(sdlpScr);
 //getmem(p,100);SDL_VideoDriverName(p,100);writeln('Video Driver: ',p);freemem(p);
end;
//############################################################################//
procedure eng_sdiset_win_pos(x,y:integer);
begin
 if fullscreen then exit;
end;
//############################################################################//
procedure eng_sdisdlquit;begin SDL_Quit;sdquit:=true;end;
//############################################################################//
procedure eng_sdiflip;
begin
 if sdquit then exit;
 sdi_pre_flip;
 SDL_Flip(sdlpScr);
 sdi_post_flip(sdlpScr^.pixels);
end;
//############################################################################//
function eng_sdilock:boolean;
begin
 result:=true;
 if(SDL_MUSTLOCK(sdlpScr))then if(SDL_LockSurface(sdlpScr)<0)then result:=false;
end; 
//############################################################################//
function eng_sdicursor(n:integer):integer;
begin
 result:=SDL_ShowCursor(n);
end;
//############################################################################//
procedure eng_sdiunlock;
begin
 if(SDL_MUSTLOCK(sdlpScr))then SDL_UnlockSurface(sdlpScr);
end;
//############################################################################//
procedure eng_sdi_touch_params;
begin
 scrx:=real_scrx;
 scry:=real_scry;
 sdi_calc_scaling;
 sdi_set_scaling;
end;
//############################################################################//
begin
end.
//############################################################################//
