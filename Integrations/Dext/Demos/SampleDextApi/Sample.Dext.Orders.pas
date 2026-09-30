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

unit Sample.Dext.Orders;

interface

uses
  Dext,
  Dext.Web,
  Dext.OpenAPI.Attributes,
  Sample.Dext.Models;

type
  /// <summary>
  /// The order endpoints of the sample, written as a Dext controller and described with its attributes.
  /// </summary>
  [ApiController('/api/orders')]
  [SwaggerTag('Orders')]
  TOrdersController = class(TObject)
  public
    [HttpGet('/{id}')]
    [AllowAnonymous]
    [SwaggerOperation('Returns an order', 'Returns the order with the given identifier')]
    [SwaggerResponse(200, TOrder, 'The order')]
    [SwaggerResponse(404, 'The order does not exist')]
    // The parameter keeps the name of the route variable, which is how Dext binds it.
    procedure GetById(pContext: IHttpContext; [FromRoute] Id: Integer); virtual;

    [HttpPost('')]
    [Authorize('bearerAuth')]
    [SwaggerOperation('Places an order')]
    [SwaggerResponse(201, TOrder, 'The order placed')]
    [SwaggerResponse(400, 'The order is not valid')]
    procedure Place(pContext: IHttpContext; const pRequest: TNewOrder); virtual;
  end;

implementation

uses
  System.SysUtils,
  Dext.Json;

{ TOrdersController }

procedure TOrdersController.GetById(pContext: IHttpContext; Id: Integer);
var
  vOrder: TOrder;
  vProblem: TProblem;
begin
  if Id <> 7 then
  begin
    vProblem.Title := 'Order not found';
    vProblem.Status := 404;
    pContext.Response.StatusCode := 404;
    pContext.Response.Json(TDextJson.Serialize<TProblem>(vProblem));
    Exit;
  end;

  vOrder := TOrder.Create;
  try
    vOrder.Id := 7;
    vOrder.PetId := 1;
    vOrder.Quantity := 1;
    vOrder.ShipDate := EncodeDate(2026, 10, 1);
    vOrder.Complete := False;
    pContext.Response.Json(TDextJson.Serialize<TOrder>(vOrder));
  finally
    vOrder.Free;
  end;
end;

procedure TOrdersController.Place(pContext: IHttpContext; const pRequest: TNewOrder);
var
  vOrder: TOrder;
begin
  vOrder := TOrder.Create;
  try
    vOrder.Id := 8;
    vOrder.PetId := pRequest.PetId;
    vOrder.Quantity := pRequest.Quantity;
    vOrder.ShipDate := Date + 1;
    vOrder.Complete := False;
    pContext.Response.StatusCode := 201;
    pContext.Response.Json(TDextJson.Serialize<TOrder>(vOrder));
  finally
    vOrder.Free;
  end;
end;

initialization
  // Keeps the controller in the executable, since it is only found through RTTI.
  TOrdersController.ClassName;

end.
