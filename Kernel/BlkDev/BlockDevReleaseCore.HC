#ifndef BLOCK_DEV_RELEASE_RECORD
#define BLOCK_DEV_RELEASE_RECORD &blkdev.blkdevs[i]
#endif
U0 BlkDevsRelease()
{//When task dies, release all owned BlkDevs.
  I64 i;
  CBlkDev *bd;
  for (i=0;i<BLKDEVS_NUM;i++) {
    bd=BLOCK_DEV_RELEASE_RECORD;
    if (bd->owning_task==Fs && bd->bd_signature==BD_SIGNATURE_VAL)
      BlkDevUnlock(bd,TRUE);
  }
}

