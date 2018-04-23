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
  Swag.Common.Types,
  Swag.Doc.Path.Operation.RequestParameter,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.Path.Operation;

type
  TSwagPath = class(TObject)
  private
    fOperations: TObjectList<TSwagPathOperation>;
    fUri: string;
    function GetPathTypeOperationFromString(const pTypeOperationString: string): TSwagPathTypeOperation;
    procedure LoadResponse(pOperation: TSwagPathOperation; pJsonResponse: TJSONObject);
    procedure LoadParameters(pOperation: TSwagPathOperation; pJsonRequestParams: TJSONArray);
    procedure LoadTags(pOperation: TSwagPathOperation; pJsonTags: TJSONArray);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson: TJSONObject);

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

procedure TSwagPath.Load(pJson: TJSONObject);
var
  i: Integer;
  vOperation: TSwagPathOperation;
  vOperationJson: TJSONObject;
  vOperationValue: string;
begin
  for i := 0 to pJson.Count - 1 do
  begin
    vOperation := TSwagPathOperation.Create;
    vOperationJson := pJson.Pairs[i].JsonValue as TJSONObject;
    vOperation.Description := vOperationJson.Values['description'].Value;
    vOperationValue := pJson.Pairs[i].JsonString.Value;
    vOperation.Operation := GetPathTypeOperationFromString(vOperationValue);

    if Assigned(vOperationJson.Values['operationId']) then
      vOperation.OperationId := vOperationJson.Values['operationId'].Value;

    if Assigned(vOperationJson.Values['deprecated']) then
      vOperation.Deprecated := (vOperationJson.Values['deprecated'] as TJSONBool).AsBoolean;

    LoadTags(vOperation, vOperationJson.Values['tags'] as TJSONArray);
    LoadParameters(vOperation, vOperationJson.Values['parameters'] as TJSONArray);
    LoadResponse(vOperation, vOperationJson.Values['responses'] as TJSONObject);

    fOperations.Add(vOperation);
  end;
end;

procedure TSwagPath.LoadTags(pOperation: TSwagPathOperation; pJsonTags: TJSONArray);
var
  j: Integer;
  vTag: string;
begin
  if Assigned(pJsonTags) then
  begin
    for j := 0 to pJsonTags.Count - 1 do
    begin
      vTag := pJsonTags.Items[j].Value;
      pOperation.Tags.Add(vTag);
    end;
  end;
end;

procedure TSwagPath.LoadParameters(pOperation: TSwagPathOperation; pJsonRequestParams: TJSONArray);
var
  k: Integer;
  vRequestParam: TSwagRequestParameter;
begin
  if Assigned(pJsonRequestParams) then
  begin
    for k := 0 to pJsonRequestParams.Count - 1 do
    begin
      vRequestParam := TSwagRequestParameter.Create;
      vRequestParam.Load(pJsonRequestParams.Items[k] as TJSONObject);
      pOperation.Parameters.Add(vRequestParam);
    end;
  end;
end;

procedure TSwagPath.LoadResponse(pOperation: TSwagPathOperation; pJsonResponse: TJSONObject);
var
  r: Integer;
  vResponse: TSwagResponse;
begin
  if Assigned(pJsonResponse) then
  begin
    for r := 0 to pJsonResponse.Count - 1 do
    begin
      vResponse := TSwagResponse.Create;
      vResponse.StatusCode := pJsonResponse.Pairs[r].JsonString.Value;
      vResponse.Load(pJsonResponse.Pairs[r].JsonValue as TJSONObject);
      pOperation.Responses.Add(vResponse.StatusCode, vResponse);
    end;
  end;
end;

function TSwagPath.GetPathTypeOperationFromString(const pTypeOperationString: string): TSwagPathTypeOperation;
begin
  Result := TSwagPathTypeOperation.ohvNotDefined;
  if pTypeOperationString = 'get' then
  begin
    Result := TSwagPathTypeOperation.ohvGet;
  end
  else if pTypeOperationString = 'post' then
  begin
    Result := TSwagPathTypeOperation.ohvPost;
  end
  else if pTypeOperationString = 'patch' then
  begin
    Result := TSwagPathTypeOperation.ohvPatch;
  end
  else if pTypeOperationString = 'put' then
  begin
    Result := TSwagPathTypeOperation.ohvPut;
  end
  else if pTypeOperationString = 'head' then
  begin
    Result := TSwagPathTypeOperation.ohvHead;
  end
  else if pTypeOperationString = 'delete' then
  begin
    Result := TSwagPathTypeOperation.ohvDelete;
  end
  else if pTypeOperationString = 'options' then
  begin
    Result := TSwagPathTypeOperation.ohvOptions;
  end;
end;

end.
