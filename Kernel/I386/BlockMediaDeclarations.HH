#ifndef I386_BLOCK_MEDIA_DECLARATIONS_INCLUDED
#define I386_BLOCK_MEDIA_DECLARATIONS_INCLUDED
#include "/Kernel/FileUtilityFlags.HH"
#include "/Kernel/BlkDev/DirContextTypes.HH"
#include "/Kernel/BlkDev/FATMediaTypes.HH"
#include "/Kernel/BlkDev/ISODescriptorTypes.HH"
extern Bool BlkRead(CDrv *dv,U8 *buf,I64 blk,I64 cnt);
extern Bool BlkWrite(CDrv *dv,U8 *buf,I64 blk,I64 cnt);
extern U0 BlkWriteZero(CDrv *dv,I64 blk,I64 cnt);
extern Bool BlkDevInit(CBlkDev *bd);
extern U0 DrvFATBlkAlloc(CDrv *dv);
extern U0 DrvFATBlkClean(CDrv *dv,I64 fat_sel=3);
extern U0 DrvFATBlkSet(CDrv *dv,I64 c,I64 fat_sel=3);
extern U0 RedSeaFreeLstBuild(CDrv *dv);
extern U0 RedSeaFreeClus(CDrv *dv,I64 c,I64 cnt);
extern I64 RedSeaAllocClus(CDrv *dv,I64 cnt);
extern U0 RedSeaInit(CDrv *dv);
extern Bool RedSeaValidate(U8 drv_let);
extern U0 RedSeaFmt(U8 drv_let,Bool quick=TRUE);
extern U0 FAT32FreeClusUntil(CDrv *dv,I64 c,I64 stop);
extern U0 FAT32FreeClus(CDrv *dv,I64 c);
extern I64 FAT32AllocClus(CDrv *dv,I64 c,I64 cnt);
extern I64 FAT32AllocContiguousClus(CDrv *dv,I64 cnt);
extern I64 ClusNumNext(CDrv *dv,I64 c,I64 cnt=1);
extern I64 ClusAlloc(CDrv *dv,I64 c=0,I64 cnt=1,Bool contiguous=FALSE);
extern I64 ClusBlkRead(CDrv *dv,U8 *buf,I64 c,I64 blks);
extern I64 ClusBlkWrite(CDrv *dv,U8 *buf,I64 c,I64 blks);
extern I64 ClusRead(CDrv *dv,U8 *buf,I64 c,I64 cnt);
extern I64 ClusWrite(CDrv *dv,U8 *buf,I64 c,I64 cnt);
extern Bool RedSeaFileFind(CDrv *dv,I64 cur_dir_clus,U8 *name,CDirEntry *_res,I64 fuf_flags=0);
extern Bool FAT32FileFind(CDrv *dv,I64 cur_dir_clus,U8 *name,CDirEntry *_res,I64 fuf_flags=0);
extern I64 Name2DirClus(CDrv *dv,U8 *dirname);
extern I64 Name2ParentDirClus(CDrv *dv,U8 *dirname);
extern Bool RedSeaDirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain);
extern Bool FAT32DirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain);
extern I64 RedSeaFilesDel(CDrv *dv,U8 *cur_dir,U8 *mask,I64 flags,Bool del_dir,Bool print_msg);
extern I64 FAT32FilesDel(CDrv *dv,U8 *cur_dir,U8 *mask,I64 flags,Bool del_dir,Bool print_msg);
extern Bool DirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain=TRUE);
extern U0 DirContextDel(CDirContext *dirc,Bool restore=TRUE);
extern CDirContext *DirContextNew(U8 *mask,Bool make_mask=FALSE,Bool make_dirs=FALSE,Bool no_mask=FALSE);
extern I64 Del(U8 *mask,Bool make_mask=FALSE,Bool del_dir=FALSE,Bool print_msg=TRUE);
extern CFile *FOpen(U8 *filename,U8 *flags,I64 cnt=0);
extern U0 FClose(CFile *f);
extern Bool FBlkRead(CFile *f,U8 *buf,I64 blk=FFB_NEXT_BLK,I64 cnt=1);
extern Bool FBlkWrite(CFile *f,U8 *buf,I64 blk=FFB_NEXT_BLK,I64 cnt=1);
extern Bool ISOInit(CDrv *dv,I64 blk);
extern U0 DskCacheInvalidate(CDrv *dv);
extern U0 DskChg(U8 drv_let=0);
extern Bool Drv(U8 drv_let);
extern U0 NativeDriveCacheHandoff(CDrv *dv);
extern CDirEntry *RedSeaFilesFind(U8 *mask,I64 flags,CDirEntry *parent=NULL);
extern CDirEntry *FAT32FilesFind(U8 *mask,I64 flags,CDirEntry *parent=NULL,I64 *dir_size=NULL);
extern CDirEntry *FilesFind(U8 *mask,I64 flags=0);
extern Bool IsDir(U8 *dirname);
extern Bool CopySingle(U8 *source,U8 *target);
extern Bool Copy(U8 *source,U8 *target=".");
extern Bool Move(U8 *source,U8 *target);
extern U0 FAT32Fmt(U8 drive,Bool quick=TRUE);
extern U0 FAT32Init(CDrv *dv);
extern U0 BlkDevDel(CBlkDev *bd);
extern I64 BlkDevAdd(CBlkDev *bd,I64 prt_num=I64_MIN,Bool whole_drv=FALSE,Bool make_free=FALSE);
extern U0 Unmount(U8 drive=0);
extern U8 MountFile(U8 *filename);
extern U8 *RedSeaFileRead(CDrv *dv,U8 *cur_dir,U8 *filename,I64 *size,I64 *attr);
extern U8 *FAT32FileRead(CDrv *dv,U8 *cur_dir,U8 *filename,I64 *size,I64 *attr);
extern Bool RedSeaCd(U8 *name,I64 cur_dir_clus);
extern Bool FAT32Cd(U8 *name,I64 cur_dir_clus);
extern I64 RedSeaFileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buffer,I64 size,CDate datetime,I64 attr);
extern I64 FAT32FileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buffer,I64 size,CDate datetime,I64 attr);
extern Bool RedSeaMkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt);
extern Bool FAT32MkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt);
#endif
