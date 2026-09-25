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

unit Horse.SwagDoc;

interface

uses
  Horse,
  Swag.Doc,
  Swag.Doc.Path,
  Horse.SwagDoc.Config;

type
  /// <summary>
  /// The user interface that renders the document, declared in the Horse.SwagDoc.Config unit.
  /// </summary>
  THorseSwagDocUserInterface = Horse.SwagDoc.Config.THorseSwagDocUserInterface;

  /// <summary>
  /// Allows the documentation of a route with the syntax used to register it in Horse.
  /// </summary>
  TSwagDocHorseRouteHelper = class helper for TSwagDoc
  public
    /// <summary>
    /// Returns the path of the document for the given Horse route, adding it to the document when it does not
    /// exist yet. The variables of the route are translated to the syntax of the specification and written as
    /// path parameters.
    /// </summary>
    function Route(const pRoute: string): TSwagPath;
  end;

const
  /// <summary>
  /// Swagger UI, the interface distributed by SmartBear. It is the default value of the UserInterface setting.
  /// </summary>
  uiSwaggerUi = THorseSwagDocUserInterface.uiSwaggerUi;

  /// <summary>
  /// Scalar, an interface that also works as a client to try the operations.
  /// </summary>
  uiScalar = THorseSwagDocUserInterface.uiScalar;

/// <summary>
/// Publishes the document and the Swagger UI page in the routes defined by the configuration.
/// </summary>
function HorseSwagDoc: THorseCallback; overload;

/// <summary>
/// Publishes the Swagger UI page in the given route and the document in the route defined by the configuration.
/// </summary>
function HorseSwagDoc(const pUserInterfaceRoute: string): THorseCallback; overload;

/// <summary>
/// Publishes the Swagger UI page and the document in the given routes.
/// </summary>
function HorseSwagDoc(const pUserInterfaceRoute, pDocumentRoute: string): THorseCallback; overload;

/// <summary>
/// The document published by the middleware. When the application does not define its own document, one is
/// created with the SpecVersion property set to svOpenApi3.
/// </summary>
function SwagDocApi: TSwagDoc;

/// <summary>
/// The settings of the middleware. They must be defined before the middleware is added to the application,
/// because the routes are registered at that moment.
/// </summary>
function SwagDocConfig: THorseSwagDocConfig;

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
  Horse.SwagDoc.Route,
  Horse.SwagDoc.Controller;

var
  fSwagDoc: TSwagDoc = nil;
  fSwagDocConfig: THorseSwagDocConfig = nil;
  fOwnsSwagDoc: Boolean = True;

function SwagDocConfig: THorseSwagDocConfig;
begin
  if not Assigned(fSwagDocConfig) then
    fSwagDocConfig := THorseSwagDocConfig.Create;
  Result := fSwagDocConfig;
end;

function SwagDocApi: TSwagDoc;
begin
  if not Assigned(fSwagDoc) then
  begin
    fSwagDoc := TSwagDoc.Create;
    fSwagDoc.SpecVersion := svOpenApi3;
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
  THorseSwagDocController.ClearDocument;
end;

function HorseSwagDoc: THorseCallback;
begin
  THorseSwagDocController.RegisterRoutes;
  Result :=
    procedure(pRequest: THorseRequest; pResponse: THorseResponse; pNext: TProc)
    begin
      pNext();
    end;
end;

function HorseSwagDoc(const pUserInterfaceRoute: string): THorseCallback;
begin
  SwagDocConfig.UserInterfaceRoute := pUserInterfaceRoute;
  Result := HorseSwagDoc();
end;

function HorseSwagDoc(const pUserInterfaceRoute, pDocumentRoute: string): THorseCallback;
begin
  SwagDocConfig.UserInterfaceRoute := pUserInterfaceRoute;
  SwagDocConfig.DocumentRoute := pDocumentRoute;
  Result := HorseSwagDoc();
end;

{ TSwagDocHorseRouteHelper }

function TSwagDocHorseRouteHelper.Route(const pRoute: string): TSwagPath;
begin
  Result := THorseSwagDocRoute.AddPath(Self, pRoute);
end;

initialization

finalization
  if fOwnsSwagDoc then
    FreeAndNil(fSwagDoc);
  FreeAndNil(fSwagDocConfig);

end.
