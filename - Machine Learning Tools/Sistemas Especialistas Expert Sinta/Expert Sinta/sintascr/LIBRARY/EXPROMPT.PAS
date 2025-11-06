{===========================================
 * Expert SINTA Visual Component Library *

 Module name: ExPrompt.pas
 Abstract:
   Formulário de perguntas ao usuário
   default para o component TExpertSystem.
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
                      Ricardo Silvestre
 Data de início: 12 de outubro de 1996
 Data de término: 12 de outubro de 1996
 Última modificação: 03 de maio de 1998
 Expert SINTA (c) 1995-1998 Grupo SINTA/LIA
 ===========================================}
unit ExPrompt;

interface

uses
   {$IFDEF WIN32}
      ComCtrls,
   {$ENDIF}
   WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
   StdCtrls, ExtCtrls, ExSystem, ExConsts, ExDlgWhy, ExCtrls;

   {$IFDEF WIN32}
      {$H-} {Desliga as huge strings}
   {$ENDIF}

const
   PROMPT_MARGINS = 40;
   WHAT_IS_THE_VALUE_OF_STRING = 'Qual o valor de ';
   ANY_CHOICE_STRING = '(Marque quantas alternativas desejar)';
   ONE_CHOICE_STRING = '(Marque somente uma alternativa)';
   ENTER_NUMBER_STRING = '(Entre um valor numérico)';
   MAX_VALUE_STRING = 'Valor máximo';
   MIN_VALUE_STRING = 'Valor mínimo';
   VALUES_RANGE_STRING = '(Coloque na faixa abaixo de valores)';

type

  TRunTime = class(TForm)
    btnOk: TBitBtn;
    btnWhy: TBitBtn;
    Frame3D: TGroupBox;
    labelQuestion: TLabel;
    labelInfo: TLabel;
    panelOption: TPanel;
    panelCnf: TPanel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOkClick(Sender: TObject);
    procedure btnWhyClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    ES: TExpertSystem;
    expert_prompt: TExpertPrompt;
    dialogWhy: TdlgWhy;
    function  CaptionSize: integer;
  public
    procedure Init(E: TExpertSystem);
    procedure StartInformation(VarCode: integer);
    procedure BuildOptions(v: integer);
  end;

implementation

uses
   Dialogs, SysUtils, ExDataSt;

{$R *.DFM}

{======================================================================
 ======================================================================
                            CLASSE TRUNTIME
 ======================================================================
 ======================================================================}

procedure TRunTime.FormCreate(Sender: TObject);
begin
   dialogWhy := TdlgWhy.Create(Self);
   expert_prompt := TExpertPrompt.Create(Self);
   expert_prompt.MaxHeight := Screen.Height - 200;
   expert_prompt.BorderStyle := bsNone;
   expert_prompt.AutoSize := true;
   expert_prompt.Parent := Self;
end;

procedure TRunTime.Init(E: TExpertSystem);
begin
   ES := E;
   if ES.Info.Name <> '' then Caption := ES.Info.Name;
   expert_prompt.ExpertSystem := ES;
end;

procedure TRunTime.FormShow(Sender: TObject);
begin
   with expert_prompt do begin
      if editValue.visible and editValue.enabled then
         editValue.SelectAll
      else
         ClearCNFs;
   end;
end;

procedure TRunTime.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   if not ES.DontConfirmOnAbort then begin
      if MessageDlg(CONFIRM_CANCEL_STRING, mtConfirmation,
         [mbYes, MbNo], 0) = mrNo then begin
         CanClose := false;
         ES.Quit := false;
         if ES.Trace then ES.Wait := true;
      end
      else
         ES.AbortConsultation;
   end;
end;

procedure TRunTime.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   if (not ES.Quit) and (ES.ReportEnding) then
      ShowMessage(CONSULTATION_END_STRING);
   ES.AbortConsultation;
end;

procedure TRunTime.FormDestroy(Sender: TObject);
begin
   expert_prompt.Free;
   dialogWhy.Free;
end;

{Se o desenvolvedor houver colocado um valor para a pergunta sobre "var",
 o programa a utiliza. Caso contrário, faz uma pergunta genérica.}
procedure TRunTime.StartInformation(VarCode: integer);
begin
   ES.BookmarkVar;
   if ES.Vars.Blind or (ES.Vars.Code <> VarCode) then ES.Vars.Seek(VarCode);
   panelOption.Visible := true;
   panelCnf.Visible := true;
   ES.Questions.Seek(VarCode);
   if ES.Questions.Blind then begin
      labelQuestion.Caption := WHAT_IS_THE_VALUE_OF_STRING + ES.Vars.Name + ' ?';
      if ES.Permission = ONLY_EXECUTE then
         btnWhy.Visible := False
      else
         btnWhy.Visible := true;
   end
   else begin
      labelQuestion.Caption := ES.Questions.question;
      if (ES.Questions.Why.Count = 0) and (ES.Permission = ONLY_EXECUTE) then
         btnWhy.Visible := False
      else
         btnWhy.Visible := true;
   end;
   if ES.Vars.Multi then
      labelInfo.Caption := ANY_CHOICE_STRING
   else begin
      if ES.Vars.Numeric then begin
         panelOption.Visible := false;
         panelCnf.Visible := false;
         ES.Values.Seek(ES.Vars.Code);
         if ES.Values.Blind then
            labelInfo.Caption := ENTER_NUMBER_STRING
         else begin
            if ES.Values.Name[1] = ';' then
               {É um intervalo do tipo "MAIOR QUE..."}
               labelInfo.Caption := '(' + MAX_VALUE_STRING + ': ' +
                                    Copy(ES.Values.Name, 2, length(ES.Values.Name))
                                    + ')'
            else begin
               if ES.Values.Name[length(ES.Values.Name)] = ';' then
                 {É um intervalo do tipo "MENOR QUE..."}
                 labelInfo.Caption := '(' + MIN_VALUE_STRING + ': ' + Copy(ES.Values.Name, 1,
                                      length(ES.Values.Name) - 1) + ')'
               else
                 {É um intervalo do tipo "MAIOR QUE, MENOR QUE..."}
                 labelInfo.Caption := VALUES_RANGE_STRING;
            end;
         end;
      end
      else
         labelInfo.Caption := ONE_CHOICE_STRING;
   end;
   ES.RestoreVarFromBookmark;
end;

{Retorna o tamanho do caption da janela.}
function TRunTime.CaptionSize: integer;
var
   answer: integer;
begin
   Canvas.Font.Style := [];
   Canvas.Font.Name := 'System';
   answer := Canvas.TextWidth(Caption) + 33;
   Canvas.Font.Style := [fsBold];
   Canvas.Font.Name := 'MS Sans Serif';
   Canvas.Font.Size := 12;
   Result := answer;
end;

procedure TRunTime.BuildOptions(v: integer);

   function Max(a, b: integer): integer;
   begin
      if a > b then
         Result := a
      else
         Result := b;
   end;

begin
   expert_prompt.MinWidth := Max(CaptionSize - PROMPT_MARGINS, 400);
   expert_prompt.MaxWidth := Screen.Width - PROMPT_MARGINS;
   expert_prompt.VarCode := v;
   Width := expert_prompt.Width + PROMPT_MARGINS;
   labelQuestion.Width := Width - 4;
   StartInformation(v);
   labelQuestion.Width := Width - 4;
   labelQuestion.Left := 2;
   labelInfo.Top := labelQuestion.Top + labelQuestion.Height;
   labelInfo.Left := 0;
   labelInfo.Width := Width;
   Left := trunc((Screen.Width - Width) / 2);
   Frame3D.Top := labelInfo.Top + labelInfo.Height + 7;
   Frame3D.Width := expert_prompt.Width + 5;
   Frame3D.Height := labelInfo.Height + expert_prompt.Height + 4;
   expert_prompt.Top := Frame3D.Top + labelInfo.Height;
   expert_prompt.Left := Width - trunc(PROMPT_MARGINS / 2) - expert_prompt.Width - 2;
   Frame3D.Left := expert_prompt.Left - 3;
   panelOption.Left := Frame3D.Left + 10;
   panelOption.Top := Frame3D.Top - 2;
   panelCNF.Top := panelOption.Top;
   btnOK.Top := Frame3D.Top + Frame3D.Height + DEFAULT_ITEMTOP;
   if btnWhy.Visible then begin
      dialogWhy.MakeExplanation(v, ES);
      btnOK.Left := trunc((Width - (2 * btnOK.Width + 50)) / 2);
      btnWhy.Top := btnOK.Top;
      btnWhy.Left := btnOk.Left + btnOk.Width + 50;
   end
   else
      btnOK.Left := trunc((Width - btnOK.Width) / 2);
   Height := btnOK.Top + trunc(2.3 * btnOK.Height);
   Top := trunc((Screen.Height - Height) / 2);
   panelCNF.Left := Frame3D.Left + Frame3D.Width - panelCnf.Width - 5;
end;

procedure TRunTime.btnOkClick(Sender: TObject);
begin
  if expert_prompt.UpdateBase then begin
     Hide;
     ES.WaitingAnswer := false;
  end;
end;

procedure TRunTime.btnWhyClick(Sender: TObject);
begin
   dialogWhy.ShowModal;
end;

end.
