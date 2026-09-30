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

unit Sample.Dext.Models;

interface

uses
  Dext.OpenAPI.Attributes,
  Swag.Doc.Schema.Attributes;

type
  TPetStatus = (psAvailable, psPending, psSold);

  /// <summary>
  /// The types of this unit are documented with the Swagger attributes of Dext, as in any Dext application.
  /// A few members also use the attributes of SwagDoc, for the limits that Dext does not describe.
  /// </summary>
  [SwaggerSchema('Pet', 'A pet of the store')]
  TPet = record
    [SwaggerProperty('The pet identifier'), SwaggerExample('1')]
    Id: Integer;

    [SwaggerProperty('The name given by the owner'), SwaggerRequired, SwaggerExample('Rex')]
    Name: string;

    [SwaggerProperty('The availability of the pet in the store')]
    Status: TPetStatus;

    [SwaggerProperty('The day the pet was born')]
    BirthDate: TDate;

    [SwagLength(0, 20), SwaggerExample('dog')]
    Tag: string;
  end;

  [SwaggerSchema('NewPet', 'The data needed to add a pet to the store')]
  TNewPet = record
    [SwaggerRequired, SwagLength(1, 60), SwaggerExample('Rex')]
    Name: string;

    Status: TPetStatus;
    BirthDate: TDate;
  end;

  [SwaggerSchema('Problem', 'The details of an error')]
  TProblem = record
    [SwaggerRequired, SwaggerExample('Pet not found')]
    Title: string;

    [SwaggerRequired, SwaggerExample('404')]
    Status: Integer;
  end;

  /// <summary>
  /// The [SwaggerResponse] attribute of the controllers accepts a class, so the order is a class.
  /// </summary>
  [SwaggerSchema('Order', 'An order of a pet')]
  TOrder = class(TObject)
  private
    fId: Integer;
    fPetId: Integer;
    fQuantity: Integer;
    fShipDate: TDateTime;
    fComplete: Boolean;
  public
    [SwaggerRequired, SwaggerExample('7')]
    property Id: Integer read fId write fId;

    [SwaggerRequired, SwaggerExample('1')]
    property PetId: Integer read fPetId write fPetId;

    [SwagRange(1, 10), SwaggerExample('2')]
    property Quantity: Integer read fQuantity write fQuantity;

    property ShipDate: TDateTime read fShipDate write fShipDate;
    property Complete: Boolean read fComplete write fComplete;
  end;

  [SwaggerSchema('NewOrder', 'The data needed to place an order')]
  TNewOrder = record
    [SwaggerRequired, SwaggerExample('1')]
    PetId: Integer;

    [SwagRange(1, 10), SwaggerExample('2')]
    Quantity: Integer;
  end;

implementation

end.
