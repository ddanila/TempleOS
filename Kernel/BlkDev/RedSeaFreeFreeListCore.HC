U0 RedSeaFreeFreeLst(CDrv *dv)
{
  CFreeLst *tmpf,*tmpf1;
  Bool unlock;
  try {
    unlock=DrvLock(dv);
    if (tmpf=dv->next_free) {
      while (tmpf!=&dv->next_free) {
	tmpf1=tmpf->next;
	Free(tmpf);
	tmpf=tmpf1;
      }
    }
    dv->next_free=NULL;
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
}

