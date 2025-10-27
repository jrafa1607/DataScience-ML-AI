{===============================================
 UNIDADE/FORMULÁRIO de créditos
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Descrição: Esta janela exibe o nome dos autores
            do Expert SINTA e dos criadores dos
            componentes utilizados.
 Data de início: 01 de agosto de 1997
 Data de término: 01 de agosto de 1997
 Última modificação: 14 de outubro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ===============================================}

unit Credits;

interface

uses
  Wintypes, WinProcs, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TdialogCredits = class(TForm)
    btnOK: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label1: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label6: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    labelURL1: TLabel;
    labelURL2: TLabel;
    labelURL3: TLabel;
    labelURL4: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    labelURL6: TLabel;
    labelURL5: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure labelURLClick(Sender: TObject);
  end;

var
  dialogCredits: TdialogCredits;

implementation

uses
   ShellAPI;
   
{$R *.DFM}

procedure TdialogCredits.FormCreate(Sender: TObject);
begin
   Screen.Cursors[2] := LoadCursor(hInstance, 'HYPER_LINK');
   labelURL1.Cursor := 2;
   labelURL2.Cursor := 2;
   labelURL3.Cursor := 2;
   labelURL4.Cursor := 2;
   labelURL5.Cursor := 2;
   labelURL6.Cursor := 2;
end;

procedure TdialogCredits.FormClose(Sender: TObject;
          var Action: TCloseAction);
begin
   Action := caFree;
end;

procedure TdialogCredits.btnOKClick(Sender: TObject);
begin
   Close;
end;

procedure TdialogCredits.labelURLClick(Sender: TObject);
var
   URL: string[255];
begin
   (Sender as TLabel).Font.Color := clPurple;
   Screen.Cursor := crHourglass;
   URL := (Sender as TLabel).Caption + #0;
   ShellExecute(Handle, 'open', @URL[1], nil, nil, SW_SHOW);
   Screen.Cursor := crDefault;
end;

end.
