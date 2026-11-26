I64 RedSeaUnusedDrvSpace(U8 drv_let=0)
{
  CDrv *dv=Let2Drv(drv_let);
  I64 res=0,i,l;
  U8 *bitmap;
  try {
    l=dv->size+dv->drv_offset-dv->data_area;
    i=((l+7)>>3+BLK_SIZE-1)>>BLK_SIZE_BITS;
    bitmap=MAlloc(i<<BLK_SIZE_BITS);
    BlkRead(dv,bitmap,dv->fat1,i);
    for (i=0;i<l;i++)
      if (!Bt(bitmap,i))
	res++;
    Free(bitmap);
  } catch
    DrvUnlock(dv);
  return res*BLK_SIZE*dv->spc;
}
I64 FAT32UnusedDrvSpace(U8 drv_let=0)
{
  CDrv *dv=Let2Drv(drv_let);
  I64 res=0,i,l;
  U32 *bitmap;
  try {
    l=(dv->size+dv->spc-1)/dv->spc-(2+dv->data_area-dv->drv_offset);
    i=(l*4+BLK_SIZE-1)>>BLK_SIZE_BITS;
    bitmap=MAlloc(i<<BLK_SIZE_BITS);
    BlkRead(dv,bitmap,dv->fat1,i);
    for (i=0;i<l;i++)
      if (!bitmap[i])
	res++;
    Free(bitmap);
  } catch
    DrvUnlock(dv);
  return res*BLK_SIZE*dv->spc;
}
public I64 DrvUnused(U8 drv_let=0)
{//Returns unused size in bytes.
  CDrv *dv=Let2Drv(drv_let),*old_dv=Fs->cur_dv;
  U8 *old_dir=StrNew(Fs->cur_dir);
  I64 res=0;
  Drv(drv_let);
  switch (dv->fs_type) {
    case FSt_REDSEA:
      res=RedSeaUnusedDrvSpace(drv_let);
      break;
    case FSt_FAT32:
      res=FAT32UnusedDrvSpace(drv_let);
      break;
    default:
      PrintErr("File System Not Supported\n");
  }
  Drv(Drv2Let(old_dv));
  Cd(old_dir);
  Free(old_dir);
  return res;
}
