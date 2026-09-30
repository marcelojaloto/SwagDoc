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

unit Swag.Doc.Schema.Attributes;

interface

type
  /// <summary>
  /// Names and describes the reusable schema generated for a class or a record by TSwagSchemaBuilder.
  /// Without it the schema is named after the type, without the leading T.
  /// </summary>
  SwagSchemaAttribute = class(TCustomAttribute)
  strict private
    fName: string;
    fDescription: string;
  public
    constructor Create(const pName: string); overload;
    constructor Create(const pName, pDescription: string); overload;

    /// <summary>
    /// The key of the schema under definitions (Swagger 2.0) or components/schemas (OpenAPI 3).
    /// </summary>
    property Name: string read fName;

    /// <summary>
    /// The description of the schema.
    /// </summary>
    property Description: string read fDescription;
  end;

  /// <summary>
  /// Changes the name of a property or field in the generated schema and describes it.
  /// An empty name keeps the name given by the member and the naming options of the builder.
  /// </summary>
  SwagPropertyAttribute = class(TCustomAttribute)
  strict private
    fName: string;
    fDescription: string;
  public
    constructor Create(const pName: string); overload;
    constructor Create(const pName, pDescription: string); overload;

    /// <summary>
    /// The name written in the properties of the schema.
    /// </summary>
    property Name: string read fName;

    /// <summary>
    /// The description of the property.
    /// </summary>
    property Description: string read fDescription;
  end;

  /// <summary>
  /// Adds the property or field to the list of required properties of the schema.
  /// </summary>
  SwagRequiredAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Leaves the property or field out of the generated schema.
  /// </summary>
  SwagIgnoreAttribute = class(TCustomAttribute)
  end;

  /// <summary>
  /// Sets the format of the property or field, for example email, uuid, uri or password.
  /// It replaces the format chosen by the builder for the Delphi type.
  /// </summary>
  SwagFormatAttribute = class(TCustomAttribute)
  strict private
    fFormat: string;
  public
    constructor Create(const pFormat: string);

    /// <summary>
    /// The value written in the format keyword.
    /// </summary>
    property Format: string read fFormat;
  end;

  /// <summary>
  /// A sample value of the property or field, shown by the user interfaces in the examples of request and
  /// response bodies. The text is written as a number or a boolean when the schema type is one of them.
  /// It is written in the examples keyword in OpenAPI 3 and in the example keyword in Swagger 2.0.
  /// </summary>
  SwagExampleAttribute = class(TCustomAttribute)
  strict private
    fValue: string;
  public
    constructor Create(const pValue: string);

    /// <summary>
    /// The sample value, as text.
    /// </summary>
    property Value: string read fValue;
  end;

  /// <summary>
  /// Limits the length of a string property or field with the minLength and maxLength keywords.
  /// A negative value leaves that limit out.
  /// </summary>
  SwagLengthAttribute = class(TCustomAttribute)
  strict private
    fMinLength: Integer;
    fMaxLength: Integer;
  public
    constructor Create(const pMinLength, pMaxLength: Integer);

    /// <summary>
    /// The minimum length, or a negative value when there is no minimum.
    /// </summary>
    property MinLength: Integer read fMinLength;

    /// <summary>
    /// The maximum length, or a negative value when there is no maximum.
    /// </summary>
    property MaxLength: Integer read fMaxLength;
  end;

  /// <summary>
  /// Limits the value of a numeric property or field with the minimum and maximum keywords.
  /// </summary>
  SwagRangeAttribute = class(TCustomAttribute)
  strict private
    fMinimum: Double;
    fMaximum: Double;
  public
    constructor Create(const pMinimum, pMaximum: Double);

    /// <summary>
    /// The inclusive minimum value.
    /// </summary>
    property Minimum: Double read fMinimum;

    /// <summary>
    /// The inclusive maximum value.
    /// </summary>
    property Maximum: Double read fMaximum;
  end;

implementation

{ SwagSchemaAttribute }

constructor SwagSchemaAttribute.Create(const pName: string);
begin
  Create(pName, '');
end;

constructor SwagSchemaAttribute.Create(const pName, pDescription: string);
begin
  inherited Create;
  fName := pName;
  fDescription := pDescription;
end;

{ SwagPropertyAttribute }

constructor SwagPropertyAttribute.Create(const pName: string);
begin
  Create(pName, '');
end;

constructor SwagPropertyAttribute.Create(const pName, pDescription: string);
begin
  inherited Create;
  fName := pName;
  fDescription := pDescription;
end;

{ SwagFormatAttribute }

constructor SwagFormatAttribute.Create(const pFormat: string);
begin
  inherited Create;
  fFormat := pFormat;
end;

{ SwagExampleAttribute }

constructor SwagExampleAttribute.Create(const pValue: string);
begin
  inherited Create;
  fValue := pValue;
end;

{ SwagLengthAttribute }

constructor SwagLengthAttribute.Create(const pMinLength, pMaxLength: Integer);
begin
  inherited Create;
  fMinLength := pMinLength;
  fMaxLength := pMaxLength;
end;

{ SwagRangeAttribute }

constructor SwagRangeAttribute.Create(const pMinimum, pMaximum: Double);
begin
  inherited Create;
  fMinimum := pMinimum;
  fMaximum := pMaximum;
end;

end.
