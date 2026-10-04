#include "/Kernel/I386/HeapInit.HC"

//The guest source compiler uses the portable validator until it can rebuild
//the 386 assembly block. Both paths validate and locate in one full scan.
#ifdef I386_HEAP_SOURCE_BUILD
I64 I386HeapScan(CI386Heap *hc,U8 *ptr)
{//Check the whole physical block chain before trusting metadata for mutation.
  //Each span is bounded by the remaining arena before advancing the cursor.
  //Thus the accumulated used bytes and block count cannot overflow U32.
  CI386HeapBlock *block;
  U8 *cursor;
  U32 remaining,span,used=0,count=0;
  Bool last_free=FALSE;
  I64 requested=-1;
  if (!hc || hc->signature!=I386_HEAP_MAGIC ||
      !I386HeapRegionValid(hc,hc->base,hc->size) ||
      hc->peak>hc->size || hc->used>hc->peak) return -1;
  cursor=hc->base; remaining=hc->size;
  while(remaining) {
    if(remaining<24) return -1;
    block=cursor; span=block->span;
    if(span<24 || span&7 || span>remaining || block->reserved) return -1;
    if(block->tag==I386_HEAP_FREE) {
      if(last_free || block->requested) return -1;
      last_free=TRUE;
    } else if(block->tag==I386_HEAP_USED) {
      if(block->requested>span-16) return -1;
      if(cursor+16==ptr) requested=block->requested;
      used+=span; count++;
      last_free=FALSE;
    } else return -1;
    cursor+=span; remaining-=span;
  }
  if(used!=hc->used || count!=hc->allocations) return -1;
  if(!ptr) return 0;
  return requested;
}

#else
I64 I386HeapScan(CI386Heap *hc,U8 *ptr)
{//Check the whole physical block chain before trusting metadata for mutation.
  //This hot loop uses bounded U32 arithmetic: each span is checked against the
  //remaining arena before advancing, so used/count cannot overflow. The region
  //check retains the wide address-overflow and control/arena overlap checks.
  Bool valid=FALSE;
  U32 last_free=0,requested=0xFFFFFFFF;
  U8 *target=ptr-16;
  if (!hc || hc->signature!=I386_HEAP_MAGIC ||
      !I386HeapRegionValid(hc,hc->base,hc->size) ||
      hc->peak>hc->size || hc->used>hc->peak) return -1;
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
    CMP ESI,U32 &target[EBP]
    JNE @@40
    PUSH EAX
    MOV EAX,U32 CI386HeapBlock.requested[ESI]
    MOV U32 &requested[EBP],EAX
    POP EAX
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
  //No requested size can equal the sentinel: every arena needs a header.
  if(!valid) return -1;
  if(!ptr) return 0;
  if(requested==0xFFFFFFFF) return -1;
  return requested;
}

#endif
public Bool I386HeapValid(CI386Heap *hc)
{
  return I386HeapScan(hc,0)>=0;
}

public U8 *I386HeapAlloc(CI386Heap *hc,I64 size,Bool zero=FALSE)
{//Validate all metadata before locating a first-fit block and mutating the arena.
  CI386HeapBlock *block=0,*rest;
  U8 *result;
  U32 offset=0,need,i,requested;
  if(size<0 || size>0xFFFFFFFF-23 || !I386HeapValid(hc)) return 0;
  requested=size; need=(size+7)&~7;
  if(!need) need=8;
  need+=16;
#ifdef I386_HEAP_SOURCE_BUILD
  while(offset<hc->size) {
    block=hc->base+offset;
    if(block->tag==I386_HEAP_FREE && block->span>=need) break;
    offset+=block->span;
  }
  if(offset>=hc->size) return 0;
#else
  asm {
    MOV EBX,U32 &hc[EBP]
    MOV ESI,U32 CI386Heap.base[EBX]
    MOV ECX,U32 CI386Heap.size[EBX]
    XOR EDX,EDX
@@10:
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_FREE
    JNE @@20
    CMP EAX,U32 &need[EBP]
    JB @@20
    MOV U32 &block[EBP],ESI
    MOV U32 &offset[EBP],EDX
    JMP @@90
@@20:
    ADD ESI,EAX
    ADD EDX,EAX
    SUB ECX,EAX
    JNZ @@10
@@90:
  }
  if(!block) return 0;
#endif
  if(block->span-need>=24) {
    rest=hc->base+offset+need;
    rest->span=block->span-need; rest->requested=0;
    rest->tag=I386_HEAP_FREE; rest->reserved=0;
    block->span=need;
  }
  block->requested=size; block->tag=I386_HEAP_USED;
  hc->used+=block->span; hc->allocations++;
  if(hc->used>hc->peak) hc->peak=hc->used;
  result=hc->base+offset+16;
  if(zero) for(i=0;i<requested;i++) result[i]=0;
  return result;
}

public I64 I386HeapSize(CI386Heap *hc,U8 *ptr)
{//Requested byte count, or -1 for an invalid or freed pointer.
  //Do not accept an early match until later blocks and counters are checked.
  if(!ptr) return -1;
  return I386HeapScan(hc,ptr);
}

public Bool I386HeapFree(CI386Heap *hc,U8 *ptr)
{//NULL is a no-op; the entire arena must validate before any mutation.
  CI386HeapBlock *block=0,*previous=0,*next;
  U8 *target=ptr-16;
  U32 offset=0;
  if(!ptr) return TRUE;
  if(!I386HeapValid(hc)) return FALSE;
#ifdef I386_HEAP_SOURCE_BUILD
  while(offset<hc->size) {
    block=hc->base+offset;
    if(hc->base+offset+16==ptr) break;
    previous=block; offset+=block->span;
  }
  if(offset>=hc->size) return FALSE;
#else
  asm {
    MOV EBX,U32 &hc[EBP]
    MOV ESI,U32 CI386Heap.base[EBX]
    MOV ECX,U32 CI386Heap.size[EBX]
    XOR EDI,EDI
    XOR EDX,EDX
@@10:
    CMP ESI,U32 &target[EBP]
    JNE @@20
    MOV U32 &block[EBP],ESI
    MOV U32 &previous[EBP],EDI
    MOV U32 &offset[EBP],EDX
    JMP @@90
@@20:
    MOV EDI,ESI
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    ADD ESI,EAX
    ADD EDX,EAX
    SUB ECX,EAX
    JNZ @@10
@@90:
  }
  if(!block) return FALSE;
#endif
  if(block->tag!=I386_HEAP_USED) return FALSE;
  hc->used-=block->span; hc->allocations--;
  block->tag=I386_HEAP_FREE; block->requested=0;
  if(offset+block->span<hc->size) {
    next=hc->base+offset+block->span;
    if(next->tag==I386_HEAP_FREE) block->span+=next->span;
  }
  if(previous && previous->tag==I386_HEAP_FREE) previous->span+=block->span;
  return TRUE;
}
