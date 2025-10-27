{=================================================
 UNIDADE/FORMULÁRIO de rastreamento de variáveis
 Implementação: Ricardo Bezerra
 Descrição: Janela de acompanhamento de variáveis,
            ao estilo de uma janela "Watch" de um
            compilador.
 Design de interface: Ricardo Bezerra
 Data de início: 22 de janeiro de 1996
 Data de término: 22 de janeiro de 1996
 Última modificação: 17 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA
 =================================================}
unit WatCode;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExtCtrls, ExCtrls;

type
  TfrmWatch = class(TForm)
    btnClose: TBitBtn;
    WatchPanel: TWatchPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  end;

var
  frmWatch: TfrmWatch;

implementation

uses
   General;

{$R *.DFM}

procedure TfrmWatch.FormCreate(Sender: TObject);
begin
   FormResize(Sender);
   WatchPanel.ExpertSystem := ExSys;
end;

procedure TfrmWatch.FormResize(Sender: TObject);
begin
 try
   if Width < 200 then Width := 200;
   if Height < 250 then Height := 250;
   WatchPanel.Width := Width - 3 * WatchPanel.Left;
   WatchPanel.Height := Height - WatchPanel.Top - btnClose.Height * 2 - 10;
   btnClose.Top := Height - 2 * btnClose.Height;
   btnClose.Left := trunc((Width - btnClose.Width) / 2);
 finally end;
end;

procedure TfrmWatch.btnCloseClick(Sender: TObject);
begin
   Close;
end;

end.
