#include "/Kernel/I386/Heap.HH"
//Caller supplies a readable control record and a writable, exclusively owned arena.
//Boot memory discovery must exclude firmware, devices, stacks and loaded images.
//No allocation, scheduler, exceptions, or host calls are required here.
Bool I386HeapRegionValid(CI386Heap *hc,U8 *base,I64 size)
{
  U64 a=(base+0)(U64),b=(hc+0)(U64);
  if (!hc || !base || a&7 || size<24 || size>0xFFFFFFFF || size&7)
    return FALSE;
  if ((base+size)(U64)<=a) return FALSE;
  if (a<=b) {
    if (b-a<size) return FALSE;
  } else if (a-b<sizeof(CI386Heap)) return FALSE;
  return TRUE;
}

public Bool I386HeapInit(CI386Heap *hc,U8 *base,I64 size)
{//Failure leaves both control and arena unchanged. Tail bytes below alignment are unused.
  CI386HeapBlock *block;
  if (size<24 || size>0xFFFFFFFF) return FALSE;
  size&=~7;
  if (!I386HeapRegionValid(hc,base,size)) return FALSE;
  block=base;
  block->span=size; block->requested=0;
  block->tag=I386_HEAP_FREE; block->reserved=0;
  hc->base=base; hc->size=size;
  hc->used=0; hc->peak=0; hc->allocations=0;
  hc->signature=I386_HEAP_MAGIC;
  return TRUE;
}

public Bool I386HeapValid(CI386Heap *hc)
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

public U8 *I386HeapAlloc(CI386Heap *hc,I64 size,Bool zero=FALSE)
{//Try-allocation: NULL on invalid size, corruption or exhaustion; no OutMem wrapper yet.
  CI386HeapBlock *block,*rest;
  U8 *result;
  I64 offset=0,need,i;
  if (size<0 || size>0xFFFFFFFF-23 || !I386HeapValid(hc)) return 0;
  need=(size+7)&~7;
  if (!need) need=8;
  need+=16;
  while (offset<hc->size) {
    block=hc->base+offset;
    if (block->tag==I386_HEAP_FREE && block->span>=need) {
      if (block->span-need>=24) {
        rest=hc->base+offset+need;
        rest->span=block->span-need; rest->requested=0;
        rest->tag=I386_HEAP_FREE; rest->reserved=0;
        block->span=need;
      }
      block->requested=size; block->tag=I386_HEAP_USED;
      hc->used+=block->span; hc->allocations++;
      if (hc->used>hc->peak) hc->peak=hc->used;
      result=hc->base+offset+16;
      if (zero) for (i=0;i<size;i++) result[i]=0;
      return result;
    }
    offset+=block->span;
  }
  return 0;
}

public I64 I386HeapSize(CI386Heap *hc,U8 *ptr)
{//Requested byte count, or -1 for an invalid or freed pointer.
  CI386HeapBlock *block;
  I64 offset=0;
  if (!ptr || !I386HeapValid(hc)) return -1;
  while (offset<hc->size) {
    block=hc->base+offset;
    if (hc->base+offset+16==ptr && block->tag==I386_HEAP_USED)
      return block->requested;
    offset+=block->span;
  }
  return -1;
}

public Bool I386HeapFree(CI386Heap *hc,U8 *ptr)
{//NULL is a no-op. Reject foreign/interior pointers and double frees without writes.
  CI386HeapBlock *block,*previous=0,*next;
  I64 offset=0;
  if (!ptr) return TRUE;
  if (!I386HeapValid(hc)) return FALSE;
  while (offset<hc->size) {
    block=hc->base+offset;
    if (hc->base+offset+16==ptr) {
      if (block->tag!=I386_HEAP_USED) return FALSE;
      hc->used-=block->span; hc->allocations--;
      block->tag=I386_HEAP_FREE; block->requested=0;
      if (offset+block->span<hc->size) {
        next=hc->base+offset+block->span;
        if (next->tag==I386_HEAP_FREE) block->span+=next->span;
      }
      if (previous && previous->tag==I386_HEAP_FREE) previous->span+=block->span;
      return TRUE;
    }
    previous=block;
    offset+=block->span;
  }
  return FALSE;
}
