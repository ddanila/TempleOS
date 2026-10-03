#include "/Kernel/I386/Heap.HH"
//Caller supplies a readable control record and a writable, exclusively owned arena.
//Boot memory discovery must exclude firmware, devices, stacks and loaded images.
//No allocation, scheduler, exceptions, or host calls are required here.
Bool I386HeapRegionValid(CI386Heap *hc,U8 *base,I64 size)
{
  U64 a=(base+0)(U64),b=(hc+0)(U64);
  if (!hc || !base || a&7 || size<24 || size>0xFFFFFFFF || size&7)
    return FALSE;
  //Check the wide sum explicitly; pointer-expression evaluation need not wrap.
  if (a+size>0xFFFFFFFF) return FALSE;
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

