{================================================
 UNIDADE/FORMULÁRIO do editor de items de regra
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Silvestre
                      Ricardo Bezerra
 Descrição: Em conjunto com a janela da unidade
            RuleCode, permite a edição de regras.
 Data de início: 03 de janeiro de 1996
 Data de término: 04 de janeiro de 1996
 Última modificação: 24 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ================================================}

unit Ruleedit;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls, Tabs,
  Buttons, ExtCtrls, Dialogs, SysUtils, Rulecode, TB97;

const
   HEAD = 0;
   TAIL = 1;

type
  TdialogEditRule = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    btnModify: TBitBtn;
    btnCancel: TBitBtn;
    HelpBtn: TBitBtn;
    comboVars: TComboBox;
    comboOperators: TComboBox;
    comboValues: TComboBox;
    groupConect: TGroupBox;
    radioAnd: TRadioButton;
    radioOr: TRadioButton;
    Label3: TLabel;
    comboCnf: TComboBox;
    editFormula: TEdit;
    checkNot: TCheckBox;
    btnInsert: TBitBtn;
    btnSwitch: TBitBtn;
    btnZoom: TToolbarButton97;
    procedure btnModifyClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure comboVarsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure comboVarsExit(Sender: TObject);
    procedure comboVarsKeyPress(Sender: TObject; var Key: Char);
    procedure btnZoomClick(Sender: TObject);
    procedure btnInsertClick(Sender: TObject);
    procedure btnSwitchClick(Sender: TObject);
  private
    mode: integer;
    cancel_close: boolean;
    filled: boolean;
    vars_changed: boolean;
    pos_head, pos_tail: integer;
    rule_source: TfrmRule;
    function  ValidInput: boolean;
    procedure ShowHeadControls;
    procedure ShowTailControls;
  public
    var_code: integer;
    val_code: integer;
    operator: string;
    cnf: real;
    conect: integer;
    negation: boolean;
    procedure DefineMode(s: TfrmRule; m: integer; first, insertion: boolean);
    procedure FillCombos;
    procedure FillWithTail(v: integer; op: string; v2: integer;
              conect: integer; neg: boolean);
    procedure FillWithHead(v: integer; v2: integer; cnf: real);
  end;

var
  dialogEditRule: TdialogEditRule;

implementation

uses
   General, Zoom, ExDataSt, ExConsts;

{$R *.DFM}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}

procedure TdialogEditRule.FormCreate(Sender: TObject);
begin
    comboCnf.Items.Add('100');
    comboCnf.Items.Add('90');
    comboCnf.Items.Add('80');
    comboCnf.Items.Add('70');
    comboCnf.Items.Add('60');
    comboCnf.Items.Add('50');
    comboCnf.Items.Add('40');
    comboCnf.Items.Add('30');
    comboCnf.Items.Add('20');
    comboCnf.Items.Add('10');
    filled := false;
end;

procedure TdialogEditRule.FormShow(Sender: TObject);
begin
   comboVars.SetFocus;
end;

procedure TdialogEditRule.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not cancel_close;
end;

procedure TdialogEditRule.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    filled := false;
end;

{======================================================================
 ======================================================================
                       CARREGAMENTO DE ITENS
 ======================================================================
 ======================================================================}

procedure TdialogEditRule.FillCombos;
begin
    comboVars.Clear;
    comboOperators.Clear;
    comboValues.Clear;
    comboVars.Text := '';
    comboValues.Text := '';
    comboOperators.Text := '';
    comboCnf.Text := '';
    ExSys.Vars.MoveFirst;
    while not ExSys.Vars.Blind do begin
       comboVars.Items.Add(ExSys.Vars.Name);
       ExSys.Vars.MoveNext;
    end;
end;

procedure TdialogEditRule.FillWithTail(v: integer; op: string;
          v2: integer; conect: integer; neg: boolean);
begin
   comboVars.Text := ExSys.VarName(v);
   comboVarsClick(Self);
   comboOperators.Text := op;
   comboValues.Text := ExSys.ValName(v, v2);
   editFormula.Text := comboValues.Text;
   case conect of
      cnAnd: radioAnd.Checked := true;
      cnOr: radioOr.Checked := true;
   else
      groupConect.Enabled := false;
   end;
   checkNot.Checked := neg;
end;

procedure TdialogEditRule.FillWithHead(v: integer; v2: integer;cnf: real);
begin
   comboVars.Text := ExSys.VarName(v);
   comboVarsClick(Self);
   comboCnf.Text := MyFloatToStr(cnf * 100);
   comboValues.Text := ExSys.ValName(v, v2);
   editFormula.Text := comboValues.Text;
   groupConect.Enabled := false;
end;

{======================================================================
 ======================================================================
                  MÉTODOS RELATIVOS ÀS COMBOBOXES
 ======================================================================
 ======================================================================}

procedure TdialogEditRule.comboVarsClick(Sender: TObject);
begin
   comboValues.Items.Clear;
   ExSys.Vars.SeekByName(comboVars.Text);
   comboValues.Text := '';
   if not ExSys.Vars.Blind then begin
      if ExSys.Vars.Numeric then begin
         comboValues.visible := false;
         editFormula.visible := true;
         btnZoom.visible := true;
      end
      else begin
         comboValues.visible := true;
         editFormula.visible := false;
         btnZoom.visible := false;
         ExSys.Values.SeekByVar(ExSys.Vars.code);
         if ExSys.Values.Blind then begin
            comboValues.Items.Add(YES_STRING);
            comboValues.Items.Add(NO_STRING);
            comboValues.Text := YES_STRING;
         end;
         while (not ExSys.Values.Blind) and
               (ExSys.Values.VarCode = ExSys.Vars.Code) do begin
               comboValues.Items.Add(ExSys.Values.Name);
               ExSys.Values.MoveNext;
         end;
      end;
      comboValues.Items.Add(UNKNOWN_STRING);
      comboOperators.Items.Clear;
      comboOperators.Items.Add('=');
      comboOperators.Items.Add('<>');
      if ExSys.Vars.Numeric then begin
         comboOperators.Items.Add('>');
         comboOperators.Items.Add('<');
         comboOperators.Items.Add('>=');
         comboOperators.Items.Add('<=');
      end;
      comboOperators.ItemIndex := 0;
   end;
end;

procedure TdialogEditRule.comboVarsExit(Sender: TObject);
begin
   if vars_changed then comboVarsClick(Sender);
   vars_changed := false;
end;

procedure TdialogEditRule.comboVarsKeyPress(Sender: TObject;
  var Key: Char);
begin
   vars_changed := true;
   comboValues.Clear;
   comboValues.Text := '';
end;

{======================================================================
 ======================================================================
             MÉTODOS RELATIVOS AOS BOTÕES DE EDIÇÃO
 ======================================================================
 ======================================================================}

procedure TdialogEditRule.btnInsertClick(Sender: TObject);
begin
   if ValidInput then begin
      if mode = HEAD then begin
         rule_source.listRules.ItemIndex := pos_head;
         rule_source.InsertNewHeadFromDialog;
         inc(pos_head);
      end
      else begin
         rule_source.listRules.ItemIndex := pos_tail;
         rule_source.InsertNewTailFromDialog;
         inc(pos_tail);
         inc(pos_head);
      end;
      if not groupConect.Enabled then begin
         groupConect.Enabled := true;
         radioAnd.Enabled := true;
         radioOr.Enabled := true;
      end;
      comboVars.SetFocus;
      comboVars.SelectAll;
   end;
end;

procedure TdialogEditRule.btnModifyClick(Sender: TObject);
begin
   cancel_close := not ValidInput;
end;

procedure TdialogEditRule.btnCancelClick(Sender: TObject);
begin
   cancel_close := false;
end;

procedure TdialogEditRule.btnSwitchClick(Sender: TObject);
begin
   if mode = TAIL then begin
      ShowHeadControls;
      comboVars.SetFocus;
      comboVars.SelectAll;
      mode := HEAD;
      btnSwitch.Hint := 'Premissa|Alterna para premissa.';
   end
   else begin
      ShowTailControls;
      comboVars.SetFocus;
      comboVars.SelectAll;
      mode := TAIL;
      btnSwitch.Hint := 'Conclusão|Alterna para conclusão.';
   end;
end;

procedure TdialogEditRule.btnZoomClick(Sender: TObject);
begin
   dialogZoom.memoFormula.Text := editFormula.Text;
   if dialogZoom.ShowModal = mrOk then begin
      editFormula.Text := dialogZoom.memoFormula.Text;
      editFormula.SelectAll;
      editFormula.SetFocus;
   end;
end;

{======================================================================
 ======================================================================
                           FUNÇÕES DE USO GERAL
 ======================================================================
 ======================================================================}

procedure TdialogEditRule.ShowHeadControls;
begin
   comboOperators.Visible := False;
   groupConect.Visible := False;
   comboCnf.Visible := True;
   checkNot.Visible := False;
end;

procedure TdialogEditRule.ShowTailControls;
begin
   comboOperators.Visible := True;
   groupConect.Visible := True;
   comboCnf.Visible := False;
   checkNot.Visible := True;
end;

procedure TdialogEditRule.DefineMode(s: TfrmRule; m: integer;
                                     first, insertion: boolean);
begin
  case m of
     HEAD:
       begin
         ShowHeadControls;
         pos_head := s.listRules.ItemIndex;
         pos_tail := s.listRules.Items.IndexOf(THEN_STRING) - 1;
       end;
     TAIL:
       begin
         ShowTailControls;
         pos_head := s.listRules.Items.Count - 1;
         pos_tail := s.listRules.ItemIndex;
       end;
  end;
  rule_source := s;
  groupConect.Enabled := not first;
  radioAnd.Enabled := not first;
  radioOr.Enabled := not first;
  mode := m;
  btnModify.Visible := not insertion;
  btnModify.Default := not insertion;
  btnSwitch.Visible := insertion;
  btnInsert.Visible := insertion;
  btnInsert.Default := insertion;
  if insertion then begin
     btnCancel.Caption := 'Fechar';
     if mode = TAIL then
        btnSwitch.Hint := 'Conclusão|Alterna para conclusão.'
     else
        btnSwitch.Hint := 'Premissa|Alterna para premissa.';
  end
  else
     btnCancel.Caption := 'Cancelar';
end;

function TdialogEditRule.ValidInput: boolean;
var
  no_values: boolean;

  {Função para checar a sintaxe de fórmulas entradas.
   ATENÇÃO: mudar, pois está TOTALMENTE incompleta!}
  function CheckSintax(formula: string): boolean;
  begin
     if formula = '' then
        Result := true
     else
        Result := false;
  end;

begin
   Result := true;
   try
     if comboVars.Items.IndexOf(comboVars.Text) = -1 then begin
        MessageDlg('Variável inexistente!', mtError, [mbOk], 0);
        Result := false;
        Exit;
     end;
     if (mode = TAIL) and (comboOperators.Items.IndexOf(comboOperators.Text) = -1) then begin
        MessageDlg('Operador inválido!', mtError, [mbOk], 0);
        Result := false;
        Exit;
     end;
     if mode = HEAD then begin
        if comboCnf.Text <> '' then
           cnf := StrToFloat(comboCnf.Text) / 100
        else
           cnf := 1;
     end;
     ExSys.Vars.SeekByName(comboVars.Text);
     var_code := ExSys.Vars.Code;
     if not ExSys.Vars.Numeric then begin
        if comboValues.Items.IndexOf(comboValues.Text) = -1 then begin
           MessageDlg('Valor inexistente!', mtError, [mbOk], 0);
           Result := false;
           Exit;
        end;
        ExSys.Values.SeekByVar(ExSys.Vars.code);
        no_values := ExSys.Values.Blind;
        if comboValues.Text = UNKNOWN_STRING then
           val_code := UNKNOWN
        else begin
           if no_values and (comboValues.Text = YES_STRING) then
              val_code := YES
           else begin
              if no_values and (comboValues.Text = NO_STRING) then
                 val_code := NO
              else begin
                 ExSys.Values.SeekByName(comboValues.Text, var_code);
                 val_code := ExSys.Values.Code;
              end;
           end;
        end;
     end
     else begin
        if CheckSintax(editFormula.Text) then begin
           MessageDlg('Fórmula inválida!', mtError, [mbOk], 0);
           Result := false;
           Exit;
        end;
        if editFormula.Text = UNKNOWN_STRING then
           val_code := UNKNOWN
        else
           val_code := ExSys.Formulas.GetFreeCode;
     end;
     operator := comboOperators.Text;
     if groupConect.Enabled then begin
        if radioAnd.Checked then
           conect := cnAnd
        else
           conect := cnOr;
     end;
     negation := checkNot.Checked;
   except
      on EConvertError do begin
         MessageDlg('Grau de confiança inválido!', mtError, [mbOk], 0);
         Result := false;
      end;
   end;
end;

end.
