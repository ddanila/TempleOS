U0 RedSeaInit(CDrv *dv)
{
  CRedSeaBoot br;
  Bool unlock;
  try {
    unlock=DrvLock(dv);
    BlkRead(dv,&br,dv->drv_offset,1);
    if (br.signature!=MBR_PT_REDSEA || br.signature2!=0xAA55)
      throw('Drv');
    dv->fs_type=FSt_REDSEA;
    RedSeaFreeFreeLst(dv);
    dv->spc=1;
    dv->size=br.sects;
    dv->data_area=dv->drv_offset+br.bitmap_sects;
    dv->root_clus=br.root_clus;
    dv->fat1=dv->fat2=dv->drv_offset+1;
    DrvFATBlkAlloc(dv);
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
}

Bool RedSeaValidate(U8 drv_let)
{
  CDrv *dv;
  CRedSeaBoot br;
  if ((dv=Let2Drv(drv_let,FALSE)) && dv->fs_type==FSt_REDSEA &&
	BlkRead(dv,&br,dv->drv_offset,1) && br.signature==MBR_PT_REDSEA &&
	br.signature2==0xAA55)
    return TRUE;
  else
    return FALSE;
}

U0 RedSeaFmt(U8 drv_let,Bool quick=TRUE)
{
  U8 *root_dir;
  CDirEntry *d_native;
  CRedSeaBoot *br=CAlloc(BLK_SIZE);
  CDrv *dv=Let2Drv(drv_let);
  I64 i,n,root_dir_blks;
  try {
    DrvLock(dv);
//	DrvTypeSet(drv_let,FSt_REDSEA);
    DrvTypeSet(drv_let,FSt_FAT32);
    dv->fs_type=FSt_REDSEA;
    br->signature=MBR_PT_REDSEA;
    br->signature2=0xAA55;
    br->drv_offset=dv->drv_offset; //For CD/DVD image copy.
    br->sects=dv->size;
    n=(br->sects+BLK_SIZE<<3-1)/BLK_SIZE<<3;
    br->bitmap_sects=n;
    br->unique_id=GetTSC^Now()(U64);
    br->root_clus=0;

    if (quick)
      i=n+1;
    else
      i=dv->size;
    BlkWriteZero(dv,dv->drv_offset,i);

    BlkWrite(dv,br,dv->drv_offset,1);
    RedSeaInit(dv);
    ClusAlloc(dv,0,1,FALSE);	//Alloc #1

    root_dir_blks=MaxI64(1,dv->bd->init_root_dir_blks);
    br->root_clus=ClusAlloc(dv,0,root_dir_blks,FALSE);
    BlkWrite(dv,br,dv->drv_offset,1);
    root_dir=CAlloc(BLK_SIZE*root_dir_blks);

    d_native=root_dir-offset(CDirEntry.start);

    d_native->attr=RS_ATTR_DIR|RS_ATTR_CONTIGUOUS;
    *d_native->name='.';
    d_native->clus=br->root_clus;
    d_native->size=BLK_SIZE*root_dir_blks;
    d_native->datetime=Now;

    d_native(U8 *)+=CDIR_SIZE;

    *d_native->name='.';
    d_native->name[1]='.';
    d_native->attr=RS_ATTR_DIR|RS_ATTR_CONTIGUOUS;
    d_native->clus=br->root_clus;
    d_native->datetime=Now;

    BlkWrite(dv,root_dir,br->root_clus,root_dir_blks);
    RedSeaInit(dv);
    DrvUnlock(dv);
  } catch
    DrvUnlock(dv);
  Free(br);
  Free(root_dir);
}
