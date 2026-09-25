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

unit Horse.SwagDoc.Discovery;

interface

uses
  Swag.Doc;

type
  /// <summary>
  /// Reads the routes registered in Horse and adds to the document the operations that are not documented yet.
  /// The router knows the path and the HTTP method of a route, so each discovered operation is written with a
  /// single response and without a summary, to show which endpoints of the API still need documentation.
  /// </summary>
  THorseSwagDocDiscovery = class(TObject)
  public
    /// <summary>
    /// Adds the routes registered in Horse to the document, except the ones listed in the ignored routes.
    /// </summary>
    class procedure DocumentRegisteredRoutes(pSwagDoc: TSwagDoc; const pIgnoredRoutes: TArray<string>); static;
  end;

implementation

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Horse,
  Horse.Commons,
  Horse.Core.RouterTree,
  Swag.Common.Types,
  Swag.Doc.Path,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response,
  Horse.SwagDoc.Route;

const
  c_DiscoveredResponseStatusCode = '200';
  c_DiscoveredResponseDescription = 'Successful response';

type
  THorseSwagDocRouteInfo = record
    Method: TMethodType;
    Route: string;
  end;

  THorseSwagDocRouteReader = class(TObject)
  strict private
    class function GetRouter: THorseRouterTree; static;
    class procedure ReadRouter(var pContext: TRttiContext; pRouter: THorseRouterTree;
      pRoutes: TList<THorseSwagDocRouteInfo>); static;
  public
    class procedure ReadRegisteredRoutes(pRoutes: TList<THorseSwagDocRouteInfo>); static;
  end;

{ THorseSwagDocRouteReader }

class function THorseSwagDocRouteReader.GetRouter: THorseRouterTree;
var
  vRouter: TObject;
begin
  Result := nil;
  vRouter := THorse.Routes as TObject;
  if vRouter is THorseRouterTree then
    Result := THorseRouterTree(vRouter);
end;

class procedure THorseSwagDocRouteReader.ReadRouter(var pContext: TRttiContext; pRouter: THorseRouterTree;
  pRoutes: TList<THorseSwagDocRouteInfo>);
var
  vType: TRttiType;
  vMethodsField: TRttiField;
  vPathField: TRttiField;
  vMethods: TList<TMethodType>;
  vMethod: TMethodType;
  vFullPath: string;
  vChild: TPair<string, THorseRouterTree>;
  vRoute: THorseSwagDocRouteInfo;
begin
  vType := pContext.GetType(pRouter.ClassType);
  vMethodsField := vType.GetField('FHandlerMethods');
  vPathField := vType.GetField('FFullPath');

  if Assigned(vMethodsField) and Assigned(vPathField) then
  begin
    vMethods := TList<TMethodType>(vMethodsField.GetValue(pRouter).AsObject);
    vFullPath := vPathField.GetValue(pRouter).AsString;
    if Assigned(vMethods) and not vFullPath.IsEmpty then
      for vMethod in vMethods do
      begin
        vRoute.Method := vMethod;
        vRoute.Route := vFullPath;
        pRoutes.Add(vRoute);
      end;
  end;

  for vChild in pRouter.Route do
    ReadRouter(pContext, vChild.Value, pRoutes);
end;

class procedure THorseSwagDocRouteReader.ReadRegisteredRoutes(pRoutes: TList<THorseSwagDocRouteInfo>);
var
  vRouter: THorseRouterTree;
  vContext: TRttiContext;
begin
  vRouter := GetRouter;
  if not Assigned(vRouter) then
    Exit;

  vContext := TRttiContext.Create;
  try
    ReadRouter(vContext, vRouter, pRoutes);
  finally
    vContext.Free;
  end;
end;

{ Conversion of the routes read from the router }

function TryConvertMethod(const pMethod: TMethodType; out pOperation: TSwagPathTypeOperation): Boolean;
begin
  Result := True;
  case pMethod of
    mtGet: pOperation := ohvGet;
    mtPut: pOperation := ohvPut;
    mtPost: pOperation := ohvPost;
    mtHead: pOperation := ohvHead;
    mtDelete: pOperation := ohvDelete;
    mtPatch: pOperation := ohvPatch;
    mtQuery: pOperation := ohvQuery;
  else
    pOperation := ohvNotDefined;
    Result := False;
  end;
end;

function IsIgnoredRoute(const pRoute: string; const pIgnoredRoutes: TArray<string>): Boolean;
var
  vIgnoredRoute: string;
begin
  Result := False;
  for vIgnoredRoute in pIgnoredRoutes do
    if SameText(pRoute, vIgnoredRoute) then
      Exit(True);
end;

function HasOperation(pPath: TSwagPath; const pOperation: TSwagPathTypeOperation): Boolean;
var
  vOperation: TSwagPathOperation;
begin
  Result := False;
  for vOperation in pPath.Operations do
    if vOperation.Operation = pOperation then
      Exit(True);
end;

procedure AddDiscoveredOperation(pPath: TSwagPath; const pOperation: TSwagPathTypeOperation);
var
  vOperation: TSwagPathOperation;
  vResponse: TSwagResponse;
begin
  vOperation := pPath.AddOperation(pOperation);

  vResponse := TSwagResponse.Create;
  vResponse.StatusCode := c_DiscoveredResponseStatusCode;
  vResponse.Description := c_DiscoveredResponseDescription;
  vOperation.Responses.Add(vResponse.StatusCode, vResponse);
end;

{ THorseSwagDocDiscovery }

class procedure THorseSwagDocDiscovery.DocumentRegisteredRoutes(pSwagDoc: TSwagDoc;
  const pIgnoredRoutes: TArray<string>);
var
  vRoutes: TList<THorseSwagDocRouteInfo>;
  vRoute: THorseSwagDocRouteInfo;
  vOperation: TSwagPathTypeOperation;
  vPath: TSwagPath;
begin
  vRoutes := TList<THorseSwagDocRouteInfo>.Create;
  try
    THorseSwagDocRouteReader.ReadRegisteredRoutes(vRoutes);
    for vRoute in vRoutes do
    begin
      if IsIgnoredRoute(vRoute.Route, pIgnoredRoutes) then
        Continue;

      if not TryConvertMethod(vRoute.Method, vOperation) then
        Continue;

      vPath := THorseSwagDocRoute.AddPath(pSwagDoc, vRoute.Route);
      if not HasOperation(vPath, vOperation) then
        AddDiscoveredOperation(vPath, vOperation);
    end;
  finally
    vRoutes.Free;
  end;
end;

end.
