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

unit Dext.SwagDoc;

interface

uses
  Swag.Doc,
  Swag.Doc.Path,
  Dext.Web.Interfaces,
  Dext.SwagDoc.Config;

type
  /// <summary>
  /// The user interface that renders the document, declared in the Dext.SwagDoc.Config unit.
  /// </summary>
  TDextSwagDocUserInterface = Dext.SwagDoc.Config.TDextSwagDocUserInterface;

  /// <summary>
  /// Allows the documentation of a route with the syntax used to register it in Dext.
  /// </summary>
  TSwagDocDextRouteHelper = class helper for TSwagDoc
  public
    /// <summary>
    /// Returns the path of the document for the given Dext route, adding it to the document when it does not
    /// exist yet. The variables of the route are written as required path parameters of type string, which the
    /// application can change.
    /// </summary>
    function Route(const pRoute: string): TSwagPath;
  end;

  /// <summary>
  /// Adds the SwagDoc middleware to a Dext application.
  /// </summary>
  TDextSwagDoc = class(TObject)
  public
    /// <summary>
    /// Publishes the document and the user interface page in the routes defined by the configuration. The
    /// endpoints registered after this call are also documented, because the document is generated on the first
    /// request. The builder of a Dext application is App.Builder.
    /// </summary>
    class function Use(const pBuilder: IApplicationBuilder): IApplicationBuilder; overload; static;

    /// <summary>
    /// Publishes the user interface page and the document in the given routes.
    /// </summary>
    class function Use(const pBuilder: IApplicationBuilder; const pUserInterfaceRoute,
      pDocumentRoute: string): IApplicationBuilder; overload; static;
  end;

const
  /// <summary>
  /// Swagger UI, the interface distributed by SmartBear. It is the default value of the UserInterface setting.
  /// </summary>
  uiSwaggerUi = TDextSwagDocUserInterface.uiSwaggerUi;

  /// <summary>
  /// Scalar, an interface that also works as a client to try the operations.
  /// </summary>
  uiScalar = TDextSwagDocUserInterface.uiScalar;

/// <summary>
/// The document published by the middleware. When the application does not define its own document, one is
/// created with the SpecVersion property set to svOpenApi3 and the OmitEmptyBasePath property set to True.
/// </summary>
function SwagDocApi: TSwagDoc;

/// <summary>
/// The settings of the middleware. They must be defined before the first request.
/// </summary>
function SwagDocConfig: TDextSwagDocConfig;

/// <summary>
/// Defines the document published by the middleware, which is useful for the applications that already build
/// their own document. The middleware only destroys the document when it owns it.
/// </summary>
procedure SetSwagDocApi(const pSwagDoc: TSwagDoc; const pOwnsDocument: Boolean = False);

/// <summary>
/// Discards the document kept in memory, so the next request generates it again. It must be called when the
/// application changes the document after it has been published.
/// </summary>
procedure ClearSwagDocApiCache;

implementation

uses
  System.SysUtils,
  Swag.Common.Types,
  Dext.SwagDoc.Route,
  Dext.SwagDoc.Middleware;

var
  fSwagDoc: TSwagDoc = nil;
  fSwagDocConfig: TDextSwagDocConfig = nil;
  fOwnsSwagDoc: Boolean = True;

function SwagDocConfig: TDextSwagDocConfig;
begin
  if not Assigned(fSwagDocConfig) then
    fSwagDocConfig := TDextSwagDocConfig.Create;
  Result := fSwagDocConfig;
end;

function SwagDocApi: TSwagDoc;
begin
  if not Assigned(fSwagDoc) then
  begin
    fSwagDoc := TSwagDoc.Create;
    fSwagDoc.SpecVersion := svOpenApi3;
    fSwagDoc.OmitEmptyBasePath := True;
    fOwnsSwagDoc := True;
  end;
  Result := fSwagDoc;
end;

procedure SetSwagDocApi(const pSwagDoc: TSwagDoc; const pOwnsDocument: Boolean);
begin
  if fOwnsSwagDoc then
    FreeAndNil(fSwagDoc);

  fSwagDoc := pSwagDoc;
  fOwnsSwagDoc := pOwnsDocument;
  ClearSwagDocApiCache;
end;

procedure ClearSwagDocApiCache;
begin
  TDextSwagDocMiddleware.ClearDocument;
end;

{ TDextSwagDoc }

class function TDextSwagDoc.Use(const pBuilder: IApplicationBuilder): IApplicationBuilder;
begin
  Result := pBuilder.UseMiddleware(TDextSwagDocMiddleware.Create(pBuilder) as IMiddleware);
end;

class function TDextSwagDoc.Use(const pBuilder: IApplicationBuilder; const pUserInterfaceRoute,
  pDocumentRoute: string): IApplicationBuilder;
begin
  SwagDocConfig.UserInterfaceRoute := pUserInterfaceRoute;
  SwagDocConfig.DocumentRoute := pDocumentRoute;
  Result := Use(pBuilder);
end;

{ TSwagDocDextRouteHelper }

function TSwagDocDextRouteHelper.Route(const pRoute: string): TSwagPath;
begin
  Result := TDextSwagDocRoute.AddPath(Self, pRoute);
end;

initialization

finalization
  if fOwnsSwagDoc then
    FreeAndNil(fSwagDoc);
  FreeAndNil(fSwagDocConfig);

end.
