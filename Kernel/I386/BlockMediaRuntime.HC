//Complete mutually recursive original block/media/stream implementations.
//Public path services still use the retained file provider.
import I64 MemCmp(U8 *left,U8 *right,I64 count);
Bool NativeBlockBreakLock(CTask *task=NULL)
{ if(!task)task=Fs;return I386TaskBreakLock(task); }
Bool NativeBlockBreakUnlock(CTask *task=NULL)
{
  Bool result;
  if(!task)task=Fs;
  result=I386TaskBreakUnlock(task);
  if(task==Fs)I386TaskBreakPoll;
  return result;
}
#define BreakLock NativeBlockBreakLock
#define BreakUnlock NativeBlockBreakUnlock
#define progress1 sys_progresses[0].val
#define progress1_max sys_progresses[0].max
#define progress1_desc sys_progresses[0].desc
#define blkdev console_config->block_globals[0]
#define FAT32_ENTRIES_PER_BLK (BLK_SIZE/sizeof(CFAT32DirEntry))
#define FAT32_ENTRIES_BITS Bsf(FAT32_ENTRIES_PER_BLK)
#include "/Kernel/BlkDev/BlockReadWriteCore.HC"
#include "/Kernel/BlkDev/BlockWriteZeroCore.HC"
#include "/Kernel/BlkDev/DriveFATAllocCore.HC"
#include "/Kernel/BlkDev/DriveFATCacheCore.HC"
#include "/Kernel/BlkDev/RedSeaAllocationCore.HC"
#include "/Kernel/BlkDev/FATAllocationCore.HC"
#include "/Kernel/BlkDev/ClusNextCore.HC"
#include "/Kernel/BlkDev/ClusTransferCore.HC"
#include "/Kernel/BlkDev/RedSeaMediaCore.HC"
#include "/Kernel/BlkDev/ISOInitCore.HC"
#include "/Kernel/BlkDev/RedSeaFileFindCore.HC"
#include "/Kernel/BlkDev/FATFileFindCore.HC"
#include "/Kernel/BlkDev/DirectoryClusterCore.HC"
#include "/Kernel/BlkDev/RedSeaDirectoryMutationCore.HC"
#include "/Kernel/BlkDev/FATDirectoryMutationCore.HC"
#include "/Kernel/BlkDev/DirNewCore.HC"
#include "/Kernel/BlkDev/DriveMediaLifecycleCore.HC"
#include "/Kernel/BlkDev/DskDirContext.HC"
#include "/Kernel/BlkDev/FileDeleteCore.HC"
#include "/Kernel/BlkDev/CFileStreamCore.HC"
#include "/Kernel/BlkDev/BlockDevInitCore.HC"

U0 NativeDriveCacheHandoff(CDrv *dv)
{//Called with the mapped drive owned before the retained provider reads/writes.
  if(dv->fs_type!=FSt_REDSEA)return;
  if(dv->cur_fat_blk) {
    DrvFATBlkClean(dv);
    dv->cur_fat_blk_num=-1;
  } else DrvFATBlkAlloc(dv);
  if(dv->next_free)RedSeaFreeFreeLst(dv);
  if(dv->bd->flags&BDF_READ_CACHE)DskCacheInvalidate2(dv);
}
