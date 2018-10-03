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

unit Sample.Api.Employee;

interface

uses
  System.JSON,
  Json.Schema,
  Swag.Doc;

type
  TFakeApiEmployee = class(TObject)
  strict private
    fRequestSchema: TJsonSchema;
    fResponseSchema: TJsonSchema;

    const c_EmployeeTagName = 'Employee';
    const c_EmployeeSchemaNameResponse = 'employeeResponse';
    const c_EmployeeSchemaNameRequest = 'employeeRequest';

    procedure DefineRequestSchemaSettings;
    procedure DefineResponseSchemaSettings;

    procedure DocumentPostEmployee(pSwagDoc: TSwagDoc);
    procedure DocumentSchemas(pSwagDoc: TSwagDoc; const pSchemaName: string; pJsonSchema: TJsonObject);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    {procedure Post;
    procedure GetAll;
    procedure Get(const pId: Int64);
    procedure Put(const pId: Int64);
    procedure Delete(const pId: Int64); }

    procedure DocumentApi(pSwagDoc: TSwagDoc);
  end;

implementation

uses
  Json.Schema.Field.Strings,
  Swag.Common.Types,
  Swag.Doc.Definition,
  Swag.Doc.Path,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.RequestParameter,
  Swag.Doc.Path.Operation.Response;

{ TApiEmployee }

constructor TFakeApiEmployee.Create;
begin
  inherited Create;

  DefineRequestSchemaSettings;
  DefineResponseSchemaSettings;
end;

destructor TFakeApiEmployee.Destroy;
begin
  fRequestSchema.Free;
  fResponseSchema.Free;

  inherited Destroy;
end;

procedure TFakeApiEmployee.DocumentApi(pSwagDoc: TSwagDoc);
begin
  DocumentSchemas(pSwagDoc, c_EmployeeSchemaNameRequest, fRequestSchema.ToJson);
  DocumentSchemas(pSwagDoc, c_EmployeeSchemaNameResponse, fResponseSchema.ToJson);

  DocumentPostEmployee(pSwagDoc);
end;

procedure TFakeApiEmployee.DocumentPostEmployee(pSwagDoc: TSwagDoc);
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
  vBody.Schema.Name := c_EmployeeSchemaNameRequest;
  vPost.Parameters.Add(vBody);

  vResponse := TSwagResponse.Create;
  vResponse.StatusCode := '201';
  vResponse.Description := 'Successfully retrieved data';
  vResponse.Schema.Name := c_EmployeeSchemaNameResponse;

  vPost.Responses.Add('201', vResponse);

  vPost.Tags.Add(c_EmployeeTagName);

  vRoute.Operations.Add(vPost);

  pSwagDoc.Paths.Add(vRoute);
end;

procedure TFakeApiEmployee.DocumentSchemas(pSwagDoc: TSwagDoc; const pSchemaName: string; pJsonSchema: TJsonObject);
var
  vDefinition: TSwagDefinition;
begin
  vDefinition := TSwagDefinition.Create;
  vDefinition.Name := pSchemaName;
  vDefinition.JsonSchema := pJsonSchema;

  pSwagDoc.Definitions.Add(vDefinition);
end;

procedure TFakeApiEmployee.DefineRequestSchemaSettings;
var
  vName: TJsonFieldString;
  vAddressSchema: TJsonSchema;
begin
  fRequestSchema := TJsonSchema.Create;
  fRequestSchema.Root.Description := 'Employee response data';

  vName := TJsonFieldString(fRequestSchema.AddField<String>('name', 'The employee full name.'));
  vName.Required := True;
  vName.MaxLength := 80;

  fRequestSchema.AddField<String>('phone', 'The employee phone number.');
  fRequestSchema.AddField<TDate>('hireDate', 'The employee hire date.');
  fRequestSchema.AddField<Double>('salary', 'The employee gross salary.');

  vAddressSchema := TJsonSchema.Create;
  try
    vAddressSchema.Root.Name := 'address';
    vAddressSchema.Root.Description := 'The employee full address.';
    vAddressSchema.AddField<String>('description', 'The employee address description.');
    vAddressSchema.AddField<String>('city', 'The employee address city.');
    vAddressSchema.AddField<String>('region', 'The employee address region.');
    vAddressSchema.AddField<String>('country', 'The employee address country.');
    vAddressSchema.AddField<String>('postalCode', 'The employee address postal code.');

    fRequestSchema.AddField(vAddressSchema);
  finally
    vAddressSchema.Free;
  end;
end;

procedure TFakeApiEmployee.DefineResponseSchemaSettings;
var
  vEmployeeSchema: TJsonSchema;
begin
  vEmployeeSchema := TJsonSchema.Create;
  vEmployeeSchema.Root.Name := 'employee';
  vEmployeeSchema.Root.Description := 'Employee request data';
  vEmployeeSchema.AddField<Int64>('id', 'The employee identification code.');
  vEmployeeSchema.Root.CopyFields(fRequestSchema.Root);

  fResponseSchema := TJsonSchema.Create;
  fResponseSchema.AddField(vEmployeeSchema);
end;

end.
