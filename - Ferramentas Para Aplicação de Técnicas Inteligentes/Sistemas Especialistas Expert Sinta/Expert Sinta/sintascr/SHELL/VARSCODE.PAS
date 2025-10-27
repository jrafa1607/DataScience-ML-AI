{===========================================
 UNIDADE/FORMULÁRIO de criação de variáveis
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Silvestre
                      Ricardo Bezerra
 Descrição: Editor de variáveis e valores.
 Data de início: 26 de dezembro de 1995
 Data de término: 29 de dezembro de 1995
 Última modificação: 07 de setembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ===========================================}

unit VarsCode;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Buttons, Main, ExDataSt, TB97;

type
  TfrmVars = class(TForm)
    panelVars: TPanel;
    labelVars: TLabel;
    labelValues: TLabel;
    listVars: TListBox;
    listValues: TListBox;
    panelEnter: TPanel;
    panelTypes: TPanel;
    labelVar: TLabel;
    labelValue: TLabel;
    editVar: TEdit;
    editValue: TEdit;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    btnNewVar: TButton;
    btnDelVar: TButton;
    btnNewValue: TButton;
    btnDelValue: TButton;
    btnHelp: TBitBtn;
    optionUni: TRadioButton;
    optionMulti: TRadioButton;
    optionNumeric: TRadioButton;
    btnVarAccept: TToolbarButton97;
    btnVarCancel: TToolbarButton97;
    btnValueAccept: TToolbarButton97;
    btnValueCancel: TToolbarButton97;
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure listVarsClick(Sender: TObject);
    procedure listValuesClick(Sender: TObject);
    procedure editVarEnter(Sender: TObject);
    procedure editVarKeyPress(Sender: TObject; var Key: Char);
    procedure btnValueCancelClick(Sender: TObject);
    procedure btnVarCancelClick(Sender: TObject);
    procedure btnVarAcceptClick(Sender: TObject);
    procedure btnValueAcceptClick(Sender: TObject);
    procedure btnNewVarClick(Sender: TObject);
    procedure btnNewValueClick(Sender: TObject);
    procedure editValueKeyPress(Sender: TObject; var Key: Char);
    procedure editValueEnter(Sender: TObject);
    procedure UpdateValues(Sender: TObject);
    procedure btnDelVarClick(Sender: TObject);
    procedure btnDelValueClick(Sender: TObject);
    procedure optionNumericClick(Sender: TObject);
    procedure optionMultiClick(Sender: TObject);
    procedure optionUniClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure listVarsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure listValuesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure listValuesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure listValuesDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure listValuesDragDrop(Sender, Source: TObject; X, Y: Integer);
  private
    var_name, val_name: string[100];
    current_var: integer;
    insert_mode: boolean;
    real_click: boolean;
    included_vars, modified_vars, excluded_vars: TSingleIndexTree;
    included_values, modified_values, excluded_values: TSingleIndexTree;
    VarsCopy: TVars;
    ValuesCopy: TValues;
    save_it: boolean;
    procedure InitializeTrees;
    procedure FillTrees;
    procedure FillList;
    procedure VarOperation;
    procedure ValOperation;
    function  VerifyRule(v: integer; tp: integer): integer;
    function  ValidNumericNumber(expression: string): boolean;
  end;

var
  frmVars: TfrmVars;

implementation

uses
   Base, RuleCode, RuleEdit, WatCode, General, ExConsts;

{$R *.DFM}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}

procedure TfrmVars.FormCreate(Sender: TObject);
begin
   var_name := '';
   val_name := '';
   real_click := true;
   current_var := 0;
   insert_mode := false;
   save_it := true;
   InitializeTrees;
   FillTrees;
   FillList;
   FormResize(Sender);
end;

procedure TfrmVars.FormResize(Sender: TObject);
begin
   try
      if Width < 330 then Width := 330;
      if Height < 300 then Height := 300;
      panelVars.Width := Width - btnNewVar.Width - trunc(panelVars.Left * 4.5);
      listVars.Width := trunc((panelVars.Width - 3 * listVars.Left) / 2);
      listVars.Height := Height - 193;
      labelVars.Left := listVars.Left + trunc((listVars.Width - labelVars.Width) / 2);
      listValues.Left := listVars.Left + listVars.Width + 8;
      listValues.Height := listVars.Height;
      listValues.Width := listVars.Width;
      labelValues.Left := listValues.Left + trunc((listValues.Width - labelValues.Width) / 2);
      panelVars.Height := Height - 160;
      btnNewVar.Left := panelVars.Left + panelVars.Width + 8;
      btnNewValue.Left := btnNewVar.Left;
      btnDelVar.Left := btnNewVar.Left;
      btnDelValue.Left := btnNewVar.Left;
      panelEnter.Top := panelVars.Top + panelVars.Height + 15;
      panelEnter.Width := panelVars.Width - 25;
      editVar.Width := panelEnter.Width - editVar.Left - 4 - 2 * btnVarAccept.Width - 2;
      editValue.Width := editVar.Width;

      btnVarAccept.Left := editVar.Left + editVar.Width + 2;
      btnValueAccept.Left := btnVarAccept.Left;
      btnVarCancel.Left := btnVarAccept.Left + btnVarAccept.Width;
      btnValueCancel.Left := btnVarCancel.Left;

      panelTypes.Left := panelEnter.Left + panelEnter.Width + 5;
      panelTypes.Top := panelEnter.Top;

      btnOk.Top := panelEnter.Top + panelEnter.Height + 14;
      btnOk.Left := panelTypes.Left + panelTypes.Width - 3 * btnOk.Width - 20;
      btnCancel.Top := btnOk.Top;
      btnCancel.Left := btnOk.Left + btnOk.Width + 10;
      btnHelp.Top := btnOk.Top;
      btnHelp.Left := btnCancel.Left + btnCancel.Width + 10;

   finally  end;
end;

procedure TfrmVars.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i, j: integer;

  {Essa subrotina fecha todas as janelas regras nas quais encontramos a
   variável (tipo = 0) ou valor (tipo=1) passado como parâmetro.}
  procedure CloseLinkedRules(v: integer; tp: integer);
  var
   to_be_closed: TSingleIndexTree;
   i, total: integer;

     procedure MarkItem(c: integer);
     begin
        to_be_closed.Seek(c);
        if to_be_closed.Blind then to_be_closed.Insert(c);
     end;

  begin
     to_be_closed := TSingleIndexTree.Create;

     ExSys.Tails.MoveFirst;
     while not ExSys.Tails.Blind do begin
        case tp of
           0: {variável}
              if ExSys.Tails.VarCode = v then MarkItem(ExSys.Tails.Code);
           1: {valor}
              if ExSys.Tails.ValCode = v then MarkItem(ExSys.Tails.Code);
        end;
        ExSys.Tails.MoveNext;
     end;

     ExSys.Heads.MoveFirst;
     while not ExSys.Heads.Blind do begin
        case tp of
           0: {variável}
              if ExSys.Heads.VarCode = v then MarkItem(ExSys.Heads.Code);
           1: {valor}
              if ExSys.Heads.ValCode = v then MarkItem(ExSys.Heads.Code);
        end;
        ExSys.Heads.MoveNext;
     end;

     to_be_closed.MoveFirst;
     while not to_be_closed.Blind do begin
        total := loaded_rules.Count - 1;
        for i := 0 to total do
           {Trata de fechar as janelas com uma regra que vai ser deletada}
           if TfrmRule(loaded_rules.Objects[i]).Code = to_be_closed.Code then begin
              TfrmRule(loaded_rules.Objects[i]).save_it := false;
              TfrmRule(loaded_rules.Objects[i]).Close;
           end;
        to_be_closed.MoveNext;
     end;

     to_be_closed.Free;
  end;

  procedure DelVars;
  begin
     excluded_vars.MoveFirst;
     while not excluded_vars.Blind do begin
        CloseLinkedRules(excluded_vars.Code, 0);
        DeleteVar(excluded_vars.Code);
        excluded_Vars.MoveNext;
     end;
  end;

  procedure DelValues;
  begin
     excluded_values.MoveFirst;
     while not excluded_values.Blind do begin
        CloseLinkedRules(excluded_values.Code, 1);
        DeleteValue(excluded_values.Code);
        excluded_values.MoveNext;
     end;
  end;

  procedure ChangeVars;
  begin
     modified_vars.MoveFirst;
     while not modified_vars.Blind do begin
       ExSys.Vars.Seek(modified_vars.Code);
       if not ExSys.Vars.Blind then begin
          VarsCopy.Seek(modified_vars.Code);
          ExSys.Vars.Name := VarsCopy.Name;
          ExSys.Vars.Multi := VarsCopy.Multi;
          ExSys.Vars.Numeric := VarsCopy.Numeric;
       end;
       modified_vars.MoveNext;
     end;
  end;

  procedure ChangeValues;
  begin
     modified_values.MoveFirst;
     while not modified_values.Blind do begin
       ExSys.Values.Seek(modified_values.Code);
       if not ExSys.Values.Blind then begin
          ValuesCopy.Seek(modified_values.Code);
          ExSys.Values.Name := ValuesCopy.Name;
          ExSys.Values.Position := ValuesCopy.Position;
       end;
       modified_values.MoveNext;
     end;
  end;

begin
   if save_it and (ExSys.Permission = TOTAL_PERMISSION) then begin
      {Grava nas árvores originais as modificações feitas}

      {Deleta as variáveis e valores necessários}
      if excluded_values.RecordCount > 0 then DelValues;
      if excluded_vars.RecordCount > 0 then DelVars;

      {Modifica as variáveis e valores necessários}
      if modified_vars.RecordCount > 0 then ChangeVars;
      if modified_values.RecordCount > 0 then ChangeValues;

      {Acrescenta as variáveis e valores necessários}
      included_vars.MoveFirst;
      while not included_vars.Blind do begin
         VarsCopy.Seek(included_vars.Code);
         if not VarsCopy.Blind then begin
            i := ExSys.Vars.GetFreeCode;
            ExSys.Vars.Insert(i, VarsCopy.Name, VarsCopy.Numeric, VarsCopy.Multi);
            ValuesCopy.SeekByVar(VarsCopy.Code);
            while (not ValuesCopy.Blind) and (ValuesCopy.VarCode = VarsCopy.Code)
            do begin
               j := ExSys.Values.GetFreeCode;
               included_values.Seek(ValuesCopy.Code);
               if not included_values.Blind then begin
                  ExSys.Values.Insert(j, ValuesCopy.Name, i, ValuesCopy.Position);
                  included_values.Delete;
                  included_values.Seek(VarsCopy.Code);
               end;
               ValuesCopy.MoveNext;
            end;
         end;
         included_vars.Delete;
         included_vars.MoveFirst;
      end;

      included_values.MoveFirst;
      while not included_values.Blind do begin
         ValuesCopy.Seek(included_values.Code);
         if not ValuesCopy.Blind then begin
            j := ExSys.Values.GetFreeCode;
            ExSys.Values.Insert(j, ValuesCopy.name, ValuesCopy.VarCode,
                                ValuesCopy.position);
         end;
         included_values.Delete;
         included_values.MoveFirst;
      end;

      {se a árvore de variáveis estiver vazia, desabilita edição de regras}
      if ExSys.Vars.RecordCount = 0 then begin
         frmBase.DisableRulesEdition;
         frmBase.btnNewRule.Enabled := false;
      end
      else begin
         frmBase.btnNewRule.Enabled := true;
         if frmBase.listRules.Items.Count > 0 then
            frmBase.EnableRulesEdition;
      end;
      cursor := crDefault;
      dialogEditRule.FillCombos;
      frmBase.save_me := true;
   end;

   if save_it and (ExSys.Permission <> TOTAL_PERMISSION) then
      MessageDlg('Lembre-se de que você não tem permissão para alterar ' +
                 'esta base de conhecimento!', mtInformation, [mbOk], 0);

   var_opened := false;
   Action := caFree;
end;

procedure TfrmVars.FormDestroy(Sender: TObject);
begin
   modified_vars.Free;
   modified_values.Free;
   included_vars.Free;
   included_values.Free;
   excluded_vars.Free;
   excluded_values.Free;
   ValuesCopy.Free;
   VarsCopy.Free;
end;

{======================================================================
 ======================================================================
                   BOTÕES DE EDIÇÃO DE VARIÁVEIS/VALORES
 ======================================================================
 ======================================================================}

procedure TfrmVars.btnNewVarClick(Sender: TObject);
begin
    btnDelVar.Enabled := False;
    btnNewValue.Enabled := False;
    btnDelValue.Enabled := False;
    editVar.Text := '';
    editValue.Text := '';
    editValue.Enabled := false;
    labelValue.Font.Color := clGray;
    btnValueAccept.Enabled := false;
    btnValueCancel.Enabled := false;
    optionNumeric.Enabled := False;
    optionMulti.Enabled := False;
    optionUni.Enabled := False;
    if not editVar.Enabled then begin
       editVar.Enabled := True;
       btnVarAccept.Enabled := True;
       btnVarCancel.Enabled := True;
       labelVar.Font.Color := clBlack;
    end;
    insert_mode := True;
    editVar.SetFocus;
end;

procedure TfrmVars.btnNewValueClick(Sender: TObject);
begin
    editValue.Text := '';
    insert_mode := True;
    if not editValue.Enabled then begin
       editValue.Enabled := True;
       btnValueAccept.Enabled := True;
       btnValueCancel.Enabled := True;
       labelValue.Font.Color := clBlack;
    end;
    editValue.SetFocus;
end;

{Essa funcção verifica se um determinado valor ou variável a ser deletado
 está presente em alguma regra}
function TfrmVars.VerifyRule(v: integer; tp: integer): integer;
var
  r1, r2: integer;

begin
   r1 := 0;
   r2 := 0;

   ExSys.Heads.MoveFirst;
   while (not ExSys.Heads.Blind) and (r1 = 0) do begin
      case tp of
         0: {variável}
            if ExSys.Heads.VarCode = v then r1 := ExSys.Heads.Code;
         1: {valor}
            if ExSys.Heads.ValCode = v then r1 := ExSys.Heads.Code;
      end;
      ExSys.Heads.MoveNext;
   end;

   ExSys.Tails.MoveFirst;
   while (not ExSys.Tails.Blind) and (r2 = 0) do begin
      case tp of
         0: {variável}
            if ExSys.Tails.VarCode = v then r2 := ExSys.Tails.Code;
         1: {valor}
            if ExSys.Tails.ValCode = v then r2 := ExSys.Tails.Code;
      end;
      ExSys.Tails.MoveNext;
   end;

   if (r1 <= r2) and (r1 <> 0) then
      Result := r1
   else begin
      if (r2 <= r1) and (r2 <> 0) then
         Result := r2
      else begin
         if r1 <> 0 then
            Result := r1
         else
            Result := r2
      end;
   end;
end;

procedure TfrmVars.btnDelVarClick(Sender: TObject);
var
   v: string;
   r, cod, cont: integer;
   continue: boolean;
begin
    V := listVars.Items[listVars.ItemIndex];
    VarsCopy.SeekByName(V);
    cod := VarsCopy.Code;
    r := VerifyRule(cod, 0);
    continue := True;
    if r > 0 then begin
       ExSys.Rules.Seek(r);
       if MessageDlg('Atenção! A regra ' + IntToStr(ExSys.Rules.Position)
           + ' (' + ExSys.Rules.Name + ') utiliza essa variável.' +
           'Apagar essa variável apagará essa regra bem como todas as que estão em mesmas condições. Continuar?',
           mtConfirmation, [mbYes, mbNo], 0) = mrNo then
          continue := False;
    end;
    if continue then begin
       {Inclui a modificação na lista de modificações}
       VarsCopy.Delete;
       included_vars.Seek(cod);
       if not included_vars.Blind then
         {Se a variável foi encontrada na lista de variáveis
          incluídas, é porque ela foi incluída agora}
          included_vars.Delete
       else begin
          ExSys.Vars.Seek(cod);
          excluded_vars.Insert(cod);
       end;
       cont := listVars.ItemIndex;
       listVars.Items.Delete(cont);
       if listVars.Items.Count > 0 then begin
          if cont > 0 then
             listVars.ItemIndex := cont - 1
          else
             listVars.ItemIndex := 0;
       end
       else begin
          optionNumeric.Enabled := False;
          optionMulti.Enabled := False;
          optionUni.Enabled := False;
          btnVarAccept.Enabled := false;
          btnVarCancel.Enabled := false;
          btnValueAccept.Enabled := false;
          btnValueCancel.Enabled := false;
          editVar.Enabled := False;
          editVar.Text := '';
          labelVar.Font.Color := clGray;
          editValue.Enabled := False;
          editValue.Text := '';
          labelValue.Font.Color := clGray;
          btnDelVar.Enabled := False;
          btnNewValue.Enabled := False;
       end;
       listValues.Clear;
       if listVars.ItemIndex <> -1 then listVarsClick(Sender);
       {Os valores ligados às variáveis são excluídos durante a atualização
        das árvores (botão OK)}
    end;
end;

procedure TfrmVars.btnDelValueClick(Sender: TObject);
var
   cod, cont, r, i: integer;
   aux: string;
   continue: boolean;
   bookmark: TMetaNode;
begin
    aux := listValues.Items[listValues.ItemIndex];
    ValuesCopy.SeekByName(aux, current_var);
    cod := ValuesCopy.Code;
    bookmark := ValuesCopy.CurrentNodeName;
    r := VerifyRule(cod, 1);
    continue := true;
    if r > 0 then begin
       ExSys.Rules.Seek(r);
       if MessageDlg('Atenção! A regra ' + IntToStr(ExSys.Rules.Position)
           + ' (' + ExSys.Rules.Name + ') utiliza esse valor. ' +
           'Apagar esse valor apagará essa regra bem como todas as que estão em mesmas condições. Continuar?',
           mtConfirmation, [mbYes, mbNo], 0) = mrNo then
          continue := False;
    end;
    if continue then begin
       {Inclui a modificação na lista de modificações}
       for i := listValues.ItemIndex + 1 to listValues.Items.Count - 1 do begin
          ValuesCopy.SeekByName(listValues.Items[i], current_var);
          ValuesCopy.position := i;
          cod := ValuesCopy.Code;
          modified_values.Seek(cod);
          if modified_values.Blind then modified_values.Insert(cod);
       end;
       ValuesCopy.CurrentNodeName := bookmark; {Repetição necessária}
       cod := ValuesCopy.Code;
       ValuesCopy.Delete;
       included_values.Seek(cod);
       if not included_values.Blind then
         {Se encontrar o item em included_values, é porque ele
          foi inserido agora}
          included_values.Delete
       else begin
          ExSys.Values.Seek(cod);
          excluded_values.Insert(cod);
       end;
       cont := listValues.ItemIndex;
       listValues.Items.Delete(listValues.ItemIndex);
       if listValues.Items.Count > 0 then begin
          if cont > 0 then
             listValues.ItemIndex := cont - 1
          else
             listValues.ItemIndex := 0;
       end
       else
          btnDelValue.Enabled := false;
       if real_click then
          if listValues.ItemIndex = -1 then begin
             editValue.Enabled := False;
             btnValueAccept.Enabled := false;
             btnValueCancel.Enabled := false;
             labelValue.Font.Color := clGray;
          end
    end;
end;

{Métodos relativos aos botões de modificação de variáveis/valores}
procedure TfrmVars.btnValueCancelClick(Sender: TObject);
begin
   editValue.Text := val_name;
end;

procedure TfrmVars.btnVarCancelClick(Sender: TObject);
begin
   editVar.Text := var_name;
end;

procedure TfrmVars.btnVarAcceptClick(Sender: TObject);
begin
   if (editVar.Text <> '') and (editVar.Text <> var_name) then VarOperation;
end;

procedure TfrmVars.btnValueAcceptClick(Sender: TObject);
begin
   if (editValue.Text <> '') and (editValue.Text <> val_name) then ValOperation;
end;

procedure TfrmVars.VarOperation;
var
  v: string[100];
  cod: integer;
  error: boolean;
begin
   editVar.Text := ExcludeBlankSpaces(editVar.Text);
   v := editVar.Text;
   error := false;
   {Verifica erros}
   if insert_mode and (listVars.Items.IndexOf(v) <> -1) then begin
      MessageDlg('Você não pode incluir variáveis com nomes iguais!',
         mtWarning, [mbOk], 0);
      error := true;
      editVar.SetFocus;
   end
   else begin
      if pos('"', v) > 0 then begin
         MessageDlg('Não se pode utilizar aspas duplas no nome da variável!',
            mtWarning, [mbOk], 0);
         error := true;
         editVar.SetFocus;
      end
      else begin
         if v = '' then begin
            MessageDlg('O nome da variável não pode ser somente espaços em branco!',
              mtWarning, [mbOk], 0);
            error := true;
            editVar.SetFocus;
         end;
      end;
   end;
   {Agora inclui na lista a nova variável}
   if not error then begin
      var_name := editVar.Text;
      if not insert_mode then begin {Modifica variáveis}
         v := listVars.Items[listVars.ItemIndex];
         VarsCopy.SeekByName(v);
         cod := VarsCopy.Code;
         modified_vars.Seek(cod);
         if modified_vars.Blind then modified_vars.Insert(cod);
         listVars.Items[listVars.ItemIndex] := editVar.Text;
         listVars.ItemIndex := listVars.Items.IndexOf(editVar.Text);
         VarsCopy.name := editVar.Text;
      end
      else begin
         optionNumeric.Enabled := True;
         optionMulti.Enabled := True;
         optionUni.Enabled := True;
         if VarsCopy.RecordCount = 0 then
            cod := 1
         else begin
            VarsCopy.CurrentKey := PRIMARY_KEY;
            VarsCopy.MoveLast;
            cod := VarsCopy.Code + 1;
         end;
         VarsCopy.Insert(cod, editVar.Text, optionNumeric.Checked, optionMulti.Checked);
         current_var := cod;
         listValues.Clear;
         listVars.Items.Add(editVar.Text);
         {Seleciona a nova variável na lista}
         real_click := False; {Avisa que a caixa de listagem não foi clicada}
         listVars.ItemIndex := listVars.Items.IndexOf(editVar.Text);
         real_click := True;
         editValue.Enabled := True;
         btnValueAccept.Enabled := True;
         btnValueCancel.Enabled := True;
         labelValue.Font.Color := clBlack;
         {Inclui a variável na árvore de variáveis incluídas}
         included_vars.Insert(cod);
         btnNewValueClick(Self);
      end;
   end;
end;

procedure TfrmVars.ValOperation;
var
   aux, aux2: string[100];
   cod, cod2, position: integer;
   s: string;
   error: boolean;
begin
   editVar.Text := ExcludeBlankSpaces(editVar.Text);
   aux := ExcludeBlankSpaces(editValue.Text);
   error := false;
   if ((aux = YES_STRING) or (aux = NO_STRING)) and
      (MessageDlg('Você não precisa colocar valores se sua variável for do ' +
                 'tipo Sim/Não. Deseja continuar mesmo assim?', mtConfirmation,
                 [mbYes, mbNo], 0) = mrNo) then begin
      editValue.Text := '';
      Exit;
   end;
   position := listValues.Items.IndexOf(aux);
   {Verifica erros}
   if ((position <> -1) and insert_mode) or
      ((position <> -1) and (position <> listValues.ItemIndex) and (not insert_mode))
      then begin
      MessageDlg('Você não pode incluir valores com nomes iguais!',
         mtWarning, [mbOk], 0);
      editValue.SetFocus;
   end
   else begin
      if pos('"', aux) > 0 then begin
         MessageDlg('Não se pode utilizar aspas duplas no nome do valor!',
            mtWarning, [mbOk], 0);
         error := true;
         editValue.SetFocus;
      end
      else begin
         if aux = '' then begin
            MessageDlg('O nome do valor não pode ser somente espaços em branco!',
              mtWarning, [mbOk], 0);
            error := true;
            editValue.SetFocus;
         end;
      end;
   end;
   if not error then begin
      if not insert_mode then begin {Modifica valores}
         aux := listValues.Items[listValues.ItemIndex];
         if optionNumeric.Checked then begin
            aux2 := editValue.Text;
            if not ValidNumericNumber(aux2) then begin
               s := 'Você colocou um valor inaceitável de intervalo. Deixe os valores em branco ou ';
               s := s + 'coloque um intervalo do tipo "min;max"';
               MessageDlg(s, mtWarning, [mbOk] ,0);
               editValue.SetFocus;
               Abort;
            end;
         end;
         val_name := editValue.Text;
         ValuesCopy.SeekByName(aux, current_var);
         cod2 := ValuesCopy.Code;
         modified_values.Seek(cod2);
         {Inclui a modificação na lista de modificações}
         if modified_values.Blind then modified_values.Insert(cod2);
         aux := editValue.Text;
         listValues.Items[listValues.ItemIndex] := aux;
         listValues.ItemIndex := listValues.Items.IndexOf(aux);
         ValuesCopy.name := aux;
      end
      else begin
         {Inclui novo valor}
         val_name := '';
         if (listValues.Items.Count > 0) and (optionNumeric.Checked = True) then begin
            MessageDlg('Você não pode incluir mais nenhum valor em uma variável numérica!',
               mtWarning, [mbOk], 0);
            editValue.Text := '';
            Abort;
         end
         else begin
            if optionNumeric.Checked then
               if not ValidNumericNumber(aux) then begin
                  s := 'Você colocou um valor inaceitável de intervalo. Deixe os valores em branco ou ';
                  s := s + 'coloque um intervalo do tipo "min;max"';
                  MessageDlg(s, mtWarning, [mbOk] ,0);
                  editValue.SetFocus;
                  Abort
               end;
         end;
         if ValuesCopy.RecordCount = 0 then
            cod := 1
         else begin
            ValuesCopy.CurrentKey := PRIMARY_KEY;
            ValuesCopy.MoveLast;
            cod := ValuesCopy.Code + 1;
         end;
         listValues.Items.Add(editValue.Text);
         listValues.ItemIndex := listValues.Items.IndexOf(aux);
         ValuesCopy.Insert(cod, editValue.Text, current_var, listValues.Items.Count);
         editValue.Text := '';
         {Inclui o valor no vetor de valores incluídos}
         included_values.Insert(cod);
      end;
   end;
end;

{======================================================================
 ======================================================================
                  MÉTODOS RELATIVOS ÀS ÁRVORES TEMPORÁRIAS
 ======================================================================
 ======================================================================}

procedure TfrmVars.InitializeTrees;
begin
   included_vars := TSingleIndexTree.Create;
   modified_vars := TSingleIndexTree.Create;
   excluded_vars := TSingleIndexTree.Create;
   included_values := TSingleIndexTree.Create;
   modified_values := TSingleIndexTree.Create;
   excluded_values := TSingleIndexTree.Create;
   VarsCopy := TVars.Create;
   ValuesCopy := TValues.Create;
end;

procedure TfrmVars.FillTrees;
var
   i, j, max, total: integer;
   current_node_1, current_node_2: TMetaNode;
   node: TNode;
begin
   {Cria uma cópia balanceada de Vars}
   if ExSys.Vars.RecordCount > 1 then
      max := 1
   else
      max := ExSys.Vars.RecordCount - 1;
   ExSys.Vars.CurrentKey := PRIMARY_KEY;
   for j := 0 to max do begin
      ExSys.Vars.MoveFirst;
      if j = 0 then
         total := ExSys.Vars.RecordCount div 2
      else
         total := (ExSys.Vars.RecordCount div 2) - 1;
      for i := 1 to total do ExSys.Vars.MoveNext;
      current_node_1 := ExSys.Vars.CurrentNode;
      if current_node_1 <> nil then begin
         current_node_2 := ExSys.Vars.CurrentNode.Next;
         if current_node_2 <> nil then current_node_2 := current_node_2.Next;
      end
      else
         current_node_2 := nil;
      while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
         if current_node_1 <> nil then begin
            node := current_node_1.node;
            VarsCopy.Insert(node.Code, TVarNode(node).Name,
               TVarNode(node).Numeric, TVarNode(node).Multi);
            current_node_1 := current_node_1.Previous;
            if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
         end;
         if current_node_2 <> nil then begin
            node := current_node_2.node;
            VarsCopy.Insert(node.Code, TVarNode(node).Name,
               TVarNode(node).Numeric, TVarNode(node).Multi);
            current_node_2 := current_node_2.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end;
      end;
   end;
   {Cria uma cópia balanceada de Values}
   if ExSys.Values.RecordCount > 1 then
      max := 1
   else
      max := ExSys.Values.RecordCount - 1;
   ExSys.Values.CurrentKey := PRIMARY_KEY;
   for j := 0 to max do begin
      ExSys.Values.MoveFirst;
      if j = 0 then
         total := ExSys.Values.RecordCount div 2
      else
         total := (ExSys.Values.RecordCount div 2) - 1;
      for i := 1 to total do ExSys.Values.MoveNext;
      current_node_1 := ExSys.Values.CurrentNode;
      if current_node_1 <> nil then begin
         current_node_2 := ExSys.Values.CurrentNode.Next;
         if current_node_2 <> nil then current_node_2 := current_node_2.Next;
      end
      else
         current_node_2 := nil;
      while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
         if current_node_1 <> nil then begin
            node := current_node_1.node;
            ValuesCopy.Insert(node.Code, TValNode(node).Name,
                              TValNode(node).VarCode, TValNode(node).Position);
            current_node_1 := current_node_1.Previous;
            if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
         end;
         if current_node_2 <> nil then begin
            node := current_node_2.node;
            ValuesCopy.Insert(node.Code, TValNode(node).Name,
                              TValNode(node).VarCode, TValNode(node).Position);
            current_node_2 := current_node_2.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end;
      end;
   end;
end;

{======================================================================
 ======================================================================
                  MÉTODOS RELATIVOS ÀS LISTBOXES
 ======================================================================
 ======================================================================}

procedure TfrmVars.FillList;
begin
   ExSys.Vars.MoveFirst;
   while not ExSys.Vars.Blind do begin
      listVars.Items.Add(ExSys.Vars.name);
      ExSys.Vars.MoveNext;
   end;
   listVars.ItemIndex := -1;
end;

procedure TfrmVars.listVarsClick(Sender: TObject);
var
   current_pos, compare_pos: integer;
   continue: boolean;
begin
   if real_click then begin
      insert_mode := False;
      VarsCopy.SeekByName(listVars.Items[listVars.ItemIndex]);
      current_var := VarsCopy.Code;
      if listVars.ItemIndex <> -1 then begin
         if optionNumeric.Enabled = False then begin
            optionNumeric.Enabled := True;
            optionMulti.Enabled := True;
            optionUni.Enabled := True;
         end;
         listValues.Clear;
         btnNewVar.Enabled := True;
         btnDelVar.Enabled := True;
         btnNewValue.Enabled := True;
         btnDelValue.Enabled := False;
         labelVar.Font.Color := clBlack;
         editVar.Enabled := True;
         btnVarAccept.Enabled := True;
         btnVarCancel.Enabled := True;
         labelValue.Font.Color := clGray;
         editValue.Enabled := False;
         btnValueAccept.Enabled := False;
         btnValueCancel.Enabled := False;
         editValue.Text := '';
         ValuesCopy.SeekByVar(current_var);
         while (not ValuesCopy.Blind) and (ValuesCopy.VarCode = current_var) do begin
            current_pos := ValuesCopy.Position;
            compare_pos := 0;
            continue := true;
            while (compare_pos < listValues.Items.Count) and continue do begin
                ValuesCopy.SeekByName(listValues.Items[compare_pos], current_var);
                if ValuesCopy.Position > current_pos then continue := false;
                if (compare_pos < listValues.Items.Count) and continue then
                    inc(compare_pos);
            end;
            ValuesCopy.CurrentKey := BY_VAR; {Devolve o ponteiro à posição
                                                 certa}
            listValues.Items.Insert(compare_pos, ValuesCopy.Name);
            ValuesCopy.MoveNext;
         end;
         editVar.Text := listVars.Items[listVars.ItemIndex];
         var_name := editVar.Text;
         if VarsCopy.Multi then begin
            real_click := false;
            optionMulti.Checked := True;
            real_click := true;
            if labelValue.Caption = 'Intervalo:' then begin
               labelValue.Caption := 'Valor:';
               labelValues.Caption := 'Valores';
            end;
         end
         else begin
            if VarsCopy.Numeric = False then begin
               real_click := false;
               optionUni.Checked := True;
               real_click := true;
               if labelValue.Caption = 'Intervalo:' then begin
                  labelValue.Caption := 'Valor:';
                  labelValues.Caption := 'Valores';
               end;
            end
            else begin
               real_click := false;
               optionNumeric.Checked := True;
               real_click := true;
               if labelValue.Caption = 'Valor:' then begin
                  labelValue.Caption := 'Intervalo:';
                  labelValues.Caption := 'Intervalo';
               end;
            end;
         end;
      end;
   end;
end;

procedure TfrmVars.listValuesClick(Sender: TObject);
begin
   if real_click then begin
      insert_mode := False;
      btnNewVar.Enabled := True;
      btnDelVar.Enabled := True;
      btnNewValue.Enabled := True;
      btnDelValue.Enabled := True;
      editValue.Text := listValues.Items[listValues.ItemIndex];
      val_name := editValue.Text;
      editValue.Enabled := True;
      btnValueAccept.Enabled := True;
      btnValueCancel.Enabled := True;
      labelValue.Font.Color := clBlack;
   end;
end;

procedure TfrmVars.listValuesMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DragItem: Integer;
begin
  if Button = mbLeft then begin
     DragItem := listValues.ItemAtPos(Point(X, Y), False);
     if (DragItem > -1) and (DragItem < listValues.Items.Count) then
        listValues.BeginDrag(False);
  end;
end;

procedure TfrmVars.listValuesDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  DropPos: Integer;
begin
  if Source = listValues then begin
     DropPos := listValues.ItemAtPos(Point(X, Y), False);
     Accept := (DropPos > -1) and (DropPos <> listValues.ItemIndex) and
       (DropPos < listValues.Items.Count);
  end
    else Accept := False;
end;

procedure TfrmVars.listValuesDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  OldPos, NewPos: integer;
  old: string;
  cod, i: integer;
begin
  if Source = listValues then begin
     OldPos := listValues.ItemIndex;
     NewPos := listValues.ItemAtPos(Point(X, Y), False);
     if (NewPos > -1) and (NewPos <> OldPos) then begin
        old := listValues.Items[OldPos];
        ValuesCopy.SeekByName(old, current_var);
        ValuesCopy.position := NewPos + 1;
        cod := ValuesCopy.Code;
        modified_values.Seek(cod);
        if modified_values.Blind then modified_values.Insert(cod);
        {Muda a posição de todos os outros valores}
        if NewPos < OldPos then
           for i := NewPos to OldPos - 1 do begin
              ValuesCopy.SeekByName(listValues.Items[i], current_var);
              ValuesCopy.Position := ValuesCopy.Position + 1;
              cod := ValuesCopy.Code;
              modified_values.Seek(cod);
              if modified_values.Blind then modified_values.Insert(cod);
           end
        else
           for i := OldPos + 1 to NewPos do begin
              ValuesCopy.SeekByName(listValues.Items[i], current_var);
              ValuesCopy.Position := ValuesCopy.Position - 1;
              cod := ValuesCopy.Code;
              modified_values.Seek(cod);
              if modified_values.Blind then modified_values.Insert(cod);
           end;
        listValues.Items.Delete(OldPos);
        listValues.Items.Insert(NewPos, old);
        listValues.ItemIndex := NewPos;
     end;
   end;
end;

procedure TfrmVars.listVarsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   If (Key = VK_DELETE) And (listVars.ItemIndex <> -1) Then btnDelVarClick(Sender);
end;

procedure TfrmVars.listValuesKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   If (Key = VK_DELETE) And (listValues.ItemIndex <> -1) Then btnDelValueClick(Sender);
end;

{======================================================================
 ======================================================================
                  MÉTODOS RELATIVOS ÀS EDITBOXES
 ======================================================================
 ======================================================================}

procedure TfrmVars.editVarEnter(Sender: TObject);
begin
   editVar.SelectAll;
   var_name := EditVar.Text
end;

procedure TfrmVars.editVarKeyPress(Sender: TObject; var Key: Char);
begin
    Case Key of
      chr(13):
          if (editVar.Text <> '') and (editVar.Text <> var_name) then begin
             Key := chr(0);
             VarOperation;
          end;
      chr(27):
        begin
          Key := chr(0);
          btnVarCancelClick(Sender);
        end;
    End
end;

procedure TfrmVars.editValueEnter(Sender: TObject);
begin
   editValue.SelectAll;
   val_name := editValue.Text;
end;

procedure TfrmVars.editValueKeyPress(Sender: TObject; var Key: Char);
begin
    case Key of
       chr(13):
          if (editValue.Text <> '') and (editValue.Text <> val_name) then begin
             Key := chr(0);
             ValOperation;
          end;
       chr(27):
         begin
          Key := chr(0);
          btnValueCancelClick(Self);
         end;
    end;
end;

procedure TfrmVars.UpdateValues(Sender: TObject);
begin
   If (editVar.Text <> '') And (editVar.Text <> var_name) then
      VarOperation;
   If (editValue.Text <> '') And (editValue.Text <> val_name) then
      ValOperation;
end;

{======================================================================
 ======================================================================
                  MÉTODOS RELATIVOS AOS RADIOBUTTONS
 ======================================================================
 ======================================================================}

procedure TfrmVars.optionNumericClick(Sender: TObject);
var
   delete_values, changed: boolean;
   resp: Word;
   aux, V: string;
begin
    {Obs.: variáveis numéricas são consideradas como sendo
     sempre univaloradas.}
    if not real_click then Exit;
    if listVars.ItemIndex = -1 then
       MessageDlg('É necessário ter alguma variável selecionada!',
         mtInformation, [mbOk], 0)
    else begin
       delete_values := False;
       resp := mrYes;
       V := listVars.Items[listVars.ItemIndex];
       VarsCopy.SeekByName(V);
       if VarsCopy.numeric <> optionNumeric.Checked then
          changed := True
       else
          changed := False;
       if optionNumeric.Checked and changed then begin
          {Aqui, caso o usuário mude uma variável não-numérica para uma
           numérica, uma mensagem surge se os valores estão
           inválidos e que devem ser apagados}
          if (listValues.Items.Count <> 1) and (listValues.Items.Count <> 0) then begin
             resp := MessageDlg('Você irá apagar os valores existentes. Deseja continuar?',
                     mtConfirmation, [mbYes, mbNo], 0);
             delete_values := True;
          end
          else begin
             if listValues.Items.Count > 0 then
                aux := listValues.Items[0]
             else
                aux := ' ';
             if (listValues.Items.Count = 1) and (not ValidNumericNumber(aux)) then begin
                resp := MessageDlg('Você irá apagar o valor existente. Deseja continuar?',
                     mtConfirmation, [mbYes, mbNo], 0);
                delete_values := True;
             end;
          end;
       end;
       if resp = mrYes then begin
          if delete_values then begin
             real_click := false;
             while listValues.Items.Count > 0 do begin
                listValues.ItemIndex := 0;
                btnDelValueClick(Sender);
             end;
             real_click := true;
          end;
          if changed then begin
             {Inclui a modificação na lista de modificações}
             modified_vars.Seek(VarsCopy.Code);
             if modified_vars.Blind then modified_vars.Insert(VarsCopy.Code);
             VarsCopy.Numeric := optionNumeric.Checked;
             if optionNumeric.Checked = True then optionMultiClick(Sender);
             labelValue.Caption := 'Intervalo:';
             labelValues.Caption := 'Intervalo';
             editVar.SetFocus;
             editVar.SelectAll;
          end;
       end
       else begin
          optionNumeric.Checked := False;
          optionMulti.Checked := VarsCopy.Multi;
          optionUni.Checked := not VarsCopy.Multi;
       end;
    end;
end;

procedure TfrmVars.optionMultiClick(Sender: TObject);
var
   V: string;
   changed: boolean;
begin
    if not real_click then Exit;
    if listVars.ItemIndex = -1 then begin
       MessageDlg('É necessário ter alguma variável selecionada!',
                   mtInformation, [mbOk], 0);
       Exit;
    end;
    V := listVars.Items[listVars.ItemIndex];
    VarsCopy.SeekByName(V);
    if VarsCopy.Multi <> optionMulti.checked then
       changed := True
    else
       changed := False;
    VarsCopy.Multi := optionMulti.Checked;
    if optionMulti.Checked then optionNumericClick(Sender);
    if changed then begin
       modified_vars.Seek(VarsCopy.Code);
       {Inclui a modificação na lista de modificações}
       if modified_vars.Blind then modified_vars.Insert(VarsCopy.Code);
       if labelValue.Caption <> 'Valor:' then begin
          labelValue.Caption := 'Valor:';
          labelValues.Caption := 'Valores';
       end;
       editVar.SetFocus;
       editVar.SelectAll;
    end;
end;

procedure TfrmVars.optionUniClick(Sender: TObject);
var
   V: string;
begin
    if not real_click then Exit;
    if listVars.ItemIndex = -1 then
       MessageDlg('É necessário ter alguma variável selecionada!',
          mtInformation, [mbOk], 0)
    else begin
       V := listVars.Items[listVars.ItemIndex];
       VarsCopy.SeekByName(V);
       if optionUni.Checked then begin
          optionNumericClick(Sender);
          optionMultiClick(Sender);
          VarsCopy.numeric := false;
          if labelValue.Caption <> 'Valor:' then begin
             labelValue.Caption := 'Valor:';
             labelValues.Caption := 'Valores';
          end;
       end;
   end;
end;

{======================================================================
 ======================================================================
             MÉTODOS RELATIVOS AOS BOTÕES DE FECHAMENTO DA JANELA
 ======================================================================
 ======================================================================}

procedure TfrmVars.btnOkClick(Sender: TObject);
begin
   save_it := true;
   Close;
end;

procedure TfrmVars.btnCancelClick(Sender: TObject);
begin
   save_it := false;
   Close;
end;

procedure TfrmVars.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
   aux: string;
begin
   if save_it then begin
     aux := 'Por favor, feche-a antes de atualizar as variáveis.';
     if target_opened then begin
        MessageDlg('A janela de definição de objetivos está aberta. '
                    + aux, mtInformation, [mbOk], 0);
        CanClose := false;
     end;
     if question_opened then begin
        MessageDlg('A janela de criação de perguntas está aberta. '
                   + aux, mtInformation, [mbOk], 0);
        CanClose := false;
     end;
     if info_opened then begin
        MessageDlg('A janela de informações gerais está aberta. '
                   + aux, mtInformation, [mbOk], 0);
        CanClose := false;
     end;
  end;
end;

{======================================================================
 ======================================================================
                           FUNÇÕES DE USO GERAL
 ======================================================================
 ======================================================================}

function TfrmVars.ValidNumericNumber(expression: string): boolean;
var
   num1, num2: real;
   size, pos_point: integer;

   function IsNumeric(s: string): boolean;
   begin
      Result := (FloatToStr(StrToFloat(s)) = s);
   end;

begin
   {Analisa se uma expressão é aceitável em termos de intervalo (sempre no
    formato "num1;num2" ou ";num1" ou "num2;", num1 < num2).}
   size := length(expression);
   pos_point := Pos(';', expression);
   if (pos_point = 0) or (expression = ';') then
      Result := False
   else begin
      if (pos_point > 1) and (pos_point < size) then begin
         if IsNumeric(Copy(expression, 1, pos_point - 1)) and
            IsNumeric(Copy(expression, pos_point + 1, length(expression))) then begin
              num1 := StrToFloat(Copy(expression, 1, pos_point - 1));
              num2 := StrToFloat(Copy(expression, pos_point + 1, length(expression)));
              {Só aceita se o intervalo estiver na ordem do menor para
               o maior.}
              Result := (num1 < num2);
         end
         else
            Result := False
      end
      else begin
         if pos_point = 1 then
            Result := IsNumeric(Copy(expression, 2, length(expression)))
         else
            {pos_point será igual a size}
            Result := IsNumeric(Copy(expression, 1, size - 1));
      end;
   end;
end;

end.
