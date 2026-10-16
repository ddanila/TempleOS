Bool DrvLock(CDrv *dv)
{//Make this task have exclusive access to drv & BlkDev.
  DrvChk(dv);
  BlkDevLock(dv->bd);
  if (!Bt(&dv->locked_flags,DVlf_LOCKED) || dv->owning_task!=Fs) {
    while (LBts(&dv->locked_flags,DVlf_LOCKED))
      Yield;
    dv->owning_task=Fs;
    return TRUE;
  } else
    return FALSE;
}

Bool DrvUnlock(CDrv *dv,Bool rst=FALSE)
{//Release exclusive lock on access to drv & BlkDev.
  DrvChk(dv);
  if (Bt(&dv->locked_flags,DVlf_LOCKED) && dv->owning_task==Fs) {
    BlkDevUnlock(dv->bd,rst);
    dv->owning_task=NULL;
    LBtr(&dv->locked_flags,DVlf_LOCKED);
    Yield; //Prevent deadlock
    return TRUE;
  } else
    return FALSE;
}

