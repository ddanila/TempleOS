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
  DskCacheInvalidate(&dv);
  storage[0]=12;storage[512]=23;storage[1024]=34;
  BlkRead(&dv,buf,0,1);BlkRead(&dv,buf,2,1);
  storage[0]=45;storage[512]=56;storage[1024]=67;
  MemSet(buf,0,1536);ok=BlkRead(&dv,buf,0,3);
  if(ok && buf[0]==12 && buf[512]==56 && buf[1024]==34)mask|=16;
  {
    CDrv dv2;CBlkDev bd2;U8 *storage2=CAlloc(2048);
    MemCpy(&dv2,&dv,sizeof(CDrv));MemCpy(&bd2,&bd,sizeof(CBlkDev));
    dv2.bd=&bd2;bd2.RAM_dsk=storage2;storage2[0]=88;
    MemSet(buf,0,512);ok=BlkRead(&dv2,buf,0,1);
    if(ok && buf[0]==88 && BlkRead(&dv,buf,0,1) && buf[0]==12)mask|=32;
    storage[0]=99;
    DskCacheInvalidate(&dv2);
    MemSet(buf,0,512);ok=BlkRead(&dv,buf,0,1);
    if(ok && buf[0]==12)mask|=64;
    Free(storage2);
  }
  {
    CDrv dv3;CBlkDev bd3;I64 sectors=blkdev.cache_size/512+1;
    U8 *storage3=CAlloc(sectors*512),*bulk=CAlloc(sectors*512);
    MemCpy(&dv3,&dv,sizeof(CDrv));MemCpy(&bd3,&bd,sizeof(CBlkDev));
    dv3.bd=&bd3;dv3.size=sectors;bd3.RAM_dsk=storage3;
    storage3[0]=13;storage3[(sectors-1)*512]=37;
    ok=sectors>1 && BlkRead(&dv3,bulk,0,sectors);
    storage3[0]=46;storage3[(sectors-1)*512]=70;
    if(ok && BlkRead(&dv3,buf,0,1) && buf[0]==46 &&
       BlkRead(&dv3,buf,sectors-1,1) && buf[0]==37)mask|=128;
    DskCacheInvalidate(&dv3);Free(storage3);Free(bulk);
  }
  DskCacheInvalidate(&dv);Free(storage);Free(buf);Free(src);return mask;
}
