// JCL_DEBUG_EXPERT_INSERTJDBG OFF
program SwagGen;

uses
  Vcl.Forms,
  SwagGenMain in 'SwagGenMain.pas' {Form1},
  Swag.Doc in 'Swag.Doc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
