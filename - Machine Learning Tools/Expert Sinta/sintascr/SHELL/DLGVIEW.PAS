{===========================================
 UNIDADE/FORMULÁRIO de definição de visuali-
 zação de regras
 Implementação: Ricardo Bezerra/Borland
 Design de interface: Ricardo Bezerra
                      Ricardo Silvestre
 Descrição: Nesta caixa de diálogo se definem
            quais regras deseja-se ver em
            conjunto.
 Baseado em template do Delphi 1.0
 Data de início: 11 de janeiro de 1996
 Data de término: 11 de janeiro de 1996
 Última modificação: 18 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA
 ===========================================}

unit Dlgview;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, Tabnotbk, TB97;

type
  TdialogView = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    TabbedNotebook: TTabbedNotebook;
    SrcList: TListBox;
    SrcLabel: TLabel;
    radioHeads: TRadioButton;
    radioAll: TRadioButton;
    DstLabel: TLabel;
    IncludeBtn: TToolbarButton97;
    DstList: TListBox;
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
    procedure FormShow(Sender: TObject);
    procedure SrcListClick(Sender: TObject);
  private
    procedure InitializeList;
  end;

var
  dialogView: TdialogView;

implementation

uses
   General, Base;

{$R *.DFM}

procedure TdialogView.IncludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcList);
  MoveSelected(SrcList, DstList.Items);
  SetItem(SrcList, Index);
end;

procedure TdialogView.ExcludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstList);
  MoveSelected(DstList, SrcList.Items);
  SetItem(DstList, Index);
end;

procedure TdialogView.IncAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcList.Items.Count - 1 do
    DstList.Items.AddObject(SrcList.Items[I],
      SrcList.Items.Objects[I]);
  SrcList.Items.Clear;
  SetItem(SrcList, 0);
end;

procedure TdialogView.ExcAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstList.Items.Count - 1 do
    SrcList.Items.AddObject(DstList.Items[I], DstList.Items.Objects[I]);
  DstList.Items.Clear;
  SetItem(DstList, 0);
end;

procedure TdialogView.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then
    begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;

procedure TdialogView.SetButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcList.Items.Count = 0;
  DstEmpty := DstList.Items.Count = 0;
  IncludeBtn.Enabled := not SrcEmpty;
  IncAllBtn.Enabled := not SrcEmpty;
  ExcludeBtn.Enabled := not DstEmpty;
  ExcAllBtn.Enabled := not DstEmpty;
end;

function TdialogView.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;

procedure TdialogView.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do
  begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then Index := 0
    else if Index > MaxIndex then Index := MaxIndex;
    Selected[Index] := True;
  end;
  SetButtons;
end;

procedure TdialogView.SrcListClick(Sender: TObject);
begin
   radioHeads.Checked := true;
end;

procedure TdialogView.InitializeList;
begin
   SrcList.Clear;
   DstList.Clear;
   ExSys.Vars.MoveFirst;
   while not ExSys.Vars.Blind do begin
      SrcList.Items.Add(ExSys.Vars.name);
      ExSys.Vars.MoveNext;
   end;
end;

procedure TdialogView.FormShow(Sender: TObject);
begin
   InitializeList;
   radioAll.Checked := True;
   SetButtons;
end;

end.
