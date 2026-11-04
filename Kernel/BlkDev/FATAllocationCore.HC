U0 FAT32FreeClusUntil(CDrv *dv,I64 c,I64 stop)
{
  I64 next,saved_c=c;
  Bool unlock,unlock_break;
  DrvChk(dv);
  if (!(0<c<0x0FFFFFF8) || c==stop) return;
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else
    try {
      unlock_break=BreakLock;
      unlock=DrvLock(dv);
      DrvFATBlkClean(dv);
      do {
	DrvFATBlkSet(dv,c,0);
	next=dv->cur_fat_blk[c&(BLK_SIZE/4-1)];
	dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=0;
	LBts(&dv->fat_blk_dirty,0);
	c=next;
      } while (0<c<0x0FFFFFF8 && c!=stop);
      DrvFATBlkClean(dv,0);

      c=saved_c;
      do {
	DrvFATBlkSet(dv,c,1);
	next=dv->cur_fat_blk[c&(BLK_SIZE/4-1)];
	dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=0;
	LBts(&dv->fat_blk_dirty,0);
	c=next;
      } while (0<c<0x0FFFFFF8 && c!=stop);
      DrvFATBlkClean(dv,1);
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

U0 FAT32FreeClus(CDrv *dv,I64 c)
{
  FAT32FreeClusUntil(dv,c,INVALID_CLUS);
}

#include "/Kernel/BlkDev/FATChainOverlapCore.HC"

I64 FAT32AllocClus(CDrv *dv,I64 c,I64 cnt)
{
  Bool wrap_around=FALSE,unlock,unlock_break;
  I64 first=INVALID_CLUS,j,l;

  if (cnt<=0) return 0x0FFFFFFF;
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    l=(dv->size+dv->drv_offset-dv->data_area)/dv->spc-1;
    j=dv->fis->most_recently_alloced;
    while (cnt-->0) {
      while (TRUE) {
	j++;
	if (j<1) j=1;
	if (j>=l) {
	  if (wrap_around)
	    throw('Drv');
	  j=1;
	  wrap_around=TRUE;
	}
	DrvFATBlkSet(dv,j);
	if (!dv->cur_fat_blk[j&(BLK_SIZE/4-1)])
	  break;
      }
      if (!(0<first<0x0FFFFFF8))
	first=j;
      if (0<c<l) {
	DrvFATBlkSet(dv,c);
	dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=j;
	LBts(&dv->fat_blk_dirty,0);
      }
      c=j;
    }

    if (0<c<l) {
      DrvFATBlkSet(dv,c);
      dv->cur_fat_blk[c&(BLK_SIZE/4-1)]=0x0FFFFFFF;
      LBts(&dv->fat_blk_dirty,0);
    }
    DrvFATBlkClean(dv);

    dv->fis->most_recently_alloced=j;
    dv->fis->free_clus=-1;
    BlkWrite(dv,dv->fis,dv->file_system_info_sect,1);
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  if (unlock)
    DrvUnlock(dv);
  if (unlock_break)
    BreakUnlock;
  return first;
}

I64 FAT32AllocContiguousClus(CDrv *dv,I64 cnt)
{
  I64 i,first=1;
  Bool cont,unlock,unlock_break;

  if (cnt<=0) return 0x0FFFFFFF;
  try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    while (TRUE) {
      first++;
      i=0;
      cont=TRUE;
      while (cont && i<cnt) {
	if ((first+i+1)*dv->spc+dv->data_area>dv->size+dv->drv_offset)
	  throw('Drv');
	DrvFATBlkSet(dv,first+i);
	if (dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)])
	  cont=FALSE;
	else
	  i++;
      }
      if (!cont)
	first=first+i;
      else {
	DrvFATBlkClean(dv);

	for (i=0;i<cnt;i++) {
	  DrvFATBlkSet(dv,first+i,0);
	  if (i+1==cnt)
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=0x0FFFFFFF;
	  else
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=first+i+1;
	  LBts(&dv->fat_blk_dirty,0);
	}
	DrvFATBlkClean(dv,0);

	for (i=0;i<cnt;i++) {
	  DrvFATBlkSet(dv,first+i,1);
	  if (i+1==cnt)
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=0x0FFFFFFF;
	  else
	    dv->cur_fat_blk[(first+i)&(BLK_SIZE/4-1)]=first+i+1;
	  LBts(&dv->fat_blk_dirty,0);
	}
	DrvFATBlkClean(dv,1);
	break;
      }
    }
  } catch {
    if (unlock)
      DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  if (unlock)
    DrvUnlock(dv);
  if (unlock_break)
    BreakUnlock;
  return first;
}

