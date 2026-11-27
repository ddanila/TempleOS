#include "/Kernel/I386/HeapKnown.HC"
//Independent previous implementation: validate, then locate and coalesce.
Bool HeapFreeReference(CI386Heap *hc,U8 *ptr)
{
  CI386HeapBlock *block=0,*previous=0,*next;
  U32 offset=0;
  if(!ptr)return TRUE;
  if(!I386HeapValid(hc))return FALSE;
  while(offset<hc->size) {
    block=hc->base+offset;
    if(hc->base+offset+16==ptr)break;
    previous=block;offset+=block->span;
  }
  if(offset>=hc->size || block->tag!=I386_HEAP_USED)return FALSE;
  hc->used-=block->span;hc->allocations--;
  block->tag=I386_HEAP_FREE;block->requested=0;
  if(offset+block->span<hc->size) {
    next=hc->base+offset+block->span;
    if(next->tag==I386_HEAP_FREE)block->span+=next->span;
  }
  if(previous && previous->tag==I386_HEAP_FREE)previous->span+=block->span;
  return TRUE;
}
Bool HeapFreeBytesEqual(U8 *a,U8 *b,I64 bytes)
{
  I64 i;
  for(i=0;i<bytes;i++)if(a[i]!=b[i])return FALSE;
  return TRUE;
}
I64 HeapFreeParityTest()
{
  CI386Heap a,b,c;
  U8 *aa=0x42000,*bb=0x42400,*cc=0x42800,*pa[4],*pb[4],*pc[4];
  U8 *orders="012301320213023103120321102310321203123013021320201320312103213023012310301230213102312032013210";
  I64 round,n,index;U64 before_a,before_b;
  for(round=0;round<24;round++) {
    for(n=0;n<512;n++) { aa[n]=0;bb[n]=0;cc[n]=0; }
    if(!I386HeapInit(&a,aa,512) || !I386HeapInit(&b,bb,512) || !I386HeapInit(&c,cc,512))return 320;
    for(n=0;n<4;n++) {
      pa[n]=I386HeapAlloc(&a,n*9,TRUE);pb[n]=I386HeapAlloc(&b,n*9,TRUE);
      pc[n]=I386HeapAlloc(&c,n*9,TRUE);
      if(!pa[n] || !pb[n] || !pc[n] || pa[n]-aa!=pb[n]-bb || pa[n]-aa!=pc[n]-cc)return 321;
    }
    before_a=Hash(aa,512);before_b=Hash(bb,512);
    if(!I386HeapValid(&c) || !I386HeapKnownFree(&c,0) ||
        I386HeapFree(&a,pa[1]+1) || HeapFreeReference(&b,pb[1]+1) ||
        I386HeapKnownFree(&c,pc[1]+1) || I386HeapKnownFree(&c,cc) ||
        I386HeapKnownFree(&c,cc+528) || Hash(aa,512)!=before_a ||
        Hash(bb,512)!=before_b || !HeapFreeBytesEqual(aa,cc,512))return 322;
    for(n=0;n<4;n++) {
      index=orders[round*4+n]-'0';
      if(!I386HeapFree(&a,pa[index]) || !HeapFreeReference(&b,pb[index]) ||
          !I386HeapKnownFree(&c,pc[index]) || I386HeapKnownFree(&c,pc[index]) ||
          a.used!=b.used || a.allocations!=b.allocations || a.peak!=b.peak ||
          c.used!=b.used || c.allocations!=b.allocations || c.peak!=b.peak ||
          !HeapFreeBytesEqual(aa,bb,512) || !HeapFreeBytesEqual(cc,bb,512) ||
          !I386HeapValid(&a) || !I386HeapValid(&b) || !I386HeapValid(&c))return 323;
    }
    if(a.used || b.used || a.allocations || b.allocations)return 324;
  }
  return 0;
}
