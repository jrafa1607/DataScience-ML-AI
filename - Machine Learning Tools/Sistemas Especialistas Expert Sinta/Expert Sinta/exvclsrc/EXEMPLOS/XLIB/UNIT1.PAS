unit Unit1;

interface

uses
  Wintypes, WinProcs, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExSystem, StdCtrls, ExCtrls, ExtCtrls, ExCtrls2;

type
  TForm1 = class(TForm)
    ExpertSystem: TExpertSystem;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Notebook1: TNotebook;
    LabelQuestion1: TLabelQuestion;
    LabelQuestion2: TLabelQuestion;
    LabelQuestion3: TLabelQuestion;
    Label3: TLabel;
    LabelQuestion4: TLabelQuestion;
    Button1: TButton;
    Button2: TButton;
    Label4: TLabel;
    LabelQuestion5: TLabelQuestion;
    Label6: TLabel;
    LabelQuestion6: TLabelQuestion;
    Label7: TLabel;
    LabelQuestion7: TLabelQuestion;
    LabelQuestion8: TLabelQuestion;
    LabelQuestion9: TLabelQuestion;
    Button3: TButton;
    ExpertPrompt3: TListExpertPrompt;
    ExpertPrompt1: TListExpertPrompt;
    ExpertPrompt2: TListExpertPrompt;
    ExpertPrompt4: TListExpertPrompt;
    ExpertPrompt5: TListExpertPrompt;
    ExpertPrompt6: TListExpertPrompt;
    ExpertPrompt7: TListExpertPrompt;
    ExpertPrompt8: TListExpertPrompt;
    ExpertPrompt9: TListExpertPrompt;
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
