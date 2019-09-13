//############################################################################//
{$ifdef fpc}{$mode delphi}{$endif}
unit utf;
interface
uses asys;
//############################################################################//
const
koi8r_codes:array[0..127]of word=(
 $2500,$2502,$250C,$2510,$2514,$2518,$251C,$2524,$252C,$2534,$253C,$2580,$2584,$2588,$258C,$2590,
 $2591,$2592,$2593,$2320,$25A0,$2219,$221A,$2248,$2264,$2265,$00A0,$2321,$00B0,$00B2,$00B7,$00F7,
 $2550,$2551,$2552,$0451,$2553,$2554,$2555,$2556,$2557,$2558,$2559,$255A,$255B,$255C,$255D,$255E,
 $255F,$2560,$2561,$0401,$2562,$2563,$2564,$2565,$2566,$2567,$2568,$2569,$256A,$256B,$256C,$00A9,
 $044E,$0430,$0431,$0446,$0434,$0435,$0444,$0433,$0445,$0438,$0439,$043A,$043B,$043C,$043D,$043E,
 $043F,$044F,$0440,$0441,$0442,$0443,$0436,$0432,$044C,$044B,$0437,$0448,$044D,$0449,$0447,$044A,
 $042E,$0410,$0411,$0426,$0414,$0415,$0424,$0413,$0425,$0418,$0419,$041A,$041B,$041C,$041D,$041E,
 $041F,$042F,$0420,$0421,$0422,$0423,$0416,$0412,$042C,$042B,$0417,$0428,$042D,$0429,$0427,$042A
);
//############################################################################//
koi8u_codes:array[0..127]of word=(
 $2500,$2502,$250C,$2510,$2514,$2518,$251C,$2524,$252C,$2534,$253C,$2580,$2584,$2588,$258C,$2590,
 $2591,$2592,$2593,$2320,$25A0,$2219,$221A,$2248,$2264,$2265,$00A0,$2321,$00B0,$00B2,$00B7,$00F7,
 $2550,$2551,$2552,$0451,$0454,$2554,$0456,$0457,$2557,$2558,$2559,$255A,$255B,$0491,$255D,$255E,
 $255F,$2560,$2561,$0401,$0404,$2563,$0406,$0407,$2566,$2567,$2568,$2569,$256A,$0490,$256C,$00A9,
 $044E,$0430,$0431,$0446,$0434,$0435,$0444,$0433,$0445,$0438,$0439,$043A,$043B,$043C,$043D,$043E,
 $043F,$044F,$0440,$0441,$0442,$0443,$0436,$0432,$044C,$044B,$0437,$0448,$044D,$0449,$0447,$044A,
 $042E,$0410,$0411,$0426,$0414,$0415,$0424,$0413,$0425,$0418,$0419,$041A,$041B,$041C,$041D,$041E,
 $041F,$042F,$0420,$0421,$0422,$0423,$0416,$0412,$042C,$042B,$0417,$0428,$042D,$0429,$0427,$042A
);
//############################################################################//
cp866_codes:array[0..127]of word=(
 $0410,$0411,$0412,$0413,$0414,$0415,$0416,$0417,$0418,$0419,$041A,$041B,$041C,$041D,$041E,$041F,
 $0420,$0421,$0422,$0423,$0424,$0425,$0426,$0427,$0428,$0429,$042A,$042B,$042C,$042D,$042E,$042F,
 $0430,$0431,$0432,$0433,$0434,$0435,$0436,$0437,$0438,$0439,$043A,$043B,$043C,$043D,$043E,$043F,
 $2591,$2592,$2593,$2502,$2524,$2561,$2562,$2556,$2555,$2563,$2551,$2557,$255D,$255C,$255B,$2510,
 $2514,$2534,$252C,$251C,$2500,$253C,$255E,$255F,$255A,$2554,$2569,$2566,$2560,$2550,$256C,$2567,
 $2568,$2564,$2565,$2559,$2558,$2552,$2553,$256B,$256A,$2518,$250C,$2588,$2584,$258C,$2590,$2580,
 $0440,$0441,$0442,$0443,$0444,$0445,$0446,$0447,$0448,$0449,$044A,$044B,$044C,$044D,$044E,$044F,
 $0401,$0451,$0404,$0454,$0407,$0457,$040E,$045E,$00B0,$2219,$00B7,$221A,$2116,$00A4,$25A0,$00A0
);
//############################################################################//
cp1251_codes:array[0..127]of word=(
 $0402,$0403,$201A,$0453,$201E,$2026,$2020,$2021,$20AC,$2030,$0409,$2039,$040A,$040C,$040B,$040F,
 $0452,$2018,$2019,$201C,$201D,$2022,$2013,$2014,$0020,$2122,$0459,$203A,$045A,$045C,$045B,$045F,
 $00A0,$040E,$045E,$0408,$00A4,$0490,$00A6,$00A7,$0401,$00A9,$0404,$00AB,$00AC,$00AD,$00AE,$0407,
 $00B0,$00B1,$0406,$0456,$0491,$00B5,$00B6,$00B7,$0451,$2116,$0454,$00BB,$0458,$0405,$0455,$0457,
 $0410,$0411,$0412,$0413,$0414,$0415,$0416,$0417,$0418,$0419,$041A,$041B,$041C,$041D,$041E,$041F,
 $0420,$0421,$0422,$0423,$0424,$0425,$0426,$0427,$0428,$0429,$042A,$042B,$042C,$042D,$042E,$042F,
 $0430,$0431,$0432,$0433,$0434,$0435,$0436,$0437,$0438,$0439,$043A,$043B,$043C,$043D,$043E,$043F,
 $0440,$0441,$0442,$0443,$0444,$0445,$0446,$0447,$0448,$0449,$044A,$044B,$044C,$044D,$044E,$044F
);
//############################################################################//
cp1252_codes:array[0..127]of word=(
 $20AC,$0081,$201A,$0192,$201E,$2026,$2020,$2021,$02C6,$2030,$0160,$2039,$0152,$008D,$017D,$008F,
 $0090,$2018,$2019,$201C,$201D,$2022,$2013,$2014,$02DC,$2122,$0161,$203A,$0153,$009D,$017E,$0178,
 $00A0,$00A1,$00A2,$00A3,$00A4,$00A5,$00A6,$00A7,$00A8,$00A9,$00AA,$00AB,$00AC,$00AD,$00AE,$00AF,
 $00B0,$00B1,$00B2,$00B3,$00B4,$00B5,$00B6,$00B7,$00B8,$00B9,$00BA,$00BB,$00BC,$00BD,$00BE,$00BF,
 $00C0,$00C1,$00C2,$00C3,$00C4,$00C5,$00C6,$00C7,$00C8,$00C9,$00CA,$00CB,$00CC,$00CD,$00CE,$00CF,
 $00D0,$00D1,$00D2,$00D3,$00D4,$00D5,$00D6,$00D7,$00D8,$00D9,$00DA,$00DB,$00DC,$00DD,$00DE,$00DF,
 $00E0,$00E1,$00E2,$00E3,$00E4,$00E5,$00E6,$00E7,$00E8,$00E9,$00EA,$00EB,$00EC,$00ED,$00EE,$00EF,
 $00F0,$00F1,$00F2,$00F3,$00F4,$00F5,$00F6,$00F7,$00F8,$00F9,$00FA,$00FB,$00FC,$00FD,$00FE,$00FF
);
//############################################################################//
cp1256_codes:array[0..127]of word=(
 $20AC,$067E,$201A,$0192,$201E,$2026,$2020,$2021,$02C6,$2030,$0679,$2039,$0152,$0686,$0698,$0688,
 $06AF,$2018,$2019,$201C,$201D,$2022,$2013,$2014,$06A9,$2122,$0691,$203A,$0153,$200C,$200D,$06BA,
 $00A0,$060C,$00A2,$00A3,$00A4,$00A5,$00A6,$00A7,$00A8,$00A9,$06BE,$00AB,$00AC,$00AD,$00AE,$00AF,
 $00B0,$00B1,$00B2,$00B3,$00B4,$00B5,$00B6,$00B7,$00B8,$00B9,$061B,$00BB,$00BC,$00BD,$00BE,$061F,
 $06C1,$0621,$0622,$0623,$0624,$0625,$0626,$0627,$0628,$0629,$062A,$062B,$062C,$062D,$062E,$062F,
 $0630,$0631,$0632,$0633,$0634,$0635,$0636,$00D7,$0637,$0638,$0639,$063A,$0640,$0641,$0642,$0643,
 $00E0,$0644,$00E2,$0645,$0646,$0647,$0648,$00E7,$00E8,$00E9,$00EA,$00EB,$0649,$064A,$00EE,$00EF,
 $064B,$064C,$064D,$064E,$00F4,$064F,$0650,$00F7,$0651,$00F9,$0652,$00FB,$00FC,$200E,$200F,$06D2
);
//############################################################################//
iso_8859_5_codes:array[0..127]of word=(
 $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
 $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
 $00A0,$0401,$0402,$0403,$0404,$0405,$0406,$0407,$0408,$0409,$040A,$040B,$040C,$00AD,$040E,$040F,
 $0410,$0411,$0412,$0413,$0414,$0415,$0416,$0417,$0418,$0419,$041A,$041B,$041C,$041D,$041E,$041F,
 $0420,$0421,$0422,$0423,$0424,$0425,$0426,$0427,$0428,$0429,$042A,$042B,$042C,$042D,$042E,$042F,
 $0430,$0431,$0432,$0433,$0434,$0435,$0436,$0437,$0438,$0439,$043A,$043B,$043C,$043D,$043E,$043F,
 $0440,$0441,$0442,$0443,$0444,$0445,$0446,$0447,$0448,$0449,$044A,$044B,$044C,$044D,$044E,$044F,
 $2116,$0451,$0452,$0453,$0454,$0455,$0456,$0457,$0458,$0459,$045A,$045B,$045C,$00A7,$045E,$045F
);
//############################################################################//
iso_8859_1_codes:array[0..127]of word=(
 $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
 $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
 $00A0,$00A1,$00A2,$00A3,$00A4,$00A5,$00A6,$00A7,$00A8,$00A9,$00AA,$00AB,$00AC,$00AD,$00AE,$00AF,
 $00B0,$00B1,$00B2,$00B3,$00B4,$00B5,$00B6,$00B7,$00B8,$00B9,$00BA,$00BB,$00BC,$00BD,$00BE,$00BF,
 $00C0,$00C1,$00C2,$00C3,$00C4,$00C5,$00C6,$00C7,$00C8,$00C9,$00CA,$00CB,$00CC,$00CD,$00CE,$00CF,
 $00D0,$00D1,$00D2,$00D3,$00D4,$00D5,$00D6,$00D7,$00D8,$00D9,$00DA,$00DB,$00DC,$00DD,$00DE,$00DF,
 $00E0,$00E1,$00E2,$00E3,$00E4,$00E5,$00E6,$00E7,$00E8,$00E9,$00EA,$00EB,$00EC,$00ED,$00EE,$00EF,
 $00F0,$00F1,$00F2,$00F3,$00F4,$00F5,$00F6,$00F7,$00F8,$00F9,$00FA,$00FB,$00FC,$00FD,$00FE,$00FF
);
//############################################################################//
type utf_parse_rec=record
 s:string;
 p:integer;
 c:dword;
 error,eof,ok:boolean;
end;
//############################################################################//
function code_to_utf(w:word):string;
procedure parse_utf(var u:utf_parse_rec);
function utxt_get_len(text:string):integer;

function koi8r_to_utf(s:string):string;
function koi8u_to_utf(s:string):string;
function cp866_to_utf(s:string):string;
function cp1251_to_utf(s:string):string;
function cp1252_to_utf(s:string):string;
function cp1256_to_utf(s:string):string;
function iso_8859_5_to_utf(s:string):string;
function iso_8859_1_to_utf(s:string):string;

function utf_to_cp866(const s:string):string;
function utf_to_cp1251(const s:string):string;

function utf_to_u16(s:string):aword;
function utf_to_u16_no_cr(s:string):aword;
function u16_to_utf(const s:pworda;sz:integer):string;overload;
function u16_to_utf(const s:aword):string;overload;

function u16_getlsymp(const s:aword;sb:word):integer;
function u16_cmp(const a,b:aword):boolean;
function u16_add(const a,b:aword):aword;
function u16_copy(const a:aword;start,len:integer):aword;
//############################################################################//
implementation
//############################################################################//
procedure parse_utf(var u:utf_parse_rec);
var md,sp:integer;
b:byte;
begin
 u.c:=$FFFFFFFF;
 u.error:=false;
 u.ok:=false;
 u.eof:=u.p>length(u.s);
 if u.eof then exit;

 u.c:=0;
 md:=0;
 sp:=u.p;
 while true do begin
  u.eof:=u.p>length(u.s);
  if u.eof then begin u.error:=true;u.c:=$FFFFFFFF;exit;end;
  b:=ord(u.s[u.p]);
  u.p:=u.p+1;

  case md of
   0:begin
    if b<128 then begin u.c:=b;u.ok:=true;exit;end;
    if (b and $C0)=$80 then begin u.error:=true;u.c:=$FFFFFFFF;break;end;
    if (b and $E0)=$C0 then begin md:=1;u.c:=b and $1F;continue;end;
    if (b and $F0)=$E0 then begin md:=2;u.c:=b and $0F;continue;end;
    //if (b and $F1)=$F0 then begin md:=3;u.c:=b and $07;continue;end;     //To enable 32bit parsing
    u.error:=true;
    u.c:=$FFFFFFFF;
    break;
   end;
   1,2,3:begin
    if (b and $C0)<>$80 then begin u.error:=true;u.c:=$FFFFFFFF;break;end;
    u.c:=u.c shl 6;
    u.c:=u.c or (b and $3F);
    md:=md-1;
    if md<=0 then begin u.ok:=true;exit;end;
   end;
  end;
 end;
 if u.error then begin
  u.p:=sp+1;
  b:=ord(u.s[sp]);
  u.c:=$F800+b;
 end;
end;
//############################################################################//
function utxt_get_len(text:string):integer;
var u:utf_parse_rec;
begin
 result:=0;
 if length(text)=0 then exit;

 u.p:=1;
 u.s:=text;
 while true do begin
  parse_utf(u);
  if u.eof then exit;
  result:=result+1;
 end;
end;
//############################################################################//
function code_to_utf(w:word):string;
begin
 result:='?';
 case w of
  // $0000:result:=#$C0#$80;
  $0000:result:=char(w);
  $0001..$007F:result:=char(w);
  $0080..$07FF:begin setlength(result,2);byte(result[1]):=$C0 or (w shr 6);byte(result[2]):=$80 or (w and $3F); end;
  $0800..$F7FF,$F900..$FFFF:begin setlength(result,3);byte(result[1]):=$E0 or (w shr 12);byte(result[2]):=$80 or ((w shr 6) and $3F);byte(result[3]):=$80 or (w and $3F); end;
  $F800..$F8FF:result:=char(w-$F800);
 end;
end;
//############################################################################//
function koi8r_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(koi8r_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function koi8u_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(koi8u_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function cp866_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(cp866_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function cp1251_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(cp1251_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function cp1252_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(cp1252_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function cp1256_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(cp1256_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function iso_8859_1_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(iso_8859_1_codes[c-128]);
  end;
 end;
end;
//############################################################################//
function iso_8859_5_to_utf(s:string):string;
var i:integer;
c:byte;
begin
 result:='';
 for i:=1 to length(s) do begin
  c:=byte(s[i]);
  case c of
   $00..$7F:result:=result+code_to_utf(c);
   $80..$FF:result:=result+code_to_utf(iso_8859_5_codes[c-128]);
  end;
 end;
end;
//############################################################################/
function utf_to_cp866(const s:string):string;
var a:aword;
i,j:integer;
begin
 a:=utf_to_u16(s);
 setlength(result,length(a));
 for i:=0 to length(a)-1 do begin
  if a[i]>127 then for j:=0 to length(cp866_codes)-1 do if cp866_codes[j]=a[i] then begin a[i]:=128+j;break;end;
  result[i+1]:=chr(a[i]);
 end;
end;
//############################################################################/
function utf_to_cp1251(const s:string):string;
var a:aword;
i,j:integer;
begin
 a:=utf_to_u16(s);
 setlength(result,length(a));
 for i:=0 to length(a)-1 do begin
  if a[i]>127 then for j:=0 to length(cp1251_codes)-1 do if cp1251_codes[j]=a[i] then begin a[i]:=128+j;break;end;
  result[i+1]:=chr(a[i]);
 end;
end;
//############################################################################//
function utf_to_u16_main(s:string;drop_cr:boolean):aword;
var n:integer;
u:utf_parse_rec;
begin
 setlength(result,3*length(s));
 n:=0;

 u.p:=1;
 u.s:=s;
 while true do begin
  parse_utf(u);
  if u.eof then break;
  if drop_cr and (u.c=$0D)then continue;
  if n>=length(result) then setlength(result,n*2+1);
  result[n]:=u.c;
  n:=n+1;
 end;
 setlength(result,n);
end;
//############################################################################//
function utf_to_u16(s:string):aword;begin result:=utf_to_u16_main(s,false);end;
function utf_to_u16_no_cr(s:string):aword;begin result:=utf_to_u16_main(s,true);end;
//############################################################################//
function u16_to_utf(const s:pworda;sz:integer):string;overload;
var i:integer;
begin
 result:='';
 for i:=0 to sz-1 do result:=result+code_to_utf(s[i]);  //FIXME: SLOW!
end;
//############################################################################//
function u16_to_utf(const s:aword):string;overload;begin result:=u16_to_utf(@s[0],length(s));end;
//############################################################################//
function u16_getlsymp(const s:aword;sb:word):integer;
var i:integer;
begin
 result:=0;
 for i:=length(s)-1 downto 0 do if (s[i]=sb)or((sb=ord(' '))and(s[i]=9)) then begin result:=i+1; exit; end;
end;
//############################################################################//
function u16_cmp(const a,b:aword):boolean;
var i:integer;
begin
 result:=false;
 if length(a)<>length(b) then exit;
 for i:=0 to length(a)-1 do if a[i]<>b[i] then exit;
 result:=true;
end;
//############################################################################//
function u16_add(const a,b:aword):aword;
var i,k:integer;
begin
 result:=a;
 k:=length(a);
 setlength(result,k+length(b));
 for i:=0 to length(b)-1 do result[k+i]:=b[i];
end;
//############################################################################//
function u16_copy(const a:aword;start,len:integer):aword;
var i,k:integer;
begin
 k:=length(a);
 if start+len>k then len:=k-start+1;
 setlength(result,len);
 for i:=0 to len-1 do result[i]:=a[start-1+i];
end;
//############################################################################//
begin
end.
//############################################################################//
