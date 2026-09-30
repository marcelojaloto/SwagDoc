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

unit Dext.SwagDoc.UI;

interface

uses
  Dext.Web.Interfaces,
  Dext.SwagDoc.Config;

type
  /// <summary>
  /// Writes the page of the user interface and publishes its distribution files when they are embedded in the
  /// application. The files are embedded by the conditional defines below, which are not declared by default,
  /// so an application only pays for what it uses:
  /// * DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI - embeds the Swagger UI files.
  /// * DEXT_SWAGDOC_EMBEDDED_SCALAR - embeds the Scalar file.
  /// When the files of the selected interface are not embedded, the page loads them from the address of the
  /// UserInterfaceResources property, or from a public CDN.
  /// </summary>
  TDextSwagDocUI = class(TObject)
  strict private
    class function BuildSwaggerUi(const pTitle, pDocumentUrl, pResources: string): string; static;
    class function BuildScalar(const pTitle, pDocumentUrl, pResources: string): string; static;
  public
    /// <summary>
    /// Returns whether the distribution files of the given user interface are embedded in the application.
    /// </summary>
    class function IsEmbedded(const pUserInterface: TDextSwagDocUserInterface): Boolean; static;

    /// <summary>
    /// Returns the address where the page finds the distribution files of the given user interface when the
    /// UserInterfaceResources property is not defined: the route of the page itself when the files are
    /// embedded in the application and a public CDN otherwise.
    /// </summary>
    class function DefaultResources(const pUserInterface: TDextSwagDocUserInterface;
      const pUserInterfaceRoute: string): string; static;

    /// <summary>
    /// Returns the page that renders the document with the given user interface.
    /// </summary>
    class function Build(const pUserInterface: TDextSwagDocUserInterface; const pTitle, pDocumentUrl,
      pResources: string): string; static;

    /// <summary>
    /// Writes the embedded distribution file requested by pPath, under the route of the page, and returns True.
    /// Returns False when pPath is not one of the embedded files.
    /// </summary>
    class function TrySendAsset(pContext: IHttpContext; const pPath, pUserInterfaceRoute: string): Boolean; static;

    /// <summary>
    /// Returns the routes of the embedded distribution files, which are not written in the document.
    /// </summary>
    class function AssetRoutes(const pUserInterfaceRoute: string): TArray<string>; static;
  end;

implementation

uses
  {$IF DEFINED(DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI) or DEFINED(DEXT_SWAGDOC_EMBEDDED_SCALAR)}
  System.Classes,
  System.ZLib,
  System.SyncObjs,
  System.Generics.Collections,
  {$IFEND}
  System.SysUtils;

{$IFDEF DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI}
{$R ..\Resources\Dext.SwagDoc.SwaggerUI.res}
{$ENDIF}
{$IFDEF DEXT_SWAGDOC_EMBEDDED_SCALAR}
{$R ..\Resources\Dext.SwagDoc.Scalar.res}
{$ENDIF}

const
  c_SwaggerUiCssFile = 'swagger-ui.css';
  c_SwaggerUiBundleFile = 'swagger-ui-bundle.js';
  c_SwaggerUiPresetFile = 'swagger-ui-standalone-preset.js';
  c_ScalarFile = 'standalone.js';

  c_SwaggerUiCssResource = 'DEXT_SWAGDOC_SWAGGER_UI_CSS';
  c_SwaggerUiBundleResource = 'DEXT_SWAGDOC_SWAGGER_UI_BUNDLE_JS';
  c_SwaggerUiPresetResource = 'DEXT_SWAGDOC_SWAGGER_UI_PRESET_JS';
  c_ScalarResource = 'DEXT_SWAGDOC_SCALAR_STANDALONE_JS';

  c_MimeTypeCss = 'text/css;charset=UTF-8';
  c_MimeTypeJavaScript = 'application/javascript;charset=UTF-8';

  // The value of RT_RCDATA, declared here to keep the unit out of the Windows units.
  c_ResourceTypeRcData = 10;

{$IF DEFINED(DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI) or DEFINED(DEXT_SWAGDOC_EMBEDDED_SCALAR)}
type
  /// <summary>
  /// Reads the distribution files from the resources of the application. They are embedded compressed, to
  /// reduce the size of the executable, and are decompressed once, on the first request of each file.
  /// </summary>
  TDextSwagDocAssets = class(TObject)
  strict private
    class var fLock: TCriticalSection;
    class var fFiles: TDictionary<string, TBytes>;
    class function Decompress(pCompressed: TStream): TBytes; static;
    class function Load(const pResourceName: string): TBytes; static;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure Send(pContext: IHttpContext; const pResourceName, pMimeType: string); static;
  end;

{ TDextSwagDocAssets }

class constructor TDextSwagDocAssets.Create;
begin
  fLock := TCriticalSection.Create;
  fFiles := TDictionary<string, TBytes>.Create;
end;

class destructor TDextSwagDocAssets.Destroy;
begin
  FreeAndNil(fFiles);
  FreeAndNil(fLock);
end;

class function TDextSwagDocAssets.Decompress(pCompressed: TStream): TBytes;
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

class function TDextSwagDocAssets.Load(const pResourceName: string): TBytes;
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

class procedure TDextSwagDocAssets.Send(pContext: IHttpContext; const pResourceName, pMimeType: string);
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

  pContext.Response.StatusCode := 200;
  pContext.Response.ContentType := pMimeType;
  pContext.Response.Write(vFile);
end;
{$IFEND}

{ TDextSwagDocUI }

class function TDextSwagDocUI.IsEmbedded(const pUserInterface: TDextSwagDocUserInterface): Boolean;
begin
{$IF DEFINED(DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI) and DEFINED(DEXT_SWAGDOC_EMBEDDED_SCALAR)}
  Result := pUserInterface in [uiSwaggerUi, uiScalar];
{$ELSEIF DEFINED(DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI)}
  Result := pUserInterface = uiSwaggerUi;
{$ELSEIF DEFINED(DEXT_SWAGDOC_EMBEDDED_SCALAR)}
  Result := pUserInterface = uiScalar;
{$ELSE}
  Result := False;
{$IFEND}
end;

class function TDextSwagDocUI.DefaultResources(const pUserInterface: TDextSwagDocUserInterface;
  const pUserInterfaceRoute: string): string;
begin
  if IsEmbedded(pUserInterface) then
    Exit(pUserInterfaceRoute);

  case pUserInterface of
    uiScalar: Result := c_DextSwagDocScalarResources;
  else
    Result := c_DextSwagDocSwaggerUiResources;
  end;
end;

class function TDextSwagDocUI.TrySendAsset(pContext: IHttpContext; const pPath,
  pUserInterfaceRoute: string): Boolean;
begin
  Result := False;
{$IFDEF DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI}
  if SameText(pPath, pUserInterfaceRoute + '/' + c_SwaggerUiCssFile) then
  begin
    TDextSwagDocAssets.Send(pContext, c_SwaggerUiCssResource, c_MimeTypeCss);
    Exit(True);
  end;
  if SameText(pPath, pUserInterfaceRoute + '/' + c_SwaggerUiBundleFile) then
  begin
    TDextSwagDocAssets.Send(pContext, c_SwaggerUiBundleResource, c_MimeTypeJavaScript);
    Exit(True);
  end;
  if SameText(pPath, pUserInterfaceRoute + '/' + c_SwaggerUiPresetFile) then
  begin
    TDextSwagDocAssets.Send(pContext, c_SwaggerUiPresetResource, c_MimeTypeJavaScript);
    Exit(True);
  end;
{$ENDIF}
{$IFDEF DEXT_SWAGDOC_EMBEDDED_SCALAR}
  if SameText(pPath, pUserInterfaceRoute + '/' + c_ScalarFile) then
  begin
    TDextSwagDocAssets.Send(pContext, c_ScalarResource, c_MimeTypeJavaScript);
    Exit(True);
  end;
{$ENDIF}
end;

class function TDextSwagDocUI.AssetRoutes(const pUserInterfaceRoute: string): TArray<string>;
begin
  Result := [];

{$IFDEF DEXT_SWAGDOC_EMBEDDED_SWAGGER_UI}
  Result := Result + [pUserInterfaceRoute + '/' + c_SwaggerUiCssFile,
    pUserInterfaceRoute + '/' + c_SwaggerUiBundleFile,
    pUserInterfaceRoute + '/' + c_SwaggerUiPresetFile];
{$ENDIF}
{$IFDEF DEXT_SWAGDOC_EMBEDDED_SCALAR}
  Result := Result + [pUserInterfaceRoute + '/' + c_ScalarFile];
{$ENDIF}
end;

class function TDextSwagDocUI.Build(const pUserInterface: TDextSwagDocUserInterface; const pTitle,
  pDocumentUrl, pResources: string): string;
begin
  case pUserInterface of
    uiScalar: Result := BuildScalar(pTitle, pDocumentUrl, pResources);
  else
    Result := BuildSwaggerUi(pTitle, pDocumentUrl, pResources);
  end;
end;

class function TDextSwagDocUI.BuildSwaggerUi(const pTitle, pDocumentUrl, pResources: string): string;
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
    '        url: "' + pDocumentUrl + '",' + sLineBreak +
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

class function TDextSwagDocUI.BuildScalar(const pTitle, pDocumentUrl, pResources: string): string;
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
    '    Scalar.createApiReference("#app", { url: "' + pDocumentUrl + '" });' + sLineBreak +
    '  </script>' + sLineBreak +
    '</body>' + sLineBreak +
    '</html>';
end;

end.
