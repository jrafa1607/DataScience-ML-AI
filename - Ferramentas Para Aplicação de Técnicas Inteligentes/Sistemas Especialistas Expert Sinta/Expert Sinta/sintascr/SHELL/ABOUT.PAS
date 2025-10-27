{==========================================
 UNIDADE/FORMULÁRIO "Sobre o Expert SINTA"
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Pequena janela "Sobre..." com
            os créditos da equipe.
 Data de início: 23 de dezembro de 1995
 Data de término: 23 de dezembro de 1995
 Última modificação: 02 de maio de 1998
 Expert SINTA (c) 1995-1998 Grupo SINTA
 ==========================================}

unit About;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, SysUtils;

type
  TdialogAbout = class(TForm)
    Label1: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    imageExSINTA: TImage;
    Label11: TLabel;
    labelURL: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label2: TLabel;
    btnOK: TButton;
    btnCredits: TButton;
    ImageLIA: TImage;
    Panel1: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCreditsClick(Sender: TObject);
    procedure labelURLClick(Sender: TObject);
  end;

implementation

uses
   {$IFDEF WIN32}
     Wordcap,
   {$ENDIF}
   General, Credits, ShellAPI;

{$R *.DFM}

{$IFDEF WINDOWS}
procedure MaskImage(Image: TImage);
var
  i, j, w, h: integer;
  color: TColor;
begin
   w := Image.Width - 1;
   h := Image.Height - 1;
   color := Image.Picture.Bitmap.Canvas.Pixels[0, 0];
   for i := 0 to w do
     for j := 0 to h do
         if Image.Picture.Bitmap.Canvas.Pixels[i, j] = color then
            Image.Picture.Bitmap.Canvas.Pixels[i, j] := clBtnFace;
end;
{$ENDIF}

procedure TdialogAbout.FormCreate(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   MaskImage(imageExSINTA);
   MaskImage(imageLIA);
   {$ELSE}
   imageExSINTA.Transparent := true;
   imageLIA.Transparent := true;
   with TMSOfficeCaption.Create(Self) do
        if GetColorsCount > 256 then Enabled := geAlways;
   {$ENDIF}
   Screen.Cursors[2] := LoadCursor(hInstance, 'HYPER_LINK');
   labelURL.Cursor := 2;
end;

procedure TdialogAbout.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
   Action := caFree;
end;

procedure TdialogAbout.btnCreditsClick(Sender: TObject);
begin
   dialogCredits := TdialogCredits.Create(nil);
   dialogCredits.ShowModal;
end;

procedure TdialogAbout.labelURLClick(Sender: TObject);
begin
   labelURL.Font.Color := clPurple;
   Screen.Cursor := crHourglass;
   ShellExecute(Handle, 'open', 'http://www.lia.ufc.br', nil, nil, SW_SHOW);
   Screen.Cursor := crDefault;
end;

end.

