program SwagDocDemo;

uses
  Vcl.Forms,
  frmSimpleDemo in 'frmSimpleDemo.pas' {frmSimpleSwaggerDocDemo};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSimpleSwaggerDocDemo, frmSimpleSwaggerDocDemo);
  Application.Run;
end.
