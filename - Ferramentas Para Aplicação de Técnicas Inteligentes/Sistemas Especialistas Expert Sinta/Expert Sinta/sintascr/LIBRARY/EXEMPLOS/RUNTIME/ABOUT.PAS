{========================================================
 * Expert SINTA Run-Time *

 Module name: About.pas
 Implementação: Ricardo Bezerra
 Data de início: 24 de março de 1997
 Data de término: 24 de março de 1997
 Última modificação: 02 de agosto de 1997
 Expert SINTA RunTime(c) 1995-1997
 Laboratório de Inteligência Artificial/LIA
 ========================================================}

unit About;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, SysUtils, ShellAPI;

type
  TdialogAbout = class(TForm)
    Label1: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Image: TImage;
    Label11: TLabel;
    labelURL: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    btnOK: TButton;
    Label2: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure labelURLClick(Sender: TObject);
  end;

implementation

{$R *.DFM}

procedure TdialogAbout.FormCreate(Sender: TObject);
var
  i, j, w, h: integer;
  color: TColor;
begin
  w := Image.Width - 1;
  h := Image.Height - 1;
  color := Image.Picture.Bitmap.Canvas.Pixels[0, h];
  for i := 0 to w do
     for j := 0 to h do
        if Image.Picture.Bitmap.Canvas.Pixels[i, j] = color then
           Image.Picture.Bitmap.Canvas.Pixels[i, j] := clBtnFace;
  Screen.Cursors[1] := LoadCursor(hInstance, 'HYPER_LINK');
  labelURL.Cursor := 1;
end;

procedure TdialogAbout.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
   Action := caFree;
end;

procedure TdialogAbout.labelURLClick(Sender: TObject);
begin
   ShellExecute(Handle, 'open', 'http://www.lia.ufc.br',
                nil, nil, SW_SHOW);
end;

end.

