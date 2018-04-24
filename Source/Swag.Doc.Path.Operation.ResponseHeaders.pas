unit Swag.Doc.Path.Operation.ResponseHeaders;

interface

uses System.SysUtils, system.json;

type

  TSwagHeaders = class(TObject)
  private
    fName: string;
    fDescription: string;
    fType: string;
  public

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson : TJSONObject);

    property Name: string read fName write fName;
    property Description: string read fDescription write fDescription;
    property ValueType: string read fType write fType;
  end;

implementation

{ TSwagHeaders }

function TSwagHeaders.GenerateJsonObject: TJSONObject;
var
  vJsonObject: TJsonObject;
begin
  vJsonObject := TJSONObject.Create;
  if fDescription.Length > 0 then
    vJsonObject.AddPair('description',fDescription);
  if fType.Length > 0 then
    vJsonObject.AddPair('type',fType);
  Result := vJsonObject;
end;

procedure TSwagHeaders.Load(pJson: TJSONObject);
begin
  if Assigned(pJson.Values['description']) then
    fDescription := pJson.Values['description'].Value;
  if Assigned(pJson.Values['type']) then
    fType := pJson.Values['type'].Value;
end;

end.
