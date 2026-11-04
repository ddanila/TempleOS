//Complete original path services for mapped media outside the retained provider.
Bool NativeFileUsesOriginal(U8 *path)
{
  CDrv *drive=Fs->cur_dv;
  if(!console_config || !console_config->files)return FALSE;
  if(path && *path) {
    if(path[1]==':')drive=Let2Drv(*path,FALSE);
    else if(*path=='~')drive=Let2Drv('~',FALSE);
  }
  return drive && drive->dv_signature==DRV_SIGNATURE_VAL &&
    !console_config->files->drive_backend(drive);
}
U8 *AMAllocIdent(U8 *allocation)
{ return MAllocIdent(allocation,I386TaskSelf->owner->root); }
//Aliases apply only to the following complete original mutually recursive bodies.
#define FileRead NativeOriginalFileRead
#define FileWrite NativeOriginalFileWrite
#define FileFind NativeOriginalFileFind
#define Cd NativeOriginalCd
#define DirMk NativeOriginalDirMk
#include "/Kernel/BlkDev/RedSeaReadDirectoryCore.HC"
#include "/Kernel/BlkDev/FATReadDirectoryCore.HC"
#include "/Kernel/BlkDev/RedSeaWriteCore.HC"
#include "/Kernel/BlkDev/FATWriteCore.HC"
#include "/Kernel/BlkDev/RedSeaMakeDirectoryCore.HC"
#include "/Kernel/BlkDev/FATMakeDirectoryCore.HC"
#include "/Kernel/BlkDev/FileReadWriteCore.HC"
#include "/Kernel/BlkDev/FileFindCore.HC"
#include "/Kernel/BlkDev/DirectoryChangeCore.HC"
#include "/Kernel/BlkDev/DirectoryMakeCore.HC"

#define Dir NativeOriginalDir
#include "/Kernel/BlkDev/DirectoryLinksCore.HC"
#include "/Kernel/BlkDev/DirectoryListCore.HC"
