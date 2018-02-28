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

unit Swag.Doc.SecurityDefinitionApiKey;

interface

uses
  System.JSON,
  Swag.Common.Types,
  Swag.Doc.SecurityDefinition;

type
  TSwagSecurityDefinitionApiKeyInLocation = (kilNotDefined, kilQuery, kilHeader);

  TSwagSecurityDefinitionApiKey = class(TSwagSecurityDefinition)
  private
    fName: string;
    fInLocation: TSwagSecurityDefinitionApiKeyInLocation;
  protected
    function GetTypeSecurity: TSwagSecurityDefinitionType; override;
    function ReturnInLocationToString: string;
  public
    function GenerateJsonObject: TJSONObject; override;

    property InLocation: TSwagSecurityDefinitionApiKeyInLocation read fInLocation write fInLocation;
    property Name: string read fName write fName;
  end;

implementation

const
  c_SwagSecurityDefinitionApiKeyType = 'type';
  c_SwagSecurityDefinitionApiKeyDescription = 'description';
  c_SwagSecurityDefinitionApiKeyIn = 'in';
  c_SwagSecurityDefinitionApiKeyName = 'name';

{ TSwagSecurityDefinitionApiKey }

function TSwagSecurityDefinitionApiKey.GenerateJsonObject: TJSONObject;
var
  vJsonItem: TJsonObject;
begin
  vJsonItem := TJsonObject.Create;
  vJsonItem.AddPair(c_SwagSecurityDefinitionApiKeyType, ReturnTypeSecurityToString);
  vJsonItem.AddPair(c_SwagSecurityDefinitionApiKeyDescription, fDescription);
  vJsonItem.AddPair(c_SwagSecurityDefinitionApiKeyIn, ReturnInLocationToString);
  vJsonItem.AddPair(c_SwagSecurityDefinitionApiKeyName, fName);

  Result := vJsonItem;
end;

function TSwagSecurityDefinitionApiKey.ReturnInLocationToString: string;
begin
  case fInLocation of
    kilQuery: Result := 'query';
    kilHeader: Result := 'header';
  else
    Result := '';
  end;
end;

function TSwagSecurityDefinitionApiKey.GetTypeSecurity: TSwagSecurityDefinitionType;
begin
  Result := ssdApiKey;
end;

end.
