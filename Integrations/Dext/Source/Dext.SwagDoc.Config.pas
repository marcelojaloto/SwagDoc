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

unit Dext.SwagDoc.Config;

interface

const
  /// <summary>
  /// The route where the generated document is published when the configuration is not changed.
  /// </summary>
  c_DextSwagDocDefaultDocumentRoute = '/docs/openapi.json';

  /// <summary>
  /// The route where the user interface page is published when the configuration is not changed.
  /// </summary>
  c_DextSwagDocDefaultUserInterfaceRoute = '/docs';

  /// <summary>
  /// The location of the Swagger UI distribution files used when they are not embedded in the application.
  /// </summary>
  c_DextSwagDocSwaggerUiResources = 'https://unpkg.com/swagger-ui-dist@5';

  /// <summary>
  /// The location of the Scalar distribution file used when it is not embedded in the application.
  /// </summary>
  c_DextSwagDocScalarResources = 'https://cdn.jsdelivr.net/npm/@scalar/api-reference/dist/browser';

  /// <summary>
  /// The name of the bearer security scheme used by the Swagger support of Dext. When an endpoint requires it
  /// and the document does not define it, the middleware defines it as an HTTP bearer scheme.
  /// </summary>
  c_DextSwagDocBearerSchemeName = 'bearerAuth';

type
  /// <summary>
  /// The user interface that renders the document.
  /// * uiSwaggerUi - Swagger UI, the interface distributed by SmartBear. It is the default value.
  /// * uiScalar - Scalar, an interface that also works as a client to try the operations.
  /// </summary>
  TDextSwagDocUserInterface = (uiSwaggerUi, uiScalar);

  /// <summary>
  /// Settings of the middleware: where the document and the user interface are published, how the page is
  /// rendered and whether the endpoints registered in Dext are documented automatically.
  /// </summary>
  TDextSwagDocConfig = class(TObject)
  strict private
    fDocumentRoute: string;
    fUserInterfaceRoute: string;
    fUserInterfaceTitle: string;
    fUserInterfaceResources: string;
    fUserInterface: TDextSwagDocUserInterface;
    fDiscoverRoutes: Boolean;
    fDefaultSecurityScheme: string;
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
    /// The route of the user interface page. The default value is /docs, so the page can run next to the
    /// /swagger page of Dext during a migration.
    /// </summary>
    property UserInterfaceRoute: string read fUserInterfaceRoute write SetUserInterfaceRoute;

    /// <summary>
    /// The user interface that renders the document. The default value is uiSwaggerUi.
    /// </summary>
    property UserInterface: TDextSwagDocUserInterface read fUserInterface write fUserInterface;

    /// <summary>
    /// The title of the page. When it is not defined, the title of the document is used.
    /// </summary>
    property UserInterfaceTitle: string read fUserInterfaceTitle write fUserInterfaceTitle;

    /// <summary>
    /// The base address of the distribution files of the user interface, without the trailing slash. When it
    /// is not defined, the files embedded in the application are used, if the conditional define of the
    /// selected interface was declared, and a public CDN otherwise. Applications that must not depend on an
    /// external address and do not embed the files can publish them with UseStaticFiles and point this
    /// property to them.
    /// </summary>
    property UserInterfaceResources: string read fUserInterfaceResources write SetUserInterfaceResources;

    /// <summary>
    /// Determines whether the endpoints registered in Dext that are not documented yet are added to the
    /// document when it is generated. The default value is true. The summary, the description, the tags, the
    /// request and response types and the security schemes given to Dext are written with each operation.
    /// </summary>
    property DiscoverRoutes: Boolean read fDiscoverRoutes write fDiscoverRoutes;

    /// <summary>
    /// The security scheme written for the endpoints of controllers marked with [Authorize] without a scheme
    /// name. When it is empty, those endpoints are written without security. The default value is empty.
    /// </summary>
    property DefaultSecurityScheme: string read fDefaultSecurityScheme write fDefaultSecurityScheme;
  end;

implementation

uses
  System.SysUtils;

{ TDextSwagDocConfig }

constructor TDextSwagDocConfig.Create;
begin
  inherited Create;
  fDocumentRoute := c_DextSwagDocDefaultDocumentRoute;
  fUserInterfaceRoute := c_DextSwagDocDefaultUserInterfaceRoute;
  fUserInterface := uiSwaggerUi;
  fDiscoverRoutes := True;
end;

function TDextSwagDocConfig.NormalizeRoute(const pRoute: string): string;
begin
  Result := pRoute.Trim;
  if Result.IsEmpty then
    raise EArgumentException.Create('The route of the middleware cannot be empty.');

  if not Result.StartsWith('/') then
    Result := '/' + Result;

  while (Result.Length > 1) and Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

procedure TDextSwagDocConfig.SetDocumentRoute(const Value: string);
begin
  fDocumentRoute := NormalizeRoute(Value);
end;

procedure TDextSwagDocConfig.SetUserInterfaceRoute(const Value: string);
begin
  fUserInterfaceRoute := NormalizeRoute(Value);
end;

procedure TDextSwagDocConfig.SetUserInterfaceResources(const Value: string);
begin
  fUserInterfaceResources := Value.Trim;
  while (fUserInterfaceResources.Length > 1) and fUserInterfaceResources.EndsWith('/') do
    fUserInterfaceResources := fUserInterfaceResources.Substring(0, fUserInterfaceResources.Length - 1);
end;

end.
