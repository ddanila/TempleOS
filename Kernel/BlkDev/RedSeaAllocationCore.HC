U0 RedSeaFreeLstBuild(CDrv *dv)
{
  Bool unlock;
  CFreeLst *tmpf;
  I64 i,first=dv->data_area,max_blk=dv->size+dv->drv_offset;
  try {
    unlock=DrvLock(dv);
    if (dv->next_free)
      RedSeaFreeFreeLst(dv);
    QueInit(&dv->next_free);
    while (first<max_blk) {
      i=0;  //count free clus
      while (first+i<max_blk) {
	DrvFATBlkSet(dv,first+i);
	if (Bt(dv->cur_fat_blk,(first+i-dv->data_area)&(BLK_SIZE<<3-1)))
	  break;
	else
	  i++;
      }
      if (i) {
	tmpf=AMAlloc(sizeof(CFreeLst));
	tmpf->size=i;
	tmpf->start=first;
	QueIns(tmpf,dv->last_free);
      }
      first+=i+1;
    }
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
}

U0 RedSeaFreeClus(CDrv *dv,I64 c,I64 cnt)
{
  CFreeLst *tmpf;
  Bool found=FALSE,unlock,unlock_break;
  DrvChk(dv);
  if (!c) return;
  if (dv->fs_type!=FSt_REDSEA)
    PrintErr("Not RedSea Drv\n");
  else
    try {
      unlock_break=BreakLock;
      unlock=DrvLock(dv);
      if (!dv->next_free)
	RedSeaFreeLstBuild(dv);
      tmpf=dv->next_free;
      while (!found && tmpf!=&dv->next_free) {
	if (tmpf->start+tmpf->size==c) {
	  tmpf->size+=cnt;
	  found=TRUE;
	} else if (c+cnt==tmpf->start) {
	  tmpf->size+=cnt;
	  tmpf->start=c;
	  found=TRUE;
	}
	tmpf=tmpf->next;
      }
      if (!found) {
	tmpf=AMAlloc(sizeof(CFreeLst));
	tmpf->size=cnt;
	tmpf->start=c;
	QueIns(tmpf,dv->last_free);
      }
      while (cnt-->0) {
	DrvFATBlkSet(dv,c);
	LBtr(dv->cur_fat_blk,(c-dv->data_area)&(BLK_SIZE<<3-1));
	LBts(&dv->fat_blk_dirty,0);
	c++;
      }
      DrvFATBlkClean(dv);

      if (unlock)
	DrvUnlock(dv);
      if (unlock_break)
	BreakUnlock;
    } catch {
      if (unlock)
	DrvUnlock(dv);
      if (unlock_break)
	BreakUnlock;
    }
}

I64 RedSeaAllocClus(CDrv *dv,I64 cnt)
{
  CFreeLst *tmpf,*best_free=NULL;
  I64 i,first,best_size=I64_MAX;
  Bool unlock,unlock_break;
  if (cnt<=0)
    throw('Drv');
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    if (!dv->next_free)
      RedSeaFreeLstBuild(dv);
    tmpf=dv->next_free;
    while (tmpf!=&dv->next_free) {
      if (tmpf->size>=cnt && tmpf->size<best_size) {
	best_free=tmpf;
	best_size=tmpf->size;
	if (tmpf->size==cnt)
	  break;
      }
      tmpf=tmpf->next;
    }
    if (!best_free)
      throw('Drv');
    first=best_free->start;
    for (i=0;i<cnt;i++) {
      DrvFATBlkSet(dv,first+i);
      LBts(dv->cur_fat_blk,(first+i-dv->data_area)&(BLK_SIZE<<3-1));
      LBts(&dv->fat_blk_dirty,0);
    }
    DrvFATBlkClean(dv);
    if (best_free->size-=cnt)
      best_free->start+=cnt;
    else {
      QueRem(best_free);
      Free(best_free);
    }
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  return first;
}
