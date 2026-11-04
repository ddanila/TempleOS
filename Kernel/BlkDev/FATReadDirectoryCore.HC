U8 *FAT32FileRead(CDrv *dv,U8 *cur_dir,U8 *filename,I64 *_size,I64 *_attr)
{
  U8 *buf=NULL;
  CDirEntry de;
  I64 c,blk_cnt,cur_dir_clus;
  Bool unlock=FALSE;
  DrvChk(dv);
  *_size=0;
  *_attr=0;
  if (dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else
    try {
      unlock=DrvLock(dv);
      cur_dir_clus=Name2DirClus(dv,cur_dir);
      if (FAT32FileFind(dv,cur_dir_clus,filename,&de,FUF_JUST_FILES)) {
	blk_cnt=(de.size+BLK_SIZE-1)>>BLK_SIZE_BITS;
	buf=MAlloc(blk_cnt<<BLK_SIZE_BITS+1);
	c=de.clus;
	if (!(0<c<0x0FFFFFF8))
	  c=0x0FFFFFFF;
	else
	  c=ClusBlkRead(dv,buf,c,blk_cnt);
	buf[de.size]=0; //Terminate
	*_size=de.size;
	*_attr=FileAttr(de.name,de.attr);
      }
      if (unlock) DrvUnlock(dv);
    } catch
      if (unlock) DrvUnlock(dv);
  return buf;
}

Bool FAT32Cd(U8 *name,I64 cur_dir_clus)
{
  CDirEntry de;
  if (Fs->cur_dv->fs_type!=FSt_FAT32)
    PrintErr("Not FAT32 Drv\n");
  else if (FAT32FileFind(Fs->cur_dv,cur_dir_clus,name,&de,FUF_JUST_DIRS))
    return TRUE;
  else
    PrintErr("File not found: \"%s\".\n",name);
  return FALSE;
}
