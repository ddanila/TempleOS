#ifndef DRIVE_LOOKUP
#define DRIVE_LOOKUP blkdev.let_to_drv[drv_let-'A']
#endif
CDrv *Let2Drv(U8 drv_let=0,Bool except=TRUE)
{//Drv letter to Drv ptr.
  CDrv *dv;
  if (!drv_let)
    dv=Fs->cur_dv;
  else {
    drv_let=Let2Let(drv_let);
    if (!('A'<=drv_let<='Z')) {
      if (except)
	throw('Drv');
      else
	return NULL;
    }
    dv=DRIVE_LOOKUP;
  }
  return DrvChk(dv,except);
}

