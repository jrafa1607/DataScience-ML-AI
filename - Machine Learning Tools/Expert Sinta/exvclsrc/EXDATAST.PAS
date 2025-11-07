{=======================================================
 * Expert SINTA Visual Component Library *

 Module name: ExDataSt.pas
 Abstract:
    Unidade de definição das estruturas de dados
    (árvores, pilhas e listas) as quais armazenam toda a
    informação da base de conhecimentos.
 Implementação: Ricardo Bezerra
 Data de início: 12 de outubro de 1996
 Data de término: 12 de outubro de 1996
 Última modificação: 08 de outubro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 =======================================================}

{======================================================================
 Observações sobre a implementação:
   - No Delphi, TODO objeto é um ponteiro, razão pela qual expressões
     como 'objeto1' := 'objeto2' são válidas, bem como a comparação
     'objeto1' = 'objeto2', pois se tratam de ponteiros;
   - As árvores são árvores binárias simples. Os "índices" são apenas
     ponteiros para nós reais (que armazenam as informações), não
     havendo, portanto, informações duplicadas. Optou-se por um pequeno
     acréscimo de gasto de memória (os tais "índices") em melhoria da
     velocidade (não há buscas sequenciais, apenas na árvore)
 ======================================================================}

unit ExDataSt;

interface

uses
   Classes, SysUtils;

const
   LEFT = 0;
   RIGHT = 1;
   NONE = 2;

   BOF_MESSAGE = 'Houve a tentativa de movimento além do início da árvore!';
   EOF_MESSAGE = 'Houve a tentativa de movimento além do fim da árvore!';
   DELETION_ERROR_MESSAGE = 'Houve a tentativa de deleção com ponteiro perdido!';
   READING_ERROR_MESSAGE = 'Houve a tentativa de leitura com ponteiro perdido! ';
   WRITING_ERROR_MESSAGE = 'Houve a tentativa de mudança de valor de propriedade com ponteiro perdido! ';
   ALLOC_VAR_ERROR_MESSAGE = 'Houve um erro de alocação de memória para variáveis! ';
   ALLOC_TAIL_ERROR_MESSAGE = 'Houve um erro de alocação de memória para caudas!';
   ALLOC_QUESTION_ERROR_MESSAGE = 'Houve um erro de alocação de memória para perguntas!';
   ALLOC_CONTEXT_ERROR_MESSAGE = 'Houve um erro de alocação de memória para contextos de ajuda!';
   ALLOC_VAR_LIST_ERROR_MESSAGE = 'Houve um erro de alocação de memória para lista de variáveis instanciadas!';
   PROP_STRING = 'Propriedade: ';
   CODE_PROP = '"código"';
   NAME_PROP = '"nome"';
   CODE_VAR_PROP = '"código da variável"';
   CODE_VALUE_PROP = '"código do valor"';
   VALUE_POS_PROP = '"posição do valor"';
   MULTIVALUED_PROP = '"multivalorada"';
   NUMERIC_PROP = '"numérica"';
   OPERATOR_PROP = '"propriedade"';
   CONECT_PROP = '"conectivo"';
   NEG_PROP = '"negação"';
   CNF_PROP = '"CNF"';
   QUESTION_PROP = '"pergunta"';
   WHY_PROP = '"motivo"';
   USE_CNF_PROP = '"usar CNF"';
   CONTEXT_PROP = '"contexto de ajuda"';
   VALUE_PROP = '"valor"';
   EMPTY_STACK_ERROR_MESSAGE = 'Pilha vazia!';
   EMPTY_QUEUE_ERROR_MESSAGE = 'Não existem elementos na fila!';
   LIST_INDEX_OUT_OF_BOUNDS_ERROR_MESSAGE = 'Índice de lista inválido!';

type
   {************** Árvores *************}
   TIndex = class;

   TNode = class
   public
      Code: integer;
   end;

   TNamedNode = class(TNode)
   public
      Name: string;
   end;

   TVarNode = class(TNamedNode)
   public
      Multi: boolean;
      Numeric: boolean;
   end;

   TValNode = class(TNamedNode)
   public
      VarCode: integer;
      Position: integer;
   end;

   TTailNode = class(TNode)
   public
      VarCode: integer;
      Operator: string[2];
      ValCode: integer; {Não apenas valores, mas também fórmulas}
      Conect: integer;
      Neg: boolean;
   end;

   THeadNode = class(TNode)
   public
      VarCode: integer;
      ValCode: integer; {Idem à classe anterior}
      CNF: single;
   end;

   TQuestionNode = class(TNode)
   public
      Question: string;
      Why: TStringList;
      UseCNF: boolean;
      constructor Create;
      destructor  Destroy; override;
   end;

   TContextNode = class(TNode)
   public
      Context: integer;
   end;

   TVarListNode = class(TNode)
   public
      ValCode: integer;
      CNF: single;
   end;

   TVarListExtraNode = class(TNode)
   public
      Value: string;
      CNF: single;
   end;

   TMetaNode = class
   public
      {O nó propriamente dito}
      Node: TNode;
      {Links para outros nós na árvore binária de nós}
      LeftChild: TMetaNode;
      RightChild: TMetaNode;
      {Links para outros nós na lista seqüencial de nós}
      Previous: TMetaNode;
      Next: TMetaNode;
      constructor Create;
   end;

   TSingleIndexTree = class
   private
      root: TMetaNode;
      last_insert: TNode; {último nó "single" inserido}
      to_be_deleted: TNode; {nó marcado para morrer}
      list_index: TIndex;
      indexes: TList;
      procedure CreateNewNode; virtual;
      procedure DestroyMetaNode(m: TMetaNode);
      procedure FreeNode(t: TNode); virtual;
      procedure DeleteCode(key: integer); virtual;
      procedure InsertInIndex(new_one, reference: TMetaNode);
      procedure DeleteInIndex(to_kill: TMetaNode; ind: integer); virtual;
      function  GetCode: integer; virtual;
   public
      CurrentKey: integer;
      RecordCount: integer;
      CurrentNode: TMetaNode;
      constructor Create;
      destructor  Destroy; override;
      function    Blind: boolean; virtual;
      procedure   Insert(c: integer); virtual;
      procedure   Seek(key: integer); virtual;
      procedure   Delete; virtual;
      procedure   MoveFirst; virtual;
      procedure   MoveLast; virtual;
      procedure   MovePrevious; virtual;
      procedure   MoveNext; virtual;
      function    GetFreeCode: integer;
      property    Code: integer read GetCode;
   end;

   TCodeNameIndexTree = class(TSingleIndexTree)
   private
      root_name: TMetaNode;
      list_index_name: TIndex;
      procedure CreateNewNode; override;
      procedure FreeNode(t: TNode); override;
      procedure DestroyOnlyMetaNode(var m: TMetaNode);
      function  GetCode: integer; override;
      function  GetName: string; virtual;
      procedure SetName(name: string); virtual;
      procedure DeleteCodeName(key: string);
      procedure InsertInNamedIndex(new_one, reference: TMetaNode);
   public
      CurrentNodeName: TMetaNode;
      constructor Create;
      destructor  Destroy; override;
      function    Blind: boolean; override;
      procedure   MoveFirst; override;
      procedure   MoveNext; override;
      procedure   MovePrevious; override;
      procedure   MoveLast; override;
      procedure   Delete; override;
      procedure   Insert(c: integer; name: string);
      procedure   Seek(key: integer); override;
      procedure   SeekByName(name: string); virtual;
      property    Name: string read GetName write SetName;
   end;

   TVars = class(TCodeNameIndexTree)
   private
      procedure CreateNewNode; override;
      function  GetMulti: boolean;
      procedure SetMulti(multi: boolean);
      function  GetNum: boolean;
      procedure SetName(name: string); override;
      procedure SetNum(numeric: boolean);
      procedure FreeNode(t: TNode); override;
   public
      procedure Insert(c: integer; n: string; num: boolean; multi: boolean);
      property  Multi: boolean read GetMulti write SetMulti;
      property  Numeric: boolean read GetNum write SetNum;
   end;

   TValues = class(TCodeNameIndexTree)
   private
      root_var: TMetaNode;
      list_index_var: TIndex;
      procedure CreateNewNode; override;
      function  GetCode: integer; override;
      function  GetName: string; override;
      procedure SetName(name: string); override;
      procedure FreeNode(t: TNode); override;
      function  GetCodeVar: integer;
      function  GetPosition: integer;
      procedure SetPosition(p: integer);
      procedure DeleteCodeName(p_key: integer; key: string);
      procedure DeleteCodeVar(p_key: integer; key: integer);
      procedure InsertInValIndex(new_one, reference: TMetaNode);
   public
      CurrentNodeVar: TMetaNode;
      constructor Create;
      destructor  Destroy; override;
      function    Blind: boolean;
      procedure   Insert(c: integer; name: string; c_var: integer; position: integer);
      procedure   SeekByName(name: string; v: integer);
      procedure   SeekByVar(c_var: integer);
      procedure   Delete; override;
      procedure   MoveFirst; override;
      procedure   MoveNext; override;
      procedure   MovePrevious; override;
      procedure   MoveLast; override;
      property    VarCode: integer read GetCodeVar;
      property    Position: integer read GetPosition write SetPosition;
   end;

   TRules = class(TValues)
    {Observe que essa classe diferecia-se unicamente de TValues pelo "alias"
     'Position'}
   public
      property  Position: integer read GetCodeVar;
   end;

   TTails = class(TSingleIndexTree)
   private
      procedure CreateNewNode; override;
      function  GetVar: integer;
      function  GetValue: integer;
      function  GetOperator: string;
      function  GetConect: integer;
      function  GetNeg: boolean;
      procedure FreeNode(t: TNode); override;
   public
      procedure Insert(c: integer; c_var: integer; op: string;
                c_val: integer; conec: integer; neg: boolean);
      property  VarCode: integer read GetVar;
      property  ValCode: integer read GetValue;
      property  Operator: string read GetOperator;
      property  Conect: integer read GetConect;
      property  Neg: boolean read GetNeg;
   end;

   THeads = class(TSingleIndexTree)
   private
      procedure CreateNewNode; override;
      function  GetVar: integer;
      function  GetValue: integer;
      function  GetCNF: single;
      procedure FreeNode(t: TNode); override;
   public
      procedure Insert(c: integer; c_var: integer; c_val: integer;
                cnf: single); virtual;
      property  VarCode: integer read GetVar;
      property  ValCode: integer read GetValue;
      property  CNF: single read GetCNF;
   end;

   TQuestions = class(TSingleIndexTree)
   private
       procedure CreateNewNode; override;
       procedure FreeNode(t: TNode); override;
       function  GetQuestion: string;
       procedure SetQuestion(q: string);
       function  GetWhy: TStringList;
       procedure SetWhy(w: TStringList);
       function  GetUseCNF: boolean;
       procedure SetUseCNF(uc: boolean);
   public
       procedure Insert(c: integer; q: string; w: TStringList; uc: boolean);
       property  Question: string read GetQuestion write SetQuestion;
       property  Why: TStringList read GetWhy write SetWhy;
       property  UseCNF: boolean read GetUseCNF write SetUseCNF;
   end;

   THelpContexts = class(TSingleIndexTree)
   private
       procedure CreateNewNode; override;
       procedure FreeNode(t: TNode); override;
       function  GetContext: integer;
       procedure SetContext(c: integer);
   public
       procedure Insert(c: integer; con: integer);
       property  Context: integer read GetContext write SetContext;
   end;

   TTargetNode = class
   public
      Code: integer;
      ShowResults: boolean;
      constructor Create;
   end;

   TTargets = class(TList)
   private
      function GetNode(Index: integer): TTargetNode;
   public
      procedure  ClearObjects;
      destructor Destroy; override;
      property   Nodes[Index: integer]: TTargetNode read GetNode;
   end;

   TFormulas = class(TCodeNameIndexTree);

   TVarListTree = class(TSingleIndexTree)
   private
       procedure CreateNewNode; override;
       procedure FreeNode(t: TNode); override;
       function  GetCodeValue: integer;
       procedure SetCodeValue(c: integer);
       function  GetCNF: single;
       procedure SetCNF(c: single);
       procedure DeleteCode(key: integer; cod_value: integer);
   public
       procedure Insert(c: integer; v: integer; cnf: single);
       procedure Delete; override;
       property  ValCode: integer read GetCodeValue write SetCodeValue;
       property  CNF: single read GetCNF write SetCNF;
   end;

   TVarListExtraTree = class(TSingleIndexTree)
   private
       procedure CreateNewNode; override;
       procedure FreeNode(t: TNode); override;
       function  GetValue: string;
       procedure SetValue(c: string);
       function  GetCNF: single;
       procedure SetCNF(c: single);
       procedure DeleteCode(key: integer; value: string);
   public
       procedure Insert(c: integer; v: string; cnf: single);
       procedure Delete; override;
       property  Value: string read GetValue write SetValue;
       property  CNF: single read GetCNF write SetCNF;
   end;

   TTreeofTreesNode = class(TNode)
      tree: TSingleIndexTree;
   end;

   TTreeOfTrees = class(TSingleIndexTree)
    private
      procedure CreateNewNode; override;
      function  GetTree: TSingleIndexTree;
      procedure SetTree(tree: TSingleIndexTree);
      procedure FreeNode(t: TNode); override;
    public
      procedure  Insert(c: integer; t: TSingleIndexTree);
      property   tree: TSingleIndexTree read GetTree write SetTree;
   end;

   {Índices sequenciais, para percorrer nós em seqüência}
   TIndex = class
   public
      First, Last: TMetaNode;
   end;

   {************** Pilhas *************}
   TIntegerNode = class
   public
      Code: integer;
   end;

   TObjectNode = class
   public
      Obj: TObject;
   end;

   TStackMetaNode = class
   public
      Node: TObject;
      Previous: TStackMetaNode;
   end;

   TStack = class
   private
       start_Node, top_Node: TStackMetaNode;
       function  CreateNewNode: TStackMetaNode;
       procedure DestroyNode(t: TStackMetaNode);
   public
       RecordCount: integer;
       constructor Create;
       destructor  Destroy; override;
       function    Pop: TObject;
       function    Top: TObject;
       procedure   Push(c: TObject);
       function    Blind: boolean;
   end;

   TIntegerStack = class(TStack)
   private
       function  CreateNewNode: TStackMetaNode;
       procedure DestroyNode(t: TStackMetaNode);
   public
       function  Pop: integer;
       function  Top: integer;
       procedure Push(c: integer);
   end;

   {Classe especial de pilha que aproveita a classe TStringList}
   TStringStack = class
   private
       function  GetRecordCount: integer;
   public
       Items: TStringList;
       constructor Create;
       destructor  Destroy; override;
       function    Pop: string;
       function    Top: string;
       procedure   Push(v: string);
       property    RecordCount: integer read GetRecordCount;
   end;

   {************** Filas *************}
   TQueueMetaNode = class(TNode)
   public
      Node: TNode;
      Next: TQueueMetaNode;
      constructor Create;
      destructor  Destroy;
   end;

   TQueue = class
   private
      function GetCode: integer;
   public
      Front: TQueueMetaNode;
      Rear: TQueueMetaNode;
      Error: boolean;
      RecordCount: integer;
      constructor Create;
      destructor  Destroy; override;
      function    Blind: boolean;
      procedure   Insert(element: integer);
      procedure   Delete;
      procedure   RebuildRear;
      property    Code: integer read GetCode;
   end;

   {************** Listas *************}
   TListMetaNode = class
   public
      PObject: TObject;
      {O Delphi inicializa automaticamente ponteiros para nil}
      Previous: TListMetaNode;
      Next: TListMetaNode;
   end;

   {Classe de lista de objetos. Não é ordenada por nada. Utilizada
    no lugar de TStringList para poupar recursos e otimizar}
   TObjectList = class
   private
      FAutoFree: boolean;
      FCount: integer;
      first, last: TListMetaNode;
      procedure DeleteThisMetaNode(m: TListMetaNode);
      procedure SetItemPointer(index: integer; ob: TObject);
      function  GetItemPointer(index: integer): TObject;
   public
      property   AutoFree: boolean read FAutoFree write FAutoFree default True;
      property   Count: integer read FCount default 0;
      property   Items[Index: integer]: TObject read GetItemPointer write SetItemPointer;
      procedure  Append(item: TObject);
      procedure  Delete(index: integer);
      destructor Destroy;
   end;

   TInstance = class
   public
      VarCode: integer;
      Val: string;
      CNF: single;
      IsACode: boolean;
   end;

   {Essa lista guarda TODAS as intâncias de todas as variáveis durante
    TODA a consulta. Necessário para recompor o valor antigo de uma
    variável se o usuário quiser voltar a uma pergunta anterior.}
   TInstanceList = class(TObjectList)
   public
      procedure AppendInstance(var_c: integer; val_c: string; cnf: single;
                is_a_code: boolean);
      procedure DeleteAllInstances(var_c: integer);
      procedure RebuildInstance(var_c: integer; X: TObject);
   end;

   {Exceção de uso geral para a Expert SINTA VCL}
   EExpertSystem = class(Exception);
   
implementation

uses
   Dialogs, ExSystem, ExConsts;

{======================================================================
 ======================================================================
                                 ÁRVORES
 ======================================================================
 ======================================================================}

{======================
 C L A S S E TMetaNode
 ======================}
{Métodos de criação e destruição do objeto}
constructor TMetaNode.Create;
begin
   inherited Create;
   Node := nil;
   LeftChild := nil;
   RightChild := nil;
   Previous := nil;
   Next := nil;
end;

{============================
 C L A S S E TSingleIndexTree
 ============================}
{Métodos de criação e destruição da árvore}
constructor TSingleIndexTree.Create;
begin
   inherited Create;
   RecordCount := 0;
   list_index := TIndex.Create;
   indexes := TList.Create;
   indexes.Add(list_index);
end;

procedure TSingleIndexTree.CreateNewNode;
begin
   last_insert := TNode.Create;
end;

destructor TSingleIndexTree.Destroy;
begin
   DestroyMetaNode(TIndex(indexes[0]).First);
   list_index.Free;
   indexes.Free;
   inherited Destroy;
end;

procedure TSingleIndexTree.DestroyMetaNode(m: TMetaNode);
var
   Next: TMetaNode;
begin
   while m <> nil do begin
      Next := m.Next;
      FreeNode(m.Node);
      m.Free;
      m := Next;
   end;
end;

procedure TSingleIndexTree.FreeNode(t: TNode);
begin
   t.Free;
end;

{Métodos de movimentação na árvore}
procedure TSingleIndexTree.MoveFirst;
begin
   CurrentNode := TIndex(indexes[PRIMARY_INDEX]).First;
end;

procedure TSingleIndexTree.MovePrevious;
begin
   if CurrentNode <> nil then
      CurrentNode := CurrentNode.Previous
   else
      MessageDlg(BOF_MESSAGE, mtWarning, [mbOk], 0);
end;

procedure TSingleIndexTree.MoveNext;
begin
   if CurrentNode <> nil then
      CurrentNode := CurrentNode.Next
   else
      MessageDlg(EOF_MESSAGE, mtWarning, [mbOk], 0);
end;

procedure TSingleIndexTree.MoveLast;
begin
   CurrentNode := TIndex(indexes[PRIMARY_INDEX]).Last;
end;

procedure TSingleIndexTree.Seek(key: integer);
begin
   CurrentNode := root;
   while (CurrentNode <> nil) and (CurrentNode.Node.Code <> key) do begin
      if key < CurrentNode.Node.Code then
         CurrentNode := CurrentNode.LeftChild
      else
         CurrentNode := CurrentNode.RightChild
   end;
end;

function TSingleIndexTree.Blind : boolean;
begin
   Result := (CurrentNode = nil);
end;

{Métodos de inserção de novos elementos}
procedure TSingleIndexTree.Insert(c: integer);
var
  the_left_child, p, q: TMetaNode;
begin
  the_left_child := nil;
  q := nil;
  p := root;
  while p <> nil do begin
     q := p;
     if c = p.Node.Code then begin
        while (p.LeftChild <> nil) and (p.LeftChild.Node.Code = c) do
               p := p.LeftChild;
        q := p;
        the_left_child := p.LeftChild;
        p := nil;
     end
     else begin
        if c <= p.Node.Code then
           p := p.LeftChild
        else
           p := p.RightChild;
     end;
  end;
  CreateNewNode;
  p := TMetaNode.Create;
  p.Node := last_insert;
  CurrentNode := p;
  CurrentNode.Node.Code := c;
  p.LeftChild := the_left_child;
  InsertInIndex(p, q);
  if q = nil then
     root := p
  else begin
     if c <= q.Node.Code then
        q.LeftChild := p
     else
        q.RightChild := p;
  end;
  RecordCount := RecordCount + 1;
end;

procedure TSingleIndexTree.InsertInIndex(new_one, reference: TMetaNode);
var
   old_code: integer;
begin
   if reference <> nil then begin
      old_code := reference.Node.Code;
      {Não praticamente nenhuma perda de velocidade, pois "reference" aponta
       para o nó imediatamente anterior a "new_one" na árvore}
       if (reference.Node.Code > new_one.Node.Code) then begin
          {Se já existirem nós com a mesma chave (por exemplo, cabeças e caudas
           de regra), recua até o primeiro com aquela chave}
          while (reference.Previous <> nil) and
                (reference.Previous.Node.Code = old_code) do
                reference := reference.Previous;
          new_one.Previous := reference.Previous;
          new_one.Next := reference;
          if reference.Previous <> nil then
             (reference.Previous).Next := new_one
          else
             TIndex(indexes[PRIMARY_INDEX]).First := new_one;
          reference.Previous := new_one;
       end
       else begin
         {Se já existirem nós com a mesma chave (por exemplo, cabeças e caudas
          de regra), grava o novo nó como sendo o último}
         while (reference.Next <> nil) and
               (reference.Next.Node.Code = old_code) do
               reference := reference.Next;
         new_one.Previous := reference;
         new_one.Next := reference.Next;
         if reference.Next <> nil then
            (reference.Next).Previous := new_one
         else
            TIndex(indexes[PRIMARY_INDEX]).Last := new_one;
         reference.Next := new_one;
      end
   end
   else begin
      {new_one será o único elemento da lista}
      TIndex(indexes[PRIMARY_INDEX]).First := new_one;
      TIndex(indexes[PRIMARY_INDEX]).Last := new_one;
   end;
end;

{Métodos de deleção de elementos}
procedure TSingleIndexTree.Delete;
var
  aux: TMetaNode;
begin
   to_be_deleted := nil;
   if CurrentNode <> nil then begin
      aux := CurrentNode.Next;
      DeleteCode(CurrentNode.Node.Code);
      CurrentNode := aux;
      RecordCount := RecordCount - 1;
   end
   else
      MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
   FreeNode(to_be_deleted);
end;

procedure TSingleIndexTree.DeleteCode(key: integer);
var
   the_one, previous: TMetaNode;
   direction: integer;
   change_the_root: boolean;

   procedure SeekTheOne;
   begin
      previous := root;
      the_one := root;
      direction := NONE;
      while (the_one <> nil) and (the_one.node.Code <> key) do begin
         previous := the_one;
         if key < the_one.Node.Code then begin
            the_one := the_one.LeftChild;
            direction := LEFT;
         end
         else begin
            the_one := the_one.RightChild;
            direction := RIGHT;
         end;
      end;
   end;

   function PerformeDeletion: TMetaNode;
   var
      aux1, aux2: TMetaNode;
   begin
     with the_one do begin
        if (LeftChild = nil) and (RightChild = nil) then begin
            to_be_deleted := the_one.Node;
            the_one.Free;
            Result := nil;
         end
         else begin
            if LeftChild = nil then begin
               aux1 := RightChild;
               to_be_deleted := the_one.Node;
               the_one.Free;
               Result := aux1;
            end
            else begin
               if RightChild = nil then begin
                  aux1 := LeftChild;
                  to_be_deleted := the_one.Node;
                  the_one.Free;
                  Result := aux1;
               end
               else begin
                  aux1 := RightChild;
                  aux2 := RightChild;
                  while aux1.LeftChild <> nil do aux1 := aux1.LeftChild;
                  aux1.LeftChild := LeftChild;
                  to_be_deleted := the_one.Node;
                  the_one.Free;
                  Result := aux2;
               end;
            end;
         end;
      end;
   end;

begin
  SeekTheOne;
  if the_one <> nil then begin
     DeleteInIndex(the_one, PRIMARY_KEY);
     if previous = root then
        change_the_root := true
     else
        change_the_root := false;
     case direction of
       NONE:  Previous := PerformeDeletion;
       LEFT:  Previous.LeftChild := PerformeDeletion;
       RIGHT: Previous.RightChild := PerformeDeletion;
     end;
     if change_the_root then root := Previous;
  end;
end;

procedure TSingleIndexTree.DeleteInIndex(to_kill: TMetaNode; ind: integer);
begin
   if (to_kill.Previous <> nil) then to_kill.Previous.Next := to_kill.Next;
   if (to_kill.Next <> nil) then to_kill.Next.Previous := to_kill.Previous;
   if to_kill = TIndex(indexes[ind]).Last then
      TIndex(indexes[ind]).Last := to_kill.Previous;
   if to_kill = TIndex(indexes[ind]).First then
      TIndex(indexes[ind]).First := to_kill.Next;
end;

{Métodos de extração de propriedades}
function TSingleIndexTree.GetCode: integer;
begin
   if CurrentNode <> nil then
      Result := CurrentNode.Node.Code
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

{Retorna um código que pode ser utilizado como novo}
function TSingleIndexTree.GetFreeCode: integer;
var
   i, old_key: integer;
   old_node: TMetaNode;
begin
   old_node := CurrentNode;
   old_key := CurrentKey;
   i := 1;
   repeat
     Seek(i);
     inc(i);
   until Blind;
   CurrentNode := old_node;
   CurrentKey := old_key; 
   Result := i - 1;
end;

{==============================
 C L A S S E TCodeNameIndexTree
 ==============================}
{Métodos de criação e destruição da árvore}
constructor TCodeNameIndexTree.Create;
begin
   inherited Create;
   CurrentKey := PRIMARY_KEY;
   list_index_name := TIndex.Create;
   indexes.Add(list_index_name);
end;

procedure TCodeNameIndexTree.FreeNode(t: TNode);
begin
   TNamedNode(t).Free;
end;

procedure TCodeNameIndexTree.CreateNewNode;
begin
   last_insert := TNamedNode.Create;
end;

destructor TCodeNameIndexTree.Destroy;
begin
   DestroyOnlyMetaNode(TIndex(indexes[1]).First);
   list_index_name.Free;
   inherited Destroy;
end;

procedure TCodeNameIndexTree.DestroyOnlyMetaNode(var m: TMetaNode);
begin
   if m <> nil then begin
      DestroyOnlyMetaNode(m.LeftChild);
      DestroyOnlyMetaNode(m.RightChild);
      m.Free;
   end;
end;

{Métodos de movimentação}
procedure TCodeNameIndexTree.MoveFirst;
begin
   if CurrentKey = PRIMARY_KEY then
      inherited MoveFirst
   else
      CurrentNodeName := TIndex(indexes[NAME_INDEX]).First;
end;

procedure TCodeNameIndexTree.MovePrevious;
begin
   if CurrentKey <> BY_NAME then
      inherited MovePrevious
   else begin
      if CurrentNodeName <> nil then
         CurrentNodeName := CurrentNodeName.Previous
      else
         MessageDlg(BOF_MESSAGE, mtWarning, [mbOk], 0);
   end;
end;

procedure TCodeNameIndexTree.MoveNext;
begin
   if CurrentKey <> BY_NAME then
      inherited MoveNext
   else begin
      if CurrentNodeName <> nil then
         CurrentNodeName := CurrentNodeName.Next
      else
         MessageDlg(EOF_MESSAGE, mtWarning, [mbOk], 0);
   end;
end;

procedure TCodeNameIndexTree.MoveLast;
begin
   if CurrentKey <> BY_NAME then
      inherited MoveLast
   else
      CurrentNodeName := TIndex(indexes[NAME_INDEX]).Last;
end;

procedure TCodeNameIndexTree.Seek(key: integer);
begin
   inherited Seek(key);
   CurrentKey := PRIMARY_KEY
end;

procedure TCodeNameIndexTree.SeekByName(name: string);
begin
   Name := AnsiUpperCase(Name);
   CurrentNodeName := root_name;
   while (CurrentNodeName <> nil)
   and (AnsiUpperCase(TNamedNode(CurrentNodeName.Node).Name) <> Name)
   do begin
      if Name < AnsiUpperCase(TNamedNode(CurrentNodeName.Node).Name) then
         CurrentNodeName := CurrentNodeName.LeftChild
      else
         CurrentNodeName := CurrentNodeName.RightChild
   end;
   CurrentKey := BY_NAME;
end;

function TCodeNameIndexTree.Blind: boolean;
begin
   if CurrentKey = PRIMARY_KEY then
      Result := inherited Blind
   else
      Result := (CurrentNodeName = nil);
end;

{Método de inserção}
procedure TCodeNameIndexTree.Insert(c: integer; name: string);
var
  the_left_child, p, q: TMetaNode;
begin
  inherited Insert(c);
  the_left_child := nil;
  q := nil;
  p := root_name;
  while p <> nil do begin
     q := p;
     if AnsiUpperCase(name) = AnsiUpperCase(TNamedNode(p.Node).Name) then begin
        while (p.LeftChild <> nil) and
              (AnsiUpperCase(name) = AnsiUpperCase(TNamedNode(p.LeftChild.Node).Name))
              do p := p.LeftChild;
        q := p;
        the_left_child := p.LeftChild;
        p := nil;
     end
     else begin
        if AnsiUpperCase(name) < AnsiUpperCase(TNamedNode(p.Node).Name) then
           p := p.LeftChild
        else
           p := p.RightChild;
     end;
  end;
  p := TMetaNode.Create;
  p.Node := last_insert;
  p.LeftChild := the_left_child;
  CurrentNodeName := p;
  TNamedNode(CurrentNodeName.Node).Name := name;
  InsertInNamedIndex(p, q);
  if q = nil then
     root_name := p
  else begin
     if AnsiUpperCase(name) <= AnsiUpperCase(TNamedNode(q.Node).Name) then
        q.LeftChild := p
     else
        q.RightChild := p;
  end;
end;

procedure TCodeNameIndexTree.InsertInNamedIndex(new_one, reference: TMetaNode);
var
   old_name: string;
begin
   if reference <> nil then begin
      old_name := TNamedNode(reference.Node).Name;
      {Não praticamente nenhuma perda de velocidade, pois "reference" aponta
       para o nó imediatamente anterior a "new_one" na árvore}
       if (TNamedNode(reference.Node).Name > TNamedNode(new_one.Node).Name) then begin
          {Se já existirem nós com a mesma chave (por exemplo, cabeças e caudas
           de regra), recua até o primeiro com aquela chave}
          while (reference.Previous <> nil) and
                (TNamedNode(reference.Previous.Node).Name = old_name) do
                reference := reference.Previous;
          new_one.Previous := reference.Previous;
          new_one.Next := reference;
          if reference.Previous <> nil then
             (reference.Previous).Next := new_one
          else
             TIndex(indexes[NAME_INDEX]).First := new_one;
          reference.Previous := new_one;
       end
       else begin
         {Se já existirem nós com a mesma chave (por exemplo, cabeças e caudas
          de regra), grava o novo nó como sendo o último}
         while (reference.Next <> nil) and
               (TNamedNode(reference.Next.Node).Name = old_name) do
               reference := reference.Next;
         new_one.Previous := reference;
         new_one.Next := reference.Next;
         if reference.Next <> nil then
            (reference.Next).Previous := new_one
         else
            TIndex(indexes[NAME_INDEX]).Last := new_one;
         reference.Next := new_one;
      end
   end
   else begin
      {new_one será o único elemento da lista}
      TIndex(indexes[NAME_INDEX]).First := new_one;
      TIndex(indexes[NAME_INDEX]).Last := new_one;
   end;
end;

{Métodos de deleção}
procedure TCodeNameIndexTree.Delete;
var
  aux: TMetaNode;
  code_aux: integer;
  name_aux: string;
begin
   to_be_deleted := nil;
   case CurrentKey of
      PRIMARY_KEY:
       begin
        if CurrentNode <> nil then begin
           aux := CurrentNode.Next;
           {É preciso guardar o código e o nome do nó atual, pois
            embora no Delphi 1.0 não haja problema de usarmos como
            parâmetro nos dois procedimentos que se seguem (ele conserva
            o ponteiro), em 32 bits o valor de CurrentNode muda quando
            deletamos a região de memória para onde ele aponta. Por isso,
            não podemos passar CurrentNode.Node.Name como parâmetro para
            o procedimento DeleteCodeName, como estávamos fazendo na
            versão 16 bits do Expert SINTA (nota por Ricardo Bezerra)}
           code_aux := CurrentNode.Node.Code;
           name_aux := TNamedNode(CurrentNode.Node).Name;
           DeleteCode(code_aux);
           DeleteCodeName(name_aux);
           RecordCount := RecordCount - 1;
           CurrentNode := aux;
        end
        else
           MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
       end;
      BY_NAME:
       begin
        if CurrentNodeName <> nil then begin
           aux := CurrentNodeName.Next;
           code_aux := CurrentNodeName.Node.Code;
           name_aux := TNamedNode(CurrentNodeName.Node).Name;
           DeleteCode(code_aux);
           DeleteCodeName(name_aux);
           RecordCount := RecordCount - 1;
           CurrentNodeName := aux;
        end
        else
           MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
       end;
   end;
   FreeNode(to_be_deleted);
end;

procedure TCodeNameIndexTree.DeleteCodeName(key: string);
var
   the_one, Previous: TMetaNode;
   direction: integer;
   change_the_root: boolean;

   procedure SeekTheOne;
   begin
      Previous := root_name;
      the_one := root_name;
      direction := NONE;
      while (the_one <> nil) and (TNamedNode(the_one.Node).Name <> key) do begin
         Previous := the_one;
         if key < TNamedNode(the_one.Node).Name then begin
            the_one := the_one.LeftChild;
            direction := LEFT;
         end
         else begin
            the_one := the_one.RightChild;
            direction := RIGHT;
         end;
      end;
   end;

  function PerformeDeletion: TMetaNode;
  var
     aux1, aux2: TMetaNode;
  begin
      with the_one do begin
         if (LeftChild = nil) and (RightChild = nil) then begin
            the_one.Free;
            Result := nil;
            {Observa-se que não é necessário deletar o nó de t, o qual
            já foi deletado na rotina DeleteCode}
         end
         else begin
            if LeftChild = nil then begin
               aux1 := RightChild;
               the_one.Free;
               Result := aux1;
            end
            else begin
               if RightChild = nil then begin
                  aux1 := LeftChild;
                  the_one.Free;
                  Result := aux1;
               end
               else begin
                  aux1 := RightChild;
                  aux2 := RightChild;
                  while aux1.LeftChild <> nil do aux1 := aux1.LeftChild;
                  aux1.LeftChild := LeftChild;
                  the_one.Free;
                  Result := aux2;
               end;
            end;
         end;
      end;
  end;

begin
  SeekTheOne;
  if the_one <> nil then begin
     DeleteInIndex(the_one, NAME_INDEX);
     if Previous = root_name then
        change_the_root := true
     else
        change_the_root := false;
     case direction of
       NONE:  Previous := PerformeDeletion;
       LEFT:  Previous.LeftChild := PerformeDeletion;
       RIGHT: Previous.RightChild := PerformeDeletion;
     end;
     if change_the_root then root_name := Previous;
  end;
end;

{Métodos de extração de propriedades}
function TCodeNameIndexTree.GetCode: integer;
begin
   case CurrentKey of
      PRIMARY_KEY:
         Result := inherited GetCode;
      BY_NAME:
        begin
         if CurrentNodeName <> nil then
            Result := CurrentNodeName.Node.Code
         else begin
            MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_PROP,
                       mtWarning, [mbOk], 0);
            Result := 0;
         end;
        end;
   end;
end;

function TCodeNameIndexTree.GetName: string;
begin
   case CurrentKey of
      PRIMARY_KEY:
        begin
         if CurrentNode <> nil then
            Result := TNamedNode(CurrentNode.Node).Name
         else begin
            MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + NAME_PROP,
                       mtWarning, [mbOk], 0);
            Result := '';
         end;
        end;
      BY_NAME:
        begin
         if CurrentNodeName <> nil then
            Result := TNamedNode(CurrentNodeName.Node).Name
         else begin
            MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + NAME_PROP,
                       mtWarning, [mbOk], 0);
            Result := '';
         end;
        end;
   end;
end;

procedure TCodeNameIndexTree.SetName(name: string);
var
   old_key: integer;
   temp_code: integer;
begin
   {Como o campo nome também é uma chave nesse tipo de árvore, a maneira
    mais fácil e inteligível de mudar o valor de uma chave é apagar o nó
    e inseri-lo novamente. A perda de peformance é praticamente nula.}
   old_key := CurrentKey;
   case CurrentKey of
      PRIMARY_KEY: temp_code := CurrentNode.Node.Code;
      BY_NAME: temp_code := CurrentNodeName.Node.Code;
   end;
   Delete;
   Insert(temp_code, Name);
   CurrentKey := old_key;
   case CurrentKey of
      PRIMARY_KEY: Seek(temp_code);
      BY_NAME: SeekByName(Name);
   end;
end;

{=================
 C L A S S E TVars
 =================}
{Métodos de criação e destruição}
procedure TVars.FreeNode(t: TNode);
begin
   TVarNode(t).Free;
end;

procedure TVars.CreateNewNode;
begin
   last_insert := TVarNode.Create;
end;

{Métodos de inserção}
procedure TVars.Insert(c: integer; n: string; num: boolean; multi: boolean);
begin
   inherited Insert(c, n);
   if (CurrentNode <> nil) and (CurrentNodeName <> nil) then begin
      TVarNode(CurrentNode.Node).Numeric := num;
      TVarNode(CurrentNode.Node).Multi := multi;
   end
   else
      MessageDlg(ALLOC_VAR_ERROR_MESSAGE, mtWarning, [mbOk], 0);
end;

{Métodos de extração de propriedades}
procedure TVars.SetName(name: string);
var
   old_key: integer;
   temp_code: integer;
   temp_multi, temp_num: boolean;
begin
   {Como o campo nome também é uma chave nesse tipo de árvore, a maneira
    mais fácil e inteligível de mudar o valor de uma chave é apagar o nó
    e inseri-lo novamente. A perda de peformance é praticamente nula.}
   old_key := CurrentKey;
   case CurrentKey of
      PRIMARY_KEY:
        begin
         temp_code := CurrentNode.Node.Code;
         temp_multi := TVarNode(CurrentNode.Node).Multi;
         temp_num := TVarNode(CurrentNode.Node).Numeric;
        end;
      BY_NAME:
        begin
         temp_code := CurrentNodeName.Node.Code;
         temp_multi := TVarNode(CurrentNodeName.Node).Multi;
         temp_num := TVarNode(CurrentNodeName.Node).Numeric;
        end;
   end;
   Delete;
   Insert(temp_code, name, temp_num, temp_multi);
   CurrentKey := old_key;
   case CurrentKey of
      PRIMARY_KEY: Seek(temp_code);
      BY_NAME: SeekByName(name);
   end;
end;

function TVars.GetMulti: boolean;
begin
   case CurrentKey of
      PRIMARY_KEY:
        begin
         if CurrentNode <> nil then
           Result := TVarNode(CurrentNode.Node).Multi
         else begin
           MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + MULTIVALUED_PROP,
                      mtWarning, [mbOk], 0);
           Result := false;
         end;
        end;
     BY_NAME:
        begin
         if CurrentNodeName <> nil then
           Result := TVarNode(CurrentNodeName.Node).Multi
         else begin
           MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + MULTIVALUED_PROP,
                      mtWarning, [mbOk], 0);
           Result := false;
         end;
        end;
   end;
end;

procedure TVars.SetMulti(multi: boolean);
var
   error: boolean;
begin
   error := false;
   case CurrentKey of
      PRIMARY_KEY:
       begin
        if CurrentNode <> nil then
           TVarNode(CurrentNode.Node).Multi := multi
        else
           error := true;
       end;
      BY_NAME:
       begin
        if CurrentNodeName <> nil then
           TVarNode(CurrentNodeName.Node).Multi := multi
        else
           error := true;
       end;
   end;
   if error then
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + MULTIVALUED_PROP,
                 mtWarning, [mbOk], 0);
end;

function TVars.GetNum: boolean;
begin
   case CurrentKey of
      PRIMARY_KEY:
        begin
         if CurrentNode <> nil then
           Result := TVarNode(CurrentNode.Node).Numeric
         else begin
           MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + NUMERIC_PROP,
                      mtWarning, [mbOk], 0);
           Result := false;
         end;
        end;
     BY_NAME:
        begin
         if CurrentNodeName <> nil then
            Result := TVarNode(CurrentNodeName.Node).Numeric
         else begin
            MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + NUMERIC_PROP,
                       mtWarning, [mbOk], 0);
            Result := false;
         end;
        end;
   end;
end;

procedure TVars.SetNum(numeric: boolean);
var
   error: boolean;
begin
   error := false;
   case CurrentKey of
      PRIMARY_KEY:
        begin
         if CurrentNode <> nil then
            TVarNode(CurrentNode.Node).Numeric := numeric
         else
            error := true;
        end;
      BY_NAME:
        begin
         if CurrentNodeName <> nil then
           TVarNode(CurrentNodeName.Node).Numeric := numeric
         else
           error := true;
        end;
   end;
   if error then
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + NUMERIC_PROP,
                 mtWarning, [mbOk], 0);
end;

{===================
 C L A S S E TValues
 ===================}
{Métodos de criação e destruição}
constructor TValues.Create;
begin
   inherited Create;
   list_index_var := TIndex.Create;
   indexes.Add(list_index_var);
end;

destructor TValues.Destroy;
begin
   DestroyOnlyMetaNode(TIndex(indexes[2]).First);
   list_index_var.Free;
   inherited Destroy;
end;

procedure TValues.FreeNode(t: TNode);
begin
   TValNode(t).Free;
end;

procedure TValues.CreateNewNode;
begin
   last_insert := TValNode.Create;
end;

{Métodos de movimentação}
procedure TValues.SeekByVar(c_var: integer);
begin
   {Deve-se prestar atenção aos códigos repetidos}
   CurrentNodeVar := root_var;
   while (CurrentNodeVar <> nil) and (TValNode(CurrentNodeVar.Node).VarCode <> c_var)
      do begin
      if c_var < TValNode(CurrentNodeVar.Node).VarCode then
         CurrentNodeVar := CurrentNodeVar.LeftChild
      else
         CurrentNodeVar := CurrentNodeVar.RightChild
   end;
   CurrentKey := BY_VAR;
end;

procedure TValues.MoveFirst;
begin
   if CurrentKey <> BY_VAR then
      inherited MoveFirst
   else
      CurrentNodeVar := TIndex(indexes[VAR_INDEX]).First;
end;

procedure TValues.MovePrevious;
begin
   if CurrentKey <> BY_VAR then
      inherited MovePrevious
   else begin
      if CurrentNodeVar <> nil then
         CurrentNodeVar := CurrentNodeVar.Previous
      else
         MessageDlg(BOF_MESSAGE, mtWarning, [mbOk], 0);
   end;
end;

procedure TValues.MoveNext;
begin
   if CurrentKey <> BY_VAR then
      inherited MoveNext
   else begin
      if CurrentNodeVar <> nil then
         CurrentNodeVar := CurrentNodeVar.Next
      else
         MessageDlg(EOF_MESSAGE, mtWarning, [mbOk], 0);
   end;
end;

procedure TValues.MoveLast;
begin
   if CurrentKey <> BY_VAR then
      inherited MoveLast
   else
      CurrentNodeVar := TIndex(indexes[VAR_INDEX]).Last;
end;

function TValues.Blind: boolean;
begin
   if CurrentKey <> BY_VAR then
      Result := inherited Blind
   else
      Result := (CurrentNodeVar = nil);
end;

procedure TValues.SeekByName(name: string; v: integer);
begin
  name := AnsiUpperCase(name);
  inherited SeekByName(name);
  while (CurrentNodeName <> nil)
     and (TValNode(CurrentNodeName.Node).VarCode <> v)
     and (AnsiUpperCase(TValNode(CurrentNodeName.Node).Name) = name) do
     CurrentNodeName := CurrentNodeName.LeftChild;
end;

{Métodos de inserção}
procedure TValues.Insert(c: integer; name: string; c_var: integer; position: integer);
var
  the_left_child, p, q: TMetaNode;
begin
  inherited Insert(c, name);
  the_left_child := nil;
  q := nil;
  p := root_var;
  while p <> nil do begin
     q := p;
     if c_var = TValNode(p.Node).VarCode then begin
        while (p.LeftChild <> nil) and (c_var = TValNode(p.LeftChild.Node).VarCode) do
               p := p.LeftChild;
        q := p;
        the_left_child := p.LeftChild;
        p := nil;
     end
     else begin
        if c_var < TValNode(p.Node).VarCode then
           p := p.LeftChild
        else
           p := p.RightChild;
     end;
  end;
  p := TMetaNode.Create;
  p.Node := last_insert;
  p.LeftChild := the_left_child;
  CurrentNodeVar := p;
  TValNode(CurrentNodeVar.Node).VarCode := c_var;
  TValNode(CurrentNodeVar.Node).Position := position;
  InsertInValIndex(p, q);
  if q = nil then
     root_var := p
  else begin
     if c_var <= TValNode(q.Node).VarCode then
        q.LeftChild := p
     else
        q.RightChild := p;
  end;
end;

procedure TValues.InsertInValIndex(new_one, reference: TMetaNode);
var
   old_var: integer;
begin
   if reference <> nil then begin
      old_var := TValNode(reference.Node).VarCode;
      {Não praticamente nenhuma perda de velocidade, pois "reference" aponta
       para o nó imediatamente anterior a "new_one" na árvore}
       if (TValNode(reference.Node).VarCode > TValNode(new_one.Node).VarCode) then begin
          {Se já existirem nós com a mesma chave (por exemplo, cabeças e caudas
           de regra), recua até o primeiro com mesma chave}
          while (reference.Previous <> nil) and
                (TValNode(reference.Previous.Node).VarCode = old_var) do
                reference := reference.Previous;
          new_one.Previous := reference.Previous;
          new_one.Next := reference;
          if reference.Previous <> nil then
             (reference.Previous).Next := new_one
          else
             TIndex(indexes[VAR_INDEX]).First := new_one;
          reference.Previous := new_one;
       end
       else begin
         {Se já existirem nós com a mesma chave (por exemplo, cabeças e caudas
          de regra), grava o novo nó como sendo o último}
         while (reference.Next <> nil) and
               (TValNode(reference.Next.Node).VarCode = old_var) do
               reference := reference.Next;
         new_one.Previous := reference;
         new_one.Next := reference.Next;
         if reference.Next <> nil then
            (reference.Next).Previous := new_one
         else
            TIndex(indexes[VAR_INDEX]).Last := new_one;
         reference.Next := new_one;
      end
   end
   else begin
      {new_one será o único elemento da lista}
      TIndex(indexes[VAR_INDEX]).First := new_one;
      TIndex(indexes[VAR_INDEX]).Last := new_one;
   end;
end;

{Métodos de deleção}
procedure TValues.Delete;
var
  aux: TMetaNode;
  code_aux, var_code_aux: integer;
  name_aux: string;
begin
   to_be_deleted := nil;
   case CurrentKey of
      PRIMARY_KEY:
       begin
        if CurrentNode <> nil then begin
           aux := CurrentNode.Next;
           code_aux := CurrentNode.Node.Code;
           name_aux := Name;
           var_code_aux := VarCode;
           DeleteCode(Code);
           DeleteCodeName(code_aux, name_aux);
           DeleteCodeVar(code_aux, var_code_aux);
           RecordCount := RecordCount - 1;
           CurrentNode := aux;
        end
        else
           MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
       end;
      BY_NAME:
       begin
        if CurrentNodeName <> nil then begin
           aux := CurrentNodeName.Next;
           code_aux := CurrentNodeName.Node.Code;
           name_aux := Name;
           var_code_aux := VarCode;
           DeleteCode(code_aux);
           DeleteCodeName(code_aux, name_aux);
           DeleteCodeVar(code_aux, var_code_aux);
           RecordCount := RecordCount - 1;
           CurrentNodeName := aux;
        end
        else
           MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
       end;
      BY_VAR:
       begin
        if CurrentNodeVar <> nil then begin
           aux := CurrentNodeVar.Next;
           code_aux := CurrentNodeVar.Node.Code;
           name_aux := Name;
           var_code_aux := VarCode;
           DeleteCode(code_aux);
           DeleteCodeName(code_aux, name_aux);
           DeleteCodeVar(code_aux, var_code_aux);
           RecordCount := RecordCount - 1;
           CurrentNodeVar := aux;
        end
        else
           MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
       end;
   end;
   FreeNode(to_be_deleted);
end;

procedure TValues.DeleteCodeName(p_key: integer; key: string);
var
   the_one, previous: TMetaNode;
   direction: integer;
   change_the_root: boolean;

   procedure SeekTheOne;
   begin
      previous := root_name;
      the_one := root_name;
      direction := NONE;
      while (the_one <> nil) and (TNamedNode(the_one.Node).Name <> key) do begin
         previous := the_one;
         if key < TNamedNode(the_one.Node).Name then begin
            the_one := the_one.LeftChild;
            direction := LEFT;
         end
         else begin
            the_one := the_one.RightChild;
            direction := RIGHT;
         end;
      end;
      {Observe que o campo 'Name' pode aparecer em vários nós. Só o
       campo 'Code' é único.}
      if (the_one <> nil) and (TNamedNode(the_one.Node).Name = key) then
      begin
         if the_one.Node.Code <> p_key then direction := LEFT;
         while (the_one.LeftChild <> nil) and (the_one.Node.Code <> p_key)
         do begin
            previous := the_one;
            the_one := the_one.LeftChild;
         end;
      end;
   end;

   function PerformeDeletion: TMetaNode;
   var
      aux1, aux2: TMetaNode;
   begin
      with the_one do begin
         if (LeftChild = nil) and (RightChild = nil) then begin
            the_one.Free;
            Result := nil;
         end
         else begin
            if LeftChild = nil then begin
               aux1 := RightChild;
               the_one.Free;
               Result := aux1;
            end
            else begin
               if RightChild = nil then begin
                  aux1 := LeftChild;
                  the_one.Free;
                  Result := aux1;
               end
               else begin
                  aux1 := RightChild;
                  aux2 := RightChild;
                  while aux1.LeftChild <> nil do aux1 := aux1.LeftChild;
                  aux1.LeftChild := LeftChild;
                  the_one.Free;
                  Result := aux2;
               end;
            end;
         end;
      end;
 end;

begin
  SeekTheOne;
  if the_one <> nil then begin
     DeleteInIndex(the_one, NAME_INDEX);
     if previous = root_name then
        change_the_root := true
     else
        change_the_root := false;
     case direction of
       NONE:  previous := PerformeDeletion;
       LEFT:  previous.LeftChild := PerformeDeletion;
       RIGHT: previous.RightChild := PerformeDeletion;
     end;
     if change_the_root then root_name := previous;
  end;
end;

procedure TValues.DeleteCodeVar(p_key: integer; key: integer);
var
   the_one, previous: TMetaNode;
   direction: integer;
   change_the_root: boolean;

   procedure SeekTheOne;
   begin
      previous := root_var;
      the_one := root_var;
      direction := NONE;
      while (the_one <> nil) and (TValNode(the_one.Node).VarCode <> key) do begin
         previous := the_one;
         if key < TValNode(the_one.Node).VarCode then begin
            the_one := the_one.LeftChild;
            direction := LEFT;
         end
         else begin
            the_one := the_one.RightChild;
            direction := RIGHT;
         end;
      end;
      {Observe que o campo 'VarCode' pode aparecer em vários nós. Só o
       campo 'Code' é único.}
      if (the_one <> nil) and (TValNode(the_one.Node).VarCode = key) then
      begin
         if the_one.Node.Code <> p_key then direction := LEFT;
         while (the_one.LeftChild <> nil) and (the_one.Node.Code <> p_key)
         do begin
            previous := the_one;
            the_one := the_one.LeftChild;
         end;
      end;
   end;

   function PerformeDeletion: TMetaNode;
   var
      aux1, aux2: TMetaNode;
   begin
      with the_one do begin
         if (LeftChild = nil) and (RightChild = nil) then begin
            the_one.Free;
            Result := nil;
         end
         else begin
            if LeftChild = nil then begin
               aux1 := RightChild;
               the_one.Free;
               Result := aux1;
            end
            else begin
               if RightChild = nil then begin
                  aux1 := LeftChild;
                  the_one.Free;
                  Result := aux1;
               end
               else begin
                  aux1 := RightChild;
                  aux2 := RightChild;
                  while aux1.LeftChild <> nil do aux1 := aux1.LeftChild;
                  aux1.LeftChild := LeftChild;
                  the_one.Free;
                  Result := aux2;
               end;
            end;
         end;
      end;
   end;

begin
  SeekTheOne;
  if the_one <> nil then begin
     DeleteInIndex(the_one, VAR_INDEX);
     if previous = root_var then
        change_the_root := true
     else
        change_the_root := false;
     case direction of
       NONE:  previous := PerformeDeletion;
       LEFT:  previous.LeftChild := PerformeDeletion;
       RIGHT: previous.RightChild := PerformeDeletion;
     end;
     if change_the_root then root_var := previous;
  end;
end;

{Métodos de tratamento de propriedades}
function TValues.GetCode: integer;
begin
   if CurrentKey <> BY_VAR then
      Result := inherited GetCode
   else begin
      if CurrentNodeVar <> nil then
         Result := CurrentNodeVar.Node.Code
      else begin
         MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_PROP,
                    mtWarning, [mbOk], 0);
         Result := 0;
      end;
   end;
end;

function TValues.GetName: string;
begin
   if CurrentKey <> BY_VAR then
      Result := inherited GetName
   else begin
      if CurrentNodeVar <> nil then
         Result := TNamedNode(CurrentNodeVar.Node).Name
      else begin
         MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + NAME_PROP,
                    mtWarning, [mbOk], 0);
         Result := '';
      end;
   end;
end;

procedure TValues.SetName(name: string);
var
   old_key: integer;
   temp_code, temp_var_code, temp_position: integer;
begin
   {Como o campo nome também é uma chave nesse tipo de árvore, a maneira
    mais fácil e inteligível de mudar o valor de uma chave é apagar o nó
    e inseri-lo novamente. A perda de peformance é praticamente nula.}
   old_key := CurrentKey;
   case CurrentKey of
      PRIMARY_KEY:
        begin
         temp_code := CurrentNode.Node.Code;
         temp_var_code := TValNode(CurrentNode.Node).VarCode;
         temp_position := TValNode(CurrentNode.Node).Position;
        end;
      BY_NAME:
        begin
         temp_code := CurrentNodeName.Node.Code;
         temp_var_code := TValNode(CurrentNodeName.Node).VarCode;
         temp_position := TValNode(CurrentNodeName.Node).Position;
        end;
      BY_VAR:
        begin
         temp_code := CurrentNodeVar.Node.Code;
         temp_var_code := TValNode(CurrentNodeVar.Node).VarCode;
         temp_position := TValNode(CurrentNodeVar.Node).Position;
        end;
   end;
   Delete;
   Insert(temp_code, name, temp_var_code, temp_position);
   CurrentKey := old_key;
   case CurrentKey of
      PRIMARY_KEY: Seek(temp_code);
      BY_NAME: SeekByName(name, temp_var_code);
      BY_VAR: SeekByVar(temp_var_code);
   end;
end;

function TValues.GetCodeVar: integer;
var
   error: boolean;
begin
   error := false;
   case CurrentKey of
        PRIMARY_KEY:
          begin
           if CurrentNode <> nil then
              Result := TValNode(CurrentNode.Node).VarCode
           else
              error := true;
          end;
        BY_NAME:
          begin
           if CurrentNodeName <> nil then
              Result := TValNode(CurrentNodeName.Node).VarCode
           else
              error := true;
          end;
        BY_VAR:
          begin
           if CurrentNodeVar <> nil then
              Result := TValNode(CurrentNodeVar.Node).VarCode
           else
              error := true
          end;
   end;
   if error then begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_VAR_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

function TValues.GetPosition: integer;
var
   error: boolean;
begin
   error := false;
   case CurrentKey of
        PRIMARY_KEY:
          begin
           if CurrentNode <> nil then
              Result := TValNode(CurrentNode.Node).Position
           else
              error := true;
          end;
        BY_NAME:
          begin
           if CurrentNodeName <> nil then
              Result := TValNode(CurrentNodeName.Node).Position
           else
              error := true;
          end;
        BY_VAR:
          begin
           if CurrentNodeVar <> nil then
              Result := TValNode(CurrentNodeVar.Node).Position
           else
              error := true
          end;
   end;
   if error then begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + VALUE_POS_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

procedure TValues.SetPosition(p: integer);
var
   error: boolean;
begin
   error := false;
   case CurrentKey of
        PRIMARY_KEY:
          begin
           if CurrentNode <> nil then
              TValNode(CurrentNode.Node).Position := p
           else
              error := true;
          end;
        BY_NAME:
          begin
           if CurrentNodeName <> nil then
              TValNode(CurrentNodeName.Node).Position := p
           else
              error := true;
          end;
        BY_VAR:
          begin
           if CurrentNodeVar <> nil then
              TValNode(CurrentNodeVar.Node).Position := p
           else
              error := true
          end;
   end;
   if error then
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + VALUE_POS_PROP,
                 mtWarning, [mbOk], 0);
end;

{==================
 C L A S S E TTails
 ==================}
{Métodos de criação e destruição}
procedure TTails.FreeNode(t: TNode);
begin
   TTailNode(t).Free;
end;

procedure TTails.CreateNewNode;
begin
   last_insert := TTailNode.Create;
end;

{Métodos de inserção}
procedure TTails.Insert(c: integer; c_var: integer; op: string;
                 c_val: integer; conec: integer; neg: boolean);
begin
  inherited Insert(c);
  if CurrentNode <> nil then begin
     TTailNode(CurrentNode.Node).VarCode := c_var;
     TTailNode(CurrentNode.Node).Operator := op;
     TTailNode(CurrentNode.Node).ValCode := c_val;
     TTailNode(CurrentNode.Node).Conect := conec;
     TTailNode(CurrentNode.Node).Neg := neg;
  end
  else
     MessageDlg(ALLOC_TAIL_ERROR_MESSAGE, mtWarning, [mbOk], 0);
end;

function TTails.GetVar: integer;
begin
   if CurrentNode <> nil then
      Result := TTailNode(CurrentNode.Node).VarCode
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_VAR_PROP,
                    mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

function TTails.GetValue: integer;
begin
   if CurrentNode <> nil then
      Result := TTailNode(CurrentNode.Node).ValCode
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_VALUE_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

function TTails.GetOperator: string;
begin
   if CurrentNode <> nil then
      Result := TTailNode(CurrentNode.Node).Operator
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + OPERATOR_PROP,
                 mtWarning, [mbOk], 0);
      Result := '';
   end;
end;

function TTails.GetConect: integer;
begin
   if CurrentNode <> nil then
      Result := TTailNode(CurrentNode.Node).Conect
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CONECT_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

function TTails.GetNeg: boolean;
begin
   if CurrentNode <> nil then
      Result := TTailNode(CurrentNode.Node).Neg
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + NEG_PROP,
                 mtWarning, [mbOk], 0);
      Result := false;
   end;
end;

{==================
 C L A S S E THeads
 ==================}
{Métodos de criação e destruição}
procedure THeads.FreeNode(t: TNode);
begin
   THeadNode(t).Free;
end;

procedure THeads.CreateNewNode;
begin
   last_insert := THeadNode.Create;
end;

{Métodos de inserção}
procedure THeads.Insert(c: integer; c_var: integer; c_val: integer;
                        cnf: single);
begin
  inherited Insert(c);
  THeadNode(CurrentNode.Node).VarCode := c_var;
  THeadNode(CurrentNode.Node).ValCode := c_val;
  THeadNode(CurrentNode.Node).CNF := cnf;
end;

{Métodos relativos a propriedades}
function THeads.GetVar: integer;
begin
   if CurrentNode <> nil then
      Result := THeadNode(CurrentNode.Node).VarCode
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_VAR_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

function THeads.GetValue: integer;
begin
   if CurrentNode <> nil then
      Result := THeadNode(CurrentNode.Node).ValCode
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_VALUE_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

function THeads.GetCNF: single;
begin
   if CurrentNode <> nil then
      Result := THeadNode(CurrentNode.Node).CNF
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CNF_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

{=========================
 C L A S S E TQuestionNode
 =========================}
{Métodos de criação de nós}
constructor TQuestionNode.Create;
begin
   inherited Create;
   Why := TStringList.Create;
end;

destructor TQuestionNode.Destroy;
begin
   Why.Free;
   inherited Destroy;
end;

{======================
 C L A S S E TQuestions
 ======================}
{Métodos de criação de nós}
procedure TQuestions.CreateNewNode;
begin
   last_insert := TQuestionNode.Create;
end;

procedure TQuestions.FreeNode(t: TNode);
begin
   TQuestionNode(t).Free;
end;

{Métodos de inserção}
procedure TQuestions.Insert(c: integer; q: string; w: TStringList; uc: boolean);
begin
   inherited Insert(c);
   if CurrentNode <> nil then begin
      TQuestionNode(CurrentNode.Node).Question := q;
      TQuestionNode(CurrentNode.Node).Why.Clear;
      if w <> nil then TQuestionNode(CurrentNode.Node).Why.AddStrings(w);
      TQuestionNode(CurrentNode.Node).UseCNF := uc;
   end
   else
      MessageDlg(ALLOC_QUESTION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
end;

{Métodos de extração de propriedades}
function TQuestions.GetQuestion: string;
begin
   if CurrentNode <> nil then
      Result := TQuestionNode(CurrentNode.Node).Question
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + QUESTION_PROP,
                 mtWarning, [mbOk], 0);
      Result := '';
   end;
end;

procedure TQuestions.SetQuestion(q: string);
begin
   if CurrentNode <> nil then
      TQuestionNode(CurrentNode.Node).Question := q
   else
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + QUESTION_PROP,
                 mtWarning, [mbOk], 0);
end;

function TQuestions.GetWhy: TStringList;
begin
   if CurrentNode <> nil then
      Result := TQuestionNode(CurrentNode.Node).Why
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + WHY_PROP,
                 mtWarning, [mbOk], 0);
      Result := nil;
   end;
end;

procedure TQuestions.SetWhy(w: TStringList);
begin
   if CurrentNode <> nil then begin
      TQuestionNode(CurrentNode.Node).Why.Clear;
      if w <> nil then TQuestionNode(CurrentNode.Node).Why.AddStrings(w);
   end
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + WHY_PROP,
                 mtWarning, [mbOk], 0);
end;

function TQuestions.GetUseCNF: boolean;
begin
   if CurrentNode <> nil then
      Result := TQuestionNode(CurrentNode.Node).UseCNF
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + USE_CNF_PROP,
                 mtWarning, [mbOk], 0);
      Result := false;
   end;
end;

procedure TQuestions.SetUseCNF(uc: boolean);
begin
   if CurrentNode <> nil then
      TQuestionNode(CurrentNode.Node).UseCNF := uc
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + USE_CNF_PROP,
                 mtWarning, [mbOk], 0);
end;

{=========================
 C L A S S E THelpContexts
 =========================}
{Métodos de criação de nós}
procedure THelpContexts.CreateNewNode;
begin
   last_insert := TContextNode.Create;
end;

procedure THelpContexts.FreeNode(t: TNode);
begin
   TContextNode(t).Free;
end;

{Métodos de inserção}
procedure THelpContexts.Insert(c: integer; con: integer);
begin
   inherited Insert(c);
   if CurrentNode <> nil then
      TContextNode(CurrentNode.Node).Context := con
   else
      MessageDlg(ALLOC_CONTEXT_ERROR_MESSAGE, mtWarning, [mbOk], 0);
end;

{Métodos de extração de propriedades}
function THelpContexts.GetContext: integer;
begin
   if CurrentNode <> nil then
      Result := TContextNode(CurrentNode.Node).Context
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CONTEXT_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

procedure THelpContexts.SetContext(c: integer);
begin
   if CurrentNode <> nil then
      TContextNode(CurrentNode.Node).Context := c
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + CONTEXT_PROP,
                 mtWarning, [mbOk], 0);
end;

{========================
 C L A S S E TVarListTree
 ========================}
{Métodos de criação de nós}
procedure TVarListTree.CreateNewNode;
begin
   last_insert := TVarListNode.Create;
end;

procedure TVarListTree.FreeNode(t: TNode);
begin
   TVarListNode(t).Free;
end;

{Métodos de inserção}
procedure TVarListTree.Insert(c: integer; v: integer; cnf: single);
begin
   inherited Insert(c);
   if CurrentNode <> nil then begin
      TVarListNode(CurrentNode.Node).ValCode := v;
      TVarListNode(CurrentNode.Node).CNF := cnf;
   end
   else
      MessageDlg(ALLOC_VAR_LIST_ERROR_MESSAGE, mtWarning, [mbOk], 0);
end;

{Métodos de deleção de elementos}
procedure TVarListTree.Delete;
var
  aux: TMetaNode;
begin
   to_be_deleted := nil;
   if CurrentNode <> nil then begin
      aux := CurrentNode.Next;
      DeleteCode(CurrentNode.Node.Code,
                 TVarListNode(CurrentNode.Node).ValCode);
      CurrentNode := aux;
      RecordCount := RecordCount - 1;
   end
   else
      MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
   FreeNode(to_be_deleted);
end;

procedure TVarListTree.DeleteCode(key: integer; cod_value: integer);
var
   the_one, previous: TMetaNode;
   direction: integer;
   change_the_root: boolean;

   procedure SeekTheOne;
   begin
      previous := root;
      the_one := root;
      direction := NONE;
      while (the_one <> nil) and (the_one.Node.Code <> key) do begin
         previous := the_one;
         if key < the_one.Node.Code then begin
            the_one := the_one.LeftChild;
            direction := LEFT;
         end
         else begin
            the_one := the_one.RightChild;
            direction := RIGHT;
         end;
      end;
      {Observe que o campo 'ValCode' pode aparecer em vários nós. Só o
       campo 'Code' é único.}
      if (the_one <> nil) and (the_one.Node.Code = key) then
      begin
         if TVarListNode(the_one.Node).ValCode <> cod_value then direction := LEFT;
         while (the_one.LeftChild <> nil) and (TVarListNode(the_one.Node).ValCode <> cod_value)
         do begin
            previous := the_one;
            the_one := the_one.LeftChild;
         end;
      end;
   end;

   function PerformeDeletion: TMetaNode;
   var
      aux1, aux2: TMetaNode;
   begin
      with the_one do begin
         if (LeftChild = nil) and (RightChild = nil) then begin
            the_one.Free;
            Result := nil;
         end
         else begin
            if LeftChild = nil then begin
               aux1 := RightChild;
               the_one.Free;
               Result := aux1;
            end
            else begin
               if RightChild = nil then begin
                  aux1 := LeftChild;
                  the_one.Free;
                  Result := aux1;
               end
               else begin
                  aux1 := RightChild;
                  aux2 := RightChild;
                  while aux1.LeftChild <> nil do aux1 := aux1.LeftChild;
                  aux1.LeftChild := LeftChild;
                  the_one.Free;
                  Result := aux2;
               end;
            end;
         end;
      end;
   end;

begin
  SeekTheOne;
  if the_one <> nil then begin
     DeleteInIndex(the_one, PRIMARY_KEY);
     if previous = root then
        change_the_root := true
     else
        change_the_root := false;
     case direction of
       NONE:  previous := PerformeDeletion;
       LEFT:  previous.LeftChild := PerformeDeletion;
       RIGHT: previous.RightChild := PerformeDeletion;
     end;
     if change_the_root then root := previous;
  end;
end;

{Métodos de extração de propriedades}
function TVarListTree.GetCodeValue: integer;
begin
   if CurrentNode <> nil then
      Result := TVarListNode(CurrentNode.Node).ValCode
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CODE_VALUE_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

procedure TVarListTree.SetCodeValue(c: integer);
begin
   if CurrentNode <> nil then
      TVarListNode(CurrentNode.Node).ValCode := c
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + CODE_VALUE_PROP,
                 mtWarning, [mbOk], 0);
end;

function TVarListTree.GetCNF: single;
begin
   if CurrentNode <> nil then
      Result := TVarListNode(CurrentNode.Node).CNF
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CNF_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

procedure TVarListTree.SetCNF(c: single);
begin
   if CurrentNode <> nil then
      TVarListNode(CurrentNode.Node).CNF := c
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + CNF_PROP,
                 mtWarning, [mbOk], 0);
end;

{=============================
 C L A S S E TVarListTreeExtra
 =============================}
{Métodos de criação de nós}
procedure TVarListExtraTree.CreateNewNode;
begin
   last_insert := TVarListExtraNode.Create;
end;

procedure TVarListExtraTree.FreeNode(t: TNode);
begin
   TVarListExtraNode(t).Free;
end;

{Métodos de inserção}
procedure TVarListExtraTree.Insert(c: integer; v: string; cnf: single);
begin
   inherited Insert(c);
   if CurrentNode <> nil then begin
      TVarListExtraNode(CurrentNode.Node).Value := v;
      TVarListExtraNode(CurrentNode.Node).CNF := cnf;
   end
   else
      MessageDlg(ALLOC_VAR_LIST_ERROR_MESSAGE, mtWarning, [mbOk], 0);
end;

{Métodos de deleção}
procedure TVarListExtraTree.Delete;
var
  aux: TMetaNode;
begin
   to_be_deleted := nil;
   if CurrentNode <> nil then begin
      aux := CurrentNode.Next;
      DeleteCode(CurrentNode.Node.Code,
                 TVarListExtraNode(CurrentNode.Node).Value);
      CurrentNode := aux;
      RecordCount := RecordCount - 1;
   end
   else
      MessageDlg(DELETION_ERROR_MESSAGE, mtWarning, [mbOk], 0);
   FreeNode(to_be_deleted);
end;

procedure TVarListExtraTree.DeleteCode(key: integer; value: string);
var
   the_one, previous: TMetaNode;
   direction: integer;
   change_the_root: boolean;

   procedure SeekTheOne;
   begin
      previous := root;
      the_one := root;
      direction := NONE;
      while (the_one <> nil) and (the_one.Node.Code <> key) do begin
         previous := the_one;
         if key < the_one.Node.Code then begin
            the_one := the_one.LeftChild;
            direction := LEFT;
         end
         else begin
            the_one := the_one.RightChild;
            direction := RIGHT;
         end;
      end;
      {Observe que o campo 'Code' pode aparecer em vários nós}
      if (the_one <> nil) and (the_one.Node.Code = key) then
      begin
         if TVarListExtraNode(the_one.Node).Value <> value then direction := LEFT;
         while (the_one.LeftChild <> nil) and (TVarListExtraNode(the_one.Node).Value <> value)
         do begin
            Previous := the_one;
            the_one := the_one.LeftChild;
         end;
      end;
   end;

   function PerformeDeletion: TMetaNode;
   var
      aux1, aux2: TMetaNode;
   begin
      with the_one do begin
         if (LeftChild = nil) and (RightChild = nil) then begin
            the_one.Free;
            Result := nil;
         end
         else begin
            if LeftChild = nil then begin
               aux1 := RightChild;
               the_one.Free;
               Result := aux1;
            end
            else begin
               if RightChild = nil then begin
                  aux1 := LeftChild;
                  the_one.Free;
                  Result := aux1;
               end
               else begin
                  aux1 := RightChild;
                  aux2 := RightChild;
                  while aux1.LeftChild <> nil do aux1 := aux1.LeftChild;
                  aux1.LeftChild := LeftChild;
                  the_one.Free;
                  Result := aux2;
               end;
            end;
         end;
      end;
   end;

begin
  SeekTheOne;
  if the_one <> nil then begin
     DeleteInIndex(the_one, PRIMARY_KEY);
     if previous = root then
        change_the_root := true
     else
        change_the_root := false;
     case direction of
       NONE:  previous := PerformeDeletion;
       LEFT:  previous.LeftChild := PerformeDeletion;
       RIGHT: previous.RightChild := PerformeDeletion;
     end;
     if change_the_root then root := previous;
  end;
end;

{Métodos de extração de propriedades}
function TVarListExtraTree.GetValue: string;
begin
   if CurrentNode <> nil then
      Result := TVarListExtraNode(CurrentNode.Node).Value
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + VALUE_PROP,
                 mtWarning, [mbOk], 0);
      Result := '';
   end;
end;

procedure TVarListExtraTree.SetValue(c: string);
begin
   if CurrentNode <> nil then
      TVarListExtraNode(CurrentNode.Node).Value := c
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + VALUE_PROP,
                 mtWarning, [mbOk], 0);
end;

function TVarListExtraTree.GetCNF: single;
begin
   if CurrentNode <> nil then
      Result := TVarListExtraNode(CurrentNode.Node).CNF
   else begin
      MessageDlg(READING_ERROR_MESSAGE + PROP_STRING + CNF_PROP,
                 mtWarning, [mbOk], 0);
      Result := 0;
   end;
end;

procedure TVarListExtraTree.SetCNF(c: single);
begin
   if CurrentNode <> nil then
      TVarListExtraNode(CurrentNode.Node).CNF := c
   else
      MessageDlg(WRITING_ERROR_MESSAGE + PROP_STRING + CNF_PROP,
                 mtWarning, [mbOk], 0);
end;

{========================
 C L A S S E TTreeOfTrees
 ========================}
{Métodos de criação e destruição}
procedure TTreeOfTrees.FreeNode(t: TNode);
begin
   TTreeOfTreesNode(t).tree.Free;
   TTreeOfTreesNode(t).Free;
end;

procedure TTreeOfTrees.CreateNewNode;
begin
   last_insert := TTreeOfTreesNode.Create;
end;

{Métodos de inserção}
procedure TTreeOfTrees.Insert(c: integer; t: TSingleIndexTree);
begin
   inherited Insert(c);
   if CurrentNode <> nil then
      TTreeOfTreesNode(CurrentNode.node).tree := t
   else
      MessageDlg('Houve um erro de alocação de memória para TTreeOfTrees.',
                 mtWarning, [mbOk], 0);
end;

{Métodos de extração de propriedades}
function TTreeOfTrees.GetTree: TSingleIndexTree;
begin
   if CurrentNode <> nil then
      Result := TTreeOfTreesNode(CurrentNode.node).tree
   else begin
      MessageDlg('Houve a tentativa de leitura da propriedade "árvore" com ponteiro perdido!',
                  mtWarning, [mbOk], 0);
      Result := nil;
   end;
end;

procedure TTreeOfTrees.SetTree(tree: TSingleIndexTree);
begin
   if CurrentNode <> nil then
      TTreeOfTreesNode(CurrentNode.node).tree := tree
   else
      MessageDlg('Houve a tentativa de mudança da propriedade "árvore" com ponteiro perdido!',
                 mtWarning, [mbOk], 0);
end;

{======================================================================
 ======================================================================
                                 PILHAS
 ======================================================================
 ======================================================================}

{==================
 C L A S S E TStack
 ==================}
{Métodos de criação e destruição do objeto}
constructor TStack.Create;
begin
   start_Node := CreateNewNode;
   top_Node := start_Node;
end;

destructor TStack.Destroy;
var
   old_top: TStackMetaNode;
begin
   while top_Node <> start_Node do begin
      old_top := top_Node;
      top_Node := top_Node.Previous;
      DestroyNode(old_top);
   end;
   DestroyNode(start_Node);
end;

function TStack.CreateNewNode: TStackMetaNode;
begin
   Result := TStackMetaNode.Create;
   Result.Node := TObjectNode.Create;
   Result.Previous := nil;
end;

procedure TStack.DestroyNode(t: TStackMetaNode);
begin
   TObjectNode(t.Node).Free;
   t.Free;
end;

{Métodos de operação com os items}
function TStack.Blind: boolean;
begin
   Result := (top_Node = start_Node);
end;

procedure TStack.Push(c: TObject);
var
   Next: TStackMetaNode;
begin
   Next := CreateNewNode;
   Next.Previous := top_Node;
   top_Node := Next;
   TObjectNode(Next.Node).Obj := c;
   inc(RecordCount);
end;

function TStack.Pop: TObject;
var
   aux: TStackMetaNode;
begin
   if Blind then begin
      MessageDlg(EMPTY_STACK_ERROR_MESSAGE, mtInformation, [mbOk], 0);
      Result := nil
   end
   else begin
      aux := top_Node.Previous;
      Result := TObjectNode(top_Node.Node).Obj;
      DestroyNode(top_Node);
      top_Node := aux;
   end;
   dec(RecordCount);
end;

function TStack.Top: TObject;
begin
   if Blind then begin
      MessageDlg(EMPTY_STACK_ERROR_MESSAGE, mtInformation, [mbOk], 0);
      Result := nil
   end
   else
      Result := TObjectNode(top_Node.Node).Obj;
end;

{=========================
 C L A S S E TIntegerStack
 =========================}
{Métodos de criação e destruição do objeto}
function TIntegerStack.CreateNewNode: TStackMetaNode;
begin
   Result := TStackMetaNode.Create;
   Result.Node := TIntegerNode.Create;
   Result.Previous := nil;
end;

procedure TIntegerStack.DestroyNode(t: TStackMetaNode);
begin
   TIntegerNode(t.Node).Free;
   t.Free;
end;

{Métodos de operação com os items}
procedure TIntegerStack.Push(c: integer);
var
   Next: TStackMetaNode;
begin
   Next := CreateNewNode;
   Next.Previous := top_Node;
   top_Node := Next;
   TIntegerNode(Next.Node).Code := c;
   inc(RecordCount);
end;

function TIntegerStack.Pop: integer;
var
   aux: TStackMetaNode;
begin
   if Blind then begin
      MessageDlg(EMPTY_STACK_ERROR_MESSAGE, mtInformation, [mbOk], 0);
      Result := 0
   end
   else begin
      aux := top_Node.Previous;
      Result := TIntegerNode(top_Node.Node).Code;
      DestroyNode(top_Node);
      top_Node := aux;
   end;
   dec(RecordCount);
end;

function TIntegerStack.Top: integer;
begin
   if Blind then begin
      MessageDlg(EMPTY_STACK_ERROR_MESSAGE, mtInformation, [mbOk], 0);
      Result := 0
   end
   else
      Result := TIntegerNode(top_Node.Node).Code;
end;

{========================
 C L A S S E TStringStack
 ========================}
{Métodos de criação e destruição}
constructor TStringStack.Create;
begin
   Items := TStringList.Create;
end;

destructor TStringStack.Destroy;
begin
   Items.Free;
end;

{Métodos de operação com os items}
function TStringStack.Pop: string;
var
   i: integer;
begin
   i := Items.Count - 1;
   Result := Items[i];
   Items.Delete(i);
end;

function TStringStack.Top: string;
var
   i: integer;
begin
   i := Items.Count - 1;
   Result := Items[i];
end;

procedure TStringStack.Push(v: string);
begin
   Items.Add(v);
end;

function TStringStack.GetRecordCount: integer;
begin
   Result := Items.Count;
end;

{======================================================================
 ======================================================================
                                 FILAS
 ======================================================================
 ======================================================================}

{==========================
 C L A S S E TQueueMetaNode
 ==========================}
{Métodos de criação e destruição do objeto}
constructor TQueueMetaNode.Create;
begin
   inherited Create;
   Node := TNode.Create;
   Next := nil;
end;

destructor TQueueMetaNode.Destroy;
begin
   Node.Free;
   inherited Destroy;
end;

{==================
 C L A S S E TQueue
 ==================}
{Métodos de criação e destruição do objeto}
constructor TQueue.Create;
begin
   Front := nil;
   Rear := Front;
   Error := false;
   RecordCount := 0;
end;

destructor TQueue.Destroy;
var
  Previous: TQueueMetaNode;
begin
   while Front <> nil do begin
      Previous := Front;
      Front := Front.Next;
      Previous.Free;
   end;
end;

{Métodos de pesquisa}
function TQueue.Blind: boolean;
begin
   Result := (RecordCount = 0);
end;

function TQueue.GetCode: integer;
begin
   if Blind then begin
      MessageDlg(EMPTY_QUEUE_ERROR_MESSAGE, mtWarning, [mbOk], 0);
      Error := true;
   end
   else
      Result := Front.Node.Code;
end;

{Métodos de inserção e deleção}
procedure TQueue.Insert(element: integer);
var
   old, aux: TQueueMetaNode;
begin
   aux := TQueueMetaNode.Create;
   aux.Node.Code := element;
   if Front = nil then begin
      Front := aux;
      Rear := Front;
   end
   else begin
      old := Rear;
      Rear := aux;
      old.Next := Rear;
   end;
   RecordCount := RecordCount + 1;
end;

procedure TQueue.Delete;
var
   aux: TQueueMetaNode;
begin
   if Blind then begin
      MessageDlg(EMPTY_QUEUE_ERROR_MESSAGE, mtWarning, [mbOk], 0);
      error := true;
   end
   else begin
      aux := Front;
      Front := Front.Next;
      aux.Free;
      RecordCount := RecordCount - 1
   end;
end;

{Redefine o ponteiro para o último elemento. Necessário no procedimento
 TES.BrutalReturn, pois uma parte final da fila é cortada fora}
procedure TQueue.RebuildRear;
var
   i, total: integer;
begin
   total := RecordCount - 1;
   Rear := Front;
   for i := 1 to total do Rear := Rear.Next;
   Rear.Next := nil;
end;

{======================================================================
 ======================================================================
                                 LISTAS
 ======================================================================
 ======================================================================}

{=======================
 C L A S S E TObjectList
 =======================}
{Métodos de criação e destruição do objeto}
destructor TObjectList.Destroy;
var
   current, Next: TListMetaNode;
begin
   current := First;
   while current <> nil do begin
      Next := current.Next;
      if FAutoFree then current.PObject.Free;
      current.Free;
      current := Next;
   end;
end;

{Inserção e delação}
procedure TObjectList.Append(item: TObject);
var
   current: TListMetaNode;
begin
   current := TListMetaNode.Create;
   if FCount = 0 then begin
      First := current;
      Last := First;
   end
   else begin
      Last.Next := current;
      current.Previous := Last;
      Last := current;
   end;
   current.PObject := item;
   inc(FCount);
end;

procedure TObjectList.Delete(index: integer);
var
   i: integer;
   current: TListMetaNode;
begin
   if (index >= FCount) or (index < 0) then
      MessageDlg(LIST_INDEX_OUT_OF_BOUNDS_ERROR_MESSAGE, mtError, [mbOk], 0)
   else begin
      current := First;
      dec(index);
      for i := 0 to index do current := current.Next;
      DeleteThisMetaNode(current);
   end;
end;

procedure TObjectList.DeleteThisMetaNode(m: TListMetaNode);
begin
   if m = First then First := m.Next;
   if m = Last then Last := m.Previous;
   if m.Previous <> nil then (m.Previous).Next := m.Next;
   if m.Next <> nil then (m.Next).Previous := m.Previous;
   if FAutoFree then m.PObject.Free;
   m.Free;
   dec(FCount);
end;

{Mudança de items}
procedure TObjectList.SetItemPointer(Index: integer; ob: TObject);
var
   i: integer;
   current: TListMetaNode;
begin
   if index >= FCount then
      MessageDlg(LIST_INDEX_OUT_OF_BOUNDS_ERROR_MESSAGE, mtError, [mbOk], 0)
   else begin
      current := First;
      dec(index);
      for i := 0 to index do current := current.Next;
      if FAutoFree then current.PObject.Free;
      current.PObject := ob;
   end;
end;

function TObjectList.GetItemPointer(index: integer): TObject;
var
   i: integer;
   current: TListMetaNode;
begin
   if index >= FCount then
      MessageDlg(LIST_INDEX_OUT_OF_BOUNDS_ERROR_MESSAGE, mtError, [mbOk], 0)
   else begin
      current := First;
      dec(index);
      for i := 0 to index do current := current.Next;
      Result := current.PObject;
   end;
end;

{=========================
 C L A S S E TInstanceList
 =========================}
{Inserção e deleção}
procedure TInstanceList.AppendInstance(var_c: integer; val_c: string; cnf: single;
          is_a_code: boolean);
var
   new_Node: TInstance;
begin
   new_Node := TInstance.Create;
   new_Node.VarCode := var_c;
   new_Node.val := val_c;
   new_Node.CNF := cnf;
   new_Node.IsACode := is_a_code;
   Append(new_Node);
end;

{Esse método é utilizado pelo método TES.DestroyAllInstances.
 Necessário para apagar a instância de uma variável que aparece
 através de uma pergunta}
procedure TInstanceList.DeleteAllInstances(var_c: integer);
var
   current, pos_current: TListMetaNode;
begin
   current := First;
   while current <> nil do begin
       pos_current := current.Next;
       if TInstance(current.PObject).VarCode = var_c then
          DeleteThisMetaNode(current);
       current := pos_current;
   end;
end;

{O seguinte método procura pela última instância de var_cna sua lista, de trás
 para frente (os últimos itens são sempre os mais novos). Ao encontrar,
 deleta o item, bem como o par correspondente na árvore de variáveis
 instanciadas (varList ou varListExtra - ver unit Machines). Em seguida,
 continuar a busca de onde parou, sempre voltando, atrás da última instanciação
 antes da deletada. Se encontrar, adiciona novamente com o método AttribVar
 da classe TExpertSystem. Observe que, se a variável for multivalorada, a ação é
 diferente: busca-se se existiu algum par igual (var_c, val_c) anterior,
 adicionando-o novamente.}
procedure TInstanceList.RebuildInstance(var_c: integer; X: TObject);
var
   aux, current: TListMetaNode;
   multi: boolean;
   ES: TExpertSystem;
   val_c: string;

   function VarCode: integer;
   begin
      Result := TInstance(current.PObject).VarCode;
   end;

   function ValCode: string;
   begin
      Result := TInstance(current.PObject).Val;
   end;

   function CNF: single;
   begin
      Result := TInstance(current.PObject).CNF;
   end;

   function IsACode: boolean;
   begin
      Result := TInstance(current.PObject).IsACode;
   end;

begin
   current := Last;
   ES := TExpertSystem(X);
   ES.Vars.Seek(var_c);
   multi := ES.Vars.Multi;
   while (current <> nil) and (VarCode <> var_c) do current := current.Previous;
   if current <> nil then begin {Achou uma instanciação}
      val_c := ValCode;
      aux := current.Previous;
      DeleteThisMetaNode(current);
      current := aux;
      {Deleta a instanciação correspondente nas árvores de
       instanciações atuais}
      if multi then begin
         ES.varList.Seek(var_c);
         while (not ES.varList.Blind) and
               (ES.varList.ValCode <> StrToInt(val_c))
               do ES.varList.MoveNext;
         if not ES.varList.Blind then ES.varList.Delete;
      end
      else begin
          ES.varList.Seek(var_c);
          if not ES.varList.Blind then ES.varList.Delete;
          ES.varListExtra.Seek(var_c);
          if not ES.varListExtra.Blind then ES.varListExtra.Delete;
      end;
      {Agora, vamos atrás de reconstitui a última instanciação antes
       dessa que foi apagada}
      if multi then begin
         {Observa-se a necessidade de procurar pelo mesmo par (var_c,
          val_c) e não somente var_c, pois as outras instanciações
          foram mantidas}
         while (current <> nil) and
               ((VarCode <> var_c) or (ValCode <> val_c))
               do current := current.Previous;
         if current <> nil then ES.AttribVar(var_c, val_c, CNF, true);
         {Observe que, apesar de continuar com o mesmo conjunto de
          instanciações (apagamos o anterior, mas substituímos pelo
          mesmo par var_c, val_c) o CNF vai ser diferente, pois quando
          atribuímos duas vezes o mesmo CNF, passa-se pela regra
          DOUBLE _EVALUTATION}
      end
      else begin
         {Aqui, a última instanciação tem que ser reconstruída, pois a variável
          univalorada substitui valores}
         while (current <> nil) and (VarCode <> var_c)
               do current := current.Previous;
         if current <> nil then ES.AttribVar(var_c, ValCode, CNF, IsACode);
      end;
   end;
end;

{=======================
 C L A S S E TTargetNode
 =======================}
constructor TTargetNode.Create;
begin
   inherited Create;
   ShowResults := true;
end;

{====================
 C L A S S E TTargets
 ====================}
function TTargets.GetNode(index: integer): TTargetNode;
begin
    Result := TTargetNode(Self[index]);
end;

procedure TTargets.ClearObjects;
var
   i, total: integer;
begin
   total := Count - 1;
   for i := 0 to total do TTargetNode(Self[i]).Free;
   Clear;
end;

destructor TTargets.Destroy;
begin
   ClearObjects;
   inherited Destroy;
end;

end.

