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

unit Swag.Doc.SecurityDefinitionOAuth2;

interface

uses
  System.JSON,
  System.SysUtils,
  Generics.Collections,
  Swag.Common.Types,
  Swag.Doc.SecurityDefinition;

type
  TSwagSecurityDefinitionOAuth2Scope = class(TObject)
  private
    fScopeName: string;
    fDescription: string;

  public
    property ScopeName: string read fScopeName write fScopeName;
    property Description: string read fDescription write fDescription;

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson: TJSONPair);

  end;


  /// <summary>
  /// The security scheme object for OAuth2 
  /// </summary>
  TSwagSecurityDefinitionOAuth2 = class(TSwagSecurityDefinition)
  private
    fName: string;
    fAuthorizationUrl: string;
    fFlow: string;
    fScopes : TObjectList<TSwagSecurityDefinitionOAuth2Scope>;
  protected
    function GetTypeSecurity: TSwagSecurityDefinitionType; override;
  public
    function GenerateJsonObject: TJSONObject; override;
    procedure Load(pJson: TJSONObject); override;

    property Name: string read fName write fName;
    property AuthorizationUrl: string read fAuthorizationUrl write fAuthorizationUrl;
    property Flow: string read fFlow write fFlow;
    property Scopes: TObjectList<TSwagSecurityDefinitionOAuth2Scope> read fScopes;

    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

const
  c_SwagSecurityDefinitionOAuth2Type = 'type';
  c_SwagSecurityDefinitionOAuth2Description = 'description';
  c_SwagSecurityDefinitionOAuth2Name = 'name';
  c_SwagSecurityDefinitionOAuth2AuthorizationUrl = 'authorizationUrl';
  c_SwagSecurityDefinitionOAuth2Flow = 'flow';
  c_SwagSecurityDefinitionOAuth2Scopes = 'scopes';


{ TSwagSecurityDefinitionOAuth2 }

constructor TSwagSecurityDefinitionOAuth2.Create;
begin
  inherited;
  fScopes := TObjectList<TSwagSecurityDefinitionOAuth2Scope>.Create;
end;

destructor TSwagSecurityDefinitionOAuth2.Destroy;
begin
  FreeAndNil(fScopes);
  inherited;
end;

function TSwagSecurityDefinitionOAuth2.GenerateJsonObject: TJSONObject;
var
  vJsonItem: TJsonObject;
  vJsonScopes : TJsonObject;
  i: Integer;
begin
  vJsonItem := TJsonObject.Create;
  vJsonItem.AddPair(c_SwagSecurityDefinitionOAuth2Type, ReturnTypeSecurityToString);
  if fDescription.Length > 0 then
    vJsonItem.AddPair(c_SwagSecurityDefinitionOAuth2Description, fDescription);
  vJsonItem.AddPair(c_SwagSecurityDefinitionOAuth2AuthorizationUrl, fAuthorizationUrl);
  vJsonItem.AddPair(c_SwagSecurityDefinitionOAuth2Flow, fFlow);

  if FScopes.Count > 0 then
  begin
    vJsonScopes := TJSONObject.Create;
    for i := 0 to FScopes.Count - 1 do
    begin
      vJsonScopes.AddPair(FScopes[i].ScopeName, fScopes[i].fDescription);
    end;
    vJsonItem.AddPair('scopes', vJsonScopes);
  end;

  Result := vJsonItem;
end;

function TSwagSecurityDefinitionOAuth2.GetTypeSecurity: TSwagSecurityDefinitionType;
begin
  Result := TSwagSecurityDefinitionType.ssdOAuth2;
end;

procedure TSwagSecurityDefinitionOAuth2.Load(pJson: TJSONObject);
var
  i: Integer;
  vJsonScope : TJSONObject;
  vScope : TSwagSecurityDefinitionOAuth2Scope;
begin
  inherited;
  if Assigned(pJson.Values[c_SwagSecurityDefinitionOAuth2Description]) then
    fDescription := pJson.Values[c_SwagSecurityDefinitionOAuth2Description].Value;
  if Assigned(pJson.Values[c_SwagSecurityDefinitionOAuth2AuthorizationUrl]) then
    fAuthorizationUrl := pJson.Values[c_SwagSecurityDefinitionOAuth2AuthorizationUrl].Value;
  if Assigned(pJson.Values[c_SwagSecurityDefinitionOAuth2Flow]) then
    fFlow := pJson.Values[c_SwagSecurityDefinitionOAuth2Flow].Value;
  if Assigned(pJson.Values[c_SwagSecurityDefinitionOAuth2Scopes]) then
  begin
    vJsonScope := pJson.Values[c_SwagSecurityDefinitionOAuth2Scopes] as TJSONObject;
    for i := 0 to vJsonScope.Count - 1 do
    begin
      vScope := TSwagSecurityDefinitionOAuth2Scope.Create;
      vScope.Load(vJsonScope.Pairs[i]);
      fScopes.Add(vScope);
    end;
  end;
end;

{ TSwagSecurityDefinitionOAuth2Scopes }

function TSwagSecurityDefinitionOAuth2Scope.GenerateJsonObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(fScopeName, fDescription);
end;

procedure TSwagSecurityDefinitionOAuth2Scope.Load(pJson: TJSONPair);
var
  i: Integer;
  vScope : TSwagSecurityDefinitionOAuth2Scope;
begin
  inherited;
  fScopeName := pJson.JsonString.Value;
  fDescription := pJson.JsonValue.Value;
end;

initialization
  AddSecurityDefinition('oauth2', TSwagSecurityDefinitionOAuth2);
end.
