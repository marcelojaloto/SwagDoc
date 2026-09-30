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

unit Dext.SwagDoc.Middleware;

interface

uses
  System.SyncObjs,
  Dext.Web.Interfaces;

type
  /// <summary>
  /// Publishes the document, the user interface page and the embedded distribution files in the routes defined
  /// by the configuration, and hands every other request to the next middleware. The document is generated on
  /// the first request, when every endpoint of the application is already registered, and kept in memory until
  /// ClearSwagDocApiCache is called.
  /// </summary>
  TDextSwagDocMiddleware = class(TInterfacedObject, IMiddleware)
  strict private
    class var fLock: TCriticalSection;
    class var fDocument: string;
    // The application builder owns the middleware, so it is kept without a reference count.
    fBuilder: Pointer;
    function BuildDocument: string;
    function GetDocument: string;
    function GetUserInterfaceTitle: string;
    procedure SendDocument(pContext: IHttpContext);
    procedure SendUserInterface(pContext: IHttpContext);
  public
    class constructor Create;
    class destructor Destroy;
    constructor Create(const pBuilder: IApplicationBuilder); reintroduce;

    /// <summary>
    /// Discards the document kept in memory, so the next request generates it again.
    /// </summary>
    class procedure ClearDocument; static;

    /// <summary>
    /// Answers the requests of the document, of the user interface and of the embedded files.
    /// </summary>
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
  end;

implementation

uses
  System.SysUtils,
  Json.Common.Helpers,
  Swag.Doc,
  Dext.SwagDoc,
  Dext.SwagDoc.UI,
  Dext.SwagDoc.Discovery;

const
  c_MethodGet = 'GET';
  c_MimeTypeJson = 'application/json;charset=UTF-8';
  c_MimeTypeHtml = 'text/html;charset=UTF-8';
  c_DefaultUserInterfaceTitle = 'API documentation';

{ TDextSwagDocMiddleware }

class constructor TDextSwagDocMiddleware.Create;
begin
  fLock := TCriticalSection.Create;
end;

class destructor TDextSwagDocMiddleware.Destroy;
begin
  FreeAndNil(fLock);
end;

constructor TDextSwagDocMiddleware.Create(const pBuilder: IApplicationBuilder);
begin
  inherited Create;
  fBuilder := Pointer(pBuilder);
end;

class procedure TDextSwagDocMiddleware.ClearDocument;
begin
  fLock.Enter;
  try
    fDocument := EmptyStr;
  finally
    fLock.Leave;
  end;
end;

procedure TDextSwagDocMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
var
  vPath: string;
begin
  if not SameText(AContext.Request.Method, c_MethodGet) then
  begin
    ANext(AContext);
    Exit;
  end;

  vPath := AContext.Request.Path;
  if SameText(vPath, SwagDocConfig.DocumentRoute) then
    SendDocument(AContext)
  else if SameText(vPath, SwagDocConfig.UserInterfaceRoute) or
    SameText(vPath, SwagDocConfig.UserInterfaceRoute + '/') then
    SendUserInterface(AContext)
  else if not TDextSwagDocUI.TrySendAsset(AContext, vPath, SwagDocConfig.UserInterfaceRoute) then
    ANext(AContext);
end;

function TDextSwagDocMiddleware.BuildDocument: string;
var
  vSwagDoc: TSwagDoc;
begin
  vSwagDoc := SwagDocApi;

  if SwagDocConfig.DiscoverRoutes and Assigned(fBuilder) then
    TDextSwagDocDiscovery.DocumentEndpoints(vSwagDoc, IApplicationBuilder(fBuilder).GetRoutes,
      [SwagDocConfig.DocumentRoute, SwagDocConfig.UserInterfaceRoute] +
      TDextSwagDocUI.AssetRoutes(SwagDocConfig.UserInterfaceRoute),
      SwagDocConfig.DefaultSecurityScheme);

  vSwagDoc.GenerateSwaggerJson;
  Result := vSwagDoc.SwaggerJson.Format;
end;

function TDextSwagDocMiddleware.GetDocument: string;
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

function TDextSwagDocMiddleware.GetUserInterfaceTitle: string;
begin
  Result := SwagDocConfig.UserInterfaceTitle;
  if Result.IsEmpty then
    Result := SwagDocApi.Info.Title;
  if Result.IsEmpty then
    Result := c_DefaultUserInterfaceTitle;
end;

procedure TDextSwagDocMiddleware.SendDocument(pContext: IHttpContext);
begin
  pContext.Response.StatusCode := 200;
  pContext.Response.ContentType := c_MimeTypeJson;
  pContext.Response.Write(GetDocument);
end;

procedure TDextSwagDocMiddleware.SendUserInterface(pContext: IHttpContext);
var
  vResources: string;
begin
  vResources := SwagDocConfig.UserInterfaceResources;
  if vResources.IsEmpty then
  begin
    vResources := TDextSwagDocUI.DefaultResources(SwagDocConfig.UserInterface, SwagDocConfig.UserInterfaceRoute);
    if TDextSwagDocUI.IsEmbedded(SwagDocConfig.UserInterface) then
      vResources := pContext.Request.ToAppUrl(vResources);
  end;

  pContext.Response.StatusCode := 200;
  pContext.Response.ContentType := c_MimeTypeHtml;
  pContext.Response.Write(TDextSwagDocUI.Build(SwagDocConfig.UserInterface, GetUserInterfaceTitle,
    pContext.Request.ToAppUrl(SwagDocConfig.DocumentRoute), vResources));
end;

end.
