#ifndef DRIVE_BOOT_LET
#define DRIVE_BOOT_LET blkdev.boot_drv_let
#endif
#ifndef DRIVE_HOME_LET
#define DRIVE_HOME_LET (*blkdev.home_dir)
#endif
CDrv *DrvChk(CDrv *dv,Bool except=TRUE)
{//Check for valid drv. Throw exception.
  if (!dv || dv->dv_signature!=DRV_SIGNATURE_VAL) {
    if (except)
      throw('Drv');
    else
      return NULL;
  } else
    return dv;
}

U8 Drv2Let(CDrv *dv=NULL)
{//Drv ptr to Drv letter.
  if (!dv)
    dv=Fs->cur_dv;
  DrvChk(dv);
  return dv->drv_let;
}

U8 Let2Let(U8 drv_let=0)
{//Drv letter to Drv letter.
  if (!drv_let)
    drv_let=Drv2Let(Fs->cur_dv);
  else if (drv_let==':')
    drv_let=DRIVE_BOOT_LET;
  else if (drv_let=='~')
    drv_let=DRIVE_HOME_LET;
  return ToUpper(drv_let);
}

