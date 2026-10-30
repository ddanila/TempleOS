I64 ClusNumNext(CDrv *dv,I64 c,I64 cnt=1)
{//Return next cnt'th clus in chain.
  Bool unlock;
  DrvChk(dv);
  if (cnt<=0) return c;
  try {
    unlock=DrvLock(dv);
    switch (dv->fs_type) {
      case FSt_REDSEA:
	c+=cnt;
	break;
      case FSt_FAT32:
	while (cnt-->0 && 0<c<0x0FFFFFF8) {
	  DrvFATBlkSet(dv,c);
	  c=dv->cur_fat_blk[c & (BLK_SIZE/4-1)];
	}
	if (!(0<c<0x0FFFFFF8))
	  c=INVALID_CLUS;
	break;
      default:
	throw('Drv');
    }
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
  return c;
}

