{===========================================
 UNIDADE/FORMULÁRIO de abertura de execução
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Uma janela de abertura de uma
            consulta.
 Data de início: 12 de janeiro de 1996
 Data de término: 12 de janeiro de 1996
 Última modificação: 21 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ===========================================}
unit Intro;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls;

type
  TdialogIntro = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Bevel1: TBevel;
    labelName: TLabel;
    labelAuthors: TLabel;
    memoIntro: TMemo;
    procedure CancelBtnClick(Sender: TObject);
    procedure memoIntroKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
  end;

var
  dialogIntro: TdialogIntro;

implementation

uses
   General, Main;

{$R *.DFM}

procedure TdialogIntro.CancelBtnClick(Sender: TObject);
begin
   ExSys.Quit := true;
end;

procedure TdialogIntro.memoIntroKeyPress(Sender: TObject; var Key: Char);
begin
   Key := char(0);
end;

procedure TdialogIntro.FormShow(Sender: TObject);
begin
   HelpBtn.Enabled := not(ExSys.Info.HelpFile = '');
end;

procedure TdialogIntro.HelpBtnClick(Sender: TObject);
var
   help_file: string;
begin
   help_file := ExSys.Info.HelpFile + #0;
   WinHelp(frmMain.Handle, @help_file[1], HELP_CONTENTS, 0);
end;

end.
