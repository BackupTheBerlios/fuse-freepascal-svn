program test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads, SysUtils,
  {$ENDIF}{$ENDIF}
  Classes
  { you can add units after this }, BaseUnix, fuse_obj;

Type
  TMyObject = Class(TObject)
  Public
    Function FillDir(DirPath: String; Var DirectoryContents: TStringList; Var AddFSRequiredFiles: Boolean): Boolean;
    Function GetAttr(DirPath: String; Var FileType: TFileType; Var Size: Cardinal; Var NrLinks: Cardinal; Var Mode: Cardinal): Boolean;
    Function Open(Path: String; Mode: Cardinal; Var Reason: TOpenFailReason): Boolean;
    Function Read(Path: String; var Buffer: Array of Byte; Count: Cardinal; Offset: Cardinal): Cardinal;
  End;

Var
  MyObject : TMyObject;

Function TMyObject.FillDir(DirPath: String; Var DirectoryContents: TStringList; Var AddFSRequiredFiles: Boolean): Boolean;
Begin
  {If DirPath = '/' then
  Begin}
    DirectoryContents.Add('Hello');
    AddFSRequiredFiles:=True;
    Result := True
//  End
End;

Function TMyObject.GetAttr(DirPath: String; Var FileType: TFileType; Var Size: Cardinal; Var NrLinks: Cardinal; Var Mode: Cardinal): Boolean;
Begin
  Result := False;
  If DirPath = '/' then
  Begin
    FileType := ftDirectory;
    NrLinks := 2;
    Mode := &755;
    Result := True
  End
  else If DirPath = '/Hello' then
  Begin
    FileType := ftFile;
    NrLinks := 1;
    Size := 13;
    Mode := &444;
    Result := True
  End
End;

Function TMyObject.Open(Path: String; Mode: Cardinal; Var Reason: TOpenFailReason): Boolean;
Begin
  If Path = '/Hello' then
    If (Mode and 3) <> O_RDONLY then
    Begin
      Reason := ofAccessDenied;
      Result := False
    End
    else
      Result := True
  else
    Result := False
End;

Function TMyObject.Read(Path: String; var Buffer: Array of Byte; Count: Cardinal; Offset: Cardinal): Cardinal;
Const
  Data = 'Hello World!'#10;
Var I, J : Integer;
Begin
  If Path <> '/Hello' then
  Begin
    Result := -ESysENOENT;
    Exit
  End;
  If Offset > Length(Data) then
  Begin
    Result := 0;
    Exit
  End;
  J := 0;
  For I := Offset to Count+OffSet-1 do
    If I < Length(Data) then
    Begin
      Buffer[J] := Ord(Data[I+1]);
      Inc(J)
    End;
  Result := J
End;

Var
  AFuseBinding : TFuseBinding;
  FuseExitCode : Integer;
  S : String;
  B : Array[0..100] of byte;
  I : Integer;

begin
  MyObject := TMyObject.Create;
  AFuseBinding := TFuseBinding.Create;
  AFuseBinding.FuseReadDirProc:=@MyObject.FillDir;
  AFuseBinding.FuseGetAttrProc:=@MyObject.GetAttr;
  AFuseBinding.FuseOpenProc:=@MyObject.Open;
  AFuseBinding.FuseReadProc:=@MyObject.Read;
  Writeln(MyObject.Read('/Hello',B,100,0), ' chars');
  S := '';
  For I := 0 to 12 do
  Begin
    Write(hexStr(B[I],2),' ');
    S := S + Chr(B[I])
  End;
  Write(S);
  FuseExitCode := AFuseBinding.fuse_main;
  AFuseBinding.Free;
  MyObject.Free;
  Halt(FuseExitCode)
end.

