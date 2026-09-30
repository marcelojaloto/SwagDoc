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

unit Sample.Dext.Pets;

interface

uses
  Dext.Web.Interfaces;

type
  /// <summary>
  /// The pet endpoints of the sample, written with the Minimal API of Dext and described with its fluent API.
  /// SwagDoc reads what is given to Dext, so nothing here is specific to SwagDoc.
  /// </summary>
  TSamplePetsApi = class(TObject)
  strict private
    class procedure MapList(const pBuilder: IApplicationBuilder); static;
    class procedure MapFind(const pBuilder: IApplicationBuilder); static;
    class procedure MapAdd(const pBuilder: IApplicationBuilder); static;
    class procedure MapExists(const pBuilder: IApplicationBuilder); static;
  public
    /// <summary>
    /// Registers the pet endpoints in the application.
    /// </summary>
    class procedure MapEndpoints(const pBuilder: IApplicationBuilder); static;

    /// <summary>
    /// Completes the document with what Dext cannot describe: the type of the path parameter.
    /// </summary>
    class procedure DocumentApi; static;
  end;

implementation

uses
  System.SysUtils,
  Dext.Json,
  Dext.Web,
  Dext.OpenAPI.Fluent,
  Swag.Common.Types,
  Swag.Doc.Path,
  Swag.Doc.Tags,
  Dext.SwagDoc,
  Sample.Dext.Models;

const
  c_PetsRoute = '/api/pets';
  c_PetRoute = '/api/pets/{id}';
  c_PetsTagName = 'Pets';

var
  fPets: TArray<TPet>;

function FindPet(const pId: Integer; out pPet: TPet): Boolean;
var
  vPet: TPet;
begin
  Result := False;
  for vPet in fPets do
    if vPet.Id = pId then
    begin
      pPet := vPet;
      Exit(True);
    end;
end;

procedure SendPetNotFound(pContext: IHttpContext);
var
  vProblem: TProblem;
begin
  vProblem.Title := 'Pet not found';
  vProblem.Status := 404;
  pContext.Response.StatusCode := 404;
  pContext.Response.Json(TDextJson.Serialize<TProblem>(vProblem));
end;

{ TSamplePetsApi }

class procedure TSamplePetsApi.MapEndpoints(const pBuilder: IApplicationBuilder);
begin
  MapList(pBuilder);
  MapFind(pBuilder);
  MapAdd(pBuilder);
  MapExists(pBuilder);
end;

class procedure TSamplePetsApi.MapList(const pBuilder: IApplicationBuilder);
begin
  SwaggerEndpoint.From(pBuilder.MapGet(c_PetsRoute,
      procedure(pContext: IHttpContext)
      begin
        pContext.Response.Json(TDextJson.Serialize<TArray<TPet>>(fPets));
      end))
    .Summary('Returns the pets of the store')
    .Tag(c_PetsTagName)
    .Response(200, TypeInfo(TArray<TPet>), 'The pets of the store');
end;

class procedure TSamplePetsApi.MapFind(const pBuilder: IApplicationBuilder);
begin
  SwaggerEndpoint.From(TApplicationBuilderExtensions.MapGet<Integer, IHttpContext>(pBuilder, c_PetRoute,
      procedure(pId: Integer; pContext: IHttpContext)
      var
        vPet: TPet;
      begin
        if FindPet(pId, vPet) then
          pContext.Response.Json(TDextJson.Serialize<TPet>(vPet))
        else
          SendPetNotFound(pContext);
      end))
    .Summary('Returns a pet of the store')
    .Tag(c_PetsTagName)
    .Response(200, TypeInfo(TPet), 'The pet')
    .Response(404, TypeInfo(TProblem), 'The pet does not exist');
end;

class procedure TSamplePetsApi.MapAdd(const pBuilder: IApplicationBuilder);
begin
  SwaggerEndpoint.From(TApplicationBuilderExtensions.MapPost<TNewPet, IHttpContext>(pBuilder, c_PetsRoute,
      procedure(pNewPet: TNewPet; pContext: IHttpContext)
      var
        vPet: TPet;
      begin
        vPet.Id := Length(fPets) + 1;
        vPet.Name := pNewPet.Name;
        vPet.Status := pNewPet.Status;
        vPet.BirthDate := pNewPet.BirthDate;
        vPet.Tag := EmptyStr;
        fPets := fPets + [vPet];
        pContext.Response.StatusCode := 201;
        pContext.Response.Json(TDextJson.Serialize<TPet>(vPet));
      end))
    .Summary('Adds a pet to the store')
    .Tag(c_PetsTagName)
    .RequestType(TypeInfo(TNewPet))
    .Response(201, TypeInfo(TPet), 'The pet added to the store')
    .Response(400, TypeInfo(TProblem), 'The pet is not valid')
    .RequireAuthorization('bearerAuth');
end;

class procedure TSamplePetsApi.MapExists(const pBuilder: IApplicationBuilder);
begin
  // The Swagger support of Dext writes GET, POST, PUT, DELETE and PATCH only. SwagDoc also writes this HEAD.
  pBuilder.MapEndpoint('HEAD', c_PetRoute,
    procedure(pContext: IHttpContext)
    var
      vPet: TPet;
    begin
      if FindPet(StrToIntDef(pContext.Request.RouteParams['id'], 0), vPet) then
        pContext.Response.StatusCode := 200
      else
        pContext.Response.StatusCode := 404;
    end);
end;

class procedure TSamplePetsApi.DocumentApi;
var
  vPath: TSwagPath;
  vTag: TSwagTag;
begin
  vTag := TSwagTag.Create;
  vTag.Name := c_PetsTagName;
  vTag.Description := 'Operations about pets';
  SwagDocApi.Tags.Add(vTag);

  // The path is created with the syntax of the route and the discovery adds its operations to it later.
  vPath := SwagDocApi.Route(c_PetRoute);
  vPath.Parameters[0].Description := 'The pet identifier';
  vPath.Parameters[0].TypeParameter := stpInteger;
end;

initialization
  SetLength(fPets, 2);
  fPets[0].Id := 1;
  fPets[0].Name := 'Rex';
  fPets[0].Status := psAvailable;
  fPets[0].BirthDate := EncodeDate(2020, 3, 15);
  fPets[0].Tag := 'dog';
  fPets[1].Id := 2;
  fPets[1].Name := 'Mia';
  fPets[1].Status := psPending;
  fPets[1].BirthDate := EncodeDate(2022, 7, 1);
  fPets[1].Tag := 'cat';

end.
