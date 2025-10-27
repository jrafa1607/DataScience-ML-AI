{========================================================
 * Expert SINTA RunTime *

 Descrição:
    Programa para consultar bases de conhecimento criadas
    com o Expert SINTA sem necessidade do ambiente de
    edição. Runtime construído especialmente para avaliar
    e demonstrar a Expert SINTA Visual Component Library.
    O código fonte deste runtime é de domínio público.
 Ambiente de programação:
    Borland Delphi 1.0

 Implementação: Ricardo Bezerra
 Data de início: 19 de março de 1997
 Data de término: 20 de março de 1997
 Última modificação: 20 de março de 1997
 Expert SINTA RunTime(c) 1995-1997
 Expert SINTA Visual Component Library (c) 1995-1997
 Laboratório de Inteligência Artificial/LIA
 Universidade Federal do Ceará
 ========================================================}
program ExRT16;

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  Results in 'Results.pas' {frmResults},
  About in 'About.pas'; {dialogAbout}

{$R *.RES}

begin
  Application.Title := 'Expert SINTA RunTime';
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmResults, frmResults);
  Application.Run;
end.
