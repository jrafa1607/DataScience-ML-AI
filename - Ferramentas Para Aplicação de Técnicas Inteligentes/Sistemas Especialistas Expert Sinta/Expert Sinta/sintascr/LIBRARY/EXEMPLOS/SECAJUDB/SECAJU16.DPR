program SECAJU16;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.RES}

begin
  Application.Title := 'Expert SINTA VCL Demo';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
