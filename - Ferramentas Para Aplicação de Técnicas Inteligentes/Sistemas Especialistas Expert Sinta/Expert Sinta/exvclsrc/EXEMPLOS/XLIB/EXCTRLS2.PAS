unit ExCtrls2;

interface

uses
   ExSystem, ExDataSt, Classes, Controls, Forms, Graphics, Menus, StdCtrls;

type

   TListExpertPromptInterface = class(TExCtrlInterface)
    public
      procedure Clear; override;
      procedure RefreshLink(Sender: TExpertSystem); override;
      procedure DestroyLink; override;
   end;

   TListExpertPrompt = class(TCustomListBox)
   private
      ExpertPromptInterface: TListExpertPromptInterface;
      FVarCode: integer;
      FVarBinary: boolean;
      FExpertSystem: TExpertSystem;
   protected
      procedure SetExpertSystem(ES: TExpertSystem);
      procedure SetVarCode(vc: integer);
   public
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      function    UpdateBase: boolean;
   published
      property VarCode: integer read FVarCode write SetVarCode;
      property ExpertSystem: TExpertSystem read FExpertSystem write SetExpertSystem;
      property Align;
      property BorderStyle;
      property Color;
      property Ctl3D;
      property DragCursor;
      property DragMode;
      property Enabled;
      property Font;
      property IntegralHeight;
      property ItemHeight;
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

   procedure Register;

implementation

uses
   ExConsts;
   
{======================================================================
 ======================================================================
                          CLASSE TLISTEXPERTPROMPT
 ======================================================================
 ======================================================================}

constructor TListExpertPrompt.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   ExpertPromptInterface := TListExpertPromptInterface.Create(I_VARIABLE_VIEW, Self);
end;

destructor TListExpertPrompt.Destroy;
begin
   if FExpertSystem <> nil then
      FExpertSystem.RemoveControl(ExpertPromptInterface);
   ExpertPromptInterface.Free;
   inherited Destroy;
end;

procedure TListExpertPrompt.SetExpertSystem(ES: TExpertSystem);
begin
   if (FExpertSystem <> ES) and (FExpertSystem <> nil) then
      FExpertSystem.RemoveControl(ExpertPromptInterface);
   FExpertSystem := ES;
   if ES <> nil then begin
      ES.AddControl(ExpertPromptInterface);
      if FVarCode <> 0 then SetVarCode(FVarCode);
   end
   else
      VarCode := 0;
end;

procedure TListExpertPrompt.SetVarCode(vc: integer);
begin
   FVarCode := vc;
   if (FExpertSystem <> nil) and (vc <> 0) and (Parent <> nil) and
      (not FExpertSystem.EmptyBase) then
   begin
      FExpertSystem.BookmarkVar;
      FExpertSystem.Vars.Seek(vc);
      if FExpertSystem.Vars.Blind then begin
         VarCode := 0;
         Exit;
      end;
      if FExpertSystem.Vars.Numeric then begin
         FExpertSystem.RestoreVarFromBookmark;
         VarCode := 0;
         raise EExpertSystem.Create('Este prompt não exibe valores de variáveis numéricas!');
      end;
      MultiSelect := FExpertSystem.Vars.Multi;
      FExpertSystem.ValuesList(vc, TStringList(Items));
      FVarBinary := (Items.Objects[0] = nil); {Variável do tipo Sim/Não} 
      FExpertSystem.RestoreVarFromBookmark;
      FVarCode := vc;
   end
   else
      if vc = 0 then Clear;
end;

function TListExpertPrompt.UpdateBase: boolean;
var
   i, total: integer;
   bin_value: integer;
begin
   if (FVarCode = 0) or (FExpertSystem = nil) or FExpertSystem.BrokenSequence or
      (not FExpertSystem.ExecutionMode) or
      ((not FExpertSystem.WaitingAnswer) and (FExpertSystem.Wait or FExpertSystem.Trace))
      then
      Result := false
   else begin
      if FVarBinary then begin
         if Selected[0] then
            FExpertSystem.AttribVarFromBinary(FVarCode, YES)
         else
            FExpertSystem.AttribVarFromBinary(FVarCode, NO);
      end
      else begin
         total := Items.Count - 1;
         bin_value := 0;
         for i := 0 to total do
             if Selected[i] then bin_value := bin_value + trunc(exp(ln(2)*i));
         if bin_value = 0 then bin_value := UNKNOWN;
         FExpertSystem.AttribVarFromBinary(FVarCode, bin_value);
      end;
      Result := true
   end;
end;

{======}

procedure TListExpertPromptInterface.Clear;
begin
   TListExpertPrompt(OwnerControl).VarCode := 0;
end;

procedure TListExpertPromptInterface.RefreshLink(Sender: TExpertSystem);
begin
   TListExpertPrompt(OwnerControl).ExpertSystem.ValuesList(TListExpertPrompt(OwnerControl).VarCode,
                                                           TStringList(TListExpertPrompt(OwnerControl).Items));
end;

procedure TListExpertPromptInterface.DestroyLink;
begin
   TListExpertPrompt(OwnerControl).ExpertSystem := nil;
end;

{======================================================================
 ======================================================================
                       REGISTRO DE COMPONENTES
 ======================================================================
 ======================================================================}

procedure Register;
begin
   RegisterComponents('Expert SINTA', [TListExpertPrompt]);
end;

end.
