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
  Json.Schema;

type
  TFakeApiEmployee = class(TObject)
  strict private
    fRequestSchema: TJsonSchema;
    fResponseSchema: TJsonSchema;

    procedure DefineRequestSchemaSettings;
    procedure DefineResponseSchemaSettings;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function Lixo: TJsonObject;

    {procedure Post;
    procedure GetAll;
    procedure Get(const pId: Int64);
    procedure Put(const pId: Int64);
    procedure Delete(const pId: Int64); }

    property RequestSchema: TJsonSchema read fRequestSchema;
    property ResponseSchema: TJsonSchema read fResponseSchema;
  end;

implementation

uses
  Json.Schema.Field.Strings;

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

function TFakeApiEmployee.Lixo: TJsonObject;
begin
  Result := fResponseSchema.ToJson;
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
begin
  fResponseSchema := TJsonSchema.Create;
  fResponseSchema.Root.Name := 'employee';
  fResponseSchema.Root.Description := 'Employee request data';
  fResponseSchema.AddField<Int64>('id', 'The employee identification code.');
  fResponseSchema.Root.CopyFields(fRequestSchema.Root);
end;

end.
