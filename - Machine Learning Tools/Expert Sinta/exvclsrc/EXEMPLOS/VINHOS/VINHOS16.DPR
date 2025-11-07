program Vinhos16;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Results in 'Results.pas' {frmResults};

{$R *.RES}

begin
  Application.Title := 'Expert SINTA VCL Demo';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TfrmResults, frmResults);
  Application.Run;
end.
