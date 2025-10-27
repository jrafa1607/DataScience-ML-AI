{===========================================
 UNIDADE/FORMULÁRIO de depuração da máquina
 de inferência
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
                      Ricardo Silvestre
 Descrição: Esta janela exibe o depurador
            de consulta. Observe que o modo
            de depuração está relacionado ao
            fato desta janela estar aberta
            ou não.
 Data de início: 09 de janeiro de 1996
 Data de término: 11 de janeiro de 1996
 Última modificação: 21 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ===========================================}
unit Trace;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExCtrls;

type
  TfrmTrace = class(TForm)
    btnClose: TBitBtn;
    DebugPanel: TDebugPanel;
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  end;

var
  frmTrace: TfrmTrace;

implementation

uses
   General;

{$R *.DFM}

procedure TfrmTrace.FormCreate(Sender: TObject);
begin
   DebugPanel.ExpertSystem := ExSys;
end;

procedure TfrmTrace.FormResize(Sender: TObject);
begin
 try
   DebugPanel.Width := Width - 3 * DebugPanel.Left;
   DebugPanel.Height := Height - DebugPanel.Top - btnClose.Height * 2 - 10;
   btnClose.Top := Height - 2 * btnClose.Height;
   btnClose.Left := trunc((Width - btnClose.Width) / 2);
 finally end;
end;

procedure TfrmTrace.FormShow(Sender: TObject);
begin
   FormResize(Sender);
end;

procedure TfrmTrace.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   if ExSys.Trace then ExSys.ResumeEngine;
end;

procedure TfrmTrace.FormActivate(Sender: TObject);
begin
   DebugPanel.Refresh;
end;

procedure TfrmTrace.btnCloseClick(Sender: TObject);
begin
   Close;
end;

end.
