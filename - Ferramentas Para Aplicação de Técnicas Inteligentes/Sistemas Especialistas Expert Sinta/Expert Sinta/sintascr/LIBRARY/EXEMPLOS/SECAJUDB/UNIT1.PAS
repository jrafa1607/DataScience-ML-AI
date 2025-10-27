unit Unit1;

interface

uses
  Wintypes, Winprocs, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExSystem, ExtCtrls, ExCtrls, StdCtrls, Db, DBTables, Grids;

type
  TForm1 = class(TForm)
    ExpertSystem: TExpertSystem;
    TableCasos: TTable;
    DebugPanel: TDebugPanel;
    memoResults: TMemo;
    TableClientes: TTable;
    Panel1: TPanel;
    Label1: TLabel;
    btnStart: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure ExpertSystemPrompt(Sender: TObject; V: Integer);
    procedure ExpertSystemShowResults(Sender: TObject; V: Integer);
    procedure ExpertSystemStart(Sender: TObject);
    procedure ExpertSystemFinish(Sender: TObject);
  public
    function GetValueFromTable(V: integer): integer;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
begin
   TableCasos.Open;
   TableClientes.Open;
end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
   memoResults.Clear;
   TableCasos.First;
   while not TableCasos.EOF do begin
      ExpertSystem.StartConsultation;
      TableCasos.Next;
   end;
   ShowMessage('Todas as consultas finalizadas!');
end;

procedure TForm1.ExpertSystemStart(Sender: TObject);
begin
   TableClientes.FindKey([TableCasos.Fields[0].AsString]);
   memoResults.Lines.Add('=====================================');
   memoResults.Lines.Add('Cliente: ' + TableClientes.FieldByName('NOME_CLIENTE').AsString);
end;

procedure TForm1.ExpertSystemShowResults(Sender: TObject; V: Integer);
var
   i, total: integer;
   values_list, cnfs_list: TStringList;
begin
   values_list := TStringList.Create;
   cnfs_list := TStringList.Create;
   try
      memoResults.Lines.Add('');
      memoResults.Lines.Add(ExpertSystem.VarName(V));
      ExpertSystem.VarInstances(V, values_list, cnfs_list);
      total := values_list.Count - 1;
      for i := 0 to total do
          memoResults.Lines.Add('  ' + values_list[i]);
   finally
      values_list.Free;
      cnfs_list.Free;
   end;
end;

procedure TForm1.ExpertSystemFinish(Sender: TObject);
begin
    memoResults.Lines.Add('');
end;

procedure TForm1.ExpertSystemPrompt(Sender: TObject; V: Integer);
begin
    ExpertSystem.AttribVarFromBinary(V, GetValueFromTable(V));
    ExpertSystem.WaitingAnswer := false;
end;

function TForm1.GetValueFromTable(V: integer): integer;

   function VarMap(V: integer): integer;
   begin
      Result := V - 4;
   end;

begin
   Result := TableCasos.Fields[VarMap(V)].AsInteger;
end;

end.
