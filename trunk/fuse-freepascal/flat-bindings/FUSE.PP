{
FUSE Freepascal bindings.
Copyright (C) 2008 Danny Milosavljevic <danny_milo@yahoo.com>

This program is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

}
unit FUSE;

{$ASSERTIONS ON}
{$MODE OBJFPC}

{$PACKRECORDS C}

interface
uses BaseUNIX, UNIXtype;
//uses BaseUNIX, UNIX, libc;

type
  TStatVFS = record { C } // 64 bit.
    f_bsize : Cardinal;
    f_frsize : Cardinal;

    f_blocks, f_bfree, f_bavail : Int64;

    f_files, f_ffree, f_favail : Int64;
    f_fsid : Cardinal;
    __f_unused : Integer; { junk }
    f_flag : Cardinal;
    f_namemax : Cardinal;
    __f_spare_1 : Integer;
    __f_spare_2 : Integer;
    __f_spare_3 : Integer;
    __f_spare_4 : Integer;
    __f_spare_5 : Integer;
    __f_spare_6 : Integer;
  end;
  TStatVFSP = ^TStatVFS;

  TFLock = record { C } // 64 bit.
    l_type : Shortint;
    l_whence : Shortint;
    l_start : off_t;
    l_len : off_t;
    l_pid : Integer; // int32.
  end;
  TFLockP = ^TFLock;
  {
  TStat = record // C // 64 bit.
    __dev_t st_dev;			/* Device.  */
    __pad1 : Cardinal;

    __ino_t __st_ino;			/* 32bit file serial number.	*/
    __mode_t st_mode;			/* File mode.  */
    __nlink_t st_nlink;			/* Link count.  */
    __uid_t st_uid;			/* User ID of the file's owner.	*/
    __gid_t st_gid;			/* Group ID of the file's group.*/
    __dev_t st_rdev;			/* Device number, if device.  */
    __pad2 : Cardinal;
    st_size : off_t;			/* Size of file, in bytes.  */
    __blksize_t st_blksize;		/* Optimal block size for I/O.  */

    st_blocks : uint64_t;		/* Number 512-byte blocks allocated. */
    st_atim, st_mtim, st_ctim : TTimespec;
    __ino64_t st_ino;			/* File serial number.		*/
  end;}
  TStatP = ^TStat;
  TFUSEP = type Pointer;

{ beware: use 64-bit stat structs! }

type
  uint64_t = Int64;
  //off_t = Int64;
  TMode = mode_t;
  TFileInfoFlags = (fDirectIO, fKeepCache, fFlush);

  TFileInfo = record { C }
    flags : Integer;
    fh_old : Cardinal; { unsigned long, don't use. }
    writepage : Integer; { bool }
    operationFlags : TFileInfoFlags;
    FH : Int64; { filesystem can fill this }
    LockOwner : Int64;
  end;
  TFileInfoP = ^TFileInfo;

  TDirectoryFiller = function(aBuffer : Pointer; aName : PChar; aSTAT : TStatP; aFileOffset : off_t) : Integer; cdecl;

  TConnectionInformation = record { C }
    ProtocolMajor : Cardinal;
    ProtocolMinor : Cardinal;
    BASYNCRead : Cardinal;
    MaximumWriteSize : Cardinal;
    MaximumReadAheadSize : Cardinal;
    Reserved1 : Cardinal;
    Reserved2 : Cardinal;
    Reserved3 : Cardinal;
    Reserved4 : Cardinal;
    Reserved5 : Cardinal;
    Reserved6 : Cardinal;
    Reserved7 : Cardinal;
    Reserved8 : Cardinal;
    Reserved9 : Cardinal;
    Reserved10 : Cardinal;
    Reserved11 : Cardinal;
    Reserved12 : Cardinal;
    Reserved13 : Cardinal;
    Reserved14 : Cardinal;
    Reserved15 : Cardinal;
    Reserved16 : Cardinal;
    Reserved17 : Cardinal;
    Reserved18 : Cardinal;
    Reserved19 : Cardinal;
    Reserved20 : Cardinal;
    Reserved21 : Cardinal;
    Reserved22 : Cardinal;
    Reserved23 : Cardinal;
    Reserved24 : Cardinal;
    Reserved25 : Cardinal;
    Reserved26 : Cardinal;
    Reserved27 : Cardinal;
  end;
  TConnectionInformationP = ^TConnectionInformation;
  
  TOperations = record { C }
    getattr     : function(aName : PChar; aSTAT : TStatP) : Integer; cdecl;
    readlink    : function(aName : PChar; aOutLink : PChar; aOutLinkSize: size_t) : Integer; cdecl;
    getdir      : function(aName : PChar; aDirectoryHandle : Pointer; aOutEntry : TDirectoryFiller) : Integer; cdecl;
    mknod       : function(aName : PChar; aMode : TMode; aDevice : dev_t) : Integer; cdecl;
    mkdir       : function(aName : PChar; aMode : TMode) : Integer; cdecl;
    unlink      : function(aName : PChar) : Integer; cdecl;
    rmdir       : function(aName : PChar) : Integer; cdecl;
    symlink     : function(aName, aNewName : PChar) : Integer; cdecl;
    rename      : function(aName, aNewName : PChar) : Integer; cdecl;
    link        : function(aName, aNewName : PChar) : Integer; cdecl;
    chmod       : function(aName : PChar; aMode : TMode) : Integer; cdecl;
    chown       : function(aName : PChar; aUID : uid_t; aGID : gid_t) : Integer; cdecl;
    truncate    : function(aName : PChar; aSize : off_t) : Integer; cdecl;
    utime       : function(aName : PChar; aTime : Putimbuf) : Integer; cdecl;
    open        : function(aName : PChar; aFileInfo : TFileInfoP) : Integer; cdecl;
    read        : function(aName : PChar; aBuffer : Pointer; aBufferSize : size_t; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer; cdecl;
    write       : function(aName : PChar; aBuffer : Pointer; aBufferSize : size_t; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer; cdecl;
    statfs      : function(aName : PChar; aOutVFSSTAT : TStatVFSP) : Integer; cdecl;
    flush       : function(aName : PChar; aFileInfo : TFileInfoP) : Integer; cdecl;
    release     : function(aName : PChar; aFileInfo : TFileInfoP) : Integer; cdecl;
    fsync       : function(aName : PChar; aBDataOnly : Integer; aFileInfo : TFileInfoP) : Integer; cdecl;
    setxattr    : function(aName : PChar; aKey : PChar; aValue : PChar; aValueSize : size_t; flags : Integer) : Integer; cdecl;
    getxattr    : function(aName : PChar; aKey : PChar; aOutValue : PChar; aOutValueSize : size_t) : Integer; cdecl;
    listxattr   : function(aName : PChar; aOutList : {list of}PChar; aOutListSize : size_t) : Integer; cdecl;
    removexattr : function(aName : PChar; aKey : PChar) : Integer; cdecl;
    opendir     : function(aName : PChar; aFileInfo : TFileInfoP) : Integer; cdecl;
    readdir     : function(aName : PChar; aBuffer : Pointer; aOutEntry : TDirectoryFiller; aFileOffset : off_t; aFileInfo : TFileInfoP) : Integer; cdecl;
    releasedir  : function(aName : PChar; aFileInfo : TFileInfoP) : Integer; cdecl;
    fsyncdir    : function(aName : PChar; aBDataOnly : Integer; aFileInfo : TFileInfoP) : Integer; cdecl;
    init        : function(aConnectionInfo : TConnectionInformationP) : Pointer{UserData}; cdecl;
    destroy     : procedure(aUserData : Pointer); cdecl;
    access      : function(aName : PChar; aMode : Integer) : Integer; cdecl;
    create      : function(aName : PChar; aMode : TMode; aFileInfo : TFileInfoP) : Integer; cdecl;
    ftruncate   : function(aName : PChar; aSize : off_t; aFileInfo : TFileInfoP) : Integer; cdecl;
    fgetattr    : function(aName : PChar; aOutStat : TStatP; aFileInfo : TFileInfoP) : Integer; cdecl;
    lock        : function(aName : PChar; aFileInfo : TFileInfoP; aCMD : Integer; aLock : TFLockP) : Integer; cdecl;
    utimens     : function(aName : PChar; aTime : array of timespec) : Integer; cdecl;
    bmap        : function(aName : PChar; aBlockSize : size_t; idx : uint64_t) : Integer; cdecl;
  end;
  TOperationsP = ^TOperations;
  TSessionP = type Pointer; // record;
  TChannelP = type Pointer;
  TChannelPP = ^TChannelP;
  TRequestP = type Pointer; // ^TRequest;
  
function fuse_main(aARGC : Integer; aARGV: PPChar; aOperations : TOperationsP; aOperationsSize : size_t; aUserData : Pointer) : Integer;

// if you want to build your own fuse_main, use these:

function fuse_get_session(aFUSE : TFUSEP) : TSessionP; cdecl;
procedure fuse_session_process(aSession : TSessionP; aBuffer : Pointer; aLength : size_t; aChannel : TChannelP); cdecl;
function fuse_chan_recv(aChannel : TChannelPP; aBuffer : Pointer; aSize : size_t) : cint; cdecl;
function fuse_session_exited(aSession : TSessionP) : cint; cdecl;
procedure fuse_session_reset(aSession : TSessionP); cdecl;
function fuse_chan_bufsize(aChannel : TChannelP) : size_t; cdecl;
// before the event loop:
function fuse_setup(aARGC : cint; aARGV : PPChar; aOperations : TOperationsP; aOperationsSize : size_t; aMountpoint : Pointer{will point to a PChar string}; aMultithreaded : Pcint; aUserData : Pointer) : TFUSEP; cdecl;
// after the event loop:
procedure fuse_teardown(aFUSE : TFUSEP; aMountpoint : Pointer{PChar, will be freed by the function}); cdecl;
    
implementation

const
  FUSELIBFile = 'libfuse.so.2';

function fuse_main_real(aARGC : Integer; aARGV: PPChar; aOperations : TOperationsP; aOperationsSize : size_t; aUserData : Pointer) : Integer; cdecl; external FUSELIBFile;

function fuse_main(aARGC : Integer; aARGV: PPChar; aOperations : TOperationsP; aOperationsSize : size_t; aUserData : Pointer) : Integer;
begin
  Result := fuse_main_real(aARGC, aARGV, aOperations, aOperationsSize, aUserData);
end;

function fuse_get_session(aFUSE : TFUSEP) : TSessionP; cdecl; external FUSELIBFile;

procedure fuse_session_process(aSession : TSessionP; aBuffer : Pointer; aLength : size_t; aChannel : TChannelP); cdecl; external FUSELIBFile;
function fuse_chan_recv(aChannel : TChannelPP; aBuffer : Pointer; aSize : size_t) : cint; cdecl; external FUSELIBFile;
function fuse_session_exited(aSession : TSessionP) : cint; cdecl; external FUSELIBFile;
procedure fuse_session_reset(aSession : TSessionP); cdecl; external FUSELIBFile;
function fuse_chan_bufsize(aChannel : TChannelP) : size_t; cdecl; external FUSELIBFile;

// before the event loop:
function fuse_setup(aARGC : cint; aARGV : PPChar; aOperations : TOperationsP; aOperationsSize : size_t; aMountpoint : Pointer{will point to a PChar string}; aMultithreaded : Pcint; aUserData : Pointer) : TFUSEP; cdecl; external FUSELIBFile;

// after the event loop:
procedure fuse_teardown(aFUSE : TFUSEP; aMountpoint : Pointer{PChar, will be freed}); cdecl; external FUSELIBFile;

initialization

  // 32 bit X86:
  assert(Sizeof(TFileInfo) = 32);
  assert(Sizeof(TOperations) = 152);
  assert(Sizeof(TFileInfoFlags) = 4);
  assert(Sizeof(off_t) = 8);
  assert(Sizeof(TStat) = 96);
  assert(Sizeof(TStatVFS) = 96);
  assert(Sizeof(TFLock) = 24);
  assert(Sizeof(size_t) = 4); // UNIX size_t.
  assert(Sizeof(TConnectionInformation) = 128);
  
end.
