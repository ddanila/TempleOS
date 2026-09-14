#ifndef FILE_PATHS_INCLUDED
#define FILE_PATHS_INCLUDED
#include "/Kernel/BlkDev/FileNames.HH"
class CFilePathContext
{
  U8 *cur_dir,*home_dir;
  U32 *white_space;
  U8 cur_drv,boot_drv;
};
//Live borrowed strings and a 256-bit whitespace bitmap. No allocation or task lookup.
//Writers consume mutable work. Output, work and leaf storage must be distinct.
//Output needs FilePathCapacity bytes; work and leaf each need input length plus two.
public extern I64 FilePathCapacity(U8 *name,CFilePathContext *context);
public extern U0 FilePathCopy(U8 *dst,U8 *src);
public extern U8 *FilePathDirWrite(U8 *dst,U8 *work,CFilePathContext *context);
public extern U8 *FilePathFileWrite(U8 *dst,U8 *work,U8 *leaf,CFilePathContext *context);
#endif
