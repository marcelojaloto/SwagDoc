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

unit Swag.Doc.SecurityDefinition;

interface

uses
  System.JSON, System.SysUtils, System.Generics.Collections, Swag.Common.Types;

type
  TSwagSecurityDefinitionClass = class of TSwagSecurityDefinition;

  /// <summary>
  /// A declaration of the security schemes available to be used in the specification.
  /// This does not enforce the security schemes on the operations and only serves to provide the relevant details for each scheme.
  /// </summary>
  TSwagSecurityDefinition = class (TObject)
  protected
    fSchemaName: TSwagSecuritySchemeName;
    fDescription: string;
    function GetTypeSecurity: TSwagSecurityDefinitionType; virtual; abstract;
    function ReturnTypeSecurityToString: string; virtual;
  public
    function GenerateJsonObject: TJSONObject; virtual; abstract;
    procedure Load(pJson: TJSONObject); virtual; abstract;
    class function GetSecurityDefinitionClass(pJson: TJSONObject): TSwagSecurityDefinitionClass;

    /// <summary>
    /// A single security scheme definition, mapping a "name" to the scheme it defines.
    /// </summary>
    property SchemeName: TSwagSecuritySchemeName read fSchemaName write fSchemaName;

    /// <summary>
    /// Required. The type of the security scheme. Valid values are "basic", "apiKey" or "oauth2".
    /// </summary>
    property TypeSecurity: TSwagSecurityDefinitionType read GetTypeSecurity;

    /// <summary>
    /// A short description for security scheme.
    /// </summary>
    property Description: string read fDescription write fDescription;

    constructor Create; virtual; abstract;
  end;


procedure AddSecurityDefinition(pName: string; pClass: TSwagSecurityDefinitionClass);

implementation

uses
  Swag.Common.Consts;

var
  securityTypes: TObjectDictionary<string, TSwagSecurityDefinitionClass>;

procedure AddSecurityDefinition(pName: string; pClass: TSwagSecurityDefinitionClass);
begin
  securityTypes.Add(pName, pClass);
end;

{ TSwagSecurityDefinition }

class function TSwagSecurityDefinition.GetSecurityDefinitionClass(pJson: TJSONObject): TSwagSecurityDefinitionClass;
var
  vSecurityType : string;
begin
  Result := nil;
  if not Assigned(pJson) then
    Exit;
  if Assigned(pJson.Values['type']) then
    vSecurityType := pJson.Values['type'].Value;
  if securityTypes.ContainsKey(vSecurityType) then
    Result := securityTypes.Items[vSecurityType];
end;

function TSwagSecurityDefinition.ReturnTypeSecurityToString: string;
begin
  Result := c_SwagSecurityDefinitionType[GetTypeSecurity];
end;

initialization
  securityTypes := TObjectDictionary<string, TSwagSecurityDefinitionClass>.Create;

finalization
  FreeAndNil(securityTypes);

end.

