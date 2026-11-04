U0 DrvFATBlkAlloc(CDrv *dv)
{
  DrvChk(dv);
  Free(dv->cur_fat_blk);
  dv->cur_fat_blk=AMAlloc(BLK_SIZE);
  dv->cur_fat_blk_num=0;
  dv->fat_blk_dirty=0;
  BlkRead(dv,dv->cur_fat_blk,dv->fat1,1);
}
