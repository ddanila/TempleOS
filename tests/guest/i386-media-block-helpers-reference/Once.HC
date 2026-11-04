extern U0 DrvFATBlkAlloc(CDrv *dv);
U0 HelperReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MediaBlockHelpersContract()
{
  CDrv dv;CBlkDev bd;I64 i,bytes=2051*512;U8 *cache;
  MemSet(&dv,0,sizeof(CDrv));MemSet(&bd,0,sizeof(CBlkDev));
  dv.dv_signature=DRV_SIGNATURE_VAL;dv.bd=&bd;dv.size=2051;dv.fs_type=FSt_REDSEA;
  bd.bd_signature=BD_SIGNATURE_VAL;bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;
  bd.first_drv_let=Fs->cur_dv->drv_let;bd.blk_size=512;bd.RAM_dsk=MAlloc(bytes);
  MemSet(bd.RAM_dsk,0x5A,bytes);
  if(!DrvLock(&dv))throw('Helper1',TRUE);
  BlkWriteZero(&dv,1,2049);
  for(i=0;i<512;i++)if(bd.RAM_dsk[i]!=0x5A)throw('Helper2',TRUE);
  for(i=512;i<2050*512;i++)if(bd.RAM_dsk[i])throw('Helper3',TRUE);
  for(i=2050*512;i<bytes;i++)if(bd.RAM_dsk[i]!=0x5A)throw('Helper4',TRUE);
  BlkWriteZero(&dv,0,0);
  for(i=0;i<512;i++)if(bd.RAM_dsk[i]!=0x5A)throw('Helper5',TRUE);
  if(DrvLock(&dv))throw('Helper6',TRUE);
  dv.fat1=2;dv.cur_fat_blk=CAlloc(512);dv.cur_fat_blk_num=88;dv.fat_blk_dirty=3;
  for(i=0;i<512;i++)bd.RAM_dsk[1024+i]=i*7+3;
  DrvFATBlkAlloc(&dv);
  if(!dv.cur_fat_blk||dv.cur_fat_blk_num||dv.fat_blk_dirty)throw('Helper7',TRUE);
  cache=dv.cur_fat_blk;
  for(i=0;i<512;i++)if(cache[i]!=bd.RAM_dsk[1024+i])throw('Helper8',TRUE);
  if(DrvLock(&dv))throw('Helper9',TRUE);
  DrvUnlock(&dv);Free(dv.cur_fat_blk);Free(bd.RAM_dsk);
}
MediaBlockHelpersContract;
HelperReport("PASS private RAM media block helpers\n");
HelperReport("DONE media block helpers\n");
