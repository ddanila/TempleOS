extern U0 I386DskCacheInit(I64 size);
extern U0 I386DskCacheAdd(CDrv *dv,U8 *buf,I64 blk,I64 cnt);
extern U0 I386RCache(CDrv *dv,U8 **buf,I64 *blk,I64 *cnt);
extern CBlkDevGlbls *I386DskCacheGlobals();
CDrv CCDrive;
Bool CCDone[2],CCOk[2];
U0 CCWorker(U8 *arg)
{
  I64 id=arg(I64),i,j,blk,cnt;U8 source[512],out[512],*p;
  MemSet(source,id+1,512);CCOk[id]=TRUE;
  for(i=0;i<64;i++) {
    I386DskCacheAdd(&CCDrive,source,7,1);Yield;
    p=out;blk=7;cnt=1;I386RCache(&CCDrive,&p,&blk,&cnt);
    if(cnt || (out[0]!=1 && out[0]!=2))CCOk[id]=FALSE;
    for(j=1;j<512;j++)if(out[j]!=out[0])CCOk[id]=FALSE;
    Yield;
  }
  CCDone[id]=TRUE;
  while(TRUE)Yield;
}
I64 CacheConcurrencyContract()
{
  CTask *a,*b;I64 deadline=cnts.jiffies+20000,result=0;
  if(I386DskCacheGlobals->cache_base)return -1;
  CCDone[0]=CCDone[1]=FALSE;CCOk[0]=CCOk[1]=FALSE;
  I386DskCacheInit(0x2000);
  a=Spawn(&CCWorker,0,"cache writer 1",-1,Fs);
  b=Spawn(&CCWorker,1(U8 *),"cache writer 2",-1,Fs);
  while(a && b && (!CCDone[0] || !CCDone[1]) && cnts.jiffies<deadline)Yield;
  //A timed-out worker may hold the cache semaphore; leave it to the disposable
  //guest rather than killing it and trying to reinitialize a locked cache.
  if(!a || !b || !CCDone[0] || !CCDone[1])return 0;
  if(a && b && CCDone[0] && CCDone[1] && CCOk[0] && CCOk[1])result=1;
  if(a)Kill(a);if(b)Kill(b);
  I386DskCacheInit(0);
  return result;
}
