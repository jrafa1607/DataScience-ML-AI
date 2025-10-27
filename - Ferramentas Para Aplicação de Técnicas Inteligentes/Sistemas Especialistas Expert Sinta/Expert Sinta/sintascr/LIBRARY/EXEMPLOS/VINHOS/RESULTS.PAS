unit Results;

interface

uses
  WinTypes, WinProcs, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExCtrls, StdCtrls, Grids, Tabs, ExtCtrls, Buttons, Outline;

type
  TfrmResults = class(TForm)
    Notebook: TNotebook;
    panelVarName: TPanel;
    panelTree: TPanel;
    panelAll: TPanel;
    panelRules: TPanel;
    TabSet: TTabSet;
    ValuesGrid: TValuesGrid;
    ConsultTree: TConsultTree;
    AllVars: TAllVars;
    RuleView: TRuleView;
    ButtonPanel: TPanel;
    btnOk: TBitBtn;
    btnExpand: TSpeedButton;
    btnCollapse: TSpeedButton;
    btnExpandVars: TSpeedButton;
    btnCollapseVars: TSpeedButton;
    procedure TabSetClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnExpandClick(Sender: TObject);
    procedure btnCollapseClick(Sender: TObject);
    procedure btnExpandVarsClick(Sender: TObject);
    procedure btnCollapseVarsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  public
    var_code: integer;
  end;

var
  frmResults: TfrmResults;

implementation

uses
   Unit1;

{$R *.DFM}

procedure TfrmResults.FormCreate(Sender: TObject);
begin
    ValuesGrid.ExpertSystem := Form1.ExpertSystem;
    RuleView.ExpertSystem := Form1.ExpertSystem;
end;

procedure TfrmResults.TabSetClick(Sender: TObject);
begin
   Notebook.PageIndex := TabSet.TabIndex;
end;

procedure TfrmResults.FormResize(Sender: TObject);
begin
   if Width < 200 Then Width := 200;
   If Height < 200 Then Height := 200;
   ValuesGrid.Width := NoteBook.Width - ValuesGrid.Left;
   ValuesGrid.Height := NoteBook.Height - ValuesGrid.Top - 10;
   ValuesGrid.ColWidths[0] := ValuesGrid.Width - ValuesGrid.ColWidths[1] - 4;
   ConsultTree.Width := ValuesGrid.Width;
   ConsultTree.Height := ValuesGrid.Height;
   AllVars.Width := ValuesGrid.Width;
   AllVars.Height := ValuesGrid.Height;
   RuleView.Width := ValuesGrid.Width;
   RuleView.Height := ValuesGrid.Height;
   panelVarName.Width := ValuesGrid.Width;
   panelTree.Width := panelVarName.Width;
   panelAll.Width := panelVarName.Width;
   panelRules.Width := panelVarName.Width;
end;

procedure TfrmResults.btnExpandClick(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   ConsultTree.BeginUpdate;
   ConsultTree.FullExpand;
   ConsultTree.EndUpdate;
   {$ELSE}
   ConsultTree.FullExpand;
   {$ENDIF}
end;

procedure TfrmResults.btnCollapseClick(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   ConsultTree.BeginUpdate;
   ConsultTree.FullCollapse;
   ConsultTree.EndUpdate;
   {$ELSE}
   ConsultTree.FullCollapse;
   {$ENDIF}
end;

procedure TfrmResults.btnExpandVarsClick(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   AllVars.BeginUpdate;
   AllVars.FullExpand;
   AllVars.EndUpdate;
   {$ELSE}
   AllVars.Items.BeginUpdate;
   AllVars.FullExpand;
   AllVars.Items.EndUpdate;
   {$ENDIF}
end;

procedure TfrmResults.btnCollapseVarsClick(Sender: TObject);
begin
   {$IFDEF WINDOWS}
   AllVars.BeginUpdate;
   AllVars.FullCollapse;
   AllVars.EndUpdate;
   {$ELSE}
   AllVars.Items.BeginUpdate;
   AllVars.FullCollapse;
   AllVars.Items.EndUpdate;
   {$ENDIF}
end;

end.
