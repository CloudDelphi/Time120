﻿unit Unit1;
{$DEFINE TOOLS}
// conflitto eurekalog con dxsound. rimuovere eurekalog nella  build finale

      { TODO  : override maglie bianca o nera }
      { TODO : settare il volume audio dei singoli file }
      { TODO : verificare se advdiceaddrow risolve splashscreen }
      { TODO : risolvere sfarfallio in formation }
      { TODO : finire traduzioni }
      { TODO : verificare bug sound prs e posizione palla}
      { TODO : sostituire grid con se_grid }
      { TODO : gestire il fine partita }
      { TODO : bug sui pulsanti tattiche. il player rimane sospeso  }

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Types, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, generics.collections, Strutils, Inifiles,math, FolderDialog,generics.defaults,
  Vcl.Grids, Vcl.ComCtrls,  Vcl.Menus, Vcl.Mask,
  Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.MMSystem,    // Delphi libraries

  DSE_Random ,     // DSE Package
  DSE_PathPlanner,
  DSE_theater,
  DSE_ThreadTimer,
  dse_bitmap,
  dse_defs,
  DSE_misc,
  DSE_SearchFiles,
  DSE_GRID,
  SoccerBrainv3,

  AdvObj,BaseGrid, AdvGrid, AdvPanel,AdvProgr, AdvBadge,CurvyControls,   // TMS grids and Panel
  JvExControls, JvTracker, JvExStdCtrls, JvShapedButton, JvSpecialProgress, // Jedi Library
  Dxwave,DXSounds,                    // DelphiX (Audio)
  ZLIBEX,                             // delphizlib invio dati compressi tra server e client

  RzBmpBtn, RzButton, RzEdit,RzSpnEdt,RzLabel, RzRadChk, RzPanel, RzRadGrp,    // RaizeComponents
  OverbyteIcsWndControl, OverbyteIcsWSocket, CnButtons, CnSpin, CnAAFont, CnAACtrls ;  // OverByteIcsWSocketE ics con modifica. vedi directory External.Packages\overbyteICS del progetto

const GCD_DEFAULT = 200;        // global cooldown, minimo 200 ms tra un input verso il server e l'altro ( anti-cheating )
const ScaleSprites = 40;        // riduzione generica di tutto gli sprite player
const BallZ0Y = 16;             // la palla sta più in basso, vicino ai piedi dello sprite player
const Ball0X = 3;               // la palla sta più avanti rispetto allo sprite player
const sprite1cell = 900;        // ms tempo che impiega un player a spostarsi di una cella
const ShowRollLifeSpan = 1600;  // ms tempo di comparsa dei roll
const ShowFaultLifeSpan = 1600; // ms notifica in caso di fallo
const msSplashTurn = 1600;
const STANDARD_MP_MS = 50;
const EndOfLine = 'ENDSOCCER';  // tutti i pacchetti Tcp tra server e client finiscono con questo marker
type TArcDirection = (adCounterClockWise, adClockWise);  // traiettorie ad arco della palla. non  usate in questo prototipo
type TArray8192 = array [0..8191] of AnsiChar; // i buf[0..255] of  TArray8192 contengono il buffer Tcp in entrata

type TSpriteArrowDirection = record
  offset : TPoint;
  angle : single;
end;

// Schermate di gioco, es. ScreenWatchLive quando guardo una partita di altri giocatori.
type TGameScreen =(ScreenLogin, ScreenSelectCountry, ScreenSelectTeam, ScreenMain,
                  ScreenWaitingFormation, ScreenFormation,
                  ScreenWaitingLiveMatch, ScreenLiveMatch, ScreenTactics, ScreenSubs,
                  ScreenSelectLiveMatch, ScreenWaitingWatchLive, ScreenWatchLive,
                  ScreenMarket );

Type TAnimationScript = class // letta dal TForm1.mainThreadTimer. Produce l'animazione degli sprite.
  Ts: TstringList;              // contiene tsScript del server. è l'animazione già accaduta sul server e ora il client deve mostrarla con gli sprite
  Index : Integer;              // cicla per gli elementi di Ts
  WaitMovingPlayers: boolean;   // Aspetta che tutti i player siano fermi
  wait: integer;                // tempo di attesa prima di procedere al prossimo elemento di Ts
  memo: Tmemo;                  // utile per log
  Constructor Create;
  Destructor destroy;
  procedure Reset;
  procedure TsAdd ( v: string );
end;
type  TPointArray4 = array[0..3] of TPoint;

Type TSoccerCell = class
  CellX, CellY, PixelX, PixelY : integer;
  Polygon: TPointArray4;
  OutSide: boolean;
  Corner: boolean;
  crossbar: array [0..2] of TPoint;
  gol: array [0..2] of TPoint;
  color: TColor;
  Team: Integer;
end;
PSoccerCell = ^TSoccerCell;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Memo1: TMemo;
    Memo3: TMemo;
    Button6: TButton;
    Button2: TButton;
    DXSound1: TDXSound;
    Button7: TButton;
    Button8: TButton;
    Button10: TButton;
    CheckBox1: TCheckBox;
    tcp: TWSocket;
    MemoC: TMemo;
    Timer1: TTimer;
    CheckBoxAI0: TCheckBox;
    CheckBoxAI1: TCheckBox;
    PanelBack: TAdvPanel;
    PanelCombatLog: TCurvyPanel;
    advDice: TAdvStringGrid;
    PanelScore: TCurvyPanel;
    btnTactics: TRzBmpButton;
    PanelSell: TCurvyPanel;
    edtSell: TRzNumericEdit;
    PanelMain: TCurvyPanel;
    PanelCountryTeam: TCurvyPanel;
    advCountryTeam: TAdvStringGrid;
    PanelListMatches: TCurvyPanel;
    btnBackListMatches: TButton;
    btnListMatches: TButton;
    PanelCorner: TCurvyPanel;
    AdvTeam: TAdvStringGrid;
    PanelLogin: TCurvyPanel;
    Label1: TLabel;
    Label5: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    AdvBadgeLabel1: TAdvBadgeLabel;
    PanelError: TCurvyPanel;
    lblError: TRzBmpButton;
    btnErrorOK: TRzBmpButton;
    btnFormation: TRzBmpButton;
    btnMainPlay: TRzBmpButton;
    btnWatchLive: TRzBmpButton;
    btnMarket: TRzBmpButton;
    btnStandings: TRzBmpButton;
    btnExit: TRzBmpButton;
    RzNumericEdit1: TRzNumericEdit;
    RzNumericEdit2: TRzNumericEdit;
    SE_Theater1: SE_Theater;
    SE_field: SE_Engine;
    SE_players: SE_Engine;
    SE_ball: SE_Engine;
    PanelInfoPlayer0: TCurvyPanel;
    PanelformationSE: TCurvyPanel;
    se_lblPlay: TRzBmpButton;
    BtnFormationBack: TRzBmpButton;
    PanelInfoplayer1: TCurvyPanel;
    PanelSkillSE: TCurvyPanel;
    SE_numbers: SE_Engine;
    SE_interface: SE_Engine;
    Button1: TButton;
    Edit3: TEdit;
    mainThread: SE_ThreadTimer;
    JvShapedButton2: TJvShapedButton;
    JvShapedButton4: TJvShapedButton;
    JvShapedButton1: TJvShapedButton;
    JvShapedButton3: TJvShapedButton;
    Memo2: TMemo;
    CheckBox2: TCheckBox;
    BtnFormationReset: TRzBmpButton;
    btnSubs: TRzBmpButton;
    advAllbrain: TAdvStringGrid;
    btnWatchLiveExit: TRzBmpButton;
    ThreadCurMove: SE_ThreadTimer;
    Button3: TButton;
    CheckBox3: TCheckBox;
    PanelXPplayer0: TCurvyPanel;
    btnxp0: TRzBmpButton;
    btnxpBack0: TRzBmpButton;
    btnTalentBmp0: TRzBmpButton;
    btnTalentBmp1: TRzBmpButton;
    FolderDialog1: TFolderDialog;
    btnReplay: TRzBmpButton;
    RzSpinEdit1: TRzSpinEdit;
    toolSpin: TRzSpinEdit;
    btnsell0: TRzBmpButton;
    BtnFormationUniform: TRzBmpButton;
    PanelUniform: TCurvyPanel;
    btnUniformBack: TRzBmpButton;
    UniformPortrait: TRzBmpButton;
    se_gridColors: TAdvStringGrid;
    btnConfirmSell: TRzBmpButton;
    PanelMarket: TCurvyPanel;
    advMarket: TAdvStringGrid;
    btnMarketBack: TRzBmpButton;
    btnMarketRefresh: TRzBmpButton;
    edtsearchprice: TRzNumericEdit;
    btnLogin: TRzBmpButton;
    btnSelCountryTeam: TRzBmpButton;
    lbl_MoneyF: TRzLabel;
    lbl_RankF: TRzLabel;
    lbl_TurnF: TRzLabel;
    lbl_PointsF: TRzLabel;
    lbl_MIF: TRzLabel;
    se_gridskill: TAdvStringGrid;
    se_lblSurname0: TRzLabel;
    se_lblSurname1: TRzLabel;
    lbl_talent0: TRzLabel;
    lbl_talent1: TRzLabel;
    ck_Jersey1: TRzRadioButton;
    ck_Shorts: TRzRadioButton;
    ck_Socks1: TRzRadioButton;
    ck_Jersey2: TRzRadioButton;
    ck_Socks2: TRzRadioButton;
    se_lblmaxvalue: TRzLabel;
    ck_HA: TRzRadioGroup;
    lblNick0: TRzLabel;
    lblNick1: TRzLabel;
    lbl_score: TRzLabel;
    ProgressSeconds: TJvSpecialProgress;
    lbl_minute: TRzLabel;
    btnAudioStadium: TRzBmpButton;
    btnDismiss0: TRzBmpButton;
    PanelDismiss: TCurvyPanel;
    btnConfirmDismiss: TRzBmpButton;
    lbl_ConfirmDismiss: TRzLabel;
    imgshpfree: TImage;
    DXSound2: TDXSound;
    DXSound3: TDXSound;
    DXSound4: TDXSound;
    DXSound5: TDXSound;
    DXSound6: TDXSound;
    DXSound7: TDXSound;
    DXSound8: TDXSound;
    DXSound9: TDXSound;
    DXSound10: TDXSound;
    lbl_TeamName: TRzLabel;
    Button4: TButton;
    SE_GridXP0: SE_Grid;
    SE_Grid0: SE_Grid;
    SE_Grid1: SE_Grid;
    lbl_descrTalent0: TRzLabel;
    lbl_descrtalent1: TRzLabel;
    PorTrait0: TCnSpeedButton;
    Portrait1: TCnSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure InitSound;
    procedure ClientLoadListMatchFile;
    procedure ClientLoadMarket;
    procedure ElaborateTsScript; // tsScript arriva dal server e contiene l'animazione da realizzare qui sul client
    procedure AdvTeamClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure tcpDataAvailable(Sender: TObject; ErrCode: Word);
    procedure BtnLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnSelCountryTeamClick(Sender: TObject);
    procedure btnFormationClick(Sender: TObject);
    procedure btnWatchLiveClick(Sender: TObject);
    procedure btnBackListMatchesClick(Sender: TObject);

    procedure tcpSessionConnected(Sender: TObject; ErrCode: Word);
    procedure tcpException(Sender: TObject; SocExcept: ESocketException);
    procedure tcpSessionClosed(Sender: TObject; ErrCode: Word);

    procedure Timer1Timer(Sender: TObject);

    procedure btnTacticsClick(Sender: TObject);
    procedure btnSkill11Click(Sender: TObject);
    procedure btnMainPlayClick(Sender: TObject);
    procedure btnErrorOKClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure advCountryTeamKeyPress(Sender: TObject; var Key: Char);
    procedure SE_Theater1SpriteMouseMove(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Shift: TShiftState);
      function FindInteractivePlayer ( aPlayer: TSoccerPlayer ): TInteractivePlayer;
    procedure SE_Theater1SpriteMouseDown(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;
      Shift: TShiftState);
    procedure SE_Theater1SpriteMouseUp(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;
      Shift: TShiftState);
    procedure SE_Theater1TheaterMouseMove(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Shift: TShiftState);
    procedure se_gridskillGetCellCursor(Sender: TObject; ACol, ARow, X, Y: Integer; var ACursor: TCursor);
    procedure Button6Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SE_ballSpriteDestinationReached(ASprite: SE_Sprite);
    procedure mainThreadTimer(Sender: TObject);
    procedure CheckBoxAI0Click(Sender: TObject);
    procedure CheckBoxAI1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure BtnFormationBackClick(Sender: TObject);
    procedure BtnFormationResetClick(Sender: TObject);
    procedure advDiceWriteRow  ( team: integer; attr, Surname, ids, vs,num1: string);
      function advDiceNextBlank  ( team: integer): Integer;
    procedure btnSubsClick(Sender: TObject);
    procedure SE_Theater1BeforeVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
    procedure btnWatchLiveExitClick(Sender: TObject);
    procedure advAllbrainClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure ThreadCurMoveTimer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure btnxp0Click(Sender: TObject);
    procedure btnxpBack0Click(Sender: TObject);
    procedure btnReplayClick(Sender: TObject);
    procedure btnStandingsClick(Sender: TObject);
    procedure toolSpinKeyPress(Sender: TObject; var Key: Char);
    procedure toolSpinButtonClick(Sender: TObject; Button: TSpinButtonType);
    procedure btnsell0Click(Sender: TObject);
    procedure BtnFormationUniformClick(Sender: TObject);
    procedure btnUniformBackClick(Sender: TObject);
    procedure se_gridColorsClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure ck_HAClick(Sender: TObject);
    procedure btnConfirmSellClick(Sender: TObject);
    procedure btnMarketBackClick(Sender: TObject);
    procedure btnMarketClick(Sender: TObject);
    procedure btnMarketRefreshClick(Sender: TObject);
    procedure advMarketClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure btnAudioStadiumClick(Sender: TObject);
    procedure btnConfirmDismissClick(Sender: TObject);
    procedure btnDismiss0Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure SE_GridXP0GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
      Sprite: SE_Sprite);
    procedure SE_GridXP0GridCellMouseMove(Sender: TObject; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
    procedure Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    fSelectedPlayer : TSoccerPlayer;
    procedure ShowFace ( aSprite: SE_Sprite);
    procedure  SetSelectedPlayer ( aPlayer: TSoccerPlayer);
    procedure ClientLoadBrainMM ( incMove: Byte) ;
    function FieldGuid2Cell (guid:string): Tpoint;
    function ClientLoadScript ( incMove: Byte) : Integer;
    procedure ArrowShowShpIntercept( CellX, CellY : Integer; ToEmptyCell: boolean);
    procedure ArrowShowMoveAutoTackle( CellX, CellY : Integer);

    procedure ArrowShowLopheading(CellX, CellY : Integer; ToEmptyCell: boolean);
    procedure ArrowShowCrossingHeading( CellX, CellY : Integer) ;
    procedure ArrowShowDribbling( anOpponent: TSoccerPlayer; CellX, CellY : Integer);
    procedure hidechances;
    procedure FirstShowRoll;

    procedure i_Tml ( MovesLeft,team: string );  // animazione internal mosse rimaste
    procedure SetTmlPosition ( team: string );
    procedure i_tuc ( team: string );          // animazione internal turn change
    procedure i_red ( ids: string );           // animazione internal red card (espulsione)
    procedure i_Yellow ( ids: string );        // animazione internal yellow card (ammonizione)
    procedure i_Injured ( ids: string );       // animazione internal infortunio
    procedure AnimCommon ( Cmd:string);

    procedure Logmemo ( ScriptLine : string );
    procedure HighLightField ( CellX, CellY, LifeSpan : integer );
    procedure HighLightFieldFriendly ( aPlayer: TSoccerPlayer; cells: char );
    procedure HighLightFieldFriendly_hide;
    procedure SelectedPlayerPopupSkillSE ( CellX, CellY: integer);

    procedure Anim ( Script: string );
    procedure RoundBorder (bmp: TBitmap; w,h: Integer);
    function inGolPosition ( PixelPosition: Tpoint ): Boolean;
    function inCrossBarPosition ( PixelPosition: Tpoint ): Boolean;
    function inGKCenterPosition ( PixelPosition: Tpoint ): Boolean;

    procedure MoveInReserves ( aPlayer: TSoccerPlayer );
    procedure MoveInDefaultField ( aPlayer: TSoccerPlayer );
    function isTvCellFormation ( Team, CellX, CellY: integer ): boolean;
    procedure SpriteReset ;
    procedure UpdateSubSprites;
    procedure LoadTranslations ;

    function Capitalize ( aString : string  ): String;

    procedure SetTheaterMatchSize;
    procedure InitializeTheaterMatch;
    procedure InitializeTheaterFormations;
    procedure Createfield;
    procedure createNoiseTV;


    procedure ClientLoadFormation ;
      procedure PreloadUniform(ha:Byte;  var UniformBitmap: SE_Bitmap);
      procedure PreloadUniformGK(ha:Byte;  var UniformBitmapGK: SE_Bitmap);
      function DarkColor(aColor: TColor): TColor;
      function softlight(aColor: TColor): TColor;
      function i_softlight(ib, ia: integer): integer;

      procedure ColorizeFault( Team:Byte;  var FaultBitmap: SE_Bitmap);

    function RndGenerate( Upper: integer ): integer;
    function RndGenerate0( Upper: integer ): integer;
    function RndGenerateRange( Lower, Upper: integer ): integer;

    procedure PanelSkillDynamicResizeSE;

    function findlstSkill (SkillName: string ): integer;
    function findPlayerMyBrainFormation ( guid: string ): TSoccerPlayer;
    procedure UpdateFormation ( Guid: string; Team, TvCellX, TvCellY: integer);
    function CheckFormationTeamMemory : Boolean; // in memoria mybrainformation lstsoccerplayer.formationcellX
      procedure RefreshCheckFormationMemory;

    procedure SetGlobalCursor ( aCursor: Tcursor);

    procedure SetupGridXP (GridXP: SE_grid; aPlayer: TsoccerPlayer);
    procedure SetupGridAttributes (GridAT: SE_grid; aPlayer: TsoccerPlayer; show:char);

    procedure CreateArrowDirection ( Player1 , Player2: TSoccerPlayer ); overload;
    procedure CreateArrowDirection ( Player1 : TSoccerPlayer;  CellX, CellY: integer ); overload;
    procedure CreateCircle(  Player : TSoccerPlayer  ); overload;
    procedure CreateCircle(  Team,  CellX, CellY: integer  );overload;
    procedure TackleMouseEnter ( Sender : TObject);
    procedure MovMouseEnter ( Sender : TObject);
    procedure ShpMouseEnter ( Sender : TObject);
    procedure LopMouseEnter ( Sender : TObject);
    procedure CroMouseEnter ( Sender : TObject);
    procedure DriMouseEnter ( Sender : TObject);
    procedure PrsMouseEnter ( Sender : TObject);
    procedure PosMouseEnter ( Sender : TObject);

    procedure SetGameScreen (const aGameScreen:TGameScreen);
  public
    { Public declarations }
    aInfoPlayer: TSoccerPlayer;
    fGameScreen: TGameScreen;
//    function InvertFormationCell (FormationCellX , FormationCellY : integer): Tpoint;


    procedure ClickSkillSE ( Sender : TObject; ARow,ACol: Integer);
    function GetDominantColor ( Team: integer  ): TColor;
    function GetContrastColor( cl: TColor  ): TColor;


    procedure LoadAdvTeam ( team : integer; stat: string; clearMark: boolean );
    procedure CreateSplash (aString: string; msLifespan: integer) ;
    procedure RemoveChancesAndInfo  ;
    procedure CornerSetBall;
    procedure CornerSetPlayer ( aPlayer: TsoccerPlayer);
    procedure PrepareAnim;
    property  GameScreen :TGameScreen read fGameScreen write SetGameScreen;
    function findlstplayer ( guid: string ): TSoccerPlayer;
    procedure SetTcpFormation;

    property  SelectedPlayer: TSoccerPlayer read fSelectedPlayer write SetSelectedPlayer;

end;

var
  Form1: TForm1;
  dir_log: string;
  MyBrain: TSoccerBrain;
  MyBrainFormation: TSoccerBrain;
  RandGen: TtdBasePRNG;
  lstPlayers: TobjectList<TSoccerPlayer>;
  GCD: Integer; // global cooldown temporaneo per braininput
  dir_tmp, dir_stadium, dir_ball, dir_skill, dir_player, dir_interface, dir_data, dir_sound, dir_attributes, dir_help, dir_talent: string;

  WAITING_GETFORMATION, WAITING_STOREFORMATION: boolean;

  // il client si mette in attesa di una rispoosta dal server:
  WaitForAuth: boolean;       // in attesa di autenticazione login

  WaitForXY_ShortPass, WaitForXY_LoftedPass, WaitForXY_Crossing,
  WaitForXY_Move,WaitForXY_PowerShot , WaitForXY_PrecisionShot, WaitForXY_Dribbling,WaitFor_Corner : boolean; // in attesa di input di gioco
  WaitForXY_FKF1: Boolean;  // chi batte la short.passing o lofted.pass
  WaitForXY_FKF2: Boolean;  // chi batte il cross
  WaitForXY_FKA2: Boolean;  // i 3 saltatori
  WaitForXY_FKD2: Boolean;  // i 3 saltatori in difesa
  WaitForXY_FKF3: Boolean;  // chi batte la punizione
  WaitForXY_FKD3: Boolean;  // la barriera
  WaitForXY_FKF4: Boolean;  // chi batte il rigore
  WaitForXY_CornerCOF : boolean;  // chi batte il corner
  WaitForXY_CornerCOA : boolean;  // i 3 coa ( attaccanti sul corner )
  WaitForXY_CornerCOD : boolean;  // i 3 coa ( difensori sul corner )


  DontDoPlayers: Boolean; // non accetta click sui player
  oldVisualCmd: string;

  se_gridskilloldCol, se_gridskilloldRow : Integer;

  TranslateMessages : TStringList;
  TalentEditing : boolean;
  AnimationScript : TAnimationScript;
  FormationsPreset: TList<TFormation>;
  ADVSKoldCol, ADVSKoldRow: integer;
  tsCoa: Tstringlist;
  tsCod: Tstringlist;
  UsePlaySoundBall: boolean;


  oldPlayer: TSoccerPlayer;
  oldShift: TShiftState;

  Score: Tscore;

  SE_DragGuid: Se_Sprite; // sprite che sto spostando con il drag and drop
  Animating:Boolean;
  tsTalents: TStringList;
  LstSkill: array[0..10] of string; // 11 skill totali
  ShowPixelInfo: Boolean;

  keyTimer : Word;

  viewMatch : Boolean; // sto guardando in modalità spettatore
  ViewReplay: Boolean; // sto guardando un reaply locale
  LiveMatch: Boolean;  // sono in livematch 1vs1

  MyGuidTeam: Integer;       // identificatore assoluto del mio team sul DB game.teams
  MyGuidTeamName: string;    // il nome del team che corrisponde ad una squadra del cuore reale
  LocalSeconds: Integer;     // Quando i 120 seocndi si esauriscono, il turno termina
  LastGuidTurn: Integer;
  lastStrError: string;
  LastCellx2,LastCelly2: Integer;


  Rewards : array [1..4, 1..20] of Integer;

  tsFtpXXX: TStringList;


  lstInteractivePlayers: TList<TInteractivePlayer>; // lista che contiene i player interagiscono durante il turno dell'avversario
  MarkingMoveAll: Boolean;

  FirstLoadOK: Boolean; // Primo caricamento della partita avvenuto. Avviene anche durante un reconnect

  TsWorldCountries, TsNationTeams : TStringList;

  Buf3 : array [0..255] of TArray8192;    // array globali. vengono riempiti in Tcp.dataavailable. una partita non va oltre 255 turni, di solito 120 + recupero
  MM3 : array [0..255] of TMemoryStream;  // copia di cui sopra ma in formato stream, per un accesso rapido a certe informazioni

  LastTcpincMove,CurrentIncMove: byte;
  incMove : array [0..255] of boolean;

  TSUniforms: array [0..1] of Tstringlist;
  UniformBitmapBW,FaultBitmapBW,InOutBitmap : SE_Bitmap;

  // Team General
  NextHa: Byte;                 // prossima partita in cas o fuori (home,away)
  mi: SmallInt;                 // media inglese
  points: Integer;              // punti
  MatchesPlayedTeam: Integer;   // totale partite giocate
  Money: Integer;               // Denaro
  TotMarket: Integer;           // Valore totale dei player

  //sounds
  AudioCrowd : TAudioFileStream;
  AudioFaul : TAudioFileStream;
  AudioCrossbar : TAudioFileStream;
  AudioBounce : TAudioFileStream;
  AudioNoGol : TAudioFileStream;
  AudioGol : TAudioFileStream;
  AudioNet : TAudioFileStream;
  AudioShot : TAudioFileStream;
  AudioTackle : TAudioFileStream;
  AudioGameOver : TAudioFileStream;
  WaveFormat: TWaveFormatEx;

implementation

{$R *.dfm}

uses Unit2{Unit ShowPanel }, Unit3;
function TryDecimalStrToInt( const S: string; out Value: Integer): Boolean;
begin
   result := ( pos( '$', S ) = 0 ) and TryStrToInt( S, Value );
end;

function RemoveEndOfLine(const Line : String) : String;
begin
    if (Length(Line) >= Length(EndOfLine)) and
       (StrLComp(PChar(@Line[1 + Length(Line) - Length(EndOfLine)]),
                 PChar(EndOfLine),
                 Length(EndOfLine)) = 0) then
        Result := Copy(Line, 1, Length(Line) - Length(EndOfLine))
    else
        Result := Line;
end;

function PointInPolyRgn(const P: TPoint; const Points: array of TPoint): Boolean;
type
  PPoints = ^TPoints;
  TPoints = array [0..0] of TPoint;
var
  Rgn: HRGN;
begin
  Rgn := CreatePolygonRgn(PPoints(@Points)^, High(Points) + 1, WINDING);
  try
    Result := PtInRegion(Rgn, P.X, P.Y);
  finally
    DeleteObject(Rgn);
  end;
end;

procedure CalculateChance  ( A, B: integer; var chanceA, chanceB: integer; var chanceColorA, chanceColorB: Tcolor);
var
  AI, BI, TA, TB: integer;
begin
  TA := 0;
  TB := 0;
  for AI := 1 to 4 do begin
    for BI := 1 to 4 do begin
      if A+AI >= B+BI then inc (TA)
        else inc (TB);
    end;
  end;
  chanceA := trunc (( TA * 100 ) / 16);
  if chanceA = 0 then begin
    chanceA := 1;
  end else if chanceA = 100 then chanceA := 99;

  chanceB := trunc (( TB * 100 ) / 16);
  if chanceB = 0 then begin
    chanceB := 1;
  end else if chanceB = 100 then chanceB := 99;

  case chanceA of
    0..33: begin
      chancecolorA:= clRed;
    end;
    34..66: begin
      chancecolorA:= clYellow;
    end;
    67..100: begin
      chancecolorA:= clGreen;
    end;
  end;

  case chanceB of
    0..33: begin
      chancecolorB:= clRed;
    end;
    34..66: begin
      chancecolorB:= clYellow;
    end;
    67..100: begin
      chancecolorB:= clGreen;
    end;
  end;
end;

Constructor TAnimationScript.create;
begin
  Ts:= TstringList.Create ;
  Index := -1;

end;
Destructor TAnimationScript.destroy ;
begin
  memo.Clear ;
  Ts.free;
  inherited;
end;
procedure TAnimationScript.Reset;
begin
  memo.Clear ;
  Index := -1;
  Wait := -1;
  WaitMovingPlayers := false;
  Ts.clear;
end;
procedure TAnimationScript.TsAdd ( v: string );
begin
  Ts.Add ( v );
 // memo.Lines.Add( v );
end;

procedure TForm1.BtnLoginClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    tcp.SendStr( 'login,'+Edit1.text +',' + Edit2.text + EndofLine);
    GCD := GCD_DEFAULT;
  end;
end;


procedure TForm1.btnMainPlayClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    if CheckFormationTeamMemory then begin
     LiveMatch := True;
     tcp.SendStr( 'queue' + endofline);
    // gameScreen := ScreenWaitingLiveMatch;
    end
       else begin
        ShowFormations;
        InitializeTheaterFormations;
       end;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnMarketBackClick(Sender: TObject);
begin
  PanelMarket.Visible := False;
  GameScreen := ScreenMain;
//  ShowMain;
end;

procedure TForm1.btnMarketClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    if GameScreen =  ScreenMain then
    tcp.SendStr( 'market,' +  IntToStr(MaxInt)  + EndofLine);
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnMarketRefreshClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    tcp.SendStr( 'market,' + edtsearchprice.text + EndofLine);
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnReplayClick(Sender: TObject);
var
  i: Integer;
  sf : SE_SearchFiles;
begin
  {$ifdef tools}
  ViewReplay := True;
  ToolSpin.Visible := True;
  // dialogs
  FolderDialog1.Directory := dir_log;

  if not FolderDialog1.Execute then begin
    ViewReplay := false;
    ToolSpin.Visible := false;
    Exit;
  end;
  sf :=  SE_SearchFiles.Create(nil);

  sf.MaskInclude.add ('*.is');
  sf.FromPath := FolderDialog1.Directory;
  sf.SubDirectories := False;
  sf.Execute ;

  while Sf.SearchState <> ssIdle do begin
    Application.ProcessMessages ;
  end;

  sf.ListFiles.Sort;

  if sf.ListFiles.Count > 0 then begin
    if FileExists( FolderDialog1.Directory  + '\' + sf.ListFiles[0] ) then begin
      InitializeTheaterMatch;
      GameScreen := ScreenLiveMatch ;
      MM3[0].LoadFromFile( FolderDialog1.Directory   + '\' + sf.ListFiles[0]);
      CopyMemory( @Buf3[0], MM3[0].Memory, MM3[0].size  );
      ClientLoadBrainMM ( 0 );
      CurrentIncMove :=  0;
      ClientLoadScript( 0 );
      if Mybrain.tsScript.Count = 0 then begin
        ClientLoadBrainMM ( 0 );
      end
      else
        ElaborateTsScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
    end
    else ViewReplay := false;
  end
  else ViewReplay := false;

  sf.Free;

  {$endif tools}

end;

procedure TForm1.btnSelCountryTeamClick(Sender: TObject);
begin
  // una volta all'inizio del gioco
  if GCD <= 0 then begin
    if GameScreen =  ScreenSelectCountry then
    tcp.SendStr( 'selectedcountry,' + advCountryTeam.Cells[0,advCountryTeam.row] + EndofLine)
    else if GameScreen =  ScreenSelectTeam then begin
      WAITING_GETFORMATION:= True;
      tcp.SendStr(  'selectedteam,' + advCountryTeam.Cells[0,advCountryTeam.row] + EndofLine);
    end;
    GCD := GCD_DEFAULT;
  end;
end;




procedure TForm1.btnsell0Click(Sender: TObject);
var
  aPlayer: TSoccerPlayer;
begin
  case btnsell0.Tag of  // onMarket
    1: begin
      WAITING_GETFORMATION:= True;
      btnsell0.Tag:=0;
      btnsell0.Caption := Translate('lbl_Sell');
      tcp.SendStr( 'cancelsell,'+ se_grid0.SceneName  + EndofLine); // solo a sinistra in formation
    end;
    0: begin
      if TotMarket < 3 then begin
        PanelSell.Visible := True;
        PanelSell.BringToFront;
        aPlayer:= MyBrainFormation.GetSoccerPlayer2( se_grid0.SceneName ) ;
        edtSell.Value := Trunc (aPlayer.MarketValue);
        edtSell.Min := Trunc (aPlayer.MarketValue);
      end
      else begin
        lastStrError:= 'lbl_ErrorMarketMax';
        ShowError( Translate('lbl_ErrorMarketMax'));
      end;
    end;
  end;

end;

procedure TForm1.btnSkill11Click(Sender: TObject);
begin
  if MyBrain.w_CornerSetup then Exit;

  if GCD <= 0 then begin
    if ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PASS'+ EndOfLine);
    GCD := GCD_DEFAULT;
    PanelCorner.Visible := false;
  end;

end;


procedure TForm1.btnStandingsClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    tcp.SendStr(  'standings' + EndofLine  );
    GCD := GCD_DEFAULT;
  end;
 { TODO -con the road : riceve in zlib la query pvp dell m.i. vicine a me }
end;

procedure TForm1.Button10Click(Sender: TObject);
begin
  {$ifdef tools}
  if SelectedPlayer = nil  then Exit;

  if GCD <= 0 then begin
    tcp.SendStr(  'testcorner,' + SelectedPlayer.ids + EndofLine  );
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}

{ brainServer.tsScript.Add('SERVER_POS,' + SelectedPlayer.ids ) ;
 brainServer.CornerSetup ( SelectedPlayer );
// brainServer.tsScript.Add('E') ;
 brainServer.SaveData;
// ClientNotifyFileData (Dir_Data + Format('%.*d',[3, brainServer.incMove]) + '.ini');
  CopyFile(PChar(brainserver.Dir_Data + Format('%.*d',[3, brainServer.incMove]) + '.ini'),PChar(Dir_Data + Format('%.*d',[3, brainServer.incMove]) + '.ini'), false);
 inc(brainServer.incMove);}

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'setplayer,' +  Edit3.Text + ',' +  RzNumericEdit1.Text + ',' +  RzNumericEdit2.Text + EndOfLine ) ;
    GCD := GCD_DEFAULT;

  end;
{$endif tools}
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i: integer;
begin
  {$ifdef tools}
  memoC.Lines.Clear ;
  for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
    memoC.Lines.Add((MyBrain.lstSoccerPlayer [i].Ids + '.' +
                     MyBrain.lstSoccerPlayer [i].surname + '.' +
                  //   inttostr(MyBrain.lstSoccerPlayer [i].BallControl)) );
                     Inttostr(MyBrain.lstSoccerPlayer [i].cellx) + '.' +
                     inttostr(MyBrain.lstSoccerPlayer [i].celly)) );
  end;
  {$endif tools}

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  {$ifdef tools}
  CheckBox3.Enabled := False;
  ThreadCurMove.Enabled := False;
  if  RzSpinEdit1.Value > 0 then
   ClientLoadBrainMM ( trunc( RzSpinEdit1.Value - 1) );
  CurrentIncMove :=  trunc( RzSpinEdit1.Value);
  ClientLoadScript( trunc( RzSpinEdit1.Value)  );
  if Mybrain.tsScript.Count = 0 then begin
    ClientLoadBrainMM ( trunc( RzSpinEdit1.Value) );
  end
  else
    ElaborateTsScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
  {$endif tools}
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  MyBrain.AI_Think(MyBrain.TeamTurn);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'setball,' + RzNumericEdit1.Text + ',' +  RzNumericEdit2.Text + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}
end;


procedure TForm1.Button7Click(Sender: TObject);
var
  i,c: Integer;
  aPoint : PPointL;
  bmp: SE_Bitmap;
  aSprite,aSEField: SE_Sprite;
begin
  {$ifdef tools}

  if GameScreen <> ScreenLiveMatch  then Exit;


    for i:= 0 to 30 do begin
      aSprite := se_field.FindSprite('shotcell'+inttostr(i));
      if aSprite <> nil then
        se_field.RemoveSprite (aSprite);
    end;

    bmp:= SE_Bitmap.Create (20,12);
    bmp.Bitmap.Canvas.Brush.Color := clRed;
    bmp.Bitmap.Canvas.Ellipse(2,2,19,7);
    for i:= 0 to Mybrain.ShotCells.Count -1 do begin
          if (Mybrain.ShotCells[i].DoorTeam <> SelectedPlayer.Team) and
            (Mybrain.ShotCells[i].CellX = SelectedPlayer.CellX) and (Mybrain.ShotCells[i].CellY = SelectedPlayer.CellY) then begin
          // sono sopra questa shotcell
          // tra le celle adiacenti, solo la X attuale e ciclo per le Y
           //   aShotCell := brain.ShotCells[I];

          for c := 0 to  Mybrain.ShotCells[i].subCell.Count -1 do begin
            aPoint := Mybrain.ShotCells[i].subCell.Items [c];
            aSEField := SE_field.FindSprite(IntToStr (aPoint.X ) + '.' + IntToStr (aPoint.Y ));

            aSprite := se_field.CreateSprite  ( bmp.Bitmap , 'shotcell'+inttostr(c),1,1,100, aSEField.Position.X ,aSEField.Position.Y,true);
            aSprite.Priority := 30;

            //anOpponent := Brain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          end;
      end;
    end;
    bmp.Free;
  {$endif tools}

end;

procedure TForm1.Button8Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'randomstamina' + EndofLine  );
    GCD := GCD_DEFAULT;
  end;
{$endif tools}
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Timer1.Enabled := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  I,x,y: Integer;
  ini : TIniFile;
begin
  {$ifdef tools}
  btnReplay.Visible := True;
  //ToolSpin.Visible := True;
  Panel1.Left := 0;
  Panel1.Top := 0;

  Panel1.Visible := True;
  Panel1.BringToFront;

  {$endif tools}
  TsUniforms[0]:= Tstringlist.create;
  TsUniforms[1]:= Tstringlist.create;

  for I := 0 to 255 do begin
    MM3[i]:= TMemoryStream.Create;
  end;

  CurrentIncMove := 0;
  lstInteractivePlayers:= TList<TInteractivePlayer>.create;
  lblNick0.Caption := '';
  lblNick1.Caption := '';


  edtSell.Left := ( (PanelSell.Width div 2) - (edtSell.Width div 2) )  ;
//////  edtBid.Top := lblSurname.top;

  FormatSettings.DecimalSeparator := '.';
  RandGen := TtdCombinedPRNG.Create(0, 0);
  MyBrainFormation:= TSoccerBrain.Create ('Formation');

  GCD:= 0;
  tsFtpXXX:= TStringList.Create ;

  //form1.Height  := iraTheater1.Top + iraTheater1.Height +35;
  MyBrain := TSoccerBrain.Create(  '') ;
  MyBrain.incMove := 0; // +1 nella ricerca .ini

  lstPlayers:= TobjectList<TSoccerPlayer>.Create(true);


  TsCoa:= Tstringlist.Create;
  TsCod:= Tstringlist.Create;

  AnimationScript:= TAnimationScript.Create ;
  AnimationScript.memo  := memo3;
  MainThread.Enabled := true;
//  CreateRewards;

  FormationsPreset := TList<TFormation>.Create;
  CreateFormationsPreset;

  dir_tmp := ExtractFilePath(application.exename) + 'bmp\tmp\';
  dir_stadium := ExtractFilePath(application.exename) + 'bmp\stadium\';
  dir_ball := ExtractFilePath(application.exename) + 'bmp\ball\';
  dir_skill := ExtractFilePath(application.exename) + 'bmp\skill\';
  dir_player := ExtractFilePath(application.exename) + 'bmp\player\';
  dir_interface := ExtractFilePath(application.exename) + 'bmp\interface\';
  dir_data := ExtractFilePath(application.exename) + 'data\';
  dir_sound := ExtractFilePath(application.exename) + 'sounds\';
  dir_attributes := ExtractFilePath(application.exename) + 'bmp\attributes\';
  dir_help := ExtractFilePath(application.exename) + 'help\';
  dir_talent := ExtractFilePath(application.exename) +  'bmp\talent\';
  LoadTranslations;


  Application.ProcessMessages ;

  // rispetto l'esatto ordine dei talenti sul DB
  tsTalents := Tstringlist.Create;
  tsTalents.add  ('goalkeeper');
  tsTalents.add ('challenge'); // lottatore
  tsTalents.add ('toughness'); // durezza
  tsTalents.add ('power');      // potenza
  tsTalents.add  ('crossing');
  tsTalents.add  ('longpass');  // solo distanza
  tsTalents.add  ('experience');  // pressing gratis
  tsTalents.add  ('dribbling');
  tsTalents.add  ('bulldog');
  tsTalents.add  ('offensive');
  tsTalents.add  ('defensive');
  tsTalents.add  ('bomb');
  tsTalents.add  ('playmaker');
  tsTalents.add  ('faul');
  tsTalents.add  ('marking');
  tsTalents.add  ('Positioning');
  tsTalents.add  ('freekicks');

  LstSkill[0]:= 'Move';
  LstSkill[1]:= 'Short.Passing';
  LstSkill[2]:= 'Lofted.Pass';
  LstSkill[3]:= 'Crossing';
  LstSkill[4]:= 'Precision.Shot';
  LstSkill[5]:= 'Power.Shot';
  LstSkill[6]:= 'Dribbling';
  LstSkill[7]:= 'Protection';
  LstSkill[8]:= 'Tackle';
  LstSkill[9]:= 'Pressing';
  LstSkill[10]:= 'Corner.Kick';

  btnFormation.Caption := Translate('lbl_Formation');
  btnMainPlay.Caption := Translate('lbl_Play');
  btnWatchLive.Caption := Translate('lbl_watchlive');
  btnMarket.Caption := Translate('lbl_Market');
  btnStandings.Caption := Translate('lbl_Standings');
  btnExit.Caption := Translate('lbl_Exit');
  btnConfirmSell.Caption := Translate('lbl_Confirm');
  btnWatchLiveExit.Caption :=  Translate('lbl_Exit');
  btnSelCountryTeam.Caption :=  Translate('lbl_Select');

  btnDismiss0.Caption :=  Translate('lbl_Dismiss');
  lbl_ConfirmDismiss.Caption := Translate('lbl_ConfirmDismiss');

  btnFormationUniform.Caption :=  Translate('lbl_Uniform');
  ck_Jersey1.Caption :=   Translate('lbl_Jersey') + ' 1';
  ck_Jersey2.Caption :=   Translate('lbl_Jersey') + ' 2';
  ck_Shorts.Caption :=   Translate('lbl_Shorts');
  ck_Socks1.Caption :=   Translate('lbl_Socks')+ ' 1';
  ck_Socks2.Caption :=   Translate('lbl_Socks')+ ' 2';
  ck_HA.Buttons[0].Caption := Translate('lbl_Home');
  ck_HA.Buttons[1].Caption := Translate('lbl_Away');

  btnLogin.Caption := Translate('lbl_Login');

  btnMarketBack.Caption := Translate('lbl_Back');
  btnMarketRefresh.Caption := Translate('lbl_Search');

  lbl_MIF.Caption := Translate('lbl_MI');
  lbl_RankF.Caption := Translate('lbl_Rank');
  lbl_pointsF.Caption := Translate('lbl_Points');
  lbl_TurnF.Caption := Translate('lbl_NextTurn');
  lbl_MoneyF.Caption := Translate('lbl_Money');



  UniformBitmapBW := SE_Bitmap.Create (dir_player + 'bw.bmp');
  FaultBitmapBW := SE_Bitmap.Create (dir_interface + 'fault.bmp');
  InOutBitmap := SE_Bitmap.Create (dir_interface + 'inout.bmp');
  InOutBitmap.Stretch( 40,40 );

  se_gridColors.DefaultColWidth := se_gridColors.Width div 13;
  se_gridColors.Colors[0,0]:= clwhite;
  se_gridColors.Colors[1,0]:= clBlack;
  se_gridColors.Colors[2,0]:= clgray;
  se_gridColors.Colors[3,0]:= clred;
  se_gridColors.Colors[4,0]:= $004080FF;
  se_gridColors.Colors[5,0]:= clyellow;
  se_gridColors.Colors[6,0]:= clGreen;
  se_gridColors.Colors[7,0]:= clLime;
  se_gridColors.Colors[8,0]:= claqua;
  se_gridColors.Colors[9,0]:= clBlue;
  se_gridColors.Colors[10,0]:= $00FF0080; // purple
  se_gridColors.Colors[11,0]:= $00FF80FF;
  se_gridColors.Colors[12,0]:= clMaroon;


  TsWorldCountries:= TStringList.Create;
  TsNationTeams:= TStringList.Create;
  TsWorldCountries.StrictDelimiter := True;
  TsNationTeams.StrictDelimiter := True;

  SetTheaterMatchSize;

  btnSubs.Bitmaps.Up.LoadFromFile ( dir_interface + 'inout.bmp') ;
  btnSubs.Bitmaps.Down.LoadFromFile ( dir_interface + 'inout.bmp') ;
  btnAudioStadium.Bitmaps.Up.LoadFromFile ( dir_interface + 'audioon.bmp') ;
  btnAudioStadium.Bitmaps.Down.LoadFromFile ( dir_interface + 'audiooff.bmp') ;
  imgshpfree.Picture.LoadFromFile(  dir_interface + 'shpfree.bmp') ;

  DeleteDirData;

  advAllbrain.Left := 3;
  advAllbrain.top := 3;
  advAllBrain.ColWidths [1]:=0;


  InitSound;

  ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
  dir_log := ini.ReadString('directory','log','c:\temp');
  btnAudioStadium.Down := not  ( ini.ReadBool('sound','stadium',true)); //1=suona 0=no     down è 0, non suonare
  ini.Free;


  Timer1Timer(Timer1);
  Timer1.Enabled := True;
  ShowPanelBack;
  ShowLogin;
  //GameScreen := ScreenLogin;


  advDice.ColWidths [0] := 0;
  advDice.ColWidths [1] := 70;
  advDice.ColWidths [2] := 110;

  advDice.ColWidths [3] := 20;
  advDice.ColWidths [4] := 20;
  advDice.ColWidths [5] := 20;

  advDice.ColWidths [6] := 110;
  advDice.ColWidths [7] := 70;
  advDice.ColWidths [8] := 0 ;

  SE_Grid0.thrdAnimate.Priority := tpLowest;
  SE_GridXp0.thrdAnimate.Priority := tpLowest;

end;
procedure TForm1.InitSound;
begin
  DXSound1.Initialize;
  AudioCrowd := TAudioFileStream.Create(DXSound1.DSound);
  AudioCrowd.AutoUpdate := True;
  AudioCrowd.BufferLength := 1000;
  AudioCrowd.FileName := dir_sound +  'crowd.wav';
  AudioCrowd.Looped := true;

  {  Setting of format of primary buffer.  }
  MakePCMWaveFormatEx(WaveFormat, 44100, AudioCrowd.Format.wBitsPerSample, 2);
  DXSound1.Primary.SetFormat(WaveFormat);

  DXSound2.Initialize;
  Audionogol := TAudioFileStream.Create(DXSound2.DSound);
  Audionogol.AutoUpdate := True;
  Audionogol.BufferLength := 1000;
  Audionogol.FileName := dir_sound + 'nogol.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, Audionogol.Format.wBitsPerSample, 2);
  DXSound2.Primary.SetFormat(WaveFormat);


  DXSound3.Initialize;
  AudioCrossbar := TAudioFileStream.Create(DXSound3.DSound);
  AudioCrossbar.AutoUpdate := True;
  AudioCrossbar.BufferLength := 1000;
  AudioCrossbar.FileName := dir_sound + 'crossbar.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioCrossbar.Format.wBitsPerSample, 2);
  DXSound3.Primary.SetFormat(WaveFormat);

  DXSound4.Initialize;
  AudioBounce := TAudioFileStream.Create(DXSound4.DSound);
  AudioBounce.AutoUpdate := True;
  AudioBounce.BufferLength := 1000;
  AudioBounce.FileName :=dir_sound +  'bounce.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioBounce.Format.wBitsPerSample, 2);
  DXSound4.Primary.SetFormat(WaveFormat);

  DXSound5.Initialize;
  Audiogol := TAudioFileStream.Create(DXSound5.DSound);
  Audiogol.AutoUpdate := True;
  Audiogol.BufferLength := 1000;
  Audiogol.FileName := dir_sound + 'gol.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, Audiogol.Format.wBitsPerSample, 2);
  DXSound5.Primary.SetFormat(WaveFormat);

  DXSound6.Initialize;
  AudioFaul := TAudioFileStream.Create(DXSound6.DSound);
  AudioFaul.AutoUpdate := True;
  AudioFaul.BufferLength := 1000;
  AudioFaul.FileName := dir_sound + 'faul.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioFaul.Format.wBitsPerSample, 2);
  DXSound6.Primary.SetFormat(WaveFormat);

  DXSound7.Initialize;
  AudioNet := TAudioFileStream.Create(DXSound7.DSound);
  AudioNet.AutoUpdate := True;
  AudioNet.BufferLength := 1000;
  AudioNet.FileName :=dir_sound +  'net.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioNet.Format.wBitsPerSample, 2);
  DXSound7.Primary.SetFormat(WaveFormat);

  DXSound8.Initialize;
  AudioShot := TAudioFileStream.Create(DXSound8.DSound);
  AudioShot.AutoUpdate := True;
  AudioShot.BufferLength := 1000;
  AudioShot.FileName :=dir_sound +  'shot.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioShot.Format.wBitsPerSample, 2);
  DXSound8.Primary.SetFormat(WaveFormat);

  DXSound9.Initialize;
  AudioTackle := TAudioFileStream.Create(DXSound9.DSound);
  AudioTackle.AutoUpdate := True;
  AudioTackle.BufferLength := 1000;
  AudioTackle.FileName :=dir_sound +  'tackle.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioTackle.Format.wBitsPerSample, 2);
  DXSound9.Primary.SetFormat(WaveFormat);

  DXSound10.Initialize;
  AudioGameOver := TAudioFileStream.Create(DXSound10.DSound);
  AudioGameOver.AutoUpdate := True;
  AudioGameOver.BufferLength := 1000;
  AudioGameOver.FileName :=dir_sound +  'gameover.wav';

  MakePCMWaveFormatEx(WaveFormat, 44100, AudioGameOver.Format.wBitsPerSample, 2);
  DXSound10.Primary.SetFormat(WaveFormat);


end;
procedure TForm1.FormDestroy(Sender: TObject);
var
  i: integer;
  ini : TIniFile;
begin
  ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
  ini.Writebool('sound','stadium', not btnAudioStadium.down );  //1=suona 0=no     down è 0, non suonare
  ini.Free;

  FaultBitmapBW.Free;
  UniformBitmapBW.Free;
  tsUniforms[1].Free;
  tsUniforms[0].Free;

  lstInteractivePlayers.Free;
  RandGen.free;
  tsFtpXXX.Free;
  AudioCrowd.free;
  AudioFaul.free;
  AudioCrossbar.free;
  AudioBounce.free;
  AudioNoGol.free;
  AudioGol.free;
  AudioNet.free;
  AudioShot.Free;
  AudioTackle.Free;
  AudioGameOver.Free;

  DXSound1.Finalize;
  DXSound2.Finalize;
  DXSound3.Finalize;
  DXSound4.Finalize;
  DXSound5.Finalize;
  DXSound6.Finalize;
  DXSound7.Finalize;
  DXSound8.Finalize;
  DXSound9.Finalize;
  DXSound10.Finalize;

  se_players.RemoveAllSprites ;
  se_ball.RemoveAllSprites ;
  se_interface.RemoveAllSprites ;
  se_field.RemoveAllSprites ;
  se_numbers.RemoveAllSprites ;

  TsCoa.free;
  TsCod.free;

  AnimAtionScript.Reset;
  AnimationScript.Ts.Free;
  AnimationScript.Free;
  TranslateMessages.Free;
  tsTalents.free;
  TsWorldCountries.Free;
  TsNationTeams.Free;

  lstPlayers.Free;
  for I := 0 to 255 do begin
    MM3[i].Free;
  end;
  //  If MyBrainFormation <> nil then MyBrainFormation.free;
//  if Mybrain <> nil then MyBrain.free;
end;

procedure TForm1.SetTheaterMatchSize ;
begin
  form1.Width := 1366;
  Form1.Height := 738;
  se_theater1.VirtualWidth := 40*16; // 12 + 4 per le riserve a sinistra e destra
  se_theater1.Virtualheight := 40*7;
  se_theater1.Width := se_theater1.VirtualWidth ;
  se_theater1.Height  := se_theater1.Virtualheight ;//960 ;
  se_theater1.Left := (form1.Width div 2) - (SE_Theater1.Width div 2);
  se_theater1.Top := (form1.Height div 2) - (SE_Theater1.Height div 2);
  PanelSkillSE.Left := (form1.Width div 2) - (PanelSkillSE.Width div 2 ) ;
  PanelSkillSE.Top := SE_Theater1.Top + SE_Theater1.Height ;

end;


procedure TForm1.SE_ballSpriteDestinationReached(ASprite: SE_Sprite);
begin
//  MyBrain.Ball.Moving := False;
 //se è dentro la porta playsound gol e stadio

 if inGolPosition (ASprite.Position ) then  begin


   AudioNet.Position := 0;
   AudioNet.Play;
//   playsound ( pchar (dir_sound +  'net.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
//   ASprite.PositionY:= ASprite.Position.Y +1; // fix sound net 2 volte
//   Sleep(300);
//   playsound ( pchar (dir_sound +  'gol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   AudioGol.Position := 0;
   AudioGol.Play;
 end
 else if inCrossBarPosition (ASprite.Position ) then begin
//   playsound ( pchar (dir_sound +  'crossbar.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   AudioCrossBar.Position := 0;
   AudioCrossBar.Play;

//   ASprite.PositionY:= ASprite.Position.Y +1; // fix sound crossbar 2 volte
//   Sleep(300);
   AudioBounce.Position := 0;
   AudioBounce.Play;

//   playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   AudioNoGol.Position := 0;
   AudioNoGol.Play;
 end
 else if inGKCenterPosition (ASprite.Position ) then begin
//   playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   AudioNoGol.Position := 0;
   AudioNoGol.Play;
 end;
end;

procedure TForm1.BtnFormationBackClick(Sender: TObject);
begin
  if PanelUniform.Visible then
    Exit;

  WAITING_STOREFORMATION := True;
  GameScreen := ScreenWaitingFormation;
  SetTcpFormation;
//ShowMain;
end;

procedure TForm1.BtnFormationResetClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    GCD := GCD_DEFAULT;
    if PanelUniform.Visible then
      Exit;
    WAITING_GETFORMATION:=true;
    tcp.SendStr(  'resetformation' + endofline);
  end;

end;

procedure TForm1.BtnFormationUniformClick(Sender: TObject);
begin
  if PanelUniform.Visible then
    Exit;

  PanelUniform.Left := (PanelBack.Width div 2) - (PanelUniform.width div 2);
  PanelUniform.Top := (PanelBack.height div 2) - (PanelUniform.height div 2);
  PanelUniform.Visible:= True;

end;

procedure TForm1.se_gridColorsClickCell(Sender: TObject; ARow, ACol: Integer);
var
  UniformBitmap: SE_Bitmap;
  ha : Byte;
begin
    if ck_HA.Buttons[0].Checked then
     ha := 0
     else ha :=1;
    if ck_Jersey1.checked then
      TSUniforms[ha][0] := IntToStr( aCol )
      else if ck_Jersey2.checked then
      TSUniforms[ha][1] := IntToStr( aCol )
      else if ck_Shorts.checked then
      TSUniforms[ha][2] := IntToStr( aCol )
      else if ck_Socks1.checked then
      TSUniforms[ha][3] := IntToStr( aCol )
      else if ck_Socks2.checked then
      TSUniforms[ha][4] := IntToStr( aCol );

    UniformBitmap := SE_Bitmap.Create (dir_player + 'bw.bmp');
    PreLoadUniform( ha, UniformBitmap   );  // usa tsuniforms e  UniformBitmapBW
    UniformBitmap.free;
    UniformPortrait.Bitmaps.Disabled.LoadFromFile(dir_tmp + 'color' + IntToStr(ha)+ '.bmp');
//    se_portrait1.Bitmaps.Disabled.LoadFromFile(dir_tmp + 'se_0b.bmp');
end;

procedure TForm1.se_gridskillGetCellCursor(Sender: TObject; ACol, ARow, X, Y: Integer; var ACursor: TCursor);
var
  aSeField : SE_Sprite;
begin
  ACursor := crHandPoint;
  // se ho già cliccato sulla skill passando sul mouse sopra ad un'altyra skill non creo i circle
  if WaitForXY_Move or  WaitForXY_ShortPass or WaitForXY_LoftedPass or WaitForXY_Crossing or  WaitForXY_Dribbling
    then Exit;


  if (ACol = se_gridskilloldCol) and (ARow = se_gridskilloldRow) then Exit;
  se_gridskilloldCol := ACol;
  se_gridskilloldRow := ARow;

  SE_interface.RemoveAllSprites;
  //SE_circle.RemoveAllSprites;
  HighLightFieldFriendly_hide;

  if se_gridskill.Cells[0,aRow]= 'Tackle' then
    TackleMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Move' then
    MovMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Short.Passing' then
    ShpMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Lofted.Pass' then
    LopMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Crossing' then
    CroMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Dribbling' then
    DriMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Precision.Shot' then
    PrsMouseEnter ( nil )
  else if se_gridskill.Cells[0,aRow]= 'Power.Shot' then
    PosMouseEnter ( nil );


end;

procedure TForm1.SE_GridXP0GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
begin

  if GCD <= 0 then begin
    GCD := GCD_DEFAULT;
    if se_gridxp0.cells [ CellX, CellY ].BackColor = clgray then begin  // clgray indica che può passare di livello
      WAITING_GETFORMATION:= True;
      case CellY of
        0: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',speed'  + EndofLine);
        end;
        1: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',defense'  + EndofLine);
        end;
        2: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',passing'  + EndofLine);
        end;
        3: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',ballcontrol'  + EndofLine);
        end;
        4: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',shot'  + EndofLine);
        end;
        5: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',heading'  + EndofLine);
        end;
        // 6 vuota
        7..23: begin
          tcp.SendStr( 'levelup,'+ se_gridxp0.SceneName + ',' + IntTostr (CellY - 6) + EndofLine); // i talenti qui sotto
        end;
      end;
    end;
  end;
{
    GridXP.Cells[0,7] := Translate('talent_Goalkeeper');
    GridXP.Cells[0,8] :=  Translate('talent_Challenge');
    GridXP.Cells[0,9] :=  Translate('talent_Toughness');
    GridXP.Cells[0,10] := Translate('talent_Power');
    GridXP.Cells[0,11] := Translate('talent_Crossing');
    GridXP.Cells[0,12] := Translate('talent_Long.Pass');
    GridXP.Cells[0,13] := Translate('talent_Experience');
    GridXP.Cells[0,14] := Translate('talent_Dribbling');
    GridXP.Cells[0,15] := Translate('talent_Bulldog');
    GridXP.Cells[0,16] := Translate('talent_Offensive');
    GridXP.Cells[0,17] := Translate('talent_Defensive');
    GridXP.Cells[0,18] := Translate('talent_Bomb');
    GridXP.Cells[0,19] := Translate('talent_Playmaker');
    GridXP.Cells[0,20] := Translate('talent_Faul');
    GridXP.Cells[0,21] := Translate('talent_Marking');
    GridXP.Cells[0,22] := Translate('talent_Positioning');
    GridXP.Cells[0,23] := Translate('talent_FreeKicks');    }

end;


procedure TForm1.SE_GridXP0GridCellMouseMove(Sender: TObject; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
var
  a,b: Integer;
  Ts:TStringList;
begin
  if Length ( SE_GridXP0.Cells[1,CellY].Text) >= 5 then  begin

    ts := TStringList.Create;
    ts.Delimiter := '/';
    ts.StrictDelimiter:= True;
    ts.DelimitedText := SE_GridXP0.Cells[1,CellY].text;

    a := StrToInt(ts[0]);
    b := StrToInt(ts[1]);
    if a >= b then begin

      Cursor := crHandPoint;

    end
    else Cursor := crDefault;

    ts.Free;

  end;
end;


{procedure TForm1.se_gridXP1GetCellCursor(Sender: TObject; ACol, ARow, X, Y: Integer; var ACursor: TCursor);
var
  a,b: Integer;
  Ts:TStringList;
begin

  if Length ( se_gridXP1.Cells[1,aRow]) >= 5 then  begin

    ts := TStringList.Create;
    ts.Delimiter := '/';
    ts.StrictDelimiter:= True;
    ts.DelimitedText := se_gridXP1.Cells[1,aRow];

    a := StrToInt(ts[0]);
    b := StrToInt(ts[1]);
    if a >= b then begin

      ACursor := crHandPoint;

    end
    else aCursor := crDefault;

    ts.Free;

  end;
end;  }

procedure TForm1.InitializeTheaterMatch;
var
  i: Integer;
  aField: Se_Sprite;
begin
  se_theater1.Active := False;
  for I := 0 to se_theater1.EngineCount -1 do begin
    se_Theater1.Engines [i].RemoveAllSprites ;
  end;
  SetTheaterMatchSize;
  createField;

  se_Theater1.Visible := True;
  se_Theater1.Active := True;

end;

procedure TForm1.InitializeTheaterFormations;
var
  i: Integer;
begin
  se_theater1.Active := False;
  for I := 0 to se_theater1.EngineCount -1 do begin
    se_Theater1.Engines [i].RemoveAllSprites ;
  end;
  SetTheaterMatchSize;
  createField;
  se_Theater1.sceneName := 'tactics';
  se_theater1.Active := true;
  se_Theater1.Visible := True;
  PanelFormationSE.Visible := True;

end;
function TForm1.softlight(aColor:Tcolor): TColor;
var
  g, b, r: integer;
  aRGB: TRGB;
begin
  aRGB := TColor2TRGB(aColor);
  aRGB.b:=  i_softlight( aRGB.b,aRGB.b);
  aRGB.g:=  i_softlight( aRGB.g,aRGB.g);
  aRGB.r:=  i_softlight( aRGB.r,aRGB.r);
  result := TRGB2TColor ( aRGB );
end;
function TForm1.DarkColor(aColor: TColor): TColor;
const
  Initial_Darken_Level = 0.25;
  Darkness_Reduction = 0.5;
var
  iX, iY: integer;
  ppx: pRGB;
  aRGB: TRGB;
  rr, gg, bb: integer;
  iFadeStep: integer;
  bDoDarken: Boolean;
begin
  if aColor= clblack then begin
   Result:=aColor;
  end
  else if aColor= clWhite then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 214;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clGray then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 87;
    aRGB.g := 87;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clRed then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 0;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= $004080FF then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 87;
    aRGB.b := 53;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clyellow then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 214;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clGreen then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 87;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clLime then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 214;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clAqua then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 214;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clBlue then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 0;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= $00FF0080 then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 87;
    aRGB.g := 0;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= $00FF0080 then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 87;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clMaroon then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 87;
    aRGB.g := 0;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end;



end;

function TForm1.i_softlight(ib, ia: integer): integer;
var
  a, b, r: double;
begin
  a := ia / 255;
  b := ib / 255;
  if b < 0.5 then
    r := 2 * a * b + sqr(a) * (1 - 2 * b)
  else
    r := sqrt(a) * (2 * b - 1) + (2 * a) * (1 - b);
  result := trunc(r * 255);
end;
procedure TForm1.PreloadUniform( ha:Byte;  var UniformBitmap: SE_Bitmap);
var
  x,y: Integer;
begin
    for x := 0 to UniformBitmap.Width-1 do begin
      for y := 0 to UniformBitmap.height-1 do begin

        if x > 48 then begin

           if (y > 21) and (y <= 55) then begin // magliette


            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack then
              UniformBitmap.Bitmap.Canvas.Pixels [x,y] := se_gridcolors.Colors [  StrToInt(TsUniforms[ha][0]), 0]  //<-- se fuori casa prende la maglia giusta
            else if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmap.Bitmap.Canvas.Pixels[x,y]  := se_gridcolors.Colors [  StrToInt(TsUniforms[ha][1]), 0];

           end

           else if (y > 55) and (y <= 70) then begin // pantaloncini
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmap.Bitmap.Canvas.Pixels [x,y] := se_gridcolors.Colors [  StrToInt(TsUniforms[ha][2]), 0]  //<-- se fuori casa prende la maglia giusta
           end

           else if (y > 77) then begin // calzettoni
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clBlack then
              UniformBitmap.Bitmap.Canvas.Pixels[x,y]  := se_gridcolors.Colors [  StrToInt(TsUniforms[ha][3]), 0]  //<-- se fuori casa prende la maglia giusta
            else if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmap.Bitmap.Canvas.Pixels [x,y] := se_gridcolors.Colors [  StrToInt(TsUniforms[ha][4]), 0];
           end;

        end

        else begin  // schiarisco

           if (y > 21) and (y <= 55) then begin // magliette


            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clBlack then
              UniformBitmap.Bitmap.Canvas.Pixels[x,y]  := DarkColor( se_gridcolors.Colors [  StrToInt(TsUniforms[ha][0]), 0])  //<-- se fuori casa prende la maglia giusta
            else if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmap.Bitmap.Canvas.Pixels [x,y] := DarkColor( se_gridcolors.Colors [  StrToInt(TsUniforms[ha][1]), 0]);

           end

           else if (y > 55) and (y <= 70) then begin // pantaloncini
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmap.Bitmap.Canvas.Pixels[x,y]  := DarkColor( se_gridcolors.Colors [  StrToInt(TsUniforms[ha][2]), 0])  //<-- se fuori casa prende la maglia giusta
           end

           else if (y > 77) then begin // calzettoni
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clBlack then
              UniformBitmap.Bitmap.Canvas.Pixels[x,y]  := DarkColor( se_gridcolors.Colors [  StrToInt(TsUniforms[ha][3]), 0])  //<-- se fuori casa prende la maglia giusta
            else if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmap.Bitmap.Canvas.Pixels[x,y]  := DarkColor( se_gridcolors.Colors [  StrToInt(TsUniforms[ha][4]), 0]);
           end;
        end;


      end;
    end;

    UniformBitmap.Bitmap.SaveToFile(dir_tmp + 'color' + IntToStr(ha) + '.bmp');
end;
procedure TForm1.PreloadUniformGK( ha:Byte;  var UniformBitmapGK: SE_Bitmap);
var
  x,y: Integer;
begin
    for x := 0 to UniformBitmapGK.Width-1 do begin
      for y := 0 to UniformBitmapGK.height-1 do begin

        if x > 48 then begin

           if (y > 21) and (y <= 55) then begin // magliette


            if (UniformBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack) or (UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite)  then
              UniformBitmapGK.Bitmap.Canvas.Pixels [x,y] := clGray;

           end

           else if (y > 55) and (y <= 70) then begin // pantaloncini
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite  then
              UniformBitmapGK.Bitmap.Canvas.Pixels [x,y] := clBlack;
           end

           else if (y > 77) then begin // calzettoni
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clBlack then
              UniformBitmapGK.Bitmap.Canvas.Pixels[x,y]  := clBlack
            else if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmapGK.Bitmap.Canvas.Pixels [x,y] := clGray;
           end;

        end

        else begin  // schiarisco

           if (y > 21) and (y <= 55) then begin // magliette


            if (UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clBlack) or (UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite) then
              UniformBitmapGK.Bitmap.Canvas.Pixels[x,y]  := DarkColor( clGray );  //<-- se fuori casa prende la maglia giusta

           end

           else if (y > 55) and (y <= 70) then begin // pantaloncini
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmapGK.Bitmap.Canvas.Pixels[x,y]  := DarkColor( clBlack )  //<-- se fuori casa prende la maglia giusta
           end

           else if (y > 77) then begin // calzettoni
            if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clBlack then
              UniformBitmapGK.Bitmap.Canvas.Pixels[x,y]  := DarkColor( clBlack )  //<-- se fuori casa prende la maglia giusta
            else if UniformBitmapBW.Bitmap.Canvas.Pixels[x,y]= clWhite then
              UniformBitmapGK.Bitmap.Canvas.Pixels[x,y]  := DarkColor( clGray );
           end;
        end;


      end;
    end;

    UniformBitmapGK.Bitmap.SaveToFile(dir_tmp + 'colorgk.bmp');
end;
procedure TForm1.ColorizeFault( Team:Byte;  var FaultBitmap: SE_Bitmap);
var
  x,y: Integer;
begin
(* mantengo x per i 2 colori *)
    for x := 0 to FaultBitmap.Width-1 do begin
      for y := 0 to FaultBitmap.height-1 do begin

        if x > 19 then begin


             // maglia 1
            if FaultBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack then
              FaultBitmap.Bitmap.Canvas.Pixels [x,y] := se_gridcolors.Colors [  StrToInt(TsUniforms[Team][0]), 0];


        end

        else begin  // schiarisco

             // maglia 2
            if FaultBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack then
              FaultBitmap.Bitmap.Canvas.Pixels [x,y] := se_gridcolors.Colors [  StrToInt(TsUniforms[Team][1]), 0];

        end;


      end;
    end;

//    FaultBitmap.Bitmap.SaveToFile(dir_tmp + 'color.bmp');
end;
procedure TForm1.ClientLoadFormation ;
var
  i,x,y: Integer;
  count: Byte;
  aPlayer: TSoccerPlayer;
  guid,age,Matches_Played,Matches_Left,stamina,Injured, yellowcard, Disqualified,Cur,lenSurname,LenHistory,LenXP,onmarket,face: Integer;
  rank: Byte;
  AIFormation_x,AIFormation_y: ShortInt;
  lenteamName, lenUniformH,lenUniformA : Integer;
  Surname, talent : string;
  DisqualifiedSprite, InjuredSprite, YellowSprite: se_SubSprite;
  aMirror: TPoint;
  FC: TFormationCell;
  TvCell,TvReserveCell: TPoint;
  aCell: TSoccerCell;
  bmp: se_BITMAP;
  aSEField: SE_Sprite;
  SS: TStringStream;
  dataStr, Attributes,tmps : string;
  GraphicSe: boolean;
  TalentID: Byte;
  aTalents: string[25];
  TsHistory,tsXP: TStringList;
  DefaultSpeed,DefaultDefense,DefaultPassing,DefaultBallControl  ,DefaultShot,DefaultHeading: Byte;
  UniformBitmap,UniformBitmapGK:SE_Bitmap;
  aColor: TColor;
procedure setupBMp (bmp:TBitmap; aColor: Tcolor);
begin
  BMP.Canvas.Font.Size := 8;
  BMP.Canvas.Font.Quality := fqAntiAliased;
  BMP.Canvas.Font.Color := aColor;
  BMP.Canvas.Font.Style :=[fsbold];
  BMP.Canvas.Brush.Style:= bsClear;
end;
begin


  if  WAITING_GETFORMATION then begin
    WAITING_GETFORMATION := False;
    GameScreen := ScreenFormation;
    GraphicSE:= True;
  end
  else if  WAITING_STOREFORMATION then begin
    WAITING_STOREFORMATION := False;
    GameScreen := ScreenMain;
    GraphicSE:= false;
  end;

  // MM3 e buf3 contengono il buffer del team
  TotMarket := 0;

  MyBrainFormation.ClearReserveSlot;
  MyBrainFormation.lstSoccerPlayer.Clear;

  SS:= TStringStream.Create;
  SS.Size := MM3[0].Size;
  Mm3[0].Position := 0;
  SS.CopyFrom( MM3[0], MM3[0].size );
  dataStr := SS.DataString;
  SS.Free;

  Cur := 0;
  MyGuidTeam:= PDWORD(@buf3 [0][ cur ])^;
  Cur := Cur + 4;
  lenteamName :=  Ord( buf3[0] [ cur ]);
  MyGuidteamName := MidStr( dataStr, cur + 2  , lenteamName );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
  cur  := cur + lenteamName + 1;

  lenUniformH :=  Ord( buf3[0] [ cur ]);
  tmps := MidStr( dataStr, cur + 2  , lenUniformH );
  TsUniforms[0].CommaText := tmps;


  cur  := cur + lenUniformH + 1;
  lenUniformA :=  Ord( buf3[0] [ cur ]);
  tmps := MidStr( dataStr, cur + 2  , lenUniformA );
  TsUniforms[1].CommaText := tmps;

  cur  := cur + lenUniformA + 1;
  NextHa :=  Ord( buf3[0] [ cur ]); // prossima partita in cas o fuori (home,away)
  Cur := Cur + 1;
  mi :=  PDWORD(@buf3[0] [ cur ])^; // media inglese
  Cur := Cur + 4;
  points :=  PDWORD(@buf3[0] [ cur ])^; // punti classifica
  Cur := Cur + 4;
  MatchesPlayedTeam :=  PDWORD(@buf3[0] [ cur ])^; // totale partite giocate
  Cur := Cur + 4;
  Money :=  PDWORD(@buf3[0] [ cur ])^; // denaro del team
  Cur := Cur + 4;
  Rank :=  Ord( buf3[0] [ cur ]);     // rank del team
  Cur := Cur + 1;
  lbl_TeamName.Caption := MyGuidteamName;
  lbl_MIF.Caption := Translate('lbl_MI')  + ' ' + IntToStr(mi);
  lbl_RankF.Caption := Translate('lbl_Rank') + ' ' + IntToStr(rank);
  lbl_pointsF.Caption := Translate('lbl_Points') + ' ' + IntToStr(points);
  lbl_TurnF.Caption := Translate('lbl_NextTurn') + ' ' + IntToStr(MatchesPlayedTeam+1) + '/38' ;
  lbl_MoneyF.Caption := Translate('lbl_Money') + ' ' + IntToStr(Money)  ;

  // viene sempre caricato il default BW , poi modificato da uniforms TS
  if GraphicSE then begin
    // preload UniformH. metto il colore vero a sinistra. il destro lo schiarisco
    // in caso di nero e bianco ho i preset grigi.
    UniformBitmap := SE_Bitmap.Create (dir_player + 'bw.bmp');
    PreLoadUniform(NextHa, UniformBitmap);  // usa tsuniforms e  UniformBitmapBW
    UniformPortrait.Bitmaps.Disabled.LoadFromFile(dir_tmp + 'color0.bmp');
    Portrait0.Glyph.LoadFromFile(dir_tmp + 'color0.bmp');
    ck_HA.Buttons[NextHa].Checked := True;
    UniformBitmapGK := SE_Bitmap.Create (dir_player + 'bw.bmp');
    PreLoadUniformGK(NextHa, UniformBitmapGK);
  end;

  MyBrain.Score.DominantColor[0]:= StrToInt( TsUniforms[0][0] );
  if TsUniforms[0][0] = TsUniforms[0][1] then
    MyBrain.Score.FontColor[0]:= GetContrastColor(  StrToInt(TsUniforms[0][0]) )
    else MyBrain.Score.FontColor[0]:= StrToInt( TsUniforms[0][1] );

  MyBrain.Score.DominantColor[1]:= StrToInt( TsUniforms[1][0] );
  if TsUniforms[1][0] = TsUniforms[1][1] then
    MyBrain.Score.FontColor[1]:= GetContrastColor(  StrToInt(TsUniforms[1][0]) )
    else MyBrain.Score.FontColor[1]:= StrToInt( TsUniforms[1][1] );


  count := ord (buf3[0] [ cur ]);   // quanti player
  Cur := Cur + 1; //
  //PDWORD(@buf3[0] [ cur ])^;
    for I := 0 to count -1 do begin
      guid :=  PDWORD(@buf3[0] [ cur ])^; // player identificativo globale
      Cur := Cur + 4;
      lenSurname :=  Ord( buf3[0] [ cur ]);
      Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
      cur  := cur + lenSurname + 1;

      Matches_Played := PWORD(@buf3[0] [ cur ])^;  // partite giocate dle player
      Cur := Cur + 2 ;
      Matches_Left := PWORD(@buf3[0] [ cur ])^;    // partite rimanenti prima di finire la carriera
      Cur := Cur + 2 ;
      Age :=  Ord( buf3[0] [ cur ]);               // età
      Cur := Cur + 1 ;
      TalentID := Ord( buf3[0] [ cur ]);           // identificativo talento
      Cur := Cur + 1;

      if TalentID > 0 then                         // il talento lo carico anchein formato stringa
        aTalents := tsTalents [ TalentID -1]
        else aTalents := '';

      Stamina := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;

      DefaultSpeed := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultDefense := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultPassing := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultBallControl := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultShot := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultHeading := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      Attributes:= IntTostr( DefaultSpeed) + ',' + IntTostr( DefaultDefense) + ',' + IntTostr( DefaultPassing) + ',' + IntTostr( DefaultBallControl) + ',' +
                   IntTostr( DefaultShot) + ',' + IntTostr( DefaultHeading) ;

      AIFormation_x := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      AIFormation_y := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      injured := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      yellowcard := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      disqualified := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      onmarket := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      face :=  PDWORD(@buf3[0] [ cur ])^; // face bmp viso
      Cur := Cur + 4;


      aPlayer:= TSoccerPlayer.create(0,MyGuidTeam,Matches_Played,IntToStr(guid),'',surname,aTalents,Attributes);
      aPlayer.TalentId := TalentID;
      aPlayer.GuidTeam := MyguidTeam;
      aPlayer.Stamina := Stamina;
      aPlayer.AIFormationCellX := AIFormation_x;
      aPlayer.AIFormationCellY := AIFormation_y;
      aPlayer.Injured := injured;
      aPlayer.yellowcard := yellowcard;
      aPlayer.Disqualified := Disqualified;
      aPlayer.onmarket := Boolean( onmarket);
      TotMarket := TotMarket + onmarket;
      aPlayer.face := face;

      if GraphicSE then begin

        if aPlayer.TalentId <> 1 then
          aPlayer.SE_Sprite := se_Players.CreateSprite(UniformBitmap.Bitmap , aPlayer.Ids,1,1,1000,0,0,true)
        else
          aPlayer.SE_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);

        aPlayer.SE_Sprite.Scale := ScaleSprites;
//        aPlayer.se_sprite.BlendMode := SE_BlendLuminosity2;
      end;

      tsHistory := TStringList.Create;
      LenHistory :=  Ord( buf3[0] [ cur ]);
      tsHistory.commaText := MidStr( dataStr, cur + 2  , LenHistory );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
      cur  := cur + LenHistory + 1;
//      tsHistory.commaText := ini.readString('player' + IntToStr(i),'History','0,0,0,0,0,0' ); // <-- 6 attributes
      aPlayer.History_Speed         := StrToInt( tsHistory[0]);
      aPlayer.History_Defense       := StrToInt( tsHistory[1]);
      aPlayer.History_BallControl   := StrToInt( tsHistory[2]);
      aPlayer.History_Passing       := StrToInt( tsHistory[3]);
      aPlayer.History_Shot          := StrToInt( tsHistory[4]);
      aPlayer.History_Heading       := StrToInt( tsHistory[5]);
      tsHistory.Free;

      tsXP := TStringList.Create;
      LenXP :=  Ord( buf3[0] [ cur ]);
 //     tsXP.commaText := ini.readString('player' + IntToStr(i),'xp','0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' ); // <-- 6 attributes , 17 talenti
      tsXP.commaText := MidStr( dataStr, cur + 2  , LenXP );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
      cur  := cur + LenXP + 1;

      // rispettare esatto ordine dei talenti sul db
      aPlayer.xp_Speed         := aPlayer.xp_Speed + StrToInt( tsXP[0]);
      aPlayer.xp_Defense       := aPlayer.xp_Defense + StrToInt( tsXP[1]);
      aPlayer.xp_BallControl   := aPlayer.xp_BallControl + StrToInt( tsXP[2]);
      aPlayer.xp_Passing       := aPlayer.xp_Passing + StrToInt( tsXP[3]);
      aPlayer.xp_Shot          := aPlayer.xp_Shot + StrToInt( tsXP[4]);
      aPlayer.xp_Heading       := aPlayer.xp_Heading + StrToInt( tsXP[5]);

      aPlayer.xpTal_GoalKeeper       := aPlayer.xpTal_GoalKeeper + StrToInt( tsXP[6]);
      aPlayer.xpTal_Challenge        := aPlayer.xpTal_Challenge + StrToInt( tsXP[7]);
      aPlayer.xpTal_Toughness        := aPlayer.xpTal_Toughness + StrToInt( tsXP[8]);
      aPlayer.xpTal_Power            := aPlayer.xpTal_Power + StrToInt( tsXP[9]);
      aPlayer.xpTal_Crossing         := aPlayer.xpTal_Crossing + StrToInt( tsXP[10]);
      aPlayer.xptal_longpass         := aPlayer.xptal_longpass + StrToInt( tsXP[11]);
      aPlayer.xpTal_Experience       := aPlayer.xpTal_Experience + StrToInt( tsXP[12]);
      aPlayer.xpTal_Dribbling        := aPlayer.xpTal_Dribbling + StrToInt( tsXP[13]);
      aPlayer.xpTal_Bulldog          := aPlayer.xpTal_Bulldog + StrToInt( tsXP[14]);
      aPlayer.xpTal_midOffensive     := aPlayer.xpTal_midOffensive + StrToInt( tsXP[15]);
      aPlayer.xpTal_midDefensive     := aPlayer.xpTal_midDefensive + StrToInt( tsXP[16]);
      aPlayer.xpTal_Bomb             := aPlayer.xpTal_Bomb + StrToInt( tsXP[17]);
      aPlayer.xpTal_PlayMaker        := aPlayer.xpTal_Bomb + StrToInt( tsXP[18]);
      aPlayer.xpTal_faul             := aPlayer.xpTal_Bomb + StrToInt( tsXP[19]);
      aPlayer.xpTal_Marking          := aPlayer.xpTal_Bomb + StrToInt( tsXP[20]);
      aPlayer.xpTal_Positioning           := aPlayer.xpTal_Bomb + StrToInt( tsXP[21]);
      aPlayer.xpTal_freekicks        := aPlayer.xpTal_Bomb + StrToInt( tsXP[22]);

      tsXP.Free;


//      aPlayer.SpriteSE.Priority := i+1;
      MyBrainFormation.AddSoccerPlayer(aPlayer); // uso anche questa lista per trovare gli sprite inKeyDown
      if MyBrainFormation.isReserveSlot  ( AIFormation_x,AIFormation_y )  then begin // le riserve tutte a sinistra

          TvReserveCell:= MyBrainFormation.ReserveSlotTV [0,AIFormation_x,AIFormation_y  ];
          MyBrainFormation.PutInReserveSlot(aPlayer) ;

          if GraphicSE then begin

            aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.X ) + '.' + IntToStr (TvReserveCell.Y ));
            aPlayer.se_Sprite.Position := aSEField.Position;
          end;


      end
      else begin // player normali
        TvCell := MyBrainFormation.AIField [0,AIFormation_x,AIFormation_y];  // traduce solo celle del campo

        if GraphicSE then begin
          aSEField := SE_field.FindSprite(IntToStr (TvCell.X ) + '.' + IntToStr (TvCell.Y ));
          aPlayer.se_Sprite.Position := aSEField.Position;
        end;
        aPlayer.Cells := TvCell;
        aPlayer.DefaultCells := TvCell;

      end;


      if GraphicSE then begin
        if  aPlayer.YellowCard > 0  then begin
          YellowSprite := se_SubSprite.create (dir_interface + 'yellow.bmp','yellow', 0,0,true,true);
          setupBMp (YellowSprite.lBmp.Bitmap , clBlack );
          YellowSprite.lBmp.Bitmap.Canvas.TextOut(0,0, IntToStr(aPlayer.YellowCard));
          aPlayer.SE_Sprite.SubSprites.Add( YellowSprite ) ;
        end;
        if aPlayer.disqualified > 0 then begin
          DisqualifiedSprite := se_SubSprite.create ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true,true);
          setupBMp (DisqualifiedSprite.lBmp.Bitmap , clWhite );
          DisqualifiedSprite.lBmp.Bitmap.Canvas.TextOut(3,0, IntToStr(aPlayer.disqualified));
          aPlayer.SE_Sprite.SubSprites.Add( DisqualifiedSprite ) ;
        end;
        if aPlayer.injured > 0  then begin
          InjuredSprite := se_SubSprite.create (dir_interface + 'injured.bmp','injured', 0,0,true,true);
          setupBMp (InjuredSprite.lBmp.Bitmap , clMaroon );
          InjuredSprite.lBmp.Bitmap.Canvas.TextOut(0,0, IntToStr(aPlayer.Injured));
          aPlayer.SE_Sprite.SubSprites.Add( InjuredSprite ) ;
        end;
      end;
    end;

    if GraphicSE then
      UniformBitmap.Free;

    RefreshCheckFormationMemory;

end;
procedure TForm1.CreateNoiseTV;    // https://www.youtube.com/watch?v=BB7jEHPBf-4
var
  bmp:SE_Bitmap;
  aSprite: SE_Sprite;
  AString: string;
begin
  btnsell0.Visible := false;
  btnXp0.Visible := false;
  btndismiss0.Visible:= false;

  SE_field.RemoveAllSprites;
  SE_players.RemoveAllSprites;
  SE_interface.RemoveAllSprites;
  SE_interface.CreateSprite( dir_interface + 'noiseTV.bmp' , 'noiseTV' ,4,1, 10, (SE_Theater1.VirtualWidth div 2), (SE_Theater1.Virtualheight div 2) ,false );

  AString :=  Translate( 'lbl_waitingwatchlive');
  bmp:=SE_Bitmap.Create(300,200);
  bmp.bitmap.Canvas.font.Name := 'calibri';
  bmp.bitmap.Canvas.font.Size  := 16;
  bmp.bitmap.Canvas.font.Style := [fsBold];
  bmp.bitmap.Canvas.font.Color := clWhite-1;
  bmp.Width := bmp.Bitmap.Canvas.TextWidth(  AString );
  bmp.Height := bmp.Bitmap.Canvas.Textheight( AString);
  bmp.bitmap.Canvas.TextOut(0,0,AString);

  aSprite := SE_interface.CreateSprite( bmp.bitmap, 'waitingsignal',1,1,1000, (SE_Theater1.VirtualWidth div 2), SE_Theater1.Virtualheight  - 30 , true   );
  aSprite.Priority := 10;
  bmp.Free;
end;
procedure TForm1.Createfield;
var
  x,y: Integer;
  bmp: se_BITMAP;
  aSEField: SE_Sprite;
  aSubSprite: SE_subSprite;
begin
  SE_field.RemoveAllSprites;
  for x := -2 to 13 do begin
    for y := 0 to 6 do begin
      if IsOutSide(X,Y) then begin
        bmp:= se_bitmap.Create(40,40);
        bmp.Bitmap.Canvas.Brush.Color :=  $7B5139;
        bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
        aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),false );
        bmp.Free;
      end
      else begin
        bmp:= se_bitmap.Create(40,40);      // disegno le righe
        bmp.Bitmap.Canvas.Brush.Color :=  $328362;
        bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
        RoundBorder (bmp.Bitmap , bmp.Width , bmp.Height);
        if (x = 1) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 2) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 1) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 2) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            bmp.Bitmap.Canvas.MoveTo(bmp.Width-1 ,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 2) and ( y= 3) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(bmp.Width-1 ,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 10) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 9) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 10) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 9) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            bmp.Bitmap.Canvas.MoveTo(1 ,1);
            bmp.Bitmap.Canvas.LineTo(1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 9) and ( y= 3) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1 ,1);
            bmp.Bitmap.Canvas.LineTo(1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 0) and ( y= 3) then begin
            aSEField:= SE_field.CreateSprite( dir_stadium + 'door.bmp', IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 11) and ( y= 3) then begin
            aSEField := SE_field.CreateSprite( dir_stadium + 'door.bmp', IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
            aSEfield.Flipped:= True;
        end
        else
          aSEField := SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        bmp.Free;
      end;

      // aggiungo il subsprite
      bmp:= se_bitmap.Create(36,36);      // disegno le righe
      bmp.Bitmap.Canvas.Brush.Color :=  $48A881;//$3E906E;
      bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
      aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(x) + '.' + IntToStr(y), 2, 2, true, false );
      aSubSprite.lVisible:= false;
      aSEField.SubSprites.Add(aSubSprite);
      bmp.Free;

    end;
  end;


end;
procedure TForm1.RefreshCheckFormationMemory;
begin

    if CheckFormationTeamMemory then begin
      btnMainPlay.Enabled := True;
      SE_lblPlay.Font.Color := clGreen;
      SE_lblPlay.Caption := 'Formation OK' ;
    end
    else begin
      btnMainPlay.Enabled := false;
      SE_lblPlay.Font.Color := clRed;
      SE_lblPlay.Caption :=  'Invalid Formation' ;
    end;

end;
function TForm1.RndGenerate( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (1, Upper + 1));
end;
function TForm1.RndGenerate0( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (0, Upper + 1));
end;
function TForm1.RndGenerateRange( Lower, Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (Lower, Upper + 1));
end;

procedure TForm1.RoundBorder (bmp: TBitmap; w,h: Integer);
var
x,y: Integer;
begin

      bmp.Canvas.Pixels [0,0]:= $7B5139;
      bmp.Canvas.Pixels [0,1]:= $7B5139;
      bmp.Canvas.Pixels [0,2]:= $7B5139;
      bmp.Canvas.Pixels [1,0]:= $7B5139;
      bmp.Canvas.Pixels [2,0]:= $7B5139;

      bmp.Canvas.Pixels [w-3,0]:= $7B5139;
      bmp.Canvas.Pixels [w-2,0]:= $7B5139;
      bmp.Canvas.Pixels [w-1,0]:= $7B5139;
      bmp.Canvas.Pixels [w-1,1]:= $7B5139;
      bmp.Canvas.Pixels [w-1,2]:= $7B5139;

      bmp.Canvas.Pixels [w-3,h-1]:= $7B5139;
      bmp.Canvas.Pixels [w-2,h-1]:= $7B5139;
      bmp.Canvas.Pixels [w-1,h-1]:= $7B5139;
      bmp.Canvas.Pixels [w-1,h-2]:= $7B5139;
      bmp.Canvas.Pixels [w-1,h-3]:= $7B5139;

      bmp.Canvas.Pixels [0,h-3]:= $7B5139;
      bmp.Canvas.Pixels [0,h-2]:= $7B5139;
      bmp.Canvas.Pixels [0,h-1]:= $7B5139;
      bmp.Canvas.Pixels [1,h-1]:= $7B5139;
      bmp.Canvas.Pixels [2,h-1]:= $7B5139;

      for x := 0 to bmp.Width -1 do begin
          bmp.Canvas.Pixels [x,0]:= $7B5139;
          bmp.Canvas.Pixels [x,bmp.Height -1]:= $7B5139;
      end;
      for y := 0 to bmp.height -1 do begin
          bmp.Canvas.Pixels [0,y]:= $7B5139;
          bmp.Canvas.Pixels [bmp.width-1,y]:= $7B5139;
      end;


end;

function TForm1.findPlayerMyBrainFormation ( guid: string ): TSoccerPlayer;
var
  i: integer;
begin
  for I := 0 to MyBrainFormation.lstSoccerPlayer.Count -1 do begin
    if  MyBrainFormation.lstSoccerPlayer[i].Ids = guid then begin
      Result :=  MyBrainFormation.lstSoccerPlayer[i];
      Exit;
    end;

  end;

end;
procedure TForm1.CreateCircle( Player : TSoccerPlayer );
var
  filename : string;
  posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Circle : SE_Sprite;
begin
    fileName := dir_interface + 'circle' + IntToStr(Player.team) + '.bmp';
    if Player.team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;

    posX := Player.se_sprite.Position.X + ArrowDirection.offset.X;
    posY := Player.se_sprite.Position.Y + ArrowDirection.offset.Y;
    Circle := SE_interface.CreateSprite(filename,'Circle', 1,1,1000,  posX,posY, true);
    Circle.Scale := 10;

end;
procedure TForm1.CreateCircle( Team, CellX, CellY: integer );
var
  filename : string;
  X1,X2,Y1,Y2,posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Circle : SE_Sprite;
  aSeField: SE_Sprite;
begin

    fileName := dir_interface + 'circle' + IntToStr(team) + '.bmp';
    if team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;


    aSeField := SE_field.FindSprite( IntToStr(CellX) + '.' + IntToStr(CellY) );
    posX := aSeField.Position.X + ArrowDirection.offset.X;
    posY := aSeField.Position.Y + ArrowDirection.offset.Y;
    Circle := SE_interface.CreateSprite(filename,'Circle', 1,1,1000,  posX,posY, true);
    Circle.Scale := 10;

end;
procedure TForm1.CreateArrowDirection ( Player1 , Player2: TSoccerPlayer );
var
  filename : string;
  X1,X2,Y1,Y2,posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Arrow : SE_Sprite;
begin
  X1:= Player1.CellX;
  Y1:= Player1.CellY;
  X2:= Player2.CellX;
  Y2:= Player2.CellY;

  // se uguale creo un circle ed esco
  if (X1=X2) and (Y1=Y2) then begin
    fileName := dir_interface + 'circle' + IntToStr(Player1.team) + '.bmp';
    if Player1.team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;

    posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
    posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;

    Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
    Arrow.Scale := 10;
    Exit;
  end;

  fileName := dir_interface + 'arrow' + IntToStr(Player1.team) + '.bmp';

  ArrowDirection.angle :=   AngleOfLine ( Player1.se_sprite.Position , Player2.se_sprite.Position );

  if (X2 = X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 = X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 > X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := 0;
  end
  else if (X2 < X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := 0;
  end;

  posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
  posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;


  Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
  Arrow.Angle := ArrowDirection.angle ;
  Arrow.Scale := 16;

end;
procedure TForm1.CreateArrowDirection ( Player1 : TSoccerPlayer; CellX, CellY: integer );
var
  filename : string;
  X1,X2,Y1,Y2,posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Arrow : SE_Sprite;
begin
  X1:= Player1.CellX;
  Y1:= Player1.CellY;
  X2:= CellX;
  Y2:= CellY;

  // se uguale creo un circle ed esco
  if (X1=X2) and (Y1=Y2) then begin
    fileName := dir_interface + 'circle' + IntToStr(Player1.team) + '.bmp';
    if Player1.team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;

    posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
    posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;
    Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
    Arrow.Scale := 10;
    Exit;
  end;


  fileName := dir_interface + 'arrow' + IntToStr(Player1.team) + '.bmp';

  ArrowDirection.angle :=   AngleOfLine ( Point(Player1.CellX,Player1.CellY) , Point ( CellX, CellY));

  if (X2 = X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 = X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 > X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := 0;
  end
  else if (X2 < X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := 0;
  end;

  posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
  posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;

  Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
  Arrow.Angle := ArrowDirection.angle ;
  Arrow.Scale := 16;

end;

procedure TForm1.TackleMouseEnter ( Sender : TObject);
begin
  hidechances;
  PanelCombatLog.Left := PanelSkillSE.Left + PanelSkillSE.Width;
  advDice.RowCount := 1;
  advDice.Clear ;

  if Mybrain.Ball.Player <> nil then begin
    if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin

      CreateArrowDirection ( SelectedPlayer , Mybrain.Ball.Player );
      advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Defense')),
        SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(SelectedPlayer.Defense + SelectedPlayer.Tal_Toughness));
      advDiceWriteRow  ( Mybrain.Ball.Player.Team,  UpperCase(Translate('attribute_BallControl')),
        Mybrain.Ball.Player.SurName, Mybrain.Ball.Player.Ids, 'VS',IntToStr(Mybrain.Ball.Player.BallControl + Mybrain.Ball.Player.Tal_Power));
     // CreateTextChanceValueSE ( Mybrain.Ball.Player.ids, Mybrain.Ball.Player.BallControl + Mybrain.Ball.Player.tal_Power   , 0,0,0,0 );
     // CreateTextChanceValueSE ( SelectedPlayer.ids, SelectedPlayer.Defense + SelectedPlayer.tal_toughness  , 0,0,0,0);
    end;
  end;

end;

procedure TForm1.PrsMouseEnter ( Sender : TObject);
var
  i,ii,c : Integer;
  anOpponent,aGK: TSoccerPlayer;
  aPoint : PPointL;
  Modifier,BaseShot: Integer;
  aDoor, BarrierCell: TPoint;
  aSeField: SE_Sprite;
begin
  hidechances;

  PanelCombatLog.Left := PanelSkillSE.Left + PanelSkillSE.Width;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;
  Modifier := 0;
  aDoor := Mybrain.GetOpponentDoor ( SelectedPlayer );
  if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, adoor.X, adoor.Y  ) > PowerShotRange then exit;

    //////    CalculateChance  (BaseShot, aGK.Defense , chanceA,chanceB,chanceColorA,chanceColorB);
//////    CreateTextChanceValue (SelectedPlayer.ids,BaseShot, dir_skill + 'Precision.Shot',0,0,0,0);
//////    CreateTextChanceValue (aGK.ids,aGK.Defense ,dir_attributes + 'Defense',0,0,0,0);

  if MyBrain.w_FreeKick3 then begin
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    BaseShot :=  SelectedPlayer.DefaultShot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX] +1 + SelectedPlayer.Tal_freekicks;  // . il +1 è importante al shot. è una freekick3
    if BaseShot <= 0 then BaseShot := 1;
    advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Shot')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(BaseShot ));
  // mostro le 4 chance in barriera
    BarrierCell := MyBrain.GetBarrierCell( MyBrain.TeamFreeKick , MyBrain.Ball.CellX, MyBrain.Ball.CellY  ) ;
    CreateCircle( aGK.Team, BarrierCell.X, BarrierCell.Y );
{    b := 0;
    for I :=  0 to Mybrain.lstSoccerPlayer.Count -1 do begin
      anOpponent := Mybrain.lstSoccerPlayer[i];
      if (anOpponent.CellX = BarrierCell.X) and (anOpponent.CellY = BarrierCell.Y) then begin
        Inc(b);
        /////CreateTextChanceValue (anOpponent.ids,anOpponent.Defense , dir_attributes + 'Defense', 0, B*18, aCell.PixelX, acell.PixelY  );
      end;
    end;   }

  // mostro la chance el portiere e la mia
    CreateCircle( aGK );
    advDiceWriteRow  ( aGK.Team, UpperCase(Translate('attribute_Defense')),  aGK.SurName, aGK.Ids, 'VS',IntToStr(aGK.Defense ));

  end
  else if MyBrain.w_FreeKick4 then begin
    BaseShot :=  SelectedPlayer.DefaultShot + modifier_penalty +1;  // . il +1 è importante  per il PRS. è una freekick4
    advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Shot')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(BaseShot ));
    // il pos non ha quel +1 ma ha la respinta
    if BaseShot <= 0 then BaseShot := 1;
  // mostro la chance el portiere e la mia
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    advDiceWriteRow  ( aGK.Team, UpperCase(Translate('attribute_Defense')),  aGK.SurName, aGK.Ids, 'VS',IntToStr(aGK.Defense ));
/////    CalculateChance  (BaseShot, aGK.Defense , chanceA,chanceB,chanceColorA,chanceColorB);
/////    CreateTextChanceValue (SelectedPlayer.ids,BaseShot, dir_skill + 'Precision.Shot',0,0,0,0);
/////    CreateTextChanceValue (aGK.ids,aGK.Defense,dir_attributes + 'Defense',0,0,0,0);
  end
  else begin
    BaseShot :=  SelectedPlayer.Shot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX];
    if BaseShot <= 0 then BaseShot := 1;
    advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Shot')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(BaseShot ));

    for Ii := 0 to MyBrain.ShotCells.Count -1 do begin

      if (MyBrain.ShotCells[ii].DoorTeam <> SelectedPlayer.Team) and
      (MyBrain.ShotCells[ii].CellX = SelectedPlayer.CellX) and (MyBrain.ShotCells[ii].CellY = SelectedPlayer.CellY) then begin

        for c := 0 to  MyBrain.ShotCells[ii].subCell.Count -1 do begin
          aPoint :=  MyBrain.ShotCells[ii].subCell.Items [c];
          anOpponent := Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          if  anOpponent = nil then continue;
          if Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y ).Team <> SelectedPlayer.Team then begin
            if SelectedPlayer.CellX = anOpponent.cellX then Modifier := soccerbrainv3.modifier_defenseShot else Modifier :=0;
            CreateArrowDirection( anOpponent, SelectedPlayer );
            advDiceWriteRow  ( anOpponent.Team, UpperCase(Translate('attribute_Defense')),  anOpponent.SurName, anOpponent.Ids, 'VS',IntToStr(anOpponent.Defense));

////            CalculateChance  (BaseShot, anOpponent.Defense + Modifier, chanceA,chanceB,chanceColorA,chanceColorB);

////            CreateTextChanceValue (anOpponent.ids,anOpponent.Defense + Modifier,dir_attributes + 'Defense',0,0,0,0);
          end;
        end;
      end;
    end;

    // mostro la chance el portiere
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    advDiceWriteRow  ( aGK.Team,  UpperCase(Translate('attribute_Defense')),  aGK.SurName, aGK.Ids, 'VS',IntToStr(aGK.Defense ) );
/////    CalculateChance  (BaseShot, aGK.Defense + Modifier, chanceA,chanceB,chanceColorA,chanceColorB);
/////    CreateTextChanceValue (SelectedPlayer.ids,BaseShot,dir_skill + 'Precision.Shot',0,0,0,0);
/////    CreateTextChanceValue (aGK.ids,aGK.Defense + Modifier,dir_attributes + 'Defense',0,0,0,0);
  end;

end;
procedure TForm1.MovMouseEnter ( Sender : TObject);
var
  I, MoveValue: Integer;
  FriendlyWall, OpponentWall,FinalWall: Boolean;
  aCellList: TList<TPoint>;
begin
//  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;
  if  SelectedPlayer.HasBall then begin
    MoveValue := SelectedPlayer.Speed -1;
    if MoveValue <=0 then MoveValue:=1;

    FriendlyWall := true;
    OpponentWall := true;
    FinalWall := true;
  end
  else begin
    MoveValue := SelectedPlayer.Speed ;
    FriendlyWall := false;
    OpponentWall := false;
    FinalWall := true;
  end;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, MoveValue,True,true , True,aCellList); // noplayer,noOutside
  for I := 0 to aCellList.Count -1 do begin

          MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, aCellList[i].X, aCellList[i].Y,
                                MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                                OpponentWall{OpponentWall},FinalWall{FinalWall},ExcludeNotOneDir{OneDir}, SelectedPlayer.MovePath );
      if SelectedPlayer.MovePath.Count > 0 then begin
        HighLightField (aCellList[i].X, aCellList[i].Y, 0 );
      end;

  end;
  aCellList.Free;


end;

procedure TForm1.ShpMouseEnter ( Sender : TObject);
var
  I: Integer;
  aCellList: TList<TPoint>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, ShortPassRange + SelectedPlayer.tal_longpass  ,false,True,true ,aCellList); // noplayer,noOutside

  for I := 0 to aCellList.Count -1 do begin
    aPlayer := MyBrain.GetSoccerPlayer(aCellList[i].X, aCellList[i].Y);
    if aPlayer <> nil then begin
      if (aPlayer.Team <> SelectedPlayer.team) or (aPlayer.Ids = SelectedPlayer.Ids) then Continue;
    end;
   // HighLightField2 ( aCellList[i].X, aCellList[i].Y );
    HighLightField (aCellList[i].X, aCellList[i].Y, 0);

  end;
  aCellList.Free;


end;
procedure TForm1.LopMouseEnter ( Sender : TObject);
var
  I: Integer;
  aCellList: TList<TPoint>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, LoftedPassRangeMax + SelectedPlayer.tal_longpass  ,false, True, true,aCellList); // noplayer,noOutside


  for I := 0 to aCellList.Count -1 do begin
    if AbsDistance(SelectedPlayer.CellX, SelectedPlayer.CellY,aCellList[i].X, aCellList[i].Y) < LoftedPassRangeMin then Continue;

    aPlayer := MyBrain.GetSoccerPlayer(aCellList[i].X, aCellList[i].Y);
    if aPlayer <> nil then begin
      if aPlayer.Team <> SelectedPlayer.team then Continue;
    end;
    HighLightField (aCellList[i].X, aCellList[i].Y , 0);

  end;
  aCellList.Free;


end;
procedure TForm1.mainThreadTimer(Sender: TObject);
begin

  GCD := GCD - SE_ThreadTimer ( Sender).Interval;
  if GameScreen = ScreenFormation  then Exit;


  if AnimationScript.Index = -1 then begin
  // iratheater1.thrdAnimate.OnTimer ( iratheater1.thrdAnimate);
      SetGlobalCursor  ( crHandpoint);
//   Application.ProcessMessages ;
   exit;
  end;

  if ( SE_ball.IsAnySpriteMoving  ) then begin   // la palla sta roteando
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      Application.ProcessMessages ;
     // SetGlobalCursor  ( crHourGlass);
      exit;
  end;

  if (AnimationScript.waitMovingPlayers) then begin // se devo apsettare i players

     if se_players.IsAnySpriteMoving  then  begin
        se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
        Application.ProcessMessages ;

     //   SetGlobalCursor  ( crHourGlass);
        exit;
     end;
  end;

  if AnimationScript.wait > -1 then begin
    AnimationScript.wait := AnimationScript.wait - MainThread.Interval ;
    if AnimationScript.wait <=0 then begin
//      iraTheater1.thrdAnimate.Priority := tpNormal;
      AnimationScript.wait :=-1;
    end
    else begin
      Application.ProcessMessages ;

      exit;
    end;
  end;


  if AnimationScript.Index <= AnimationScript.Ts.Count -1  then begin
//      if not Mybrain.Ball.Se_Sprite.DestinationReached  then exit;
    if se_ball.IsAnySpriteMoving then begin
//    if MyBrain.Ball.Moving  then begin   // la palla sta roteando
     //   se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
   //   SetGlobalCursor  ( crHourGlass);
//      Application.ProcessMessages ;
        exit;
    end;

   // SetGlobalCursor  ( crHourGlass);


  {$ifdef tools}
    toolSpin.Visible := false;
  {$endif tools}
    Animating:= True;
    anim (AnimationScript.Ts[ AnimationScript.Index ]);
    AnimationScript.Index := AnimationScript.Index + 1;
  end
  else begin
    AnimationScript.Index := -1;

//    if (MyBrain.w_CornerSetup) or ( MyBrain.w_FreeKickSetup2 ) or ( MyBrain.w_FreeKick2 ) or ( MyBrain.w_FreeKickSetup3 ) or ( MyBrain.w_FreeKick3 ) then
//      goto skipReset;
//    SpriteReset( true );
//SkipReset:
  {$ifdef tools}
    if viewReplay then
      toolSpin.Visible := true;
  {$endif tools}
    Animating:= false;

   // qui sotto non penso sia da fare perchè dai freekick arrivano dei playermove
   //if not Cl_BrainLoaded then // se non caricato durante i freekick
    ClientLoadBrainMM ( CurrentIncMove ) ;
    SpriteReset;
    UpdateSubSprites;
    IncMove [CurrentIncMove] := True; // caricato e completamente eseguito
//    inc ( CurrentIncMove );
  end;



end;
procedure TForm1.SetGlobalCursor ( aCursor: Tcursor);
begin
    advAllbrain.Cursor := aCursor;
    SE_Theater1.Cursor := aCursor;

end;
procedure TForm1.CroMouseEnter ( Sender : TObject);
var
  I: Integer;
  aCellList: TList<TPoint>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY,CrossingRangeMax + SelectedPlayer.tal_longpass  ,false,True,True, aCellList); // noplayer,noOutside


  for I := 0 to aCellList.Count -1 do begin
    if AbsDistance(SelectedPlayer.CellX, SelectedPlayer.CellY,aCellList[i].X, aCellList[i].Y) < CrossingRangeMin then Continue;

    aPlayer := MyBrain.GetSoccerPlayer(aCellList[i].X, aCellList[i].Y);
    if aPlayer <> nil then begin
      if aPlayer.Team <> SelectedPlayer.team then Continue;
      if not aPlayer.InCrossingArea  then Continue;
      HighLightField (aCellList[i].X, aCellList[i].Y,0);

    end;

  end;
  aCellList.Free;


end;
procedure TForm1.DriMouseEnter ( Sender : TObject);
var
  I: Integer;
  aPlayerList: TObjectList<TSoccerPlayer>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;

  aPlayerList:= TObjectList<TSoccerPlayer>.create(False);

  MyBrain.GetNeighbournsOpponent( SelectedPlayer.CellX, SelectedPlayer.CellY, SelectedPlayer.Team ,aPlayerList);

  for I := 0 to aPlayerList.Count -1 do begin
   // HighLightField2 ( aCellList[i].X, aCellList[i].Y );
      HighLightField (aPlayerList[i].cellX, aPlayerList[i].cellY,0);
  end;

  aPlayerList.Free;


end;

procedure TForm1.PosMouseEnter ( Sender : TObject);
var
  i,ii,c : Integer;
  anOpponent,aGK: TSoccerPlayer;
  aPoint : PPointL;
  Modifier,BaseShot,chanceA,chanceB: Integer;
  BarrierCell: TPoint;
  aDoor: TPoint;

begin
  hidechances;
  PanelCombatLog.Left := PanelSkillSE.Left + PanelSkillSE.Width;
  advDice.RowCount := 1;
  advDice.Clear ;
  if SelectedPlayer = nil then Exit;
  Modifier := 0;
  aDoor := Mybrain.GetOpponentDoor ( SelectedPlayer );
  if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, adoor.X, adoor.Y  ) > PowerShotRange then exit;

  if MyBrain.w_FreeKick3 then begin
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    BaseShot :=  SelectedPlayer.DefaultShot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX] +1 + SelectedPlayer.Tal_freekicks;  // . il +1 è importante al shot. è una freekick3
    if BaseShot <= 0 then BaseShot := 1;
    advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Shot')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(BaseShot));
  // mostro le 4 chance in barriera
    BarrierCell := MyBrain.GetBarrierCell( MyBrain.TeamFreeKick , MyBrain.Ball.CellX, MyBrain.Ball.CellY  ) ;
    CreateCircle( aGK.Team, BarrierCell.X, BarrierCell.Y );

    CreateCircle( aGK );
    advDiceWriteRow  ( aGK.Team,  UpperCase(Translate('attribute_Defense')),  aGK.SurName, aGK.Ids, 'VS',IntToStr(aGK.Defense ) );
  end
  else if MyBrain.w_FreeKick4 then begin
    BaseShot :=  SelectedPlayer.DefaultShot + modifier_penalty ;  // . il +2 è importante al shot. è una freekick4
    if BaseShot <= 0 then BaseShot := 1;
    advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Shot')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(BaseShot));

    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    advDiceWriteRow  ( aGK.Team,  UpperCase(Translate('attribute_Defense')),  aGK.SurName, aGK.Ids, 'VS',IntToStr(aGK.Defense ));
  end
  else begin
    BaseShot :=  SelectedPlayer.Shot + Mybrain.MalusPowerShot[SelectedPlayer.CellX]  ;
    if BaseShot <= 0 then BaseShot := 1;
    advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Shot')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(BaseShot));

    for Ii := 0 to MyBrain.ShotCells.Count -1 do begin

      if (MyBrain.ShotCells[ii].DoorTeam <> SelectedPlayer.Team) and
      (MyBrain.ShotCells[ii].CellX = SelectedPlayer.CellX) and (MyBrain.ShotCells[ii].CellY = SelectedPlayer.CellY) then begin

        for c := 0 to  MyBrain.ShotCells[ii].subCell.Count -1 do begin
          aPoint := MyBrain.ShotCells[ii].subCell.Items [c];
          anOpponent := Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          if  anOpponent = nil then continue;
          if Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y ).Team <> SelectedPlayer.Team then begin
            if SelectedPlayer.CellX = anOpponent.cellX then Modifier := soccerbrainv3.modifier_defenseShot else Modifier :=0;
            CreateArrowDirection( anOpponent, SelectedPlayer );
            advDiceWriteRow  ( anOpponent.Team,  UpperCase(Translate('attribute_Defense')),  anOpponent.SurName, anOpponent.Ids, 'VS',IntToStr(anOpponent.Defense ));

          end;
        end;
      end;
    end;

    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    advDiceWriteRow  ( aGK.Team,  UpperCase(Translate('attribute_Defense')),  aGK.SurName, aGK.Ids, 'VS',IntToStr(aGK.Defense ) );
  end;

end;

procedure TForm1.ClickSkillSE ( Sender : TObject; ARow,ACol: Integer);
var
  aDoor: TPoint;
begin
{  LstSkill[0]:= 'Move';
  LstSkill[1]:= 'Short.Passing';
  LstSkill[2]:= 'Lofted.Pass';
  LstSkill[3]:= 'Crossing';
  LstSkill[4]:= 'Precision.Shot';
  LstSkill[5]:= 'Power.Shot';
  LstSkill[6]:= 'Dribbling';
  LstSkill[7]:= 'Protection';
  LstSkill[8]:= 'Tackle';
  LstSkill[9]:= 'Pressing';
  LstSkill[10]:= 'Corner.Kick'; }
  if se_players.IsAnySpriteMoving or se_ball.IsAnySpriteMoving   then  exit;
  panelSkillSE.Visible := False;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
//  application.ProcessMessages ;
  if se_gridskill.Cells [0,aRow] = 'Move' then begin
          WaitForXY_Move := true;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
  end
  else if se_gridskill.Cells [0,aRow] = 'Short.Passing' then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= true;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
  end
  else if se_gridskill.Cells [0,aRow] = 'Lofted.Pass' then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= true;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
  end
  else if se_gridskill.Cells [0,aRow] = 'Crossing' then begin
    if GCD <= 0 then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= true;
          WaitForXY_Dribbling:= false;

          if MyBrain.w_FreeKick2 then begin   // in caso di freeKick2 il cross è automatico
            WaitForXY_Crossing:= false;
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'CRO2' + EndofLine);
            hidechances;
          end;
          GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Precision.Shot' then begin
    if GCD <= 0 then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
          aDoor:= MyBrain.GetOpponentDoor (SelectedPlayer );
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PRS'  + EndofLine);
            hidechances;
           GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Power.Shot' then begin
    if GCD <= 0 then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
          aDoor:= MyBrain.GetOpponentDoor (SelectedPlayer );
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'POS' + EndofLine);
          hidechances;
          GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Dribbling' then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= true;
  end
  else if se_gridskill.Cells [0,aRow] = 'Protection' then begin
    if GCD <= 0 then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
          if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PRO'  + EndofLine);
          GCD := GCD_DEFAULT;
          hidechances;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Tackle' then begin
    if GCD <= 0 then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
          if Mybrain.Ball.Player <> nil then begin
            if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
              // Tackle può portare anche ai falli e relativi infortuni e cartellini. Un tackle da dietro ha alte possibilità di generare un fallo
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'TAC' + ',' + SelectedPlayer.Ids  + EndofLine);
                  hidechances;
            end;
          end;
      GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Pressing' then begin
    if GCD <= 0 then begin
            WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
          if Mybrain.Ball.Player <> nil then begin
            if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PRE,' + SelectedPlayer.Ids  + EndofLine);
                  hidechances;
            end;
          end;
     GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Corner.Kick' then begin
         // non più usata
    if GCD <= 0 then begin
          WaitForXY_Move := false;
          WaitForXY_ShortPass:= false;
          WaitForXY_LoftedPass:= false;
          WaitForXY_Crossing:= false;
          WaitForXY_Dribbling:= false;
          // sul brain iscof batterà il corner
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'COR' + EndofLine);
                  GCD := GCD_DEFAULT;
                  hidechances;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Pass' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PASS'+ EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Stay' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) and  ( not SelectedPlayer.stay)
         then tcp.SendStr( 'STAY,' + SelectedPlayer.Ids  + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,aRow] = 'Free' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) and  ( SelectedPlayer.stay)
        then tcp.SendStr( 'FREE,' + SelectedPlayer.Ids + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end;



end;

procedure TForm1.UpdateFormation ( Guid: string; Team, TvCellX, TvCellY: integer);
var
  i: Integer;
  AICell: TPoint;
  aPlayer: TSoccerPlayer;
begin
  (* Aggiorna la MyBrainFormation, solo fuori da un match *)
   for i := 0 to MyBrainFormation.lstSoccerPlayer.count -1 do begin
      aPlayer := MyBrainFormation.lstSoccerPlayer[i];
      if aPlayer.Ids = Guid then begin
        if ((TvCellX = 0) and (TvCellY=3)) or (TvCellX = 2)  or  (TvCellX = 5) or (TvCellX = 8) then begin // uso TvCell
          AICell:=  MybrainFormation.Tv2AiField ( Team, TvCellX, TvCellY );
          aPlayer.DefaultCellS := Point  (TvCellX,TvCellY );
          aPlayer.AIFormationCellX  := AICell.X ;
          aPlayer.AIFormationCellY  := AICell.Y ;
          aPlayer.CellX :=  TvCellX;
          aPlayer.CellY :=  TvCellY;
          RefreshCheckFormationMemory;
          Exit;
        end
        else begin  // riserva
          MyBrainFormation.PutInReserveSlot(aPlayer) ;
          RefreshCheckFormationMemory;
          Exit;
        end;
      end;
   end;


end;
procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  {$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'pause,' + BoolToStr(CheckBox2.Checked) + EndOfLine  ) ;
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}
end;

procedure TForm1.CheckBox3Click(Sender: TObject);
begin

  ThreadCurMove.Enabled := CheckBox3.Checked;

end;

procedure TForm1.CheckBoxAI0Click(Sender: TObject);
begin
  {$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'aiteam,0,' +  BoolToStr(CheckBoxAI0.Checked)  + EndOfLine );
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}

end;

procedure TForm1.CheckBoxAI1Click(Sender: TObject);
begin
  {$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'aiteam,1,' +  BoolToStr(CheckBoxAI1.Checked)  + EndOfLine );
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}

end;

function TForm1.CheckFormationTeamMemory : Boolean;
var
  i,i2,pcount,pdisq,Formation_x,formation_y,disqualified: Integer;
  ini : TInifile;
  aPlayer: TSoccerPlayer;
  CellPoint : TPoint;
  lstCellPoint: TList<TPoint>;
  DupFound: Boolean;
begin
  (* controlla in locale memoria *)
  // controlla se sono schierati 11 giocatori a parte i disqualified. se può farlo deve giocare col massimo dei giocatori
  Result:= False;

  pcount:=0;
  pdisq:=0;
  lstCellPoint:= TList<TPoint>.Create;

  // non leggo la situazione direttamente dagli sprite, ma dal file ini così leggo tutte le formazioni di tutte le squadre
  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    aPlayer := MyBrainFormation.lstSoccerPlayer[i];
    if isOutSideAI (aPlayer.AIformationCellX,aPlayer.AIFormationCellY)  or (aPlayer.disqualified  > 0)  then continue;

    if (aPlayer.AIformationCellY = 6) or
       (aPlayer.AIformationCellY= 3) or
       (aPlayer.AIformationCellY = 9) or
       ((aPlayer.AIformationCellY = 11) and ( aPlayer.AIformationCellX = 3) )  then begin
         Inc(pCount);
       end;

    // cerco celle duplicate
//    if (aPlayer.CellX <> 0) and  (aPlayer.CellY <> 0) then begin
      DupFound:= False;
      for i2 := 0 to lstCellPoint.Count -1 do begin
        if (lstCellPoint[i2].X = aPlayer.AIformationCellX) and (lstCellPoint[i2].Y = aPlayer.AIformationCellY) then  begin
          MyBrainFormation.PutInReserveSlot(aPlayer);
          MoveInReserves(aPlayer);
//          aPlayer.Cells := Point(0,0);
          Dec(pCount);
          DupFound:=True;
        end;
//      end;

      if not DupFound then begin
        CellPoint.X :=  aPlayer.AIformationCellX;
        CellPoint.Y :=  aPlayer.AIformationCellY;
        lstCellPoint.Add (CellPoint);
      end;
    end;



  end;

  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    aPlayer := MyBrainFormation.lstSoccerPlayer[i];
    if aPlayer.disqualified > 0 then Inc(pDisq);// è lo stesso;
    //if aPlayer.injured > 0 then Inc(pDisq);
  end;

  // se sono 11 non sqlificati altrimenti...
  if pcount = 11 then begin
    result := True;
  end;

  // qui result è false perchè maggiore o inferiore a 11
  if pcount > 11 then begin
    result := false;
  end;

  // ... ti perdono il fatto che non puoi scherarne 11 tra gli squalificati
  if (result = false) and (MyBrainFormation.lstSoccerPlayer.count > 0) then begin
    if (MyBrainFormation.lstSoccerPlayer.count - pdisq) < 11 then begin
      Result:= True; // formazione valida con quello che è disponibile
    end;

  end;

  lstCellPoint.Free;

end;

function TForm1.inGolPosition ( PixelPosition: Tpoint ): boolean;
var
  aSEField: SE_Sprite;
begin

  Result := False;
  aSEField := SE_field.FindSprite('0.3');
  if (PixelPosition.X = aSEField.Position.X - 20) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;
  aSEField := SE_field.FindSprite('11.3');
  if (PixelPosition.X = aSEField.Position.X + 20) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;

end;
function TForm1.inCrossBarPosition ( PixelPosition: Tpoint ): Boolean;
var
  aSEField: SE_Sprite;
begin

  Result := False;
  aSEField := SE_field.FindSprite('0.3');
  if (PixelPosition.X = aSEField.Position.X - 10) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;
  aSEField := SE_field.FindSprite('11.3');
  if (PixelPosition.X = aSEField.Position.X + 10) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;

end;
function TForm1.inGKCenterPosition ( PixelPosition: Tpoint ): boolean;
var
  aSEField: SE_Sprite;
begin

  Result := False;
  aSEField := SE_field.FindSprite('0.3');
  if (PixelPosition.X = aSEField.Position.X ) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;
  aSEField := SE_field.FindSprite('11.3');
  if (PixelPosition.X = aSEField.Position.X ) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;

end;
procedure Tform1.SpriteReset ;
var
  i: integer;
  aPlayer: TsoccerPlayer;
  aSEField: SE_Sprite;
  rndy,X,Y: Integer;
  ACellBarrier,TvReserveCell: TPoint;

begin
  // la palla
    aSEField := SE_field.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));
    Mybrain.Ball.SE_Sprite.Position  := aSEField.Position;
    Mybrain.Ball.SE_Sprite.PositionY := Mybrain.Ball.SE_Sprite.Position.Y + BallZ0Y;
    Mybrain.Ball.SE_Sprite.FrameXmax := 0 ; // palla ferma

    if Mybrain.Ball.Player <> nil then begin
      case Mybrain.Ball.Player.team of
        0: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX + abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
        1: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX - abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
      end;

    end;

    Mybrain.Ball.SE_Sprite.BlendMode := se_BlendNormal;
    Mybrain.Ball.SE_Sprite.Visible := True;

    if Mybrain.w_CornerSetup then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
      CornerSetBall;
    end;

    // i player
    for I := 0 to Mybrain.lstSoccerPlayer.Count -1 do begin
      aPlayer := Mybrain.lstSoccerPlayer [i];

      if MyBrainFormation.isReserveSlot  ( aPlayer.AIFormationCellX, aPlayer.AIFormationCellY )  then begin // le riserve tutte a sinistra

         TvReserveCell:= MyBrainFormation.ReserveSlotTV [aPlayer.team,aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ];
             // MyBrainFormation.PutInReserveSlot(aPlayer) ;

         MyBrain.ReserveSlot [aPlayer.Team, aPlayer.AIFormationCellX, aPlayer.AIFormationCellY]:= aPlayer.Ids;

        aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.x)+ '.' + IntToStr (TvReserveCell.Y));

        aPlayer.se_Sprite.Position := aSEField.Position;
        aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

            if GameScreen = ScreenSubs then
              aPlayer.se_Sprite.Visible := True
              else aPlayer.se_Sprite.Visible := false;

      end
      else begin  // player normali

        aSEField := SE_field.FindSprite(IntToStr (aPlayer.CellX ) + '.' + IntToStr (aPlayer.CellY ));
        aPlayer.se_Sprite.Position := aSEField.position  ;
        aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

      end;


      aPlayer.SE_Sprite.Labels.Clear ;
      aPlayer.SE_Sprite.SubSprites.Clear;

      if MyBrain.w_FreeKick3  then begin
        if aPlayer.isFKD3 then begin
          ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
          aSeField := SE_field.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));
          rndY := RndGenerateRange(3,22);
          if Odd(RndGenerate(2)) then rndY := -rndY;
          aPlayer.se_Sprite.Position := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
          aPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
        end;
      end;

        if Mybrain.w_CornerSetup and aPlayer.isCOF then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
          CornerSetPlayer ( aPlayer );
       end;

       aPlayer.SE_Sprite.Visible := True;
    end;

    // le riserve
    for I := 0 to Mybrain.lstSoccerReserve.Count -1 do begin
      aPlayer := Mybrain.lstSoccerReserve [i];
      if MyBrainFormation.isReserveSlot  ( aPlayer.AIFormationCellX, aPlayer.AIFormationCellY )  then begin // le riserve tutte a sinistra

         TvReserveCell:= MyBrainFormation.ReserveSlotTV [aPlayer.team,aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ];

            MyBrain.ReserveSlot [aPlayer.Team, aPlayer.cellx, aPlayer.cellY]:= aPlayer.Ids;
        aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.x)+ '.' + IntToStr (TvReserveCell.Y));

            aPlayer.se_Sprite.Position := aSEField.Position;
            aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
            if GameScreen = ScreenSubs then
              aPlayer.SE_Sprite.Visible := True
              else aPlayer.se_sprite.Visible := False;
      end;
    end;


  Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;

  UpdateSubSprites;
  HighLightFieldFriendly_hide; // qualsiasi evidenziazione scompare
//  application.ProcessMessages ;

  SetGlobalCursor( crHandPoint);


end;
procedure TForm1.CornerSetBall;
var
  CornerMap: TCornerMap;
  aSEField: SE_Sprite;
begin
  CornerMap := Mybrain.GetCorner ( Mybrain.TeamCorner , Mybrain.Ball.CellY, OpponentCorner) ; // mi restituisce la cell del corner reale
  aSEField := SE_field.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));

  Mybrain.Ball.SE_Sprite.Position :=  point ( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );
  Mybrain.Ball.SE_Sprite.MoverData.Destination :=  point ( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );

end;
procedure TForm1.CornerSetPlayer ( aPlayer: TsoccerPlayer);
var
  CornerMap: TCornerMap;
  aSEField: SE_Sprite;
begin
  CornerMap := Mybrain.GetCorner ( Mybrain.TeamCorner , Mybrain.Ball.CellY, OpponentCorner) ; // mi restituisce la cell del corner reale
  aSEField := SE_field.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));

  aPlayer.SE_Sprite.Position :=  Point( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );
  aPlayer.SE_Sprite.MoverData.Destination  :=  Point( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );

end;

procedure Tform1.RemoveChancesAndInfo;
var
  i: integer;
begin
  for I := 0 to Mybrain.lstSoccerPlayer.Count -1 do begin
    Mybrain.lstSoccerPlayer[i].Se_Sprite.Labels.Clear ;;
    Mybrain.lstSoccerPlayer[i].Se_Sprite.SubSprites.Clear;
  end;

end;

procedure Tform1.PrepareAnim;
begin
  advDice.Clear ;
  advDice.RowCount :=1;
 // RemoveChancesAndInfo;
  HideChances;
  AnimationScript.Reset ;
end;
procedure Tform1.CreateSplash (aString: string; msLifespan: integer) ;
var
  w: Integer;
  bmp: SE_Bitmap;
  aSprite: SE_Sprite;
begin

  SE_interface.RemoveAllSprites;
  HighLightFieldFriendly_hide;
  bmp:= SE_Bitmap.Create(600,40);
  bmp.Bitmap.Canvas.Brush.color := clblack;
  bmp.Bitmap.Canvas.Font.Name := 'Calibri';
  bmp.Bitmap.Canvas.Font.Quality := fqNonAntialiased;
  bmp.Bitmap.Canvas.font.Size := 24;
  bmp.Bitmap.Canvas.Font.Style := [fsBold];
  bmp.Bitmap.Canvas.font.Color := clyellow;
  bmp.Bitmap.Canvas.FillRect(rect(0,0,bmp.Width ,bmp.Height ));
  w:= bmp.Bitmap.Canvas.TextWidth(aString);
  bmp.Bitmap.Canvas.TextOut( (bmp.Bitmap.Width div 2)  - (w div 2), 0 ,aString );

  aSprite := se_interface.CreateSprite(bmp.Bitmap, aString, 1,1, 20,(se_theater1.VirtualBitmap.Width div 2),(se_theater1.VirtualBitmap.Height div 2), true  );
  //aSprite.LifeSpan := 80;
  aSprite.LifeSpan := msLifespan;
  lbl_score.Caption := IntToStr(Mybrain.Score.gol [0]) +'-'+ IntToStr(Mybrain.Score.gol [1]);
  aSprite.MoverData.Speed := 10;
  aSprite.MoverData.Destination := Point( aSprite.Position.X , aSprite.Position.Y - 200 );

  bmp.Free;
end;

procedure TForm1.LoadTranslations ;
var
  ini: TIniFile;
begin
  TranslateMessages:= TStringList.Create;
  TranslateMessages.StrictDelimiter := True;


  ini:= TIniFile.Create(dir_data + 'text\it\messages.txt' );
  ini.ReadSectionValues ('Messages',TranslateMessages ) ;
  ini.Free;


end;
Function TForm1.Capitalize ( aString : string  ): String;
begin
   if Length ( astring ) > 0 then
    Result :=  UPPERCASE (aString[1]) + RightStr ( aString , Length ( aString ) -1 )
    else
      result := '';

end;


function TForm1.ClientLoadScript ( incMove: Byte) : Integer;
var
  StartScript: Integer;
  SS : TStringStream;
  lentsscript: word;
begin
  AnimationScript.Reset ;
  Mybrain.tsScript.Clear ;

{
  str:= AnsiString  ( tsScript.CommaText );
  LentsScript := Length (str);
  MMbraindata.Write( @LentsScript, sizeof(integer) );
  MMbraindata.Write( @str[1] , Length(str) );

}
  StartScript := PWORD(@buf3[incMove][ 0 ])^;   // punta ai 2 byte word che indicano la lunghezza della stringa
  if StartScript = 0 then Exit;
  SS:= TStringStream.Create;
  SS.Size := MM3[incMove].Size;
  Mm3[incMove].Position := 0;
  SS.CopyFrom( MM3[incMove], MM3[incMove].size );


  // se non c'è tsscript la stringa è lunga 0
  lentsscript := PWORD(@buf3[incMove][ StartScript ])^;
  if lentsscript > 0 then
    Mybrain.tsScript.CommaText := midStr ( SS.DataString , StartScript +1+2, lentsscript ); //+1 ragiona in base 1  +2 per len della stringa

  SS.Free;

  result := Mybrain.tsScript.Count;
end;

procedure Tform1.ClientLoadBrainMM  ( incMove: Byte );
var
  SS : TStringStream;
  lenuser0,lenuser1,lenteamname0,lenteamname1,lenuniform0,lenuniform1,lenSurname: byte;
  dataStr,tmpStr: string;
  Cur: Integer;
  TotPlayer,TotReserve: byte;
  aSEField, aSprite: se_Sprite;
  i,aAge,aCellX,aCellY,aTeam,aGuidTeam,nMatchesPlayed,nMatchesLeft,pcount,rndY,aStamina: integer;
  DefaultCellX,DefaultCellY: ShortInt;
  aTalentID: Byte;
  Sp: TSoccerPlayer;
  FC: TFormationCell;
  aPoint : TPoint;
  aCell: TSoccerCell;
  aName, aSurname,  aTalents,Attributes,aIds: string;
  bmp: se_Bitmap;
  PenaltyCell: TPoint;
  bmp1: SE_Bitmap;
  Injured: Integer;
  CornerMap: TCornerMap;
  ACellBarrier,TvReserveCell: TPoint;
  DefaultSpeed, DefaultDefense , DefaultPassing, DefaultBallControl, DefaultShot, DefaultHeading: Byte;
  Speed, Defense , Passing, BallControl, Shot, Heading: ShortInt;
  UniformBitmap : array[0..1] of SE_Bitmap;
  UniformBitmapGK: SE_bitmap;
begin
  PanelSkillSE.Visible:= False;
  se_players.RemoveAllSprites ;
  MyBrain.ClearReserveSlot;

  MyBrain.lstSoccerPlayer.Clear ;
  MyBrain.lstSoccerReserve.Clear;

  SS := TStringStream.Create;
  SS.Size := MM3[incMove].Size;
  MM3[incMove].Position := 0;
  ss.CopyFrom( MM3[incMove], MM3[incMove].size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  if RightStr(dataStr,2) <> 'IS' then Exit;


  // a 0 c'è la word che indica dove comincia tsScript
  cur := 2;
  lenuser0:=  Ord( buf3[incMove] [ cur ]);                 // ragiona in base 0
  MyBrain.Score.Username [0] := MidStr( dataStr, cur +2  , lenUser0 );// ragiona in base 1
  cur  := cur + lenuser0 + 1;
  lenuser1:=  Ord( buf3[incMove][Cur]);                 // ragiona in base 0
  MyBrain.Score.Username [1] := MidStr( dataStr, Cur + 2, lenUser1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenUser1 + 1;

  lenteamname0 :=  Ord( buf3[incMove][ cur ]);
  MyBrain.Score.Team [0]  := MidStr( dataStr, cur + 2  , lenteamname0 );// ragiona in base 1
  cur  := cur + lenteamname0 + 1;
  lenteamname1:=  Ord( buf3[incMove][Cur]);                 // ragiona in base 0
  MyBrain.Score.Team [1] := MidStr( dataStr, Cur + 2, lenteamname1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenteamname1 + 1;

  MyBrain.Score.TeamGuid [0] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.TeamGuid [1] :=  PDWORD(@buf3[incMove][ cur ])^;

  cur := cur + 4 ;
  MyBrain.Score.TeamMI [0] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.TeamMI [1] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;

  MyBrain.Score.Country [0] :=  PWORD(@buf3[incMove][ cur ])^;
  cur := cur + 2 ;
  MyBrain.Score.Country [1] :=  PWORD(@buf3[incMove][ cur ])^;
  cur := cur + 2 ;

  lenUniform0 :=  Ord( buf3[incMove][ cur ]);
  MyBrain.Score.Uniform [0]  := MidStr( dataStr, cur + 2  , lenUniform0 );// ragiona in base 1
  cur  := cur + lenUniform0 + 1;
  lenUniform1:=  Ord( buf3[incMove][Cur]);                 // ragiona in base 0
  MyBrain.Score.Uniform [1] := MidStr( dataStr, Cur + 2, lenUniform1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenUniform1 + 1;

  TsUniforms[0].CommaText := MyBrain.Score.Uniform [0] ; // in formazione casa/trasferta
  TsUniforms[1].CommaText := MyBrain.Score.Uniform [1] ;
  UniformBitmap[0] := SE_Bitmap.Create (dir_player + 'bw.bmp');
  PreLoadUniform (0, UniformBitmap[0] );  // usa tsuniforms e  UniformBitmapBW
  Portrait0.Glyph.LoadFromFile(dir_tmp + 'color0.bmp');
  UniformBitmap[1] := SE_Bitmap.Create (dir_player + 'bw.bmp');
  PreLoadUniform (1, UniformBitmap[1] );  // usa tsuniforms e  UniformBitmapBW
  Portrait1.Glyph.LoadFromFile(dir_tmp + 'color1.bmp');
  UniformBitmapGK := SE_Bitmap.Create (dir_player + 'bw.bmp');
  PreLoadUniformGK (1, UniformBitmapGK );
  { TODO : override maglie if checkbox ... black or white }
  MyBrain.Score.DominantColor[0]:=  se_gridColors.Colors [ StrToInt( TsUniforms[0][0] ),0 ];
  if TsUniforms[0][0] = TsUniforms[0][1] then
    MyBrain.Score.FontColor[0]:= GetContrastColor( se_gridColors.Colors [ StrToInt(TsUniforms[0][0]),0 ] )
    else MyBrain.Score.FontColor[0]:= se_gridColors.Colors [ StrToInt( TsUniforms[0].Strings[1] ),0];

  MyBrain.Score.DominantColor[1]:= se_gridColors.Colors [ StrToInt( TsUniforms[1][0] ),0 ];
  if TsUniforms[1][0] = TsUniforms[1][1] then
    MyBrain.Score.FontColor[1]:= GetContrastColor( se_gridColors.Colors [ StrToInt(TsUniforms[1][0]),0 ] )
    else MyBrain.Score.FontColor[1]:= se_gridColors.Colors [StrToInt( TsUniforms[1][1] ),0];

  lblNick0.Color :=  MyBrain.Score.DominantColor[0];
  lblNick0.Font.Color:= MyBrain.Score.FontColor[0];
  lblNick1.Color :=  MyBrain.Score.DominantColor[1];
  lblNick1.Font.Color:= MyBrain.Score.FontColor[1];

  MyBrain.Score.Gol [0] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.Gol [1] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;

  MyBrain.Minute :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  LocalSeconds  :=  Ord( buf3[incMove][ cur ]);
  MyBrain.fmilliseconds :=  (PWORD(@buf3[incMove][ cur ])^ ) * 1000;
  cur := cur + 2 ;

  MyBrain.TeamTurn :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.FTeamMovesLeft :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.GameStarted :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.FlagEndGame :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.Shpbuff :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.ShpFree :=    Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.incMove :=    Ord( buf3[incMove][ cur ]);   // supplementari, rigori, può sforare 255 ?
  cur := cur + 1 ;
  i_tml ( IntToStr( MyBrain.FTeamMovesLeft ) ,  IntToStr( MyBrain.TeamTurn ) )  ;

  // aggiungo la palla
  se_ball.RemoveAllSprites ;
  SE_ball.ProcessSprites(20);
//  application.ProcessMessages ;
  if MyBrain.Ball <> nil then
    MyBrain.Ball.Free;

  MyBrain.Ball := Tball.create(MyBrain);
  MyBrain.Ball.CellX :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Ball.CellY :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;


    // aggiungo la palla
    aSEField := SE_field.FindSprite(IntToStr (MyBrain.Ball.CellX ) + '.' + IntToStr (MyBrain.Ball.CellY ));


    Mybrain.Ball.SE_Sprite := se_Ball.CreateSprite(dir_ball + 'ball1.bmp','ball',1,1,5,
                                              aSEField.Position.X   , aSEField.Position.Y , true);
   // Mybrain.Ball.SE_Sprite.Scale := 100;    Mybrain.Ball.SE_Sprite.Position :=aSEField.Position;
    Mybrain.Ball.Se_sprite.Scale := 30;
    Mybrain.Ball.SE_Sprite.MoverData.Speed:= 3;
    Mybrain.Ball.SE_Sprite.PositionY := Mybrain.Ball.SE_Sprite.Position.Y + BallZ0Y;
    Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.Se_sprite.Position;
    Mybrain.Ball.SE_Sprite.FrameXmax := 0 ; // palla ferma


    if Mybrain.Ball.Player <> nil then begin
      case Mybrain.Ball.Player.team of
        0: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX + abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
        1: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX - abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
      end;

    end;


  MyBrain.TeamCorner :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.w_CornerSetup :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Coa:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Cod:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_CornerKick:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.TeamfreeKick :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.w_FreeKickSetup1 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka1:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick1:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup2 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka2:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fkd2:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick2:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup3 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka3:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fkd3:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick3:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup4 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka4:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick4:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  lblNick0.Caption :=  MyBrain.Score.UserName[0] +' - ' +  UpperCase( MyBrain.Score.Team [0]);
  lblNick1.Caption :=   MyBrain.Score.Team [1] +' - ' +  UpperCase(MyBrain.Score.UserName[1]);
  lbl_score.Caption := IntToStr(Mybrain.Score.gol [0]) +'-'+ IntToStr(Mybrain.Score.gol [1]);

  lblNick0.Color :=  MyBrain.Score.DominantColor [0];
  lblNick0.BlinkColor  :=  MyBrain.Score.DominantColor [0];
  lblNick0.Font.Color := GetContrastColor(lblNick0.Color  );

  lblNick1.Color :=  MyBrain.Score.DominantColor [1];
  lblNick1.BlinkColor  :=  MyBrain.Score.DominantColor [1];
  lblNick1.Font.Color := GetContrastColor(lblNick1.Color  );
  lbl_minute.Caption := IntToStr(MyBrain.Minute) +'''';



  totPlayer :=  Ord( buf3[incMove][ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo player
  for I := 0 to totPlayer -1 do begin

//    PlayerGuid := StrToInt(spManager.lstSoccerPlayer[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    aIds := IntToStr( PDWORD(@buf3[incMove][ cur ])^);
    Cur := Cur + 4;
    aGuidTeam := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[incMove][ cur ]);
    aSurname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;
    aTeam := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;
    aAge :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;

    nMatchesplayed := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    nMatchesLeft := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    aTalentID := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    if aTalentID > 0 then
      aTalents := tsTalents [ aTalentID -1]
      else aTalents := '';

    aStamina := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultSpeed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultDefense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultPassing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultBallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultShot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultHeading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Attributes:= IntTostr( DefaultSpeed) + ',' + IntTostr( DefaultDefense) + ',' + IntTostr( DefaultPassing) + ',' + IntTostr( DefaultBallControl) + ',' +
                 IntTostr( DefaultShot) + ',' + IntTostr( DefaultHeading) ;

    Sp:= TSoccerPlayer.Create( aTeam,
                               MyBrain.Score.TeamGuid [aTeam] ,
                               nMatchesplayed,
                               aIds,
                               aName,
                               aSurname,
                               aTalents,
                               Attributes  );     // attributes e defaultAttrributes sono uguali
    Sp.Stamina := aStamina;
    Sp.TalentId:= aTalentID;

    Sp.Speed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Defense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Passing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.BallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Shot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Heading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    Injured:= Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Injured := Injured;
    if Injured > 0 then begin
      Sp.Speed :=1;
      Sp.Defense :=1;
      Sp.Passing :=1;
      Sp.BallControl :=1;
      Sp.Shot :=1;
      Sp.Heading :=1;
    end;


    Sp.YellowCard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.redcard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.disqualified :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.gameover :=  Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;

    Sp.AIFormationCellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.AIFormationCellY  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultCellX := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    DefaultCellY := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    Sp.DefaultCellS :=  Point( DefaultCellX, DefaultCellY); // innesca e setta il role

    Sp.CellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.CellY := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

      (* variabili di gioco *)
    Sp.Stay  := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.CanMove  := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.CanSkill := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    sp.CanDribbling := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.PressingDone  := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    sp.BonusTackleTurn  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    sp.BonusLopBallControlTurn  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    sp.BonusProtectionTurn  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    sp.UnderPressureTurn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    sp.BonusSHPturn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    sp.BonusSHPAREAturn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.BonusPLMturn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.isCOF := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.isFK1 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.isFK2 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.isFK3 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.isFK4 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.isFKD3 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    Sp.face := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;

      if Sp.TalentId <> 1 then
        Sp.Se_Sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,Sp.Ids,1,1,100,0,0,true)
      else
        Sp.SE_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , Sp.Ids,1,1,1000,0,0,true);

      Sp.se_sprite.Scale:= ScaleSprites;
      Sp.se_Sprite.ModPriority := i+2;
      Sp.se_Sprite.MoverData.Speed := 3;
//        Sp.Sprite.SoundFolder := dir_sound;
        MyBrain.AddSoccerPlayer(Sp);

            // se è espulso o sostituito è ancora in lstsoccerplayer, non lstreserve
//            if Sp.Gameover or playerout  then begin

            if MyBrainFormation.isReserveSlot  ( Sp.AIFormationCellX, Sp.AIFormationCellY )  then begin // le riserve tutte a sinistra

              TvReserveCell:= MyBrainFormation.ReserveSlotTV [Sp.team,Sp.AIFormationCellX, Sp.AIFormationCellY  ];
             // MyBrainFormation.PutInReserveSlot(aPlayer) ;

              MyBrain.ReserveSlot [Sp.Team, Sp.AIFormationCellX, Sp.AIFormationCellY]:= Sp.Ids;

              aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.X ) + '.' + IntToStr (TvReserveCell.Y));

              Sp.se_Sprite.Position := aSEField.Position;
              Sp.se_sprite.MoverData.Destination := aSEField.Position;
            end
            else begin  // player normali
              aSEField := SE_field.FindSprite(IntToStr (Sp.CellX ) + '.' + IntToStr (Sp.CellY ));
              Sp.se_Sprite.Position := aSEField.position  ;
              Sp.se_sprite.MoverData.Destination := aSEField.Position;

              if GameScreen = ScreenSubs then
                Sp.se_Sprite.Visible := True
                else Sp.se_Sprite.Visible := false;

            end;

            if MyBrain.w_FreeKick3  then begin
              if Sp.isFKD3 then begin
                ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
                aSeField := SE_field.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));
                rndY := RndGenerateRange(3,22);
                if Odd(RndGenerate(2)) then rndY := -rndY;
                Sp.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
              end;
            end

            else if MyBrain.w_CornerSetup then begin
              if Sp.isCOF then begin
                CornerSetPlayer( sp );
              end;
            end;

            sp.SE_Sprite.Visible := True;




  end;

  totReserve :=  Ord( buf3[incMove][ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo Reserve
  for I := 0 to totReserve -1 do begin

//    PlayerGuid := StrToInt(spManager.lstSoccerPlayer[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    aIds := IntToStr( PDWORD(@buf3[incMove][ cur ])^);
    Cur := Cur + 4;
    aGuidTeam := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[incMove][ cur ]);
    aSurname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;
    aTeam := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;
    aAge :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;

    nMatchesplayed := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    nMatchesLeft := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    aTalentID := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    if aTalentID > 0 then
      aTalents := tsTalents [ aTalentID -1]
      else aTalents := '';

    aStamina := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultSpeed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultDefense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultPassing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultBallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultShot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultHeading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Attributes:= IntTostr( DefaultSpeed) + ',' + IntTostr( DefaultDefense) + ',' + IntTostr( DefaultPassing) + ',' + IntTostr( DefaultBallControl) + ',' +
                 IntTostr( DefaultShot) + ',' + IntTostr( DefaultHeading) ;

    Sp:= TSoccerPlayer.Create( aTeam,
                               MyBrain.Score.TeamGuid [aTeam] ,
                               nMatchesplayed,
                               aIds,
                               aName,
                               aSurname,
                               aTalents,
                               Attributes  );     // attributes e defaultAttrributes sono uguali

    Sp.Stamina := aStamina;
    Sp.TalentId:= aTalentID;

    Sp.Speed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Defense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Passing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.BallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Shot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Heading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    Injured:= Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.Injured := Injured;
    if Injured > 0 then begin
      Sp.Speed :=1;
      Sp.Defense :=1;
      Sp.Passing :=1;
      Sp.BallControl :=1;
      Sp.Shot :=1;
      Sp.Heading :=1;
    end;


    Sp.YellowCard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.redcard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.disqualified :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.gameover :=  Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;

    Sp.AIFormationCellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.AIFormationCellY  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultCellX := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    DefaultCellY := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    Sp.DefaultCellS :=  Point( DefaultCellX, DefaultCellY); // innesca e setta il role

    Sp.CellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Sp.CellY := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    Sp.face := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;


                    // fare preloadBrain, diverso da formation
      if Sp.TalentId <> 1 then
        Sp.Se_Sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,Sp.Ids,1,1,100,0,0,true)
      else
        Sp.SE_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , Sp.Ids,1,1,1000,0,0,true);
      Sp.se_sprite.Scale:= ScaleSprites;
      Sp.se_Sprite.ModPriority := i+2;
      Sp.se_Sprite.MoverData.Speed := 3;
//        Sp.Sprite.SoundFolder := dir_sound;
      { in formationcell_xy  0 6 coincide con 0 6 riserva. 0 6 non è una formnation valida, quindi ok }
//      if  MyBrain.isReserveSlot  ( Sp.CellX  , Sp.CellY )  then begin // le riserve tutte a sinistra o tutte a destra
          MyBrain.AddSoccerReserve(Sp);
            if MyBrainFormation.isReserveSlot  ( Sp.AIFormationCellX, Sp.AIFormationCellY )  then begin // le riserve tutte a sinistra

              TvReserveCell:= MyBrainFormation.ReserveSlotTV [Sp.team,Sp.AIFormationCellX, Sp.AIFormationCellY  ];
             // MyBrainFormation.PutInReserveSlot(aPlayer) ;

              MyBrain.ReserveSlot [Sp.Team, Sp.AIFormationCellX, Sp.AIFormationCellY]:= Sp.Ids;

              aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.X ) + '.' + IntToStr (TvReserveCell.Y));

            Sp.se_Sprite.Position := aSEField.Position;
            Sp.se_sprite.MoverData.Destination := aSEField.Position;
           end;

            if GameScreen = ScreenSubs then
              Sp.se_Sprite.Visible := True
              else Sp.se_Sprite.Visible := false;


  end;
  UniformBitmap[0].Free;
  UniformBitmap[1].Free;
  UpdateSubSprites;
  // cur posizionato sull'inizio di tsscript

{

    CLIENTLOADSCRIPT

  str:= AnsiString  ( tsScript.CommaText );
  LentsScript := Length (str);
  MMbraindata.Write( @LentsScript, sizeof(integer) );
  MMbraindata.Write( @str[1] , Length(str) );

}


  if MyBrain.w_Fka1 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, OpponentCorner );
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        WaitForXY_FKF1 := true; //'Scegli chi batterà il fk1';
        LoadAdvTeam (MyBrain.TeamTurn, 'Passing',true);
        ShowCornerFreeKickGrid;   //
    end
    else PanelCorner.Visible := False;
  end
  else if MyBrain.w_FreeKick1  then begin
//    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
//      SelectedPlayerPopupSkillSE ( MyBrain.Ball.CellX, MyBrain.Ball.CellY );
//    end
//    else PanelCorner.Visible := False;
    PanelCorner.Visible := False;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkillSE( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Fka2 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        WaitForXY_FKF2 := true; //'Scegli chi batterà il fk2';
        LoadAdvTeam (MyBrain.TeamTurn, 'Crossing',true);
        ShowCornerFreeKickGrid;   //
    end
    else PanelCorner.Visible := False;
  end
  else if MyBrain.w_Fkd2 then begin

    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, OpponentCorner );
      HighLightField( CornerMap.HeadingCellD [0].X,CornerMap.HeadingCellD [0].Y,0);
      LoadAdvTeam (MyBrain.TeamTurn, 'Heading',true);
      ShowCornerFreeKickGrid;
    end
    else PanelCorner.Visible := False;
  end
  else if MyBrain.w_FreeKick2  then begin
      PanelCorner.Visible := False;
      if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
          tcp.SendStr( 'CRO2' + endofline);
      end;
  end
  else if MyBrain.w_Fka3 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        WaitForXY_FKF3 := true; //'Scegli chi batterà il fk3';
        LoadAdvTeam (MyBrain.TeamTurn, 'Shot',true);
        ShowCornerFreeKickGrid;   //
    end
    else PanelCorner.Visible := False;
  end
  else if MyBrain.w_Fkd3 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      ACellBarrier :=  MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
      HighLightField( aCellBarrier.X,  aCellBarrier.Y,0 );
      LoadAdvTeam (MyBrain.TeamTurn, 'Defense',true);
      ShowCornerFreeKickGrid;
    end
    else PanelCorner.Visible := False;

  end
  else if MyBrain.w_FreeKick3  then begin
    PanelCorner.Visible := False;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkillSE( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Fka4 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        PenaltyCell := MyBrain.GetPenaltyCell ( MyBrain.TeamTurn );
        HighLightField ( PenaltyCell.x,PenaltyCell.Y  ,0 );
        WaitForXY_FKF4 := true; //'Scegli chi batterà il fk4';
        LoadAdvTeam (MyBrain.TeamTurn, 'Shot',true);
        ShowCornerFreeKickGrid;   //
    end
    else PanelCorner.Visible := False;
  end
  else if MyBrain.w_FreeKick4  then begin
    PanelCorner.Visible := False;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkillSE( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Coa then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        WaitForXY_CornerCOF := true;
        LoadAdvTeam (MyBrain.TeamTurn, 'Crossing',true);
        ShowCornerFreeKickGrid;   //
    end
    else PanelCorner.Visible := False;
  end
  else if MyBrain.w_Cod then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, OpponentCorner );
      HighLightField( CornerMap.HeadingCellD [0].X,CornerMap.HeadingCellD [0].Y,0);
      LoadAdvTeam (MyBrain.TeamTurn, 'Heading',true);
      ShowCornerFreeKickGrid;
    end
    else PanelCorner.Visible := False;

  end
  else if MyBrain.w_CornerKick  then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        tcp.SendStr( 'COR' + endofline);
    end;
  end;

   btnTactics.Down := false;  // clientloadbrain risponde sempre resettando a screenlivematch
   btnsubs.Down := false;

   btnTactics.Visible := Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;

   if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
    or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then begin
     btnsubs.Visible := False;
     btntactics.Visible := False;
   end
   else begin
    btnsubs.Visible := True;
    btntactics.Visible := true;
   end;

   PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;


    if (Mybrain.Score.TeamGuid [0]  = MyGuidTeam ) or (Mybrain.Score.TeamGuid [1]  = MyGuidTeam ) then
      btnWatchLiveExit.Visible := false
      else btnWatchLiveExit.Visible := true;

     SetGlobalCursor(crHandPoint );

     if (not AudioCrowd.Playing) and ( not btnAudioStadium.Down) then begin
      AudioCrowd.Play;
     end;

   if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
    or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then begin
     btnsubs.Visible := False;
   end
   else btnsubs.Visible := True;
//   if Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam then begin

    if Mybrain.TeamTurn = 0 then begin
      btnSubs.Left := lblNick0.Left;
      btnTactics.Left := btnSubs.Left + btnSubs.Width;
      lblNick0.Blinking := True;
      lblNick1.Blinking := false;
    end
    else if Mybrain.TeamTurn = 1 then begin
      lblNick0.Blinking := false;
      lblNick1.Blinking := True;
      btnTactics.Left := lblNick1.Left + lblNick1.Width - btnTactics.Width ;
      btnSubs.Left := btnTactics.Left - btnSubs.Width;
    end;

end;

procedure  Tform1.SetSelectedPlayer ( aPlayer: TSoccerPlayer);
var
  i,L: Integer;
  aSubSprite : SE_SubSprite;
begin
  fSelectedPlayer := aPlayer;
  HighLightFieldFriendly_hide;
  se_gridskilloldCol := -100; // forza il mouseover sulla stessa skill se cambio selectedplayer
  se_gridskilloldRow := -100;
    for i := 0 to se_players.SpriteCount -1 do begin
      if fSelectedPlayer <> nil then begin

        if se_players.Sprites [i].Guid = aPlayer.ids then begin
          aSubSprite:= se_players.Sprites [i].FindSubSprite ('selected');
          if aSubSprite = nil then begin
            aSubSprite := SE_SubSprite.create( dir_interface + 'selected.bmp', 'selected', 0,0, True , true);
            se_players.Sprites [i].SubSprites.add ( aSubSprite );
          end;
        end
        else  begin
          se_players.Sprites [i].DeleteSubSprite ('selected');
        end;

      end;
    end;

end;
procedure Tform1.SetTmlPosition ( team: string );
begin
  if team = '0' then begin

      ProgressSeconds.Left := lblNick0.Left;
      JvShapedButton1.Left := SE_Theater1.left;
      JvShapedButton2.Left := JvShapedButton1.left + JvShapedButton1.Width ;
      JvShapedButton3.Left := JvShapedButton2.left + JvShapedButton2.Width ;
      JvShapedButton4.Left := JvShapedButton3.left + JvShapedButton3.Width ;
      imgshpfree.Left := JvShapedButton4.left + JvShapedButton4.Width ;
  end
  else begin
      JvShapedButton1.Left := PanelSkillSE.Left + PanelSkillSE.Width ;
      JvShapedButton2.Left := JvShapedButton1.left + JvShapedButton1.Width ;
      JvShapedButton3.Left := JvShapedButton2.left + JvShapedButton2.Width ;
      JvShapedButton4.Left := JvShapedButton3.left + JvShapedButton3.Width ;
      imgshpfree.Left := JvShapedButton4.left + JvShapedButton4.Width ;
      ProgressSeconds.Left := lblNick1.Left;
  end;
end;


procedure Tform1.i_tml ( MovesLeft,team: string );
var
  fore,back: TColor;
begin

    SetTmlPosition ( Team );
    DontDoPlayers:= False;

    lbl_minute.Caption := IntToStr(MyBrain.Minute) +'''';

    fore := MyBrain.Score.DominantColor [ StrToInt(Team)  ];
    Back:= GetContrastColor(MyBrain.Score.DominantColor [ StrToInt(Team)]) ;
    JvShapedButton1.Color := fore;
    JvShapedButton2.Color := fore;
    JvShapedButton3.Color := fore;
    JvShapedButton4.Color := fore;
//    JvShapedButton5.Color := fore;
    ProgressSeconds.StartColor := fore;
    ProgressSeconds.EndColor := fore;
    ProgressSeconds.Font.Color := back;
    ProgressSeconds.Visible := true;

  case StrToInt(MovesLeft) of
    0:Begin

      JvShapedButton1.Visible := False;
      JvShapedButton2.Visible := False;
      JvShapedButton3.Visible := False;
      JvShapedButton4.Visible := False;

    End;
    1:Begin

      JvShapedButton1.Visible := true;
      JvShapedButton2.Visible := False;
      JvShapedButton3.Visible := False;
      JvShapedButton4.Visible := False;
    End;
    2:Begin

      JvShapedButton1.Visible := true;
      JvShapedButton2.Visible := true;
      JvShapedButton3.Visible := false;
      JvShapedButton4.Visible := False;
    End;
    3:Begin
      JvShapedButton1.Visible := true;
      JvShapedButton2.Visible := true;
      JvShapedButton3.Visible := true;
      JvShapedButton4.Visible := False;
    End;
    4:Begin
      JvShapedButton1.Visible := true;
      JvShapedButton2.Visible := true;
      JvShapedButton3.Visible := true;
      JvShapedButton4.Visible := true;
    End;
  end;


    imgshpfree.Visible := MyBrain.ShpFree = 1 ;
end;
procedure Tform1.i_tuc ( team: string );
var
  fore,back: TColor;
begin

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

   SetTmlPosition ( Team );
    //CreateSplash ( Translate('Round',1)  + ' ' + MyBrain.Score.Team [MyBrain.TeamTurn],msSplashTurn);

    fore := MyBrain.Score.DominantColor [ StrToInt(Team) ];
    Back:= GetContrastColor(MyBrain.Score.DominantColor [ StrToInt(Team)]) ;

    ProgressSeconds.StartColor := fore;
    ProgressSeconds.EndColor := fore;
    ProgressSeconds.Font.Color := back;

    JvShapedButton1.Color := fore;
    JvShapedButton1.Visible:= True;


    JvShapedButton2.Color := fore;
    JvShapedButton2.Visible:= True;

    JvShapedButton3.Color := fore;
    JvShapedButton3.Visible:= True;

    JvShapedButton4.Color := fore;
    JvShapedButton4.Visible:= True;

//    JvShapedButton5.Color := fore;
    imgshpfree.Visible := MyBrain.ShpFree = 1 ;

   // if MyBrain.Score.TeamGuid [StrToInt(Team)] = GuidTeam then
   //   btnSkill11.Visible := True
   //   else btnSkill11.Visible := false;
   btnTactics.Visible := Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;


   if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
    or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then begin
     btnsubs.Visible := False;
   end
   else btnsubs.Visible := True;
//   if Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam then begin
    if team = '0' then begin
      btnSubs.Left := lblNick0.Left;
      btnTactics.Left := btnSubs.Left + btnSubs.Width;
      lblNick0.Blinking := True;
      lblNick1.Blinking := false;
    end
    else if team = '1' then begin
      lblNick0.Blinking := false;
      lblNick1.Blinking := True;
      btnTactics.Left := lblNick1.Left + lblNick1.Width - btnTactics.Width ;
      btnSubs.Left := btnTactics.Left - btnSubs.Width;
    end;



end;
procedure Tform1.i_red ( ids: string );
var
  aPlayer: TSoccerPlayer;
begin

    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    aPlayer:= MyBrain.GetSoccerPlayer2(ids);
    advdicewriterow ( aplayer.Team, Translate('lbl_RedCard'),  aplayer.surname,  aplayer.ids , 'FAULT','');
    MyBrain.PutInReserveSlot(aPlayer); // anticipa quello che farà il server
    MoveInReserves (aPlayer);

end;
procedure Tform1.i_yellow ( ids: string );
var
  aPlayer: TSoccerPlayer;
begin

    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    aPlayer:= MyBrain.GetSoccerPlayer2(ids);
    advdicewriterow ( aplayer.Team, Translate('lbl_YellowCard'),  aplayer.surname,  aplayer.ids , 'FAULT','');

end;
procedure Tform1.i_injured ( ids: string );
var
  aPlayer: TSoccerPlayer;
begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
     aPlayer:= MyBrain.GetSoccerPlayer2(ids);
     advdicewriterow ( aplayer.Team, Translate('lbl_Injured'),  aplayer.surname,  aplayer.ids , 'FAULT','');
     // MoveInReserves (aPlayer);
     // aPlayer.Sprite.Visible := false;
     // AdvScoreClickCell(advScore,0,0); btntactics
end;
procedure TForm1.AnimCommon ( Cmd:string);
var
  tsCmd: TStringList;
  aPlayer: TSoccerPlayer;
begin
  tsCmd:= TstringList.Create ;
  tsCmd.CommaText := Cmd;//Mybrain.tsScript [0];

  if (tsCmd[0]= 'sc_player')  or (tsCmd[0]='sc_pa') then begin
    // il player è già posizionato
    AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
  end
  else if tsCmd[0]= 'sc_DICE' then begin
//    TsScript.add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
//    IntTostr(aPlayer.Passing)+',Short.Passing,'+ aPlayer.ids+','+IntTostr(Roll.value) + ',' + Roll.fatigue +',0');
    aPlayer :=  MyBrain.GetSoccerPlayer (  tsCmd[6] );

    advDice.ScrollInView(0, advDice.RowCount -1, spLeading);                                                  //F o N
    AnimationScript.Tsadd ('cl_showroll,' + aPlayer.Ids + ',' + tsCmd[3]  + ',' + tsCmd[5] + ',' + tsCmd[8] );
  end
  else if tsCmd[0]= 'sc_ai.movetoball' then begin   // movetoball prima di aimoveall
    AnimationScript.Tsadd ('cl_wait,2000');
  end
  else if tsCmd[0]= 'sc_mtbDICE' then begin
    aPlayer :=  MyBrain.GetSoccerPlayer (  tsCmd[6] );
    advDice.ScrollInView(0, advDice.RowCount -1, spLeading);
    AnimationScript.Tsadd ('cl_mtbshowroll,' + aPlayer.Ids + ',' + tsCmd[3]  + ',' + tsCmd[5]);
    AnimationScript.Tsadd ('cl_wait,1600');
  end
  else if tsCmd[0]= 'sc_TML' then begin
    AnimationScript.TsAdd  ( 'cl_tml,' + tsCmd[1] + ','+ tsCmd[2] );
  end
  else if tsCmd[0]= 'sc_TUC' then begin
    AnimationScript.TsAdd  ( 'cl_tuc,' + tsCmd[1]);
  end
  else if tsCmd[0]= 'sc_fault.cheatballgk' then begin
   AnimationScript.TsAdd  ( 'cl_fault.cheatballgk,' + tsCmd[1]);
  end
  else if tsCmd[0]= 'sc_fault.cheatball' then begin
   AnimationScript.TsAdd  ( 'cl_fault.cheatball,' + tsCmd[1]);
  end
  else if tsCmd[0]= 'sc_GAMEOVER' then begin
    AnimationScript.TsAdd  ( 'cl_splash.gameover');
    AnimationScript.TsAdd  ( 'cl_wait,3000');
  end;

  tsCmd.free;

end;
procedure TForm1.Logmemo ( ScriptLine : string );
begin

    if Pos ('sc_ai.moveall', ScriptLine,1) <> 0 then begin
      MarkingMoveAll := True;
    end
    else if Pos ('sc_ai.endmoveall',ScriptLine,1) <> 0 then begin
      MarkingMoveAll := False;
      memo2.Lines.Add(ScriptLine);
      Exit;
    end;
    // SC_ST
    if Pos ('SC_ST', ScriptLine,1) <> 0 then Exit;

    if not MarkingMoveAll then
      memo1.Lines.Add( ScriptLine )
      else memo2.Lines.Add(ScriptLine);

end;
procedure TForm1.Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=13 then begin
    Key :=0;
    BtnLoginClick ( BtnLogin);
  end;
end;

procedure TForm1.ElaborateTsScript;  // tsScript arriva dal server e contiene l'animazione da realizzare qui sul client
var
  TsCmd : TstringList;
  aTackle,exBallPlayer, aGK,BallPlayer: TSoccerPlayer;
  I: Integer;
begin
  tsCmd:= TstringList.Create ;

  tsCmd.CommaText := Mybrain.tsScript [0];

  MarkingMoveAll:= False;
  LogMemo ( tsCmd.CommaText );

//*****************************************************************************************************************************************
//
//
//   if tsCmd[0] = 'SERVER_PLM'   Player move, un player si muove con o senza palla
//
//*****************************************************************************************************************************************
    if tsCmd[0] = 'SERVER_PLM' then begin   // ids aplayer.cellx, aplayer.celly, cellx celly

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Move,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );


        if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd (  'cl_ball.move,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd (  'cl_ball.move.toball,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_bounce' then begin
          AnimationScript.Tsadd (  'cl_ball.bounce,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
        end
        else if tsCmd[0]= 'sc_ai.moveall' then begin
          AnimationScript.Tsadd ('cl_ball.stop' );
        end
        else if tsCmd[0]= 'sc_noswap' then begin
          // 1 ids tackle
          // 2 ids defender
          // 3 cellx
          // 4 celly
          // 5 cellx provenienza tentativo tackle
          // 6 celly provenienza tentativo tackle

         // AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
         // Dist := AbsDistance(StrToInt( tsCmd[5]),StrToInt( tsCmd[6]),StrToInt( tsCmd[3]),StrToInt( tsCmd[4])     );
         // AnimationScript.Tsadd ('cl_wait,' + IntTostr(( dist * sprite1cell)));

        end
    // in realtà qui sono già swappati nel brain
        else if tsCmd[0] = 'sc_swap' then begin  // in caso di contrasto automatico difensivo ( tackle automatico )
          // 1 ids tackle
          // 2 ids defender
          // 3 cellx
          // 4 celly
          // 5 cellx provenienza tackle riuscito
          // 6 celly provenienza tackle riuscito

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]);
          AnimationScript.Tsadd ('cl_wait,' + IntTostr((  sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4] +',' +   tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;


        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;   // prima mostro i Roll ( tiro dado 1d4 )

    end
//*****************************************************************************************************************************************
//
//
//   else if (tsCmd[0]= 'SERVER_SHP') then begin    Short.Passing, passaggio corto.
//
//*****************************************************************************************************************************************
    else if (tsCmd[0]= 'SERVER_SHP') then begin   // ids aplayer.cellx aplayer.celly  cellx celly

      imgshpfree.Visible := MyBrain.ShpFree = 1 ;

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Short.Passing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]  );

        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.toball,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else if tsCmd[0]='sc_bounce' then begin  // rimbalzo nel caso venga intercettato
          AnimationScript.Tsadd (  'cl_ball.bounce,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_player.move.intercept' then begin
          AnimationScript.Tsadd ('cl_player.move.intercept,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait,' + IntTostr( sprite1cell));
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll ;

    end

//*****************************************************************************************************************************************
//
//
//   else if (tsCmd[0]= 'SERVER_TAC') or (tsCmd[0] = 'SERVER_DRI')  Tackle oppure Dribbling
//
//*****************************************************************************************************************************************
    else if (tsCmd[0]= 'SERVER_TAC') or (tsCmd[0] = 'SERVER_DRI') then begin   // ids aplayer.cellx aplayer.celly cellx celly

      PrepareAnim;
      if tsCmd[0]= 'SERVER_TAC' then
      AnimationScript.Tsadd ( 'cl_mainskillused,Tackle,'+ tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else
      AnimationScript.Tsadd ( 'cl_mainskillused,Dribbling,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]= 'sc_tackle.no' then begin   // il tackle non riesce, il player ci prova ma torna nella sua cella
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo tackle
          // 4 celly provenienza tentativo tackle
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          aTackle := MyBrain.GetSoccerPlayer(tsCmd[1]);

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] ); // va sulla cella della palla
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));  // aspetto un po'
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );  // torna alla cella di partenza

        end
        else if tsCmd[0] = 'sc_tackle.ok' then begin  // il tackle riesce
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo tackle
          // 4 celly provenienza tentativo tackle
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale
          aTackle := MyBrain.GetSoccerPlayer(tsCmd[1]);
          exBallPlayer := MyBrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

          AnimationScript.Tsadd ('cl_player.move,'      +  exBallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));

        end
        else if tsCmd[0] = 'sc_tackle.ok10' then begin // il tackle riesce perfettamente, se può avanza di una cella nella direzione del tackle
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo tackle
          // 4 celly provenienza tentativo tackle
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[1]);      // il player che che fa tackle sul portatore di palla
          exBallPlayer := Mybrain.GetSoccerPlayer(tsCmd[2]); // il player che aveva la palla ma l'ha persa
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] +',' + tsCmd[1]+ ',0'  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));


        end
        else if tsCmd[0]= 'sc_dribbling.no' then begin
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

         // BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
         // aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[3] + ','+tsCmd[4] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]= 'sc_dribbling.ok.10' then begin    // uguale a sotto
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move.toball,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move.toball,3,' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]= 'sc_dribbling.ok' then begin
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move.toball,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move.toball,3,' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end


        else if tsCmd[0]= 'sc_yellow' then begin

          AnimationScript.TsAdd  ( 'cl_yellow,' + tsCmd[1]);
        end
        else if tsCmd[0]= 'sc_red' then begin
          AnimationScript.TsAdd  ( 'cl_red,' + tsCmd[1]);
        end
        else if tsCmd[0]= 'sc_injured' then begin
          AnimationScript.TsAdd  ( 'cl_injured,' + tsCmd[1]);
        end
        else if (tsCmd[0]= 'sc_fault')  then begin
          AnimationScript.Tsadd ('cl_fault,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1500)));
        end
        else if (tsCmd[0]= 'sc_fault.cheatballgk')  then begin
          AnimationScript.Tsadd ('cl_fault.cheatballgk,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1500)));
        end
        else if (tsCmd[0]= 'sc_fault.cheatball')  then begin
          AnimationScript.Tsadd ('cl_fault.cheatball,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1500)));
        end
        else if tsCmd[0]= 'sc_FREEKICK1.FKA1' then begin
//        AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
          AnimationScript.Tsadd ('cl_freekick1.fka1,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
        end
        else if tsCmd[0]= 'sc_FREEKICK2.FKA2' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
          AnimationScript.Tsadd ('cl_freekick2.fka2,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
        end
        else if tsCmd[0]= 'sc_FREEKICK3.FKA3' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
          AnimationScript.Tsadd ('cl_freekick3.fka3,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
        end
        else if tsCmd[0]= 'sc_FREEKICK4.FKA4' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
//          AnimationScript.Ts.Insert(AnimationScript.Index + 1 ,'cl_wait,3000');
          AnimationScript.Tsadd ('cl_freekick4.fka4,' + tsCmd[1]+','+tsCmd[2] +','+tsCmd[3] );
        end
        else if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_ball.move,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]   );
         // AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd (  'cl_ball.move.toball,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_bounce' then begin
          AnimationScript.Tsadd (  'cl_ball.bounce,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;


        i := i+1;
      end;


      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr(MaxDistance*Sprite1cell));
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;


    end


//*****************************************************************************************************************************************
//
//
//   tsCmd[0] = 'SERVER_LOP'
//
//*****************************************************************************************************************************************


   else if tsCmd[0] = 'SERVER_LOP' then begin
      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Lofted.Pass,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      i:=1;
      //MainPlayer :=   Mybrain.GetSoccerPlayer ( tsCmd[1]);
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]  );
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.toball,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end

    // in realtà qui sono già swappati nel brain
        else if tsCmd[0] = 'sc_lop.heading.bounce' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 ids aHeading
          // 4 cellx aPlayer
          // 5 celly aPlayer
          // 6 cellx aFriend
          // 7 celly aFriend
          // 8 cellx aHeading
          // 9 celly aHeading
          // 10 cellx  Ball.cellx
          // 11 celly Ball.cellx


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[3] + ',' + tsCmd[8] + ','+tsCmd[9]  +',' + tsCmd[6] + ','+tsCmd[7] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[6]+ ','+tsCmd[7] +',' + tsCmd[8] + ','+tsCmd[9] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[1]+ ',heading' );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[1]+ ',0' );

        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.bounce' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+ ',' + tsCmd[1]+ ',0' );
        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.bounce.toball' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'  +  tsCmd[2] + ','+tsCmd[5]+ ','+tsCmd[6] + ','+tsCmd[7]+','+tsCmd[8] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.ok10' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend

          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );

        end
        else if tsCmd[0] = 'sc_lop.no' then begin
          // 1 ids aPlayer
          // 2 cellx aPlayer
          // 3 celly aPlayer
          // 4 cellx  Ball.cellx
          // 5 celly Ball.cellx
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[2] + ','+tsCmd[3]+ ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[1]+ ',0' );
        end
        else if tsCmd[0] = 'sc_lop.ok10' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx  Ball.cellx
          // 6 celly Ball.cellx
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );

        end
        else if tsCmd[0] = 'sc_lop.back.bounce' then begin  // esiste sul volley
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_lop.back.swap.bounce' then begin   // esiste sul volley
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end

        else if tsCmd[0] = 'sc_lop.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0'  );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if (tsCmd[0] = 'sc_pos.bounce.gk')  or (tsCmd[0] = 'sc_lop.bounce.gk') then begin  // anche tiro al volo
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,'+tsCmd[9]  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
          //QUI tsCmd [7] e tsCmd [8] indicano la cella di uscita - MyBrain.,ball è già sulla cella del corner

        end

        //crossbar e gol uguali pos e prs
        else if (tsCmd[0] = 'sc_lop.bounce.crossbar')  or (tsCmd[0] = 'sc_prs.bounce.crossbar') then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,5,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_lop.gol'   then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball

                  { TsScript.add ('sc_cross.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,volley'  );

          AnimationScript.Tsadd ('cl_lop.gol,3,' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  );
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait,' + IntTostr(Sprite1cell));
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;
   end


//*****************************************************************************************************************************************
//
//
//    else if (tsCmd[0] = 'SERVER_CRO') or (tsCmd[0] = 'SERVER_POS') or (tsCmd[0] = 'SERVER_PRS') or (tsCmd[0] = 'SERVER_COR') then begin
//
//*****************************************************************************************************************************************


   else if (tsCmd[0] = 'SERVER_CRO')  or (tsCmd[0] = 'SERVER_POS') or (tsCmd[0] = 'SERVER_PRS') or (tsCmd[0] = 'SERVER_COR')
      or (tsCmd[0] = 'SERVER_POS3' ) or (tsCmd[0] = 'SERVER_PRS3' ) or (tsCmd[0] = 'SERVER_POS4' ) or (tsCmd[0] = 'SERVER_PRS4' )   then begin


      PrepareAnim;
      if tsCmd[0] = 'SERVER_CRO' then
        AnimationScript.Tsadd ( 'cl_mainskillused,Crossing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else if  Pos ( 'POS', tsCmd[0] ,1) <> 0 then
        AnimationScript.Tsadd ( 'cl_mainskillused,Power.Shot,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else if  Pos ( 'PRS', tsCmd[0] ,1) <> 0 then
        AnimationScript.Tsadd ( 'cl_mainskillused,Precision.Shot,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else if  tsCmd[0] =  'SERVER_COR' then
        AnimationScript.Tsadd ( 'cl_mainskillused,Crossing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      if (tsCmd[0] = 'SERVER_COR')then begin
        // prepare corner
        AnimationScript.Tsadd ('cl_prepare.corner,' +  tsCmd[1] +  ','+tsCmd[2]+ ','+tsCmd[3] );
      end;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

//***********************************************************************************************************
//
//           POS
//
//
//***********************************************************************************************************
        if tsCmd[0] = 'sc_pos.back.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_pos.back.swap.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end

        else if tsCmd[0] = 'sc_pos.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0'  );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_pos.bounce.gk' then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end

        //crossbar e gol uguali pos e prs
        else if (tsCmd[0] = 'sc_pos.bounce.crossbar')  or (tsCmd[0] = 'sc_prs.bounce.crossbar') then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if (tsCmd[0] = 'sc_pos.gol') or  (tsCmd[0] = 'sc_prs.gol')  then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)

          AnimationScript.Tsadd ('cl_' + rightStr(tsCmd[0],7) +',3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,'+tsCmd[9]  );
        end

//***********************************************************************************************************
//
//          PRS
//
//
//***********************************************************************************************************


        else if tsCmd[0] = 'sc_prs.back.stealball' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'  +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[7] + ','+tsCmd[8] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_prs.stealball' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_prs.gk' then begin
          // 1 ids aPlayer
          // 2 aGK anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 aGK anOpponent
          // 6 aGK anOpponent
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end



        else if tsCmd[0]='sc_bounce.heading' then begin  // ids , cellx, celly , dstcellx, dstcelly

//          aPlayer:= Mybrain.GetSoccerPlayer(tsCmd[1]);

          AnimationScript.Tsadd (  'cl_ball.bounce.heading,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]='sc_bounce.gk' then begin
//          aGK := Mybrain.GetSoccerPlayer  ( StrToInt(tsCmd[1]),StrToInt(tsCmd[2]));
          AnimationScript.Tsadd (  'cl_ball.bounce.gk,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]='sc_bounce.crossbar' then begin
//          aGK := Mybrain.GetSoccerPlayer  ( StrToInt(tsCmd[1]),StrToInt(tsCmd[2]));
          AnimationScript.Tsadd (  'cl_ball.bounce.gk,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end

//***********************************************************************************************************
//
//           CORNER o CRO2 ( freekick2 )
//
//
//***********************************************************************************************************
    // in realtà qui sono già swappati nel brain
        else if (tsCmd[0] = 'sc_corner.headingdef.swap.bounce') or (tsCmd[0] = 'sc_cro2.headingdef.swap.bounce')  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aHeadingOpponent
          // 4 cellx Corner
          // 5 celly Corner
          // 6 cellx aPlayer
          // 7 celly aPlayer
          // 8 cellx aHeadingFriend    già swappati i 2 heading sul corner
          // 9 celly aHeadingFriend
          // 10 cellx aHeadingOpponent
          // 11 celly aHeadingOpponent
          // 12 cellx  Ball.cellx
          // 13 celly Ball.cellx
{                     TsScript.add ('sc_corner.headingdef.swap.bounce,' + aPlayer.Ids +','  + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));  }


          // già swappati nel corner
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[10] + ','+tsCmd[11]  +',' + tsCmd[8] + ','+tsCmd[9] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[3] + ',' + tsCmd[8] + ','+tsCmd[9]  +',' + tsCmd[10] + ','+tsCmd[11] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,heading'  );


          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.headingdef.bounce') or  (tsCmd[0] = 'sc_cro2.headingdef.bounce')   then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aHeadingOpponent
          // 4 cellx Corner
          // 5 celly Corner
          // 6 cellx aPlayer
          // 7 celly aPlayer
          // 8 cellx aHeadingOpponent
          // 9 celly aHeadingOpponent
          // 10 cellx  Ball.cellx
          // 11 celly Ball.cellx

                  {   TsScript.add ('sc_corner.headingdef.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids +',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));   }


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.headingatt.swap') or  (tsCmd[0] ='sc_cro2.headingatt.swap') then begin
          // 1 ids aHeadingFriend
          // 2 ids aHeadingOpponent
          // 3 cellx  aHeadingFriend
          // 4 celly aHeadingFriend
          // 5 cellx aHeadingOpponent
          // 6 celly aHeadingOpponent

                      { TsScript.add ('sc_corner.headingatt.swap,' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)); }
          // già swappati nel corner
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

        end
        else if (tsCmd[0] = 'sc_corner.bounce.gk') or (tsCmd[0] = 'sc_cro2.bounce.gk') then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  Corner
          // 5 celly Corner
          // 6 cellx  aPlayer
          // 7 celly aPlayer
          // 8 cellx  aHeadingFriend
          // 9 celly aHeadingFriend
          // 10 cellx aGK
          // 11 celly aGK
          // 12 cellx Ball
          // 13 celly Ball
          // 14 left right


                { TsScript.add ('sc_corner.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[8]+ ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,3,' + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.bounce.crossbar') or (tsCmd[0] = 'sc_cro2.bounce.crossbar') then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  Corner
          // 5 celly Corner
          // 6 cellx  aPlayer
          // 7 celly aPlayer
          // 8 cellx  aHeadingFriend
          // 9 celly aHeadingFriend
          // 10 cellx aGK
          // 11 celly aGK
          // 12 cellx Ball
          // 13 celly Ball
          // 14 left right

                 {  TsScript.add ('sc_pos.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );   }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[8]+ ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,3,' + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.gol') or (tsCmd[0] = 'sc_cro2.gol') then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  Corner
          // 5 celly Corner
          // 6 cellx  aPlayer
          // 7 celly aPlayer
          // 8 cellx  aHeadingFriend
          // 9 celly aHeadingFriend
          // 10 cellx aGK
          // 11 celly aGK
          // 12 cellx Ball
          // 13 celly Ball
          // 14 left right

                  { TsScript.add ('sc_corner.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );

          if (tsCmd[0] = 'sc_corner.gol') then
            AnimationScript.Tsadd ('cl_corner.gol,3,' + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  )
          else if (tsCmd[0] = 'sc_cro2.gol') then
            AnimationScript.Tsadd ('cl_cro2.gol,3,' + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  );



    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Z
    //7 Left o right 1 2

        end

//***********************************************************************************************************
//
//           CROSS
//
//
//***********************************************************************************************************


        else if tsCmd[0] = 'sc_cross.gol'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball
          // 12 left right

                  { TsScript.add ('sc_cross.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,heading'  );

          AnimationScript.Tsadd ('cl_cross.gol,3,' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  );
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Z
    //7 Left o right 1 2

        end
        else if tsCmd[0] = 'sc_cross.bounce.crossbar'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball

                 {  TsScript.add ('sc_pos.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY)  );   }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[6]+ ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,3,' + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if tsCmd[0] = 'sc_cross.bounce.gk'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball
                  {TsScript.add ('sc_cross.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY)  ); }


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[6]+ ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,3,' + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if tsCmd[0] = 'sc_cross.headingdef.swap.bounce'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aHeadingOpponent
          // 4 cellx aPlayer
          // 5 celly aPlayer
          // 6 cellx aHeadingFriend    già swappati i 2 heading sul corner
          // 7 celly aHeadingFriend
          // 8 cellx aHeadingOpponent
          // 9 celly aHeadingOpponent
          // 10 cellx  Ball.cellx
          // 11 celly Ball.cellx
{                   TsScript.add ('sc_cross.headingdef.swap.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeading.ids
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeading.cellx)+',' + IntTostr(aHeading.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));}


          // già swappati nel cross
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[8] + ','+tsCmd[9]  +',' + tsCmd[6] + ','+tsCmd[7] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[3] + ',' + tsCmd[6] + ','+tsCmd[7]  +',' + tsCmd[8] + ','+tsCmd[9] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );


          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if tsCmd[0] = 'sc_cross.headingdef.bounce'  then begin
          // 1 ids aPlayer
          // 2 ids aGhost
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGhost
          // 6 celly aGhost
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

                  { TsScript.add ('sc_cross.headingdef.bounce,' + aPlayer.Ids +',' + aGhost.ids + ','
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aGhost.cellx)+',' + IntTostr(aGhost.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly)); }


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,3,' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,heading'  );
          AnimationScript.Tsadd ('cl_ball.bounce,3,' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );

        end





        else if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.toball,3,' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_gol.cross' then begin
          AnimationScript.Tsadd ('cl_gol.cross,' + tsCmd[1] + ','+ tsCmd[2]+','+tsCmd[3] + ','+ tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_CORNER.COA' then begin
//  TsScript.add ('sc_CORNER.COA,' + intTostr(TeamTurn) + ',' + IntTostr( CornerMap.CornerCell.X) +','+IntTostr( CornerMap.CornerCell.Y) ) ; // richiesta al client corner free kick
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
//          AnimationScript.Ts.Insert(AnimationScript.Index + 1 ,'cl_wait,3000');
          AnimationScript.Tsadd ('cl_corner.coa,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );

        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait,' + IntTostr((  Sprite1cell)));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;   // prima tutti i showroll da eseguire in AnimationScript

   end
   else if tsCmd[0] = 'SERVER_PASS' then begin   // tscmd[1] il team che passa
     // tt := tsCmd[1];
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;
      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;

//      if tt = '0' then
//        AnimationScript.TsAdd  ( 'cl_tuc,' + '1')
 //       else AnimationScript.TsAdd  ( 'cl_tuc,' + '0');



   end


   // Corner

   else if tsCmd[0] = 'SERVER_COA.IS' then begin   // cof + swapstring

      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'COA.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_coa.is,' + tsCmd.CommaText );  // cof coa + swapstring
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      WaitForXY_CornerCOF := false;
      WaitForXY_CornerCOA := false;
      WaitForXY_CornerCOD := true;

      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_COD.IS' then begin

      PrepareAnim;
      WaitForXY_CornerCOD := false;

      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'COD.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_cod.is,' + tsCmd.CommaText );  //  cod + swapstring
          AnimationScript.Tsadd ('cl_wait,2000');
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_FKA1.IS' then begin
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin

          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          if tsCmd[0] = 'FKA1.IS' then begin
            tsCmd.Delete(0);
            AnimationScript.Tsadd ('cl_fka1.is,' + tsCmd.CommaText );  // team, fka1 + swapstring
          end
          else AnimCommon ( tsCmd.commatext );

          i := i+1;
      end;

      AnimationScript.Index := 0;
      WaitForXY_FKF1 := false;
      WaitForXY_FKA2 := false;
//      WaitForXY_FKD2 := true;

      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_FKA2.IS' then begin   // fka2 + swapstring
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin

        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKA2.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka2.is,' + tsCmd.CommaText );  // team, fka1 + swapstring
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      WaitForXY_FKF2 := false;
      WaitForXY_FKA2 := false;
      WaitForXY_FKD2 := true;

      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0] = 'SERVER_FKD2.IS' then begin

      PrepareAnim;
      AnimationScript.Reset ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKD2.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka2.is,' + tsCmd.CommaText );  // team, fkd2 + swapstring
        end
        else  AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      WaitForXY_FKD2 := false;


      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_FKA3.IS' then begin   // fkf3 + swapstring
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKA3.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka3.is,' + tsCmd.CommaText );  // team, fka3 + swapstring
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      WaitForXY_FKF3 := false;
     // WaitForXY_FKA3 := false;
      WaitForXY_FKD3 := true;

      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0] = 'SERVER_FKD3.IS' then begin // barriera

      PrepareAnim;
      i:=1;

      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKD3.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fkd3.is,' + tsCmd.CommaText );  // team, fkd3 + swapstring
          AnimationScript.Tsadd ('cl_wait,2000');
        end
        else if (tsCmd[0]= 'sc_player.barrier')  then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.barrier,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      WaitForXY_FKD3 := false;
      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0] = 'SERVER_FKA4.IS' then begin   // fkf4 + swapstring
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKA4.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka4.is,' + tsCmd.CommaText );  // team, fkd4 + swapstring
          AnimationScript.Tsadd ('cl_wait,2000');
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      WaitForXY_FKF4 := false;

      Mybrain.tsScript.Clear ;
   end


   else if tsCmd[0]= 'SERVER_TACTIC' then begin
      // il player è già posizionato


      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
        if tsCmd[0] = 'sc_tactic' then begin
          AnimationScript.Tsadd ('cl_tactic,' +  tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] +  ',' + tsCmd[4]+ ',' + tsCmd[5]  ); // ids , defaultcellx, defaultcelly , newdefx, newdefy
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(1000));
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0]= 'SERVER_SUB' then begin
      // il player è già posizionato

      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
        if tsCmd[0] = 'sc_sub' then begin
          AnimationScript.Tsadd ('cl_sub,' +  tsCmd[1] + ',' + tsCmd[2] ); // ids1 , ids2
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0]= 'SERVER_STAY' then begin
      // il player è già posizionato
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
//        if tsCmd[0] = 'sc_tactic' then begin
//          AnimationScript.Tsadd ('cl_tactic,' +  tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] +  ',' + tsCmd[4]+ ',' + tsCmd[5]  ); // ids , defaultcellx, defaultcelly , newdefx, newdefy
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(1000));
//        end
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0]= 'SERVER_FREE' then begin
      // il player è già posizionato
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
//        if tsCmd[0] = 'sc_tactic' then begin
//          AnimationScript.Tsadd ('cl_tactic,' +  tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] +  ',' + tsCmd[4]+ ',' + tsCmd[5]  ); // ids , defaultcellx, defaultcelly , newdefx, newdefy
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(1000));
//        end
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end


    //
    // esterni per semplici movimenti
    // comandi singoli
    //



   else if tsCmd[0]= 'SERVER_PRE' then begin
      // il player è già posizionato

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Pressing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );


          i := i+1;
      end;

//      AnimationScript.Tsadd ('cl_wait,' + IntTostr(sprite1cell));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0]= 'SERVER_PRO' then begin
      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Protection,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      i:=1;


      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

//      AnimationScript.Tsadd ('cl_wait,' + IntTostr(sprite1cell));
 //     AnimationScript.Tsadd ('cl_wait,1000');
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end;



//  if Mybrain.tsScript.count > 0 then begin
//    Mybrain.tsScript.Delete(0);
//  end;
  //Mybrain.tsScript.Clear ;
  TsCmd.Free;


end;


procedure TForm1.FirstShowRoll ; // primo mostriamo i roll, in seguito l'animazione
var
  i,NextDice: Integer;
  Main, showRoll: string;
  tmp: TStringList;
  label retry;
begin
//  nextdice := 0;
  for i := 1 to AnimationScript.Ts.Count -1 do begin   // a partire da 1. setto il mainskillused
    if LeftStr ( AnimationScript.Ts[i],16) = 'cl_mainskillused' then begin
      Main := AnimationScript.Ts[i];
      AnimationScript.Ts[i]:='';
//      NextDice:=i;
      Break;
    end;
  end;

//  if NextDice > 0 then   begin
//    AnimationScript.Ts.Insert(0,Main);
//    AnimationScript.Ts.Insert(1,'cl_wait,2000');
//  end;

  tmp := TStringList.Create;

  for i := 1 to AnimationScript.Ts.Count -1 do begin
    if LeftStr (AnimationScript.Ts[i],11) = 'cl_showroll' then begin
      tmp.add (AnimationScript.Ts[i]);
      AnimationScript.Ts[i]:='';
    end;
  end;

  for i := AnimationScript.Ts.Count -1 downto 1 do begin
    if AnimationScript.Ts[i] = '' then begin
      AnimationScript.Ts.Delete(i);
    end;
  end;

  NextDice:=1;
  for i := 0 to tmp.Count -1 do begin
      AnimationScript.Ts.Insert ( NextDice, tmp[i]);
//      AnimationScript.Ts.Insert ( NextDice+1, 'cl_wait,1600');
      NextDice := NextDice + 1;
  end;

  tmp.Free;

  // dopo ogni showroll o mainskilled inserisco il clwait, per dare un certo tempo di leggere i roll
Retry:
  for i := 0 to AnimationScript.Ts.Count -2 do begin
    if LeftStr (AnimationScript.Ts[i],11) = 'cl_showroll' then begin
      if pos ( 'cl_wait' , AnimationScript.Ts[i+1],1) = 0 then begin
        AnimationScript.Ts.Insert ( i+1,'cl_wait,1800');
        goto retry;
      end;
    end
    else if LeftStr (AnimationScript.Ts[i],16) = 'cl_mainskillused' then begin
      if pos ( 'cl_wait' , AnimationScript.Ts[i+1],1) = 0 then begin
        AnimationScript.Ts.Insert ( i+1,'cl_wait,1800');
        goto retry;
      end;
    end;
  end;


  for i := 0 to AnimationScript.Ts.Count -1 do begin
    memo3.Lines.Add(AnimationScript.Ts[i]);
  end;
end;



procedure TForm1.UpdateSubSprites;
var
  p: Integer;
  SeSprite: SE_SubSprite;
begin

    for P:= 0 to MyBrain.lstSoccerPlayer.Count -1 do begin

         if (MyBrain.lstSoccerPlayer[p].BonusSHPturn > 0) or (MyBrain.lstSoccerPlayer[p].BonusPLMTurn > 0)
         or (MyBrain.lstSoccerPlayer[p].BonusTackleTurn > 0) or (MyBrain.lstSoccerPlayer[p].BonusLopBallControlTurn > 0)
         or (MyBrain.lstSoccerPlayer[p].BonusProtectionTurn > 0)
         then begin
            SeSprite := se_SubSprite.create ( dir_attributes + 'star.bmp','star', 0,0,true,true);
            MyBrain.lstSoccerPlayer[P].SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (MyBrain.lstSoccerPlayer[p].RedCard > 0) or (MyBrain.lstSoccerPlayer[p].Yellowcard = 2)
         or (MyBrain.lstSoccerPlayer[p].disqualified > 0)
         then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true,true);
            MyBrain.lstSoccerPlayer[P].SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (MyBrain.lstSoccerPlayer[p].Injured  > 0)  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'injured.bmp','injured', 0,0,true,true);
            MyBrain.lstSoccerPlayer[P].SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (MyBrain.lstSoccerPlayer[p].YellowCard  > 0)  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'yellow.bmp','yellow', 0,0,true,true);
            MyBrain.lstSoccerPlayer[P].SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (MyBrain.lstSoccerPlayer[p].PlayerOut  )  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'inout.bmp','inout', 0,0,true,true);
            MyBrain.lstSoccerPlayer[P].SE_Sprite.SubSprites.Add(SeSprite);
         end;

         if (MyBrain.lstSoccerPlayer[p].stay  )  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'stay.bmp','stay', 0,0,true,true);
            MyBrain.lstSoccerPlayer[P].SE_Sprite.SubSprites.Add(SeSprite);
         end;

   //   end;

      // se l'avversario ha la palla ed è il nostro turno
          if (MyBrain.TeamTurn <> MyBrain.GetTeamBall) and (MyBrain.GetTeamBall <> -1)  then begin
           //  CreateTextChanceValueSE (  MyBrain.Ball.Player.ids, MyBrain.Ball.Player.BallControl   , dir_attributes + 'Ball.Control',0,0,0,0);
          end;
    end;
    for P:= 0 to MyBrain.lstSoccerReserve.Count -1 do begin

       if (MyBrain.lstSoccerReserve[p].RedCard > 0) or (MyBrain.lstSoccerReserve[p].Yellowcard = 2)
       or (MyBrain.lstSoccerReserve[p].disqualified > 0)
       then begin
          SeSprite := se_SubSprite.create ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true,true);
          MyBrain.lstSoccerReserve[P].SE_Sprite.SubSprites.Add(SeSprite);
       end
       else if (MyBrain.lstSoccerReserve[p].Injured  > 0)  then begin
          SeSprite := se_SubSprite.create ( dir_interface + 'injured.bmp','injured', 0,0,true,true);
          MyBrain.lstSoccerReserve[P].SE_Sprite.SubSprites.Add(SeSprite);
       end
       else if (MyBrain.lstSoccerReserve[p].PlayerOut )  then begin
          SeSprite := se_SubSprite.create ( dir_interface + 'inout.bmp','inout', 0,0,true,true);
          MyBrain.lstSoccerReserve[P].SE_Sprite.SubSprites.Add(SeSprite);
       end;


    end;

end;

procedure TForm1.advAllbrainClickCell(Sender: TObject; ARow, ACol: Integer);
begin
  if GCD <= 0 then begin

    if aCol = 10 then begin
      if advAllBrain.Cells[0,aRow] <> ''  then begin
        if (not viewMatch)  then begin
          gameScreen := ScreenWaitingWatchLive ;
          MemoC.Lines.Add('>tcp: viewmatch,' + advAllBrain.Cells[0,aRow] ); // col 0 = brainIds
          tcp.SendStr(  'viewmatch,' + advAllBrain.Cells[0,aRow] + EndofLine );
//          GCD := GCD_DEFAULT;
          viewMatch := True;
          SetGlobalCursor( crHourGlass);
        end;
      end;
    end;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.advCountryTeamKeyPress(Sender: TObject; var Key: Char);
var
  i: Integer;
begin
  for I := 0 to advCountryTeam.RowCount -1 do begin
    if UpperCase(LeftStr(advCountryTeam.Cells[1,i],1)) = UpperCase(key) then begin
      advCountryTeam.Row := i;
      Break;
    end;
  end;
end;

procedure TForm1.AdvTeamClickCell(Sender: TObject; ARow, ACol: Integer);
var
  aCellBarrier, aCellPenalty: TPoint;
  CornerMap: tCornerMap;
  SwapPlayer: TSoccerPlayer;
  TeamCornerOrfreeKick: Integer;
  rndY : Integer;
  aSeField: SE_Sprite;
begin
  if GCD > 0 then Exit;
  if aRow = 0 then exit;
  // Qui sotto ci sono 3 blocchi: richiesta COF, FKF     COA      COD
  if advTeam.FontColors [1,aRow] <> clSilver then begin  // in formazione squalificati, infortunati sono tutti grigi
    advTeam.FontColors [1,aRow] := clSilver;
    advTeam.FontColors [2,aRow] := clSilver;
    advTeam.FontColors [3,aRow] := clSilver;
    if  (WaitForXY_FKF1)  then begin

          SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow]  ) ; // ids
          TsCoa.add (SelectedPlayer.Ids);
          if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK1_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
          GCD := GCD_DEFAULT;
          WaitForXY_FKF1:= False;
          PanelCorner.Visible := False;
    end
    else if (WaitForXY_FKF4) and (MyBrain.w_Fka4 ) then begin   // rigore
          SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow]  ) ; // ids
          TsCoa.add (SelectedPlayer.Ids);

            if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK4_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
            GCD := GCD_DEFAULT;
            WaitForXY_FKF4:= False;
          PanelCorner.Visible := False;
    end
    else if (WaitForXY_CornerCOF) or (WaitForXY_FKF2)  then begin

        SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow]  ) ; // ids
        tscoa.Add ( SelectedPlayer.Ids );

        if ((WaitForXY_CornerCOF) and (MyBrain.w_Coa)) then begin
          WaitForXY_CornerCOF := false;
          WaitForXY_CornerCOA := true;
          TeamCornerOrfreeKick :=  MyBrain.TeamCorner;
          CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
          aSeField := SE_field.FindSprite( IntToStr(CornerMap.CornerCell.X) +'.' + IntToStr(CornerMap.CornerCell.Y) );
          SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.CornerCell.X, CornerMap.CornerCell.Y);
          // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
          SelectedPlayer.SE_Sprite.MoverData.Destination := Point( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );

          while (MyBrain.GameStarted ) and ((Animating) or (se_players.IsAnySpriteMoving )) do begin
            se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
            application.ProcessMessages ;
          end;

          CornerSetPlayer(SelectedPlayer);
         // SelectedPlayer.SE_Sprite.Position := aSeField.Position;
        end
        else if ((WaitForXY_FKF2) and (MyBrain.w_Fka2 )) then begin
          aSeField := SE_field.FindSprite( IntToStr(MyBrain.Ball.cellX) +'.' + IntToStr(MyBrain.Ball.cellY) );
          SwapPlayer := MyBrain.GetSoccerPlayer( MyBrain.Ball.cellX,MyBrain.Ball.CellY);
          WaitForXY_FKF2:= False;
          WaitForXY_FKA2:= true;
          TeamCornerOrfreeKick :=  MyBrain.TeamFreeKick;
          CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
          // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
          SelectedPlayer.SE_Sprite.MoverData.Destination :=  aSeField.Position;
         // SelectedPlayer.SE_Sprite.Position :=  aSeField.Position;
        end;




        // setto anche la palla
//        Mybrain.Ball.SE_Sprite.MoverData.Destination := aSeField.Position ;
//        Mybrain.Ball.SE_Sprite.Position := aSeField.Position ;


          // swappo come farà il brain un eventuale swapplayer
          if SwapPlayer <> nil then begin
            if SwapPlayer.Ids <> SelectedPlayer.ids then begin
            SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X   , aSeField.Position.Y + 30 );
          //  SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X   , SelectedPlayer.SE_Sprite.Position.Y +30);
            end;
          end;


//        SetPolyCellColor( CornerMap.HeadingCellA [0].X,CornerMap.HeadingCellA [0].Y, clyellow);
          if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then
            HighLightField ( CornerMap.HeadingCellA [0].X,CornerMap.HeadingCellA [0].Y,0);

        LoadAdvTeam (TeamCornerOrfreeKick, 'Heading' , false);

        // ribadisco per via del reload
        advTeam.FontColors [1,aRow] := clSilver;
        advTeam.FontColors [2,aRow] := clSilver;
        advTeam.FontColors [3,aRow] := clSilver;

    end
    else if ((WaitForXY_CornerCOA) and (MyBrain.w_Coa)) or ((WaitForXY_FKA2) and (MyBrain.w_Fka2 ))  then begin

          SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow]  ) ; // ids
          // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
          if ((WaitForXY_CornerCOA) and (MyBrain.w_Coa)) then
            TeamCornerOrfreeKick :=  MyBrain.TeamCorner
            else if ((WaitForXY_FKA2) and (MyBrain.w_Fka2 )) then
             TeamCornerOrfreeKick :=  MyBrain.TeamFreeKick;

          CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;


          aSeField := SE_field.FindSprite( IntToStr(CornerMap.HeadingCellA [TsCoa.count-1].X) +'.' + IntToStr(CornerMap.HeadingCellA [TsCoa.count-1].Y) );


          SelectedPlayer.SE_Sprite.MoverData.Destination := aSeField.Position ;
      //    SelectedPlayer.SE_Sprite.Position := aSeField.Position;

          // swappo come farà il brain un eventuale swapplayer
          SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellA [TsCoa.count-1].X, CornerMap.HeadingCellA [TsCoa.count-1].Y);
          TsCoa.add (SelectedPlayer.Ids);//<-- dopo la riga sopra

          if SwapPlayer <> nil then begin
            if SwapPlayer.Ids <> SelectedPlayer.ids then begin
            SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X, aSeField.Position.Y +30);
         //   SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X, SelectedPlayer.SE_Sprite.Position.Y +30);
            end;
          end;

          if tsCoa.Count = 4 then begin   // cof + 3 coa
            if ((WaitForXY_CornerCOA) and (MyBrain.w_Coa)) then begin
              if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'CORNER_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
              WaitForXY_CornerCOA:= false;
              PanelCorner.Visible := False;
            end
            else if ((WaitForXY_FKA2) and (MyBrain.w_Fka2 )) then begin
              if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK2_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
              WaitForXY_FKA2:= false;
              PanelCorner.Visible := False;
            end;
//            tsCoa.Clear ;  non svuotare
            exit;
          end;

        // se sono io
          if MyBrain.Score.AI[MyBrain.TeamTurn] = false then
            HighLightField( CornerMap.HeadingCellA [TsCoa.count-1].X,CornerMap.HeadingCellA [TsCoa.count-1].Y,0 );

    end
    else if ((WaitForXY_CornerCOD) and (MyBrain.w_Cod)) or ((WaitForXY_FKD2) and (MyBrain.w_Fkd2 )) then begin
          SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow] ) ; // ids

          // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
          if ((WaitForXY_CornerCOD) and (MyBrain.w_CoD)) then
            TeamCornerOrfreeKick :=  MyBrain.TeamCorner
            else if ((WaitForXY_FKD2) and (MyBrain.w_Fkd2 )) then
             TeamCornerOrfreeKick :=  MyBrain.TeamFreeKick;
          CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;

          aSeField := SE_field.FindSprite( IntToStr(CornerMap.HeadingCellD [TsCod.count].X) +'.' + IntToStr(CornerMap.HeadingCellD [TsCod.count].Y) );

          // 2 direzioni in cui guardare ... fix?
          SelectedPlayer.SE_Sprite.MoverData.Destination := aSeField.Position ;
       //   SelectedPlayer.SE_Sprite.Position := aSeField.Position ;

          // swappo non come farà il brain un eventuale swapplayer, ma affianco gli sprite
          TsCod.add (SelectedPlayer.Ids);//<-- prima della riga sotto
          SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellD [TsCod.count-1].X, CornerMap.HeadingCellD [TsCod.count-1].Y);

          if SwapPlayer <> nil then begin
            if SwapPlayer.Ids <> SelectedPlayer.ids then begin
            SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X   , aSeField.Position.Y +30);
        //    SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X   , SelectedPlayer.SE_Sprite.Position.Y +30);
            end;
          end;

          if tsCod.Count = 3 then begin  // 3 cod
            if ((WaitForXY_CornerCOD) and (MyBrain.w_Cod)) then begin
              if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'CORNER_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
              WaitForXY_CornerCOD:= False;
              PanelCorner.Visible := False;
            end
            else if ((WaitForXY_FKD2) and (MyBrain.w_Fkd2 )) then begin
              if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK2_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
              WaitForXY_FKD2 := False;
              GCD := GCD_DEFAULT;
              PanelCorner.Visible := False;
            end;
            exit;
          end;

          //c'è exit sopra, TsCod.count è corretto
          if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then
            HighLightField( CornerMap.HeadingCellD [TsCod.count].X,CornerMap.HeadingCellD [TsCod.count].Y ,0);
          // sposto la freccia
//          aSprite := e_Highlights.FindSpritebyIDS('arrowcor' );
//          aCell:= GetPolyCells (CornerMap.HeadingCellD [TsCod.count].X,CornerMap.HeadingCellD [TsCod.count].Y );
//          aSprite.MoverData.Destination :=   Point (aCell.PixelX , aCell.pixelY -20);
//          aSprite.Position := Point (aCell.PixelX , aCell.pixelY -20);


    end
    else if (WaitForXY_FKF3) and (MyBrain.w_Fka3 ) then begin // punizione dal limite
          SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow]  ) ; // ids
          TsCoa.add (SelectedPlayer.Ids);

          aSeField := SE_field.FindSprite( IntToStr(MyBrain.Ball.CellX) +'.' + IntToStr(MyBrain.Ball.CellY) );
//          SwapPlayer := MyBrain.GetSoccerPlayer( MyBrain.Ball.cellX,MyBrain.Ball.CellY);
          WaitForXY_FKF3:= False;
          WaitForXY_FKD3:= true;
//          CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
          // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)

         // ACellBarrier :=  MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
         // aSeField := SE_field.FindSprite( IntToStr(ACellBarrier.X) +'.' + IntToStr(ACellBarrier.Y) );
          SelectedPlayer.SE_Sprite.MoverData.Destination := aSeField.Position ;

         //   if SwapPlayer <> nil then begin
         //     if SwapPlayer.Ids <> SelectedPlayer.ids then begin
         //       SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + 30) ;
         //     end;
         //   end;

        //  if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then
        //    HighLightField( ACellBarrier.X, ACellBarrier.Y ,0);

            if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK3_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
            PanelCorner.Visible := False;
            GCD := GCD_DEFAULT;

    end
    else if ((WaitForXY_FKD3) and (MyBrain.w_Fkd3 )) then begin // BARRIERA
          SelectedPlayer:= MyBrain.GetSoccerPlayer(advTeam.Cells [0,aRow]  ) ; // ids

          // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
          CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
          ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.CellY)  ; // la cella barriera !!!!
          aSeField := SE_field.FindSprite( IntToStr(ACellBarrier.X) +'.' + IntToStr(ACellBarrier.Y) );


          rndY := RndGenerateRange(3,22);
          if Odd(RndGenerate(2)) then rndY := -rndY;

          SelectedPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X  , aSeField.Position.Y + rndY);
      //    SelectedPlayer.SE_Sprite.Position := Point (aSeField.Position.X  , aSeField.Position.Y + rndY);

          // swappo non come farà il brain un eventuale swapplayer, ma affianco gli sprite
          TsCod.add (SelectedPlayer.Ids);// in barriera swappo solo il primo
          if tsCod.Count = 1 then begin // in barriera swappo solo il primo
            SwapPlayer := MyBrain.GetSoccerPlayer( ACellBarrier.X , ACellBarrier.Y );

            if SwapPlayer <> nil then begin
              if SwapPlayer.Ids <> SelectedPlayer.ids then begin
               SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X +30  , aSeField.Position.Y   );
         //     SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X   , SelectedPlayer.SE_Sprite.Position.Y + 30);
              end;
            end;
          end
          else if tsCod.Count = 4 then begin  // 4 in barriera
            if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK3_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
            PanelCorner.Visible := False;
            GCD := GCD_DEFAULT;
            WaitForXY_FKD3:= False;
            exit;
          end;

    end;


  end;
end;

procedure TForm1.Anim ( Script: string );
var
  i,rndY,posY: Integer;
  ts: TstringList;
  aPoint: TPoint;
  netgol,head: Integer;
  aPath: dse_pathPlanner.Tpath;
  aStep: dse_pathPlanner.TpathStep ;
  ClockWise: TArcDirection;
  aCell,aCell2: TSoccerCell;
  aPlayer,aPlayer2, aTackle, aGK, aBarrierPlayer : TSoccerPlayer;
  srcCellX, srcCellY, dstCellX, dstCellY,Z : integer; // Source e destination Cells
  Dst, TmpX,tmpY: integer;
  CornerMap: TCornerMap;
  aCellBarrier: TPoint;
  sebmp: SE_Bitmap;
  seSprite: SE_Sprite;
  ASoccerCellFK, ASoccerCell: TSoccerCell;
  modifierX,ModifierY,visX,visY: integer;
  aSEField: SE_Sprite;
  aSize:TSize;
  FaultBitmap: SE_Bitmap;
  ff:Byte;
begin


  ts := TstringList.Create ;
  ts.CommaText := Script;

  if ts[0] = 'cl_showroll' then begin
    //1 aPlayer.ids
    //2 Roll Totale
    //3 Skill used
    //4 N o F
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    // i punteggi
    sebmp:= Se_bitmap.Create (32,32);
    if ts[4] = 'F' then
      sebmp.Bitmap.Canvas.Brush.color := clMaroon
    else        //  'N'
      sebmp.Bitmap.Canvas.Brush.color := clGray;

    sebmp.Bitmap.Canvas.Ellipse(6,6,26,26);
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 10;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
    sebmp.Bitmap.Canvas.Font.Color := clYellow;
    if length(ts[2]) = 1 then
      sebmp.Bitmap.Canvas.TextOut( 12,8, ts[2])
      else sebmp.Bitmap.Canvas.TextOut( 7,8, ts[2]);

    // o è una skill o è un attributo nel panelcombat
    if Translate ( 'skill_' + ts[3]) <> '' then
      advdicewriterow ( aplayer.Team,  UpperCase( Translate ( 'skill_' + ts[3])),  aplayer.surname,  aPlayer.ids , ts[2], '' )
      else advdicewriterow ( aplayer.Team,  UpperCase( Translate ( 'attribute_' + ts[3])),  aplayer.surname,  aPlayer.ids , ts[2], '' );

    SeSprite := se_numbers.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aPlayer.SE_Sprite.Position.X  , aPlayer.SE_Sprite.Position.Y , true );
    SeSprite.LifeSpan := ShowRollLifeSpan;
    sebmp.Free;

  end
  else if ts[0] = 'cl_mtbshowroll' then begin
    //1 aPlayer.ids
    //2 Roll Totale
    //3 Skill used
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    // i punteggi
    sebmp:= Se_bitmap.Create (32,32);
    sebmp.Bitmap.Canvas.Brush.color := clGray;
    sebmp.Bitmap.Canvas.Ellipse(6,6,26,26);
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 10;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
    sebmp.Bitmap.Canvas.Font.Color := clYellow;
    if length(ts[2]) = 1 then
      sebmp.Bitmap.Canvas.TextOut( 12,8, ts[2])
      else sebmp.Bitmap.Canvas.TextOut( 7,8, ts[2]);
    advdicewriterow ( aplayer.Team,  UpperCase( Translate ( 'skill_Move')),  aplayer.surname,  aPlayer.ids , ts[2], '' );

    SeSprite := se_numbers.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aPlayer.SE_Sprite.Position.X  , aPlayer.SE_Sprite.Position.Y , true );
    SeSprite.LifeSpan := ShowRollLifeSpan;
    sebmp.Free;

  end
  else if ts[0] = 'cl_mainskillused' then begin
    //1 skill
    //2 aPlayer.ids
    //3 aPlayer.cellx
    //4 aPlayer.cellY
    //5 cellx         // non sempre
    //6 cellY         // non sempre
    aPlayer := MyBrain.GetSoccerPlayer(ts[2]);

    // la skill usata e i punteggi
    aSEField := SE_field.FindSprite( Ts[5] + '.' + Ts[6] );

    sebmp:= Se_bitmap.Create (80,14);
    sebmp.Bitmap.Canvas.Brush.color := $007B5139;
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 8;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
    sebmp.Bitmap.Canvas.Font.Color := clYellow;
    ASize:=sebmp.Bitmap.Canvas.TextExtent(ts[1]);
    sebmp.Resize( aSize.Width, aSize.Height, $007B5139  );
      sebmp.Bitmap.Canvas.TextOut( 1,0, ts[1]);
//    advdicewriterow ( ts[1], aplayer.surname,  aPlayer.ids , 'VS');

    posY := aSEField.Position.Y - 30;
    if PosY < 20 then posY := 30;


    SeSprite := se_numbers.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aSEField.Position.X  ,  posY, true );
    SeSprite.LifeSpan := ShowRollLifeSpan * 2;
    sebmp.Free;

    HighLightField( StrToInt(Ts[3]), StrToInt(Ts[4]) , ShowRollLifeSpan * 2);
    HighLightField( StrToInt(Ts[5]), StrToInt(Ts[6]) , ShowRollLifeSpan * 2);

    posY := aSEField.Position.Y -aSize.Height;
    if PosY < 20 then posY := 30;

    SeSprite := se_numbers.CreateSprite( dir_interface + 'arrowmoving.bmp', 'cone', 8, 1, 5, aSEField.Position.X  ,posY , true );
//    seSprite.Angle := AngleOfLine( aPlayer.se_sprite.Position, aSEField.Position  ) ;
    SeSprite.LifeSpan := ShowRollLifeSpan * 2;
//    SeSprite.Scale := 50;

  end

  else if ts[0] = 'cl_sub' then begin

     // sono veramente già swappati sul brain , ma qui ancora no perchè il clientloadbrain ciene caricato dopo questo scritp
     aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
     aPlayer2:= MyBrain.GetSoccerPlayer2(ts[2]);
     // sono veramente già swappati quindi la sefield è di aplayer2 , quello che verrà sostituito

     advdicewriterow ( aplayer.Team, Translate('lbl_Substitution'),  aplayer.surname,  aplayer2.surname , 'FAULT','');
     InOutBitmap:= SE_Bitmap.Create ( InOutBitmap );
     aSeField := SE_field.FindSprite( IntToStr(aPlayer2.CellX )+ '.' + IntToStr(aPlayer2.CellY ) );
     seSprite:= SE_interface.CreateSprite(InOutBitmap.BITMAP ,'inout',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     InOutBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;


  end
  else if ts[0] = 'cl_tactic' then begin
     aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
     advdicewriterow ( aplayer.Team, Translate('lbl_Tactic'),  aplayer.surname,  aplayer.ids , 'FAULT','');

  end
  else if ts[0] = 'cl_sound' then begin
    if ts[1]='soundishot' then begin
//      playsound ( pchar (dir_sound +  'shot.wav' ) , 0, SND_FILENAME OR SND_ASYNC)
      AudioShot.Position := 0;
      Audioshot.Play;
    end
    else if ts[1]='soundtackle' then begin
//       playsound ( pchar (dir_sound +  'tackle.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
      AudioTackle.Position := 0;
      AudioTackle.Play;
    end;
  end
  else if ts[0] = 'cl_red' then begin
    i_red(ts[1]);

  end
  else if ts[0] = 'cl_injured' then begin

    i_injured(ts[1]);
  end
  else if ts[0] = 'cl_yellow' then begin

    i_Yellow(ts[1]);
  end
  else if ts[0] = 'cl_tuc' then begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) and  (se_Ball.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      i_tuc ( ts[1]);
  end
  else if ts[0] = 'cl_tml' then begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) and  (se_Ball.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      i_tml ( ts[1], ts[2]);
  end
  else if ts[0] = 'cl_player.move.heading' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo per heading
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;

  end
  else if ts[0] = 'cl_player.speed' then begin
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aPlayer.Se_Sprite.MoverData.Speed := strToFloat(ts[2]);
  end
  else if ts[0] = 'cl_ball.stop' then begin
    MyBrain.Ball.Se_sprite.FrameXmax :=0;
  end
  else if ts[0] = 'cl_player.move.barrier' then begin

    ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
    aSeField := SE_field.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));

    rndY := RndGenerateRange(3,22);
    if Odd(RndGenerate(2)) then rndY := -rndY;
    aBarrierPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aBarrierPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
//    aBarrierPlayer.SE_Sprite.Position := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
  end
  else if ts[0] = 'cl_player.move' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;
  end
  else if ts[0] = 'cl_player.move.toball' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    case aPlayer.team of
      0: begin
        Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X +abs(Ball0X),aSEField.Position.Y + BallZ0Y);
      end;
      1: begin
        Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X -abs(Ball0X),aSEField.Position.Y+ BallZ0Y);
      end;
    end;
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;

  end
  else if ts[0] = 'cl_player.move.intercept' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

  end
  else if ts[0] = 'cl_player.move.strange' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

  end
  else if ts[0] = 'cl_ball.move' then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 ids eventuale azione
    //7 heading, intercept, stop ecc... oppure gol,bar, o un numero per dire quale angolo
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    if ts[7] = 'heading' then begin
      Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X , aSEField.Position.Y - 20) ; // forza il calculateVectors
    end
    else if ts[7] = 'gol' then begin
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X -20 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X +20 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
      end;
    end
    else if ts[7] = 'bar' then begin
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X -10 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X +10 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
      end;

    end
{    else if ts[7] = '1' then begin
      aSEField := SE_field.FindSprite( '-1.2');
      Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position

    end
    else if ts[7] = '2' then begin
      aSEField := SE_field.FindSprite( '11.2');
      Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position

    end  }
    else
      Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position;

  {    if Mybrain.Ball.Player <> nil then begin
        if Mybrain.Ball.Player.Role='G' then begin
          AudioNoGol.Position:=0;
          AudioNoGol.Play;
        end;
      end; }

  end
  else if ts[0] = 'cl_ball.move.toball' then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 ids eventuale azione
    //7 heading, intercept, stop ecc...
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);


    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    head:=0;
    if Ts[7] = 'heading' then head:= -20;
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    //aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

      if Mybrain.Ball.Player = nil then
        Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X ,aSEField.Position.Y + BallZ0Y+ head)
      else begin

        case Mybrain.Ball.Player.team of
          0: begin
            Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X  +abs(Ball0X),aSEField.Position.Y + BallZ0Y);
          end;
          1: begin
            Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X -abs(Ball0X),aSEField.Position.Y + BallZ0Y);
          end;
        end;

        {if Mybrain.Ball.Player.Role='G' then begin
          AudioNoGol.Position:=0;
          AudioNoGol.Play;
        end;}
      end;


  end
  else if  (ts[0] = 'cl_ball.bounce') or (ts[0] = 'cl_ball.bounce.heading') or (ts[0] = 'cl_ball.bounce.back')
     or (ts[0] = 'cl_ball.bounce.crossbar') or (ts[0] = 'cl_ball.bounce.gk')
    then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 ids eventuale azione
    //7 heading, intercept, stop ecc...

   //QUI tsCmd [4] e tsCmd [5] indicano la cella di uscita - MyBrain.,ball è già sulla cella del corner

    if (ts[0] = 'cl_ball.bounce') or (ts[0] = 'cl_ball.bounce.heading') or (ts[0] = 'cl_ball.bounce.back') then begin
      AudioBounce.Position:=0;
      AudioBounce.Play;
    end

    else if (ts[0] = 'cl_ball.bounce.gk') then  begin
//      playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
      AudioBounce.Position:=0;
      AudioBounce.Play;
//      Sleep(300);

      AudioNoGol.Position:=0;
      AudioNoGol.Play;
    end;

//    (ts[0] = 'cl_ball.bounce.crossbar') <-- gestita in se_ball.destinationreached
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

//    CornerMap := MyBrain.GetCorner ( MyBrain.TeamCorner ,  dstCellY, OpponentCorner );

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position;

  end


  else if ts[0] = 'cl_prepare.corner' then begin

    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    CornerSetPlayer (aPlayer);

  end
  else if ts[0] = 'cl_wait' then begin
    //1 milliseconds
    AnimationScript.wait :=StrToInt(Ts[1]);

  end
  else if ts[0] = 'cl_wait.moving.players' then begin
    //1 milliseconds
    AnimationScript.waitMovingPlayers := true;

  end
  else if ts[0] = 'cl_destroy' then begin
//    AnimationScript.Reset ;
    SpriteReset ;
  end
  else if (ts[0]= 'cl_pos.gol') or (ts[0]= 'cl_prs.gol') or (ts[0]= 'cl_corner.gol') or (ts[0]= 'cl_cro2.gol') or (ts[0]= 'cl_cross.gol') or (ts[0]= 'cl_lop.gol') then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Z
    //7 Left o right 1 2

    // la palla in MyBrain è già a 6 3 o 5 3, ma lo sprite no
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) and (se_ball.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);


    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point(  aSEField.Position.X - 20, aSEField.Position.Y);
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point(  aSEField.Position.X + 20, aSEField.Position.Y);
        end;
      end;

    AnimationScript.TsAdd  ( 'cl_splash.gol');
    AnimationScript.TsAdd  ( 'cl_wait,3000');
  end
  else if ts[0]= 'cl_splash.gol' then begin
    advdicewriterow ( 0,   'Gol!!!',  '',  '' , '', '' );
  end
  else if ts[0]= 'cl_splash.gameover' then begin
    advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_GameOver' )),  '',  '' , '', '' );
//  playsound ( pchar (dir_sound +  'gameover.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    AudioGameOver.Position:=0;
    AudioGameOver.Play;
    se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
    Sleep(2000);
    AnimationScript.Reset ;
    LiveMatch := False;
    ViewMatch := False;
    GameScreen := ScreenMain;
  end
// da qui in poi carico prima il brain
  else if ts[0]= 'cl_corner.coa' then begin   // richiede un coa , mostro lo splash corner
      // teamturn e corner , cornerx cornery

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      PanelSkillSE.Visible := false;
     // Cl_BrainLoaded := true;
     // ClientLoadBrainSE(dir_data + Format('%.*d',[3, MyBrain.incMove+1]) + '.ini'); // forzo la lettura del brain, devo sapere adesso

      tscoa.Clear;
      //CreateSplash ('Corner',msSplashTurn);
      advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_Corner' )),  '',  '' , '', '' );


  end
  else if ts[0]= 'cl_coa.is' then begin  // conferma di COF + COA + swapstring scelto dal client e automatica richiesta COD

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

//      tscoa.Clear;
      tscod.Clear;

  end


  else if ts[0]= 'cl_cod.is' then begin  // conferma di COD + swapstring scelto dal client

     // tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;


  end
  else if ts[0]= 'cl_freekick1.fka1' then begin   // richiede un fka1 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    tscoa.Clear;
    tscod.clear;

    advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , '', '' );


  end
  else if ts[0]= 'cl_freekick2.fka2' then begin   // richiede un fka2 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;
    advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , '', '' );


  end

  else if ts[0]= 'cl_freekick3.fka3' then begin   // richiede un fka3 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;
    advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , '', '' );


  end

  else if ts[0]= 'cl_freekick4.fka4' then begin   // richiede un fka4 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;
    advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , '', '' );

  end

  else if ts[0]= 'cl_fka1.is' then begin  // team, conferma di FKF1 + swapstring scelto dal client

    // attendo i precendenti sc_player
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

  end

  else if ts[0]= 'cl_fka2.is' then begin  // conferma di FKF2 + FKA2 + swapstring scelto dal client e automatica richiesta FKD2
//      tscoa.Clear;
      tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;



  end
  else if ts[0]= 'cl_fkd2.is' then begin  // conferma difkd2 + swapstring scelto dal client

     // tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

  end

  else if ts[0]= 'cl_fka3.is' then begin  // conferma di FKF3 e basta + swapstring scelto dal client e automatica richiesta FKD2 (barriera)
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscod.Clear;



  end
  else if ts[0]= 'cl_fkd3.is' then begin  // conferma di fkd3 + swapstring scelto dal client  (barriera)

     // tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
        // tscod contiene l'ultimo cod barriera
       // schiera barriera

  end
  else if ts[0]= 'cl_fka4.is' then begin  // conferma di FKF4, la celladel rigore  era stata liberata
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;


  end
  else if ts[0]= 'cl_fault' then begin    //  team a favore, cellx, celly
// TsScript.add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
     aPlayer := MyBrain.GetSoccerPlayer( ts[1] );
     if aPlayer.Team = 0 then ff := 1
     else ff := 0;
     FaultBitmap:= SE_Bitmap.Create ( FaultBitmapBW );
     ColorizeFault(  ff , FaultBitmap );
     aSeField := SE_field.FindSprite(  ts[2] + '.' + ts[3] );
     seSprite:= SE_interface.CreateSprite(FaultBitmap.BITMAP ,'fault',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     FaultBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;
//   playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
     AudioFaul.Position:=0;
     AudioFaul.Play;
     advdicewriterow ( aplayer.Team, Translate('lbl_Fault'),  aplayer.surname,  aPlayer.ids , 'FAULT','');

  end
  else if ts[0]= 'sc_fault.cheatballgk' then begin
     FaultBitmap:= SE_Bitmap.Create ( FaultBitmapBW );
     ColorizeFault(  StrToInt(ts[1]) , FaultBitmap );
     aSeField := SE_field.FindSprite(  ts[2] + '.' + ts[3] );
     seSprite:= SE_interface.CreateSprite(FaultBitmap.BITMAP ,'fault',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     FaultBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;
     advdicewriterow ( 0,  UpperCase( Translate ( 'lbl_Fault' )),  '',  '' , '', '' );
//     playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
     AudioFaul.Position:=0;
     AudioFaul.Play;

     advdicewriterow ( aplayer.Team, Translate('lbl_Fault'),  '',  '' , 'FAULT','');
  end
  else if ts[0]= 'sc_fault.cheatball' then begin
     FaultBitmap:= SE_Bitmap.Create ( FaultBitmapBW );
     ColorizeFault(  StrToInt(ts[1]) , FaultBitmap );
     aSeField := SE_field.FindSprite(  ts[2] + '.' + ts[3] );
     seSprite:= SE_interface.CreateSprite(FaultBitmap.BITMAP ,'fault',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     FaultBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;
     advdicewriterow ( aplayer.Team, Translate('lbl_Fault'),  '',  '' , 'FAULT','');
//     playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
     AudioFaul.Position:=0;
     AudioFaul.Play;

  end;

  ts.free;
  Application.ProcessMessages ;



end;

procedure TForm1.btnTacticsClick(Sender: TObject);
begin
(* Premuto durante la partita  mostra anche la formazione avversaria , premuto solo nel mio turno *)
    // posso cliccare quando è tuto fermo e quando sta a me
  if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 or
  (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) or Animating then Exit;

  if btnTactics.Down  then begin

    GameScreen := ScreenTactics ;

  end
  else begin

    SpriteReset;

    MyBrain.Ball.SE_Sprite.Visible := True;
    fGameScreen := ScreenLiveMatch;    // attenzione alla f, non innescare

  end;

end;
procedure TForm1.btnUniformBackClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    createNoiseTV;
    WAITING_GETFORMATION:= True;
    tcp.SendStr(  'setuniform,' +  TSUniforms[0].CommaText + ',' + TSUniforms[1].CommaText + endofline);
    PanelUniform.Visible:= false;
    GCD := GCD_DEFAULT;
  end;

end;

procedure TForm1.btnSubsClick(Sender: TObject);
begin

(* Premuto durante la partita , premuto solo nel mio turno *)
  if btnSubs.Down then begin

    // posso cliccare quando è tuto fermo e quando sta a me
    if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 or
    (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) or Animating then Exit;

    GameScreen := ScreenSubs
  end
  else begin

    fGameScreen := ScreenLiveMatch;    // attenzione alla f, non innescare
    SpriteReset;

    MyBrain.Ball.SE_Sprite.Visible := True;

  end;
end;

procedure TForm1.btnWatchLiveClick(Sender: TObject);
begin
    if GCD <= 0 then begin
      MemoC.Lines.Add('>tcp: listmatch'  );
      if (not viewMatch) and (not LiveMatch) then tcp.SendStr( 'listmatch' + EndofLine );
      GCD := GCD_DEFAULT;
    end;
   // panel2.Visible := False;

end;

procedure TForm1.btnWatchLiveExitClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    if ViewReplay then begin
      AudioCrowd.Stop;
      ToolSpin.Visible := false;
      ViewReplay := false;
      while (se_ball.IsAnySpriteMoving ) or (se_players.IsAnySpriteMoving ) or (Animating) do begin
        se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
        application.ProcessMessages ;
      end;

      gamescreen := ScreenLogin;
    end
    else if viewMatch then begin
      AudioCrowd.Stop;
      viewMatch := False;
      tcp.SendStr( 'closeviewmatch' + EndofLine);
      while (se_ball.IsAnySpriteMoving ) or (se_players.IsAnySpriteMoving ) or (Animating) do begin
        se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
        application.ProcessMessages ;
      end;
      gamescreen := ScreenMain;
    end;

      JvShapedButton1.Visible := False;
      JvShapedButton2.Visible := False;
      JvShapedButton3.Visible := False;
      JvShapedButton4.Visible := False;
      imgshpfree.Visible := False;
      ProgressSeconds.Visible := False;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnxp0Click(Sender: TObject);
begin

  PanelXPPlayer0.Visible := True;

end;

procedure TForm1.btnxpBack0Click(Sender: TObject);
begin
  PanelXPPlayer0.Visible := false;

end;

procedure TForm1.btnAudioStadiumClick(Sender: TObject);
begin
  if not btnAudioStadium.Down then begin

    if Not AudioCrowd.Playing then begin
      AudioCrowd.Play;
    end;
  end
  else begin // non suonare
    if  AudioCrowd.Playing then begin
      AudioCrowd.Stop;
    end;

  end;
end;

procedure TForm1.btnBackListMatchesClick(Sender: TObject);
begin
  GameScreen := ScreenMain;
end;


procedure TForm1.btnConfirmDismissClick(Sender: TObject);
begin

  if GCD <= 0 then begin
    WAITING_GETFORMATION:= True;
    tcp.SendStr( 'dismiss,'+ se_grid0.SceneName + EndofLine); // solo a sinistra in formation
    PanelDismiss.Visible:= False;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnConfirmSellClick(Sender: TObject);
var
  i,tGK: Integer;
  aPlayer: TSoccerPlayer;
begin
  if GCD <= 0 then begin
    GCD := GCD_DEFAULT;
    PanelSell.Visible := False;
    aPlayer:= MyBrainformation.GetSoccerPlayer2 (se_grid0.SceneName);
    if aPlayer.TalentId=1 then begin
      tGK:=0;
      for I := MyBrainFormation.lstSoccerPlayer.Count -1 downto 0 do begin
        if MyBrainFormation.lstSoccerPlayer[i].TalentId = 1 then
          tGK := tGK +1;
      end;
      if (tGK = 1) and (aPlayer.TalentId=1) then begin
        ShowError ( Translate ('warning_nosellgk'));
        Exit;
      end;
    end;


      WAITING_GETFORMATION:= True;
      btnsell0.Tag:=1;
      btnsell0.Caption := Translate('lbl_CancelSell');
      tcp.SendStr( 'sell,'+ se_grid0.SceneName  + ',' + edtSell.Text + EndofLine); // solo a sinistra in formation
  end;

end;

procedure TForm1.btnDismiss0Click(Sender: TObject);
begin
  PanelDismiss.Visible := True;
  PanelDismiss.BringToFront;
end;

procedure TForm1.btnErrorOKClick(Sender: TObject);
begin
  PanelError.Visible := False;
  if lastStrError = 'errorlogin' then
    PanelLogin.Visible := True;

end;

procedure TForm1.btnExitClick(Sender: TObject);
begin
  Application.Terminate ;
end;

function TForm1.findlstplayer ( guid: string ): TSoccerPlayer;
var
  i: integer;
begin
  for I := 0 to lstPlayers.Count -1 do begin
    if lstplayers[i].Ids = guid then begin
      Result := lstplayers[i];
      Exit;
    end;

  end;

end;
procedure TForm1.btnFormationClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    tcp.SendStr( 'getformation' + EndofLine);
    WAITING_GETFORMATION := True;
    GCD := GCD_DEFAULT;
  end;
end;

function TForm1.isTvCellFormation ( Team, CellX, CellY: integer ): boolean;
begin
  Result := False;
  case team of
    0: if ((CellX = 0) and (CellY=3)) or ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) then Result:= True;
    1: if ((CellX = 11) and (CellY=3)) or ((CellX = 9)  or  (CellX = 6) or (CellX = 3))  then Result:= True;
  end;

end;
procedure TForm1.MoveInReserves ( aPlayer: TSoccerPlayer );
var
  asefield: SE_Sprite;
  TvReserveCell: TPoint;
begin
//   aPlayer.Cells := MyBrain.PutInReserveSlot ( aPlayer );
   TvReserveCell:= MyBrainFormation.ReserveSlotTV [aPlayer.team,aPlayer.CellX,aPlayer.CellY  ];
   aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.x ) + '.' + IntToStr (TvReserveCell.y ));

   aPlayer.se_sprite.MoverData.speed:=20;
   aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

end;
procedure TForm1.MoveInDefaultField ( aPlayer: TSoccerPlayer );
var
  SelectedPoly: TSoccerCell;
  aSEField : SE_Sprite;
begin
  aSEField := SE_field.FindSprite(IntToStr (aPlayer.DefaultCellX ) + '.' + IntToStr (aPlayer.DefaultCellY ));
  aPlayer.SE_Sprite.MoverData.Destination := aSEField.Position ;
  aPlayer.SE_Sprite.position := aSEField.Position ;
end;

procedure Tform1.HighLightField ( CellX, CellY, LifeSpan : integer);
var
  i: integer;
  aCell : TSoccerCell;
  aSEField : SE_Sprite;
  aSubSprite: SE_SubSprite;
  bmp: SE_Bitmap;
begin
  aSEField := SE_field.FindSprite(IntToStr (CellX ) + '.' + IntToStr (CellY ));
  aSEField.SubSprites[0].lVisible := true;
  // aggiungo un subsprite a fieldsprite di un colore verde più chiaro
{  bmp:= se_bitmap.Create(36,36);      // disegno le righe
  bmp.Bitmap.Canvas.Brush.Color :=  $48A881;//$3E906E;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));

  aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(CellX) + '.' + IntToStr(CellY) , 2, 2, true, false );
  if LifeSpan <> 0 then
    aSubSprite.LifeSpan := LifeSpan;
  aSEField.SubSprites.Add(aSubSprite);
  bmp.Free;     }
end;
procedure Tform1.HighLightFieldFriendly ( aPlayer: TSoccerPlayer; cells: char );
var
  i,Y,CellX: integer;
  aSEField : SE_Sprite;
  aSubSprite: SE_SubSprite;
  bmp: SE_Bitmap;
  aPlayer2: TSoccerPlayer;
begin

  // aggiungo un subsprite a fieldsprite di un colore verde più chiaro
 // bmp:= se_bitmap.Create(36,36);      // disegno le righe
 // bmp.Bitmap.Canvas.Brush.Color :=  $48A881;//$3E906E;
 // bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));

  if cells= 'b' then begin // solo sostituzioni , illumino solo possibili compagni da sostituire tenendo conto del GK
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer2 := MyBrain.lstSoccerPlayer[i];
      if aPlayer2.Team = aPlayer.Team  then begin
        if (aPlayer.Talents = 'goalkeeper') and (aPlayer.Talents = 'goalkeeper') then begin
          aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
          aSEField.SubSprites[0].lVisible := true;
//          aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(aPlayer2.CellX) + '.' + IntToStr(aPlayer2.CellY), 2, 2, true, false );
//          aSEField.SubSprites.Add(aSubSprite);
 //         bmp.Free;
 //         Exit;
        end
        else if (aPlayer.Talents <> 'goalkeeper') and (aPlayer.Talents <> 'goalkeeper') then begin
          aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
          aSEField.SubSprites[0].lVisible := true;
//          aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(aPlayer2.CellX) + '.' + IntToStr(aPlayer2.CellY), 2, 2, true, false );
//          aSEField.SubSprites.Add(aSubSprite);
        end

      end;
    end;
  end
  else if cells= 's' then begin // solo sostituzioni a distanza > 4, illumino solo possibili compagni da sostituire tenendo conto del GK
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer2 := MyBrain.lstSoccerPlayer[i];
      if aPlayer2.Team = aPlayer.Team  then begin

        if AbsDistance(aPlayer2.CellX, aPlayer2.CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) >= 4 then begin

          if (aPlayer.TalentID = 1) and (aPlayer2.TalentID = 1) then begin
            aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
            aSEField.SubSprites[0].lVisible := true;
  //          aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(aPlayer2.CellX) + '.' + IntToStr(aPlayer2.CellY), 2, 2, true, false );
  //          aSEField.SubSprites.Add(aSubSprite);
  //         bmp.Free;
  //          Exit;
          end
          else if (aPlayer.TalentID <> 1 ) and (aPlayer2.TalentId <> 1) then begin
            aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
            aSEField.SubSprites[0].lVisible := true;
  //          aSEField.RemoveAllSubSprites;
  //          aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(aPlayer2.CellX) + '.' + IntToStr(aPlayer2.CellY), 2, 2, true, false );
  //          aSEField.SubSprites.Add(aSubSprite);
          end
        end;
      end;
    end;
  end

  else if cells = 'f' then begin // solo celle libere e del proprio team formation
    for CellX := 0 to 11 do begin
      for Y := 0 to 6 do begin
        aPlayer2 := MyBrain.GetSoccerPlayerDefault( CellX, Y );
        if aPlayer2 <> nil then Continue; // skip cella occupata da player
        if ((CellX = 0)  and (Y = 3)) or ((CellX = 11)  and (Y = 3)) then Continue; // tactic non permessa sulla cella portiere

        aSEField := SE_field.FindSprite(IntToStr ( CellX ) + '.' + IntToStr (Y ));


        if ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team = 0) then begin

    //        aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(CellX) + '.' + IntToStr(Y), 2, 2, true, false );
            aSEField.SubSprites[0].lVisible := true;
        end
        else if ( (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team = 1) then begin

     //       aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(CellX) + '.' + IntToStr(Y), 2, 2, true, false );
   //        aSEField.SubSprites[0].lVisible := true;
        end;

      end;

    end;
  end

  else if cells = 't' then begin // celle libere o occupate del proprio team formation
    for CellX := 0 to 11 do begin
      for Y := 0 to 6 do begin
        //aPlayer2 := MyBrain.GetSoccerPlayerDefault( CellX, Y );
        //if aPlayer2 <> nil then Continue; // skip cella occupata da player

        if aPlayer.TalentId <> 1 then begin   // non è un  goalkeeper

          if ((CellX = 0)  and (Y = 3)) or ((CellX = 11)  and (Y = 3)) then Continue; // tactic non permessa sulla cella portiere

          aSEField := SE_field.FindSprite(IntToStr ( CellX ) + '.' + IntToStr (Y ));


          if ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team = 0) then begin
            aSEField.SubSprites[0].lVisible := true;
//              aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(CellX) + '.' + IntToStr(Y), 2, 2, true, false );
//              aSEField.SubSprites.Add(aSubSprite);
          end
          else if ( (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team = 1) then begin
            aSEField.SubSprites[0].lVisible := true;

//              aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(CellX) + '.' + IntToStr(Y), 2, 2, true, false );
//              aSEField.SubSprites.Add(aSubSprite);
          end;

        end
        else begin  //  è un  goalkeeper

          if aPlayer.Team = 0 then begin
            aSEField := SE_field.FindSprite(IntToStr ( 0 ) + '.' + IntToStr ( 3 ));
          end
          else begin
            aSEField := SE_field.FindSprite(IntToStr ( 11 ) + '.' + IntToStr ( 3 ));
          end;

          aSEField.SubSprites[0].lVisible := true;
//        aSubSprite := SE_SubSprite.create(bmp,'highlight' + IntToStr(CellX) + '.' + IntToStr(Y), 2, 2, true, false );
//          aSEField.SubSprites.Add(aSubSprite);

        end;

      end;

    end;
  end;

  bmp.Free;
end;
procedure Tform1.HighLightFieldFriendly_hide;
var
  i: Integer;
begin
  for I := 0 to SE_field.SpriteCount -1 do begin
    SE_field.Sprites [i].SubSprites[0].lVisible := false;
  end;
end;

procedure TForm1.hidechances ;
begin
   //for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
   // MyBrain.lstSoccerPlayer [i].SE_Sprite.Labels.Clear;
   //end;
   SE_interface.removeallSprites;
   HighLightFieldFriendly_hide;


end;
procedure Tform1.SelectedPlayerPopupSkillSE ( CellX, CellY: integer);
var
  i: integer;
  tmp: integer;
  PosX: integer;
  ModifierX, ModifierY: integer;
  aList : TObjectList<TSoccerPlayer>;
  visX,visY: Integer;
  label LoadButtonBar,Preloadbuttonbar;
procedure setupBMp (bmp:TBitmap; aColor: Tcolor);
begin
  BMP.Canvas.Font.Size := 8;
  BMP.Canvas.Font.Quality := fqAntiAliased;
  BMP.Canvas.Font.Color := aColor; //$0041BEFF; //clBlack;//$00C0C0;
  BMP.Canvas.Font.Style :=[fsbold];
  BMP.Canvas.Brush.Style:= bsClear;
end;
begin

    if (WaitForXY_cornerCOF ) or (WaitForXY_cornerCOA ) or (WaitForXY_cornerCOD ) or ( WaitForXY_FKF1 )
      or ( WaitForXY_FKF2 ) or ( WaitForXY_FKA2 ) or ( WaitForXY_FKD2 )
      or ( WaitForXY_FKF3 ) or ( WaitForXY_FKD3 ) or ( WaitForXY_FKF4 ) then begin
      exit;    // input solo da advteam
    end;

    if PanelCorner.Visible  then   // input solo da advteam
      Exit;

  //  if MyBrain.w_CornerSetup  then SelectedPlayer := MyBrain.GetCof
  //  else SelectedPlayer :=  MyBrain.GetSoccerPlayer (  CellX, CellY );

    if MyBrain.w_FreeKick1 then SelectedPlayer := MyBrain.GetFK1
    else if MyBrain.w_FreeKick2 then SelectedPlayer := MyBrain.GetFK2
    else if MyBrain.w_FreeKick3 then SelectedPlayer := MyBrain.GetFK3
    else if MyBrain.w_FreeKick4 then SelectedPlayer := MyBrain.GetFK4
    else SelectedPlayer :=  MyBrain.GetSoccerPlayer (  CellX, CellY );


    if SelectedPlayer=nil then exit;
//    if SelectedPlayer.Team <> MyBrain.TeamTurn then begin
    if (SelectedPlayer.Team <> MyBrain.TeamTurn) or (SelectedPlayer.GuidTeam <> MyGuidTeam)  then begin
      exit;
    end;



    if Not SelectedPlayer.CanSkill then goto Preloadbuttonbar;
//    if SelectedPlayer.GuidTeam <> MyGuidTeam then Exit;

   // HideChances;


    SelectedPlayer.ActiveSkills.Clear ;
    if SelectedPlayer.isCOF then begin
      if SelectedPlayer.Role <> 'G' then SelectedPlayer.ActiveSkills.Add('Corner.Kick=' + IntTostr(SelectedPlayer.Passing + SelectedPlayer.Tal_Crossing  ));
      goto LoadButtonBar; // break
    end
    else if SelectedPlayer.isFK1 then begin
      if SelectedPlayer.Role <> 'G' then begin
        SelectedPlayer.ActiveSkills.Add('Short.Passing=' + IntTostr(SelectedPlayer.Passing ));
        SelectedPlayer.ActiveSkills.Add('Lofted.Pass=' + IntTostr(SelectedPlayer.Passing ));
        goto LoadButtonBar; // break
      end;
    end
    else if SelectedPlayer.isFK2 then begin
//      if SelectedPlayer.Role <> 'G' then SelectedPlayer.ActiveSkills.Add('Crossing=' + IntTostr(SelectedPlayer.Passing + SelectedPlayer.Tal_Crossing  ));
      Exit;
      goto LoadButtonBar; // break
    end
    else if SelectedPlayer.isFK3 then begin
      if SelectedPlayer.Role <> 'G' then begin
        SelectedPlayer.ActiveSkills.Add('Power.Shot=' + IntTostr(SelectedPlayer.shot  ));
        SelectedPlayer.ActiveSkills.Add('Precision.Shot=' + IntTostr(SelectedPlayer.shot  ));
        goto LoadButtonBar; // break
      end;
    end
    else if SelectedPlayer.isFK4 then begin
      if SelectedPlayer.Role <> 'G' then begin
        SelectedPlayer.ActiveSkills.Add('Power.Shot=' + IntTostr(SelectedPlayer.shot  ));
        SelectedPlayer.ActiveSkills.Add('Precision.Shot=' + IntTostr(SelectedPlayer.shot  ));
        goto LoadButtonBar; // break
      end;
    end;


    if (SelectedPlayer.CanMove) and (SelectedPlayer.Role <> 'G')then begin
      tmp:= SelectedPlayer.speed - Abs(Integer(SelectedPlayer.HasBall));
      if tmp <= 0 then tmp := 1;

      if not SelectedPlayer.PressingDone then SelectedPlayer.ActiveSkills.Add('Move=' + IntTostr( tmp  ) );
    end;



    if SelectedPlayer.HasBall then begin
      // Skill Standard Comuni
      SelectedPlayer.ActiveSkills.Add('Short.Passing=' + IntTostr(SelectedPlayer.Passing));//; + SelectedPlayer.tal_longpass)  );
      SelectedPlayer.ActiveSkills.Add('Lofted.Pass=' + IntTostr(SelectedPlayer.Passing ));//+ SelectedPlayer.tal_longpass  ));
      // Se nella metà campo avversaria e in shotCell aggiungo gli Shot

      if SelectedPlayer.InShotCell then begin
        SelectedPlayer.ActiveSkills.Add('Precision.Shot=' + IntTostr( SelectedPlayer.shot   ));
        SelectedPlayer.ActiveSkills.Add('Power.Shot=' + IntTostr( SelectedPlayer.Shot  ));
      end;

      if (SelectedPlayer.Role <> 'G') and not (MyBrain.w_CornerKick) and not (MyBrain.w_FreeKick1) and not (MyBrain.w_FreeKick2) and not
       (MyBrain.w_FreeKick3) and not(MyBrain.w_FreeKick4)
       then SelectedPlayer.ActiveSkills.Add('Protection=2'); // ha la palla

      if (SelectedPlayer.Role <> 'G') and ( MyBrain.GetFriendInCrossingArea( SelectedPlayer ) ) then // ha la palla
              SelectedPlayer.ActiveSkills.Add('Crossing=' + IntTostr(SelectedPlayer.Passing + SelectedPlayer.Tal_crossing  ));

      if SelectedPlayer.canDribbling then begin
        if (SelectedPlayer.Role <> 'G') then begin
          aList := TObjectList<TSoccerPlayer>.Create (false);
          MyBrain.GetNeighbournsOpponent (SelectedPlayer.cellX, SelectedPlayer.CellY, SelectedPlayer.Team, aList  );
          if aList.Count > 0 then SelectedPlayer.ActiveSkills.Add('Dribbling=' + IntTostr(SelectedPlayer.BallControl  + SelectedPlayer.Tal_Dribbling   ));
          // ha la palla e ci sono avversari a distanza 1 da potere dribblare
          aList.Free;
        end;
      end;
    end

    // se non ha la palla
    else if Not(SelectedPlayer.HasBall) then begin
        // se la palla è a distanza 1 e appartiene a un player avversario
      if  AbsDistance (Mybrain.Ball.CellX  ,Mybrain.Ball.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
        if Mybrain.Ball.Player <> nil then begin
          if( AbsDistance ( SelectedPlayer.CellX, SelectedPlayer.CellY , Mybrain.Ball.CellX , Mybrain.Ball.CellY ) = 1) and
            (Mybrain.Ball.Player.Team <> SelectedPlayer.Team) and( Mybrain.Ball.Player.Role <> 'G')
          then begin
            if (SelectedPlayer.Role <> 'G') and ( not SelectedPlayer.PressingDone) then SelectedPlayer.ActiveSkills.Add('Tackle=' + IntTostr(SelectedPlayer.Defense  + SelectedPlayer.Tal_Toughness    ));;
            if (SelectedPlayer.Role <> 'G') and ( not SelectedPlayer.PressingDone) then SelectedPlayer.ActiveSkills.Add('Pressing=-2');
          end;
        end;
      end;


    end;

    if  MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 then
      goto LoadButtonBar;

PreLoadButtonBar:
    SelectedPlayer.ActiveSkills.Add('Pass=0');
    if (SelectedPlayer.Role <> 'G') then begin
      if SelectedPlayer.stay then SelectedPlayer.ActiveSkills.Add('Free=0')
      else SelectedPlayer.ActiveSkills.Add('Stay=0');
    end;
LoadButtonBar:
    if SelectedPlayer.ActiveSkills.count = 0 then Exit;
    se_gridskill.Clear;
    se_gridskill.RowCount := SelectedPlayer.ActiveSkills.count;
    se_gridskill.ColWidths [0]:=0;
    se_gridskill.ColWidths [1]:=120;
    se_gridskill.ColWidths [2]:=16;
    for I := 0 to SelectedPlayer.ActiveSkills.count -1 do begin
      se_gridskill.Cells[0,i]:= SelectedPlayer.ActiveSkills.Names [i]; // da usare in caso di traduzione della col 1
      se_gridskill.Cells[1,i]:= Translate( 'skill_' + SelectedPlayer.ActiveSkills.Names [i]); // tradotta
      if SelectedPlayer.ActiveSkills.ValueFromIndex [i] <> '0' then se_gridskill.Cells[2,i]:= SelectedPlayer.ActiveSkills.ValueFromIndex [i];
      if (se_gridskill.Cells[0,i]='Stay') or  (se_gridskill.Cells[0,i]='Free') then begin
        se_gridskill.Colors[1,i] := clSilver;
        se_gridskill.Colors[2,i] := clSilver;
        se_gridskill.FontColors[1,i] := clBlack;
        se_gridskill.FontColors[2,i] := clBlack;
      end;
    end;

    PanelSkillDynamicResizeSE;
    PanelSkillSE.Visible := True;
//    visX := se_Theater1.XVirtualToVisible(SelectedPlayer.SE_Sprite.Position.X) - (PanelSkillSE.Width div 2) + se_theater1.Left ;
//    visY := se_Theater1.YVirtualToVisible(SelectedPlayer.SE_Sprite.Position.Y + SelectedPlayer.SE_Sprite.BMP.Height div 2 )+10 +se_theater1.Top  ;
//    PanelSkillSE.Left := visX;
//    PanelSkillSE.Top := visY ;
    PanelSkillSE.BringToFront ;

end;

procedure TForm1.PanelSkillDynamicResizeSE;
begin

  se_gridskill.Height := se_gridskill.RowCount * se_gridskill.DefaultRowHeight;
  panelskillSE.Height :=  se_gridskill.Height + 16;

end;
procedure TForm1.SE_Theater1TheaterMouseMove(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Shift: TShiftState);
begin
//    caption := IntToStr(VirtualX) + '  ' +  IntToStr(VirtualY);
    panelsell.Visible := false;

    if (se_dragGuid <> nil) then begin


      // alla fine è outside lo metto nelle riserve
  {      if (se_dragGuid.Position.X < 0 ) or (se_dragGuid.Position.X > se_Theater1.Width )
        or (se_dragGuid.Position.Y < 0) or (se_dragGuid.Position.Y > se_Theater1.Height  )
        then begin
          MoveInReserves(aPlayer);
          DragGuid := nil;
          DrawPoly:= False;
        end
        else begin  }
          se_dragGuid.MoverData.Destination := Point(VirtualX,VirtualY);
          se_dragGuid.Position := Point (VirtualX,VirtualY);
    //    end;
    end;
end;

function TForm1.findlstSkill (SkillName: string ): integer;
var
  i: Integer;
begin
  for I := Low(LstSkill) to High(LstSkill) do begin
    if lstSkill[i]=SkillName then begin
      Result := i;
      Exit;
      end;
    end;
end;
procedure TForm1.LoadAdvTeam ( team : integer; Stat:string; clearMark: boolean );
var
  i,Y: integer;
begin
    if ClearMark then advTeam.ClearAll ;

    PanelSkillSE.Visible := False;

    advTeam.ColWidths [0]:=0;
    advTeam.ColWidths [1]:=50;
    advTeam.ColWidths [2]:=120;
    advTeam.ColWidths [3]:=80;
    AdvTeam.Height := (AdvTeam.RowCount * AdvTeam.DefaultRowHeight  ) + 4 ;


    AdvTeam.FontColors [1,0] := clWhite;
    AdvTeam.FontColors [2,0] := clWhite;
    AdvTeam.FontColors [3,0] := clWhite;
    AdvTeam.Colors [1,0]:= clblack;
    AdvTeam.Colors [2,0]:= clblack;
    AdvTeam.Colors [3,0]:= clblack;

    for I := 1 to advTeam.Rowcount -1 do begin
      AdvTeam.FontColors [1,i] := clWhite;
      AdvTeam.FontColors [2,i] := clWhite;
      AdvTeam.FontColors [3,i] := clWhite;

      AdvTeam.Alignments [1,i] := taCenter;
      AdvTeam.Alignments  [3,i] := taCenter;
    end;

  advTeam.Cells [1,0] := Translate ( 'lbl_Role');
  advTeam.Cells [2,0] := Translate ( 'lbl_Surname');
  Application.ProcessMessages ;

   advTeam.Cells [3,0] := stat; //Translate (Stat);


      Y := 1;
      for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
        if MyBrain.lstSoccerPlayer[i].Team = Team then begin
          if  MyBrain.lstSoccerPlayer[i].Gameover then Continue; // espulsi  o sostituiti

          if MyBrain.lstSoccerPlayer[i].Role = 'G' then begin
            advTeam.FontColors [1, Y] := clSilver;
            advTeam.FontColors [2, Y] := clSilver;
            advTeam.FontColors [3, Y] := clSilver;
          end;

            AdvTeam.Cells [0, Y]  := MyBrain.lstSoccerPlayer[i].Ids ;
            advTeam.Cells [1, Y] := MyBrain.lstSoccerPlayer[i].Role;
            advTeam.Cells [2, Y] := MyBrain.lstSoccerPlayer[i].Surname;


            if (Stat = 'Crossing') or (Stat = 'Passing')  then
              advTeam.Cells [3,Y] := IntTostr (MyBrain.lstSoccerPlayer[i].defaultPassing + MyBrain.lstSoccerPlayer[i].Tal_Crossing)
            else if Stat = 'Heading' then
              advTeam.Cells [3,Y] := IntTostr(MyBrain.lstSoccerPlayer[i].defaultheading)
            else if Stat = 'Shot' then
              advTeam.Cells [3,Y] := IntTostr(MyBrain.lstSoccerPlayer[i].DefaultShot )
            else if Stat = 'Defense' then
              advTeam.Cells [3,Y] := IntTostr(MyBrain.lstSoccerPlayer[i].defaultDefense);

            application.ProcessMessages ;
            inc (Y);
        end;
      end;

  PanelCorner.Height := Advteam.Height + 8;
  PanelCorner.Visible := True;
end;
function TForm1.GetDominantColor ( Team: integer  ): TColor;
begin
  if Team = 0 then result := clred
    else Result := $FE0001;

end;
function TForm1.GetContrastColor( cl: TColor  ): TColor;
var
  a: double;
  d: Integer;
  aTrgb: DSE_defs.TRGB;
begin
    aTrgb := TColor2TRGB(cl);
    // Counting the perceptive luminance - human eye favors green color...
    a := 1 - ( 0.299 * aTrgb.R + 0.587 * aTrgb.G + 0.114 * aTrgb.B)/255;

    if (a < 0.5) then
       d := 0 // bright colors - black font
    else
       d  := 254; // dark colors - white font  non 355 clwhite usato per bsclear
    aTrgb.r := d;
    aTrgb.g := d;
    aTrgb.b := d;
    Result := TRGB2TColor(aTrgb);
end;

procedure TForm1.SE_Theater1BeforeVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
begin
{  if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin

    VirtualBitmap.Bitmap.Canvas.Pen.Color := clYellow - RndGenerate(100) ;
    VirtualBitmap.Bitmap.Canvas.MoveTo(  0 ,0 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  VirtualBitmap.Width -1 , 0 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  VirtualBitmap.Width -1, VirtualBitmap.height -1 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  0, VirtualBitmap.height -1 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  0, 0 );

    VirtualBitmap.Bitmap.Canvas.Pen.Color := clYellow - RndGenerate(100) ;
    VirtualBitmap.Bitmap.Canvas.MoveTo(  1 ,1 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  VirtualBitmap.Width -1 , 1 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  VirtualBitmap.Width -1, VirtualBitmap.height -2 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  1, VirtualBitmap.height -2 );
    VirtualBitmap.Bitmap.Canvas.LineTo(  1, 1 );
  end;    }

end;

procedure TForm1.SE_Theater1SpriteMouseDown(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;
  Shift: TShiftState);
var
  i: integer;
  aPlayer: TSoccerPlayer;
  FriendlyWall,OpponentWall,FinalWall: boolean;
  MoveValue: Integer;
  MyParam: TSoccerParam;
  aHeadingFriend,aFriend: TSoccerPlayer;
  aPoint: TPoint;
  CellX,CellY: integer;
  aPath: dse_pathPlanner.Tpath;
  Highlight: SE_SubSprite;
  aSeField: SE_Sprite;

begin
  if (animating) or (not se_Theater1.Active)  then Exit;

  if GameScreen = ScreenFormation then begin

    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

        aPlayer := findPlayerMyBrainFormation (lstSprite[i].guid);
     //  if (Button = mbLeft) and (SE_DragGuid = nil) then begin
//          lstSprite[i].ChangeBitmap( dir_player + 'face.bmp',1,1,1000 );
 //       end
        if Button = mbLeft then begin
          if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0) then begin
            se_dragGuid := lstSprite[i];
            HighLightFieldFriendly ( aPlayer, 't' ); // team e talent goalkeeper  , illumina celle di formazione libere o occupate
            if MyBrain.isReserveSlot(aPlayer.CellX , aPlayer.CellX ) then
              MyBrain.ReserveSlot[0,aPlayer.CellX,aPlayer.celly]:='';
            Exit;
          end
          else SE_DragGuid := nil;
        end;
      end;
    end;


  end

  else if GameScreen = ScreenTactics then begin

    if Button = MbRight then begin
      SE_DragGuid := nil;
      HighLightFieldFriendly_hide;
      GameScreen := ScreenTactics ;
      Exit;
    end;
    SE_interface.RemoveAllSprites;


      for I := 0 to lstSprite.Count -1 do begin

        if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

            aPlayer := MyBrain.GetSoccerPlayer2 (lstSprite[i].guid); // trova tutti  comunque
            if aPlayer.GuidTeam  <> MyGuidTeam then Exit;   // sposto solo i miei

            if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0) and not (aPlayer.Gameover ) then begin
                SE_dragGuid := lstSprite[i];
                if not MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.CellY) then
                  HighLightFieldFriendly ( aPlayer, 'f' ); // team e talent goalkeeper  , illumina celle di formazione libere
                  Exit;
            end;
        end;
      end;

  end
  else if GameScreen = ScreenSubs then begin

    if Button = MbRight then begin
      SE_DragGuid := nil;
      HighLightFieldFriendly_hide;
      GameScreen := ScreenSubs ;
      Exit;
    end;
    SE_interface.RemoveAllSprites;
    // voglio fare una sostituzione
    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

          aPlayer := MyBrain.GetSoccerPlayer2 (lstSprite[i].guid); // trova tutti  comunque
          if aPlayer.GuidTeam  <> MyGuidTeam then Exit;   // sposto solo i miei   e solo quelli della panchina

          if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0) and not (aPlayer.Gameover )
              and (MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.CellY)) then begin
              SE_dragGuid := lstSprite[i];
              HighLightFieldFriendly ( aPlayer , 's' ); // team e talent goalkeeper a distanza < 4 , illumina celle di formazione occupate da compagni
              Exit;
    //          ReserveSlot[aPlayer.CellX,aPlayer.celly]:='';
          end;
       //   Exit;
      end;
    end;
  end

  else if GameScreen = ScreenLiveMatch then begin

    if Button = MbRight then begin

      SE_DragGuid := nil;
      HighLightFieldFriendly_hide;
      if PanelCorner.Visible then Exit;


      WaitForXY_Loftedpass := false;
      WaitForXY_Shortpass := false;
      WaitForXY_Move:= false;
      WaitForXY_Crossing := false;
      WaitForXY_Dribbling := false;
      WaitForXY_PrecisionShot:= false;
      WaitForXY_PowerShot:= false;
  //    hideinterface('sks');
      hidechances;
      PanelSkillSE.Visible := False;
      //AnimationScript.Reset ;
      //SpriteResetSE(true);
       Exit;
    end;

    if GCD > 0 then Exit;




      for I := 0 to lstSprite.Count -1 do begin


        if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites


          if (not WaitForXY_Shortpass) and (not WaitForXY_LoftedPass) and (not WaitForXY_Crossing)
          and  not (WaitForXY_Move) and not (WaitForXY_Dribbling) then begin //and not (WaitFor_Corner)
            // lo faccio qui perchè se gli engine cambiano priorità rimane corretto
            if DontDoPlayers then Exit;
            fSelectedPlayer := MyBrain.GetSoccerPlayer2 (lstSprite[i].guid); // trova tutti  comunque
            if SelectedPlayer.GuidTeam = MyGuidTeam then begin

              if not IsOutside ( SelectedPlayer.CellX, SelectedPlayer.CellY) then begin
                SelectedPlayerPopupSkillSE( SelectedPlayer.CellX, SelectedPlayer.CellY );
                Exit;
              end;
            end;
          end;
        end;

        // qui sopra SelectedPlayerPopupSkillSE compare solo se può comparire. se cìè un waitfor non agisce
        // se arriva qui ed è attivo un waitfor 'aspetto' che sia se_field per avere le coordinate. il player lo trovo via celle
      // un player si muove CON o SENZA palla

        if lstSprite[i].Engine = se_Field then begin
           aPoint:= FieldGuid2Cell (lstSprite[i].guid);
           CellX := aPoint.X;
           CellY := aPoint.Y;

          if WaitForXY_Move  then begin
            if  SelectedPlayer = nil then Exit;
            if  not SelectedPlayer.CanSkill  then Exit;
            if  not SelectedPlayer.CanMove then Exit;
            // trick, se non c'è il subsprite highlight non posso muovermi li'
            aSeField := SE_field.FindSprite( IntToStr(CellX) + '.' + IntToStr(CellY));
            highlight := aSeField.FindSubSprite(  'highlight' + IntToStr(CellX) + '.' + IntToStr(CellY));
            if highlight = nil then
              Exit;

            if  SelectedPlayer.HasBall then begin
              MoveValue := SelectedPlayer.Speed -1;
              if MoveValue <=0 then MoveValue:=1;

              FriendlyWall := true;
              OpponentWall := true;
              FinalWall := true;
              MyParam := withball;
            end
            else begin
              MoveValue := SelectedPlayer.Speed ;
              FriendlyWall := false;
              OpponentWall := false;
              FinalWall := true;
              MyParam := withoutball;
            end;
            if (SelectedPlayer.CellX = CellX) and (SelectedPlayer.CellY = CellY) then exit;
                MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, CellX, CellY,
                                      MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                                      OpponentWall{OpponentWall},FinalWall{FinalWall},TruncOneDir{OneDir}, SelectedPlayer.MovePath );

            if (SelectedPlayer.MovePath.Count > 0) then begin

              WaitForXY_Move:= false;
              DontDoPlayers := true;
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
                tcp.SendStr( 'PLM' + ',' + SelectedPlayer.Ids   + ',' +
                IntToStr(SelectedPlayer.MovePath[ SelectedPlayer.MovePath.Count -1].X ) +  ',' +
                IntToStr(SelectedPlayer.MovePath[ SelectedPlayer.MovePath.Count -1].Y ) + EndofLine );   // mando l'ultima cella del path
              GCD := GCD_DEFAULT;
              hidechances;
            end;
          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (WaitForXY_Shortpass) then begin

            if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) > (ShortPassRange +  SelectedPlayer.Tal_LongPass) then exit;


            aFriend := MyBrain.GetSoccerPlayer ( CellX, CellY );
            if aFriend <> nil then begin
              if aFriend.Team <> SelectedPlayer.Team  then begin
              // hack
              exit;
              end;
            end;

            aPath:= dse_pathPlanner.Tpath.Create ;
            GetLinePoints ( Mybrain.Ball.CellX ,Mybrain.Ball.CellY,  CellX, CellY , aPath );
            aPath.Steps.Delete(0); // elimino la cella di partenza

            if aPath.Count > 0 then begin
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'SHP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + EndofLine );
              GCD := GCD_DEFAULT;
              hidechances;
            end;

            WaitForXY_Shortpass := false;
            DontDoPlayers := true;
            aPath.Free;
          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (WaitForXY_Loftedpass)  then begin
            // controllo lato client. il server lo ripete
            if ( SelectedPlayer.Role <> 'G' ) and
            ( (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) >( LoftedPassRangeMax +  SelectedPlayer.Tal_LongPass))
             or (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  )   < LoftedPassRangeMin ) )
             then exit
             else begin // è un portiere
            if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) > ( 5))   // oltre sua metacampo
             or (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  )   <  LoftedPassRangeMin )
             then exit;
             end;

            if IsGKCell(Cellx,Celly) then Exit;

            aPlayer := MyBrain.GetSoccerPlayer(CellX,CellY);
            if aPlayer <> nil then begin
              if (aPlayer.Team <> SelectedPlayer.Team) or ( aPlayer = SelectedPlayer) then exit;
            end;
            if SelectedPlayer.Role <> 'G' then begin
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'LOP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + ',N' + EndofLine);
              GCD := GCD_DEFAULT;
              hidechances;
            end
            else begin
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'LOP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + ',GKLOP'+ EndofLine );
              GCD := GCD_DEFAULT;
              hidechances;
            end;

            WaitForXY_Loftedpass := false;
            DontDoPlayers := true;

          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (WaitForXY_Crossing)  then begin
            // controllo lato client. il server lo ripete
            if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) > (CrossingRangeMax+  SelectedPlayer.Tal_LongPass))
             or (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  )   < CrossingRangeMin )
             then exit;

            if not MyBrain.GetFriendInCrossingArea( SelectedPlayer ) then exit;
            aHeadingFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
            if aHeadingFriend = nil then exit;
            if aHeadingFriend.Team  <> SelectedPlayer.Team then exit;
            if not (aHeadingFriend.InCrossingArea) then exit;
            if (aHeadingFriend.Team <> SelectedPlayer.Team) or ( aHeadingFriend.ids = SelectedPlayer.ids) then exit;

            if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'CRO' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + EndofLine );
            GCD := GCD_DEFAULT;
            hidechances;

            WaitForXY_Crossing := false;
            DontDoPlayers := true;

          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (WaitForXY_Dribbling)  then begin
            // controllo lato client. il server lo ripete

            if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) = 1) and (SelectedPlayer.CanDribbling ) then begin

              aPlayer := MyBrain.GetSoccerPlayer(CellX,CellY);
              if aPlayer = nil then exit;
                if (aPlayer.Team = SelectedPlayer.Team) or ( aPlayer = SelectedPlayer) then exit;
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'DRI' + ','  + IntToStr(CellX) +  ',' + IntToStr(CellY ) + EndofLine );
              GCD := GCD_DEFAULT;
              hidechances;

              WaitForXY_Dribbling := false;
              DontDoPlayers := true;
            end;
          end;
        end;

    end;
  end;

end;
procedure TForm1.ck_HAClick(Sender: TObject);
var
  ha : Byte;
  UniformBitmap: SE_Bitmap;
begin
    if ck_HA.Buttons[0].Checked then
     ha := 0
     else ha :=1;

    UniformBitmap := SE_Bitmap.Create (dir_player + 'bw.bmp');
    PreLoadUniform( ha, UniformBitmap );  // usa tsuniforms e  UniformBitmapBW
    UniformBitmap.free;
    UniformPortrait.Bitmaps.Disabled.LoadFromFile(dir_tmp + 'color' + IntToStr(ha) +'.bmp');
  //  se_portrait1.Bitmaps.Disabled.LoadFromFile(dir_tmp + 'se_0b.bmp');

end;

procedure TForm1.ShowFace ( aSprite: SE_Sprite);
var
  aSubSprite: SE_SubSprite;
  i: integer;
  aPlayer: TSoccerPlayer;
begin
//  aSprite[i].ChangeBitmap( dir_player + 'face.bmp',1,1,1000 );

  aPlayer := MyBrain.GetSoccerPlayer2 (aSprite.guid); // trova tutti  comunque

  for I := 0 to se_Players.SpriteCount -1 do begin
    Se_Players.Sprites[i].RemoveAllSubSprites;
  end;
  aSubSprite := SE_SubSprite.create( dir_player + IntTostr(aPlayer.face) +'.bmp' , 'face', 0,0, true, true );
  aSubSprite.lBmp.Stretch (trunc (( aSubSprite.lBmp.Width * ScaleSprites ) / 100), trunc (( aSubSprite.lBmp.Height * ScaleSprites ) / 100)  );
  aSprite.AddSubSprite(aSubSprite);

  //aSprite.ChangeBitmap( dir_player + 'face.bmp',1,1,1000 );

end;

procedure TForm1.SE_Theater1SpriteMouseMove(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Shift: TShiftState);
var
  aPlayer,aFriend,anOpponent: TSoccerPlayer;
  SE_GridAttributes : SE_grid;
  btnxp,btnBmp : TRzBmpButton;
  portrait : TCnSpeedButton;
  lbls,lblt,lbldescrT: TRzLabel;
  i,x,y: Integer;

  CellX, CellY : Integer;
  aPoint: TPoint;
  anInteractivePlayer: TInteractivePlayer;
  ToEmptyCell: boolean;
  MoveValue: Integer;
  FriendlyWall, OpponentWall,FinalWall: Boolean;

begin
  if (not Se_Theater1.Active) then Exit;
  if SE_DragGuid <> nil then begin
    Exit;
  end;
  panelsell.Visible := false;

  for I := 0 to lstSprite.Count -1 do begin

    if lstSprite[i].Engine = se_players then begin

      if GameScreen = ScreenFormation  then begin
        aPlayer:= MyBrainFormation.GetSoccerPlayer2( lstSprite[i].guid );

        ShowFace ( lstSprite[i] );

        btnxp0.Visible := True;
        btnsell0.Visible := True;
        btnDismiss0.Visible := True;
        PanelDismiss.Visible := False;
        if aPlayer.OnMarket then begin
          btnsell0.Caption := Translate ('lbl_CancelSell');
          btnsell0.Tag := 1;
        end
        else begin
          btnsell0.Caption := Translate ('lbl_Sell');
          btnsell0.Tag := 0;                              // il tag per azione button
        end;

        aPlayer:= MyBrain.GetSoccerPlayer2( lstSprite[i].guid );
        if aPLayer <> nil then begin
          SE_GridXP0.SceneName:= aPlayer.Ids;;
          SetupGridXP ( SE_GridXP0, aPlayer  );
        end;

      end
      else begin  // no ScreenFormation
        btnDismiss0.Visible := false;
        btnXP0.Visible := false;
        btnSell0.Visible := false;


      end;

      aPlayer:= MyBrain.GetSoccerPlayer2( lstSprite[i].guid );
      if aPLayer <> nil  then begin

        case aPlayer.Team of
          0: begin
            SE_GridAttributes := SE_Grid0;
            lbls := se_lblSurname0;
            lblt:= lbl_Talent0;
            lbldescrT:= lbl_descrtalent0;
            btnBmp :=btnTalentBmp0;
            portrait := Portrait0;

          end;
          1: begin
            SE_GridAttributes := SE_Grid1;
            lbls := se_lblSurname1;
            lblt:= lbl_Talent1;
            lbldescrT:= lbl_descrtalent1;
            btnBmp :=btnTalentBmp1;
            portrait := Portrait1;
          end;
        end;


        if not (ssShift in Shift) then begin

          SE_GridAttributes.SceneName:= aPlayer.Ids;;
          SetupGridAttributes (SE_GridAttributes, aPlayer, 'a'  );  // attributi
        end
        else begin //  ssShift in Shift
          // come sopra ma mostro la history

          SetupGridAttributes (SE_GridAttributes, aPlayer, 'h'  ); // history

        end;

        portrait.Glyph.LoadFromFile(dir_player + IntTostr(aPlayer.face) + '.bmp');

          if CheckBox1.Checked then
            lblS.Caption := aPlayer.Ids + ' ' + aPlayer.SurName + ' (' + aPlayer.Role +')'
              else lbls.Caption := aPlayer.SurName + ' (' + aPlayer.Role +')' ;



           lblt.Caption :=  Capitalize  ( Translate( 'Talent_' + capitalize ( aPlayer.Talents) ));
           lbldescrT.Caption := Translate('descr_talent_' + aPlayer.Talents);
              //          lblR.Caption := '';
           if aPlayer.Talents <> '' then begin
               btnBmp.Bitmaps.Disabled.LoadFromFile( dir_talent + aPlayer.Talents + '.bmp' );
               btnBmp.Visible := True;
           end
           else btnBmp.Visible := False;


      end;
    end



      // qui sopra la parte infoplayer. da qui in poi le arrowdirection
      // non usare EXIt ma continue

    else if lstSprite[i].Engine = SE_field then  begin
      aPoint:= FieldGuid2Cell (lstSprite[i].guid);

     // if (aPoint.X = oldCellXMouseMove)  or (aPoint.Y = oldCellYMouseMove) then continue;

      CellX := aPoint.X;
      CellY := aPoint.Y;

//      advDice.Clear ;         // inizializza la advDice ogni volta che cambia di cella  ma solo se c'è un waitForXY
//      advDice.RowCount := 1;
      if GameScreen = ScreenLiveMatch then begin

        if WaitForXY_Shortpass then begin       // shp su friend o cella vuota
          advDice.Clear ;
          advDice.RowCount := 1;
          ToEmptyCell := true;
          SE_interface.removeallSprites;
          if (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) > (ShortPassRange +  MyBrain.Ball.Player.Tal_LongPass))
          or (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) = 0)
          then continue;
          aFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
          if aFriend <> nil then begin
            if (aFriend.Ids = MyBrain.Ball.Player.ids) or (aFriend.Team <> MyBrain.Ball.Player.Team ) then continue;
            ToEmptyCell := false;
          end;
          advDiceWriteRow( SelectedPlayer.Team, UpperCase(Translate('attribute_Passing')) , SelectedPlayer.SurName , SelectedPlayer.Ids ,'VS',IntToStr(SelectedPlayer.Passing) );
          ArrowShowShpIntercept ( CellX, CellY, ToEmptyCell) ;
        end
        else if WaitForXY_Move then begin       // di 2 o più mostro intercept autocontrasto
          advDice.Clear ;
          advDice.RowCount := 1;
          SE_interface.removeallSprites;  // rimuovo le frecce,  non rimuovo gli highlight
         // HighLightFieldFriendly_hide;

          if  SelectedPlayer.HasBall then begin
            MoveValue := SelectedPlayer.Speed -1;
            if MoveValue <=0 then MoveValue:=1;

            FriendlyWall := true;
            OpponentWall := true;
            FinalWall := true;
          end
          else begin
            MoveValue := SelectedPlayer.Speed ;
            FriendlyWall := false;
            OpponentWall := false;
            FinalWall := true;
          end;

          MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, CellX, CellY,
                                MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                                OpponentWall{OpponentWall},FinalWall{FinalWall},ExcludeNotOneDir{OneDir}, SelectedPlayer.MovePath );
          if SelectedPlayer.MovePath.Count > 0 then begin
            // ultimo del path, non cellx celly
            HighLightField (SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y, 0 );
            if  SelectedPlayer.HasBall then begin
              advDiceWriteRow( SelectedPlayer.Team, UpperCase(Translate('attribute_BallControl')) , SelectedPlayer.SurName , SelectedPlayer.Ids ,'VS',IntToStr(SelectedPlayer.BallControl)  );
              ArrowShowMoveAutoTackle  ( SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y) ;
              HighLightField (SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y, 0 );
            end;
          end;
        end
        else if WaitForXY_LoftedPass then begin  // mostro i colpi di testa difensivi o chi arriva sulla palla
          advDice.Clear ;
          advDice.RowCount := 1;
          ToEmptyCell := true;
          SE_interface.removeallSprites;
          if ( MyBrain.Ball.Player.Role <> 'G' ) and
          ( (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) >( LoftedPassRangeMax +  MyBrain.Ball.Player.Tal_LongPass))
           or (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  )   < LoftedPassRangeMin ) )
           then begin
             continue;
           end
           else begin // è un portiere
            if (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) > ( 5))   // oltre sua metacampo
             or (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  )   < LoftedPassRangeMin )
             then begin
               continue;
             end;
          end;
          aFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
          if aFriend <> nil then begin
            if (aFriend.Ids = MyBrain.Ball.Player.ids) or (aFriend.Team <> MyBrain.Ball.Player.Team ) then continue;
            ToEmptyCell := false;
          end;

          advDiceWriteRow( SelectedPlayer.Team, UpperCase(Translate('attribute_Passing')) , SelectedPlayer.SurName , SelectedPlayer.Ids ,'VS',IntToStr(SelectedPlayer.Passing) );
          ArrowShowLopHeading( CellX, CellY, ToEmptyCell) ;
          if aFriend <> nil then begin
            advDiceWriteRow( aFriend.Team, UpperCase(Translate('attribute_BallControl')) , aFriend.SurName , aFriend.Ids ,'VS', IntToStr(aFriend.BallControl) );
            if aFriend.InCrossingArea then
              advDiceWriteRow( aFriend.Team, '10: ' + UpperCase(Translate('skill_Volley')) , aFriend.SurName , aFriend.Ids ,'VS',IntToStr(aFriend.Shot) );
          end;
        end
        else if WaitForXY_Crossing then begin   // mostro i colpi di testa difensivi o chi arriva sulla palla
          advDice.Clear ;
          advDice.RowCount := 1;
          SE_interface.removeallSprites;
          if (absDistance ( MyBrain.ball.Player.CellX ,  MyBrain.ball.Player.CellY, CellX, CellY  ) > (CrossingRangeMax + MyBrain.ball.Player.tal_longpass ) )
            or (absDistance ( MyBrain.ball.Player.CellX ,  MyBrain.ball.Player.CellY, CellX, CellY  ) < CrossingRangeMin)  then begin
             continue;
          end;
          aFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
          if aFriend <> nil then begin
            if (aFriend.Ids = MyBrain.Ball.Player.ids) or (aFriend.Team <> MyBrain.Ball.Player.Team ) then continue;
            if aFriend.InCrossingArea then begin
              advDiceWriteRow( SelectedPlayer.Team, UpperCase(Translate('attribute_Passing')) , SelectedPlayer.SurName , SelectedPlayer.Ids ,'VS',IntToStr(SelectedPlayer.Passing) );
              ArrowShowCrossingHeading( CellX, CellY) ;
              advDiceWriteRow( aFriend.Team, UpperCase(Translate('attribute_Heading')) , aFriend.SurName , aFriend.Ids ,'VS',IntToStr(aFriend.heading) );
            end;
          end
          else continue;

        end
        else if WaitForXY_Dribbling then begin  // mostro freccia su opponent da dribblare
          advDice.Clear ;
          advDice.RowCount := 1;
          SE_interface.removeallSprites;
          anOpponent := MyBrain.GetSoccerPlayer(CellX,CellY);
          if anOpponent = nil then continue;
            if (anOpponent.Team = SelectedPlayer.Team)  or (anOpponent.Ids = SelectedPlayer.ids) or
            (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, CellX, CellY  ) > 1) then begin
             continue;
            end;

          ArrowShowDribbling( anOpponent, CellX, CellY);
  //          CalculateChance  (SelectedPlayer.BallControl + SelectedPlayer.tal_Dribbling -2, anOpponent.Defense , chanceA,chanceB,chanceColorA,chanceColorB);
        end
        else if WaitForXY_PowerShot then begin // mostro opponent, intercept, e portiere
          SE_interface.removeallSprites;
        end
        else if WaitForXY_PrecisionShot then begin // mostro opponent, intercept, e portiere
          SE_interface.removeallSprites;
        end
        else if WaitFor_Corner then begin   // mostro opponent, e frecce contrarie
          SE_interface.removeallSprites;
        end;
      end;
    end;
  end;
end;
procedure TForm1.advDiceWriteRow  ( team: integer; attr, Surname, ids, vs,num1: string);
var
  Row: Integer;
begin

  //advDiceAddRow trova la prima parte vuota e scrive li' . addrow è opzionale
  Row := advDiceNextBlank ( team ); // riporta comunque l'ultima se non trova prima un blank ( addrow precedenti aggiungono blank )
// es.  advDiceWriteRow  ( SelectedPlayer.Team, IntToStr(SelectedPlayer.Defense ) + ' ' + UpperCase(Translate('attribute_Defense')),
//        SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS');

  advDice.Colors [4, Row ] := advDice.Color ;
  advDice.FontColors [4, Row ] := clYellow;
  if vs <> 'FAULT' then advDice.Cells[ 4, Row] := vs;


  if team = 0 then begin

    if vs <> 'FAULT' then begin
      advDice.Colors [1, Row ] := MyBrain.Score.DominantColor[0];
      advDice.Colors [2, Row ] := MyBrain.Score.DominantColor[0];
      advDice.Colors [3, Row ] := MyBrain.Score.DominantColor[0];
      advDice.FontColors [1, Row ] := GetContrastColor( MyBrain.Score.DominantColor[0]);
      advDice.FontColors [2, Row ] := GetContrastColor( MyBrain.Score.DominantColor[0]);
      advDice.FontColors [3, Row ] := GetContrastColor( MyBrain.Score.DominantColor[0]);
    end
    else begin
      advDice.Colors [1, Row ] := clGray;
      advDice.Colors [2, Row ] := clGray;
      advDice.Colors [3, Row ] := clGray;
      advDice.FontColors [1, Row ] := clyellow;
      advDice.FontColors [2, Row ] := clyellow;
      advDice.FontColors [3, Row ] := clyellow;
    end;
    advDice.Cells[ 3, Row] := num1;
    advDice.Cells[ 2, Row] := UpperCase(attr);
    advDice.Cells[ 1, Row] := Surname;
    advDice.Cells[ 0, Row] := ids;
    advDice.AddRow ;

  end
  else begin
    if vs <> 'FAULT' then begin
      advDice.Colors [5, Row ] := MyBrain.Score.DominantColor[1];
      advDice.Colors [6, Row ] := MyBrain.Score.DominantColor[1];
      advDice.Colors [7, Row ] := MyBrain.Score.DominantColor[1];
      advDice.FontColors [5, Row ] := GetContrastColor( MyBrain.Score.DominantColor[1]);
      advDice.FontColors [6, Row ] := GetContrastColor( MyBrain.Score.DominantColor[1]);
      advDice.FontColors [7, Row ] := GetContrastColor( MyBrain.Score.DominantColor[1]);
    end
    else begin
      advDice.Colors [5, Row ] :=clGray;
      advDice.Colors [6, Row ] := clGray;
      advDice.Colors [7, Row ] := clGray;
      advDice.FontColors [5, Row ] := clyellow;
      advDice.FontColors [6, Row ] := clyellow;
      advDice.FontColors [7, Row ] := clyellow;
    end;

    advDice.Alignments [7, Row ] := taRightJustify;
    advDice.Cells[ 5, Row] := num1;
    advDice.Cells[ 6, Row] := UpperCase(attr);
    advDice.Cells[ 7, Row] := Surname;
    advDice.Cells[ 8, Row] := ids;
    advDice.AddRow ;

  end;
end;
procedure TForm1.advMarketClickCell(Sender: TObject; ARow, ACol: Integer);
begin
  if GCD <= 0 then begin

    if MyBrainFormation.lstSoccerPlayer.Count < 18 then begin
      WAITING_GETFORMATION:= True;
      tcp.SendStr( 'buy,'+ advMarket.Cells[0,ARow] + EndofLine)
    end
      else ShowError(Translate('warning_max18'));
    GCD := GCD_DEFAULT;
  end;

end;

function TForm1.advDiceNextBlank  ( team: integer): Integer;
var
  y: Integer;
begin
  Result := advDice.RowCount -1;
  Exit;

    for y := 0 to advDice.rowcount -1 do begin
      if team = 0 then begin

        if advDice.Cells[ 0, Y] = '' then begin    // ids
          result := Y;
        end;

      end
      else begin

        if advDice.Cells[ 8, Y] = '' then begin   // ids
          result := Y;
        end;

      end;

    end;
//
end;

function TForm1.FindInteractivePlayer ( aPlayer: TSoccerPlayer ): TInteractivePlayer;
begin
  //
end;
procedure TForm1.ArrowShowMoveAutoTackle ( CellX, CellY : Integer);
var
  i,au,MoveValue: Integer;
  aCellList: TList<TPoint>;
  label Myexit;
begin
   SE_interface.removeallSprites;
//  hidechances;
  MoveValue := SelectedPlayer.Speed -1;
  if MoveValue <=0 then MoveValue:=1;
  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, MoveValue,True,true , True,aCellList); // noplayer,noOutside
  // se mi muovo col mouse s una possibile cella - qui solo hasball=true -
  for I := 0 to aCellList.Count -1 do begin
    if (aCellList[i].X= CellX) and (aCellList[i].Y= CellY) then begin
      MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.CellY, CellX, CellY,
                              MoveValue{Limit},false{useFlank},true{FriendlyWall},
                              true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, SelectedPlayer.MovePath );

      // PLM Precompilo la lista di possibili autotackle perchè non si ripetano
      if SelectedPlayer.MovePath.count > 0 then begin// solo se si muove di 2 o più ? > 1  per il momento la regola è: non cella finale
        MyBrain.CompileAutoTackleList (SelectedPlayer.Team{avversari di}, 1{MaxDistance},  SelectedPlayer.MovePath, lstInteractivePlayers  );
      end;

      for au := 0 to lstInteractivePlayers.Count -1 do begin
        lstInteractivePlayers[au].Attribute := atDefense;
        CreateArrowDirection( lstInteractivePlayers[au].Player  , lstInteractivePlayers[au].Cell.X ,lstInteractivePlayers[au].Cell.Y );
        advDiceWriteRow  ( lstInteractivePlayers[au].Player.Team, UpperCase(Translate('attribute_Defense')),  lstInteractivePlayers[au].Player.SurName, lstInteractivePlayers[au].Player.Ids, 'VS',IntToStr(lstInteractivePlayers[au].Player.Defense));
      end;

      break; //goto MyExit;
    end;

  end;
Myexit:
  aCellList.Free;


end;
procedure TForm1.ArrowShowShpIntercept ( CellX, CellY : Integer; ToEmptyCell: boolean);
var
  aPath: dse_pathPlanner.Tpath;
  i,y: integer;
  anIntercept, anOpponent,aFriend: TSoccerPlayer;
  aInteractivePlayer: TInteractivePlayer;
  ToEmptyCellMalus: integer;
  LstMoving: TList<TInteractivePlayer>;

begin
  // calcola il percorso della palla in linea retta e ottiene un path di celle interessate
  aPath:= dse_pathPlanner.Tpath.Create;
  SoccerBrainv3.GetLinePoints ( MyBrain.Ball.CellX ,MyBrain.Ball.CellY,  CellX, CellY, aPath );
  aPath.Steps.Delete(0); // elimino la cella di partenza

    // SHP Precompilo la lista di possibili intercept perchè non si ripetano
  MyBrain.CompileInterceptList (  MyBrain.Ball.Player.Team{avversari di}, 1{MaxDistance}, aPath, lstInteractivePlayers  );

  for I := 0 to aPath.Count -1 do begin
       // cella per cella o trovo un opponente o trovo un intercept

      anOpponent:= MyBrain.GetSoccerPlayer ( aPath[i].X,aPath[i].Y);
      if anOpponent <> nil then begin
          if anOpponent.Team <> MyBrain.Ball.Player.Team then begin
            aInteractivePlayer:= TInteractivePlayer.Create;
            aInteractivePlayer.Player  :=  anOpponent;                    // aggiungo per il mousemove anche il difensore davanti alla palla
            aInteractivePlayer.Cell := Point ( aPath[i].X ,aPath[i].Y );
            aInteractivePlayer.Attribute := atDefense;
            lstInteractivePlayers.add (aInteractivePlayer);
            CreateArrowDirection( anOpponent, aPath[i].X,aPath[i].Y );
            advDiceWriteRow  ( anOpponent.Team, UpperCase(Translate('attribute_Defense')),  anOpponent.SurName, anOpponent.Ids, 'VS',IntToStr(anOpponent.Defense) );
          end;
      end

      else begin // no opponent ma possibile intercept su cella vuota

        for Y := 0 to lstInteractivePlayers.count -1 do begin
          anIntercept := lstInteractivePlayers[Y].Player;
          if ( lstInteractivePlayers[Y].Cell.X = aPath[i].X) and (lstInteractivePlayers[Y].Cell.Y = aPath[i].Y) then begin  // se questa cella
            lstInteractivePlayers[Y].Attribute := atDefense;  { TODO -cgameplay : intercept potrebbe usare atBallControl? }
            CreateArrowDirection( anIntercept, aPath[i].X,aPath[i].Y );
            aFriend := MyBrain.GetSoccerPlayer ( CellX , CellY);
            if aFriend = nil then
   { toemptycells lo devo riportare adesso }
             advDiceWriteRow  ( anIntercept.Team, UpperCase(Translate('attribute_Defense')),  anIntercept.SurName, anIntercept.Ids, 'VS',IntToStr(anIntercept.Defense))
            else advDiceWriteRow  ( anIntercept.Team, UpperCase(Translate('attribute_Defense')),  anIntercept.SurName, anIntercept.Ids, 'VS',
                                      IntToStr(anIntercept.Defense -1));
          end
        end;

      end
  end;

  // compilo la lista di compagni che possono raggiungere quella cella e mostro la loro speed. solo su cella vuota finale
  // solo nel caso non vi siano intercept
  if (ToEmptyCell)  and (lstInteractivePlayers.Count = 0) then begin
    LstMoving:= TList<TInteractivePlayer>.create;
    MyBrain.CompileMovingList (1{MaxDistance}, CellX, CellY, LstMoving  );
    for Y := 0 to LstMoving.count -1 do begin
      LstMoving[Y].Attribute := atSpeed;
      CreateArrowDirection( LstMoving[Y].Player, CellX,CellY );
      advDiceWriteRow  ( LstMoving[Y].Player.Team, UpperCase(Translate('attribute_Speed')),  LstMoving[Y].Player.SurName, LstMoving[Y].Player.Ids, 'VS',IntToStr(LstMoving[Y].Player.Speed ));
    end;

    LstMoving.Free;
  end;


  aPath.Free;
end;
procedure TForm1.ArrowShowLopheading(CellX, CellY : Integer; ToEmptyCell:
    boolean);
var
  y: integer;
  aheading: TSoccerPlayer;
  ToEmptyCellMalus: integer;
  LstMoving: TList<TInteractivePlayer>;

begin

  if not ToEmptyCell then begin
    // LOP su friend

    // LOP Precompilo la lista di possibili Heading perchè non si ripetano
    MyBrain.CompileHeadingList (SelectedPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, lstInteractivePlayers  );
    for Y := 0 to lstInteractivePlayers.count -1 do begin
         // cella per cella o trovo un opponent o trovo un intercept
      aHeading := lstInteractivePlayers[Y].Player;
      if ( lstInteractivePlayers[Y].Cell.X = CellX) and (lstInteractivePlayers[Y].Cell.Y = CellY) then begin  // se questa cella
            // CalculateChance  ( SelectedPlayer.Passing , aHeading.Heading  , chanceA,chanceB,chanceColorA,chanceColorB);
            lstInteractivePlayers[Y].Attribute := atHeading;
            CreateArrowDirection( aHeading, CellX,CellY );
            advDiceWriteRow  ( aHeading.Team, UpperCase(Translate('attribute_Heading')),  aHeading.SurName, aHeading.Ids, 'VS',IntToStr(aHeading.Passing));

      end;

    end;

  end

  else begin
    // LOP su cella vuota
  // compilo la lista di compagni che possono raggiungere quella cella e mostro la loro speed. solo su cella vuota finale
    LstMoving:= TList<TInteractivePlayer>.create;
    MyBrain.CompileMovingList (1{MaxDistance}, CellX, CellY, LstMoving  );
    for Y := 0 to LstMoving.count -1 do begin
      LstMoving[Y].Attribute := atSpeed;
      CreateArrowDirection( LstMoving[Y].Player, CellX,CellY );
      advDiceWriteRow  ( LstMoving[Y].Player.Team, UpperCase(Translate('attribute_Speed')),  LstMoving[Y].Player.SurName, LstMoving[Y].Player.Ids, 'VS',IntToStr(LstMoving[Y].Player.Speed));
    end;

    LstMoving.Free;
  end;

end;

procedure TForm1.ArrowShowCrossingHeading ( CellX, CellY : Integer);
var
  y,BonusDefenseHeading,BaseHeading: integer;
  aheading: TSoccerPlayer;
  aInteractivePlayer: TInteractivePlayer;
  ToEmptyCellMalus: integer;
  LstMoving: TList<TInteractivePlayer>;

begin
//          CreateTextChanceValue (SelectedPlayer.ids, SelectedPlayer.passing + SelectedPlayer.Tal_Crossing , dir_skill + 'Crossing',0,0,0,0);

  HighLightField (CellX ,CellY,0);


  BonusDefenseHeading := MyBrain.GetCrossDefenseBonus (SelectedPlayer, CellX, CellY );
  // CRO Precompilo la lista di possibili Heading perchè non si ripetano
  MyBrain.CompileHeadingList (SelectedPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, lstInteractivePlayers  );
  for Y := 0 to lstInteractivePlayers.count -1 do begin
    aHeading := lstInteractivePlayers[Y].Player;
       // cella per cella o trovo un opponent o trovo un intercept
    if ( lstInteractivePlayers[Y].Cell.X = CellX) and (lstInteractivePlayers[Y].Cell.Y = CellY) then begin  // se questa cella
     //     CalculateChance  ( aFriend.heading, aHeading.Heading + BonusDefenseHeading  , chanceA,chanceB,chanceColorA,chanceColorB);
     //     BaseHeading :=  LstHeading[Y].Player.Heading + BonusDefenseHeading;
     //     if Baseheading <= 0 then Baseheading :=1;
      CreateArrowDirection( lstInteractivePlayers[Y].Player, CellX,CellY );
      advDiceWriteRow  ( aHeading.Team, UpperCase(Translate('attribute_Heading')),  aHeading.SurName, aHeading.Ids, 'VS',
                         IntToStr(aHeading.heading + BonusDefenseHeading ));
     //     CreateTextChanceValue ( LstHeading[Y].Player.ids, BaseHeading  ,dir_attributes +  'Heading',0,0,0,0);

    end;

  end;

end;
procedure TForm1.ArrowShowDribbling ( anOpponent: TSoccerPlayer; CellX, CellY : Integer);
var
  anInteractivePlayer : TInteractivePlayer;
begin

  anInteractivePlayer := TInteractivePlayer.Create ;
  anInteractivePlayer.Player := anOpponent;
  anInteractivePlayer.Cell.X := cellX;
  anInteractivePlayer.Cell.Y := cellY;
  anInteractivePlayer.Attribute := atDefense;
  CreateArrowDirection(  MyBrain.ball.Player, CellX,CellY );
  advDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_BallControl')),  SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',
                      IntToStr(SelectedPlayer.BallControl + SelectedPlayer.Tal_Dribbling ) );
  advDiceWriteRow  ( anOpponent.Team, UpperCase(Translate('attribute_Defense')),  anOpponent.SurName, anOpponent.Ids, 'VS',
                      IntToStr(anOpponent.Defense ));

end;
function Tform1.FieldGuid2Cell (guid:string): Tpoint;
var
  x: Integer;
begin
  x:= Pos( '.',guid,1);
  result.X :=  StrToInt( LeftStr(guid, x -1 )  );
  result.Y :=  StrToInt( RightStr(guid, Length(guid) - x   )  );

end;
procedure TForm1.SE_Theater1SpriteMouseUp(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;  Shift: TShiftState);
var
  aPlayer,aPlayer2: TSoccerPlayer;
  i, CellX, CellY: integer;
  aSeField: SE_Sprite;
  AICell, Acell,aPoint: TPoint;
  label reserve;
  label exitScreenSubs;
begin
  if Se_DragGuid = nil then Exit;

  for I := 0 to lstSprite.Count -1 do begin
    if lstSprite[i].Engine = se_field then begin
      aSEField := SE_field.FindSprite(lstSprite[i].guid );
      Acell := FieldGuid2Cell ( lstSprite[i].guid);
      CellX := Acell.X;
      Celly := acell.Y;
      Break;
    end;
  end;

  if GameScreen = ScreenFormation then begin


    aPlayer := findPlayerMyBrainFormation (Se_DragGuid.Guid);
    if (aPlayer.disqualified > 0) or (aPlayer.Injured > 0) then goto reserve;


        if not IsOutSide ( CellX, CellY) then begin

          if (CellX = 0) or (CellX = 2)  or  (CellX = 5) or (CellX = 8) then begin // uso TvCell

            if (isGKcell ( CellX, CellY ) ) and (aPlayer.Talents <> 'goalkeeper') then goto reserve;    // un goalkeeper può essere schierato solo in porta
            if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.Talents = 'goalkeeper') then goto reserve;    // un goalkeeper può essere schierato solo in porta

             //MoveInDefaultField(aPlayer);
             // se c'è un player in quella polyCell lo sposto nelle riserve
            for i := 0 to MyBrainFormation.lstSoccerPlayer.count -1 do begin
              aPlayer2 := MyBrainFormation.lstSoccerPlayer[i];
              AICell:=  MyBrainFormation.Tv2AiField ( 0, CellX, CellY );  // 0 è il mio team, sposto solo i miei
              if (aPlayer2.AIFormationCellX  = AICell.X) and (aPlayer2.AIFormationCellY  = AICell.Y) and ( aPlayer2.ids <> se_DragGuid.guid ) then begin  // un player nel .ini a cellX,celly  lo metto nelle riserver
                MyBrainFormation.PutInReserveSlot( aPlayer2 );
                RefreshCheckFormationMemory;
                MoveInReserves(aPlayer2);
              end;
            end;

             // e dopo storo il nuovo player
             Updateformation ( se_DragGuid.guid, 0, CellX, CellY); // passo delle TvCell che converte in Aicells che sotra nel db tramite MyBrainFormation
            // aPlayer.DefaultCells := Point(CellX ,CellY);// deafultcells la uso in memoria, non ha valore di dato da storare
             SE_DragGuid.MoverData.Destination := aSeField.Position;
             SE_DragGuid.Position := aSeField.Position;


            se_DragGuid := nil;
            HighLightFieldFriendly_hide ;
          end
          else begin
    reserve:
              MyBrainFormation.PutInReserveSlot( aPlayer );
              RefreshCheckFormationMemory;
              MoveInReserves(aPlayer);
              se_DragGuid := nil;
            HighLightFieldFriendly_hide ;

          end;
        end
        else if IsOutSide ( CellX, CellY) then begin // lo metto nelle riserve
              MyBrainFormation.PutInReserveSlot( aPlayer );
              RefreshCheckFormationMemory;
              MoveInReserves(aPlayer);
              se_DragGuid := nil;
            HighLightFieldFriendly_hide ;
        end;

  end
  else if GameScreen = ScreenTactics then begin

    if GCD > 0 then Exit;

    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_field then begin   // sposto solo players , non altri sprites

        //cellX e CellY devono essere in campo, mai fuori
        if IsOutSide( CellX, CellY) then Exit;
        if SE_DragGuid = nil then Exit;



        // il mouseup è solo in campo, mai click fuori dal campo
        aPlayer := MyBrain.GetSoccerPlayer2 (SE_DragGuid.Guid); // mouseup su qualsiasi cella
        if MyBrain.Score.TeamSubs [ aPlayer.team ] >= 3 then Exit;
        aPlayer2 := MyBrain.GetSoccerPlayerDefault (CellX, CellY); // mouseup su qualsiasi cella

        if ((CellX = 0) or (CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team <> 0) then
          Exit;
        if ((CellX = 11) or (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team <> 1) then
          Exit;

        if aPlayer2 = nil then begin
          // se_dragguid deve essere uno già in campo
          if MyBrain.isReserveSlot ( aPlayer.CellX , aPlayer.CellY ) then Exit;   //

          // gk solo nel posto del gk
          if (isGKcell ( CellX, CellY ) ) and (aPlayer.Talents <> 'goalkeeper') then exit;    // un goalkeeper può essere schierato solo in porta
          if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.Talents = 'goalkeeper') then exit;    // un goalkeeper può essere schierato solo in porta
          SE_DragGuid := nil;
          tcp.SendStr( 'TACTIC,' + aPlayer.ids + ',' + IntToStr(CellX) + ',' + IntToStr(CellY) + EndOfLine );// il server risponde con clientLoadbrain
          HighLightFieldFriendly_hide;
          Exit;
  //        aPlayer.DefaultCellS  := point (CellX,CellY);
  //        MoveInDefaultField(aPlayer);
  //        aPlayer.DefaultCellS  := point (CellX,CellY);
  //        MoveInDefaultField(aPlayer);
  //        aPlayer2.Cells := MyBrain.NextReserveSlot(aPlayer2);
  //        MoveInReserves(aPlayer2);
        end;


      end;

            // MBRIGHT market
  //         aPlayer := MyBrain.GetSoccerPlayer(CellX, CellY);
  //        if aPlayer = nil then Exit;

  //        edtBid.Min := aPlayer.MarketValue;
  //        edtBid.Value := aPlayer.MarketValue;
  //        lblConfirmBid.Caption := Translate('Confirm offer' ) +': ' + APlayer.SurName +', ' + Translate('Age') +': ' +
  //        IntToStr(aPlayer.age) + ', ' + Translate('Value' ) + ': ' + IntToStr(aPlayer.MarketValue) + ' ' +  Translate('Gold' );



    end;
  end
  else if GameScreen = ScreenSubs then begin
    if GCD > 0 then Exit;

    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_field then begin   // sposto solo players , non altri sprites

        aPlayer := MyBrain.GetSoccerPlayer2 (SE_DragGuid.Guid); // mouseup su qualsiasi cella
        if MyBrain.Score.TeamSubs [ aPlayer.team ] >= 3 then goto exitScreenSubs;
        //cellX e CellY devono essere in campo, mai fuori
        if IsOutSide( CellX, CellY) then goto exitScreenSubs;
        if SE_DragGuid = nil then goto exitScreenSubs;


        // il mouseup è solo in campo, mai click fuori dal campo
        aPlayer2 := MyBrain.GetSoccerPlayer (CellX, CellY); // mouseup su qualsiasi cella
        if aPlayer2 <> nil then begin
          // se_dragguid deve essere uno che proviene dalla panchina
          // gk solo nel posto del gk
          if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
          or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then goto exitScreenSubs;
          if aPlayer.Ids = aPlayer2.Ids then goto exitScreenSubs;
          if (isGKcell ( CellX, CellY ) ) and (aPlayer.Talents <> 'goalkeeper') then goto exitScreenSubs;;    // un goalkeeper può essere schierato solo in porta
          if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.Talents = 'goalkeeper') then goto exitScreenSubs;;    // un goalkeeper può essere schierato solo in porta
          if aPlayer.Team <>  MyBrain.TeamTurn  then goto exitScreenSubs;;  // sposto solo i miei
          if aPlayer.gameover then goto exitScreenSubs;;  // non espulsi o già sostitutiti
          if aPlayer.disqualified > 0 then goto exitScreenSubs;;  // non squalificati
          if not MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.cellY) then goto exitScreenSubs;; // solo uno dalla panchina su una cella già occupata
          if AbsDistance(aPlayer2.CellX, aPlayer2.CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) < 4 then goto exitScreenSubs;;
//          if ((CellX = 0) or (CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team <> 0) then
//            goto exitScreenSubs;;
//          if ((CellX = 11) or (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team <> 1) then
//            goto exitScreenSubs;;

          SE_DragGuid := nil;
          HighLightFieldFriendly_hide;
          tcp.SendStr( 'SUB,' + aPlayer.ids + ',' + aPlayer2.ids + EndOfLine );// il server risponde con clientLoadbrain
          Exit;
        end
        else begin // aplayer2 ! non esiste, metto via tutto
exitScreenSubs:
          SE_DragGuid := nil;
          HighLightFieldFriendly_hide;
          MoveInReserves(aPlayer);
          Exit;
        end;
      end;
    end;

  end;

end;
procedure TForm1.SetupGridXP (GridXP: SE_grid; aPlayer: TsoccerPlayer);
var
  i,y: Integer;
  ts :TStringList;
  a,b: integer;
begin
  GridXp.ClearData;   // importante anche pr memoryleak
  GridXp.DefaultColWidth := 16;
  GridXp.DefaultRowHeight := 16;
  GridXp.ColCount :=3;
  GridXp.RowCount :=24;
  GridXp.Columns[0].Width := 120;
  GridXp.Columns[1].Width := 60;
  GridXp.Columns[2].Width := 40;
  GridXp.Width := GridXp.VirtualWidth;


  for y := 0 to gridXP.RowCount -1 do begin
    GridXp.Rows[y].Height := 16;
    gridXP.Cells[0,y].FontName := 'Verdana';
    gridXP.Cells[0,y].FontSize := 8;
    gridXP.Cells[0,y].FontColor := clWhite;
    gridXP.Cells[1,y].FontColor  := clWhite;
    gridXP.Cells[1,y].CellAlignmentH := hRight;
    gridXP.AddProgressBar(1,y, 0 ,$00804000,pbstandard);
  end;
  GridXP.Cells[0,0].Text :=  Translate('attribute_Speed');
  GridXP.Cells[0,1].Text :=  Translate('attribute_Defense');
  GridXP.Cells[0,2].Text :=  Translate('attribute_Passing');
  GridXP.Cells[0,3].Text :=  Translate('attribute_BallControl');
  GridXP.Cells[0,4].Text :=  Translate('attribute_Shot');
  GridXP.Cells[0,5].Text :=  Translate('attribute_Heading');

  GridXP.Cells[0,6].Text :=  '';

  if aPlayer.DefaultSpeed < 6 then begin
    GridXP.Cells[1,0].Text  := IntToStr(aPlayer.xp_Speed) + '/120' ;
    GridXP.Cells[1,0].ProgressBarValue :=  (aPlayer.xp_Speed * 100) div 120;
  end;
  if aPlayer.DefaultDefense < 6 then begin
    GridXP.Cells[1,1].Text  := IntToStr(aPlayer.xp_Defense) + '/120' ;
    GridXP.Cells[1,1].ProgressBarValue :=  (aPlayer.xp_Defense * 100) div 120;
  end;
  if aPlayer.DefaultPassing < 6 then begin
    GridXP.Cells[1,2].Text  := IntToStr(aPlayer.xp_Passing) + '/120' ;
    GridXP.Cells[1,2].ProgressBarValue :=  (aPlayer.xp_Passing * 100) div 120;
  end;
  if aPlayer.DefaultBallControl < 6 then begin
    GridXP.Cells[1,3].Text  := IntToStr(aPlayer.xp_BallControl) + '/120' ;
    GridXP.Cells[1,3].ProgressBarValue :=  (aPlayer.xp_BallControl * 100) div 120;
  end;
  if aPlayer.DefaultShot < 6 then begin
    GridXP.Cells[1,4].Text  := IntToStr(aPlayer.xp_Shot) + '/120' ;
    GridXP.Cells[1,4].ProgressBarValue :=  (aPlayer.xp_Shot * 100) div 120;
  end;
  if aPlayer.DefaultHeading < 6 then begin
    GridXP.Cells[1,5].Text  := IntToStr(aPlayer.xp_Heading) + '/120' ;
    GridXP.Cells[1,5].ProgressBarValue :=  (aPlayer.xp_Heading * 100) div 120;
  end;

  GridXP.Cells[1,6].Text  := '';

  // rispetto l'esatto ordine dei talenti sul DB
  if aPlayer.TalentId = 0 then begin

    GridXP.Cells[0,7].Text := Translate('talent_Goalkeeper');
    GridXP.Cells[0,8].Text :=  Translate('talent_Challenge');
    GridXP.Cells[0,9].Text :=  Translate('talent_Toughness');
    GridXP.Cells[0,10].Text := Translate('talent_Power');
    GridXP.Cells[0,11].Text := Translate('talent_Crossing');
    GridXP.Cells[0,12].Text := Translate('talent_LongPass');
    GridXP.Cells[0,13].Text := Translate('talent_Experience');
    GridXP.Cells[0,14].Text := Translate('talent_Dribbling');
    GridXP.Cells[0,15].Text := Translate('talent_Bulldog');
    GridXP.Cells[0,16].Text := Translate('talent_Offensive');
    GridXP.Cells[0,17].Text := Translate('talent_Defensive');
    GridXP.Cells[0,18].Text := Translate('talent_Bomb');
    GridXP.Cells[0,19].Text := Translate('talent_Playmaker');
    GridXP.Cells[0,20].Text := Translate('talent_Faul');
    GridXP.Cells[0,21].Text := Translate('talent_Marking');
    GridXP.Cells[0,22].Text := Translate('talent_Positioning');
    GridXP.Cells[0,23].Text := Translate('talent_FreeKicks');


    GridXP.Cells[1,7].Text  := IntToStr(aPlayer.xpTal_GoalKeeper) + '/120' ;
    GridXP.Cells[1,7].ProgressBarValue :=  (aPlayer.xpTal_GoalKeeper * 100) div 120;
    GridXP.Cells[1,8].Text  := IntToStr(aPlayer.xpTal_Challenge) + '/120';  // lottatore
    GridXP.Cells[1,8].ProgressBarValue :=  (aPlayer.xpTal_Challenge * 100) div 120;
    GridXP.Cells[1,9].Text  := IntToStr(aPlayer.xpTal_Toughness) + '/120';
    GridXP.Cells[1,9].ProgressBarValue :=  (aPlayer.xpTal_Toughness * 100) div 120;
    GridXP.Cells[1,10].Text  := IntToStr(aPlayer.xpTal_Power ) + '/120';   // toughness
    GridXP.Cells[1,10].ProgressBarValue :=  (aPlayer.xpTal_Power * 100) div 120;
    GridXP.Cells[1,11].Text  := IntToStr(aPlayer.xpTal_Crossing ) + '/120';
    GridXP.Cells[1,11].ProgressBarValue :=  (aPlayer.xpTal_Crossing * 100) div 120;
    GridXP.Cells[1,12].Text  := IntToStr(aPlayer.xptal_longpass) + '/120';  // solo distanza
    GridXP.Cells[1,12].ProgressBarValue :=  (aPlayer.xptal_longpass * 100) div 120;
    GridXP.Cells[1,13].Text  := IntToStr(aPlayer.xpTal_Experience) + '/120';
    GridXP.Cells[1,13].ProgressBarValue :=  (aPlayer.xpTal_Experience * 100) div 120;
    GridXP.Cells[1,14].Text  := IntToStr(aPlayer.xpTal_Dribbling) + '/120';
    GridXP.Cells[1,14].ProgressBarValue :=  (aPlayer.xpTal_Dribbling * 100) div 120;
    GridXP.Cells[1,15].Text  := IntToStr(aPlayer.xpTal_Bulldog) + '/120'; // mastino +1 anticipo
    GridXP.Cells[1,15].ProgressBarValue :=  (aPlayer.xpTal_Bulldog * 100) div 120;
    GridXP.Cells[1,16].Text  := IntToStr(aPlayer.xpTal_midOffensive) + '/120';
    GridXP.Cells[1,16].ProgressBarValue :=  (aPlayer.xpTal_midOffensive * 100) div 120;
    GridXP.Cells[1,17].Text  := IntToStr(aPlayer.xpTal_midDefensive) + '/120';
    GridXP.Cells[1,17].ProgressBarValue :=  (aPlayer.xpTal_midDefensive * 100) div 120;
    GridXP.Cells[1,18].Text  := IntToStr(aPlayer.xpTal_Bomb) + '/120';
    GridXP.Cells[1,18].ProgressBarValue :=  (aPlayer.xpTal_Bomb * 100) div 120;
    GridXP.Cells[1,19].Text  := IntToStr(aPlayer.xpTal_PlayMaker) + '/120';
    GridXP.Cells[1,19].ProgressBarValue :=  (aPlayer.xpTal_PlayMaker * 100) div 120;
    GridXP.Cells[1,20].Text  := IntToStr(aPlayer.xpTal_faul) + '/120';
    GridXP.Cells[1,20].ProgressBarValue :=  (aPlayer.xpTal_faul * 100) div 120;
    GridXP.Cells[1,21].Text  := IntToStr(aPlayer.xpTal_marking) + '/120';
    GridXP.Cells[1,21].ProgressBarValue :=  (aPlayer.xpTal_marking * 100) div 120;
    GridXP.Cells[1,22].Text  := IntToStr(aPlayer.xpTal_Positioning) + '/120';
    GridXP.Cells[1,22].ProgressBarValue :=  (aPlayer.xpTal_Positioning * 100) div 120;
    GridXP.Cells[1,23].Text  := IntToStr(aPlayer.xpTal_freekicks) + '/120';
    GridXP.Cells[1,23].ProgressBarValue :=  (aPlayer.xpTal_freekicks * 100) div 120;

  end
  else begin
    for I := 7 to GridXP.RowCount -1 do begin
      GridXP.Cells[0,i].Text:= '';
      GridXP.Cells[1,i].Text:= '';
    //  GridXP.RemoveBitmap (2,i);
    end;

  end;

  ts := TStringList.Create;
  ts.Delimiter := '/';
  ts.StrictDelimiter:= True;
  for I := 0 to GridXP.RowCount -1 do begin
    ts.DelimitedText := GridXP.Cells[1,i].Text ;
    if Length( ts.DelimitedText) < 5 then Continue;

    a := StrToInt(ts[0]);
    b := StrToInt(ts[1]);
    if a >= b then begin   // se sono arrivato a 120 o anche oltre
      GridXP.Cells[0,i].BackColor := clGray;
      GridXP.Cells[1,i].BackColor := clGray;
      GridXP.Cells [0,i].FontColor := $0041BEFF;
      GridXP.Cells [1,i].FontColor := $0041BEFF;
    end;

  end;
  ts.Free;
end;
procedure TForm1.SetupGridAttributes (GridAT: SE_grid; aPlayer: TsoccerPlayer; show: char);
var
  i,y: Integer;
  ts :TStringList;
  bmp: SE_bitmap;
begin

  GridAT.ClearData;   // importante anche pr memoryleak
  GridAT.DefaultColWidth := 16;
  GridAT.DefaultRowHeight := 16;
  GridAT.ColCount :=4; // descrizione, vuoto, valore, bitmaps o progressbar
  GridAT.RowCount :=9; // 6 attributi + eta , valore, stamina
  GridAT.Columns[0].Width := 80;
  GridAT.Columns[1].Width := 30; // align right
  GridAT.Columns[2].Width := 10; // vuota
  GridAT.Columns[3].Width := 12*9; //9 massimo valore attributo
  GridAT.Height := 16*9;// 9 righe
  GridAT.Width := 80+30+10+(12*9);

  for y := 0 to GridAT.RowCount -1 do begin
    GridAT.Rows[y].Height := 16;

    GridAT.Cells[0,y].FontName := 'Verdana';
    GridAT.Cells[0,y].FontSize := 8;
    GridAT.cells [0,y].FontColor := clWhite;

    GridAT.Cells[1,y].FontSize := 8;
    GridAT.cells [1,y].FontColor := clWhite;
    GridAT.cells [1,y].FontColor := clYellow;
    GridAT.Cells[1,y].CellAlignmentH := hRight;

  end;

  if aPlayer.TalentId <> 1 then begin
    GridAT.Cells[0,0].text:= Translate('attribute_Speed');
    GridAT.Cells[0,1].text:= Translate('attribute_Defense');
    GridAT.Cells[0,2].text:= Translate('attribute_Passing');
    GridAT.Cells[0,3].text:= Translate('attribute_BallControl');
    GridAT.Cells[0,4].text:= Translate('attribute_Shot');
    GridAT.Cells[0,5].text:= Translate('attribute_Heading');
    GridAT.Cells[0,6].text:= Translate('lbl_Age');
    GridAT.Cells[0,7].text:= Translate('lbl_MarketValue');
    GridAT.Cells[0,8].text:= Translate('attribute_Stamina');
  end
  else begin
    GridAT.Cells[0,1].text:= Translate('attribute_Defense');
    GridAT.Cells[0,2].text:= Translate('attribute_Passing');
  end;

  if Show = 'a' then begin

    // ora aggiungo i dati

    if aPlayer.TalentId <> 1 then begin
      GridAT.Cells[1,0].Text := IntTostr(aPlayer.Speed);
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.Passing);
      GridAT.Cells[1,3].Text := IntTostr(aPlayer.BallControl);
      GridAT.Cells[1,4].Text := IntTostr(aPlayer.Shot);
      GridAT.Cells[1,5].Text := IntTostr(aPlayer.Heading);
      GridAT.Cells[1,6].Text := IntTostr(aPlayer.Age);
      GridAT.Cells[1,7].Text := IntTostr(aPlayer.MarketValue);
      GridAT.Cells[1,8].Text := IntTostr(aPlayer.Stamina);
    end
    else begin
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.Passing);

    end;
    // i bmp
    bmp:= SE_bitmap.Create ( dir_ball + 'ball2.bmp');

    GridAT.AddSE_Bitmap ( 3, 0, aPlayer.Speed, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 1, aPlayer.Defense, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 2, aPlayer.Passing, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 3, aPlayer.BallControl, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 4, aPlayer.Shot, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 5, aPlayer.Heading, bmp, true );

    bmp.Free;
  end
  else if show = 'h' then begin

    if aPlayer.TalentId <> 1 then begin
      GridAT.Cells[1,0].Text := IntTostr(aPlayer.history_Speed);
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.history_Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.history_Passing);
      GridAT.Cells[1,3].Text := IntTostr(aPlayer.history_BallControl);
      GridAT.Cells[1,4].Text := IntTostr(aPlayer.history_Shot);
      GridAT.Cells[1,5].Text := IntTostr(aPlayer.history_Heading);
      GridAT.Cells[1,6].Text := IntTostr(aPlayer.Age);
      GridAT.Cells[1,7].Text := IntTostr(aPlayer.MarketValue);
      GridAT.Cells[1,8].Text := IntTostr(aPlayer.Stamina);
    end
    else begin
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.history_Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.history_Passing);

    end;
    // i bmp
    bmp:= SE_bitmap.Create ( dir_ball + 'ball2.bmp');

    GridAT.AddSE_Bitmap ( 3, 0, aPlayer.history_Speed, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 1, aPlayer.history_Defense, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 2, aPlayer.history_Passing, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 3, aPlayer.history_BallControl, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 4, aPlayer.history_Shot, bmp, true );
    GridAT.AddSE_Bitmap ( 3, 5, aPlayer.history_Heading, bmp, true );

    bmp.Free;
  end;

  GridAT.AddProgressBar(3,8, (aPlayer.Stamina * 100 ) div 120 ,clGreen {//$00804000},pbstandard); // cellx, celly, value, style
   if aPlayer.Stamina <= 60 then
    GridAT.Cells [3,8].ProgressBarColor := clRed
    else GridAT.Cells [3,8].ProgressBarColor:=clGreen {//$00804000};


  Form1.lbl_Talent0.Left := Form1.PanelinfoPlayer0.Width div 2 - Form1.lbl_Talent0.Width div 2 ;
  Form1.lbl_Talent0.Top := Form1.SE_grid0.Top + Form1.SE_grid0.Height + 6 ;
  Form1.lbl_descrtalent0.Left := Form1.SE_grid0.Left ;
  Form1.lbl_descrtalent0.Top := Form1.lbl_Talent0.Top + Form1.lbl_Talent0.Height + 8;
  Form1.lbl_descrtalent0.Width := Form1.SE_grid0.Width ;
  Form1.lbl_descrtalent0.Height := 74;

  Form1.lbl_Talent1.Left := Form1.PanelinfoPlayer1.Width div 2 - Form1.lbl_Talent1.Width div 2 ;
  Form1.lbl_Talent1.Top := Form1.SE_grid1.Top + Form1.SE_grid1.Height + 6;
  Form1.lbl_descrtalent1.Left := Form1.SE_grid1.Left ;
  Form1.lbl_descrtalent1.Top := Form1.lbl_Talent1.Top + Form1.lbl_Talent1.Height + 8;
  Form1.lbl_descrtalent1.Width := Form1.SE_grid1.Width ;
  Form1.lbl_descrtalent1.Height := 74;

end;


procedure TForm1.SetTcpFormation;
var
  i: Integer;
  TcpForm: TStringList;
  aPlayer: TSoccerPlayer;
begin
  if GCD <= 0 then begin
    TcpForm:= TStringList.Create ;
    { TODO -cfuturismi : check duplicati anche qui come sul server }
    for i := 0 to MyBrainFormation.lstSoccerPlayer.Count -1 do begin
      aPlayer := MyBrainFormation.lstSoccerPlayer[i];
  // il server valida anche gli Ids, qui il client non può perchè non conosce gli id
           TcpForm.Add( aPlayer.ids  + '=' +
           IntToStr(aPlayer.AIFormationCellX ) + ':' +
           IntToStr(aPlayer.AIFormationCellY ));
    end;

    tcp.SendStr(  'setformation,' +  TcpForm.CommaText + endofline);
    TcpForm.Free;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.tcpDataAvailable(Sender: TObject; ErrCode: Word);
var
  I, LEN, totalString: Integer;
  Buf     : array [0..8191] of AnsiChar;
  ini : Tinifile;
  Ts: TstringList;
  directory,filename,tmpStr: string;
  MMbraindata: TMemoryStream;
  MMbraindataZIP: TMemoryStream;
  SignaturePK : string;
  SignatureBEGINBRAIN: string ;
  DeCompressedStream: TZDecompressionStream;
  s1,s2,s3,s4,InBuffer: string;
  MM,MM2 : TMemoryStream;
  label firstload;
begin
 //   MMbraindata:= TMemoryStream.Create;
 //   MMbrainData.Size := TWSocket(Sender).BufSize;
 //   Len := TWSocket(Sender).Receive(MMbrainData.Memory , TWSocket(Sender).BufSize );
 //   SetString(aaa, PAnsiChar( MMbrainData.Memory ), MMbraindata.Size ); //div SizeOf(Char));
 //   MMbraindata.Free;
//    Len := TCustomLineWSocket(Sender).Receive(@Buf, Sizeof(Buf) - 1);

    // arrivano dati compressi solo dopo beginbrain e beginteam

    MM := TMemoryStream.Create;  // potrebbe anche non servire a nulla
    MM.Size := Sizeof(Buf) - 1;
    Len := TWSocket(Sender).Receive( MM.Memory,  Sizeof(Buf) - 1);
    CopyMemory( @Buf, MM.Memory, Len  ); // metto nel buffer per i comandi non compressi
    TWSocket(Sender).DeleteBufferedData ;
//    Len := TWSocket(Sender).Receive(@Buf, Sizeof(Buf) - 1);

    if Len <= 0 then begin
      MM.Free;
      Exit;
    end;

    // COMPRESSED PACKED
    { -cINFO  : string(buf) mi tronca la stringa zippata }
 //   SetLength( dataStr ,  Len - 19 );
    tmpStr := String(Buf);
    if MidStr( tmpStr,1,4 )= 'GUID' then begin  // guid,guidteam,teamname,nextha,mi
  //    dal server arriva una prima parte stringa e poi uno stream compresso:
  //    Cli.SendStr( 'GUID,' + IntToStr(Cli.GuidTeam ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + ',' +
  //    'BEGINBRAIN' +  chr ( abrain.incMove )   +  brainManager.GetBrainStream ( abrain ) + EndofLine);
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );
      viewMatch := false;
      LiveMatch := true;
      s1 := ExtractWordL (2, tmpStr, ',');
      s2 := ExtractWordL (3, tmpStr, ',');
      s3 := ExtractWordL (4, tmpStr, ',');
      s4 := ExtractWordL (5, tmpStr, ',');
      MyGuidTeam :=  StrToInt(s1);
      MyGuidTeamName :=  s2;


      TotalString := 4 + 5 + Length (s1) + Length (s2) +Length (s3) +Length (s4) ; //4 è la lunghezza di 'GUID' e 5 sono le virgole
      LastTcpIncMove := ord (buf [TotalString + 10 ]); // 10 è lunghezza di BEGINBRAIN. mi posiziono sul primo byte che indica IncMove
      MemoC.Lines.Add('BEGINBRAIN '+  IntToStr(LastTcpIncMove) );

      MM2:= TMemoryStream.Create;
      MM2.Write( buf[  TotalString + 11 ] , len - 11 - TotalString ); // elimino s4 e incmove 11 -11. e prima elimino la parte stringa
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );


      MM3[LastTcpIncMove].Clear;
      MM3[LastTcpIncMove].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[LastTcpIncMove], mm3[LastTcpIncMove].Memory , mm3[LastTcpIncMove].size  ); // copia del buf per non essere sovrascritti
      MM3[LastTcpIncMove].SaveToFile( dir_data + IntToStr(LastTcpIncMove) + '.IS');
//      goto firstload;
      if not FirstLoadOK  then begin   // avvio partita o ricollegamento
        InitializeTheaterMatch;
        SE_interface.RemoveAllSprites;
        GameScreen:= ScreenLiveMatch; // initializetheatermAtch
        CurrentIncMove := LastTcpIncMove;
        ClientLoadBrainMM (CurrentIncMove) ;   // (incmove)
        FirstLoadOK := True;
        if ViewReplay then ToolSpin.Visible := True;
        for I := 0 to 255 do begin
         IncMove [i] := false;
        end;
        for I := 0 to CurrentIncMove do begin
         IncMove [i] := true; // caricato e completamente eseguito
        end;


        SpriteReset;
        ThreadCurMove.Enabled := true;
      end;

      MM.Free;
      Exit;
    end
    else if MidStr( tmpStr,1,10 )= 'BEGINBRAIN' then begin   { il byte incmove nella stringa}

      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

        LastTcpIncMove := ord (buf [10]);
        MemoC.Lines.Add('BEGINBRAIN '+  IntToStr(LastTcpIncMove) );

        // elimino beginbrain
        MM2:= TMemoryStream.Create;
        MM2.Write( buf[11] , len - 11 ); // elimino beginbrain   e incmove 11 -11

        // su mm3 ho 9c78 compressed
         DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
  //       mm3[incmove].clearM
         MM3[LastTcpIncMove].Clear;
  //       DeCompressedStream.Position := 0;
         MM3[LastTcpIncMove].CopyFrom ( DeCompressedStream, 0);
         MM2.free;     // endsoccer si perde da solo decomprimendo
         DeCompressedStream.Free;
  //      CopyMemory( @Buf3, mm3.Memory , mm3.size  ); // copia del buf per non essere sovrascritti
        CopyMemory( @Buf3[LastTcpIncMove], mm3[LastTcpIncMove].Memory , mm3[LastTcpIncMove].size  ); // copia del buf per non essere sovrascritti
        MM3[LastTcpIncMove].SaveToFile( dir_data + IntToStr(LastTcpIncMove) + '.IS');
  firstload:
      if viewMatch or LiveMatch then begin
        if not FirstLoadOK  then begin   // avvio partita o ricollegamento
          InitializeTheaterMatch;
          GameScreen:= ScreenLiveMatch; // initializetheatermAtch
          CurrentIncMove := LastTcpIncMove;
          ClientLoadBrainMM (CurrentIncMove) ;   // (incmove)
          FirstLoadOK := True;
          for I := 0 to 255 do begin
           IncMove [i] := false;
          end;
          for I := 0 to CurrentIncMove do begin
           IncMove [i] := true; // caricato e completamente eseguito
          end;


          SpriteReset;
          ThreadCurMove.Enabled := true;

        end;

      end;
        MM.Free;
        Exit;
    end
    else if MidStr(tmpStr,1,9 )= 'BEGINTEAM' then begin
      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[9] , len - 9 ); // elimino beginteam

      // su mm3 ho 9c78 compressed
       DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
       MM3[0].Clear;
//       DeCompressedStream.Position := 0;
       MM3[0].CopyFrom ( DeCompressedStream, 0);
       MM2.free;     // endsoccer si perde da solo decomprimendo
       DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      GameScreen := ScreenFormation;

      ClientLoadFormation;
      MM.Free;
      Exit;
    end
    else if MidStr(tmpStr,1,11 )= 'BEGINMARKET' then begin
      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[11] , len - 11 ); // elimino beginMarket

      // su mm3 ho 9c78 compressed
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
      MM3[0].Clear;
//       DeCompressedStream.Position := 0;
      MM3[0].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      ClientLoadMarket;
      GameScreen := ScreenMarket;
      MM.Free;
      Exit;
    end
    else if MidStr(tmpStr,1,8 )= 'BEGINLAB' then begin
      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[8] , len - 8 ); // elimino beginLAB

      // su mm3 ho 9c78 compressed
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
      MM3[0].Clear;
//       DeCompressedStream.Position := 0;
      MM3[0].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      ClientLoadListMatchFile;
      GameScreen := ScreenSelectLiveMatch;
      MM.Free;
      Exit;
    end;

    ThreadCurMove.Enabled := false; // parte solo in beginbrain
    MemoC.Lines.Add( 'normal size: ' + IntToStr(Len) );

  //  Buf[Len]       := #0;              { Nul terminate  }
    Ts:= Tstringlist.Create ;
    Ts.StrictDelimiter := True;
    ts.CommaText := RemoveEndOfLine(String(Buf));
//    ts.CommaText := RemoveEndOfLine(aaa);
    MemoC.Lines.Add('<tcp:'+ Ts.CommaText);
    if rightstr(ts[0],4) = 'guid' then begin   // guid,guidteam,teamname,nextha,mi
      MyGuidTeam := StrToInt(ts[1]);
      MyGuidTeamName := ts[2];
      Caption := Edit1.Text + '-' + MyGuidTeamName;
      GameScreen := ScreenMain;
    end
    else if  ts[0] = 'BEGINWT' then begin  // lista team della country selezionata
      ts.Delete(0); // BEGINWT
      TsNationTeams.CommaText := ts.CommaText;
      GameScreen := ScreenSelectTeam;

    end
    else if  ts[0] = 'BEGINWC' then begin // lista country
      ts.Delete(0); // BEGINWC
      TsWorldCountries.CommaText := ts.CommaText;
      GameScreen := ScreenSelectCountry;
    end
    else if  ts[0] = 'BEGINLM' then begin // lista match attivi-
      ts.Delete(0); // BEGINLM
    end
    else if ts[0] = 'avg' then begin   // media ms di attesa, da fare in futuro
      //MyGuidTeam := StrToInt(ts[1]);
      //MyGuidTeamName := ts[2];
      //Caption := Edit1.Text + '-' + MyGuidTeamName;
      GameScreen := ScreenWaitingLiveMatch;
    end
    else if ts[0] = 'errorlogin' then begin
      lastStrError:= ts[0];
      ShowError( Translate(ts[0]));
    end
    else if ts[0] = 'errorformation' then begin
      lastStrError:= ts[0];
      ShowError( Translate(ts[0]));
    end;

    ts.Free;
    MM.Free;

end;

procedure TForm1.tcpException(Sender: TObject; SocExcept: ESocketException);
begin

      MemoC.Lines.add('Can''t connect, error ' + SocExcept.ErrorMessage);
      GameScreen := ScreenLogin;

end;

procedure TForm1.tcpSessionClosed(Sender: TObject; ErrCode: Word);
begin
      advDice.ClearAll ;
      FirstLoadOK:= False;
      MyGuidTeam := 0;
      Timer1.Enabled := true;
      AdvBadgeLabel1.BadgeColor := clRed;
      AdvBadgeLabel1.Badge := 'connecting';
      GameScreen := ScreenLogin;
      MyBrainFormation.lstSoccerPlayer.Clear;
      ThreadCurMove.Enabled := False;
      viewMatch := false;
      LiveMatch := false;
end;

procedure TForm1.tcpSessionConnected(Sender: TObject; ErrCode: Word);
begin
    if ErrCode <> 0 then begin
      Timer1.Enabled := true;
      MemoC.Lines.add('Can''t connect, error #' + IntToStr(ErrCode));
      GameScreen := ScreenLogin;
      WaitForAuth := True;
      AdvBadgeLabel1.BadgeColor := clRed;
      AdvBadgeLabel1.Badge := 'connecting';
      ThreadCurMove.Enabled := False;
      viewMatch := false;
      LiveMatch := false;

    end
    else  begin
      //Timer1.Enabled := False;
      se_Theater1.Active := true;
      MemoC.Lines.add('Session Connected.');
      //GameScreen := ScreenLogin;
      WaitForAuth := True;
      AdvBadgeLabel1.BadgeColor := clGreen;
      AdvBadgeLabel1.Badge := 'connected';
      viewMatch := false;
      LiveMatch := false;
    end;
end;



{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TForm1.ThreadCurMoveTimer(Sender: TObject);
begin
      // brain in memoria e sprite a video
      // se c'è lo script lo eseguo
    if ( SE_ball.IsAnySpriteMoving  ) or (SE_players.IsAnySpriteMoving ) or (Animating) then
      Exit;


    if CurrentIncMove <= LastTcpIncMove  then begin

      if IncMove [CurrentIncMove] = false then begin   // se non è stato ancora caricato nella tsScript

        ClientLoadScript ( CurrentIncMove ); // ( MM3, buf3 ); // punta direttamente dove comincia tsScript
        if Mybrain.tsScript.Count = 0 then begin
          ClientLoadBrainMM ( CurrentIncMove);
          IncMove [CurrentIncMove] := True; // caricato e completamente eseguito
         // Inc(CurrentIncMove); // se maggiore al giro dopo aspetta
        end
        else
          ElaborateTsScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
      // per questro motivo MM3 e buf3 devono essere globali

//          Inc(CurrentIncMove); // se maggiore al giro dopo aspetta
      end
      else Inc(CurrentIncMove); // se maggiore al giro dopo aspetta



    end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  ini : TInifile;
begin
    if ViewReplay then
      exit;
    if Tcp.State = wsConnecting then
        Exit;

    if Tcp.State <> wsConnected then  begin

        ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
        tcp.Addr := ini.ReadString('tcp','addr','127.0.0.1');
        Tcp.Port := ini.ReadString('tcp','port','2018');
        ini.Free;

        tcp.LineMode := true;
        tcp.LineLimit := 8192;
        tcp.LineEdit  := false;
        tcp.LineEnd := EndOfLine;
        tcp.LingerOnOff := wsLingerOn;
        Tcp.Connect;
    end;


      if MyBrain.GameStarted  then begin
        localseconds := localseconds - (Timer1.Interval div 1000);
        if LocalSeconds < 0 then LocalSeconds := 0;

//        Caption :=  Edit1.Text + ' ' + MyBrain.Score.Team [  MyBrain.TeamTurn ] +  ' ' + IntToStr(MyBrain.TeamTurn) + ': '+ IntToStr(localseconds);
        ProgressSeconds.Position := localseconds;
        if ProgressSeconds.PercentDone  < 50 then
          ProgressSeconds.Font.Color := clWhite
          else ProgressSeconds.Font.Color := GetContrastColor(MyBrain.Score.DominantColor [  MyBrain.TeamTurn ]) ;


        ProgressSeconds.Caption := IntToStr(localseconds);

      end;
end;


procedure TForm1.toolSpinButtonClick(Sender: TObject; Button: TSpinButtonType);
var
  AChar: Char;
begin
  aChar := #13;
  toolSpinKeyPress(Sender, aChar);
end;

procedure TForm1.toolSpinKeyPress(Sender: TObject; var Key: Char);
begin
  {$ifdef tools}
  if Key=#13 then begin
    ThreadCurMove.Enabled := False;
    Key:=#0;

    ViewReplay := True;
  // dialogs
    if FileExists( FolderDialog1.Directory  + '\' + Format('%.*d',[3, Trunc(toolSpin.Value)]) + '.IS'  ) then begin
      AnimationScript.Reset;
      MM3[Trunc(toolSpin.Value)].LoadFromFile( FolderDialog1.Directory  + '\' + Format('%.*d',[3, Trunc(toolSpin.Value)]) + '.IS');
      CopyMemory( @Buf3[Trunc(toolSpin.Value)], MM3[Trunc(toolSpin.Value)].Memory, MM3[Trunc(toolSpin.Value)].size  );

      if Trunc(toolSpin.Value) > 0 then begin
        MM3[Trunc(toolSpin.Value)-1].LoadFromFile( FolderDialog1.Directory  + '\' + Format('%.*d',[3, Trunc(toolSpin.Value)-1]) + '.IS');
        CopyMemory( @Buf3[Trunc(toolSpin.Value)-1], MM3[Trunc(toolSpin.Value)-1].Memory, MM3[Trunc(toolSpin.Value)-1].size  );
        ClientLoadBrainMM ( Trunc(toolSpin.Value)-1 );
      end;

      CurrentIncMove :=  Trunc(toolSpin.Value);
      ClientLoadScript( Trunc(toolSpin.Value) );
      if Mybrain.tsScript.Count = 0 then begin
        ClientLoadBrainMM ( Trunc(toolSpin.Value) );
      end
      else
        ElaborateTsScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
    end
    else begin
      ShowMessage('file missing');
    end;

  end;
  {$endif tools}
end;

procedure TForm1.SetGameScreen (const aGameScreen:TGameScreen);
var
  i: Integer;
  aPlayer: TSoccerPlayer;
  aSeField: SE_Sprite;

begin

  fGameScreen:= aGameScreen;

  if fGameScreen = ScreenLogin then begin
    AudioCrowd.Stop;
    viewMatch := False;
    ShowLogin;

  end
  else if fGameScreen = ScreenSelectCountry then begin
    AudioCrowd.Stop;
    SE_Theater1.Visible := false;
    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    // file data\world.countries.ini riempe advCountry
    advCountryTeam.ColWidths [0] := 0;

    advCountryTeam.RowCount := TsWorldCountries.count;
    for I := 0 to advCountryTeam.RowCount -1 do begin
      advCountryTeam.Cells[0,i]:= TsWorldCountries.Names[i];
      advCountryTeam.Cells[1,i]:= TsWorldCountries.ValueFromIndex[i];
    end;

    advCountryTeam.Row := 0;
    PanelCountryTeam.Visible := True;
  end
  else if fGameScreen = ScreenSelectTeam then begin
    AudioCrowd.Stop;
    SE_Theater1.Visible := false;
    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    // file data\world.teamss.ini riempe advCountry
    advCountryTeam.RowCount := TsNationTeams.Count;
    for I := 0 to advCountryTeam.RowCount -1 do begin
      advCountryTeam.Cells[0,i]:= TsNationTeams.Names[i];
      advCountryTeam.Cells[1,i]:= TsNationTeams.ValueFromIndex[i];
    end;


    advCountryTeam.Row := 0;
    PanelCountryTeam.Visible := True;

  end
  else if fGameScreen = ScreenWaitingFormation then begin // si accede cliccando back - settcpformation, in attesa
    AudioCrowd.Stop;
    SetTheaterMatchSize;
    PanelInfoPlayer0.Visible := False;
    PanelMarket.Visible:= False;
    PanelSell.Visible:= false;
    PanelDismiss.Visible:= false;
    PanelformationSE.Visible:= false;
    CreateNoiseTv;

  end
  else if fGameScreen = ScreenFormation then begin    // diversa da ScreenLiveFormations che prende i dati dal brain

    AudioCrowd.Stop;
    FirstLoadOK:= False;
    PanelCombatLog.Visible := False;
    SE_Theater1.Visible := false;
    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelCountryTeam.Visible := false;
    PanelListMatches.Visible := false;
    PanelSell.Visible := false;
    PanelMarket.Visible := False;
    PanelScore.Visible:= False;

    btnWatchLiveExit.Visible := false;
    PanelInfoPlayer0.Visible:= True;
    PanelInfoPlayer1.Visible:= false;
    PanelXPPlayer0.Visible := false;
    InitializeTheaterFormations;
    ShowFormations;
  end

  else if fGameScreen = ScreenTactics then begin    // btnTACTICS prende i dati dal brain

    if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 or
    (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) or Animating then Exit;
   // MyBrain.ClearReserveSlot; // questo va bene e poi le devo riempire con putinreserveslot

    PanelSkillSE.Visible := False;
    PanelCombatLog.Visible := False;
    // passo da cells a defaultcell. E' visibile anche l'avversario

    for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer := MyBrain.lstSoccerPlayer [i];
      if aPlayer.gameover then Continue;    // espulsi o già sostituiti

        aSEField := SE_field.FindSprite(IntToStr (aPlayer.DefaultCellX ) + '.' + IntToStr (aPlayer.DefaultCellY ));
        aPlayer.se_Sprite.Position := aSEField.position  ;
        aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

       aPlayer.se_sprite.Visible := True;
    end;
    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin
      aPlayer := MyBrain.lstSoccerReserve [i];
      //if aPlayer.gameover then Continue;    // espulsi o già sostituiti
      aPlayer.se_sprite.Visible := False
    end;

//    lblSubsLeft.Caption := Translate ( 'Substitutions' ) + ' ' + IntToStr( MyBrain.Score.TeamSubs [MyBrain.TeamTurn]  - MyBrain.InQueueSubsTeam (MyBrain.TeamTurn) );

    MyBrain.Ball.Se_Sprite.Visible := False;


  end
  else if fGameScreen = ScreenSubs then begin    // btnSubs

    PanelSkillSE.Visible := False;
    PanelCombatLog.Visible := False;

    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      aPlayer := MyBrain.lstSoccerPlayer [i];
        if aPlayer.gameover then aPlayer.se_sprite.Visible := False;   // espulsi o già sostituiti
        if  MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin  // nel mio turno
          if aPlayer.GuidTeam <> MyGuidTeam then
            aPlayer.se_sprite.Visible := False;
        end;

    end;

    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin
      aPlayer := MyBrain.lstSoccerReserve [i];
        if aPlayer.gameover then aPlayer.se_sprite.Visible := False;   // espulsi o già sostituiti
        if  MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin  // nel mio turno
          if aPlayer.GuidTeam <> MyGuidTeam then
            aPlayer.se_sprite.Visible := False
            else aPlayer.se_sprite.Visible := true;
        end;
    end;

    MyBrain.Ball.Se_Sprite.Visible := False;

  end


  else if fGameScreen = ScreenMain then begin
    AudioCrowd.Stop;
    ThreadCurMove.Enabled := false; // parte solo in beginbrain
    FirstLoadOK:= False;
    btnWatchLiveExit.Visible := false;
    PanelInfoPlayer0.Visible:= false;
    PanelInfoPlayer1.Visible:= false;
    PanelXPPlayer0.Visible := false;
    PanelScore.Visible := false;
    ShowMain;
    //ClientLoadFormation ;
    btnMainPlay.Enabled := CheckFormationTeamMemory;

  end
  else if fGameScreen = ScreenWaitingLiveMatch then begin // si accede cliccando queue
    AudioCrowd.Stop;
    SE_Theater1.Visible := True;
    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    SetTheaterMatchSize;
    CreateNoiseTv;

  end
  else if (fGameScreen = ScreenLivematch) or (fGameScreen = ScreenWatchLive) then begin
//    SetTheaterMatchSizeSE;
    SE_Theater1.Visible := True;
    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    btnWatchLiveExit.Visible := false;
    PanelInfoPlayer0.Visible:= True;
    PanelInfoPlayer1.Visible:= True;
    PanelXPPlayer0.Visible := false;
    PanelScore.Visible := true;
    ShowScore;
    advDice.ClearAll ;
  end
  else if fGameScreen = ScreenWaitingWatchLive then begin // si accede cliccando l'icona TV
    AudioCrowd.Stop;
    SE_Theater1.Visible := True;
    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    SetTheaterMatchSize;
    CreateNoiseTv;

  end
  else if fGameScreen = ScreenSelectLiveMatch then begin
    AudioCrowd.Stop;
    btnWatchLiveExit.Visible := false;
    FirstLoadOK:= False;
    PanelLogin.Visible := false;
    PanelMain.Visible := false;
    SE_Theater1.Visible := false;
    PanelListMatches.Visible := True;
  end
  else if fGameScreen = ScreenMarket then begin
    AudioCrowd.Stop;
    btnWatchLiveExit.Visible := false;
    FirstLoadOK:= False;
    PanelLogin.Visible := false;
    PanelMain.Visible := false;
    SE_Theater1.Visible := false;
    PanelListMatches.Visible := false;
    PanelMarket.Visible:= True;
  end;


end;
procedure TForm1.ClientLoadListMatchFile ;
var
  i,count,Country0,Country1,ActiveMatchesCount,Cur,LBrainIds,LUserName0,LUserName1,LTeamName0,LTeamName1: Integer;
  bmpflags, cBitmap: SE_Bitmap;
  SS : TStringStream;
  dataStr: string;
begin
{
  MM.Write( @BrainManager.lstbrain.count , SizeOf(word) );
  for i := BrainManager.lstbrain.count -1 downto 0 do begin

    MM.Write( @BrainManager.lstBrain[i].BrainIDS, Length (BrainManager.lstBrain[i].BrainIDS) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.UserName[0], Length (BrainManager.lstBrain[i].Score.UserName) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.UserName[1], Length (BrainManager.lstBrain[i].Score.UserName) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.Team[0], Length (BrainManager.lstBrain[i].Score.Team[0]) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.Team[1], Length (BrainManager.lstBrain[i].Score.Team[1]) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.Country[0], sizeof (word ) );
    MM.Write( @BrainManager.lstBrain[i].Score.Country[1], sizeof (word ) );
    MM.Write( @BrainManager.lstBrain[i].Score.Gol[0], sizeof (byte ) );
    MM.Write( @BrainManager.lstBrain[i].Score.Gol[1], sizeof (byte ) );
    MM.Write( @BrainManager.lstBrain[i].minute, sizeof (byte ) );                       '

  end;
}
  // su MM3 globale c'è la lista
  SS := TStringStream.Create;
  SS.Size := MM3[0].Size;
  MM3[0].Position := 0;
  ss.CopyFrom( MM3[0], MM3[0].size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  bmpflags := SE_Bitmap.Create ( dir_interface + 'flags.bmp');
  advAllBrain.ClearAll ;
  advAllBrain.RowCount :=1;
  advAllBrain.Cells[0,0]:= '';
  advAllBrain.Cells[1,0]:= '';
  advAllBrain.ColWidths [0]:=0;
  advAllBrain.ColWidths [1]:=80;     //usename 0
  advAllBrain.ColWidths [2]:=30;     // flag 0
  advAllBrain.ColWidths [3]:=120;    // teamname  0
  advAllBrain.ColWidths [4]:=20;
  advAllBrain.ColWidths [5]:=20;
  advAllBrain.ColWidths [6]:=120;    // teamname  1
  advAllBrain.ColWidths [7]:=30;     // flag 0
  advAllBrain.ColWidths [8]:=80;     //usename 1
  advAllBrain.ColWidths [9]:=60;  // vuoto
  advAllBrain.ColWidths [10]:=30;  // icona tv
  advAllBrain.ColWidths [11]:=40;  // minute

  // a 0 c'è la word che indica dove comincia
  cur := 0;
  ActiveMatchesCount:=   PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
  advAllBrain.RowCount := ActiveMatchesCount;
  Cur := Cur + 2; // è una word

  for I := 0 to ActiveMatchesCount -1 do begin
    LBrainIds :=  Ord( buf3[0][ cur ]);
    advAllBrain.Cells[0,i]  := MidStr( dataStr, cur + 2  , LBrainIds );// ragiona in base 1
    cur  := cur + LBrainIds + 1;

    LuserName0 :=  Ord( buf3[0][ cur ]);
    advAllBrain.Cells[1,i]  := MidStr( dataStr, cur + 2  , LuserName0 );// ragiona in base 1
    cur  := cur + LuserName0 + 1;
    LuserName1 :=  Ord( buf3[0][ cur ]);
    advAllBrain.Cells[8,i]  := MidStr( dataStr, cur + 2  , LuserName1 );// ragiona in base 1
    cur  := cur + LuserName1 + 1;

    advAllbrain.Alignments [8,i] := taRightJustify;

    LTeamName0 :=  Ord( buf3[0][ cur ]);
    advAllBrain.Cells[3,i]  := MidStr( dataStr, cur + 2  , LTeamName0 );// ragiona in base 1
    cur  := cur + LTeamName0 + 1;
    LTeamName1 :=  Ord( buf3[0][ cur ]);
    advAllBrain.Cells[6,i]  := MidStr( dataStr, cur + 2  , LTeamName1 );// ragiona in base 1
    cur  := cur + LTeamName1 + 1;

    Country0:=  PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
    cBitmap := SE_Bitmap.Create (60,40);

    case Country0  of
      1: begin
        bmpflags.CopyRectTo( cBitmap, 2,12,0,0,60,40,False,0 );
      end;
      2: begin
        bmpflags.CopyRectTo( cBitmap, 66,12,0,0,60,40,False,0 );
      end;
      3: begin
        bmpflags.CopyRectTo( cBitmap, 130,12,0,0,60,40,False,0 );
      end;
      4: begin
        bmpflags.CopyRectTo( cBitmap, 194,12,0,0,60,40,False,0 );
      end;
      5: begin
        bmpflags.CopyRectTo( cBitmap, 259,12,0,0,60,40,False,0 );
      end;
    end;
    cBitmap.Stretch(30,22);
    advAllBrain.AddBitmap(2,i,cBitmap.Bitmap,false, haLeft, vaTop);
    Cur := Cur + 2;

    Country1:=  PWORD(@buf3[0][ cur ])^;               // ragiona in base 0
    cBitmap := SE_Bitmap.Create (60,40);

    case Country1  of
      1: begin
        bmpflags.CopyRectTo( cBitmap, 2,12,0,0,60,40,False,0 );
      end;
      2: begin
        bmpflags.CopyRectTo( cBitmap, 66,12,0,0,60,40,False,0 );
      end;
      3: begin
        bmpflags.CopyRectTo( cBitmap, 130,12,0,0,60,40,False,0 );
      end;
      4: begin
        bmpflags.CopyRectTo( cBitmap, 194,12,0,0,60,40,False,0 );
      end;
      5: begin
        bmpflags.CopyRectTo( cBitmap, 259,12,0,0,60,40,False,0 );
      end;
    end;
    cBitmap.Stretch(30,22);
    advAllbrain.Alignments [6,i] := taRightJustify;
    advAllBrain.AddBitmap(7,i,cBitmap.Bitmap, false, haLeft, vaTop);
    Cur := Cur + 2;


    advAllBrain.Cells[4,i]:=  IntToStr( ord ( buf3[0][ cur ]));                 // ragiona in base 0
    Cur := Cur + 1;
    advAllBrain.Cells[5,i]:=  IntToStr( ord ( buf3[0][ cur ]));                 // ragiona in base 0
    Cur := Cur + 1;

    advAllbrain.Alignments [11,i] := taLeftJustify;
    advAllBrain.Cells[11,i]:=  IntToStr ( ord ( buf3[0][ cur ]));
    Cur := Cur + 1;

    // 9 vuota

    cBitmap := SE_Bitmap.Create ( dir_interface + 'tv.bmp');
    advAllBrain.AddBitmap(10,i,cBitmap.Bitmap, false, haLeft, vaTop);



  end;

  bmpflags.Free;

end;
procedure TForm1.ClientLoadMarket ;
var
  i,i1,RecordCount,Cur,LSurName,Age : Integer;
  talentID : byte;
  cBitmap: SE_Bitmap;
  SS : TStringStream;
  dataStr: string;
  MatchesPlayed,MatchesLeft: Word;
  y: Integer;
begin
{
    MM.Write( @Count , SizeOf(word) );

    for i := MyQuerymarket.RecordCount -1 downto 0 do begin

      MM.Write( @guidplayer, sizeof ( integer ) );
      MM.Write( @name[0], Length (name) +1 );
      MM.Write( @sellprice, sizeof ( integer ) );

      MM.Write( @speed, sizeof ( byte ) );
      MM.Write( @defense, sizeof ( byte ) );
      MM.Write( @passing, sizeof ( byte ) );
      MM.Write( @ballcontrol, sizeof ( byte ) );
      MM.Write( @shot, sizeof ( byte ) );
      MM.Write( @heading, sizeof ( byte ) );
      MM.Write( @talent, sizeof ( byte ) );

      MM.Write( @matches_played, sizeof ( word ) );
      MM.Write( @matches_left, sizeof ( word ) );
}
  // su MM3 globale c'è la lista
  SS := TStringStream.Create;
  SS.Size := MM3[0].Size;
  MM3[0].Position := 0;
  ss.CopyFrom( MM3[0], MM3[0].size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  advMarket.ClearAll ;
  advMarket.RowCount :=1;
  advMarket.ColWidths [0]:=0;      // guidplayer
  advMarket.ColWidths [1]:=100;     // name
  advMarket.ColWidths [2]:=65;     // sell
  advMarket.ColWidths [3]:=35;    // s
  advMarket.ColWidths [4]:=35;     // d
  advMarket.ColWidths [5]:=35;     // p
  advMarket.ColWidths [6]:=35;    // bc
  advMarket.ColWidths [7]:=35;     // sh
  advMarket.ColWidths [8]:=35;     // h
  advMarket.ColWidths [9]:=35;  // talent
  advMarket.ColWidths [10]:=35;  // age
  advMarket.ColWidths [11]:=35;  // matches left
  advMarket.ColWidths [12]:=60;  // BUY

  advMarket.Cells[0,0]:= '';
  advMarket.Cells[1,0]:= Translate('lbl_Surname');
  advMarket.Cells[2,0]:= Translate('lbl_Price');
  advMarket.Cells[3,0]:= Translate('attribute_Speed');
  advMarket.Cells[4,0]:= Translate('attribute_Defense');
  advMarket.Cells[5,0]:= Translate('attribute_Passing');
  advMarket.Cells[6,0]:= Translate('attribute_BallControl');
  advMarket.Cells[7,0]:= Translate('attribute_Shot');
  advMarket.Cells[8,0]:= Translate('attribute_Heading');
  advMarket.Cells[9,0]:= Translate('lbl_Talent');
  advMarket.Cells[10,0]:= Translate('lbl_Age');
  advMarket.Cells[11,0]:= Translate('lbl_MatchesLeft');


  // a 0 c'è la word che indica dove comincia
  cur := 0;
  RecordCount:=   PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
  advMarket.RowCount := RecordCount + 1; // intestazione presente
    advMarket.Alignments [2,0] := taCenter;
    advMarket.Alignments [3,0] := taCenter;
    advMarket.Alignments [4,0] := taCenter;
    advMarket.Alignments [5,0] := taCenter;
    advMarket.Alignments [6,0] := taCenter;
    advMarket.Alignments [7,0] := taCenter;
    advMarket.Alignments [8,0] := taCenter;
    advMarket.Alignments [9,0] := taCenter;
    advMarket.Alignments [10,0] := taCenter;
    advMarket.Alignments [11,0] := taCenter;

  for y := 1 to advMarket.RowCount -1 do begin  // Non intestazione
    advMarket.Alignments [2,y] := taRightJustify;
    advMarket.Alignments [3,y] := taCenter;
    advMarket.Alignments [4,y] := taCenter;
    advMarket.Alignments [5,y] := taCenter;
    advMarket.Alignments [6,y] := taCenter;
    advMarket.Alignments [7,y] := taCenter;
    advMarket.Alignments [8,y] := taCenter;
    advMarket.Alignments [10,y] := taCenter;
    advMarket.Alignments [11,y] := taRightJustify;
  end;



  Cur := Cur + 2; // è una word

  for I := 0 to RecordCount -1 do begin
    I1 := i +1;                                  // intestazione grid
    advMarket.Cells[0,i1]  := IntToStr( PDWORD(@buf3[0][ cur ])^);
    Cur := Cur + 4;

    LSurname :=  Ord( buf3[0][ cur ]);
    advMarket.Cells[1,i1]  := MidStr( dataStr, cur + 2  , LSurname );// ragiona in base 1
    cur  := cur + LSurname + 1;

    advMarket.Cells[2,i1]  :=  IntToStr( PDWORD(@buf3[0][ cur ])^); // sellprice
    Cur := Cur + 4;

    advMarket.Cells[3,i1]  :=  IntToStr( Ord( buf3[0][ cur ]));  // speed
    Cur := Cur + 1;
    advMarket.Cells[4,i1]  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    advMarket.Cells[5,i1]  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    advMarket.Cells[6,i1]  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    advMarket.Cells[7,i1]  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    advMarket.Cells[8,i1]  :=  IntToStr( Ord( buf3[0][ cur ]));  // heading
    Cur := Cur + 1;

    talentID :=  Ord( buf3[0][ cur ]);
    Cur := Cur + 1;

    if talentID <> 0 then begin
      cBitmap := SE_Bitmap.Create ( dir_talent + tsTalents[talentID-1]+'.bmp' ) ;
      cBitmap.Stretch(30,22);
      advMarket.AddBitmap(9,i1,cBitmap.Bitmap,false, haLeft, vaTop);
    end;

    MatchesPlayed :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;

    MatchesLeft :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;

    Age:= Trunc(  MatchesPlayed  div SEASON_MATCHES) + 18 ;

    advMarket.Cells[10,i1]  :=  IntToStr( age );
    advMarket.Cells[11,i1]  :=  IntToStr( MatchesLeft );

    advMarket.Colors[12,i1] := clGray;
    advMarket.FontColors[12,i1] := $0041BEFF;
    advMarket.cells[12,i1] := Translate('lbl_Buy');

  end;


end;


end.


