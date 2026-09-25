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

unit Horse.SwagDoc.Route;

interface

uses
  Swag.Doc,
  Swag.Doc.Path;

type
  /// <summary>
  /// Translates the routes registered in Horse to the paths of the document. Horse writes the variables of a
  /// route as :name and the specification writes them as {name}.
  /// </summary>
  THorseSwagDocRoute = class(TObject)
  strict private
    class function HasParameter(pPath: TSwagPath; const pName: string): Boolean; static;
    class procedure AddPathParameters(pPath: TSwagPath); static;
  public
    /// <summary>
    /// Returns the path of the specification for the given Horse route.
    /// </summary>
    class function ToOpenApiPath(const pRoute: string): string; static;

    /// <summary>
    /// Returns the path of the document for the given Horse route. The path is added to the document with a
    /// parameter for each variable of the route when it does not exist yet.
    /// </summary>
    class function AddPath(pSwagDoc: TSwagDoc; const pRoute: string): TSwagPath; static;

    /// <summary>
    /// Returns the path of the document with the given uri or nil when the document does not have it.
    /// </summary>
    class function FindPath(pSwagDoc: TSwagDoc; const pUri: string): TSwagPath; static;
  end;

implementation

uses
  System.SysUtils,
  Swag.Common.Types,
  Swag.Doc.Path.Operation.RequestParameter;

{ THorseSwagDocRoute }

class function THorseSwagDocRoute.ToOpenApiPath(const pRoute: string): string;
var
  vSegments: TArray<string>;
  vSegment: string;
  vIndex: Integer;
begin
  vSegments := pRoute.Trim.Split(['/']);
  for vIndex := Low(vSegments) to High(vSegments) do
  begin
    vSegment := vSegments[vIndex];
    if not vSegment.StartsWith(':') then
      Continue;

    vSegment := vSegment.Substring(1);
    if vSegment.EndsWith('?') then
      vSegment := vSegment.Substring(0, vSegment.Length - 1);

    vSegments[vIndex] := '{' + vSegment + '}';
  end;

  Result := string.Join('/', vSegments);
  if not Result.StartsWith('/') then
    Result := '/' + Result;

  while (Result.Length > 1) and Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

class function THorseSwagDocRoute.FindPath(pSwagDoc: TSwagDoc; const pUri: string): TSwagPath;
var
  vPath: TSwagPath;
begin
  Result := nil;
  for vPath in pSwagDoc.Paths do
    if SameText(vPath.Uri, pUri) then
      Exit(vPath);
end;

class function THorseSwagDocRoute.AddPath(pSwagDoc: TSwagDoc; const pRoute: string): TSwagPath;
var
  vUri: string;
begin
  vUri := ToOpenApiPath(pRoute);
  Result := FindPath(pSwagDoc, vUri);
  if Assigned(Result) then
    Exit;

  Result := TSwagPath.Create;
  Result.Uri := vUri;
  pSwagDoc.Paths.Add(Result);
  AddPathParameters(Result);
end;

class function THorseSwagDocRoute.HasParameter(pPath: TSwagPath; const pName: string): Boolean;
var
  vParameter: TSwagRequestParameter;
begin
  Result := False;
  for vParameter in pPath.Parameters do
    if SameText(vParameter.Name, pName) then
      Exit(True);
end;

class procedure THorseSwagDocRoute.AddPathParameters(pPath: TSwagPath);
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
