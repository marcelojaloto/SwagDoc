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

unit Sample.Main;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.TabControl
  ;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Memo2: TMemo;
    btnGenerateClient: TButton;
    procedure btnGenerateClientClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  Swag.Doc,
  SwagDoc.DelphiRESTClient,
  System.IOUtils
  ;

procedure TForm1.btnGenerateClientClick(Sender: TObject);
var
  clientBuilder : TSwagDocToDelphiRESTClientBuilder;
  swagDoc : TSwagDoc;
  filename : string;
begin
  clientBuilder := nil;
  try
    swagDoc := TSwagDoc.Create;
    filename := 'C:\Programming\SwagDoc\Demos\SwaggerSampleApi\Swagger.json';
    swagDoc.LoadFromFile(filename);
    memo1.Lines.Text := TFile.ReadAllText(filename);
    clientBuilder := TSwagDocToDelphiRESTClientBuilder.Create(swagDoc);
    memo2.Lines.Text := clientBuilder.Generate;
  finally
    FreeAndNil(clientBuilder);
    FreeAndNil(swagDoc);
  end;
end;

initialization
  ReportMemoryLeaksOnShutdown := True;

end.
