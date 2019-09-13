//############################################################################//
unit sdigui;
interface
uses {$ifdef mswindows}windows,{$endif}asys,maths,strval,grph,graph8
{$ifdef android},jni_util{$endif}
,sdigrtools,mgrecs,sdirecs,sdiauxi,sdisound,sdimenu,sdicalcs;
//############################################################################/
const
menu_xs=400;
menu_ys=400;
cap_off=50;
data_off=80;
cbx_size=48;
//############################################################################//
LB_LEFT=0;
LB_CENTER=1;
LB_RIGHT=2;
LB_BIG_LEFT=3;
LB_BIG_CENTER=4;
LB_BIG_RIGHT=5; 
//############################################################################//
SCB_VERTICAL=0;
SCB_HORIZONTAL=1;
//############################################################################//
type
pcheckbox_type=^checkbox_type; 
pinputbox_type=^inputbox_type;
ptextbox_type=^textbox_type;
pbutton_type=^button_type;
pscrollbox_type=^scrollbox_type;
plabel_type=^label_type;
pscrollbar_type=^scrollbar_type;
pscrollarea_type=^scrollarea_type;
//############################################################################//
onevent_inputbox=procedure(s:psdi_rec;ib:pinputbox_type);
onevent_checkbox=procedure(s:psdi_rec;par,px:dword);
onevent_button  =procedure(s:psdi_rec;par,px:dword);
onevent_scroll  =procedure(s:psdi_rec;par,px:dword);
//############################################################################//
checkbox_type=record
 vr:pboolean;
 prev_vr:boolean;
 linked_cb:pcheckbox_type;
  
 vis:boolean;
 x,y,xs,ys:integer;
 mnum,pg:dword;

 event:onevent_checkbox;
 par:dword;
end;
//############################################################################//
inputbox_type=record
 wid,typ:integer;

 vri:pinteger;   //1
 vre:pdouble;    //2
 vrm:pstringmg;   //3

 vr:pstring;     //0
 prev_vr:string;
 ci,vis:boolean;

 alloc:boolean;

 ix,iy:integer;
 mnum,pg:dword;

 oni:onevent_inputbox;
 par:dword;
end;
//############################################################################//
textbox_type=record
 wid,fnt:integer;
 vr:pstring;
 prev_vr:string;
 cnt:boolean;
 alloc:boolean;

 vis:boolean;
 ix,iy:integer;
 mnum,pg:dword;
end;
//############################################################################//
label_type=record
 tp,fnt:integer;
 bc,fc,mc:byte;
 txt:string;
 upd,vis:boolean; 
 
 x,y:integer;
 mnum,pg:dword;
end;
//############################################################################//
button_type=record
 fnt0,fnt1:integer;    
 bc0,fc0,mc0,bc1,fc1,mc1:byte;
 txt:string;
 prev_stat,stat,vis,set_stat,no_snd:boolean;
  
 x,y,xs,ys:integer;
 mnum,pg:dword;

 event:onevent_button;
 par:dword;  
end;
//############################################################################//
scrollbox_type=record
 vis:boolean;
 dr:integer;
 reverse:boolean;
 step,top,bottom:integer;
 a_dwn,b_dwn:boolean;
 vr:pinteger;
 prev_vr:integer;
 
 xa,ya,xb,yb,xs,ys:integer;
 mnum,pg:dword;

 event:onevent_scroll;
 par:dword;  
end;
//############################################################################//
scrollbar_type=record
 wid:integer;
 ulim,llim:single;
 vr:psingle;
 prev_vr:single;

 ix,iy:integer;
 mnum,pg:dword;
end;
//############################################################################//
scrollarea_type=record
 dr:integer;
 last_dwn_y:integer;
 last_dwn_vr:integer;
 rb:pscrollbox_type;
 step,step_len,ulim,llim:integer;
 vr:pinteger;
 prev_vr:integer;
  
 x,y,xs,ys:integer;
 mnum,pg:dword;

 event:onevent_scroll;
 par:dword;  
end;         
//############################################################################//
var
sg_chkboxes:array of pcheckbox_type=nil;           //Checkboxes    
sg_inpboxes:array of pinputbox_type=nil;           //Input boxes
sg_txtboxes:array of ptextbox_type=nil;            //Text boxes
sg_labels:array of plabel_type=nil;                //Labels
sg_buttons:array of pbutton_type=nil;              //Buttons
sg_scrollboxes:array of pscrollbox_type=nil;       //Scroll boxes
sg_scrollbars:array of pscrollbar_type=nil;        //Scroll bars
sg_scrollareas:array of pscrollarea_type=nil;      //Scroll areas

cur_inputbox:pinputbox_type=nil;   //Current input box 
cur_inputbox_pos:integer=0;        //Current input box position
ibxm:boolean;                      //Input mode  
//############################################################################//
function  add_checkbox(mnum,pg:dword;x,y,xs,ys:integer;linked_cb:pcheckbox_type;vr:pboolean;event:onevent_checkbox;par:dword=0):pcheckbox_type;
function  add_textbox (mnum,pg:dword;ix,iy,wid:integer;cnt:boolean;fnt:integer;vr:pstring;def:string):ptextbox_type;
function  add_inputbox(mnum,pg:dword;ix,iy,wid,typ:integer;vr:pointer;oni:onevent_inputbox;par:dword;def:string):pinputbox_type;

function  add_label(mnum,pg:dword;x,y,tp:integer;txt:string;fnt:integer;fc,bc,mc:byte):plabel_type;overload;
function  add_label(mnum,pg:dword;x,y,tp,fp:integer;txt:string):plabel_type;overload;

function  add_button(mnum,pg:dword;x,y,xs,ys,fnt0:integer;fc0,bc0,mc0:byte;fnt1:integer;fc1,bc1,mc1:byte;txt:string;event:onevent_button;par:dword):pbutton_type;overload;
function  add_button(mnum,pg:dword;x,y,xs,ys,fp0,fp1:integer;txt:string;event:onevent_button;par:dword):pbutton_type;overload;

function  add_scrollbox(mnum,pg:dword;dr,xa,ya,xb,yb,xs,ys,step,top,bottom:integer;reverse:boolean;vr:pinteger;event:onevent_scroll;par:dword):pscrollbox_type;
function  add_scrollbar(mnum,pg:dword;ix,iy,wid:integer;ulim,llim:single;vr:psingle):pscrollbar_type;
function  add_scrolarea(mnum,pg:dword;dr,x,y,xs,ys,step,step_len,ulim,llim:integer;vr:pinteger;event:onevent_scroll;par:dword;rb:pscrollbox_type):pscrollarea_type;
//############################################################################//    
procedure draw_uint(s:psdi_rec;spr:ptypspr);
procedure gui_frame_event;
procedure clear_gui;
procedure reup_gui(s:psdi_rec);
procedure rmnu_sizes(cg:psdi_grap_rec;out xs,ys,tyo:integer);
//############################################################################//  
function add_clickbox(mn,pg:dword;x,y:integer;nam:string;lf:pcheckbox_type;vr:pboolean;oni:onevent_checkbox;par:dword=0):pcheckbox_type;
function add_clickbox_3(mn,pg:dword;x,y:integer;nam:string;lf:pcheckbox_type;vr:pboolean;oni:onevent_checkbox;par:dword=0):pcheckbox_type;
function add_numeric_input(mn,pg:dword;x,y:integer;nam:string;step,ulim,llim:integer;vr:pinteger;event:onevent_scroll;par:dword):pscrollbox_type;
function add_text_input(mn,pg:dword;x,y,wid,typ:integer;nam:string;vr:pointer;oni:onevent_inputbox;par:dword;def:string):pinputbox_type;
//############################################################################//         
function gui_mouse_dwn  (s:psdi_rec;shift:dword;x,y:integer):boolean;
function gui_mouse_move (s:psdi_rec;shift:dword;x,y:integer):boolean;
function gui_mouse_wheel(s:psdi_rec;shift:dword;x,y,d:integer):boolean;
function gui_mouse_up   (s:psdi_rec;shift:dword;x,y:integer):boolean;
function proc_input_boxes(s:psdi_rec;key,shift:dword):boolean;
//############################################################################//
implementation
//############################################################################//
function match_id(a,b:dword):boolean;
begin
 result:=((a and b)<>0)or((a=0)and(b=0));
end;
//############################################################################//
function add_checkbox(mnum,pg:dword;x,y,xs,ys:integer;linked_cb:pcheckbox_type;vr:pboolean;event:onevent_checkbox;par:dword=0):pcheckbox_type;
begin                        
 setlength(sg_chkboxes,length(sg_chkboxes)+1);
 new(sg_chkboxes[length(sg_chkboxes)-1]);
 result:=sg_chkboxes[length(sg_chkboxes)-1];
 
 result.x:=x;result.y:=y;result.xs:=xs;result.ys:=ys;result.mnum:=mnum;result.pg:=pg;
 result.linked_cb:=linked_cb;result.vr:=vr;result.prev_vr:=vr^;result.event:=event;result.par:=par;
 result.vis:=true;
end;      
//############################################################################//
function add_inputbox(mnum,pg:dword;ix,iy,wid,typ:integer;vr:pointer;oni:onevent_inputbox;par:dword;def:string):pinputbox_type;
begin       
 setlength(sg_inpboxes,length(sg_inpboxes)+1);
 new(sg_inpboxes[length(sg_inpboxes)-1]);
 result:=sg_inpboxes[length(sg_inpboxes)-1]; 
 
 
 result.ix:=ix;
 result.iy:=iy;
 result.wid:=wid;
 result.mnum:=mnum;
 result.pg:=pg;
 result.alloc:=false;
 result.ci:=false;
 result.vis:=true;
 result.typ:=typ;

 case typ of
  0:begin
   if vr=nil then begin result.alloc:=true;new(pstring(vr));pstring(vr)^:=def;end;
   result.vr:=vr;
  end;
  //Integer
  1:begin             
   result.vri:=vr;
   new(pstring(result.vr));
   result.alloc:=true;
   pstring(result.vr)^:=stri(pinteger(vr)^);
  end;
  //Double
  2:begin             
   result.vre:=vr;
   new(pstring(result.vr));
   result.alloc:=true;
   pstring(result.vr)^:=stre(pdouble(vr)^);
  end;
  //StringMG
  3:begin             
   result.vrm:=vr;
   new(pstring(result.vr));
   result.alloc:=true;
   pstring(result.vr)^:=pstringmg(vr)^;
  end;
 end;

 result.prev_vr:=pstring(result.vr)^;
 result.oni:=oni;
 result.par:=par;
end;        
//############################################################################//
function  add_textbox(mnum,pg:dword;ix,iy,wid:integer;cnt:boolean;fnt:integer;vr:pstring;def:string):ptextbox_type;
begin  
 setlength(sg_txtboxes,length(sg_txtboxes)+1);
 new(sg_txtboxes[length(sg_txtboxes)-1]);
 result:=sg_txtboxes[length(sg_txtboxes)-1]; 
 
 
 result.ix:=ix;
 result.iy:=iy;
 result.wid:=wid;
 result.mnum:=mnum;
 result.pg:=pg;
 result.cnt:=cnt;
 result.fnt:=fnt;
 result.alloc:=false;
 if vr=nil then begin result.alloc:=true;new(vr);vr^:=def;end;
 result.vr:=vr;
 result.prev_vr:=vr^;
 result.vis:=true;
end;       
//############################################################################//
function add_label(mnum,pg:dword;x,y,tp:integer;txt:string;fnt:integer;fc,bc,mc:byte):plabel_type;overload;
begin     
 setlength(sg_labels,length(sg_labels)+1);
 new(sg_labels[length(sg_labels)-1]);
 result:=sg_labels[length(sg_labels)-1];
 
 result.x:=x;result.y:=y;result.tp:=tp;result.pg:=pg;
 result.mnum:=mnum;result.fnt:=fnt;result.fc:=fc;result.bc:=bc;result.mc:=mc;
 result.txt:=txt;result.upd:=true;result.vis:=true;
end;         
function add_label(mnum,pg:dword;x,y,tp,fp:integer;txt:string):plabel_type;overload;
begin result:=add_label(mnum,pg,x,y,tp,txt,fntpr[fp][0],fntpr[fp][1],fntpr[fp][2],fntpr[fp][3]); end;
//############################################################################//
function add_button(mnum,pg:dword;x,y,xs,ys,fnt0:integer;fc0,bc0,mc0:byte;fnt1:integer;fc1,bc1,mc1:byte;txt:string;event:onevent_button;par:dword):pbutton_type;overload;
begin  
 setlength(sg_buttons,length(sg_buttons)+1);
 new(sg_buttons[length(sg_buttons)-1]);
 result:=sg_buttons[length(sg_buttons)-1];
 
 result.x:=x;result.y:=y;
 result.set_stat:=false;result.no_snd:=false;
 result.xs:=xs;result.ys:=ys;result.pg:=pg;
 result.mnum:=mnum;result.fnt0:=fnt0;result.vis:=true;
 result.fnt1:=fnt1;result.txt:=txt;result.stat:=false;
 result.prev_stat:=false;result.event:=event;result.par:=par;
 result.fc0:=fc0;result.bc0:=bc0;result.mc0:=mc0;
 result.fc1:=fc1;result.bc1:=bc1;result.mc1:=mc1;
end;     
function add_button(mnum,pg:dword;x,y,xs,ys,fp0,fp1:integer;txt:string;event:onevent_button;par:dword):pbutton_type;overload;
begin result:=add_button(mnum,pg,x,y,xs,ys,fntpr[fp0][0],fntpr[fp0][1],fntpr[fp0][2],fntpr[fp0][3],fntpr[fp1][0],fntpr[fp1][1],fntpr[fp1][2],fntpr[fp1][3],txt,event,par); end;
//############################################################################//
function add_scrollbox(mnum,pg:dword;dr,xa,ya,xb,yb,xs,ys,step,top,bottom:integer;reverse:boolean;vr:pinteger;event:onevent_scroll;par:dword):pscrollbox_type;
begin  
 setlength(sg_scrollboxes,length(sg_scrollboxes)+1);
 new(sg_scrollboxes[length(sg_scrollboxes)-1]);
 result:=sg_scrollboxes[length(sg_scrollboxes)-1];
 
 result.dr:=dr;result.reverse:=reverse;
 result.xa:=xa;result.ya:=ya;result.xb:=xb;result.yb:=yb;result.xs:=xs;result.ys:=ys;
 result.step:=step;result.top:=top;result.bottom:=bottom;
 result.mnum:=mnum;result.pg:=pg;
 result.vr:=vr;result.prev_vr:=vr^;
 result.event:=event;result.par:=par;result.a_dwn:=false;result.b_dwn:=false;result.vis:=true;
end;
//############################################################################//
function add_scrollbar(mnum,pg:dword;ix,iy,wid:integer;ulim,llim:single;vr:psingle):pscrollbar_type;
begin  
 setlength(sg_scrollbars,length(sg_scrollbars)+1);
 new(sg_scrollbars[length(sg_scrollbars)-1]);
 result:=sg_scrollbars[length(sg_scrollbars)-1];
 
 result.wid:=wid;result.ix:=ix;result.iy:=iy;
 result.ulim:=ulim;result.llim:=llim;result.mnum:=mnum;result.pg:=pg;
 result.vr:=vr;result.prev_vr:=vr^;
end;
//############################################################################//
function add_scrolarea(mnum,pg:dword;dr,x,y,xs,ys,step,step_len,ulim,llim:integer;vr:pinteger;event:onevent_scroll;par:dword;rb:pscrollbox_type):pscrollarea_type;
begin
 setlength(sg_scrollareas,length(sg_scrollareas)+1);
 new(sg_scrollareas[length(sg_scrollareas)-1]);
 result:=sg_scrollareas[length(sg_scrollareas)-1];
 
 result.last_dwn_y:=-1;
 result.dr:=dr;result.x:=x;result.y:=y;
 result.xs:=xs;result.ys:=ys;result.step:=step;result.step_len:=step_len;
 result.ulim:=ulim;result.llim:=llim;result.mnum:=mnum;result.pg:=pg;
 result.vr:=vr;result.prev_vr:=vr^;result.rb:=rb;
 result.event:=event;result.par:=par;
end;     
//############################################################################//
//############################################################################//
procedure draw_checkbox(cg:psdi_grap_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;cb:pcheckbox_type);
begin
 if not cb.vis then exit;    
 if cb.vr=nil then exit;
 if not (match_id(tnum,cb.mnum)and(tpg=cb.pg)and(cb.prev_vr<>cb.vr^))then exit;
 
 cb.prev_vr:=cb.vr^;
 tran_rect8(cg,spr,xn+cb.x,yn+cb.y,cb.xs,cb.ys,ord(ord(cb.vr^)>0));
end;
//############################################################################//
procedure draw_inputbox(cg:psdi_grap_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;ib:pinputbox_type);
begin
 if not ib.vis then exit;
 if not match_id(tnum,ib.mnum)or(tpg<>ib.pg) then exit;
 if ib.prev_vr=ib.vr^ then exit;

 ib.prev_vr:=ib.vr^;
 tran_rect8(cg,spr,xn+ib.ix,yn+ib.iy,ib.wid,text_box_hei,0);

 if ib.vr<>nil then wrtxt8(cg,spr,xn+ib.ix+3,yn+ib.iy+7,ib.vr^,2);
 if (cur_inputbox=ib)and ibxm then drrect8(spr,xn+ib.ix+3+gettxtmglen(cg,0,copy(ib.vr^,1,cur_inputbox_pos))-1,yn+ib.iy+5,xn+ib.ix+3+gettxtmglen(cg,0,copy(ib.vr^,1,cur_inputbox_pos))-1,yn+ib.iy+7+7,2);
end;
//############################################################################//
procedure draw_textbox(s:psdi_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;tb:ptextbox_type);
var stt:string;
begin
 if not tb.vis then exit;
 if not match_id(tnum,tb.mnum)or(tpg<>tb.pg) then exit;
 if tb.prev_vr=tb.vr^ then exit;

 tb.prev_vr:=tb.vr^;
 tran_rect8(s.cg,spr,xn+tb.ix,yn+tb.iy,tb.wid,text_box_hei,0);

 stt:=tb.vr^;
 if tb.vr<>nil then if not tb.cnt then wrtxt8   (s.cg,spr,xn+tb.ix+3                ,yn+tb.iy+7,stt,tb.fnt);
 if tb.vr<>nil then if     tb.cnt then wrtxtcnt8(s.cg,spr,xn+tb.ix+(tb.wid-6)div 2+3,yn+tb.iy+7,stt,tb.fnt);
end;      
//############################################################################//
procedure draw_button(s:psdi_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;bt:pbutton_type);
var n,n2,n3,n4:integer;
begin
 if not bt.vis then exit;
 if not match_id(tnum,bt.mnum)or(tpg<>bt.pg)or(bt.stat=bt.prev_stat) then exit;
 bt.prev_stat:=bt.stat;

 if bt.stat or bt.set_stat then begin n:=bt.fnt1;n2:=bt.fc1;n3:=bt.bc1;n4:=bt.mc1; end else begin n:=bt.fnt0;n2:=bt.fc0;n3:=bt.bc0;n4:=bt.mc0; end;

 tran_rect8(s.cg,spr,xn+bt.x,yn+bt.y,bt.xs,bt.ys,ord(bt.stat or bt.set_stat));
 wrtxtcntmg8(s.cg,spr,xn+bt.x+bt.xs div 2,yn+bt.y+bt.ys div 2-s.cg.mgfnt[n].height div 2-1+ord(bt.stat or bt.set_stat),bt.txt,n,n2,n3,n4);
end;   
//############################################################################//
procedure draw_scrollbox(cg:psdi_grap_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;sc:pscrollbox_type);
var x,y,off,k:integer;
begin
 if sc.vis then if match_id(tnum,sc.mnum)and(tpg=sc.pg)and(sc.prev_vr<>sc.vr^) then begin
  sc.prev_vr:=sc.vr^;
  if sc.vr<>nil then begin
   if sc.vr^<=sc.top then sc.a_dwn:=true;
   if sc.vr^>=sc.bottom then sc.b_dwn:=true;

   tran_rect8(cg,spr,xn+sc.xa,yn+sc.ya,sc.xs,sc.ys,ord(sc.a_dwn));
   tran_rect8(cg,spr,xn+sc.xb,yn+sc.yb,sc.xs,sc.ys,ord(sc.b_dwn));
   off:=4;
   for k:=-1 to 1 do case sc.dr of
    SCB_VERTICAL:begin
     if sc.reverse then begin x:=xn+sc.xb+sc.xs div 2;y:=yn+sc.yb+sc.ys div 2; end else begin x:=xn+sc.xa+sc.xs div 2;y:=yn+sc.ya+sc.ys div 2;end;
     drline8(spr,x+k,y-sc.ys div 2+off,x+k,y+sc.ys div 2-off,line_color);
     drline8(spr,x,y+k-sc.ys div 2+off,x-sc.xs div 2+off,y+k,line_color);
     drline8(spr,x,y+k-sc.ys div 2+off,x+sc.xs div 2-off,y+k,line_color);
           
     if sc.reverse then begin x:=xn+sc.xa+sc.xs div 2;y:=yn+sc.ya+sc.ys div 2; end else begin x:=xn+sc.xb+sc.xs div 2;y:=yn+sc.yb+sc.ys div 2;end;
     drline8(spr,x+k,y-sc.ys div 2+off,x+k,y+sc.ys div 2-off,line_color);
     drline8(spr,x,y+k+sc.ys div 2-off,x-sc.xs div 2+off,y+k,line_color);
     drline8(spr,x,y+k+sc.ys div 2-off,x+sc.xs div 2-off,y+k,line_color);
    end;
    SCB_HORIZONTAL:begin  
     x:=xn+sc.xa+sc.xs div 2;y:=yn+sc.ya+sc.ys div 2;
     drline8(spr,x-sc.xs div 2+off,y+k,x+sc.xs div 2-off,y+k,line_color);
     drline8(spr,x+k-sc.xs div 2+off,y,x+k,y+sc.ys div 2-off,line_color);
     drline8(spr,x+k-sc.xs div 2+off,y,x+k,y-sc.ys div 2+off,line_color);

     x:=xn+sc.xb+sc.xs div 2;y:=yn+sc.yb+sc.ys div 2;
     drline8(spr,x-sc.xs div 2+off,y+k,x+sc.xs div 2-off,y+k,line_color);
     drline8(spr,x+k+sc.xs div 2-off,y,x+k,y+sc.ys div 2-off,line_color);
     drline8(spr,x+k+sc.xs div 2-off,y,x+k,y-sc.ys div 2+off,line_color);
    end;
   end;
  end;
 end;
end;
//############################################################################//
procedure draw_label(s:psdi_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;lb:plabel_type);
begin
 if not lb.vis then exit;
 if not match_id(tnum,lb.mnum)or(tpg<>lb.pg)or not lb.upd then exit;
 lb.upd:=false;
 case lb.tp of
  LB_LEFT:      wrtxtmg8   (s.cg,spr,xn+lb.x,yn+lb.y,lb.txt,lb.fnt,lb.fc,lb.bc,lb.mc);
  LB_CENTER:    wrtxtcntmg8(s.cg,spr,xn+lb.x,yn+lb.y,lb.txt,lb.fnt,lb.fc,lb.bc,lb.mc);
  LB_RIGHT:     wrtxtrmg8  (s.cg,spr,xn+lb.x,yn+lb.y,lb.txt,lb.fnt,lb.fc,lb.bc,lb.mc);
  LB_BIG_LEFT:  wrbgtxt8   (s.cg,spr,xn+lb.x,yn+lb.y,lb.txt,lb.fnt);
  LB_BIG_CENTER:wrbgtxtcnt8(s.cg,spr,xn+lb.x,yn+lb.y,lb.txt,lb.fnt);
  LB_BIG_RIGHT: wrbgtxtr8  (s.cg,spr,xn+lb.x,yn+lb.y,lb.txt,lb.fnt);
 end;
end;
//############################################################################//
procedure draw_scrollbar(cg:psdi_grap_rec;spr:ptypspr;xn,yn:integer;tnum,tpg:dword;sb:pscrollbar_type);
var n:integer;
begin
 with sb^ do if match_id(tnum,mnum)and(tpg=pg)and(prev_vr<>vr^) then begin
  prev_vr:=vr^;
  if vr<>nil then begin
   n:=round(((vr^-ulim)/(llim-ulim))*wid);
   if vr^<ulim then n:=0;
   if vr^>llim then n:=wid;
   drrectx8(spr,xn+ix,yn+iy,wid,2,line_color);
   drrectx8(spr,xn+ix+n-1,yn+iy-scroller_hei div 2,2,scroller_hei,line_color);
  end;
 end;
end;
//############################################################################//
//Frame and menus user interface
procedure draw_uint(s:psdi_rec;spr:ptypspr);
var xn,yn,i:integer;
begin try 
 calc_menuframe_pos(s.cur_menu,xn,yn);

 for i:=0 to length(sg_chkboxes)-1    do draw_checkbox (s.cg,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_chkboxes[i]); 
 for i:=0 to length(sg_scrollboxes)-1 do draw_scrollbox(s.cg,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_scrollboxes[i]); 
 for i:=0 to length(sg_scrollbars)-1  do draw_scrollbar(s.cg,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_scrollbars[i]); 
 for i:=0 to length(sg_inpboxes)-1    do draw_inputbox (s.cg,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_inpboxes[i]);
 for i:=0 to length(sg_txtboxes)-1    do draw_textbox  (s,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_txtboxes[i]);     
 for i:=0 to length(sg_labels)-1      do draw_label    (s,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_labels[i]);     
 for i:=0 to length(sg_buttons)-1     do draw_button   (s,spr,xn,yn,s.cur_menu,s.cur_menu_page,sg_buttons[i]);

 except stderr(s,'SDIDraws','draw_gui');end;
end;
//############################################################################// 
procedure ib_apply_val(ib:pinputbox_type;dir:integer);
begin
 //0 - vr->val
 //1 - val->vr
 case dir of
  0:case ib.typ of
   1:ib.vri^:=vali(pstring(ib.vr)^);
   2:ib.vre^:=vale(pstring(ib.vr)^);  
   3:ib.vrm^:=pstring(ib.vr)^;
  end;
  1:case ib.typ of
   1:pstring(ib.vr)^:=stri(ib.vri^);
   2:pstring(ib.vr)^:=stre(ib.vre^);  
   3:pstring(ib.vr)^:=ib.vrm^;
  end;
 end;
end;    
//############################################################################//         
procedure reup_gui(s:psdi_rec);
var i:integer;
xn,yn:integer;
begin            
 calc_menuframe_pos(s.cur_menu,xn,yn);
 for i:=0 to length(sg_inpboxes)-1 do with sg_inpboxes[i]^ do if match_id(s.cur_menu,mnum) then ib_apply_val(sg_inpboxes[i],1);
end;  
//############################################################################//   
function in_button(cg:psdi_grap_rec;x,y,xn,yn,i:integer):boolean;
begin
 result:=inrects(x,y,xn+sg_buttons[i].x,yn+sg_buttons[i].y,sg_buttons[i].xs,sg_buttons[i].ys);
end;  
//############################################################################//         
function gui_mouse_dwn(s:psdi_rec;shift:dword;x,y:integer):boolean;
var i,ii:integer;
xn,yn:integer;
cb:pcheckbox_type;
scb:pscrollbox_type;
bt:pbutton_type;
begin
 result:=false;
 if s.hide_interface then exit;
 calc_menuframe_pos(s.cur_menu,xn,yn);
 
 result:=ibxm;
 for i:=0 to length(sg_chkboxes)-1 do begin
  cb:=sg_chkboxes[i];
  if cb.vis then if match_id(s.cur_menu,cb.mnum)and(s.cur_menu_page=cb.pg) then begin
   if inrects(x,y,xn+cb.x,yn+cb.y,cb.xs,cb.ys) then begin
    snd_click(SND_TOGGLE);
    cb.vr^:=not cb.vr^;
    if cb.linked_cb<>nil then cb.linked_cb.vr^:=not cb.linked_cb.vr^;
    if assigned(cb.event) then cb.event(s,cb.par,ord(cb.vr^));
    event_frame(s);
    result:=true;
   end;
  end;
 end;

 for i:=0 to length(sg_scrollboxes)-1 do begin
  scb:=sg_scrollboxes[i];
  if scb.vis then if match_id(s.cur_menu,scb.mnum)and(s.cur_menu_page=scb.pg) then begin
   if inrects(x,y,xn+scb.xa,yn+scb.ya,scb.xs,scb.ys) then begin snd_click(SND_ACCEPT);scb.a_dwn:=true; scb.b_dwn:=false;event_frame(s);result:=true;end;
   if inrects(x,y,xn+scb.xb,yn+scb.yb,scb.xs,scb.ys) then begin snd_click(SND_ACCEPT);scb.a_dwn:=false;scb.b_dwn:=true; event_frame(s);result:=true;end;
  end;
 end;

 for i:=0 to length(sg_scrollbars)-1 do with sg_scrollbars[i]^ do if match_id(s.cur_menu,mnum)and(s.cur_menu_page=pg) then begin
  if inrects(x,y,xn+ix,yn+iy-scroller_hei div 2,wid,scroller_hei) then begin
   snd_click(SND_ACCEPT);
   vr^:=ulim+((x-(xn+ix))/wid)*(llim-ulim);
   if vr^>llim then vr^:=llim;  
   if vr^<ulim then vr^:=ulim;
   event_frame(s);   
   result:=true;
  end;       
 end; 
 for i:=0 to length(sg_scrollareas)-1 do if match_id(s.cur_menu,sg_scrollareas[i].mnum)and(s.cur_menu_page=sg_scrollareas[i].pg) then begin
  if inrects(x,y,xn+sg_scrollareas[i].x,yn+sg_scrollareas[i].y,sg_scrollareas[i].xs,sg_scrollareas[i].ys) then begin
   sg_scrollareas[i].last_dwn_y:=sg_scrollareas[i].y;     
   sg_scrollareas[i].last_dwn_vr:=sg_scrollareas[i].vr^;
  end;
 end;

 for i:=0 to length(sg_inpboxes)-1 do with sg_inpboxes[i]^ do if match_id(s.cur_menu,mnum)and(s.cur_menu_page=pg) then begin
  if not inrect(x,y,xn+ix,yn+iy,xn+ix+wid,yn+iy+23) then if ci then begin
   ci:=false;  
   ibxm:=false;
   ib_apply_val(sg_inpboxes[i],0);
   if cur_inputbox<>nil then if assigned(cur_inputbox.oni) then cur_inputbox.oni(s,cur_inputbox);    
   result:=true;
  end;
 end;

 for i:=0 to length(sg_inpboxes)-1 do with sg_inpboxes[i]^ do if vis then if match_id(s.cur_menu,mnum)and(s.cur_menu_page=pg) then begin
  if inrect(x,y,xn+ix,yn+iy,xn+ix+wid,yn+iy+23) then begin
   for ii:=0 to length(sg_inpboxes)-1 do sg_inpboxes[ii].ci:=false;
   ci:=true;  
   result:=true;
   ibxm:=true;   
   ib_apply_val(sg_inpboxes[i],1);
   cur_inputbox_pos:=length(vr^);
   cur_inputbox:=sg_inpboxes[i];
   {$ifdef android}
   pstring(sg_inpboxes[i].vr)^:='';
   show_virtual_keyboard;
   {$endif}
   exit;
  end;
 end;

 for i:=0 to length(sg_buttons)-1 do begin
  bt:=sg_buttons[i];
  if bt.vis then if match_id(s.cur_menu,bt.mnum)and(s.cur_menu_page=bt.pg) then begin
   if in_button(s.cg,x,y,xn,yn,i) then begin
    if not bt.no_snd then snd_click(SND_BUTTON);
    bt.stat:=true;
    event_frame(s);
    result:=true;
   end;
  end;
 end;
end;  
//############################################################################//
//############################################################################//       
function gui_mouse_move(s:psdi_rec;shift:dword;x,y:integer):boolean;
var i,xn,yn:integer;
//sg:pscrollarea_type;
begin 
 result:=false;
 if s.hide_interface then exit;
 calc_menuframe_pos(s.cur_menu,xn,yn);
 if not isf(shift,sh_left) then exit;

 for i:=0 to length(sg_scrollbars)-1 do with sg_scrollbars[i]^ do if match_id(s.cur_menu,mnum)and(s.cur_menu_page=pg) then begin
  if inrects(x,y,xn+ix-10,yn+iy-scroller_hei div 2-5,wid+20,scroller_hei+5) then begin
   vr^:=ulim+((x-(xn+ix))/wid)*(llim-ulim);
   if vr^>llim then vr^:=llim;  
   if vr^<ulim then vr^:=ulim;
   event_frame(s);
   result:=true;
  end;       
 end;
 {
 //FIXME: Broken...
 for i:=0 to length(sg_scrollareas)-1 do begin
  sg:=sg_scrollareas[i];
  if match_id(s.cur_menu,sg.mnum)and(s.cur_menu_page=sg.pg) then begin
   if inrects(x,y,xn+sg.x,yn+sg.y,sg.xs,sg.ys) and (sg.last_dwn_y>=0) then begin
    n:=sg.vr^;
    if sg.dr>0 then sg.vr^:=round(sg.ulim+((x-(xn+sg.x))/sg.xs)*(sg.llim-sg.ulim))
               else sg.vr^:=round(sg.last_dwn_vr+sg.step*(sg.last_dwn_y-y)/sg.step_len);
    if sg.vr^>sg.llim then sg.vr^:=sg.llim;
    if sg.vr^<sg.ulim then sg.vr^:=sg.ulim;
    if sg.vr^<>n then if assigned(sg.event) then sg.event(s,sg.par,1);
    event_frame(s);
    result:=true;
    if sg.rb<>nil then begin
     sg.rb.prev_vr:=99999999;
     sg.rb.a_dwn:=false;
     sg.rb.b_dwn:=false;
    end;
   end;
  end;
 end;
 }
end; 
//############################################################################//
//############################################################################//       
function gui_mouse_wheel(s:psdi_rec;shift:dword;x,y,d:integer):boolean;
var i,n:integer;
xn,yn:integer;
sg:pscrollarea_type;
begin 
 result:=false;
 if s.hide_interface then exit;
 calc_menuframe_pos(s.cur_menu,xn,yn);
                      
 for i:=0 to length(sg_scrollareas)-1 do sg_scrollareas[i].last_dwn_y:=-1;
 
 for i:=0 to length(sg_scrollareas)-1 do begin
  sg:=sg_scrollareas[i];
  if match_id(s.cur_menu,sg.mnum)and(s.cur_menu_page=sg.pg) then begin
   if inrects(x,y,xn+sg.x,yn+sg.y,sg.xs,sg.ys) then begin
    n:=sg.vr^;
    if abs(sg.dr)=1 then sg.vr^:=sg.vr^+d*sg.step;
    if abs(sg.dr)=2 then sg.vr^:=sg.vr^-d*sg.step;
    if sg.vr^>sg.llim then sg.vr^:=sg.llim;
    if sg.vr^<sg.ulim then sg.vr^:=sg.ulim;
    if sg.vr^<>n then if assigned(sg.event) then sg.event(s,sg.par,1);
    event_frame(s);
    result:=true;
    if sg.rb<>nil then begin
     sg.rb.prev_vr:=99999999;
     sg.rb.a_dwn:=false;
     sg.rb.b_dwn:=false;
    end;
   end;
  end;
 end;
end;    
//############################################################################//         
function gui_mouse_up(s:psdi_rec;shift:dword;x,y:integer):boolean;
var i,n:integer;
xn,yn:integer;
scb:pscrollbox_type; 
bt:pbutton_type;
begin result:=false;try  
 calc_menuframe_pos(s.cur_menu,xn,yn); 
 if s.hide_interface then exit;

 for i:=0 to length(sg_buttons)-1 do begin
  bt:=sg_buttons[i];
  if bt.vis and bt.stat then begin
   //Right. The button destroys itself... Then tries to alter own state. (buttons can be deleted in callbacks)
   bt.stat:=false;
   if match_id(s.cur_menu,bt.mnum)and(s.cur_menu_page=bt.pg)then if in_button(s.cg,x,y,xn,yn,i) then begin
    result:=true;
    if assigned(bt.event) then bt.event(s,bt.par,0);
    break;
   end;
   event_frame(s);
  end;
 end;
                    
 for i:=0 to length(sg_scrollareas)-1 do sg_scrollareas[i].last_dwn_y:=-1;
 
 for i:=0 to length(sg_scrollboxes)-1 do begin
  scb:=sg_scrollboxes[i];
  if scb.vis then if match_id(s.cur_menu,scb.mnum)and(s.cur_menu_page=scb.pg) then begin
   if inrects(x,y,xn+scb.xa,yn+scb.ya,scb.xs,scb.ys) then begin
    result:=true;
    n:=scb.vr^;
    scb.vr^:=scb.vr^-scb.step;
    if scb.vr^<scb.top then scb.vr^:=scb.top;
    if scb.vr^<>n then if assigned(scb.event) then scb.event(s,scb.par,1);
    reup_gui(s);
   end;
   if inrects(x,y,xn+scb.xb,yn+scb.yb,scb.xs,scb.ys) then begin
    result:=true;
    n:=scb.vr^;
    scb.vr^:=scb.vr^+scb.step;
    if scb.vr^>scb.bottom then scb.vr^:=scb.bottom;
    if scb.vr^<>n then if assigned(scb.event) then scb.event(s,scb.par,2);
    reup_gui(s);
   end;
   scb.a_dwn:=false;
   scb.b_dwn:=false;
   event_frame(s);
  end;
 end;
  
 except stderr(s,'SDIDraws','mupint'); end;
end;           
//############################################################################//
//############################################################################//
function  proc_input_boxes(s:psdi_rec;key,shift:dword):boolean;
var ss:string;
ib:pinputbox_type;
begin
 result:=false;  
 if s.hide_interface then exit;
 if ibxm then begin   
  ib:=cur_inputbox;
  event_map_reposition(s);
  event_units(s);
  event_frame(s);
  case key of
   key_up:cur_inputbox_pos:=0;
   key_dwn:cur_inputbox_pos:=length(ib.vr^);
   key_right:begin cur_inputbox_pos:=cur_inputbox_pos+1; if cur_inputbox_pos>length(ib.vr^) then cur_inputbox_pos:=length(ib.vr^); end;
   key_left:begin cur_inputbox_pos:=cur_inputbox_pos-1; if cur_inputbox_pos<0 then cur_inputbox_pos:=0; end;
   key_enter:begin ib_apply_val(ib,0); ibxm:=false;if assigned(ib.oni) then ib.oni(s,ib); end;
   key_esc:begin ib_apply_val(ib,0); ibxm:=false;if assigned(ib.oni) then ib.oni(s,ib); end;
   key_backspace:begin
    if cur_inputbox_pos=0 then begin result:=true;exit;end else
    if cur_inputbox_pos=1 then ib.vr^:=copy(ib.vr^,2,length(ib.vr^)) else
    if cur_inputbox_pos=length(ib.vr^) then ib.vr^:=copy(ib.vr^,1,length(ib.vr^)-1) else
    ib.vr^:=copy(ib.vr^,1,cur_inputbox_pos-1)+copy(ib.vr^,cur_inputbox_pos+1,length(ib.vr^));
    cur_inputbox_pos:=cur_inputbox_pos-1;
   end;
   else begin
    if isf(shift,sh_ctrl) then case key of
     key_v:begin
      {$ifdef mswindows}
      if OpenClipboard(0) then begin
       ss:=pchar(GetClipboardData(1));  //CF_TEXT     
       ib.vr^:=copy(ib.vr^,1,cur_inputbox_pos)+ss+copy(ib.vr^,cur_inputbox_pos+1,length(ib.vr^));
       cur_inputbox_pos:=cur_inputbox_pos+length(ss);
      end;
      CloseClipboard;
      {$endif}
     end;
    end;
    if key>=32 then if length(ib.vr^)<ib.wid/8 then begin
     ss:=chr(key);
     //if (key>=$41)and(key<=$5A) then if not (ssshift in shift) then ss:=chr(key+$20);
     if isf(shift,sh_shift) then begin
      if (key>=$61)and(key<=$7A) then ss:=chr(key-$20);
      case ss[1] of
       '`':ss:='~';
       '/':ss:='?';
       ',':ss:='<';
       '.':ss:='>';
       ';':ss:=':';
       '''':ss:='"';
       '[':ss:='{';
       ']':ss:='}';
       '\':ss:='|';
      end;
      if (key>=$2D)and(key<=$3D) then case key of
       $2D:ss:='_';
       $30:ss:=')';
       $31:ss:='!';
       $32:ss:='@';
       $33:ss:='#';
       $34:ss:='$';
       $35:ss:='%';
       $36:ss:='^';
       $37:ss:='&';
       $38:ss:='*';
       $39:ss:='(';
       $3D:ss:='+';
      end;
     end;
     if((key>$80)and(key<$C0)and(key<>$A8)and(key<>$B8))or(key>$FF)then case key of
      $C0:if isf(shift,sh_shift) then ss:='~' else ss:='`';
      $DB:if isf(shift,sh_shift) then ss:='{' else ss:='[';
      $DD:if isf(shift,sh_shift) then ss:='}' else ss:=']';
      $BA:if isf(shift,sh_shift) then ss:=':' else ss:=';';
      $DE:if isf(shift,sh_shift) then ss:='"' else ss:='''';
      $DC:if isf(shift,sh_shift) then ss:='|' else ss:='\';
      $BC:if isf(shift,sh_shift) then ss:='<' else ss:=',';
      $BE:if isf(shift,sh_shift) then ss:='>' else ss:='.';
      $BF:if isf(shift,sh_shift) then ss:='?' else ss:='/';
      else begin result:=true;exit; end;
     end;
     if cur_inputbox_pos=0 then ib.vr^:=ss+ib.vr^ else
     if cur_inputbox_pos=length(ib.vr^) then ib.vr^:=ib.vr^+ss else
     ib.vr^:=copy(ib.vr^,1,cur_inputbox_pos)+ss+copy(ib.vr^,cur_inputbox_pos+1,length(ib.vr^));
     cur_inputbox_pos:=cur_inputbox_pos+1;
    end;
   end;
  end;
  result:=true;
 end;  
end;    
//############################################################################//
procedure gui_frame_event;
var i:integer;
begin                          
 for i:=0 to length(sg_scrollboxes)-1 do sg_scrollboxes[i].prev_vr:=sg_scrollboxes[i].vr^+1;
 for i:=0 to length(sg_scrollbars)-1  do sg_scrollbars [i].prev_vr:=sg_scrollbars [i].vr^+1;
 for i:=0 to length(sg_chkboxes)-1    do sg_chkboxes   [i].prev_vr:=not sg_chkboxes[i].vr^;
 for i:=0 to length(sg_inpboxes)-1    do sg_inpboxes   [i].prev_vr:=sg_inpboxes[i].vr^+' ';
 for i:=0 to length(sg_txtboxes)-1    do sg_txtboxes   [i].prev_vr:=sg_txtboxes[i].vr^+' ';
 for i:=0 to length(sg_labels)-1      do sg_labels     [i].upd:=true;
 for i:=0 to length(sg_buttons)-1     do sg_buttons    [i].prev_stat:=not sg_buttons[i].stat;
end;
//############################################################################//
procedure clear_gui;
var i:integer;
begin        
 ibxm:=false;
 cur_inputbox:=nil; 
 cur_inputbox_pos:=0;

 for i:=0 to length(sg_chkboxes)-1 do if sg_chkboxes[i]<>nil then dispose(sg_chkboxes[i]);
 for i:=0 to length(sg_buttons)-1 do dispose(sg_buttons[i]);
 for i:=0 to length(sg_scrollboxes)-1 do dispose(sg_scrollboxes[i]);
 for i:=0 to length(sg_scrollbars)-1 do dispose(sg_scrollbars[i]);
 for i:=0 to length(sg_labels)-1 do dispose(sg_labels[i]);
 for i:=0 to length(sg_scrollareas)-1 do dispose(sg_scrollareas[i]);
 
 for i:=0 to length(sg_inpboxes)-1 do begin
  if sg_inpboxes[i].alloc then dispose(sg_inpboxes[i].vr);
  dispose(sg_inpboxes[i]);
 end;
 for i:=0 to length(sg_txtboxes)-1 do begin
  if sg_txtboxes[i].alloc then dispose(sg_txtboxes[i].vr);
  dispose(sg_txtboxes[i]);
 end;

 setlength(sg_chkboxes,0);
 setlength(sg_txtboxes,0);
 setlength(sg_inpboxes,0);
 setlength(sg_buttons,0);
 setlength(sg_scrollboxes,0);
 setlength(sg_scrollbars,0);
 setlength(sg_scrollareas,0);
 setlength(sg_labels,0);
end;       
//############################################################################//
procedure rmnu_sizes(cg:psdi_grap_rec;out xs,ys,tyo:integer);
begin
 xs:=gcrxs(cg.intf.rmnu);
 ys:=gcrys(cg.intf.rmnu);
 tyo:=ys div 2-7;
end;
//############################################################################//
function add_clickbox(mn,pg:dword;x,y:integer;nam:string;lf:pcheckbox_type;vr:pboolean;oni:onevent_checkbox;par:dword=0):pcheckbox_type;
begin
 add_label(mn,pg,x*(menu_xs div 2)+5+cbx_size+5,data_off+cbx_size div 2+(cbx_size+5)*y,LB_LEFT,0,nam);
 result:=add_checkbox(mn,pg,x*(menu_xs div 2)+5,data_off+(cbx_size+5)*y,cbx_size,cbx_size,lf,vr,oni,par);
end;
//############################################################################//
function add_clickbox_3(mn,pg:dword;x,y:integer;nam:string;lf:pcheckbox_type;vr:pboolean;oni:onevent_checkbox;par:dword=0):pcheckbox_type;
begin
 add_label(mn,pg,x*(menu_xs div 3)+5+cbx_size+5,data_off+cbx_size div 2+(cbx_size+5)*y,LB_LEFT,0,nam);
 result:=add_checkbox(mn,pg,x*(menu_xs div 3)+5,data_off+(cbx_size+5)*y,cbx_size,cbx_size,lf,vr,oni,par);
end;   
//############################################################################//
function add_numeric_input(mn,pg:dword;x,y:integer;nam:string;step,ulim,llim:integer;vr:pinteger;event:onevent_scroll;par:dword):pscrollbox_type;
begin
 add_label(mn,pg,x,y,LB_LEFT,0,nam);
 add_inputbox(mn,pg,x,y+13,40,1,vr,nil,1,'');
 result:=add_scrollbox(mn,pg,SCB_HORIZONTAL,x+90-25,y+13,x+90,y+13,24,25,step,ulim,llim,false,vr,event,par);
end;
//############################################################################//
function add_text_input(mn,pg:dword;x,y,wid,typ:integer;nam:string;vr:pointer;oni:onevent_inputbox;par:dword;def:string):pinputbox_type;
begin
 add_label(mn,pg,x,y,LB_LEFT,0,nam);
 result:=add_inputbox(mn,pg,x,y+13,wid,typ,vr,oni,par,def);
end;
//############################################################################//
begin    
end.
//############################################################################//
