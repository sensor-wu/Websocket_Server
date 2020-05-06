object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'WebSocket Server DEMO (2020-05-01 '#31070#24030#28023#32435' - '#32769#21556')'
  ClientHeight = 403
  ClientWidth = 718
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 20
  object Panel_Button: TPanel
    Left = 0
    Top = 0
    Width = 718
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    DesignSize = (
      718
      49)
    object SpeedButton1: TSpeedButton
      Left = 16
      Top = 7
      Width = 100
      Height = 32
      Action = Action_StartServer
      Flat = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlue
      Font.Height = -15
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object SpeedButton2: TSpeedButton
      Left = 122
      Top = 7
      Width = 100
      Height = 32
      Action = Action_StopServer
      Flat = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlue
      Font.Height = -15
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object SpeedButton4: TSpeedButton
      Left = 396
      Top = 7
      Width = 100
      Height = 32
      Action = Action_ping
      Anchors = [akTop, akRight]
      Flat = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlue
      Font.Height = -15
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object SpeedButton6: TSpeedButton
      Left = 510
      Top = 7
      Width = 100
      Height = 32
      Action = Action_DisconnectAll
      Anchors = [akTop, akRight]
      Flat = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlue
      Font.Height = -15
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object SpeedButton8: TSpeedButton
      Left = 608
      Top = 7
      Width = 100
      Height = 32
      Action = Action_OpenIE
      Anchors = [akTop, akRight]
      Flat = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlue
      Font.Height = -15
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
  end
  object Panel_Client: TPanel
    Left = 0
    Top = 49
    Width = 718
    Height = 354
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 249
      Top = 0
      Height = 354
      ExplicitLeft = 272
      ExplicitTop = 64
      ExplicitHeight = 100
    end
    object Panel_Connections: TPanel
      Left = 0
      Top = 0
      Width = 249
      Height = 354
      Align = alLeft
      BevelOuter = bvLowered
      TabOrder = 0
      object Label_HandShakeTimeout: TLabel
        Left = 9
        Top = 48
        Width = 145
        Height = 17
        Hint = #25569#25163#36229#26102#26102#38388#65292#33258#20174#25509#25910#21040#23458#25143#31471#30340#25569#25163#20449#24687#24320#22987#21040#20840#37096#25910#21040#27491#30830#30340#25569#25163#20449#24687#20043#38388#30340#26102#38388#12290
        Caption = 'HandShakeTimeOut'#65288's'#65289
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label_WebPort: TLabel
        Left = 9
        Top = 84
        Width = 59
        Height = 20
        Hint = 'WebSocket '#30340#31471#21475#65292#40664#35748#26159' 80'#65292#21487#20197#35774#32622#21512#36866#30340#20854#23427#20540#12290
        Caption = 'WebPort'
        Font.Charset = ANSI_CHARSET
        Font.Color = clRed
        Font.Height = -14
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label_Interval: TLabel
        Left = 9
        Top = 121
        Width = 84
        Height = 20
        Hint = #30456#37051#20004#20010'ping'#20043#38388#30340#26102#38388#38388#38548#65292#36825#20010#21442#25968#20027#35201#26159#24403#21551#21160' HeartBeat'#21518#26377#25928#12290
        Caption = 'Interval'#65288's'#65289
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label_MaxConnections: TLabel
        Left = 9
        Top = 157
        Width = 113
        Height = 20
        Caption = 'MaxConnections'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentFont = False
      end
      object Label_PingTimeout: TLabel
        Left = 9
        Top = 194
        Width = 121
        Height = 20
        Hint = #20174#26381#21153#22120#21457#20986'ping'#21629#20196#21040#25910#21040'pong'#22238#22797#20043#38388#30340#26102#38388#38388#38548#65292#36229#36807#36825#20010#26102#38388#35748#20026'ping'#22833#36133#65292#26029#24320#23458#25143#31471#65292#21333#20301#65306#31186
        Caption = 'PingTimeout'#65288's'#65289
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label_ReadTimeout: TLabel
        Left = 9
        Top = 231
        Width = 128
        Height = 20
        Hint = #20027#35201#26159#20026#20102#20943#23569#32447#31243#36807#22810#21344#29992'CPU'#65292#40664#35748#26159'10'#65292#22914#26524#35774#32622#20026'0'#65292#21017#20250#21344#25454#36807#22810'CPU'#26102#38388
        Caption = 'ReadTimeout'#65288'ms)'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Panel1: TPanel
        Left = 1
        Top = 1
        Width = 247
        Height = 41
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object Label1: TLabel
          Left = 0
          Top = 0
          Width = 247
          Height = 41
          Align = alClient
          Alignment = taCenter
          Caption = 'WebSocket '#21442#25968
          Layout = tlCenter
          ExplicitWidth = 118
          ExplicitHeight = 20
        end
      end
      object SpinEdit_HandShakeTimeout: TSpinEdit
        Left = 165
        Top = 44
        Width = 73
        Height = 27
        Hint = #25569#25163#36229#26102#26102#38388#65292#33258#20174#25509#25910#21040#23458#25143#31471#30340#25569#25163#20449#24687#24320#22987#21040#20840#37096#25910#21040#27491#30830#30340#25569#25163#20449#24687#20043#38388#30340#26102#38388#12290#13#10#36229#36807#36825#20010#26102#38388#65292#25569#25163#22833#36133#65281
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        MaxValue = 1000000
        MinValue = 1
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        Value = 10
        OnChange = SpinEdit_HandShakeTimeoutChange
      end
      object SpinEdit_WebPort: TSpinEdit
        Left = 165
        Top = 81
        Width = 73
        Height = 27
        Hint = 'WebSocket '#30340#31471#21475#65292#40664#35748#26159' 80'#65292#21487#20197#35774#32622#21512#36866#30340#20854#23427#20540#12290
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        MaxValue = 1000000
        MinValue = 80
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        Value = 80
        OnChange = SpinEdit_HandShakeTimeoutChange
      end
      object SpinEdit_Interval: TSpinEdit
        Left = 165
        Top = 118
        Width = 73
        Height = 27
        Hint = #30456#37051#20004#20010'ping'#20043#38388#30340#26102#38388#38388#38548#65292#36825#20010#21442#25968#20027#35201#26159#24403#21551#21160' HeartBeat'#21518#26377#25928#12290
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        MaxValue = 1000000
        MinValue = 1
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        Value = 60
        OnChange = SpinEdit_HandShakeTimeoutChange
      end
      object SpinEdit_MaxConnections: TSpinEdit
        Left = 165
        Top = 156
        Width = 73
        Height = 27
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        MaxValue = 1000000
        MinValue = 0
        ParentFont = False
        TabOrder = 4
        Value = 0
        OnChange = SpinEdit_HandShakeTimeoutChange
      end
      object SpinEdit_PingTimeout: TSpinEdit
        Left = 165
        Top = 193
        Width = 73
        Height = 27
        Hint = #20174#26381#21153#22120#21457#20986'ping'#21629#20196#21040#25910#21040'pong'#22238#22797#20043#38388#30340#26102#38388#38388#38548#65292#36229#36807#36825#20010#26102#38388#35748#20026'ping'#22833#36133#65292#26029#24320#23458#25143#31471#65292#21333#20301#65306#31186
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        MaxValue = 1000000
        MinValue = 1
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        Value = 10
        OnChange = SpinEdit_HandShakeTimeoutChange
      end
      object SpinEdit_ReadTimeout: TSpinEdit
        Left = 165
        Top = 231
        Width = 73
        Height = 27
        Hint = #20027#35201#26159#20026#20102#20943#23569#32447#31243#36807#22810#21344#29992'CPU'#65292#40664#35748#26159'10'#65292#22914#26524#35774#32622#20026'0'#65292#21017#20250#21344#25454#36807#22810'CPU'#26102#38388#65292#21333#20301#65306#27627#31186
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        MaxValue = 1000000
        MinValue = 1
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        Value = 10
        OnChange = SpinEdit_HandShakeTimeoutChange
      end
      object CheckBox_HeartBeat: TCheckBox
        Left = 16
        Top = 280
        Width = 111
        Height = 17
        Hint = #26159#21542#21551#21160#24515#36339#26816#27979#65292#21551#21160#21518#23601#20250#23450#26102#21457#36865' ping'
        Caption = '  HeartBeat   '
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnClick = SpinEdit_HandShakeTimeoutChange
      end
    end
    object Panel_Memo: TPanel
      Left = 252
      Top = 0
      Width = 466
      Height = 354
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 466
        Height = 89
        Align = alTop
        BevelOuter = bvLowered
        TabOrder = 0
        DesignSize = (
          466
          89)
        object SpeedButton3: TSpeedButton
          Left = 22
          Top = 16
          Width = 81
          Height = 52
          Action = Action_Broadcast
          Flat = True
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -15
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
        end
        object SpeedButton5: TSpeedButton
          Left = 123
          Top = 16
          Width = 81
          Height = 52
          Action = Action_WriteTexts
          Flat = True
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -15
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
        end
        object Memo_Message: TMemo
          Left = 224
          Top = 16
          Width = 231
          Height = 57
          Anchors = [akLeft, akTop, akRight]
          Color = 16316664
          Font.Charset = ANSI_CHARSET
          Font.Color = clTeal
          Font.Height = -15
          Font.Name = 'Courier New'
          Font.Style = []
          Lines.Strings = (
            'Send_Message')
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel3: TPanel
        Left = 0
        Top = 89
        Width = 225
        Height = 265
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 1
        object Panel4: TPanel
          Left = 0
          Top = 0
          Width = 225
          Height = 41
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object Label_Client: TLabel
            Left = 0
            Top = 0
            Width = 225
            Height = 41
            Align = alClient
            Alignment = taCenter
            Caption = #24403#21069#26377#25928#23458#25143#31471
            Layout = tlCenter
            ExplicitWidth = 105
            ExplicitHeight = 20
          end
        end
        object ListBox1: TListBox
          Left = 0
          Top = 41
          Width = 225
          Height = 224
          Align = alClient
          BorderStyle = bsNone
          ItemHeight = 20
          PopupMenu = PopupMenu1
          TabOrder = 1
          OnClick = ListBox1Click
        end
      end
      object Panel5: TPanel
        Left = 225
        Top = 89
        Width = 241
        Height = 265
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 2
        object Panel6: TPanel
          Left = 0
          Top = 0
          Width = 241
          Height = 41
          Align = alTop
          BevelOuter = bvNone
          Color = clCream
          ParentBackground = False
          TabOrder = 0
          DesignSize = (
            241
            41)
          object Label_Message: TLabel
            Left = 0
            Top = 0
            Width = 68
            Height = 41
            Align = alLeft
            Alignment = taCenter
            Caption = '  '#28040#24687#31383#21475
            Layout = tlCenter
            ExplicitHeight = 20
          end
          object SpeedButton7: TSpeedButton
            Left = 158
            Top = 6
            Width = 73
            Height = 29
            Action = Action_Clear
            Anchors = [akTop, akRight]
            Flat = True
            Font.Charset = ANSI_CHARSET
            Font.Color = clBlue
            Font.Height = -15
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            OnClick = SpeedButton7Click
            ExplicitLeft = 128
          end
        end
        object Memo_Log: TMemo
          Left = 0
          Top = 41
          Width = 241
          Height = 224
          Align = alClient
          Color = clInfoBk
          Font.Charset = ANSI_CHARSET
          Font.Color = clTeal
          Font.Height = -13
          Font.Name = 'Courier New'
          Font.Style = []
          Lines.Strings = (
            #35843#35797#20449#24687#26174#31034#21306#22495'....')
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 1
        end
      end
    end
  end
  object WebSocket1: TWebSocket
    WebPort = 80
    Interval = 60
    HandShakeTimeout = 10
    PingTimeout = 10
    ReadTimeout = 10
    MaxConnections = 0
    OnStartup = WebSocket1Startup
    OnShutdown = WebSocket1Shutdown
    OnConnect = WebSocket1Connect
    OnDisConnect = WebSocket1DisConnect
    OnError = WebSocket1Error
    OnException = WebSocket1Exception
    OnHandShake = WebSocket1HandShake
    OnMessage = WebSocket1Message
    OnPong = WebSocket1Pong
    Left = 360
    Top = 8
  end
  object ActionList1: TActionList
    Left = 272
    Top = 9
    object Action_StartServer: TAction
      Caption = #25171#24320#26381#21153
      OnExecute = Action_StartServerExecute
    end
    object Action_StopServer: TAction
      Caption = #20851#38381#26381#21153
      OnExecute = Action_StopServerExecute
    end
    object Action_WriteTexts: TAction
      Caption = #21457#36865#28040#24687
      OnExecute = Action_WriteTextsExecute
    end
    object Action_Broadcast: TAction
      Caption = #24191#25773#28040#24687
      OnExecute = Action_BroadcastExecute
    end
    object Action_ping: TAction
      Caption = 'Ping '#23458#25143#31471
      OnExecute = Action_pingExecute
    end
    object Action_DisconnectAll: TAction
      Caption = #26029#24320#20840#37096
      OnExecute = Action_DisconnectAllExecute
    end
    object Action_Clear: TAction
      Caption = #28165#38500
      OnExecute = Action_ClearExecute
    end
    object Action_OpenIE: TAction
      Caption = #35895#27468#27983#35272#22120
      OnExecute = Action_OpenIEExecute
    end
    object Action_ClientInfo: TAction
      Caption = #33719#21462#23458#25143#31471#20449#24687
      OnExecute = Action_ClientInfoExecute
    end
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 292
    Top = 226
  end
  object PopupMenu1: TPopupMenu
    AutoHotkeys = maManual
    Left = 364
    Top = 226
    object N1: TMenuItem
      Action = Action_ClientInfo
    end
  end
end
