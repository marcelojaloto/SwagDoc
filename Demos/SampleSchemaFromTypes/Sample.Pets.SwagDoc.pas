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

unit Sample.Pets.SwagDoc;

interface

uses
  Swag.Common.Types,
  Swag.Doc,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response;

type
  /// <summary>
  /// Builds the document of a small pet store. The schemas of the bodies are generated from the Delphi types of
  /// the unit Sample.Pets.Models by TSwagSchemaBuilder, so no JSON schema is written by hand.
  /// </summary>
  TSamplePetsSwagDoc = class(TObject)
  strict private
    const
      c_PetsTagName = 'Pets';
      c_MimeTypeJson = 'application/json';

    class procedure DocumentInfo(pSwagDoc: TSwagDoc); static;
    class procedure DocumentPets(pSwagDoc: TSwagDoc); static;
    class procedure DocumentPet(pSwagDoc: TSwagDoc); static;
    class function AddResponse(pOperation: TSwagPathOperation; const pStatusCode,
      pDescription: string): TSwagResponse; static;
  public
    /// <summary>
    /// Creates the document of the pet store for the given version of the specification.
    /// The caller owns the returned document.
    /// </summary>
    class function CreateDocument(const pSpecVersion: TSwagVersion): TSwagDoc; static;
  end;

implementation

uses
  Swag.Doc.Tags,
  Swag.Doc.Definition,
  Swag.Doc.Path.Operation.RequestParameter,
  Swag.Doc.Schema.Builder,
  Sample.Pets.Models;

{ TSamplePetsSwagDoc }

class function TSamplePetsSwagDoc.CreateDocument(const pSpecVersion: TSwagVersion): TSwagDoc;
begin
  Result := TSwagDoc.Create;
  try
    Result.SpecVersion := pSpecVersion;
    DocumentInfo(Result);
    DocumentPets(Result);
    DocumentPet(Result);
  except
    Result.Free;
    raise;
  end;
end;

class procedure TSamplePetsSwagDoc.DocumentInfo(pSwagDoc: TSwagDoc);
var
  vTag: TSwagTag;
begin
  pSwagDoc.Info.Title := 'Pet Store';
  pSwagDoc.Info.Version := '1.0.0';
  pSwagDoc.Info.Description := 'The schemas of this document are generated from Delphi classes and records.';
  pSwagDoc.Host := 'localhost:9000';
  pSwagDoc.BasePath := '/';
  pSwagDoc.Schemes := [tpsHttp];
  pSwagDoc.AddServer('http://localhost:9000');

  vTag := TSwagTag.Create;
  vTag.Name := c_PetsTagName;
  vTag.Description := 'Operations about pets';
  pSwagDoc.Tags.Add(vTag);
end;

class function TSamplePetsSwagDoc.AddResponse(pOperation: TSwagPathOperation; const pStatusCode,
  pDescription: string): TSwagResponse;
begin
  Result := TSwagResponse.Create;
  Result.StatusCode := pStatusCode;
  Result.Description := pDescription;
  pOperation.Responses.Add(pStatusCode, Result);
end;

class procedure TSamplePetsSwagDoc.DocumentPets(pSwagDoc: TSwagDoc);
var
  vPath: TSwagPath;
  vOperation: TSwagPathOperation;
  vResponse: TSwagResponse;
begin
  vPath := TSwagPath.Create;
  vPath.Uri := '/pets';
  pSwagDoc.Paths.Add(vPath);

  vOperation := vPath.AddOperation(ohvGet);
  vOperation.OperationId := 'getPets';
  vOperation.Summary := 'Returns a page of the pets of the store';
  vOperation.Tags.Add(c_PetsTagName);

  // A generic class is registered as a schema of its own, named PageOfPet.
  vResponse := AddResponse(vOperation, '200', 'A page of pets');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.Name := TSwagSchemaBuilder.Add<TPage<TPet>>(pSwagDoc).Name;

  vOperation := vPath.AddOperation(ohvPost);
  vOperation.OperationId := 'addPet';
  vOperation.Summary := 'Adds a pet to the store';
  vOperation.Tags.Add(c_PetsTagName);

  // Add<T> registers the record and returns its schema, which is referenced by name.
  vOperation.RequestBody.Description := 'The pet to add to the store';
  vOperation.RequestBody.Required := True;
  vOperation.RequestBody.AddMediaType(c_MimeTypeJson).Schema.Name :=
    TSwagSchemaBuilder.Add<TNewPet>(pSwagDoc).Name;

  vResponse := AddResponse(vOperation, '201', 'The pet added to the store');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.Name := TSwagSchemaBuilder.Add<TPet>(pSwagDoc).Name;

  vResponse := AddResponse(vOperation, '400', 'The pet is not valid');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.Name := TSwagSchemaBuilder.Add<TProblem>(pSwagDoc).Name;
end;

class procedure TSamplePetsSwagDoc.DocumentPet(pSwagDoc: TSwagDoc);
var
  vPath: TSwagPath;
  vOperation: TSwagPathOperation;
  vParameter: TSwagRequestParameter;
  vResponse: TSwagResponse;
begin
  vPath := TSwagPath.Create;
  vPath.Uri := '/pets/{petId}';
  pSwagDoc.Paths.Add(vPath);

  vParameter := TSwagRequestParameter.Create;
  vParameter.Name := 'petId';
  vParameter.InLocation := rpiPath;
  vParameter.Required := True;
  vParameter.Description := 'The pet identifier';
  vParameter.TypeParameter := stpInteger;
  vPath.Parameters.Add(vParameter);

  vOperation := vPath.AddOperation(ohvGet);
  vOperation.OperationId := 'getPet';
  vOperation.Summary := 'Returns a pet of the store';
  vOperation.Tags.Add(c_PetsTagName);

  vResponse := AddResponse(vOperation, '200', 'The pet');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.Name := TSwagSchemaBuilder.Add<TPet>(pSwagDoc).Name;

  // AssignTo<T> also describes types that are not classes or records, here an array written inline.
  vOperation := vPath.AddOperation(ohvPut);
  vOperation.OperationId := 'replacePetPhotos';
  vOperation.Summary := 'Replaces the photos of a pet';
  vOperation.Tags.Add(c_PetsTagName);
  vOperation.RequestBody.Required := True;
  TSwagSchemaBuilder.AssignTo<TArray<TPetPhoto>>(pSwagDoc,
    vOperation.RequestBody.AddMediaType(c_MimeTypeJson).Schema);

  AddResponse(vOperation, '204', 'The photos were replaced');

  vResponse := AddResponse(vOperation, '404', 'The pet does not exist');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.Name := TSwagSchemaBuilder.Add<TProblem>(pSwagDoc).Name;
end;

end.
