unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uWebSocket_Component, Vcl.ExtCtrls,
  ShellAPI,
  Vcl.StdCtrls, System.Actions, Vcl.ActnList, Vcl.Buttons, Vcl.Samples.Spin,
  Vcl.Menus;

type
  TForm4 = class(TForm)
    WebSocket1: TWebSocket;
    Panel_Button: TPanel;
    Panel_Client: TPanel;
    Panel_Connections: TPanel;
    Panel1: TPanel;
    Label1: TLabel;
    Splitter1: TSplitter;
    Panel_Memo: TPanel;
    Panel2: TPanel;
    ActionList1: TActionList;
    Action_StartServer: TAction;
    Action_StopServer: TAction;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Action_WriteTexts: TAction;
    Action_Broadcast: TAction;
    Action_ping: TAction;
    SpeedButton4: TSpeedButton;
    Action_DisconnectAll: TAction;
    SpeedButton6: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton5: TSpeedButton;
    Memo_Message: TMemo;
    Label_HandShakeTimeout: TLabel;
    SpinEdit_HandShakeTimeout: TSpinEdit;
    Label_WebPort: TLabel;
    SpinEdit_WebPort: TSpinEdit;
    Label_Interval: TLabel;
    SpinEdit_Interval: TSpinEdit;
    Label_MaxConnections: TLabel;
    SpinEdit_MaxConnections: TSpinEdit;
    Label_PingTimeout: TLabel;
    SpinEdit_PingTimeout: TSpinEdit;
    Label_ReadTimeout: TLabel;
    SpinEdit_ReadTimeout: TSpinEdit;
    CheckBox_HeartBeat: TCheckBox;
    Panel3: TPanel;
    Panel4: TPanel;
    Label_Client: TLabel;
    ListBox1: TListBox;
    Panel5: TPanel;
    Panel6: TPanel;
    Label_Message: TLabel;
    Memo_Log: TMemo;
    SpeedButton7: TSpeedButton;
    Action_Clear: TAction;
    SpeedButton8: TSpeedButton;
    Action_OpenIE: TAction;
    Timer1: TTimer;
    Action_ClientInfo: TAction;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    procedure Action_StartServerExecute(Sender: TObject);
    procedure Action_StopServerExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpinEdit_HandShakeTimeoutChange(Sender: TObject);
    procedure Action_OpenIEExecute(Sender: TObject);
    procedure WebSocket1Connect(ClientID: string);
    procedure WebSocket1DisConnect(ClientID: string);
    procedure SpeedButton7Click(Sender: TObject);
    procedure Action_WriteTextsExecute(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure WebSocket1Message(ClientID, Text_Message: string);
    procedure WebSocket1HandShake(ClientID, WebSocket_Key, WebSocket_Version,
      User_Agent: string);
    procedure WebSocket1Pong(ClientID, Text_Message: string);
    procedure WebSocket1Startup(Sender: TObject);
    procedure WebSocket1Shutdown(Sender: TObject);
    procedure WebSocket1Error(ClientID, ErrorMsg: string);
    procedure WebSocket1Exception(Sender: TObject; ErrorMsg: string);
    procedure Action_BroadcastExecute(Sender: TObject);
    procedure Action_pingExecute(Sender: TObject);
    procedure Action_DisconnectAllExecute(Sender: TObject);
    procedure Action_ClearExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Action_ClientInfoExecute(Sender: TObject);
  private
    //刷新界面
    procedure RefreshUI;
    procedure Save_Params;
    procedure Load_Params;
    //2020-02-27 释放资源文件函数
    // 2017-12-04  释放资源文件
    // 释放出资源文件
    // 入口参数：
    // ResFileName: 资源文件名称
    // ReleaseFile: 需要释放的文件，包含目标路径以及文件名称
    // isOverride : 表示是否覆盖
    // 出口参数：
    // 把资源文件名称ResFileName 释放到 ReleaseFile中
    procedure ReleaseFile_FromResource(ResFileName, ReleaseFile: string; isOverride: Boolean = False);
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.Action_BroadcastExecute(Sender: TObject);
begin
  WebSocket1.Broadcast(Memo_Message.Text);
  Memo_Log.Lines.Add('广播消息发送: ' + Memo_Message.Text) ;
end;

procedure TForm4.Action_ClearExecute(Sender: TObject);
begin
  Memo_Log.Clear;
  RefreshUI;
end;

procedure TForm4.Action_ClientInfoExecute(Sender: TObject);
var
  ClientID   : string;
  ClientInfo : TClientInfo;
  ItemIndex  : integer;
  S : string;
begin
  ItemIndex := ListBox1.ItemIndex;
  if ItemIndex = -1 then Exit;
  ClientID := ListBox1.Items[ItemIndex];
  ClientInfo := WebSocket1.Get_ClientInfo(ClientID);

  S := #13#10'----- 客户端信息 -----'#13#10;
  S := S + 'ClientID: ' + ClientID + #13#10;
  S := S + '    User_Agent: ' + ClientInfo.User_Agent + #13#10;
  S := S + '      ClientIP: ' + ClientInfo.ClientIP + #13#10;
  S := S + '    ClientPort: ' + ClientInfo.ClientPort.ToString + #13#10;
  S := S + '   ConnectTime: ' +  FormatDateTime('YYYY-MM-DD hh:mm:ss zzz', ClientInfo.ConnectTime) + #13#10;
  S := S + ' HandshakeTime: ' +  FormatDateTime('YYYY-MM-DD hh:mm:ss zzz', ClientInfo.HandshakeTime) + #13#10;
  S := S + '  ping_Timeout: ' +  FormatDateTime('YYYY-MM-DD hh:mm:ss zzz', ClientInfo.ping_Timeout) + #13#10;
  S := S + '   R_Last_Text: ' + ClientInfo.R_Last_Text + #13#10;
  S := S + '   S_Last_Text: ' + ClientInfo.S_Last_Text + #13#10;
  S := S + '       R_Count: ' + ClientInfo.R_Count.ToString + #13#10;
  S := S + '       S_Count: ' + ClientInfo.S_Count.ToString + #13#10 + #13#10;

  Memo_Log.Lines.Add(S);
end;

procedure TForm4.Action_DisconnectAllExecute(Sender: TObject);
begin
  WebSocket1.DisconnectAll;
  Memo_Log.Lines.Add('发送DiscannectALL,断开所有连接！' ) ;
  RefreshUI;
end;

procedure TForm4.Action_OpenIEExecute(Sender: TObject);
begin
  Shellexecute(handle,nil,'"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"',PWideChar( '"' + ExtractFilePath(ParamStr(0)) + 'index.html"'),nil,sw_normal)
end;

procedure TForm4.Action_pingExecute(Sender: TObject);
begin
  WebSocket1.ping(ListBox1.Items[ListBox1.ItemIndex],'szhn');
  Memo_Log.Lines.Add('发送ping(' + ListBox1.Items[ListBox1.ItemIndex] + '): szhn' ) ;
end;

procedure TForm4.Action_StartServerExecute(Sender: TObject);
begin
  //准备参数
  WebSocket1.WebPort          := SpinEdit_WebPort.Value;
  WebSocket1.HandShakeTimeout := SpinEdit_HandShakeTimeout.Value;
  WebSocket1.Interval         := SpinEdit_Interval.Value;
  WebSocket1.PingTimeout      := SpinEdit_PingTimeout.Value;
  WebSocket1.ReadTimeout      := SpinEdit_ReadTimeout.Value;
  WebSocket1.MaxConnections   := SpinEdit_MaxConnections.Value;

  WebSocket1.HeartBeat        :=CheckBox_HeartBeat.Checked;
  //启动服务
  WebSocket1.Start_WebSocketServer;

  if WebSocket1.Active then
     begin
       Memo_Log.Clear;
       Memo_Log.Lines.Add('WebSocket 服务已经打开，端口: ' + SpinEdit_WebPort.Value.ToString + '  可以直接通过WebSocket客户端连接');
     end;

  Timer1.Enabled := True;   
  RefreshUI;
end;

procedure TForm4.Action_StopServerExecute(Sender: TObject);
begin
  WebSocket1.Stop_WebSocketServer;
  RefreshUI;
  Application.ProcessMessages;
  sleep(200);
  Application.ProcessMessages;
  ListBox1.Clear;

  Timer1.Enabled := False;   
end;

procedure TForm4.Action_WriteTextsExecute(Sender: TObject);
var
  ErrorMsg : string;
  ClientID : string;
  
begin
  ClientID := ListBox1.Items[ListBox1.ItemIndex];
  if WebSocket1.WriteTexts(ClientID,Memo_Message.Text,ErrorMsg) then 
     Memo_Log.Lines.Add('发送消息(' + ClientID + '): ' + Memo_Message.Text )
   else
     Memo_Log.Lines.Add('发送消息(' + ClientID + ')失败！') ;
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
  ReleaseFile_FromResource('index_html', ExtractFilePath(ParamStr(0)) + 'index.html');
  Load_Params;
end;

procedure TForm4.FormShow(Sender: TObject);
begin
  RefreshUI;
end;

procedure TForm4.ListBox1Click(Sender: TObject);
begin
  RefreshUI;
end;

procedure TForm4.Load_Params;
var
  TL : TStringList;
  FileName : string;
begin
  FileName := ChangeFileExt(ParamStr(0),'.INI');
  if not FileExists(FileName) then Exit;
  TL := TStringList.Create;
  try
    TL.LoadFromFile(FileName);
    SpinEdit_HandShakeTimeout.Value := TL.Values['HandShakeTimeOut'].ToInteger;
    SpinEdit_WebPort.Value          := TL.Values['WebPort'].ToInteger;
    SpinEdit_Interval.Value         := TL.Values['Interval'].ToInteger;
    SpinEdit_MaxConnections.Value   := TL.Values['MaxConnections'].ToInteger;
    SpinEdit_PingTimeout.Value      := TL.Values['PingTimeout'].ToInteger;
    SpinEdit_ReadTimeout.Value      := TL.Values['ReadTimeout'].ToInteger;

    CheckBox_HeartBeat.Checked      := TL.Values['HeartBeat'] = 'true';
  finally
    TL.Free;
  end;
end;

procedure TForm4.RefreshUI;
begin
  Action_StartServer.Enabled  := not WebSocket1.Active;
  Action_StopServer.Enabled   := WebSocket1.Active;
  Action_WriteTexts.Enabled   := WebSocket1.Active and (WebSocket1.Count > 0) and (ListBox1.ItemIndex <> -1);
  Action_Broadcast.Enabled    := WebSocket1.Active and (WebSocket1.Count > 0);
  Action_ping.Enabled         := WebSocket1.Active and (WebSocket1.Count > 0) and (ListBox1.ItemIndex <> -1);
  Action_Clear.Enabled        := Memo_Log.Text <> '';
  Action_DisconnectAll.Enabled:= WebSocket1.Active and (WebSocket1.Count > 0);
  Action_OpenIE.Enabled       := WebSocket1.Active;


  Label_HandShakeTimeout.Enabled    := not WebSocket1.Active;
  SpinEdit_HandShakeTimeout.Enabled := not WebSocket1.Active;

  Label_WebPort.Enabled             := not WebSocket1.Active;
  SpinEdit_WebPort.Enabled          := not WebSocket1.Active;

  Label_Interval.Enabled   := not WebSocket1.Active;
  SpinEdit_Interval.Enabled:= not WebSocket1.Active;

  Label_MaxConnections.Enabled    := not WebSocket1.Active;
  SpinEdit_MaxConnections.Enabled := not WebSocket1.Active;

  Label_PingTimeout.Enabled   := not WebSocket1.Active;
  SpinEdit_PingTimeout.Enabled:= not WebSocket1.Active;

  Label_ReadTimeout.Enabled   := not WebSocket1.Active;
  SpinEdit_ReadTimeout.Enabled:= not WebSocket1.Active;

  CheckBox_HeartBeat.Enabled  := not WebSocket1.Active;

  Memo_Message.Enabled        := WebSocket1.Active;

  Label_Client.Enabled        := WebSocket1.Active;
  ListBox1.Enabled            := WebSocket1.Active;

  Label_Message.Enabled       := WebSocket1.Active;
end;

procedure TForm4.ReleaseFile_FromResource(ResFileName, ReleaseFile: string;
  isOverride: Boolean);
var
  ResName: string;
  ResStream: TResourceStream;
begin
  // 如果不需要覆盖，而且已经存在，则直接退出
  if FileExists(ReleaseFile) then
    if not isOverride then
      Exit;
  // 资源文件名称
  ResName := ResFileName;
  // 如果资源文件不存在，则直接退出
  if FindResource(HInstance, PChar(ResName), RT_RCDATA) = 0 then
    Exit;

  // 释放资源文件
  ResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  try
    ResStream.SaveToFile(ReleaseFile);
  finally
    ResStream.Free;
  end;

end;

procedure TForm4.Save_Params;
var
  TL : TStringList;
  FileName : string;
begin
  TL := TStringList.Create;
  try
     TL.Clear;
     TL.AddPair('HandShakeTimeOut',SpinEdit_HandShakeTimeout.Value.ToString);
     TL.AddPair('WebPort',SpinEdit_WebPort.Value.ToString);
     TL.AddPair('Interval',SpinEdit_Interval.Value.ToString);
     TL.AddPair('MaxConnections',SpinEdit_MaxConnections.Value.ToString);
     TL.AddPair('PingTimeout',SpinEdit_PingTimeout.Value.ToString);
     TL.AddPair('ReadTimeout',SpinEdit_ReadTimeout.Value.ToString);


     if CheckBox_HeartBeat.Checked then
        TL.AddPair('HeartBeat','true')
     else
        TL.AddPair('HeartBeat','false');

     FileName := ChangeFileExt(ParamStr(0),'.INI');
     TL.SaveToFile(FileName);

  finally
    TL.Free;
  end;
end;

procedure TForm4.SpeedButton7Click(Sender: TObject);
begin
  Memo_Log.Clear;
  RefreshUI;
end;

procedure TForm4.SpinEdit_HandShakeTimeoutChange(Sender: TObject);
begin
  Save_Params;
end;

procedure TForm4.Timer1Timer(Sender: TObject);
begin
  if not WebSocket1.Active then Exit;
  RefreshUI;
  if WebSocket1.Count = 0 then  ListBox1.Clear;

  Label_Client.Caption := '当前有效客户端: ' + WebSocket1.Count.ToString ;
  
end;

procedure TForm4.WebSocket1Connect(ClientID: string);
begin
  Memo_Log.Lines.Add('===客户端成功: ' + ClientID);

  ListBox1.Items.Text := WebSocket1.Connections.Text;

  RefreshUI;
end;

procedure TForm4.WebSocket1DisConnect(ClientID: string);
var
  ItemIndex : integer;
begin
  Memo_Log.Lines.Add('  xxx客户端断开: ' + ClientID);

  ItemIndex := ListBox1.Items.IndexOf(ClientID);
  ListBox1.Items.Delete(ItemIndex);

  Application.ProcessMessages;
  
  RefreshUI;
end;

procedure TForm4.WebSocket1Error(ClientID, ErrorMsg: string);
begin
  Memo_Log.Lines.Add('出现错误(' + ClientID + '): ' + ErrorMsg);
end;

procedure TForm4.WebSocket1Exception(Sender: TObject; ErrorMsg: string);
begin
  Memo_Log.Lines.Add('   xxxxx 出现异常: ' + ErrorMsg);
end;

procedure TForm4.WebSocket1HandShake(ClientID, WebSocket_Key, WebSocket_Version,
  User_Agent: string);
begin
  Memo_Log.Lines.Add('******** 握手成功 ********');
  Memo_Log.Lines.Add('         ClientID: ' + ClientID);
  Memo_Log.Lines.Add(    'WebSocket_Key: '+ WebSocket_Key);
  Memo_Log.Lines.Add('WebSocket_Version: ' + WebSocket_Version);
  Memo_Log.Lines.Add('       User_Agent: ' + User_Agent);
  
end;

procedure TForm4.WebSocket1Message(ClientID, Text_Message: string);
begin
  Memo_Log.Lines.Add('收到消息(' + ClientID + '): ' + Text_Message);
end;

procedure TForm4.WebSocket1Pong(ClientID, Text_Message: string);
begin
  Memo_Log.Lines.Add(FormatDateTime('hh:mm:ss zzz',Now) + '  收到消息(' + ClientID + '): ping 回复 ' + Text_Message);
end;

procedure TForm4.WebSocket1Shutdown(Sender: TObject);
begin
  Memo_Log.Lines.Add('WebSocket 服务已经关闭!');
end;

procedure TForm4.WebSocket1Startup(Sender: TObject);
begin
  Memo_Log.Lines.Add('WebSocket 服务已经成功打开!');
end;

end.
