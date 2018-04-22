object frmSimpleSwaggerDocDemo: TfrmSimpleSwaggerDocDemo
  Left = 0
  Top = 0
  Caption = 'Simple SwagDoc Demo'
  ClientHeight = 214
  ClientWidth = 876
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 39
    Width = 876
    Height = 175
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
  end
  object btnLoadJSON: TButton
    Left = 21
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Load JSON'
    TabOrder = 1
    OnClick = btnLoadJSONClick
  end
end
