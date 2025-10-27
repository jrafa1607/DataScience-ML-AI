{============================================
 * Expert SINTA RunTime *

 Module name: Main.pas
 Implementação: Ricardo Bezerra
 Data de início: 19 de março de 1997
 Data de término: 20 de março de 1997
 Última modificação: 03 de novembro de 1997
 Expert SINTA RunTime(c) 1995-1997
 Laboratório de Inteligência Artificial/LIA
 ============================================}

unit Main;

interface

uses
  WinTypes, WinProcs, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExSystem, ExCtrls, ExtCtrls, StdCtrls, Buttons, WinSplit,
  Tabs, ExDlgWhy;

type
  TfrmMain = class(TForm)
    ExpertSystem: TExpertSystem;
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuExit: TMenuItem;
    N2: TMenuItem;
    mnuOpen: TMenuItem;
    mnuHelp: TMenuItem;
    mnuAbout: TMenuItem;
    OpenDialog: TOpenDialog;
    panelToolBar: TPanel;
    BevelMenu: TBevel;
    panelWorkSpace: TPanel;
    ExNavigator: TExNavigator;
    mnuConsult: TMenuItem;
    mnuGo: TMenuItem;
    panelStatus: TPanel;
    panelInfo: TPanel;
    btnShowDebug: TSpeedButton;
    WinSplit: TWinSplit;
    TabSet: TTabSet;
    Notebook: TNotebook;
    DebugPanel: TDebugPanel;
    WatchPanel: TWatchPanel;
    btnOpen: TSpeedButton;
    mnuBack: TMenuItem;
    mnuStep: TMenuItem;
    mnuPause: TMenuItem;
    mnuStop: TMenuItem;
    panelEnter: TPanel;
    panelQuestion: TPanel;
    LabelQuestion: TLabelQuestion;
    btnOK: TBitBtn;
    btnWhy: TBitBtn;
    WhyDialog: TWhyDialog;
    panelLIA: TPanel;
    imageLIA: TImage;
    labelLIA: TLabel;
    labelNameLIA: TLabel;
    labelURL: TLabel;
    ExpertPrompt: TExpertPrompt;
    {$IFDEF WINDOWS}
      {$R CURSOR.RES}
    {$ELSE}
      {$R CURSOR32.RES}
    {$ENDIF}
    procedure FormCreate(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuGoClick(Sender: TObject);
    procedure btnShowDebugClick(Sender: TObject);
    procedure ExpertSystemPause(Sender: TObject);
    procedure ExpertSystemShowResults(Sender: TObject; V: Integer);
    procedure TabSetClick(Sender: TObject);
    procedure mnuConsultClick(Sender: TObject);
    procedure mnuBackClick(Sender: TObject);
    procedure mnuStepClick(Sender: TObject);
    procedure mnuPauseClick(Sender: TObject);
    procedure mnuStopClick(Sender: TObject);
    procedure ExpertSystemStart(Sender: TObject);
    procedure ExpertSystemPrompt(Sender: TObject; V: Integer);
    procedure btnOKClick(Sender: TObject);
    procedure btnWhyClick(Sender: TObject);
    procedure ExpertSystemFinish(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);
    procedure panelWorkSpaceResize(Sender: TObject);
    procedure labelURLClick(Sender: TObject);
  private
    procedure ResizePanelQuestion;
  end;

var
  frmMain: TfrmMain;

implementation

uses
   Results, About, ShellAPI;

{$R *.DFM}

{===================================================================
                   INICIALIZAÇÕES & FINALIZAÇÕES
 ===================================================================}

procedure TfrmMain.FormCreate(Sender: TObject);
var
   w, h, i, j: integer;
begin
   TabSet.Tabs := Notebook.Pages;
   w := imageLIA.Width - 1;
   h := imageLIA.Height - 1;
   for i := 0 to w do
     for j := 0 to h do
         if imageLIA.Picture.Bitmap.Canvas.Pixels[i, j] = clWhite then
            imageLIA.Picture.Bitmap.Canvas.Pixels[i, j] := clBtnFace;
   {$IFDEF WINDOWS}
     BevelMenu.Visible := false;
   {$ENDIF}
   Screen.Cursors[1] := LoadCursor(hInstance, 'HYPER_LINK');
   labelURL.Cursor := 1;
end;

procedure TfrmMain.TabSetClick(Sender: TObject);
begin
   NoteBook.PageIndex := TabSet.TabIndex;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   {Sempre coloque esse comando nesse evento}
    ExpertSystem.AbortConsultation;
end;

{===================================================================
                          COMANDOS DE MENUS
 ===================================================================}

procedure TfrmMain.mnuOpenClick(Sender: TObject);
begin
   if OpenDialog.Execute then begin
      if FileExists(OpenDialog.FileName) then begin
         ExpertPrompt.VarCode := 0;
         LabelQuestion.VarCode := 0;
         ExpertSystem.FileName := OpenDialog.FileName;
         if ExpertSystem.FileName <> '' then begin
            if ExpertSystem.Info.Name <> '' then
               Caption := ExpertSystem.Info.Name
            else
               Caption := Application.Title;
         end
         else begin
            MessageDlg('Este arquivo não é válido!', mtError, [mbOk], 0);
            Caption := Application.Title;
         end;
         ResizePanelQuestion;
      end
      else
         MessageDlg('Arquivo inexistente!', mtError, [mbOk], 0);
   end;
end;

procedure TfrmMain.mnuExitClick(Sender: TObject);
begin
    Close;
end;

procedure TfrmMain.mnuConsultClick(Sender: TObject);
begin
   {Esse é uma maneira fácil de sincronizar um menu com um
    navegador, que é autoajustável}
   with ExNavigator do begin
      mnuGo.Enabled := btnGo.Enabled;
      mnuBack.Enabled := btnBack.Enabled;
      mnuStep.Enabled := btnStep.Enabled;
      mnuPause.Enabled := btnPause.Enabled;
      mnuStop.Enabled := btnStop.Enabled;
   end;
end;

procedure TfrmMain.mnuGoClick(Sender: TObject);
begin
    ExNavigator.btnGo.Click;
end;

procedure TfrmMain.mnuBackClick(Sender: TObject);
begin
    ExNavigator.btnBack.Click;
end;

procedure TfrmMain.mnuStepClick(Sender: TObject);
begin
    ExNavigator.btnStep.Click;
end;

procedure TfrmMain.mnuPauseClick(Sender: TObject);
begin
    ExNavigator.btnPause.Click;
end;

procedure TfrmMain.mnuStopClick(Sender: TObject);
begin
    ExNavigator.btnStop.Click;
end;

procedure TfrmMain.btnShowDebugClick(Sender: TObject);
begin
   panelInfo.Visible := not panelInfo.Visible;
   WinSplit.Enabled := not WinSplit.Enabled;
   if ExpertSystem.Trace then ExpertSystem.ResumeEngine;
end;

procedure TfrmMain.mnuAboutClick(Sender: TObject);
begin
   with TdialogAbout.Create(Self) do begin
      ShowModal;
      Free;
   end;
end;

{===================================================================
                   EVENTOS SOBRE O SISTEMA ESPECIALISTA
 ===================================================================}

procedure TfrmMain.ExpertSystemStart(Sender: TObject);
begin
   {Sempre limpe todas as ConsultTree no começo de uma consulta}
   frmResults.ConsultTree.Clear;
   btnOk.Enabled := true;
   btnWhy.Enabled := true;
   btnOpen.Enabled := false;
   mnuOpen.Enabled := false;
end;

procedure TfrmMain.ExpertSystemFinish(Sender: TObject);
begin
    btnOk.Enabled := false;
    btnWhy.Enabled := false;
    btnOpen.Enabled := true;
    mnuOpen.Enabled := true;
end;

procedure TfrmMain.ExpertSystemPause(Sender: TObject);
begin
   {Mostra o depurador sempre que entra em pausa}
   if not panelInfo.Visible then btnShowDebug.Click;
end;

procedure TfrmMain.ExpertSystemPrompt(Sender: TObject; V: Integer);
begin
   labelQuestion.VarCode := V;
   ResizePanelQuestion;
   ExpertPrompt.VarCode := V;
end;

procedure TfrmMain.btnOKClick(Sender: TObject);
begin
   {Se você está usando prompts customizados, NUNCA esqueça de colocar,
    em algum ponto do código, essa ação}
   ExpertPrompt.UpdateBase;
   {Libera a máquina de inferência}
   ExpertSystem.WaitingAnswer := false;
end;

procedure TfrmMain.btnWhyClick(Sender: TObject);
begin
   WhyDialog.Execute(ExpertPrompt.VarCode, ExpertSystem);
end;

procedure TfrmMain.ExpertSystemShowResults(Sender: TObject; V: Integer);
begin
   with frmResults do begin
      var_code := v; {Usada na ajuda on-line}
      panelVarName.Caption := ExpertSystem.VarName(v);
      ValuesGrid.VarCode := v;
      ValuesGrid.RefreshValues;
      {Observe que, uma vez preenchida uma ConsultTree, outra não poderá
       ser utilizada, ou seja, todas as informações daquela busca de um
       objetivo são "descarregadas" em ConsultTree. Para replicar itens
       de uma ConsultTree em outra, consulte a ajuda para as classes
       TOutline (Delphi 1.x) ou TTreeView (Delphi 2.0 ou superior)}
      ConsultTree.CreateTree(ExpertSystem);
      AllVars.CreateTree(ExpertSystem);
      Notebook.PageIndex := 0;
      TabSet.TabIndex := 0;
      ShowModal;
   end;
end;

{===================================================================
                                 ETC.
 ===================================================================}

procedure TfrmMain.ResizePanelQuestion;
begin
   {labelQuestion tem AutoResize = true}
   labelQuestion.Width := panelQuestion.Width - 4;
   panelQuestion.Height := labelQuestion.Height + 4;
end;

procedure TfrmMain.panelWorkSpaceResize(Sender: TObject);
var
   temp_caption: string;
begin
   {Use novamente BuildOptions para centralizar as opções do
    ExpertPrompt}
   btnOk.Left := trunc((panelEnter.Width - 1.5 * btnOk.Width - 20) / 2);
   btnWhy.Left := btnOk.Left + btnOk.Width + 10;
   temp_caption := labelQuestion.Caption;
   labelQuestion.Caption := '';
   labelQuestion.Width := panelQuestion.Width - 4;
   labelQuestion.Caption := temp_caption;
   labelQuestion.Width := panelQuestion.Width - 4;
   panelQuestion.Height := labelQuestion.Height + 4;
   ExpertPrompt.ArrangeOptions;
end;

procedure TfrmMain.labelURLClick(Sender: TObject);
begin
   ShellExecute(Handle, 'open', 'http://www.lia.ufc.br',
                nil, nil, SW_SHOW);
end;

end.
