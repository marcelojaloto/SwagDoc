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

unit Swag.Doc.Info;

interface

uses
  System.JSON,
  Swag.Doc.Info.Contact;

type
  TSwagInfo = class(TObject)
  private
    fVersion: string;
    fTitle: string;
    fDescription: string;
    fContact: TSwagInfoContact;
    FTermsOfService: string;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;
    procedure Load(inJSON: TJSONObject);

    property Version: string read fVersion write fVersion;
    property Title: string read fTitle write fTitle;
    property TermsOfService: string read FTermsOfService write FTermsOfService;
    property Description: string read fDescription write fDescription;
    property Contact: TSwagInfoContact read fContact write fContact;
  end;

implementation

uses
  System.SysUtils;

const
  c_SwagInfoVersion = 'version';
  c_SwagInfoTitle = 'title';
  c_SwagInfoDescription = 'description';
  c_SwagInfoContact = 'contact';
  c_SwagInfoTermsOfService = 'termsOfService';

{ TSwagInfo }

procedure TSwagInfo.Load(inJSON: TJSONObject);
begin
  if Assigned(inJSON.Values[c_SwagInfoVersion]) then
  begin
    fVersion := inJSON.Values[c_SwagInfoVersion].Value;
  end;
  if Assigned(inJSON.Values[c_SwagInfoTitle]) then
  begin
    fTitle := inJSON.Values[c_SwagInfoTitle].Value;
  end;
  if Assigned(inJSON.Values[c_SwagInfoDescription]) then
  begin
    fDescription := inJSON.Values[c_SwagInfoDescription].Value;
  end;
  if Assigned(inJSON.Values[c_SwagInfoTermsOfService]) then
  begin
    FTermsOfService := inJSON.Values[c_SwagInfoTermsOfService].Value;
  end;
  if Assigned(inJSON.Values[c_SwagInfoContact]) then
  begin
    fContact.Load(inJSON.Values[c_SwagInfoContact] as TJSONObject);
  end;

end;

constructor TSwagInfo.Create;
begin
  inherited Create;
  fContact := TSwagInfoContact.Create;
end;

destructor TSwagInfo.Destroy;
begin
  FreeAndNil(fContact);
  inherited Destroy;
end;

function TSwagInfo.GenerateJsonObject: TJSONObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair(c_SwagInfoVersion, fVersion);
  Result.AddPair(c_SwagInfoTitle, fTitle);
  Result.AddPair(c_SwagInfoDescription, fDescription);
  if not FTermsOfService.IsEmpty then
    Result.AddPair(c_SwagInfoTermsOfService, FTermsOfService);
  if not fContact.IsEmpty then
  begin
    Result.AddPair(c_SwagInfoContact, fContact.GenerateJsonObject);
  end;
end;


end.
