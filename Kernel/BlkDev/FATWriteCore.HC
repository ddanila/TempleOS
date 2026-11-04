I64 FAT32FileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buf,I64 size,
	CDate cdt,I64 attr)
{
  CDirEntry de,existing;
  I64 c=0,blk_cnt;
  Bool contiguous,unlock=FALSE,unlock_break=FALSE;
  MemSet(&de,0,sizeof(CDirEntry));
  if (size<0) size=0;
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else if (!CFileNameTo(de.name,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else try {
    unlock_break=BreakLock;
    unlock=DrvLock(dv);
    if (FAT32FileFind(dv,Name2DirClus(dv,cur_dir),de.name,&existing,
	  FUF_JUST_FILES))
      StrCpy(de.name,existing.name);
    FAT32FilesDel(dv,cur_dir,de.name,0,FALSE,FALSE);
    if (attr & RS_ATTR_CONTIGUOUS)
      contiguous=TRUE;
    else
      contiguous=FALSE;
    de.size=size;
    if (blk_cnt=(size+BLK_SIZE-1)>>BLK_SIZE_BITS)
      c=ClusAlloc(dv,0,(blk_cnt+dv->spc-1)/dv->spc,contiguous);
    else
      c=0x0FFFFFFF;
    de.clus=c;
    de.attr=attr;
    de.datetime=cdt;
    if (blk_cnt)
      ClusBlkWrite(dv,buf,c,blk_cnt);
    FAT32DirNew(dv,cur_dir,&de,TRUE);
    if (unlock) {DrvUnlock(dv);unlock=FALSE;}
    if (unlock_break) {unlock_break=FALSE;BreakUnlock;}
  } catch {
    if (unlock) DrvUnlock(dv);
    if (unlock_break) BreakUnlock;
  }
  return c;
}
