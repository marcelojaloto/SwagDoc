unit SwagDoc.DelphiRESTClient;

interface

uses
  classes,
  system.json,
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Swag.Doc,
  Swag.Common.Types,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.Path.Operation.RequestParameter,
  DelphiUnit
  ;

type


  TSwagDocToDelphiRESTClientBuilder = class(TObject)
  private
    FSwagDoc : TSwagDoc;
    function CapitalizeFirstLetter(const typeName: string): string;
    function RewriteUriToSwaggerWay(const uri:string): string;
    function OperationIdToFunctionName(inOperation: TSwagPathOperation): string;
    procedure SortTypeDefinitions(delphiUnit: TDelphiUnit);
    function GenerateUnitText(delphiUnit: TDelphiUnit): string;
    procedure ConvertSwaggerDefinitionsToTypeDefinitions(delphiUnit: TDelphiUnit);
    function ConvertSwaggerTypeToDelphiType(inSwaggerType: TSwagRequestParameter): string;
    function ConvertRefToType(const inRef:String): string;
    function ConvertRefToVarName(const inRef:String): string;
    procedure ChildType(DelphiUnit : TDelphiUnit; json: TJSONPair);
    procedure HandleArray(inField: TUnitFieldDefinition; json: TJSONPair);
  public
    constructor Create(SwagDoc: TSwagDoc);
    function Generate: string;
  end;

implementation

uses
  Json.Common.Helpers
  , Winapi.Windows
  , System.IOUtils
  ;

{ TSwagDocToDelphiMVCFrameworkBuilder }

function TSwagDocToDelphiRESTClientBuilder.OperationIdToFunctionName(inOperation: TSwagPathOperation):string;
begin
  Result := inOperation.OperationId.Replace('{','').Replace('}','').Replace('-','');
  if not CharInSet(Result[1], ['a'..'z','A'..'Z']) then
    Result := 'F' + Result;

  Result := CapitalizeFirstLetter(Result);
end;

function TSwagDocToDelphiRESTClientBuilder.RewriteUriToSwaggerWay(const uri:string):string;
begin
  Result := uri.Replace('{','($').Replace('}',')');
end;

function TSwagDocToDelphiRESTClientBuilder.CapitalizeFirstLetter(const typeName: string): string;
begin
  if typeName.Length > 2 then
    Result := Copy(typeName, 1, 1).ToUpper + Copy(typeName, 2, typeName.Length - 1)
  else
    Result := typeName;
end;


constructor TSwagDocToDelphiRESTClientBuilder.Create(SwagDoc: TSwagDoc);
begin
  FSwagDoc := SwagDoc;
end;

function TSwagDocToDelphiRESTClientBuilder.ConvertRefToType(const inRef:String):string;
begin
  Result := Copy(inRef, inRef.LastIndexOf('/') + 2);
  Result := Copy(Result,1,1).ToUpper + Copy(Result,2);
  if Result.ToLower <> 'string' then
    Result := 'T' + Result;
end;

function TSwagDocToDelphiRESTClientBuilder.ConvertRefToVarName(const inRef:String):string;
begin
  Result := Copy(inRef, inRef.LastIndexOf('/') + 2);
end;

function TSwagDocToDelphiRESTClientBuilder.Generate: string;
var
  i: Integer;
  j: Integer;
  k: Integer;
  LDelphiUnit : TDelphiUnit;
  LMVCControllerClient : TUnitTypeDefinition;
  LMethod : TUnitMethod;
  LParam : TUnitParameter;
  LParamType : TUnitTypeDefinition;
  LResponse : TPair<string, TSwagResponse>;
  LSchemaObj : TJsonObject;
  LResultParam : TUnitParameter;
  LField : TUnitFieldDefinition;
  LRef : String;
begin
  LDelphiUnit := nil;
  try
    LDelphiUnit := TDelphiUnit.Create;
    LDelphiUnit.UnitFile := 'mvccontrollerclient';
    LDelphiUnit.AddInterfaceUnit('IPPeerClient');
    LDelphiUnit.AddInterfaceUnit('REST.Client');
    LDelphiUnit.AddInterfaceUnit('REST.Authenticator.OAuth');
    LDelphiUnit.AddInterfaceUnit('REST.Types');
    LDelphiUnit.AddInterfaceUnit('MVCFramework');
    LDelphiUnit.AddInterfaceUnit('MVCFramework.Commons');
    LDelphiUnit.AddImplementationUnit('Swag.Doc');

    ConvertSwaggerDefinitionsToTypeDefinitions(LDelphiUnit);


    LMVCControllerClient := TUnitTypeDefinition.Create;
    LMVCControllerClient.TypeName := 'TMyMVCControllerClient';
    LMVCControllerClient.TypeInherited := 'TObject';
    LMVCControllerClient.AddAttribute('  [MVCPath(''' + RewriteUriToSwaggerWay(fSwagDoc.BasePath) + ''')]');

    LField := TUnitFieldDefinition.Create;
    LField.FieldName := 'RESTClient';
    LField.FieldType := 'TRESTClient';
    LMVCControllerClient.Fields.Add(LField);

    LField := TUnitFieldDefinition.Create;
    LField.FieldName := 'RESTRequest';
    LField.FieldType := 'TRESTRequest';
    LMVCControllerClient.Fields.Add(LField);

    LField := TUnitFieldDefinition.Create;
    LField.FieldName := 'RESTResponse';
    LField.FieldType := 'TRESTResponse';
    LMVCControllerClient.Fields.Add(LField);

    LDelphiUnit.AddType(LMVCControllerClient);
    ConvertSwaggerDefinitionsToTypeDefinitions(LDelphiUnit);

    for i := 0 to fSwagDoc.Paths.Count - 1 do
    begin
      for j := 0 to fSwagDoc.Paths[i].Operations.Count - 1 do
      begin
        LMethod := TUnitMethod.Create;
        LMethod.AddAttribute('    [MVCDoc(' + QuotedStr(fSwagDoc.Paths[i].Operations[j].Description) + ')]');
        LMethod.AddAttribute('    [MVCPath(''' + fSwagDoc.Paths[i].Uri + ''')]');
        LMethod.AddAttribute('    [MVCHTTPMethod([http' + fSwagDoc.Paths[i].Operations[j].OperationToString + '])]');
        LMethod.Name := OperationIdToFunctionName(fSwagDoc.Paths[i].Operations[j]);

              for k := 0 to FSwagDoc.Paths[i].Operations[j].Parameters.Count - 1 do
              begin
//              if fSwagDoc.Paths[i].Operations[j].Parameters[k].InLocation <> rpiPath then
                begin
                  LResultParam := TUnitParameter.Create;
                  LResultParam.ParamName := CapitalizeFirstLetter(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name);
                  LResultParam.ParamType := TUnitTypeDefinition.Create;
                  LResultParam.ParamType.TypeName := ConvertSwaggerTypeToDelphiType(fSwagDoc.Paths[i].Operations[j].Parameters[k]);
                  LMethod.AddParameter(LResultParam);
//                  LMethod.AddLocalVariable(LResultParam);
//                  LMethod.Content.Add('  param' + TidyUpTypeName(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name) + ' := Context.Request.Params[' + QuotedStr(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name) + '];');
                end;
              end;


        for LResponse in FSwagDoc.Paths[i].Operations[j].Responses do
        begin
//        MVCResponse(200, 'success', TEmployee)
          LSchemaObj := LResponse.Value.Schema.JsonSchema;
          if LSchemaObj = nil then
            continue;
          if LSchemaObj.TryGetValue('$ref', LRef) then
          begin
            LMethod.AddAttribute('    [MVCResponse(' + LResponse.Key + ', ' +
                                                   QuotedStr(LResponse.Value.Description) + ', ' + ConvertRefToType(LRef) + ')]');
            LResultParam := TUnitParameter.Create;
            LResultParam.ParamName := ConvertRefToVarName(LRef);
            LResultParam.ParamType := TUnitTypeDefinition.Create;
            LResultParam.ParamType.TypeName := ConvertRefToType(LRef);
            LMethod.AddLocalVariable(LResultParam);
            LMethod.Content.Add('  ' + ConvertRefToVarName(LRef) + ' := ' + ConvertRefToType(LRef) + '.Create;');
              for k := 0 to FSwagDoc.Paths[i].Operations[j].Parameters.Count - 1 do
              begin
//              if fSwagDoc.Paths[i].Operations[j].Parameters[k].InLocation <> rpiPath then
                begin
                  LResultParam := TUnitParameter.Create;
                  LResultParam.ParamName := CapitalizeFirstLetter(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name);
                  LResultParam.ParamType := TUnitTypeDefinition.Create;
                  LResultParam.ParamType.TypeName := ConvertSwaggerTypeToDelphiType(fSwagDoc.Paths[i].Operations[j].Parameters[k]);
                  if LResultParam.ParamType.TypeName = 'array of' then
                  begin
                    LResultParam.ParamType.TypeName := LResultParam.ParamType.TypeName + ' ' + fSwagDoc.Paths[i].Operations[j].Parameters[k].Schema.JsonSchema.Values['type'].Value;
                  end;
                  LMethod.AddParameter(LResultParam);
//                  LMethod.AddLocalVariable(LResultParam);
//                  LMethod.Content.Add('  param' + TidyUpTypeName(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name) + ' := Context.Request.Params[' + QuotedStr(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name) + '];');
                end;
              end;
//            method.Content.Add('  Render(' + response.Key + ', ' + ConvertRefToVarName(ref) + ');');
          end
          else
          begin
            if not LSchemaObj.TryGetValue('properties', LSchemaObj) then
              continue;
            if not LSchemaObj.TryGetValue('employees', LSchemaObj) then
              continue;
            if not LSchemaObj.TryGetValue('items', LSchemaObj) then
              continue;
            if LSchemaObj.TryGetValue('$ref', LRef) then
            begin
              LMethod.AddAttribute('    [MVCResponseList(' + LResponse.Key + ', ' +
                                                     QuotedStr(LResponse.Value.Description) + ', ' + ConvertRefToType(LRef) + ')]');
              LResultParam := TUnitParameter.Create;
              LResultParam.ParamName := ConvertRefToVarName(LRef);
              LResultParam.ParamType := TUnitTypeDefinition.Create;
              LResultParam.ParamType.TypeName := 'TObjectList<' + ConvertRefToType(LRef) + '>';
              LMethod.AddLocalVariable(LResultParam);
              LDelphiUnit.AddInterfaceUnit('Generics.Collections');
              LMethod.Content.Add('  ' + ConvertRefToVarName(LRef) + ' := TObjectList<' + ConvertRefToType(LRef) + '>.Create;');

              for k := 0 to FSwagDoc.Paths[i].Operations[j].Parameters.Count - 1 do
              begin
//                if fSwagDoc.Paths[i].Operations[j].Parameters[k].InLocation <> rpiPath then
                begin
                  LResultParam := TUnitParameter.Create;
                  LResultParam.ParamName := fSwagDoc.Paths[i].Operations[j].Parameters[k].Name;
                  LResultParam.ParamType := TUnitTypeDefinition.Create;
                  LResultParam.ParamType.TypeName := ConvertSwaggerTypeToDelphiType(fSwagDoc.Paths[i].Operations[j].Parameters[k]);
                  LMethod.AddLocalVariable(LResultParam);
                  LMethod.Content.Add('  ' + fSwagDoc.Paths[i].Operations[j].Parameters[k].Name + ' := Context.Request.Params[' + QuotedStr(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name) + '];');
                end;
              end;



//              method.Content.Add('  Render(' + response.Key + ', ' + ConvertRefToVarName(ref) + ');');
            end
            else
            begin
              for k := 0 to FSwagDoc.Paths[i].Operations[j].Parameters.Count - 1 do
              begin
//                if fSwagDoc.Paths[i].Operations[j].Parameters[k].InLocation <> rpiPath then
                begin
                  LResultParam := TUnitParameter.Create;
                  LResultParam.ParamName := fSwagDoc.Paths[i].Operations[j].Parameters[k].Name;
                  LResultParam.ParamType := TUnitTypeDefinition.Create;
                  LResultParam.ParamType.TypeName := ConvertSwaggerTypeToDelphiType(fSwagDoc.Paths[i].Operations[j].Parameters[k]);
                  LMethod.AddLocalVariable(LResultParam);
                  LMethod.Content.Add('  ' + fSwagDoc.Paths[i].Operations[j].Parameters[k].Name + ' := Context.Request.Params[' + QuotedStr(fSwagDoc.Paths[i].Operations[j].Parameters[k].Name) + '];');
                end;
              end;
              LMethod.AddAttribute('    [MVCResponse(' + LResponse.Key + ', ' +
                                                   QuotedStr(LResponse.Value.Description) + ')]');
            end;
          end;
        end;

        LMVCControllerClient.FMethods.Add(LMethod);
      end;
    end;

    SortTypeDefinitions(LDelphiUnit);

    Result := GenerateUnitText(LDelphiUnit);
  finally
    LDelphiUnit.Free;
  end;
end;

procedure TSwagDocToDelphiRESTClientBuilder.HandleArray(inField : TUnitFieldDefinition; json: TJSONPair);
var
  jsonObj : TJSONObject;
  jsonVal : TJSONValue;
  LType : String;
begin
  if Assigned(((json.JsonValue as TJSONObject).Values['items'] as TJSONObject).Values['type']) then
  begin
    LType := ((json.JsonValue as TJSONObject).Values['items'] as TJSONObject).Values['type'].Value;
    if LType.ToLower <> 'string' then
      LType := 'T' + LType;
    inField.FieldType := 'array of ' + LType;
  end
  else
  begin
    OutputDebugString(PChar(json.ToJSON));
    jsonVal := (json.JsonValue as TJSONObject).Values['items'] as TJSONObject;
    OutputDebugString(PChar(jsonVal.ToJSON));
    jsonObj := jsonVal as TJSONObject;
    jsonVal := jsonObj.Values['$ref'];
    OutputDebugString(PChar(jsonVal.Value));
    inField.FieldType := 'array of ' + ConvertRefToType(jsonVal.value);
  end;
end;


procedure TSwagDocToDelphiRESTClientBuilder.ChildType(DelphiUnit : TDelphiUnit; json: TJSONPair);
var
  LTypeInfo: TUnitTypeDefinition;
  LJsonProps: TJSONObject;
  LFieldInfo: TUnitFieldDefinition;
  LTypeObj: TJSONObject;
  j: Integer;
  LValue : string;
begin
  OutputDebugString(PChar('Child: ' + json.ToJSON));
  LTypeInfo := TUnitTypeDefinition.Create;
  LTypeInfo.TypeName := 'T' + CapitalizeFirstLetter(json.JSONString.Value);

  LJsonProps := (json.JSONValue as TJSONObject).Values['properties'] as TJSONObject;
  for j := 0 to LJsonProps.Count - 1 do
  begin
    OutputDebugString(PChar(LJsonProps.Pairs[j].ToJSON));
    LFieldInfo := TUnitFieldDefinition.Create;
    LFieldInfo.FieldName := LJsonProps.Pairs[j].JsonString.Value;
    LTypeObj := LJsonProps.Pairs[j].JsonValue as TJSONObject;
    LFieldInfo.FieldType := LTypeObj.Values['type'].Value;
    if LFieldInfo.FieldType = 'number' then
      LFieldInfo.FieldType := 'Double'
    else if LFieldInfo.FieldType = 'object' then
    begin
      LFieldInfo.FieldType := 'T' + CapitalizeFirstLetter(LJsonProps.Pairs[j].JsonString.Value);
      ChildType(DelphiUnit, LJsonProps.Pairs[j]);
    end;
    if LTypeObj.TryGetValue('description', LValue) then
      LFieldInfo.AddAttribute('[MVCDoc(' + QuotedStr(LValue) + ')]');
    if LTypeObj.TryGetValue('format', LValue) then
      LFieldInfo.AddAttribute('[MVCFormat(' + QuotedStr(LValue) + ')]');
    if LTypeObj.TryGetValue('maxLength', LValue) then
      LFieldInfo.AddAttribute('[MVCMaxLength(' + LValue + ')]');
    LTypeInfo.Fields.Add(LFieldInfo);
  end;
  delphiUnit.AddType(LTypeInfo);
end;

procedure TSwagDocToDelphiRESTClientBuilder.ConvertSwaggerDefinitionsToTypeDefinitions(delphiUnit: TDelphiUnit);
var
  LTypeInfo: TUnitTypeDefinition;
  LJsonProps: TJSONObject;
  LFieldInfo: TUnitFieldDefinition;
  LTypeObj: TJSONObject;
  i: Integer;
  j: Integer;
  LValue : string;
begin
  for i := 0 to fSwagDoc.Definitions.Count - 1 do
  begin
    LTypeInfo := TUnitTypeDefinition.Create;
    LTypeInfo.TypeName := 'T' + CapitalizeFirstLetter(fSwagDoc.Definitions[i].Name);
    LJsonProps := fSwagDoc.Definitions[i].JsonSchema.Values['properties'] as TJSONObject;
    for j := 0 to LJsonProps.Count - 1 do
    begin
      OutputDebugString(PChar(LJsonProps.Pairs[j].ToJSON));
      LFieldInfo := TUnitFieldDefinition.Create;
      LFieldInfo.FieldName := LJsonProps.Pairs[j].JsonString.Value;
      LTypeObj := LJsonProps.Pairs[j].JsonValue as TJSONObject;
      if Assigned(LTypeObj.Values['type']) then
        LFieldInfo.FieldType := LTypeObj.Values['type'].Value
      else
        LFieldInfo.FieldType := ConvertRefToType(LTypeObj.Values['$ref'].Value);

      if LFieldInfo.FieldType = 'number' then
        LFieldInfo.FieldType := 'Double'
      else if LFieldInfo.FieldType = 'object' then
      begin
        LFieldInfo.FieldType := 'T' + CapitalizeFirstLetter(LJsonProps.Pairs[j].JsonString.Value);
        ChildType(DelphiUnit, LJsonProps.Pairs[j]);
      end
      else if LFieldInfo.FieldType = 'array' then
      begin
        HandleArray(LFieldInfo, LJsonProps.Pairs[j]);
      end;
      if LTypeObj.TryGetValue('description', LValue) then
        LFieldInfo.AddAttribute('[MVCDoc(' + QuotedStr(LValue) + ')]');
      if LTypeObj.TryGetValue('format', LValue) then
        LFieldInfo.AddAttribute('[MVCFormat(' + QuotedStr(LValue) + ')]');
      if LTypeObj.TryGetValue('maxLength', LValue) then
        LFieldInfo.AddAttribute('[MVCMaxLength(' + LValue + ')]');
      if LTypeObj.TryGetValue('minimum', LValue) then
        LFieldInfo.AddAttribute('[MVCMinimum(' + LValue + ')]');
      if LTypeObj.TryGetValue('maximum', LValue) then
        LFieldInfo.AddAttribute('[MVCMaximum(' + LValue + ')]');
      LTypeInfo.Fields.Add(LFieldInfo);
    end;
    delphiUnit.AddType(LTypeInfo);
  end;
end;

function TSwagDocToDelphiRESTClientBuilder.ConvertSwaggerTypeToDelphiType(inSwaggerType: TSwagRequestParameter): string;
var
  LSwaggerType : TSwagTypeParameter;
  json : TJSONObject;
begin
  LSwaggerType := inSwaggerType.TypeParameter;
  case LSwaggerType of
    stpNotDefined:
    begin
      if Assigned(inSwaggerType.Schema.JsonSchema.Values['$ref']) then
        Result := ConvertRefToType(inSwaggerType.Schema.JsonSchema.Values['$ref'].Value)
      else
      begin
        Result := inSwaggerType.Schema.JsonSchema.Values['type'].Value;
        if Result = 'array' then
        begin
          if Assigned(inSwaggerType.Schema.JsonSchema.Values['items']) then
            if Assigned((inSwaggerType.Schema.JsonSchema.Values['items'] as TJSONObject).Values['$ref']) then
              Result := 'array of ' + ConvertRefToType((inSwaggerType.Schema.JsonSchema.Values['items'] as TJSONObject).Values['$ref'].Value);
        end;
      end;
    end;
    stpString: Result := 'String';
    stpNumber: Result := 'Double';
    stpInteger: Result := 'Integer';
    stpBoolean: Result := 'Boolean';
    stpArray:
    begin
      json := inSwaggerType.Schema.JsonSchema;
      if Assigned(json) then
      begin
        OutputDebugString(PChar('TYPE: ' + json.ToJson));
        Result := 'array of ' + inSwaggerType.Schema.JsonSchema.Values['type'].Value;
      end
      else
      begin
        if Assigned(inSwaggerType.Items.Values['type']) then
        begin
          Result := 'array of ' + inSwaggerType.Items.Values['type'].Value;
        end
        else
          Result := 'array of ';
      end;
    end;
    stpFile: Result := 'err File';
  end;
end;

function TSwagDocToDelphiRESTClientBuilder.GenerateUnitText(delphiUnit: TDelphiUnit): string;
var
  i: Integer;
  j: Integer;
  LMethod: TUnitMethod;
  LMvcFile: TStringList;
  filename : string;
begin
  LMvcFile := TStringList.Create;
  try
    LMvcFile.Add(delphiUnit.GenerateInterfaceSectionStart);
    LMvcFile.Add(delphiUnit.GenerateInterfaceUses);
    LMvcFile.Add('(*');
    LMvcFile.Add('Title: ' + fSwagDoc.Info.Title);
    LMvcFile.Add('Description: ' + fSwagDoc.Info.Description);
    LMvcFile.Add('License: ' + fSwagDoc.Info.License.Name);
    LMvcFile.Add('*)');
    LMvcFile.Add('');
    LMvcFile.Add('type');

    SortTypeDefinitions(delphiUnit);

    for i := 0 to delphiUnit.TypeDefinitions.Count - 1 do
    begin
      LMvcFile.Add(delphiUnit.TypeDefinitions[i].GenerateInterface);
    end;
    LMvcFile.Add(delphiUnit.GenerateImplementationSectionStart);
    LMvcFile.Add(delphiUnit.GenerateImplementationUses);
    LMvcFile.Add('');
    for j := 0 to delphiUnit.TypeDefinitions.Count - 1 do
    begin
      for LMethod in delphiUnit.TypeDefinitions[j].GetMethods do
      begin
        LMvcFile.Add(LMethod.GenerateImplementation(delphiUnit.TypeDefinitions[j]));
      end;
    end;
    LMvcFile.Add('end.');
    Result := LMvcFile.Text;
    filename := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\mvccontrollerclient.pas');
    LMvcFile.SaveToFile(filename);
  finally
    FreeAndNil(LMvcFile);
  end;
end;


procedure TSwagDocToDelphiRESTClientBuilder.SortTypeDefinitions(delphiUnit: TDelphiUnit);
begin
  { TODO : Make this much more advanced to handle dependency ordering of declarations }

  delphiUnit.TypeDefinitions.Sort(TComparer<TUnitTypeDefinition>.Construct(function (const L, R: TUnitTypeDefinition): integer
  begin
    if L.TypeName = 'TMyMVCControllerClient' then
      Result := 1
    else if R.TypeName = 'TMyMVCControllerClient' then
      Result := -1
    else
      Result := CompareText(L.TypeName, R.TypeName)
  end));
end;

end.
