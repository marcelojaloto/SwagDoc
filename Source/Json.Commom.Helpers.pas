unit Json.Commom.Helpers;

interface

uses
  System.JSON;

type
  TJSONAncestorHelper = class helper for TJSONAncestor
  public
    function Format: string;
  end;

  TJSONValueHelper = class helper for TJSONValue
  public
    function GetValueRelaxed<T>(path:String):T; overload; // If not found, returns default("",0,false,etc)
    function GetValueRelaxed<T>(path:String; adefault:T):T; overload; // If value is not available, return the default.
  end;

implementation

{ TJSONAncestorHelper }

function TJSONAncestorHelper.Format: string;
var
  vJsonString: string;
  vChar: Char;
  vEOL: string;
  vIndent: string;
  vLeftIndent: string;
  vIsEOL: Boolean;
  vIsInString: Boolean;
  vIsEscape: Boolean;
begin
  vEOL := #13#10;
  vIndent := '  ';
  vIsEOL := true;
  vIsInString := false;
  vIsEscape := false;
  vJsonString := Self.ToString;
  for vChar in vJsonString do
  begin
    if not vIsInString and ((vChar = '{') or (vChar = '[')) then
    begin
      if not vIsEOL then
        Result := Result + vEOL;
      Result := Result + vLeftIndent + vChar + vEOL;
      vLeftIndent := vLeftIndent + vIndent;
      Result := Result + vLeftIndent;
      vIsEOL := true;
    end
    else if not vIsInString and (vChar = ',') then
    begin
      vIsEOL := false;
      Result := Result + vChar + vEOL + vLeftIndent;
    end
    else if not vIsInString and ((vChar = '}') or (vChar = ']')) then
    begin
      Delete(vLeftIndent, 1, Length(vIndent));
      if not vIsEOL then
        Result := Result + vEOL;
      Result := Result + vLeftIndent + vChar + vEOL;
      vIsEOL := true;
    end
    else
    begin
      vIsEOL := false;
      Result := Result + vChar;
    end;
    vIsEscape := (vChar = '\') and not vIsEscape;
    if not vIsEscape and (vChar = '"') then
      vIsInString := not vIsInString;
  end;
end;

{ TJSONValueHelper }

function TJSONValueHelper.GetValueRelaxed<T>(path: String): T;
begin
  result:=GetValueRelaxed<T>(path,default(T));
end;

function TJSONValueHelper.GetValueRelaxed<T>(path: String; adefault: T): T;
begin
  if not(TryGetValue<T>(path,result)) then result:=adefault;
end;

end.
