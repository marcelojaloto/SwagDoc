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

unit Swag.Doc;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  Swag.Common.Types,
  Swag.Doc.Info,
  Swag.Doc.Info.License,
  Swag.Doc.SecurityDefinition,
  Swag.Doc.Path,
  Swag.Doc.Definition;

type
  TSwagDoc = class(TObject)
  private
    fInfo: TSwagInfo;
    fLicense: TSwagInfoLicense;
    fConsumes: TList<TSwagMimeType>;
    fProduces: TList<TSwagMimeType>;
    fBasePath: string;
    fHost: string;
    fSchemes: TSwagTransferProtocolSchemes;
    fPaths: TObjectList<TSwagPath>;
    fDefinitions: TObjectList<TSwagDefinition>;
    fSecurityDefinitions: TObjectList<TSwagSecurityDefinition>;
    fSwaggerJson: TJSONValue;
    fSwaggerFilesFolder: string;
    function GetSwaggerVersion: string;
    procedure SetSwaggerFilesFolder(const Value: string);
  protected
    function GenerateSchemesJsonArray: TJSONArray;
    function GenerateSecurityDefinitionsJsonObject: TJSONObject;
    function GenerateConsumesJsonArray: TJSONArray;
    function GenerateProducesJsonArray: TJSONArray;
    function GeneratePathsJsonObject: TJSONObject;
    function GenerateDefinitionsJsonObject: TJSONObject;

    function GenerateMimeTypesJsonArray(pMimeTypesList: TList<TSwagMimeType>): TJSONArray;
    function ReturnSwaggerFileName: string;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    procedure GenerateSwaggerJson;
    procedure SaveSwaggerJsonToFile;

    procedure LoadFromFile(const pFilename: string);

    property SwaggerFilesFolder: string read fSwaggerFilesFolder write SetSwaggerFilesFolder;
    property SwaggerJson: TJSONValue read fSwaggerJson;

    property SwaggerVersion: string read GetSwaggerVersion;
    property Info: TSwagInfo read fInfo;
    property License: TSwagInfoLicense read fLicense;
    property Host: string read fHost write fHost;
    property BasePath: string read fBasePath write fBasePath;
    property Schemes: TSwagTransferProtocolSchemes read fSchemes write fSchemes;
    property SecurityDefinitions: TObjectList<TSwagSecurityDefinition> read fSecurityDefinitions;
    property Consumes: TList<TSwagMimeType> read fConsumes;
    property Produces: TList<TSwagMimeType> read fProduces;
    property Paths: TObjectList<TSwagPath> read fPaths;
    property Definitions: TObjectList<TSwagDefinition> read fDefinitions;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  REST.Json,
  Swag.Common.Consts,
  Swag.Common.Types.Helpers;

const
  c_Swagger = 'swagger';
  c_SwagInfo = 'info';
  c_SwagLicense = 'license';
  c_SwagHost = 'host';
  c_SwagBasePath = 'basePath';
  c_SwagSchemes = 'schemes';
  c_SwagSecurityDefinitions = 'securityDefinitions';
  c_SwagConsumes = 'consumes';
  c_SwagProduces = 'produces';
  c_SwagPaths = 'paths';
  c_SwagDefinitions = 'definitions';

{ TSwagDoc }

constructor TSwagDoc.Create;
begin
  inherited Create;

  fInfo := TSwagInfo.Create;
  fLicense := TSwagInfoLicense.Create;
  fSecurityDefinitions := TObjectList<TSwagSecurityDefinition>.Create;
  fConsumes := TList<string>.Create;
  fProduces := TList<string>.Create;
  fPaths := TObjectList<TSwagPath>.Create;
  fDefinitions := TObjectList<TSwagDefinition>.Create;
end;

destructor TSwagDoc.Destroy;
begin
  FreeAndNil(fConsumes);
  FreeAndNil(fProduces);
  FreeAndNil(fDefinitions);
  FreeAndNil(fPaths);
  FreeAndNil(fInfo);
  FreeAndNil(fSecurityDefinitions);
  FreeAndNil(fLicense);

  if Assigned(fSwaggerJson) then
    FreeAndNil(fSwaggerJson);

  inherited Destroy;
end;

procedure TSwagDoc.SaveSwaggerJsonToFile;
var
  vJsonFile: TStringStream;
begin
  if not Assigned(fSwaggerJson) then
    Exit;

  if not System.SysUtils.DirectoryExists(fSwaggerFilesFolder) then
    System.SysUtils.ForceDirectories(fSwaggerFilesFolder);

  vJsonFile := TStringStream.Create(TJson.Format(fSwaggerJson));
  try
    vJsonFile.SaveToFile(ReturnSwaggerFileName);
  finally
    FreeAndNil(vJsonFile);
  end;
end;

function TSwagDoc.GenerateMimeTypesJsonArray(pMimeTypesList: TList<TSwagMimeType>): TJSONArray;
var
  vIndex: Integer;
begin
  Result := TJSONArray.Create;
  for vIndex := 0 to pMimeTypesList.Count -1 do
    Result.Add(pMimeTypesList.Items[vIndex]);
end;

function TSwagDoc.GenerateConsumesJsonArray: TJSONArray;
begin
  Result := GenerateMimeTypesJsonArray(fConsumes);
end;

function TSwagDoc.GenerateProducesJsonArray: TJSONArray;
begin
  Result := GenerateMimeTypesJsonArray(fProduces);
end;

function TSwagDoc.GenerateDefinitionsJsonObject: TJSONObject;
var
  vIndex: integer;
begin
  Result := TJsonObject.Create;
  for vIndex := 0 to fDefinitions.Count -1 do
    Result.AddPair(fDefinitions.Items[vIndex].Name, fDefinitions.Items[vIndex].JsonSchema);
end;

function TSwagDoc.GeneratePathsJsonObject: TJSONObject;
var
  vIndex: integer;
begin
  Result := TJsonObject.Create;
  for vIndex := 0 to fPaths.Count -1 do
    Result.AddPair(fPaths.Items[vIndex].Uri, fPaths.Items[vIndex].GenerateJsonObject);
end;

function TSwagDoc.GenerateSchemesJsonArray: TJSONArray;
var
  vScheme: TSwagTransferProtocolScheme;
begin
  Result := TJSONArray.Create;
  for vScheme := Low(TSwagTransferProtocolScheme) to high(TSwagTransferProtocolScheme) do
  begin
    if vScheme in fSchemes then
      Result.Add(c_SwagTransferProtocolScheme[vScheme]);
  end;
end;

function TSwagDoc.GenerateSecurityDefinitionsJsonObject: TJSONObject;
var
  vIndex: integer;
begin
  Result := TJsonObject.Create;
  for vIndex := 0 to fSecurityDefinitions.Count -1 do
    Result.AddPair(fSecurityDefinitions.Items[vIndex].SchemaName, fSecurityDefinitions.Items[vIndex].GenerateJsonObject);
end;

procedure TSwagDoc.GenerateSwaggerJson;
var
  vJsonObject: TJsonObject;
begin
  vJsonObject := TJsonObject.Create;

  vJsonObject.AddPair(c_Swagger, GetSwaggerVersion);
  vJsonObject.AddPair(c_SwagInfo, fInfo.GenerateJsonObject);

  if not fLicense.isEmpty then
    vJsonObject.AddPair(c_SwagLicense,fLicense.GenerateJsonObject);

  if not fHost.IsEmpty then
    vJsonObject.AddPair(c_SwagHost, fHost);
  vJsonObject.AddPair(c_SwagBasePath, fBasePath);

  if (fSchemes <> []) then
    vJsonObject.AddPair(c_SwagSchemes, GenerateSchemesJsonArray);

  if (fSecurityDefinitions.Count > 0) then
    vJsonObject.AddPair(c_SwagSecurityDefinitions, GenerateSecurityDefinitionsJsonObject);

  if (fConsumes.Count > 0) then
    vJsonObject.AddPair(c_SwagConsumes, GenerateConsumesJsonArray);

  if (fProduces.Count > 0) then
    vJsonObject.AddPair(c_SwagProduces, GenerateProducesJsonArray);

  if (fPaths.Count > 0) then
    vJsonObject.AddPair(c_SwagPaths, GeneratePathsJsonObject);

  if (fDefinitions.Count > 0) then
    vJsonObject.AddPair(c_SwagDefinitions, GenerateDefinitionsJsonObject);

  if Assigned(fSwaggerJson) then
    fSwaggerJson.Free;
  fSwaggerJson := vJsonObject;
end;

function TSwagDoc.GetSwaggerVersion: string;
begin
  Result := c_SwaggerVersion;
end;

procedure TSwagDoc.LoadFromFile(const pFilename: string);
var
  vJsonObj: TJSONObject;
  vPath: TSwagPath;
  vJsonSchemesArray: TJSONArray;
  vJsonProduces: TJSONArray;
  vJsonConsumes: TJSONArray;
  vIndex: Integer;
begin

  if not FileExists(pFilename) then
  begin
    raise Exception.Create('File Doesn''t Exist ['+pFilename+']');
  end;

  fSwaggerJson := TJSONObject.ParseJSONValue(TFile.ReadAllText(pFilename));
  fInfo.Load((fSwaggerJson as TJSONObject).Values[c_SwagInfo] as TJSONObject);

  fLicense.Load((fSwaggerJson as TJSONObject).Values[c_SwagLicense] as TJSONObject);

  vJsonObj := (fSwaggerJson as TJSONObject).Values[c_SwagPaths] as TJSONObject;
  vJsonSchemesArray := (fSwaggerJson as TJSONObject).Values[c_SwagSchemes] as TJSONArray;

  for vIndex := 0 to vJsonSchemesArray.Count - 1 do
  begin
    fSchemes.Add(vJsonSchemesArray.Items[vIndex].Value);
  end;

  fHost := (fSwaggerJson as TJSONObject).Values[c_SwagHost].Value;
  fBasePath := (fSwaggerJson as TJSONObject).Values[c_SwagBasePath].Value;

  for vIndex := 0 to vJsonObj.Count - 1 do
  begin
    vPath := TSwagPath.Create;
    vPath.Uri := vJsonObj.Pairs[vIndex].JSONString.Value;
    vPath.Load((vJsonObj.Pairs[vIndex].JsonValue) as TJSONObject);
    fPaths.Add(vPath);
  end;

  vJsonProduces := (fSwaggerJson as TJSONObject).Values[c_SwagProduces] as TJSONArray;
  for vIndex := 0 to vJsonProduces.Count - 1 do
  begin
    Produces.Add(vJsonProduces.Items[vIndex].Value);
  end;

  vJsonConsumes := (fSwaggerJson as TJSONObject).Values[c_SwagConsumes] as TJSONArray;
  for vIndex := 0 to vJsonConsumes.count - 1 do
  begin
    Consumes.Add(vJsonConsumes.Items[vIndex].Value);
  end;
end;

function TSwagDoc.ReturnSwaggerFileName: string;
begin
  Result := fSwaggerFilesFolder + c_SwaggerFileName;
end;

procedure TSwagDoc.SetSwaggerFilesFolder(const Value: string);
begin
  fSwaggerFilesFolder := IncludeTrailingPathDelimiter(Trim(Value));
end;

end.
