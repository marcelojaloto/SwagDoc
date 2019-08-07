program ClientApiGenerator;

uses
  System.StartUpCopy,
  FMX.Forms,
  Sample.Main in 'Sample.Main.pas' {Form1},
  DelphiUnit in 'DelphiUnit.pas',
  SwagDoc.DelphiRESTClient in 'SwagDoc.DelphiRESTClient.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
