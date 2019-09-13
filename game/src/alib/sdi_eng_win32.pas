//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit sdi_eng_win32;
interface
uses asys,strval,grph,tim,sdi_scale,sdi_rec,windows,messages,shellapi;
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

procedure wnd_icon_create(s:string);
procedure wnd_icon_remove;
procedure wnd_hide;
//############################################################################//
implementation
//############################################################################//
type
sdi_win=record
 fs:boolean;
 xs,ys:integer;
 name:string;

 skip_paint:boolean;
 
 hins:HINST;
 wnd:HWND;
 screen_bmp:HBITMAP;
 cur_curs:HCURSOR;
 curs_state:integer;

 srf:pointer;
 
 ct,dt:double;
 fpsc,cfps:integer;

 pks:array[0..65535]of boolean;
 mbtns:array[0..4]of boolean;
end;
psdi_win=^sdi_win;
//############################################################################//
var
sdquit:boolean;
win:sdi_win;
wir:array of hwnd=nil;
wer:array of pointer=nil;
curs:HCURSOR;
x_frame:integer=6;
y_frame:integer=25;
//############################################################################//
function timeBeginPeriod(x1:dword):dword;stdcall; external 'winmm.dll' name 'timeBeginPeriod';
//############################################################################//
procedure eng_sdwinunfoc;
begin 
 if sdifocusoff then begin
  sdifocus:=false;
  eng_sdiflip;
 end;
end;
//############################################################################//
procedure eng_sdwinfoc;
begin 
 if sdifocusoff then begin
  sdiev:=true;
  sdifocus:=true;
 end;
end;
//############################################################################//
procedure eng_sdwinmousein;begin end;
procedure eng_sdwinmouseout;begin end; 
//############################################################################//
procedure eng_settitle(a:string);
begin
 SetWindowText(win.wnd,pchar(a));
end;
//############################################################################//
procedure eng_setsdlpal;
var dc,mdc:hdc;
pal:array of RGBQUAD;
i:integer;
begin
 if scrbit<>8 then exit;
 setlength(pal,256);
 for i:=0 to 255 do begin
  pal[i].rgbRed:=sdipal4[i][0];
  pal[i].rgbGreen:=sdipal4[i][1];
  pal[i].rgbBlue:=sdipal4[i][2];
  pal[i].rgbReserved:=0;
 end;
 
 dc:=GetDC(win.wnd);
 mdc:=CreateCompatibleDC(dc);
 SelectObject(mdc,win.screen_bmp);
 SetDIBColorTable(mdc,0,256,pal[0]);
 DeleteDC(mdc);
 releasedc(win.wnd,dc);
end;
//############################################################################//
procedure eng_sditestscreenset(var fs:boolean);
var xs,ys:integer;
rect:trect;
begin
 if not fs then begin
  if sdi_check_res then begin
   if SystemParametersInfo(SPI_GETWORKAREA,0,@rect,0) then begin
    xs:=rect.right-rect.left-6-6;
    ys:=rect.bottom-rect.top-25-6;
    xs:=xs-xs mod 4;
    ys:=ys-ys mod 4;
    if scrx>xs then scrx:=xs;
    if scry>ys then scry:=ys;
   end;
  end;
 end else begin
  xs:=GetSystemMetrics(SM_CXSCREEN);
  ys:=GetSystemMetrics(SM_CYSCREEN);
  scrx:=xs;
  scry:=ys;
 end;
end;
//############################################################################//
procedure create_bitmap(w:psdi_win);
var binfo:pBITMAPINFO;
sz:integer;
dc:hdc;
begin
 if w.screen_bmp<>0 then DeleteObject(w.screen_bmp);

 dc:=GetDC(w.wnd);

 sz:=sizeof(BITMAPINFO);
 //if( is16bitmode ) {
   //16bit modes, palette area used for rgb bitmasks
 //  binfo_size += 3*sizeof(DWORD);
 //else if ( video->format->palette ) {
 if scrbit=8 then sz:=sz+256*4;
 getmem(binfo,sz);

 binfo.bmiHeader.biSize:=sizeof(BITMAPINFOHEADER);
 binfo.bmiHeader.biWidth:=w.xs;
 binfo.bmiHeader.biHeight:=-w.ys;
 binfo.bmiHeader.biPlanes:=1;
 binfo.bmiHeader.biSizeImage:=w.ys*w.xs*scrbit div 4;
 binfo.bmiHeader.biXPelsPerMeter:=0;
 binfo.bmiHeader.biYPelsPerMeter:=0;
 binfo.bmiHeader.biClrUsed:=0;
 binfo.bmiHeader.biClrImportant:=0;
 binfo.bmiHeader.biBitCount:=scrbit;
 binfo.bmiHeader.biCompression:=BI_RGB;

 if scrbit=8 then fillchar(binfo.bmiColors,256*4,0);
 
 //getmem(w.srf,w.xs*w.ys*bc div 4);
 win.srf:=nil;
 w.screen_bmp:=CreateDIBSection(dc,binfo^,DIB_RGB_COLORS,w.srf,0,0);

 releasedc(w.wnd,dc);
 freemem(binfo);
end;
//############################################################################//
procedure wnd_show(w:psdi_win);
begin
 showwindow(w.wnd,SW_SHOW);
 setforegroundwindow(w.wnd);
 setfocus(w.wnd);
end;
//############################################################################//
procedure wnd_resize(w:psdi_win);   
var bounds:trect;
begin
 bounds.left:=0;
 bounds.top:=0;
 bounds.right:=w.xs;
 bounds.bottom:=w.ys;
 AdjustWindowRectEx(bounds,GetWindowLong(w.wnd,GWL_STYLE), (GetMenu(w.wnd)<>0), 0); 
 x_frame:=bounds.right-bounds.left-scrx;
 y_frame:=bounds.bottom-bounds.top-scry;
 SetWindowPos(w.wnd,HWND_NOTOPMOST,0,0,bounds.right-bounds.left,bounds.bottom-bounds.top,SWP_NOCOPYBITS or SWP_NOMOVE);
end;
//############################################################################//
procedure wnd_redraw(w:psdi_win;paint:boolean);     
var dc,mdc:hdc;
ps:PAINTSTRUCT;
begin
 if paint then dc:=beginpaint(w.wnd,ps) else dc:=GetDC(w.wnd);
 mdc:=CreateCompatibleDC(dc);
 SelectObject(mdc,w.screen_bmp);
 BitBlt(dc,0,0,w.xs,w.ys,mdc,0,0,SRCCOPY);
 DeleteDC(mdc);
 if paint then EndPaint(w.wnd,ps) else releasedc(w.wnd,dc);
end;
//############################################################################//
procedure wnd_handleinput(paint:boolean);
var lmsg:tmsg;
begin
 win.skip_paint:=not paint;
 while PeekMessage(lmsg,0,0,0,PM_REMOVE) do begin
  if (lmsg.message=WM_QUIT) then halting:=true else begin  
   TranslateMessage(lmsg);
   DispatchMessage(lmsg);
  end;
 end;
end;
//############################################################################//
procedure numpadxlate(var w:WPARAM);
begin
 case w of
  VK_NUMPAD8:w:=VK_UP;
  VK_NUMPAD2:w:=VK_DOWN;
  VK_NUMPAD4:w:=VK_LEFT;
  VK_NUMPAD6:w:=VK_RIGHT;
  
  VK_NUMPAD0:w:=VK_INSERT;
  VK_NUMPAD1:w:=VK_END;
  VK_NUMPAD3:w:=VK_NEXT;
  VK_NUMPAD5:w:=VK_CLEAR;
  VK_NUMPAD7:w:=VK_HOME;   
  VK_NUMPAD9:w:=VK_PRIOR;
  VK_DECIMAL:w:=VK_DELETE;
 end;
end; 
//############################################################################//
function wnd_old_xlate_key(w:psdi_win;wpar:WPARAM;lpar:LPARAM):word;
var vkey:integer;
sc:word;
state:tkeyboardstate;
begin
 numpadxlate(wpar);
 
 vkey:=wpar;
 sc:=lpar shr 16;
 result:=vkey;
 if (vkey=key_enter)and((sc and $100)<>0)then result:=key_NUM_ENTER;
 if sdi_sc then result:=sc;

 sdi_key_uni:=0;
 getkeyboardstate(state);
 {$ifndef FPC}
 ToUnicode(wpar,sc shl 8,state,sdi_key_uni,2,0);
 {$else}
 ToUnicode(wpar,sc shl 8,state,@sdi_key_uni,2,0);
 {$endif}
 //if sdi_key_uni=0 then sdi_key_uni:=vkey;

 if sdi_uni then result:=sdi_key_uni;
end;
//############################################################################//
function wnd_xlate_key(w:psdi_win;wpar:WPARAM;lpar:LPARAM):word;
var r:integer;
sc:word;
state:tkeyboardstate;
begin
 if not sdi_full_keys then begin
  result:=wnd_old_xlate_key(w,wpar,lpar);
  exit;
 end;

 sc:=lpar shr 16;
 
 result:=0;
 getkeyboardstate(state);
 {$ifndef FPC}
 r:=ToUnicode(wpar,sc shl 8,state,result,2,0);
 {$else}
 r:=ToUnicode(wpar,sc shl 8,state,@result,2,0);
 {$endif}
 if (result=0)or(r<>1) then result:=sc or $E000;
 if result=9 then result:=$E009;  //Tab
end;
//############################################################################//     
procedure docsh_old(w:psdi_win;var cshift:dword);
begin
 if (w.pks[VK_SHIFT] and not sdi_sc)or((w.pks[42] or w.pks[54]) and sdi_sc) then begin
  setf(cshift,sh_shift);
  if w.pks[256] then setf(cshift,sh_lshift);
  if w.pks[257] then setf(cshift,sh_rshift);
 end;
 if (w.pks[VK_Control] and not sdi_sc)or((w.pks[29] or w.pks[285]) and sdi_sc)  then setf(cshift,sh_ctrl);
 if (w.pks[VK_menu]    and not sdi_sc)or((w.pks[56] or w.pks[312]) and sdi_sc)  then setf(cshift,sh_alt);
end;
//############################################################################//
procedure docsh(w:psdi_win;var cshift:dword);
begin
 cshift:=0;
 if w.mbtns[0] then setf(cshift,sh_left);
 if w.mbtns[1] then setf(cshift,sh_right);
 if w.mbtns[2] then setf(cshift,sh_middle);
 if w.mbtns[3] then setf(cshift,sh_up);
 if w.mbtns[4] then setf(cshift,sh_down);
 
 if not sdi_full_keys then begin
  docsh_old(w,cshift);
  exit;
 end;
 
 if w.pks[ukey_r_shift] or w.pks[ukey_l_shift] then begin
  setf(cshift,sh_shift);
  if w.pks[ukey_l_shift] then setf(cshift,sh_lshift);
  if w.pks[ukey_r_shift] then setf(cshift,sh_rshift);
 end;
 if w.pks[ukey_l_ctrl] or w.pks[ukey_r_ctrl] then setf(cshift,sh_ctrl);
 if w.pks[ukey_l_alt]  or w.pks[ukey_r_alt]  then setf(cshift,sh_alt);
end;
//############################################################################//
function wndproc(hwnd:HWND;msg:UINT;wpar:WPARAM;lpar:LPARAM):LRESULT; stdcall;
var cshift:dword;
w:psdi_win;
s:pCREATESTRUCT;
i:integer;
begin
 result:=0;
 w:=nil;
 
 if msg<>WM_CREATE then begin
  for i:=0 to length(wir)-1 do if wir[i]=hwnd then begin
   w:=wer[i];
   break;
  end;
  if w=nil then begin
   result:=DefWindowProc(hWnd,Msg,wPar,lPar);
   exit;
  end;
 end;

 case msg of
  WM_CREATE:begin
   s:=pointer(lpar);
   i:=length(wir);
   setlength(wir,i+1);
   setlength(wer,i+1);
   wir[i]:=hwnd;
   wer[i]:=s.lpCreateParams;
  end;
  WM_CLOSE:begin
   if assigned(sdi_event) then sdi_event(glgr_evclose,0,0,0,0); 
   sdquit:=true;
   PostQuitMessage(0);
  end;
  WM_KEYDOWN:begin
   wpar:=wnd_xlate_key(w,wpar,lpar);
   w.pks[wpar]:=true;
   if lpar and $FFFFFF=$2A0001 then w.pks[256]:=true;
   if lpar and $FFFFFF=$360001 then w.pks[257]:=true;   
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evkeydwn,0,0,wpar,cshift);     
  end;
  WM_KEYUP:begin
   wpar:=wnd_xlate_key(w,wpar,lpar);
   if sdi_sc then wpar:=wpar-$C000;
   w.pks[wpar]:=false;
   if lpar and $FFFFFF=$2A0001 then w.pks[256]:=false;
   if lpar and $FFFFFF=$360001 then w.pks[257]:=false;  
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evkeyup,0,0,wpar,cshift);   
  end;
  WM_SYSKEYDOWN:begin
   wpar:=wnd_xlate_key(w,wpar,lpar);
   if sdi_sc then wpar:=wpar-$2000;
   w.pks[wpar]:=true;
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evkeydwn,0,0,wpar,cshift); 
  end;
  WM_SYSKEYUP:begin
   wpar:=wnd_xlate_key(w,wpar,lpar);
   if sdi_sc then wpar:=wpar-$C000;
   w.pks[wpar]:=false;
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evkeyup,0,0,wpar,cshift);   
  end;
  WM_MOUSEMOVE:begin
   docsh(w,cshift);
   curx:=10*(lpar mod 65536) div direct_scale_10x;
   cury:=10*(lpar div 65536) div direct_scale_10x;
   if assigned(sdi_event) then sdi_event(glgr_evmsmove,curx,cury,0,cshift);
  end;
  WM_LBUTTONDOWN:begin
   w.mbtns[0]:=true;
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evmsdwn,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
  end;
  WM_LBUTTONUP:begin
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evmsup,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
   w.mbtns[0]:=false;
   docsh(w,cshift);
  end;
  WM_RBUTTONDOWN:begin
   w.mbtns[1]:=true;
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evmsdwn,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
  end;
  WM_RBUTTONUP:begin 
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evmsup,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
   w.mbtns[1]:=false;
   docsh(w,cshift);
  end;
  WM_MBUTTONDOWN:begin
   w.mbtns[2]:=true;
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evmsdwn,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
  end;
  WM_MBUTTONUP:begin 
   docsh(w,cshift);
   if assigned(sdi_event) then sdi_event(glgr_evmsup,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
   w.mbtns[2]:=false;   
   docsh(w,cshift);
  end;
  WM_MOUSEWHEEL:begin
   if abs(wpar)<>0 then begin
    i:=wpar shr 16;
    i:=i*round(wpar/abs(wpar));
    w.mbtns[3]:=false;
    w.mbtns[4]:=false;
    if i>0 then w.mbtns[3]:=true;
    if i<0 then w.mbtns[4]:=true;
    docsh(w,cshift);
    if assigned(sdi_event) then sdi_event(glgr_evmsdwn,10*(lpar mod 65536) div direct_scale_10x,10*(lpar div 65536) div direct_scale_10x,0,cshift);
    w.mbtns[3]:=false;
    w.mbtns[4]:=false;
   end;
  end;
  WM_PAINT:begin
   if not w.skip_paint then if assigned(sdi_mainloop) then sdi_mainloop(win.ct,win.dt); 
   w.skip_paint:=false;
   wnd_redraw(w,true);
  end;
  WM_SIZE:begin
   if ((lpar and $FFFF)<>scrx)or(((lpar shr 16) and $FFFF)<>scry) then begin
    scrx:=lpar and $FFFF;
    scry:=(lpar shr 16) and $FFFF;
    scrx:=scrx-scrx mod 4;

    if scrx=0 then scrx:=4;
    if scry=0 then scry:=4;

    sdi_calc_scaling;

    w.xs:=real_scrx;
    w.ys:=real_scry;
    create_bitmap(w);
    sdiscr_real:=win.srf;

    sdi_set_scaling;

    sdi_event(glgr_evresize,scrx,scry,0,0);
    sdifocus:=true;
   end;
  end;
  WM_SETCURSOR:begin
   if (lpar and $FF)=HTCLIENT then begin
    SetCursor(w.cur_curs);
    result:=1;
   end else result:=DefWindowProc(hWnd,Msg,wpar,lpar);
  end;
  WM_USER+1:if (lpar and $FF)=1 then ShowWindow(w.wnd,SW_SHOWNORMAL);
  else begin
   result:=DefWindowProc(hWnd,Msg,wpar,lpar);
  end;
 end;
end;
//############################################################################//
procedure wnd_kill(w:psdi_win);
begin
 if w.fs then begin
  ChangeDisplaySettings(devmode(nil^),0);
  ShowCursor(true);
 end;

 if (w.wnd<>0)and(not destroywindow(w.wnd)) then begin
  MessageBox(0,'Unable to destroy window!','Error',MB_OK or MB_ICONERROR);
  w.wnd:=0;
 end;
 if not unregisterclass('sdi',0) then begin
  //MessageBox(0,'Unable to unregister window class!','Error',MB_OK or MB_ICONERROR);
 end;
end;
//############################################################################//
procedure wnd_create(fs:boolean;xs,ys,bc:integer;name:string);
var wdcl:TWndClass;
dws,dwes:DWORD;
w:psdi_win;
dc:hdc;
begin
 sdquit:=false;
 w:=@win;

 if(bc<>8)and(bc<>16)and(bc<>32)then halt;

 fillchar(win,sizeof(win),0);

 w.fs:=fs;
 w.xs:=xs;
 w.ys:=ys;
 w.screen_bmp:=0;
 w.name:=name;
 w.hins:=getmodulehandle(nil);
 
 zeromemory(@wdcl,sizeof(wdcl));
 with wdcl do begin
  style        :=CS_HREDRAW or CS_VREDRAW or CS_OWNDC;
  lpfnWndProc  :=@wndproc;
  hInstance    :=w.hins;
  hCursor      :=0;
  lpszClassName:='sdi';
 end;
 if RegisterClass(wdcl)=0 then exit; 
 
 if fs then begin
  dws:=WS_POPUP        or        // Creates a popup window
       WS_CLIPCHILDREN or        // Doesn't draw within child windows
       WS_CLIPSIBLINGS;          // Doesn't draw within sibling windows
  dwes:=WS_EX_APPWINDOW;         // Top level window
  showcursor(false);
 end else begin
  dws:=WS_OVERLAPPEDWINDOW or
       WS_CLIPCHILDREN or        // Doesn't draw within child windows
       WS_CLIPSIBLINGS;          // Doesn't draw within sibling windows
  dwes:=WS_EX_APPWINDOW or       // Top level window
        WS_EX_WINDOWEDGE;        // Border with a raised edge
 end;
        
 w.wnd:=createwindowex(dwes,       // Extended window styles
                       'sdi',   // Class name
                       pchar(w.name),// Window title (caption)
                       dws,        // Window styles
                       0, 0,       // Window position
                       w.xs,w.ys,    // Size of window
                       0,          // No parent window
                       0,          // No menu
                       w.hins,       // Instance
                       w);       // Pass gwin to WM_CREATE

 
 if w.wnd=0 then begin
  wnd_kill(w);
  MessageBox(0,'Unable to create window!','Error',MB_OK or MB_ICONERROR);
  //result:=false;
  exit;
 end;

 if not fs then wnd_resize(w);
   
 dc:=getdc(w.wnd);
 if dc=0 then begin
  wnd_kill(w);
  MessageBox(0,'Unable to get a device context!','Error',MB_OK or MB_ICONERROR);
  //result:=false;
  exit;
 end;
 releasedc(w.wnd,dc);
 
 create_bitmap(w);
end;
//############################################################################//
procedure wnd_icon_create(s:string);
var tnd:tNOTIFYICONDATA;
i:integer;
begin
 tnd.cbSize:=sizeof(tnd);
 {$ifdef fpc}tnd.hwnd:=win.wnd;{$else}tnd.wnd:=win.wnd;{$endif}
 tnd.uID:=128;//IDR_MAINFRAME;
 tnd.uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
 tnd.uCallbackMessage:=WM_USER+1;
 //tnd.hIcon:=LoadIcon(AfxGetInstanceHandle(),MAKEINTRESOURCE(IDR_MAINFRAME));
 tnd.hIcon:=LoadIcon(0,IDI_ASTERISK);
 if length(s)>=63 then setlength(s,63);
 for i:=0 to length(s)-1 do tnd.szTip[i]:=s[1+i];
 tnd.szTip[length(s)]:=#0;

 Shell_NotifyIcona(NIM_ADD,@tnd);
end;
//############################################################################//
procedure wnd_icon_remove;
var tnd:tNOTIFYICONDATA;
begin
 tnd.cbSize:=sizeof(tnd);
 {$ifdef fpc}tnd.hwnd:=win.wnd;{$else}tnd.wnd:=win.wnd;{$endif}
 tnd.uID:=128;//IDR_MAINFRAME;
 Shell_NotifyIcona(NIM_DELETE,@tnd);
end;
//############################################################################//
procedure wnd_hide;
begin
 ShowWindow(win.wnd,SW_HIDE);
end;
//############################################################################//
procedure sdinit(fs:boolean);
begin
 eng_sditestscreenset(fs); 
 wnd_create(fs,scrx,scry,scrbit,'SDI');

 timeBeginPeriod(1);
 //SDL_EnableUNICODE(1);
                       
 scrbitbin:=ord(scrbit>=8)+ord(scrbit>=16)+ord(scrbit>=24)+ord(scrbit>=32);
 sdiscr_real:=win.srf;

 sdi_calc_scaling;
 sdi_set_scaling;
end;   
//############################################################################//
procedure eng_sdi_handleinput;
begin
 wnd_handleinput(false);
 eng_sdiflip;
end;
//############################################################################//
procedure eng_sdiloop;
var tim_dt:integer;
start_time,cur_time,delta,fps_time:int64;
begin try
 tim_dt:=getdt;
 stdt(tim_dt);
 start_time:=rtdt(tim_dt);
 cur_time:=start_time;
 fps_time:=start_time;
 while not(sdquit or halting) do begin
  while (rtdt(tim_dt)-cur_time)<(1000000 div max_fps) do sleep(1);
  delta:=rtdt(tim_dt)-cur_time;
  cur_time:=rtdt(tim_dt);
  win.ct:=(cur_time-start_time)/1000000;
  win.dt:=delta/1000000;
  if win.dt<0.001 then win.dt:=0.001;
  
  //FPS
  if (cur_time-fps_time)>=1000000 then begin
   fps:=fpsc;
   fpsc:=0;
   fps_time:=cur_time;
   if fpsdbg then eng_settitle(sdbasetitle+' FPS='+stri(fps)+' MDT='+stre(win.dt))
  end;

  //Input
  wnd_handleinput(true);
  if halting then break;
  //Draw
  if sdifocus then if assigned(sdi_mainloop) then sdi_mainloop(win.ct,win.dt);  
 end;
 freedt(tim_dt);

 //freemem(win.srf);
 
 except halt;end;
end;
//############################################################################//
procedure eng_setsdi(x,y,b:integer;f:boolean;cap:string;tim,evt:pointer);
var xs,ys:integer;
rect:trect;
begin   
 sdiscr_alloc:=nil;
 sdinit(fullscreen);
 eng_settitle(sdbasetitle);

 curs:=LoadCursor(0,IDC_ARROW);
 win.cur_curs:=curs;
 SetCursor(win.cur_curs);
 win.curs_state:=1;
 
 xs:=0;
 ys:=0;
 
 if SystemParametersInfo(SPI_GETWORKAREA,0,@rect,0)then begin
  xs:=(rect.right-rect.left) div 2-scrx div 2-x_frame div 2;
  ys:=(rect.bottom-rect.top) div 2-scry div 2;
 end;
 if not f then begin
  if sdi_centre_top then SetWindowPos(win.wnd,HWND_TOP,xs,0,scrx,scry,SWP_NOSIZE);   
  if sdi_centre_mid then SetWindowPos(win.wnd,HWND_TOP,xs,ys,scrx,scry,SWP_NOSIZE);   
 end; 
 
 wnd_show(@win);
end;
//############################################################################//
procedure eng_sdiset_win_pos(x,y:integer);
begin
 if fullscreen then exit;
 SetWindowPos(win.wnd,HWND_TOP,x,y,scrx,scry,SWP_NOSIZE);   
end;
//############################################################################//
procedure eng_sdisdlquit;
begin
 wnd_kill(@win);
end;
//############################################################################//
procedure eng_sdiflip;
begin
 sdi_pre_flip;
 wnd_redraw(@win,false); 
 sdi_post_flip(win.srf);
end;
//############################################################################//
function eng_sdilock:boolean;begin result:=true;end; 
//############################################################################//
function eng_sdicursor(n:integer):integer;
begin
 result:=win.curs_state;
 if(win.curs_state<>n)and(n<>-1)then begin
  if n=0 then win.cur_curs:=0 else win.cur_curs:=curs;
  SetCursor(win.cur_curs);
  win.curs_state:=n;
 end;
end;
//############################################################################//
procedure eng_sdiunlock;begin end;
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
