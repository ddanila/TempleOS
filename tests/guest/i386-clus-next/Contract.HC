I64 CNContract()
{
  CDrv dv;CBlkDev bd;U8 *storage=CAlloc(2048);U32 *fat=CAlloc(512),*sector=storage;
  I64 mask=0;Bool caught;
  MemCpy(&dv,Fs->cur_dv,sizeof(CDrv));MemCpy(&bd,Fs->cur_dv->bd,sizeof(CBlkDev));
  dv.bd=&bd;dv.drv_offset=0;dv.size=4;dv.locked_flags=0;dv.owning_task=NULL;
  dv.fat1=0;dv.fat2=2;dv.cur_fat_blk=fat;dv.cur_fat_blk_num=0;dv.fat_blk_dirty=0;
  bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;bd.RAM_dsk=storage;
  bd.lock_fwding=NULL;bd.locked_flags=0;bd.owning_task=NULL;
  dv.fs_type=FSt_REDSEA;
  if(ClusNumNext(&dv,17,3)==20 && ClusNumNext(&dv,17,0)==17)mask|=1;
  dv.fs_type=FSt_FAT32;fat[2]=3;fat[3]=4;fat[4]=0x0FFFFFFF;
  if(ClusNumNext(&dv,2,2)==4 && ClusNumNext(&dv,2,3)==INVALID_CLUS)mask|=2;
  fat[127]=129;sector[128+1]=130;sector[128+2]=0x0FFFFFFF;
  dv.fat_blk_dirty=1;
  if(ClusNumNext(&dv,127,2)==130 && dv.cur_fat_blk_num==1)mask|=4;
  if(sector[2]==3 && sector[127]==129 && sector[256+2]==3 &&
      sector[256+127]==129 && !dv.fat_blk_dirty)mask|=64;
  if(DrvLock(&dv) && ClusNumNext(&dv,130,1)==INVALID_CLUS &&
      dv.owning_task==Fs && bd.owning_task==Fs && DrvUnlock(&dv))mask|=8;
  dv.fs_type=255;caught=FALSE;
  try ClusNumNext(&dv,2,1);catch {caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}
  if(caught)mask|=16;
  dv.dv_signature=0;caught=FALSE;
  try ClusNumNext(&dv,2,1);catch {caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}
  if(caught)mask|=32;
  Free(fat);Free(storage);return mask;
}
