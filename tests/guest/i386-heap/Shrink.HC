I64 HeapShrinkTest()
{//Owned module compaction needs exact size, retained bytes and reclaimed tail.
  CI386Heap hc;
  CI386HeapBlock *block;
  U8 *arena=0x48000,*p,*q,*r;
  I64 i,used,peak;
  U64 before;
  if(!I386HeapInit(&hc,arena,1024)) return 301;
  p=I386HeapAlloc(&hc,200); q=I386HeapAlloc(&hc,100);
  if(!p || !q) return 302;
  for(i=0;i<200;i++) p[i]=i;
  used=hc.used; peak=hc.peak; before=Hash(arena,1024);
  if(I386HeapShrink(&hc,0,1) || I386HeapShrink(&hc,p+1,1) ||
      I386HeapShrink(&hc,p,-1) || I386HeapShrink(&hc,p,201) ||
      I386HeapShrink(&hc,p,0x100000000) || Hash(arena,1024)!=before ||
      hc.used!=used || hc.allocations!=2) return 303;
  //An eight-byte tail cannot hold a free block; requested size still changes.
  if(!I386HeapShrink(&hc,p,192) || I386HeapSize(&hc,p)!=192 ||
      hc.used!=used || hc.peak!=peak || !I386HeapValid(&hc)) return 304;
  if(!I386HeapShrink(&hc,p,64) || I386HeapSize(&hc,p)!=64 ||
      hc.used!=used-136 || hc.allocations!=2 || hc.peak!=peak ||
      !I386HeapValid(&hc)) return 305;
  for(i=0;i<64;i++) if(p[i]!=i) return 306;
  r=I386HeapAlloc(&hc,120);
  if(r!=p+80 || !I386HeapFree(&hc,r) || !I386HeapFree(&hc,q)) return 307;
  //Shrinking beside a free block must merge tails, including the zero case.
  if(!I386HeapShrink(&hc,p,0) || I386HeapSize(&hc,p)!=0 ||
      hc.used!=24 || hc.allocations!=1 || !I386HeapValid(&hc)) return 308;
  r=I386HeapAlloc(&hc,984);
  if(!r || !I386HeapFree(&hc,r) || !I386HeapFree(&hc,p) ||
      hc.used || hc.allocations || !I386HeapValid(&hc)) return 309;
  before=Hash(arena,1024);
  if(I386HeapShrink(&hc,p,0) || Hash(arena,1024)!=before) return 310;
  p=I386HeapAlloc(&hc,64); q=I386HeapAlloc(&hc,64);
  block=q-16; block->reserved=1; before=Hash(arena,1024);
  if(I386HeapShrink(&hc,p,8) || Hash(arena,1024)!=before) return 311;
  block->reserved=0;
  if(!I386HeapFree(&hc,p) || !I386HeapFree(&hc,q)) return 312;
  return 0;
}
