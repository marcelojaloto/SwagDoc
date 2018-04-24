unit frmSimpleDemo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Swag.Doc.Definition,
  Swag.Doc, Swag.Doc.Path, Swag.Doc.Path.Operation, Swag.Common.Types,Vcl.StdCtrls;

type
  TfrmSimpleSwaggerDocDemo = class(TForm)
    Memo1: TMemo;
    btnLoadJSON: TButton;
    procedure btnLoadJSONClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    fSwagDoc: TSwagDoc;
  public
    { Public declarations }
  end;

var
  frmSimpleSwaggerDocDemo: TfrmSimpleSwaggerDocDemo;

implementation

{$R *.dfm}

uses REST.Json, System.IOUtils;

procedure TfrmSimpleSwaggerDocDemo.btnLoadJSONClick(Sender: TObject);
var
  vFullFilename : String;
begin
  vFullFilename := TPath.Combine(GetCurrentDir,'flickr.json');
  fSwagDoc.LoadFromFile(vFullFilename);
  fSwagDoc.GenerateSwaggerJson;
  Memo1.Lines.Add(REST.Json.TJson.Format(fSwagDoc.SwaggerJson));
end;

procedure TfrmSimpleSwaggerDocDemo.FormCreate(Sender: TObject);
begin
  fSwagDoc := TSwagDoc.Create;
end;

procedure TfrmSimpleSwaggerDocDemo.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fSwagDoc);
end;

end.
