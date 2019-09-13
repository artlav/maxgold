//############################################################################//
{$mode objfpc}
{$h+}
unit dns_unix;
{$WArN 5028 off:Local $1 "$2" is not used}
interface
uses baseunix,sockets;
//############################################################################//
type dns_info_rec=record
 ip:string;
 port:word;
 server:in_addr;
end;
//############################################################################//
const
maxresolveAddr=10;
maxrecursion=10;
timeout_sec=5;
//############################################################################//
var
dns_info:array of dns_info_rec;
//############################################################################//
function resolveHostByName(host:string;out addr:in_addr):boolean;
//############################################################################//
implementation
//############################################################################//
const
DNSQrY_A     = 1;                     // name to IP address
DNSQrY_AAAA  = 28;                    // name to IP6 address
DNSQrY_A6    = 38;                    // name to IP6 (new)
DNSQrY_PTr   = 12;                    // IP address to name
DNSQrY_MX    = 15;                    // name to MX
DNSQrY_TXT   = 16;                    // name to TXT
DNSQrY_CNAME = 5;

// Flags 1
QF_Qr     = $80;
QF_OPCODE = $78;
QF_AA     = $04;
QF_TC     = $02;  // Truncated.
QF_rD     = $01;

// Flags 2
QF_rA     = $80;
QF_Z      = $70;
QF_rCODE  = $0F;
//############################################################################//
type
TPayLoad =array[0..511] of byte;
TQueryData=packed record
 id     :array[0..1] of byte;
 flags1 :byte;
 flags2 :byte;
 qdcount:word;
 ancount:word;
 nscount:word;
 arcount:word;
 Payload:TPayLoad;
end;
//############################################################################//
TrrData=packed record       // rr record
 Atype   :word;            // Answer type
 AClass  :word;
 TTL     :dword;
 rDLength:word;
end;
PrrData = ^TrrData;
//############################################################################//
Function BuildPayLoad(out Q:TQueryData; Name:String; rr:word; QClass:word):Integer;
Var P:Pbyte;
l,S:Integer;
  
begin
  result:=-1;
  If length(Name)>506 then
    Exit;
  result:=0;  
  P:=@Q.Payload[0];
  repeat
    L:=Pos('.',Name);
    If (L=0) then
      S:=Length(Name)
    else
      S:=L-1;
    P[result]:=S;
    Move(Name[1],P[result+1],S);
    Inc(result,S+1);
    If (L>0) then
      Delete(Name,1,L);
  Until (L=0);
  P[result]:=0;
  rr := htons(rr);
  Move(rr,P[result+1],2);
  Inc(result,3);
  QClass := htons(QClass);
  Move(qclass,P[result],2);
  Inc(result,2);
end;



Function Nextrr(Const PayLoad:TPayLoad;Var Start:LongInt; AnsLen:LongInt; out rr:TrrData):Boolean;

Var
  I:Integer;
  HaveName:Boolean;
  PA:PrrData;
  
begin
  result:=False;
  I:=Start;
  // Skip labels and pointers. At least 1 label or pointer is present.
  repeat
    HaveName:=True;
    If (Payload[i]>63) then // Pointer, skip
      Inc(I,2)
    else If Payload[i]=0 then // Null termination of label, skip.
      Inc(i)
    else  
      begin
      Inc(I,Payload[i]+1); // Label, continue scan.
      HaveName:=False;
      end;
  Until HaveName or (I>(AnsLen-sizeof(TrrData)));
  result:=(I<=(AnsLen-sizeof(TrrData)));
  // Check rr record.
  PA:=PrrData(@Payload[i]);
  rr:=PA^;
  Start:=I+sizeof(TrrData);
end;
//############################################################################//
//QueryData handling functions
function CheckAnswer(const qry:TQueryData;var ans:TQueryData):Boolean;
begin
 result:=False;
 //Check ID.
 if (ans.ID[1]<>QrY.ID[1]) or (ans.ID[0]<>Qry.ID[0]) then exit;
 //Flags?
 if (ans.Flags1 and QF_Qr)=0 then exit;
 if (ans.Flags1 and QF_OPCODE)<>0 then  exit;
 if (ans.Flags2 and QF_rCODE)<>0 then exit;
 //Number of answers?
 ans.AnCount:=htons(ans.Ancount);
 If ans.Ancount<1 then exit;
 result:=True;
end;
//############################################################################//
function SkipAnsQueries(var Ans:TQueryData;L:integer):integer;
var q,i:Integer;
begin
 result:=0;
 ans.qdcount:=htons(ans.qdcount);
 i:=0;
 q:=0;
 while (Q<ans.qdcount) and (i<l) do begin
  if ans.payload[i]>63 then begin
   inc(i,6);
   inc(q);
  end else begin
   if ans.payload[i]=0 then begin
    inc(q);
    inc(i,5);
   end else inc(i,ans.payload[i]+1);
  end;
 end;
 result:=i;
end;
//############################################################################//
//DNS Query functions
//############################################################################//
function query(var Qry:TQueryData;out Ans:TQueryData;QryLen:Integer;out AnsLen:Integer):Boolean;
var SA:TInetSockAddr;
Sock,L,Al,rTO,i:integer;
readFDS:TFDSet;
success:boolean;  
begin
 result:=False;
 qry.ID[0]:=random(256);
 qry.ID[1]:=random(256);
 qry.Flags1:=QF_rD;
 qry.Flags2:=0;
 qry.qdcount:=htons(1); // was 1 shl 8;
 qry.ancount:=0;
 qry.nscount:=0;
 qry.arcount:=0;
              
 success:=false;
 for i:=0 to length(dns_info)-1 do begin
  sock:=FpSocket(PF_INET,SOCK_DGrAM,0);
  if sock=-1 then exit;

  sa.sin_family:=AF_INET;
  sa.sin_port:=htons(dns_info[i].port);
  sa.sin_addr.s_addr:=cardinal(dns_info[i].server);
  fpsendto(sock,@qry,qrylen+12,0,@sa,sizeof(sa));

  //Wait for answer.
  rTO:=timeout_sec*1000;
  fpFD_ZErO(readFDS);
  fpFD_Set(sock,readfds);
  if fpSelect(Sock+1,@readfds,Nil,Nil,rTO)<=0 then begin
   fpclose(Sock);
   continue;
  end;
  AL:=sizeof(SA);
  L:=fprecvfrom(Sock,@ans,sizeof(Ans),0,@SA,@AL);
  fpclose(Sock);
  success:=true;
  break;
 end;
 if not success then exit;

 //Check lenght answer and fields in header data.
 if (L<12) or not CheckAnswer(Qry,Ans) Then exit;

 //return Payload length.
 Anslen:=L-12;
 result:=True;
end;
//############################################################################//
function stringfromlabel(pl: TPayLoad; start: integer): string;
var l,i: integer;
begin
  result := '';
  l := 0;
  i := 0;
  repeat
    l := ord(pl[start]);
    { compressed reply }
    while (l >= 192) do
      begin
        { the -12 is because of the reply header length }
        start := (l and not(192)) shl 8 + ord(pl[start+1]) - 12;
        l := ord(pl[start]);
      end;
    if l <> 0 then begin
      setlength(result,length(result)+l);
      move(pl[start+1],result[i+1],l);
      result := result + '.';
      inc(start,l); inc(start);
      inc(i,l); inc(i);
    end;
  until l = 0;
  if result[length(result)] = '.' then setlength(result,length(result)-1);
end;

Function resolveNameAt(HostName:String; out Addresses:Array of in_addr; recurse: Integer):Integer;
Var
  Qry, Ans           :TQueryData;
  MaxAnswer,I,QryLen,
  AnsLen,AnsStart    :Longint;
  rr                 :TrrData;
  cname              :string;
begin
  result:=0;
  QryLen:=BuildPayLoad(Qry,HostName,DNSQrY_A,1);
  If Not Query(Qry,Ans,QryLen,AnsLen) then begin
    result:=-1;
    exit;
  end;

 AnsStart:=SkipAnsQueries(Ans,AnsLen);
 MaxAnswer:=Ans.AnCount-1;
 If MaxAnswer>High(Addresses) then MaxAnswer:=High(Addresses);
 I:=0;
 While (I<=MaxAnswer) and Nextrr(Ans.Payload,AnsStart,AnsLen,rr) do begin
  if htons(rr.AClass) = 1 then
    case ntohs(rr.AType) of
      DNSQrY_A: begin
       {$ifdef fpc}Addresses[i]:=default(in_addr);{$endif} //dewarning
       Move(Ans.PayLoad[AnsStart],Addresses[i],sizeof(in_addr));
       inc(result);
       Inc(AnsStart,htons(rr.rDLength));
      end;
      DNSQrY_CNAME: begin
       if recurse >= Maxrecursion then begin
        result := -1;
        exit;
       end;
       rr.rdlength := ntohs(rr.rdlength);
       setlength(cname, rr.rdlength);
       cname := stringfromlabel(ans.payload, ansstart);
       result := resolveNameAt(cname, Addresses, recurse+1);
       exit; // FIXME: what about other servers?!
      end;
    end;
    inc(I);
  end;  
end;
//############################################################################//
function resolveName(HostName:string;out addresses:array of in_addr):integer;
begin
 result:=resolveNameAt(HostName,Addresses,0);
end;
//############################################################################//
function resolveHostByName(host:string;out addr:in_addr):boolean;
var address:array[0..MaxresolveAddr-1] of in_addr;
n:integer;
begin
 n:=resolveName(host,address);
 result:=n>0;
 If result then addr:=address[0];
end;
//############################################################################//
procedure init_resolver;
var i:integer;
begin
 setlength(dns_info,3);
 dns_info[0].ip:='127.0.0.1';       //In case of local resolver
 dns_info[0].port:=53;
 dns_info[1].ip:='208.67.222.222';  //OpenDNS
 dns_info[1].port:=5353;            //Some bastards like AKADO block port 53
 dns_info[2].ip:='8.8.8.8';         //Google 
 dns_info[2].port:=53;
 for i:=0 to length(dns_info)-1 do dns_info[i].server:=HostToNet(StrToHostAddr(dns_info[i].ip));
end;
//############################################################################//
begin
 init_resolver;
end.
//############################################################################//
