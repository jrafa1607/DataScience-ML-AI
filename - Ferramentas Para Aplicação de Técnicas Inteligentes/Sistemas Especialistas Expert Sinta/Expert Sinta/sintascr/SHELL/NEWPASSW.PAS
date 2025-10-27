{==========================================
 UNIDADE/FORMULÁRIO de criação de senha
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Janela para inserção de senhas.
 Data de início: 14 de março de 1996
 Data de término: 14 de março de 1996
 Última modicação: 21 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ==========================================}

unit NewPassw;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls, Dialogs, General;

type
  TdialogCreatePasswd = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Bevel1: TBevel;
    Label1: TLabel;
    editPassword: TEdit;
    btnClear: TBitBtn;
    Label2: TLabel;
    editConfirm: TEdit;
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    save: boolean;
  end;

var
  dialogCreatePasswd: TdialogCreatePasswd;

implementation

uses
   Options, ExConsts, ExSystem;

{$R *.DFM}

procedure TdialogCreatePasswd.FormShow(Sender: TObject);
begin
   save := false;
   editPassword.Text := Decrypt(dialogOptions.temp_passwd, THE_KEY);
   editConfirm.Text := '';
   editPassword.SetFocus;
end;

procedure TdialogCreatePasswd.OKBtnClick(Sender: TObject);
begin
   save := true;
end;

procedure TdialogCreatePasswd.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
   if save then begin
      if editPassword.Text <> editConfirm.Text then begin
         MessageDlg('Confirmação errada!', mtError, [mbOk], 0);
         editConfirm.SetFocus;
         editConfirm.SelectAll;
         CanClose := false;
      end;
   end;
   save := false;
end;

end.
