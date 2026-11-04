Bool FAT32MkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt)
{
  I64 c,cur_dir_clus=Name2DirClus(dv,cur_dir),
//Rough estimate of size
	size=CeilU64((entry_cnt+2)<<FAT32_ENTRIES_BITS,dv->spc<<BLK_SIZE_BITS);
  U8 *buf=CAlloc(size);
  CDirEntry d_native;
  CFAT32DirEntry *dFAT=buf;
  Bool unlock_break;

  try {
    unlock_break=BreakLock;
    c=FileWrite(name,buf,size,0,RS_ATTR_DIR);
    MemSet(&d_native,0,sizeof(CDirEntry));
    d_native.attr=RS_ATTR_DIR;
    *d_native.name='.';
    d_native.name[1]=0;
    d_native.clus=c;
    d_native.size=0;
    d_native.datetime=Now;
    FAT32DirFill(dFAT,&d_native,NULL,dv->fat32_local_time_offset);
    dFAT++;

    MemSet(&d_native,0,sizeof(CDirEntry));
    d_native.attr=RS_ATTR_DIR;
    *d_native.name='.';
    d_native.name[1]='.';
    d_native.name[2]=0;
    d_native.clus=cur_dir_clus;
    d_native.size=0;
    d_native.datetime=Now;
    FAT32DirFill(dFAT,&d_native,NULL,dv->fat32_local_time_offset);
    ClusWrite(dv,buf,c,1);
    Free(buf);
    if (unlock_break)
      BreakUnlock;
  } catch
    if (unlock_break)
      BreakUnlock;
  return TRUE;
}
