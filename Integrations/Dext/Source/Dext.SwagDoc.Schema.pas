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

unit Dext.SwagDoc.Schema;

interface

uses
  System.Rtti,
  Swag.Doc,
  Swag.Doc.Schema.Builder,
  Dext.Json.Types;

type
  /// <summary>
  /// Generates the schemas of the types used by Dext endpoints as the JSON serializer of Dext writes them:
  /// * the names follow the CaseStyle and the enumerations follow the EnumStyle of the default settings of
  ///   TDextJson, and dates are written as ISO 8601 date and time strings;
  /// * JsonName renames a member and JsonIgnore or NotMapped leaves it out;
  /// * the Swagger attributes of Dext (SwaggerSchema, SwaggerProperty, SwaggerRequired, SwaggerFormat,
  ///   SwaggerExample and SwaggerIgnoreProperty) are honored, so the existing types need no change;
  /// * Prop&lt;T&gt; is written as T and Nullable&lt;T&gt; as a T that also accepts null.
  /// The attributes of the unit Swag.Doc.Schema.Attributes are also honored and take precedence.
  /// </summary>
  TDextSwagSchemaBuilder = class(TSwagSchemaBuilder)
  strict private
    fCaseStyle: TCaseStyle;
    fIsoDates: Boolean;
    procedure ReadDextMemberInfo(pMember: TRttiMember; var pInfo: TSwagSchemaMember);
    function IsDateType(pMember: TRttiMember): Boolean;
  strict protected
    procedure ReadTypeInfo(pType: TRttiType; var pName, pDescription: string); override;
    procedure ReadMemberInfo(pMember: TRttiMember; var pInfo: TSwagSchemaMember); override;
    function ResolveType(pType: TRttiType; var pNullable: Boolean): TRttiType; override;
    function ApplyNameCase(const pName: string): string; override;
  public
    constructor Create(pSwagDoc: TSwagDoc); override;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Json,
  Dext.OpenAPI.Attributes;

const
  c_PropTypeName = 'Prop<';
  c_NullableTypeName = 'Nullable<';
  c_ValueMemberName = 'Value';
  c_ValueFieldName = 'FValue';
  c_NotMappedAttributeName = 'NotMappedAttribute';
  c_FormatDateTime = 'date-time';

{ TDextSwagSchemaBuilder }

constructor TDextSwagSchemaBuilder.Create(pSwagDoc: TSwagDoc);
var
  vSettings: TJsonSettings;
begin
  inherited Create(pSwagDoc);
  vSettings := TDextJson.GetDefaultSettings;
  fCaseStyle := vSettings.CaseStyle;
  fIsoDates := vSettings.DateFormatStyle = TDateFormat.ISO8601;
  if vSettings.EnumStyle = TEnumStyle.AsString then
    EnumStyle := sesName
  else
    EnumStyle := sesOrdinal;
end;

function TDextSwagSchemaBuilder.ApplyNameCase(const pName: string): string;
begin
  Result := TJsonUtils.ApplyCaseStyle(pName, fCaseStyle);
end;

procedure TDextSwagSchemaBuilder.ReadTypeInfo(pType: TRttiType; var pName, pDescription: string);
var
  vAttribute: TCustomAttribute;
begin
  for vAttribute in pType.GetAttributes do
    if vAttribute is SwaggerSchemaAttribute then
    begin
      if not SwaggerSchemaAttribute(vAttribute).Title.IsEmpty then
        pName := SwaggerSchemaAttribute(vAttribute).Title;
      if not SwaggerSchemaAttribute(vAttribute).Description.IsEmpty then
        pDescription := SwaggerSchemaAttribute(vAttribute).Description;
    end;

  inherited ReadTypeInfo(pType, pName, pDescription);
end;

procedure TDextSwagSchemaBuilder.ReadMemberInfo(pMember: TRttiMember; var pInfo: TSwagSchemaMember);
begin
  ReadDextMemberInfo(pMember, pInfo);
  inherited ReadMemberInfo(pMember, pInfo);
end;

function TDextSwagSchemaBuilder.IsDateType(pMember: TRttiMember): Boolean;
var
  vType: TRttiType;
begin
  vType := nil;
  if pMember is TRttiProperty then
    vType := TRttiProperty(pMember).PropertyType
  else if pMember is TRttiField then
    vType := TRttiField(pMember).FieldType;

  Result := Assigned(vType) and ((vType.Handle = TypeInfo(TDate)) or (vType.Handle = TypeInfo(TTime)));
end;

procedure TDextSwagSchemaBuilder.ReadDextMemberInfo(pMember: TRttiMember; var pInfo: TSwagSchemaMember);
var
  vAttribute: TCustomAttribute;
begin
  // The serializer of Dext writes TDate and TTime with the full ISO 8601 date and time format.
  if fIsoDates and IsDateType(pMember) then
    pInfo.Format := c_FormatDateTime;

  for vAttribute in pMember.GetAttributes do
    if vAttribute is JsonNameAttribute then
      pInfo.Name := JsonNameAttribute(vAttribute).Name
    else if (vAttribute is JsonIgnoreAttribute) or (vAttribute is SwaggerIgnorePropertyAttribute) or
      (vAttribute.ClassName = c_NotMappedAttributeName) then
      pInfo.Ignored := True
    else if vAttribute is SwaggerPropertyAttribute then
    begin
      if not SwaggerPropertyAttribute(vAttribute).Name.IsEmpty then
        pInfo.Name := SwaggerPropertyAttribute(vAttribute).Name;
      if not SwaggerPropertyAttribute(vAttribute).Description.IsEmpty then
        pInfo.Description := SwaggerPropertyAttribute(vAttribute).Description;
      if not SwaggerPropertyAttribute(vAttribute).Format.IsEmpty then
        pInfo.Format := SwaggerPropertyAttribute(vAttribute).Format;
      if not SwaggerPropertyAttribute(vAttribute).Example.IsEmpty then
      begin
        pInfo.Example := SwaggerPropertyAttribute(vAttribute).Example;
        pInfo.HasExample := True;
      end;
      if SwaggerPropertyAttribute(vAttribute).Required then
        pInfo.Required := True;
    end
    else if vAttribute is SwaggerRequiredAttribute then
      pInfo.Required := True
    else if vAttribute is SwaggerFormatAttribute then
      pInfo.Format := SwaggerFormatAttribute(vAttribute).Format
    else if vAttribute is SwaggerExampleAttribute then
    begin
      pInfo.Example := SwaggerExampleAttribute(vAttribute).Value;
      pInfo.HasExample := True;
    end;
end;

function TDextSwagSchemaBuilder.ResolveType(pType: TRttiType; var pNullable: Boolean): TRttiType;
var
  vName: string;
  vProperty: TRttiProperty;
  vField: TRttiField;
begin
  Result := inherited ResolveType(pType, pNullable);
  if not Assigned(Result) or not Result.IsRecord then
    Exit;

  vName := Result.Name;
  if not (vName.StartsWith(c_PropTypeName) or vName.StartsWith(c_NullableTypeName)) then
    Exit;

  if vName.StartsWith(c_NullableTypeName) then
    pNullable := True;

  vProperty := Result.GetProperty(c_ValueMemberName);
  if Assigned(vProperty) then
    Exit(vProperty.PropertyType);

  vField := Result.GetField(c_ValueFieldName);
  if Assigned(vField) then
    Result := vField.FieldType;
end;

end.
