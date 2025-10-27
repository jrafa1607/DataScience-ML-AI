{==========================================
 UNIDADE/FORMULÁRIO de criação de interface
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Este formulário limita-se à
            criação das perguntas que devem
            ser feitas ao usuário quando se
            fazem necessárias.
 Data de início: 12 de janeiro de 1996
 Data de término: 12 de janeiro de 1996
 Última modificação: 07 de setembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ==========================================}
unit AskCode;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls, ExDataSt, TB97;

type
  TfrmQuestions = class(TForm)
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    btnHelp: TBitBtn;
    SrcList: TListBox;
    DstList: TListBox;
    SrcLabel: TLabel;
    DstLabel: TLabel;
    panelQuestions: TPanel;
    labelQuestion: TLabel;
    editQuestion: TEdit;
    labelWhy: TLabel;
    memoWhy: TMemo;
    checkUseCNF: TCheckBox;
    IncludeBtn: TToolbarButton97;
    ExcludeBtn: TToolbarButton97;
    procedure IncludeBtnClick(Sender: TObject);
    procedure ExcludeBtnClick(Sender: TObject);
    procedure SetButtons;
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure FormCreate(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure DstListClick(Sender: TObject);
  private
    save_it: boolean;
    current_var: integer;
    QuestionsCopy: TQuestions;
    procedure QuestionEdit;
    procedure NewQuestion(Index: integer);
    procedure FillVars;
    procedure FillQuestions;
  end;

var
  frmQuestions: TfrmQuestions;

implementation

uses
   General, Base, Dialogs, ExConsts;

{$R *.DFM}

{Métodos relativos ao preenchimento e manutenção das estruturas auxiliares}
procedure TfrmQuestions.FillVars;
begin
  ExSys.Vars.CurrentKey := PRIMARY_KEY;
  ExSys.Vars.MoveFirst;
  while not ExSys.Vars.Blind do begin
     ExSys.Questions.Seek(ExSys.Vars.Code);
     if ExSys.Questions.Blind then
        SrcList.Items.Add(ExSys.Vars.Name)
     else
        DstList.Items.Add(ExSys.Vars.Name);
     ExSys.Vars.MoveNext;
  end;
end;

procedure TfrmQuestions.FillQuestions;
var
   i, j, max, total: integer;
   current_node_1, current_node_2: TMetaNode;
   node: TNode;
begin
   QuestionsCopy := TQuestions.Create;
   if ExSys.Questions.RecordCount > 1 then
      max := 1
   else
      max := ExSys.Questions.RecordCount - 1;
   {Cria uma cópia balanceada de Questions}
   for j := 0 to max do begin
      ExSys.Questions.MoveFirst;
      if j = 0 then
         total := ExSys.Questions.RecordCount div 2
      else
         total := (ExSys.Questions.RecordCount div 2) - 1;
      for i := 1 to total do ExSys.Questions.MoveNext;
      current_node_1 := ExSys.Questions.CurrentNode;
      if current_node_1 <> nil then begin
         current_node_2 := ExSys.Questions.CurrentNode.Next;
         if current_node_2 <> nil then current_node_2 := current_node_2.Next;
      end
      else
         current_node_2 := nil;
      while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
         if current_node_1 <> nil then begin
            node := current_node_1.node;
            with TQuestionNode(node) do
               QuestionsCopy.Insert(Code, Question, Why, UseCNF);
            current_node_1 := current_node_1.Previous;
            if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
         end;
         if current_node_2 <> nil then begin
            node := current_node_2.Node;
            with TQuestionNode(node) do
               QuestionsCopy.Insert(Code, Question, Why, UseCNF);
            current_node_2 := current_node_2.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end;
      end;
   end;
end;

procedure TfrmQuestions.NewQuestion(Index: integer);
begin
   ExSys.Vars.SeekByName(SrcList.Items[Index]);
   QuestionsCopy.Insert(ExSys.Vars.code, '', nil, true);
   editQuestion.Text := '';
   memoWhy.Lines.Clear;
   checkUseCNF.Checked := true;
end;

procedure TfrmQuestions.QuestionEdit;
begin
   QuestionsCopy.Seek(current_var);
   QuestionsCopy.Question := editQuestion.Text;
   QuestionsCopy.Why := TStringList(memoWhy.Lines);
   QuestionsCopy.UseCNF := checkUseCNF.Checked;
end;

{Métodos relativos aos eventos das listas}
procedure TfrmQuestions.DstListClick(Sender: TObject);
begin
    if DstList.ItemIndex <> -1 then begin
       editQuestion.Enabled := true;
       labelQuestion.Font.Color := clBlack;
       memoWhy.Enabled := true;
       labelWhy.Font.Color := clBlack;
       checkUseCNF.Enabled := true;
    end
    else begin
       editQuestion.Enabled := false;
       labelQuestion.Font.Color := clGray;
       memoWhy.Enabled := false;
       labelWhy.Font.Color := clGray;
       checkUseCNF.Enabled := false;
    end;
    if current_var <> 0 then QuestionEdit;
    if DstList.ItemIndex <> -1 then begin
       ExSys.Vars.SeekByName(DstList.Items[DstList.ItemIndex]);
       QuestionsCopy.Seek(ExSys.Vars.code);
       current_var := ExSys.Vars.code;
       editQuestion.Text := QuestionsCopy.Question;
       memoWhy.Clear;
       memoWhy.Lines.AddStrings(QuestionsCopy.Why);
       checkUseCNF.Checked := QuestionsCopy.UseCNF;
    end;
end;

{Métodos relativos aos botões de remoção/inclusão de items}
procedure TfrmQuestions.IncludeBtnClick(Sender: TObject);
var
  index: integer;
  name: string;
begin
  if SrcList.ItemIndex <> -1 then begin
     If current_var <> 0 then QuestionEdit;
     index := SrcList.ItemIndex;
     name := SrcList.Items[Index];
     NewQuestion(Index);
     MoveSelected(SrcList, DstList.Items);
     DstList.ItemIndex := DstList.Items.IndexOf(name);
     current_var := 0;
     DstListClick(Sender);
     editQuestion.SetFocus;
  end;
end;

procedure TfrmQuestions.ExcludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  if DstList.ItemIndex <> -1 then begin
     Index := DstList.ItemIndex;
     ExSys.Vars.SeekByName(DstList.Items[Index]);
     QuestionsCopy.Seek(ExSys.Vars.Code);
     QuestionsCopy.Delete;
     current_var := 0;
     MoveSelected(DstList, SrcList.Items);
  end;
end;

procedure TfrmQuestions.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  i: Integer;
begin
  i := List.ItemIndex;
  Items.AddObject(List.Items[i], List.Items.Objects[i]);
  List.Items.Delete(i);
  SetButtons;
end;

procedure TfrmQuestions.SetButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcList.Items.Count = 0;
  DstEmpty := DstList.Items.Count = 0;
  IncludeBtn.Enabled := not SrcEmpty;
  ExcludeBtn.Enabled := not DstEmpty;
end;

{Métodos relativos aos botões de controle (Ok, cancelar, etc.}
procedure TfrmQuestions.btnOkClick(Sender: TObject);
begin
   DstListClick(Sender);
   Close;
end;

procedure TfrmQuestions.btnCancelClick(Sender: TObject);
begin
   save_it := false;
   Close;
end;

{Métodos relativos ao formulário}
procedure TfrmQuestions.FormCreate(Sender: TObject);
begin
   save_it := true;
   current_var := 0;
   FillVars;
   FillQuestions;
   SetButtons;
   Height := 312;
   Width := 520;
   FormResize(Sender);
   Invalidate;
end;

procedure TfrmQuestions.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
   i, j, max, total: integer;
   current_node_1, current_node_2: TMetaNode;
   node: TNode;

begin
   question_opened := false;
   if save_it and (ExSys.Permission = TOTAL_PERMISSION) then begin
      frmBase.save_me := true;
      ExSys.Questions.Free;
      ExSys.Questions := TQuestions.Create;
      {Restaura Questions de forma balanceada}
      if QuestionsCopy.RecordCount > 1 then
         max := 1
      else
         max := QuestionsCopy.RecordCount - 1;
      for j := 0 to max do begin
         QuestionsCopy.MoveFirst;
         if j = 0 then
            total := QuestionsCopy.RecordCount div 2
         else
            total := (QuestionsCopy.RecordCount div 2) - 1;
         for i := 1 to total do QuestionsCopy.MoveNext;
         current_node_1 := QuestionsCopy.CurrentNode;
         if current_node_1 <> nil then begin
            current_node_2 := QuestionsCopy.CurrentNode.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end
         else
            current_node_2 := nil;
         while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
            if current_node_1 <> nil then begin
               node := current_node_1.Node;
               with TQuestionNode(node) do
                  ExSys.Questions.Insert(Code, Question, Why, UseCNF);
               current_node_1 := current_node_1.Previous;
               if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
            end;
            if current_node_2 <> nil then begin
               node := current_node_2.Node;
               with TQuestionNode(node) do
                  ExSys.Questions.Insert(Code, Question, Why, UseCNF);
               current_node_2 := current_node_2.Next;
               if current_node_2 <> nil then current_node_2 := current_node_2.Next;
            end;
         end;
      end;
      frmBase.save_me := true;
   end;
   QuestionsCopy.Free;
   if save_it and (ExSys.Permission <> TOTAL_PERMISSION) then
      MessageDlg('Lembre-se de que você não tem permissão para alterar essa ' +
                 'base de conhecimento!', mtInformation, [mbOk], 0);
   Action := caFree;
end;

procedure TfrmQuestions.FormResize(Sender: TObject);
var
   delta1, delta2: integer;
begin
 try
   if Height < 310 then Height := 310;
   if Width < 500 then Width := 500;
   delta1 := IncludeBtn.Left - (SrcList.Left + SrcList.Width);
   delta2 := DstList.Left - (SrcList.Left + SrcList.Width);
   SrcList.Width := trunc((Width - delta2 - 4 * SrcList.Left - btnOk.Width) / 2);
   SrcList.Height := trunc(Height / 2) - SrcLabel.Top - 25;
   DstList.Width := SrcList.Width;
   DstList.Left := SrcList.Left + SrcList.Width + delta2;
   DstList.Height := SrcList.Height;
   DstLabel.Left := DstList.Left;
   IncludeBtn.Left := SrcList.Left + SrcList.Width + delta1;
   ExcludeBtn.Left := IncludeBtn.Left;
   btnOk.Left := DstList.Left + DstList.Width + SrcList.Left;
   btnCancel.Left := btnOk.Left;
   btnHelp.Left := btnOk.Left;
   panelQuestions.Width := btnOk.Left + btnOk.Width - panelQuestions.Left;
   panelQuestions.Top := SrcList.Top + SrcList.Height + 10;
   panelQuestions.Height := Height - panelQuestions.Top - 30;
   editQuestion.Width := panelQuestions.Width - 2 * editQuestion.Left;
   memoWhy.Width := editQuestion.Width;
   memoWhy.Height := panelQuestions.Height - memoWhy.Top - 10;
 finally end;
end;

end.
