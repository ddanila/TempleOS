Bool RedSeaMkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt)
{//entry_cnt is for preallocating dir blks.
  I64	c,cur_dir_clus=Name2DirClus(dv,cur_dir),
	size=CeilU64((entry_cnt+3)<<6,BLK_SIZE);
#assert CDIR_SIZE==64
  U8 *buf=CAlloc(size);
  CDirEntry *d_native=buf-offset(CDirEntry.start);
  Bool unlock_break;
  try {
    unlock_break=BreakLock;
    c=FileWrite(name,buf,size,0,RS_ATTR_DIR);
    d_native->attr=RS_ATTR_DIR|RS_ATTR_CONTIGUOUS;
    StrCpy(d_native->name,name);
    d_native->clus=c;
    d_native->size=size;
    d_native->datetime=Now;
    d_native(U8 *)+=CDIR_SIZE;

    d_native->attr=RS_ATTR_DIR|RS_ATTR_CONTIGUOUS;
    *d_native->name='.';
    d_native->name[1]='.';
    d_native->name[2]=0;
    d_native->clus=cur_dir_clus;
    d_native->size=0;
    d_native->datetime=Now;
    BlkWrite(dv,buf,c,1);
    Free(buf);
    if (unlock_break)
      BreakUnlock;
  } catch
    if (unlock_break)
      BreakUnlock;
  return TRUE;
}
