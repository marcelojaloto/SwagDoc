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

unit Swag.Doc.Path.Operation.RequestParameter;

interface

uses
  System.JSON,
  Swag.Common.Types,
  Swag.Doc.Definition,
  JSON.Commom.Helpers;
type
  /// <summary>
  /// Describes a single operation parameter.
  /// A unique parameter is defined by a combination of a name and location.
  /// </summary>
  TSwagRequestParameter = class(TObject)
  private
    fName: string;
    fInLocation: TSwagRequestParameterInLocation;
    fRequired: Boolean;
    fSchema: TSwagDefinition;
    fDescription: string;
    fTypeParameter: string;
    fPattern: string;
  protected
    function ReturnInLocationToString: string;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    function GenerateJsonObject: TJSONObject;
    procedure Load(pJson: TJSONObject);

    /// <summary>
    /// There are five possible parameter types: Query, Header, Path, Form e Body.
    /// </summary>
    property InLocation: TSwagRequestParameterInLocation read fInLocation write fInLocation;

    /// <summary>
    /// Required. The name of the parameter. Parameter names are case sensitive.
    /// If in is "path", the name field MUST correspond to the associated path segment from the path field in the Paths Object.
    /// See Path Templating for further information.
    /// For all other cases, the name corresponds to the parameter name used based on the in property.
    /// </summary>
    property Name: string read fName write fName;

    /// <summary>
    /// A brief description of the parameter. This could contain examples of use. GFM syntax can be used for rich text representation.
    /// </summary>
    property Description: string read fDescription write fDescription;

    /// <summary>
    /// Determines whether this parameter is mandatory. If the parameter is in "path", this property is required and its value MUST be true.
    /// Otherwise, the property MAY be included and its default value is false.
    /// </summary>
    property Required: Boolean read fRequired write fRequired;

    /// <summary>
    /// See https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-5.2.3.
    /// </summary>
    property Pattern: string read fPattern write fPattern;

    /// <summary>
    /// If in is "body"
    /// Required. The schema defining the type used for the body parameter.
    /// </summary>
    property Schema: TSwagDefinition read fSchema;

    /// <summary>
    /// If in is any value other than "body"
    /// Required. The type of the parameter. Since the parameter is not located at the request body, it is limited to
    /// simple types (that is, not an object).
    /// The value MUST be one of "string", "number", "integer", "boolean", "array" or "file".
    /// If type is "file", the consumes MUST be either "multipart/form-data", " application/x-www-form-urlencoded" or both
    /// and the parameter MUST be in "formData".
    /// </summary>
    property TypeParameter: string read fTypeParameter write fTypeParameter;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Swag.Common.Consts,
  Swag.Common.Types.Helpers;

const
  c_SwagRequestParameterIn = 'in';
  c_SwagRequestParameterName = 'name';
  c_SwagRequestParameterDescription = 'description';
  c_SwagRequestParameterRequired = 'required';
  c_SwagRequestParameterSchema = 'schema';
  c_SwagRequestParameterType = 'type';

{ TSwagRequestParameter }

constructor TSwagRequestParameter.Create;
begin
  inherited Create;
  fSchema := TSwagDefinition.Create;
end;

destructor TSwagRequestParameter.Destroy;
begin
  FreeAndNil(fSchema);
  inherited Destroy;
end;

function TSwagRequestParameter.GenerateJsonObject: TJSONObject;
var
  vJsonObject: TJsonObject;
begin
  vJsonObject := TJsonObject.Create;
  vJsonObject.AddPair(c_SwagRequestParameterIn, ReturnInLocationToString);
  vJsonObject.AddPair(c_SwagRequestParameterName, fName);
  if not fDescription.IsEmpty then
    vJsonObject.AddPair(c_SwagRequestParameterDescription, fDescription);
  if not fPattern.IsEmpty then
    vJsonObject.AddPair('pattern', fPattern);

  vJsonObject.AddPair(c_SwagRequestParameterRequired, TJSONBool.Create(fRequired));

  if (not fSchema.Name.IsEmpty) then
    vJsonObject.AddPair(c_SwagRequestParameterSchema, fSchema.GenerateJsonRefDefinition)
  else if Assigned(fSchema.JsonSchema) then
    vJsonObject.AddPair(c_SwagRequestParameterSchema, fSchema.JsonSchema)
  else if not fTypeParameter.IsEmpty then
    vJsonObject.AddPair(c_SwagRequestParameterType, fTypeParameter);

  Result := vJsonObject;
end;

procedure TSwagRequestParameter.Load(pJson: TJSONObject);
begin
  if Assigned(pJson.Values[c_SwagRequestParameterRequired]) then
    fRequired := (pJson.Values[c_SwagRequestParameterRequired] as TJSONBool).AsBoolean
  else
    fRequired := False;

  if Assigned(pJson.Values['pattern']) then
    fPattern := pJson.Values['pattern'].Value;

  if Assigned(pJson.Values[c_SwagRequestParameterName]) then
    fName := pJson.Values[c_SwagRequestParameterName].Value;

  if Assigned(pJson.Values['in']) then
    fInLocation.ToType(pJson.Values['in'].Value);

  fTypeParameter := pJson.GetValueRelaxed<String>(c_SwagRequestParameterType);
end;

function TSwagRequestParameter.ReturnInLocationToString: string;
begin
  Result := c_SwagRequestParameterInLocation[fInLocation];
end;

end.
