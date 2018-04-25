program GenerateSwagger;

uses
  Vcl.Forms,
  frmGenerate in 'frmGenerate.pas' {Form1},
  Swag.Common.Consts in '..\..\Source\Swag.Common.Consts.pas',
  Swag.Common.Types in '..\..\Source\Swag.Common.Types.pas',
  Swag.Doc.Definition in '..\..\Source\Swag.Doc.Definition.pas',
  Swag.Doc.Info.Contact in '..\..\Source\Swag.Doc.Info.Contact.pas',
  Swag.Doc.Info.License in '..\..\Source\Swag.Doc.Info.License.pas',
  Swag.Doc.Info in '..\..\Source\Swag.Doc.Info.pas',
  Swag.Doc in '..\..\Source\Swag.Doc.pas',
  Swag.Doc.Path.Operation in '..\..\Source\Swag.Doc.Path.Operation.pas',
  Swag.Doc.Path.Operation.RequestParameter in '..\..\Source\Swag.Doc.Path.Operation.RequestParameter.pas',
  Swag.Doc.Path.Operation.Response in '..\..\Source\Swag.Doc.Path.Operation.Response.pas',
  Swag.Doc.Path in '..\..\Source\Swag.Doc.Path.pas',
  Swag.Doc.SecurityDefinition in '..\..\Source\Swag.Doc.SecurityDefinition.pas',
  Swag.Doc.SecurityDefinitionApiKey in '..\..\Source\Swag.Doc.SecurityDefinitionApiKey.pas',
  Swag.Doc.Path.Operation.ResponseHeaders in '..\..\Source\Swag.Doc.Path.Operation.ResponseHeaders.pas',
  Swag.Common.Types.Helpers in '..\..\Source\Swag.Common.Types.Helpers.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
