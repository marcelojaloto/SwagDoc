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

unit Sample.Api.Pets;

interface

uses
  System.JSON,
  Horse,
  Swag.Doc,
  Swag.Doc.Path,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response;

type
  /// <summary>
  /// The pet operations of the sample API. The routes are registered in Horse with the syntax of the framework
  /// and documented with the same route, which is translated to the path of the specification.
  /// </summary>
  TSamplePetsApi = class(TObject)
  strict private
    const
      c_PetsRoute = '/pets';
      c_PetRoute = '/pets/:id';
      c_PetsTagName = 'Pets';
      c_PetSchemaName = 'pet';
      c_MimeTypeJson = 'application/json';

    class procedure DocumentSchemas(pSwagDoc: TSwagDoc); static;
    class procedure DocumentPets(pSwagDoc: TSwagDoc); static;
    class procedure DocumentPet(pSwagDoc: TSwagDoc); static;
    class function AddResponse(pOperation: TSwagPathOperation; const pStatusCode,
      pDescription: string): TSwagResponse; static;
    class function PetListSchema(pSwagDoc: TSwagDoc): TJSONObject; static;

    class procedure GetPets(pRequest: THorseRequest; pResponse: THorseResponse); static;
    class procedure AddPet(pRequest: THorseRequest; pResponse: THorseResponse); static;
    class procedure GetPet(pRequest: THorseRequest; pResponse: THorseResponse); static;
  public
    /// <summary>
    /// Registers the routes of the pet operations in Horse.
    /// </summary>
    class procedure RegisterRoutes; static;

    /// <summary>
    /// Documents the pet operations in the given document.
    /// </summary>
    class procedure DocumentApi(pSwagDoc: TSwagDoc); static;
  end;

implementation

uses
  Json.Schema,
  Horse.SwagDoc,
  Swag.Common.Types,
  Swag.Doc.Definition,
  Swag.Doc.Tags,
  Swag.Doc.Path.Operation.RequestBody;

{ TSamplePetsApi }

class procedure TSamplePetsApi.RegisterRoutes;
begin
  THorse.Get(c_PetsRoute, GetPets);
  THorse.Post(c_PetsRoute, AddPet);
  THorse.Get(c_PetRoute, GetPet);
end;

class procedure TSamplePetsApi.GetPets(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  pResponse.ContentType(c_MimeTypeJson).Send('[{"id":1,"name":"Rex","status":"available"}]');
end;

class procedure TSamplePetsApi.AddPet(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  pResponse.Status(201).ContentType(c_MimeTypeJson).Send('{"id":2,"name":"Bob","status":"available"}');
end;

class procedure TSamplePetsApi.GetPet(pRequest: THorseRequest; pResponse: THorseResponse);
begin
  if pRequest.Params['id'] <> '1' then
  begin
    pResponse.Status(404).ContentType(c_MimeTypeJson).Send('{"title":"Pet not found","status":404}');
    Exit;
  end;

  pResponse.ContentType(c_MimeTypeJson).Send('{"id":1,"name":"Rex","status":"available"}');
end;

class procedure TSamplePetsApi.DocumentApi(pSwagDoc: TSwagDoc);
var
  vTag: TSwagTag;
begin
  vTag := TSwagTag.Create;
  vTag.Name := c_PetsTagName;
  vTag.Description := 'Operations about pets';
  pSwagDoc.Tags.Add(vTag);

  DocumentSchemas(pSwagDoc);
  DocumentPets(pSwagDoc);
  DocumentPet(pSwagDoc);
end;

class procedure TSamplePetsApi.DocumentSchemas(pSwagDoc: TSwagDoc);
var
  vDefinition: TSwagDefinition;
  vSchema: TJsonSchema;
begin
  vSchema := TJsonSchema.Create;
  try
    vSchema.Root.Description := 'A pet of the store';
    vSchema.AddField<Int64>('id', 'The pet identifier.');
    vSchema.AddField<string>('name', 'The pet name.');
    vSchema.AddField<string>('status', 'The availability of the pet in the store.');

    vDefinition := TSwagDefinition.Create;
    vDefinition.Name := c_PetSchemaName;
    vDefinition.JsonSchema := vSchema.ToJson;
    pSwagDoc.Definitions.Add(vDefinition);
  finally
    vSchema.Free;
  end;
end;

class function TSamplePetsApi.AddResponse(pOperation: TSwagPathOperation; const pStatusCode,
  pDescription: string): TSwagResponse;
begin
  Result := TSwagResponse.Create;
  Result.StatusCode := pStatusCode;
  Result.Description := pDescription;
  pOperation.Responses.Add(pStatusCode, Result);
end;

class function TSamplePetsApi.PetListSchema(pSwagDoc: TSwagDoc): TJSONObject;
const
  c_OpenApi3SchemaRef = '#/components/schemas/';
  c_Swagger2SchemaRef = '#/definitions/';
var
  vRef: string;
begin
  // The schemas of a Swagger 2.0 document are written under definitions and the ones of an OpenAPI 3 document
  // under components, so a schema written by hand needs the reference of the version of the document.
  if pSwagDoc.SpecVersion = svOpenApi3 then
    vRef := c_OpenApi3SchemaRef + c_PetSchemaName
  else
    vRef := c_Swagger2SchemaRef + c_PetSchemaName;

  Result := TJSONObject.ParseJSONValue('{"type":"array","items":{"$ref":"' + vRef + '"}}') as TJSONObject;
end;

class procedure TSamplePetsApi.DocumentPets(pSwagDoc: TSwagDoc);
var
  vPath: TSwagPath;
  vOperation: TSwagPathOperation;
  vResponse: TSwagResponse;
  vRequestBody: TSwagRequestBody;
begin
  vPath := pSwagDoc.Route(c_PetsRoute);

  vOperation := vPath.AddOperation(ohvGet);
  vOperation.OperationId := 'getPets';
  vOperation.Summary := 'Returns the pets of the store';
  vOperation.Tags.Add(c_PetsTagName);

  vResponse := AddResponse(vOperation, '200', 'The pets of the store');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.JsonSchema := PetListSchema(pSwagDoc);

  vOperation := vPath.AddOperation(ohvPost);
  vOperation.OperationId := 'addPet';
  vOperation.Summary := 'Adds a pet to the store';
  vOperation.Tags.Add(c_PetsTagName);

  vRequestBody := vOperation.RequestBody;
  vRequestBody.Description := 'The pet to add to the store';
  vRequestBody.Required := True;
  vRequestBody.AddMediaType(c_MimeTypeJson).Schema.Name := c_PetSchemaName;

  vResponse := AddResponse(vOperation, '201', 'The pet added to the store');
  vResponse.AddMediaType(c_MimeTypeJson).Schema.Name := c_PetSchemaName;
end;

class procedure TSamplePetsApi.DocumentPet(pSwagDoc: TSwagDoc);
var
  vPath: TSwagPath;
  vOperation: TSwagPathOperation;
begin
  vPath := pSwagDoc.Route(c_PetRoute);
  vPath.Parameters[0].Description := 'The pet identifier.';
  vPath.Parameters[0].TypeParameter := stpInteger;

  vOperation := vPath.AddOperation(ohvGet);
  vOperation.OperationId := 'getPet';
  vOperation.Summary := 'Returns a pet of the store';
  vOperation.Tags.Add(c_PetsTagName);

  AddResponse(vOperation, '200', 'The pet of the store').AddMediaType(c_MimeTypeJson).Schema.Name :=
    c_PetSchemaName;

  AddResponse(vOperation, '404', 'The pet does not exist');
end;

end.
