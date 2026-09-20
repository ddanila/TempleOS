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

public Bool I386HeapValid(CI386Heap *hc)
{//Check the whole physical block chain before trusting metadata for mutation.
  //This hot loop uses bounded U32 arithmetic: each span is checked against the
  //remaining arena before advancing, so used/count cannot overflow. The region
  //check retains the wide address-overflow and control/arena overlap checks.
  Bool valid=FALSE;
  U32 last_free=0;
  if (!hc || hc->signature!=I386_HEAP_MAGIC ||
      !I386HeapRegionValid(hc,hc->base,hc->size) ||
      hc->peak>hc->size || hc->used>hc->peak) return FALSE;
  asm {
    MOV EBX,U32 &hc[EBP]
    MOV ESI,U32 CI386Heap.base[EBX]
    MOV ECX,U32 CI386Heap.size[EBX]
    XOR EDI,EDI
    XOR EDX,EDX
@@10:
    CMP ECX,24
    JB @@90
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    CMP EAX,24
    JB @@90
    TEST EAX,7
    JNZ @@90
    CMP EAX,ECX
    JA @@90
    CMP U32 CI386HeapBlock.reserved[ESI],0
    JNZ @@90
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_FREE
    JE @@30
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_USED
    JNE @@90
    SUB EAX,16
    CMP U32 CI386HeapBlock.requested[ESI],EAX
    JA @@90
    ADD EAX,16
    ADD EDI,EAX
    ADD EDX,1
    MOV U32 &last_free[EBP],0
    JMP @@40
@@30:
    CMP U32 &last_free[EBP],0
    JNZ @@90
    CMP U32 CI386HeapBlock.requested[ESI],0
    JNZ @@90
    MOV U32 &last_free[EBP],1
@@40:
    ADD ESI,EAX
    SUB ECX,EAX
    JNZ @@10
    CMP EDI,U32 CI386Heap.used[EBX]
    JNE @@90
    CMP EDX,U32 CI386Heap.allocations[EBX]
    JNE @@90
    MOV U8 &valid[EBP],1
@@90:
  }
  return valid;
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
