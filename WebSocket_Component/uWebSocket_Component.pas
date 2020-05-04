{2020-04-29 开始开发
 1. 需要使用到 Indy  TidTCPServer 控件；
 2. 需要处理线程中事件回调问题
 3. 需要记录 各个连接的 AContext: TIdContext,以便后续处理，包括断开，发信息等等
 4. 需要使用到正则函数

 //实际的握手信号， Client端发过来的
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


     分析client 端的数据，已经握手成功
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

    FIN : 此位指示是否已从客户端发送完整消息（最后一包消息）。
    RSV1,RSV2,RSV3 : 这些位必须为0，除非协商了向它们提供非零值的扩展。
    opcode : 这些位描述接收到的消息类型。操作码0x1表示这是一条文本消息。
           0 : 表示是一个连续的Frame
           1 : 表示是一条文本消息
           2 : 表示是流消息
           3-7 : 保留
           8 : 表示一个连接关闭
           9 : 一个ping
           A : 一个pong
           B-F : 保留  （自定义 ： B Client端发送的FIN不是1）

    M : 定义是否包含“有效加密数据”。如果设置为1，则数据中包含加密密钥，这用于解除“有效加密数据”的数据。从客户端到服务器的所有消息都设置了此位。
    Payload Length : 如果此值介于0和125之间，则为消息的长度。如果是126，则以下2个字节（16位无符号整数）是长度。如果是127，则以下8个字节（64位无符号整数）是长度。


    关于连续帧数据的说明：
    对于作为三个片段发送的文本消息，第一个片段的操作码为0x1，FIN位为clear；第二个片段的操作码为0x0，FIN位为clear，
    第三个片段有一个0x0操作码和一个FIN位，说明整个数据已经准备好了。

}
unit uWebSocket_Component;

interface

uses
  IdCustomTCPServer, IdTCPServer, IdContext,IdComponent,IdGlobal,   //关于 TidTCPServer

  System.Hash,
  System.NetEncoding,
  System.RegularExpressions,       //正则，编码，Hash 库

  system.DateUtils,
  Vcl.ExtCtrls,   //Timer

  System.SysUtils, System.Classes;

const
  CWebSocket_KEY = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'; //标准要求的

type
  TClientInfo = record
    ClientIP      : string;
    ClientPort    : Word;
    ConnectTime   : TDateTime;     //连接成功时间
    HandshakeTime : TDateTime;     //握手成功时间
    ping_Timeout  : TDateTime;     //发送ping命令之后，需要在这个时间之前得到回复，如果没有得到回复，则需要挂断客户端   0:表示没有发送ping命令

    R_Last_Text   : string;        //最后一次接收到的文本数据
    S_Last_Text   : string;        //最后一次发送的数据

    R_Count       : integer;       //接收的消息次数
    S_Count       : integer;       //发送的消息次数

    ID            : string;        //唯一的索引  是  ClientIP + ':' +  ClientPort
    DisConnect    : Boolean;       //断开客户端连接
    User_Agent    : string;
  end;
  //创建一个包含客户端连接信息的ContextClass
  TMyContext = class(TIdServerContext)
    ClientInfo: TClientInfo;
  end;

  TOnStartup     = procedure(Sender : TObject) of object;    //服务器启动事件
  TOnShutdown    = procedure(Sender : TObject) of object;    //服务器关闭事件
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
    FIdTCPServer        : TIdTCPServer;   //indy的TCP服务器
    //定义属性
    FActive             : Boolean;   //服务器是否启动
    FWebPort            : Word;      //WebSocket的打开端口
    FVersion            : string;
    FHeartBeat          : Boolean;   //是否允许心跳，默认是False
    FInterval           : Word;      //心跳间隔时间，单位是秒，默认60秒
    FHandShakeTimeout   : Integer;      //超时时间，单位： ms
    FPingTimeout        : integer;      //单位是毫秒， 默认10 * 1000
    FReadTimeOut        : Word;     //线程中，检查数据的时间间隔，默认是10毫秒，减少CPU占用用时间
    FMaxConnections     : integer;     //最大连接数
    FConnectionList     : TStringList;

    FPingTimer          : TTimer;  //进行ping 的定时器


    FOnStartup      : TOnStartup;    //服务器启动事件
    FOnShutdown     : TOnShutdown;   //服务器停止事件
    FOnConnect      : TOnConnect;     //客户端连接成功
    FOnDisConnect   : TOnDisConnect;  //客户端断开连接
    FOnError        : TOnError;       //错误发生事件，例如握手错误
    FOnException    : TOnException;   //TCPServer的异常事件
    FOnHandhake     : TOnHandhake;     //握手成功事件
    FOnMessage      : TOnMessage;     //收到客户端消息
    FOnBinary       : TOnBinary;      //二进制消息
    FOnPong         : TOnPong;    //Pong事件


    procedure SetWebPort(Value : Word);
    procedure SetVersion(Value : string);
    procedure SetHandShakeTimeout(Value : integer);
    procedure SetPingTimeout(Value : integer);
    procedure SetHeartBeat(Value : Boolean);
    procedure SetInterval(Value : Word);
    procedure SetReadTimeOut(Value : Word);
    procedure SetMaxConnections(Value : integer);

    //ping定时器 事件
    procedure Ping_OnTimer(Sender: TObject);

    //在字节流后增加字节流
    function AppendBytes(const ABytes, BBytes: TBytes): TBytes;
    //数据字节流转 HEX字符串
    function Bytes_To_HexStr(Bytes: TBytes; Delia: string = ' '; BCount: Byte = 32): string;
    //服务器端，根据发送的数据，生成协议需要的数据
    function Build_WebSocketBytes(SourceData : TBytes; opcode : Byte = $01) : TBytes;

    //获取FIN,opcode 等函数, 通过第一个字节判断
    function Get_FIN_and_opcode(ClientData : TBytes; var opcode : Byte) : Boolean;    //取得FIN,True表示已经设置FIN，False表示没有设置FIN
    //获取客户端实际的发送数据，作为字节流返回，掩码后的
    function Get_ClientData(ClientData :TBytes) : TBytes;    //得到解密后的实际数据

    //处理握手函数,如果握手成功，则返回True，否则返回False, 同时 ErrorMsg中包含错误信息
    function Process_Handshake(Context : TIdContext; var ErrorMsg : string) : Boolean;
  protected
    //TidTCPServer 事件处理函数
    procedure IdTCPServer_Connect(AContext: TIdContext);
    procedure IdTCPServer_Disconnect(AContext: TIdContext);
    procedure IdTCPServer_ContextCreated(AContext: TIdContext);
    procedure IdTCPServer_Execute(AContext: TIdContext);
    procedure IdTCPServer_Exception(AContext: TIdContext;  AException: Exception);
    procedure IdTCPServer_Status(ASender: TObject; const AStatus: TIdStatus;  const AStatusText: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    //对外公共方法
    procedure Start_WebSocketServer;     //启动服务器
    procedure Stop_WebSocketServer;      //停止服务器
    procedure DisconnectAll;   //断开所有连接
    procedure ping(ClientID : string; Application_data : string = '');  //sends a ping to all connected clients. If a time-out is specified, it waits a response until a time-out is exceeded, if no response, then closes the connection.
    function Connections : TStringList;
    function Count : Word;
    function WriteBytes(const ClientID : string; Bytes_Message : TBytes; var ErrorMsg : string): Boolean;   //发送字节数据流
    function WriteTexts(const ClientID : string; Text_Message : string; var ErrorMsg : string): Boolean;
    procedure Broadcast(Text_Message : string);   //广播消息给所有客户端，不判断是否成功

    function Get_ClientInfo(ClientID : string) : TClientInfo;
  published
    property Active           : Boolean read FActive;    //指示服务器状态
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
          //判断是否握手成功
          if TMyContext(LContext).ClientInfo.HandshakeTime = 0 then
             Continue;

          B := TEncoding.UTF8.GetBytes(Text_Message);
          B := Build_WebSocketBytes(B);
          LContext.Connection.IOHandler.Write(TidBytes(B));
          //更新发送计数
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
  //1. 取得数据长度
  Len := Length(SourceData);
  if Len = 0 then Exit;

  if opcode > $0F then Exit;    //opcode 的有效值是 0 - F

  //2. 构建第一个包含opcode 的字节
  if Len <= 125 then
     begin
       SetLength(Result, Len + 2);
       Result[0] := $80 + opcode ;//   $81;  //129  表示是最后一帧
       Result[1] := Len;  //实际的数据长度
       move(SourceData[0],Result[2],Len);
       Exit;
     end;

  if (Len > 125) and (Len <= 65535) then
     begin
       SetLength(Result, Len + 4);
       Result[0] := $80 + opcode ;// $81;  //129  表示是最后一帧
       Result[1] := 126;  //包含两个字节的数据长度

       Result[2] := Len div 256;
       Result[3] := len mod 256;
       move(SourceData[0],Result[4],Len);
       Exit;
     end;

  if Len > 65535 then
     begin
       SetLength(Result, Len + 6);
       Result[0] := $80 + opcode ;// $81;  //129  表示是最后一帧
       Result[1] := 127;  //包含两个字节的数据长度

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
  // 用空格分开
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
  FVersion := '1.0.0.0';   //当前版本
  FWebPort := 80;   //默认端口号
  FHandShakeTimeout := 10;  //超时时间 10秒
  FPingTimeout := 10;  //超时时间 10秒
  FHeartBeat   := False;
  FInterval    := 60;    //每隔60秒 ping 客户端一次, 最小20
  FReadTimeOut := 10;  //单位：ms
  FMaxConnections := 0;

  if not (csDesigning in ComponentState) then
    begin
      FConnectionList := TStringList.Create;
      //创建TCP服务器
      FIdTCPServer    := TIdTCPServer.Create(nil);
      //个性化创建，包含客户端信息
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
      FPingTimer.Interval:= FInterval * 1000; //定时器的时间间隔
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
          TMyContext(LContext).ClientInfo.DisConnect := True;  //设置关闭连接
        end;
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;


function TWebSocket.Get_ClientData(ClientData: TBytes): TBytes;
var
  MaskKEY : TBytes;      //掩码密钥，应该是4个字节
  Payload_Length,i : Int64;  //实际的数据长度
  M : Byte;
  B : Byte;
  Payload_Len  : Byte;
  dataPosition : Byte;
begin
  //1. 首先判断段M位是否为1，不是则错误
  if Length(ClientData) <= 3 then
     raise Exception.Create('Err04,数据长度不能为0');
  B := ClientData[1];
  M := B shr 7;
  if M <> 1 then  //说明从客户端发来的数据没有加密，是不正确的
     raise Exception.Create('Err05,客户端数据格式不正确(没有掩码位)');

  //2. 数据长度
  Payload_Len := B - $80;
  SetLength(MaskKEY,4);
  case Payload_Len of
    126 :
      begin
        //获取数据长度
        Payload_Length := 0;
        Payload_Length := ((Payload_Length or ClientData[2]) shl 8) or ClientData[3];
        move(ClientData[4],MaskKEY[0],4);      //MaskKEY
        dataPosition := 8;
      end;
    127 :
      begin
        //获取数据长度
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

  //解密数据
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
  //只判断第一个字节
  if Length(ClientData) <= 3 then
     raise Exception.Create('Err02,数据长度不能为0');

  //1. 首先判断是否符合数格式 x000xxxx 数据
  B := ClientData[0];
  B := B and $70;
  if B <> 0  then
    raise Exception.Create('Err03,客户端数据格式不正确');

  //2. 取得FIN位
  B := ClientData[0];
  B := B shr 7;
  Result := B = 1;
  //3. 取得opcode
  B := ClientData[0];
  opcode := B and $0F;
end;

procedure TWebSocket.IdTCPServer_Connect(AContext: TIdContext);
begin
  //发起连接成功事件
  if not Assigned(FOnConnect) then Exit;
  FOnConnect(AContext.Connection.Socket.Binding.PeerIP + ':' + AContext.Connection.Socket.Binding.PeerPort.ToString);
end;

procedure TWebSocket.IdTCPServer_ContextCreated(AContext: TIdContext);
begin
  //初始化客户端记录结构数据
  with TMyContext(AContext).ClientInfo do
     begin
       ClientIP   := AContext.Connection.Socket.Binding.PeerIP;
       ClientPort := AContext.Connection.Socket.Binding.PeerPort;
       ID         := ClientIP + ':' + ClientPort.ToString;
       ConnectTime:= Now;
       HandshakeTime := 0;   //没有握手成功,如果成功，这里表示的是握手成功的时间
       ping_Timeout  := 0;   //不是ping 状态
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

  FRB    : TBytes;     //结果字节流
  Fopcode: Byte;

  Handhake_OK : Boolean;
  i : integer;
begin
  ClientID := AContext.Connection.Socket.Binding.PeerIP + ':' + AContext.Connection.Socket.Binding.PeerPort.ToString;
  Sleep(FReadTimeOut);   //这样将减少 CPU的占用时间，但是减低实时性，不过 毫秒级是可以忽略的

  if TMyContext(AContext).ClientInfo.DisConnect then
     begin
       AContext.Connection.Disconnect;
       Exit;
     end;

  //1. 首先判断是否已经握手成功，判断标准是是否已经有握手时间
  if TMyContext(AContext).ClientInfo.HandshakeTime = 0 then
     if Process_Handshake(AContext,ErrorMsg) then   //握手成功，修改握手时间
        TMyContext(AContext).ClientInfo.handshakeTime := Now
     else     //握手失败，关闭客户端连接，直接退出
       begin
         AContext.Connection.Disconnect;
         Exit;
       end;

  //2. 判断是否有ping 在执行
  if TMyContext(AContext).ClientInfo.ping_Timeout <> 0 then
     if Now > TMyContext(AContext).ClientInfo.ping_Timeout then
        begin
          //超时未收到ping的回复，挂断客户端
          AContext.Connection.Disconnect;
          Exit;
        end;

  //3. 握手成功，处理接收的消息
  //循环接收消息
  SetLength(FRB,0);
  //while True do
    begin
      //准备接收客户端数据
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
            0 :   //表示是一个连续的Frame
                begin
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                  //Continue;
                end;
            1 :   //表示是一条文本消息
                begin
                  Fopcode := opcode;
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                  //Continue;
                end;
            2 :   //表示是流消息
                begin
                  Fopcode := opcode;
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                  //Continue;
                end;
            3,4,5,6,7 : ; //保留
            8 :   //表示一个连接关闭
                begin
                  AContext.Connection.Disconnect;  //关闭连接，直接退出
                  Exit;
                end;
            9 :   //一个ping
                begin

                end;
            $A :   //一个pong
                begin
                  Fopcode := opcode;
                  outBytes := Get_ClientData(inBytes);
                  FRB := AppendBytes(FRB,outBytes);
                end;
         end
      else   //说明已经结束
        begin
          outBytes := Get_ClientData(inBytes);
          if length(FRB) = 0 then
             Fopcode := opcode;
          FRB := AppendBytes(FRB,outBytes);
          case Fopcode of
            1 :  //文本消息
              begin
                S := TEncoding.UTF8.GetString(FRB);
                if Assigned(FOnMessage) then
                   FOnMessage(ClientID,S);
                SetLength(FRB,0);
                //更新接收消息计数
                TMyContext(AContext).ClientInfo.R_Last_Text := S;
                TMyContext(AContext).ClientInfo.R_Count := TMyContext(AContext).ClientInfo.R_Count + 1;
              end;
            2 :  //流消息
              begin
                if Assigned(FOnBinary) then
                   FOnBinary(ClientID,FRB);
                SetLength(FRB,0);
              end;
            9 :   //一个ping
                begin

                end;
            $A:
              begin
                S := TEncoding.UTF8.GetString(FRB);
                if Assigned(FOnPong) then
                   FOnPong(ClientID,S);
                SetLength(FRB,0);
                //修改Ping的超时
                TMyContext(AContext).ClientInfo.ping_Timeout := 0;   //本次执成功
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
              B := Build_WebSocketBytes(B,$09);   //ping指令
              LContext.Connection.IOHandler.Write(TidBytes(B));

              //设置接收Pong的时间
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
        //如果已经关闭了定时器，则立即退出
        if not FPingTimer.Enabled then Exit;

        LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
        B := TEncoding.UTF8.GetBytes('ping');
        B := Build_WebSocketBytes(B,$09);   //ping指令
        LContext.Connection.IOHandler.Write(TidBytes(B));
        //设置接收Pong的时间
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
   //如果握手成功，则返回True,否则返回握手失败 False
   //1. 首先检查接收到的数据，数据长度必须至少50
   ClientID   := Context.Connection.Socket.Binding.PeerIP + ':' + Context.Connection.Socket.Binding.PeerPort.ToString;
   tStart := Now;   //当前时间
   while true do
   begin
      //如果超时，则直接返回错误
      if SecondsBetween(Now,tStart) > FHandShakeTimeout then
         begin
           Result   := False;
           ErrorMsg := '握手信号超时！';
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
      //读取到实际的数据
      Context.Connection.IOHandler.ReadBytes(TidBytes(inBytes),inlen ,False);
      try
        inString := TEncoding.UTF8.GetString(inBytes);
        //1.进行数据解析
        Upgrade           := TRegEx.Match(inString,'Upgrade: (.*)').Groups.Item[1].Value;
        Connection        := TRegEx.Match(inString,'Connection: (.*)').Groups.Item[1].Value;
        WebSocket_Key     := TRegEx.Match(inString,'Sec-WebSocket-Key: (.*)').Groups.Item[1].Value;
        WebSocket_Version := TRegEx.Match(inString,'Sec-WebSocket-Version: (.*)').Groups.Item[1].Value;
        User_Agent        := TRegEx.Match(inString,'User-Agent: (.*)').Groups.Item[1].Value;

        if (Upgrade <> 'websocket') or (Connection <> 'Upgrade') or (WebSocket_Key = '') then  //说明不是WebSocket协议，退出
           begin
             Result   := False;
             ErrorMsg := '收到的握手数据流不正确(未包含 WebSocket_Key 字段)！';
             if Assigned(FOnError) then
               FOnError(ClientID,ErrorMsg);
             Exit;
           end;

        //2.构造返回数据
        sResponse := 'HTTP/1.1 101 Switching Protocols' + #13#10;
        sResponse := sResponse + 'Connection: Upgrade' + #13#10;
        sResponse := sResponse + 'Upgrade: websocket' + #13#10;

        outBytes := THashSHA1.GetHashBytes(UTF8String( Trim(WebSocket_Key) + CWebSocket_KEY ));
        S := TNetEncoding.Base64.EncodeBytesToString(outBytes);
        sResponse := sResponse + 'Sec-WebSocket-Accept: ' + S +#13#10#13#10;
        outBytes := TEncoding.UTF8.GetBytes(sResponse);
        Context.Connection.IOHandler.Write(TidBytes(outBytes),Length(outBytes));

        //客户端信息
        TMyContext(Context).ClientInfo.User_Agent := User_Agent;

        if Assigned(FOnHandhake) then
           FOnHandhake(ClientID,WebSocket_Key,WebSocket_Version,User_Agent);
        //写入握手成功时间
        Result := True;
        Break;
      except on E: Exception do
        begin
          Result   := False;
          ErrorMsg := '收到的握手数据流不正确(不是UTF8字符串)！';
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
  //需要启动 心跳检测
  if not (csDesigning in ComponentState) then
    if FIdTCPServer.Active then
       FPingTimer.Enabled := FHeartBeat;
end;

procedure TWebSocket.SetInterval(Value: Word);
begin
  if Value < 20 then Value := 20;
  FInterval := Value;
  //刷新定时器的时间间隔
  if not (csDesigning in ComponentState) then
     FPingTimer.Interval:= FInterval * 1000; //定时器的时间间隔
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
  FIdTCPServer.DefaultPort := FWebPort;  //设置打开端口
  try
    FIdTCPServer.Active := True;
    FActive := FIdTCPServer.Active;

    //是否启动ping定时器
    FPingTimer.Enabled := FHeartBeat;

    //启动成功事件
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
  ErrorMsg := '当前没有连接的客户端！';
  if FIdTCPServer.Contexts = nil then Exit(False);

  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          if (TMyContext(LContext).ClientInfo.ID = ClientID) then
            begin
              //判断是否握手成功
              if TMyContext(LContext).ClientInfo.HandshakeTime = 0 then
                 begin
                   ErrorMsg := '当前连接尚未进行握手！';
                   Exit(False);
                 end;

              B := Build_WebSocketBytes(Bytes_Message,2);  //发送的是字节流
              LContext.Connection.IOHandler.Write(TidBytes(B));
              //更新发送计数
              TMyContext(LContext).ClientInfo.S_Last_Text := Bytes_To_HexStr(Bytes_Message);
              TMyContext(LContext).ClientInfo.S_Count := TMyContext(LContext).ClientInfo.S_Count + 1;

              Exit(True);
            end;
        end;
      ErrorMsg := '未查询到客户端: ' + ClientID;
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
  ErrorMsg := '当前没有连接的客户端！';
  if FIdTCPServer.Contexts = nil then Exit(False);
  LList := FIdTCPServer.Contexts.LockList;
    try
      for i := 0 to LList.Count - 1 do
        begin
          LContext := {$IFDEF HAS_GENERICS_TList}LList.Items[i]{$ELSE}TIdContext(LList.Items[i]){$ENDIF};
          if (TMyContext(LContext).ClientInfo.ID = ClientID) then
            begin
              //判断是否握手成功
              if TMyContext(LContext).ClientInfo.HandshakeTime = 0 then
                 begin
                   ErrorMsg := '当前连接尚未进行握手！';
                   Exit(False);
                 end;
              B := TEncoding.UTF8.GetBytes(Text_Message);
              B := Build_WebSocketBytes(B);
              LContext.Connection.IOHandler.Write(TidBytes(B));
              //更新发送计数
              TMyContext(LContext).ClientInfo.S_Last_Text := Text_Message;
              TMyContext(LContext).ClientInfo.S_Count := TMyContext(LContext).ClientInfo.S_Count + 1;

              Exit(True);
            end;
        end;
      ErrorMsg := '未查询到客户端: ' + ClientID;
      Exit(False);
    finally
      FIdTCPServer.Contexts.UnLockList;
    end;
end;

end.
