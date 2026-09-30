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

unit Dext.SwagDoc.Discovery;

interface

uses
  Swag.Doc,
  Dext.Web.Interfaces;

type
  /// <summary>
  /// Adds to the document the endpoints registered in Dext, both the Minimal API ones and the ones of the
  /// controllers, with what Dext knows about each of them: the summary, the description, the tags, the request
  /// and response types, the documented responses and the security schemes. An operation already written in
  /// the document is kept as it is, so the application can replace any discovered operation by its own.
  /// </summary>
  TDextSwagDocDiscovery = class(TObject)
  public
    /// <summary>
    /// Documents the given endpoints, except the ones whose route is in pIgnoredRoutes. The endpoints of
    /// controllers marked with [Authorize] without a scheme name are written with pDefaultSecurityScheme,
    /// when it is not empty.
    /// </summary>
    class procedure DocumentEndpoints(pSwagDoc: TSwagDoc; const pEndpoints: TArray<TEndpointMetadata>;
      const pIgnoredRoutes: TArray<string>; const pDefaultSecurityScheme: string); static;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Swag.Common.Types,
  Swag.Doc.Definition,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.SecurityDefinition,
  Swag.Doc.SecurityDefinitionHttp,
  Swag.Doc.Schema.Builder,
  Dext.SwagDoc.Config,
  Dext.SwagDoc.Route,
  Dext.SwagDoc.Schema;

const
  c_MimeTypeJson = 'application/json';
  c_SuccessDescription = 'Successful response';
  c_CreatedDescription = 'Created';
  c_NoContentDescription = 'No Content';
  c_ResponseDescription = 'Response %d';
  c_BearerScheme = 'bearer';
  c_BearerFormat = 'JWT';

type
  TDextSwagDocOperationWriter = class(TObject)
  strict private
    fSwagDoc: TSwagDoc;
    fBuilder: TSwagSchemaBuilder;
    fDefaultSecurityScheme: string;
    function HasSuccessResponse(const pEndpoint: TEndpointMetadata): Boolean;
    function AddResponse(pOperation: TSwagPathOperation; const pStatusCode: Integer;
      const pDescription: string): TSwagResponse;
    procedure AssignSchema(pTypeInfo: PTypeInfo; pTarget: TSwagDefinition);
    procedure WriteRequestBody(pOperation: TSwagPathOperation; const pEndpoint: TEndpointMetadata);
    procedure WriteDefaultResponse(pOperation: TSwagPathOperation; const pEndpoint: TEndpointMetadata);
    procedure WriteResponses(pOperation: TSwagPathOperation; const pEndpoint: TEndpointMetadata);
    procedure WriteSecurity(pOperation: TSwagPathOperation; const pEndpoint: TEndpointMetadata);
    procedure EnsureSecurityDefinition(const pSchemeName: string);
  public
    constructor Create(pSwagDoc: TSwagDoc; const pDefaultSecurityScheme: string); reintroduce;
    destructor Destroy; override;
    procedure Write(pPath: TSwagPath; const pOperationType: TSwagPathTypeOperation;
      const pEndpoint: TEndpointMetadata);
  end;

function TryConvertMethod(const pMethod: string; out pOperation: TSwagPathTypeOperation): Boolean;
var
  vMethod: string;
begin
  Result := True;
  vMethod := pMethod.ToUpper;
  if vMethod = 'GET' then
    pOperation := ohvGet
  else if vMethod = 'POST' then
    pOperation := ohvPost
  else if vMethod = 'PUT' then
    pOperation := ohvPut
  else if vMethod = 'DELETE' then
    pOperation := ohvDelete
  else if vMethod = 'PATCH' then
    pOperation := ohvPatch
  else if vMethod = 'HEAD' then
    pOperation := ohvHead
  else if vMethod = 'OPTIONS' then
    pOperation := ohvOptions
  else if vMethod = 'TRACE' then
    pOperation := ohvTrace
  else if vMethod = 'QUERY' then
    pOperation := ohvQuery
  else
  begin
    pOperation := ohvNotDefined;
    Result := False;
  end;
end;

function IsIgnoredRoute(const pRoute: string; const pIgnoredRoutes: TArray<string>): Boolean;
var
  vIgnoredRoute: string;
begin
  Result := False;
  for vIgnoredRoute in pIgnoredRoutes do
    if SameText(pRoute, vIgnoredRoute) then
      Exit(True);
end;

function HasOperation(pPath: TSwagPath; const pOperation: TSwagPathTypeOperation): Boolean;
var
  vOperation: TSwagPathOperation;
begin
  Result := False;
  for vOperation in pPath.Operations do
    if vOperation.Operation = pOperation then
      Exit(True);
end;

{ TDextSwagDocOperationWriter }

constructor TDextSwagDocOperationWriter.Create(pSwagDoc: TSwagDoc; const pDefaultSecurityScheme: string);
begin
  inherited Create;
  fSwagDoc := pSwagDoc;
  fDefaultSecurityScheme := pDefaultSecurityScheme;
  fBuilder := TDextSwagSchemaBuilder.Create(pSwagDoc);
end;

destructor TDextSwagDocOperationWriter.Destroy;
begin
  FreeAndNil(fBuilder);
  inherited Destroy;
end;

procedure TDextSwagDocOperationWriter.Write(pPath: TSwagPath; const pOperationType: TSwagPathTypeOperation;
  const pEndpoint: TEndpointMetadata);
var
  vOperation: TSwagPathOperation;
  vTag: string;
begin
  vOperation := pPath.AddOperation(pOperationType);
  vOperation.Summary := pEndpoint.Summary;
  vOperation.Description := pEndpoint.Description;
  for vTag in pEndpoint.Tags do
    if not vTag.IsEmpty then
      vOperation.Tags.Add(vTag);

  WriteRequestBody(vOperation, pEndpoint);
  if not HasSuccessResponse(pEndpoint) then
    WriteDefaultResponse(vOperation, pEndpoint);
  WriteResponses(vOperation, pEndpoint);
  WriteSecurity(vOperation, pEndpoint);
end;

procedure TDextSwagDocOperationWriter.AssignSchema(pTypeInfo: PTypeInfo; pTarget: TSwagDefinition);
begin
  if Assigned(pTypeInfo) then
    fBuilder.AssignType(pTypeInfo, pTarget);
end;

function TDextSwagDocOperationWriter.AddResponse(pOperation: TSwagPathOperation; const pStatusCode: Integer;
  const pDescription: string): TSwagResponse;
var
  vStatusCode: string;
begin
  vStatusCode := IntToStr(pStatusCode);
  pOperation.Responses.Remove(vStatusCode);

  Result := TSwagResponse.Create;
  Result.StatusCode := vStatusCode;
  Result.Description := pDescription;
  if Result.Description.IsEmpty then
    Result.Description := Format(c_ResponseDescription, [pStatusCode]);
  pOperation.Responses.Add(vStatusCode, Result);
end;

function TDextSwagDocOperationWriter.HasSuccessResponse(const pEndpoint: TEndpointMetadata): Boolean;
var
  vResponse: TOpenAPIResponseMetadata;
begin
  Result := False;
  for vResponse in pEndpoint.Responses do
    if (vResponse.StatusCode >= 200) and (vResponse.StatusCode < 300) then
      Exit(True);
end;

procedure TDextSwagDocOperationWriter.WriteRequestBody(pOperation: TSwagPathOperation;
  const pEndpoint: TEndpointMetadata);
begin
  if not Assigned(pEndpoint.RequestType) then
    Exit;
  if not (pOperation.Operation in [ohvPost, ohvPut, ohvPatch, ohvQuery]) then
    Exit;

  pOperation.RequestBody.Required := True;
  AssignSchema(pEndpoint.RequestType, pOperation.RequestBody.AddMediaType(c_MimeTypeJson).Schema);
end;

procedure TDextSwagDocOperationWriter.WriteDefaultResponse(pOperation: TSwagPathOperation;
  const pEndpoint: TEndpointMetadata);
var
  vResponse: TSwagResponse;
begin
  case pOperation.Operation of
    ohvPost:
      vResponse := AddResponse(pOperation, 201, c_CreatedDescription);
    ohvDelete:
      begin
        AddResponse(pOperation, 204, c_NoContentDescription);
        Exit;
      end;
  else
    vResponse := AddResponse(pOperation, 200, c_SuccessDescription);
  end;

  if Assigned(pEndpoint.ResponseType) then
    AssignSchema(pEndpoint.ResponseType, vResponse.AddMediaType(c_MimeTypeJson).Schema);
end;

procedure TDextSwagDocOperationWriter.WriteResponses(pOperation: TSwagPathOperation;
  const pEndpoint: TEndpointMetadata);
var
  vMetadata: TOpenAPIResponseMetadata;
  vResponse: TSwagResponse;
  vMediaType: string;
  vSchemaType: PTypeInfo;
begin
  for vMetadata in pEndpoint.Responses do
  begin
    vResponse := AddResponse(pOperation, vMetadata.StatusCode, vMetadata.Description);
    if vMetadata.StatusCode = 204 then
      Continue;

    vSchemaType := vMetadata.SchemaType;
    if not Assigned(vSchemaType) and (vMetadata.StatusCode >= 200) and (vMetadata.StatusCode < 300) then
      vSchemaType := pEndpoint.ResponseType;
    if not Assigned(vSchemaType) then
      Continue;

    vMediaType := vMetadata.MediaType;
    if vMediaType.IsEmpty then
      vMediaType := c_MimeTypeJson;
    AssignSchema(vSchemaType, vResponse.AddMediaType(vMediaType).Schema);
  end;
end;

procedure TDextSwagDocOperationWriter.WriteSecurity(pOperation: TSwagPathOperation;
  const pEndpoint: TEndpointMetadata);
var
  vScheme: string;
  vSchemeName: string;
begin
  for vScheme in pEndpoint.Security do
  begin
    vSchemeName := vScheme;
    if vSchemeName.IsEmpty then
      vSchemeName := fDefaultSecurityScheme;
    if vSchemeName.IsEmpty or pOperation.Security.Contains(vSchemeName) then
      Continue;

    pOperation.Security.Add(vSchemeName);
    EnsureSecurityDefinition(vSchemeName);
  end;

  if pEndpoint.AllowAnonymous and (pOperation.Security.Count = 0) and
    ((fSwagDoc.SecurityRequirements.Count > 0) or fSwagDoc.GlobalSecurityFromDefinitions) then
    pOperation.DisableSecurity := True;
end;

procedure TDextSwagDocOperationWriter.EnsureSecurityDefinition(const pSchemeName: string);
var
  vDefinition: TSwagSecurityDefinition;
  vBearer: TSwagSecurityDefinitionHttp;
begin
  if pSchemeName <> c_DextSwagDocBearerSchemeName then
    Exit;

  for vDefinition in fSwagDoc.SecurityDefinitions do
    if vDefinition.SchemeName = pSchemeName then
      Exit;

  vBearer := TSwagSecurityDefinitionHttp.Create;
  vBearer.SchemeName := pSchemeName;
  vBearer.Scheme := c_BearerScheme;
  vBearer.BearerFormat := c_BearerFormat;
  fSwagDoc.SecurityDefinitions.Add(vBearer);
end;

{ TDextSwagDocDiscovery }

class procedure TDextSwagDocDiscovery.DocumentEndpoints(pSwagDoc: TSwagDoc;
  const pEndpoints: TArray<TEndpointMetadata>; const pIgnoredRoutes: TArray<string>;
  const pDefaultSecurityScheme: string);
var
  vWriter: TDextSwagDocOperationWriter;
  vEndpoint: TEndpointMetadata;
  vRoute: string;
  vOperationType: TSwagPathTypeOperation;
  vPath: TSwagPath;
begin
  vWriter := TDextSwagDocOperationWriter.Create(pSwagDoc, pDefaultSecurityScheme);
  try
    for vEndpoint in pEndpoints do
    begin
      vRoute := TDextSwagDocRoute.NormalizeRoute(vEndpoint.Path);
      if IsIgnoredRoute(vRoute, pIgnoredRoutes) then
        Continue;

      if not TryConvertMethod(vEndpoint.Method, vOperationType) then
        Continue;

      vPath := TDextSwagDocRoute.AddPath(pSwagDoc, vRoute);
      if not HasOperation(vPath, vOperationType) then
        vWriter.Write(vPath, vOperationType, vEndpoint);
    end;
  finally
    vWriter.Free;
  end;
end;

end.
