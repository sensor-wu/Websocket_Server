program WebSocketServer_Demo;



{$R *.dres}

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {Form4};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
