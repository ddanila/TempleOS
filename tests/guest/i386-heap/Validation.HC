//Keep the pre-optimization HolyC validator as an independent differential oracle.
Bool HeapValidReference(CI386Heap *hc)
{//Check the whole physical block chain before trusting metadata for mutation.
  CI386HeapBlock *block;
  I64 offset=0,used=0,count=0;
  Bool last_free=FALSE;
  if (!hc || hc->signature!=I386_HEAP_MAGIC ||
      !I386HeapRegionValid(hc,hc->base,hc->size) ||
      hc->peak>hc->size || hc->used>hc->peak) return FALSE;
  while (offset<hc->size) {
    if (hc->size-offset<24) return FALSE;
    block=hc->base+offset;
    if (block->span<24 || block->span&7 || block->span>hc->size-offset ||
        block->reserved) return FALSE;
    if (block->tag==I386_HEAP_FREE) {
      if (last_free || block->requested) return FALSE;
      last_free=TRUE;
    } else if (block->tag==I386_HEAP_USED) {
      if (block->requested>block->span-16) return FALSE;
      used+=block->span; count++;
      last_free=FALSE;
    } else return FALSE;
    offset+=block->span;
  }
  return used==hc->used && count==hc->allocations;
}

I64 HeapValidationTest(CI386Heap *hc,U8 *arena)
{
  U8 *p,*q,*r;
  CI386HeapBlock *blocks[4];
  U32 *word,old,values[8];
  I64 i,j,k,checks=0;
  U64 before;
  if(!I386HeapInit(hc,arena,256)) return 301;
  p=I386HeapAlloc(hc,0); q=I386HeapAlloc(hc,7); r=I386HeapAlloc(hc,33);
  if(!p || !q || !r) return 302;
  blocks[0]=p-16; blocks[1]=q-16; blocks[2]=r-16;
  blocks[3]=(r-16)+blocks[2]->span;
  values[0]=0; values[1]=1; values[2]=7; values[3]=16;
  values[4]=23; values[5]=24; values[6]=32; values[7]=0xFFFFFFFF;
  //Corrupt each header word, including later headers after a valid early block.
  //Neither implementation may write the arena or stop after finding one block.
  for(i=0;i<4;i++) for(j=0;j<4;j++) {
    word=blocks[i]; word+=j; old=*word;
    for(k=0;k<8;k++) {
      *word=values[k]; before=Hash(arena,256);
      if(I386HeapValid(hc)!=HeapValidReference(hc) || Hash(arena,256)!=before) return 303;
      checks++;
    }
    *word=old;
  }
  //Allocation counters/signature and the unused reserved header word remain
  //part of validation, including zero-sized allocation requested lengths.
  for(i=0;i<4;i++) {
    if(i==0) word=&hc->used;
    if(i==1) word=&hc->peak;
    if(i==2) word=&hc->allocations;
    if(i==3) word=&hc->signature;
    old=*word;
    for(k=0;k<8;k++) {
      *word=values[k]; before=Hash(arena,256);
      if(I386HeapValid(hc)!=HeapValidReference(hc) || Hash(arena,256)!=before) return 304;
      checks++;
    }
    *word=old;
  }
  if(checks!=160 || !I386HeapValid(hc) || !HeapValidReference(hc)) return 305;
  blocks[3]->reserved=1; before=Hash(arena,256);
  if(I386HeapSize(hc,p)!=-1 || I386HeapAlloc(hc,1) || I386HeapFree(hc,p) ||
      Hash(arena,256)!=before) return 306;
  blocks[3]->reserved=0;
  if(!I386HeapFree(hc,p) || !I386HeapFree(hc,q) || !I386HeapFree(hc,r) ||
      !I386HeapValid(hc) || !HeapValidReference(hc) || hc->used || hc->allocations) return 307;
  return 0;
}
