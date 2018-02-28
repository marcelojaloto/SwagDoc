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

unit Swag.Common.Types;

interface

uses
  System.Generics.Collections;

type
  TSwagStatusCode = string;
  TSwagMimeType = string;
  TSwagJsonExampleDescription = string;

  TSwagSecuritySchemaName = string;
  TSwagSecurityDefinitionType = (ssdNotDefined, ssdBasic, ssdApiKey, ssdOAuth2);
  TSwagSecurityDefinitionsType = set of TSwagSecurityDefinitionType;
  TSwagSecurityScopesSchemaName = string;
  TSwagSecurityScopesSchemaDescription = string;
  TSwagSecurityScopes = TDictionary<TSwagSecurityScopesSchemaName, TSwagSecurityScopesSchemaDescription>;

  TSwagTransferProtocolScheme = (tpsNotDefined, tpsHttp, tpsHttps, tpsWs, tpsWss);
  TSwagTransferProtocolSchemes = set of TSwagTransferProtocolScheme;

  TSwagRequestParameterInLocation = (rpiNotDefined, rpiQuery, rpiHeader, rpiPath, rpiFormData, rpiBody);

  TSwagPathTypeOperation = (ohvNotDefined, ohvGet, ohvPost, ohvPut, ohvDelete, ohvOptions, ohvHead, ohvPatch);

implementation

end.
