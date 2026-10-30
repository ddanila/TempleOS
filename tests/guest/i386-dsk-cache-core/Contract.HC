extern U0 I386DskCacheInit(I64 size);
extern U0 I386DskCacheAdd(CDrv *dv,U8 *buf,I64 blk,I64 cnt);
extern U0 I386RCache(CDrv *dv,U8 **buf,I64 *blk,I64 *cnt);
extern U0 I386DskCacheInvalidate2(CDrv *dv);
extern CBlkDevGlbls *I386DskCacheGlobals();

I64 CacheCoreContract()
{
  CDrv a,b;U8 src[1536],out[1536],*p;I64 blk,cnt,n,i,mask=0;
  CBlkDevGlbls *g=I386DskCacheGlobals;
  if(g->cache_base) return -1;
  I386DskCacheInit(0x2000);
  n=g->cache_size/512;
  if(g->cache_base && g->cache_ctrl && g->cache_hash_table && n>=3) mask|=1;
  MemSet(src,0,1536);src[0]=11;src[512]=22;src[1024]=33;
  I386DskCacheAdd(&a,src,0,1);I386DskCacheAdd(&a,src+1024,2,1);
  MemSet(out,0,1536);p=out;blk=0;cnt=3;I386RCache(&a,&p,&blk,&cnt);
  if(out[0]==11 && out[1024]==33 && p==out+512 && blk==1 && cnt==1)mask|=2;
  p=out;blk=0;cnt=1;I386RCache(&b,&p,&blk,&cnt);
  if(p==out && blk==0 && cnt==1)mask|=4;
  src[0]=44;I386DskCacheAdd(&b,src,0,1);I386DskCacheInvalidate2(&b);
  MemSet(out,0,512);p=out;blk=0;cnt=1;I386RCache(&a,&p,&blk,&cnt);
  if(!cnt && out[0]==11)mask|=8;
  I386DskCacheInvalidate2(&a);
  for(i=0;i<n+1;i++) { src[0]=i;I386DskCacheAdd(&a,src,i,1); }
  p=out;blk=0;cnt=1;I386RCache(&a,&p,&blk,&cnt);
  if(cnt==1)mask|=16;
  p=out;blk=n;cnt=1;I386RCache(&a,&p,&blk,&cnt);
  if(!cnt && out[0]==n(U8))mask|=32;
  I386DskCacheInit(0);
  if(!g->cache_base && !g->cache_ctrl && !g->cache_hash_table)mask|=64;
  return mask;
}
