program SwagDocDemo;

uses
  Vcl.Forms,
  frmSimpleDemo in 'frmSimpleDemo.pas' {frmSimpleSwaggerDocDemo},
  Swag.Common.Consts in 'Swag.Common.Consts.pas',
  Swag.Common.Types in 'Swag.Common.Types.pas',
  Swag.Doc.Definition in 'Swag.Doc.Definition.pas',
  Swag.Doc.Info.Contact in 'Swag.Doc.Info.Contact.pas',
  Swag.Doc.Info in 'Swag.Doc.Info.pas',
  Swag.Doc in 'Swag.Doc.pas',
  Swag.Doc.Path.Operation in 'Swag.Doc.Path.Operation.pas',
  Swag.Doc.Path.Operation.RequestParameter in 'Swag.Doc.Path.Operation.RequestParameter.pas',
  Swag.Doc.Path.Operation.Response in 'Swag.Doc.Path.Operation.Response.pas',
  Swag.Doc.Path in 'Swag.Doc.Path.pas',
  Swag.Doc.SecurityDefinition in 'Swag.Doc.SecurityDefinition.pas',
  Swag.Doc.SecurityDefinitionApiKey in 'Swag.Doc.SecurityDefinitionApiKey.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSimpleSwaggerDocDemo, frmSimpleSwaggerDocDemo);
  Application.Run;
end.
