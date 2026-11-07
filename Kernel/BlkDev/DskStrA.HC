#include "/Kernel/BlkDev/FileNames.HC"
#include "/Kernel/BlkDev/FilePaths.HC"

#include "/Kernel/BlkDev/FileExtRemCore.HC"

#include "/Kernel/BlkDev/FilesFindMatchCore.HC"

U0 FilePathTaskContext(CFilePathContext *context)
{
  context->cur_dir=Fs->cur_dir;
  context->home_dir=blkdev.home_dir;
  context->white_space=char_bmp_white_space;
  context->cur_drv=0;
  if(context->cur_dir && *context->cur_dir) context->cur_drv=Drv2Let;
  context->boot_drv=blkdev.boot_drv_let;
}

U8 *DirNameAbs(U8 *_dirname)
{//MAlloc absolute dir string with drv letter.
  CFilePathContext context;
  U8 *work,*res;
  if(!_dirname) _dirname="";
  FilePathTaskContext(&context);
  work=MAlloc(StrLen(_dirname)+2);
  res=MAlloc(FilePathCapacity(_dirname,&context));
  FilePathCopy(work,_dirname);
  FilePathDirWrite(res,work,&context);
  Free(work);
  return res;
}

U8 *FileNameAbsConstruct(U8 *_filename)
{//Absolute filename. Accepts $LK,"FUF_Z_OR_NOT_Z",A="MN:FUF_Z_OR_NOT_Z"$, $LK,"FUF_SCAN_PARENTS",A="MN:FUF_SCAN_PARENTS"$.
  CFilePathContext context;
  U8 *work,*res;
  I64 length;
  if(!_filename) _filename="";
  FilePathTaskContext(&context);
  length=StrLen(_filename);
  work=MAlloc((length+2)*2);
  res=MAlloc(FilePathCapacity(_filename,&context));
  FilePathCopy(work,_filename);
  FilePathFileWrite(res,work,work+length+2,&context);
  Free(work);
  return res;
}
#include "/Kernel/BlkDev/FileNameAbsCore.HC"
U8 *FileNameAbs(U8 *_filename,I64 fuf_flags=0)
{//Absolute filename with original FileFind flag handling.
  return FileNameAbsCore(_filename,fuf_flags,&FileNameAbsConstruct);
}

#include "/Kernel/BlkDev/ExtChgCore.HC"

#include "/Kernel/BlkDev/ExtDftCore.HC"

#include "/Kernel/BlkDev/CdDirEntryCore.HC"

#include "/Kernel/BlkDev/FileNameCheckCore.HC"

#include "/Kernel/BlkDev/ToggleZorNotZCore.HC"

U8 *FileNameTmpTxt()
{//Make pretty-safe tmp filename in home dir.
  return MStrPrint("~/SysTmp%X.DD.Z",GetTSC>>8&0xFFFFFFFF);
}

#include "/Kernel/BlkDev/DirCurCore.HC"

#include "/Kernel/BlkDev/DirFileCore.HC"
