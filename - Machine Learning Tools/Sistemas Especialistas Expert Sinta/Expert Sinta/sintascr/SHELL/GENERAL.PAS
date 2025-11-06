{==========================================
 UNIDADE de declarações gerais
 Implementação: Ricardo Bezerra
                Ricardo Silvestre
 Descrição: Nesta unidade são colocadas as
            variáveis globais e funções de
            uso geral.
 Data de início: 23 de dezembro de 1995
 Data de término: 18 de janeiro de 1996
 Última modificação: 04 de agosto de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ==========================================}
unit General;

interface

uses
   Classes, Dialogs, SysUtils, ExSystem;

var

  ExSys: TExpertSystem;

  loaded_rules: TStringList;

  {Flags indicando que janelas do editor de bases de conhecimento
   estão abertas}
  base_opened: boolean;
  var_opened: boolean;
  target_opened: boolean;
  question_opened: boolean;
  info_opened: boolean;
  file_chosen: string;

  {Indica o diretório do último arquivo aberto. Uma funcionalidade que
   todo aplicativo deveria ter (não um besteirol de "Meus Documentos"...)}
  save_folder: string;
  {Flag indicando se a janela de "Dica do Dia" deve aparecer no início}
  show_tips: boolean;
  {Última "Dica do Dia" exibida}
  current_tip: integer;

procedure InitExpertSystem;

procedure WriteGeneralINIConfig;
procedure ReadGeneralINIConfig;
procedure WriteLastUsedFile;
procedure ReadLastUsedFile;

procedure DeleteRule(rule: integer);
procedure DeleteOnlySentences(rule: integer);
procedure DeleteVar(v: integer);
procedure DeleteValue(v: integer);
procedure DeleteQuestion(q: integer);
procedure DeleteTarget(t: integer);
procedure DefinePositions(min: integer; delta: integer; max: integer);

function  MyFloatToStr(r: real): string;
function  Space(size: integer): string;
function  ExcludeBlankSpaces(s: string): string;
function  GetColorsCount : integer;
procedure TipOfTheDay;

implementation

uses
   IniFiles, Main, Forms, Totd, ExDataSt, WatCode, ExConsts,
   Wintypes, Winprocs
   {$IFDEF WIN32}
     ,TB97
   {$ENDIF};

{======================================================================
 ======================================================================
                             INICIALIZAÇÃO
 ======================================================================
 ======================================================================}

procedure InitExpertSystem;
begin
   ExSys := TExpertSystem.Create(frmMain);
   ExSys.AfterCheckPassword := frmMain.AfterCheckPassword;
   ExSys.OnStart := frmMain.OnStart;
   ExSys.OnPrompt := frmMain.OnPrompt;
   ExSys.OnShowResults := frmMain.OnShowResults;
   ExSys.OnFinish := frmMain.OnFinish;
end;

{======================================================================
 ======================================================================
                       INFORMAÇÕES DE CONFIGURAÇÃO
 ======================================================================
 ======================================================================}

{Esse procedimento grava as configurações gerais no arquivo .INI
 do Expert SINTA}
procedure WriteGeneralINIConfig;
var
  SINTAIni: TIniFile;

  {$IFDEF WIN32}
  procedure WriteToolBarConfig(key: string; bar: TToolBar97);
  begin
   with SINTAIni do begin
     WriteInteger(key, 'Cima', bar.Top);
     WriteInteger(key, 'Esquerda', bar.Left);
     WriteInteger(key, 'Largura', bar.Width);
     WriteInteger(key, 'Altura', bar.Height);
     if bar.DockedTo <> nil then
        WriteInteger(key, 'Dock', bar.DockedTo.Tag)
     else
        WriteInteger(key, 'Dock', 0);
     WriteInteger(key, 'Linha', bar.DockRow);
     WriteInteger(key, 'Posição dock', bar.DockPos);
     WriteBool(key, 'Visível', bar.Visible);
   end;
  end;
  {$ENDIF}

begin
  SINTAIni := TIniFile.Create('EXSINTA.INI');
  with SINTAIni do begin
     WriteInteger('Janela Principal', 'Cima', frmMain.Top);
     WriteInteger('Janela Principal', 'Esquerda', frmMain.Left);
     WriteInteger('Janela Principal', 'Largura', frmMain.Width);
     WriteInteger('Janela Principal', 'Altura', frmMain.Height);
     if frmMain.WindowState = wsNormal then
        WriteInteger('Janela Principal', 'Estado', 0)
     else begin
        if frmMain.WindowState = wsMaximized then
           WriteInteger('Janela Principal', 'Estado', 1)
        else
           WriteInteger('Janela Principal', 'Estado', 2);
     end;
     WriteString('Geral', 'Pasta de trabalho', save_folder);
     WriteBool('Geral', 'Dica do dia', show_tips);
     WriteInteger('Geral', 'Última dica do dia', current_tip);
     {$IFDEF WIN32}
     WriteToolBarConfig('Ferramentas arquivo', frmMain.XToolBarFile);
     WriteToolBarConfig('Ferramentas consulta', frmMain.XToolBarConsult);
     WriteToolBarConfig('Ferramentas sistema', frmMain.XToolBarSystem);
     WriteToolBarConfig('Ferramentas ajuda', frmMain.XToolBarHelp);
     {$ENDIF}
     Free;
  end;
end;

{Esse procedimento lê as configurações gerais no arquivo .INI
 do Expert SINTA}
procedure ReadGeneralINIConfig;
var
  SINTAIni: TIniFile;
  estado: integer;

  {$IFDEF WIN32}
  procedure ReadToolBarConfig(key: string; bar: TToolBar97);
  var
     temp: integer;
  begin
   with SINTAIni do begin
     temp := ReadInteger(key, 'Dock', -1);
     case temp of
       0: bar.DockedTo := nil;
       1: bar.DockedTo := frmMain.DocksTop;
       2: bar.DockedTo := frmMain.DocksLeft;
       3: bar.DockedTo := frmMain.DocksRight;
       4: bar.DockedTo := frmMain.DocksBottom;
     end;

     temp := ReadInteger(key, 'Cima', -1);
     if temp <> -1 then bar.Top := temp;

     temp := ReadInteger(key, 'Esquerda', -1);
     if temp <> -1 then bar.Left := temp;

     temp := ReadInteger(key, 'Largura', -1);
     if temp <> -1 then bar.Width := temp;

     temp := ReadInteger(key, 'Altura', -1);
     if temp <> -1 then bar.Height := temp;

     temp := ReadInteger(key, 'Linha', -1);
     if temp <> -1 then bar.DockRow := temp;

     temp := ReadInteger(key, 'Posição dock', -1);
     if temp <> -1 then bar.DockPos := temp;

     bar.Visible := ReadBool(key, 'Visível', true);
   end;
  end;
  {$ENDIF}

begin
  SINTAIni := TIniFile.Create('EXSINTA.INI');
  with SINTAIni do begin
     estado := ReadInteger('Janela Principal', 'Estado', 0);
     case estado of
       0: frmMain.WindowState := wsNormal;
       1: frmMain.WindowState := wsMaximized;
       2: frmMain.WindowState := wsMinimized;
     end;
     if frmMain.WindowState <> wsMaximized then begin
        frmMain.Top := ReadInteger('Janela Principal', 'Cima', 10);
        frmMain.Left := ReadInteger('Janela Principal', 'Esquerda', 10);
        frmMain.Width := ReadInteger('Janela Principal', 'Largura', 500);
        frmMain.Height := ReadInteger('Janela Principal', 'Altura', 200);
     end;
     save_folder := ReadString('Geral', 'Pasta de trabalho', '');
     show_tips := ReadBool('Geral', 'Dica do dia', true);
     current_tip := ReadInteger('Geral', 'Última dica do dia', 0);
     {$IFDEF WIN32}
     ReadToolBarConfig('Ferramentas arquivo', frmMain.XToolBarFile);
     ReadToolBarConfig('Ferramentas consulta', frmMain.XToolBarConsult);
     ReadToolBarConfig('Ferramentas sistema', frmMain.XToolBarSystem);
     ReadToolBarConfig('Ferramentas ajuda', frmMain.XToolBarHelp);
     {$ENDIF}
     Free;
  end;
end;

{Grava no arquivo .INI do Expert SINTA as últimas bases de conhecimento
 utilizadas}
procedure WriteLastUsedFile;
var
   last_files: array[1..4] of string;
   i, position: integer;
   SINTAIni: TIniFile;
begin
  SINTAIni := TIniFile.Create('EXSINTA.INI');
  with SINTAIni do begin
     for i := 1 to 4 do last_files[i] := ReadString('Arquivos', IntToStr(i),'');
     WriteString('Arquivos', '1', AnsiUpperCase(file_chosen));
     position := 2;
     for i := 1 to 3 do begin
         if last_files[i] <> AnsiUpperCase(file_chosen) then begin
            WriteString('Arquivos', IntToStr(position), AnsiUpperCase(last_files[i]));
            position := position + 1;
         end;
     end;
     for i := position to 4 do
         if last_files[i] <> AnsiUpperCase(file_chosen) then
            WriteString('Arquivos', IntToStr(i), last_files[i]);
  end;
end;

{Lê do arquivo .INI do Expert SINTA as últimas bases de conhecimento
 utilizadas}
procedure ReadLastUsedFile;
var
   last_files: array[1..4] of string;
   i, total: integer;
   SINTAIni: TIniFile;
begin
  total := 0;
  SINTAIni := TIniFile.Create('EXSINTA.INI');
  with SINTAIni do begin
     for i := 1 to 4 do begin
         last_files[i] := ReadString('Arquivos', IntToStr(i),'');
         if last_files[i] <> '' then begin
            total := total + 1;
            case total of
             1: begin
                  frmMain.mnuLastFile1.Visible := true;
                  frmMain.mnuLastFile1.Caption := '&1 ' + ExtractFileName(last_files[i]);
                  frmMain.mnuLastFile1.Hint := last_files[i];
                end;
             2: begin
                  frmMain.mnuLastFile2.Visible := true;
                  frmMain.mnuLastFile2.Caption := '&2 ' + ExtractFileName(last_files[i]);
                  frmMain.mnuLastFile2.Hint := last_files[i];
                end;
             3: begin
                  frmMain.mnuLastFile3.Visible := true;
                  frmMain.mnuLastFile3.Caption := '&3 ' + ExtractFileName(last_files[i]);
                  frmMain.mnuLastFile3.Hint := last_files[i];
                end;
             4: begin
                  frmMain.mnuLastFile4.Visible := true;
                  frmMain.mnuLastFile4.Caption := '&4 ' + ExtractFileName(last_files[i]);
                  frmMain.mnuLastFile4.Hint := last_files[i];
                end;
            end;
         end;
     end;
     if total > 0 then frmMain.mnuFileBar.Visible := true;
  end;
end;

{======================================================================
 ======================================================================
                      GERÊNCIA DA BASE DE CONHECIMENTO
 ======================================================================
 ======================================================================}

 {Deleta uma regra da base de conhecimento, incluindo seu nó na
 árvore de regras, nas árvores de cabeças e caudas e na árvore de
 fórmulas}
procedure DeleteRule(rule: integer);
begin
   with ExSys do begin
      Heads.Seek(rule);
      while (not Heads.Blind) and (Heads.Code = rule) do begin
         {Apaga quaisquer fórmulas ligadas}
         if Heads.ValCode <> UNKNOWN then begin
            Vars.Seek(Heads.VarCode);
            if Vars.Numeric then begin
               Formulas.Seek(Heads.ValCode);
               if not Formulas.Blind then Formulas.Delete;
            end;
         end;
         Heads.Delete;
      end;
      Tails.Seek(rule);
      while (not Tails.Blind) and (Tails.Code = rule) do begin
         if Tails.ValCode <> UNKNOWN then begin
            Vars.Seek(Tails.VarCode);
            if Vars.Numeric then begin
               Formulas.Seek(Tails.ValCode);
               if not Formulas.Blind then Formulas.Delete;
            end;
         end;
         Tails.Delete;
      end;
      Rules.Seek(rule);
      Rules.Delete;
   end;
end;

{Semelhante à anterior, mas deleta apenas as cabeças e caudas da regra}
procedure DeleteOnlySentences(rule: integer);
begin
   with ExSys do begin
      Heads.Seek(rule);
      while (not Heads.Blind) and (Heads.Code = rule) do Heads.Delete;
      Tails.Seek(rule);
      while (not Tails.Blind) and (Tails.Code = rule) do Tails.Delete;
   end;
end;

{Deleta uma variável da base de conhecimento, incluindo seu nó na
 árvore de variáveis, seus valores, ponteiros na lista de objetivos e
 quaisquer regras relacionadas}
procedure DeleteVar(v: integer);
var
   to_be_deleted: TSingleIndexTree;
   i: integer;

   procedure MarkItem(c: integer);
   begin
      to_be_deleted.Seek(c);
      if to_be_deleted.Blind then to_be_deleted.Insert(c);
   end;

begin
   with ExSys do begin
      {Deleta regras ligadas}
      to_be_deleted := TSingleIndexTree.Create;
      Tails.MoveFirst;
      while not Tails.Blind do begin
         if Tails.VarCode = v then MarkItem(Tails.Code);
         Tails.MoveNext;
      end;
      Heads.MoveFirst;
      while not Heads.Blind do begin
         if Heads.VarCode = v then MarkItem(Heads.Code);
         Heads.MoveNext;
      end;
      to_be_deleted.MoveFirst;
      while not to_be_deleted.Blind do begin
         DeleteRule(to_be_deleted.Code);
         to_be_deleted.MoveNext;
      end;
      to_be_deleted.Free;

      {Deleta objetivos ligados}
      i := 0;
      while i < Targets.Count do begin
         if Targets.Nodes[i].Code = v then begin
            Targets.Nodes[i].Free;
            Targets.Delete(i);
         end;
         inc(i);
      end;

      {Deleta perguntas ligadas}
      Questions.Seek(v);
      if not Questions.Blind then Questions.Delete;

      {Deleta valores ligados}
      Values.SeekByVar(v);
      while (not Values.Blind) and (Values.VarCode = v) do begin
         {Deleta os contextos de ajuda ligados}
         HelpContexts.Seek(Values.Code);
         if not HelpContexts.Blind then HelpContexts.Delete;
         Values.Delete;
         {Automaticamente o ponteiro passa para o próximo valor}
      end;

      {Deleta itens da janela Watch}
      frmWatch.WatchPanel.DeleteItem(v, '');

      Vars.Seek(v);
      if not Vars.Blind then Vars.Delete;
   end;
end;

{Deleta um valor da base de conhecimento, incluindo quaisquer regras
 relacionadas}
procedure DeleteValue(v: integer);
var
   to_be_deleted: TSingleIndexTree;

   procedure MarkItem(c: integer);
   begin
      to_be_deleted.Seek(c);
      if to_be_deleted.Blind then to_be_deleted.Insert(c);
   end;

begin
   with ExSys do begin
      {Deleta regras ligadas}
      to_be_deleted := TSingleIndexTree.Create;
      Tails.MoveFirst;
      while not Tails.Blind do begin
         if Tails.ValCode = v then MarkItem(Tails.Code);
         Tails.MoveNext;
      end;
      Heads.MoveFirst;
      while not Heads.Blind do begin
         if Heads.ValCode = v then MarkItem(Heads.Code);
         Heads.MoveNext;
      end;
      to_be_deleted.MoveFirst;
      while not to_be_deleted.Blind do begin
         DeleteRule(to_be_deleted.Code);
         to_be_deleted.MoveNext;
      end;
      to_be_deleted.Free;

      {Deleta os contextos de ajuda ligados}
      HelpContexts.Seek(v);
      if not HelpContexts.Blind then HelpContexts.Delete;

      Values.Seek(v);
      if not Values.Blind then Values.Delete;
   end;
end;

{Deleta uma pergunta da base de conhecimento}
procedure DeleteQuestion(q: integer);
begin
   with ExSys do begin
      Questions.Seek(q);
      Questions.Delete;
   end;
end;

{Deleta um objetivo da base de conhecimento}
procedure DeleteTarget(t: integer);
var
   i: integer;
begin
   with ExSys do begin
      {Deleta objetivos ligados}
      i := 0;
      while Targets.Nodes[i].Code <> t do inc(i);
      Targets.Nodes[i].Free;
      Targets.Delete(i);
   end;
end;

{Modifica as posições das regras a partir da regra de posição 'new_pos'}
procedure DefinePositions(min: integer; delta: integer; max: integer);
var
   temp_code, temp_pos, current: integer;
   temp_name: string;
   next_node_var: TMetaNode;
begin
   with ExSys do begin
      Rules.SeekByVar(max);
      current := max;
      while current >= min do begin
         temp_code := Rules.Code;
         temp_name := Rules.Name;
         temp_pos := Rules.Position;
         next_node_var := Rules.CurrentNodeVar.Previous;
         {Deleta-se e insere-se novamente o nó, pois estamos mudando
          sua "chave primária"}
         Rules.Delete;
         Rules.Insert(temp_code, temp_name, temp_pos + delta, 0);
         dec(current);
         Rules.CurrentNodeVar := next_node_var;
      end;
   end;
end;

{======================================================================
 ======================================================================
                        FUNÇÕES GERAIS AUXILIARES
 ======================================================================
 ======================================================================}

function MyFloatToStr(r: real): string;
begin
   Result := FloatToStrF(r, ffGeneral, 5, 2);
end;

function Space(size: integer): string;
var
   i: integer;
begin
   Result := '';
   for i := 1 to size do Result := Result + ' ';
end;

{Elimina espaços que aparecem no começo e no final de um token}
function ExcludeBlankSpaces(s: string): string;
begin
  while (length(s) <> 1) and (s[1] = ' ') do s := Copy(s, 2, length(s));
  while (length(s) <> 1) and (s[length(s)] = ' ') do s := Copy(s, 1, length(s) - 1);
  if s = ' ' then s := '';
  Result := s;
end;

{Pega o número de cores na tela}
function GetColorsCount: integer;
var
  h : hDC;
begin
  try
    h      := GetDC( 0 );
    Result :=
      1 shl
      (
        GetDeviceCaps( h, PLANES ) *
        GetDeviceCaps( h, BITSPIXEL )
      );
    ReleaseDC( 0, h );
  except
    Result := 0;
    ReleaseDC( 0, h );
  end;
end;

{======================================================================
 ======================================================================
                                DICA DO DIA
 ======================================================================
 ======================================================================}

{Mostra dica do dia}
procedure TipOfTheDay;
begin
  try
    fTipOfTheDay := TfTipOfTheDay.Create(Application);
    fTipOfTheDay.CurrentTip := current_tip;
    fTipOfTheDay.cbShowTips.Checked := show_tips;
    fTipOfTheDay.ShowModal;
    current_tip := fTipOfTheDay.CurrentTip;
    show_tips := fTipOfTheDay.cbShowTips.Checked;
  finally
    fTipOfTheDay.Free;
  end;
end;

{function TMainForm.GetScreenColors: longint;
var
  DC: hDC;
  n1, n2: longint;
begin
  DC:=MainForm.Canvas.Handle;
  n1 := GetDeviceCaps( DC, PLANES );
  n2 := GetDeviceCaps( DC, BITSPIXEL );
  Result := longint( 1 ) shl ( n1 * n2 );
end;}

end.
