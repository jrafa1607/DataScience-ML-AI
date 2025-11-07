{=================================================
 UNIDADE/FORMULÁRIO de informações sobre a base
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Permite a inclusão de dados comple-
            mentares sobre a base de conhecimento.
 Data de início: 11 de janeiro de 1996
 Data de término: 12 de janeiro de 1996
 Última modificação: 21 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =================================================}
unit Infocode;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls, Tabs,
  Buttons, ExtCtrls, ExDataSt, TB97;

type
  TfrmInfos = class(TForm)
    ButtonPanel: TPanel;
    TabSet: TTabSet;
    Notebook: TNotebook;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    groupGeneral: TGroupBox;
    groupHelp: TGroupBox;
    labelName: TLabel;
    editName: TEdit;
    labelAuthors: TLabel;
    editAuthors: TEdit;
    labelOverture: TLabel;
    memoOverture: TMemo;
    checkShow: TCheckBox;
    labelExtra: TLabel;
    labelHelpName: TLabel;
    editHelpName: TEdit;
    labelVars: TLabel;
    labelValues: TLabel;
    listTargets: TListBox;
    listValues: TListBox;
    labelContext: TLabel;
    editContext: TEdit;
    btnAccept: TToolbarButton97;
    btnCancel: TToolbarButton97;
    procedure FormCreate(Sender: TObject);
    procedure TabSetClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CancelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure listTargetsClick(Sender: TObject);
    procedure editContextEnter(Sender: TObject);
    procedure listValuesClick(Sender: TObject);
    procedure ContextOperation(Sender: TObject);
    procedure editContextKeyPress(Sender: TObject; var Key: Char);
    procedure btnCancelClick(Sender: TObject);
  private
    save_it: boolean;
    modified_contexts: TSingleIndexTree;
    old_context, current_var, current_value: integer;
    ContextsCopy: THelpContexts;
    procedure CopyContexts;
    procedure StartTargets;
  end;

var
  frmInfos: TfrmInfos;

implementation

uses
   General, Base, SysUtils, Dialogs, ExConsts;

{$R *.DFM}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}

procedure TfrmInfos.FormCreate(Sender: TObject);
begin
  TabSet.Tabs := Notebook.Pages;
  ContextsCopy := THelpContexts.Create;
  modified_contexts := TSingleIndexTree.Create;
  save_it := true;
  CopyContexts;
  StartTargets;
end;

procedure TfrmInfos.FormShow(Sender: TObject);
begin
   editName.Text := ExSys.Info.Name;
   editAuthors.Text := ExSys.Info.Authors;
   memoOverture.Lines.AddStrings(ExSys.Info.Overture);
   editHelpName.Text := ExSys.Info.HelpFile;
   checkShow.checked := ExSys.Info.ShowIntro;
   FormResize(Sender);
   editName.SetFocus;
   editName.SelectAll;
end;

procedure TfrmInfos.FormResize(Sender: TObject);
begin
   try
      if Width < 300 then Width := 300;
      if Height < 200 then Height := 200;
      groupGeneral.Height := NoteBook.Height - 2 * groupGeneral.Top;
      groupGeneral.Width := NoteBook.Width - 2 * groupGeneral.Left;
      editName.Width := groupGeneral.Width - labelName.Width - 2 * labelName.Left - 40;
      editAuthors.Width := editName.Width;
      memoOverture.Width := editName.Width;
      memoOverture.Height := groupGeneral.Height - memoOverture.Top -
         checkShow.Height - 10 - trunc(labelName.Top / 2);
      checkShow.Top := memoOverture.Top + memoOverture.Height + 15;

      groupHelp.Height := groupGeneral.Height;
      groupHelp.Width := groupGeneral.Width;
      labelExtra.Top := checkShow.Top;
      editHelpName.Width := groupHelp.Width - labelHelpName.Width -
         2 * labelHelpName.Left - 20;
      labelContext.Left := groupHelp.Width - editContext.Width -
                           2 * btnAccept.Width - 10;
      editContext.Left := labelContext.Left;
      btnAccept.Left := editContext.Left + editContext.Width + 5;
      btnCancel.Left := btnAccept.Left + btnAccept.Width;
      listTargets.Width := trunc((groupHelp.Width - 2 * labelHelpName.Left -
         editContext.Width - 2 * btnAccept.Width - 10) / 2);
      listValues.Width := listTargets.Width;
      listValues.Left := listTargets.Left + listTargets.Width +
         trunc(0.5 * labelHelpName.Left);
      listTargets.Height := groupHelp.Height - listTargets.Top -
         labelExtra.Height - 15;
      listValues.Height := listTargets.Height;
      labelValues.Left := listValues.Left;

   finally end;
end;

procedure TfrmInfos.FormClose(Sender: TObject; var Action: TCloseAction);

   procedure SaveContexts(t: TMetaNode);
   begin
      ContextsCopy.Seek(t.node.Code);
      ExSys.HelpContexts.Seek(ContextsCopy.Code);
      if ExSys.HelpContexts.Blind then begin
         if ContextsCopy.context <> 0 then
            ExSys.HelpContexts.Insert(ContextsCopy.Code, ContextsCopy.Context)
      end
      else begin
         if ContextsCopy.Context <> 0 then
            ExSys.HelpContexts.Context := ContextsCopy.Context
         else
            ExSys.HelpContexts.Delete;
      end;
   end;

begin
   if save_it and (ExSys.Permission = TOTAL_PERMISSION) then begin
      ExSys.Info.Name := editName.Text;
      ExSys.Info.Authors := editAuthors.Text;
      ExSys.Info.Overture.Clear;
      ExSys.Info.Overture.AddStrings(memoOverture.Lines);
      ExSys.Info.HelpFile := editHelpName.Text;
      ExSys.Info.ShowIntro := checkShow.checked;
      modified_contexts.MoveFirst;
      while not modified_contexts.Blind do begin
         SaveContexts(modified_contexts.CurrentNode);
         modified_contexts.MoveNext;
      end;
      frmBase.save_me := true;
   end;
   if save_it and (ExSys.Permission <> TOTAL_PERMISSION) then
      MessageDlg('Lembre-se de que você não tem permissão para alterar essa ' +
                  'base de conhecimento!', mtInformation, [mbOk], 0);
   info_opened := false;
   ContextsCopy.Free;
   modified_contexts.Free;
   Action := caFree;
end;

{======================================================================
 ======================================================================
                     TRATAMENTO DOS CONTEXTOS DE AJUDA
 ======================================================================
 ======================================================================}

procedure TfrmInfos.StartTargets;
var
   i, total: integer;
begin
   total := ExSys.Targets.Count - 1;
   for i := 0 to total do begin
       ExSys.Vars.Seek(ExSys.Targets.Nodes[i].Code);
       if not ExSys.Vars.Blind then listTargets.Items.Add(ExSys.Vars.name);
   end;
end;

procedure TfrmInfos.CopyContexts;
var
   i, j, max, total: integer;
   current_node_1, current_node_2: TMetaNode;
   node: TNode;
begin
   {Cria uma cópia balanceada de HelpContexts}
   if ExSys.HelpContexts.RecordCount > 1 then
      max := 1
   else
      max := ExSys.HelpContexts.RecordCount - 1;
   for j := 0 to max do begin
      ExSys.HelpContexts.MoveFirst;
      if j = 0 then
         total := ExSys.HelpContexts.RecordCount div 2
      else
         total := (ExSys.HelpContexts.RecordCount div 2) - 1;
      for i := 1 to total do ExSys.HelpContexts.MoveNext;
      current_node_1 := ExSys.HelpContexts.CurrentNode;
      if current_node_1 <> nil then begin
         current_node_2 := ExSys.HelpContexts.CurrentNode.Next;
         if current_node_2 <> nil then current_node_2 := current_node_2.Next;
      end
      else
         current_node_2 := nil;
      while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
         if current_node_1 <> nil then begin
            node := current_node_1.node;
            ContextsCopy.Insert(node.Code, TContextNode(node).Context);
            current_node_1 := current_node_1.Previous;
            if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
         end;
         if current_node_2 <> nil then begin
            node := current_node_2.node;
            ContextsCopy.Insert(node.Code, TContextNode(node).context);
            current_node_2 := current_node_2.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end;
      end;
   end;
end;

procedure TfrmInfos.listTargetsClick(Sender: TObject);
begin
   ExSys.Vars.SeekByName(listTargets.Items[listTargets.ItemIndex]);
   current_var := ExSys.Vars.Code;
   ExSys.Values.SeekByVar(current_var);
   listValues.Items.Clear;
   while (not ExSys.Values.Blind) and (ExSys.Values.VarCode = current_var) do begin
      listValues.Items.Add(ExSys.Values.name);
      ExSys.Values.MoveNext;
   end;
   editContext.Enabled := False;
   btnAccept.Enabled := False;
   btnCancel.Enabled := False;
end;

procedure TfrmInfos.listValuesClick(Sender: TObject);
begin
   ExSys.Values.SeekByName(listValues.Items[listValues.ItemIndex], current_var);
   current_value := ExSys.Values.Code;
   ContextsCopy.Seek(current_value);
   if not ContextsCopy.Blind then
      editContext.Text := IntToStr(ContextsCopy.context)
   else
      editContext.Text := '0';
   editContext.Enabled := True;
   btnAccept.Enabled := True;
   btnCancel.Enabled := True;
end;

procedure TfrmInfos.editContextEnter(Sender: TObject);
begin
   try
      old_context := StrToInt(editContext.Text);
   except
      old_context := 0;
   end;
end;

procedure TfrmInfos.ContextOperation(Sender: TObject);
var
   c: integer;

   procedure ModifyContext(c: integer);
   begin
      ContextsCopy.context := c;
      modified_contexts.Seek(current_value);
      if modified_contexts.Blind then
         modified_contexts.Insert(current_value);
   end;

   procedure NewContext(c: integer);
   begin
      ContextsCopy.Insert(current_value, c);
      modified_contexts.Insert(current_value);
   end;

   procedure DelContext;
   begin
      ModifyContext(0);
   end;

begin
   try
     c := StrToInt(editContext.Text);
   except
     c := 0;
   end;
   editContext.Text := IntToStr(c);
   ContextsCopy.Seek(current_value);
   if c <> 0 then begin
      {É um contexto diferente de zero. Lembrar que contextos iguais
       a zero não são gravados}
      if not ContextsCopy.Blind then
         ModifyContext(c)
      else
         NewContext(c);
   end
   else
      {Se um contexto foi modificado para zero, deve ser
       deletado (é uma otimização de espaço)}
      if not ContextsCopy.Blind then DelContext;
      {Se não foi encontrado nada e o contexto é zero, não
       há nada para fazer.}
   if Sender is TSpeedButton then begin
      editContext.SetFocus;
      editContext.SelectAll;
   end;
end;

procedure TfrmInfos.editContextKeyPress(Sender: TObject; var Key: Char);
begin
   if Key = char(13) then begin
      Key := char(0);
      ContextOperation(btnAccept);
   end;
   if Key = char(27) then begin
      Key := char(0);
      btnCancelClick(Sender);
   end;
end;

{======================================================================
 ======================================================================
                                  EXTRAS
 ======================================================================
 ======================================================================}

procedure TfrmInfos.TabSetClick(Sender: TObject);
begin
  Notebook.PageIndex := TabSet.TabIndex;
end;

procedure TfrmInfos.OKBtnClick(Sender: TObject);
begin
   save_it := true;
   Close;
end;

procedure TfrmInfos.CancelBtnClick(Sender: TObject);
begin
   save_it := false;
   Close;
end;

procedure TfrmInfos.btnCancelClick(Sender: TObject);
begin
   editContext.Text := IntToStr(old_context);
end;

end.
