//############################################################################//
unit sdl;
{$weakpackageunit on}
{$align on}
{$ifdef fpc}{$packrecords 4}{$endif}
interface
//############################################################################//
const
{$ifdef win32}lib_name='SDL.dll';{$endif}
{$ifdef win64}lib_name='SDL64.dll';{$endif}
{$ifdef wince}lib_name='SDLCE.dll';{$endif}
{$ifdef linux}lib_name='libSDL.so';{$endif}
{$ifdef macos}lib_name='libSDL.dylib';{$endif}
//############################################################################//
const
SDL_INIT_VIDEO=$00000020;
  
//SDL_events.h constants
SDL_NOEVENT=0;  //Unused (do not remove)
SDL_ACTIVEEVENT=1;  //Application loses/gains visibility
SDL_KEYDOWN=2;  //Keys pressed
SDL_KEYUP=3;  //Keys released
SDL_MOUSEMOTION=4;  //Mouse moved
SDL_MOUSEBUTTONDOWN=5;  //Mouse button pressed
SDL_MOUSEBUTTONUP=6;  //Mouse button released
SDL_QUITEV=12;  //User-requested quit ( Changed due to procedure conflict )
SDL_SYSWMEVENT=13;  //System specific event
SDL_EVENT_RESERVEDA=14;  //Reserved for future use..
SDL_EVENT_RESERVED=15;  //Reserved for future use..
SDL_VIDEORESIZE=16;  //User resized video mode
SDL_VIDEOEXPOSE=17;  //Screen needs to be redrawn

//These are the currently supported flags for the SDL_surface
//Available for SDL_CreateRGBSurface() or SDL_SetVideoMode()
SDL_SWSURFACE=$00000000;  //Surface is in system memory
SDL_HWSURFACE=$00000001;  //Surface is in video memory
SDL_ASYNCBLIT=$00000004;  //Use asynchronous blits if possible

//Available for SDL_SetVideoMode()
SDL_ANYFORMAT=$10000000;  //Allow any video depth/pixel-format
SDL_HWPALETTE=$20000000;  //Surface has exclusive palette
SDL_DOUBLEBUF=$40000000;  //Set up double-buffered video mode
SDL_FULLSCREEN=$80000000;  //Surface is a full screen display
SDL_RESIZABLE=$00000010;  //This video mode may be resized
SDL_NOFRAME=$00000020;  //No window caption or edge frame

//Used internally (read-only)
SDL_HWACCEL=$00000100;  //Blit uses hardware acceleration
SDL_SRCCOLORKEY=$00001000;  //Blit uses a source color key
SDL_RLEACCELOK=$00002000;  //Private flag
SDL_RLEACCEL=$00004000;  //Colorkey blit is RLE accelerated
SDL_SRCALPHA=$00010000;  //Blit uses source alpha blending
SDL_SRCCLIPPING=$00100000;  //Blit uses source clipping
SDL_PREALLOC=$01000000;  //Surface uses preallocated memory

//flags for SDL_SetPalette()
SDL_LOGPAL=$01;
SDL_PHYSPAL=$02;
//############################################################################//
type
{$ifndef fpc}dword=cardinal;{$endif}
TSDL_errorcode=(SDL_ENOMEM,SDL_EFREAD,SDL_EFWRITE,SDL_EFSEEK,SDL_LASTERROR);

TSDLKey=LongWord;
TSDLMod=LongWord;
  
PSDL_KeySym=^TSDL_KeySym;
TSDL_KeySym=record
 scancode:byte;  //hardware specific scancode
 sym:TSDLKey;  //SDL virtual keysym
 modifier:TSDLMod;  //current key modifiers
 unicode:word;  //translated character
end;

//Application visibility event structure
TSDL_ActiveEvent=record
 type_:byte;  //SDL_ACTIVEEVENT
 gain:byte;  //Whether given states were gained or lost (1/0)
 state:byte;  //A mask of the focus states
end;

//Keyboard event structure
TSDL_KeyboardEvent=record
 type_:byte;  //SDL_KEYDOWN or SDL_KEYUP
 which:byte;  //The keyboard device index
 state:byte;  //SDL_PRESSED or SDL_RELEASED
 keysym:TSDL_KeySym;
end;

//Mouse motion event structure
TSDL_MouseMotionEvent=record
 type_:byte;  //SDL_MOUSEMOTION
 which:byte;  //The mouse device index
 state:byte;  //The current button state
 x, y:word;  //The X/Y coordinates of the mouse
 xrel:smallint;  //The relative motion in the X direction
 yrel:smallint;  //The relative motion in the Y direction
end;

//Mouse button event structure
TSDL_MouseButtonEvent=record
 type_:byte; //SDL_MOUSEBUTTONDOWN or SDL_MOUSEBUTTONUP
 which:byte; //The mouse device index
 button:byte;  //The mouse button index
 state:byte; //SDL_PRESSED or SDL_RELEASED
 x:word;     //The X coordinates of the mouse at press time
 y:word;     //The Y coordinates of the mouse at press time
end;

//The "window resized" event
//When you get this event, you are responsible for setting a new video mode with the new width and height.
TSDL_ResizeEvent=record
 type_:byte;  //SDL_VIDEORESIZE
 w:integer;  //New width
 h:integer;  //New height
end;

//The "quit requested" event
PSDL_QuitEvent=^TSDL_QuitEvent;
TSDL_QuitEvent=record
 type_:byte;
end;

PSDL_Event=^TSDL_Event;
TSDL_Event=record
 case byte of
  SDL_NOEVENT:(type_:byte);
  SDL_ACTIVEEVENT:(active:TSDL_ActiveEvent);
  SDL_KEYDOWN,SDL_KEYUP:(key:TSDL_KeyboardEvent);
  SDL_MOUSEMOTION:(motion:TSDL_MouseMotionEvent);
  SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:(button:TSDL_MouseButtonEvent );
  SDL_VIDEORESIZE:(resize:TSDL_ResizeEvent );
  SDL_QUITEV:(quit:TSDL_QuitEvent );
  20:(quit1:array[0..127]of byte );  //More events in newer lib, destroying the stack for lack of space in the record
end;

PSDL_Rect=^TSDL_Rect;
TSDL_Rect=record
 x, y:smallint;
 w, h:word;
end;

PSDL_Color=^TSDL_Color;
TSDL_Color=record
 r:byte;
 g:byte;
 b:byte;
 unused:byte;
end;

PSDL_ColorArray=^TSDL_ColorArray;
TSDL_ColorArray=array[0..65000] of TSDL_Color;

PSDL_Palette=^TSDL_Palette;
TSDL_Palette=record
 ncolors:integer;
 colors:PSDL_ColorArray;
end;

//Everything in the pixel format structure is read-only
PSDL_PixelFormat=^TSDL_PixelFormat;
TSDL_PixelFormat=record
 palette:PSDL_Palette;
 BitsPerPixel:byte;
 BytesPerPixel:byte;
 Rloss:byte;
 Gloss:byte;
 Bloss:byte;
 Aloss:byte;
 Rshift:byte;
 Gshift:byte;
 Bshift:byte;
 Ashift:byte;
 RMask:dword;
 GMask:dword;
 BMask:dword;
 AMask:dword;
 colorkey:dword;  //RGB color key information
 alpha:byte;  //Alpha value information (per-surface alpha)
end;

//typedef for private surface blitting functions
PSDL_Surface=^TSDL_Surface;
{   
 00 00 00 00 
 98 7F 00 00 C0 B9 A8 00 
  00 00 00 00 
 20 03 00 00 
 58 02 00 00 
 80 0C 
 00 00 00 00 00 00 
 00 70 BD 6E B7 7F 00 00
 }
{$ifdef cpu64}
TSDL_Surface=packed record
 flags:dword;  //Read-only
 format:PSDL_PixelFormat;  //Read-only
 padding1:dword;
 w,h:dword;  //Read-only
 pitch:word;  //Read-only
 padding3:word;
 padding2:dword;
 pixels:pointer;  //Read-write
 offset:integer;  //Private
 hwdata:pointer;  //TPrivate_hwdata; Hardware-specific surface info

 //clipping information:
 clip_rect:TSDL_Rect;  //Read-only
 unused1:dword;  //for binary compatibility
 //Allow recursive locks
 locked:dword;  //Private
 //info for fast blit mapping to other surfaces
 Blitmap:pointer;  //PSDL_BlitMap;  //  Private
 //format version, bumped at every change to invalidate blit maps
 format_version:Cardinal;  //Private
 refcount:integer;
end;
{$else}
TSDL_Surface=record
 flags:dword;  //Read-only
 format:PSDL_PixelFormat;  //Read-only
 w,h:integer;  //Read-only
 pitch:word;  //Read-only
 pixels:pointer;  //Read-write
 offset:integer;  //Private
 hwdata:pointer;  //TPrivate_hwdata; Hardware-specific surface info

 //clipping information:
 clip_rect:TSDL_Rect;  //Read-only
 unused1:dword;  //for binary compatibility
 //Allow recursive locks
 locked:dword;  //Private
 //info for fast blit mapping to other surfaces
 Blitmap:pointer;  //PSDL_BlitMap;  //  Private
 //format version, bumped at every change to invalidate blit maps
 format_version:Cardinal;  //Private
 refcount:integer;
end;
{$endif}
//############################################################################//
function SDL_Init(flags:dword):integer;cdecl;external lib_name;
procedure SDL_Quit;cdecl;external lib_name;
//############################################################################//
function SDL_PollEvent(event:PSDL_Event):integer;cdecl;external lib_name;
function SDL_EnableKeyRepeat(delay,interval:integer):integer;cdecl;external lib_name;
//############################################################################//
function SDL_GetVideoSurface:PSDL_Surface;cdecl;external lib_name;
function SDL_SetVideoMode(width,height,bpp:integer;flags:dword):PSDL_Surface;cdecl;external lib_name;
function SDL_Flip(screen:PSDL_Surface):integer;cdecl;external lib_name;
function SDL_SetColors(surface:PSDL_Surface;colors:PSDL_Color;firstcolor,ncolors:integer):integer;cdecl;external lib_name;
function SDL_SetPalette(surface:PSDL_Surface;flags:integer;colors:PSDL_Color;firstcolor,ncolors:integer):integer;cdecl;external lib_name;
function SDL_MustLock(Surface:PSDL_Surface):boolean;
function SDL_LockSurface(surface:PSDL_Surface):integer;cdecl;external lib_name;
procedure SDL_UnlockSurface(surface:PSDL_Surface);cdecl;external lib_name;  
//############################################################################//
function SDL_MapRGB(format:PSDL_PixelFormat;r,g,b:byte):dword;cdecl;external lib_name;
function SDL_FillRect(dst:PSDL_Surface;dstrect:PSDL_Rect;color:dword):integer;cdecl;external lib_name;        
//############################################################################//
procedure SDL_WM_GetCaption(var title,icon:pchar);cdecl;external lib_name;
procedure SDL_WM_SetCaption(title,icon:pchar);cdecl;external lib_name;
procedure SDL_WM_SetIcon(icon:PSDL_Surface;mask:byte);cdecl;external lib_name;
function SDL_ShowCursor(toggle:integer):integer;cdecl;external lib_name;
//############################################################################//
//Enable/Disable UNICODE translation of keyboard input.
//This translation has some overhead, so translation defaults off.
//If 'enable' is 1, translation is enabled.
//If 'enable' is 0, translation is disabled.
//If 'enable' is -1, the translation state is not changed.
//It returns the previous state of keyboard translation.
function SDL_EnableUNICODE(enable:integer):integer;cdecl;external lib_name;
function SDL_GetError:pchar;cdecl;external lib_name;
//############################################################################//
implementation
//############################################################################//
function SDL_MustLock(Surface:PSDL_Surface):boolean;
begin
 result:=(surface.offset<>0)or((surface^.flags and (SDL_HWSURFACE or SDL_ASYNCBLIT or SDL_RLEACCEL))<>0) ;
end;
//############################################################################//
end.   
//############################################################################//

