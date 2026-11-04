extern Bool RedSeaValidate(U8 drv_let);
extern U0 RedSeaInit(CDrv *dv);
extern U0 RedSeaFmt(U8 drv_let,Bool quick=TRUE);
extern U0 RedSeaFreeFreeLst(CDrv *dv);
#define DrvFATBlkClean ReferenceFATClean
#define DrvFATBlkSet ReferenceFATSet
#define RedSeaFreeLstBuild ReferenceFreeListBuild
#define RedSeaAllocClus ReferenceRedSeaAlloc
#define RedSeaFreeClus ReferenceRedSeaFree
#include "/Kernel/BlkDev/DriveFATCacheCore.HC"
#include "/Kernel/BlkDev/RedSeaAllocationCore.HC"
U0 MediaReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 RedSeaMediaContract()
{
  CDrv dv;CDrv *saved=blkdev.let_to_drv[25];CBlkDev bd;
  CRedSeaBoot *br;CDirEntry *root;I64 a,b,c,reused,i;Bool caught=FALSE;U8 *bitmap;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.fs_type=FSt_REDSEA;
  dv.bd=&bd;dv.size=128;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;
  bd.first_drv_let='Z';bd.max_blk=127;bd.blk_size=512;bd.init_root_dir_blks=2;
  bd.RAM_dsk=CAlloc(128*512);
  blkdev.let_to_drv[25]=&dv;
  br=bd.RAM_dsk;br->signature=MBR_PT_REDSEA;br->signature2=0xAA55;
  br->sects=128;br->bitmap_sects=1;br->root_clus=3;
  if(!RedSeaValidate('Z'))throw('Media1',TRUE);
  br->signature2=0;
  if(RedSeaValidate('Z'))throw('Media2',TRUE);
  br->signature2=0xAA55;
  if(!DrvLock(&dv))throw('Media3',TRUE);
  RedSeaInit(&dv);
  if(dv.size!=128||dv.data_area!=1||dv.root_clus!=3||dv.fat1!=1||dv.fat2!=1||dv.spc!=1)throw('Media4',TRUE);
  if(!dv.cur_fat_blk||dv.cur_fat_blk_num||dv.fat_blk_dirty||DrvLock(&dv))throw('Media5',TRUE);
  DrvUnlock(&dv);
  RedSeaFmt('Z',TRUE);
  br=bd.RAM_dsk;
  if(!RedSeaValidate('Z')||br->sects!=128||!br->root_clus||br->bitmap_sects!=1)throw('Media6',TRUE);
  root=bd.RAM_dsk+br->root_clus*512-offset(CDirEntry.start);
  if(root->name[0]!='.'||root->name[1]||root->clus!=br->root_clus||root->size!=1024||!(root->attr&RS_ATTR_DIR))throw('Media7',TRUE);
  root(U8 *)+=CDIR_SIZE;
  if(root->name[0]!='.'||root->name[1]!='.'||root->name[2]||root->clus!=br->root_clus)throw('Media8',TRUE);
  a=RedSeaAllocClus(&dv,3);b=RedSeaAllocClus(&dv,5);c=RedSeaAllocClus(&dv,2);
  if(b!=a+3||c!=b+5)throw('Alloc1',TRUE);
  bitmap=bd.RAM_dsk+dv.fat1*512;
  for(i=0;i<10;i++)if(!Bt(bitmap,a+i-dv.data_area))throw('Alloc2',TRUE);
  RedSeaFreeClus(&dv,a,3);reused=RedSeaAllocClus(&dv,2);
  if(reused!=a)throw('Alloc3',TRUE);
  RedSeaFreeClus(&dv,reused,2);RedSeaFreeClus(&dv,b,5);RedSeaFreeClus(&dv,c,2);
  for(i=0;i<10;i++)if(Bt(bitmap,a+i-dv.data_area))throw('Alloc4',TRUE);
  RedSeaFreeFreeLst(&dv);
  if(!DrvLock(&dv))throw('Alloc5',TRUE);
  reused=RedSeaAllocClus(&dv,10);
  if(reused!=a||DrvLock(&dv))throw('Alloc6',TRUE);
  RedSeaFreeClus(&dv,reused,10);
  try RedSeaAllocClus(&dv,0);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught||DrvLock(&dv))throw('Alloc7',TRUE);
  DrvUnlock(&dv);
  RedSeaFreeFreeLst(&dv);Free(dv.cur_fat_blk);Free(bd.RAM_dsk);
  blkdev.let_to_drv[25]=saved;
}
RedSeaMediaContract;
MediaReport("PASS private RAM RedSea allocation\n");
MediaReport("DONE RedSea allocation\n");
