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
  Swag.Doc.Path.Operation.ResponseHeaders,
  Swag.Doc.Definition;

type
  TSwagResponse = class(TObject)
  private
    fStatusCode: TSwagStatusCode;
    fSchema: TSwagDefinition;
    fHeaders: TObjectList<TSwagHeaders>;
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
    property Headers : TObjectList<TSwagHeaders> read fHeaders;
    property Examples: TDictionary<TSwagJsonExampleDescription, TJSONObject> read fExamples;
  end;

implementation

uses
  System.SysUtils;

const
  c_SwagResponseDescription = 'description';
  c_SwagResponseSchema = 'schema';
  c_SwagResponseExamples = 'examples';
  c_SwagResponseHeaders = 'headers';

{ TSwagResponse }

constructor TSwagResponse.Create;
begin
  inherited Create;
  fExamples := TDictionary<TSwagJsonExampleDescription, TJSONObject>.Create;
  fSchema := TSwagDefinition.Create;
  fHeaders := TObjectList<TSwagHeaders>.Create;
end;

destructor TSwagResponse.Destroy;
begin
  FreeAndNil(fExamples);
  FreeAndNil(fSchema);
  FreeAndNil(fHeaders);
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
  i: Integer;
  vJsonHeaders : TJSONObject;
begin
  vJsonObject := TJsonObject.Create;
  vJsonObject.AddPair(c_SwagResponseDescription, fDescription);

  if (not fSchema.Name.IsEmpty) then
    vJsonObject.AddPair(c_SwagResponseSchema, fSchema.NameToJson)
  else if Assigned(fSchema.JsonSchema) then
    vJsonObject.AddPair(c_SwagResponseSchema, fSchema.JsonSchema);

  if (fExamples.Count > 0) then
    vJsonObject.AddPair(c_SwagResponseExamples, GenerateExamplesJsonObject);

  if fHeaders.Count > 0 then
  begin
    vJsonHeaders := TJSONObject.Create;
    for i := 0 to fHeaders.Count - 1 do
    begin
      vJsonHeaders.AddPair(fHeaders[i].Name,fHeaders[i].GenerateJsonObject);
    end;
    vJsonObject.AddPair(c_SwagResponseHeaders,vJsonHeaders);
  end;

  Result := vJsonObject;
end;

procedure TSwagResponse.Load(pJson: TJSONObject);
var
  vJSONHeaders : TJSONObject;
  i: Integer;
  vheader : TSwagHeaders;
begin
  if Assigned(pJson.Values[c_SwagResponseDescription]) then
    fDescription := pJson.Values[c_SwagResponseDescription].Value;

  if Assigned(pJson.Values[c_SwagResponseHeaders]) then
  begin
    vJSONHeaders := pJson.Values[c_SwagResponseHeaders] as TJSONObject;
    for i := 0 to vJSONHeaders.Count - 1 do
    begin
      vheader := TSwagHeaders.Create;
      vheader.Load(vJSONHeaders.Pairs[i].JsonValue as TJSONObject);
      vheader.Name := vJSONHeaders.Pairs[i].JsonString.Value;
      fHeaders.Add(vheader);
    end;
  end;

end;

end.
