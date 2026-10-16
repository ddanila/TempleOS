U0 DrvDel(CDrv *dv)
{//Delete drv
  if (dv->fs_type==FSt_REDSEA && dv->next_free)
    RedSeaFreeFreeLst(dv);
  Free(dv->cur_fat_blk);
  Free(dv->fis);
  MemSet(dv,0,sizeof(CDrv));
}
