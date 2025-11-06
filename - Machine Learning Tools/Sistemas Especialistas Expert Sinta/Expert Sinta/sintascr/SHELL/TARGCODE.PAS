{=============================================
 UNIDADE/FORMULÁRIO de objetivos
 Implementação: Ricardo Bezerra/Borland
 Design de interface: Ricardo Bezerra
 Descrição: Aqui o usuário define quais são
            os objetivos do sistema e em qual
            ordem estes devem ser encontrados.
 Baseado em template do Delphi 1.0
 Data de início: 05 de janeiro de 1996
 Data de término: 05 de janeiro de 1996
 Última modificação: 18 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =============================================}

unit Targcode;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExDataSt, TB97;

type
  TfrmTargets = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    SrcList: TListBox;
    DstList: TListBox;
    SrcLabel: TLabel;
    DstLabel: TLabel;
    checkShowResults: TCheckBox;
    IncludeBtn: TToolbarButton97;
    IncAllBtn: TToolbarButton97;
    ExcludeBtn: TToolbarButton97;
    ExcAllBtn: TToolbarButton97;
    procedure IncludeBtnClick(Sender: TObject);
    procedure ExcludeBtnClick(Sender: TObject);
    procedure IncAllBtnClick(Sender: TObject);
    procedure ExcAllBtnClick(Sender: TObject);
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetItem(List: TListBox; Index: Integer);
    function  GetFirstSelection(List: TCustomListBox): Integer;
    procedure SetButtons;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure DstListMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DstListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure DstListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure DstListClick(Sender: TObject);
    procedure checkShowResultsClick(Sender: TObject);
    procedure SrcListClick(Sender: TObject);
  private
    save_it: boolean;
    TargetsCopy: TTargets;
    procedure InitializeLists;
  end;

var
  frmTargets: TfrmTargets;

implementation

uses
   General, Base, Dialogs, SysUtils, ExConsts;

{$R *.DFM}

{======================================================================
 ======================================================================
                       INICIALIZAÇÕES E FINALIZAÇÕES
 ======================================================================
 ======================================================================}


procedure TfrmTargets.FormCreate(Sender: TObject);
begin
   save_it := true;
   InitializeLists;
   SetButtons;
   FormResize(Sender);
end;

procedure TfrmTargets.FormResize(Sender: TObject);
var
   delta, delta2, delta3: integer;
begin
   try
     if Width < 361 then Width := 361;
     if Height < 257 then Height := 257;
     delta := DstList.Left -(SrcList.Left + SrcList.Width);
     delta2 := IncludeBtn.Left -(SrcList.Left + SrcList.Width);
     delta3 := OkBtn.Top - (SrcList.Top + SrcList.Height);
     SrcList.Width := trunc((Width - 3 * SrcList.Left - delta) / 2);
     SrcList.Height := Height - SrcList.Top - 2 * delta3 - 2 * OkBtn.Height;
     DstList.Width := SrcList.Width;
     DstList.Left := SrcList.Left + SrcList.Width + delta;
     DstList.Height := SrcList.Height - checkShowResults.Height - 2;
     checkShowResults.Top := DstList.Height + DstList.Top + 1;
     checkShowResults.Left := DstList.Left;
     DstLabel.Left := DstList.Left;
     IncludeBtn.Left := SrcList.Left + SrcList.Width + delta2;
     IncAllBtn.Left := IncludeBtn.Left;
     ExcludeBtn.Left := IncludeBtn.Left;
     ExcAllBtn.Left := IncludeBtn.Left;
     OkBtn.Top := SrcList.Top + SrcList.Height + {delta3 + 5} trunc(OkBtn.Height / 2);
     CancelBtn.Top := OkBtn.Top;
     HelpBtn.Top := OkBtn.Top;
     Okbtn.Left := DstList.Left + DstList.Width - 3 * OkBtn.Width - 20;
     Cancelbtn.Left := Okbtn.Left + Okbtn.Width + 10;
     Helpbtn.Left := Cancelbtn.Left + Cancelbtn.Width + 10;
   finally
   end;
end;

procedure TfrmTargets.FormShow(Sender: TObject);
begin
   FormResize(Sender);
end;

procedure TfrmTargets.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
   i, total: integer;
   error: boolean;
begin
   total := DstList.Items.Count - 1;
   i := 0;
   error := false;
   while (not error) and (i <= total) do begin
      ExSys.Vars.SeekByName(DstList.Items[i]);
      if ExSys.Vars.Blind then begin
         MessageDlg('Variável inexistente!', mtError, [mbOk], 0);
         error := true;
      end;
      inc(i);
   end;
   CanClose := not error;
end;

procedure TfrmTargets.FormClose(Sender: TObject; var Action: TCloseAction);
var
   i, total: integer;
   targ_aux: TTargetNode;
begin
   if save_it and (ExSys.Permission = TOTAL_PERMISSION) then begin
      ExSys.Targets.ClearObjects;
      total := DstList.Items.Count - 1;
      i := 0;
      while (i <= total) do begin
         targ_aux := TTargetNode.Create;
         targ_aux.Code := TargetsCopy.Nodes[i].code;
         targ_aux.ShowResults := TargetsCopy.Nodes[i].ShowResults;
         ExSys.Targets.Add(targ_aux);
         i := i + 1;
      end;
      frmBase.save_me := true;
   end;
   target_opened := false;
   if save_it and (ExSys.Permission <> TOTAL_PERMISSION) then
       MessageDlg('Lembre-se de que você não tem permissão para alterar essa ' +
                  'base de conhecimento!', mtInformation, [mbOk], 0);
   TargetsCopy.Free;
   Action := caFree;
end;

{======================================================================
 ======================================================================
                    BOTÕES DE TRANSFERÊNCIA DE ITEMS
 ======================================================================
 ======================================================================}

procedure TfrmTargets.InitializeLists;
var
  i, total: integer;
  targ_aux: TTargetNode;
begin
   total := ExSys.Targets.Count - 1;
   TargetsCopy := TTargets.Create;
   for i := 0 to total do begin
      ExSys.Vars.Seek(ExSys.Targets.Nodes[i].code);
      targ_aux := TTargetNode.Create;
      targ_aux.Code := ExSys.Targets.Nodes[i].code;
      targ_aux.ShowResults := ExSys.Targets.Nodes[i].ShowResults;
      TargetsCopy.Add(targ_aux);
      DstList.Items.Add(ExSys.Vars.name);
   end;
   ExSys.Vars.MoveFirst;
   while not ExSys.Vars.Blind do begin
     if DstList.Items.IndexOf(ExSys.Vars.name) = -1 then
        SrcList.Items.Add(ExSys.Vars.name);
     ExSys.Vars.MoveNext;
   end;
end;

procedure TfrmTargets.IncludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcList);
  MoveSelected(SrcList, DstList.Items);
  SetItem(SrcList, Index);
end;

procedure TfrmTargets.ExcludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := DstList.ItemIndex;
  MoveSelected(DstList, SrcList.Items);
  SetItem(DstList, Index);
end;

procedure TfrmTargets.IncAllBtnClick(Sender: TObject);
var
  i: Integer;
  targ_aux: TTargetNode;
begin
  for i := 0 to SrcList.Items.Count - 1 do begin
    DstList.Items.AddObject(SrcList.Items[i], SrcList.Items.Objects[i]);
    targ_aux := TTargetNode.Create;
    ExSys.Vars.SeekByName(SrcList.Items[i]);
    targ_aux.Code := ExSys.Vars.Code;
    targ_aux.ShowResults := true;
    TargetsCopy.Add(targ_aux);
  end;
  SrcList.Items.Clear;
  SetItem(SrcList, 0);
end;

procedure TfrmTargets.ExcAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstList.Items.Count - 1 do
    SrcList.Items.AddObject(DstList.Items[I], DstList.Items.Objects[I]);
  DstList.Items.Clear;
  TargetsCopy.ClearObjects;
  SetItem(DstList, 0);
end;

procedure TfrmTargets.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  i: Integer;
  targ_aux: TTargetNode;
begin
  if List = SrcList then begin
     for i := List.Items.Count - 1 downto 0 do
       if List.Selected[i] then begin
          Items.AddObject(List.Items[i], List.Items.Objects[i]);
          targ_aux := TTargetNode.Create;
          ExSys.Vars.SeekByName(List.Items[i]);
          targ_aux.Code := ExSys.Vars.Code;
          targ_aux.ShowResults := true;
          TargetsCopy.Add(targ_aux);
          List.Items.Delete(i);
       end
  end
  else begin
     i := DstList.ItemIndex;
     Items.AddObject(List.Items[i], List.Items.Objects[i]);
     TargetsCopy.Nodes[i].Free;
     TargetsCopy.Delete(i);
     List.Items.Delete(i);
  end;
end;

procedure TfrmTargets.SetButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcList.Items.Count = 0;
  DstEmpty := DstList.Items.Count = 0;
  IncludeBtn.Enabled := (not SrcEmpty) and (SrcList.SelCount > 0);
  IncAllBtn.Enabled := not SrcEmpty;
  ExcludeBtn.Enabled := (not DstEmpty) and (DstList.ItemIndex <> -1);;
  ExcAllBtn.Enabled := not DstEmpty;
  checkShowResults.Enabled := (not DstEmpty) and (DstList.ItemIndex <> -1);
  if not checkShowResults.Enabled then checkShowResults.Checked := false;
end;

function TfrmTargets.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TfrmTargets.SetItem(List: TListBox; Index: Integer);
begin
   List.SetFocus;
   SetButtons;
end;

{======================================================================
 ======================================================================
                        DEMAIS BOTÕES DE COMANDO
 ======================================================================
 ======================================================================}

procedure TfrmTargets.OKBtnClick(Sender: TObject);
begin
   Close;
end;

procedure TfrmTargets.CancelBtnClick(Sender: TObject);
begin
   save_it := false;
   Close;
end;

{======================================================================
 ======================================================================
                              LISTAS DE ITEMS
 ======================================================================
 ======================================================================}

procedure TfrmTargets.DstListMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DragItem: Integer;
begin
  if Button = mbLeft then begin
     DragItem := DstList.ItemAtPos(Point(X, Y), False);
     if (DragItem > -1) and (DragItem < DstList.Items.Count) then
        DstList.BeginDrag(False);
  end;
end;

procedure TfrmTargets.DstListDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  DropPos: Integer;
begin
  if Source = DstList then begin
     DropPos := DstList.ItemAtPos(Point(X, Y), False);
     Accept := (DropPos > -1) and (DropPos <> DstList.ItemIndex) and
       (DropPos < DstList.Items.Count);
  end
    else Accept := False;
end;

procedure TfrmTargets.DstListDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  OldPos, NewPos: integer;
  old: string;
  targ_aux: TTargetNode;
begin
  if Source = DstList then begin
     OldPos := DstList.ItemIndex;
     NewPos := DstList.ItemAtPos(Point(X, Y), False);
     if (NewPos > -1) and (NewPos <> OldPos) then begin
        old := DstList.Items[OldPos];
        DstList.Items.Delete(OldPos);
        targ_aux := TargetsCopy.Nodes[OldPos];
        TargetsCopy.Delete(OldPos);
        DstList.Items.Insert(NewPos, old);
        TargetsCopy.Insert(NewPos, targ_aux);
        checkShowResults.Enabled := false;
        checkShowResults.Checked := false;
     end;
   end;
end;

procedure TfrmTargets.SrcListClick(Sender: TObject);
begin
   IncludeBtn.Enabled := true;
end;

procedure TfrmTargets.DstListClick(Sender: TObject);
begin
   if not checkShowResults.Enabled then checkShowResults.Enabled := true;
   checkShowResults.Checked :=
      TargetsCopy.Nodes[DstList.ItemIndex].ShowResults;
   ExcludeBtn.Enabled := true;
end;

{======================================================================
 ======================================================================
                                 EXTRAS
 ======================================================================
 ======================================================================}

procedure TfrmTargets.checkShowResultsClick(Sender: TObject);
begin
   if DstList.ItemIndex <> -1 then
      TargetsCopy.Nodes[DstList.ItemIndex].ShowResults :=
                  checkShowResults.Checked;
end;

end.
