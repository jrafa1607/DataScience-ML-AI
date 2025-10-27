{========================================================
 * Expert SINTA Visual Component Library *

 Módulo: ExSystem.pas
 Descrição:
    Unidade que engloba a classe principal, TExpertSytem,
    envolvendo máquina de inferência e cálculo de fato-
    res de confiança com o uso de backward chaining.
 Componente: TExpertSystem
 Implementação: Ricardo Bezerra
 Implementação do cálculo de expressões: João Fernando
 Data de início: 12 de outubro de 1996
 Data de término: 11 de março de 1997
 Última modificação: 02 de maio de 1998
 Expert SINTA (c) 1995-1998 Grupo SINTA/LIA
 ========================================================}
unit ExSystem;

interface

uses
   ExDataSt, Classes, SysUtils, ExConsts;

   {$IFDEF WIN32}
      {$H-} {Desliga as huge strings}
      {$A-} {Records não alinhados}
   {$ENDIF}

type

   {Indica base inválida - quando não possui regras}
   EKBaseInvalid = class(Exception);
   {Erro de sintaxe na expressão numérica}
   EExpSyntaxError = class(Exception);
   {Sistema especialista nulo}
   ENullExpertSystem = class(Exception);
   {Variável inválida}
   EInvalidVar = class(Exception);
   {Valor inválido}
   EInvalidValue = class(Exception);

   {Permite acompanhamento da máquina de inferência, apontando para
    determinado ponto da base}
   TTraceShadow = record
      Rule: integer;  {Regra na qual a Inference Engine se localiza}
      Order: integer; {Número do item da regra apontado}
      Tail: boolean;  {Esse item está na cauda (true) ou na cabeça (false) da regra?}
   end;

  {$IFDEF WINDOWS}
    TMyInteger = integer; {Inteiro de 16 bits}
  {$ELSE}
    TMyInteger = smallint; {Inteiro de 16 bits}
  {$ENDIF}

   {Estruturas usadas para carregar arquivo}
   THeader = array[1..10] of byte;

   TVarRecord = record
     Code: TMyInteger;
     Name: string;
     Multi: boolean;
     Numeric: boolean;
   end;

   TValRecord_1_0 = record {versão 1.0}
     Code: TMyInteger;
     Name: string;
     VarCode: TMyInteger;
   end;

   TValRecord = record
     Code: TMyInteger;
     Name: string;
     VarCode: TMyInteger;
     Position: TMyInteger;
   end;

   TTargetRecord = record
     Code: TMyInteger;
     ShowResults: boolean;
   end;

   TRuleRecord = record
     Code: TMyInteger;
     Name: string;
     VarCode: TMyInteger;
   end;

   THeadRecord = record
     Code: TMyInteger;
     VarCode: TMyInteger;
     ValCode: TMyInteger;
     CNF: real; {Ao invés de single, para manter compatibilidade}
   end;

   TTailRecord = record
     Code: TMyInteger;
     VarCode: TMyInteger;
     Operator: string[2];
     ValCode: TMyInteger;
     Conect: TMyInteger;
     Neg: boolean;
   end;

   TFormulaRecord = record
     Code: TMyInteger;
     Formula: string;
   end;

   TPartialQuestionRecord = record
     Code: TMyInteger;
     Question: string;
   end;

   TContextRecord = record
     Code: TMyInteger;
     Context: TMyInteger;
   end;

   {Armazena as informações sobre a base}
   TInfos = record
      Name: string;          {Nome da base}
      Authors: string;       {Nome dos autores}
      Overture: TStringList; {Texto de abertura}
      HelpFile: string;      {Nome do arquivo de ajuda}
      ShowIntro: boolean;    {Se é para mostrar uma tela de abertura ou não}
   end;

   {Armazena as informações de permissões sobre a base}
   TProtection = record
      Password: string;       {Senha}
      Permission: TMyInteger; {Permissão dada se o usuário não souber a senha}
      UsePassword: boolean;   {Usar a senha mesmo ou não?}
   end;

   {Fórmulas personalizadas para cálculo de fatores de confiança}
   TCustomFormulas = record
      FormulaAnd: string;         {Fórmula personalizada para o AND}
      DefaultAnd: boolean;        {Ignorar a personalizada e usar o default?}
      FormulaOr:  string;         {Fórmula personalizada para o OR}
      DefaultOr:  boolean;        {Ignorar a personalizada e usar o default?}
      FormulaConclusion: string;  {Fórmula personalizada para conclusões}
      DefaultConclusion: boolean; {Ignorar a personalizada e usar o default?}
   end;

   {Eventos relativos ao sistema especialista}
   TVarBasedEvent = procedure (Sender: TObject; V: integer) of object;

   TExpertSystem = class;

   {Interface para controles que se comunicam com o sistema especialista}
   TExCtrlInterface = class
   protected
       OwnerControl: TObject;
   public
       Kind: byte;
       constructor Create(AKind: byte; AOwnerControl: TObject);
       procedure   Clear; virtual; abstract;
       procedure   RefreshLink(Sender: TExpertSystem); virtual; abstract;
       procedure   DestroyLink; virtual; abstract;
   end;

   {Interface para depuradores}
   TExDebugInterface = class(TExCtrlInterface)
   protected
       function  GetActiveTrace: boolean; virtual; abstract;
       procedure SetActiveTrace(ac: boolean); virtual; abstract;
   public
       property  ActiveTrace: boolean read GetActiveTrace write SetActiveTrace;
       procedure Activate; virtual; abstract;
       procedure Update(rule: integer; order: integer; is_tail: boolean); virtual; abstract;
   end;

   {CLASSE PRINCIPAL}
   TExpertSystem = class(TComponent)
   private
       {*********** Variáveis da máquina de inferência *************}
       {Eventos}
       FAfterCheckPassword: TNotifyEvent;
       FOnStart: TNotifyEvent;
       FOnFinish: TNotifyEvent;
       FOnFindTarget: TVarBasedEvent;
       FOnBackQuestion: TVarBasedEvent;
       FOnChange: TVarBasedEvent;
       FOnExecuteStep: TNotifyEvent;
       FOnPause: TNotifyEvent;
       FOnPrompt: TVarBasedEvent;
       FOnResume: TNotifyEvent;
       FOnShowResults: TVarBasedEvent;
       {Indica que a máquina de inferência está esperando por uma
        resposta do usuário a uma pergunta feita}
       FWaitingAnswer: boolean;
       {Indica que o usuário quis voltar à pergunta
        anterior, desmantelando a sequência de Find's. É preciso saber
        tomar de volta o fio da meada.}
       FBrokenSequence: boolean;
       {Essa lista aponta para cada item de "Trail" (ver abaixo) que
        realiza uma pergunta, de modo a permitir voltar perguntas
        anteriores mais rapidamente. A cada pergunta associada, há
        uma string indicando a qual regra ela pertence.}
       QuestionsList: TStringList;
       {Regras usadas até um determinado momento, aprovadas ou não.}
       UsedRules: TSingleIndexTree;
       {LastQuestionHelp indica a posição em que se encontrava a máquina de
        inferência na última vez que se fez uma pergunta (ver método AddTrail).
        LastHeadStep guarda a posição dentro de uma regra se uma pergunta
        surgiu de uma cabeça de regra (possível se for uma fórmula matemática
        utilizada em uma conclusão). Observe que esses passos não são inclusos
        no método AddTrail para compactar o máximo possível a fila que
        armazena o rastreamento.}
       LastQuestionStep: TTraceShadow;
       LastHeadStep: integer;
       {HeadVars guarda os códigos das cabeças ordenados pelo
        código da variável. A árvore é balanceada}
       HeadsVars: THelpContexts;
       BookmarkQuestions: TMetaNode;
       BookmarkVars1, BookmarkVars2: TMetaNode;
       BookmarkValues1, BookmarkValues2, BookmarkValues3: TMetaNode;
       OldIndexVars, OldIndexValues: integer;
       {Mostra uma mensagem de fim de consulta}
       FReportEnding: boolean;
       {*********** Variáveis relativas ao arquivo da base *********}
       FFileName  :string;  {Nome do arquivo da base}
       TheFile    :file;    {Arquivo da base}
       FVersion   :string;  {Versão do arquivo (ex. "1.0", "1.1"}
       FEmptyBase :boolean; {Já existe alguma base carregada?}
       {********** Relações com outros componentes **********}
       RunTime: TObject; {Janela prompt default}
       InstanceViewControls, VariableViewControls,
       KBViewControls, StatusViewControls: TList;
       procedure  DestroyLinks;
       procedure  RefreshLinks;
       procedure  SetFileName(FN: string);
   protected    
       {*********** Métodos da máquina de inferência *********}
       procedure StartEngine;
       procedure AddTrail(cod1: integer; cod2: integer);
       function  ANDRule(c1: single; c2: single): single;
       procedure BrutalReturn;
       function  CalcResultString(fun: string; var UnknownVar: boolean): single;
       function  ComparationCNF (v: integer; Value: string; Operator: string;
                                 Neg: boolean): single;
       procedure DestroyAllInstances(v: integer);
       function  DOUBLEEVALUATIONRule(Cnf1: single; Cnf2: single): single;
       procedure ExecuteRule(rule: integer; CNF: single);
       function  ExpressionResult(expression: string; rule: integer): single;
       function  HEADRule(c1: single; c2: single): single;
       function  NOTRule(CNF: single): single;
       function  ORRule(c1: single; c2: single): single;
       procedure Prompt(v: integer); dynamic;
       procedure ShowResults(v: integer); dynamic;
       function  TailResult(rule: integer): single;
       {********** Métodos de depuração e mostra de resultados *********}
       procedure UpdateDebug(rule: integer; order: integer; is_tail: boolean);
       {********** Métodos para carregar a base *********}
       function  CheckHeader(FN: string): boolean;
       function  CheckPassword: integer;
       procedure SetDefault;
       {********** Relações com outros componentes ********}
       procedure NotifyControls(ListControls: TList);
       procedure NotifyControls2(ListControls: TList);
       procedure NotifyControlsWithPermission(ListControls: TList);
   public
       {Lista das variáveis instanciadas}
       varList: TVarListTree;
       {Variáveis instanciadas numéricas}
       varListExtra: TVarListExtraTree;
       {Todas as intâncias de todas as variáveis em todos os momentos da consulta}
       InstanceList: TInstanceList;
       {Total de perguntas feitas durante a busca de um objetivo}
       TotalQuestions: integer;
       {Indica que uma consulta está em andamento}
       ExecutionMode: boolean;
       {Indica se o sistema especialista deve permitir confirmação ou não
        quando uma consulta é cancelada.}
       DontConfirmOnAbort: boolean;
       {Descrição das seguintes variáveis:
        - Trace: indica que a máquina de inferência está no modo de
          depuração;
        - Quit: indica que o usuário abortou a execução da consulta;
        - Wait: indica que a máquina de inferência NÃO pode continuar,
          pois está esperando por uma entrada do usuário (seja a
          resposta de uma pergunta, seja um comando (F8) para continuar
          a depuração);
        - TrailEnabled: permite que se acrescentem itens na fila de
          rastreamento da base (trail);
        - LockedAttrib é utilizada em BrutalReturn e AttribVar. Serve
          para indicar que a lista InstanceList não deve receber o
          valor que é atribuído para varList ou varListExtra;}
       Trace, Quit, Wait, TrailEnabled, UpdateDebugEnabled, LockedAttrib: boolean;
       {Fila com os passos feitos pela máquina de inferência, de modo
        mais compactado possível. Ver método AddTrail}
       Trail: TQueue;
       {********** Variáveis para cálculo de expressões *********}
       {Uma variável foi usada em uma fórmula, mas a máquina de inferência atribuiu
        um valor desconhecido a ela}
       UnknownVar: boolean;
       {********** Variáveis para depuração e resultados *********}
       {Guarda o estado do trace para sincronizar a janela de debug com
        a máquina de inferência. Quando o debug ficar visível, ele é posto
        na posição certa lendo essa estrutura.}
       CurrentTrace: TTraceShadow;
       DebugControl: TExDebugInterface;
       {*********** Variáveis para cálculo de expressões **********}
       {Examinar ou não todas as premissas, mesmo se já sabemos, com parte
        das premissas, se uma regra vai falhar ou não}
       ExamineAll: boolean;
       {Armazena as fórmulas para cálculo CNF}
       CustomFormulas: TCustomFormulas;
       {Parâmetros para o cálculo fórmulas CNF personalizadas}
       Cnf1, Cnf2: single;
       {***********Variáveis de uso geral**********}
       Vars: TVars;
       Values: TValues;
       Heads: THeads;
       Tails: TTails;
       Rules: TRules;
       Targets: TTargets;
       Questions: TQuestions;
       HelpContexts: THelpContexts;
       Formulas: TFormulas;
       MIN_VALUE, MIN_CNF, MAX_CNF: single;
       Priority: TMyInteger;
       Info: TInfos;
       Protection: TProtection;
       {A permissão real obtida pelo usuário, nem sempre igual à permissão
        determinada em Protection}
       Permission: integer;
       {******* Métodos da máquina de inferência *****}
       procedure StartConsultation;
       procedure AbortConsultation;
       procedure AbortPrompt;
       procedure AttribVar(v: integer; value: string; cnf: single;
                           is_a_code: boolean);
       procedure AttribVarFromBinary(V, VBin: integer);
       procedure AttribVarFromPosition(V, Pos: integer; CNF: single);
       procedure BackToLastQuestion;
       procedure DefaultPrompt(v: integer);
       procedure ExecuteStep;
       procedure Find(cod_var: integer);
       procedure PauseEngine;
       procedure ResumeEngine;
       {********** Métodos de cálculo de expressões *********}
       function  CalcResult(fun: integer): single;
       {********** Métodos para carregar/salvar a base *********}
       function LoadFromFile(FN: string): boolean;
       function SaveToFile(FN: string): boolean;
       {********** Métodos de uso geral **********}
       constructor Create(AOwner: TComponent); override;
       destructor  Destroy; override;
       procedure BookmarkVar;
       procedure BookmarkQuestion;
       procedure ClearBase;
       function  CanView: boolean;
       function  ConectName(c: integer): string;
       function  FastRealValue(c: integer): string;
       function  IsConect(s: string): boolean;
       function  RealValue(c: integer): string;
       function  MyFloatToStr(r: single): string;
       procedure RestoreQuestionFromBookmark;
       procedure RestoreVarFromBookmark;
       function  Space(size: integer): string;
       function  VarCode(v: string): integer;
       function  ValCode(vr: integer; v: string): integer;
       procedure ValuesList(V: integer; ListOfValues: TStringList);
       procedure VarInstances(V: integer; ValuesList, CNFsList: TStringList);
       function  VarName(c: integer): string;
       function  ValName(v, c: integer): string;
       {********** Relações com outros componentes **********}
       procedure AddControl(control: TExCtrlInterface);
       procedure RemoveControl(control: TExCtrlInterface);
       property  WaitingAnswer: boolean read FWaitingAnswer write FWaitingAnswer;
       property  BrokenSequence: boolean read FBrokenSequence;
       property  EmptyBase: boolean read FEmptyBase write FEmptyBase;
       {********************* Outros ************************}
       property  Version: string read FVersion write FVersion;
     published
       property FileName: string read FFileName write SetFileName;
       property ReportEnding: boolean read FReportEnding write FReportEnding default true;
       property AfterCheckPassword: TNotifyEvent read FAfterCheckPassword write FAfterCheckPassword;
       property OnStart: TNotifyEvent read FOnStart write FOnStart;
       property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
       {Ações a serem tomadas imediatamente antes do início da consulta
        a um objetivo. Útil para inicializar variáveis}
       property OnFindTarget: TVarBasedEvent read FOnFindTarget write FOnFindTarget;
       {Ações a serem tomadas quando uma variável recebe uma nova instância}
       property OnChange: TVarBasedEvent read FOnChange write FOnChange;
       {Ações a serem tomadas antes da execução de mais um passo durante
        depuração}
       property OnExecuteStep: TNotifyEvent read FOnExecuteStep write FOnExecuteStep;
       {Ações a serem tomadas quando a máquina de inferência entra no modo
        de depuração}
       property OnPause: TNotifyEvent read FOnPause write FOnPause;
       {Ações a serem tomadas quando a máquina de inferência sai do modo
        de depuração}
       property OnResume: TNotifyEvent read FOnResume write FOnResume;
       {Eventos de perguntas sobre uma variável}
       property OnPrompt: TVarBasedEvent read FOnPrompt write FOnPrompt;
       {Evento de exibição de resultados de um objetivo}
       property OnShowResults: TVarBasedEvent read FOnShowResults write FOnShowResults;
   end;

procedure Register;
function Encrypt(const S: String; Key: Word): String;
function Decrypt(const S: String; Key: Word): String;

implementation

uses
   Dialogs, Forms, Controls, ExPrompt, ExCtrls, ExDlgWhy, ExPasswd;

{======================================================================
 ======================================================================
                FUNÇÕES RELATIVAS À MAQUINA DE INFERÊNCIA
 ======================================================================
 ======================================================================}

procedure TExpertSystem.StartConsultation;
begin
   if not ExecutionMode then begin
      Trace := false;
      StartEngine;
   end;
end;

{Procedimento que aciona, pela primeira vez, a máquina de inferência,
 procurando encontrar todos os objetivos.}
procedure TExpertSystem.StartEngine;
var
   current_target: integer;

   procedure StartHeadsByName;
   var
      i, j, max, total: integer;
      current_node_1, current_node_2: TMetaNode;
      node: TNode;
   begin
      HeadsVars := THelpContexts.Create;
      if Heads.RecordCount > 1 then
         max := 1
      else
         max := Heads.RecordCount - 1;
      for j := 0 to max do begin
         Heads.MoveFirst;
         if j = 0 then
            total := Heads.RecordCount div 2
         else
            total := (Heads.RecordCount div 2) - 1;
         for i := 1 to total do Heads.MoveNext;
         current_node_1 := Heads.CurrentNode;
         if current_node_1 <> nil then begin
            current_node_2 := Heads.CurrentNode.Next;
            if current_node_2 <> nil then current_node_2 := current_node_2.Next;
         end
         else
            current_node_2 := nil;
         while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
            if current_node_1 <> nil then begin
               node := current_node_1.node;
               HeadsVars.Insert(THeadNode(node).VarCode, node.Code);
               current_node_1 := current_node_1.Previous;
               if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
            end;
            if current_node_2 <> nil then begin
               node := current_node_2.node;
               HeadsVars.Insert(THeadNode(node).VarCode, THeadNode(node).Code);
               current_node_2 := current_node_2.Next;
               if current_node_2 <> nil then current_node_2 := current_node_2.Next;
            end;
         end;
      end;
   end;

begin
 if Heads.RecordCount = 0 then
    raise EKBaseInvalid.Create(CREATE_RULES);
 EmptyBase := false;
 Quit := False;
 FBrokenSequence := false;
 TrailEnabled := true;
 UpdateDebugEnabled := true;
 LockedAttrib := false;
 FWaitingAnswer := false;
 try
   ExecutionMode := true;
   DontConfirmOnAbort := false;
   MIN_CNF := 0;
   MAX_CNF := 1;
   current_target := 0;
   UsedRules := TSingleIndexTree.Create;
   varList := TVarListTree.Create;
   varListExtra := TVarListExtraTree.Create;
   InstanceList := TInstanceList.Create;
   Trail := TQueue.Create;
   QuestionsList := TStringList.Create;
   StartHeadsByName;
   TotalQuestions := 0;
   RunTime := TRunTime.Create(Self);
   TRunTime(RunTime).Init(Self);
   NotifyControls(StatusViewControls);
   NotifyControls2(InstanceViewControls);
   if Assigned(FOnStart) then FOnStart(Self);
   while (current_target < Targets.Count) and (not Quit) do begin
      if Assigned(FOnFindTarget) then begin
         WaitingAnswer := true;
         FOnFindTarget(Self, Targets.Nodes[current_target].Code);
         while WaitingAnswer do Application.ProcessMessages;
      end;
      Find(Targets.Nodes[current_target].Code);
      if not FBrokenSequence then begin
         if (not Quit) and (Targets.Nodes[current_target].ShowResults)
            then ShowResults(Targets.Nodes[current_target].Code);
         inc(current_target);
         TotalQuestions := 0;
         NotifyControls(StatusViewControls);
      end
      else
         BrutalReturn;
   end;
 finally
   begin
      Trace := false;
      DontConfirmOnAbort := true;
      if not Quit then TRunTime(RunTime).Close;
      TRunTime(RunTime).Free;
      Quit := false;
      Trail.Free;
      varList.Free;
      varListExtra.Free;
      InstanceList.Free;
      UsedRules.Free;
      QuestionsList.Free;
      ExecutionMode := false;
      NotifyControls(StatusViewControls);
      if Assigned(FOnFinish) then FOnFinish(Self);
   end;
 end;
end;

{Finaliza a execução}
procedure TExpertSystem.AbortConsultation;
begin
    if ExecutionMode then begin
       Quit := True;
       if Trace then begin
          Wait := False;
          Trace := False;
       end;
       AbortPrompt;
    end;
end;

{Deixa a máquina de inferência continuar, se necessário}
procedure TExpertSystem.AbortPrompt;
begin
   FWaitingAnswer := false;
   if (TRunTime(RunTime) <> nil) and TRunTime(RunTime).Visible then
       TRunTime(RunTime).Hide;
end;

procedure TExpertSystem.AddTrail(cod1: integer; cod2: integer);
begin
{Essa subrotina é fundamental para que se faça, posteriormente, uma
 árvore explicativa sobre o caminho feito pela máquina de inferência.
 Para isso, ela guarda, aos pares, informações sobre o que a máquina de
 inferência realiza, de acordo com os seguintes código:
        - cod1 > 0 indica que a máquina de inferência está passando
          pela premissa de ordem cod2 da regra cod1;
        - cod1 = 0 indica que a máquina de inferência realizou uma
          pergunta sobre a variável cod2;
        - cod1 = -1 indica que a regra cod2 foi aprovada;
        - cod1 = -2 indica que a regra cod2 foi rejeitada;
        - cod1 = -3 indica que a máquina começou a procurar a
          variável cod2.}
 if TrailEnabled then begin
   if cod1 > 0 then
      with LastQuestionStep do begin
         rule := cod1;
         order := cod2;
         tail := true;
      end;
   if (cod1 = RULE_OK) or (cod1 = RULE_FAILED) then
      LastQuestionStep.tail := false;
   Trail.Insert(cod1);
   if cod1 = QUESTION then
      with LastQuestionStep do begin
         if LastQuestionStep.tail then
            QuestionsList.AddObject(IntToStr(rule) + '/' +
                           IntToStr(order) + '/true', Trail.Rear)
         else
            QuestionsList.AddObject(IntToStr(rule) + '/' +
                           IntToStr(LastHeadStep) + '/false', Trail.Rear)
      end;
   Trail.Insert(cod2);
 end;
{Posteriormente, caso o usuário pergunte sobre como a máquina chegou até
 aquele resultado, uma outra função encarrega-se-á de "traduzir" esses
 códigos em expressões amigáveis.}
end;

{Regra da conjunção}
function TExpertSystem.ANDRule(c1: single; c2: single): single;
begin
   {MÉTODO ANTIGO - retirado do PSE do Genaro
   if Cnf1 > Cnf2 then
      Result := Cnf2
   else
      Result := Cnf1;}
   {NOVO MÉTODO - segundo o Helano, "inspirado na Teoria dos Conjuntos"}
   if CustomFormulas.DefaultAnd then
      Result := c1 * c2
   else begin
      Cnf1 := c1;
      Cnf2 := c2;
      Result := CalcResultString(CustomFormulas.FormulaAnd, UnknownVar);
   end;
end;

{Essa subrotina encarrega-se de incluir na lista de variáveis instanciadas
 a variável "v", bem como ajustar esses valores em caso de repetição
 ou quando a variável não é multivalorada. O último parâmetro indica
 se devemos interpretar "Value" como um código de valor ou como o valor
 propriamente dito.}
procedure TExpertSystem.AttribVar(v: integer; value: string; cnf: single;
          is_a_code: boolean);
var
   found_and_equal, found: boolean;
   value_num: integer;
   final_cnf: single;
   bookmark: TMetaNode;

   procedure YesNoTransformation(var value: integer; var cnf: single);
   begin
     {Primeiro verifica-se se não é algo do tipo "Sim, com 30%".
      Nesse exemplo, transforma-se o valor para "Não, com 70%".}
      if (value = YES) and (cnf < 0.5) then begin
          value := NO;
          cnf := 1 - cnf;
      end
      else
         if (value = NO) and (cnf <= 0.5) then begin
             value := YES;
             cnf := 1 - cnf;
         end;
   end;

begin
   if Quit then begin
      if Trace then Trace := False;
      ExecutionMode := False;
   end
   else begin
      final_cnf := CNF;
      try
         value_num := StrToInt(Value);
      except
         on EConvertError do value_num := 0;
      end;
      found_and_equal := False;
      Vars.Seek(v);
      if Vars.Multi then begin
         {Variáveis numéricas nunca são multivaloradas}
         varList.Seek(v);
         while (not varList.Blind) and (varList.Code = v) and
            (varList.ValCode <> value_num) do varList.MoveNext;
         if (not varList.Blind) and (varList.Code = v) and
            (varList.ValCode = value_num) then found_and_equal := true;
         if found_and_equal then begin
            final_cnf := DOUBLEEVALUATIONRule(varList.CNF, CNF);
            varList.CNF := final_cnf;
         end
         else
            varList.Insert(v, value_num, CNF);
      end
      else begin
         if not Vars.Numeric then begin
            found := False;
            varList.Seek(v);
            if (not varList.Blind) and (varList.Code = v) then begin
               found := true;
               if varList.ValCode = value_num then found_and_equal := true;
            end;
            if not found then begin
               varListExtra.Seek(v);
               if (not varListExtra.Blind) and (varListExtra.Code = v) then begin
                  found := True;
                  if varListExtra.Value = value then found_and_equal := True;
              end;
            end;
            if is_a_code then begin
               {Nesse caso, o valor que está sendo passado é um código de valor,
                não um valor literal. É importante que se faça essa diferença
                pois, se uma váriável é texto puro (NÃO IMPLEMENTADA AINDA), não
                podemos confundir o valor atribuído com um código de valor.}
               YesNoTransformation(value_num, CNF);
               if found_and_equal then begin
                 {Já estava com esse valor, deve-se alterar o grau de confiança.}
                 final_cnf := DOUBLEEVALUATIONRule(varList.CNF, CNF);
                 YesNoTransformation(value_num, final_cnf); {Sim, de novo!}
                 if varList.ValCode <> value_num then
                    {No caso do Sim-Não transformado}
                    varList.ValCode := value_num;
                 varList.CNF := final_cnf;
               end
               else begin
                  if found then begin {Substituir o valor.}
                     varList.CNF := CNF;
                     varList.ValCode := value_num;
                  end
                  else
                     {Adiciona o novo trio "atributo-valor-grau de confiança".}
                     varList.Insert(v, value_num, CNF);
               end;
            end
            else begin
               if found_and_equal then begin
                  {Já estava com esse valor, deve-se alterar o grau de confiança.}
                  final_cnf := DOUBLEEVALUATIONRule(varListExtra.CNF, CNF);
                  varListExtra.CNF := final_cnf;
               end
               else begin
                  if found then begin {Substituir o valor.}
                     varListExtra.CNF := CNF;
                     varListExtra.Value := value;
                  end
                  else
                     {Adiciona o novo trio "atributo-valor-grau de confiança".}
                     varListExtra.Insert(v, value, cnf);
               end;
            end;
         end
         else begin
            varListExtra.Seek(v);
            if not varListExtra.Blind then begin
               if is_a_code and (value_num = UNKNOWN) then begin
                  varListExtra.Delete;
                  varList.Seek(v);
                  if varList.Blind then
                     varList.Insert(v, UNKNOWN, CNF)
                  else begin
                     varList.ValCode := UNKNOWN;
                     varList.CNF := CNF;
                  end;
               end
               else begin
                  varListExtra.CNF := CNF;
                  bookmark := varListExtra.CurrentNode;
                  if is_a_code then begin
                     AddTrail(START_EVALUATION, 0);
                     value := FloatToStr(CalcResult(value_num));
                     AddTrail(END_EVALUATION, 0);
                  end;
                  varListExtra.CurrentNode := bookmark;
                  if UnknownVar then begin
                     varListExtra.Delete;
                     varList.Insert(v, UNKNOWN, CNF);
                     value := IntToStr(UNKNOWN);
                     is_a_code := true;
                  end
                  else
                     varListExtra.Value := value;
               end;
            end
            else begin
               varList.Seek(v);
               if not varList.Blind then varList.Delete;
               if is_a_code and (value_num = UNKNOWN) then
                  varList.Insert(v, UNKNOWN, CNF)
               else begin
                  if is_a_code then begin
                     AddTrail(START_EVALUATION, 0);
                     value := FloatToStr(CalcResult(value_num));
                     AddTrail(END_EVALUATION, 0);
                  end;
                  if UnknownVar then begin
                     varList.Insert(v, UNKNOWN, CNF);
                     value := IntToStr(UNKNOWN);
                     is_a_code := true;
                  end
                  else
                     varListExtra.Insert(v, value, CNF);
               end;
            end;
         end;
      end;
      if not LockedAttrib then
         InstanceList.AppendInstance(v, value, final_cnf, is_a_code);
   end;
   NotifyControls2(InstanceViewControls);
   if Assigned(FOnChange) then FOnChange(Self, v);
end;

{Atribui valores para variáveis univaloradas e multivaloradas através
 de um número binário e da ordem de seus valores. Por exemplo, digamos que
 deseje atribuir o primeiro, terceiro e quarto valores de uma variável à
 base de fatos. A fórmula 2^(1-1) + 2^(3-1) + 2^(4-1) dá 11, que neste
 método é decodicada em "1011" (observe que "1011" é o inverso de 11 em
 binário: "1101")}
procedure TExpertSystem.AttribVarFromBinary(V, VBin: integer);
var
   sequence: string[255];
   tam, cont: integer;
   bookmark: TMetaNode;
begin
   Vars.Seek(V);
   if Vars.Numeric then
      raise EExpertSystem.Create('Método AttribVarFromBinary só pode ser ' +
            'chamado para variáveis não numéricas!');
   if VBin = UNKNOWN then
      AttribVar(V, IntToStr(UNKNOWN), MAX_CNF, true)
   else begin
      Values.SeekByVar(V);
      if Values.Blind then begin
         {Variável do tipo Sim/Não}
         if (VBin <> YES) and (VBin <> NO) then
            raise EExpertSystem.Create('Valor inválido no método AttribVarFromBinary!');
         AttribVar(V, IntToStr(VBin), MAX_CNF, true);
      end
      else begin
         sequence := '';
         repeat
            sequence := sequence + IntToStr(VBin mod 2);
            VBin := VBin div 2;
         until VBin = 0;
         tam := length(sequence);
         cont := 1;
         bookmark := Values.CurrentNodeVar;
         while cont <= tam do begin
            if sequence[cont] = '1' then begin
               {Encontra o valor pela posição ocupada}
               Values.CurrentNodeVar := bookmark;
               Values.CurrentKey := BY_VAR;
               while (not Values.Blind) and (Values.VarCode = V) and
                     (Values.Position <> cont) do Values.MoveNext;
               if (not Values.Blind) and (Values.VarCode = V) then
                  AttribVar(V, IntToStr(Values.Code), MAX_CNF, true)
               else
                  raise EExpertSystem.Create('Uso inválido do método AttribVarFromBinary!');
            end;
            inc(cont);
         end;
      end;
   end;
end;

{Atribui um valor a uma variável baseada na posição da primeira em relação
 à variável em questão (atributo 'position' de TValNode. Este método
 aceita passagem de CNF}
procedure TExpertSystem.AttribVarFromPosition(V, Pos: integer; CNF: single);
begin
   Vars.Seek(V);
   if Vars.Numeric then
      raise EExpertSystem.Create('Método AttribVarFromPosition só pode ser ' +
            'chamado para variáveis não numéricas!');
   if Pos = UNKNOWN then
      AttribVar(V, IntToStr(UNKNOWN), MAX_CNF, true)
   else begin
      Values.SeekByVar(V);
      if Values.Blind then begin
         {Variável do tipo Sim/Não}
         if (Pos <> YES) and (Pos <> NO) then
            raise EExpertSystem.Create('Valor inválido no método AttribVarFromPosition!');
         AttribVar(V, IntToStr(Pos), CNF, true);
      end
      else begin
          while (not Values.Blind) and (Values.VarCode = V) and
                (Values.Position <> Pos) do Values.MoveNext;
          if (not Values.Blind) and (Values.VarCode = V) then
             AttribVar(V, IntToStr(Values.Code), CNF, true)
          else
             raise EExpertSystem.Create('Uso inválido do método AttribVarFromPosition!');
      end;
   end;
end;

procedure TExpertSystem.BackToLastQuestion;
begin
   if TotalQuestions > 0 then begin
      FBrokenSequence := true;
      UpdateDebugEnabled := false;
      dec(TotalQuestions);
      if TotalQuestions = 0 then NotifyControls(StatusViewControls);
      AbortPrompt;
      Wait := false;
   end;
end;

{Procedimento realmente brutal, é disparado sempre que o usuário desejar
 retornar à pergunta anterior. Desfaz todas as ações feitas até esse
 momento, retira elementos da lista de ações (Trail), desfaz instancia-
 ções, desmantela TODA pilha de Find's que houver, desmarca todas as
 regras usadas posteriormente à pergunta (além da regra na qual a pergunta
 se localiza), dá um "boot" na máquina de inferência, recomeçando o
 Find a partir da variável objetivo do momento - obviamente, o retorno
 será rápido pois as instanciações feitas até antes da pergunta são
 mantidas. Esse foi o procedimento mais legível que consegui para efetuar
 essa volta e recriar a pilha de Find's que existia no momento anterior
 à pergunta. Procure também, nessa unit e na unit Trace, referências à
 variável "FBrokenSequence", indicando que determinado procedimento deve
 "abortar" se naquele trecho o mala do usuário voltar para a pergunta
 anterior.}
procedure TExpertSystem.BrutalReturn;
{Relembrando
 - cod1 > 0 indica que a máquina de inferência está passando
    pela premissa de ordem cod2 da regra cod1;
 - cod1 = Question indica que a máquina de inferência realizou uma
    pergunta sobre a variável cod2;
 - cod1 = RULE_OK indica que a regra cod2 foi aprovada (mas não ainda executada);
 - cod1 = RULE_FAILED indica que a regra cod2 foi rejeitada;
 - cod1 = RULE_EXECUTED indica que a regra foi terminada;
 - cod1 = SEARCHING indica que a máquina começou a procurar a
   variável cod2.}
var
   cod1, cod2: integer;
   total: integer;
   aux, aux2: TQueueMetaNode;
   the_rule, the_order: integer;
   was_tail: boolean;
   back_trail: TIntegerStack;

   procedure ExtractPosInfo;
   var
      next_pos, position: string;
      i: integer;
   begin
      Position := QuestionsList[total];
      i := 1;
      next_pos := '';
      while position[i] <> '/' do begin
         next_pos := next_pos + position[i];
         inc(i);
      end;
      the_rule := StrToInt(next_pos);
      Position := Copy(Position, i + 1, Length(position));

      i := 1;
      next_pos := '';
      while position[i] <> '/' do begin
         next_pos := next_pos + Position[i];
         inc(i);
      end;
      the_order := StrToInt(next_pos);

      position := Copy(position, i + 1, Length(position));
      if position = 'true' then
         was_tail := true
      else
         was_tail := false;

   end;

   {Corta fora tudo de "Trail" a partir desse ponto}
   procedure PrepareCodes;
   begin
     aux := TQueueMetaNode(QuestionsList.Objects[total]);
     back_trail := TIntegerStack.Create;
     while aux <> nil do begin
        cod1 := aux.node.Code;
        aux2 := aux.Next;
        aux.Free;
        aux := aux2;
        cod2 := aux.node.Code;
        aux2 := aux.Next;
        aux.Free;
        aux := aux2;
        back_trail.Push(cod1);
        back_trail.Push(cod2);
        Trail.RecordCount := Trail.RecordCount - 2;
     end;
     Trail.RebuildRear;
   end;

   procedure GetCodes;
   begin
      cod2 := back_trail.Pop;
      cod1 := back_trail.Pop;
   end;

begin
   total := QuestionsList.Count - 1;
   if Assigned(FOnBackQuestion) then FOnBackQuestion(Self, total);

   ExtractPosInfo;
   PrepareCodes;

   UsedRules.Seek(the_rule);
   if not UsedRules.Blind then UsedRules.Delete;

   TrailEnabled := false;
   LockedAttrib := true;

   QuestionsList.Delete(total);

   while back_trail.RecordCount > 0 do begin
      GetCodes;
      case cod1 of
         RULE_EXECUTED:
            {Desfaz todas as instância provocadas por essa regra e
             desmarca os itens da lista de debug}
            begin
             UsedRules.Seek(cod2);
             if not UsedRules.Blind then UsedRules.Delete;
             Heads.Seek(cod2);
             while (Heads.CurrentNode.Next <> nil) and
                   (Heads.CurrentNode.Next.Node.Code = cod2)
                   do Heads.MoveNext;
             while (not Heads.Blind) and (Heads.Code = cod2) do begin
                InstanceList.RebuildInstance(Heads.VarCode, Self);
                Heads.MovePrevious;
             end;
           end;
         RULE_FAILED:
           begin
             UsedRules.Seek(cod2);
             if not UsedRules.Blind then UsedRules.Delete;
           end;
         QUESTION:
           DestroyAllInstances(cod2);
         ATTRIB_UNKNOWN:
           {Quando uma regra falha e esta é a última regra da qual
            se pode concluir uma variável presente em uma de suas
            cabeças, essa variável recebe valor DESCONHECIDO (o que
            é diferente de não ter nenhum valor. Se a variável não tem
            nenhum valor, a máquina de inferência pode ir atrás de um.
            Agora, se o valor é DESCONHECIDO e a variável, univalorada,
            então a máquina de inferência não se importa).
            Portanto, deve-se destruir os valores desconhecidos das
            variáveis presentes nas cabeças da regra.}
            InstanceList.RebuildInstance(cod2, Self);
      end;
   end;

   {if not was_tail then begin
      order := 1;
      Heads.Seek(the_rule);
      while (not Heads.Blind) and (Heads.Code = the_rule) do begin
         if order >= the_order then
            InstanceList.RebuildInstance(Heads.VarCode,
                         IntToStr(Heads.ValCode), Self);
         Heads.MoveNext;
         inc(order);
      end;
   end;}

   with LastQuestionStep do begin
      rule := the_rule;
      order := the_order;
      tail := was_tail;
   end;

   {Reposiciona o debug na pergunta anterior}
   UpdateDebug(the_rule, the_order, was_tail);

   back_trail.Free;
   LockedAttrib := false;
   NotifyControls2(InstanceViewControls);
   if Assigned(FOnChange) then FOnChange(Self, -1);
   FBrokenSequence := false; {Finalmente...}
end;

{A função compara a variável "v" e o valor "Value" em relação ao
 operador "Operator" e devolve o grau de confiança da comparação.
 Deve ser levado em conta também o "NOT" - negação da sentença,
 uma frescura que o Helano pediu.
 Se necessário, a função evoca a subrotina "Find" para encontrar os
 valores de "v".}
function TExpertSystem.ComparationCNF (v: integer; value: string; operator: string;
                                       neg: boolean): single;
var
   found, found_in_extras, in_list, Numeric: boolean;
   value_code: integer;

   procedure InvertOperator(var op: string);
   begin
     if op = '=' then
        op := '<>'
     else begin
        if op = '<>' then
           op := '='
        else begin
           if op = '>=' then
              op := '<'
           else begin
              if op = '<=' then
                 op := '>'
              else begin
                 if op = '<' then
                    op := '>='
                 else
                    op := '<='
              end;
           end;
        end;
     end;
   end;

begin
   found := False;
   found_in_extras := False;
   in_list := False;
   Vars.Seek(v);
   numeric := Vars.Numeric;
   if neg then InvertOperator(Operator);
   try
      value_code := StrToInt(value);
   except
      on EConvertError do value_code := 0;
   end;
   repeat
     varList.Seek(v);
     if not varList.Blind then begin
        in_list := True;  {Ou seja, a variável já havia sido instanciada
                           anteriormente.}
        while (not varList.Blind) and (varList.Code = v) and
              (varList.ValCode <> value_code) do varList.MoveNext;
        if (not varList.Blind) and (varList.Code = v) and
           (varList.ValCode = value_code) then found := True;
     end;
     {Procura agora valores não cadastrados na tabela de valores, o que
      inclui as variáveis numéricas.}
     if not in_list then begin
        varListExtra.Seek(v);
        if not varListExtra.Blind then begin
           in_list := true;
           found_in_extras := true;
           if numeric then
              found := true
           else begin
              while (not varListExtra.Blind) and (varListExtra.Code = v) and
                    (Uppercase(varListExtra.Value) <> Uppercase(value))
                    do varListExtra.MoveNext;
              if (not varListExtra.Blind) and (varListExtra.Code = v) and
                 (Uppercase(varListExtra.Value) = Uppercase(value))
                 then found := True;
           end;
        end;
     end;
     if (not in_list) and (not FBrokenSequence) then Find(v);
     if Quit then begin
        if Trace then Trace := False;
        ExecutionMode := False;
     end;
  until in_list or Quit or FBrokenSequence;
  if (not Quit) and (not FBrokenSequence) then begin
     if not found_in_extras then begin
        if operator = '=' then begin
           if found then {Existe uma atribuição "Value" a "v".}
              Result := varList.CNF
           else
              Result := MIN_CNF;
        end;
        if operator = '<>' then begin
           if found then
              Result := NOTRule(varList.CNF)
           else
              Result := MAX_CNF
        end;
        {O próxima caso diz respeito a variáveis numéricas, mas cuja
         instância é DESCONHECIDO. Desta forma, found_in_extras = false.
         Outros operadores devem ser tratados}
        if (operator <> '=') and (operator <> '<>') then
            Result := MIN_CNF;
     end
     else begin
          {Tratamento das variáveis cujo valor atribuído não se encontra
           na tabela de valores.}
          if operator = '=' then begin
             if numeric then begin
                if (StrToFloat(varListExtra.Value) = CalcResult(value_code))
                   and (not UnknownVar) then
                   Result := varListExtra.CNF
                else
                   Result := MIN_CNF;
             end
             else begin
                if found then {Existe uma atribuição "Value" a "v".}
                   Result := varListExtra.CNF
                else
                   Result := MIN_CNF;
             end;
          end;
          if operator = '<>' then begin
             if numeric then begin
                if (StrToFloat(varListExtra.Value) <> CalcResult(value_code))
                   and (not UnknownVar) then
                   Result := varListExtra.CNF
                else
                   Result := MIN_CNF;
             end
             else begin
                if found then {Existe uma atribuição "Value" a "v".}
                   Result := NOTRule(varListExtra.CNF)
                else
                   Result := MAX_CNF;
             end;
          end;
          if operator = '>' then begin
             if found then begin
                if (StrToFloat(varListExtra.Value) > CalcResult(value_code))
                    and (not UnknownVar) then
                   Result := MAX_CNF
                else
                   Result := MIN_CNF
             end
             else
                 Result := MIN_CNF
          end;
          if operator = '<' then begin
             if found then begin
                if (StrToFloat(varListExtra.Value) < CalcResult(value_code))
                   and (not UnknownVar) then
                   Result := MAX_CNF
                else
                   Result := MIN_CNF
             end
             else
                 Result := MIN_CNF
          end;
          if operator = '>=' then begin
             if found then begin
                if (StrToFloat(varListExtra.Value) >= CalcResult(value_code)) and
                   (not UnknownVar) then
                   Result := MAX_CNF
                else
                   Result := MIN_CNF
             end
             else
                 Result := MIN_CNF
          end;
          if operator = '<=' then begin
             if found then begin
                if (StrToFloat(varListExtra.Value) <= CalcResult(value_code))
                   and (not UnknownVar) then
                   Result := MAX_CNF
                else
                   Result := MIN_CNF
             end
             else
                 Result := MIN_CNF
          end;
     end;
  end
  else
     Result := MIN_CNF;
end;

{Destrói todas as instância de uma variável. Utilizada somente para
 em variáveis cujos valores são obtidos a partir de uma pergunta. Veja
 também o método BrutalReturn}
procedure TExpertSystem.DestroyAllInstances(v: integer);
begin
   varList.Seek(v);
   while (not varList.Blind) and (varList.Code = v) do varList.Delete;
   varListExtra.Seek(v);
   while (not varListExtra.Blind) and (varListExtra.Code = v) do varListExtra.Delete;
   {Ao se deletar um item, automaticamente se passa para o próximo - MoveNext}
   InstanceList.DeleteAllInstances(v);
end;

{Essa é a função utilizada para o cálculo do fator de uma variável
 quando recebe duas vezes o mesmo valor.
 "Cnf1" é o CNF da atribuição anterior e "Cnf2", o da última.}
function TExpertSystem.DOUBLEEVALUATIONRule(Cnf1: single; Cnf2: single): single;
begin
   Result := (Cnf1 + Cnf2) - Cnf1 * Cnf2;
end;

{Essa subrotina, acionada após a validação de uma regra "rule", instancia
 todas as variáveis presentes na cabeça da mesma, de acordo com o
 CNF total das premissas.}
procedure TExpertSystem.ExecuteRule(rule: integer; cnf: single);
var
   order: integer;
   real_cnf: single;
   bookmark_head: TMetaNode;
begin
   if (not Quit) and (not FBrokenSequence) then begin
      order := 1;
      Heads.Seek(rule);
      while (not Heads.Blind) and (Heads.Code = rule) do begin
         bookmark_head := Heads.CurrentNode;
         LastHeadStep := order;
         real_cnf := HEADRule(cnf, Heads.CNF);

         if UpdateDebugEnabled then
            UpdateDebug(Heads.Code, order, false);

         AttribVar(Heads.VarCode, IntToStr(Heads.ValCode), real_cnf, True);
         Heads.CurrentNode := bookmark_head;
         Heads.MoveNext;
         inc(order);
       end;
   end;
end;

procedure TExpertSystem.ExecuteStep;
begin
   if Assigned(FOnExecuteStep) then FOnExecuteStep(Self);
   if not Trace then begin
      if not ExecutionMode then begin
         Trace := true;
         if DebugControl <> nil then
            DebugControl.ActiveTrace := true;
         NotifyControls(StatusViewControls);
         if Assigned(FOnPause) then FOnPause(Self);
         StartEngine;
      end
      else begin
         Trace := true;
         Wait := false;
      end;
   end
   else
      Wait := false;
end;

{Essa função se encarrega de avaliar expressões do tipo
 "aCONEC1bCONEC2c...THEN", onde a, b, c... são códigos das ordens
 de registros de uma cauda, todos relativos à regra "rule".
 O avaliador usa o método das pilhas para avaliar uma expressão.}
function TExpertSystem.ExpressionResult(expression: string; rule: integer): single;
var
   finish, aborted: boolean;
   answer: single;
   expression_stack: TStringStack; {Pilha da expressão pós-fixada}
   expression_indexes: TStringList;
   order: integer;
   tail_bookmark: TMetaNode;

   {Coloca a expressão da cauda na forma pós-fixada}
   procedure PostFix;
   var
     token: string;
     c: char;
     i: integer;
     aux_stack: TStringStack;
     turn_conect: boolean;
   begin
     aux_stack := TStringStack.Create;
     turn_conect := false;
     while expression <> THEN_STRING do begin
         i := 1;
         token := '';
         c := expression[i];
         while ((not turn_conect) and (c >= '0') and (c <= '9')) or
               (turn_conect and not ((c >= '0') and (c <= '9'))) do begin
            token := token + c;
            i := i + 1;
            if i > length(expression) then
               c := '0'
            else
               c := expression[i]
         end;
         expression := copy(expression, i, length(expression) - (i - 1));
         if turn_conect then begin
            if aux_stack.RecordCount <> 0 then
               case priority of
                  cnOr:
                    if (aux_stack.Top = ConectName(cnOr)) and (token = ConectName(cnAnd)) then
                       while aux_stack.RecordCount <> 0 do expression_stack.Push(aux_stack.Pop);
                  cnAnd:
                    if (aux_stack.Top = ConectName(cnAnd)) and (token = ConectName(cnOr)) then
                       while aux_stack.RecordCount <> 0 do expression_stack.Push(aux_stack.Pop);
               end;
            aux_stack.Push(token);
         end
         else begin
            expression_stack.Push('-1'); {Indica que ainda não foi avaliado}
            expression_indexes.Add(IntToStr(expression_stack.Items.Count - 1));
         end;
         turn_conect := not turn_conect;
      end;
      {Descarrega o restante da pilha auxiliar na pilha da expressão}
      while aux_stack.RecordCount <> 0 do expression_stack.Push(aux_stack.Pop);
      aux_stack.Free;
   end;

   function Evaluate(s: TStringStack): single;
   var
      total, cont: integer;
      r: TStringStack;

      {Utiliza os elementos do topo da pilha "result" e os calcula de
       acordo com o conectivo "op".}
      procedure Calc (result: TStringStack; op: string);
      var
         a, b: single;
      begin
         b := StrToFloat(result.Pop);
         a := StrToFloat(result.Pop);
         if op = ConectName(cnAnd) then
            result.Push(FloatToStr(ANDRule(a, b)))
         else
            result.Push(FloatToStr(ORRule(a, b)));
      end;

   begin
      r := TStringStack.Create;
      total := s.RecordCount - 1;
      cont := 0;
      while cont <= total do begin
         if not IsConect(s.Items[cont]) then {Se for um fator de confiança...}
            r.Push(s.Items[cont])
         else {Se for um conectivo...}
            Calc(r, s.Items[cont]);
         cont := cont + 1;
      end;
      Result := StrToFloat(r.Top);
      r.Free;
   end;

   function PreAnswer(stack: TStringStack; confidence: string): single;
   var
     st, eval_stack: TStringStack;
     shortcut: TIntegerStack;
     i, total, cont, size_st: integer;
     a, b: single;
   begin
     st := TStringStack.Create;
     eval_stack := TStringStack.Create;
     shortcut := TIntegerStack.Create;
     try
        total := stack.Items.Count - 1;
        for i := 0 to total do begin
            if stack.Items[i] <> '-1' then
               st.Push(stack.Items[i])
            else
               st.Push(confidence);
        end;

        {Aqui a estrutura de pilha vai ser usada de maneira diferente
         para permitir modificações em seus itens}
        size_st := st.Items.Count;
        cont := 0;

        while cont < size_st do begin
           if not IsConect(st.Items[cont]) then begin
              {E' uma premissa a ser pesquisada}
             eval_stack.Push(st.Items[cont]);
             shortcut.Push(cont);
           end
           else begin
              b := StrToFloat(eval_stack.Pop);
              a := StrToFloat(eval_stack.Pop);
              if st.Items[cont] = ConectName(cnAnd) then
                 eval_stack.Push(FloatToStr(ANDRule(a, b)))
              else
                 eval_stack.Push(FloatToStr(ORRule(a, b)));
              if ((StrToFloat(eval_stack.Top) >= MIN_VALUE) and (confidence = '0')) or
                 ((StrToFloat(eval_stack.Top) < MIN_VALUE) and (confidence = '1')) then
                 while not shortcut.Blind do begin
                    {Marca itens desnecessários}
                    if stack.Items[shortcut.Top] = '-1' then
                       stack.Items[shortcut.Pop] := confidence
                    else
                       shortcut.Pop;
                 end;
           end;
           inc(cont);
        end;
        Result := StrToFloat(eval_stack.Top);
     finally
        st.Free;
        eval_stack.Free;
        shortcut.Free;
     end;
   end;

begin
   if Quit then begin
      if Trace then Trace := False;
      ExecutionMode := False;
   end
   else begin

      expression_stack := TStringStack.Create;
      expression_indexes := TStringList.Create;
      finish := False;
      aborted := False;
      order := 1;
      Tails.Seek(rule); {Procura pelo primeiro nó com a regra.}
      tail_bookmark := Tails.CurrentNode;
      Result := 0;
      PostFix;

      repeat

        if (not FBrokenSequence) and
           (expression_stack.Items[StrToInt(expression_indexes[order - 1])] = '-1')
           then begin

           {Atualiza a posição do trace, se necessário}
           if UpdateDebugEnabled then
              UpdateDebug(Tails.Code, order, true);

           {Guarda o caminho feito, uma passagem por uma premissa}
           AddTrail(rule, order);
           answer := ComparationCNF(Tails.VarCode, IntToStr(Tails.ValCode),
                     Tails.Operator, Tails.Neg);
           {Atualiza os resultados das comparações na pilha de avaliação.}
           expression_stack.Items[StrToInt(expression_indexes[order - 1])]
              := FloatToStr(answer);
           if order = expression_indexes.Count then begin
              finish := true;
              Result := Evaluate(expression_stack);
           end
           else begin
              {Verifica se deve ser feita uma avaliação completa ou não}
              if (not ExamineAll) and (PreAnswer(expression_stack, '1') < MIN_VALUE) then
                 {É feita uma pré-avaliação com todos os items da cauda. Nas sentenças
                  que ainda não sabemos o valor de confiança, atribuímos o máximo CNF
                  possível (100%). Ao calcularmos as pilhas e encontrarmos um valor
                  inferior ao MIN_VALUE, a máquina de inferência não irá atrás das
                  sentenças restantes, pois de um modo ou de outro a regra irá falhar.}
                 Aborted := true
              else begin
                 if not ExamineAll then begin
                    Result := PreAnswer(expression_stack, '0');
                    if Result >= MIN_VALUE then
                      {É feita uma pré-avaliação com todos os items da cauda. Nas sentenças
                       que ainda não sabemos o valor de confiança, atribuímos o mínimo CNF
                       possível (0%). Ao calcularmos as pilhas e encontrarmos um valor
                       igual ou superior ao MIN_VALUE e se o usuário especificou que assim deseja
                       (variável de ambiente 'examine_all'), a máquina de inferência não
                       irá atrás das sentenças restantes, considerando a regra aceita, mesmo
                       que o CNF talvez não corresponda à realidade.}
                       finish := true
                 end;
              end;
           end;
        end
        else
           aborted := FBrokenSequence;

        if  not (finish or aborted or Quit) then begin
            Tails.CurrentNode := tail_bookmark;
            Tails.MoveNext;
            tail_bookmark := Tails.CurrentNode;
            inc(order);
        end;

      until (finish or aborted or Quit);

      expression_stack.Free;
      expression_indexes.Free;
   end;
end;

{Essa subrotina localiza e instancia uma variável de código cod_var, utili-
 zando o encadeamento para trás. Ela é chamada somente quando a variável
 ainda não possui nenhum valor.}
procedure TExpertSystem.Find(cod_var: integer);
var
   multi, continue, flag: boolean;
   already_exists: boolean;
   order: THelpContexts;

   procedure SeekRule(t: TMetaNode; var flag: boolean; multi: boolean);
   var
      cnf: single;
      rule: integer;
   begin
      {a propriedade "Context" equivale ao código da regra (o campo
       "Code" é a posição da regra).}
      rule := TContextNode(t.node).Context;
      UsedRules.Seek(rule);
      if UsedRules.Blind then begin
         {Só parte atrás da regra caso ela não tiver sido utilizada
         em momento algum.}
         cnf := TailResult(rule);
         if not FBrokenSequence then begin
            if cnf >= MIN_VALUE then begin
               AddTrail(RULE_OK, rule);
               {Instancia todas as variáveis da cabeça da regra "rule"}
               ExecuteRule(rule, cnf);
               AddTrail(RULE_EXECUTED, rule);
               flag := True;
            end
            else
               AddTrail(RULE_FAILED, rule);
            if not FBrokenSequence then UsedRules.Insert(rule);
         end;
      end;
   end;

begin
   if Quit then begin
      if Trace then Trace := False;
      ExecutionMode := False;
   end
   else begin
      varList.Seek(cod_var);
      varListExtra.Seek(cod_var);
      {A variável already_exists checa se a variável já foi instanciada
       alguma vez. Quando chamaríamos Find novamente para uma variável
       já com instâncias? No caso de variáveis objetivos que foram
       encontradas anteriormente, seja por outras regras ou mesmo com
       instâncias criadas via programação de front-ends. O método
       StartEngine não checa por outras instâncias - pode ser, por exemplo,
       que a variável seja multivalorada. Neste caso, precisamos encontrar
       os demais valores.}
      already_exists := (not varList.Blind) or (not varListExtra.Blind);
      order := THelpContexts.Create;
      AddTrail(SEARCHING, cod_var);
      Vars.Seek(cod_var);
      multi := Vars.Multi;
      HeadsVars.Seek(cod_var);
      continue := not HeadsVars.Blind;
      {Relembrando: a propriedade "Code" de HeadVars são os códigos
       das variáveis presentes nas cabeças, enquanto a propriedade
       "Context" são os código das regras}
      while (not HeadsVars.Blind) and (HeadsVars.Code = cod_var)
            and (not FBrokenSequence) do begin
         Rules.Seek(HeadsVars.Context);
         order.Insert(Rules.Position, HeadsVars.Context);
         HeadsVars.MoveNext;
      end;
      if continue then begin
         {Foi encontrada a variável procurada em alguma cabeça de regra.}
         flag := False;
         order.MoveFirst;
         while (not order.Blind)
               and (multi or ((not multi) and (not flag)))
               and (not FBrokenSequence) do begin
           {Esse jogo com 'Multi' e 'flag' é um cuidado para não se instanciar
            variáveis não multivaloradas mais de uma vez.}
            SeekRule(order.CurrentNode, flag, multi);
            order.MoveNext;
         end;
         {Se nenhum valor pôde ser atribuído a "cod_var", ela irá receber
          o valor "DESCONHECIDO", mas somente, claro, se antes não possuía
          nenhum valor (variável already_exists).}
         if (not flag) and (not FBrokenSequence) and (not already_exists) then begin
            AddTrail(ATTRIB_UNKNOWN, cod_var);
            AttribVar(cod_var, IntToStr(UNKNOWN), MAX_CNF, true);
         end;
      end
      else
         {Não foi encontrada a variável procurada em nenhuma cabeça de regra.
          Deve-se fazer uma pergunta ao usuário.}
         Prompt(cod_var);
      order.Free;
   end;
end;

{Essa é a função utilizada para o cálculo do fator de confiança de
 uma regra. "Cnf1" é o CNF total das premissas e "Cnf2" o que foi
 indicado pela regra.}
function TExpertSystem.HEADRule(c1: single; c2: single): single;
begin
   if CustomFormulas.DefaultConclusion then
      Result := c1 * c2
   else begin
      Cnf1 := c1;
      Cnf2 := c2;
      Result := CalcResultString(CustomFormulas.FormulaConclusion, UnknownVar);
   end;
end;

{Essa é a função utilizada para o cálculo do fator do operador "<>".
 "CNF" é o CNF da comparação.}
function TExpertSystem.NOTRule(cnf: single): single;
begin
   Result := MAX_CNF - cnf;
end;

{Essa é a função utilizada para o cálculo do fator do operador "OU".
 "Cnf1" é o CNF da primeira comparação e "Cnf2", o da segunda.}
function TExpertSystem.ORRule(c1: single; c2: single): single;
begin
   if CustomFormulas.DefaultOr then
      Result := (c1 + c2) - c1 * c2
   else begin
      Cnf1 := c1;
      Cnf2 := c2;
      Result := CalcResultString(CustomFormulas.FormulaOr, UnknownVar);
   end;
end;

{Aciona o formulário de perguntas para atribuir valores a variáveis
 que não podem ser inferidas pelas regras da base}
procedure TExpertSystem.DefaultPrompt(v: integer);
begin
   TRunTime(RunTime).BuildOptions(v);
   TRunTime(RunTime).Show;
end;

procedure TExpertSystem.Prompt(v: integer);
begin
   TrailEnabled := true;
   UpdateDebugEnabled := true;
   FWaitingAnswer := true;
   if Assigned(FOnPrompt) then
      FOnPrompt(Self, v)
   else
      DefaultPrompt(v);
   while FWaitingAnswer do Application.ProcessMessages;
   {Guarda o caminho feito, uma pergunta}
   if not FBrokenSequence then begin
      AddTrail(Question, v);
      inc(TotalQuestions);
      NotifyControls(StatusViewControls);
   end;
end;

{Dá uma pausa e entra no modo de depuração}
procedure TExpertSystem.PauseEngine;
begin
    if ExecutionMode and (not Trace) then begin
       if Assigned(FOnPause) then FOnPause(Self);
       Trace := True;
       NotifyControls(StatusViewControls);
       with CurrentTrace do UpdateDebug(rule, order, tail);
    end;
end;

{Procedimento chamado para recolocar a base no modo de execução,
 após ter dado uma pausa}
procedure TExpertSystem.ResumeEngine;
begin
   if ExecutionMode and Trace then begin
      if Assigned(FOnResume) then FOnResume(Self);
      Trace := False;
      Wait := False;
      NotifyControls(StatusViewControls);
   end;
end;

{Exibe os resultados obtidos pela máquina de inferência sobre
 a variável "v".}
procedure TExpertSystem.ShowResults(v: integer);
begin
  if Assigned(FOnShowResults) then
     FOnShowResults(Self, v);
end;

{A função devolve o CNF total das premissas da regra "rule".
 Primeiramente, ela verifica todos os conectivos da regra para
 acelerar o cálculo em certas condições. Em seguida, chama a função
 "ExpressionResult" para efetivamente calcular o resultado.}
function TExpertSystem.TailResult(rule: integer): single;
var
   expression, con_string: string;
   order: integer;
begin
   if Quit then begin
      if Trace then Trace := False;
      ExecutionMode := false;
   end
   else begin
      expression := '';
      {Procura pelo primeiro registro com a regra.}
      Tails.Seek(rule);
      order := 1;
      while (not Tails.Blind) and (Tails.Code = rule) do begin
         {Monta uma string com referências a todas as premissas e conectivos.}
         con_string := ConectName(Tails.Conect);
         expression := expression + IntToStr(order) + con_string;
         order := order + 1;
         Tails.MoveNext;
      end;
      Result := ExpressionResult(expression, rule);
   end;
end;

{======================================================================
 ======================================================================
                         FUNÇÕES DE USO GERAL
 ======================================================================
 ======================================================================}

{Construtor da classe TExpertSystem}
constructor TExpertSystem.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   FEmptyBase := true;
   FReportEnding := true;
   InstanceViewControls := TList.Create;
   VariableViewControls := TList.Create;
   KBViewControls := TList.Create;
   StatusViewControls := TList.Create;
end;

procedure TExpertSystem.SetDefault;
begin
   ExecutionMode := false;
   Trace := false;
   Wait := false;
   FEmptyBase := true;
   FFileName := '';
   Permission := TOTAL_PERMISSION;
   Priority := cnAnd;
   ExamineAll := false;
   MIN_VALUE := 0.5;
   FVersion := '1.1';
   with Info do begin
      Name := NO_NAME_BASE;
      Authors := '';
      Overture.Free;
      Overture := TStringList.Create;
      HelpFile := '';
      ShowIntro := false;
   end;
   with Protection do begin
      Password := '';
      Permission := TOTAL_PERMISSION;
      UsePassword := false;
   end;
   with CustomFormulas do begin
      FormulaAnd := '';
      DefaultAnd := true;
      FormulaOr := '';
      DefaultOr := true;
      FormulaConclusion := '';
      DefaultConclusion := true;
   end;
end;

procedure TExpertSystem.DestroyLinks;
var
   i, total: integer;
begin
   total := InstanceViewControls.Count - 1;
   for i := 0 to total do
       TExCtrlInterface(InstanceViewControls[i]).DestroyLink;

   total := VariableViewControls.Count - 1;
   for i := 0 to total do
       TExCtrlInterface(VariableViewControls[i]).DestroyLink;

   total := KBViewControls.Count - 1;
   for i := 0 to total do
       TExCtrlInterface(KBViewControls[i]).DestroyLink;

   total := StatusViewControls.Count - 1;
   for i := 0 to total do
       TExCtrlInterface(StatusViewControls[i]).DestroyLink;
end;

{Destrutor da classe TExpertSystem}
destructor TExpertSystem.Destroy;
begin
   DestroyLinks;
   Vars.Free;
   Values.Free;
   Heads.Free;
   Tails.Free;
   Rules.Free;
   Targets.Free;
   Questions.Free;
   HelpContexts.Free;
   Formulas.Free;
   Info.Overture.Free;
   InstanceViewControls.Free;
   VariableViewControls.Free;
   KBViewControls.Free;
   StatusViewControls.Free;
   inherited Destroy;
end;

{Limpa e recria as estruturas de dados da base de conhecimento}
procedure TExpertSystem.ClearBase;
begin
   Vars.Free;
   Values.Free;
   Heads.Free;
   Tails.Free;
   Rules.Free;
   Targets.Free;
   Questions.Free;
   HelpContexts.Free;
   Formulas.Free;
   Vars := TVars.Create;
   Values := TValues.Create;
   Heads := THeads.Create;
   Tails := TTails.Create;
   Rules := TRules.Create;
   Targets := TTargets.Create;
   Questions := TQuestions.Create;
   HelpContexts := THelpContexts.Create;
   Formulas := TFormulas.Create;
   SetDefault;
   RefreshLinks;
end;

{Salva a posição dos ponteiros nas árvores}
procedure TExpertSystem.BookmarkVar;
begin
   with Vars do begin
      BookmarkVars1 := CurrentNode;
      BookmarkVars2 := CurrentNodeName;
      OldIndexVars := CurrentKey;
   end;
   with Values do begin
      BookmarkValues1 := CurrentNode;
      BookmarkValues2 := CurrentNodeName;
      BookmarkValues3 := CurrentNodeVar;
      OldIndexValues := CurrentKey;
   end;
end;

{Restaura as posições dos ponteiros nas árvores}
procedure TExpertSystem.RestoreVarFromBookmark;
begin
   with Vars do begin
      CurrentNode := BookmarkVars1;
      CurrentNodeName := BookmarkVars2;
      CurrentKey := OldIndexVars;
   end;
   with Values do begin
      CurrentNode := BookmarkValues1;
      CurrentNodeName := BookmarkValues2;
      CurrentNodeVar := BookmarkValues3;
      CurrentKey := OldIndexValues;
   end;
end;

{Salva a posição dos ponteiros nas árvores}
procedure TExpertSystem.BookmarkQuestion;
begin
   BookmarkQuestions := Questions.CurrentNode;
end;

{Restaura as posições dos ponteiros nas árvores}
procedure TExpertSystem.RestoreQuestionFromBookmark;
begin
   Questions.CurrentNode := BookmarkQuestions;
end;

{É possível ver as regras? Elas não estão protegidas por senha?}
function TExpertSystem.CanView: boolean;
begin
   Result := Permission <> ONLY_EXECUTE;
end;

{Retorna o nome de um conectivo}
function TExpertSystem.ConectName(c: integer): string;
begin
   case c of
      cnAnd: Result := AND_STRING_EXTENDED;
      cnOr: Result := OR_STRING_EXTENDED;
      cnThen: Result := THEN_STRING;
   else
      begin
         MessageDlg(THERE_IS_NO_CONECT, mtError, [mbOk], 0);
         Result := UNDEFINED_TOKEN;
      end;
   end
end;

function TExpertSystem.FastRealValue(c: integer): string;
begin
   case c of
      UNKNOWN:
        Result := UNKNOWN_STRING;
      YES:
        Result := YES_STRING;
      NO:
        Result := NO_STRING;
      else begin
        if Vars.Numeric then
           Result := Formulas.Name
        else
           Result := Values.Name
      end;
  end;
end;

{Determina se uma determinada string é um dos conectivos aceitos no
 Expert SINTA}
function TExpertSystem.IsConect(s: string): boolean;
var
   i: integer;
begin
   i := 0;
   while (i <= 1) and (ConectName(i) <> s) do i := i + 1;
   if i <= 1 then
      Result := true
   else
      Result := false;
end;

function TExpertSystem.MyFloatToStr(r: single): string;
begin
   Result := FloatToStrF(r, ffGeneral, 5, 2);
end;

function TExpertSystem.RealValue(c: integer): string;
begin
   case c of
      UNKNOWN:
        Result := UNKNOWN_STRING;
      YES:
        Result := YES_STRING;
      NO:
        Result := NO_STRING;
      else begin
        if Vars.Numeric then begin
           Formulas.Seek(c);
           if not Formulas.Blind then
              Result := Formulas.Name
           else begin
              MessageDlg(NO_VALUE + '!', mtError, [mbOk], 0);
              Result := '';
           end;
        end
        else begin
           Values.Seek(c);
           if not Values.Blind then
              Result := Values.Name
           else begin
              MessageDlg(NO_VALUE + '!', mtError, [mbOk], 0);
              Result := '';
           end;
        end;
      end;
  end;
end;

function TExpertSystem.Space(size: integer): string;
var
   i: integer;
begin
   Result := '';
   for i := 1 to size do Result := Result + ' ';
end;

{Retorna o código de uma variável}
function TExpertSystem.VarCode(v: string): integer;
begin
   BookmarkVar;
   Vars.SeekByName(v);
   if not Vars.Blind then
      Result := Vars.Code
   else
      Result := -1;
   RestoreVarFromBookmark;
end;

{Retorna o código de um valor}
function TExpertSystem.ValCode(vr: integer; v: string): integer;
begin
   BookmarkVar;
   Values.SeekByName(v, vr);
   if not Values.Blind then
      Result := Values.Code
   else
      Result := -1;
   RestoreVarFromBookmark;
end;

{Retorna o nome de um valor}
function TExpertSystem.ValName(v, c: integer): string;
begin
   BookmarkVar;
   Vars.Seek(v);
   if not Vars.Blind then begin
      if not Vars.Numeric then begin
         case c of
            UNKNOWN:
               Result := UNKNOWN_STRING;
            YES:
               Result := YES_STRING;
            NO:
               Result := NO_STRING;
            else begin
                Values.Seek(c);
                if not Values.Blind then
                   Result := Values.Name
                else begin
                   MessageDlg(VALUE_NOT_FOUND, mtError, [mbOk], 0);
                   Result := UNDEFINED_TOKEN;
                end;
            end;
         end;
      end
      else begin
         if c = UNKNOWN then
            Result := UNKNOWN_STRING
         else begin
            Formulas.Seek(c);
            if not Formulas.Blind then
               Result := Formulas.Name
            else begin
                MessageDlg(FORMULA_NOT_FOUND, mtError, [mbOk], 0);
                Result := UNDEFINED_TOKEN;
            end;
         end;
      end;
   end
   else
      Result := UNDEFINED_TOKEN;
   RestoreVarFromBookmark;
end;

{Retorna o nome de uma variável}
function TExpertSystem.VarName(c: integer): string;
begin
   BookmarkVar;
   Vars.Seek(c);
   if not Vars.Blind then
      Result := Vars.Name
   else begin
      MessageDlg(VAR_NOT_FOUND, mtError, [mbOk], 0);
      Result := UNDEFINED_TOKEN;
   end;
   RestoreVarFromBookmark;
end;

{Devolve a lista de valores possíveis de uma variável em uma string list
 ordenadas pelo campo 'position'}
procedure TExpertSystem.ValuesList(V: integer; ListOfValues: TStringList);
var
   current_pos, compare_pos: integer;
   continue: boolean;
begin
   ListOfValues.Clear;
   Vars.Seek(V);
   if Vars.Numeric then Exit;
   Values.SeekByVar(V);
   if Values.Blind then begin
      {Decide se os valores são somente do tipo "sim/não"}
      ListOfValues.Add(YES_STRING);
      ListOfValues.Add(NO_STRING);
   end
   else begin
      while (not Values.Blind) and (Values.VarCode = V) do begin
         current_pos := Values.Position;
         compare_pos := 0;
         continue := true;
         while (compare_pos < ListOfValues.Count) and continue do begin
            if TValNode(ListOfValues.Objects[compare_pos]).Position > current_pos
               then continue := false;
            if (compare_pos < ListOfValues.Count) and continue then
                inc(compare_pos);
         end;
         ListOfValues.InsertObject(compare_pos, Values.Name, Values.CurrentNodeVar.Node);
         Values.MoveNext;
       end;
   end;
end;

{Este método preenche ValuesList e CNFsList com a respectiva lista de instâncias
 de uma dada variável V em ordem decrescente de CNF e ordem crescente de
 posição (atributo 'position' de TValNode)}
procedure TExpertSystem.VarInstances(V: integer; ValuesList, CNFsList: TStringList);
var
   Orders: TStringList;
   found: boolean;

   procedure QuickSortByCNF(l: integer; r: integer);
   var
      k: extended;
      i, j: integer;
   begin
      k := StrToFloat(CNFsList[trunc((l + r) / 2)]);
      i := l;
      j := r;
      repeat
         while StrToFloat(CNFsList[i]) > k do inc(i);
         while k > StrToFloat(CNFsList[j]) do dec(j);
         if i <= j then begin
            CNFsList.Exchange(i, j);
            ValuesList.Exchange(i, j);
            Orders.Exchange(i, j);
            inc(i);
            dec(j);
         end;
      until i > j;
      if l < j then QuickSortByCNF(l, j);
      if i < r then QuickSortByCNF(i, r);
   end;

   procedure QuickSortByPosition(l: integer; r: integer);
   var
      k, i, j: integer;
   begin
      k := StrToInt(orders[trunc((l + r) / 2)]);
      i := l;
      j := r;
      repeat
         while StrToInt(orders[i]) < k do inc(i);
         while k < StrToInt(orders[j]) do dec(j);
         if i <= j then begin
            Orders.Exchange(i, j);
            ValuesList.Exchange(i, j);
            {Não é preciso trocar os cnfs, pois são os mesmos
             em todo intervalo}
            inc(i);
            dec(j);
         end;
      until i > j;
      if l < j then QuickSortByPosition(l, j);
      if i < r then QuickSortByPosition(i, r);
   end;

   procedure OrderByPosition;
   var
      i, j, total: integer;
      old_cnfs: string;
   begin
      total := ValuesList.Count - 1;
      i := 0;
      while i < total do begin
          j := i;
          old_cnfs := CNFsList[i];
          while (i < total) and (CNFsList[i + 1] = old_cnfs) do inc(i);
          if i > j then QuickSortByPosition(j, i);
          inc(i);
      end;
   end;

begin
   ValuesList.Clear;
   CNFsList.Clear;
   if not ExecutionMode then Exit;
   Orders := TStringList.Create;
   try
      Orders.Clear;
      found := false;
      Vars.Seek(V);
      varList.MoveFirst;
      while not varList.Blind do begin
         if varList.Code = V then begin
            found := true;
            if varList.ValCode <> UNKNOWN then begin
               ValuesList.Add(RealValue(varList.ValCode));
               CNFsList.Add(MyFloatToStr(100 * varList.CNF));
               if not Vars.Numeric then begin
                 {lembrando que variáveis numéricas são univaloradas}
                 if (varList.ValCode = YES) or
                    (varList.ValCode = NO) then
                    Orders.Add('1')
                 else begin
                    Values.Seek(varList.ValCode);
                    Orders.Add(IntToStr(Values.Position));
                 end;
              end;
            end
            else begin
               ValuesList.Add(NO_VALUE);
               CNFsList.Add('100');
            end;
         end;
         varList.MoveNext;
      end;
      varListExtra.MoveFirst;
      while not varListExtra.Blind do begin
         if varListExtra.Code = V then begin
            found := true;
            ValuesList.Add(varListExtra.Value);
            CNFsList.Add(MyFloatToStr(100 * varListExtra.cnf));
         end;
         varListExtra.MoveNext;
      end;
      if not Found then ValuesList.Add(NO_VALUE);
      if ValuesList.Count > 1 then begin
         QuickSortByCnf(0, ValuesList.Count - 1);
         OrderByPosition;
      end;
   finally
      Orders.Free;
   end;
end;


{======================================================================
 ======================================================================
                       CÁLCULO DE FUNÇÕES MATEMÁTICAS
 ======================================================================
 ======================================================================}

function TExpertSystem.CalcResult(fun: integer): single;
var
   unknown_var: boolean;
begin
   Formulas.Seek(fun);
   if not Formulas.Blind then
      Result := CalcResultString(Formulas.Name, unknown_var)
   else begin
      MessageDlg(FORMULA_NOT_FOUND, mtError, [mbOk], 0);
      Result := 0;
   end;
   UnknownVar := unknown_var;
end;

function TExpertSystem.CalcResultString(fun: string; var UnknownVar: boolean): single;
var
   Formula  :string;
   BufFonte :string;
   Valor    :single;
   Cadeia   :string;
   CmpTok   :single;
   Carac    :char;
   PtrFonte :byte;
   PtrMem   :integer;
   PtrSimb  :integer;
   Tam      :integer;
   Token    :byte;
   Neg      :byte;

   {********** Métodos de cálculo de expressões *********}
    function  AnalyseFunction: single; forward;
    procedure StartCalc; forward;
    function  F: single; forward;
    function  E: single; forward;
    function  T: single; forward;
    function  T_LINHA(var aux1: single): single; forward;
    function  E_LINHA(var aux3: single): single; forward;
    function  IdentFunctions: single; forward;
    function  ConsNumerica:single; forward;
    procedure TestFunction; forward;
    procedure ExpressionError(error_msg: string); forward;
    function  SymbolTable: single; forward;
    procedure GetChar; forward;
    procedure EraseBlankSpace; forward;

procedure StartCalc;
begin
  UnknownVar := false;
  PtrFonte := 1;
  BufFonte := '';
  Carac := ' ';
  PtrMem := 0;
  PtrSimb := 1;
  Cadeia := 'a';
  Neg := 0;
end;

function AnalyseFunction: single;
var
      aux      : single;
      min      : single;
      max      : single;
      base     : single;
      flag     : byte;
begin
       flag:=1;
       case token of
            3:   { MIN }
                 begin
                 EraseBlankSpace;
                 if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                 GetChar;
                 repeat
                      EraseBlankSpace;
                      if flag = 1 then
                           begin
                           min:=E;
                           flag:=0;
                           end
                      else
                           begin
                           aux:=E;
                           if aux < min then
                              min:=aux;
                           end;
                      EraseBlankSpace;
                      if carac =',' then
                         GetChar
                      else
                         if (carac <> ',') and (carac <> ')') then
                            ExpressionError(COMMA_CLOSE_PARENTH_EXPECTED);
                 until carac = ')';
                 AnalyseFunction:=min;
                 GetChar;
                 end;
             4:   { MAX }
                 begin
                 EraseBlankSpace;
                 if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                 GetChar;
                 repeat
                      EraseBlankSpace;
                      if flag = 1 then
                           begin
                           max:=E;
                           flag:=0;
                           end
                      else
                           begin
                           aux:=E;
                           if aux > max then
                                max:=aux;
                           end;
                       EraseBlankSpace;
                       if carac = ',' then
                          GetChar
                       else
                          if (carac <> ',') and (carac <> ')') then
                             ExpressionError(COMMA_CLOSE_PARENTH_EXPECTED);
                 until carac = ')';
                 AnalyseFunction:=max;
                 GetChar;
                 end;
            5:   { SQR }
                 begin
                 EraseBlankSpace;
                 if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                 GetChar;
                 EraseBlankSpace;
                 AnalyseFunction:=sqrt(E);
                 EraseBlankSpace;
                 if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                 GetChar;
                 end;
            6:   { EXP }
                 begin
                 EraseBlankSpace;
                 if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                 GetChar;
                 EraseBlankSpace;
                 AnalyseFunction:=exp(E);
                 EraseBlankSpace;
                 if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                 GetChar;
                 end;
            7:   { POT }
                 begin
                 EraseBlankSpace;
                 if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                 GetChar;
                 EraseBlankSpace;
                 base:=E;
                 EraseBlankSpace;
                 if carac <> ',' then ExpressionError(COMMA_EXPECTED);
                 GetChar;
                 EraseBlankSpace;
                 aux:=E;
                 EraseBlankSpace;
                 if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                 AnalyseFunction:=exp(aux*ln(base));
                 GetChar;
                 end;
            8:   { LOG }
                 begin
                 EraseBlankSpace;
                 if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                 GetChar;
                 EraseBlankSpace;
                 base:=E;
                 EraseBlankSpace;
                 if carac <> ',' then ExpressionError(COMMA_EXPECTED);
                 GetChar;
                 EraseBlankSpace;
                 aux:=E;
                 EraseBlankSpace;
                 if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                 AnalyseFunction:=ln(base)/ln(aux);
                 GetChar;
                end;
            9:   { LN }
                 begin
                      EraseBlankSpace;
                      if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                      GetChar;
                      EraseBlankSpace;
                      AnalyseFunction:=ln(E);
                      EraseBlankSpace;
                      if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                      GetChar;
                 end;
           10:   { ABS }
                 begin
                      EraseBlankSpace;
                      if carac <> '('then ExpressionError(OPEN_PARENTH_EXPECTED);
                      GetChar;
                      EraseBlankSpace;
                      aux:=E;
                      if aux >= 0 then
                           AnalyseFunction:=aux
                      else
                           AnalyseFunction:=-aux;
                      EraseBlankSpace;
                      if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                      GetChar;
                 end;
            11:  { SEN }
                 begin
                      EraseBlankSpace;
                      if carac <> '(' then ExpressionError(OPEN_PARENTH_EXPECTED);
                      GetChar;
                      EraseBlankSpace;
                      AnalyseFunction:=sin(E);
                      EraseBlankSpace;
                      if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                      GetChar;
                 end;
            12:  { COS }
                 begin
                      EraseBlankSpace;
                      if carac <> '('then ExpressionError(OPEN_PARENTH_EXPECTED);
                      GetChar;
                      EraseBlankSpace;
                      AnalyseFunction:=cos(E);
                      EraseBlankSpace;
                      if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                      GetChar;
                 end;
             13:  { TAN }
                 begin
                      EraseBlankSpace;
                      if carac <> '('then ExpressionError(OPEN_PARENTH_EXPECTED);
                      GetChar;
                      EraseBlankSpace;
                      aux:=E;
                      AnalyseFunction:=sin(aux)/cos(aux);
                      EraseBlankSpace;
                      if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
                      GetChar;
                 end;
             end;
end;

function F: single;
var
   aux4: single;
begin
   case carac of
        'A'..'Z' :
             begin
             F:=IdentFunctions;
             end;
        '0'..'9' :
             begin
              F:=ConsNumerica;
             end;
        '(' :
             begin
             GetChar;
             F:=E;
             if carac <> ')' then ExpressionError(CLOSE_PARENTH_EXPECTED);
             GetChar;
             end;
         '"':
             begin
             cadeia:='';
             GetChar;
             EraseBlankSpace;
             while (carac <> '"') and (carac <> #0) do begin
                  cadeia:=cadeia + carac;
                  GetChar;
             end;
             if carac = #0 then ExpressionError(QUOTE_EXPECTED);
             F:=SymbolTable;
             GetChar;
             EraseBlankSpace;
             end;
         '-':
             begin
             GetChar;
             EraseBlankSpace;
             if carac <> '(' then begin
                Neg:=1;
                aux4:=E;
             end
             else
                aux4:=-E;
             F:=aux4;
             T_LINHA(aux4);
             end;
         '+':
             begin
            GetChar;
             EraseBlankSpace;
             aux4:=E;
             F:=aux4;
             T_LINHA(aux4);
            end;
       else
            ExpressionError(INDENTIFIER_CLOSE_PARENTH_EXPECTED);
   end; {Fim do case}
end; {Fim do procedimento F}

function E: single;
var
 aux2:single;
begin
  aux2 := T;
  E := E_LINHA(aux2);
end;

function T: single;
var
   aux: single;
begin
   if Neg = 0 then
      aux := F
   else begin
      aux := -F;
      Neg := 0;
   end;
   EraseBlankSpace;
   T := T_LINHA(aux);
end;

function T_LINHA(var aux1: single):single;
var
  dummy: single;
begin
  if carac = '*' then begin
     GetChar;
     EraseBlankSpace;
     aux1 := aux1 * F;
     EraseBlankSpace;
     dummy := T_LINHA(aux1);
  end
  else
     if carac = '/' then begin
        GetChar;
        EraseBlankSpace;
        aux1 := aux1 / F;
        EraseBlankSpace;
        dummy := T_LINHA(aux1);
     end;
  T_LINHA := aux1;
end;

function E_LINHA(var aux3: single): single;
var
  dummy: single;
begin
if carac = '+' then begin
    GetChar;
    EraseBlankSpace;
    aux3 := aux3 + T;
    EraseBlankSpace;
    dummy := E_LINHA(aux3);
end
else
  if carac = '-' then begin
     GetChar;
     EraseBlankSpace;
     aux3 := aux3 - T;
     EraseBlankSpace;
     dummy := E_LINHA(aux3);
  end;
  E_LINHA := aux3;
end;

function IdentFunctions: single;
begin
  cadeia := '';
  while carac in ['A'..'Z','0'..'9'] do begin
     cadeia := cadeia + carac;
     GetChar;
  end;
  TestFunction;
  if token = TOK_id then
     IdentFunctions := SymbolTable
  else
     IdentFunctions := AnalyseFunction;
end;

function ConsNumerica:single;
var
   deci : single;
   cont : integer;
   i    : integer;
begin
   token:=TOK_ct;
   CmpTok:=0;
   repeat
       CmpTok:=CmpTok * 10 + (ord(carac) - ord('0'));
       GetChar;
   until not(carac in['0'..'9']);
   if carac = '.' then begin
      deci:=0;
      cont:=0;
      GetChar;
      if not (carac in['0'..'9']) then ExpressionError(INVALID_CHAR);
      repeat
         deci:=deci * 10 + (ord(carac) - ord('0'));
         cont:=cont + 1;
         GetChar;
      until not(carac in['0'..'9']);
      for i:=1 to cont do deci:=deci/10;
      CmpTok:=CmpTok + deci;
   end;
   ConsNumerica := CmpTok;
end;

procedure TestFunction;
var
 i: integer;
begin
  i := 0;
  repeat
     i := i + 1;
  until (tab_res[i] = cadeia) or (i = 12);
  token := tab_fun[i];
end;

function SymbolTable: single;
var
   cod: integer;
   achou: boolean;
begin
   if cadeia = VAR_CNF_1 then
      SymbolTable := Cnf1
   else begin
      if cadeia = VAR_CNF_2 then
         SymbolTable := Cnf2
      else begin
         Vars.SeekByName(cadeia);
         if Vars.Blind then begin
            ExpressionError(UNDECLARED_VAR + ' ' + cadeia + '!' + Chr(13) + Chr(10));
            valor := 0;
         end
         else begin
            cod := Vars.Code;
            repeat
               achou := false;
               varListExtra.Seek(cod);
               if not varListExtra.Blind then begin
                  achou := true;
                  valor := StrToFloat(varListExtra.Value);
               end
               else begin
                  varList.Seek(cod);
                  if not varList.Blind then begin
                     {Se a variável numérica foi encontrada em varList,
                      é porque ela assumiu como instanciação o DESCONHECIDO}
                     achou := true;
                     valor := 0;
                     UnknownVar := true;
                  end
                  else
                     Find(cod);
               end;
            until achou or (Quit) or (FBrokenSequence);
         end;
         SymbolTable := valor;
      end;
   end;
end;

procedure ExpressionError(error_msg: string);
begin
   if not UnknownVar then
      raise EExpSyntaxError.Create(error_msg + ' ' + FUNCTION_STRING + ': ' + Formula);
end;

procedure GetChar;
var
  aux: string[1];
begin
  if PtrFonte = 1 then begin
    tam := length(Formula);
    if tam = 0 then
       ExpressionError(EMPTY_FORMULA)
    else
       BufFonte:=Formula;
 end;
 if PtrFonte > length(Formula) then
    carac := #0
 else begin
    {Um truque para poder utilizar a função AnsiUpperCase com um tipo
     char}
    aux[0] := '1';
    aux[1] := BufFonte[PtrFonte];
    aux := AnsiUpperCase(aux);
    carac := aux[1];
  end;
  if tam >= PtrFonte then PtrFonte := PtrFonte + 1;
end;

procedure EraseBlankSpace;
begin
   while carac = ' ' do GetChar;
end;

begin
   Formula := fun;
   StartCalc;
   while carac = ' ' do GetChar;
   Result := trunc(100 * E) / 100; {Precisão de duas casas}
   if carac <> #0 then ExpressionError(UNEXPECTED_END_EXPRESSION);
end;

{======================================================================
 ======================================================================
                       ABRIR/SALVAR ARQUIVO DA BASE
 ======================================================================
 ======================================================================}

{Verifica se o arquivo tem o cabeçalho pré-definido que identifica
 arquivos do Expert SINTA - Ver procedimento "SaveHeader" para maiores
 informações.}
function TExpertSystem.CheckHeader(FN: string): boolean;
var
   aux, aux2: THeader;
   i: TMyInteger;
begin
   aux[1] := 45;
   aux[2] := 12;
   aux[3] := 189;
   aux[4] := 22;
   aux[5] := 99;
   aux[6] := 40;
   aux[7] := 243;
   aux[8] := 151;
   aux[9] := 202;
   aux[10] := 33;
   AssignFile(TheFile, FN);
   Reset(TheFile, 1);
   BlockRead(TheFile, aux2, sizeof(aux2));
   i := 1;
   while (i < 10) and (aux[i] = aux2[i]) do i := i + 1;
   if i = 10 then
      case aux2[10] of
         33: begin
               FVersion := '1.0';
               Result := true;
             end;
         34: begin
               FVersion := '1.1';
               Result := true;
             end;
         else begin
             Close(TheFile);
             MessageDlg(OLD_VERSION_WARNING, mtError, [mbOk], 0);
             Result := false;
         end;
      end
   else begin
      Close(TheFile);
      Result := false;
   end;
end;

{Verificação de senhas, dando como resposta a prioridade}
function TExpertSystem.CheckPassword: integer;
var
   size: integer;
   dialogPasswd: TdialogPasswd;
begin
   dialogPasswd := TdialogPasswd.Create(nil);
   size := sizeof(Protection.Password) +
           sizeof(Protection.Permission) +
           sizeof(Protection.UsePassword);
   {Calculamos 'size' desta forma pois o tipo record em 32-bit é alinhado,
    ou seja, o tamanho de 'protection' é 260, e não 259, como a soma acima
    acusa}
   BlockRead(TheFile, Protection, size);
   if Protection.UsePassword then begin
      dialogPasswd.Passwd := Decrypt(Protection.Password, THE_KEY);
      dialogPasswd.PrimaryPermission := Protection.Permission;
      if dialogPasswd.ShowModal = mrOk then begin
         if dialogPasswd.Password.Text = '' then {aceita restrições}
            Result := Protection.Permission
         else
            Result := TOTAL_PERMISSION; {acesso total}
      end
      else
         Result := NO_PERMISSION; {cancelado}
   end
   else
      Result := TOTAL_PERMISSION;
   dialogPasswd.Free;
end;

procedure TExpertSystem.SetFileName(FN: string);
begin
   if FN <> '' then begin
      if LoadFromFile(FN) then
         FFileName := FN
      else
         FFileName := '';
   end
   else begin
      FFileName := '';
      FEmptyBase := true;
   end;
   RefreshLinks;
end;

procedure TExpertSystem.RefreshLinks;
begin
   NotifyControls(InstanceViewControls);
   NotifyControls(VariableViewControls);
   NotifyControlsWithPermission(KBViewControls);
   NotifyControls(StatusViewControls);
end;

function TExpertSystem.LoadFromFile(FN: string): boolean;
var
   var_aux: TVarRecord;
   val_aux: TValRecord;
   val_aux_1_0: TValRecord_1_0;
   targ_aux: TTargetRecord;
   rule_aux: TRuleRecord;
   head_aux: THeadRecord;
   formula_aux: TFormulaRecord;
   context_aux: TContextRecord;

   {Carrega informações}
   procedure LoadInfo;
   var
      total, cont: TMyInteger;
      aux: string;
   begin
     BlockRead(TheFile, info.Name, sizeof(info.Name));
     BlockRead(TheFile, info.authors, sizeof(info.authors));
     {Obs. Como TStringList têm tamanho variado, precisamos salvá-la
      linha por linha, bem como incluir no arquivo o total de linhas,
      para posterior leitura (LoadBase)}
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
        BlockRead(TheFile, aux, sizeof(aux));
        info.overture.Add(aux);
     end;
     BlockRead(TheFile, info.HelpFile, sizeof(info.HelpFile));
     BlockRead(TheFile, info.ShowIntro, sizeof(info.ShowIntro));
     if FVersion = '1.0' then
        with CustomFormulas do begin
           FormulaAnd := '';
           DefaultAnd := true;
           FormulaOr := '';
           DefaultOr := true;
           FormulaConclusion := '';
           DefaultConclusion := true;
        end
     else {versão 1.1}
        BlockRead(TheFile, CustomFormulas, sizeof(CustomFormulas));
   end;

  {Carrega variáveis}
  procedure LoadVars;
  var
     cont, total: TMyInteger;
  begin
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
         BlockRead(TheFile, var_aux, sizeof(var_aux));
         Vars.Insert(var_aux.Code, var_aux.Name, var_aux.Numeric, var_aux.Multi);
     end;
  end;

  {Carregar valores}
  procedure LoadValues;
  var
     cont, total: TMyInteger;
     next_code: integer;
  begin
     BlockRead(TheFile, total, sizeof(total));
     if FVersion = '1.0' then
        for cont := 1 to total do begin
            BlockRead(TheFile, val_aux_1_0, sizeof(val_aux_1_0));
            Values.SeekByVar(val_aux_1_0.VarCode );
            next_code := 1;
            while (not Values.Blind) and (Values.VarCode = val_aux_1_0.VarCode)
            do begin
               inc(next_code);
               Values.MoveNext;
            end;
            Values.Insert(val_aux_1_0.Code, val_aux_1_0.Name,
                          val_aux_1_0.VarCode, next_code);
        end
     else
        for cont := 1 to total do begin
            BlockRead(TheFile, val_aux, sizeof(val_aux));
            Values.Insert(val_aux.Code, val_aux.Name,
                          val_aux.VarCode, val_aux.Position);
        end;
  end;

  {Carregar cabeças}
  procedure LoadHeads;
  var
     cont, total: TMyInteger;
  begin
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
         BlockRead(TheFile, head_aux, sizeof(head_aux));
         Heads.Insert(head_aux.Code, head_aux.VarCode,
               head_aux.ValCode, head_aux.CNF);
     end;
  end;

  {Carregar caudas}
  procedure LoadTails;
  var
     cont, total: TMyInteger;
     {$IFDEF WINDOWS}
        tail_aux: TTailRecord;
     {$ELSE}
        code_aux, var_code_aux, val_code_aux, conect_aux: TMyInteger;
        neg_aux: boolean;
        op_aux: string[2];
     {$ENDIF}
  begin
     BlockRead(TheFile, total, sizeof(total));
     {$IFDEF WINDOWS}
     for cont := 1 to total do begin
         BlockRead(TheFile, tail_aux, sizeof(tail_aux));
         Tails.Insert(tail_aux.Code, tail_aux.VarCode, tail_aux.Operator,
                      tail_aux.ValCode, tail_aux.Conect, tail_aux.Neg);
     end;
     {$ELSE}
        for cont := 1 to total do begin
            BlockRead(TheFile, code_aux, sizeof(code_aux));
            BlockRead(TheFile, var_code_aux, sizeof(var_code_aux));
            BlockRead(TheFile, op_aux, sizeof(op_aux));
            BLockRead(TheFile, val_code_aux, sizeof(val_code_aux));
            BlockRead(TheFile, conect_aux, sizeof(conect_aux));
            BlockRead(TheFile, neg_aux, sizeof(neg_aux));
            Tails.Insert(code_aux, var_code_aux, op_aux,
                         val_code_aux, conect_aux, neg_aux);
        end;
     {$ENDIF}
  end;

  {Carregar regras}
  procedure LoadRules;
  var
     cont, total: TMyInteger;
  begin
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
         BlockRead(TheFile, rule_aux, sizeof(rule_aux));
         Rules.Insert(rule_aux.Code, rule_aux.Name, rule_aux.VarCode, 0);
     end;
  end;

  {Carregar fórmulas}
  procedure LoadFormulas;
  var
     cont, total: TMyInteger;
  begin
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
        BlockRead(TheFile, formula_aux, sizeof(formula_aux));
        Formulas.Insert(formula_aux.Code, formula_aux.Formula);
     end;
  end;

  {Carregar perguntas}
  procedure LoadQuestions;
  var
     code, total_why, why_cont, cont, total: TMyInteger;
     question, why_item: string;
     aux: TStringList;
     use_rule: boolean;
  begin
     aux := TStringList.Create;
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
         aux.Clear;
         BlockRead(TheFile, Code, sizeof(Code));
         BlockRead(TheFile, Question, sizeof(Question));
         BlockRead(TheFile, total_why, sizeof(total_why));
         for why_cont := 1 to total_why do begin
             BlockRead(TheFile, why_item, sizeof(why_item));
             aux.Add(why_item);
         end;
         if FVersion = '1.0' then
            Questions.Insert(Code, Question, aux, true)
         else begin
            BlockRead(TheFile, use_rule, sizeof(use_rule));
            Questions.Insert(Code, Question, aux, use_rule);
         end;
     end;
     aux.Free;
  end;

  {Carregar objetivos}
  procedure LoadTargets;
  var
     aux, cont, total: TMyInteger;
     targ_node: TTargetNode;
  begin
     BlockRead(TheFile, total, sizeof(total));
     if FVersion = '1.0' then
        for cont := 1 to total do begin
            BlockRead(TheFile, aux, sizeof(aux));
            targ_node := TTargetNode.Create;
            targ_node.Code := aux;
            Targets.Add(targ_node);
        end
     else
        for cont := 1 to total do begin
            BlockRead(TheFile, targ_aux, sizeof(targ_aux));
            targ_node := TTargetNode.Create;
            targ_node.Code := targ_aux.Code;
            targ_node.ShowResults := targ_aux.ShowResults;
            Targets.Add(targ_node);
        end;
  end;

  {Carregar contextos de ajuda}
  procedure LoadContexts;
  var
     cont, total: TMyInteger;
  begin
     BlockRead(TheFile, total, sizeof(total));
     for cont := 1 to total do begin
         BlockRead(TheFile, context_aux, sizeof(context_aux));
         HelpContexts.Insert(context_aux.Code, context_aux.Context);
     end;
  end;

  {Carrega opções gerais}
  procedure LoadGeneralOptions;
  var
     real_MIN_VALUE: real; {Para manter compatibilidade com a
                            versão antiga do Expert SINTA}
  begin
     BlockRead(TheFile, Priority, sizeof(Priority));
     BlockRead(TheFile, real_MIN_VALUE, sizeof(real_MIN_VALUE));
     MIN_VALUE := real_MIN_VALUE;
     BlockRead(TheFile, ExamineAll, sizeof(ExamineAll));
  end;

begin
 Result := true;
 if CheckHeader(FN) then begin
    try
      ClearBase;
      Permission := CheckPassword;
      if Assigned(FAfterCheckPassword) and (Permission > NO_PERMISSION) then
         FAfterCheckPassword(Self);
      LoadInfo;
      LoadVars;
      LoadValues;
      LoadHeads;
      LoadTails;
      LoadRules;
      LoadFormulas;
      LoadQuestions;
      LoadTargets;
      LoadContexts;
      LoadGeneralOptions;
      FEmptyBase := false;
    except
      Permission := CORRUPTED_FILE;
      FEmptyBase := true;
      MessageDlg(OPEN_FILE_ERROR, mtError, [mbOk], 0);
      Result := false;
    end;
    Close(TheFile);
    if Permission <= NO_PERMISSION then begin
       ClearBase;
       Result := false;
    end;
 end
 else begin
    Permission := BAD_FILE;
    Result := false;
 end;
end;

function TExpertSystem.SaveToFile(FN: string): boolean;
var
   var_aux: TVarRecord;
   val_aux: TValRecord;
   val_aux_1_0: TValRecord_1_0;
   targ_aux: TTargetRecord;
   rule_aux: TRuleRecord;
   head_aux: THeadRecord;
   tail_aux: TTailRecord;
   formula_aux: TFormulaRecord;
   ask_aux: TPartialQuestionRecord;
   aux_why: string;
   context_aux: TContextRecord;

  {Ao carregar um arquivo, o Expert SINTA confere se os 10 primeiros
   bytes são os pré-definidos (ver procedimento a seguir para saber
   os bytes pré-definidos). Em caso afirmativo, o arquivo deve ser do
   formato Expert SINTA. Seria MUITO azar abrir um arquivo com os mesmos
   10 primeiros bytes que não fosse um arquivo ExSINTA - probabilidade
   de uma chance em 2^80 (dois elevado a octogésima potência).}
  procedure SaveHeader;
  var
     aux: THeader;
  begin
     aux[1] := 45;
     aux[2] := 12;
     aux[3] := 189;
     aux[4] := 22;
     aux[5] := 99;
     aux[6] := 40;
     aux[7] := 243;
     aux[8] := 151;
     aux[9] := 202;
     if Version = '1.0' then
        aux[10] := 33
     else
        aux[10] := 34;
     BlockWrite(TheFile, aux, sizeof(aux));
  end;

  {O procedimento a seguir salva as informações gerais dadas pelo
   usuário, incluindo o nome da base, o nome dos autores, um texto de
   abertura e o nome do arquivo de ajuda.}
  procedure SaveInfo;
  var
     cont, total: TMyInteger;
     aux: string;
  begin
     BlockWrite(TheFile, Info.Name, sizeof(Info.Name));
     BlockWrite(TheFile, Info.Authors, sizeof(Info.Authors));
     {Obs. Como TStringList têm tamanho variado, precisamos salvá-la
      linha por linha, bem como incluir no arquivo o total de linhas,
      para posterior leitura (LoadBase)}
     total := Info.Overture.Count;
     BlockWrite(TheFile, total, sizeof(total));
     for cont := 0 to total - 1 do begin
        aux := Info.overture[cont];
        BlockWrite(TheFile, aux, sizeof(aux));
     end;
     BlockWrite(TheFile, Info.HelpFile, sizeof(Info.HelpFile));
     BlockWrite(TheFile, Info.ShowIntro, sizeof(Info.ShowIntro));
     if version > '1.0' then BlockWrite(TheFile, CustomFormulas, sizeof(CustomFormulas));
  end;

  {Salvar variáveis}
  procedure SaveVars;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     Node: TNode;
     total: TMyInteger;

     procedure SaveVarItem(t: TNode);
     begin
        var_aux.Code := TVarNode(t).Code;
        var_aux.Name := TVarNode(t).Name;
        var_aux.Multi := TVarNode(t).Multi;
        var_aux.Numeric := TVarNode(t).Numeric;
        BlockWrite(TheFile, var_aux, sizeof(var_aux));
     end;

  begin
     total := Vars.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        {Grava Vars de forma balanceada}
        if Vars.RecordCount > 1 then
           max := 1
        else
           max := Vars.RecordCount - 1;
        Vars.CurrentKey := PRIMARY_KEY;
        for j := 0 to max do begin
           Vars.MoveFirst;
           if j = 0 then
              total := Vars.RecordCount div 2
           else
              total := (Vars.RecordCount div 2) - 1;
           for i := 1 to total do Vars.MoveNext;
           current_node_1 := Vars.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Vars.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.Node;
                 SaveVarItem(Node);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.Node;
                 SaveVarItem(node);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
            end;
        end;
     end;
  end;

  {Salvar valores}
  procedure SaveValues;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     Node: TNode;
     total: TMyInteger;

     procedure SaveValItem(t: TNode);
     begin
        if version = '1.0' then begin
           val_aux_1_0.Code := TValNode(t).Code;
           val_aux_1_0.Name := TValNode(t).Name;
           val_aux_1_0.VarCode := TValNode(t).VarCode;
           BlockWrite(TheFile, val_aux_1_0, sizeof(val_aux_1_0));
        end
        else begin
           val_aux.Code := TValNode(t).Code;
           val_aux.Name := TValNode(t).Name;
           val_aux.VarCode := TValNode(t).VarCode;
           val_aux.Position := TValNode(t).Position;
           BlockWrite(TheFile, val_aux, sizeof(val_aux));
        end;
     end;

  begin
     total := Values.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        {Grava Values de forma balanceada}
        Values.CurrentKey := PRIMARY_KEY;
        if Values.RecordCount > 1 then
           max := 1
        else
           max := Values.RecordCount - 1;
        for j := 0 to max do begin
           Values.MoveFirst;
           if j = 0 then
              total := Values.RecordCount div 2
           else
              total := (Values.RecordCount div 2) - 1;
           for i := 1 to total do Values.MoveNext;
           current_node_1 := Values.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Values.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.node;
                 SaveValItem(node);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.Node;
                 SaveValItem(node);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salvar cabeças}
  procedure SaveHeads;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     node: TNode;
     total: TMyInteger;

     procedure SaveHeadItem(Code: integer);
     begin
        Heads.Seek(Code);
        while (not Heads.Blind) and (Heads.Code = Code) do begin
           head_aux.Code := Heads.Code;
           head_aux.VarCode := Heads.VarCode;
           head_aux.ValCode := Heads.ValCode;
           head_aux.Cnf := Heads.Cnf;
           BlockWrite(TheFile, head_aux, sizeof(head_aux));
           Heads.MoveNext;
        end;
     end;

  begin
     total := Heads.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        if Rules.RecordCount > 1 then
           max := 1
        else
           max := Rules.RecordCount - 1;
        Rules.CurrentKey := PRIMARY_KEY;
        for j := 0 to max do begin
           Rules.MoveFirst;
           if j = 0 then
              total := Rules.RecordCount div 2
           else
              total := (Rules.RecordCount div 2) - 1;
           for i := 1 to total do Rules.MoveNext;
           current_node_1 := Rules.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Rules.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.node;
                 SaveHeadItem(node.Code);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.node;
                 SaveHeadItem(node.Code);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salvar caudas}
  procedure SaveTails;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     node: TNode;
     total: TMyInteger;

     procedure SaveTailItem(Code: integer);
     begin
        Tails.Seek(Code);
        while (not Tails.Blind) and (Tails.Code = Code) do begin
           tail_aux.Code := Tails.Code;
           tail_aux.VarCode := Tails.VarCode;
           tail_aux.Operator := Tails.Operator;
           tail_aux.ValCode := Tails.ValCode;
           tail_aux.Conect := Tails.Conect;
           tail_aux.Neg := Tails.Neg;
           {$IFDEF WINDOWS}
              BlockWrite(TheFile, tail_aux, sizeof(tail_aux));
           {$ELSE}
              with tail_aux do begin
                 BlockWrite(TheFile, Code, sizeof(Code));
                 BlockWrite(TheFile, VarCode, sizeof(VarCode));
                 BlockWrite(TheFile, Operator, sizeof(Operator));
                 BlockWrite(TheFile, ValCode, sizeof(ValCode));
                 BlockWrite(TheFile, Conect, sizeof(Conect));
                 BlockWrite(TheFile, Neg, sizeof(Neg));
              end;
           {$ENDIF}
           Tails.MoveNext;
        end;
     end;

  begin
     total := Tails.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        if Rules.RecordCount > 1 then
           max := 1
        else
           max := Rules.RecordCount - 1;
        Rules.CurrentKey := PRIMARY_KEY;
        for j := 0 to max do begin
           Rules.MoveFirst;
           if j = 0 then
              total := Rules.RecordCount div 2
           else
              total := (Rules.RecordCount div 2) - 1;
           for i := 1 to total do Rules.MoveNext;
           current_node_1 := Rules.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Rules.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.Node;
                 SaveTailItem(node.Code);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.node;
                 SaveTailItem(node.Code);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salvar regras}
  procedure SaveRules;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     node: TNode;
     total: TMyInteger;

     procedure SaveRuleItem(t: TNode);
     begin
        rule_aux.Code := TValNode(t).Code;
        rule_aux.Name := TValNode(t).Name;
        rule_aux.VarCode := TValNode(t).VarCode;
        BlockWrite(TheFile, rule_aux, sizeof(rule_aux));
     end;

  begin
     total := Rules.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     Rules.CurrentKey := PRIMARY_KEY;
     if total <> 0 then begin
        if Rules.RecordCount > 1 then
           max := 1
        else
           max := Rules.RecordCount - 1;
        Rules.CurrentKey := PRIMARY_KEY;
        for j := 0 to max do begin
           Rules.MoveFirst;
           if j = 0 then
              total := Rules.RecordCount div 2
           else
              total := (Rules.RecordCount div 2) - 1;
           for i := 1 to total do Rules.MoveNext;
           current_node_1 := Rules.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Rules.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.node;
                 SaveRuleItem(node);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.node;
                 SaveRuleItem(node);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salvar fórmulas}
  procedure SaveFormulas;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     node: TNode;
     total: TMyInteger;

     procedure SaveFormulasItem(t: TNode);
     begin
        formula_aux.Code := TNamedNode(t).Code;
        formula_aux.Formula := TNamedNode(t).Name;
        BlockWrite(TheFile, formula_aux, sizeof(formula_aux));
     end;

  begin
     total := Formulas.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        Formulas.CurrentKey := PRIMARY_KEY;
        if Formulas.RecordCount > 1 then
           max := 1
        else
           max := Formulas.RecordCount - 1;
        for j := 0 to max do begin
           Formulas.MoveFirst;
           if j = 0 then
              total := Formulas.RecordCount div 2
           else
              total := (Formulas.RecordCount div 2) - 1;
           for i := 1 to total do Formulas.MoveNext;
           current_node_1 := Formulas.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Formulas.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.node;
                 SaveFormulasItem(node);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.node;
                 SaveFormulasItem(node);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salvar perguntas}
  procedure SaveQuestions;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     node: TNode;
     total: TMyInteger;
     total_why: TMyInteger;

     procedure SaveQuestionItem(t: TNode);
     var
        cont_why: integer;
     begin
        ask_aux.Code := TQuestionNode(t).Code;
        ask_aux.question := TQuestionNode(t).question;
        BlockWrite(TheFile, ask_aux, sizeof(ask_aux));
        total_why := TQuestionNode(t).Why.Count;
        BlockWrite(TheFile, total_why, sizeof(total_why));
        for cont_why := 0 to total_why - 1 do begin
            aux_why := TQuestionNode(t).Why[cont_why];
            BlockWrite(TheFile, aux_why, sizeof(aux_why));
        end;
        if version > '1.0' then BlockWrite(TheFile,
                                           TQuestionNode(t).UseCNF,
                                           sizeof(boolean));
     end;

  begin
     total := Questions.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        if Questions.RecordCount > 1 then
           max := 1
        else
           max := Questions.RecordCount - 1;
        for j := 0 to max do begin
           Questions.MoveFirst;
           if j = 0 then
              total := Questions.RecordCount div 2
           else
              total := (Questions.RecordCount div 2) - 1;
           for i := 1 to total do Questions.MoveNext;
           current_node_1 := Questions.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := Questions.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.node;
                 SaveQuestionItem(node);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.node;
                 SaveQuestionItem(node);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salvar objetivos}
  procedure SaveTargets;
  var
     aux, i, total: TMyInteger;
  begin
     total := Targets.Count;
     BlockWrite(TheFile, total, sizeof(total));
     if version = '1.0' then
        for i := 0 to total - 1 do begin
           aux :=Targets.Nodes[i].Code;
           BlockWrite(TheFile, aux, sizeof(aux));
        end
     else
        for i := 0 to total - 1 do begin
           targ_aux.Code := Targets.Nodes[i].Code;
           targ_aux.ShowResults := Targets.Nodes[i].ShowResults;
           BlockWrite(TheFile, targ_aux, sizeof(targ_aux));
        end;
  end;

  {Salvar contextos de ajuda}
  procedure SaveContexts;
  var
     i, j, max: integer;
     current_node_1, current_node_2: TMetaNode;
     node: TNode;
     total: TMyInteger;

     procedure SaveContextItem(t: TNode);
     begin
        context_aux.Code := TContextNode(t).Code;
        context_aux.Context := TContextNode(t).Context;
        BlockWrite(TheFile, context_aux, sizeof(context_aux));
     end;

  begin
     total := HelpContexts.RecordCount;
     BlockWrite(TheFile, total, sizeof(total));
     if total <> 0 then begin
        if HelpContexts.RecordCount > 1 then
           max := 1
        else
           max := HelpContexts.RecordCount - 1;
        for j := 0 to max do begin
           HelpContexts.MoveFirst;
           if j = 0 then
              total := HelpContexts.RecordCount div 2
           else
              total := (HelpContexts.RecordCount div 2) - 1;
           for i := 1 to total do HelpContexts.MoveNext;
           current_node_1 := HelpContexts.CurrentNode;
           if current_node_1 <> nil then begin
              current_node_2 := HelpContexts.CurrentNode.Next;
              if current_node_2 <> nil then current_node_2 := current_node_2.Next;
           end
           else
              current_node_2 := nil;
           while (current_node_1 <> nil) or (current_node_2 <> nil) do begin
              if current_node_1 <> nil then begin
                 node := current_node_1.node;
                 SaveContextItem(node);
                 current_node_1 := current_node_1.Previous;
                 if current_node_1 <> nil then current_node_1 := current_node_1.Previous;
              end;
              if current_node_2 <> nil then begin
                 node := current_node_2.node;
                 SaveContextItem(node);
                 current_node_2 := current_node_2.Next;
                 if current_node_2 <> nil then current_node_2 := current_node_2.Next;
              end;
           end;
        end;
     end;
  end;

  {Salva opções gerais}
  procedure SaveGeneralOptions;
  var
     real_MIN_VALUE: real; {Para manter compatibilidade com a
                            versão antiga do Expert SINTA}
  begin
     BlockWrite(TheFile, Priority, sizeof(Priority));
     real_MIN_VALUE := MIN_VALUE;
     BlockWrite(TheFile, real_MIN_VALUE, sizeof(real_MIN_VALUE));
     BlockWrite(TheFile, ExamineAll, sizeof(ExamineAll));
  end;

  procedure SaveProtections;
  var
    size: integer;
  begin
    size := sizeof(Protection.Password) +
            sizeof(Protection.Permission) +
            sizeof(Protection.UsePassword);
    BlockWrite(TheFile, Protection, size);
  end;

begin
   AssignFile(TheFile, FN);
 try
   Rewrite(TheFile, 1);
   SaveHeader;
   SaveProtections;
   SaveInfo;
   SaveVars;
   SaveValues;
   SaveHeads;
   SaveTails;
   SaveRules;
   SaveFormulas;
   SaveQuestions;
   SaveTargets;
   SaveContexts;
   SaveGeneralOptions;
   Close(TheFile);
   Result := true;
 except
   Result := false;
   Close(TheFile);
 end;
end;

{ PRODUCT  :  Delphi                                 NUMBER  :  2803
  VERSION  :  All
       OS  :  Windows
     DATE  :  May 31, 1995
    TITLE  :  How to encrypt a String

  Here is a program that demonstrates routines for encryption and
  decryption of strings. Note: We claim no responsibily for the
  security of these functions.

  DISCLAIMER: You have the right to use this technical information
  subject to the terms of the No-Nonsense License Statement that
  you received with the Borland product to which this information
  pertains.}

{$Q-}
{Devolve uma string desencriptada de acordo com um número passado como
 chave (Key)}
function Decrypt(const S: String; Key: Word): String;
var
  i: byte;
  total: integer;
begin
  Result[0] := S[0];
  total := Length(S);
  for i := 1 to total do begin
    Result[i] := char(byte(S[i]) xor (Key shr 8));
    Key := (byte(S[i]) + Key) * C1 + C2;
  end;
end;

{Devolve uma string encriptada de acordo com um número passado como
 chave (Key)}
function Encrypt(const S: String; Key: Word): String;
var
  i: byte;
  total: integer;
begin
  Result[0] := S[0];
  total := Length(S);
  for i := 1 to total do begin
    Result[i] := char(byte(S[i]) xor (Key shr 8));
    Key := (byte(Result[i]) + Key) * C1 + C2;
  end;
end;
{$Q+}

{======================================================================
 ======================================================================
                         FUNÇÕES DE DEPURAÇÃO
 ======================================================================
 ======================================================================}

procedure TExpertSystem.UpdateDebug(rule: integer; order: integer; is_tail: boolean);
begin
   if (DebugControl <> nil) and CanView then begin
      DebugControl.Update(rule, order, is_tail);
      if Trace then DebugControl.Activate;
   end;
   CurrentTrace.rule := rule;
   CurrentTrace.order := order;
   CurrentTrace.tail := is_tail;
end;

{======================================================================
 ======================================================================
                      RELAÇÕES COM OUTROS COMPONENTES
 ======================================================================
 ======================================================================}

{Construtor da classe TExCtrlInterface}
constructor TExCtrlInterface.Create(AKind: byte; AOwnerControl: TObject);
begin
   Kind := AKind;
   OwnerControl := AOwnerControl;
end;

procedure TExpertSystem.AddControl(control: TExCtrlInterface);
var
   List: TList;
begin
   case control.Kind of
      I_INSTANCE_VIEW: List := InstanceViewControls;
      I_VARIABLE_VIEW: List := VariableViewControls;
      I_KB_VIEW:       List := KBViewControls;
      I_STATUS_VIEW:   List := StatusViewControls;
      else raise EExpertSystem.Create('Uso indevido do métod AddControl!');
   end;
   if List.IndexOf(control) = -1 then List.Add(control);
end;

procedure TExpertSystem.RemoveControl(control: TExCtrlInterface);
var
   List: TList;
   i: integer;
begin
   case control.Kind of
      I_INSTANCE_VIEW: List := InstanceViewControls;
      I_VARIABLE_VIEW: List := VariableViewControls;
      I_KB_VIEW:       List := KBViewControls;
      I_STATUS_VIEW:   List := StatusViewControls;
      else raise EExpertSystem.Create('Uso indevido do métod AddControl!');
   end;
   i := List.IndexOf(control);
   if i <> -1 then List.Delete(i);
end;

procedure TExpertSystem.NotifyControls(ListControls: TList);
var
   i, total: integer;
begin
   total := ListControls.Count - 1;
   if FEmptyBase then
      for i := 0 to total do
          TExCtrlInterface(ListControls[i]).Clear
   else
      for i := 0 to total do
          TExCtrlInterface(ListControls[i]).RefreshLink(Self);
end;

procedure TExpertSystem.NotifyControls2(ListControls: TList);
var
   i, total: integer;
begin
   total := ListControls.Count - 1;
   for i := 0 to total do
       TExCtrlInterface(ListControls[i]).RefreshLink(nil);
end;

procedure TExpertSystem.NotifyControlsWithPermission(ListControls: TList);
var
   i, total: integer;
begin
   total := ListControls.Count - 1;
   if FEmptyBase or (not CanView) then
      for i := 0 to total do
          TExCtrlInterface(ListControls[i]).Clear
   else
      for i := 0 to total do
          TExCtrlInterface(ListControls[i]).RefreshLink(Self);
end;

{======================================================================
 ======================================================================
                       REGISTRO DE COMPONENTES
 ======================================================================
 ======================================================================}

procedure Register;
begin
   RegisterComponents('Expert SINTA', [TExpertSystem]);
   RegisterComponents('Expert SINTA', [TRuleView]);
   RegisterComponents('Expert SINTA', [TExpertPrompt]);
   RegisterComponents('Expert SINTA', [TLabelQuestion]);
   RegisterComponents('Expert SINTA', [TWhyDialog]);
   RegisterComponents('Expert SINTA', [TDebugPanel]);
   RegisterComponents('Expert SINTA', [TWatchPanel]);
   RegisterComponents('Expert SINTA', [TValuesGrid]);
   RegisterComponents('Expert SINTA', [TConsultTree]);
   RegisterComponents('Expert SINTA', [TAllVars]);
   RegisterComponents('Expert SINTA', [TExNavigator]);
end;

end.
