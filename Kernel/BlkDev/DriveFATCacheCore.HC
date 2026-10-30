U0 DrvFATBlkClean(CDrv *dv,I64 fat_sel=3)
{
  if ((dv->fs_type==FSt_FAT32 || dv->fs_type==FSt_REDSEA) &&
       Bt(&dv->fat_blk_dirty,0)) {
    if (dv->fat1==dv->fat2) {
      BlkWrite(dv,dv->cur_fat_blk,dv->fat1+dv->cur_fat_blk_num,1);
      LBtr(&dv->fat_blk_dirty,0);
    } else {
      if (fat_sel==3 || !fat_sel)
	BlkWrite(dv,dv->cur_fat_blk,dv->fat1+dv->cur_fat_blk_num,1);
      if (fat_sel==3 || fat_sel==1) {
	BlkWrite(dv,dv->cur_fat_blk,dv->fat2+dv->cur_fat_blk_num,1);
	LBtr(&dv->fat_blk_dirty,0);
      }
    }
  }
}

U0 DrvFATBlkSet(CDrv *dv,I64 c,I64 fat_sel=3)
{
  I64 fat_blk_num;
  if (c==INVALID_CLUS)
    throw('Drv');
  switch (dv->fs_type) {
    case FSt_FAT32:
      fat_blk_num=c>>(BLK_SIZE_BITS-2);
      break;
    case FSt_REDSEA:
      fat_blk_num=(c-dv->data_area)>>(BLK_SIZE_BITS+3);
      break;
    default:
      throw('Drv');
  }
  if (fat_blk_num!=dv->cur_fat_blk_num) {
    DrvFATBlkClean(dv,fat_sel);
    dv->cur_fat_blk_num=fat_blk_num;
    if (fat_sel==3 || !fat_sel)
      BlkRead(dv,dv->cur_fat_blk,dv->fat1+dv->cur_fat_blk_num,1);
    else
      BlkRead(dv,dv->cur_fat_blk,dv->fat2+dv->cur_fat_blk_num,1);
  }
}

