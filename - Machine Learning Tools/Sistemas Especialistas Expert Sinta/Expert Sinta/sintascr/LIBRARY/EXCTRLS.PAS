{========================================================
 * Expert SINTA Visual Component Library *

 Module name: ExCtrls.pas
 Abstract:
    Conjunto de controles de auxílio à criação de um
    programa que consulta uma base de conhecimento
    criada com o Expert SINTA.
 Componentes: TConsultTree, TExpertPrompt, TRuleView,
              TValuesGrid, TLabelQuestion, TDebugPanel,
              TExNavigator, TWatchPanel, TAllVars
 Implementação: Ricardo Bezerra
 Data de início: 08 de março de 1997
 Data de término: 18 de março de 1997
 Última modificação: 10 de dezembro de 1997
 Expert SINTA (c) 1995-1997 Grupo SINTA/LIA
 ========================================================}
unit ExCtrls;

interface

uses
   {$IFDEF WIN32}
      ComCtrls, 
   {$ENDIF}
   {$IFDEF WINDOWS}
      Outline,
   {$ENDIF}
   Wintypes, Winprocs, Classes, Forms, StdCtrls, ExtCtrls, Graphics,
   Messages, Buttons, Grids, Controls, Menus, ExDataSt, ExSystem;

const

   DEFAULT_ITEMTOP = 8; {Topo do primeiro item do menu de opções TExPrompt}
   DEFAULT_ITEMLEFT = 5; {Topo do primeiro item do menu de opções TExPrompt}
   DEFAULT_NAVIGATOR_WIDTH = 23;
   DEFAULT_NAVIGATOR_HEIGHT = 21;

   ASKING_USER_ABOUT = 'Perguntando ao usuário sobre ';
   USER_ANSWER = 'Resposta do usuário: ';
   WITH_STRING = 'com';
   THE_RULE_STRING = 'A regra ';
   WAS_ACCEPTED = ' foi aceita:';
   WAS_REJECTED = ' foi rejeitada.';
   EVALUATING_STRING = 'Avaliando ';
   SEARCHING_STRING = 'Procurando ';
   ENTERING_RULE = 'Entrando na regra ';
   VERIFYING_IF = 'Verificando se ';
   IS_FALSE_STRING = ' é falso';
   COMPARING_STRING = 'Comparando ';
   RULE_STRING = 'REGRA ';
   VALUE_STRING = 'Valor';
   ENTRY_ERROR = 'Há um erro na entrada número ';
   INVALID_CNF_ENTRY = 'Grau de confiança inválido na entrada ';
   INVALID_NUMERIC_VALUE = 'Valor numérico inválido!';
   BELOW_MIN_VALUE = 'O valor não pode ser inferior ao mínimo!';
   BEYOND_MAX_VALUE = 'O valor não pode exceder o máximo!';
   WHAT_IS_THE_VALUE_OF = 'Qual o valor de ';
   BTNGO_HINT = 'Iniciar|Inicia uma consulta ao sistema especialista.';
   BTNBACK_HINT = 'Voltar pergunta|Volta à pergunta anterior.';
   BTNSTEP_HINT = 'Passo|Executa a base passo a passo.';
   BTNPAUSE_HINT = 'Pausa|Interrompe a execução da base de conhecimentos.';
   BTNSTOP_HINT = 'Parar|Aborta a execução da base de conhecimentos.';
   VARIABLES_STRING = 'Variáveis';
   VALUES_STRING = 'Valores';
   BASE_NOT_RUNNING = 'A base não está no modo de execução.';

   {$IFDEF WINDOWS}
   InitRepeatPause = 400;  { pause before repeat timer (ms) }
   RepeatPause     = 100;  { pause before hint window displays (ms)}
   {$ENDIF}

type

   {$IFDEF WINDOWS} {Controles *somente* para Windows 3.1}

   TTimerSpeedButton = class;

   { TSpinButton }

   TSpinButton = class (TWinControl)
   private
     FUpButton: TTimerSpeedButton;
     FDownButton: TTimerSpeedButton;
     FFocusedButton: TTimerSpeedButton;
     FFocusControl: TWinControl;
     FOnUpClick: TNotifyEvent;
     FOnDownClick: TNotifyEvent;
     function CreateButton: TTimerSpeedButton;
     function GetUpGlyph: TBitmap;
     function GetDownGlyph: TBitmap;
     procedure SetUpGlyph(Value: TBitmap);
     procedure SetDownGlyph(Value: TBitmap);
     procedure BtnClick(Sender: TObject);
     procedure BtnMouseDown (Sender: TObject; Button: TMouseButton;
               Shift: TShiftState; X, Y: Integer);
     procedure SetFocusBtn (Btn: TTimerSpeedButton);
     procedure AdjustSize (var W: Integer; var H: Integer);
     procedure WMSize(var Message: TWMSize);  message WM_SIZE;
     procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
     procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
     procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
   protected
     procedure Loaded; override;
     procedure KeyDown(var Key: Word; Shift: TShiftState); override;
   public
     constructor Create(AOwner: TComponent);
     procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
   published
     property Align;
     property Ctl3D;
     property DragCursor;
     property DragMode;
     property DownGlyph: TBitmap read GetDownGlyph write SetDownGlyph;
     property Enabled;
     property FocusControl: TWinControl read FFocusControl write FFocusControl;
     property ParentCtl3D;
     property ParentShowHint;
     property PopupMenu;
     property ShowHint;
     property TabOrder;
     property TabStop;
     property Visible;
     property OnDownClick: TNotifyEvent read FOnDownClick write FOnDownClick;
     property OnDragDrop;
     property OnDragOver;
     property OnEndDrag;
     property OnEnter;
     property OnExit;
     property OnUpClick: TNotifyEvent read FOnUpClick write FOnUpClick;
     property UpGlyph: TBitmap read GetUpGlyph write SetUpGlyph;
   end;

   { TSpinEdit }

   TSpinEdit = class(TCustomEdit)
   private
     FMinValue: single;
     FMaxValue: single;
     FCanvas: TCanvas;
     FIncrement: single;
     FButton: TSpinButton;
     FEditorEnabled: Boolean;
     function GetMinHeight: Integer;
     function GetValue: single;
     function CheckValue (NewValue: single): single;
     procedure SetValue (NewValue: single);
     procedure SetEditRect;
     procedure WMSize(var Message: TWMSize); message WM_SIZE;
     procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
     procedure CMExit(var Message: TCMExit);   message CM_EXIT;
     procedure WMPaste(var Message: TWMPaste);   message WM_PASTE;
     procedure WMCut(var Message: TWMCut);   message WM_CUT;
   protected
     function IsValidChar(Key: Char): Boolean; virtual;
     procedure UpClick (Sender: TObject); virtual;
     procedure DownClick (Sender: TObject); virtual;
     procedure KeyDown(var Key: Word; Shift: TShiftState); override;
     procedure KeyPress(var Key: Char); override;
     procedure CreateParams(var Params: TCreateParams); override;
     procedure CreateWnd; override;
   public
     constructor Create(AOwner: TComponent);
     destructor Destroy; override;
     property Button: TSpinButton read FButton;
   published
     property AutoSelect;
     property AutoSize;
     property Color;
     property Ctl3D;
     property DragCursor;
     property DragMode;
     property EditorEnabled: Boolean read FEditorEnabled write FEditorEnabled default True;
     property Enabled;
     property Font;
     property Increment: single read FIncrement write FIncrement {default 1.0};
     property MaxLength;
     property MaxValue: single read FMaxValue write FMaxValue;
     property MinValue: single read FMinValue write FMinValue;
     property ParentColor;
     property ParentCtl3D;
     property ParentFont;
     property ParentShowHint;
     property PopupMenu;
     property ReadOnly;
     property ShowHint;
     property TabOrder;
     property TabStop;
     property Value: single read GetValue write SetValue;
     property Visible;
     property OnChange;
     property OnClick;
     property OnDblClick;
     property OnDragDrop;
     property OnDragOver;
     property OnEndDrag;
     property OnEnter;
     property OnExit;
     property OnKeyDown;
     property OnKeyPress;
     property OnKeyUp;
     property OnMouseDown;
     property OnMouseMove;
     property OnMouseUp;
   end;

   { TTimerSpeedButton }

   TTimeBtnState = set of (tbFocusRect, tbAllowTimer);

   TTimerSpeedButton = class(TSpeedButton)
   private
     FRepeatTimer: TTimer;
     FTimeBtnState: TTimeBtnState;
     procedure TimerExpired(Sender: TObject);
   protected
     procedure Paint; override;
     procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
       X, Y: Integer); override;
     procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
       X, Y: Integer); override;
   public
     destructor Destroy; override;
     property TimeBtnState: TTimeBtnState read FTimeBtnState write FTimeBtnState;
   end;

   {Árvore com todas as decisões tomadas durante uma consulta}
   TConsultTree = class(TCustomOutLine)
   public
      constructor Create(AOwner: TComponent); override;
      procedure   CreateTree(ES: TExpertSystem);
      procedure   CreateFromTrail(ES: TExpertSystem; sub_trail: TQueue;
                  last_insert: integer; child: boolean);
   published
      property Font;
      property ParentColor;
      property ParentFont;
      property PopupMenu;
      property TabOrder;
      property TabStop;

      property OnClick;
      property OnDblClick;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnKeyDown;
      property OnKeyPress;
      property OnKeyUp;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
   end;

   {Exibe todos os valores de todas as variáveis}
   TAllVars = class(TCustomOutLine)
   public
      constructor Create(AOwner: TComponent); override; 
      procedure   CreateTree(ES: TExpertSystem);
   published
      property Font;
      property ParentColor;
      property ParentFont;
      property PopupMenu;
      property TabOrder;
      property TabStop;
   end;

   {$ELSE} {Controles *somente* para Windows 95/NT}

   TLimitedEdit = class(TEdit)
   private
     FMinValue: LongInt;
     FMaxValue: LongInt;
     procedure CMExit(var Message: TCMExit);   message CM_EXIT;
     function  GetValue: LongInt;
     function  CheckValue (NewValue: LongInt): LongInt;
     procedure SetValue (NewValue: LongInt);
   protected
     function  IsValidChar(Key: Char): Boolean; virtual;
     procedure KeyPress(var Key: Char); override;
   published
     property MaxValue: LongInt read FMaxValue write FMaxValue;
     property MinValue: LongInt read FMinValue write FMinValue;
     property Value: LongInt read GetValue write SetValue;
   end;

   TSpinEdit = class
   private
     FEdit: TLimitedEdit;
     FButton: TUpDown;
   protected
     function  GetParent: TWinControl;
     procedure SetParent(AParent: TWinControl);
     function  GetIncrement: LongInt;
     procedure SetIncrement(i: LongInt);
     function  GetMaxValue: smallint;
     procedure SetMaxValue(i: smallint);
     function  GetMinValue: smallint;
     procedure SetMinValue(i: smallint);
     function  GetWidth: integer;
     procedure SetWidth(i: integer);
     function  GetHeight: integer;
     procedure SetHeight(i: integer);
     function  GetLeft: integer;
     procedure SetLeft(i: integer);
     function  GetTop: integer;
     procedure SetTop(i: integer);
     function  GetFont: TFont;
     procedure SetFont(i: TFont);
     function  GetEnabled: boolean;
     procedure SetEnabled(i: boolean);
     function  GetVisible: boolean;
     procedure SetVisible(i: boolean);
     function  GetMaxLength: integer;
     procedure SetMaxLength(i: integer);
     function  GetText: string;
     procedure SetText(i: string);
   public
     constructor Create(AOwner: TComponent); 
     destructor  Destroy; override;
     property    Button: TUpDown read FButton;
     property    Width: integer read GetWidth write SetWidth;
     property    Height: integer read GetHeight write SetHeight;
     property    Top: integer read GetTop write SetTop;
     property    Left: integer read GetLeft write SetLeft;
   published
     property Increment: LongInt read GetIncrement write SetIncrement default 1;
     property MaxValue: smallint read GetMaxValue write SetMaxValue default 100;
     property MinValue: smallint read GetMinValue write SetMinValue default 0;
     property Parent: TWinControl read GetParent write SetParent;
     property Font: TFont read GetFont write SetFont;
     property Enabled: boolean read GetEnabled write SetEnabled;
     property Text: string read GetText write SetText;
     property MaxLength: integer read GetMaxLength write SetMaxLength;
     property Visible: boolean read GetVisible write SetVisible;
   end;

   TConsultTree = class(TCustomTreeView)
   private
      InternalImageList: TImageList;
   public
      constructor Create(AOwner: TComponent); override;
      procedure   CreateTree(ES: TExpertSystem);
      procedure   CreateFromTrail(ES: TExpertSystem; sub_trail: TQueue;
                  last_insert: TTreeNode; child: boolean);
      procedure   Clear;
   published
      property Align;
      property BorderStyle;
      property Color;
      property Ctl3D;
      property DragCursor;
      property DragMode;
      property Enabled;
      property Font;
      property HideSelection;
      property ParentColor;
      property ParentCtl3D;
      property ParentFont;
      property ParentShowHint;
      property PopUpMenu;
      property ReadOnly default false;
      property ShowButtons;
      property ShowHint;
      property ShowLines;
      property ShowRoot;
      property TabOrder;
      property TabStop;
      property OnChange;
      property OnChanging;
      property OnClick;
      property OnCollapsed;
      property OnCollapsing;
      property OnCompare;
      property OnDblClick;
      property OnDeletion;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnExpanded;
      property OnExpanding;
      property OnGetImageIndex;
      property OnGetSelectedIndex;
      property OnKeyDown;
      property OnKeyPress;
      property OnKeyUp;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnStartDrag;
   end;

   TAllVars = class(TCustomTreeView)
   private
      InternalImageList: TImageList;
      procedure Expanded(Sender: TObject; Node: TTreeNode);
      procedure Collapsed(Sender: TObject; Node: TTreeNode);
   public
      constructor Create(AOwner: TComponent); override;
      procedure   CreateTree(ES: TExpertSystem);
   published
      property Align;
      property BorderStyle;
      property Color;
      property Ctl3D;
      property DragCursor;
      property DragMode;
      property Enabled;
      property Font;
      property HideSelection;
      property Items;
      property ParentColor;
      property ParentCtl3D;
      property ParentFont;
      property ParentShowHint;
      property PopUpMenu;
      property ReadOnly default false;
      property ShowButtons;
      property ShowHint;
      property ShowLines;
      property ShowRoot;
      property TabOrder;
      property TabStop;
      property OnChange;
      property OnChanging;
      property OnClick;
      property OnCollapsed;
      property OnCollapsing;
      property OnCompare;
      property OnDblClick;
      property OnDeletion;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnExpanded;
      property OnExpanding;
      property OnGetImageIndex;
      property OnGetSelectedIndex;
      property OnKeyDown;
      property OnKeyPress;
      property OnKeyUp;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnStartDrag;
   end;

   {$ENDIF}

   TRuleViewInterface = class(TExCtrlInterface)
   public
     procedure Clear; override;
     procedure RefreshLink(Sender: TExpertSystem); override;
     procedure DestroyLink; override;
   end;

   TCustomRuleView = class(TCustomListBox)
   protected
     RuleViewInterface: TExCtrlInterface;
     FExpertSystem: TExpertSystem;
     code_rule, pos_rule: integer;
     FUseFilter: boolean;
     sentence, str_val: string;
     procedure SetExpertSystem(ES: TExpertSystem); virtual;
     procedure CreateInterface; virtual;
     procedure DrawItem(Index: Integer; Rect: TRect;
               State: TOwnerDrawState); override;
     function  RuleOk(code: integer): boolean;
   public
     HeadFilter: TSingleIndexTree;
     constructor Create(AOwner: TComponent); override;
     destructor  Destroy; override;
     procedure   FillRules; virtual;
   published
     property ExpertSystem: TExpertSystem
              read FExpertSystem write SetExpertSystem;
   public
     procedure SetHorizontalBar;
   end;

   TRuleView = class(TCustomRuleView)
   published
     property UseFilter: boolean read FUseFilter write FUseFilter default false;
     property Align;
     property BorderStyle;
     property Color;
     property Ctl3D;
     property DragCursor;
     property DragMode;
     property Enabled;
     property ExtendedSelect;
     property Font;
     property IntegralHeight;
     property ItemHeight default 13;
     property MultiSelect;
     property ParentColor;
     property ParentCtl3D;
     property ParentFont;
     property ParentShowHint;
     property PopupMenu;
     property ShowHint;
     property TabOrder;
     property TabStop;
     property Visible;
     property OnClick;
     property OnDblClick;
     property OnDragDrop;
     property OnDragOver;
     property OnEndDrag;
     property OnEnter;
     property OnExit;
     property OnKeyDown;
     property OnKeyPress;
     property OnKeyUp;
     property OnMouseDown;
     property OnMouseMove;
     property OnMouseUp;
     {$IFDEF WIN32}
        property TabWidth;
        property OnStartDrag;
     {$ENDIF}
   end;

   TValuesGridInterface = class(TExCtrlInterface)
     public
       procedure Clear; override;
       procedure RefreshLink(Sender: TExpertSystem); override;
       procedure DestroyLink; override;
   end;

   TValuesGrid = class(TStringGrid)
   private
     ValuesGridInterface: TValuesGridInterface;
     {Precisa dizer?}
     FExpertSystem: TExpertSystem;
     {Variável cujos valores serão exibidos no grid}
     FVarCode: integer;
     {Existe alguma variável atribuída ao grid?}
     VarLoaded: boolean;
     {Lista dos valores exibidos}
     ValuesList: TStringList;
     {Lista dos valores de confiança de cada valor}
     CnfsList: TStringList;
     Orders: TStringList;
     {Indica se os valores devem ser atualizados instantaneamente}
     FAutomaticUpdate: boolean;
     procedure LoadVar;
     procedure SetExpertSystem(ES: TExpertSystem); 
     procedure SetVarCode(v: integer);
     procedure SetAutomaticUpdate(au: boolean);
     procedure ClearValuesGrid;
   public
     constructor Create(AOwner: TComponent); override;
     destructor  Destroy; override;
     procedure   RefreshValues;
   published
     property ExpertSystem: TExpertSystem
              read FExpertSystem write SetExpertSystem;
     property VarCode: integer read FVarCode write SetVarCode{ default 0};
     property AutomaticUpdate: boolean read FAutomaticUpdate write SetAutomaticUpdate
              default false;
     property BorderStyle;
     property Color;
     property DefaultColWidth;
     property DefaultDrawing;
     property DefaultRowHeight default 18;
     property GridLineWidth;
     property Options;
     property ParentColor;
     property ScrollBars;
   end;

   {EditBox para entrada de CNFs}
   TTxtCnf = class(TSpinEdit)
      constructor Create(AOwner: TComponent);
   end;

   {CheckBox para escolha de valores em uma pergunta}
   TVarOption = class(TCheckBox)
     MyCnf: TTxtCnf;
     procedure Click; override;
   end;

   {ScrollBar para entrada de valores numéricos dentro de um intervalo}
  {$IFDEF WIN32}
    TScrollValue = class(TTrackBar)
  {$ELSE}
    TScrollValue = class(TScrollBar)
  {$ENDIF}
    protected
      procedure ScrollChange(Sender: TObject);
    public
      constructor Create(AOwner: TComponent); override;
    end;

   TExpertPromptInterface = class(TExCtrlInterface)
    public
      procedure Clear; override;
      procedure RefreshLink(Sender: TExpertSystem); override;
      procedure DestroyLink; override;
   end;

   {Menu de opções para responder uma pergunta}
   TExpertPrompt = class(TScrollBox)
   private
      ExpertPromptInterface: TExpertPromptInterface;
      FVarCode: integer;
      FExpertSystem: TExpertSystem;
      FShowErrorMessages: boolean;
      FMaxHeight, FMaxWidth: integer;
      FMinHeight, FMinWidth: integer;
      FAutoSize: boolean;
      {Guarda se a variável FVarCode é multivalorada ou não, numérica ou não}
      VarMulti, VarNumeric: boolean;
      {Scrollbar que permite a entrada de um valor numérico}
      scrollValue: TScrollValue;
      {Lista de checkboxes para marcar}
      ListOfItems: TStringList;
      {Lista de spinedits para entrar cnfs}
      ListOfCnfs: TStringList;
      labelValue: TLabel;
      {Painéis que exibem os valores máximo e mínimo que uma variável
       numérica pode assumir}
      panelMin: TPanel;
      panelMax: TPanel;
      {Total atual de opções dinâmicas apresentadas. Útil para acelerar
       exibição de opções quando este componente muda de variável
       diversas vezes, aproveitando as checkboxes já existentes.}
      LastNumberOfOptionsUsed: integer;
      {Indica que o controle deve se autoajustar caso ele sofra
       redimensionamento}
      ActiveResize: boolean;
      procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
      procedure DisableOthers(t: TVarOption);
      procedure HideNumericControls;
      procedure HideTextControls;
      procedure SetExpertSystem(ES: TExpertSystem);
      procedure SetVarCode(vc: integer);
      procedure SetAutoSize(asize: boolean);
   protected
      procedure ArrangeTextOptions;
      procedure ArrangeNumericOptions;
      procedure MakeTextOptions;
      procedure MakeNumOptions;
   public
      {EditBox para entrar um valor numérico}
      editValue:  TEdit;
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure   BuildOptions;
      procedure   ArrangeOptions;
      procedure   ClearCNFs;
      function    UpdateBase: boolean;
   published
      {Variável referente às opções exibidas}
      property VarCode: integer read FVarCode write SetVarCode;
      {Mostra mensagens de erro em entradas inválidas?}
      property ShowErrorMessages:boolean read FShowErrorMessages write FShowErrorMessages
                                         default true;
      {Precisa dizer?}
      property ExpertSystem: TExpertSystem read FExpertSystem write SetExpertSystem;
      {Especifica tamanhos em caso de "AutoSize = true"}
      property MaxHeight: integer read FMaxHeight write FMaxHeight default 300;
      property MaxWidth: integer read FMaxWidth write FMaxWidth default 400;
      property MinHeight: integer read FMinHeight write FMinHeight default 0;
      property MinWidth: integer read FMinWidth write FMinWidth default 0;
      property AutoSize: boolean read FAutoSize write SetAutoSize default false;
      {property ItemFont: TFont read FItemFont write SetItemFont;}
   end;

   TLabelQuestionInterface = class(TExCtrlInterface)
   public
      procedure Clear; override;
      procedure RefreshLink(Sender: TExpertSystem); override;
      procedure DestroyLink; override;
   end;

   {Label exibindo uma pergunta}
   TLabelQuestion = class(TCustomLabel)
   private
      LabelQuestionInterface: TLabelQuestionInterface;
      FVarCode: integer;
      FExpertSystem: TExpertSystem;
      procedure SetExpertSystem(ES: TExpertSystem);
      procedure SetVarCode(vc: integer);
   public
      constructor Create(AOwner: TComponent); override;
      procedure   BuildCaption;
      destructor  Destroy; override;
   published
      {Variável referente à pergunta exibida}
      property VarCode: integer read FVarCode write SetVarCode;
      {Precisa dizer?}
      property ExpertSystem: TExpertSystem read FExpertSystem write SetExpertSystem;
      property Align;
      property Alignment;
      property AutoSize;
      property Caption;
      property Color;
      property DragCursor;
      property DragMode;
      property Enabled;
      property FocusControl;
      property Font;
      property ParentColor;
      property ParentFont;
      property ParentShowHint;
      property PopupMenu;
      property ShowAccelChar;
      property ShowHint;
      property Transparent;
      property Visible;
      property WordWrap;
      property OnClick;
      property OnDblClick;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      {$IFDEF WIN32}
      property OnStartDrag;
      {$ENDIF}
   end;

   {Depurador, exibe regras e muda de status à medida que passos
    são executados}

   TDebugPanelInterface = class(TExDebugInterface)
   protected
     function  GetActiveTrace: boolean; override;
     procedure SetActiveTrace(ac: boolean); override;
   public
     procedure Activate; override;
     procedure Update(rule: integer; order: integer; is_tail: boolean); override;
     procedure Clear; override;
     procedure RefreshLink(Sender: TExpertSystem); override;
     procedure DestroyLink; override;
   end;

   TDebugPanel = class(TCustomRuleView)
   private
      current_line: integer;
      tails_trace, heads_trace: THelpContexts;
   protected
      procedure Click; override;
      procedure SetExpertSystem(ES: TExpertSystem); override;
      procedure CreateInterface; override;
   public
      ActiveTrace: boolean;
      destructor Destroy; override;
      procedure  Activate;
      procedure  FillRules; override;
      procedure  Update(rule: integer; order: integer; is_tail: boolean);
   published
      property Align;
      property BorderStyle;
      property Color;
      property Ctl3D;
      property DragCursor;
      property DragMode;
      property Enabled;
      property ExtendedSelect;
      property Font;
      property IntegralHeight;
      property ItemHeight default 13;
      property MultiSelect;
      property ParentColor;
      property ParentCtl3D;
      property ParentFont;
      property ParentShowHint;
      property PopupMenu;
      property ShowHint;
      property TabOrder;
      property TabStop;
      property Visible;
      property OnClick;
      property OnDblClick;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnKeyDown;
      property OnKeyPress;
      property OnKeyUp;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      {$IFDEF WIN32}
         property TabWidth;
         property OnStartDrag;
      {$ENDIF}
   end;

   TNavigatorVisibleButton = (nbGo, nbBack, nbStep, nbPause, nbStop);

   TNavigatorVisibleButtons = set of TNavigatorVisibleButton;

   TNavigatorInterface = class(TExCtrlInterface)
     public
       procedure Clear; override;
       procedure RefreshLink(Sender: TExpertSystem); override;
       procedure DestroyLink; override;
   end;

   TExNavigator = class(TCustomPanel)
   private
      NavigatorInterface: TNavigatorInterface;
      FExpertSystem: TExpertSystem;
      FVisibleButtons: TNavigatorVisibleButtons;
      TotalButtons: integer;
      listVisibleButtons: TList;
      procedure ArrangeButtons;
      procedure Click(Sender: TObject);
      procedure SetExpertSystem(ES: TExpertSystem);
      procedure SetVisibleButtons(vb: TNavigatorVisibleButtons);
      procedure WMSize(var Message: TWMSize); message WM_SIZE;
   public
      btnGo, btnPause, btnBack, btnStop, btnStep: TSpeedButton;
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure   DisableAll;
      procedure   UpdateButtons;
      procedure   SetDefaults;
   published
      property ExpertSystem: TExpertSystem read FExpertSystem write SetExpertSystem;
      property VisibleButtons: TNavigatorVisibleButtons
                               read FVisibleButtons write SetVisibleButtons
                               default [nbGo, nbBack, nbStep, nbPause, nbStop];
      property Align;
      property BevelInner;
      property BevelOuter;
      property BevelWidth;
      property BorderWidth;
      property BorderStyle;
      property DragCursor;
      property DragMode;
      property Enabled;
      property Color;
      property Ctl3D;
      property Locked;
      property ParentColor;
      property ParentCtl3D;
      property PopupMenu;
      property TabOrder;
      property TabStop;
      property Visible;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnResize;
      {$IFDEF WIN32}
      property OnStartDrag;
      {$ENDIF}
   end;

   TWatchPanelInterface = class(TExCtrlInterface)
    public
      procedure Clear; override;
      procedure RefreshLink(Sender: TExpertSystem); override;
      procedure DestroyLink; override;
   end;

   TWatchPanel = class(TCustomPanel)
   private
      WatchPanelInterface: TWatchPanelInterface;
      FExpertSystem: TExpertSystem;
      FAddAll: boolean;
      FValuesListHeight: integer;
      procedure listVarsClick(Sender: TObject);
      procedure SetAddAll(a: boolean);
      procedure SetExpertSystem(ES: TExpertSystem);
      function  GetValuesListHeight: integer;
      procedure SetValuesListHeight(h: integer);
      procedure WMSize(var Message: TWMSize);  message WM_SIZE;
      procedure EKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
   protected
      procedure KeyDown(var Key: Word; Shift: TShiftState); override;
   public
      WatchedVars: TSingleIndexTree;
      listVars: TListBox;
      listValues: TListBox;
      labelVars: TLabel;
      labelValues: TLabel;
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure   AddNewItem(v: integer);
      procedure   Clear;
      procedure   DeleteItem(v: integer; name: string);
      procedure   FillVars;
      procedure   Update; override;
   published
      property AddAll: boolean read FAddAll write SetAddAll default true;
      property ExpertSystem: TExpertSystem read FExpertSystem write SetExpertSystem;
      property ValuesListHeight: integer read GetValuesListHeight write SetValuesListHeight;
      property Align;
      property BevelInner;
      property BevelOuter;
      property BevelWidth;
      property BorderWidth;
      property BorderStyle;
      property DragCursor;
      property DragMode;
      property Enabled;
      property Color;
      property Ctl3D;
      property Font;
      property Locked;
      property ParentColor;
      property ParentCtl3D;
      property PopupMenu;
      property TabOrder;
      property TabStop;
      property Visible;
      property OnClick;
      property OnDblClick;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnResize;
      {$IFDEF WIN32}
      property OnStartDrag;
      {$ENDIF}
   end;

implementation

uses
   SysUtils, Dialogs, ExConsts;

{$IFDEF WIN32}
   {$R EXSYS32.RES}
{$ELSE}
   {$R EXSYS16.RES}
{$ENDIF}

function Max(a: integer; b: integer): integer;
begin
   if a >= b then
      Result := a
   else
      Result := b;
end;

function Min(a: integer; b: integer): integer;
begin
   if a <= b then
      Result := a
   else
      Result := b;
end;

{$IFDEF WINDOWS}

function MyFloatToStr(r: single): string;
begin
   Result := FloatToStrF(r, ffGeneral, 5, 2);
end;

{======================================================================
 ======================================================================
                        CLASSE TSPINBUTTON (16-BIT)
 ======================================================================
 ======================================================================}

constructor TSpinButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls, csSetCaption] +
    [csFramed, csOpaque];

  FUpButton := CreateButton;
  FDownButton := CreateButton;
  UpGlyph := nil;
  DownGlyph := nil;

  Width := 20;
  Height := 25;
  FFocusedButton := FUpButton;
end;

function TSpinButton.CreateButton: TTimerSpeedButton;
begin
  Result := TTimerSpeedButton.Create (Self);
  Result.OnClick := BtnClick;
  Result.OnMouseDown := BtnMouseDown;
  Result.Visible := True;
  Result.Enabled := True;
  Result.TimeBtnState := [tbAllowTimer];
  Result.NumGlyphs := 1;
  Result.Parent := Self;
end;

procedure TSpinButton.AdjustSize (var W: Integer; var H: Integer);
var
  Y: Integer;
begin
  if (FUpButton = nil) or (csLoading in ComponentState) then Exit;
  if W < 15 then W := 15;
  FUpButton.SetBounds (0, 0, W, H div 2);
  FDownButton.SetBounds (0, FUpButton.Height - 1, W, H - FUpButton.Height + 1);
end;

procedure TSpinButton.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  W, H: Integer;
begin
  W := AWidth;
  H := AHeight;
  AdjustSize (W, H);
  inherited SetBounds (ALeft, ATop, W, H);
end;

procedure TSpinButton.WMSize(var Message: TWMSize);
var
  W, H: Integer;
begin
  inherited;

  { check for minimum size }
  W := Width;
  H := Height;
  AdjustSize (W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds(Left, Top, W, H);
  Message.Result := 0;
end;

procedure TSpinButton.WMSetFocus(var Message: TWMSetFocus);
begin
  FFocusedButton.TimeBtnState := FFocusedButton.TimeBtnState + [tbFocusRect];
  FFocusedButton.Invalidate;
end;

procedure TSpinButton.WMKillFocus(var Message: TWMKillFocus);
begin
  FFocusedButton.TimeBtnState := FFocusedButton.TimeBtnState - [tbFocusRect];
  FFocusedButton.Invalidate;
end;

procedure TSpinButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_UP:
      begin
        SetFocusBtn (FUpButton);
        FUpButton.Click;
      end;
    VK_DOWN:
      begin
        SetFocusBtn (FDownButton);
        FDownButton.Click;
      end;
    VK_SPACE:
      FFocusedButton.Click;
  end;
end;

procedure TSpinButton.BtnMouseDown (Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    SetFocusBtn (TTimerSpeedButton (Sender));
    if (FFocusControl <> nil) and FFocusControl.TabStop and 
        FFocusControl.CanFocus and (GetFocus <> FFocusControl.Handle) then
      FFocusControl.SetFocus
    else if TabStop and (GetFocus <> Handle) and CanFocus then
      SetFocus;
  end;
end;

procedure TSpinButton.BtnClick(Sender: TObject);
begin
  if Sender = FUpButton then
  begin
    if Assigned(FOnUpClick) then FOnUpClick(Self);
  end
  else
    if Assigned(FOnDownClick) then FOnDownClick(Self);
end;

procedure TSpinButton.SetFocusBtn (Btn: TTimerSpeedButton);
begin
  if TabStop and CanFocus and  (Btn <> FFocusedButton) then
  begin
    FFocusedButton.TimeBtnState := FFocusedButton.TimeBtnState - [tbFocusRect];
    FFocusedButton := Btn;
    if (GetFocus = Handle) then 
    begin
       FFocusedButton.TimeBtnState := FFocusedButton.TimeBtnState + [tbFocusRect];
       Invalidate;
    end;
  end;
end;

procedure TSpinButton.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TSpinButton.Loaded;
var
  W, H: Integer;
begin
  inherited Loaded;
  W := Width;
  H := Height;
  AdjustSize (W, H);
  if (W <> Width) or (H <> Height) then
    inherited SetBounds (Left, Top, W, H);
end;

function TSpinButton.GetUpGlyph: TBitmap;
begin
  Result := FUpButton.Glyph;
end;

procedure TSpinButton.SetUpGlyph(Value: TBitmap);
begin
  if Value <> nil then
    FUpButton.Glyph := Value
  else
  begin
    FUpButton.Glyph.Handle := LoadBitmap(HInstance, 'MY_SPINUP');
    FUpButton.NumGlyphs := 1;
    FUpButton.Invalidate;
  end;
end;

function TSpinButton.GetDownGlyph: TBitmap;
begin
  Result := FDownButton.Glyph;
end;

procedure TSpinButton.SetDownGlyph(Value: TBitmap);
begin
  if Value <> nil then
    FDownButton.Glyph := Value
  else
  begin
    FDownButton.Glyph.Handle := LoadBitmap(HInstance, 'MY_SPINDOWN');
    FDownButton.NumGlyphs := 1;
    FDownButton.Invalidate;
  end;
end;

{======================================================================
 ======================================================================
                        CLASSE TSPINEDIT (16-BIT)
 ======================================================================
 ======================================================================}

constructor TSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FButton := TSpinButton.Create (Self);
  FButton.Width := 15;
  FButton.Height := 17;
  FButton.Visible := True;
  FButton.Parent := Self;
  FButton.FocusControl := Self;
  FButton.OnUpClick := UpClick;
  FButton.OnDownClick := DownClick;
  Text := '';
  ControlStyle := ControlStyle - [csSetCaption];
  FIncrement := 1;
  FEditorEnabled := True;
end;

destructor TSpinEdit.Destroy;
begin
  FButton := nil;
  inherited Destroy;
end;

procedure TSpinEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then UpClick (Self)
  else if Key = VK_DOWN then DownClick (Self);
  inherited KeyDown(Key, Shift);
end;

procedure TSpinEdit.KeyPress(var Key: Char);
begin
  if not IsValidChar(Key) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
  if Key <> #0 then inherited KeyPress(Key);
end;

function TSpinEdit.IsValidChar(Key: Char): Boolean;
begin
  Result := (Key in [DecimalSeparator, '+', '-', '0'..'9']) or
    ((Key < #32) {and (Key <> Chr(VK_RETURN))});
  if not FEditorEnabled and Result and ((Key >= #32) or
      (Key = Char(VK_BACK)) or (Key = Char(VK_DELETE))) then
    Result := False;
end;

procedure TSpinEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
{  Params.Style := Params.Style and not WS_BORDER;  }
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
end;

procedure TSpinEdit.CreateWnd;
var
  Loc: TRect;
begin
  inherited CreateWnd;
  SetEditRect;
end;

procedure TSpinEdit.SetEditRect;
var
  Loc: TRect;
begin
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));
  Loc.Bottom := ClientHeight;
  Loc.Right := ClientWidth - FButton.Width - 2;
  Loc.Top := 0;  
  Loc.Left := 0;  
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@Loc));
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));  {debug}
end;

procedure TSpinEdit.WMSize(var Message: TWMSize);
var
  Loc: TRect;
  MinHeight: Integer;
begin
  inherited;
  MinHeight := GetMinHeight;
    { text edit bug: if size to less than minheight, then edit ctrl does
      not display the text }
  if Height < MinHeight then   
    Height := MinHeight
  else if FButton <> nil then
  begin
    FButton.SetBounds (Width - FButton.Width, 0, FButton.Width, Height);
    SetEditRect;
  end;
end;

function TSpinEdit.GetMinHeight: Integer;
var
  DC: HDC;
  SaveFont: HFont;
  I: Integer;
  SysMetrics, Metrics: TTextMetric;
begin
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > Metrics.tmHeight then I := Metrics.tmHeight;
  Result := Metrics.tmHeight + I div 4 + GetSystemMetrics(SM_CYBORDER) * 4 + 2;
end;

procedure TSpinEdit.UpClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := Value + FIncrement;
end;

procedure TSpinEdit.DownClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := Value - FIncrement;
end;

procedure TSpinEdit.WMPaste(var Message: TWMPaste);   
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TSpinEdit.WMCut(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TSpinEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  if CheckValue (Value) <> Value then
     SetValue (Value);
end;

function TSpinEdit.GetValue: single;
begin
  try
    Result := StrToFloat (Text);
  except
    Result := FMinValue;
  end;
end;

procedure TSpinEdit.SetValue (NewValue: single);
begin
  Text := MyFloatToStr (CheckValue (NewValue));
end;

function TSpinEdit.CheckValue (NewValue: single): single;
begin
  Result := NewValue;
  if (FMaxValue <> FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else if NewValue > FMaxValue then
      Result := FMaxValue;
  end;
end;

procedure TSpinEdit.CMEnter(var Message: TCMGotFocus);
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;

{======================================================================
 ======================================================================
                      CLASSE TTIMERSPEEDBUTTON (16-BIT)
 ======================================================================
 ======================================================================}

destructor TTimerSpeedButton.Destroy;
begin
  if FRepeatTimer <> nil then
    FRepeatTimer.Free;
  inherited Destroy;
end;

procedure TTimerSpeedButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown (Button, Shift, X, Y);
  if tbAllowTimer in FTimeBtnState then
  begin
    if FRepeatTimer = nil then
      FRepeatTimer := TTimer.Create(Self);

    FRepeatTimer.OnTimer := TimerExpired;
    FRepeatTimer.Interval := InitRepeatPause;
    FRepeatTimer.Enabled  := True;
  end;
end;

procedure TTimerSpeedButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
                                  X, Y: Integer);
begin
  inherited MouseUp (Button, Shift, X, Y);
  if FRepeatTimer <> nil then
    FRepeatTimer.Enabled  := False;
end;

procedure TTimerSpeedButton.TimerExpired(Sender: TObject);
begin
  FRepeatTimer.Interval := RepeatPause;
  if (FState = bsDown) and MouseCapture then
  begin
    try
      Click;
    except
      FRepeatTimer.Enabled := False;
      raise;
    end;
  end;
end;

procedure TTimerSpeedButton.Paint;
var
  R: TRect;
begin
  inherited Paint;
  if tbFocusRect in FTimeBtnState then
  begin
    R := Bounds(0, 0, Width, Height);
    InflateRect(R, -3, -3);
    if FState = bsDown then
      OffsetRect(R, 1, 1);
    DrawFocusRect(Canvas.Handle, R);
  end;
end;

{======================================================================
 ======================================================================
                     CLASSE TCONSULTTREE (16-BIT)
 ======================================================================
 ======================================================================}

constructor TConsultTree.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   OutlineStyle := osTreePictureText;
   Style := otOwnerDraw;
   ItemHeight := 16;
   Options := [ooDrawTreeRoot];
   PictureLeaf.Handle := LoadBitmap(hInstance, 'STEP');
   PictureClosed.Handle := LoadBitmap(hInstance, 'ZOOMIN');
   PictureOpen.Handle := LoadBitmap(hInstance, 'ZOOMOUT');
end;

procedure TConsultTree.CreateTree(ES: TExpertSystem);
begin
   CreateFromTrail(ES, ES.Trail, 0, false);
end;

procedure TConsultTree.CreateFromTrail(ES: TExpertSystem; sub_trail: TQueue;
          last_insert: integer; child: boolean);
var
   i, aux: integer;
   level: TIntegerStack;
   the_value: string;

   procedure CreateEvaluationSubTree;
   var
      evaluation_trail: TQueue;
      old_last_insert: integer;
      BookmarkVars, BookmarkValues,
      BookmarkHeads, BookmarkRules: TMetaNode;
      start_eval_cont, end_eval_cont: integer;
   begin
      BookmarkVars := ES.Vars.CurrentNode;
      BookmarkValues := ES.Values.CurrentNode;
      BookmarkHeads := ES.Heads.CurrentNode;
      BookmarkRules := ES.Rules.CurrentNode;
      evaluation_trail := TQueue.Create;
      sub_trail.Delete;
      sub_trail.Delete;
      start_eval_cont := 1;
      end_eval_cont := 0;
      while start_eval_cont <> end_eval_cont do begin
         if sub_trail.code = START_EVALUATION then inc(start_eval_cont);
         if sub_trail.code = END_EVALUATION then inc(end_eval_cont);
         if start_eval_cont <> end_eval_cont then begin
            evaluation_trail.Insert(sub_trail.code);
            sub_trail.Delete;
            evaluation_trail.Insert(sub_trail.code);
         end
         else
            sub_trail.Delete; {Simplesmente ignora o último par}
         sub_trail.Delete;
      end;
      if evaluation_trail.RecordCount > 0 then begin
         old_last_insert := last_insert;
         CreateFromTrail(ES, evaluation_trail, last_insert, true);
         last_insert := old_last_insert;
      end;
      evaluation_trail.Free;
      ES.Vars.CurrentNode := BookmarkVars;
      ES.Values.CurrentNode := BookmarkValues;
      ES.Heads.CurrentNode := BookmarkHeads;
      ES.Rules.CurrentNode := BookmarkRules;
   end;

begin
 if not ES.CanView then Exit;
 level := TIntegerStack.Create;
 with ES do begin
   while not sub_trail.Blind do begin
      case sub_trail.code of
        QUESTION: {Uma pergunta foi feita}
          begin
           sub_trail.Delete;
           Vars.Seek(sub_trail.code);
           if child then begin
              last_insert := AddChild(last_insert,
                             ASKING_USER_ABOUT + Vars.name + ' ...');
              child := false;
           end
           else
              last_insert := Add(last_insert,
                             ASKING_USER_ABOUT + Vars.name + ' ...');
           varList.Seek(sub_trail.code);
           {Mostra as respostas dadas pelo usuário}
           if not varList.Blind then begin
              while (not varList.Blind) and (varList.code = sub_trail.code) do begin
                 if child then begin
                    last_insert := AddChild(last_insert,
                                   USER_ANSWER + RealValue(varList.ValCode)
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varList.cnf) + '%');
                    child := false;
                 end
                 else
                    last_insert := Add(last_insert,
                                   USER_ANSWER + RealValue(varList.ValCode)
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varList.cnf) + '%');
                 varList.MoveNext;
              end;
           end
           else begin
              varListExtra.Seek(sub_trail.code);
              while (not varListExtra.Blind) and (varListExtra.code = sub_trail.code) do begin
                 if child then begin
                    last_insert := AddChild(last_insert,
                                   USER_ANSWER + varListExtra.Value
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varListExtra.cnf) + '%');
                    child := false;
                 end
                 else
                    last_insert := Add(last_insert,
                                   USER_ANSWER + varListExtra.Value
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varListExtra.cnf) + '%');
                 varListExtra.MoveNext;
              end;
           end;
           sub_trail.Delete;
          end;
        RULE_OK: {Uma regra foi aceita}
          begin
           sub_trail.Delete;
           Rules.Seek(sub_trail.code);
           last_insert := Add(last_insert,
                          THE_RULE_STRING + IntToStr(Rules.Position) +
                          WAS_ACCEPTED);
           child := true;
           Heads.Seek(sub_trail.code);
           sub_trail.Delete;
           while (not Heads.Blind) and (Heads.Code = Rules.Code) do begin
               Vars.Seek(Heads.VarCode);
               if Vars.Numeric then begin
                  the_value := FloatToStr(CalcResult(Heads.ValCode));
                  if ES.UnknownVar then the_value := UNKNOWN_STRING;
               end
               else
                  the_value := RealValue(Heads.ValCode);
               if child then begin
                  if Vars.Numeric then begin
                     last_insert := AddChild(last_insert,
                        EVALUATING_STRING + Vars.name + ' = ' + Formulas.name);
                     CreateEvaluationSubTree;
                     last_insert := Add(last_insert,
                         Vars.name + ' = ' + the_value);
                  end
                  else
                     last_insert := AddChild(last_insert,
                         Vars.name + ' = ' + the_value);
                  child := false;
               end
               else begin
                  if Vars.Numeric then begin
                     last_insert := Add(last_insert,
                        EVALUATING_STRING + Vars.name + ' = ' + Formulas.name);
                     CreateEvaluationSubTree;
                  end;
                  last_insert := Add(last_insert,
                      Vars.name + ' = ' + the_value);
               end;
               Heads.MoveNext;
           end;
           child := false;
           last_insert := level.Pop;
          end;
        RULE_FAILED: {Uma regra foi rejeitada}
          begin
           sub_trail.Delete;
           Rules.Seek(sub_trail.code);
           if child then
              last_insert := AddChild(last_insert,
                             THE_RULE_STRING + IntToStr(Rules.Position) +
                             WAS_REJECTED)
           else
              last_insert := Add(last_insert,
                             THE_RULE_STRING +  + IntToStr(Rules.Position) +
                             WAS_REJECTED);
           sub_trail.Delete;
           child := false;
           last_insert := level.Pop;
          end;
        SEARCHING: {Avisa que uma determinada variável está sendo procurada}
          begin
           sub_trail.Delete;
           Vars.Seek(sub_trail.code);
           if child then begin
              last_insert := AddChild(last_insert,
                             SEARCHING_STRING + Vars.name + ' ...');
           end
           else
              last_insert := Add(last_insert,
                             SEARCHING_STRING + Vars.name + ' ...');
           sub_trail.Delete;
           child := false;
          end;
        RULE_EXECUTED, ATTRIB_UNKNOWN:
          begin
             sub_trail.Delete;
             sub_trail.Delete;
          end;
        else  {Ou seja, é uma comparação em uma regra}
          begin
           aux := sub_trail.code;
           sub_trail.Delete;
           if sub_trail.code = 1 then begin
              Rules.Seek(aux);
              if child then
                 last_insert := AddChild(last_insert,
                                ENTERING_RULE + IntToStr(Rules.Position) + ' ...')
              else
                 last_insert := Add(last_insert,
                                ENTERING_RULE + IntToStr(Rules.Position) + ' ...');
              child := true;
              level.Push(last_insert);
           end;
           Tails.Seek(aux);
           for i := 2 to sub_trail.code do Tails.MoveNext;
           Vars.Seek(Tails.VarCode);
           if child then begin
              if Tails.Neg then
                 last_insert := AddChild(last_insert,
                                VERIFYING_IF + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode) + IS_FALSE_STRING)
              else
                 last_insert := AddChild(last_insert,
                                COMPARING_STRING + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode));
              child := false;
           end
           else begin
              if Tails.Neg then
                 last_insert := AddChild(last_insert,
                                VERIFYING_IF + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode) + IS_FALSE_STRING)
              else
                 last_insert := Add(last_insert,
                                COMPARING_STRING + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode));
           end;
           sub_trail.Delete;
          end;
      end;
   end;
 end;
 level.Free;
 FullExpand;
end;

{======================================================================
 ======================================================================
                     CLASSE TALLVARS (16-BIT)
 ======================================================================
 ======================================================================}

constructor TAllVars.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   OutlineStyle := osTreePictureText;
   Style := otOwnerDraw;
   ItemHeight := 19;
   Options := [ooDrawTreeRoot];
   PictureLeaf.Handle := LoadBitmap(hInstance, 'VARLEAF');
   PictureClosed.Handle := LoadBitmap(hInstance, 'VARCLOSED');
   PictureOpen.Handle := LoadBitmap(hInstance, 'VAROPENED');
end;

procedure TAllVars.CreateTree(ES: TExpertSystem);
var
   pos: integer;
   aux: integer;
   inserted: boolean;
begin
   if (not ES.EmptyBase) and (ES.ExecutionMode) and (ES.CanView) then begin
      with ES do begin
         BookmarkVar;
         Vars.CurrentKey := BY_NAME;
         Vars.MoveFirst;
         pos := 0;
         Clear;
         while not Vars.Blind do begin
            inserted := false;
            varList.Seek(Vars.code);
            if not varList.Blind then begin
               pos := Add(pos, Vars.name);
               inserted := true;
               aux := AddChild(pos,
                   RealValue(varList.ValCode) + ' (' +
                   MyFloatToStr(varList.cnf * 100) + '%)');
               varList.MoveNext;
               while (not varList.Blind) and
                  (varList.code = Vars.code) do begin
                  aux := Add(aux, RealValue(varList.ValCode) + ' (' +
                         MyFloatToStr(varList.cnf * 100) + '%)');
                 varList.MoveNext;
               end;
            end;
            varListExtra.Seek(Vars.code);
            if not varListExtra.Blind then begin
               if not inserted then pos := Add(pos, Vars.name);
               aux := AddChild(pos, varListExtra.Value +
                      ' (' + MyFloatToStr(varListExtra.cnf * 100) + '%)');
               varListExtra.MoveNext;
               while (not varListExtra.Blind) and (varListExtra.code = Vars.code)
               do begin
                   aux := Add(aux, varListExtra.Value +
                          ' (' + MyFloatToStr(varListExtra.cnf * 100) + '%)');
                   varListExtra.MoveNext;
               end;
            end;
            Vars.MoveNext;
         end;
         RestoreVarFromBookmark;
      end;
      FullCollapse;
   end
   else
      Clear;
end;

{$ELSE}

(*********************************************************************)
(*********************************************************************)

{======================================================================
 ======================================================================
                        CLASSE TLIMITEDEDIT (32-BIT)
 ======================================================================
 ======================================================================}
function TLimitedEdit.IsValidChar(Key: Char): Boolean;
begin
  Result := (Key in [DecimalSeparator, '+', '-', '0'..'9']) or
    ((Key < #32) and (Key <> Chr(VK_RETURN)));
end;

procedure TLimitedEdit.KeyPress(var Key: Char);
begin
  if not IsValidChar(Key) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
  if Key <> #0 then inherited KeyPress(Key);
end;

procedure TLimitedEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  if CheckValue (Value) <> Value then
     SetValue (Value);
end;

function TLimitedEdit.GetValue: LongInt;
begin
  try
    Result := StrToInt (Text);
  except
    Result := FMinValue;
  end;
end;

procedure TLimitedEdit.SetValue (NewValue: LongInt);
begin
  Text := IntToStr (CheckValue (NewValue));
end;

function TLimitedEdit.CheckValue (NewValue: LongInt): LongInt;
begin
  Result := NewValue;
  if (FMaxValue <> FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else if NewValue > FMaxValue then
      Result := FMaxValue;
  end;
end;

{======================================================================
 ======================================================================
                         CLASSE TSPINEDIT (32-BIT)
 ======================================================================
 ======================================================================}
constructor TSpinEdit.Create(AOwner: TComponent);
begin
  FEdit := TLimitedEdit.Create(nil);
  FButton := TUpDown.Create(nil);
  FEdit.MinValue := 0;
  FEdit.MaxValue := 100;
end;

destructor TSpinEdit.Destroy;
begin
   FEdit.Free;
   FButton.Free;
   inherited Destroy;
end;

function TSpinEdit.GetParent: TWinControl;
begin
   Result := FEdit.Parent;
end;

procedure TSpinEdit.SetParent(AParent: TWinControl);
var
   old_text: string;
begin
   old_text := Text;
   FEdit.Parent := AParent;
   FButton.Parent := AParent;
   if AParent <> nil then FButton.Associate := FEdit;
   Text := old_text;
   {Não me pergunte por que preciso restaurar o texto,
    talvez seja um problema com TUpDown}
end;

function TSpinEdit.GetIncrement: LongInt;
begin
   Result := FButton.Increment;
end;

procedure TSpinEdit.SetIncrement(i: LongInt);
begin
   FButton.Increment := i;
end;

function TSpinEdit.GetMaxValue: smallint;
begin
   Result := FButton.Max;
end;

procedure TSpinEdit.SetMaxValue(i: smallint);
begin
   FButton.Max := i;
   FEdit.MaxValue := i;
end;

function TSpinEdit.GetMinValue: smallint;
begin
   Result := FButton.Min;
end;

procedure TSpinEdit.SetMinValue(i: smallint);
begin
   FButton.Min := i;
   FEdit.MinValue := i;
end;

function TSpinEdit.GetWidth: integer;
begin
   Result := FEdit.Width + FButton.Width;
end;

procedure TSpinEdit.SetWidth(i: integer);
var
   old_text: string;
begin
   old_text := Text;
   FEdit.Width := i - FButton.Width;
   if FButton.Parent <> nil then FButton.Associate := FEdit;
   Text := old_text;
end;

function TSpinEdit.GetHeight: integer;
begin
   Result := FEdit.Height;
end;

procedure TSpinEdit.SetHeight(i: integer);
var
   old_text: string;
begin
   old_text := Text;
   FEdit.Height := i;
   if FButton.Parent <> nil then FButton.Associate := FEdit;
   Text := old_text;
end;

function TSpinEdit.GetLeft: integer;
begin
   Result := FEdit.Left;
end;

procedure TSpinEdit.SetLeft(i: integer);
var
   old_text: string;
begin
   old_text := Text;
   FEdit.Left := i;
   if FButton.Parent <> nil then FButton.Associate := FEdit;
   Text := old_text;
end;

function TSpinEdit.GetTop: integer;
begin
   Result := FEdit.Top;
end;

procedure TSpinEdit.SetTop(i: integer);
var
   old_text: string;
begin
   old_text := Text;
   FEdit.Top := i;
   if FButton.Parent <> nil then FButton.Associate := FEdit;
   Text := old_text;
end;

function TSpinEdit.GetFont: TFont;
begin
   Result := FEdit.Font;
end;

procedure TSpinEdit.SetFont(i: TFont);
begin
   FEdit.Font.Assign(i);
end;

function TSpinEdit.GetEnabled: boolean;
begin
   Result := FEdit.Enabled;
end;

procedure TSpinEdit.SetEnabled(i: boolean);
begin
   FEdit.Enabled := i;
   FButton.Enabled := i;
end;

function TSpinEdit.GetVisible: boolean;
begin
   Result := FEdit.Visible;
end;

procedure TSpinEdit.SetVisible(i: boolean);
var
   old_text: string;
begin
   old_text := Text;
   if FButton.Parent <> nil then FButton.Associate := FEdit;
   FEdit.Visible := i;
   FButton.Visible := i;
   FEdit.Text := '';
   Text := old_text;
end;

function TSpinEdit.GetMaxLength: integer;
begin
   Result := FEdit.MaxLength;
end;

procedure TSpinEdit.SetMaxLength(i: integer);
begin
   FEdit.MaxLength := i;
end;

function TSpinEdit.GetText: string;
begin
   Result := FEdit.Text;
end;

procedure TSpinEdit.SetText(i: string);
begin
   FEdit.Text := i;
end;

{======================================================================
 ======================================================================
                     CLASSE TCONSULTTREE (32-BIT)
 ======================================================================
 ======================================================================}

constructor TConsultTree.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   InternalImageList := TImageList.Create(Self);
   InternalImageList.ShareImages := false;
   InternalImageList.ResourceLoad(rtBitmap, 'TREEBITMAPS', clOlive);
   Images := InternalImageList;
   ReadOnly := true;
end;

procedure TConsultTree.CreateTree(ES: TExpertSystem);
begin
   CreateFromTrail(ES, ES.Trail, nil, false);
end;

procedure TConsultTree.CreateFromTrail(ES: TExpertSystem; sub_trail: TQueue;
          last_insert: TTreeNode; child: boolean);
var
   i, aux: integer;
   level: TStack;
   the_value: string;

   procedure CreateEvaluationSubTree;
   var
      evaluation_trail: TQueue;
      old_last_insert: TTreeNode;
      BookmarkVars, BookmarkValues,
      BookmarkHeads, BookmarkRules: TMetaNode;
      start_eval_cont, end_eval_cont: integer;
   begin
      BookmarkVars := ES.Vars.CurrentNode;
      BookmarkValues := ES.Values.CurrentNode;
      BookmarkHeads := ES.Heads.CurrentNode;
      BookmarkRules := ES.Rules.CurrentNode;
      evaluation_trail := TQueue.Create;
      sub_trail.Delete;
      sub_trail.Delete;
      start_eval_cont := 1;
      end_eval_cont := 0;
      while start_eval_cont <> end_eval_cont do begin
         if sub_trail.code = START_EVALUATION then inc(start_eval_cont);
         if sub_trail.code = END_EVALUATION then inc(end_eval_cont);
         if start_eval_cont <> end_eval_cont then begin
            evaluation_trail.Insert(sub_trail.code);
            sub_trail.Delete;
            evaluation_trail.Insert(sub_trail.code);
         end
         else
            sub_trail.Delete; {Simplesmente ignora o último par}
         sub_trail.Delete;
      end;
      if evaluation_trail.RecordCount > 0 then begin
         last_insert.ImageIndex := 1;
         last_insert.SelectedIndex := 1;
         old_last_insert := last_insert;
         CreateFromTrail(ES, evaluation_trail, last_insert, true);
         last_insert := old_last_insert;
      end;
      evaluation_trail.Free;
      ES.Vars.CurrentNode := BookmarkVars;
      ES.Values.CurrentNode := BookmarkValues;
      ES.Heads.CurrentNode := BookmarkHeads;
      ES.Rules.CurrentNode := BookmarkRules;
   end;

begin
 if not ES.CanView then Exit;
 level := TStack.Create;
 with ES do begin
   while not sub_trail.Blind do begin
      case sub_trail.code of
        QUESTION: {Uma pergunta foi feita}
          begin
           sub_trail.Delete;
           Vars.Seek(sub_trail.code);
           if child then begin
              last_insert := Items.AddChild(last_insert,
                             ASKING_USER_ABOUT + Vars.name + ' ...');
              child := false;
           end
           else
              last_insert := Items.Add(last_insert,
                             ASKING_USER_ABOUT + Vars.name + ' ...');
           last_insert.ImageIndex := 0;
           last_insert.SelectedIndex := 0;
           varList.Seek(sub_trail.code);
           {Mostra as respostas dadas pelo usuário}
           if not varList.Blind then begin
              while (not varList.Blind) and (varList.code = sub_trail.code) do begin
                 if child then begin
                    last_insert := Items.AddChild(last_insert,
                                   USER_ANSWER + RealValue(varList.ValCode)
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varList.cnf) + '%');
                    child := false;
                 end
                 else
                    last_insert := Items.Add(last_insert,
                                   USER_ANSWER + RealValue(varList.ValCode)
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varList.cnf) + '%');
                 last_insert.ImageIndex := 0;
                 last_insert.SelectedIndex := 0;
                 varList.MoveNext;
              end;
           end
           else begin
              varListExtra.Seek(sub_trail.code);
              while (not varListExtra.Blind) and (varListExtra.code = sub_trail.code) do begin
                 if child then begin
                    last_insert := Items.AddChild(last_insert,
                                   'Resposta do usuário:  ' + varListExtra.Value
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varListExtra.cnf) + '%');
                    child := false;
                 end
                 else
                    last_insert := Items.Add(last_insert,
                                   'Resposta do usuário:  ' + varListExtra.Value
                                   + ', ' + WITH_STRING + ' ' +
                                   MyFloatToStr(100 * varListExtra.cnf) + '%');
                 varListExtra.MoveNext;
                 last_insert.ImageIndex := 0;
                 last_insert.SelectedIndex := 0;
              end;
           end;
           sub_trail.Delete;
          end;
        RULE_OK: {Uma regra foi aceita}
          begin
           sub_trail.Delete;
           Rules.Seek(sub_trail.code);
           last_insert := Items.Add(last_insert,
                          THE_RULE_STRING + IntToStr(Rules.Position) + WAS_ACCEPTED);
           last_insert.ImageIndex := 1;
           last_insert.SelectedIndex := 1;
           child := true;
           Heads.Seek(sub_trail.code);
           sub_trail.Delete;
           while (not Heads.Blind) and (Heads.Code = Rules.Code) do begin
               Vars.Seek(Heads.VarCode);
               if Vars.Numeric then begin
                  the_value := FloatToStr(CalcResult(Heads.ValCode));
                  if ES.UnknownVar then the_value := UNKNOWN_STRING;
               end
               else
                  the_value := RealValue(Heads.ValCode);
               if child then begin
                  if Vars.Numeric then begin
                     last_insert := Items.AddChild(last_insert,
                        EVALUATING_STRING + Vars.name + ' = ' + Formulas.name);
                     CreateEvaluationSubTree;
                     last_insert := Items.Add(last_insert,
                         Vars.name + ' = ' + the_value);
                     last_insert.ImageIndex := 0;
                     last_insert.SelectedIndex := 0;
                  end
                  else
                     last_insert := Items.AddChild(last_insert,
                         Vars.name + ' = ' + the_value);
                  child := false;
               end
               else begin
                  if Vars.Numeric then begin
                     last_insert := Items.Add(last_insert,
                        EVALUATING_STRING + Vars.name + ' = ' + Formulas.name);
                     CreateEvaluationSubTree;
                  end;
                  last_insert := Items.Add(last_insert,
                      Vars.name + ' = ' + the_value);
               end;
               last_insert.ImageIndex := 0;
               last_insert.SelectedIndex := 0;
               Heads.MoveNext;
           end;
           child := false;
           last_insert := TTreeNode(level.Pop);
          end;
        RULE_FAILED: {Uma regra foi rejeitada}
          begin
           sub_trail.Delete;
           Rules.Seek(sub_trail.code);
           if child then
              last_insert := Items.AddChild(last_insert,
                             THE_RULE_STRING + IntToStr(Rules.Position) + WAS_REJECTED)
           else
              last_insert := Items.Add(last_insert,
                             THE_RULE_STRING + IntToStr(Rules.Position) + WAS_REJECTED);
           last_insert.ImageIndex := 0;
           last_insert.SelectedIndex := 0;
           sub_trail.Delete;
           child := false;
           last_insert := TTreeNode(level.Pop);
          end;
        SEARCHING: {Avisa que uma determinada variável está sendo procurada}
          begin
           sub_trail.Delete;
           Vars.Seek(sub_trail.code);
           if child then begin
              last_insert := Items.AddChild(last_insert,
                             SEARCHING_STRING + Vars.name + ' ...');
           end
           else
              last_insert := Items.Add(last_insert,
                             SEARCHING_STRING + Vars.name + ' ...');
           last_insert.ImageIndex := 0;
           last_insert.SelectedIndex := 0;
           sub_trail.Delete;
           child := false;
          end;
        RULE_EXECUTED, ATTRIB_UNKNOWN:
          begin
             sub_trail.Delete;
             sub_trail.Delete;
          end;
        else  {Ou seja, é uma comparação em uma regra}
          begin
           aux := sub_trail.code;
           sub_trail.Delete;
           if sub_trail.code = 1 then begin
              Rules.Seek(aux);
              if child then
                 last_insert := Items.AddChild(last_insert,
                                ENTERING_RULE + IntToStr(Rules.Position) + ' ...')
              else
                 last_insert := Items.Add(last_insert,
                                ENTERING_RULE + IntToStr(Rules.Position) + ' ...');

              last_insert.ImageIndex := 1;
              last_insert.SelectedIndex := 1;
              child := true;
              level.Push(last_insert);
           end;
           Tails.Seek(aux);
           for i := 2 to sub_trail.code do Tails.MoveNext;
           Vars.Seek(Tails.VarCode);
           if child then begin
              if Tails.Neg then
                 last_insert := Items.AddChild(last_insert,
                                VERIFYING_IF + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode) + IS_FALSE_STRING)
              else
                 last_insert := Items.AddChild(last_insert,
                                COMPARING_STRING + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode));
              last_insert.ImageIndex := 0;
              last_insert.SelectedIndex := 0;
              child := false;
           end
           else begin
              if Tails.Neg then
                 last_insert := Items.AddChild(last_insert,
                                VERIFYING_IF + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode) + IS_FALSE_STRING)
              else
                 last_insert := Items.Add(last_insert,
                                COMPARING_STRING + Vars.name + ' ' + Tails.Operator +  ' ' +
                                RealValue(Tails.ValCode));
              last_insert.ImageIndex := 0;
              last_insert.SelectedIndex := 0;
           end;
           sub_trail.Delete;
          end;
      end;
   end;
 end;
 level.Free;
 FullExpand;
 if Items.Count > 0 then Selected := Items[0];
end;

procedure TConsultTree.Clear;
begin
   Items.Clear;
end;

{======================================================================
 ======================================================================
                     CLASSE TALLVARS (32-BIT)
 ======================================================================
 ======================================================================}

constructor TAllVars.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   InternalImageList := TImageList.Create(Self);
   InternalImageList.ShareImages := false;
   InternalImageList.ResourceLoad(rtBitmap, 'ALLVARSBITMAPS', clOlive);
   Images := InternalImageList;
   ReadOnly := true;
   OnCollapsed := Collapsed;
   OnExpanded := Expanded;
end;

procedure TAllVars.Expanded(Sender: TObject; Node: TTreeNode);
begin
   Node.ImageIndex := 1;
   Node.SelectedIndex := 1;
end;

procedure TAllVars.Collapsed(Sender: TObject; Node: TTreeNode);
begin
   Node.ImageIndex := 0;
   Node.SelectedIndex := 0;
end;

procedure TAllVars.CreateTree(ES: TExpertSystem);
var
   pos, aux: TTreeNode;
   inserted: boolean;
begin
   if (not ES.EmptyBase) and (ES.ExecutionMode) and (ES.CanView) then begin
      with ES do begin
         BookmarkVar;
         Vars.CurrentKey := BY_NAME;
         Vars.MoveFirst;
         Items.Clear;
         pos := nil;
         while not Vars.Blind do begin
            inserted := false;
            varList.Seek(Vars.code);
            if not varList.Blind then begin
               pos := Items.Add(pos, Vars.name);
               pos.ImageIndex := 0;
               pos.SelectedIndex := 0;
               inserted := true;
               aux := Items.AddChild(pos,
                      RealValue(varList.ValCode) + ' (' +
                      MyFloatToStr(varList.cnf * 100) + '%)');
               aux.ImageIndex := 2;
               aux.SelectedIndex := 2;
               varList.MoveNext;
               while (not varList.Blind) and
                  (varList.code = Vars.code) do begin
                  aux := Items.Add(aux, RealValue(varList.ValCode) + ' (' +
                         MyFloatToStr(varList.cnf * 100) + '%)');
                  aux.ImageIndex := 2;
                  aux.SelectedIndex := 2;
                  varList.MoveNext;
               end;
            end;
            varListExtra.Seek(Vars.code);
            if not varListExtra.Blind then begin
               if not inserted then begin
                  pos := Items.Add(pos, Vars.name);
                  pos.ImageIndex := 0;
                  pos.SelectedIndex := 0;
               end;
               aux := Items.AddChild(pos, varListExtra.Value +
                      ' (' + MyFloatToStr(varListExtra.cnf * 100) + '%)');
               aux.ImageIndex := 2;
               aux.SelectedIndex := 2;
               varListExtra.MoveNext;
               while (not varListExtra.Blind) and (varListExtra.code = Vars.code)
               do begin
                   aux := Items.Add(aux, varListExtra.Value +
                          ' (' + MyFloatToStr(varListExtra.cnf * 100) + '%)');
                   aux.ImageIndex := 2;
                   aux.SelectedIndex := 2;
                   varListExtra.MoveNext;
               end;
            end;
            Vars.MoveNext;
         end;
         RestoreVarFromBookmark;
      end;
      FullCollapse;
      if Items.Count > 0 then Selected := Items[0];
   end
   else
      Items.Clear;
end;

{$ENDIF}

(*********************************************************************)
(*********************************************************************)

{======================================================================
 ======================================================================
                          CLASSE TRULEVIEW
 ======================================================================
 ======================================================================}

constructor TCustomRuleView.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   CreateInterface;
   Style := lbOwnerDrawFixed;
   ItemHeight := 13;
   FUseFilter := false;
   HeadFilter := TSingleIndexTree.Create;
end;

destructor TCustomRuleView.Destroy;
begin
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(RuleViewInterface);
   HeadFilter.Free;
   RuleViewInterface.Free;
   inherited Destroy;
end;

procedure TCustomRuleView.CreateInterface;
begin
   RuleViewInterface := TRuleViewInterface.Create(I_KB_VIEW, Self);
end;

procedure TCustomRuleView.SetHorizontalBar;
begin
   {Habilita a barra horizontal}
   SendMessage(Handle, LB_SetHorizontalExtent, 1000, Longint(0));
end;

procedure TCustomRuleView.DrawItem(Index: Integer; Rect: TRect;
                          State: TOwnerDrawState);
var
  if_length: integer;
begin
  Canvas.FillRect(Rect);
  if_length := length(IF_STRING);
  if (ExpertSystem.IsConect(Copy(Items[Index], 1, DEFAULT_CONECT_LENGTH))
     or (Copy(Items[Index], 1, if_length) = IF_STRING))
     then begin
     if not (odSelected in State) then
        Canvas.Font.Color := clNavy
     else
        Canvas.Font.Color := clWhite;
     Canvas.TextOut(Rect.Left + DEFAULT_CONECT_LENGTH * Canvas.TextWidth('M'),
            Rect.Top, Copy(Items[Index], 1, DEFAULT_CONECT_LENGTH));
     if not (odSelected in State) then Canvas.Font.Color := clBlack;
     Canvas.TextOut(Rect.Left + (DEFAULT_CONECT_LENGTH + 5) * Canvas.TextWidth('M'),
            Rect.Top, Copy(Items[Index], DEFAULT_CONECT_LENGTH + 1, Length(Items[Index])));
  end
  else begin
     if (Copy(Items[Index], 1, 5) = '\ENT ') then begin
         if not (odSelected in State) then
            Canvas.Font.Color := clNavy
         else
            Canvas.Font.Color := clWhite;
         Canvas.TextOut(Rect.Left + DEFAULT_CONECT_LENGTH * Canvas.TextWidth('M'),
                 Rect.Top, THEN_STRING);
         if not (odSelected in State) then Canvas.Font.Color := clBlack;
         Canvas.TextOut(Rect.Left + (DEFAULT_CONECT_LENGTH + 5) * Canvas.TextWidth('M'),
            Rect.Top, Copy(Items[Index], 6, Length(Items[Index])));
     end
     else begin
        if Copy(Items[Index], 1, 6) = '\ENT\ ' then begin
           if not (odSelected in State) then
              Canvas.Font.Color := clBlack
           else
              Canvas.Font.Color := clWhite;
           Canvas.TextOut(Rect.Left + (DEFAULT_CONECT_LENGTH + 5) * Canvas.TextWidth('M'),
           Rect.Top, Copy(Items[Index], 7, length(Items[Index])));
        end
        else begin
           if not (odSelected in State) then
              Canvas.Font.Color := clNavy
           else
              Canvas.Font.Color := clWhite;
           Canvas.TextOut(Rect.Left + Canvas.TextWidth('M'),
                           Rect.Top, Items[Index]);
        end;
     end;
  end;
end;

procedure TCustomRuleView.FillRules;
begin
  Clear;
  with FExpertSystem do begin
    if not EmptyBase then begin
       Rules.CurrentKey := BY_POSITION;
       Rules.MoveFirst;
       while not Rules.Blind do begin
           code_rule := Rules.Code;
           pos_rule := Rules.Position;
           if (not FUseFilter) or (FUseFilter and RuleOk(code_rule)) then begin
              Tails.Seek(code_rule);
              Heads.Seek(code_rule);
              Items.Add(RULE_STRING + IntToStr(pos_rule));
              Vars.Seek(Tails.VarCode);
              if Vars.Numeric then begin
                 Formulas.Seek(Tails.ValCode);
                 str_val := Formulas.name;
              end
              else
                 str_val := RealValue(Tails.ValCode);
              if Tails.Neg then
                 sentence := IF_STRING + ' ' + NOT_STRING + ' ' +
                             Vars.name + ' ' + Tails.Operator + ' ' + str_val
              else
                 sentence := IF_STRING + ' ' + Vars.name + ' ' +
                            Tails.Operator + ' ' + str_val;
              Items.Add(sentence);
              if Tails.Conect <> cnthen then
                 Items.Add(ConectName(Tails.Conect) + Space(DEFAULT_CONECT_LENGTH -
                                      length(ConectName(Tails.Conect))));
              Tails.MoveNext;
              while (not Tails.Blind) and (Tails.code = code_rule) do begin
                  if Tails.Neg then sentence := sentence + NOT_STRING + ' ';
                  Vars.Seek(Tails.VarCode);
                  if Vars.Numeric then begin
                     Formulas.Seek(Tails.ValCode);
                     str_val := Formulas.name;
                  end
                  else
                     str_val := RealValue(Tails.ValCode);
                 sentence := Vars.name + ' ' + Tails.Operator + ' ' + str_val;
                 Items[Items.Count - 1] := Items[Items.Count - 1] + sentence;
                 if Tails.Conect <> cnThen then
                    Items.Add(ConectName(Tails.Conect) + Space(DEFAULT_CONECT_LENGTH
                              - length(ConectName(Tails.Conect))));
                 Tails.MoveNext;
              end;

              Vars.Seek(Heads.VarCode);
              if Vars.Numeric then begin
                 Formulas.Seek(Heads.ValCode);
                 str_val := Formulas.name;
              end
              else
                 str_val := RealValue(Heads.ValCode);
              sentence := '\ENT ' + Vars.name + ' = ' + str_val +
                         ' CNF ' + MyFloatToStr(Heads.cnf * 100) + '%';
              Items.Add(sentence);
              Heads.MoveNext;
              while (not Heads.Blind) and (Heads.code = code_rule) do begin
                  Vars.Seek(Heads.VarCode);
                  if Vars.Numeric then begin
                     Formulas.Seek(Heads.ValCode);
                     str_val := Formulas.name;
                  end
                  else
                     str_val := RealValue(Heads.ValCode);
                  sentence := '\ENT\ ' + Vars.name + ' = ' + str_val +
                     ' CNF ' + MyFloatToStr(Heads.cnf * 100) + '%';
                  Items.Add(sentence);
                  Heads.MoveNext;
              end;
           end;
           Rules.MoveNext;
       end;
    end;
  end;
end;

{Essa função verifica se a regra possui uma das variáveis escolhidas pelo
 filtro}
function TCustomRuleView.RuleOk(code: integer): boolean;
var
   found: boolean;

   function HeadOk(t: TMetaNode; var found: boolean): boolean;
   begin
       HeadFilter.Seek((t.node as THeadNode).VarCode);
       found := not HeadFilter.Blind;
       Result := not HeadFilter.Blind;
   end;

begin
   found := false;
   FExpertSystem.Heads.Seek(code);
   while (not FExpertSystem.Heads.Blind) and
         (FExpertSystem.Heads.Code = code) and
         (not HeadOk(FExpertSystem.Heads.CurrentNode, found)) do
         FExpertSystem.Heads.MoveNext;
   Result := found;
end;

procedure TCustomRuleView.SetExpertSystem(ES: TExpertSystem);
begin
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(RuleViewInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      ES.AddControl(RuleViewInterface);
      if ES.CanView then
         FillRules
      else
         Clear;
   end
   else
      Clear;
end;

{======}

procedure TRuleViewInterface.Clear;
begin
   TCustomRuleView(OwnerControl).Clear;
end;

procedure TRuleViewInterface.RefreshLink(Sender: TExpertSystem);
begin
   TCustomRuleView(OwnerControl).FillRules;
end;

procedure TRuleViewInterface.DestroyLink;
begin
   TCustomRuleView(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                          CLASSE TVALUESGRID
 ======================================================================
 ======================================================================}
constructor TValuesGrid.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   ValuesGridInterface := TValuesGridInterface.Create(I_INSTANCE_VIEW, Self);
   FVarCode := 0;
   VarLoaded := false;
   DefaultRowHeight := 18;
   ValuesList := TStringList.Create;
   CnfsList := TStringList.Create;
   Orders := TStringList.Create;
   ClearValuesGrid;
end;

destructor TValuesGrid.Destroy;
begin
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(ValuesGridInterface);
   ValuesGridInterface.Free;
   ValuesList.Free;
   CnfsList.Free;
   Orders.Free;
   inherited Destroy;
end;

procedure TValuesGrid.SetAutomaticUpdate(au: boolean);
begin
   FAutomaticUpdate := au;
   if au then begin
      if FExpertSystem <> nil then
         FExpertSystem.AddControl(ValuesGridInterface);
      LoadVar;
      RefreshValues;
   end
   else begin
      if FExpertSystem <> nil then
         FExpertSystem.RemoveControl(ValuesGridInterface);
      ClearValuesGrid;
   end;
end;

procedure TValuesGrid.SetExpertSystem(ES: TExpertSystem);
begin
   ClearValuesGrid;
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(ValuesGridInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      if FAutomaticUpdate then begin
         ES.AddControl(ValuesGridInterface);
         RefreshValues;
      end;
   end
   else begin
      VarLoaded := false;
      ClearValuesGrid;
   end;
end;

procedure TValuesGrid.SetVarCode(v: integer);
begin
    FVarCode := v;
    if v = 0 then begin
       ClearValuesGrid;
       VarLoaded := false;
    end;
end;

procedure TValuesGrid.LoadVar;
var
    blind: boolean;
begin
   if (FExpertSystem <> nil) and (FVarCode <> 0) then begin
       if FExpertSystem.EmptyBase then
          VarLoaded := false
       else begin
          FExpertSystem.BookmarkVar;
          FExpertSystem.Vars.Seek(FVarCode);
          blind := FExpertSystem.Vars.Blind;
          FExpertSystem.RestoreVarFromBookmark;
          if blind then begin
             VarLoaded := false;
             ClearValuesGrid;
          end
          else begin
             VarLoaded := true;
             if FAutomaticUpdate then RefreshValues;
          end;
       end;
   end
   else
      VarLoaded := false;
end;

procedure TValuesGrid.RefreshValues;
var
   i: integer;
begin
   if not VarLoaded then LoadVar;
   if VarLoaded and FExpertSystem.ExecutionMode then begin
      ClearValuesGrid;
      FExpertSystem.VarInstances(FVarCode, ValuesList, CnfsList);
      RowCount := ValuesList.Count + 1;
      Cols[0].Strings[0] := VALUE_STRING;
      Cols[1].Strings[0] := 'CNF (%)';
      for i := 1 to ValuesList.Count do begin
         Cols[0].Strings[i] := ValuesList[i - 1];
         Cols[1].Strings[i] := CnfsList[i - 1];
      end;
   end;
end;

procedure TValuesGrid.ClearValuesGrid;
begin
   ColCount := 2;
   RowCount := 2;
   FixedCols := 0;
   FixedRows := 1;
   Cols[0].Clear;
   Cols[1].Clear;
end;

{======}

procedure TValuesGridInterface.Clear;
begin
   TValuesGrid(OwnerControl).RefreshValues;
end;

procedure TValuesGridInterface.RefreshLink(Sender: TExpertSystem);
begin
   TValuesGrid(OwnerControl).RefreshValues;
end;

procedure TValuesGridInterface.DestroyLink;
begin
   TValuesGrid(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                           CLASSE TTXTCNF
 ======================================================================
 ======================================================================}

constructor TTxtCnf.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   Font.Name := 'MS Sans Serif';
   Font.Size := 8;
   Font.Style := [fsBold];
   Increment := 10;
   Width := 50;
   Height := 20;
   MinValue := 0;
   MaxValue := 100;
   MaxLength := 4;
   Enabled := False;
   Text := '';
end;

{======================================================================
 ======================================================================
                          CLASSE TVAROPTION
 ======================================================================
 ======================================================================}

procedure TVarOption.Click;
begin
   inherited Click;
   if not Checked then begin
      MyCnf.Text := '';
      MyCnf.Enabled := False;
   end
   else
      if Checked then begin
         MyCnf.Enabled := true;
         MyCnf.Text := '100';
         if TExpertPrompt(Parent).VarMulti = False then
            TExpertPrompt(Parent).DisableOthers(Self);
      end;
end;

{======================================================================
 ======================================================================
                          CLASSE TSCROLLVALUE
 ======================================================================
 ======================================================================}
procedure TScrollValue.ScrollChange(Sender: TObject);
begin
   TExpertPrompt(Parent).editValue.Text := IntToStr(Position);
end;

constructor TScrollValue.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   {$IFDEF WIN32}
      Orientation := trHorizontal;
      Height := 45;
   {$ELSE}
      Kind := sbHorizontal;
      Height := 25;
   {$ENDIF}
   OnChange := ScrollChange;
end;

{======================================================================
 ======================================================================
                          CLASSE TEXPERTPROMPT
 ======================================================================
 ======================================================================}

constructor TExpertPrompt.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   ExpertPromptInterface := TExpertPromptInterface.Create(I_VARIABLE_VIEW, Self);
   ActiveResize := true;
   ListOfItems := TStringList.Create;
   ListOfCnfs := TStringList.Create;
   scrollValue := TScrollValue.Create(Self);
   scrollValue.Visible := false;
   editValue := TEdit.Create(Self);
   editValue.Visible := false;
   panelMin := TPanel.Create(Self);
   panelMin.Width := 78;
   panelMin.Height := 25;
   panelMin.Visible := false;
   panelMax := TPanel.Create(Self);
   panelMax.Width := 78;
   panelMax.Height := 25;
   panelMax.Visible := false;
   labelValue := TLabel.Create(Self);
   labelValue.Visible := false;
   labelValue.Caption := 'Valor:';
   LastNumberOfOptionsUsed := -1;
   FShowErrorMessages := true;
   FMaxHeight := 300;
   FMaxWidth := 400;
   FMinHeight := 0;
   FMinWidth := 0;
   FAutoSize := false;
   with Font do begin
      Name := 'MS Sans Serif';
      Size := 12;
      Style := [];
   end;
   {Conserta um bug do Delphi}
   if not (csDesigning in ComponentState) then begin
      editValue.Parent := Self;
      panelMin.Parent := Self;
      panelMax.Parent := Self;
      scrollValue.Parent := Self;
      labelValue.Parent := Self;
   end;
end;

destructor TExpertPrompt.Destroy;
var
   i, total: integer;
begin
   total := ListOfItems.Count - 1;
   for i := 0 To total do begin
      TVarOption(ListOfItems.Objects[i]).Free;
      TTxtCnf(ListOfCnfs.Objects[i]).Free;
   end;
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(ExpertPromptInterface);
   ExpertPromptInterface.Free;
   ListOfItems.Free;
   ListOfCnfs.Free;
   {FItemFont.Free;}
   inherited Destroy;
   {Os outros objetos são destruídos automaticamente pois sua propriedade
    'Owner' é o objeto em TExpertPrompt em si.
    Lembrar que TTxtCnf NÃO é um componente na versão 32 bit da
    Expert SINTA Visual Component Library, por isso tem que
    ser destruída explicitamente. TVarOption entrou na jogada só
    para enfeitar, pois não era necessária a destruição explícita}
end;

{Esse método inibe outras checkboxes se uma é marcada e a variável
 é univalorada}
procedure TExpertPrompt.DisableOthers(t: TVarOption);
var
   i, j: integer;
begin
   i := ListOfItems.Count - 1;
   for j := 0 to i do
      if (t <> TVarOption(ListOfItems.Objects[j])) and
         TVarOption(ListOfItems.Objects[j]).Checked then begin
         TVarOption(ListOfItems.Objects[j]).Checked := false;
         TVarOption(ListOfItems.Objects[j]).Click;
      end;
end;

procedure TExpertPrompt.HideTextControls;
var
   i: integer;
begin
   for i := 0 to LastNumberOfOptionsUsed do begin
       TVarOption(ListOfItems.Objects[i]).Visible := false;
       TTxtCnf(ListOfCnfs.Objects[i]).Visible := false;
       {Conserta um bug do Delphi}
       if csDesigning in ComponentState then begin
          TVarOption(ListOfItems.Objects[i]).Parent := nil;
          TTxtCnf(ListOfCnfs.Objects[i]).Parent := nil;
       end;
   end;
end;

procedure TExpertPrompt.HideNumericControls;
begin
   panelMin.Visible := false;
   panelMax.Visible := false;
   editValue.Visible := false;
   labelValue.Visible := false;
   scrollValue.Visible := false;
   {Conserta um bug do Delphi}
   if csDesigning in ComponentState then begin
      editValue.Parent := nil;
      panelMin.Parent := nil;
      panelMax.Parent := nil;
      scrollValue.Parent := nil;
      labelValue.Parent := nil;
   end;
end;

{Essa subrotina encarrega-se de encontrar os valores possíveis da
 variável corrente não-numérica ("var") e criar um menu de opções
 com os valores citados pelo desenvolvedor.}
procedure TExpertPrompt.MakeTextOptions;
var
   new_var: TVarOption;
   new_cnf: TTxtCnf;
   i, total_options: integer;
   ListOfValues: TStringList;
begin
   HideNumericControls;

   {Conserta um bug do Delphi}
   if csDesigning in ComponentState then
      for i := 0 to LastNumberOfOptionsUsed do begin
          TVarOption(ListOfItems.Objects[i]).Parent := Self;
          TTxtCnf(ListOfCnfs.Objects[i]).Parent := Self;
      end;

   for i := 0 to LastNumberOfOptionsUsed do begin
       TVarOption(ListOfItems.Objects[i]).Visible := false;
       TTxtCnf(ListOfCnfs.Objects[i]).Visible := false;
   end;

   ListOfValues := TStringList.Create;
   FExpertSystem.ValuesList(FVarCode, ListOfValues);
   total_options := ListOfValues.Count - 1;
   for i := 0 to total_options do begin
      if i <= LastNumberOfOptionsUsed then begin
         if ListOfValues.Objects[i] <> nil then
            ListOfItems[i] := IntToStr(TValNode(ListOfValues.Objects[i]).Code)
         else begin
            if i = 0 then
               ListOfItems[i] := IntToStr(YES)
            else
               ListOfItems[i] := IntToStr(NO);
         end;
         TVarOption(ListOfItems.Objects[i]).Caption := ListOfValues[i];
         TVarOption(ListOfItems.Objects[i]).Checked := False;
         TTxtCnf(ListOfCnfs.Objects[i]).Text := '';
      end
      else begin
         new_var := TVarOption.Create(Self);
         new_var.Parent := Self;
         new_var.Caption := ListOfValues[i];
         if ListOfValues.Objects[i] <> nil then
            ListOfItems.AddObject(IntToStr(TValNode(ListOfValues.Objects[i]).Code), new_var)
         else begin
            if i = 0 then
               ListOfItems.AddObject(IntToStr(YES), new_var)
            else
               ListOfItems.AddObject(IntToStr(NO), new_var)
         end;
         new_cnf := TTxtCnf.Create(Self);
         new_cnf.Visible := false;
         new_cnf.Parent := Self;
         new_cnf.Text := '';
         ListOfCnfs.AddObject('', new_cnf);
         new_var.MyCnf := new_cnf;
      end;
   end;

   for i := total_options + 1 to LastNumberOfOptionsUsed do begin
      TVarOption(ListOfItems.Objects[i]).Free;
      TTxtCnf(ListOfCnfs.Objects[i]).Free;
   end;
   for i := total_options + 1 to LastNumberOfOptionsUsed do begin
      ListOfItems.Delete(total_options + 1);
      ListOfCnfs.Delete(total_options + 1);
   end;

   LastNumberOfOptionsUsed := total_options;
   ArrangeTextOptions;
   ListOfValues.Free;
end;

procedure TExpertPrompt.ClearCNFs;
var
   i: integer;
begin
   for i := 0 to LastNumberOfOptionsUsed do
       TTxtCnf(ListOfCnfs.Objects[i]).Text := '';
end;

{Após a determinação dos itens que aparecerão nesse TExpertPrompt,
 precisamos posicioná-los corretamente, o que é feito por este método}
procedure TExpertPrompt.ArrangeTextOptions;
var
   i, total_options: integer;
   height_of_items: integer;
   Extent: TSize;
   device: HDC;
   max_option: string;
   max_length: integer;
   visible_cnf: boolean;
   extra_bar_width, border_size: integer;

   procedure InitAuxHDC;
   var
     text: string[255];
   begin
     text := 'DISPLAY' + #0;
     device := CreateDC(@text[1], nil, nil, nil);
     SelectObject(device, Font.Handle);
   end;

   procedure AutoResizeVarOption(op: TVarOption);
   var
      Text: string[255];
   begin
      Text := op.Caption;
      Text := Text + #0;
      {$IFDEF WIN32}
        GetTextExtentPoint32(device, @Text[1], Length(Text), Extent);
      {$ELSE}
        GetTextExtentPoint(device, @Text[1], Length(Text), Extent);
      {$ENDIF}
      op.Width := Extent.cX + 40;
      op.Height := Extent.cY;
      {ATENÇÃO: Colocar, no lugar de 40, o tamanho real da
       marca de uma checkbox!!!! - Não consegui encontrar em lugar
       algum, nem com GetSystemMetrics, como conseguir o tamanho de uma
       check box!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
      if op.Width > max_length then max_length := op.Width;
    end;

begin

   border_size := Height - ClientHeight; {Na falta de outro método...}

   total_options := LastNumberOfOptionsUsed;
   if total_options < 0 then Exit;

   max_option := '';
   max_length := 0;
   InitAuxHDC;

   for i := 0 to total_options do begin
      if length(TVarOption(ListOfItems.Objects[i]).Caption) >
         length(max_option) then
         max_option := TVarOption(ListOfItems.Objects[i]).Caption;
      AutoResizeVarOption(TVarOption(ListOfItems.Objects[i]));
      TVarOption(ListOfItems.Objects[i]).MyCnf.Height :=
                TVarOption(ListOfItems.Objects[i]).Height;
   end;

   height_of_items := 2 * DEFAULT_ITEMTOP +
                      trunc((total_options + 1) *
                            TVarOption(ListOfItems.Objects[0]).Height +
                            0.5 * (total_options) *
                            TVarOption(ListOfItems.Objects[0]).Height);

   if FAutoSize then begin
      Height := Min(FMaxHeight, height_of_items);
      if FMinHeight <> 0 then Height := Max(FMinHeight, Height);
      Width := Min(FMaxWidth,
                   max_length + TTxtCnf(ListOfCnfs.Objects[0]).Width +
                   2 * DEFAULT_ITEMLEFT + 3);
      if FMinWidth <> 0 then Width := Max(FMinWidth, Width);
   end;

   if Height - border_size < height_of_items then
      TVarOption(ListOfItems.Objects[0]).Top := DEFAULT_ITEMTOP
   else
      TVarOption(ListOfItems.Objects[0]).Top :=
                 trunc((Height - height_of_items) / 2) + DEFAULT_ITEMTOP;

   TTxtCnf(ListOfCnfs.Objects[0]).Top := TVarOption(ListOfItems.Objects[0]).Top;

   for i := 1 to total_options do begin
       TVarOption(ListOfItems.Objects[i]).Top :=
          TVarOption(ListOfItems.Objects[i - 1]).Top +
          trunc(1.5 * TVarOption(ListOfItems.Objects[i - 1]).Height);
       TTxtCnf(ListOfCnfs.Objects[i]).Top :=
               TVarOption(ListOfItems.Objects[i]).Top;
   end;

   {Pega a largura da scroll bar vertical, se existir.
    Observe que o melhor seria uma alternativa elegante capaz de descobrir
    se uma dada scrollbar está visível. Não consegui encontrar em
    nenhum lugar uma maneira de fazer isto (a propriedade Visible
    de uma TScrollBar serve apenas para saber se uma scrollbar PODE
    estar visível)}
   if TVarOption(ListOfItems.Objects[total_options]).Top +
      TVarOption(ListOfItems.Objects[total_options]).Height > Height - border_size
      then
      {$IFDEF WINDOWS}
        extra_bar_width := GetSystemMetrics(SM_CXHTHUMB)
      {$ELSE}
        extra_bar_width := GetSystemMetrics(SM_CXVSCROLL)
      {$ENDIF}
   else
       extra_bar_width := 0;

   for i := 0 to total_options do begin
       TVarOption(ListOfItems.Objects[i]).Left := DEFAULT_ITEMLEFT;
       TTxtCnf(ListOfCnfs.Objects[i]).Left :=
               Max(Width - TTxtCnf(ListOfCnfs.Objects[i]).Width -
                   4 - DEFAULT_ITEMLEFT - extra_bar_width,
                   max_length + DEFAULT_ITEMLEFT - extra_bar_width);
   end;
   FExpertSystem.BookmarkQuestion;
   FExpertSystem.Questions.Seek(FVarCode);
   visible_cnf := FExpertSystem.Questions.Blind or FExpertSystem.Questions.UseCNF;
   FExpertSystem.RestoreQuestionFromBookmark;
   for i := 0 to total_options do begin
      TVarOption(ListOfItems.Objects[i]).Visible := true;
      TTxtCnf(ListOfCnfs.Objects[i]).Visible := visible_cnf;
   end;

   HorzScrollBar.Position := 0;
   VertScrollBar.Position := 0;

   DeleteDC(device);

   ActiveResize := true;

end;

{Essa subrotina posiciona objetos no formulário de perguntas de modo
 a pedir o valor de uma variável numérica}
procedure TExpertPrompt.MakeNumOptions;
var
   min_value, max_value, position: integer;
begin
   HideTextControls;
   FExpertSystem.Values.SeekByVar(FVarCode);
   if not FExpertSystem.Values.Blind then begin
      if FExpertSystem.Values.name[1] = ';' then begin
         {É um intervalo do tipo "MAIOR QUE..."}
         panelMax.Caption := Copy(FExpertSystem.Values.name, 2, length(FExpertSystem.Values.name));
         panelMin.Caption := '';
      end
      else begin
         if FExpertSystem.Values.name[length(FExpertSystem.Values.name)] = ';' then begin
            {É um intervalo do tipo "MENOR QUE..."}
            panelMin.Caption := Copy(FExpertSystem.Values.name, 1, length(FExpertSystem.Values.name) - 1);
            panelMax.Caption := '';
         end
         else begin
            position := Pos(';', FExpertSystem.Values.name);
            {É um intervalo do tipo "MAIOR QUE, MENOR QUE..."}
            min_value := StrToInt(Copy(FExpertSystem.Values.name, 1, position - 1));
            max_value := StrToInt(Copy(FExpertSystem.Values.name, position + 1, length(FExpertSystem.Values.name)));
            if min_value > scrollValue.Max then ScrollValue.Max := min_value;
            scrollValue.Min := min_value;
            scrollValue.Max := max_value;
            panelMin.Caption := Copy(FExpertSystem.Values.name, 1, position - 1);
            panelMax.Caption := Copy(FExpertSystem.Values.name, position + 1,
                                length(FExpertSystem.Values.name));
         end;
      end;
   end
   else begin
      panelMax.Caption := '';
      panelMin.Caption := '';
   end;
   editValue.Text := '';
   ArrangeNumericOptions;
end;

procedure TExpertPrompt.ArrangeNumericOptions;

   procedure ShowNumericControls;
   begin
     {Conserta um bug do Delphi}
     if csDesigning in ComponentState then begin
        editValue.Parent := Self;
        labelValue.Parent := Self;
        if panelMin.Visible then
           panelMin.Parent := Self
        else
           panelMin.Parent := nil;
        if panelMax.Visible then
           panelMax.Parent := Self
        else
           panelMax.Parent := nil;
        if scrollValue.Visible then
           scrollValue.Parent := Self
        else
           scrollValue.Parent := nil;
     end;
     editValue.Visible := true;
     labelValue.Visible := true;
   end;

begin
   if FAutoSize then begin
      Width := Min(350, FMaxWidth);
      Width := Max(Width, FMinWidth);
   end;
   if FAutoSize then begin
      Height := Min(100, FMaxHeight);
      Height := Max(Height, FMinHeight);
   end;
   editValue.Left := trunc((Width - editValue.Width - labelValue.Width - 5) / 2) +
                     labelValue.Width + 5;
   labelValue.Left := editValue.Left - labelValue.Width - 5;
   FExpertSystem.Values.SeekByVar(FVarCode);
   if not FExpertSystem.Values.Blind then begin
      if FExpertSystem.Values.name[1] = ';' then begin
         {É um intervalo do tipo "MAIOR QUE..."}
         labelValue.Top := trunc((Height - labelValue.Height) / 2);
         editValue.Top := trunc((Height - editValue.Height) / 2);
      end
      else begin
         if FExpertSystem.Values.name[length(FExpertSystem.Values.Name)] = ';' then begin
            {É um intervalo do tipo "MENOR QUE..."}
            labelValue.Top := trunc((Height - labelValue.Height) / 2);
            editValue.Top := trunc((Height - editValue.Height) / 2);
         end
         else begin
            if FAutoSize then begin
               Height := Min(130, FMaxHeight);
               Height := Max(Height, FMinHeight);
            end;
            {É um intervalo do tipo "MAIOR QUE, MENOR QUE..."}
            labelValue.Top := trunc((Height - labelValue.Height - scrollValue.Height - 40) / 2 );
            editValue.Top := labelValue.Top;
            labelValue.Top := trunc((Height - 4 * panelMax.Height) / 2);
            editValue.Top := labelValue.Top;
            panelMax.Top := labelValue.Top + labelValue.Height + 40;
            panelMin.Top := panelMax.Top;
            panelMin.Left := 3;
            panelMax.Left := Width - panelMax.Width - 6;
            scrollValue.Width := panelMax.Left - (panelMin.Left
                                 + panelMin.Width) - 10;
            scrollValue.Left := panelMin.Left + panelMin.Width + 5;
            scrollValue.Top := panelMin.Top;
            panelMin.Visible := true;
            panelMax.Visible := true;
            scrollValue.Visible := true;
         end;
      end;
   end
   else begin
      scrollValue.Visible := false;
      panelMax.Visible := false;
      panelMax.Caption := '';
      panelMin.Visible := false;
      panelMin.Caption := '';
      labelValue.Top := trunc((Height - labelValue.Height) / 2);
      editValue.Top := trunc((Height - editValue.Height) / 2);
   end;
   ShowNumericControls;
   try editValue.SetFocus; except end;
end;

{Constrói as opções (checkboxes ou scrollbar/editbox)}
procedure TExpertPrompt.BuildOptions;
begin
   if (FExpertSystem <> nil) and (FVarCode <> 0) and (Parent <> nil) and
      (not FExpertSystem.EmptyBase) then
   begin
      FExpertSystem.BookmarkVar;
      FExpertSystem.Vars.Seek(FVarCode);
      if not FExpertSystem.Vars.Blind then begin
         VarMulti := FExpertSystem.Vars.Multi;
         VarNumeric := FExpertSystem.Vars.Numeric;
         if VarNumeric then
            MakeNumOptions {Se a variável é numérica...}
         else
            MakeTextOptions; {Se a variável é texto...}
      end
      else
         VarCode := 0;
      FExpertSystem.RestoreVarFromBookmark;
   end;
end;

procedure TExpertPrompt.ArrangeOptions;
begin
   if (FExpertSystem <> nil) and (FVarCode <> 0) and (Parent <> nil) and
      (not FExpertSystem.EmptyBase) then
   begin
      if VarNumeric then
         ArrangeNumericOptions
      else
         ArrangeTextOptions;
   end;
end;

{Atualiza a base de conhecimento com a nova entrada}
function TExpertPrompt.UpdateBase: boolean;
var
   i: integer;
   no_value: boolean;
   cnf, v: real;
   aux: string;
begin
   if (FVarCode = 0) or (FExpertSystem = nil) or FExpertSystem.BrokenSequence or
      (not FExpertSystem.ExecutionMode) or
      ((not FExpertSystem.WaitingAnswer) and (FExpertSystem.Wait or FExpertSystem.Trace))
      then begin
      Result := false;
      Exit;
   end;
   i := 0;
   Result := true;
   no_value := true;
   if not VarNumeric then begin
      if LastNumberOfOptionsUsed >= 0 then begin
         {Nesse caso, o desenvolvedor criou um menu de opções para essa
          variável, que não é numérica.}
         repeat
           {Verifica se todos os graus de confiança são válidos.}
           if TTxtCnf(ListOfCnfs.Objects[i]).Text = '' then
              cnf := FExpertSystem.MAX_CNF
           else begin
              try
                 cnf := StrToFloat(TTxtCnf(ListOfCnfs.Objects[i]).Text) / 100;
              except
                 on EConvertError do begin
                    Result := false;
                    if FShowErrorMessages then
                       MessageDlg(ENTRY_ERROR + IntToStr(i + 1) + '.',
                       mtError, [mbOk], 0);
                 end;
              end;
              if Result and ((cnf < FExpertSystem.MIN_CNF) or (cnf > FExpertSystem.MAX_CNF)) then begin
                 if FShowErrorMessages then
                    MessageDlg(INVALID_CNF_ENTRY +
                    IntToStr(i + 1) + '.', mtInformation, [mbOk], 0);
                 Result := false;
              end;
           end;
           inc(i);
         until (i > LastNumberOfOptionsUsed) or (not Result);
         if Result then begin
            for i := 0 to LastNumberOfOptionsUsed do begin
                if TVarOption(ListOfItems.Objects[i]).Checked then begin
                    if TTxtCnf(ListOfCnfs.Objects[i]).Text = '' then
                       cnf := 1.0
                    else
                       cnf := StrToFloat(TTxtCnf(ListOfCnfs.Objects[i]).Text) / 100;
                    FExpertSystem.AttribVar(FVarCode, ListOfItems[i], cnf, true);
                    no_value := false;
                 end;
             end;
            {Verifica se nenhum valor foi atribuído.}
             if no_value then
                FExpertSystem.AttribVar(FVarCode, IntToStr(UNKNOWN),
                                        FExpertSystem.MAX_CNF, true);
         end;
      end
      else begin
         {Nesse caso, o desenvolvedor não criou nenhum menu de opções para
          essa variável, o usuário digitou a opção diretamente na caixa
          de texto.}
         if editValue.Text <> '' then begin
            aux := editValue.Text;
            FExpertSystem.AttribVar(FVarCode, aux,
                                    FExpertSystem.MAX_CNF, false);
         end
         else
            {ATENÇÃO: POSTERIORMENTE, POSSIBILITAR GRAUS DE CONFIANÇA
             INCLUSIVE COM ESSE TIPO DE ENTRADA.
             Se o usuário deixar a caixa de texto vazia, então
             será entendido como um "NÃO SEI".}
             FExpertSystem.AttribVar(FVarCode, IntToStr(UNKNOWN),
                                     FExpertSystem.MAX_CNF, true);
      end;
   end
   else begin
      if editValue.Text <> '' then begin
         {Verificação de intervalos em variáveis numéricas.}
         try
            v := StrToFloat(editValue.Text);
         except
            on EConvertError do begin
               if FShowErrorMessages then
                  MessageDlg(INVALID_NUMERIC_VALUE, mtError, [mbOk], 0);
               Result := false;
            end;
         end;
         if Result then begin
            if panelMIN.Caption <> '' then
               if v < StrToFloat(panelMIN.Caption) then begin
                  if FShowErrorMessages then
                      MessageDlg(BELOW_MIN_VALUE, mtError, [mbOk], 0);
                  Result := false;
               end;
            if Result and (panelMAX.Caption <> '') then
               if v > StrToFloat(panelMAX.Caption) then begin
                  if FShowErrorMessages then
                     MessageDlg(BEYOND_MAX_VALUE, mtError, [mbOk], 0);
                  Result := false;
               end;
            {ATENÇÃO: INCLUIR POSSIBILIDADE DE FATORES DE CONFIANÇA EM
             VARIÁVEIS NUMÉRICAS!}
            if Result then
               FExpertSystem.AttribVar(FVarCode, editValue.Text,
                                       FExpertSystem.MAX_CNF, false);
         end;
      end
      else
         {Caixa de texto vazia equivale a valor desconhecido.}
         FExpertSystem.AttribVar(FVarCode, IntToStr(UNKNOWN),
                                 FExpertSystem.MAX_CNF, true);
   end;
end;

procedure TExpertPrompt.SetExpertSystem(ES: TExpertSystem);
begin
   if (FExpertSystem <> ES) and (FExpertSystem <> nil) then
      FExpertSystem.RemoveControl(ExpertPromptInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      ES.AddControl(ExpertPromptInterface);
      if FVarCode <> 0 then BuildOptions;
   end
   else
      VarCode := 0;
end;

procedure TExpertPrompt.SetVarCode(vc: integer);
begin
   if (vc = 0) and (FVarCode <> 0) then begin
      HideNumericControls;
      HideTextControls;
      FVarCode := vc;
   end
   else begin
      FVarCode := vc;
      BuildOptions;
   end;
end;

procedure TExpertPrompt.SetAutoSize(asize: boolean);
begin
   FAutoSize := asize;
   if asize then BuildOptions;
end;

procedure TExpertPrompt.CMFontChanged(var Message: TMessage);
begin
   inherited;
   BuildOptions;
end;

{======}

procedure TExpertPromptInterface.Clear;
begin
   TExpertPrompt(OwnerControl).VarCode := 0;
end;

procedure TExpertPromptInterface.RefreshLink(Sender: TExpertSystem);
begin
   TExpertPrompt(OwnerControl).BuildOptions;
end;

procedure TExpertPromptInterface.DestroyLink;
begin
   TExpertPrompt(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                          CLASSE TLABELQUESTION
 ======================================================================
 ======================================================================}

constructor TLabelQuestion.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   LabelQuestionInterface := TLabelQuestionInterface.Create(I_VARIABLE_VIEW, Self);
end;

destructor TLabelQuestion.Destroy;
begin
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(LabelQuestionInterface);
   LabelQuestionInterface.Free;
   inherited Destroy;
end;

procedure TLabelQuestion.SetExpertSystem(ES: TExpertSystem);
begin
   if (FExpertSystem <> ES) and (FExpertSystem <> nil) then
      FExpertSystem.RemoveControl(LabelQuestionInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      ES.AddControl(LabelQuestionInterface);
      if FVarCode <> 0 then BuildCaption;
   end
   else
      VarCode := 0;
end;

procedure TLabelQuestion.SetVarCode(vc: integer);
begin
   if (vc = 0) and (FVarCode <> 0) then begin
      FVarCode := vc;
      Caption := '';
   end
   else begin
      FVarCode := vc;
      if FExpertSystem <> nil then BuildCaption;
   end;
end;

procedure TLabelQuestion.BuildCaption;
begin
   if (FExpertSystem <> nil) and (FVarCode <> 0) and (not FExpertSystem.EmptyBase)
   then begin
      FExpertSystem.BookmarkQuestion;
      if FExpertSystem.Questions.Blind or (FExpertSystem.Questions.code <> FVarCode) then
         FExpertSystem.Questions.Seek(FVarCode);
      if FExpertSystem.Questions.Blind then begin
         FExpertSystem.BookmarkVar;
         FExpertSystem.Vars.Seek(FVarCode);
         Caption := WHAT_IS_THE_VALUE_OF + FExpertSystem.Vars.name + '?';
         FExpertSystem.RestoreVarFromBookmark;
      end
      else
         Caption := FExpertSystem.Questions.Question;
      FExpertSystem.RestoreQuestionFromBookmark;
   end;
end;

{======}

procedure TLabelQuestionInterface.Clear;
begin
   TLabelQuestion(OwnerControl).VarCode := 0;
end;

procedure TLabelQuestionInterface.RefreshLink(Sender: TExpertSystem);
begin
   TLabelQuestion(OwnerControl).BuildCaption;
end;

procedure TLabelQuestionInterface.DestroyLink;
begin
   TLabelQuestion(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                          CLASSE TDEBUGPANEL
 ======================================================================
 ======================================================================}

destructor TDebugPanel.Destroy;
begin
   tails_trace.Free;
   heads_trace.Free;
   if (FExpertSystem <> nil) and
      (FExpertSystem.DebugControl = RuleViewInterface) then
      FExpertSystem.DebugControl := nil;
   inherited Destroy;
end;

procedure TDebugPanel.CreateInterface;
begin
   RuleViewInterface := TDebugPanelInterface.Create(I_KB_VIEW, Self);
end;

procedure TDebugPanel.FillRules;
var
  Position: integer;
begin
  Position := 0;
  inherited FillRules;
  with FExpertSystem do begin
    Rules.CurrentKey := BY_POSITION;
    Rules.MoveFirst;
    while not Rules.Blind do begin
        inc(Position); {Uma posição é gasta com o nome da regra}
        code_rule := Rules.code;
        pos_rule := Rules.Position;

        Tails.Seek(code_rule);
        Heads.Seek(code_rule);

        tails_trace.Insert(code_rule, Position);
        inc(Position);
        Tails.MoveNext;
        while (not Tails.Blind) and (Tails.code = code_rule) do begin
             tails_trace.Insert(code_rule, Position);
             Tails.MoveNext;
             inc(Position);
        end;

        heads_trace.Insert(code_rule, Position);
        inc(Position);
        Heads.MoveNext;
        while (not Heads.Blind) and (Heads.code = code_rule) do begin
            heads_trace.Insert(code_rule, Position);
            Heads.MoveNext;
            inc(Position);
        end;

        Rules.MoveNext;
    end;
  end;
end;

procedure TDebugPanel.SetExpertSystem(ES: TExpertSystem);
begin
   if (FExpertSystem <> ES) and (ES <> nil) and
      (ES.DebugControl <> nil) and
      (TExDebugInterface(ES.DebugControl) <> RuleViewInterface)
      then ES.DebugControl.DestroyLink;
   if (FExpertSystem <> ES) and (FExpertSystem <> nil) and
      (FExpertSystem.DebugControl <> nil) and
      (TExDebugInterface(FExpertSystem.DebugControl) <> RuleViewInterface)
      then FExpertSystem.DebugControl.DestroyLink;
   FExpertSystem := ES;
   if ES <> nil then begin
      tails_trace.Free;
      heads_trace.Free;
      tails_trace := THelpContexts.Create;
      heads_trace := THelpContexts.Create;
      if (not ES.EmptyBase) and ES.CanView then
         FillRules
      else
         Clear;
      ES.AddControl(RuleViewInterface);
      ES.DebugControl := TExDebugInterface(RuleViewInterface);
   end
   else
      Clear;
   current_line := -1;
end;

procedure TDebugPanel.Update(rule: integer; order: integer; is_tail: boolean);
var
   i: integer;
begin
   FExpertSystem.Rules.Seek(rule);
   if is_tail then begin
      tails_trace.Seek(rule);
      for i := 2 to order do tails_trace.MoveNext;
      {A propriedade "Context" de tails_trace guarda o número de uma
       linha da caixa de listagem}
      current_line := tails_trace.Context;
      ItemIndex := tails_trace.Context;
   end
   else begin
      heads_trace.Seek(rule);
      for i := 2 to order do heads_trace.MoveNext;
      {A propriedade "Context" de heads_trace guarda o número de uma
       linha da caixa de listagem "listRules"}
      current_line := heads_trace.Context;
      ItemIndex := heads_trace.Context;
   end;
end;

procedure TDebugPanel.Activate;
begin
    ActiveTrace := (not FExpertSystem.WaitingAnswer) and
                   (not FExpertSystem.BrokenSequence);
    if (not FExpertSystem.Wait) and ActiveTrace then begin
       FExpertSystem.Wait := true;
       while FExpertSystem.Wait do Application.ProcessMessages;
    end;
    ActiveTrace := false;
end;

procedure TDebugPanel.Click;
begin
    {Obs.: Se você adaptar esse código para outra linguagem, primeiro
     verifique se um comando do tipo listRules.ItemIndex := current_line
     dispara um evento de Click, como no caso Visual Bomb..., digo,
     Visual BASIC. O Delphi não é assim, ele NÃO dispara nenhum evento.
     Se for uma linguagem tipo VB, use um flag para evitar que o código
     seja repetido ad infinitum até dar um estouro de pilha}
    if (FExpertSystem <> nil) and (FExpertSystem.ExecutionMode) and
       (ItemIndex <> current_line) then ItemIndex := current_line;
end;

{========}

function TDebugPanelInterface.GetActiveTrace: boolean;
begin
   Result := TDebugPanel(OwnerControl).ActiveTrace;
end;

procedure TDebugPanelInterface.SetActiveTrace(ac: boolean);
begin
   TDebugPanel(OwnerControl).ActiveTrace := ac;
end;

procedure TDebugPanelInterface.Activate;
begin
   TDebugPanel(OwnerControl).Activate;
end;

procedure TDebugPanelInterface.Update(rule: integer; order: integer; is_tail: boolean);
begin
   TDebugPanel(OwnerControl).Update(rule, order, is_tail);
end;

procedure TDebugPanelInterface.Clear;
begin
   TDebugPanel(OwnerControl).Clear;
end;

procedure TDebugPanelInterface.RefreshLink(Sender: TExpertSystem);
begin
   with TDebugPanel(OwnerControl) do begin
      tails_trace.Free;
      heads_trace.Free;
      tails_trace := THelpContexts.Create;
      heads_trace := THelpContexts.Create;
      FillRules;
   end;
end;

procedure TDebugPanelInterface.DestroyLink;
begin
   TDebugPanel(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                          CLASSE TEXNAVIGATOR
 ======================================================================
 ======================================================================}

constructor TExNavigator.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
    NavigatorInterface := TNavigatorInterface.Create(I_STATUS_VIEW, Self);
    BevelOuter := bvNone;
    listVisibleButtons := TList.Create;
    Caption := '';
    btnGo := TSpeedButton.Create(Self);
    btnGo.Hint := BTNGO_HINT;
    btnGo.Width := DEFAULT_NAVIGATOR_WIDTH;
    btnGo.Height := DEFAULT_NAVIGATOR_HEIGHT;
    btnGo.Glyph.Handle := LoadBitmap(hInstance, 'BTNGO');
    btnGo.NumGlyphs := 2;
    btnGo.ShowHint := true;
    listVisibleButtons.Add(btnGo);
    btnBack := TSpeedButton.Create(Self);
    btnBack.Hint := BTNBACK_HINT;
    btnBack.Width := DEFAULT_NAVIGATOR_WIDTH;
    btnBack.Height := DEFAULT_NAVIGATOR_HEIGHT;
    btnBack.Glyph.Handle := LoadBitmap(hInstance, 'BTNBACK');
    btnBack.NumGlyphs := 2;
    btnBack.ShowHint := true;
    listVisibleButtons.Add(btnBack);
    btnStep := TSpeedButton.Create(Self);
    btnStep.Hint := BTNSTEP_HINT;
    btnStep.Width := DEFAULT_NAVIGATOR_WIDTH;
    btnStep.Height := DEFAULT_NAVIGATOR_HEIGHT;
    btnStep.Glyph.Handle := LoadBitmap(hInstance, 'BTNSTEP');
    btnStep.NumGlyphs := 2;
    btnStep.ShowHint := true;
    listVisibleButtons.Add(btnStep);
    btnPause := TSpeedButton.Create(Self);
    btnPause.Hint := BTNPAUSE_HINT;
    btnPause.Width := DEFAULT_NAVIGATOR_WIDTH;
    btnPause.Height := DEFAULT_NAVIGATOR_HEIGHT;
    btnPause.Glyph.Handle := LoadBitmap(hInstance, 'BTNPAUSE');
    btnPause.NumGlyphs := 2;
    btnPause.ShowHint := true;
    listVisibleButtons.Add(btnPause);
    btnStop := TSpeedButton.Create(Self);
    btnStop.Hint := BTNSTOP_HINT;
    btnStop.Width := DEFAULT_NAVIGATOR_WIDTH;
    btnStop.Height := DEFAULT_NAVIGATOR_HEIGHT;
    btnStop.Glyph.Handle := LoadBitmap(hInstance, 'BTNSTOP');
    btnStop.NumGlyphs := 2;
    btnStop.ShowHint := true;
    listVisibleButtons.Add(btnStop);
    TotalButtons := 5;
    Height := DEFAULT_NAVIGATOR_HEIGHT;
    Width := TotalButtons * DEFAULT_NAVIGATOR_WIDTH;
    ArrangeButtons;
    btnGo.Parent := Self;
    btnBack.Parent := Self;
    btnStep.Parent := Self;
    btnPause.Parent := Self;
    btnStop.Parent := Self;
    btnGo.OnClick := Click;
    btnBack.OnClick := Click;
    btnStep.OnClick := Click;
    btnPause.OnClick := Click;
    btnStop.OnClick := Click;
    FVisibleButtons := [nbGo, nbBack, nbStep, nbPause, nbStop];
    DisableAll;
end;

destructor TExNavigator.Destroy;
begin
   listVisibleButtons.Free;
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(NavigatorInterface);
   NavigatorInterface.Free;
   inherited Destroy;
end;

procedure TExNavigator.ArrangeButtons;
var
   i, x0, y0: integer;
begin
   x0 := trunc((Width - TotalButtons * DEFAULT_NAVIGATOR_WIDTH) / 2);
   y0 := trunc((Height - DEFAULT_NAVIGATOR_HEIGHT) / 2);
   for i := 0 to TotalButtons - 1 do begin
       TSpeedButton(listVisibleButtons[i]).Left := x0 + i * DEFAULT_NAVIGATOR_WIDTH;
       TSpeedButton(listVisibleButtons[i]).Top := y0;
   end;
end;

procedure TExNavigator.Click(Sender: TObject);
begin
   if FExpertSystem <> nil then begin
      if Sender = btnGo then begin
         if FExpertSystem.Trace then
            FExpertSystem.ResumeEngine
         else
            FExpertSystem.StartConsultation;
      end;
      if Sender = btnBack then
         FExpertSystem.BackToLastQuestion;
      if Sender = btnStep then
         FExpertSystem.ExecuteStep;
      if Sender = btnPause then
         FExpertSystem.PauseEngine;
      if Sender = btnStop then
         FExpertSystem.AbortConsultation;
   end;
end;

procedure TExNavigator.SetVisibleButtons(vb: TNavigatorVisibleButtons);
var
   OldButtonWidth: integer;
begin
   try
      OldButtonWidth := trunc(Width / TotalButtons);
   except
      OldButtonWidth := DEFAULT_NAVIGATOR_WIDTH;
   end;
   TotalButtons := 0;
   FVisibleButtons := vb;
   listVisibleButtons.Clear;
   if nbGo in FVisibleButtons then begin
      if csDesigning in ComponentState then btnGo.Parent := Self;
      btnGo.Visible := true;
      listVisibleButtons.Add(btnGo);
      inc(TotalButtons);
   end
   else begin
      if csDesigning in ComponentState then btnGo.Parent := nil;
      btnGo.Visible := false;
   end;
   if nbBack in FVisibleButtons then begin
      if csDesigning in ComponentState then btnBack.Parent := Self;
      btnBack.Visible := true;
      listVisibleButtons.Add(btnBack);
      inc(TotalButtons);
   end
   else begin
      if csDesigning in ComponentState then btnBack.Parent := nil;
      btnBack.Visible := false;
   end;
   if nbStep in FVisibleButtons then begin
      if csDesigning in ComponentState then btnStep.Parent := Self;
      btnStep.Visible := true;
      listVisibleButtons.Add(btnStep);
      inc(TotalButtons);
   end
   else begin
      if csDesigning in ComponentState then btnStep.Parent := nil;
      btnStep.Visible := false;
   end;
   if nbPause in FVisibleButtons then begin
      if csDesigning in ComponentState then btnPause.Parent := Self;
      btnPause.Visible := true;
      listVisibleButtons.Add(btnPause);
      inc(TotalButtons);
   end
   else begin
      if csDesigning in ComponentState then btnPause.Parent := nil;
      btnPause.Visible := false;
   end;
   if nbStop in FVisibleButtons then begin
      if csDesigning in ComponentState then btnStop.Parent := Self;
      btnStop.Visible := true;
      listVisibleButtons.Add(btnStop);
      inc(TotalButtons);
   end
   else begin
      if csDesigning in ComponentState then btnStop.Parent := nil;
      btnStop.Visible := false;
   end;
   {Width := TotalButtons * DEFAULT_NAVIGATOR_WIDTH;
    Height := DEFAULT_NAVIGATOR_HEIGHT;
    ArrangeButtons;}
    Width := OldButtonWidth * TotalButtons;
end;

procedure TExNavigator.WMSize(var Message: TWMSize);
var
   i, w: integer;
begin
   inherited;
   {if Width < TotalButtons * DEFAULT_NAVIGATOR_WIDTH then
      Width := TotalButtons * DEFAULT_NAVIGATOR_WIDTH;
   if Height < DEFAULT_NAVIGATOR_HEIGHT then
      Height := DEFAULT_NAVIGATOR_HEIGHT;
   ArrangeButtons;}
   try
      w := trunc(Width / TotalButtons);
   except
      w := DEFAULT_NAVIGATOR_WIDTH;
   end;
   for i := 0 to TotalButtons - 1 do begin
       TSpeedButton(listVisibleButtons[i]).Left := i * w;
       TSpeedButton(listVisibleButtons[i]).Width := w;
       TSpeedButton(listVisibleButtons[i]).Height := Height;
   end;
end;

procedure TExNavigator.SetExpertSystem(ES: TExpertSystem);
begin
   if (FExpertSystem <> ES) and (FExpertSystem <> nil) then
      FExpertSystem.RemoveControl(NavigatorInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      ES.AddControl(NavigatorInterface);
      if ES.EmptyBase then
         DisableAll
      else
         SetDefaults;
   end
   else
      DisableAll;
end;

procedure TExNavigator.DisableAll;
begin
   btnGo.Enabled := false;
   btnBack.Enabled := false;
   btnStep.Enabled := false;
   btnPause.Enabled := false;
   btnStop.Enabled := false;
end;

procedure TExNavigator.SetDefaults;
begin
   btnGo.Enabled := true;
   btnBack.Enabled := false;
   btnStep.Enabled := FExpertSystem.CanView;
   btnPause.Enabled := false;
   btnStop.Enabled := false;
end;

procedure TExNavigator.UpdateButtons;
begin
   if FExpertSystem <> nil then begin
      btnGo.Enabled := true;
      btnBack.Enabled := FExpertSystem.TotalQuestions > 0;
      btnStep.Enabled := FExpertSystem.Trace;
      btnPause.Enabled :=  FExpertSystem.CanView and (not FExpertSystem.Trace);
      btnStop.Enabled := true;
   end;
end;

{======}

procedure TNavigatorInterface.Clear;
begin
   TExNavigator(OwnerControl).DisableAll;
end;

procedure TNavigatorInterface.RefreshLink(Sender: TExpertSystem);
begin
   if TExNavigator(OwnerControl).ExpertSystem.ExecutionMode then
      TExNavigator(OwnerControl).UpdateButtons
   else
      TExNavigator(OwnerControl).SetDefaults;
end;

procedure TNavigatorInterface.DestroyLink;
begin
   TExNavigator(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                          CLASSE TWATCHPANEL
 ======================================================================
 ======================================================================}

constructor TWatchPanel.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   WatchPanelInterface := TWatchPanelInterface.Create(I_INSTANCE_VIEW, Self);
   Caption := '';
   BevelOuter := bvNone;

   labelVars := TLabel.Create(Self);
   labelVars.Caption := VARIABLES_STRING;
   labelVars.Parent := Self;
   labelVars.Align := alTop;

   listVars := TListBox.Create(Self);
   listVars.Parent := Self;
   listVars.Align := alTop;
   listVars.OnKeyDown := EKeyDown;

   labelValues := TLabel.Create(Self);
   labelValues.Caption := VALUES_STRING;
   labelValues.Parent := Self;
   labelValues.Top := listVars.Top + listVars.Height + 10;
   labelValues.Align := alTop;

   listValues := TListBox.Create(Self);
   listValues.Parent := Self;
   listValues.Align := alClient;

   listVars.ParentFont := true;
   listValues.ParentFont := true;

   labelVars.ParentFont := true;
   labelValues.ParentFont := true;

   listVars.OnClick := listVarsClick;
   listVars.Sorted := true;
   Height := 250;
   ValuesListHeight := 50;
   WatchedVars := TSingleIndexTree.Create;
   FAddAll := true;
end;

destructor TWatchPanel.Destroy;
begin
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(WatchPanelInterface);
   WatchPanelInterface.Free;
   WatchedVars.Free;
   inherited Destroy;
end;

procedure TWatchPanel.AddNewItem(v: integer);
begin
   if (FExpertSystem <> nil) and (not FExpertSystem.EmptyBase) then begin
      FExpertSystem.Vars.Seek(v);
      {Guarda o código da variável inserida}
      WatchedVars.Insert(v);
      listVars.Items.Add(FExpertSystem.Vars.Name);
   end;
end;

procedure TWatchPanel.DeleteItem(v: integer; name: string);
begin
   if (FExpertSystem <> nil) and (not FExpertSystem.EmptyBase) then begin
      WatchedVars.Seek(v);
      if not WatchedVars.Blind then begin
         WatchedVars.Delete;
         if name = '' then begin
            FExpertSystem.BookmarkVar;
            FExpertSystem.Vars.Seek(v);
            if not FExpertSystem.Vars.Blind then
               name := FExpertSystem.Vars.name
            else begin
               FExpertSystem.RestoreVarFromBookmark;
               Exit;
            end;
            FExpertSystem.RestoreVarFromBookmark;
         end;
         listVars.Items.Delete(listVars.Items.IndexOf(name));
         Update;
      end;
   end;
end;

procedure TWatchPanel.Clear;
begin
   listVars.Clear;
   listValues.Clear;
   WatchedVars.Free;
   WatchedVars := TSingleIndexTree.Create;
end;

procedure TWatchPanel.Update;
begin
  if (FExpertSystem <> nil) and (not FExpertSystem.EmptyBase) then begin
     listValues.Clear;
     with FExpertSystem do begin
       if ExecutionMode and (listVars.ItemIndex <> -1) then begin
          BookmarkVar;
          Vars.SeekByName(listVars.Items[listVars.ItemIndex]);
          varList.Seek(Vars.code);
          while (not varList.Blind) and (varList.code = Vars.code) do begin
             listValues.Items.Add(RealValue(varList.ValCode)
                + ', ' + WITH_STRING + ' ' +
                MyFloatToStr(varList.cnf * 100) + '%');
             varList.MoveNext;
          end;
          varListExtra.Seek(Vars.code);
          while (not varListExtra.Blind) and (varListExtra.code = Vars.code) do begin
             listValues.Items.Add(varListExtra.Value + ' (' +
                MyFloatToStr(varListExtra.cnf * 100) + '%)');
             varListExtra.MoveNext;
          end;
          RestoreVarFromBookmark;
       end
       else
          if listVars.ItemIndex <> -1 then
             listValues.Items.Add(BASE_NOT_RUNNING);
     end;
  end;
end;

procedure TWatchPanel.listVarsClick(Sender: TObject);
begin
   Update;
end;

function TWatchPanel.GetValuesListHeight: integer;
begin
   Result := listValues.Height;
end;

procedure TWatchPanel.SetValuesListHeight(h: integer);
begin
   if h < 0 then h := 0;
   listVars.Height := Height - labelVars.Height - labelValues.Height - h;
   FValuesListHeight := h;
end;

procedure TWatchPanel.SetExpertSystem(ES: TExpertSystem);
begin
   if (FExpertSystem <> ES) and (FExpertSystem <> nil) then
      FExpertSystem.RemoveControl(WatchPanelInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      ES.AddControl(WatchPanelInterface);
      if FAddAll and ES.CanView then
         FillVars
      else
         Clear;
   end
   else
      Clear;
end;

procedure TWatchPanel.SetAddAll(a: boolean);
begin
   if (not FAddAll) and a then FillVars;
   FAddAll := a;
end;

procedure TWatchPanel.FillVars;
begin
   Clear;
   if (FExpertSystem <> nil) and (not FExpertSystem.EmptyBase) then begin
      FExpertSystem.BookmarkVar;
      FExpertSystem.Vars.MoveFirst;
      while not FExpertSystem.Vars.Blind do begin
         listVars.Items.Add(FExpertSystem.Vars.name);
         FExpertSystem.Vars.MoveNext;
      end;
      FExpertSystem.RestoreVarFromBookmark;
   end;
end;

procedure TWatchPanel.WMSize(var Message: TWMSize);
begin
   inherited;
   if Height < labelVars.Height + labelValues.Height + 150 then
      Height := labelVars.Height + labelValues.Height + 150;
   ValuesListHeight := FValuesListHeight;
   labelVars.Top := 0;
   labelValues.Top := listVars.Top + listVars.Height + 1;
end;

procedure TWatchPanel.EKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   KeyDown(Key, Shift);
end;

procedure TWatchPanel.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then begin
     if listVars.ItemIndex <> -1 then begin
        FExpertSystem.BookmarkVar;
        FExpertSystem.Vars.SeekByName(listVars.Items[listVars.ItemIndex]);
        DeleteItem(FExpertSystem.Vars.Code, FExpertSystem.Vars.Name);
        FExpertSystem.RestoreVarFromBookmark;
        listVars.SetFocus;
     end;
  end;
end;

procedure TWatchPanelInterface.Clear;
begin
   TWatchPanel(OwnerControl).Clear;
end;

procedure TWatchPanelInterface.RefreshLink(Sender: TExpertSystem);
begin
   if Sender = nil then
      TWatchPanel(OwnerControl).Update
   else begin
      if TWatchPanel(OwnerControl).AddAll then
         TWatchPanel(OwnerControl).FillVars
      else
         TWatchPanel(OwnerControl).Clear;
   end;
end;

procedure TWatchPanelInterface.DestroyLink;
begin
   TWatchPanel(OwnerControl).ExpertSystem := nil;
end;

end.
