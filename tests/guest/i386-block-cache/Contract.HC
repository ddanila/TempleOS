I64 BCContract()
{
  CDrv dv; CBlkDev bd; U8 *storage=CAlloc(2048),*buf=CAlloc(1536),*src=CAlloc(512);
  I64 mask=0; Bool ok;
  MemCpy(&dv,Fs->cur_dv,sizeof(CDrv));MemCpy(&bd,Fs->cur_dv->bd,sizeof(CBlkDev));
  dv.bd=&bd;dv.drv_offset=0;dv.size=4;dv.locked_flags=0;dv.owning_task=NULL;
  bd.type=BDT_RAM;bd.flags=BDF_INITIALIZED|BDF_READ_CACHE;bd.RAM_dsk=storage;
  bd.lock_fwding=NULL;bd.locked_flags=0;bd.owning_task=NULL;
  storage[0]=11;storage[512]=22;storage[1024]=33;
  ok=BlkRead(&dv,buf,0,3);
  if(ok && buf[0]==11 && buf[512]==22 && buf[1024]==33)mask|=1;
  storage[0]=44;storage[512]=55;storage[1024]=66;
  MemSet(buf,0,1536);ok=BlkRead(&dv,buf,0,3);
  if(ok && buf[0]==11 && buf[512]==22 && buf[1024]==33)mask|=2;
  src[0]=77;ok=BlkWrite(&dv,src,1,1);MemSet(buf,0,512);
  if(ok && BlkRead(&dv,buf,1,1) && buf[0]==77 && storage[512]==77)mask|=4;
  DskCacheInvalidate(&dv);MemSet(buf,0,1536);ok=BlkRead(&dv,buf,0,3);
  if(ok && buf[0]==44 && buf[512]==77 && buf[1024]==66)mask|=8;
  DskCacheInvalidate(&dv);Free(storage);Free(buf);Free(src);return mask;
}
