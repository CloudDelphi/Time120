{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Fran�ois PIETTE
Creation:     Jan 15, 2005
Description:
Version:      7.03
EMail:        francois.piette@overbyte.be    http://www.overbyte.be
Support:      Unsupported code.
Legal issues: Copyright (C) 2005-2010 by Fran�ois PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium. Fax: +32-4-365.74.56
              <francois.piette@overbyte.be>

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.

              4. You must register this software by sending a picture postcard
                 to the author. Use a nice stamp and mention your name, street
                 address, EMail address and any comment you like to say.

History:
Oct 03, 2009 V7.01 F.Piette added file upload demo. Fixed Unicode issue with
                   answer display.
Dec 19, 2009 V7.02 Arno fixed URL encoding.
Feb 4,  2011 V7.03 Angus added bandwidth throttling using TCustomThrottledWSocket
                    Demo shows file upload duration and speed


 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
unit OverbyteIcsHttpPost1;

{$I OverbyteIcsDefs.inc}
{$IFNDEF DELPHI7_UP}
    Bomb('This sample requires Delphi 7 or later');
{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  OverbyteIcsIniFiles, StdCtrls, ExtCtrls, OverbyteIcsUrl, OverbyteIcsWndControl,
  OverbyteIcsHttpProt, OverByteIcsFtpSrvT;

type
  THttpPostForm = class(TForm)
    ToolsPanel: TPanel;
    DisplayMemo: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    FirstNameEdit: TEdit;
    LastNameEdit: TEdit;
    Label3: TLabel;
    ActionURLEdit: TEdit;
    PostButton: TButton;
    Label4: TLabel;
    HttpCli1: THttpCli;
    Label5: TLabel;
    FileNameEdit: TEdit;
    UploadButton: TButton;
    Shape1: TShape;
    Label6: TLabel;
    UploadURLEdit: TEdit;
    Label10: TLabel;
    BandwidthLimitEdit: TEdit;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure PostButtonClick(Sender: TObject);
    procedure HttpCli1RequestDone(Sender: TObject; RqType: THttpRequest;
                                  ErrCode: Word);
    procedure UploadButtonClick(Sender: TObject);
  private
    FIniFileName : String;
    FInitialized : Boolean;
  public
    procedure Display(Msg : String);
    property IniFileName : String read FIniFileName write FIniFileName;
  end;

var
  HttpPostForm: THttpPostForm;
  StartTime: Longword;

implementation

{$R *.DFM}

const
    SectionWindow      = 'Window';   // Must be unique for each window
    KeyTop             = 'Top';
    KeyLeft            = 'Left';
    KeyWidth           = 'Width';
    KeyHeight          = 'Height';
    SectionData        = 'Data';
    KeyFirstName       = 'FirstName';
    KeyLastName        = 'LastName';
    KeyActionURL       = 'ActionURL';
    KeyUploadURL       = 'UploadURL';
    KeyFilePath        = 'UploadFilePath';
    KeyBandwidthLimit  = 'BandwidthLimit';

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.FormCreate(Sender: TObject);
begin
    FIniFileName := GetIcsIniFileName;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.FormShow(Sender: TObject);
var
    IniFile : TIcsIniFile;
begin
    if not FInitialized then begin
        FInitialized := TRUE;

        IniFile      := TIcsIniFile.Create(FIniFileName);
        Width        := IniFile.ReadInteger(SectionWindow, KeyWidth,  Width);
        Height       := IniFile.ReadInteger(SectionWindow, KeyHeight, Height);
        Top          := IniFile.ReadInteger(SectionWindow, KeyTop,
                                            (Screen.Height - Height) div 2);
        Left         := IniFile.ReadInteger(SectionWindow, KeyLeft,
                                            (Screen.Width  - Width)  div 2);
        FirstNameEdit.Text := IniFile.ReadString(SectionData, KeyFirstName,
                                                 'John');
        LastNameEdit.Text  := IniFile.ReadString(SectionData, KeyLastName,
                                                 'Doe');
        ActionURLEdit.Text := IniFile.ReadString(SectionData, KeyActionURL,
                                  'http://localhost/cgi-bin/FormHandler');
        UploadURLEdit.Text := IniFile.ReadString(SectionData, KeyUploadURL,
                                  'http://localhost/cgi-bin/FileUpload\unit1.pas');
        FileNameEdit.Text := IniFile.ReadString(SectionData, KeyFilePath,
                                  'c:\temp\unit1.pas');
        BandwidthLimitEdit.Text := IniFile.ReadString(SectionData, KeyBandwidthLimit, '1000000');
        IniFile.Free;
        DisplayMemo.Clear;
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
    IniFile : TIcsIniFile;
begin
    IniFile := TIcsIniFile.Create(FIniFileName);
    IniFile.WriteInteger(SectionWindow, KeyTop,         Top);
    IniFile.WriteInteger(SectionWindow, KeyLeft,        Left);
    IniFile.WriteInteger(SectionWindow, KeyWidth,       Width);
    IniFile.WriteInteger(SectionWindow, KeyHeight,      Height);
    IniFile.WriteString(SectionData, KeyFirstName, FirstNameEdit.Text);
    IniFile.WriteString(SectionData, KeyLastName,  LastNameEdit.Text);
    IniFile.WriteString(SectionData, KeyActionURL, ActionURLEdit.Text);
    IniFile.WriteString(SectionData, KeyUploadURL, UploadURLEdit.Text);
    IniFile.WriteString(SectionData, KeyFilePath,  FileNameEdit.Text);
    IniFile.WriteString(SectionData, KeyBandwidthLimit,  BandwidthLimitEdit.Text);
    IniFile.UpdateFile;
    IniFile.Free;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.Display(Msg : String);
begin
    DisplayMemo.Lines.BeginUpdate;
    try
        if DisplayMemo.Lines.Count > 200 then begin
            while DisplayMemo.Lines.Count > 200 do
                DisplayMemo.Lines.Delete(0);
        end;
        DisplayMemo.Lines.Add(Msg);
    finally
        DisplayMemo.Lines.EndUpdate;
        SendMessage(DisplayMemo.Handle, EM_SCROLLCARET, 0, 0);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.PostButtonClick(Sender: TObject);
var
    Data : AnsiString;
begin
    Data := 'FirstName=' + UrlEncodeToA(Trim(FirstNameEdit.Text)) + '&' +
            'LastName='  + UrlEncodeToA(Trim(LastNameEdit.Text))  + '&' +
            'Submit=Submit';
    HttpCli1.SendStream := TMemoryStream.Create;
    HttpCli1.SendStream.Write(Data[1], Length(Data));
    HttpCli1.SendStream.Seek(0, 0);
    HttpCli1.RcvdStream      := TMemoryStream.Create;
    HttpCli1.URL             := Trim(ActionURLEdit.Text);
    HttpCli1.ContentTypePost := 'application/x-www-form-urlencoded';
    StartTime := 0;
    HttpCli1.PostAsync;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.UploadButtonClick(Sender: TObject);
var
    FileName : String;
begin
    FileName                 := Trim(FilenameEdit.Text);
    HttpCli1.SendStream      := TFileStream.Create(FileName, fmOpenRead);
    HttpCli1.RcvdStream      := TMemoryStream.Create;
    HttpCli1.URL             := Trim(UploadURLEdit.Text);
    HttpCli1.ContentTypePost := 'application/binary';
{$IFDEF BUILTIN_THROTTLE}
    HttpCli1.BandwidthLimit := StrToIntDef(BandwidthLimitEdit.Text, 1000000);
    if HttpCli1.BandwidthLimit > 0 then
        HttpCli1.Options := HttpCli1.Options + [httpoBandwidthControl];
{$ENDIF}
    StartTime := GetTickCount;
    HttpCli1.PostAsync;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function BuildLongString(Len : Integer) : String;
var
    I : Integer;
begin
    SetLength(Result, Len);
    for I := 1 to Len do
        Result[I] := Char(48 + (I mod 10));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure THttpPostForm.HttpCli1RequestDone(
    Sender  : TObject;
    RqType  : THttpRequest;
    ErrCode : Word);
var
    Data : AnsiString;  // WebServ demo send AnsiString replies
    Duration, BytesSec, ByteCount: integer;
    Temp: string;
begin
    ByteCount := HttpCli1.SendStream.Size;
    HttpCli1.SendStream.Free;
    HttpCli1.SendStream := nil;

    if ErrCode <> 0 then begin
        Display('Post failed with error #' + IntToStr(ErrCode));
        HttpCli1.RcvdStream.Free;
        HttpCli1.RcvdStream := nil;
        Exit;
    end;
    if HttpCli1.StatusCode <> 200 then begin
        Display('Post failed with error: ' + IntToStr(HttpCli1.StatusCode) +
                ' ' + HttpCli1.ReasonPhrase);
        HttpCli1.RcvdStream.Free;
        HttpCli1.RcvdStream := nil;
        Exit;
    end;
    Display('Post was OK. Response was:');
    HttpCli1.RcvdStream.Seek(0, 0);
    SetLength(Data, HttpCli1.RcvdStream.Size);
    HttpCli1.RcvdStream.Read(Data[1], Length(Data));
    Display(String(Data));
    if StartTime <> 0 then begin
        Duration := GetTickCount - StartTime;
        Temp := 'Received ' + IntToStr(ByteCount) + ' bytes, ';
        if Duration < 5000 then
            Temp := Temp + IntToStr(Duration) + ' milliseconds'
        else
            Temp := Temp + IntToStr(Duration div 1000) + ' seconds';
        if ByteCount > 32767 then
            BytesSec := 1000 * (ByteCount div Duration)
        else
            BytesSec := (1000 * ByteCount) div Duration;
        Temp := Temp + ' (' + IntToKByte(BytesSec) + 'bytes/sec)';
        Display(temp);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

end.
