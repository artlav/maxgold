//############################################################################//
{$ifdef FPC}{$MODE delphi}{$endif}
unit sound;
interface
uses asys;
//############################################################################//
type channel=record
 id:integer;
 run,loop,rec:boolean;
 fmt,rate,ch_cnt:integer;

 buf:pointer;
 len,pos:integer; //in samples

 vol:integer; //0..100
end;
pchannel=^channel;
//############################################################################//
function sound_init(dev:string;rate,chan:integer):boolean;
function sound_init_record(dev:string;rate,chan:integer):boolean;
procedure sound_deinit;
function sound_get_new_channel:pchannel;
procedure sound_ch_free(c:pchannel);

procedure sound_ch_pos(c:pchannel;pos:single);
procedure sound_ch_vol(c:pchannel;vol:single);

procedure sound_ch_set_loop(c:pchannel;loop:boolean);
procedure sound_ch_replay(c:pchannel);
procedure sound_ch_play(c:pchannel);
procedure sound_ch_record(c:pchannel);
procedure sound_ch_stop(c:pchannel);
procedure sound_ch_rewind(c:pchannel);

function sound_ch_is_play(c:pchannel):boolean;
function sound_ch_is_record(c:pchannel):boolean;

procedure normalize_flt_channel(ch:pchannel);
//############################################################################//
var sound_latency:double=0.2;  //Output latency, where applicable (i.e. win32)
//############################################################################//
implementation
//############################################################################//
//'default' for default device
function sound_init(dev:string;rate,chan:integer):boolean;
begin
 result:=false;
end;
//############################################################################//
function sound_init_record(dev:string;rate,chan:integer):boolean;
begin
 result:=false;
end;
//############################################################################//
procedure sound_deinit;
begin
end;
//############################################################################//
function sound_get_new_channel:pchannel;
begin
 result:=nil;
end;
//############################################################################//
procedure sound_ch_free(c:pchannel);
begin
end;
//############################################################################//
//pos in seconds
procedure sound_ch_pos(c:pchannel;pos:single);
begin
end;
//############################################################################//
//0..1, can go up to 10
procedure sound_ch_vol(c:pchannel;vol:single);
begin
end;
//############################################################################//
procedure sound_ch_set_loop(c:pchannel;loop:boolean);begin c.loop:=loop;end;
procedure sound_ch_play  (c:pchannel);begin c.run:=true;end;
procedure sound_ch_record(c:pchannel);begin c.rec:=true;end;
procedure sound_ch_stop  (c:pchannel);begin c.run:=false;c.rec:=false;end;
procedure sound_ch_rewind(c:pchannel);begin c.pos:=0;end;
procedure sound_ch_replay(c:pchannel);begin sound_ch_rewind(c);sound_ch_play(c);end;
//############################################################################//
function sound_ch_is_play(c:pchannel):boolean;begin result:=c.run;end;
function sound_ch_is_record(c:pchannel):boolean;begin result:=c.rec;end;
//############################################################################//
procedure normalize_flt_channel(ch:pchannel);
begin
end;
//############################################################################//
begin
end.
//############################################################################//
{

Todo:
-Callback-based channel
+recording support
+Windows support
-MAC support

}
//############################################################################//

