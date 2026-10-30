I64 BOContract()
{
  CDrv dv; CBlkDev bd;
  U8 *storage=CAlloc(2048),*src=MAlloc(1024),*dst=CAlloc(1024);
  I64 i,mask=0;Bool ok,caught;
  MemCpy(&dv,Fs->cur_dv,sizeof(CDrv));
  MemCpy(&bd,Fs->cur_dv->bd,sizeof(CBlkDev));
  dv.bd=&bd;dv.drv_offset=0;dv.size=4;dv.locked_flags=0;dv.owning_task=NULL;
  bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED;bd.RAM_dsk=storage;
  bd.lock_fwding=NULL;bd.locked_flags=0;bd.owning_task=NULL;
  for(i=0;i<1024;i++)src[i]=(i*13+7)&255;
  if(BlkRead(&dv,NULL,100,0) && BlkWrite(&dv,NULL,100,0))mask|=1;
  ok=BlkWrite(&dv,src,1,2) && BlkRead(&dv,dst,1,2);
  for(i=0;i<1024;i++)if(src[i]!=dst[i])ok=FALSE;
  if(ok && !storage[0] && !storage[1536])mask|=2;
  caught=FALSE;
  try BlkRead(&dv,dst,4,1);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(caught)mask|=4;
  bd.flags|=BDF_READ_ONLY;caught=FALSE;
  try BlkWrite(&dv,src,0,1);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(caught && !storage[0])mask|=8;
  bd.flags&=~BDF_READ_ONLY;
  if(DrvLock(&dv) && BlkWrite(&dv,src,0,1) &&
      dv.owning_task==Fs && bd.owning_task==Fs && DrvUnlock(&dv))mask|=16;
  Free(storage);Free(src);Free(dst);return mask;
}
