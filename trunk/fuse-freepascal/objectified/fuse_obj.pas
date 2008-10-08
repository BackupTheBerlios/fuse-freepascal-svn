unit fuse_obj;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fuse, UNIXtype;

type
  TFileType = (ftFile, ftDirectory);
  TOpenFailReason = (ofNonExistant, ofAccessDenied, ofNotSpecified);
  TFuseGetAttrProc = Function(DirPath: String; Var FileType: TFileType; Var Size: Cardinal; Var NrLinks: Cardinal; Var Mode: Cardinal): Boolean of object;
  TFuseReadDirProc = Function(Path: String; Var DirectoryContents: TStringList; Var AddFSRequiredFiles: Boolean): Boolean of object;
  TFuseOpenProc = Function(Path: String; Mode: Cardinal; Var Reason: TOpenFailReason): Boolean of object;
  TFuseReadProc = Function(Path: String; var Buffer: Array of Byte; Count: Cardinal; Offset: Cardinal): Cardinal of object;
  TFuseBinding = Class(TObject)
  Private
    fuse_oper : TOperations;
    fFuseReadDirProc: TFuseReadDirProc;
    fFuseGetAttrProc: TFuseGetAttrProc;
    fFuseOpenProc: TFuseOpenProc;
    fFuseReadProc: TFuseReadProc;
    function oper_readdir(aNameC : PChar; aBuffer : Pointer; filler : TDirectoryFiller; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer;
    function oper_getattr(aNameC : PChar; aSTAT : TStatP) : Integer;
    function oper_open(aNameC : PChar; aFileInfo : TFileInfoP): Integer;
    function oper_read(aNameC : PChar; aBuffer : Pointer; aBufferSize : size_t; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer;
  Public
    Constructor Create;
    Destructor Destroy; override;
    Function fuse_main: Integer;
  Published
    Property FuseReadDirProc: TFuseReadDirProc read fFuseReadDirProc write fFuseReadDirProc;
    Property FuseGetAttrProc: TFuseGetAttrProc read fFuseGetAttrProc write fFuseGetAttrProc;
    Property FuseOpenProc: TFuseOpenProc read fFuseOpenProc write fFuseOpenProc;
    Property FuseReadProc: TFuseReadProc read fFuseReadProc write fFuseReadProc;
  End;

//helper functions

//function fileAttribsFromMode(FileType: TFileType; mode: Integer): Cardinal;

implementation

Uses libc, Strings, BaseUNIX;

const
  hello_path : String = '/hello';
  hello_str : String = 'Hello World!'#10;
Var
  FuseGlobalObject : TFuseBinding;

{function fileAttribsFromMode(FileType: TFileType; mode: Integer): Cardinal;
begin
  case FileType of
    ftFile : Result := S_IFREG or mode;
    ftDirectory : Result := S_IFDIR or mode;
  else
    Result := -1
  end
end;
}
procedure createCString(Var CString: PChar; aString: String);
Begin
End;

function global_oper_readdir(aNameC : PChar; aBuffer : Pointer; filler : TDirectoryFiller; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer; cdecl;
begin
  Result := FuseGlobalObject.oper_readdir(aNameC,aBuffer,filler,aFileOffset,aFileInfo)
end;

function global_oper_getattr(aNameC : PChar; aSTAT : TStatP) : Integer; cdecl;
begin
  Result := FuseGlobalObject.oper_getattr(aNameC, aSTAT)
end;

function global_oper_open(aNameC : PChar; aFileInfo : TFileInfoP) : Integer; cdecl;
begin
  Result := FuseGlobalObject.oper_open(aNameC,aFileInfo)
end;

function global_oper_read(aNameC : PChar; aBuffer : Pointer; aBufferSize : size_t; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer; cdecl;
begin
  Result := FuseGlobalObject.oper_read(aNameC,aBuffer,aBufferSize,aFileOffset,aFileInfo)
end;

Constructor TFuseBinding.Create;
Begin
  FuseGlobalObject := Self;
  with fuse_oper do
  begin
    getattr     := @global_oper_getattr;//hello_getattr;
    readlink    := nil;
    getdir      := nil;
    mknod       := nil;
    mkdir       := nil;
    unlink      := nil;
    rmdir       := nil;
    symlink     := nil;
    rename      := nil;
    link        := nil;
    chmod       := nil;
    chown       := nil;
    truncate    := nil;
    utime       := nil;
    open        := @global_oper_open;//hello_open;
    read        := @global_oper_read;//hello_read;
    write       := nil;
    statfs      := nil;
    flush       := nil;
    release     := nil;
    fsync       := nil;
    setxattr    := nil;
    getxattr    := nil;
    listxattr   := nil;
    removexattr := nil;
    opendir     := nil;
    readdir     := @global_oper_readdir;//hello_readdir;
    releasedir  := nil;
    fsyncdir    := nil;
    init        := nil;
    destroy     := nil;
    access      := nil;
    create      := nil;
    ftruncate   := nil;
    fgetattr    := nil;
    lock        := nil;
    utimens     := nil;
    bmap        := nil
  End
End;

function TFuseBinding.oper_readdir(aNameC : PChar; aBuffer : Pointer; filler : TDirectoryFiller; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer;
Var
  DirList : TStringList;
  DotDotDot : Boolean;
  I : Integer;
  S : String;
  P : PChar;
begin
  DotDotDot := False;
  If Assigned(fFuseReadDirProc) then
  Begin
    DirList := TStringList.Create;
    If (not fFuseReadDirProc(String(aNameC),DirList,DotDotDot)) then
    Begin
      Result := -ESysENOENT;
      Exit
    End
  end;
  If DotDotDot then
  Begin
    filler(aBuffer, '.', nil, 0);
    filler(aBuffer, '..', nil, 0);
  End;
  If Assigned(fFuseReadDirProc) then
  Begin
    For I := 0 to DirList.Count-1 do
      If Length(DirList[0]) > 0 then
      Begin
        S := DirList[I];
        P := @S[1];
        filler(aBuffer, P, nil, 0)
      End
  End;
  Result := 0
end;

function TFuseBinding.oper_getattr(aNameC : PChar; aSTAT : TStatP) : Integer;
var
  aName : String;
  ft : TFileType;
  Size, Mode, Links : Cardinal;
begin
  Result := 0;

  aName := aNameC;

  FillChar(aStat^, Sizeof(TStat), 0);
  If Assigned(fFuseGetAttrProc) then
  Begin
    if not fFuseGetAttrProc(String(aNameC),ft,size,links,mode) then
      Result := -ESysENOENT
  End
  else If aName = '/' then
  begin
    aSTAT^.st_mode := S_IFDIR or 493; // 0755;
    aSTAT^.st_nlink := 2;
    Exit
  end
  else
  Begin
    Result := -ESysENOENT;
    Exit
  End;
  Case ft of
    ftDirectory : aSTAT^.st_mode := S_IFDIR or mode;
    ftFile : aSTAT^.st_mode := S_IFREG or mode;
  End;
  aSTAT^.st_nlink := links;
  aSTAT^.size := size;
end;

function TFuseBinding.oper_open(aNameC : PChar; aFileInfo : TFileInfoP) : Integer;
var
  aName : String;
  Reason: TOpenFailReason;
begin
  aName := aNameC;
  Reason := ofNotSpecified;
  If Assigned(fFuseOpenProc) then
    If fFuseOpenProc(AName,aFileInfo^.flags,Reason) then
      Result := 0
    else
      Case Reason of
        ofNotSpecified, ofNonExistant : Result := -ESysENOENT;
        ofAccessDenied : Result := -ESysEACCES;
      End
  else
    Result := -ESysENOENT
end;

function TFuseBinding.oper_read(aNameC : PChar; aBuffer : Pointer; aBufferSize : size_t; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer;
var
  len : size_t;
  aName : String;
  Buffer: Array Of Byte;
begin
  aName := aNameC;
  If not Assigned(fFuseReadProc) then
  Begin
    Result := -ESysENOENT;
    Exit
  End;
  SetLength(Buffer, aBufferSize);
  FillChar(Buffer,aBufferSize,0);
  Result := fFuseReadProc(aName, Buffer, aBufferSize, aFileOffset);
  If Result > 0 then
    If Result < aBufferSize then
      aBufferSize := 0
    else
      memcpy(ABuffer, @Buffer, Result)
end;

Destructor TFuseBinding.Destroy;
Begin
  FuseGlobalObject := nil;
  inherited Destroy;
End;

Function TFuseBinding.fuse_main: Integer;
Begin
  fuse.fuse_main(argc, argv, @fuse_oper, SizeOf(fuse_oper), nil)
End;

end.

