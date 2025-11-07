{=============================================
 * Expert SINTA Visual Component Library *

 Module name: ExDlgWhy.pas
 Abstract:
      Uma caixa de diálogo que monta uma
      explicação para uma determinada pergunta
      ou exibe uma correspondente criada pelo
      desenvolvedor da base de conhecimento.
 Componente: TWhyDialog
 Implementação: Ricardo Bezerra
 Design de interface: Ricardo Bezerra
 Data de início: 12 de janeiro de 1996
 Data de término: 12 de janeiro de 1996
 Última modificação: 15 de setembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =============================================}
unit ExDlgWhy;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExDataSt, ExSystem;

const
   THIS_IS_A_TARGET_STRING = 'Este é um dos objetivos do sistema.';
   TO_CONCLUDE_STRING = 'Para concluir';
   I_NEED_TO_KNOW_STRING = 'eu preciso saber se';

type
  TdlgWhy = class(TForm)
    btnOk: TBitBtn;
    memo: TMemo;
    procedure memoKeyPress(Sender: TObject; var Key: Char);
  public
    procedure MakeExplanation(v: integer; ES: TExpertSystem);
  end;

  TWhyDialog = class(TComponent)
  public
    function Execute(v: integer; ES: TExpertSystem): boolean;
  end;

implementation

{$R *.DFM}

procedure TdlgWhy.memoKeyPress(Sender: TObject; var Key: Char);
begin
   Key := char(0);
end;

{Gera um "porquê" do motivo daquela pergunta}
procedure TdlgWhy.MakeExplanation(v: integer; ES: TExpertSystem);
var
   head_bookmark, tail_bookmark: TMetaNode;
   the_rule: integer;
begin
   memo.Lines.Clear;
   ES.Questions.Seek(v);
   if (not ES.Questions.Blind) and (ES.Questions.Why.Count > 0) then
      memo.Lines.AddStrings(ES.Questions.Why)
   else begin
      if not ES.CanView then Exit;
      if ES.Tails.CurrentNode = nil then begin
         {Não existe regra que explique o motivo desta pergunta. Isto
          pode ser devido ao fato de que esta variável é um objetivo
          ou por uma chamada indevida a esta função}
          memo.Lines.Add(THIS_IS_A_TARGET_STRING);
          Exit;
      end;
      head_bookmark := ES.Heads.CurrentNode;
      tail_bookmark := ES.Tails.CurrentNode;
      the_rule := ES.Tails.CurrentNode.node.Code;
      ES.BookmarkVar;
      memo.Lines.Add(TO_CONCLUDE_STRING);
      ES.Heads.Seek(the_rule);
      while (not ES.Heads.Blind) and (ES.Heads.Code = the_rule) do begin
         ES.Vars.Seek(ES.Heads.VarCode);
         memo.Lines.Add(' -  ' + ES.Vars.Name + ' = ' + ES.RealValue(ES.Heads.ValCode));
         ES.Heads.MoveNext;
      end;
      memo.Lines.Add(I_NEED_TO_KNOW_STRING);
      ES.Tails.Seek(the_rule);
      while (not ES.Tails.Blind) and (ES.Tails.Code = the_rule) do begin
         ES.Vars.Seek(ES.Tails.VarCode);
         if ES.Vars.Code = v then
            memo.Lines.Add('==> ' + ES.Vars.Name + ' ' + ES.Tails.Operator
                                     + ' '  + ES.RealValue(ES.Tails.ValCode))
         else
            memo.Lines.Add(' -  ' + ES.Vars.Name + ' ' + ES.Tails.Operator
                                     + ' ' + ES.RealValue(ES.Tails.ValCode));
         ES.Tails.MoveNext;
      end;
      ES.Heads.CurrentNode := head_bookmark;
      ES.Tails.CurrentNode := tail_bookmark;
      ES.RestoreVarFromBookmark;
   end;
end;

function TWhyDialog.Execute(v: integer; ES: TExpertSystem): boolean;
var
   DlgWhy: TDlgWhy;
begin
   DlgWhy := TDlgWhy.Create(Application);
   try
      if (ES <> nil) and (not ES.EmptyBase) then begin
         DlgWhy.MakeExplanation(v, ES);
         DlgWhy.ShowModal;
         Result := true;
      end
      else
         Result := false;
   finally
      DlgWhy.Free;
   end;
end;

end.
