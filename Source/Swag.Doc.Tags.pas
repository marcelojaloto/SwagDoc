unit Swag.Doc.Tags;

interface

uses
  System.SysUtils,
  System.JSON;

type
  TSwagExternalDocs = class(TObject)
  strict private
    fDescription: string;
    fUrl: string;
  public
    property Description: string read fDescription write fDescription;
    property Url: string read fUrl write FUrl;

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson: TJSONObject);
  end;

  TSwagTag = class(TObject)
  strict private
    fName: string;
    fDescription: string;
    fExternalDocs: TSwagExternalDocs;

  public
    property Name: string read fName write fName;
    property Description: string read fDescription write fDescription;
    property ExternalDocs: TSwagExternalDocs read fExternalDocs write fExternalDocs;

    constructor Create;
    destructor Destroy;

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson: TJSONObject);
  end;

implementation

{ TSwagTag }

constructor TSwagTag.Create;
begin
  fExternalDocs := TSwagExternalDocs.Create;
end;

destructor TSwagTag.Destroy;
begin
  FreeAndNil(fExternalDocs);
end;

function TSwagTag.GenerateJsonObject: TJSONObject;
var
  vExternalDocs : TJSONObject;
begin
  Result := TJsonObject.Create;
  if fName.Length > 0 then
    Result.AddPair('name', fName);
  if fDescription.Length > 0 then
    Result.AddPair('description', fDescription);

  vExternalDocs := fExternalDocs.GenerateJsonObject;
  if Assigned(vExternalDocs) then
    Result.AddPair('externalDocs', vExternalDocs);
end;

procedure TSwagTag.Load(pJson: TJSONObject);
begin
  if not Assigned(pJson) then
    Exit;
  if Assigned(pJson.Values['description']) then
    fDescription := pJson.Values['description'].Value;
  if Assigned(pJson.Values['name']) then
    fName := pJson.Values['name'].Value;
  if Assigned(pJson.Values['externalDocs']) then
    fExternalDocs.Load(pJson.Values['externalDocs'] as TJSONObject);
end;

{ TSwagExternalDocs }

function TSwagExternalDocs.GenerateJsonObject: TJSONObject;
begin
  Result := nil;
  if (fDescription.Length = 0) and (fUrl.Length = 0) then
    Exit;
  Result := TJsonObject.Create;
  if fDescription.Length > 0 then
    Result.AddPair('description', fDescription);
  if fUrl.Length > 0 then
    Result.AddPair('url', fUrl);
end;

procedure TSwagExternalDocs.Load(pJson: TJSONObject);
begin
  if Assigned(pJson.Values['description']) then
    fDescription := pJson.Values['description'].Value;
  if Assigned(pJson.Values['url']) then
    fUrl := pJson.Values['url'].Value;
end;

end.
