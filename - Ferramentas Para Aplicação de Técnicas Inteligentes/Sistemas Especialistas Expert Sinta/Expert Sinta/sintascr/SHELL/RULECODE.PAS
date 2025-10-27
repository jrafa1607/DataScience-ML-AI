{================================================
 UNIDADE/FORMULÁRIO de criação de regras
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Silvestre
                      Ricardo Bezerra
 Descrição: Este é o editor de regras. Comunica-
            se com o editor de itens de regra
            (em RuleEdit.pas).
 Data de início: 02 de janeiro de 1996
 Data de término:04 de janeiro de 1996
 Última modificação: 07 de setembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ================================================}

unit RuleCode;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExtCtrls, ExDataSt;

type
  TfrmRule = class(TForm)
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    btnChange: TBitBtn;
    btnDel: TBitBtn;
    btnNew: TBitBtn;
    panelName: TPanel;
    labelName: TLabel;
    editName: TEdit;
    panelRules: TPanel;
    btnHelp: TBitBtn;
    SubPanel: TPanel;
    ScrollBox: TScrollBox;
    listRules: TListBox;
    labelOrder: TLabel;
    editOrder: TEdit;
    btnNextRule: TButton;
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure listRulesClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
    procedure listRulesDblClick(Sender: TObject);
    procedure listRulesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure listRulesDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure btnNextRuleClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    set_next: boolean;
    MARGIN: string;
    NewFormulas, FormsToBeDeleted: TSingleIndexTree;
    CopyFormulas: TCodeNameIndexTree;
    function  RuleOK: boolean;
    procedure LoadRule(c: integer; model: boolean);
    procedure InsertTail(pos: integer; v: integer; op: string;
       v2: integer; con: integer; neg: boolean);
    procedure DeleteTail(pos: integer);
    procedure ModifyTail(pos: integer; v: integer; op: string;
       v2: integer; con: integer; neg: boolean);
    procedure ModifyOnlyConect(pos: integer);
    procedure InsertHead(pos: integer; v: integer; v2: integer;
       cnf: real);
    procedure DeleteHead(pos: integer);
    procedure ModifyHead(pos: integer; v: integer; v2: integer;
       cnf: real);
    procedure ModifyRuleView;
    procedure DeleteLinkedFormula(var_code, form_code: integer);
  public
    save_it: boolean;
    code: integer;
    procedure SetRule(c: integer; order: integer; name: string; model: boolean);
    procedure InsertNewHeadFromDialog;
    procedure InsertNewTailFromDialog;
  end;

implementation

uses
   General, RuleEdit, Base, Main, ExConsts;

{$R *.DFM}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}

procedure TfrmRule.FormCreate(Sender: TObject);
begin
   save_it := true;
   set_next := false;
   listRules.Items.Add(IF_STRING);
   listRules.Items.Add(THEN_STRING);
   MARGIN := Space(DEFAULT_CONECT_LENGTH);
   NewFormulas := TSingleIndexTree.Create;
   CopyFormulas := TCodeNameIndexTree.Create;
   FormsToBeDeleted := TSingleIndexTree.Create;
   Width := 100;
   Height := 100;
   FormResize(Sender);
end;

procedure TfrmRule.FormResize(Sender: TObject);
begin
  try
    if Width < 540 then  Width := 540;
    if Height < 300 then Height := 300;
    panelRules.Height := Height - 140;
    panelRules.Width := Width - 2 * panelRules.Left - 6;
    panelName.Width := panelRules.Width;
    editName.Width := panelRules.Width - editName.Left -
                      labelOrder.Width - editOrder.Width - 20;
    SubPanel.Height := panelRules.Height - 2 * SubPanel.Top;
    SubPanel.Width := panelRules.Width - 2 * SubPanel.Left;
    ModifyRuleView;
    btnChange.Top := panelRules.Top + panelRules.Height + 20;
    btnNew.Top := btnChange.Top;
    btnDel.Top := btnChange.Top;
    labelOrder.Left := editName.Width + editName.Left + 6;
    editOrder.Left := labelOrder.Left + labelOrder.Width + 2;
    btnOK.Top := btnChange.Top;
    btnOK.Left := panelRules.Width - 3 * btnOK.Width;
    btnCancel.Top := btnOk.Top;
    btnCancel.Left := btnOK.Left + btnOk.Width;
    btnHelp.Top := btnOk.Top;
    btnHelp.Left := btnCancel.Left + btnCancel.Width;

    btnNextRule.Top := btnOk.Top;
    btnNextRule.Left := btnNew.Left + btnNew.Width + 3;
    btnNextRule.Width := btnOk.Left - (btnNew.Left + btnNew.Width) - 6;
  finally end;
end;

procedure TfrmRule.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   CanClose := RuleOK;
end;

procedure TfrmRule.FormClose(Sender: TObject; var Action: TCloseAction);
var
  total, pos, i, position, old_position: integer;
begin
   pos := listRules.Items.IndexOf(THEN_STRING) - 1;
   total := frmBase.listRules.Items.Count;
   if save_it and (ExSys.Permission = TOTAL_PERMISSION) then begin

      Screen.Cursor := crHourGlass;

      position := StrToInt(editOrder.Text);
      if position < 1 then position := 1;
      if code > 0 then begin {Altera uma regra já existente}
         if position > total then position := total;
         {Apaga a regra, mas deixa as possíveis fórmulas presentes}
         DeleteOnlySentences(code);
         ExSys.Rules.Seek(code);
         if ExSys.Rules.Position <> position then begin
            old_position := ExSys.Rules.position;
            ExSys.Rules.Delete;
            if position < old_position then
               DefinePositions(position, 1, old_position - 1)
            else
               DefinePositions(old_position + 1, -1, position);
            ExSys.Rules.Insert(code, editName.Text, position, 0);
         end
         else begin
            ExSys.Rules.Name := editName.Text;
            old_position := position;
         end;
      end
      else begin {Nova regra}
         if position > total + 1 then
            position := total + 1;
         code := ExSys.Rules.GetFreeCode;
         DefinePositions(position, 1, total);
         ExSys.Rules.Insert(code, editName.Text, position, 0);
         frmBase.listRules.Items.AddObject('', TValNode(ExSys.Rules.CurrentNodeVar.Node));
         old_position := frmBase.listRules.Items.Count;
      end;

      {Deleta fórmulas modificadas}
      FormsToBeDeleted.MoveFirst;
      while not FormsToBeDeleted.Blind do begin
         ExSys.Formulas.Seek(FormsToBeDeleted.code);
         if not ExSys.Formulas.Blind then ExSys.Formulas.Delete;
         FormsToBeDeleted.MoveNext;
      end;

      for i := 1 to pos do
          ExSys.Tails.Insert(code,
                      TTailNode(listRules.Items.Objects[i]).VarCode,
                      TTailNode(listRules.Items.Objects[i]).Operator,
                      TTailNode(listRules.Items.Objects[i]).ValCode,
                      TTailNode(listRules.Items.Objects[i]).Conect,
                      TTailNode(listRules.Items.Objects[i]).Neg);
      for i := pos + 2 to listRules.Items.Count - 1 do
          ExSys.Heads.Insert(code,
                      THeadNode(listRules.Items.Objects[i]).VarCode,
                      THeadNode(listRules.Items.Objects[i]).ValCode,
                      THeadNode(listRules.Items.Objects[i]).Cnf);
      if frmBase.btnOpenRule.Enabled = false then frmBase.EnableRulesEdition;

      if position < old_position then
         frmBase.ArrangeListRules(position - 1, old_position - 1)
      else
         frmBase.ArrangeListRules(old_position - 1, position - 1);
      frmBase.listRules.ItemIndex := position - 1;
      frmBase.save_me := true;

      Screen.Cursor := crDefault;

   end
   else begin

      {Restaura fórmulas modificadas}
      CopyFormulas.MoveFirst;
      while not CopyFormulas.Blind do begin
         ExSys.Formulas.Seek(CopyFormulas.code);
         if not ExSys.Formulas.Blind then ExSys.Formulas.Name := CopyFormulas.name;
         CopyFormulas.MoveNext;
      end;

      {Deleta todas as fórmulas novas}
      NewFormulas.MoveFirst;
      while not NewFormulas.Blind do begin
         ExSys.Formulas.Seek(NewFormulas.code);
         if not ExSys.Formulas.Blind then ExSys.Formulas.Delete;
         NewFormulas.MoveNext;
      end;

   end;
   for i := 1 to pos do
       TTailNode(listRules.Items.Objects[i]).Free;
   for i := pos + 2 to listRules.Items.Count - 1 do
       THeadNode(listRules.Items.Objects[i]).Free;
   NewFormulas.Free;
   CopyFormulas.Free;
   FormsToBeDeleted.Free;
   pos := loaded_rules.IndexOfObject(Self);
   loaded_rules.Delete(pos);
   if save_it and (ExSys.Permission <> TOTAL_PERMISSION) then
       MessageDlg('Lembre-se de que você não tem permissão para alterar essa ' +
                  'base de conhecimento!', mtInformation, [mbOk], 0);
   Action := caFree;
end;

procedure TfrmRule.FormDestroy(Sender: TObject);
begin
   if set_next then frmBase.btnNewRuleClick(nil);
end;

{======================================================================
 ======================================================================
                       CARREGAMENTO DA REGRA
 ======================================================================
 ======================================================================}

procedure TfrmRule.SetRule(c: integer; order: integer; name: string;
                           model: boolean);
begin
   if c > 0 then begin
      LoadRule(c, model);
      if model then {O flag 'model' indica se a regra é somente de modelo}
         code := 0
      else
         code := c;
   end
   else begin
      code := 0;
      listRules.Visible := true;
      listRules.ItemIndex := 0;
   end;
   btnNew.SetFocus;
   Caption := 'Regra ' + IntToStr(order);
   editName.Text := name;
   editOrder.Text := IntToStr(order);
   ModifyRuleView;
end;

procedure TfrmRule.LoadRule(c: integer; model: boolean);
var
  cont, val_code: integer;
begin
  cont := 1;
  ExSys.Tails.Seek(c);
  while (not ExSys.Tails.Blind) and (ExSys.Tails.Code = c) do begin
     if model then begin
        ExSys.Vars.Seek(ExSys.Tails.VarCode);
        if (ExSys.Vars.Numeric) and (val_code <> UNKNOWN) then begin
           {Se for o modelo de uma regra, então cria fórmulas novas
            baseadas nas do modelo}
            val_code := ExSys.Formulas.GetFreeCode;
            ExSys.Formulas.Seek(ExSys.Tails.ValCode);
            ExSys.Formulas.Insert(val_code, ExSys.Formulas.Name);
            NewFormulas.Insert(val_code);
        end
        else
            val_code := ExSys.Tails.ValCode;
        InsertTail(cont, ExSys.Tails.VarCode, ExSys.Tails.Operator,
                   val_code, ExSys.Tails.Conect, ExSys.Tails.Neg);
     end
     else
        InsertTail(cont, ExSys.Tails.VarCode, ExSys.Tails.Operator,
                   ExSys.Tails.ValCode, ExSys.Tails.Conect, ExSys.Tails.Neg);
     ExSys.Tails.MoveNext;
     cont := cont + 1;
  end;
  cont := cont + 1;
  ExSys.Heads.Seek(c);
  while (not ExSys.Heads.Blind) and (ExSys.Heads.Code = c) do begin
     if model then begin
        ExSys.Vars.Seek(ExSys.Heads.VarCode);
        if (ExSys.Vars.Numeric) and (val_code <> UNKNOWN) then begin
            val_code := ExSys.Formulas.GetFreeCode;
            ExSys.Formulas.Seek(ExSys.Heads.ValCode);
            ExSys.Formulas.Insert(val_code, ExSys.Formulas.Name);
            NewFormulas.Insert(val_code);
        end
        else
            val_code := ExSys.Heads.ValCode;
        InsertHead(cont, ExSys.Heads.VarCode, val_code, ExSys.Heads.Cnf);
     end
     else
        InsertHead(cont, ExSys.Heads.VarCode, ExSys.Heads.ValCode, ExSys.Heads.Cnf);
     ExSys.Heads.MoveNext;
     inc(cont);
  end;
  listRules.Visible := true;
end;

{======================================================================
 ======================================================================
                           BOTÕES DE EDIÇÃO
 ======================================================================
 ======================================================================}

procedure TfrmRule.btnNewClick(Sender: TObject);
var
   pos: integer;
begin
   pos := listRules.ItemIndex;
   if pos >= listRules.Items.IndexOf(THEN_STRING) then
      with dialogEditRule do begin
         DefineMode(Self, HEAD, false, true);
         ShowModal;
      end
   else
      with dialogEditRule do begin
         if pos = 0 then
            DefineMode(Self, TAIL, true, true)
         else
            DefineMode(Self, TAIL, false, true);
         ShowModal;
      end;
end;

procedure TfrmRule.btnChangeClick(Sender: TObject);
var
   pos, c: integer;

   procedure CheckNumericVar(var old_var, old_val, var_code, val_code: integer;
                             sentence: string);
   begin
      ExSys.Vars.Seek(var_code);
      if ExSys.Vars.Numeric then begin
         ExSys.Vars.Seek(old_var);
         {Verifica se a variável anterior era numérica ou não}
         if ExSys.Vars.numeric then begin
            if val_code <> UNKNOWN then begin
               if old_val <> UNKNOWN then begin
                 {Como a variável anterior da sentença também era numérica,
                  usa-se o mesmo código da fórmula antiga}
                  val_code := old_val;
                  ExSys.Formulas.Seek(old_val);
                  {Salva a fórmula para posterior restauração, se o usuário
                   cancelar as mudanças}
                  CopyFormulas.Seek(old_val);
                  if CopyFormulas.Blind then
                     CopyFormulas.Insert(old_val, ExSys.Formulas.Name);
                     ExSys.Formulas.Name := sentence;
               end
               else begin
                  {O valor da variável numérica anterior era 'DESCONHECIDO',
                  logo é necessário que se crie uma nova fórmula}
                  ExSys.Formulas.Insert(val_code, sentence);
                  NewFormulas.Insert(val_code);
               end;
            end
            else
               {Não será necessário nenhuma fórmula nessa sentença (pois o
                valor da sentença é 'DESCONHECIDO'), logo marca-se a fórmula
                antiga para deleção2}
               if old_val <> UNKNOWN then FormsToBeDeleted.Insert(old_val);
         end
         else
            {A variável anterior não era numérica, portanto é necessário
             que criemos uma nova fórmula}
            if val_code <> UNKNOWN then begin
               ExSys.Formulas.Insert(val_code, sentence);
               NewFormulas.Insert(val_code);
            end;
      end
      else
         if old_val <> UNKNOWN then begin
            ExSys.Vars.Seek(old_var);
            {A variável anterior era numérica, apaga-se a fórmula}
            if ExSys.Vars.Numeric then
               FormsToBeDeleted.Insert(old_val);
         end;
   end;

begin
   pos := listRules.ItemIndex;
   if pos >= listRules.Items.IndexOf(THEN_STRING) then
      with dialogEditRule do begin
         DefineMode(Self, HEAD, false, false);
         FillWithHead(THeadNode(listRules.Items.Objects[pos]).VarCode,
                      THeadNode(listRules.Items.Objects[pos]).ValCode,
                      THeadNode(listRules.Items.Objects[pos]).Cnf);
         if ShowModal = mrOk then begin
            CheckNumericVar(THeadNode(listRules.Items.Objects[pos]).VarCode,
                            THeadNode(listRules.Items.Objects[pos]).ValCode,
                            var_code, val_code, editFormula.Text);
            ModifyHead(pos, var_code, val_code, cnf);
            ModifyRuleView;
         end;
      end
   else
      with dialogEditRule do begin
         if pos = 1 then
            DefineMode(Self, TAIL, true, false)
         else
            DefineMode(Self, TAIL, false, false);
         if pos <> 1 then
            c := TTailNode(listRules.Items.Objects[pos - 1]).Conect
         else
            c := cnAnd;
         FillWithTail(TTailNode(listRules.Items.Objects[pos]).VarCode,
                      TTailNode(listRules.Items.Objects[pos]).Operator,
                      TTailNode(listRules.Items.Objects[pos]).ValCode,
                      c,
                      TTailNode(listRules.Items.Objects[pos]).Neg);
         if ShowModal = MrOk then begin
            CheckNumericVar(TTailNode(listRules.Items.Objects[pos]).VarCode,
                            TTailNode(listRules.Items.Objects[pos]).ValCode,
                            var_code, val_code, editFormula.Text);
            if pos <> 1 then
               TTailNode(listRules.Items.Objects[pos - 1]).conect := conect;
            if pos = listRules.Items.IndexOf(THEN_STRING) - 1 then
               ModifyTail(pos, var_code, operator, val_code, cnThen, negation)
            else begin {pos <> 1 e não é antes do ENTÃO}
               c := TTailNode(listRules.Items.Objects[pos]).conect;
               ModifyTail(pos, var_code, operator, val_code, c, negation);
            end;
            if (pos > 1) and (pos <> listRules.Items.IndexOf(THEN_STRING) - 1) then
               ModifyOnlyConect(pos + 1);
            ModifyRuleView;
         end;
      end;
end;

procedure TfrmRule.btnDelClick(Sender: TObject);
var
   old_value, con, pos, pos_then: integer;
begin
   pos_then := listRules.Items.IndexOf(THEN_STRING);
   pos := listRules.ItemIndex;

   if pos < pos_then then begin
      con := TTailNode(listRules.Items.Objects[pos]).Conect;

      {Marca fórmulas a serem deletedas. Não são deletadas agora porque
       o usuário pode cancelar a edição da regra}
      old_value := TTailNode(listRules.Items.Objects[pos]).ValCode;
      if old_value <> UNKNOWN then begin
         ExSys.Vars.Seek(TTailNode(listRules.Items.Objects[pos]).VarCode);
         if ExSys.Vars.Numeric then FormsToBeDeleted.Insert(old_value);
      end;

      DeleteTail(listRules.ItemIndex);
      if pos > 1 then
         TTailNode(listRules.Items.Objects[pos - 1]).Conect := con
      else
         if pos + 1 <> pos_then then ModifyOnlyConect(pos);
   end
   else begin
      {Marca fórmulas a serem deletedas. Não são deletadas agora porque
       o usuário pode cancelar a edição da regra}
      old_value := THeadNode(listRules.Items.Objects[pos]).ValCode;
      if old_value <> UNKNOWN then begin
         ExSys.Vars.Seek(THeadNode(listRules.Items.Objects[pos]).VarCode);
         if ExSys.Vars.numeric then FormsToBeDeleted.Insert(old_value);
      end;

      DeleteHead(listRules.ItemIndex);
   end;
   if pos = -1 then begin
      btnNew.Enabled := false;
      btnChange.Enabled := false;
      btnDel.Enabled := false;
   end;
   ModifyRuleView;
end;

procedure TfrmRule.listRulesDblClick(Sender: TObject);
begin
   if btnChange.Enabled then btnChangeClick(Sender);
end;

procedure TfrmRule.listRulesKeyDown(Sender: TObject; var Key: Word;
                                    Shift: TShiftState);
begin
   if (Key = VK_DELETE) and (btnDel.Enabled) then btnDelClick(Sender);
end;

{======================================================================
 ======================================================================
                       MÉTODO DE EDIÇÃO DE REGRA
 ======================================================================
 ======================================================================}

procedure TfrmRule.InsertTail(pos: integer; v: integer; op: string;
          v2: integer; con: integer; neg: boolean);
var
   item: string;
   new_tail: TTailNode;
begin
   if pos > 1 then
      item := ExSys.ConectName(TTailNode(listRules.Items.Objects[pos - 1]).Conect)
   else
      item := MARGIN;
   if neg then item := item + NOT_STRING + ' ';
   item := item + ExSys.VarName(v) + ' ';
   item := item + op + ' ';
   item := item + ExSys.ValName(v, v2);
   new_tail := TTailNode.Create;
   new_tail.VarCode := v;
   new_tail.Operator := op;
   new_tail.ValCode := v2;
   new_tail.Conect := con;
   new_tail.Neg := neg;
   listRules.Items.InsertObject(pos, item, new_tail);
   listRules.ItemIndex := pos;
   listRulesClick(Self);
end;

{Esse procedimento deleta uma fórmula que tenha sido criada nesse sessão de
 edição, ou seja, imediatamente após a abertura da janela}
procedure TfrmRule.DeleteLinkedFormula(var_code, form_code: integer);
begin
   if form_code <> UNKNOWN then begin
      ExSys.Vars.Seek(var_code);
      if ExSys.Vars.Numeric then begin
         NewFormulas.Seek(form_code);
         {Se é uma fórmula recém-inserida...}
         if not NewFormulas.Blind then begin
            ExSys.Formulas.Seek(form_code);
            ExSys.Formulas.Delete;
            NewFormulas.Delete;
         end;
      end;
   end;
end;

procedure TfrmRule.DeleteTail(pos: integer);
begin
   DeleteLinkedFormula(TTailNode(listRules.Items.Objects[pos]).VarCode,
                       TTailNode(listRules.Items.Objects[pos]).ValCode);
   TTailNode(listRules.Items.Objects[pos]).Free;
   listRules.Items.Delete(pos);
   if pos > listRules.Items.Count then
      listRules.ItemIndex := pos - 1
   else
      listRules.ItemIndex := pos - 1;
   listRulesClick(Self);
end;

procedure TfrmRule.ModifyTail(pos: integer; v: integer; op: string;
          v2: integer; con: integer; neg: boolean);
var
   item: string;
   new_tail: TTailNode;
begin
   if pos > 1 then
      item := ExSys.ConectName(TTailNode(listRules.Items.Objects[pos - 1]).Conect)
   else
      item := MARGIN;
   if neg then item := item + NOT_STRING + ' ';
   item := item + ExSys.VarName(v) + ' ';
   item := item + op + ' ';
   item := item + ExSys.ValName(v, v2);
   new_tail := listRules.Items.Objects[pos] as TTailNode;
   new_tail.VarCode := v;
   new_tail.Operator := op;
   new_tail.ValCode := v2;
   new_tail.Conect := con;
   new_tail.Neg := neg;
   listRules.Items[pos] := item;
   listRules.ItemIndex := pos;
   listRulesClick(Self);
end;

procedure TfrmRule.ModifyOnlyConect(pos: integer);
var
   item: string;
   aux: string;
begin
   if pos > 1 then
      item := ExSys.ConectName(TTailNode(listRules.Items.Objects[pos - 1]).Conect)
   else
      item := MARGIN;
   aux := listRules.Items[pos];
   listRules.Items[pos] := item + Copy(aux, DEFAULT_CONECT_LENGTH + 1, length(aux) - DEFAULT_CONECT_LENGTH);
end;

procedure TfrmRule.InsertHead(pos: integer; v: integer; v2: integer;
          cnf: real);
var
   item: string;
   new_head: THeadNode;
begin
   item := MARGIN;
   item := item + ExSys.VarName(v) + ' = ';
   item := item + ExSys.ValName(v, v2);
   item := item + ' CNF ' + MyFloatToStr(cnf * 100) + '%';
   new_head := THeadNode.Create;
   new_head.VarCode := v;
   new_head.ValCode := v2;
   new_head.Cnf := cnf;
   listRules.Items.InsertObject(pos, item, new_head);
   listRules.ItemIndex := pos;
   listRulesClick(Self);
end;

procedure TfrmRule.DeleteHead(pos: integer);
begin
   DeleteLinkedFormula(THeadNode(listRules.Items.Objects[pos]).VarCode,
                       THeadNode(listRules.Items.Objects[pos]).ValCode);
   THeadNode(listRules.Items.Objects[pos]).Free;
   listRules.Items.Delete(pos);
   if pos > listRules.Items.Count then
      listRules.ItemIndex := pos - 1
   else
      listRules.ItemIndex := pos - 1;
   listRulesClick(Self);
end;

procedure TfrmRule.ModifyHead(pos: integer; v: integer; v2: integer;
          cnf: real);
var
   item: string;
   new_head: THeadNode;
begin
   item := MARGIN;
   item := item + ExSys.VarName(v) + ' = ';
   item := item + ExSys.ValName(v, v2);
   item := item + ' CNF ' + MyFloatToStr(cnf * 100) + '%';
   new_head := listRules.Items.Objects[pos] as THeadNode;
   new_head.VarCode := v;
   new_head.ValCode := v2;
   new_head.Cnf := cnf;
   listRules.Items[pos] := item;
   listRules.ItemIndex := pos;
   listRulesClick(Self);
end;

procedure TfrmRule.listRulesClick(Sender: TObject);
var
   pos_if: integer;
   pos_then: integer;
begin
   pos_if := listRules.Items.IndexOf(IF_STRING);
   pos_then := listRules.Items.IndexOf(THEN_STRING);
   btnNew.Enabled := true;
   if (listRules.ItemIndex <> pos_if) and (listRules.ItemIndex <> pos_then) then begin
       btnChange.Enabled := true;
       btnDel.Enabled := true;
   end
   else begin
       btnChange.Enabled := false;
       btnDel.Enabled := false;
   end;
end;

{======================================================================
 ======================================================================
                 INTERFACE COM O EDITOR DE ITENS DE REGRA
 ======================================================================
 ======================================================================}

{Esse procedimento é chamdo por dialogEditRule, para inserir uma
 nova cabeça sem precisar fechar a caixa de diálogo}
procedure TfrmRule.InsertNewHeadFromDialog;
var
   pos: integer;
begin
   pos := listRules.ItemIndex;
   {Vars já foi posicionada corretamente por dialogEditRule}
   with dialogEditRule do begin
      if (ExSys.Vars.Numeric) and (val_code <> UNKNOWN) then begin
          ExSys.Formulas.Insert(val_code, editFormula.Text);
          NewFormulas.Insert(val_code);
      end;
      InsertHead(pos + 1, var_code, val_code, cnf);
   end;
   ModifyRuleView;
end;

procedure TfrmRule.InsertNewTailFromDialog;
var
   pos, old_conect: integer;
begin
   pos := listRules.ItemIndex;
   {Vars já foi posicionada corretamente por dialogEditRule}
   with dialogEditRule do begin
      if (ExSys.Vars.Numeric) and (val_code <> UNKNOWN) then begin
          ExSys.Formulas.Insert(val_code, editFormula.Text);
          NewFormulas.Insert(val_code);
      end;
      if pos <> 0 then begin
         old_conect := TTailNode(listRules.Items.Objects[pos]).Conect;
         TTailNode(listRules.Items.Objects[pos]).Conect := conect;
      end
      else
         old_conect := cnAnd;
      if pos = listRules.Items.IndexOf(THEN_STRING) - 1 then
         InsertTail(pos + 1, var_code, operator, val_code, cnThen, negation)
      else
         InsertTail(pos + 1, var_code, operator, val_code, old_conect, negation);
      if pos <> listRules.Items.IndexOf(THEN_STRING) - 2 then
         ModifyOnlyConect(pos + 2);
   end;
   ModifyRuleView;
end;

{======================================================================
 ======================================================================
            DESENHO E AJUSTE DA CAIXA DE LISTAGEM COM A REGRA
 ======================================================================
 ======================================================================}

procedure TfrmRule.listRulesDrawItem(Control: TWinControl; Index: Integer;
          Rect: TRect; State: TOwnerDrawState);
begin
   with listRules do begin
      Canvas.FillRect(Rect);
      if odSelected in State then
         Canvas.Font.Color := clWhite
      else begin
         if (Index = 0) or (Index = Items.IndexOf(THEN_STRING)) then
            Canvas.Font.Color := clRed
         else
            Canvas.Font.Color := clNavy;
      end;
      if (not (odSelected in State)) and
         ExSys.IsConect(Copy(Items[Index], 1, DEFAULT_CONECT_LENGTH)) then
         begin
         Canvas.Font.Color := clRed;
         Canvas.TextOut(Rect.Left, Rect.Top, Copy(Items[Index], 1,
                        DEFAULT_CONECT_LENGTH));
         Canvas.Font.Color := clNavy;
         Canvas.TextOut(Rect.Left + DEFAULT_CONECT_LENGTH * Canvas.TextWidth('M'),
                Rect.Top, Copy(Items[Index], DEFAULT_CONECT_LENGTH + 1,
                Length(Items[Index])));
      end
      else
         Canvas.TextOut(Rect.Left, Rect.Top, Items[Index]);
   end;
end;

procedure TfrmRule.ModifyRuleView;
var
  i, bigger, tam_bigger: integer;
begin
   bigger := 0;
   for i := 1 to ListRules.Items.Count - 1 do
      if Length(listRules.Items[i]) > Length(listRules.Items[bigger])
         then bigger := i;
   if SubPanel.Height > (listRules.Items.Count + 1) * listRules.ItemHeight then
      listRules.Height := ScrollBox.Height
   else
      listRules.Height := (listRules.Items.Count + 1) * listRules.ItemHeight;
   tam_bigger := listRules.Canvas.TextWidth('M') * length(listRules.Items[bigger]);
   if SubPanel.Width > tam_bigger then
      listRules.Width := ScrollBox.Width
   else
      listRules.Width := tam_bigger;
end;

{======================================================================
 ======================================================================
             MÉTODOS RELATIVOS AOS BOTÕES DE FECHAMENTO DA JANELA
 ======================================================================
 ======================================================================}

procedure TfrmRule.btnNextRuleClick(Sender: TObject);
begin
   if RuleOK then begin
      set_next := true;
      save_it := true;
      Close;
   end;
end;

procedure TfrmRule.btnOkClick(Sender: TObject);
begin
  save_it := true;
  Close;
end;

procedure TfrmRule.btnCancelClick(Sender: TObject);
begin
  save_it := false;
  Close;
end;

{======================================================================
 ======================================================================
                           FUNÇÕES DE USO GERAL
 ======================================================================
 ======================================================================}

function TfrmRule.RuleOK: boolean;

  {Verifica a "completude" (ou algo aproximado :-) da regra}
  function Completeness: boolean;
  var
     pos: integer;
  begin
     {Verifica a existência de alguma cauda ou cabeça}
     pos := listRules.Items.IndexOf(THEN_STRING);
     Result := ((pos <> 1) and (pos <> listRules.Items.Count - 1));
     if not Result then
        MessageDlg('A regra não está estruturada da maneira correta!',
                   mtError, [mbOk], 0);
  end;

  {Verifica a "corretude" da regra - ou algo aproximado ;-)}
  function Correctness: boolean;
  var
    i, j, pos, total_heads: integer;
    tail_var, head_var: integer;
  begin
    {O Expert SINTA não vai aceitar se uma mesma variável aparece tanto
     nas premissas como nas conclusões de uma regra, pelo motivo óbvio
     de que é uma maneira fácil da máquina de inferência entrar em
     recursão infinita - ver "Sistema Especialista para Redes de Computadores",
     by Ricardo Silvestre - 1995!}
    pos := listRules.Items.IndexOf(THEN_STRING) - 1;
    total_heads := listRules.Items.Count - (pos + 2);
    Result := true;
    i := 1;
    while Result and (i <= total_heads) do begin
       j := 1;
       head_var := THeadNode(listRules.Items.Objects[pos + 1 + i]).VarCode;
       while Result and (j <= pos) do begin
         tail_var := TTailNode(listRules.Items.Objects[j]).VarCode;
         if tail_var = head_var then Result := false;
         inc(j);
       end;
       inc(i);
    end;
    if not Result then MessageDlg('Não é possível a presença de uma mesma ' +
       'variável nas premissas e conclusões simultaneamente!', mtError,
       [mbOk], 0);
  end;

begin
   if save_it then begin
      if (not Completeness) or (not Correctness) then
         Result := false
      else begin
         if editOrder.Text = '' then begin
            MessageDlg('É necessário que a regra tenha uma ordem!',
               mtWarning, [mbOk], 0);
            editOrder.SetFocus;
            Result := false;
         end
         else begin
            try
              StrToInt(editOrder.Text);
              Result := true;
            except
              on EConvertError do begin
                 MessageDlg('Ordem de regra inválida!', mtWarning, [mbOk], 0);
                 editOrder.SetFocus;
                 Result := false;
               end;
            end;
        end;
      end;
   end
   else
     Result := true;
end;

end.
