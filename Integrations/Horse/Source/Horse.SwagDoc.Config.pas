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

unit Horse.SwagDoc.Config;

interface

const
  /// <summary>
  /// The route where the generated document is published when the configuration is not changed.
  /// </summary>
  c_HorseSwagDocDefaultDocumentRoute = '/docs/openapi.json';

  /// <summary>
  /// The route where the user interface page is published when the configuration is not changed.
  /// </summary>
  c_HorseSwagDocDefaultUserInterfaceRoute = '/docs';

  /// <summary>
  /// The location of the Swagger UI distribution files used when they are not embedded in the application.
  /// </summary>
  c_HorseSwagDocSwaggerUiResources = 'https://unpkg.com/swagger-ui-dist@5';

  /// <summary>
  /// The location of the Scalar distribution file used when it is not embedded in the application.
  /// </summary>
  c_HorseSwagDocScalarResources = 'https://cdn.jsdelivr.net/npm/@scalar/api-reference/dist/browser';

type
  /// <summary>
  /// The user interface that renders the document.
  /// * uiSwaggerUi - Swagger UI, the interface distributed by SmartBear. It is the default value.
  /// * uiScalar - Scalar, an interface that also works as a client to try the operations.
  /// </summary>
  THorseSwagDocUserInterface = (uiSwaggerUi, uiScalar);

  /// <summary>
  /// Settings of the middleware: where the document and the user interface are published, how the page is
  /// rendered and whether the routes registered in Horse are documented automatically.
  /// </summary>
  THorseSwagDocConfig = class(TObject)
  strict private
    fDocumentRoute: string;
    fUserInterfaceRoute: string;
    fUserInterfaceTitle: string;
    fUserInterfaceResources: string;
    fUserInterface: THorseSwagDocUserInterface;
    fDiscoverRoutes: Boolean;
    function NormalizeRoute(const pRoute: string): string;
    procedure SetDocumentRoute(const Value: string);
    procedure SetUserInterfaceRoute(const Value: string);
    procedure SetUserInterfaceResources(const Value: string);
  public
    constructor Create; reintroduce;

    /// <summary>
    /// The route of the generated document. The default value is /docs/openapi.json and applications that
    /// write Swagger 2.0 documents usually change it to /docs/swagger.json.
    /// </summary>
    property DocumentRoute: string read fDocumentRoute write SetDocumentRoute;

    /// <summary>
    /// The route of the user interface page. The default value is /docs.
    /// </summary>
    property UserInterfaceRoute: string read fUserInterfaceRoute write SetUserInterfaceRoute;

    /// <summary>
    /// The user interface that renders the document. The default value is uiSwaggerUi.
    /// </summary>
    property UserInterface: THorseSwagDocUserInterface read fUserInterface write fUserInterface;

    /// <summary>
    /// The title of the page. When it is not defined, the title of the document is used.
    /// </summary>
    property UserInterfaceTitle: string read fUserInterfaceTitle write fUserInterfaceTitle;

    /// <summary>
    /// The base address of the distribution files of the user interface, without the trailing slash. When it
    /// is not defined, the files embedded in the application are used, if the conditional define of the
    /// selected interface was declared, and a public CDN otherwise. Applications that must not depend on an
    /// external address and do not embed the files can publish them with a static file middleware and point
    /// this property to them.
    /// </summary>
    property UserInterfaceResources: string read fUserInterfaceResources write SetUserInterfaceResources;

    /// <summary>
    /// Determines whether the routes registered in Horse that are not documented yet are added to the
    /// document when it is generated. The default value is true. Only the path and the HTTP method are known
    /// by the router, so each discovered operation is written with a single response and without a summary.
    /// </summary>
    property DiscoverRoutes: Boolean read fDiscoverRoutes write fDiscoverRoutes;
  end;

implementation

uses
  System.SysUtils;

{ THorseSwagDocConfig }

constructor THorseSwagDocConfig.Create;
begin
  inherited Create;
  fDocumentRoute := c_HorseSwagDocDefaultDocumentRoute;
  fUserInterfaceRoute := c_HorseSwagDocDefaultUserInterfaceRoute;
  fUserInterface := uiSwaggerUi;
  fDiscoverRoutes := True;
end;

function THorseSwagDocConfig.NormalizeRoute(const pRoute: string): string;
begin
  Result := pRoute.Trim;
  if Result.IsEmpty then
    raise EArgumentException.Create('The route of the middleware cannot be empty.');

  if not Result.StartsWith('/') then
    Result := '/' + Result;

  while (Result.Length > 1) and Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

procedure THorseSwagDocConfig.SetDocumentRoute(const Value: string);
begin
  fDocumentRoute := NormalizeRoute(Value);
end;

procedure THorseSwagDocConfig.SetUserInterfaceRoute(const Value: string);
begin
  fUserInterfaceRoute := NormalizeRoute(Value);
end;

procedure THorseSwagDocConfig.SetUserInterfaceResources(const Value: string);
begin
  fUserInterfaceResources := Value.Trim;
  while (fUserInterfaceResources.Length > 1) and fUserInterfaceResources.EndsWith('/') do
    fUserInterfaceResources := fUserInterfaceResources.Substring(0, fUserInterfaceResources.Length - 1);
end;

end.
