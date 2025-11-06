{=============================================
 UNIDADE/FORMULÁRIO de abertura
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
                      Ricardo Silvestre
 Descrição: A janela "Splash" do Expert SINTA.
 Data de início: 16 de janeiro de 1996
 Data de término: 16 de janeiro de 1996
 Última modificação: 20 de novembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =============================================}
unit Overture;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, StdCtrls, Buttons;

type
  TfrmFirstOne = class(TForm)
    Panel: TPanel;
    Bevel: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Image: TImage;
    label32: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  end;

var
  frmFirstOne: TfrmFirstOne;

implementation

{$R *.DFM}

procedure TfrmFirstOne.FormCreate(Sender: TObject);
{$IFDEF WINDOWS}
var
  i, j, w, h: integer;
  color: TColor;
{$ENDIF}
begin
   {$IFDEF WINDOWS}
   w := Image.Width - 1;
   h := Image.Height - 1;
   color := Image.Picture.Bitmap.Canvas.Pixels[0, h];
   for i := 0 to w do
     for j := 0 to h do
         if Image.Picture.Bitmap.Canvas.Pixels[i, j] = color then
            Image.Picture.Bitmap.Canvas.Pixels[i, j] := clBtnFace;
   {$ELSE}
   Image.Transparent := true;
   label32.visible := true;
   {$ENDIF}
end;

procedure TfrmFirstOne.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
   Action := caFree;
end;

end.
