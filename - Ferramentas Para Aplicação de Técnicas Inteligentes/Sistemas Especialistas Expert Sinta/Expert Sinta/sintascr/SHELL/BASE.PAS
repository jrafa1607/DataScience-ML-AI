{===========================================
 UNIDADE/FORMULÁRIO da base de conhecimentos
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Silvestre
 Descrição: Janela gerenciadora do editor de
            bases de conhecimento.
 Data de início: 23 de dezembro de 1995
 Data de término: 18 de janeiro de 1996
 Última modificação: 17 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ===========================================}

unit Base;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls;

type
  TfrmBase = class(TForm)
    btnNewRule: TButton;
    btnOpenRule: TButton;
    btnDelete: TButton;
    btnView: TButton;
    btnVars: TButton;
    btnQuestions: TButton;
    btnTargets: TButton;
    btnInfo: TButton;
    btnClose: TButton;
    listRules: TListBox;
    labelSINTA: TLabel;
    labelBack: TLabel;
    procedure FormResize(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    {$IFDEF WINDOWS}
      {$R CURSOR.RES}
    {$ELSE}
      {$R CURSOR32.RES}
    {$ENDIF}
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnVarsClick(Sender: TObject);
    procedure listRulesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure listRulesDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure listRulesDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure btnNewRuleClick(Sender: TObject);
    procedure btnOpenRuleClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnTargetsClick(Sender: TObject);
    procedure btnViewClick(Sender: TObject);
    procedure btnInfoClick(Sender: TObject);
    procedure btnQuestionsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure listRulesDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure listRulesClick(Sender: TObject);
  private
    procedure DefinePos;
    procedure DisableBase;
  public
    save_me, dont_close_me: boolean;
    procedure FillRules;
    procedure ArrangeListRules(p0, pf: integer);
    procedure ArrangeRulesOnDelete(p0: integer);
    procedure DisableRulesEdition;
    procedure EnableRulesEdition;
  end;

var
  frmBase: TfrmBase;

implementation

uses
   General, Main, NewRule, RuleCode, VarsCode, TargCode,
   DlgView, ViewCode, InfoCode, AskCode, ExConsts, ExDataSt;

{$R *.DFM}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}

procedure TfrmBase.FormCreate(Sender: TObject);
begin
   ExSys.ClearBase;
   loaded_rules := TStringList.Create;
   var_opened := false;
   target_opened := false;
   question_opened := false;
   info_opened := false;
   save_me := false;
   base_opened := true;
   Width := 336;
   Height := 331;
   labelSINTA.Left := labelBack.Left +
                      trunc((labelBack.Width - labelSINTA.Width) / 2);
   labelSINTA.Top := labelBack.Top +
                      trunc((labelBack.Height - labelSINTA.Height) / 2);
   Screen.Cursors[1] := LoadCursor(hInstance, 'DRAG_RULE');
   with frmMain do begin
      mnuEdit.Visible := true;
      mnuExecute.Visible := true;
      mnuDebug.Visible := true;
      mnuWindow.Visible := true;
      mnuSystem.Visible := true;
      lineOptions.Visible := true;
      mnuOptions.Visible := true;
      mnuOptions.Enabled := true;
   end;
   listRules.DragCursor := 1;
   DefinePos;
   FormResize(Sender);
end;

procedure TfrmBase.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
   answer: Word;
begin
   dont_close_me := false;
   if save_me then begin
      answer := MessageDlg('Salvar as modificações feitas?', mtConfirmation,
                [mbYes, mbNo, mbCancel], 0);
      case answer of
         mrYes:
            begin
               frmMain.btnSaveClick(Sender);
               CanClose := not dont_close_me;
            end;
         mrCancel: CanClose := false;
      end;
   end;
end;

procedure TfrmBase.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Action := caFree;
   loaded_rules.Free;
   with frmMain do begin
      mnuEdit.Visible := false;
      mnuExecute.Visible := false;
      mnuDebug.Visible := false;
      mnuWindow.Visible := false;
      mnuSystem.Visible := false;
      lineOptions.Visible := false;
      mnuOptions.Visible := false;
      mnuOptions.Enabled := false;
      mnuPrint.Enabled := false;
      mnuExport.Enabled := false;
      btnOpenRule.Hint := 'Abrir Regra ' + IntToStr(listRules.ItemIndex + 1)
             + '|Abre uma regra selecionada para edição.';
      btnDelete.Hint := 'Excluir Regra ' + IntToStr(listRules.ItemIndex + 1)
             + '|Exclui a regra selecionada na lista.';
   end;
   WriteLastUsedFile;
   DisableBase;
   base_opened := false;
end;

{======================================================================
 ======================================================================
                REDIMENSIONAMENTO E POSICIONAMENTO DA JANELA
 ======================================================================
 ======================================================================}

procedure TfrmBase.FormResize(Sender: TObject);
begin
  try
    listRules.Width := Width - 5 * btnNewRule.Left - btnNewRule.Width;
    listRules.Height := Height - 5 * listRules.Top;
  finally
  end;
end;

procedure TfrmBase.DefinePos;
begin
   Left := 0;
   Top := 0;
end;

{======================================================================
 ======================================================================
                       GERÊNCIA DA LISTA DE REGRAS
 ======================================================================
 ======================================================================}

procedure TfrmBase.FillRules;
begin
   ExSys.Rules.CurrentKey := BY_POSITION;
   ExSys.Rules.MoveFirst;
   listRules.Clear;
   while not ExSys.Rules.Blind do begin
       listRules.Items.AddObject('REGRA  ' +
         IntToStr(ExSys.Rules.Position) + '     ' +
         ExSys.Rules.Name, TValNode(ExSys.Rules.CurrentNodeVar.Node));
       ExSys.Rules.MoveNext;
   end;
end;

procedure TfrmBase.ArrangeListRules(p0, pf: integer);
var
   i: integer;
begin
   ExSys.Rules.SeekByVar(p0 + 1);
   for i := p0 to pf do begin
       listRules.Items[i] := 'REGRA  ' + IntToStr(ExSys.Rules.Position) +
                             '     ' + ExSys.Rules.Name;
       listRules.Items.Objects[i] := TValNode(ExSys.Rules.CurrentNodeVar.Node);
       ExSys.Rules.MoveNext;
   end;
end;

procedure TfrmBase.ArrangeRulesOnDelete(p0: integer);
var
   total, i: integer;
begin
   total := listRules.Items.Count - 1;
   ExSys.Rules.SeekByVar(p0 + 1);
   for i := p0 to total do begin
       listRules.Items[i] := 'REGRA  ' + IntToStr(ExSys.Rules.Position) +
                             '     ' + ExSys.Rules.Name;
       ExSys.Rules.MoveNext;
   end;
end;

procedure TfrmBase.listRulesMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DragItem: Integer;
begin
  if Button = mbLeft then begin
    DragItem := listRules.ItemAtPos(Point(X, Y), False);
    if (DragItem > -1) and (DragItem < listRules.Items.Count) then
       listRules.BeginDrag(False);
  end;
end;

procedure TfrmBase.listRulesDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  DropPos: Integer;
begin
  if Source = listRules then begin
    DropPos := listRules.ItemAtPos(Point(X, Y), False);
    Accept := (DropPos > -1) and (DropPos <> listRules.ItemIndex) and
      (DropPos < listRules.Items.Count);
  end
    else Accept := False;
end;

procedure TfrmBase.listRulesDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  OldPos, NewPos, code: Integer;
  name: string;
begin
  if Source = listRules then begin
     if ExSys.Permission <> TOTAL_PERMISSION then
        MessageDlg('Lembre-se de que você não tem permissão para alterar essa ' +
                   'base de conhecimento!', mtInformation, [mbOk], 0)
     else begin
        OldPos := listRules.ItemIndex + 1;
        NewPos := listRules.ItemAtPos(Point(X, Y), False) + 1;
        if (NewPos > -1) and (NewPos <> OldPos) then begin
           {MUDAR A ORDEM DAS REGRAS}
           code := TValNode(listRules.Items.Objects[OldPos - 1]).code;
           name := TValNode(listRules.Items.Objects[OldPos - 1]).name;
           ExSys.Rules.Seek(code);
           ExSys.Rules.Delete;
           if NewPos < OldPos then
              DefinePositions(NewPos, 1, OldPos - 1)
           else
              DefinePositions(OldPos + 1, -1, NewPos);
           ExSys.Rules.Insert(code, name, NewPos, 0);
           if NewPos < OldPos then
              ArrangeListRules(NewPos - 1, OldPos - 1)
           else
              ArrangeListRules(OldPos - 1, NewPos - 1);
           listRules.ItemIndex := NewPos - 1;
           save_me := true;
        end;
     end;
   end;
end;

procedure TfrmBase.listRulesDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
   p: integer;
   aux: string;
begin
   with listRules do begin
      Canvas.FillRect(Rect);
      aux := Items[Index];
      p := Pos(' ', Items[Index]);
      aux := Copy(aux, p + 1 , Length(aux));
      p := Pos(' ', Copy(Items[Index], p + 2 , Length(Items[Index]))) + p + 2;
      if odSelected in State then
         Canvas.Font.Color := clWhite
      else
         Canvas.Font.Color := clNavy;
      Canvas.TextOut(Rect.Left, Rect.Top, Copy(Items[Index], 1, p));
      if odSelected in State then
         Canvas.Font.Color := clWhite
      else
         Canvas.Font.Color := clBlack;
      Canvas.TextOut(Rect.Left + Canvas.TextWidth('M') * 7,
         Rect.Top, Copy(Items[Index], p, Length(Items[Index])));
   end;
end;

procedure TfrmBase.listRulesClick(Sender: TObject);
begin
   frmMain.btnOpenRule.Hint := 'Abrir Regra ' + IntToStr(listRules.ItemIndex + 1)
           + '|Abre uma regra selecionada para edição.';
   frmMain.btnDelete.Hint := 'Excluir Regra ' + IntToStr(listRules.ItemIndex + 1)
           + '|Exclui a regra selecionada na lista.';
end;

{======================================================================
 ======================================================================
                           BOTÕES DE COMANDO
 ======================================================================
 ======================================================================}

procedure TfrmBase.btnNewRuleClick(Sender: TObject);
var
   new_rule: TfrmRule;
   code: integer;
begin
   if dialogNewRule.ShowModal = mrOk then begin
      new_rule := TfrmRule.Create(Self);
      if dialogNewRule.comboModel.ItemIndex = 0 then
         new_rule.SetRule(0,
                          dialogNewRule.num_rule, 'sem nome',
                          true)
      else begin
         code := dialogNewRule.comboModel.Items.Count -
                 dialogNewRule.comboModel.ItemIndex;
         ExSys.Rules.SeekByVar(code); {Procura a regra que esteja na posição
                                       "code", não a de código "code"}
         code := ExSys.Rules.code;
         new_rule.SetRule(code,
                          dialogNewRule.num_rule, 'sem nome',
                          true);
      end;
      loaded_rules.AddObject(IntToStr(dialogNewRule.num_rule), new_rule);
   end;
end;

procedure TfrmBase.btnOpenRuleClick(Sender: TObject);
var
   new_rule: TfrmRule;
   code: string;
   position: integer;
begin
   code := IntToStr(TValNode(listRules.Items.Objects[listRules.ItemIndex]).code);
   position := loaded_rules.IndexOf(code);
   if position <> -1 then {Já havia uma janela aberta com essa regra}
      TfrmRule(loaded_rules.Objects[position]).Show
      {Não esquecer que cada item de 'loaded_rules' aponta para um
       formulário de regras, assim como cada item da lista 'listRules'
       aponta para um nó com as características da regra}
   else begin
      new_rule := TfrmRule.Create(Self);
      new_rule.SetRule(StrToInt(code),
         TValNode(listRules.Items.Objects[listRules.ItemIndex]).VarCode,
         TValNode(listRules.Items.Objects[listRules.ItemIndex]).Name,
         false);
         {OBS.: code_var representa a posição da regra}
      loaded_rules.AddObject(code, new_rule);
   end;
end;

procedure TfrmBase.btnDeleteClick(Sender: TObject);
var
  code, pos: integer;
  continue: boolean;
begin
    if (Sender is TButton) and ((Sender as TButton) = btnDelete) and
       (ExSys.Permission <> TOTAL_PERMISSION) then begin
       MessageDlg('Lembre-se de que você não tem permissão para alterar essa ' +
                  'base de conhecimento!', mtInformation, [mbOk], 0);
       continue := false;
    end
    else
       continue := true;
    if continue and (Sender is TButton) and ((Sender as TButton) = btnDelete) then begin
       if MessageDlg('Excluir regra?', mtConfirmation, [mbYes, mbNo], 0) =
          mrNo then continue := false;
    end;
    if continue then begin
       Screen.Cursor := crHourGlass;
       pos := listRules.ItemIndex;
       code := TValNode(listRules.Items.Objects[pos]).code;
       DeleteRule(code);
       if pos <> listRules.Items.Count - 1 then
          DefinePositions(pos + 2, -1, listRules.Items.Count);
       listRules.Items.Delete(pos);
       ArrangeListRules(pos, listRules.Items.Count - 1);
       ArrangeRulesOnDelete(pos);
       if listRules.Items.Count = 0 then
          DisableRulesEdition
       else begin
          if pos = 0 then
             listRules.ItemIndex := 0
          else
             listRules.ItemIndex := pos - 1;
       end;
       save_me := true;
       Screen.Cursor := crDefault;
    end;
end;

procedure TfrmBase.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if (Key = VK_DELETE) and (btnDelete.Enabled = true) then
      btnDeleteClick(btnDelete);
end;

procedure TfrmBase.btnViewClick(Sender: TObject);
var
   total, i: integer;
   frmView: TfrmView;
begin
   if dialogView.ShowModal = mrOk then begin
      if btnOpenRule.Enabled then ExSys.EmptyBase := false;
      frmView := TfrmView.Create(frmMain);
      {Filtra as regras}
      if dialogView.radioHeads.Checked then
         with frmView do begin
            total := dialogView.DstList.Items.Count - 1;
            RuleView.UseFilter := true;
            for i := 0 to total do begin
                ExSys.Vars.SeekByName(dialogView.DstList.Items[i]);
                RuleView.HeadFilter.Insert(ExSys.Vars.Code);
            end;
         end;
      frmView.RuleView.ExpertSystem := ExSys;
   end;
end;

procedure TfrmBase.btnVarsClick(Sender: TObject);
begin
   if not var_opened then begin
      frmVars := TfrmVars.Create(Self);
      var_opened := true;
   end;
end;

procedure TfrmBase.btnTargetsClick(Sender: TObject);
begin
   if not target_opened then begin
      frmTargets := TfrmTargets.Create(Self);
      target_opened := true;
   end;
end;

procedure TfrmBase.btnQuestionsClick(Sender: TObject);
begin
   if not question_opened then begin
      frmQuestions := TfrmQuestions.Create(Self);
      question_opened := true;
   end;
end;

procedure TfrmBase.btnInfoClick(Sender: TObject);
begin
   if not info_opened then begin
      frmInfos := TfrmInfos.Create(Self);
      info_opened := true;
   end;
end;

procedure TfrmBase.btnCloseClick(Sender: TObject);
begin
   Close;
end;

{======================================================================
 ======================================================================
               INIBIÇÃO/DESINIBIÇÃO DE ELEMENTOS DA INTERFACE 
 ======================================================================
 ======================================================================}

procedure TfrmBase.DisableBase;
begin
    frmMain.mnuSave.Enabled := False;
    frmMain.mnuSaveAs.Enabled := False;
    frmMain.btnStep.Enabled := False;
    frmMain.btnGo.Enabled := False;
    frmMain.mnuExecute.Enabled := False;
    frmMain.mnuWindow.Enabled := False;
    frmMain.mnuEdit.Enabled := False;
    frmMain.mnuDebug.Enabled := False;
    frmMain.btnSave.Enabled := False;
    frmMain.btnPrint.Enabled := False;
    frmMain.btnWatch.Enabled := False;
    frmMain.btnAddVars.Enabled := False;
    frmMain.DisableOwnButtons;
end;

procedure TfrmBase.DisableRulesEdition;
begin
    btnOpenRule.Enabled := false;
    btnView.Enabled := false;
    btnDelete.Enabled := false;
    frmMain.btnWatch.Enabled := false;
    frmMain.btnOpenRule.Enabled := false;
    frmMain.btnView.Enabled := false;
    frmMain.btnDelete.Enabled := false;
    frmMain.mnuExecute.Enabled := False;
    frmMain.mnuDebug.Enabled := False;
    frmMain.btnGo.Enabled := False;
    frmMain.btnStep.Enabled := False;
    frmMain.btnOpenRule.Hint := 'Abrir Regra|Abre uma regra selecionada para edição.';
    frmMain.btnDelete.Hint := 'Excluir Regra|Exclui a regra selecionada na lista.';
end;

procedure TfrmBase.EnableRulesEdition;
begin
    btnOpenRule.Enabled := true;
    btnView.Enabled := true;
    btnDelete.Enabled := true;
    frmMain.btnWatch.Enabled := true;
    frmMain.btnOpenRule.Enabled := true;
    frmMain.btnView.Enabled := true;
    frmMain.btnDelete.Enabled := true;
    frmMain.btnPrint.Enabled := true;
    frmMain.mnuExecute.Enabled := true;
    frmMain.mnuDebug.Enabled := true;
    frmMain.btnGo.Enabled := true;
    frmMain.btnStep.Enabled := true;
    listRules.ItemIndex := 0;
    frmMain.btnOpenRule.Hint := 'Abrir Regra 1'
           + '|Abre uma regra selecionada para edição.';
    frmMain.btnDelete.Hint := 'Excluir Regra 1'
           + '|Exclui a regra selecionada na lista.';
end;


end.
