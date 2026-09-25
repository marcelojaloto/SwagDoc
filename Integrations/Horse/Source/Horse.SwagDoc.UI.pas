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

unit Horse.SwagDoc.UI;

interface

uses
  Horse.SwagDoc.Config;

type
  /// <summary>
  /// Writes the page of the user interface and publishes its distribution files when they are embedded in the
  /// application. The files are embedded by the conditional defines below, which are not declared by default,
  /// so an application only pays for what it uses:
  /// * HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI - embeds the Swagger UI files.
  /// * HORSE_SWAGDOC_EMBEDDED_SCALAR - embeds the Scalar file.
  /// When the files of the selected interface are not embedded, the page loads them from the address of the
  /// UserInterfaceResources property.
  /// </summary>
  THorseSwagDocUI = class(TObject)
  strict private
    class function BuildSwaggerUi(const pTitle, pDocumentRoute, pResources: string): string; static;
    class function BuildScalar(const pTitle, pDocumentRoute, pResources: string): string; static;
  public
    /// <summary>
    /// Returns whether the distribution files of the given user interface are embedded in the application.
    /// </summary>
    class function IsEmbedded(const pUserInterface: THorseSwagDocUserInterface): Boolean; static;

    /// <summary>
    /// Returns the address where the page finds the distribution files of the given user interface when the
    /// UserInterfaceResources property is not defined: the route of the page itself when the files are
    /// embedded in the application and a public CDN otherwise.
    /// </summary>
    class function DefaultResources(const pUserInterface: THorseSwagDocUserInterface;
      const pUserInterfaceRoute: string): string; static;

    /// <summary>
    /// Returns the page that renders the document with the given user interface.
    /// </summary>
    class function Build(const pUserInterface: THorseSwagDocUserInterface; const pTitle, pDocumentRoute,
      pResources: string): string; static;

    /// <summary>
    /// Registers the routes of the distribution files embedded in the application, under the route of the
    /// page. Nothing is registered when no conditional define was declared.
    /// </summary>
    class procedure RegisterRoutes(const pUserInterfaceRoute: string); static;

    /// <summary>
    /// Returns the routes registered by the RegisterRoutes method, which are not written in the document.
    /// </summary>
    class function AssetRoutes(const pUserInterfaceRoute: string): TArray<string>; static;
  end;

implementation

uses
  System.SysUtils,
  {$IF DEFINED(HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI) or DEFINED(HORSE_SWAGDOC_EMBEDDED_SCALAR)}
  System.Classes,
  System.ZLib,
  System.SyncObjs,
  System.Generics.Collections,
  {$IFEND}
  Horse;

{$IFDEF HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI}
{$R ..\Resources\Horse.SwagDoc.SwaggerUI.res}
{$ENDIF}
{$IFDEF HORSE_SWAGDOC_EMBEDDED_SCALAR}
{$R ..\Resources\Horse.SwagDoc.Scalar.res}
{$ENDIF}

const
  c_SwaggerUiCssFile = 'swagger-ui.css';
  c_SwaggerUiBundleFile = 'swagger-ui-bundle.js';
  c_SwaggerUiPresetFile = 'swagger-ui-standalone-preset.js';
  c_ScalarFile = 'standalone.js';

  c_SwaggerUiCssResource = 'SWAGDOC_SWAGGER_UI_CSS';
  c_SwaggerUiBundleResource = 'SWAGDOC_SWAGGER_UI_BUNDLE_JS';
  c_SwaggerUiPresetResource = 'SWAGDOC_SWAGGER_UI_PRESET_JS';
  c_ScalarResource = 'SWAGDOC_SCALAR_STANDALONE_JS';

  c_MimeTypeCss = 'text/css;charset=UTF-8';
  c_MimeTypeJavaScript = 'application/javascript;charset=UTF-8';

  // The value of RT_RCDATA, declared here to keep the unit out of the Windows units.
  c_ResourceTypeRcData = 10;

{$IF DEFINED(HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI) or DEFINED(HORSE_SWAGDOC_EMBEDDED_SCALAR)}
type
  /// <summary>
  /// Reads the distribution files from the resources of the application. They are embedded compressed, to
  /// reduce the size of the executable, and are decompressed once, on the first request of each file.
  /// </summary>
  THorseSwagDocAssets = class(TObject)
  strict private
    class var fLock: TCriticalSection;
    class var fFiles: TDictionary<string, TBytes>;
    class function Decompress(pCompressed: TStream): TBytes; static;
    class function Load(const pResourceName: string): TBytes; static;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Send(pResponse: THorseResponse; const pResourceName, pMimeType: string); static;
  end;

{ THorseSwagDocAssets }

class constructor THorseSwagDocAssets.Create;
begin
  fLock := TCriticalSection.Create;
  fFiles := TDictionary<string, TBytes>.Create;
end;

class destructor THorseSwagDocAssets.Destroy;
begin
  FreeAndNil(fFiles);
  FreeAndNil(fLock);
end;

class function THorseSwagDocAssets.Decompress(pCompressed: TStream): TBytes;
const
  c_GZipWindowBits = 15 + 16;
var
  vDecompressor: TZDecompressionStream;
  vFile: TBytesStream;
begin
  vFile := TBytesStream.Create;
  try
    vDecompressor := TZDecompressionStream.Create(pCompressed, c_GZipWindowBits);
    try
      vFile.CopyFrom(vDecompressor, 0);
    finally
      vDecompressor.Free;
    end;
    Result := Copy(vFile.Bytes, 0, vFile.Size);
  finally
    vFile.Free;
  end;
end;

class function THorseSwagDocAssets.Load(const pResourceName: string): TBytes;
var
  vResource: TResourceStream;
begin
  vResource := TResourceStream.Create(FindResourceHInstance(HInstance), pResourceName,
    PChar(NativeUInt(c_ResourceTypeRcData)));
  try
    Result := Decompress(vResource);
  finally
    vResource.Free;
  end;
end;

class procedure THorseSwagDocAssets.Send(pResponse: THorseResponse; const pResourceName, pMimeType: string);
var
  vFile: TBytes;
begin
  fLock.Enter;
  try
    if not fFiles.TryGetValue(pResourceName, vFile) then
    begin
      vFile := Load(pResourceName);
      fFiles.Add(pResourceName, vFile);
    end;
  finally
    fLock.Leave;
  end;

  pResponse.ContentType(pMimeType).Send(vFile);
end;
{$IFEND}

{$IFDEF HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI}
procedure SendSwaggerUiCss(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  THorseSwagDocAssets.Send(pResponse, c_SwaggerUiCssResource, c_MimeTypeCss);
end;

procedure SendSwaggerUiBundle(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  THorseSwagDocAssets.Send(pResponse, c_SwaggerUiBundleResource, c_MimeTypeJavaScript);
end;

procedure SendSwaggerUiPreset(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  THorseSwagDocAssets.Send(pResponse, c_SwaggerUiPresetResource, c_MimeTypeJavaScript);
end;
{$ENDIF}

{$IFDEF HORSE_SWAGDOC_EMBEDDED_SCALAR}
procedure SendScalar(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  THorseSwagDocAssets.Send(pResponse, c_ScalarResource, c_MimeTypeJavaScript);
end;
{$ENDIF}

{ THorseSwagDocUI }

class function THorseSwagDocUI.IsEmbedded(const pUserInterface: THorseSwagDocUserInterface): Boolean;
begin
{$IF DEFINED(HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI) and DEFINED(HORSE_SWAGDOC_EMBEDDED_SCALAR)}
  Result := pUserInterface in [uiSwaggerUi, uiScalar];
{$ELSEIF DEFINED(HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI)}
  Result := pUserInterface = uiSwaggerUi;
{$ELSEIF DEFINED(HORSE_SWAGDOC_EMBEDDED_SCALAR)}
  Result := pUserInterface = uiScalar;
{$ELSE}
  Result := False;
{$IFEND}
end;

class function THorseSwagDocUI.DefaultResources(const pUserInterface: THorseSwagDocUserInterface;
  const pUserInterfaceRoute: string): string;
begin
  if IsEmbedded(pUserInterface) then
    Exit(pUserInterfaceRoute);

  case pUserInterface of
    uiScalar: Result := c_HorseSwagDocScalarResources;
  else
    Result := c_HorseSwagDocSwaggerUiResources;
  end;
end;

class procedure THorseSwagDocUI.RegisterRoutes(const pUserInterfaceRoute: string);
begin
{$IFDEF HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI}
  THorse.Get(pUserInterfaceRoute + '/' + c_SwaggerUiCssFile, SendSwaggerUiCss);
  THorse.Get(pUserInterfaceRoute + '/' + c_SwaggerUiBundleFile, SendSwaggerUiBundle);
  THorse.Get(pUserInterfaceRoute + '/' + c_SwaggerUiPresetFile, SendSwaggerUiPreset);
{$ENDIF}
{$IFDEF HORSE_SWAGDOC_EMBEDDED_SCALAR}
  THorse.Get(pUserInterfaceRoute + '/' + c_ScalarFile, SendScalar);
{$ENDIF}
end;

class function THorseSwagDocUI.AssetRoutes(const pUserInterfaceRoute: string): TArray<string>;
begin
  Result := [];

{$IFDEF HORSE_SWAGDOC_EMBEDDED_SWAGGER_UI}
  Result := Result + [pUserInterfaceRoute + '/' + c_SwaggerUiCssFile,
    pUserInterfaceRoute + '/' + c_SwaggerUiBundleFile,
    pUserInterfaceRoute + '/' + c_SwaggerUiPresetFile];
{$ENDIF}
{$IFDEF HORSE_SWAGDOC_EMBEDDED_SCALAR}
  Result := Result + [pUserInterfaceRoute + '/' + c_ScalarFile];
{$ENDIF}
end;

class function THorseSwagDocUI.Build(const pUserInterface: THorseSwagDocUserInterface; const pTitle,
  pDocumentRoute, pResources: string): string;
begin
  case pUserInterface of
    uiScalar: Result := BuildScalar(pTitle, pDocumentRoute, pResources);
  else
    Result := BuildSwaggerUi(pTitle, pDocumentRoute, pResources);
  end;
end;

class function THorseSwagDocUI.BuildSwaggerUi(const pTitle, pDocumentRoute, pResources: string): string;
begin
  Result :=
    '<!DOCTYPE html>' + sLineBreak +
    '<html lang="en">' + sLineBreak +
    '<head>' + sLineBreak +
    '  <meta charset="UTF-8">' + sLineBreak +
    '  <meta name="viewport" content="width=device-width, initial-scale=1">' + sLineBreak +
    '  <title>' + pTitle + '</title>' + sLineBreak +
    '  <link rel="stylesheet" href="' + pResources + '/' + c_SwaggerUiCssFile + '">' + sLineBreak +
    '</head>' + sLineBreak +
    '<body>' + sLineBreak +
    '  <div id="swagger-ui"></div>' + sLineBreak +
    '  <script src="' + pResources + '/' + c_SwaggerUiBundleFile + '"></script>' + sLineBreak +
    '  <script src="' + pResources + '/' + c_SwaggerUiPresetFile + '"></script>' + sLineBreak +
    '  <script>' + sLineBreak +
    '    window.onload = function () {' + sLineBreak +
    '      window.ui = SwaggerUIBundle({' + sLineBreak +
    '        url: "' + pDocumentRoute + '",' + sLineBreak +
    '        dom_id: "#swagger-ui",' + sLineBreak +
    '        deepLinking: true,' + sLineBreak +
    '        presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],' + sLineBreak +
    '        layout: "StandaloneLayout"' + sLineBreak +
    '      });' + sLineBreak +
    '    };' + sLineBreak +
    '  </script>' + sLineBreak +
    '</body>' + sLineBreak +
    '</html>';
end;

class function THorseSwagDocUI.BuildScalar(const pTitle, pDocumentRoute, pResources: string): string;
begin
  Result :=
    '<!DOCTYPE html>' + sLineBreak +
    '<html lang="en">' + sLineBreak +
    '<head>' + sLineBreak +
    '  <meta charset="UTF-8">' + sLineBreak +
    '  <meta name="viewport" content="width=device-width, initial-scale=1">' + sLineBreak +
    '  <title>' + pTitle + '</title>' + sLineBreak +
    '</head>' + sLineBreak +
    '<body>' + sLineBreak +
    '  <div id="app"></div>' + sLineBreak +
    '  <script src="' + pResources + '/' + c_ScalarFile + '"></script>' + sLineBreak +
    '  <script>' + sLineBreak +
    '    Scalar.createApiReference("#app", { url: "' + pDocumentRoute + '" });' + sLineBreak +
    '  </script>' + sLineBreak +
    '</body>' + sLineBreak +
    '</html>';
end;

end.
