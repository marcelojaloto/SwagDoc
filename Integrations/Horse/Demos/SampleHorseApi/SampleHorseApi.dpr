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

program SampleHorseApi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.SwagDoc,
  Swag.Common.Types,
  Sample.Api.Pets in 'Sample.Api.Pets.pas';

const
  c_Port = 9000;

begin
  SwagDocConfig.UserInterfaceTitle := 'Pet Store';

  // Run the sample with the -scalar parameter to render the document with Scalar instead of Swagger UI.
  if FindCmdLineSwitch('scalar') then
    SwagDocConfig.UserInterface := uiScalar;

  // Run the sample with the -swagger2 parameter to publish a Swagger 2.0 document instead of an OpenAPI 3 one.
  if FindCmdLineSwitch('swagger2') then
    SwagDocConfig.DocumentRoute := '/docs/swagger.json';

  THorse.Use(HorseSwagDoc);

  if FindCmdLineSwitch('swagger2') then
    SwagDocApi.SpecVersion := svSwagger2;

  SwagDocApi.Info.Title := 'Pet Store';
  SwagDocApi.Info.Version := '1.0.0';
  SwagDocApi.Info.Description := 'Sample API documented with SwagDoc in an application written with Horse.';

  TSamplePetsApi.DocumentApi(SwagDocApi);
  TSamplePetsApi.RegisterRoutes;

  // The route below is not documented by the application, so it is written in the document by the discovery
  // of the registered routes.
  THorse.Get('/health',
    procedure(pRequest: THorseRequest; pResponse: THorseResponse)
    begin
      pResponse.ContentType('application/json').Send('{"status":"up"}');
    end);

  THorse.Listen(c_Port,
    procedure
    begin
      Writeln(Format('The sample API is running on http://localhost:%d', [c_Port]));
      Writeln(Format('Documentation: http://localhost:%d%s', [c_Port, SwagDocConfig.UserInterfaceRoute]));
      Writeln(Format('Document: http://localhost:%d%s', [c_Port, SwagDocConfig.DocumentRoute]));
    end);
end.
