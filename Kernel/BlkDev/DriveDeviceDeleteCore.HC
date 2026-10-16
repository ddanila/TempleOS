#ifndef DRIVE_DEVICE_DELETE_RECORD
#define DRIVE_DEVICE_DELETE_RECORD &blkdev.drvs[i]
#endif
U0 DrvBlkDevDel(CBlkDev *bd)
{//Delete drv's of BlkDev
  I64 i;
  CDrv *dv;
  for (i=0;i<DRVS_NUM;i++) {
    dv=DRIVE_DEVICE_DELETE_RECORD;
    if (dv->bd==bd)
      DrvDel(dv);
  }
}
