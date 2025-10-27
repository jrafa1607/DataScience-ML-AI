{============================================
 UNIDADE/FORMULÁRIO de adição de variáveis
 para rastreamento
 Implementação: Ricardo Bezerra
 Descrição: Permite a seleção de um conjunto
            de variáveis a serem acompanhadas
            pela janela "Watch".
 Design de interface: Ricardo Bezerra
 Data de início: 20 de janeiro de 1996
 Data de término: 20 de janeiro de 1996
 Última modificação: 17 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ============================================}
unit AddWVars;

interface

uses
  WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls, ExDataSt, Tabnotbk;

type
  TdialogAddVars = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    TabbedNotebook: TTabbedNotebook;
    listVars: TListBox;
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    bookmark_1, bookmark_2: TMetaNode;
    old_index: integer;
  end;

var
  dialogAddVars: TdialogAddVars;

implementation

uses
   General, WatCode, ExConsts;

{$R *.DFM}

procedure TdialogAddVars.FormShow(Sender: TObject);
begin
   with ExSys.Vars do begin
      bookmark_1 := CurrentNode;
      bookmark_2 := CurrentNodeName;
      old_index := CurrentKey;
   end;
   listVars.Clear;
   ExSys.Vars.CurrentKey := PRIMARY_KEY;
   ExSys.Vars.MoveFirst;
   {Preenche a lista com variáveis que ainda não estão na janela
    de acompanhamento de variáveis (Watch)}
   while not ExSys.Vars.Blind do begin
      frmWatch.WatchPanel.WatchedVars.Seek(ExSys.Vars.code);
      if frmWatch.WatchPanel.WatchedVars.Blind then
         listVars.Items.Add(ExSys.Vars.Name);
      ExSys.Vars.MoveNext;
   end;
end;

procedure TdialogAddVars.OKBtnClick(Sender: TObject);
var
   total, i: integer;
begin
   total := listVars.Items.Count - 1;
   for i := 0 to total do
       if listVars.Selected[i] then begin
          ExSys.Vars.SeekByName(listVars.Items[i]);
          frmWatch.WatchPanel.AddNewItem(ExSys.Vars.Code);
       end;
end;

procedure TdialogAddVars.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  {Era necessário ter salvo as posições de Vars porque essa janela
   pode a vir ser chamada durante uma pergunta}
   with ExSys.Vars do begin
      CurrentNode := bookmark_1;
      CurrentNodeName := bookmark_2;
      CurrentKey := old_index;
   end;
end;

end.
