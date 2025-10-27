{==========================================
 UNIDADE/FORMULÁRIO de opções gerais
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Permite a definição de opções
            gerais relativas à máquina de
            inferência e permissões de
            acesso.
 Data de início: 10 de março de 1996
 Data de término: 01 de abril de 1996
 Última modificação: 21 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ==========================================}

unit Options;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, TabNotBk, StdCtrls, Buttons;

const
  DEFAULT_FORMULA = 'A fórmula padrão está sendo utilizada.';

type
  TdialogOptions = class(TForm)
    TabbedNotebook: TTabbedNotebook;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    groupPreced: TGroupBox;
    radioAND: TRadioButton;
    radioOr: TRadioButton;
    Label2: TLabel;
    checkAllAvaliation: TCheckBox;
    checkUsePasswd: TCheckBox;
    labelPasswdStatus: TLabel;
    btnNewPasswd: TButton;
    groupRestrictions: TGroupBox;
    editCNF: TEdit;
    radioExecAndView: TRadioButton;
    radioOnlyExec: TRadioButton;
    radioNone: TRadioButton;
    groupCalc: TGroupBox;
    labelAnd: TLabel;
    labelOr: TLabel;
    labelConclusion: TLabel;
    editAnd: TEdit;
    btnChangeAnd: TButton;
    editOr: TEdit;
    btnChangeOr: TButton;
    editConclusion: TEdit;
    btnChangeConclusion: TButton;
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure btnNewPasswdClick(Sender: TObject);
    procedure btnChangeAndClick(Sender: TObject);
    procedure btnChangeOrClick(Sender: TObject);
    procedure btnChangeConclusionClick(Sender: TObject);
  public
    temp_passwd: string;
  end;

var
  dialogOptions: TdialogOptions;

implementation

uses
   Base, General, NewPassw, ExConsts, ExSystem;

{$R *.DFM}

procedure TdialogOptions.FormShow(Sender: TObject);
begin
   case ExSys.Priority of
     cnAnd:
        radioAnd.Checked := true;
     cnOr:
        radioOr.Checked := true;
   end;
   with ExSys.Protection do begin
     if Decrypt(Password, THE_KEY) <> '' then begin
        labelPasswdStatus.Caption := 'Senha definida.';
        btnNewPasswd.Caption := '&Mudar senha...';
        groupRestrictions.Enabled := true;
        radioExecAndView.Enabled := true;
        radioOnlyExec.Enabled := true;
        radioNone.Enabled := true;
        checkUsePasswd.Enabled := true;
     end
     else begin
        labelPasswdStatus.Caption := 'Nenhuma senha em uso atualmente.';
        btnNewPasswd.Caption := '&Nova senha...';
        radioExecAndView.Enabled := false;
        radioOnlyExec.Enabled := false;
        radioNone.Enabled := false;
        checkUsePasswd.Enabled := false;
     end;
     case Permission of
        EXECUTE_AND_VIEW:
         begin
          radioExecAndView.checked := true;
          radioOnlyExec.checked := false;
          radioNone.checked := false;
         end;
        ONLY_EXECUTE:
         begin
          radioExecAndView.checked := false;
          radioOnlyExec.checked := true;
          radioNone.checked := false;
         end;
        NO_PERMISSION:
         begin
          radioExecAndView.checked := false;
          radioOnlyExec.checked := false;
          radioNone.checked := true;
         end;
     end;
     checkUsePasswd.checked := UsePassword;
     temp_passwd := password;
   end;
   editCNF.Text := FloatToStr(trunc(ExSys.MIN_VALUE * 100));
   with ExSys.CustomFormulas do begin
      if DefaultAnd then begin
         btnChangeAnd.Caption := '&Alterar';
         editAnd.Text := DEFAULT_FORMULA;
         editAnd.Enabled := false;
      end
      else begin
         btnChangeAnd.Caption := '&Padrão';
         editAnd.Text := FormulaAnd;
         editAnd.Enabled := true;
      end;
      if DefaultOr then begin
         btnChangeOr.Caption := 'Alt&erar';
         editOr.Text := DEFAULT_FORMULA;
         editOr.Enabled := false;
      end
      else begin
         btnChangeOr.Caption := 'P&adrão';
         editOr.Text := FormulaOr;
         editOr.Enabled := true;
      end;
      if DefaultConclusion then begin
         btnChangeConclusion.Caption := 'Alte&rar';
         editConclusion.Text := DEFAULT_FORMULA;
         editConclusion.Enabled := false;
      end
      else begin
         btnChangeConclusion.Caption := 'Pa&drão';
         editConclusion.Text := FormulaConclusion;
         editConclusion.Enabled := true;
      end;
   end;
   checkAllAvaliation.Checked := ExSys.ExamineAll;
end;

procedure TdialogOptions.OKBtnClick(Sender: TObject);
var
   continue: boolean;
   aux_cnf: real;
begin
   continue := true;

   try
     aux_cnf := StrToFloat(editCNF.Text);
     if (aux_cnf < 0) or (aux_cnf > 100) then begin
        MessageDlg('Valor inválido no grau de confiança mínimo!',
                   mtError, [mbOk], 0);
        TabbedNotebook.PageIndex := 1;
        continue := false;
     end;
   except
     begin
      MessageDlg('Valor inválido no grau de confiança mínimo!',
                 mtError, [mbOk], 0);
      TabbedNotebook.PageIndex := 1;
      continue := false;
     end;
   end;

   if continue and (ExSys.Permission = TOTAL_PERMISSION) then begin
      if radioAnd.Checked then
         ExSys.Priority := cnAnd
      else
         ExSys.Priority := cnOr;

      ExSys.MIN_VALUE := StrToFloat(editCNF.Text) / 100;

      ExSys.ExamineAll := checkAllAvaliation.Checked;

      with ExSys.Protection do begin
         Password := temp_passwd;
         if radioNone.checked then
            Permission := NO_PERMISSION
         else begin
            if radioOnlyExec.checked then
               Permission := ONLY_EXECUTE
            else
               Permission := EXECUTE_AND_VIEW;
         end;
         UsePassword := checkUsePasswd.checked;
      end;

      with ExSys.CustomFormulas do begin
         if editAnd.Text = DEFAULT_FORMULA then begin
            DefaultAnd := true;
            FormulaAnd := '';
         end
         else begin
            DefaultAnd := false;
            FormulaAnd := editAnd.Text;
         end;
         if editOr.Text = DEFAULT_FORMULA then begin
            DefaultOr := true;
            FormulaOr := '';
         end
         else begin
            DefaultOr := false;
            FormulaOr := editOr.Text;
         end;
         if editConclusion.Text = DEFAULT_FORMULA then begin
            DefaultConclusion := true;
            FormulaConclusion := '';
         end
         else begin
            DefaultConclusion := false;
            FormulaConclusion := editConclusion.Text;
         end;
      end;

      frmBase.save_me := true;

      Close;
   end;
   if continue and (ExSys.Permission <> TOTAL_PERMISSION) then
      MessageDlg('Lembre-se de que você não tem permissão para alterar ' +
                 'esta base de conhecimento!', mtInformation, [mbOk], 0);
end;

procedure TdialogOptions.btnNewPasswdClick(Sender: TObject);
var
   answer: integer;
begin
   answer := dialogCreatePasswd.ShowModal;
   if (answer = mrOk) and (dialogCreatePasswd.editPassword.Text <> '') then begin
      temp_passwd := Encrypt(dialogCreatePasswd.editPassword.Text,
                                     THE_KEY);
      labelPasswdStatus.Caption := 'Senha definida.';
      btnNewPasswd.Caption := '&Mudar senha...';
      groupRestrictions.Enabled := true;
      radioExecAndView.Enabled := true;
      radioOnlyExec.Enabled := true;
      radioNone.Enabled := true;
      checkUsePasswd.Enabled := true;
   end
   else
      if (answer = mrNo) or ((answer = mrOk) and
         (dialogCreatePasswd.editPassword.Text = '')) then begin
         {Limpar a senha}
         temp_passwd := Encrypt('', THE_KEY);
         labelPasswdStatus.Caption := 'Nenhuma senha em uso atualmente.';
         btnNewPasswd.Caption := '&Nova senha...';
         groupRestrictions.Enabled := false;
         radioExecAndView.Enabled := false;
         radioOnlyExec.Enabled := false;
         radioNone.Enabled := false;
         checkUsePasswd.Enabled := false;
         checkUsePasswd.checked := false;
      end;
end;

procedure TdialogOptions.btnChangeAndClick(Sender: TObject);
begin
   if editAnd.Text = DEFAULT_FORMULA then begin
      editAnd.Text := '';
      editAnd.Enabled := true;
      editAnd.SetFocus;
      btnChangeAnd.Caption := '&Padrão';
   end
   else begin
      editAnd.Text := DEFAULT_FORMULA;
      editAnd.Enabled := false;
      btnChangeAnd.Caption := '&Alterar';
   end;
end;

procedure TdialogOptions.btnChangeOrClick(Sender: TObject);
begin
   if editOr.Text = DEFAULT_FORMULA then begin
      editOr.Text := '';
      editOr.Enabled := true;
      editOr.SetFocus;
      btnChangeOr.Caption := 'P&adrão';
   end
   else begin
      editOr.Text := DEFAULT_FORMULA;
      editOr.Enabled := false;
      btnChangeOr.Caption := 'Alt&erar';
   end;
end;

procedure TdialogOptions.btnChangeConclusionClick(Sender: TObject);
begin
   if editConclusion.Text = DEFAULT_FORMULA then begin
      editConclusion.Text := '';
      editConclusion.Enabled := true;
      editConclusion.SetFocus;
      btnChangeConclusion.Caption := 'Pa&drão';
   end
   else begin
      editConclusion.Text := DEFAULT_FORMULA;
      editConclusion.Enabled := false;
      btnChangeConclusion.Caption := 'Alte&rar';
   end;
end;

end.
