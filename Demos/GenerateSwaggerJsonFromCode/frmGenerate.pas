unit frmGenerate;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    btnGenerate: TButton;
    procedure btnGenerateClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses REST.Json, 
  System.Json,
  Swag.Common.Types,
  Swag.Doc.Path,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.RequestParameter,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.Path.Operation.ResponseHeaders,
  Swag.Doc.Definition,
  Swag.Doc;

procedure TForm1.btnGenerateClick(Sender: TObject);
var
  vSwagDoc : TSwagDoc;
  vPath : TSwagPath;
  vOperation : TSwagPathOperation;
  vParam : TSwagRequestParameter;
  vResponse : TSwagResponse;
  vResponseHeader : TSwagHeaders;
  vDefinition, vDefinition2, vDefinition3 : TSwagDefinition;
  vJSONProperities : TJSONObject;
  vJSONSchema : TJSONObject;
  vJSONSubProp : TJSONPair;
  vJSONType : TJSONObject;
begin
  vSwagDoc := TSwagDoc.Create;
  try
    vSwagDoc.Info.Title := 'Sample API';
    vSwagDoc.Info.Version := 'v1.2';
    vSwagDoc.Info.TermsOfService := 'https://example.com/someurl/tos';
    vSwagDoc.Info.Description := 'Sample API Description';
    vSwagDoc.Info.Contact.Name := 'John Smith';
    vSwagDoc.Info.Contact.Email := 'jsmith@example.com';
    vSwagDoc.Info.Contact.Url := 'https://example.com/contact';
    vSwagDoc.Info.License.Name := 'Some License';
    vSwagDoc.Info.License.Url := 'https://example.com/license';

    vSwagDoc.Host := 'example.com';
    vSwagDoc.BasePath := '/basepath';

    vSwagDoc.Consumes.Add('application/json');

    vSwagDoc.Produces.Add('text/xml');
    vSwagDoc.Produces.Add('application/json');

    vSwagDoc.Schemes := [tpsHttps];

    vDefinition3 := TSwagDefinition.Create;
    vDefinition3.Name := 'SomeSubType';

    vJSONSchema := TJSONObject.Create;
    vJSONSchema.AddPair('type','object');

    vJSONType := TJSONObject.Create;
    vJsonType.AddPair('type','string');
    vJSONProperities := TJSONObject.Create;
    vJSONProperities.AddPair('id',vJSONType);

    vJSONSchema.AddPair('properties',vJSONProperities);


    vDefinition3.JsonSchema := vJSONSchema;
    vSwagDoc.Definitions.Add(vDefinition3);

    vDefinition := TSwagDefinition.Create;
    vDefinition.Name := 'SomeType';

    vJSONSchema := TJSONObject.Create;
    vJSONSchema.AddPair('type','object');

    vJSONType := TJSONObject.Create;
    vJSONType.AddPair('type','integer');
    vJSONType.AddPair('format','int64');

    vJSONProperities := TJSONObject.Create;
    vJSONProperities.AddPair('id',vJSONType);

    vJSONType := TJSONObject.Create;
    vJSONType.AddPair('type','object');
    vJSONProperities.AddPair('subType',vDefinition3.NameToJson);


    vJSONType := TJSONObject.Create;
    vJsonType.AddPair('type','string');
    vJsonType.AddPair('format','decimel');
    vJSONType.AddPair('multipleOf',TJSONNumber.Create(0.01));
    vJSONType.AddPair('minimum',TJSONNumber.Create(-9999999999.99));
    vJSONType.AddPair('maximum',TJSONNumber.Create(9999999999.99));
    vJSONType.AddPair('title','Total Cost');
    vJSONType.AddPair('description','Total Cost');
    vJSONType.AddPair('example',TJSONNumber.Create(9999999999.99));
    vJSONProperities.AddPair('cost',vJSONType);
    vJSONSchema.AddPair('properties',vJSONProperities);
    vDefinition.JsonSchema := vJSONSchema;
    vSwagDoc.Definitions.Add(vDefinition);

    vPath := TSwagPath.Create;
    vPath.Uri := '/path/request/{param1}';

    vOperation := TSwagPathOperation.Create;
    vOperation.Operation := ohvPost;
    vOperation.OperationId := 'RequestData';
    vOperation.Description := 'Requests some data';

    vParam := TSwagRequestParameter.Create;
    vParam.Name := 'param1';
    vParam.InLocation := rpiPath;
    vParam.Description := 'A param required';
    vParam.Required := True;
    vParam.TypeParameter := 'string';
    vOperation.Parameters.Add(vParam);

    vParam := TSwagRequestParameter.Create;
    vParam.Name := 'param2';
    vParam.InLocation := rpiQuery;
    vParam.Description := 'A param that is not required';
    vParam.Required := False;
    vParam.TypeParameter := 'string';
    vOperation.Parameters.Add(vParam);

    vParam := TSwagRequestParameter.Create;
    vParam.Name := 'param3';
    vParam.InLocation := rpiBody;
    vParam.Required := True;

    vDefinition2 := TSwagDefinition.Create;
    vDefinition2.Name := 'SomeType';
    vParam.Schema.JsonSchema := vDefinition2.NameToJson;
    vOperation.Parameters.Add(vParam);


    vResponse := TSwagResponse.Create;
    vResponse.StatusCode := '200';
    vResponse.Description := 'Successfully retrieved data';
    vResponse.Schema.JsonSchema := vDefinition2.NameToJson;

    vResponseHeader := TSwagHeaders.Create;
    vResponseHeader.Name := 'X-Rate-Limit-Limit';
    vResponseHeader.Description := 'The number of allowed requests in the current period';
    vResponseHeader.ValueType := 'integer';
    vResponse.Headers.Add(vResponseHeader);
    vOperation.Responses.Add('200',vResponse);

    vResponse := TSwagResponse.Create;
    vResponse.StatusCode := 'default';
    vResponse.Description := 'Error occured';

    vOperation.Responses.Add('default',vResponse);

    vOperation.Tags.Add('TagName');
        
    vPath.Operations.Add(vOperation);
    vSwagDoc.Paths.Add(vPath);

    vSwagDoc.GenerateSwaggerJson;
    Memo1.Lines.Add(REST.Json.TJson.Format(vSwagDoc.SwaggerJson));
  finally
    FreeAndNil(vSwagDoc);
  end;
end;

end.
