{
 Rafe's Tip-Of-The-Day Dialog
 ----------------------------

Rafe's Tip-Of-The-Day Dialog offers the sort of functionality you
get in many software packages today. Features include:

	o "Standard" look
	o Changing main text

As this package is freeware it comes with no warranty of any kind.
However, if your computer does blow up as a direct result of using
it I'd enjoy hearing about the experience.

To install Rafe's Tip-Of-The-Day Dialog copy all the files (except
this one) into a directory that's on your component path.

To use Rafe's Tip-Of-The-Day Dialog add the unit TOTD to your
uses clause. Then when you want to show a tip use something like the
following block of code to call up the dialog:

  try
    fTipOfTheDay:=TfTipOfTheDay.Create (Application);
    fTipOfTheDay.CurrentTip:= //set the number of the last shown tip here
    fTipOfTheDay.cbShowTips.Checked:= //set the last status of show tips here
    fTipOfTheDay.ShowModal;
    /*get the number of the last shown tip here*/:=fTipOfTheDay.CurrentTip;
    /*get the status of show tips here*/:=fTipOfTheDay.cbShowTips.Checked;
  finally
    fTipOfTheDay.Free;
  end;

I've left the storing and setting of the CurrentTip and ShowTips
checkbox up to the user. I figured that this would be best as you'll
probably have a .INI file for your application already and you'll want
to use this.

The tips are stored in a file called TIPS.TXT and are of the form
/*TYPE_CHARACTER*/ The tip to be shown. The TYPE_CHARACTER denotes what
the dialog box will have as the leading text and supported
TYPE_CHARACTERS are:

    ^ : 'Today''s tip...'
    ? : 'Did you know...'
    ' : 'Today''s quote...'
    ! : 'Today''s joke...'
    # : 'Today''s message...'

There is an example TIPS.TXT file included.

Hope you like it and find it useful. Comments and suggestions are
most welcome.

One final thing, if you do find this useful then PLEASE be kind
enough to send me a sign of your appreciation (an e-mail, postcard,
t-shirt, money, food etc.). None of this stuff magically appeared
overnight.

	Rafe

E-Mail: rafe@rcai.demon.co.uk
WWW: http://www.oxfordcc.co.uk/rcai
Surface Mail: 89 Sharland Close, Grove, Oxon. OX12 0AF. UK.
MODIFICAÇÕES: Ricardo Bezerra, 05 de fevereiro de 1997}

unit Totd;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TfTipOfTheDay = class(TForm)
    Bevel1: TBevel;
    bClose: TBitBtn;
    Panel1: TPanel;
    lTitle: TLabel;
    iBulb: TImage;
    lTip: TLabel;
    bNext: TBitBtn;
    cbShowTips: TCheckBox;
    bPrevious: TBitBtn;
    procedure bCloseClick(Sender: TObject);
    procedure bClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    MaxTip: Integer;
    Tips : TStringList;
    procedure GetTip (Next : Boolean);
  public
    CurrentTip : Integer;
  end;

var
  fTipOfTheDay: TfTipOfTheDay;

implementation

{$R *.DFM}

procedure TfTipOfTheDay.bCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfTipOfTheDay.GetTip (Next : Boolean);
var
  Tip, Title : String;
begin
  { locate next/previous tip }
  if Next then
    inc (CurrentTip)
  else
    dec (CurrentTip);
  if CurrentTip<0 then CurrentTip:=Tips.Count-1;
  if CurrentTip>=Tips.Count then CurrentTip:=0;
  { get tip and level }
  Tip:=Tips.Strings[CurrentTip];
  case Tip[1] of
    '^'  : Title:='Dica do dia...';
    '?'  : Title:='Você sabia?...';
    '''' : Title:='Citação do dia...';
    '!'  : Title:='Piada do dia...';
    '#'  : Title:='Mensagem do dia...';
  else
    Title:='';
  end; { case }
  lTitle.Caption:=Title;
  lTip.Caption:=format (Copy(Tip, 2, 255), [#13, #13, #13, #13, #13]); { show it! }
end;

procedure TfTipOfTheDay.bClick(Sender: TObject);
begin
  GetTip (Sender=bNext); { get a tip }
end;

procedure TfTipOfTheDay.FormCreate(Sender: TObject);
begin
  CurrentTip:=0;
  Tips:=TStringList.Create;
end;

procedure TfTipOfTheDay.FormDestroy(Sender: TObject);
begin
  Tips.Free;
end;

procedure TfTipOfTheDay.FormShow(Sender: TObject);
begin
  MaxTip := CurrentTip;
  try
    if FileExists('EXSINTA.TIP') then Tips.LoadFromFile ('EXSINTA.TIP');
  finally
    if Tips.Count=0 then
    begin
      bNext.Enabled:=False;
      bPrevious.Enabled:=False;
    end
    else
    bClick (bNext);
  end; { Try }
end;

procedure TfTipOfTheDay.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
   if MaxTip > CurrentTip then CurrentTip := MaxTip;
end;

end.
