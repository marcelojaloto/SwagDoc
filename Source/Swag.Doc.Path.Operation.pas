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

unit Swag.Doc.Path.Operation;

interface

uses
  System.Generics.Collections,
  System.JSON,
  Swag.Common.Types,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.Path.Operation.RequestParameter;

type

  TSwagPathOperation = class(TObject)
  private
    fOperation: TSwagPathTypeOperation;
    fDescription: string;
    fConsumes: TList<TSwagMimeType>;
    fProduces: TList<TSwagMimeType>;
    fParameters: TObjectList<TSwagRequestParameter>;
    fResponses: TObjectDictionary<TSwagStatusCode, TSwagResponse>;
    fSecurity: TList<TSwagSecuritySchemaName>;
    fTags: TList<string>;
    function GetOperationToString: string;
  protected
    function GenerateTagsJsonArray(pTagList: TList<string>): TJSONArray;
    function GenerateMimeTypesJsonArray(pMimeTypesList: TList<TSwagMimeType>): TJSONArray;
    function GenerateParametersJsonArray: TJSONArray;
    function GenarateResponsesJsonObject: TJSONObject;
    function GenerateSecurityJsonArray: TJSONArray;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;

    property Operation: TSwagPathTypeOperation read fOperation write fOperation;
    property OperationToString: string read GetOperationToString;

    property Description: string read fDescription write fDescription;
    property Tags: TList<string> read fTags;
    property Consumes: TList<TSwagMimeType> read fConsumes;
    property Produces: TList<TSwagMimeType> read fProduces;
    property Parameters: TObjectList<TSwagRequestParameter> read fParameters;
    property Responses: TObjectDictionary<TSwagStatusCode, TSwagResponse> read fResponses;
    property Security: TList<TSwagSecuritySchemaName> read fSecurity;
  end;

implementation

uses
  System.SysUtils,
  Swag.Common.Consts;

const
  c_SwagPathOperationDescription = 'description';
  c_SwagPathOperationTags = 'tags';
  c_SwagPathOperationProduces = 'produces';
  c_SwagPathOperationConsumes = 'consumes';
  c_SwagPathOperationParameters = 'parameters';
  c_SwagPathOperationResponses = 'responses';
  c_SwagPathOperationSecurity = 'security';

{ TSwagPathOperation }

constructor TSwagPathOperation.Create;
begin
  inherited Create;

  fTags := TList<string>.Create;
  fConsumes := TList<TSwagMimeType>.Create;
  fProduces := TList<TSwagMimeType>.Create;
  fParameters := TObjectList<TSwagRequestParameter>.Create;
  fResponses := TObjectDictionary<TSwagStatusCode, TSwagResponse>.Create([doOwnsValues]);
  fSecurity := TList<TSwagSecuritySchemaName>.Create;
end;

destructor TSwagPathOperation.Destroy;
begin
  FreeAndNil(fProduces);
  FreeAndNil(fConsumes);
  FreeAndNil(fResponses);
  FreeAndNil(fParameters);
  FreeAndNil(fSecurity);
  FreeAndNil(fTags);

  inherited Destroy;
end;

function TSwagPathOperation.GetOperationToString: string;
begin
  Result := c_SwagPathOperationHttpVerbs[fOperation];
end;

function TSwagPathOperation.GenarateResponsesJsonObject: TJSONObject;
var
  vResponse: TSwagResponse;
  vResponsesSortedArray: TArray<TSwagStatusCode>;
  vStatusCode: TSwagStatusCode;
begin
  Result := TJsonObject.Create;
  vResponsesSortedArray := fResponses.Keys.ToArray;
  TArray.Sort<TSwagStatusCode>(vResponsesSortedArray);
  for vStatusCode in vResponsesSortedArray do
  begin
    vResponse := fResponses.Items[vStatusCode];
    Result.AddPair(vResponse.StatusCode, vResponse.GenerateJsonObject);
  end;
end;

function TSwagPathOperation.GenerateMimeTypesJsonArray(pMimeTypesList: TList<TSwagMimeType>): TJSONArray;
var
  vIndex: Integer;
begin
  Result := TJSONArray.Create;
  for vIndex := 0 to pMimeTypesList.Count -1 do
    Result.Add(pMimeTypesList.Items[vIndex]);
end;

function TSwagPathOperation.GenerateParametersJsonArray: TJSONArray;
var
  vIndex: Integer;
begin
  Result := TJSONArray.Create;
  for vIndex := 0 to fParameters.Count - 1 do
    Result.Add(fParameters.Items[vIndex].GenerateJsonObject);
end;

// suports only JWT in swagger version 2.0
function TSwagPathOperation.GenerateSecurityJsonArray: TJSONArray;
var
  vIndex: Integer;
  vJsonItem: TJsonObject;
  vJsonListSecurityScopes: TJSONArray;
begin
  Result := TJSONArray.Create;
  for vIndex := 0 to fSecurity.Count - 1 do
  begin
    vJsonListSecurityScopes := TJSONArray.Create;
    vJsonItem := TJsonObject.Create;
    vJsonItem.AddPair(fSecurity.Items[vIndex], vJsonListSecurityScopes);
    Result.Add(vJsonItem);
  end;
end;

function TSwagPathOperation.GenerateTagsJsonArray(pTagList: TList<string>): TJSONArray;
var
  vIndex: Integer;
begin
  Result := TJSONArray.Create;
  for vIndex := 0 to pTagList.Count -1 do
    Result.Add(pTagList.Items[vIndex]);
end;

function TSwagPathOperation.GenerateJsonObject: TJSONObject;
var
  vJsonObject: TJsonObject;
begin
  vJsonObject := TJsonObject.Create;
  vJsonObject.AddPair(c_SwagPathOperationDescription, fDescription);
  if (fTags.Count > 0) then
    vJsonObject.AddPair(c_SwagPathOperationTags, GenerateTagsJsonArray(fTags));
  if (fConsumes.Count > 0) then
    vJsonObject.AddPair(c_SwagPathOperationConsumes, GenerateMimeTypesJsonArray(fConsumes));
  if (fProduces.Count > 0) then
    vJsonObject.AddPair(c_SwagPathOperationProduces, GenerateMimeTypesJsonArray(fProduces));
  if (fParameters.Count > 0) then
    vJsonObject.AddPair(c_SwagPathOperationParameters, GenerateParametersJsonArray);
  if (fResponses.Count > 0) then
    vJsonObject.AddPair(c_SwagPathOperationResponses, GenarateResponsesJsonObject);
  if (fSecurity.Count > 0) then
    vJsonObject.AddPair(c_SwagPathOperationSecurity, GenerateSecurityJsonArray);
  Result := vJsonObject;
end;

end.
