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

unit Swag.Doc.Path;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  Swag.Doc.Path.Operation;

type
  TSwagPath = class(TObject)
  private
    fOperations: TObjectList<TSwagPathOperation>;
    fUri: string;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;

    property Uri: string read fUri write fUri;
    property Operations: TObjectList<TSwagPathOperation> read fOperations;
  end;

implementation

uses
  System.SysUtils;

{ TSwagPath }

constructor TSwagPath.Create;
begin
  inherited Create;
  fOperations := TObjectList<TSwagPathOperation>.Create;
end;

destructor TSwagPath.Destroy;
begin
  FreeAndNil(fOperations);
  inherited Destroy;
end;

function TSwagPath.GenerateJsonObject: TJSONObject;
var
  vIndex: integer;
begin
  Result := TJsonObject.Create;
  for vIndex := 0 to fOperations.Count -1 do
    Result.AddPair(fOperations.Items[vIndex].OperationToString, fOperations.Items[vIndex].GenerateJsonObject);
end;

end.
