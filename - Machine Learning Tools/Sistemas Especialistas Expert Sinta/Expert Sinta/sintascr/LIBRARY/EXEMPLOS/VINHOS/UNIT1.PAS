unit Unit1;

interface

uses
  Wintypes, WinProcs, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExSystem, StdCtrls, ExCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    ExpertSystem: TExpertSystem;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Notebook1: TNotebook;
    LabelQuestion1: TLabelQuestion;
    ExpertPrompt1: TExpertPrompt;
    LabelQuestion2: TLabelQuestion;
    LabelQuestion3: TLabelQuestion;
    Label3: TLabel;
    LabelQuestion4: TLabelQuestion;
    ExpertPrompt3: TExpertPrompt;
    Button1: TButton;
    Button2: TButton;
    ExpertPrompt2: TExpertPrompt;
    Label4: TLabel;
    LabelQuestion5: TLabelQuestion;
    ExpertPrompt4: TExpertPrompt;
    Label6: TLabel;
    ExpertPrompt5: TExpertPrompt;
    LabelQuestion6: TLabelQuestion;
    ExpertPrompt6: TExpertPrompt;
    Label7: TLabel;
    LabelQuestion7: TLabelQuestion;
    ExpertPrompt7: TExpertPrompt;
    LabelQuestion8: TLabelQuestion;
    ExpertPrompt8: TExpertPrompt;
    LabelQuestion9: TLabelQuestion;
    ExpertPrompt9: TExpertPrompt;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ExpertSystemStart(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ExpertSystemFinish(Sender: TObject);
    procedure ExpertSystemShowResults(Sender: TObject; V: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
    Results;

{$R *.DFM}

procedure TForm1.Button1Click(Sender: TObject);
begin
   Notebook1.PageIndex := Notebook1.PageIndex - 1;
   if Notebook1.PageIndex = 0 then Button1.Enabled := false;
   Button2.Enabled := true;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
   Notebook1.PageIndex := Notebook1.PageIndex + 1;
   if Notebook1.PageIndex = 2 then begin
      Button2.Enabled := false;
      Button3.Enabled := true;
   end;
   Button1.Enabled := true;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
   ExpertSystem.StartConsultation;
end;

procedure TForm1.ExpertSystemStart(Sender: TObject);
begin
   frmResults.ConsultTree.Clear;
   ExpertPrompt1.UpdateBase;
   ExpertPrompt2.UpdateBase;
   ExpertPrompt3.UpdateBase;
   ExpertPrompt4.UpdateBase;
   ExpertPrompt5.UpdateBase;
   ExpertPrompt6.UpdateBase;
   ExpertPrompt7.UpdateBase;
   ExpertPrompt8.UpdateBase;
   ExpertPrompt9.UpdateBase;
end;

procedure TForm1.ExpertSystemFinish(Sender: TObject);
begin
   Button1.Enabled := false;
   Button2.Enabled := true;
   Button3.Enabled := false;
   Notebook1.PageIndex := 0;
end;

procedure TForm1.ExpertSystemShowResults(Sender: TObject; V: Integer);
begin
   with frmResults do begin
      var_code := v;
      ValuesGrid.VarCode := v;
      ValuesGrid.RefreshValues;
      ConsultTree.CreateTree(ExpertSystem);
      AllVars.CreateTree(ExpertSystem);
      Notebook.PageIndex := 0;
      TabSet.TabIndex := 0;
      ShowModal;
   end;
end;

end.
