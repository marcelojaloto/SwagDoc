{******************************************************************************}
{                                                                              }
{  Delphi SwagDoc Library                                                      }
{  Copyright (c) 2018 Marcelo Jaloto                                           }
{  https://github.com/marcelojaloto/SwagDoc                                    }
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

unit Swag.Doc.Path.Operation.Response;

interface

uses
  System.Generics.Collections,
  System.JSON,
  Swag.Common.Types,
  Swag.Doc.Definition;

type
  TSwagResponse = class(TObject)
  private
    fStatusCode: TSwagStatusCode;
    fSchema: TSwagDefinition;
    fDescription: string;
    fExamples: TDictionary<TSwagJsonExampleDescription, TJSONObject>;
  protected
    function GenerateExamplesJsonObject: TJSONObject;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson : TJSONObject);

    property StatusCode: TSwagStatusCode read fStatusCode write fStatusCode;
    property Description: string read fDescription write fDescription;
    property Schema: TSwagDefinition read fSchema;
    property Examples: TDictionary<TSwagJsonExampleDescription, TJSONObject> read fExamples;
  end;

implementation

uses
  System.SysUtils;

const
  c_SwagResponseDescription = 'description';
  c_SwagResponseSchema = 'schema';
  c_SwagResponseExamples = 'examples';

{ TSwagResponse }

constructor TSwagResponse.Create;
begin
  inherited Create;
  fExamples := TDictionary<TSwagJsonExampleDescription, TJSONObject>.Create;
  fSchema := TSwagDefinition.Create;
end;

destructor TSwagResponse.Destroy;
begin
  FreeAndNil(fExamples);
  FreeAndNil(fSchema);
  inherited Destroy;
end;

function TSwagResponse.GenerateExamplesJsonObject: TJSONObject;
var
  vKey: TSwagJsonExampleDescription;
begin
  Result := TJsonObject.Create;
  for vKey in fExamples.Keys do
    Result.AddPair(vKey, fExamples.Items[vKey]);
end;

function TSwagResponse.GenerateJsonObject: TJSONObject;
var
  vJsonObject: TJsonObject;
begin
  vJsonObject := TJsonObject.Create;
  vJsonObject.AddPair(c_SwagResponseDescription, fDescription);

  if (not fSchema.Name.IsEmpty) then
    vJsonObject.AddPair(c_SwagResponseSchema, fSchema.NameToJson)
  else if Assigned(fSchema.JsonSchema) then
    vJsonObject.AddPair(c_SwagResponseSchema, fSchema.JsonSchema);

  if (fExamples.Count > 0) then
    vJsonObject.AddPair(c_SwagResponseExamples, GenerateExamplesJsonObject);

  Result := vJsonObject;
end;

procedure TSwagResponse.Load(pJson: TJSONObject);
begin
  if Assigned(pJson.Values[c_SwagResponseDescription]) then
    fDescription := pJson.Values[c_SwagResponseDescription].Value;
end;

end.
