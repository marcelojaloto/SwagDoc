unit SwagGenMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,System.JSON,REST.JSON,IoUtils,
  StrUtils,Generics.Collections,swag.doc,swag.doc.definition;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    swaggerdoc:TSwagDoc;
    body,hdr,refs,fwds:TStringList;
    procedure addln(msg:String);
    function JField(json:TJSONObject; path:String):String;
    procedure BuildDefinition(def:TSwagDefinition);
    procedure CheckRefs(atype:String);
    procedure BuildUtils;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.addln(msg: String);
begin
  memo1.lines.add(msg);
end;

procedure TForm1.BuildDefinition(def: TSwagDefinition);
var aname,adelphitype,atype,ttype,iname,hname:String; detail,properties,info:TJSONObject; p:TJSONPair;
    s:String; fmt:String;
    fromJSON:TStringList;
    toJSON:TStringList;
    fromJSONhdr,toJSONHdr:TStringList;
    aCreate,aDestroy:TStringList;
    hasindex:Boolean;
    isnumber:Boolean;
    isbool:Boolean;

    function GetType(ppair:TJSONPair):String;
    var pname,ptype,ref,s:String;
    begin
      isnumber:=false;
      isbool:=false;
      pname:=ppair.JsonString.Value;
      info:=ppair.JSONValue as TJSONObject;
      ptype:=JField(info,'type');
      if (ptype='string') then result:='String'
      else if (ptype='integer') then
      begin
        isnumber:=true;
        fmt:=jfield(info,'format');
        if fmt='int64' then result:='Int64'
        else result:='Integer';
      end
      else if (ptype='number') then
      begin
        isnumber:=true;
        fmt:=jfield(info,'format');
        if fmt='double' then result:='Double'
        else result:='Double';
      end
      else if (ptype='boolean') then
      begin
        isbool:=true;
        result:='Boolean';
      end
      else if (ptype='array') then // TODO: array may NOT be an object.
      begin
        ref:=info.getValue<String>('items.$ref');
        ttype:='T'+copy(ref,15,length(ref));  // TODO: This may not always be #/definitions/
        CheckRefs(ttype);
        result:='TObjectList<'+ttype+'>';
        if not(HasIndex) then
        begin
          toJSONHdr.add('  jlist:TJSONArray;');
          fromJSONHdr.add('  jvalue:TJSONValue;');
        end;
        hasindex:=true;
        iname:=pname+'Iter';
        toJSONhdr.add('  '+iname+':'+ttype+';');
        toJSON.add('  jlist:=TJSONArray.Create;');
        toJSON.add('  for '+iname+' in '+pname+' do');
        toJSON.add('  begin');
        toJSON.add('    jlist.add('+iname+'.toJSON);');
        toJSON.add('  end;');
        toJSON.add('  json.addpair('''+pname+''',jlist);');

        hname:=pname+'Tmp';
        fromJSONhdr.add('  '+hname+':'+ttype+';');
        fromJSON.add('  '+pname+'.clear;');
        fromJSON.add('  for jvalue in getArray(json,'''+pname+''') do');
        fromJSON.add('  begin');
        fromJSON.add('    '+hname+':='+ttype+'.Create;');
        fromJSON.add('    '+hname+'.FromJSON(jvalue);');
        fromJSON.add('    '+pname+'.add('+hname+');');
        fromJSON.add('  end;');
        aCreate.add('  '+pname+':='+result+'.Create;');
        aDestroy.add('  freeandnil('+pname+');');
      end
      else if (ptype='') then
      begin
        ref:=JField(ppair.JsonValue as TJSONObject, '$ref');
        if StartsStr('#/definitions/',ref) then
        begin
          result:='T'+copy(ref,15,length(ref));
          checkrefs(result);
          toJSON.add('  json.addpair('''+pname+''','+pname+'.toJSON);');
          toJSON.add('  '+pname+'.fromJSON(json.values['''+pname+''']);');
          aCreate.add('  '+pname+':='+result+'.Create;');
          aDestroy.add('  freeandnil('+pname+');');
        end
      end
      else result:=ptype;
      if (ptype<>'') and (ptype<>'array') then
      begin
        s:=pname;
        if (isnumber) then s:='TJSONNumber.Create('+s+')'
        else if (isbool) then s:='TJSONBool.Create('+s+')';
        toJSON.add(  '  json.addpair('''+pname+''','+s+');');
        fromJSON.add('  '+pname+':=getValue<'+result+'>(json,'''+pname+''');');
      end;
    end;

begin
  aname:=def.Name;
  detail:=def.JsonSchema;
  atype:=JField(detail,'type');
  hdr.add('');
  hdr.add('// '+aname+': '+atype);
  toJSON:=nil;
  fromJSON:=nil;
  aCreate:=nil;
  aDestroy:=nil;
  if (atype='object') then
  begin
    toJSON:=TStringList.Create;
    fromJSON:=TStringList.Create;
    acreate:=TStringList.Create;
    adestroy:=TStringList.Create;
    fromJSONhdr:=TStringList.Create;
    toJSONhdr:=TStringList.Create;
    try
      adelphiType:='T'+aname;
      hasindex:=false;
     if (refs.indexof(adelphitype)<0) then refs.add(aDelphiType);
      hdr.add('  '+adelphiType+' = class(TSwaggerBase)');
      properties:=detail.values['properties'] as TJSONObject;
      for p in properties do
      begin
        s:=p.JsonString.value+': ';
        s:=s+GetType(p);
        hdr.add('    '+s+';');
      end;
      if (aCreate.Count>0) then
      begin
        hdr.add('    constructor Create;');
        body.add('constructor '+ADelphiType+'.Create;');
        body.add('begin');
        body.AddStrings(aCreate);
        body.add('end;');
        body.add('');
      end;
      if (aDestroy.Count>0) then
      begin
        hdr.add('    destructor Destroy; override;');
        body.add('destructor '+aDelphiType+'.Destroy;');
        body.add('begin');
        body.AddStrings(aDestroy);
        body.add('  inherited;');
        body.add('end;');
        body.add('');
      end;
      hdr.add('    function ToJSON:TJSONObject; override;');
      hdr.add('    procedure FromJSON(jsonvalue:TJSONValue); override;');
      hdr.add('  end;');
      body.add('function '+aDelphiType+'.ToJSON:TJSONObject;');
      body.add('var json:TJSONObject;');
      body.addStrings(toJSONHdr);
      body.add('begin');
      body.add('  json:=TJSONObject.Create;');
      body.addStrings(toJSON);
      body.add('  result:=json;');
      body.add('end;');
      body.add('');
      body.add('procedure '+aDelphiType+'.FromJSON(jsonvalue:TJSONValue);');
      body.add('var json:TJSONObject;');
      body.addStrings(fromJSONHdr);
      body.add('begin');
      body.add('  json:=jsonvalue as TJSONObject;');
      body.addStrings(fromJSON);
      body.add('end;');
      body.add('');
    finally
      toJSON.free;
      fromJSON.free;
      fromJSONHdr.free;
      toJSONHdr.free;
      aCreate.Free;
      aDestroy.Free;
    end;
  end;
end;

procedure TForm1.BuildUtils;
begin
  hdr.add('// A base utility class for the generated objects.');
  hdr.add('// For multiple APIs, this would be better copied into its own unit.');
  hdr.add('TSwaggerBase = class');
  hdr.add('public');
  hdr.add('  isStrict:Boolean; // Throw error if data is missing.');
  hdr.add('  function ToJSON:TJSONObject; virtual; abstract;');
  hdr.add('  procedure FromJSON(json:TJSONValue); virtual; abstract;');
  hdr.add('  function GetValue<T>(json:TJSONObject; path:String):T;');
  hdr.add('  function GetArray(json:TJSONObject; path:String):TJSONArray;');
  hdr.add('end;');
  body.add('function TSwaggerBase.GetValue<T>(json:TJSONObject; path:String):T;');
  body.add('var tmp:T;');
  body.add('begin');
  body.add('  if (isStrict) then result:=json.GetValue<T>(path)');
  body.add('  else');
  body.add('  begin');
  body.add('    if (json.TryGetValue<T>(path,tmp)) then result:=tmp');
  body.add('    else result:=default(T);');
  body.add('  end;');
  body.add('end;');
  body.add('');
  body.add('function TSwaggerBase.GetArray(json:TJSONObject; path:String):TJSONArray;');
  body.add('begin');
  body.add('  result:=nil;');
  body.add('  try');
  body.add('    result:=json.GetValue(path) as TJSONArray;');
  body.add('  except');
  body.add('  end;');
  body.add('  if result=nil then result:=TJSONArray.Create;');
  body.add('end;');
  body.add('');
end;

procedure TForm1.Button1Click(Sender: TObject);
var json:TJSONObject;
begin
  if not Opendialog1.Execute then exit;
  try
    swaggerdoc.LoadFromFile(OpenDialog1.FileName);
    json:=swaggerdoc.SwaggerJson as TJSONObject;
    memo1.Text:=TJSON.Format(json);
  except
    on e:Exception do addln(e.classname+': '+e.Message);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var version:String; definitions:TJSONObject; item:TSwagDefinition; s,title:String;
begin
  version:=swaggerdoc.SwaggerVersion;
  if (version='') then
  begin
    addln('Not swagger file.');
    exit;
  end;
  memo1.clear;
  body.clear;
  refs.clear;
  fwds.clear;
  title:=swaggerdoc.Info.Title;
  addln('Unit '+StringReplace(title,' ','_',[])+';');
  addln('interface');
  addln('uses Sysutils,System.JSON,Generics.Collections;');
  addln('//Swagger: '+version);
  addln('//Title:  '+title+';');
  addln('//Version:'+swaggerdoc.Info.Version);
  addln('type ');

  if (swaggerdoc.Definitions.Count<1) then
  begin
    addln('No definitions');
    exit;
  end;
  BuildUtils;
  for item in swaggerdoc.definitions do
  begin
//    addln(item.JsonString.value);
    BuildDefinition(item);
  end;
  for s in fwds do
  begin
    addln('  '+s+' = class;');
  end;
  addln('');
  memo1.lines.addStrings(hdr);
  addln('implementation');
  addln('');
  memo1.Lines.addStrings(body);
  addln('end.');
end;

procedure TForm1.CheckRefs(atype: String);
begin
  if refs.IndexOf(atype)<0 then
  begin
    refs.add(atype);
    fwds.add(atype);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  swaggerdoc:=TSwagDoc.Create;
  body:=TStringList.Create;
  hdr:=TStringList.Create;
  refs:=TStringList.Create;
  fwds:=TStringList.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  freeandnil(swaggerdoc);
  freeandnil(body);
  freeandnil(hdr);
  freeandnil(refs);
  freeandnil(fwds);
end;

function TForm1.JField(json: TJSONObject; path: String): String;
var node:TJSONValue;
begin
  result:='';
  if not(assigned(json)) then exit;
  node:=json.Values[path];
  if (node=nil) then exit;
  result:=vartostr(node.Value);
end;

end.
