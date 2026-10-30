I64 BGContract()
{
  CCacheBlk cb;CBlkDevGlbls bg;I64 mask=0;
  MemSet(&cb,0,sizeof(cb));MemSet(&bg,0,sizeof(bg));
  cb.blk=37;bg.cache_ctrl=&cb;bg.cache_size=512;
  if(bg.cache_ctrl->blk==37 && bg.cache_size==512)mask|=1;
  bg.let_to_drv[31]=Fs->cur_dv;
  if(bg.let_to_drv[31]==Fs->cur_dv)mask|=2;
  cb.body[0]=11;cb.body[BLK_SIZE-1]=22;
  if(cb.body[0]==11 && cb.body[BLK_SIZE-1]==22)mask|=4;
  if(sizeof(bg.let_to_drv)/sizeof(CDrv *)==32 &&
    offset(CCacheBlk.body)==offset(CCacheBlk.blk)+sizeof(I64))mask|=8;
  return mask;
}
