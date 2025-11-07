{========================================================
 * Expert SINTA Run-Time *

 Module name: Main.pas
 Implementação: Ricardo Bezerra
 Data de início: 22 de março de 1997
 Data de término: 22 de março de 1997
 Última modicação: 31 de julho de 1997
 Expert SINTA RunTime(c) 1995-1997
 Laboratório de Inteligência Artificial/LIA
 ========================================================}
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
    labelHelp: TLabel;
    btnOk: TBitBtn;
    btnHelp: TBitBtn;
    btnHelpOnItem: TSpeedButton;
    btnExpand: TSpeedButton;
    btnCollapse: TSpeedButton;
    btnExpandVars: TSpeedButton;
    btnCollapseVars: TSpeedButton;
    procedure TabSetClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnHelpOnItemClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
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
   Main;

{$R *.DFM}

procedure TfrmResults.FormCreate(Sender: TObject);
begin
    ValuesGrid.ExpertSystem := frmMain.ExpertSystem;
    RuleView.ExpertSystem := frmMain.ExpertSystem;
end;

procedure TfrmResults.FormShow(Sender: TObject);
begin
   labelHelp.visible := (frmMain.ExpertSystem.Info.HelpFile <> '');
   btnHelpOnItem.visible := labelHelp.visible;
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

procedure TfrmResults.btnHelpOnItemClick(Sender: TObject);
var
   key: Word;
begin
   key := VK_F2;
   FormKeyDown(btnHelpOnItem, key, []);
end;

procedure TfrmResults.FormKeyDown(Sender: TObject; var Key: Word;
          Shift: TShiftState);
var
   help_file: string;
begin
   if Key <> VK_F2 then Exit;
   Key := 0;
   with frmMain.ExpertSystem do begin
      BookmarkVar;
      if Info.HelpFile <> '' then begin
         help_file := Info.HelpFile + #0;
         if not((ValuesGrid.Row > 0) and (ValuesGrid.Col = 0)) then
            {Chama o "contents" do arquivo de ajuda da base}
            WinHelp(frmMain.Handle, @help_file[1], HELP_CONTENTS, 0)
         else begin
            if (ValuesGrid.Row > 0) and (ValuesGrid.Col = 0) then begin
               Values.SeekByName(ValuesGrid.Cells[ValuesGrid.Col, ValuesGrid.Row],
                                 var_code);
               HelpContexts.Seek(Values.code);
               if not HelpContexts.Blind then
                  {Chama um tópico específico}
                  WinHelp(frmMain.Handle, @help_file[1], HELP_CONTEXT, HelpContexts.context)
               else
                  WinHelp(frmMain.Handle, @help_file[1], HELP_CONTENTS, 0);
            end
            else
               WinHelp(frmMain.Handle, @help_file[1], HELP_CONTENTS, 0)
         end;
      end
      else
         Application.HelpCommand(HELP_CONTENTS, 0);
      RestoreVarFromBookmark;
   end;
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
