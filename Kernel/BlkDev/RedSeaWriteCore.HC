I64 RedSeaFileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buf,I64 size,
	CDate cdt,I64 attr)
{
  CDirEntry de;
  I64 c=0,blk_cnt;
  MemSet(&de,0,sizeof(CDirEntry));
  if (size<0) size=0;
  if (dv->fs_type!=FSt_REDSEA)
    PrintErr("Not RedSea Drv\n");
  else if (!CFileNameTo(de.name,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else {
    RedSeaFilesDel(dv,cur_dir,de.name,0,FALSE,FALSE);
    de.size=size;
    if (blk_cnt=(size+BLK_SIZE-1)>>BLK_SIZE_BITS)
      c=ClusAlloc(dv,0,blk_cnt,TRUE); //Always contiguous
    else
      c=INVALID_CLUS;
    de.clus=c;
    de.attr=attr|RS_ATTR_CONTIGUOUS;
    de.datetime=cdt;
    if (blk_cnt)
      BlkWrite(dv,buf,c,blk_cnt);
    RedSeaDirNew(dv,cur_dir,&de,TRUE);
  }
  return c;
}
