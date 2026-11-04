#define DrvFATBlkClean ReferenceFATClean
#define DrvFATBlkSet ReferenceFATSet
#define ClusNumNext ReferenceClusNext
#define FAT32FreeClusUntil ReferenceFATFreeUntil
#define FAT32FreeClus ReferenceFATFree
#define FAT32ChainOverlap ReferenceFATOverlap
#define FAT32AllocClus ReferenceFATAlloc
#define FAT32AllocContiguousClus ReferenceFATContiguous
#include "/Kernel/BlkDev/DriveFATCacheCore.HC"
#include "/Kernel/BlkDev/ClusNextCore.HC"
#include "/Kernel/BlkDev/FATAllocationCore.HC"
U0 FATReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 FATAllocationContract()
{
  CDrv dv;CDrv *saved=blkdev.let_to_drv[25];CBlkDev bd;I64 a,b,i;U32 *fat1,*fat2;Bool caught=FALSE;
  if(sizeof(CFAT32Boot)!=512||sizeof(CFAT32FileInfoSect)!=512||offset(CFAT32Boot.signature)!=510||offset(CFAT32FileInfoSect.most_recently_alloced)!=492)throw('FATT',TRUE);
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.drv_let='Z';dv.fs_type=FSt_FAT32;
  dv.bd=&bd;dv.size=512;dv.spc=1;dv.data_area=10;dv.root_clus=2;
  dv.fat1=2;dv.fat2=6;dv.file_system_info_sect=1;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;
  bd.first_drv_let='Z';bd.max_blk=511;bd.blk_size=512;
  bd.RAM_dsk=CAlloc(512*512);dv.fis=CAlloc(512);dv.cur_fat_blk=CAlloc(512);
  blkdev.let_to_drv[25]=&dv;
  fat1=bd.RAM_dsk+2*512;fat2=bd.RAM_dsk+6*512;
  fat1[0]=0x0FFFFFF8;fat1[1]=0x0FFFFFFF;fat1[2]=0x0FFFFFFF;
  fat1[3]=fat1[4]=fat1[6]=0x0FFFFFFF;
  MemCpy(fat2,fat1,4*512);MemCpy(dv.cur_fat_blk,fat1,512);
  dv.fis->most_recently_alloced=125;
  a=FAT32AllocClus(&dv,0,3);
  if(a!=126||fat1[126]!=127||fat1[127]!=128||fat1[128]!=0x0FFFFFFF)throw('FAT1',TRUE);
  if(MemCmp(fat1,fat2,4*512)||dv.fis->most_recently_alloced!=128||dv.fis->free_clus!=0xFFFFFFFF)throw('FAT2',TRUE);
  if(MemCmp(bd.RAM_dsk+512,dv.fis,512)||ClusNumNext(&dv,a,2)!=128)throw('FAT3',TRUE);
  FAT32FreeClusUntil(&dv,a,127);
  if(fat1[126]||fat2[126]||fat1[127]!=128||fat1[128]!=0x0FFFFFFF)throw('FAT4',TRUE);
  FAT32FreeClus(&dv,127);
  if(fat1[127]||fat1[128]||MemCmp(fat1,fat2,4*512))throw('FAT5',TRUE);
  b=FAT32AllocContiguousClus(&dv,3);
  if(b!=7||fat1[7]!=8||fat1[8]!=9||fat1[9]!=0x0FFFFFFF||MemCmp(fat1,fat2,4*512))throw('FAT6',TRUE);
  if(FAT32ChainOverlap(&dv,7,8)!=8||FAT32ChainOverlap(&dv,7,2)!=INVALID_CLUS)throw('FAT7',TRUE);
  FAT32FreeClus(&dv,b);
  dv.fis->most_recently_alloced=500;
  a=FAT32AllocClus(&dv,0,1);
  if(a!=5||fat1[5]!=0x0FFFFFFF||MemCmp(fat1,fat2,4*512))throw('FAT8',TRUE);
  FAT32FreeClus(&dv,a);
  if(FAT32AllocClus(&dv,0,0)!=0x0FFFFFFF||FAT32AllocContiguousClus(&dv,0)!=0x0FFFFFFF)throw('FAT9',TRUE);
  a=FAT32AllocClus(&dv,0,1);b=FAT32AllocClus(&dv,a,2);
  if(ClusNumNext(&dv,a)!=b||ClusNumNext(&dv,b,2)!=INVALID_CLUS||MemCmp(fat1,fat2,4*512))throw('FATC',TRUE);
  FAT32FreeClus(&dv,a);
  if(!DrvLock(&dv))throw('FATL',TRUE);
  a=FAT32AllocContiguousClus(&dv,2);FAT32FreeClus(&dv,a);
  if(DrvLock(&dv))throw('FATA',TRUE);
  DrvUnlock(&dv);
  DrvFATBlkClean(&dv);
  //Contiguous allocation can use cluster 501; chained allocation wraps before it.
  for(i=1;i<502;i++)fat1[i]=0x0FFFFFFF;
  MemCpy(fat2,fat1,4*512);MemCpy(dv.cur_fat_blk,fat1,512);dv.cur_fat_blk_num=0;
  dv.fis->most_recently_alloced=500;
  try FAT32AllocClus(&dv,0,1);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught||!DrvLock(&dv))throw('FATB',TRUE);
  DrvUnlock(&dv);
  caught=FALSE;
  try FAT32AllocContiguousClus(&dv,1);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught||!DrvLock(&dv))throw('FATD',TRUE);
  DrvUnlock(&dv);
  Free(dv.cur_fat_blk);Free(dv.fis);Free(bd.RAM_dsk);
  blkdev.let_to_drv[25]=saved;
}
FATAllocationContract;
FATReport("PASS private RAM FAT32 allocation\n");
FATReport("DONE FAT32 allocation\n");
