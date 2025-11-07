{========================================================
 * Expert SINTA Visual Component Library *

 Módulo: ExConsts.pas
 Descrição:
    Inclui as principais constantes utilizadas pela 
    Expert SINTA VCL.
 Implementação: Ricardo Bezerra
 Data de início: 12 de outubro de 1996
 Data de término: 11 de março de 1997
 Última modificação: 31 de julho de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ========================================================}
unit ExConsts;

interface

const

   {Geral}
   QUESTION = 0;
   RULE_OK = -1;
   RULE_FAILED = -2;
   RULE_EXECUTED = -3;
   SEARCHING = -4;
   START_EVALUATION = -5;
   END_EVALUATION = -6;
   ATTRIB_UNKNOWN = -7;
   
   VAR_CNF_1 = 'CNF1';
   VAR_CNF_2 = 'CNF2';
   NO_NAME_BASE = 'SEM NOME';

   UNKNOWN = -1;
   UNKNOWN_STRING = 'DESCONHECIDO';
   {Define qual o tamanho máximo de um nome de conectivo, em caracteres}
   DEFAULT_CONECT_LENGTH = 3;
   IF_STRING = 'SE';
   AND_STRING = 'E';
   {Conectivo com espaços para alinhamento. Ver TRuleView e DEFAULT_CONECT_LENGTH}
   AND_STRING_EXTENDED = 'E  ';
   OR_STRING = 'OU';
   OR_STRING_EXTENDED = 'OU ';
   THEN_STRING = 'ENTÃO';
   NOT_STRING = 'NÃO';
   VALUE_STRING = 'VALOR';
   YES = -2;
   NO = -3;
   YES_STRING = 'Sim';
   NO_STRING = 'Não';
   cnAND = 0;
   cnOR = 1;
   cnTHEN = 2;
   NO_VALUE = 'Nenhum valor encontrado.';

   C1 = 52845;
   C2 = 22719;
   THE_KEY = 49675;
   NO_PERMISSION = 0;
   TOTAL_PERMISSION = 1;
   ONLY_EXECUTE = 2;
   EXECUTE_AND_VIEW = 3;
   BAD_FILE = -1;
   CORRUPTED_FILE = -2;

   CREATE_RULES = 'Crie algumas regra antes!';
   THERE_IS_NO_CONECT = 'Uma conectivo inexistente foi requerido!';
   UNDEFINED_TOKEN = '???';
   VAR_NOT_FOUND = 'Uma variável inexistente foi requerida!';
   VALUE_NOT_FOUND = 'Um valor inexistente foi requerido!';
   FORMULA_NOT_FOUND = 'Um fórmula inexistente foi requerida!';
   OPEN_PARENTH_EXPECTED = '( esperado!';
   CLOSE_PARENTH_EXPECTED = ') esperado!';
   COMMA_CLOSE_PARENTH_EXPECTED = ', ou ) esperado!';
   INDENTIFIER_CLOSE_PARENTH_EXPECTED = ') ou identificador esperado!';
   COMMA_EXPECTED = ', esperado!';
   QUOTE_EXPECTED = '" esperado!';
   INVALID_CHAR = 'Caractere inválido!';
   UNDECLARED_VAR = 'Variável não declarada:';
   FUNCTION_STRING = 'Função';
   EMPTY_FORMULA = 'Fórmula vazia!';
   UNEXPECTED_END_EXPRESSION = 'Final inesperado de expressão matemática!';
   OLD_VERSION_WARNING = 'Você precisa de uma versão mais nova do Expert SINTA para abrir essa base!';
   OPEN_FILE_ERROR = 'Um erro ocorreu durante a abertura do arquivo. Ele pode'
                    + ' estar danificado, ou não ser realmente do formato Expert SINTA,'
                    + ' ou ainda ser uma insuficiência de memória do sistema.';

   TOK_id=01; TOK_ct=02; TOK_MIN=03; TOK_MAX=04; TOK_SQR=05; TOK_EXP=06;
   TOK_POT=07; TOK_LOG=08; TOK_LN=09; TOK_ABS=10; TOK_SEN=11; TOK_COS=12;
   TOK_TAN=13;
   tab_res: array[1..12] of string[3] =('MIN','MAX','SQR','EXP','POT','LOG',
                         'LN','ABS','SEN','COS','TAN','   ');
   tab_fun: array[1..12] of byte =(TOK_MIN,TOK_MAX,TOK_SQR,TOK_EXP,TOK_POT,
                          TOK_LOG,TOK_LN,TOK_ABS,TOK_SEN,TOK_COS,TOK_TAN,TOK_id);

   {Interfaces}
   {Para objetos que exibem instâncias de variáveis}
   I_INSTANCE_VIEW = 0;
   {Para objetos que exibem dados relativos a variáveis, como uma pergunta
    ou os seus possíveis valores}
   I_VARIABLE_VIEW = 1;
   {Para objetos que exibem regras ou trechos de regras}
   I_KB_VIEW = 2;
   {Para objetos que refletem o status da máquina de inferência, como
    um navegador}
   I_STATUS_VIEW = 3;

   {Prompt}
   CONFIRM_CANCEL_STRING = 'Confirma cancelamento da consulta?';
   CONSULTATION_END_STRING = 'Fim da consulta';

   {Estrutura de dados}
   PRIMARY_INDEX = 0;
   NAME_INDEX = 1;
   VAR_INDEX = 2;
   PRIMARY_KEY = 0;
   BY_NAME = 1;
   BY_VAR = 2;
   BY_POSITION = 2;

implementation

end.