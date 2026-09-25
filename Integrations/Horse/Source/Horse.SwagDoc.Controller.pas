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

unit Horse.SwagDoc.Controller;

interface

uses
  System.SyncObjs,
  Horse;

type
  /// <summary>
  /// Publishes the document and the Swagger UI page in the routes defined by the configuration. The document
  /// is generated on the first request and kept in memory until the ClearDocument method is called.
  /// </summary>
  THorseSwagDocController = class(TObject)
  strict private
    class var fLock: TCriticalSection;
    class var fDocument: string;
    class var fRoutesRegistered: Boolean;
    class function BuildDocument: string; static;
    class function BuildUserInterface: string; static;
    class function GetDocument: string; static;
    class function GetUserInterfaceTitle: string; static;
  public
    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Registers the routes of the document and of the user interface. The routes are registered once, so the
    /// configuration must be defined before the middleware is added to the application.
    /// </summary>
    class procedure RegisterRoutes; static;

    /// <summary>
    /// Discards the document kept in memory, so the next request generates it again.
    /// </summary>
    class procedure ClearDocument; static;

    /// <summary>
    /// Writes the generated document in the response.
    /// </summary>
    class procedure SendDocument(pRequest: THorseRequest; pResponse: THorseResponse); static;

    /// <summary>
    /// Writes the Swagger UI page in the response.
    /// </summary>
    class procedure SendUserInterface(pRequest: THorseRequest; pResponse: THorseResponse); static;
  end;

implementation

uses
  System.SysUtils,
  Json.Common.Helpers,
  Swag.Doc,
  Horse.SwagDoc,
  Horse.SwagDoc.UI,
  Horse.SwagDoc.Discovery;

const
  c_MimeTypeJson = 'application/json;charset=UTF-8';
  c_MimeTypeHtml = 'text/html;charset=UTF-8';
  c_DefaultUserInterfaceTitle = 'API documentation';

{ THorseSwagDocController }

class constructor THorseSwagDocController.Create;
begin
  fLock := TCriticalSection.Create;
  fRoutesRegistered := False;
end;

class destructor THorseSwagDocController.Destroy;
begin
  FreeAndNil(fLock);
end;

class procedure THorseSwagDocController.RegisterRoutes;
begin
  if fRoutesRegistered then
    Exit;

  fRoutesRegistered := True;
  THorse.Get(SwagDocConfig.UserInterfaceRoute, SendUserInterface);
  THorse.Get(SwagDocConfig.DocumentRoute, SendDocument);
  THorseSwagDocUI.RegisterRoutes(SwagDocConfig.UserInterfaceRoute);
end;

class procedure THorseSwagDocController.ClearDocument;
begin
  fLock.Enter;
  try
    fDocument := EmptyStr;
  finally
    fLock.Leave;
  end;
end;

class function THorseSwagDocController.BuildDocument: string;
var
  vSwagDoc: TSwagDoc;
begin
  vSwagDoc := SwagDocApi;

  if SwagDocConfig.DiscoverRoutes then
  try
    THorseSwagDocDiscovery.DocumentRegisteredRoutes(vSwagDoc,
      [SwagDocConfig.DocumentRoute, SwagDocConfig.UserInterfaceRoute] +
      THorseSwagDocUI.AssetRoutes(SwagDocConfig.UserInterfaceRoute));
  except
    // The discovery reads the router of Horse, so a failure here only means that the document is written
    // with the operations documented by the application.
  end;

  vSwagDoc.GenerateSwaggerJson;
  Result := vSwagDoc.SwaggerJson.Format;
end;

class function THorseSwagDocController.GetDocument: string;
begin
  fLock.Enter;
  try
    if fDocument.IsEmpty then
      fDocument := BuildDocument;
    Result := fDocument;
  finally
    fLock.Leave;
  end;
end;

class function THorseSwagDocController.GetUserInterfaceTitle: string;
begin
  Result := SwagDocConfig.UserInterfaceTitle;
  if Result.IsEmpty then
    Result := SwagDocApi.Info.Title;
  if Result.IsEmpty then
    Result := c_DefaultUserInterfaceTitle;
end;

class function THorseSwagDocController.BuildUserInterface: string;
var
  vResources: string;
begin
  vResources := SwagDocConfig.UserInterfaceResources;
  if vResources.IsEmpty then
    vResources := THorseSwagDocUI.DefaultResources(SwagDocConfig.UserInterface,
      SwagDocConfig.UserInterfaceRoute);

  Result := THorseSwagDocUI.Build(SwagDocConfig.UserInterface, GetUserInterfaceTitle,
    SwagDocConfig.DocumentRoute, vResources);
end;

class procedure THorseSwagDocController.SendDocument(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  pResponse.ContentType(c_MimeTypeJson).Send(GetDocument);
end;

class procedure THorseSwagDocController.SendUserInterface(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  pResponse.ContentType(c_MimeTypeHtml).Send(BuildUserInterface);
end;

end.
