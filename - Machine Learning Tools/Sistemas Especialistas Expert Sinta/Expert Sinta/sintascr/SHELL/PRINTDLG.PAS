{=====================================================
 UNIDADE/FORMULÁRIO para exibir o status da impressão
 Implementação: Ricardo Bezerra
 Descrição: Exibe o status de uma impressão em
           andamento;
 Data de início: 09 de setembro de 1996
 Data de término: 09 de setembro de 1996
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =====================================================}
unit PrintDlg;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, SysUtils;

type
  TdialogPrint = class(TForm)
    labelInfo: TLabel;
    labelPrinter: TLabel;
    btnCancel: TButton;
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  end;

implementation

uses
   Export, Printers;

{$R *.DFM}

procedure TdialogPrint.FormShow(Sender: TObject);
var
  buffer1, buffer2, buffer3: array[0..255] of char;
  ADeviceMode: THandle;
  ADevice, ADriver, Port: PChar;
begin
   abort_printing := false;
   ADevice := @buffer1[0];
   ADriver := @buffer2[0];
   Port := @buffer3[0];
   Printer.GetPrinter(ADevice, ADriver, Port, ADeviceMode);
   labelPrinter.Caption := StrPas(ADevice) + ' em ' + StrPas(Port);
end;

procedure TdialogPrint.btnCancelClick(Sender: TObject);
begin
   abort_printing := true;
end;

procedure TdialogPrint.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
   Action := caFree;
end;

end.
