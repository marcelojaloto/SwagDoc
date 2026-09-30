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

unit Dext.SwagDoc.Route;

interface

uses
  Swag.Doc,
  Swag.Doc.Path.Operation;

type
  /// <summary>
  /// Finds and creates the paths of the document for the routes of Dext. Dext already writes the variables of a
  /// route between braces, as the specification does, so a route is used as the path without translation.
  /// </summary>
  TDextSwagDocRoute = class(TObject)
  strict private
    class function HasParameter(pPath: TSwagPath; const pName: string): Boolean; static;
    class procedure AddPathParameters(pPath: TSwagPath); static;
  public
    /// <summary>
    /// Returns the route with a leading slash and without a trailing one.
    /// </summary>
    class function NormalizeRoute(const pRoute: string): string; static;

    /// <summary>
    /// Returns the path of the document with the given route, or nil when the document does not have it.
    /// </summary>
    class function FindPath(pSwagDoc: TSwagDoc; const pRoute: string): TSwagPath; static;

    /// <summary>
    /// Returns the path of the document with the given route, adding it to the document when it does not exist
    /// yet. The variables of the route are written as required path parameters of type string.
    /// </summary>
    class function AddPath(pSwagDoc: TSwagDoc; const pRoute: string): TSwagPath; static;
  end;

implementation

uses
  System.SysUtils,
  Swag.Common.Types,
  Swag.Doc.Path.Operation.RequestParameter;

{ TDextSwagDocRoute }

class function TDextSwagDocRoute.NormalizeRoute(const pRoute: string): string;
begin
  Result := pRoute.Trim;
  if not Result.StartsWith('/') then
    Result := '/' + Result;

  while (Result.Length > 1) and Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

class function TDextSwagDocRoute.FindPath(pSwagDoc: TSwagDoc; const pRoute: string): TSwagPath;
var
  vUri: string;
  vPath: TSwagPath;
begin
  Result := nil;
  vUri := NormalizeRoute(pRoute);
  for vPath in pSwagDoc.Paths do
    if SameText(vPath.Uri, vUri) then
      Exit(vPath);
end;

class function TDextSwagDocRoute.AddPath(pSwagDoc: TSwagDoc; const pRoute: string): TSwagPath;
begin
  Result := FindPath(pSwagDoc, pRoute);
  if Assigned(Result) then
    Exit;

  Result := TSwagPath.Create;
  Result.Uri := NormalizeRoute(pRoute);
  pSwagDoc.Paths.Add(Result);
  AddPathParameters(Result);
end;

class function TDextSwagDocRoute.HasParameter(pPath: TSwagPath; const pName: string): Boolean;
var
  vParameter: TSwagRequestParameter;
begin
  Result := False;
  for vParameter in pPath.Parameters do
    if SameText(vParameter.Name, pName) then
      Exit(True);
end;

class procedure TDextSwagDocRoute.AddPathParameters(pPath: TSwagPath);
var
  vUri: string;
  vParameter: TSwagRequestParameter;
  vName: string;
  vStart: Integer;
  vEnd: Integer;
begin
  vUri := pPath.Uri;
  vStart := vUri.IndexOf('{');
  while vStart >= 0 do
  begin
    vEnd := vUri.IndexOf('}', vStart);
    if vEnd < 0 then
      Break;

    vName := vUri.Substring(vStart + 1, vEnd - vStart - 1);
    if not vName.IsEmpty and not HasParameter(pPath, vName) then
    begin
      vParameter := TSwagRequestParameter.Create;
      vParameter.Name := vName;
      vParameter.InLocation := rpiPath;
      vParameter.Required := True;
      vParameter.TypeParameter := stpString;
      pPath.Parameters.Add(vParameter);
    end;

    vStart := vUri.IndexOf('{', vEnd);
  end;
end;

end.
