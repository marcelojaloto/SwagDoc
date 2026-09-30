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

program SampleSchemaFromTypes;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Swag.Common.Types,
  Swag.Doc,
  Sample.Pets.Models in 'Sample.Pets.Models.pas',
  Sample.Pets.SwagDoc in 'Sample.Pets.SwagDoc.pas';

procedure SaveDocument(const pSpecVersion: TSwagVersion; const pFolder, pFileName: string);
var
  vSwagDoc: TSwagDoc;
begin
  vSwagDoc := TSamplePetsSwagDoc.CreateDocument(pSpecVersion);
  try
    vSwagDoc.GenerateSwaggerJson;
    vSwagDoc.SwaggerFilesFolder := pFolder;
    vSwagDoc.SwaggerFileName := pFileName;
    vSwagDoc.SaveSwaggerJsonToFile;
    Writeln('Saved ', IncludeTrailingPathDelimiter(pFolder) + pFileName);
  finally
    vSwagDoc.Free;
  end;
end;

var
  vFolder: string;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    // The documents are saved in the folder given as the first parameter, or next to the executable.
    vFolder := ParamStr(1);
    if vFolder.IsEmpty then
      vFolder := ExtractFilePath(ParamStr(0));

    SaveDocument(svOpenApi3, vFolder, 'openapi.json');
    SaveDocument(svSwagger2, vFolder, 'swagger.json');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
