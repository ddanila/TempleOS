#ifndef BLOCK_DEV_SLOT_RECORD
#define BLOCK_DEV_SLOT_RECORD &blkdev.blkdevs[i]
#endif
CBlkDev *BlkDevNextFreeSlot(U8 first_drv_let,I64 type)
{//Locate free slot for new BlkDev, like during $LK,"Mount",A="MN:Mount"$().
  I64 i=0;
  CBlkDev *res;
  if (Let2BlkDevType(first_drv_let)!=type)
    throw('BlkDev');
  do {
    res=BLOCK_DEV_SLOT_RECORD;
    if (res->bd_signature!=BD_SIGNATURE_VAL) {
      MemSet(res,0,sizeof(CBlkDev));
      res->first_drv_let=first_drv_let;
      res->type=type;
      res->flags=BDF_READ_CACHE;
      res->blk_size=BLK_SIZE;
      res->max_blk=0xEFFFFFFF;
      switch (type) {
	case BDT_RAM:
	  res->flags&=~BDF_READ_CACHE;
	  break;
	case BDT_ISO_FILE_READ:
	  res->flags|=BDF_READ_ONLY;
	  break;
	case BDT_ATAPI:
	  res->flags|=BDF_REMOVABLE|BDF_READ_ONLY;
	  res->blk_size=DVD_BLK_SIZE;
	  break;
      }
      return res;
    }
  } while (++i<BLKDEVS_NUM);
  throw('BlkDev');
  return NULL; //never gets here
}
