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

unit Swag.Doc.Info.Contact;

interface

uses
  System.JSON;

type
  TSwagInfoContact = class(TObject)
  private
    fName: string;
    fEmail: string;
    fUrl: string;
  public
    function GenerateJsonObject: TJSONObject;

    property Name: string read fName write fName;
    property Email: string read fEmail write fEmail;
    property Url: string read fUrl write fUrl;
  end;

implementation

const
  c_SwagInfoContactName = 'name';
  c_SwagInfoContactEmail = 'email';
  c_SwagInfoContactUrl = 'url';

{ TSwagInfoContact }

function TSwagInfoContact.GenerateJsonObject: TJSONObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair(c_SwagInfoContactName, fName);
  Result.AddPair(c_SwagInfoContactEmail, fEmail);
  Result.AddPair(c_SwagInfoContactUrl, fUrl);
end;

end.
