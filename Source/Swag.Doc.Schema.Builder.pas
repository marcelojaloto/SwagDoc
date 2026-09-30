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

unit Swag.Doc.Schema.Builder;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.JSON,
  System.Generics.Collections,
  Swag.Doc,
  Swag.Doc.Definition;

type
  ESwagSchemaBuilder = class(Exception);

  /// <summary>
  /// How the values of an enumerated type are written: by name, as strings, or by ordinal value, as integers.
  /// Choose the one used by the JSON serializer of the application.
  /// </summary>
  TSwagSchemaEnumStyle = (sesName, sesOrdinal);

  /// <summary>
  /// How the names of the properties and fields are written when no name is given by an attribute.
  /// Choose the one used by the JSON serializer of the application.
  /// </summary>
  TSwagSchemaNameCase = (sncUnchanged, sncCamelCase, sncPascalCase, sncSnakeCase);

  /// <summary>
  /// What the builder knows about a property or field before writing it into the schema.
  /// A descendant of TSwagSchemaBuilder fills it from its own attributes in ReadMemberInfo.
  /// </summary>
  TSwagSchemaMember = record
    Name: string;
    Description: string;
    Format: string;
    Example: string;
    HasExample: Boolean;
    Required: Boolean;
    Ignored: Boolean;
    Nullable: Boolean;
    MinLength: Integer;
    MaxLength: Integer;
    HasRange: Boolean;
    Minimum: Double;
    Maximum: Double;
  end;

  TSwagSchemaBuilderClass = class of TSwagSchemaBuilder;

  /// <summary>
  /// Generates JSON schemas from Delphi types through RTTI and registers the classes and records as reusable
  /// schemas of a TSwagDoc, under definitions in Swagger 2.0 and under components/schemas in OpenAPI 3.
  /// Classes are described by their public and published properties and records by their public fields.
  /// Nested classes and records become reusable schemas of their own and are written as references.
  /// The attributes of the unit Swag.Doc.Schema.Attributes name, describe, require, ignore and limit the members.
  /// </summary>
  TSwagSchemaBuilder = class(TObject)
  strict private
    fSwagDoc: TSwagDoc;
    fContext: TRttiContext;
    fNames: TDictionary<PTypeInfo, string>;
    fEnumStyle: TSwagSchemaEnumStyle;
    fNameCase: TSwagSchemaNameCase;

    function FindDefinition(const pName: string): TSwagDefinition;
    function RegisterType(pType: TRttiType): string;
    function IsObjectType(pType: TRttiType): Boolean;
    function FindItemsProperty(pType: TRttiType; out pIndexType: TRttiType): TRttiType;
    function FindListElementType(pType: TRttiType): TRttiType;
    function FindDictionaryValueType(pType: TRttiType): TRttiType;
    function BuildSchema(pType: TRttiType; const pNullable: Boolean): TJSONObject;
    function BuildResolvedSchema(pType: TRttiType): TJSONObject;
    function BuildObjectSchema(pType: TRttiType; const pDescription: string): TJSONObject;
    function BuildEnumSchema(pType: TRttiType): TJSONObject;
    function BuildFloatSchema(pType: TRttiType): TJSONObject;
    function GetMembers(pType: TRttiType): TArray<TRttiMember>;
    function GetMemberType(pMember: TRttiMember): TRttiType;
    function CreateNumber(const pValue: Double): TJSONNumber;
    function CreateExampleValue(pSchema: TJSONObject; const pValue: string): TJSONValue;
    procedure ApplyMemberInfo(pSchema: TJSONObject; const pInfo: TSwagSchemaMember);
  strict protected
    /// <summary>
    /// Returns the default name of the reusable schema of a type: the type name without the unit and without the
    /// leading T, with the type arguments of a generic type joined by Of and And, for example PagedOfPet.
    /// </summary>
    function DefaultSchemaName(pType: TRttiType): string; virtual;

    /// <summary>
    /// Reads the name and the description of the reusable schema of a class or a record.
    /// </summary>
    procedure ReadTypeInfo(pType: TRttiType; var pName, pDescription: string); virtual;

    /// <summary>
    /// Reads what the attributes of a property or field say about it. pInfo arrives with the name converted by
    /// NameCase and without limits.
    /// </summary>
    procedure ReadMemberInfo(pMember: TRttiMember; var pInfo: TSwagSchemaMember); virtual;

    /// <summary>
    /// Returns the type that is really serialized for pType. A wrapper type, such as a nullable record, returns
    /// the type it wraps and sets pNullable. The default implementation returns pType.
    /// </summary>
    function ResolveType(pType: TRttiType; var pNullable: Boolean): TRttiType; virtual;

    /// <summary>
    /// Converts the name of a member according to NameCase.
    /// </summary>
    function ApplyNameCase(const pName: string): string; virtual;

    property Context: TRttiContext read fContext;
  public
    constructor Create(pSwagDoc: TSwagDoc); virtual;
    destructor Destroy; override;

    /// <summary>
    /// Registers a class or a record, and the classes and records it uses, as reusable schemas of the document.
    /// A schema already registered under the same name is kept, so a schema written by hand takes precedence.
    /// Raises ESwagSchemaBuilder when the type is not a class or a record.
    /// </summary>
    function AddType(pTypeInfo: PTypeInfo): TSwagDefinition;

    /// <summary>
    /// Makes pTarget describe the type: a class or a record is registered and referenced by name, and any other
    /// type, such as an array or a simple type, is written inline.
    /// </summary>
    procedure AssignType(pTypeInfo: PTypeInfo; pTarget: TSwagDefinition);

    /// <summary>
    /// Generates the JSON schema of the type. Classes and records are registered and returned as references.
    /// The caller owns the returned object.
    /// </summary>
    function GenerateSchema(pTypeInfo: PTypeInfo): TJSONObject;

    /// <summary>
    /// Registers the class or record T as a reusable schema of pSwagDoc and returns it.
    /// Use the Name of the result to reference it from a response, a request body or a parameter.
    /// </summary>
    class function Add<T>(pSwagDoc: TSwagDoc): TSwagDefinition;

    /// <summary>
    /// Makes pTarget describe the type T, for example TArray&lt;TPet&gt; for a response that returns a list.
    /// </summary>
    class procedure AssignTo<T>(pSwagDoc: TSwagDoc; pTarget: TSwagDefinition);

    /// <summary>
    /// The document that receives the reusable schemas.
    /// </summary>
    property SwagDoc: TSwagDoc read fSwagDoc;

    /// <summary>
    /// How the values of enumerated types are written. The default is sesName.
    /// </summary>
    property EnumStyle: TSwagSchemaEnumStyle read fEnumStyle write fEnumStyle;

    /// <summary>
    /// How the names of members without a name given by an attribute are written. The default is sncUnchanged.
    /// </summary>
    property NameCase: TSwagSchemaNameCase read fNameCase write fNameCase;
  end;

implementation

uses
  System.Classes,
  System.Character,
  Swag.Doc.Schema.Attributes;

const
  c_SchemaRefPrefix = '#/components/schemas/';
  c_SchemaRef = '$ref';
  c_SchemaType = 'type';
  c_SchemaFormat = 'format';
  c_SchemaDescription = 'description';
  c_SchemaProperties = 'properties';
  c_SchemaAdditionalProperties = 'additionalProperties';
  c_SchemaRequired = 'required';
  c_SchemaItems = 'items';
  c_SchemaEnum = 'enum';
  c_SchemaNullable = 'nullable';
  c_SchemaExamples = 'examples';
  c_SchemaMinLength = 'minLength';
  c_SchemaMaxLength = 'maxLength';
  c_SchemaMinimum = 'minimum';
  c_SchemaMaximum = 'maximum';
  c_SchemaMinItems = 'minItems';
  c_SchemaMaxItems = 'maxItems';
  c_SchemaUniqueItems = 'uniqueItems';
  c_TypeObject = 'object';
  c_TypeArray = 'array';
  c_TypeString = 'string';
  c_TypeInteger = 'integer';
  c_TypeNumber = 'number';
  c_TypeBoolean = 'boolean';
  c_FormatInt32 = 'int32';
  c_FormatInt64 = 'int64';
  c_FormatFloat = 'float';
  c_FormatDouble = 'double';
  c_FormatDateTime = 'date-time';
  c_FormatDate = 'date';
  c_FormatTime = 'time';
  c_FormatUuid = 'uuid';
  c_ErrorNotObjectType = 'The type %s is not a class or a record. Use AssignType to describe it inline.';
  c_ErrorNoTypeInfo = 'The type has no RTTI information.';

var
  fInvariantFormat: TFormatSettings;

{ TSwagSchemaBuilder }

constructor TSwagSchemaBuilder.Create(pSwagDoc: TSwagDoc);
begin
  inherited Create;
  fSwagDoc := pSwagDoc;
  fContext := TRttiContext.Create;
  fNames := TDictionary<PTypeInfo, string>.Create;
  fEnumStyle := sesName;
  fNameCase := sncUnchanged;
end;

destructor TSwagSchemaBuilder.Destroy;
begin
  FreeAndNil(fNames);
  fContext.Free;
  inherited Destroy;
end;

class function TSwagSchemaBuilder.Add<T>(pSwagDoc: TSwagDoc): TSwagDefinition;
var
  vBuilder: TSwagSchemaBuilder;
begin
  vBuilder := TSwagSchemaBuilderClass(Self).Create(pSwagDoc);
  try
    Result := vBuilder.AddType(TypeInfo(T));
  finally
    vBuilder.Free;
  end;
end;

class procedure TSwagSchemaBuilder.AssignTo<T>(pSwagDoc: TSwagDoc; pTarget: TSwagDefinition);
var
  vBuilder: TSwagSchemaBuilder;
begin
  vBuilder := TSwagSchemaBuilderClass(Self).Create(pSwagDoc);
  try
    vBuilder.AssignType(TypeInfo(T), pTarget);
  finally
    vBuilder.Free;
  end;
end;

function TSwagSchemaBuilder.AddType(pTypeInfo: PTypeInfo): TSwagDefinition;
var
  vType: TRttiType;
  vNullable: Boolean;
begin
  if not Assigned(pTypeInfo) then
    raise ESwagSchemaBuilder.Create(c_ErrorNoTypeInfo);

  vNullable := False;
  vType := ResolveType(fContext.GetType(pTypeInfo), vNullable);
  if not IsObjectType(vType) then
    raise ESwagSchemaBuilder.CreateFmt(c_ErrorNotObjectType, [vType.Name]);

  Result := FindDefinition(RegisterType(vType));
end;

procedure TSwagSchemaBuilder.AssignType(pTypeInfo: PTypeInfo; pTarget: TSwagDefinition);
var
  vType: TRttiType;
  vNullable: Boolean;
  vOldSchema: TJSONObject;
begin
  if not Assigned(pTypeInfo) then
    raise ESwagSchemaBuilder.Create(c_ErrorNoTypeInfo);

  vNullable := False;
  vType := ResolveType(fContext.GetType(pTypeInfo), vNullable);
  if IsObjectType(vType) and not vNullable then
  begin
    pTarget.Name := RegisterType(vType);
    Exit;
  end;

  vOldSchema := pTarget.JsonSchema;
  pTarget.JsonSchema := BuildSchema(vType, vNullable);
  vOldSchema.Free;
end;

function TSwagSchemaBuilder.GenerateSchema(pTypeInfo: PTypeInfo): TJSONObject;
begin
  if not Assigned(pTypeInfo) then
    raise ESwagSchemaBuilder.Create(c_ErrorNoTypeInfo);
  Result := BuildSchema(fContext.GetType(pTypeInfo), False);
end;

function TSwagSchemaBuilder.FindDefinition(const pName: string): TSwagDefinition;
var
  vIndex: Integer;
begin
  Result := nil;
  for vIndex := 0 to fSwagDoc.Definitions.Count - 1 do
    if fSwagDoc.Definitions.Items[vIndex].Name = pName then
      Exit(fSwagDoc.Definitions.Items[vIndex]);
end;

function TSwagSchemaBuilder.RegisterType(pType: TRttiType): string;
var
  vDescription: string;
  vDefinition: TSwagDefinition;
begin
  if fNames.TryGetValue(pType.Handle, Result) then
    Exit;

  Result := DefaultSchemaName(pType);
  vDescription := EmptyStr;
  ReadTypeInfo(pType, Result, vDescription);
  fNames.Add(pType.Handle, Result);

  if Assigned(FindDefinition(Result)) then
    Exit;

  vDefinition := TSwagDefinition.Create;
  vDefinition.Name := Result;
  fSwagDoc.Definitions.Add(vDefinition);
  vDefinition.JsonSchema := BuildObjectSchema(pType, vDescription);
end;

function TSwagSchemaBuilder.IsObjectType(pType: TRttiType): Boolean;
begin
  Result := False;
  if not Assigned(pType) then
    Exit;

  if pType.IsRecord then
    Exit(pType.Handle <> TypeInfo(TGUID));

  if pType.TypeKind = tkClass then
    Result := (not TRttiInstanceType(pType).MetaclassType.InheritsFrom(TStrings)) and
      (not Assigned(FindListElementType(pType))) and (not Assigned(FindDictionaryValueType(pType)));
end;

function TSwagSchemaBuilder.FindItemsProperty(pType: TRttiType; out pIndexType: TRttiType): TRttiType;
var
  vItems: TRttiIndexedProperty;
  vParameters: TArray<TRttiParameter>;
begin
  Result := nil;
  pIndexType := nil;
  if pType.TypeKind <> tkClass then
    Exit;

  vItems := pType.GetIndexedProperty('Items');
  if not Assigned(vItems) or not Assigned(vItems.ReadMethod) then
    Exit;

  vParameters := vItems.ReadMethod.GetParameters;
  if Length(vParameters) <> 1 then
    Exit;

  pIndexType := vParameters[0].ParamType;
  Result := vItems.PropertyType;
end;

function TSwagSchemaBuilder.FindListElementType(pType: TRttiType): TRttiType;
var
  vMethod: TRttiMethod;
  vIndexType: TRttiType;
begin
  Result := nil;
  if (pType.TypeKind <> tkClass) or Assigned(FindDictionaryValueType(pType)) then
    Exit;

  vMethod := pType.GetMethod('ToArray');
  if Assigned(vMethod) and (Length(vMethod.GetParameters) = 0) and (vMethod.ReturnType is TRttiDynamicArrayType) then
    Exit(TRttiDynamicArrayType(vMethod.ReturnType).ElementType);

  Result := FindItemsProperty(pType, vIndexType);
  if Assigned(Result) and not (Assigned(vIndexType) and (vIndexType.TypeKind = tkInteger)) then
    Result := nil;
end;

function TSwagSchemaBuilder.FindDictionaryValueType(pType: TRttiType): TRttiType;
var
  vMethod: TRttiMethod;
  vParameters: TArray<TRttiParameter>;
  vIndexType: TRttiType;
begin
  Result := nil;
  if pType.TypeKind <> tkClass then
    Exit;

  vMethod := pType.GetMethod('TryGetValue');
  if Assigned(vMethod) then
  begin
    vParameters := vMethod.GetParameters;
    if (Length(vParameters) = 2) and (pfOut in vParameters[1].Flags) then
      Exit(vParameters[1].ParamType);
  end;

  Result := FindItemsProperty(pType, vIndexType);
  if Assigned(Result) and not (Assigned(vIndexType) and (vIndexType.TypeKind in [tkString, tkLString, tkWString,
    tkUString])) then
    Result := nil;
end;

function TSwagSchemaBuilder.DefaultSchemaName(pType: TRttiType): string;
var
  vName: string;
  vToken: string;
  vIndex: Integer;

  procedure FlushToken;
  var
    vDot: Integer;
  begin
    if vToken.IsEmpty then
      Exit;
    vDot := vToken.LastDelimiter('.');
    if vDot >= 0 then
      vToken := vToken.Substring(vDot + 1);
    if (vToken.Length > 1) and (vToken.Chars[0] = 'T') and vToken.Chars[1].IsUpper then
      vToken := vToken.Substring(1);
    Result := Result + vToken;
    vToken := EmptyStr;
  end;

begin
  Result := EmptyStr;
  vToken := EmptyStr;
  vName := pType.Name;
  for vIndex := 0 to vName.Length - 1 do
    case vName.Chars[vIndex] of
      '<':
        begin
          FlushToken;
          Result := Result + 'Of';
        end;
      ',':
        begin
          FlushToken;
          Result := Result + 'And';
        end;
      '>', ' ':
        FlushToken;
    else
      vToken := vToken + vName.Chars[vIndex];
    end;
  FlushToken;
end;

procedure TSwagSchemaBuilder.ReadTypeInfo(pType: TRttiType; var pName, pDescription: string);
var
  vAttribute: TCustomAttribute;
begin
  for vAttribute in pType.GetAttributes do
    if vAttribute is SwagSchemaAttribute then
    begin
      if not SwagSchemaAttribute(vAttribute).Name.IsEmpty then
        pName := SwagSchemaAttribute(vAttribute).Name;
      if not SwagSchemaAttribute(vAttribute).Description.IsEmpty then
        pDescription := SwagSchemaAttribute(vAttribute).Description;
    end;
end;

procedure TSwagSchemaBuilder.ReadMemberInfo(pMember: TRttiMember; var pInfo: TSwagSchemaMember);
var
  vAttribute: TCustomAttribute;
begin
  for vAttribute in pMember.GetAttributes do
    if vAttribute is SwagPropertyAttribute then
    begin
      if not SwagPropertyAttribute(vAttribute).Name.IsEmpty then
        pInfo.Name := SwagPropertyAttribute(vAttribute).Name;
      if not SwagPropertyAttribute(vAttribute).Description.IsEmpty then
        pInfo.Description := SwagPropertyAttribute(vAttribute).Description;
    end
    else if vAttribute is SwagRequiredAttribute then
      pInfo.Required := True
    else if vAttribute is SwagIgnoreAttribute then
      pInfo.Ignored := True
    else if vAttribute is SwagFormatAttribute then
      pInfo.Format := SwagFormatAttribute(vAttribute).Format
    else if vAttribute is SwagExampleAttribute then
    begin
      pInfo.Example := SwagExampleAttribute(vAttribute).Value;
      pInfo.HasExample := True;
    end
    else if vAttribute is SwagLengthAttribute then
    begin
      pInfo.MinLength := SwagLengthAttribute(vAttribute).MinLength;
      pInfo.MaxLength := SwagLengthAttribute(vAttribute).MaxLength;
    end
    else if vAttribute is SwagRangeAttribute then
    begin
      pInfo.HasRange := True;
      pInfo.Minimum := SwagRangeAttribute(vAttribute).Minimum;
      pInfo.Maximum := SwagRangeAttribute(vAttribute).Maximum;
    end;
end;

function TSwagSchemaBuilder.ResolveType(pType: TRttiType; var pNullable: Boolean): TRttiType;
begin
  Result := pType;
end;

function TSwagSchemaBuilder.ApplyNameCase(const pName: string): string;
var
  vIndex: Integer;
begin
  Result := pName;
  if Result.IsEmpty then
    Exit;

  case fNameCase of
    sncCamelCase:
      Result := Result.Chars[0].ToLower + Result.Substring(1);
    sncPascalCase:
      Result := Result.Chars[0].ToUpper + Result.Substring(1);
    sncSnakeCase:
      begin
        Result := EmptyStr;
        for vIndex := 0 to pName.Length - 1 do
        begin
          if (vIndex > 0) and pName.Chars[vIndex].IsUpper and not pName.Chars[vIndex - 1].IsUpper then
            Result := Result + '_';
          Result := Result + pName.Chars[vIndex].ToLower;
        end;
      end;
  end;
end;

function TSwagSchemaBuilder.BuildSchema(pType: TRttiType; const pNullable: Boolean): TJSONObject;
var
  vType: TRttiType;
  vNullable: Boolean;
begin
  vNullable := pNullable;
  vType := ResolveType(pType, vNullable);
  if IsObjectType(vType) then
  begin
    Result := TJSONObject.Create;
    Result.AddPair(c_SchemaRef, c_SchemaRefPrefix + RegisterType(vType));
  end
  else
    Result := BuildResolvedSchema(vType);

  if vNullable then
    Result.AddPair(c_SchemaNullable, TJSONBool.Create(True));
end;

function TSwagSchemaBuilder.BuildResolvedSchema(pType: TRttiType): TJSONObject;
var
  vElementType: TRttiType;
begin
  Result := TJSONObject.Create;
  if not Assigned(pType) then
    Exit;

  case pType.TypeKind of
    tkInteger:
      begin
        Result.AddPair(c_SchemaType, c_TypeInteger);
        if TRttiOrdinalType(pType).OrdType = otULong then
          Result.AddPair(c_SchemaFormat, c_FormatInt64)
        else
          Result.AddPair(c_SchemaFormat, c_FormatInt32);
      end;
    tkInt64:
      begin
        Result.AddPair(c_SchemaType, c_TypeInteger);
        Result.AddPair(c_SchemaFormat, c_FormatInt64);
      end;
    tkFloat:
      begin
        Result.Free;
        Result := BuildFloatSchema(pType);
      end;
    tkChar, tkWChar:
      begin
        Result.AddPair(c_SchemaType, c_TypeString);
        Result.AddPair(c_SchemaMaxLength, TJSONNumber.Create(1));
      end;
    tkString, tkLString, tkWString, tkUString:
      Result.AddPair(c_SchemaType, c_TypeString);
    tkEnumeration:
      begin
        Result.Free;
        Result := BuildEnumSchema(pType);
      end;
    tkSet:
      begin
        Result.AddPair(c_SchemaType, c_TypeArray);
        Result.AddPair(c_SchemaUniqueItems, TJSONBool.Create(True));
        Result.AddPair(c_SchemaItems, BuildSchema(TRttiSetType(pType).ElementType, False));
      end;
    tkDynArray:
      begin
        Result.AddPair(c_SchemaType, c_TypeArray);
        Result.AddPair(c_SchemaItems, BuildSchema(TRttiDynamicArrayType(pType).ElementType, False));
      end;
    tkArray:
      begin
        Result.AddPair(c_SchemaType, c_TypeArray);
        Result.AddPair(c_SchemaItems, BuildSchema(TRttiArrayType(pType).ElementType, False));
        if TRttiArrayType(pType).DimensionCount = 1 then
        begin
          Result.AddPair(c_SchemaMinItems, TJSONNumber.Create(TRttiArrayType(pType).TotalElementCount));
          Result.AddPair(c_SchemaMaxItems, TJSONNumber.Create(TRttiArrayType(pType).TotalElementCount));
        end;
      end;
    tkRecord:
      if pType.Handle = TypeInfo(TGUID) then
      begin
        Result.AddPair(c_SchemaType, c_TypeString);
        Result.AddPair(c_SchemaFormat, c_FormatUuid);
      end;
    tkClass:
      if TRttiInstanceType(pType).MetaclassType.InheritsFrom(TStrings) then
      begin
        Result.AddPair(c_SchemaType, c_TypeArray);
        Result.AddPair(c_SchemaItems, TJSONObject.Create(TJSONPair.Create(c_SchemaType, c_TypeString)));
      end
      else
      begin
        vElementType := FindDictionaryValueType(pType);
        if Assigned(vElementType) then
        begin
          Result.AddPair(c_SchemaType, c_TypeObject);
          Result.AddPair(c_SchemaAdditionalProperties, BuildSchema(vElementType, False));
        end
        else
        begin
          vElementType := FindListElementType(pType);
          if Assigned(vElementType) then
          begin
            Result.AddPair(c_SchemaType, c_TypeArray);
            Result.AddPair(c_SchemaItems, BuildSchema(vElementType, False));
          end;
        end;
      end;
  end;
end;

function TSwagSchemaBuilder.BuildFloatSchema(pType: TRttiType): TJSONObject;
begin
  Result := TJSONObject.Create;
  if pType.Handle = TypeInfo(TDateTime) then
  begin
    Result.AddPair(c_SchemaType, c_TypeString);
    Result.AddPair(c_SchemaFormat, c_FormatDateTime);
  end
  else if pType.Handle = TypeInfo(TDate) then
  begin
    Result.AddPair(c_SchemaType, c_TypeString);
    Result.AddPair(c_SchemaFormat, c_FormatDate);
  end
  else if pType.Handle = TypeInfo(TTime) then
  begin
    Result.AddPair(c_SchemaType, c_TypeString);
    Result.AddPair(c_SchemaFormat, c_FormatTime);
  end
  else
  begin
    Result.AddPair(c_SchemaType, c_TypeNumber);
    case TRttiFloatType(pType).FloatType of
      ftSingle:
        Result.AddPair(c_SchemaFormat, c_FormatFloat);
      ftDouble, ftExtended:
        Result.AddPair(c_SchemaFormat, c_FormatDouble);
    end;
  end;
end;

function TSwagSchemaBuilder.BuildEnumSchema(pType: TRttiType): TJSONObject;
var
  vValues: TJSONArray;
  vOrdinalType: TRttiOrdinalType;
  vIndex: Integer;
begin
  Result := TJSONObject.Create;
  if pType.Handle = TypeInfo(Boolean) then
  begin
    Result.AddPair(c_SchemaType, c_TypeBoolean);
    Exit;
  end;

  vOrdinalType := TRttiOrdinalType(pType);
  if (vOrdinalType is TRttiEnumerationType) and
    (TRttiEnumerationType(vOrdinalType).UnderlyingType.Handle = TypeInfo(Boolean)) then
  begin
    Result.AddPair(c_SchemaType, c_TypeBoolean);
    Exit;
  end;

  vValues := TJSONArray.Create;
  case fEnumStyle of
    sesOrdinal:
      begin
        Result.AddPair(c_SchemaType, c_TypeInteger);
        for vIndex := vOrdinalType.MinValue to vOrdinalType.MaxValue do
          vValues.Add(vIndex);
      end;
  else
    begin
      Result.AddPair(c_SchemaType, c_TypeString);
      for vIndex := vOrdinalType.MinValue to vOrdinalType.MaxValue do
        vValues.Add(GetEnumName(pType.Handle, vIndex));
    end;
  end;
  Result.AddPair(c_SchemaEnum, vValues);
end;

function TSwagSchemaBuilder.GetMembers(pType: TRttiType): TArray<TRttiMember>;
var
  vMembers: TList<TRttiMember>;
  vHierarchy: TList<TRttiType>;
  vLevel: TRttiType;
  vIndex: Integer;
  vProperty: TRttiProperty;
  vField: TRttiField;
begin
  vMembers := TList<TRttiMember>.Create;
  try
    if pType.IsRecord then
    begin
      for vField in pType.GetFields do
        if vField.Visibility in [mvPublic, mvPublished] then
          vMembers.Add(vField);
    end
    else
    begin
      vHierarchy := TList<TRttiType>.Create;
      try
        vLevel := pType;
        while Assigned(vLevel) and (TRttiInstanceType(vLevel).DeclaringUnitName <> 'System') do
        begin
          vHierarchy.Insert(0, vLevel);
          vLevel := vLevel.BaseType;
        end;

        for vIndex := 0 to vHierarchy.Count - 1 do
          for vProperty in vHierarchy.Items[vIndex].GetDeclaredProperties do
            if (vProperty.Visibility in [mvPublic, mvPublished]) and vProperty.IsReadable then
              vMembers.Add(vProperty);
      finally
        vHierarchy.Free;
      end;
    end;
    Result := vMembers.ToArray;
  finally
    vMembers.Free;
  end;
end;

function TSwagSchemaBuilder.GetMemberType(pMember: TRttiMember): TRttiType;
begin
  Result := nil;
  if pMember is TRttiProperty then
    Result := TRttiProperty(pMember).PropertyType
  else if pMember is TRttiField then
    Result := TRttiField(pMember).FieldType;
end;

function TSwagSchemaBuilder.BuildObjectSchema(pType: TRttiType; const pDescription: string): TJSONObject;
var
  vProperties: TJSONObject;
  vRequired: TJSONArray;
  vMember: TRttiMember;
  vMemberType: TRttiType;
  vInfo: TSwagSchemaMember;
  vSchema: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(c_SchemaType, c_TypeObject);
  if not pDescription.IsEmpty then
    Result.AddPair(c_SchemaDescription, pDescription);

  vProperties := TJSONObject.Create;
  vRequired := TJSONArray.Create;
  try
    for vMember in GetMembers(pType) do
    begin
      vMemberType := GetMemberType(vMember);
      if not Assigned(vMemberType) then
        Continue;

      vInfo := Default(TSwagSchemaMember);
      vInfo.Name := ApplyNameCase(vMember.Name);
      vInfo.MinLength := -1;
      vInfo.MaxLength := -1;
      ReadMemberInfo(vMember, vInfo);
      if vInfo.Ignored or vInfo.Name.IsEmpty or Assigned(vProperties.Values[vInfo.Name]) then
        Continue;

      vSchema := BuildSchema(vMemberType, vInfo.Nullable);
      ApplyMemberInfo(vSchema, vInfo);
      vProperties.AddPair(vInfo.Name, vSchema);
      if vInfo.Required then
        vRequired.Add(vInfo.Name);
    end;

    Result.AddPair(c_SchemaProperties, vProperties);
    vProperties := nil;
    if vRequired.Count > 0 then
    begin
      Result.AddPair(c_SchemaRequired, vRequired);
      vRequired := nil;
    end;
  finally
    vProperties.Free;
    vRequired.Free;
  end;
end;

procedure TSwagSchemaBuilder.ApplyMemberInfo(pSchema: TJSONObject; const pInfo: TSwagSchemaMember);
begin
  if not pInfo.Description.IsEmpty then
    pSchema.AddPair(c_SchemaDescription, pInfo.Description);

  if not pInfo.Format.IsEmpty then
  begin
    pSchema.RemovePair(c_SchemaFormat).Free;
    pSchema.AddPair(c_SchemaFormat, pInfo.Format);
  end;

  if pInfo.MinLength >= 0 then
    pSchema.AddPair(c_SchemaMinLength, TJSONNumber.Create(pInfo.MinLength));
  if pInfo.MaxLength >= 0 then
    pSchema.AddPair(c_SchemaMaxLength, TJSONNumber.Create(pInfo.MaxLength));

  if pInfo.HasRange then
  begin
    pSchema.AddPair(c_SchemaMinimum, CreateNumber(pInfo.Minimum));
    pSchema.AddPair(c_SchemaMaximum, CreateNumber(pInfo.Maximum));
  end;

  if pInfo.HasExample then
    pSchema.AddPair(c_SchemaExamples, TJSONArray.Create(CreateExampleValue(pSchema, pInfo.Example)));
end;

function TSwagSchemaBuilder.CreateNumber(const pValue: Double): TJSONNumber;
const
  c_MaxExactInteger = 9007199254740992.0;
begin
  if (Frac(pValue) = 0) and (Abs(pValue) <= c_MaxExactInteger) then
    Result := TJSONNumber.Create(Trunc(pValue))
  else
    Result := TJSONNumber.Create(pValue);
end;

function TSwagSchemaBuilder.CreateExampleValue(pSchema: TJSONObject; const pValue: string): TJSONValue;
var
  vType: string;
  vInteger: Int64;
  vFloat: Double;
begin
  vType := EmptyStr;
  if pSchema.Values[c_SchemaType] is TJSONString then
    vType := pSchema.Values[c_SchemaType].Value;

  if (vType = c_TypeInteger) and TryStrToInt64(pValue, vInteger) then
    Result := TJSONNumber.Create(vInteger)
  else if (vType = c_TypeNumber) and TryStrToFloat(pValue, vFloat, fInvariantFormat) then
    Result := CreateNumber(vFloat)
  else if (vType = c_TypeBoolean) and (SameText(pValue, 'true') or SameText(pValue, 'false')) then
    Result := TJSONBool.Create(SameText(pValue, 'true'))
  else
    Result := TJSONString.Create(pValue);
end;

initialization
  fInvariantFormat := TFormatSettings.Create('en-US');
  fInvariantFormat.DecimalSeparator := '.';
  fInvariantFormat.ThousandSeparator := ',';

end.
