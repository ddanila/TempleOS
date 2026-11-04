U0 DskCacheInvalidate(CDrv *dv)
{//Needed for removable media. Called by $LK,"DskChg",A="MN:DskChg"$().
  Bool unlock;
  CBlkDev *bd=dv->bd;
  DrvChk(dv);
  try {
    unlock=DrvLock(dv);
    BlkDevInit(bd);
    if (bd->flags & BDF_READ_CACHE)
      DskCacheInvalidate2(dv);
    if (bd->type==BDT_ATAPI && !(bd->flags & BDF_READ_ONLY_OVERRIDE))
      ISOInit(dv,(32767/bd->blk_size+1)*bd->blk_size>>BLK_SIZE_BITS);
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
}

U0 DskChg(U8 drv_let=0)
{//Change disk. (Needed for removable media.)
  CDrv *dv=Let2Drv(drv_let);
  CBlkDev *bd=dv->bd;
  if (!(bd->flags&BDF_INITIALIZED))
    BlkDevInit(bd);
  else if (bd->flags&BDF_REMOVABLE) {
    if (bd->type==BDT_ATAPI)
      ATAInit(bd); //TODO: This is a kludge for QEMU?
    DskCacheInvalidate(dv);
  }
  Drv(drv_let);
  RedSeaFreeFreeLst(dv);
}

Bool Drv(U8 drv_let)
{//Change drive.  You can set drive with $LK,"Cd",A="MN:Cd"$() as well.
  CDrv *dv=Let2Drv(drv_let);
  CBlkDev *bd;
  bd=BlkDevChk(dv->bd);
  if (dv!=Fs->cur_dv) {
    if (bd->flags & BDF_REMOVABLE && !(bd->flags & BDF_INITIALIZED))
      DskChg(Drv2Let(dv));
    if (bd->type==BDT_RAM ||
	bd->type==BDT_ISO_FILE_READ || bd->type==BDT_ISO_FILE_WRITE)
      BlkDevInit(bd);
  }
  Fs->cur_dv=dv;
  Free(Fs->cur_dir);
  Fs->cur_dir=StrNew("/");
  switch (dv->fs_type) {
    case FSt_REDSEA:
    case FSt_FAT32:
      return TRUE;
    default:
      PrintErr("File System Not Supported\n");
      return FALSE;
  }
}
