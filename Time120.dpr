program Time120;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit3 in 'Unit3.pas',
  Unit2 in 'Unit2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.