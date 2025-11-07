{=================================================
 UNIDADE para exportação das bases de conhecimento
 Implementação: Ricardo Bezerra
 Descrição: Exporta a base de conhecimento em
            outros formatos, incluindo impressão.
 Data de início: 09 de setembro de 1996
 Data de término: 09 de setembro de 1996
 Última modificação: 24 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =================================================}

unit Export;

interface

procedure ExportToText(text_file: string; to_printer: boolean);
procedure ExportToStruct(text_file: string; to_printer: boolean);

var
   abort_printing: boolean;

implementation

uses
   General, ExDataSt, Printers, PrintDlg, SysUtils, Forms, ExConsts;

procedure ExportToText(text_file: string; to_printer: boolean);
var
   output_file: TextFile;
   dialogPrint: TdialogPrint;

   procedure WriteHeader;
   var
     i, total: integer;
   begin
     Writeln(output_file, '------------------------------------------------' +
                          '--------------------------------');
     with ExSys.Info do begin
      Writeln(output_file, 'SOBRE O SISTEMA ESPECIALISTA');
      Writeln(output_file, '  -- Nome:    ' + Name);
      Writeln(output_file, '  -- Autores: ' + Authors);
      total := Overture.Count - 1;
      if total <> -1 then Writeln(output_file, '  -- Resumo:');
      for i := 0 to total do Writeln(output_file, '     ' + Overture.Strings[i]);
     end;
     Writeln(output_file, '');
     with ExSys.CustomFormulas do begin
       if not DefaultAnd then
          Writeln(output_file, 'Fórmula para cálculo de confiança na conjunção: ' +
                               FormulaAnd);
       if not DefaultOr then
          Writeln(output_file, 'Fórmula para cálculo de confiança na disjunção: ' +
                               FormulaOr);
       if not DefaultConclusion then
          Writeln(output_file, 'Fórmula para cálculo de confiança na conclusão: ' +
                               FormulaConclusion);
     end;
     Write(output_file, 'Operador de maior precedência: ');
     if ExSys.Priority = cnAnd then
        Writeln(output_file, 'conjunção')
     else
        Writeln(output_file, 'disjunção');
     Writeln(output_file, 'Fator de confiança mínimo para aceitação de regra: ' +
             FloatToStr(trunc(ExSys.MIN_VALUE * 100)));
     if ExSys.ExamineAll then Writeln(output_file,
        'As premissas devem ser avaliadas por completo.');
     Writeln(output_file, '');
     Writeln(output_file, 'SOBRE OS ARQUIVOS');
     Writeln(output_file, '  Arquivo original: ' + file_chosen);
     if ExSys.Info.HelpFile <> '' then
        Writeln(output_file, '  Arquivo de ajuda: ' + ExSys.Info.HelpFile)
     else
        Writeln(output_file, '  O sistema não possui recursos de ajuda.');
     Writeln(output_file, '------------------------------------------------' +
                          '--------------------------------');
     Writeln(output_file, '');
     Application.ProcessMessages;
   end;

   procedure WriteVars;
   begin
     if not abort_printing then begin
      Writeln(output_file, 'VARIÁVEIS');
      Writeln(output_file, '');
      ExSys.Vars.CurrentKey := BY_NAME;
      ExSys.Vars.MoveFirst;
      while (not ExSys.Vars.Blind) and (not abort_printing) do begin
         Application.ProcessMessages;
         Writeln(output_file, '  ' + ExSys.Vars.Name);
         ExSys.Values.SeekByVar(ExSys.Vars.Code);
         if ExSys.Values.Blind then begin
            {Writeln(output_file, '      Sim');
            Writeln(output_file, '      Não');}
         end
         else begin
            Writeln(output_file, '    Valores:');
            while (not ExSys.Values.Blind) and
                  (ExSys.Values.VarCode = ExSys.Vars.Code) do begin
                  Writeln(output_file, '      ' + ExSys.Values.name);
                  ExSys.Values.MoveNext;
            end;
         end;
         Writeln(output_file, '    Tipo:');
         if ExSys.Vars.Multi then
            Writeln(output_file, '      multivalorada')
         else begin
            if ExSys.Vars.Numeric then
               Writeln(output_file, '      numérica')
            else
               Writeln(output_file, '      univalorada');
         end;
         ExSys.Vars.MoveNext;
      end;
     end;
     if not abort_printing then Writeln(output_file, '');
   end;

   procedure WriteTargets;
   var
     i, total: integer;
   begin
     if not abort_printing then begin
       Writeln(output_file, 'OBJETIVOS');
       Writeln(output_file, '');
       total := ExSys.Targets.Count - 1;
       for i := 0 to total do begin
          Application.ProcessMessages;
          ExSys.Vars.Seek(ExSys.Targets.Nodes[i].code);
          if not abort_printing then Writeln(output_file, '  ' + ExSys.Vars.name);
       end;
      end;
     if not abort_printing then Writeln(output_file, '');
   end;

   procedure WriteRules;
   var
      code_rule, pos_rule: integer;
      str_val, sentence: string;
   begin
     if not abort_printing then begin
        Writeln(output_file, 'REGRAS');
        Writeln(output_file, '');
        ExSys.Rules.CurrentKey := BY_POSITION;
        ExSys.Rules.MoveFirst;
        while (not ExSys.Rules.Blind) and (not abort_printing) do begin
          Application.ProcessMessages;
          code_rule := ExSys.Rules.code;
          pos_rule := ExSys.Rules.position;
          ExSys.Tails.Seek(code_rule);
          ExSys.Heads.Seek(code_rule);
          Writeln(output_file, '  Regra ' + IntToStr(pos_rule));
          ExSys.Vars.Seek(ExSys.Tails.VarCode);
          if ExSys.Vars.numeric then begin
             ExSys.Formulas.Seek(ExSys.Tails.ValCode);
             str_val := ExSys.Formulas.Name;
          end
          else
             str_val := ExSys.RealValue(ExSys.Tails.ValCode);
          if ExSys.Tails.Neg then
             sentence := IF_STRING + ' ' + NOT_STRING + ' ' +
                         ExSys.Vars.Name + ' ' + ExSys.Tails.Operator
                         + ' ' + str_val
          else
             sentence := IF_STRING + ' ' + ExSys.Vars.Name + ' ' +
                         ExSys.Tails.Operator + ' ' + str_val;
          Writeln(output_file, '    ' + sentence);
          if ExSys.Tails.Conect <> cnThen then
             Write(output_file, '    ' + ExSys.ConectName(ExSys.Tails.Conect) +
                   Space(DEFAULT_CONECT_LENGTH -
                   length(ExSys.ConectName(ExSys.Tails.Conect))));
          ExSys.Tails.MoveNext;
          while (not ExSys.Tails.Blind) and (ExSys.Tails.Code = code_rule)
          do begin
             if ExSys.Tails.Neg then sentence := sentence + NOT_STRING + ' ';
             ExSys.Vars.Seek(ExSys.Tails.VarCode);
             if ExSys.Vars.Numeric then begin
                ExSys.Formulas.Seek(ExSys.Tails.ValCode);
                str_val := ExSys.Formulas.Name;
             end
             else
                str_val := ExSys.RealValue(ExSys.Tails.ValCode);
             sentence := ExSys.Vars.Name + ' ' + ExSys.Tails.Operator +
                         ' ' + str_val;
             Writeln(output_file, sentence);
             if ExSys.Tails.Conect <> cnThen then
                Write(output_file, '    ' + ExSys.ConectName(ExSys.Tails.Conect) +
                      Space(DEFAULT_CONECT_LENGTH -
                      length(ExSys.ConectName(ExSys.Tails.Conect))));
             ExSys.Tails.MoveNext;
         end;
         ExSys.Vars.Seek(ExSys.Heads.VarCode);
         if ExSys.Vars.Numeric then begin
            ExSys.Formulas.Seek(ExSys.Heads.ValCode);
            str_val := ExSys.Formulas.name;
         end
         else
            str_val := ExSys.RealValue(ExSys.Heads.ValCode);
         sentence := THEN_STRING + ' ' + ExSys.Vars.Name + ' = ' + str_val 
                     + ' CNF ' + MyFloatToStr(ExSys.Heads.Cnf * 100) + '%';
         Writeln(output_file, '    ' + sentence);
         ExSys.Heads.MoveNext;
         while (not ExSys.Heads.Blind) and (ExSys.Heads.Code = code_rule)
         do begin
             ExSys.Vars.Seek(ExSys.Heads.VarCode);
             if ExSys.Vars.Numeric then begin
                ExSys.Formulas.Seek(ExSys.Heads.ValCode);
                str_val := ExSys.Formulas.Name;
             end
             else
                str_val := ExSys.RealValue(ExSys.Heads.ValCode);
             sentence := '      ' + ExSys.Vars.Name + ' = ' + str_val +
                         ' CNF ' + MyFloatToStr(ExSys.Heads.cnf * 100) + '%';
             Writeln(output_file, '    ' + sentence);
             ExSys.Heads.MoveNext;
         end;
         Writeln(output_file, '');
         ExSys.Rules.MoveNext;
        end;
     end;
    end;

   procedure WriteQuestions;
   var
      i, total: integer;
   begin
      if (ExSys.Questions.RecordCount > 0) and (not abort_printing) then begin
         Writeln(output_file, 'PERGUNTAS');
         Writeln(output_file, '');
         ExSys.Vars.CurrentKey := BY_NAME;
         ExSys.Vars.MoveFirst;
         while (not ExSys.Vars.Blind) and (not abort_printing) do begin
            Application.ProcessMessages;
            ExSys.Questions.Seek(ExSys.Vars.Code);
            if not ExSys.Questions.Blind then begin
               Writeln(output_file, '  Variável:' + ExSys.Vars.Name);
               Writeln(output_file, '     Pergunta:"' +
                       ExSys.Questions.Question + '"');
               total := ExSys.Questions.Why.Count - 1;
               if total >=0 then begin
                  Writeln(output_file, '     Motivo:"' + ExSys.Questions.Why[0]);
                  for i := 1 to total do
                      Writeln(output_file, '            "' + ExSys.Questions.why[i]);
               end;
            end;
            ExSys.Vars.MoveNext;
         end;
         if not abort_printing then Writeln(output_file, '');
      end;
   end;

   procedure WriteFootNote;
   begin
     if not abort_printing then begin
        Writeln(output_file, '------------------------------------------------' +
                             '--------------------------------');
        Writeln(output_file, 'Gerado com o Expert SINTA versão 1.1b');
        Writeln(output_file, '(c) 1997 - Universidade Federal do Ceará');
        Writeln(output_file, '           Laboratório de Inteligência Artificial');
        Writeln(output_file, '           LIA/UFC');
        Writeln(output_file, '------------------------------------------------' +
                             '--------------------------------');
     end;
   end;

begin
   abort_printing := false;
   if to_printer then begin
      dialogPrint := TdialogPrint.Create(nil);
      dialogPrint.Show;
      dialogPrint.Refresh;
      AssignPrn(output_file);
      Printer.Title := 'Imprimindo base de conhecimento';
   end
   else
      AssignFile(output_file, text_file);
   Rewrite(output_file);
   try
     WriteHeader;
     WriteVars;
     WriteTargets;
     WriteRules;
     WriteQuestions;
     WriteFootNote;
   finally
     if to_printer then
        dialogPrint.Close
     else
        save_folder := ExtractFilePath(text_file);
     if abort_printing then Printer.Abort;
     CloseFile(output_file);
   end;
end;

procedure ExportToStruct(text_file: string; to_printer: boolean);
var
   output_file: TextFile;
   dialogPrint: TdialogPrint;

   procedure WriteHeader;
   var
     i, total: integer;
   begin
     Writeln(output_file, '------------------------------------------------' +
                          '--------------------------------');
     Writeln(output_file, 'CÓDIGOS INTERNOS DE BASE DE CONHECIMENTO');
     with ExSys.Info do begin
       Writeln(output_file, 'SOBRE O SISTEMA ESPECIALISTA');
       Writeln(output_file, '  -- Nome:    ' + Name);
       Writeln(output_file, '  -- Autores: ' + Authors);
       total := Overture.Count - 1;
       if total <> -1 then Writeln(output_file, '  -- Resumo:');
       for i := 0 to total do Writeln(output_file, '     ' + Overture.Strings[i]);
     end;
     Writeln(output_file, '');
     Writeln(output_file, 'SOBRE OS ARQUIVOS');
     Writeln(output_file, '  Arquivo original: ' + file_chosen);
     if ExSys.Info.HelpFile <> '' then
        Writeln(output_file, '  Arquivo de ajuda: ' + ExSys.Info.HelpFile)
     else
        Writeln(output_file, '  O sistema não possui recursos de ajuda.');
     Writeln(output_file, '------------------------------------------------' +
                          '--------------------------------');
     Writeln(output_file, '');
     Application.ProcessMessages;
   end;

   procedure WriteVars;
   begin
      Writeln(output_file, 'Variáveis - CÓDIGO, NOME');
      Writeln(output_file, '');
      ExSys.Vars.CurrentKey := PRIMARY_KEY;
      ExSys.Vars.MoveFirst;
      while not ExSys.Vars.Blind do
         with ExSys.Vars do begin
            Writeln(output_file, IntToStr(code) + ', ' + Name);
            MoveNext;
         end;
      Writeln(output_file, '');

      Writeln(output_file, 'Variáveis - NOME, CÓDIGO');
      Writeln(output_file, '');
      ExSys.Vars.CurrentKey := BY_NAME;
      ExSys.Vars.MoveFirst;
      while not ExSys.Vars.Blind do
         with ExSys.Vars do begin
            Writeln(output_file, name + ', ' + IntToStr(Code));
            MoveNext;
         end;
      Writeln(output_file, '');
   end;

   procedure WriteValues;
   begin
      Writeln(output_file, 'Valores - CÓDIGO, NOME, CÓDIGO DA VARIÁVEL, POSIÇÃO');
      Writeln(output_file, '');
      ExSys.Values.CurrentKey := PRIMARY_KEY;
      ExSys.Values.MoveFirst;
      while not ExSys.Values.Blind do
         with ExSys.Values do begin
            Writeln(output_file, IntToStr(Code) + ', ' + Name + ', ',
                                 IntToStr(VarCode) + ', ' + IntToStr(Position));
            MoveNext;
         end;
      Writeln(output_file, '');

      Writeln(output_file, 'Valores - NOME, CÓDIGO, CÓDIGO DA VARIÁVEL, POSIÇÃO');
      Writeln(output_file, '');
      ExSys.Values.CurrentKey := BY_NAME;
      ExSys.Values.MoveFirst;
      while not ExSys.Values.Blind do
         with ExSys.Values do begin
            Writeln(output_file, name + ', ' + IntToStr(Code) + ', ' +
                                 IntToStr(VarCode) + ', ' + IntToStr(Position));
            MoveNext;
         end;
      Writeln(output_file, '');

      Writeln(output_file, 'Valores - CÓDIGO DA VARIÁVEL, CÓDIGO, NOME, POSIÇÃO');
      Writeln(output_file, '');
      ExSys.Values.CurrentKey := BY_VAR;
      ExSys.Values.MoveFirst;
      while not ExSys.Values.Blind do
         with ExSys.Values do begin
            Writeln(output_file, IntToStr(VarCode) + ', ' + IntToStr(Code) +
                                 ', ' + Name + ', ' + IntToStr(Position));
            MoveNext;
         end;
      Writeln(output_file, '');
   end;

   procedure WriteRules;
   begin
      Writeln(output_file, 'Regras - POSIÇÃO, NOME, CÓDIGO');
      Writeln(output_file, '');
      ExSys.Rules.CurrentKey := BY_VAR;
      ExSys.Rules.MoveFirst;
      while not ExSys.Rules.Blind do
         with ExSys.Rules do begin
            Writeln(output_file, IntToStr(Position) + ', ' + Name + ', ',
                                 IntToStr(Code));
            MoveNext;
         end;
      Writeln(output_file, '');

      Writeln(output_file, 'Regras - CÓDIGO, NOME, POSIÇÃO');
      Writeln(output_file, '');
      ExSys.Rules.CurrentKey := PRIMARY_KEY;
      ExSys.Rules.MoveFirst;
      while not ExSys.Rules.Blind do
         with ExSys.Rules do begin
            Writeln(output_file, IntToStr(Code) + ', ' + Name + ', ',
                                 IntToStr(Position));
            MoveNext;
         end;
      Writeln(output_file, '');

      Writeln(output_file, 'Regras - NOME, CÓDIGO, POSIÇÃO');
      Writeln(output_file, '');
      ExSys.Rules.CurrentKey := BY_NAME;
      ExSys.Rules.MoveFirst;
      while not ExSys.Rules.Blind do
         with ExSys.Rules do begin
            Writeln(output_file, Name + ', ' + IntToStr(Code) + ', ' ,
                                 IntToStr(Position));
            MoveNext;
         end;
      Writeln(output_file, '');
   end;

   procedure WriteFootNote;
   begin
     if not abort_printing then begin
        Writeln(output_file, '------------------------------------------------' +
                             '--------------------------------');
        Writeln(output_file, 'Gerado com o Expert SINTA versão 1.1b');
        Writeln(output_file, '(c) 1997 - Universidade Federal do Ceará');
        Writeln(output_file, '           Laboratório de Inteligência Artificial');
        Writeln(output_file, '           LIA/UFC');
        Writeln(output_file, '');
        Writeln(output_file, '           Utilize esses códigos na programação');
        Writeln(output_file, '           de front-ends com a Expert SINTA VCL');
        Writeln(output_file, '------------------------------------------------' +
                             '--------------------------------');
     end;
   end;

begin
   abort_printing := false;
   if to_printer then begin
      dialogPrint := TdialogPrint.Create(nil);
      dialogPrint.Show;
      dialogPrint.Refresh;
      AssignPrn(output_file);
      Printer.Title := 'Imprimindo estrutura da base de conhecimento';
   end
   else
      AssignFile(output_file, text_file);
   Rewrite(output_file);
   try
     WriteHeader;
     WriteVars;
     WriteValues;
     WriteRules;
     WriteFootNote;
   finally
     if to_printer then
        dialogPrint.Close
     else
        save_folder := ExtractFilePath(text_file);
     if abort_printing then Printer.Abort;
     CloseFile(output_file);
   end;
end;

end.
