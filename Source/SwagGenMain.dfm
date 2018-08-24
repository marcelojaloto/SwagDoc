object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'SwaggerGen'
  ClientHeight = 465
  ClientWidth = 667
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
  object Panel1: TPanel
    Left = 0
    Top = 424
    Width = 667
    Height = 41
    Align = alBottom
    TabOrder = 0
    object Button1: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Load Swagger'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 88
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Generate'
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 667
    Height = 424
    Align = alClient
    Lines.Strings = (
      'SwagGen'
      ''
      
        'This will generate Delphi Object wrappers to handle the creation' +
        ' and consumption of'
      'Swagger Schemas.'
      ''
      ''
      'Load the Swagger json definition, then hit generate.'
      ''
      'Cut and past the result into the unit of your choice.'
      ''
      'Use SwagDoc to read the definitions.'
      ''
      'A work in progress.')
    TabOrder = 1
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'json'
    Filter = 'Swagger File|*.json'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Load Swagger Definition'
    Left = 328
    Top = 240
  end
end
