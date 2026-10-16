Bool BlkDevLock(CBlkDev *bd)
{//Make this task have exclusive access to BlkDev.
  BlkDevChk(bd);
  while (bd->lock_fwding)
    bd=bd->lock_fwding; //If two blkdevs on same controller, use just one lock
  if (!Bt(&bd->locked_flags,BDlf_LOCKED) || bd->owning_task!=Fs) {
    while (LBts(&bd->locked_flags,BDlf_LOCKED))
      Yield;
    bd->owning_task=Fs;
    return TRUE;
  } else
    return FALSE;
}

Bool BlkDevUnlock(CBlkDev *bd,Bool rst=FALSE)
{//Release exclusive lock on access to BlkDev.
  BlkDevChk(bd);
  while (bd->lock_fwding)
    bd=bd->lock_fwding; //If two blkdevs on same controller, use just one lock
  if (Bt(&bd->locked_flags,BDlf_LOCKED) && bd->owning_task==Fs) {
    if (rst)
      bd->flags&=~(BDF_INITIALIZED|BDF_INIT_IN_PROGRESS);
    bd->owning_task=NULL;
    LBtr(&bd->locked_flags,BDlf_LOCKED);
    Yield; //Prevent deadlock
    return TRUE;
  } else
    return FALSE;
}

