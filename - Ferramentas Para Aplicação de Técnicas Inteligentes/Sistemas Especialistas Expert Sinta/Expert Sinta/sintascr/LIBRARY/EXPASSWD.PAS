{==========================================
 * Expert SINTA Visual Component Library *

 Module name: ExPasswd.pas
 Abstract:
     Tela para entrada de senha
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Data de início: 14 de março de 1996
 Data de término: 14 de março de 1996
 Última modificação: 08 de maio de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ==========================================}

unit ExPasswd;

interface

uses
   WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
   Buttons, Dialogs;

   {$IFDEF WIN32}
      {$H-} {Desliga as huge strings}
   {$ENDIF}

const
   INVALID_PASSWORD_STRING = 'Senha inválida!';
   NO_PERMISSION_STRING = 'Não é permitido o uso desse arquivo em nenhuma hipótese!';
   EXECUTE_AND_VIEW_STRING = 'Você poderá utilizar o sistema especialista normalmente, mas ' +
                             'não será permitida a edição da base!';
   ONLY_EXECUTE_STRING = 'A permissão de uso restringe o sistema especialista somente à ' +
                         'execução. Você não poderá ver as regras que formam a base de ' +
                         'conhecimento.';

type
  TdialogPasswd = class(TForm)
    Label1: TLabel;
    Password: TEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    Label2: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OKBtnClick(Sender: TObject);
  private
    enter: boolean;
  public
    Passwd: string;
    PrimaryPermission: integer;
  end;

implementation

uses
   ExSystem, ExConsts;

{$R *.DFM}

procedure TdialogPasswd.FormShow(Sender: TObject);
begin
   Password.Text := '';
   Password.SetFocus;
   Enter := false;
end;

procedure TdialogPasswd.OKBtnClick(Sender: TObject);
begin
   Enter := true;
end;

procedure TdialogPasswd.FormCloseQuery(Sender: TObject;
          var CanClose: Boolean);
begin
   if enter and (Password.Text <> '') and (Password.Text <> passwd)
      then begin
      MessageDlg(INVALID_PASSWORD_STRING, mtError, [mbOk], 0);
      CanClose := false;
      enter := false;
      Password.Text := '';
      Password.SetFocus;
   end;
   if enter and (Password.Text = '') then
      case PrimaryPermission of
         NO_PERMISSION:
            MessageDlg(NO_PERMISSION_STRING, mtInformation, [mbOk], 0);
         EXECUTE_AND_VIEW:
            MessageDlg(EXECUTE_AND_VIEW_STRING, mtInformation, [mbOk], 0);
         ONLY_EXECUTE:
            MessageDlg(ONLY_EXECUTE_STRING, mtInformation, [mbOk], 0);
      end;
end;

end.

