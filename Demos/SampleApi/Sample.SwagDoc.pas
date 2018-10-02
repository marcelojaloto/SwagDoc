{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

unit Sample.SwagDoc;

interface

uses
  Swag.Doc;

type
  TSampleApiSwagDocBuilder = class(TObject)
  strict private
    fSwagDoc: TSwagDoc;
    fDeployFolder: string;

    const c_EmployeeSchemaName = 'Employee';

    procedure PopulateApiInfo;
    procedure PopulateApiSettings;
    procedure PopulateSchemaDefinition;
    procedure PopulateApiRoutes;
    procedure DocumentsPostEmployee;
    procedure SaveSwaggerJson;
  private
    procedure SetDeployFolder(const Value: string);
  public
    function Generate: string;
    property DeployFolder: string read fDeployFolder write SetDeployFolder;
  end;

implementation

uses
  Swag.Common.Types,
  Swag.Doc.Definition,
  Swag.Doc.Path,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.RequestParameter,
  Swag.Doc.Path.Operation.Response,
  Sample.Api.Employee;

{ TSampleApiSwagDocBuilder }

function TSampleApiSwagDocBuilder.Generate: string;
begin
  fSwagDoc := TSwagDoc.Create;
  try
    PopulateApiInfo;
    PopulateApiSettings;
    PopulateSchemaDefinition;
    PopulateApiRoutes;

    fSwagDoc.GenerateSwaggerJson;

    SaveSwaggerJson;

    Result := fSwagDoc.SwaggerJson.ToString;
  finally
    fSwagDoc.Free;
  end;
end;

procedure TSampleApiSwagDocBuilder.PopulateApiInfo;
begin
  fSwagDoc.Info.Title := 'Sample API';
  fSwagDoc.Info.Version := 'v1.0';
  fSwagDoc.Info.TermsOfService := 'http://www.apache.org/licenses/LICENSE-2.0.txt';
  fSwagDoc.Info.Description := 'Sample API Description';
  fSwagDoc.Info.Contact.Name := 'Marcelo Jaloto';
  fSwagDoc.Info.Contact.Email := 'marcelojaloto@gmail.com';
  fSwagDoc.Info.Contact.Url := 'https://github.com/marcelojaloto/SwagDoc';
  fSwagDoc.Info.License.Name := 'Apache License - Version 2.0, January 2004';
  fSwagDoc.Info.License.Url := 'http://www.apache.org/licenses/LICENSE-2.0';
end;

procedure TSampleApiSwagDocBuilder.PopulateApiSettings;
begin
  fSwagDoc.Host := 'localhost';
  fSwagDoc.BasePath := '/api';

  fSwagDoc.Consumes.Add('application/json');
  fSwagDoc.Produces.Add('application/json');

  fSwagDoc.Schemes := [tpsHttp];
end;

procedure TSampleApiSwagDocBuilder.PopulateSchemaDefinition;
var
  vDefEmployee: TSwagDefinition;
  vApiEmployee: TFakeApiEmployee;
begin
  vApiEmployee := TFakeApiEmployee.Create;
  try
    vDefEmployee := TSwagDefinition.Create;
    vDefEmployee.Name := c_EmployeeSchemaName;
    vDefEmployee.JsonSchema := vApiEmployee.RequestSchema.ToJson;
    fSwagDoc.Definitions.Add(vDefEmployee);
  finally
    vApiEmployee.Free;
  end;
end;

procedure TSampleApiSwagDocBuilder.SaveSwaggerJson;
begin
  fSwagDoc.SwaggerFilesFolder := fDeployFolder;
  fSwagDoc.SaveSwaggerJsonToFile;
end;

procedure TSampleApiSwagDocBuilder.SetDeployFolder(const Value: string);
begin
  fDeployFolder := Value;
end;

procedure TSampleApiSwagDocBuilder.PopulateApiRoutes;
begin
  DocumentsPostEmployee;
end;

procedure TSampleApiSwagDocBuilder.DocumentsPostEmployee;
var
  vRoute: TSwagPath;
  vPost: TSwagPathOperation;
  vBody: TSwagRequestParameter;
  vResponse: TSwagResponse;
begin
  vRoute := TSwagPath.Create;
  vRoute.Uri := '/employees';

  vPost := TSwagPathOperation.Create;
  vPost.Operation := ohvPost;
  vPost.OperationId := '{C450E1E0-341D-4947-A156-9C167BE021D5}';
  vPost.Description := 'Creates a employees.';

  vBody := TSwagRequestParameter.Create;
  vBody.Name := 'employeeObject';
  vBody.InLocation := rpiBody;
  vBody.Required := True;
  vBody.Schema.Name := c_EmployeeSchemaName;
  vPost.Parameters.Add(vBody);

  vResponse := TSwagResponse.Create;
  vResponse.StatusCode := '201';
  vResponse.Description := 'Successfully retrieved data';
  vResponse.Schema.Name := c_EmployeeSchemaName;
  vPost.Responses.Add('201', vResponse);

  vPost.Tags.Add(c_EmployeeSchemaName);

  vRoute.Operations.Add(vPost);

  fSwagDoc.Paths.Add(vRoute);
end;


end.
