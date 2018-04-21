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
    function GetPathTypeOperationFromString(const opstring: string): TSwagPathTypeOperation;
    procedure LoadResponse(Op: TSwagPathOperation; JsonResponseObj: TJSONObject);
    procedure LoadParameters(Op: TSwagPathOperation; jsonRequestParams: TJSONArray);
    procedure LoadTags(Op: TSwagPathOperation; jsonTags: TJSONArray);
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;
    procedure Load(inJSON: TJSONObject);

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

procedure TSwagPath.Load(inJSON: TJSONObject);
var
  jsonObj : TJSONObject;
  i : Integer;
  Op : TSwagPathOperation;
  OpObj : TJSONObject;
  opstring : string;
begin
  for i := 0 to inJSON.Count - 1 do
  begin
    Op := TSwagPathOperation.Create;
    OpObj := inJSON.Pairs[i].JsonValue as TJSONObject;
    Op.Description := OpObj.Values['description'].Value;
    opstring := inJSON.Pairs[i].JsonString.Value;
    Op.Operation := GetPathTypeOperationFromString(opstring);

    if Assigned(OpObj.Values['operationId']) then
      Op.OperationId := OpObj.Values['operationId'].Value;

    if Assigned(OpObj.Values['deprecated']) then
      Op.Deprecated := (OpObj.Values['deprecated'] as TJSONBool).AsBoolean;

    LoadTags(Op, OpObj.Values['tags'] as TJSONArray);
    LoadParameters(Op, OpObj.Values['parameters'] as TJSONArray);
    LoadResponse(Op, OpObj.Values['responses'] as TJSONObject);

    Operations.Add(Op);
  end;
end;

procedure TSwagPath.LoadTags(Op: TSwagPathOperation; jsonTags: TJSONArray);
var
  j: Integer;
  tag: string;
begin
  if Assigned(jsonTags) then
  begin
    for j := 0 to jsonTags.Count - 1 do
    begin
      tag := jsonTags.Items[j].Value;
      Op.Tags.Add(tag);
    end;
  end;
end;

procedure TSwagPath.LoadParameters(Op: TSwagPathOperation; jsonRequestParams: TJSONArray);
var
  k: Integer;
  RequestParam: TSwagRequestParameter;
begin
  if Assigned(jsonRequestParams) then
  begin
    for k := 0 to jsonRequestParams.Count - 1 do
    begin
      RequestParam := TSwagRequestParameter.Create;
      RequestParam.Load(jsonRequestParams.Items[k] as TJSONObject);
      Op.Parameters.Add(RequestParam);
    end;
  end;
end;

procedure TSwagPath.LoadResponse(Op: TSwagPathOperation; JsonResponseObj: TJSONObject);
var
  r: Integer;
  Response: TSwagResponse;
begin
  if Assigned(JsonResponseObj) then
  begin
    for r := 0 to JsonResponseObj.Count - 1 do
    begin
      Response := TSwagResponse.Create;
      Response.StatusCode := JsonResponseObj.Pairs[r].JsonString.Value;
      Response.Load(JsonResponseObj.Pairs[r].JsonValue as TJSONObject);
      Op.Responses.Add(Response.StatusCode, Response);
    end;
  end;
end;

function TSwagPath.GetPathTypeOperationFromString(const opstring: string): TSwagPathTypeOperation;
begin
  Result := TSwagPathTypeOperation.ohvNotDefined;
  if opstring = 'get' then
  begin
    Result := TSwagPathTypeOperation.ohvGet;
  end
  else if opstring = 'post' then
  begin
    Result := TSwagPathTypeOperation.ohvPost;
  end
  else if opstring = 'patch' then
  begin
    Result := TSwagPathTypeOperation.ohvPatch;
  end
  else if opstring = 'put' then
  begin
    Result := TSwagPathTypeOperation.ohvPut;
  end
  else if opstring = 'head' then
  begin
    Result := TSwagPathTypeOperation.ohvHead;
  end
  else if opstring = 'delete' then
  begin
    Result := TSwagPathTypeOperation.ohvDelete;
  end
  else if opstring = 'options' then
  begin
    Result := TSwagPathTypeOperation.ohvOptions;
  end;
end;

end.
