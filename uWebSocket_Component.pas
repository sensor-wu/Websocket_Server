{2020-04-29 ��ʼ����
 1. ��Ҫʹ�õ� Indy  TidTCPServer �ؼ���
 2. ��Ҫ�����߳����¼��ص�����
 3. ��Ҫ��¼ �������ӵ� AContext: TIdContext,�Ա�������������Ͽ�������Ϣ�ȵ�
 4. ��Ҫʹ�õ�������

 //ʵ�ʵ������źţ� Client�˷�������
    GET / HTTP/1.1
    Upgrade: websocket
    Connection: Upgrade
    Host: ssltest.local:3002
    Origin: http://127.0.0.1:8020
    Pragma: no-cache
    Cache-Control: no-cache
    Sec-WebSocket-Key: fS9cWqJVhWrwc8+4S3vj3A==
    Sec-WebSocket-Version: 13
    Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits, x-webkit-deflate-frame
    User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.138 Safari/537.36


     ����client �˵����ݣ��Ѿ����ֳɹ�
     0             1               2               3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-------+-+-------------+-------------------------------+
    |F|R|R|R| opcode|M| Payload len | Extended payload length |
    |I|S|S|S| (4) |A| (7) | (16/64) |
    |N|V|V|V| |S| | (if payload len==126/127) |
    | |1|2|3| |K| | |
    +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
    | Extended payload length continued, if payload len == 127 |
    + - - - - - - - - - - - - - - - +-------------------------------+
    | |Masking-key, if MASK set to 1 |
    +-------------------------------+-------------------------------+
    | Masking-key (continued) | Payload Data |
    +-------------------------------- - - - - - - - - - - - - - - - +
    : Payload Data continued ... :
    + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
    | Payload Data continued ... |
    +---------------------------------------------------------------+

    FIN : ��λָʾ�Ƿ��Ѵӿͻ��˷���������Ϣ�����һ����Ϣ����
    RSV1,RSV2,RSV3 : ��Щλ����Ϊ0������Э�����������ṩ����ֵ����չ��
    opcode : ��Щλ�������յ�����Ϣ���͡�������0x1��ʾ����һ���ı���Ϣ��
           0 : ��ʾ��һ��������Frame
           1 : ��ʾ��һ���ı���Ϣ
           2 : ��ʾ������Ϣ
           3-7 : ����
           8 : ��ʾһ�����ӹر�
           9 : һ��ping
           A : һ��pong
           B-F : ����  ���Զ��� �� B Client�˷��͵�FIN����1��

    M : �����Ƿ��������Ч�������ݡ����������Ϊ1���������а���������Կ�������ڽ������Ч�������ݡ������ݡ��ӿͻ��˵���������������Ϣ�������˴�λ��
    Payload Length : �����ֵ����0��125֮�䣬��Ϊ��Ϣ�ĳ��ȡ������126��������2���ֽڣ�16λ�޷����������ǳ��ȡ������127��������8���ֽڣ�64λ�޷����������ǳ��ȡ�


    ��������֡���ݵ�˵����
    ������Ϊ����Ƭ�η��͵��ı���Ϣ����һ��Ƭ�εĲ�����Ϊ0x1��FINλΪclear���ڶ���Ƭ�εĲ�����Ϊ0x0��FINλΪclear��
    ������Ƭ����һ��0x0�������һ��FINλ��˵�����������Ѿ�׼�����ˡ�

}
unit uWebSocket_Component;

interface

uses
  IdCustomTCPServer, IdTCPServer, IdContext,IdComponent,IdGlobal,   //���� TidTCPServer

  System.Hash,
  System.NetEncoding,
  System.RegularExpressions,       //���򣬱��룬Hash ��

  system.DateUtils,
  Vcl.ExtCtrls,   //Timer

  System.SysUtils, System.Classes;

const
  CWebSocket_KEY = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'; //��׼Ҫ���

type
  TClientInfo = record
    ClientIP      : string;
    ClientPort    : Word;
    ConnectTime   : TDateTime;     //���ӳɹ�ʱ��
    HandshakeTime : TDateTime;     //���ֳɹ�ʱ��
    ping_Timeout  : TDateTime;     //����ping����֮����Ҫ�����ʱ��֮ǰ�õ��ظ������û�еõ��ظ�������Ҫ�ҶϿͻ���   0:��ʾû�з���ping����

    R_Last_Text   : string;        //���һ�ν��յ����ı�����
    S_Last_Text   : string;        //���һ�η��͵�����

    R_Count       : integer;       //���յ���Ϣ����
    S_Count       : integer;       //���͵���Ϣ����

    ID            : string;        //Ψһ������  ��  ClientIP + ':' +  ClientPort
    DisConnect    : Boolean;       //�Ͽ��ͻ�������
    User_Agent    : string;
  end;
  //����һ�������ͻ���������Ϣ��ContextClass
  TMyContext = class(TIdServerContext)
    ClientInfo: TClientInfo;
  end;

  TOnStartup     = procedure(Sender : TObject) of object;    //�����������¼�
  TOnShutdown    = procedure(Sender : TObject) of object;    //�������ر��¼�
  TOnConnect     = procedure(ClientID : string) of object;
  TOnDisConnect  = procedure(ClientID : string) of object;
  TOnError       = procedure(ClientID : string; ErrorMsg : string) of object;
  TOnException   = procedure(Sender : TObject; ErrorMsg : string) of object;
  TOnHandhake    = procedure(ClientID : string; WebSocket_Key,WebSocket_Version,User_Agent : string) of object;
  TOnMessage     = procedure(ClientID : string; Text_Message : string) of object;
  TOnBinary      = procedure(ClientID : string; Bytes_Message : TBytes) of object;
  TOnPong        = procedure(ClientID : string; Text_Message : string) of object;


  TWebSocket = class(TComponent)
  private
    FIdTCPServer        : TIdTCPServer;   //indy��TCP������
    //��������
    FActive             : Boolean;   //�������Ƿ�����
    FWebPort            : Word;      //WebSocket�Ĵ򿪶˿�
    FVersion            : string;
    FHeartBeat          : Boolean;   //�Ƿ�����������Ĭ����False
    FInterval           : Word;      //�������ʱ�䣬��λ���룬Ĭ��60��
    FHandShakeTimeout   : Integer;      //��ʱʱ�䣬��λ�� ms
    FPingTimeout        : integer;      //��λ�Ǻ��룬 Ĭ��10 * 1000
    FReadTimeOut        : Word;     //�߳��У�������ݵ�ʱ������Ĭ����10���룬����CPUռ����ʱ��
    FMaxConnections     : integer;     //���������
    FConnectionList     : TStringList;

    FPingTimer          : TTimer;  //����ping �Ķ�ʱ��


    FOnStartup      : TOnStartup;    //�����������¼�
    FOnShutdown     : TOnShutdown;   //������ֹͣ�¼�
    FOnConnect      : TOnConnect;     //�ͻ������ӳɹ�
    FOnDisConnect   : TOnDisConnect;  //�ͻ��˶Ͽ�����
    FOnError        : TOnError;       //�������¼����������ִ���
    FOnException    : TOnException;   //TCPServer���쳣�¼�
    FOnHandhake     : TOnHandhake;     //���ֳɹ��¼�
    FOnMessage      : TOnMessage;     //�յ��ͻ�����Ϣ
    FOnBinary       : TOnBinary;      //��������Ϣ
    FOnPong         : TOnPong;    //Pong�¼�


    procedure SetWebPort(Value : Word);
    procedure SetVersion(Value : string);
    procedure SetHandShakeTimeout(Value : integer);
    procedure SetPingTimeout(Value : integer);
    procedure SetHeartBeat(Value : Boolean);
    procedure SetInterval(Value : Word);
    procedure SetReadTimeOut(Value : Word);
    procedure SetMaxConnections(Value : integer);

    //ping��ʱ�� �¼�
    procedure Ping_OnTimer(Sender: TObject);

    //���ֽ����������ֽ���
    function AppendBytes(const ABytes, BBytes: TBytes): TBytes;
    //�����ֽ���ת HEX�ַ���
    function Bytes_To_HexStr(Bytes: TBytes; Delia: string = ' '; BCount: Byte = 32): string;
    //�������ˣ����ݷ��͵����ݣ�����Э����Ҫ������
    function Build_WebSocketBytes(SourceData : TBytes; opcode : Byte = $01) : TBytes;

    //��ȡFIN,opcode �Ⱥ���, ͨ����һ���ֽ��ж�
    function Get_FIN_and_opcode(ClientData : TBytes; var opcode : Byte) : Boolean;    //ȡ��FIN,True��ʾ�Ѿ�����FIN��False��ʾû������FIN
    //��ȡ�ͻ���ʵ�ʵķ������ݣ���Ϊ�ֽ������أ�������
    function Get_ClientData(ClientData :TBytes) : TBytes;    //�õ����ܺ��ʵ������

    //�������ֺ���,������ֳɹ����򷵻�True�����򷵻�False, ͬʱ ErrorMsg�а���������Ϣ
    function Process_Handshake(Context : TIdContext; var ErrorMsg : string) : Boolean;
  protected
    //TidTCPServer �¼�������
    procedure IdTCPServer_Connect(AContext: TIdContext);
    procedure IdTCPServer_Disconnect(AContext: TIdContext);
    procedure IdTCPServer_ContextCreated(AContext: TIdContext);
    procedure IdTCPServer_Execute(AContext: TIdContext);
    procedure IdTCPServer_Exception(AContext: TIdContext;  AException: Exception);
    procedure IdTCPServer_Status(ASender: TObject; const AStatus: TIdStatus;  const AStatusText: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    //���⹫������
    procedure Start_WebSocketServer;     //����������
    procedure Stop_WebSocketServer;      //ֹͣ������
    procedure DisconnectAll;   //�Ͽ���������
    procedure ping(ClientID : string; Application_data : string = '');  //sends a ping to all connected clients. If a time-out is specified, it waits a response until a time-out is exceeded, if no response, then closes the connection.
    function Connections : TStringList;
    function Count : Word;
    function WriteBytes(const ClientID : string; Bytes_Message : TBytes; var ErrorMsg : string): Boolean;   //�����ֽ�������
    function WriteTexts(const ClientID : string; Text_Message : string; var ErrorMsg : string): Boolean;
    procedure Broadcast(Text_Message : string);   //�㲥��Ϣ�����пͻ��ˣ����ж��Ƿ�ɹ�

    function Get_ClientInfo(ClientID : string) : TClientInfo;
  published
    property Active           : Boolean read FActive;    //ָʾ������״̬
    property WebPort          : Word read FWebPort write SetWebPort;
    property Version          : string read FVersion;
    property HeartBeat        : Boolean read FHeartBeat write SetHeartBeat default False;
    property Interval         : Word read FInterval write SetInterval;
    property HandShakeTimeout : integer read FHandShakeTimeout write SetHandShakeTimeout;
    property PingTimeout      : integer read FPingTimeout write SetPingTimeout;
    property ReadTimeout      : Word read FReadTimeOut write SetReadTimeOut;
    property MaxConnections   : integer read FMaxConnections write SetMaxConnections;


    property OnStartup     : TOnStartup read FOnStartup write FOnStartup;
    property OnShutdown    : TOnShutdown read FOnShutdown write FOnShutdown;
    property OnConnect     : TOnConnect read FOnConnect write FOnConnect;
    property OnDisConnect  : TOnDisConnect read FOnDisConnect write FOnDisConnect;
    property OnError       : TOnError read FOnError write FOnError;
    property OnException   : TOnException read FOnException write FOnException;
    property OnHandShake   : TOnHandhake read FOnHandhake write FOnHandhake;
    property OnMessage     : TOnMessage read FOnMessage write FOnMessage;
    property OnBinary      : TOnBinary read FOnBinary write FOnBinary;
    property OnPong        : TOnPong read FOnPong write FOnPong;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('LW', [TWebSocket]);
end;

{ TWebSocket }

function TWebSocket.AppendBytes(const ABytes, BBytes: TBytes): TBytes;
var
  BLen, OldLen: Integer;
begin
  BLen := Length(BBytes);
  if BLen <= 0 then
    Exit;
  OldLen := Length(ABytes);
  SetLength(Result, OldLen + BLen);
  if OldLen > 0 then
     Move(ABytes[0], Result[0], OldLen);
  Move(BBytes[0], Result[OldLen], BLen);
end;

procedure TWebSocket.Broadcast(Text_Message: string);
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  if FIdTCPServer.Contexts = nil then Exit;
  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          //�ж��Ƿ����ֳɹ�
          if TMyContext(LContext).ClientInfo.HandshakeTime = 0 then
             Continue;

          B := TEncoding.UTF8.GetBytes(Text_Message);
          B := Build_WebSocketBytes(B);
          LContext.Connection.IOHandler.Write(TidBytes(B));
          //���·��ͼ���
          TMyContext(LContext).ClientInfo.S_Last_Text := Text_Message;
          TMyContext(LContext).ClientInfo.S_Count := TMyContext(LContext).ClientInfo.S_Count + 1;
        end;
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;

function TWebSocket.Build_WebSocketBytes(SourceData: TBytes; opcode : Byte = $01): TBytes;
var
  Len : Int64;
begin
  //1. ȡ�����ݳ���
  Len := Length(SourceData);
  if Len = 0 then Exit;

  if opcode > $0F then Exit;    //opcode ����Чֵ�� 0 - F

  //2. ������һ������opcode ���ֽ�
  if Len <= 125 then
     begin
       SetLength(Result, Len + 2);
       Result[0] := $80 + opcode ;//   $81;  //129  ��ʾ�����һ֡
       Result[1] := Len;  //ʵ�ʵ����ݳ���
       move(SourceData[0],Result[2],Len);
       Exit;
     end;

  if (Len > 125) and (Len <= 65535) then
     begin
       SetLength(Result, Len + 4);
       Result[0] := $80 + opcode ;// $81;  //129  ��ʾ�����һ֡
       Result[1] := 126;  //���������ֽڵ����ݳ���

       Result[2] := Len div 256;
       Result[3] := len mod 256;
       move(SourceData[0],Result[4],Len);
       Exit;
     end;

  if Len > 65535 then
     begin
       SetLength(Result, Len + 6);
       Result[0] := $80 + opcode ;// $81;  //129  ��ʾ�����һ֡
       Result[1] := 127;  //���������ֽڵ����ݳ���

       Result[2] := Len div (256 * 256 * 256);
       Result[3] := len mod (256 * 256);
       Result[4] := Len div 256;
       Result[5] := len mod 256;
       move(SourceData[0],Result[6],Len);
       Exit;
     end;

end;

function TWebSocket.Bytes_To_HexStr(Bytes: TBytes; Delia: string;
  BCount: Byte): string;
var
  RB: TBytes;
  i, j, Len: Integer;
  S: string;
begin
  if Length(Bytes) <= 0 then
    Exit('');

  SetLength(RB, Length(Bytes) * 2);

  BinToHex(Bytes, 0, RB, 0, Length(Bytes));

  S := TEncoding.ANSI.GetString(RB);
  Result := '';
  j := 0;
  // �ÿո�ֿ�
  Len := Length(S);
  for i := 1 to Len do
  begin
    if (i Mod 2) = 0 then
    begin
      Result := Result + S.Substring(i - 2, 2) + Delia;
      j := j + 1;
      if (j mod BCount) = 0 then
        Result := Result + #13#10;
    end;
  end;
end;

function TWebSocket.Connections: TStringList;
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  FConnectionList.Clear;
  Result := FConnectionList;
  if FIdTCPServer.Contexts = nil then Exit;
  LList := FIdTCPServer.Contexts.LockList;
    try
      FConnectionList.Clear;
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          FConnectionList.Append(TMyContext(LContext).ClientInfo.ID);
        end;
      Result := FConnectionList;
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;


function TWebSocket.Count: Word;
begin
  Result := FIdTCPServer.Contexts.Count;
end;

constructor TWebSocket.Create(AOwner: TComponent);
begin
  inherited;
  FVersion := '1.0.0.0';   //��ǰ�汾
  FWebPort := 80;   //Ĭ�϶˿ں�
  FHandShakeTimeout := 10;  //��ʱʱ�� 10��
  FPingTimeout := 10;  //��ʱʱ�� 10��
  FHeartBeat   := False;
  FInterval    := 60;    //ÿ��60�� ping �ͻ���һ��, ��С20
  FReadTimeOut := 10;  //��λ��ms
  FMaxConnections := 0;

  if not (csDesigning in ComponentState) then
    begin
      FConnectionList := TStringList.Create;
      //����TCP������
      FIdTCPServer    := TIdTCPServer.Create(nil);
      //���Ի������������ͻ�����Ϣ
      FIdTCPServer.ContextClass:= TMyContext;

      FIdTCPServer.MaxConnections := FMaxConnections;
      FIdTCPServer.DefaultPort      := FWebPort;
      FIdTCPServer.Active           := False;
      FIdTCPServer.OnConnect        := IdTCPServer_Connect;
      FIdTCPServer.OnDisconnect     := IdTCPServer_Disconnect;
      FIdTCPServer.OnContextCreated := IdTCPServer_ContextCreated;
      FIdTCPServer.OnExecute        := IdTCPServer_Execute;
      FIdTCPServer.OnException      := IdTCPServer_Exception;
      FIdTCPServer.OnStatus         := IdTCPServer_Status;

      FPingTimer         := TTimer.Create(nil);
      FPingTimer.Interval:= FInterval * 1000; //��ʱ����ʱ����
      FPingTimer.OnTimer := Ping_OnTimer
    end;
end;

destructor TWebSocket.Destroy;
begin
  if not (csDesigning in ComponentState) then
    begin
     if FIdTCPServer <> nil then
       FIdTCPServer.Free;
     FConnectionList.Free;

     FPingTimer.Free;
    end;
  inherited;
end;

procedure TWebSocket.DisconnectAll;
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  if not FActive then  Exit;

  if FIdTCPServer.Contexts = nil then Exit;
  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          TMyContext(LContext).ClientInfo.DisConnect := True;  //���ùر�����
        end;
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;


function TWebSocket.Get_ClientData(ClientData: TBytes): TBytes;
var
  MaskKEY : TBytes;      //������Կ��Ӧ����4���ֽ�
  Payload_Length,i : Int64;  //ʵ�ʵ����ݳ���
  M : Byte;
  B : Byte;
  Payload_Len  : Byte;
  dataPosition : Byte;
begin
  //1. �����ж϶�Mλ�Ƿ�Ϊ1�����������
  if Length(ClientData) <= 3 then
     raise Exception.Create('Err04,���ݳ��Ȳ���Ϊ0');
  B := ClientData[1];
  M := B shr 7;
  if M <> 1 then  //˵���ӿͻ��˷���������û�м��ܣ��ǲ���ȷ��
     raise Exception.Create('Err05,�ͻ������ݸ�ʽ����ȷ(û������λ)');

  //2. ���ݳ���
  Payload_Len := B - $80;
  SetLength(MaskKEY,4);
  case Payload_Len of
    126 :
      begin
        //��ȡ���ݳ���
        Payload_Length := 0;
        Payload_Length := ((Payload_Length or ClientData[2]) shl 8) or ClientData[3];
        move(ClientData[4],MaskKEY[0],4);      //MaskKEY
        dataPosition := 8;
      end;
    127 :
      begin
        //��ȡ���ݳ���
        Payload_Length := 0;
        for i := 2 to 8 do
          Payload_Length := (Payload_Length or ClientData[i]) shl 8;
        Payload_Length := Payload_Length or ClientData[9];

        move(ClientData[2],Payload_Length,8);
        move(ClientData[10],MaskKEY[0],4);
        dataPosition := 14;
      end
  else  //0-125
    Payload_Length := Payload_Len;
    move(ClientData[2],MaskKEY[0],4);
    dataPosition := 6;
  end;

  //��������
  SetLength(Result,Payload_Length);
  for i := 0 to Payload_Length - 1 do
    Result[i] := ClientData[i + dataPosition] xor MaskKEY[i mod 4];
end;

function TWebSocket.Get_ClientInfo(ClientID: string): TClientInfo;
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  if FIdTCPServer.Contexts = nil then Exit;
  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          if (TMyContext(LContext).ClientInfo.ID = ClientID) then
            begin
              Result := TMyContext(LContext).ClientInfo;
              Exit;
            end;
        end;
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;


function TWebSocket.Get_FIN_and_opcode(ClientData: TBytes; var opcode: Byte): Boolean;
var
  B : Byte;
begin
  //ֻ�жϵ�һ���ֽ�
  if Length(ClientData) <= 3 then
     raise Exception.Create('Err02,���ݳ��Ȳ���Ϊ0');

  //1. �����ж��Ƿ��������ʽ x000xxxx ����
  B := ClientData[0];
  B := B and $70;
  if B <> 0  then
    raise Exception.Create('Err03,�ͻ������ݸ�ʽ����ȷ');

  //2. ȡ��FINλ
  B := ClientData[0];
  B := B shr 7;
  Result := B = 1;
  //3. ȡ��opcode
  B := ClientData[0];
  opcode := B and $0F;
end;

procedure TWebSocket.IdTCPServer_Connect(AContext: TIdContext);
begin
  //�������ӳɹ��¼�
  if not Assigned(FOnConnect) then Exit;
  FOnConnect(AContext.Connection.Socket.Binding.PeerIP + ':' + AContext.Connection.Socket.Binding.PeerPort.ToString);
end;

procedure TWebSocket.IdTCPServer_ContextCreated(AContext: TIdContext);
begin
  //��ʼ���ͻ��˼�¼�ṹ����
  with TMyContext(AContext).ClientInfo do
     begin
       ClientIP   := AContext.Connection.Socket.Binding.PeerIP;
       ClientPort := AContext.Connection.Socket.Binding.PeerPort;
       ID         := ClientIP + ':' + ClientPort.ToString;
       ConnectTime:= Now;
       HandshakeTime := 0;   //û�����ֳɹ�,����ɹ��������ʾ�������ֳɹ���ʱ��
       ping_Timeout  := 0;   //����ping ״̬
       R_Last_Text   := '';
       S_Last_Text   := '';
       R_Count       := 0;
       S_Count       := 0;
       DisConnect    := False;
     end;
end;

procedure TWebSocket.IdTCPServer_Disconnect(AContext: TIdContext);
begin
  if not Assigned(FOnDisConnect) then Exit;
  FOnDisConnect(TMyContext(AContext).ClientInfo.ID);
end;

procedure TWebSocket.IdTCPServer_Exception(AContext: TIdContext;
  AException: Exception);
var
  ClientIP   : string;
  ClientPort : Word;
  ErrorMsg   : string;
begin
  if Assigned(FOnException) then
    begin
      clientIP   := AContext.Connection.Socket.BoundIP;
      clientPort := AContext.Connection.Socket.BoundPort;
      ErrorMsg := ClientIP + ':' + clientPort.ToString + #13#10 + AException.Message;
      FOnException(Self, ErrorMsg);
    end;
end;

procedure TWebSocket.IdTCPServer_Execute(AContext: TIdContext);
var
  ClientIP   : string;
  ClientPort : Word;
  len : int64;
  inBytes,outBytes : TBytes;
  S,sKey,sResponse : string;
  ErrorMsg : string;
  ClientID : string;

  FIN    : Boolean;
  opcode : Byte;

  FRB    : TBytes;     //����ֽ���
  Fopcode: Byte;

  Handhake_OK : Boolean;
  i : integer;
begin
  ClientID := AContext.Connection.Socket.Binding.PeerIP + ':' + AContext.Connection.Socket.Binding.PeerPort.ToString;
  Sleep(FReadTimeOut);   //���������� CPU��ռ��ʱ�䣬���Ǽ���ʵʱ�ԣ����� ���뼶�ǿ��Ժ��Ե�

  if TMyContext(AContext).ClientInfo.DisConnect then
     begin
       AContext.Connection.Disconnect;
       Exit;
     end;

  //1. �����ж��Ƿ��Ѿ����ֳɹ����жϱ�׼���Ƿ��Ѿ�������ʱ��
  if TMyContext(AContext).ClientInfo.HandshakeTime = 0 then
     if Process_Handshake(AContext,ErrorMsg) then   //���ֳɹ����޸�����ʱ��
        TMyContext(AContext).ClientInfo.handshakeTime := Now
     else     //����ʧ�ܣ��رտͻ������ӣ�ֱ���˳�
       begin
         AContext.Connection.Disconnect;
         Exit;
       end;

  //2. �ж��Ƿ���ping ��ִ��
  if TMyContext(AContext).ClientInfo.ping_Timeout <> 0 then
     if Now > TMyContext(AContext).ClientInfo.ping_Timeout then
        begin
          //��ʱδ�յ�ping�Ļظ����ҶϿͻ���
          AContext.Connection.Disconnect;
          Exit;
        end;

  //3. ���ֳɹ���������յ���Ϣ
  //ѭ��������Ϣ
  SetLength(FRB,0);
  //while True do
    begin
      //׼�����տͻ�������
      if AContext.Connection.IOHandler.InputBufferIsEmpty then
        begin
          AContext.Connection.IOHandler.CheckForDataOnSource(0);
          AContext.Connection.IOHandler.CheckForDisconnect;
          if AContext.Connection.IOHandler.InputBufferIsEmpty then Exit;
        end;

      Len := AContext.Connection.IOHandler.InputBuffer.Size;
      if Len <= 3 then Exit;;
      SetLength(inBytes,0);
      AContext.Connection.IOHandler.ReadBytes(TidBytes(inBytes),len ,False);

      FIN := Get_FIN_and_opcode(inBytes,opcode);
      if not FIN then
         case opcode of
            0 :   //��ʾ��һ��������Frame
                begin
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                  //Continue;
                end;
            1 :   //��ʾ��һ���ı���Ϣ
                begin
                  Fopcode := opcode;
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                  //Continue;
                end;
            2 :   //��ʾ������Ϣ
                begin
                  Fopcode := opcode;
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                  //Continue;
                end;
            3,4,5,6,7 : ; //����
            8 :   //��ʾһ�����ӹر�
                begin
                  AContext.Connection.Disconnect;  //�ر����ӣ�ֱ���˳�
                  Exit;
                end;
            9 :   //һ��ping
                begin

                end;
            $A :   //һ��pong
                begin
                  Fopcode := opcode;
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                end;
         end
      else   //˵���Ѿ�����
        begin
          outBytes := Get_ClientData(inBytes);
          if length(FRB) = 0 then
             Fopcode := opcode;
          FRB := AppendBytes(FRB,outBytes);
          case Fopcode of
            1 :  //�ı���Ϣ
              begin
                S := TEncoding.UTF8.GetString(FRB);
                if Assigned(FOnMessage) then
                   FOnMessage(ClientID,S);
                SetLength(FRB,0);
                //���½�����Ϣ����
                TMyContext(AContext).ClientInfo.R_Last_Text := S;
                TMyContext(AContext).ClientInfo.R_Count := TMyContext(AContext).ClientInfo.R_Count + 1;
              end;
            2 :  //����Ϣ
              begin
                if Assigned(FOnBinary) then
                   FOnBinary(ClientID,FRB);
                SetLength(FRB,0);
              end;
            9 :   //һ��ping
                begin

                end;
            $A:
              begin
                S := TEncoding.UTF8.GetString(FRB);
                if Assigned(FOnPong) then
                   FOnPong(ClientID,S);
                SetLength(FRB,0);
                //�޸�Ping�ĳ�ʱ
                TMyContext(AContext).ClientInfo.ping_Timeout := 0;   //����ִ�ɹ�
              end;
          end;
        end;
    end;
  
end;

procedure TWebSocket.IdTCPServer_Status(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: string);
begin

end;


procedure TWebSocket.ping(ClientID, Application_data: string);
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  if FIdTCPServer.Contexts = nil then Exit;
  if Application_data = '' then Application_data := FormatDateTime('YYYY-MM-DD hh:mm:ss zzz',Now);
  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          if (TMyContext(LContext).ClientInfo.ID = ClientID) then
            begin
              B := TEncoding.UTF8.GetBytes(Application_data);
              B := Build_WebSocketBytes(B,$09);   //pingָ��
              LContext.Connection.IOHandler.Write(TidBytes(B));

              //���ý���Pong��ʱ��
              TMyContext(LContext).ClientInfo.ping_Timeout := IncSecond(Now,FPingTimeout);
              Exit;
            end;
        end;
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;

procedure TWebSocket.Ping_OnTimer(Sender: TObject);
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  if FIdTCPServer.Contexts = nil then Exit;
  LList := FIdTCPServer.Contexts.LockList;
  try
    for i := 0 to LList.Count - 1 do
      begin
        //����Ѿ��ر��˶�ʱ�����������˳�
        if not FPingTimer.Enabled then Exit;

        LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
        B := TEncoding.UTF8.GetBytes('ping');
        B := Build_WebSocketBytes(B,$09);   //pingָ��
        LContext.Connection.IOHandler.Write(TidBytes(B));
        //���ý���Pong��ʱ��
        TMyContext(LContext).ClientInfo.ping_Timeout := IncSecond(Now,FPingTimeout);
      end;
  finally
    FIdTCPServer.Contexts.UnLockList;
  end;
end;

function TWebSocket.Process_Handshake(Context: TIdContext;
  var ErrorMsg: string): Boolean;
var
  inBytes  : TBytes;
  inString : string;
  inLen    : integer;
  tStart   : TDateTime;
  ClientID : string;

  WebSocket_Key     : string;
  WebSocket_Version : string;
  User_Agent        : string;
  Upgrade           : string;
  Connection        : string;

  sResponse         : string;
  outBytes          : TBytes;
  S : string;
begin
   //������ֳɹ����򷵻�True,���򷵻�����ʧ�� False
   //1. ���ȼ����յ������ݣ����ݳ��ȱ�������50
   ClientID   := Context.Connection.Socket.Binding.PeerIP + ':' + Context.Connection.Socket.Binding.PeerPort.ToString;
   tStart := Now;   //��ǰʱ��
   while true do
   begin
      //�����ʱ����ֱ�ӷ��ش���
      if SecondsBetween(Now,tStart) > FHandShakeTimeout then
         begin
           Result   := False;
           ErrorMsg := '�����źų�ʱ��';
           if Assigned(FOnError) then
              FOnError(ClientID,ErrorMsg);
           Exit;
         end;

      if Context.Connection.IOHandler.InputBufferIsEmpty then
        begin
          Context.Connection.IOHandler.CheckForDataOnSource(0);
          Context.Connection.IOHandler.CheckForDisconnect;
          if Context.Connection.IOHandler.InputBufferIsEmpty then Exit;
        end;

      inLen := Context.Connection.IOHandler.InputBuffer.Size;
      if inLen <= 50 then Continue;
      SetLength(inBytes,0);
      //��ȡ��ʵ�ʵ�����
      Context.Connection.IOHandler.ReadBytes(TidBytes(inBytes),inlen ,False);
      try
        inString := TEncoding.UTF8.GetString(inBytes);
        //1.�������ݽ���
        Upgrade           := TRegEx.Match(inString,'Upgrade: (.*)').Groups.Item[1].Value;
        Connection        := TRegEx.Match(inString,'Connection: (.*)').Groups.Item[1].Value;
        WebSocket_Key     := TRegEx.Match(inString,'Sec-WebSocket-Key: (.*)').Groups.Item[1].Value;
        WebSocket_Version := TRegEx.Match(inString,'Sec-WebSocket-Version: (.*)').Groups.Item[1].Value;
        User_Agent        := TRegEx.Match(inString,'User-Agent: (.*)').Groups.Item[1].Value;

        if (Upgrade <> 'websocket') or (Connection <> 'Upgrade') or (WebSocket_Key = '') then  //˵������WebSocketЭ�飬�˳�
           begin
             Result   := False;
             ErrorMsg := '�յ�����������������ȷ(δ���� WebSocket_Key �ֶ�)��';
             if Assigned(FOnError) then
               FOnError(ClientID,ErrorMsg);
             Exit;
           end;

        //2.���췵������
        sResponse := 'HTTP/1.1 101 Switching Protocols' + #13#10;
        sResponse := sResponse + 'Connection: Upgrade' + #13#10;
        sResponse := sResponse + 'Upgrade: websocket' + #13#10;

        outBytes := THashSHA1.GetHashBytes(UTF8String( Trim(WebSocket_Key) + CWebSocket_KEY ));
        S := TNetEncoding.Base64.EncodeBytesToString(outBytes);
        sResponse := sResponse + 'Sec-WebSocket-Accept: ' + S +#13#10#13#10;
        outBytes := TEncoding.UTF8.GetBytes(sResponse);
        Context.Connection.IOHandler.Write(TidBytes(outBytes),Length(outBytes));

        //�ͻ�����Ϣ
        TMyContext(Context).ClientInfo.User_Agent := User_Agent;

        if Assigned(FOnHandhake) then
           FOnHandhake(ClientID,WebSocket_Key,WebSocket_Version,User_Agent);
        //д�����ֳɹ�ʱ��
        Result := True;
        Break;
      except on E: Exception do
        begin
          Result   := False;
          ErrorMsg := '�յ�����������������ȷ(����UTF8�ַ���)��';
          if Assigned(FOnError) then
             FOnError(ClientID,ErrorMsg);
          Exit;
        end;
      end;
   end;
end;



procedure TWebSocket.SetHeartBeat(Value: Boolean);
begin
  FHeartBeat := Value;
  //��Ҫ���� �������
  if not (csDesigning in ComponentState) then
    if FIdTCPServer.Active then
       FPingTimer.Enabled := FHeartBeat;
end;

procedure TWebSocket.SetInterval(Value: Word);
begin
  if Value < 20 then Value := 20;
  FInterval := Value;
  //ˢ�¶�ʱ����ʱ����
  if not (csDesigning in ComponentState) then
     FPingTimer.Interval:= FInterval * 1000; //��ʱ����ʱ����
end;

procedure TWebSocket.SetMaxConnections(Value: integer);
begin
  if Value < 0 then Value := 0;
  FMaxConnections := Value;
  if not (csDesigning in ComponentState) then
     FIdTCPServer.MaxConnections := FMaxConnections;
end;

procedure TWebSocket.SetPingTimeout(Value: integer);
begin
  if Value <= 0 then  Value := 10;
  FPingTimeout := Value;
end;

procedure TWebSocket.SetReadTimeOut(Value: Word);
begin
  FReadTimeOut := Value;
end;

procedure TWebSocket.SetHandShakeTimeout(Value: integer);
begin
  if Value < 0 then Value := 20;
  FHandShakeTimeout := Value;
end;

procedure TWebSocket.SetVersion(Value: string);
begin
  FVersion := Value;
end;

procedure TWebSocket.SetWebPort(Value: Word);
begin
  FWebPort := Value;
end;

procedure TWebSocket.Start_WebSocketServer;
begin
  if FActive then Exit;
  FIdTCPServer.DefaultPort := FWebPort;  //���ô򿪶˿�
  try
    FIdTCPServer.Active := True;
    FActive := FIdTCPServer.Active;

    //�Ƿ�����ping��ʱ��
    FPingTimer.Enabled := FHeartBeat;

    //�����ɹ��¼�
    if Assigned(FOnStartup) then
       FOnStartup(Self);
  except on E: Exception do
    begin
      FActive := False;
      raise Exception.Create('Err001'#13#10 + E.Message);
    end;
  end;
end;

procedure TWebSocket.Stop_WebSocketServer;
begin
  if not FActive then Exit;
  FPingTimer.Enabled := False;
  sleep(200);
  DisconnectAll;
  Sleep(200);
  FPingTimer.Enabled := False;
  FIdTCPServer.Active := False;
  FActive := FIdTCPServer.Active;
  if Assigned(FOnShutdown) then  FOnShutdown(Self);
end;

function TWebSocket.WriteBytes(const ClientID: string; Bytes_Message: TBytes;
  var ErrorMsg: string): Boolean;
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  ErrorMsg := '��ǰû�����ӵĿͻ��ˣ�';
  if FIdTCPServer.Contexts = nil then Exit(False);

  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          if (TMyContext(LContext).ClientInfo.ID = ClientID) then
            begin
              //�ж��Ƿ����ֳɹ�
              if TMyContext(LContext).ClientInfo.HandshakeTime = 0 then
                 begin
                   ErrorMsg := '��ǰ������δ�������֣�';
                   Exit(False);
                 end;

              B := Build_WebSocketBytes(Bytes_Message,2);  //���͵����ֽ���
              LContext.Connection.IOHandler.Write(TidBytes(B));
              //���·��ͼ���
              TMyContext(LContext).ClientInfo.S_Last_Text := Bytes_To_HexStr(Bytes_Message);
              TMyContext(LContext).ClientInfo.S_Count := TMyContext(LContext).ClientInfo.S_Count + 1;

              Exit(True);
            end;
        end;
      ErrorMsg := 'δ��ѯ���ͻ���: ' + ClientID;
      Exit(False);
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;

function TWebSocket.WriteTexts(const ClientID: string; Text_Message: string;
  var ErrorMsg: string): Boolean;
var
  LContext: TIdContext;
  LList: TIdContextList;
  i : integer;
  B : TBytes;
begin
  ErrorMsg := '��ǰû�����ӵĿͻ��ˣ�';
  if FIdTCPServer.Contexts = nil then Exit(False);
  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          if (TMyContext(LContext).ClientInfo.ID = ClientID) then
            begin
              //�ж��Ƿ����ֳɹ�
              if TMyContext(LContext).ClientInfo.HandshakeTime = 0 then
                 begin
                   ErrorMsg := '��ǰ������δ�������֣�';
                   Exit(False);
                 end;
              B := TEncoding.UTF8.GetBytes(Text_Message);
              B := Build_WebSocketBytes(B);
              LContext.Connection.IOHandler.Write(TidBytes(B));
              //���·��ͼ���
              TMyContext(LContext).ClientInfo.S_Last_Text := Text_Message;
              TMyContext(LContext).ClientInfo.S_Count := TMyContext(LContext).ClientInfo.S_Count + 1;

              Exit(True);
            end;
        end;
      ErrorMsg := 'δ��ѯ���ͻ���: ' + ClientID;
      Exit(False);
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;

end.
