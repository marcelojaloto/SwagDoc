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

unit Swag.Doc.Definition;

interface

uses
  System.JSON;

type
  TSwagDefinition = class(TObject)
  private
    fName: string;
    fJsonSchema: TJsonObject;
    procedure SetName(const Value: string);
    procedure SetJsonSchema(const Value: TJsonObject);
  public
    function GenerateJsonRefDefinition: TJsonObject;

    property Name: string read fName write SetName;
    property JsonSchema: TJsonObject read fJsonSchema write SetJsonSchema; // http://json-schema.org
  end;

implementation

uses
  System.SysUtils;

{ TSwagDefinition }

procedure TSwagDefinition.SetJsonSchema(const Value: TJsonObject);
begin
  fJsonSchema := Value;
end;

procedure TSwagDefinition.SetName(const Value: string);
begin
  fName := Value;
end;

{ TSwagDefinition }

function TSwagDefinition.GenerateJsonRefDefinition: TJsonObject;
const
  c_SchemaRef = '$ref';
  c_PrefixDefinitionName = '#/definitions/';
begin
  Result := TJsonObject.Create;
  Result.AddPair(c_SchemaRef, c_PrefixDefinitionName + fName);
end;

end.
