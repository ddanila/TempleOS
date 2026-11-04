U0 HomeSet(U8 *dirname)
{//Change home directory.
  dirname=DirNameAbs(dirname);
  Free(blkdev.home_dir);
  blkdev.home_dir=AStrNew(dirname);
  Free(dirname);
}

#include "/Kernel/BlkDev/DirectoryChangeCore.HC"

#include "/Kernel/BlkDev/IsDirCore.HC"

#include "/Kernel/BlkDev/DirectoryListCore.HC"

#include "/Kernel/BlkDev/DirectoryMakeCore.HC"
