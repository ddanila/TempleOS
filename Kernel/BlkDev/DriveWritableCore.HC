CBlkDev *DrvIsWritable(U8 drv_let=0,Bool except=FALSE)
{//Is drive writable?
  CBlkDev *bd;
  if (!(bd=Let2BlkDev(drv_let,except)) || bd->flags & BDF_READ_ONLY) {
    if (except)
      throw('Drv');
    else
      return NULL;
  } else
    return bd;
}

