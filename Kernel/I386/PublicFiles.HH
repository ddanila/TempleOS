#ifndef I386_PUBLIC_FILES_INCLUDED
#define I386_PUBLIC_FILES_INCLUDED
#include "/Kernel/DateTypes.HH"
#include "/Kernel/FileMaskTypes.HH"
#include "/Kernel/BlkDev/FreeListTypes.HH"
#include "/Kernel/BlkDev/DriveTypes.HH"
#include "/Kernel/BlkDev/DirContextTypes.HH"
#include "/Kernel/DirEntryTypes.HH"
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/BlkDev/CFileTypes.HH"
#include "/Kernel/BlkDev/BlockDevTypes.HH"
#include "/Kernel/BlkDev/BlockSize.HH"
#include "/Kernel/BlkDev/BlockGlobalsTypes.HH"
public _extern _FILES_FIND_MATCH Bool FilesFindMatch(U8 *test_name,U8 *files_find_mask,I64 fuf_flags=0);
public _extern _WILD_MATCH Bool WildMatch(U8 *test_str,U8 *wild_str);
public _extern _BLOCK_DEV_NEXT_FREE_SLOT CBlkDev *BlkDevNextFreeSlot(U8 first_drv_let,I64 type);
public _extern _LET_TO_DRV CDrv *Let2Drv(U8 drv_let=0,Bool except=TRUE);
public _extern _BLOCK_DEV_CHECK CBlkDev *BlkDevChk(CBlkDev *bd,Bool except=TRUE);
public _extern _LET_TO_BLOCK_DEV CBlkDev *Let2BlkDev(U8 drv_let=0,Bool except=TRUE);
public _extern _DRV_IS_WRITABLE CBlkDev *DrvIsWritable(U8 drv_let=0,Bool except=FALSE);
public _extern _BLOCK_DEV_LOCK Bool BlkDevLock(CBlkDev *bd);
public _extern _BLOCK_DEV_UNLOCK Bool BlkDevUnlock(CBlkDev *bd,Bool rst=FALSE);
public _extern _DRV_MAP Bool DrvMap(U8 drv_let,CDrv *dv);
public _extern _DRV_DEL U0 DrvDel(CDrv *dv);
public _extern _DRV_MAKE_FREE_SLOT CDrv *DrvMakeFreeSlot(U8 drv_let);
public _extern _DRV_NEXT_FREE_LET U8 DrvNextFreeLet(U8 first_drv_let='C');
public _extern _DRV_LOCK Bool DrvLock(CDrv *dv);
public _extern _DRV_UNLOCK Bool DrvUnlock(CDrv *dv,Bool rst=FALSE);
public _extern _DRVS_RELEASE U0 DrvsRelease();
public _extern _BLOCK_DEVS_RELEASE U0 BlkDevsRelease();
public _extern _DRV_CHECK CDrv *DrvChk(CDrv *dv,Bool except=TRUE);
public _extern _DRV_TO_LET U8 Drv2Let(CDrv *dv=NULL);
public _extern _LET_TO_LET U8 Let2Let(U8 drv_let=0);
public _extern _LET_TO_BLOCK_DEV_TYPE I64 Let2BlkDevType(U8 drv_let);
public _extern _DRV_TEXT_ATTR_GET U8 DrvTextAttrGet(U8 drv_let=0);
#include "/Kernel/DirEntryTypes.HH"
#include "/Kernel/FileFindFlags.HH"
public _extern _FILE_NAME_CHK Bool FileNameChk(U8 *filename);
public _extern _FILE_NAME_ABS U8 *FileNameAbs(U8 *filename,I64 fuf_flags=0);
public _extern _FILE_FIND Bool FileFind(U8 *filename,CDirEntry *_de=0,I64 flags=0);
public _extern _COPY_SINGLE_Z Bool CopySingleZ(U8 *f1,U8 *f2);
public _extern _DIR_ENTRY_DEL U0 DirEntryDel(CDirEntry *entry);
public _extern _DIR_ENTRY_DEL2 U0 DirEntryDel2(CDirEntry *entry);
public _extern _DIR_TREE_DEL U0 DirTreeDel(CDirEntry *entry);
public _extern _DIR_TREE_DEL2 U0 DirTreeDel2(CDirEntry *entry);
public _extern _DIR_FILES_FLATTEN CDirEntry *DirFilesFlatten(CDirEntry *entry,CDirEntry **result,I64 flags);
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
public _extern _CLUS_TO_BLOCK I64 Clus2Blk(CDrv *dv,I64 c);
public _extern _FSIZE I64 FSize(CFile *f);
public _extern _FILE_READ U8 *FileRead(U8 *filename,I64 *_size=0,I64 *_attr=0);
public _extern _CD Bool Cd(U8 *dirname=0,Bool make_dirs=FALSE);
public _extern _FILE_EXT_DOT U8 *FileExtDot(U8 *src);
public _extern _FILE_EXT_REM U8 *FileExtRem(U8 *src,U8 *dst=NULL);
public _extern _EXT_CHG U8 *ExtChg(U8 *filename,U8 *extension);
public _extern _IS_DOT_C Bool IsDotC(U8 *filename);
public _extern _IS_DOT_Z Bool IsDotZ(U8 *filename);
public _extern _TOGGLE_ZOR_NOT_Z U8 *ToggleZorNotZ(U8 *name);
public _extern _EXT_DFT U8 *ExtDft(U8 *filename,U8 *extension);

public _extern _DIR_CUR U8 *DirCur(CTask *task=NULL,CTask *mem_task=NULL);
#endif
