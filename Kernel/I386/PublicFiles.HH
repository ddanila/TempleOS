#ifndef I386_PUBLIC_FILES_INCLUDED
#define I386_PUBLIC_FILES_INCLUDED
#include "/Kernel/DateTypes.HH"
#include "/Kernel/BlkDev/DriveTypes.HH"
#include "/Kernel/BlkDev/BlockDevTypes.HH"
public _extern _DRV_CHECK CDrv *DrvChk(CDrv *dv,Bool except=TRUE);
public _extern _DRV_TO_LET U8 Drv2Let(CDrv *dv=NULL);
public _extern _LET_TO_LET U8 Let2Let(U8 drv_let=0);
public _extern _LET_TO_BLOCK_DEV_TYPE I64 Let2BlkDevType(U8 drv_let);
public _extern _DRV_TEXT_ATTR_GET U8 DrvTextAttrGet(U8 drv_let=0);
#include "/Kernel/DirEntryTypes.HH"
#include "/Kernel/FileFindFlags.HH"
public _extern _FILE_NAME_ABS U8 *FileNameAbs(U8 *filename,I64 fuf_flags=0);
public _extern _FILE_FIND Bool FileFind(U8 *filename,CDirEntry *_de=0,I64 flags=0);
public _extern _FILE_WRITE I64 FileWrite(U8 *filename,U8 *buffer,I64 size,CDate cdt=0,I64 attr=0);
public _extern _DIR_MK Bool DirMk(U8 *filename,I64 entry_cnt=0);
public _extern _DIR I64 Dir(U8 *filename=NULL);
public _extern _ED_DIR Bool EdDir(U8 *directory=NULL);
public _extern _FILE_DEL Bool FileDel(U8 *filename);
public _extern _FILE_RENAME Bool FileRename(U8 *old_filename,U8 *new_filename);
public _extern _DIR_DEL Bool DirDel(U8 *filename);
public _extern _FILE_MOVE Bool FileMove(U8 *old_filename,U8 *new_filename);
//Exact source/module-tree transport between mounted drives; -1 on failure.
//A positive limit stops after that many files for a resumable bounded pass.
public _extern _I386_INSTALL_TREE I64 I386InstallTree(
  U8 *source,U8 *target,I64 limit=0);
public _extern _I386_INSTALL_BOOT Bool I386InstallBoot(U8 *source,U8 *target);
//Install a linked flat-image file with LBA 0 written last on a blank target.
public _extern _I386_INSTALL_BOOT_IMAGE Bool I386InstallBootImage(
  U8 *source,U8 *target,U8 *image_file);
//Bootstrap modules execute before the interactive break service is loaded.
public _extern _I386_BUILD_MODULE I64 I386BuildModule(
  U8 *source,U8 *target,Bool boot_module=FALSE);
//Link six boot modules to a flat file at 0x11000; publication is separate.
public _extern _I386_BUILD_BOOT_IMAGE I64 I386BuildBootImage(
  U8 *kernel_module,U8 *helper_directory,U8 *target);
public _extern _FILE_READ U8 *FileRead(U8 *filename,I64 *_size=0,I64 *_attr=0);
public _extern _CD Bool Cd(U8 *dirname=0,Bool make_dirs=FALSE);
#endif
