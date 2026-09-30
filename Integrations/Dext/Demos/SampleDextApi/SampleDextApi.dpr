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

program SampleDextApi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Dext,
  Dext.Web,
  Dext.Json,
  Dext.Json.Types,
  Dext.Swagger.Middleware,
  Dext.OpenAPI.Generator,
  Dext.SwagDoc,
  Swag.Common.Types,
  Sample.Dext.Models in 'Sample.Dext.Models.pas',
  Sample.Dext.Pets in 'Sample.Dext.Pets.pas',
  Sample.Dext.Orders in 'Sample.Dext.Orders.pas';

const
  c_Port = 9000;

var
  vApp: IWebApplication;
  vNativeOptions: TOpenAPIOptions;
begin
  try
    // The serializer of Dext writes camelCase names and enumerations by name. SwagDoc reads the same settings,
    // so the document describes the JSON that the endpoints really send.
    JsonDefaultSettings(TJsonSettings.Default.CamelCase.EnumAsString);

    vApp := TDextApplication.Create;
    vApp.Services.AddControllers;

    SwagDocConfig.UserInterfaceTitle := 'Pet Store';

    // Run the sample with the -scalar parameter to render the document with Scalar instead of Swagger UI.
    if FindCmdLineSwitch('scalar') then
      SwagDocConfig.UserInterface := uiScalar;

    // Run the sample with the -swagger2 parameter to publish a Swagger 2.0 document instead of an OpenAPI 3 one.
    // A Swagger 2.0 document has no servers list, so the address of the API is given by the host. The basePath
    // is left out while it is empty, because the document of the middleware sets OmitEmptyBasePath.
    if FindCmdLineSwitch('swagger2') then
    begin
      SwagDocConfig.DocumentRoute := '/docs/swagger.json';
      SwagDocApi.SpecVersion := svSwagger2;
      SwagDocApi.Host := Format('localhost:%d', [c_Port]);
    end;

    // Run the sample with the -www parameter to load the files of the interface from the www folder next to the
    // executable, published by the static files middleware of Dext, instead of a CDN.
    if FindCmdLineSwitch('www') then
    begin
      vApp.Builder.UseStaticFiles(TPath.Combine(ExtractFilePath(ParamStr(0)), 'www'));
      if SwagDocConfig.UserInterface = uiScalar then
        SwagDocConfig.UserInterfaceResources := '/scalar'
      else
        SwagDocConfig.UserInterfaceResources := '/swagger-ui';
    end;

    SwagDocApi.Info.Title := 'Pet Store';
    SwagDocApi.Info.Version := '1.0.0';
    SwagDocApi.Info.Description := 'Sample API written with Dext and documented with SwagDoc.';
    SwagDocApi.AddServer(Format('http://localhost:%d', [c_Port]));

    // The document is generated on the first request, so every endpoint below is documented, even the ones
    // registered after this line.
    TDextSwagDoc.Use(vApp.Builder);

    TSamplePetsApi.DocumentApi;
    TSamplePetsApi.MapEndpoints(vApp.Builder);
    vApp.MapControllers;

    // An endpoint without any description is also written in the document.
    vApp.Builder.MapGet('/health',
      procedure(pContext: IHttpContext)
      begin
        pContext.Response.Json('{"status":"up"}');
      end);

    // The Swagger support of Dext itself, published at /swagger for comparison.
    vNativeOptions := TOpenAPIOptions.Default;
    vNativeOptions.Title := 'Pet Store';
    vNativeOptions.Version := '1.0.0';
    TSwaggerExtensions.UseSwagger(vApp.Builder, vNativeOptions);

    Writeln(Format('The sample API is running on http://localhost:%d', [c_Port]));
    Writeln(Format('Documentation: http://localhost:%d%s', [c_Port, SwagDocConfig.UserInterfaceRoute]));
    Writeln(Format('Document: http://localhost:%d%s', [c_Port, SwagDocConfig.DocumentRoute]));
    Writeln(Format('Swagger support of Dext: http://localhost:%d/swagger', [c_Port]));

    vApp.Run(c_Port);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
