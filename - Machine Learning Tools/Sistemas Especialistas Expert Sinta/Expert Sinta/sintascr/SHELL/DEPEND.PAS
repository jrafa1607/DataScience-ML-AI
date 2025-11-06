{===================================================
 UNIDADE/FORMULÁRIO de indicação de dependências
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Aqui são apresentadas as dependências
            de cada variável partindo dos objetivos.
            Referências circulares são detectadas.
 Data de início: 05 de fevereiro de 1997
 Data de término: 06 de fevereiro de 1997
 Última modificação: 20 de novembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ===================================================}

unit Depend;

interface

uses
  Wintypes, Winprocs, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, StdCtrls, Buttons, ExDataSt, General, Tabnotbk, ExtCtrls, WinSplit,
  TB97,
  {$IFDEF WINDOWS}
     Outline;
  {$ELSE}
     ComCtrls;
  {$ENDIF}

type
  TdialogDepend = class(TForm)
    btnClose: TBitBtn;
    TabbedNotebook: TTabbedNotebook;
    panelDummy: TPanel;
    listErrors: TListBox;
    WinSplit: TWinSplit;
    HelpBtn: TBitBtn;
    btnExpand: TToolbarButton97;
    btnCollapse: TToolbarButton97;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExpandClick(Sender: TObject);
    procedure btnCollapseClick(Sender: TObject);
    procedure listErrorsDblClick(Sender: TObject);
  private
    {As dependências de cada variável estão em uma árvore referenciada
     por cada nó de VarsDependencies}
     VarsDependencies: TTreeOfTrees;
    {HeadVars guarda os códigos das cabeças ordenados pelo
     código da variável. A árvore é balanceada}
     HeadsVars: THelpContexts;
    {Indica que determinada variável está gerando dependências, acusando,
     assim, dependências circulares. Ver o método InsertDependencies}
     OpenedDependencies: TSingleIndexTree;
    {Indica que houve dependência circular}
     conflict: boolean;
    {Lista com todas as variáveis que geraram conflito (dependência circular)}
     ConflictList: TList;
     next_conflict_code: ^integer;
     {$IFDEF WINDOWS}
     treeDependencies: TOutline;
     procedure InsertDependencies(position, code: integer);
     {$ELSE}
     treeDependencies: TTreeView;
     ilDependencies: TImageList;
     procedure InsertDependencies(position: TTreeNode; code: integer);
     procedure TreeViewCollapsed(Sender: TObject; Node: TTreeNode);
     procedure TreeViewExpanded(Sender: TObject; Node: TTreeNode);
     {$ENDIF}
     procedure InitHeadsVars;
     procedure GenerateFirstLevelDependencies;
     procedure CheckDependencies;
     procedure DealConflicts;
  end;

var
  dialogDepend: TdialogDepend;

implementation

uses
   ExConsts;

{$R *.DFM}

{$IFDEF WINDOWS}
   {$R DEPRES16.RES}
{$ELSE}
   {$R DEPRES32.RES}
{$ENDIF}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}

procedure TdialogDepend.FormCreate(Sender: TObject);
begin
  try
    Screen.Cursor := crHourGlass;
    {$IFDEF WINDOWS}
    treeDependencies := TOutline.Create(Self);
    treeDependencies.PictureLeaf.Handle := LoadBitmap(hInstance, 'DEPLEAF');
    treeDependencies.PictureClosed.Handle := LoadBitmap(hInstance, 'DEPCLOSED');
    treeDependencies.PictureOpen.Handle := LoadBitmap(hInstance, 'DEPOPENED');
    treeDependencies.Style := otOwnerDraw;
    treeDependencies.ItemHeight := 19;
    {$ELSE}
    treeDependencies := TTreeView.Create(Self);
    ilDependencies := TImageList.Create(Self);
    ilDependencies.ShareImages := false;
    ilDependencies.ResourceLoad(rtBitmap, 'ALLDEPENDENCIESBITMAPS', clFuchsia);
    treeDependencies.Images := ilDependencies;
    treeDependencies.OnCollapsed := TreeViewCollapsed;
    treeDependencies.OnExpanded := TreeViewExpanded;
    {$ENDIF}
    treeDependencies.Parent := panelDummy;
    treeDependencies.Align := alTop;
    treeDependencies.TabOrder := 0;
    treeDependencies.Height := 260;
    WinSplit.TargetControl := treeDependencies;
    WinSplit.Top := treeDependencies.Height;
    InitHeadsVars;
    GenerateFirstLevelDependencies;
    CheckDependencies;
  finally
    Screen.Cursor := crDefault;
    DealConflicts;
  end;
end;

procedure TdialogDepend.FormDestroy(Sender: TObject);
var
   i, total: integer;
begin
   VarsDependencies.Free;
   HeadsVars.Free;
   OpenedDependencies.Free;
   total := ConflictList.Count - 1;
   for i := 0 to total do dispose(ConflictList[i]);
   ConflictList.Free;
end;

{======================================================================
 ======================================================================
                            GERAÇÃO DA ÁRVORE
 ======================================================================
 ======================================================================}

procedure TdialogDepend.InitHeadsVars;
var
   i, j, max, total: integer;
   current_node_1, current_node_2: TMetaNode;
   node: TNode;
begin
   HeadsVars := THelpContexts.Create;
   if ExSys.Heads.RecordCount > 1 then
      max := 1
   else
      max := ExSys.Heads.RecordCount - 1;
   for j := 0 to max do begin
      ExSys.Heads.MoveFirst;
      if j = 0 then
         total := ExSys.Heads.RecordCount div 2
      else
         total := (ExSys.Heads.RecordCount div 2) - 1;
      for i := 1 to total do ExSys.Heads.MoveNext;
      current_node_1 := ExSys.Heads.CurrentNode;
      if current_node_1 <> nil then begin
         current_node_2 := ExSys.Heads.CurrentNode.Next;
         if current_node_2 <> nil then current_node_2 := current_node_2.Next;
      end
      else
         current_node_2 := nil;
      while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
         if current_node_1 <> nil then begin
            node := current_node_1.node;
            HeadsVars.Insert(THeadNode(node).VarCode, node.code);
            current_node_1 := current_node_1.Previous;
            if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
         end;
         if current_node_2 <> nil then begin
            node := current_node_2.node;
            HeadsVars.Insert(THeadNode(node).VarCode, THeadNode(node).Code);
            current_node_2 := current_node_2.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end;
      end;
   end;
end;

procedure TdialogDepend.GenerateFirstLevelDependencies;
var
   dependencies: TSingleIndexTree;
begin
   VarsDependencies := TTreeOfTrees.Create;
   ExSys.Vars.CurrentKey := PRIMARY_KEY;
   ExSys.Vars.MoveFirst;
   while not ExSys.Vars.Blind do begin
      HeadsVars.Seek(ExSys.Vars.code);
      {Relembrando: a propriedade "code" de HeadVars são os códigos
       das variáveis presentes nas cabeças, enquanto a propriedade
       "context" são os código das regras}
      if not HeadsVars.Blind then begin
         {Depende de outras variáveis}
         dependencies := TSingleIndexTree.Create;
         while (not HeadsVars.Blind) and (HeadsVars.Code = ExSys.Vars.Code)
         do begin
            ExSys.Tails.Seek(HeadsVars.Context);
            while (not ExSys.Tails.Blind) and (ExSys.Tails.Code = HeadsVars.Context)
            do begin
               dependencies.Seek(ExSys.Tails.VarCode);
               if dependencies.Blind then
                  dependencies.Insert(ExSys.Tails.VarCode);
               ExSys.Tails.MoveNext;
            end;
            HeadsVars.MoveNext;
         end;
      end
      else
         dependencies := nil; {Depende do usuário}
      VarsDependencies.Insert(ExSys.Vars.Code, dependencies);
      ExSys.Vars.MoveNext;
   end;
end;

procedure TdialogDepend.CheckDependencies;
var
   i, total: integer;
begin
   OpenedDependencies := TSingleIndexTree.Create;
   ConflictList := TList.Create;
   conflict := false;
   total := ExSys.Targets.Count - 1;
   {$IFDEF WINDOWS}
   for i := 0 to total do
       InsertDependencies(0, ExSys.Targets.Nodes[i].Code);
   treeDependencies.BeginUpdate;
   treeDependencies.FullExpand;
   treeDependencies.EndUpdate;
   {$ELSE}
   for i := 0 to total do
       InsertDependencies(nil, ExSys.Targets.Nodes[i].Code);
   treeDependencies.Items.BeginUpdate;
   treeDependencies.FullExpand;
   treeDependencies.Items.EndUpdate;
   {$ENDIF}
end;

{$IFDEF WINDOWS}
procedure TdialogDepend.InsertDependencies(position, code: integer);
var
    current_pos: integer;
    bookmark_depend1, bookmark_depend2: TMetaNode;
begin
    OpenedDependencies.Insert(code);
    ExSys.Vars.Seek(code);
    current_pos := treeDependencies.AddChild(position, ExSys.Vars.name);
    VarsDependencies.Seek(code);
    if VarsDependencies.tree = nil then
       treeDependencies.AddChild(current_pos, 'Usuário')
    else begin
       bookmark_depend1 := VarsDependencies.CurrentNode;
       VarsDependencies.tree.MoveFirst;
       while not VarsDependencies.tree.Blind do begin
          bookmark_depend2 := VarsDependencies.tree.CurrentNode;
          OpenedDependencies.Seek(VarsDependencies.tree.CurrentNode.Node.Code);
          if OpenedDependencies.Blind then
             InsertDependencies(current_pos,
                                VarsDependencies.tree.CurrentNode.Node.Code)
          else begin
             conflict := true;
             new(next_conflict_code);
             next_conflict_code^ := code;
             ConflictList.Add(next_conflict_code);
             new(next_conflict_code);
             next_conflict_code^ := VarsDependencies.tree.CurrentNode.Node.Code;
             ConflictList.Add(next_conflict_code);
             ExSys.Vars.Seek(VarsDependencies.tree.CurrentNode.Node.Code);
             current_pos := treeDependencies.AddChild(current_pos, ExSys.Vars.Name);
             new(next_conflict_code);
             next_conflict_code^ := current_pos;
             ConflictList.Add(next_conflict_code);
             treeDependencies.AddChild(current_pos, 'CONFLITO!')
          end;
          VarsDependencies.CurrentNode := bookmark_depend1;
          VarsDependencies.tree.CurrentNode := bookmark_depend2;
          VarsDependencies.tree.MoveNext;
       end;
    end;
    OpenedDependencies.Seek(code);
    OpenedDependencies.Delete;
end;
{$ELSE}
procedure TdialogDepend.InsertDependencies(position: TTreeNode; code: integer);
var
    aux, current_pos: TTreeNode;
    bookmark_depend1, bookmark_depend2: TMetaNode;
begin
    OpenedDependencies.Insert(code);
    ExSys.Vars.Seek(code);
    current_pos := treeDependencies.Items.AddChild(position, ExSys.Vars.name);
    current_pos.ImageIndex := 0;
    current_pos.SelectedIndex := 0;
    VarsDependencies.Seek(code);
    if VarsDependencies.tree = nil then begin
       aux := treeDependencies.Items.AddChild(current_pos, 'Usuário');
       aux.ImageIndex := 2;
       aux.SelectedIndex := 2;
    end
    else begin
       bookmark_depend1 := VarsDependencies.CurrentNode;
       VarsDependencies.tree.MoveFirst;
       while not VarsDependencies.tree.Blind do begin
          bookmark_depend2 := VarsDependencies.tree.CurrentNode;
          OpenedDependencies.Seek(VarsDependencies.tree.CurrentNode.Node.Code);
          if OpenedDependencies.Blind then
             InsertDependencies(current_pos,
                                VarsDependencies.tree.CurrentNode.Node.Code)
          else begin
             conflict := true;
             new(next_conflict_code);
             next_conflict_code^ := code;
             ConflictList.Add(next_conflict_code);
             new(next_conflict_code);
             next_conflict_code^ := VarsDependencies.tree.CurrentNode.Node.Code;
             ConflictList.Add(next_conflict_code);
             ExSys.Vars.Seek(VarsDependencies.tree.CurrentNode.Node.Code);
             current_pos := treeDependencies.Items.AddChild(current_pos, ExSys.Vars.Name);
             current_pos.ImageIndex := 0;
             current_pos.SelectedIndex := 0;
             new(next_conflict_code);
             next_conflict_code^ := current_pos.AbsoluteIndex;
             ConflictList.Add(next_conflict_code);
             aux := treeDependencies.Items.AddChild(current_pos, 'CONFLITO!');
             aux.ImageIndex := 3;
             aux.SelectedIndex := 3;
          end;
          VarsDependencies.CurrentNode := bookmark_depend1;
          VarsDependencies.tree.CurrentNode := bookmark_depend2;
          VarsDependencies.tree.MoveNext;
       end;
    end;
    OpenedDependencies.Seek(code);
    OpenedDependencies.Delete;
end;

procedure TdialogDepend.TreeViewCollapsed(Sender: TObject; Node: TTreeNode);
begin
   Node.ImageIndex := 0;
   Node.SelectedIndex := 0;
end;

procedure TdialogDepend.TreeViewExpanded(Sender: TObject; Node: TTreeNode);
begin
   Node.ImageIndex := 1;
   Node.SelectedIndex := 1;
end;
{$ENDIF}

{======================================================================
 ======================================================================
                           BOTÕES DE COMANDO
 ======================================================================
 ======================================================================}

procedure TdialogDepend.btnExpandClick(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   treeDependencies.BeginUpdate;
   treeDependencies.FullExpand;
   treeDependencies.EndUpdate;
   {$ELSE}
   treeDependencies.Items.BeginUpdate;
   treeDependencies.FullExpand;
   treeDependencies.Items.EndUpdate;
   {$ENDIF}
end;

procedure TdialogDepend.btnCollapseClick(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   treeDependencies.BeginUpdate;
   treeDependencies.FullCollapse;
   treeDependencies.EndUpdate;
   {$ELSE}
   treeDependencies.Items.BeginUpdate;
   treeDependencies.FullCollapse;
   treeDependencies.Items.EndUpdate;
   {$ENDIF}
end;

{======================================================================
 ======================================================================
                           MENSAGENS DE ERRO
 ======================================================================
 ======================================================================}

procedure TdialogDepend.DealConflicts;
var
   i, total: integer;
   mess: string;
begin
   if conflict then begin
      MessageDlg('Conflito entre variáveis!', mtError, [mbOk], 0);
      total := ConflictList.Count - 1;
      i := 0;
      while i < total do begin
         mess := 'Dependência circular entre ';
         ExSys.Vars.Seek(integer(ConflictList[i]^));
         mess := mess + ExSys.Vars.Name + ' e ';
         inc(i);
         ExSys.Vars.Seek(integer(ConflictList[i]^));
         mess := mess + ExSys.Vars.Name;
         listErrors.Items.Add(mess);
         i := i + 2;
      end;
   end
   else begin
      WinSplit.Visible := false;
      WinSplit.TargetControl := nil;
      treeDependencies.Align := alClient;
      listErrors.Visible := false;
   end;
end;

{$IFDEF WINDOWS}
procedure TdialogDepend.listErrorsDblClick(Sender: TObject);
var
   item: integer;

   procedure ExpandParent(n: TOutlineNode);
   begin
      if n.Level <> 1 then ExpandParent(n.Parent);
      n.Expanded := true;
   end;

begin
   item := integer(ConflictList[listErrors.ItemIndex * 3 + 2]^);
   treeDependencies.BeginUpdate;
   treeDependencies.FullCollapse;
   ExpandParent(treeDependencies.Items[item]);
   treeDependencies.EndUpdate;
   treeDependencies.SelectedItem := item;
end;
{$ELSE}
procedure TdialogDepend.listErrorsDblClick(Sender: TObject);
var
   item: integer;

   procedure ExpandParent(n: TTreeNode);
   begin
      if n.Level <> 1 then ExpandParent(n.Parent);
      n.Expanded := true;
   end;

begin
   item := integer(ConflictList[listErrors.ItemIndex * 3 + 2]^);
   treeDependencies.Items.BeginUpdate;
   treeDependencies.FullCollapse;
   ExpandParent(treeDependencies.Items[item]);
   treeDependencies.Items.EndUpdate;
   treeDependencies.Items[item].Selected := true;
end;
{$ENDIF}

end.
