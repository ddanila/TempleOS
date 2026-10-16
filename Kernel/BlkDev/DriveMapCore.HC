#ifndef DRIVE_MAP_SLOT
#define DRIVE_MAP_SLOT blkdev.let_to_drv[drv_let-'A']
#endif
Bool DrvMap(U8 drv_let,CDrv *dv)
{//Make drive letter map to another.
  drv_let=Let2Let(drv_let);
  if ('A'<=drv_let<='Z') {
    DRIVE_MAP_SLOT=dv;
    dv->drv_let=drv_let;
    return TRUE;
  } else
    return FALSE;
}
