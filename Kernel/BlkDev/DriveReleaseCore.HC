#ifndef DRIVE_RELEASE_RECORD
#define DRIVE_RELEASE_RECORD &blkdev.drvs[i]
#endif
U0 DrvsRelease()
{//When task dies, release all owned drvs.
  I64 i;
  CDrv *dv;
  for (i=0;i<DRVS_NUM;i++) {
    dv=DRIVE_RELEASE_RECORD;
    if (dv->owning_task==Fs && dv->dv_signature==DRV_SIGNATURE_VAL)
      DrvUnlock(dv,TRUE);
  }
}

