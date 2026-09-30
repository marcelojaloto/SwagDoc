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

unit Sample.Pets.Models;

interface

uses
  System.Generics.Collections,
  Swag.Doc.Schema.Attributes;

type
  /// <summary>
  /// An enumerated type is written with its names, or with its ordinal values when the builder is told so.
  /// </summary>
  TPetStatus = (psAvailable, psPending, psSold);

  /// <summary>
  /// A record is described by its public fields.
  /// </summary>
  TPetPhoto = record
    [SwagFormat('uri'), SwagExample('https://example.com/photos/rex.png')]
    Url: string;
    Caption: string;
  end;

  /// <summary>
  /// A class without attributes becomes a schema named after the type, without the leading T.
  /// </summary>
  TCategory = class(TObject)
  private
    fId: Int64;
    fName: string;
  public
    property Id: Int64 read fId write fId;
    property Name: string read fName write fName;
  end;

  /// <summary>
  /// A class is described by its public and published properties. The nested class, the array of records and
  /// the list become references to their own schemas.
  /// </summary>
  [SwagSchema('Pet', 'A pet of the store')]
  TPet = class(TObject)
  private
    fId: Int64;
    fName: string;
    fCategory: TCategory;
    fTags: TArray<string>;
    fStatus: TPetStatus;
    fBirthDate: TDate;
    fWeight: Double;
    fPhotos: TArray<TPetPhoto>;
    fInternalCode: string;
  public
    [SwagRequired, SwagProperty('id', 'The pet identifier'), SwagExample('10')]
    property Id: Int64 read fId write fId;

    [SwagRequired, SwagProperty('name', 'The name given by the owner'), SwagLength(1, 60), SwagExample('Rex')]
    property Name: string read fName write fName;

    [SwagProperty('category')]
    property Category: TCategory read fCategory write fCategory;

    [SwagProperty('tags')]
    property Tags: TArray<string> read fTags write fTags;

    [SwagProperty('status', 'The availability of the pet in the store')]
    property Status: TPetStatus read fStatus write fStatus;

    [SwagProperty('birthDate')]
    property BirthDate: TDate read fBirthDate write fBirthDate;

    [SwagProperty('weight', 'The weight in kilograms'), SwagRange(0, 150), SwagExample('12.5')]
    property Weight: Double read fWeight write fWeight;

    [SwagProperty('photos')]
    property Photos: TArray<TPetPhoto> read fPhotos write fPhotos;

    [SwagIgnore]
    property InternalCode: string read fInternalCode write fInternalCode;
  end;

  /// <summary>
  /// The body of the request that adds a pet.
  /// </summary>
  [SwagSchema('NewPet', 'The data needed to add a pet to the store')]
  TNewPet = record
    [SwagRequired, SwagProperty('name'), SwagLength(1, 60), SwagExample('Rex')]
    Name: string;

    [SwagProperty('categoryId'), SwagExample('1')]
    CategoryId: Int64;

    [SwagProperty('status')]
    Status: TPetStatus;
  end;

  /// <summary>
  /// A generic class gets a schema per type argument, named after both, for example PageOfPet.
  /// </summary>
  TPage<T: class> = class(TObject)
  private
    fItems: TObjectList<T>;
    fTotal: Integer;
  public
    [SwagProperty('items')]
    property Items: TObjectList<T> read fItems write fItems;

    [SwagProperty('total', 'The number of items of all pages'), SwagExample('42')]
    property Total: Integer read fTotal write fTotal;
  end;

  /// <summary>
  /// The body of the error responses.
  /// </summary>
  [SwagSchema('Problem', 'The details of an error')]
  TProblem = record
    [SwagRequired, SwagProperty('title'), SwagExample('Pet not found')]
    Title: string;

    [SwagRequired, SwagProperty('status'), SwagExample('404')]
    Status: Integer;
  end;

implementation

end.
