#include "/Kernel/I386/HeapInit.HC"

//The guest source compiler uses the portable validator until it can rebuild
//the 386 assembly block. Both paths validate and locate in one full scan.
#ifdef I386_HEAP_SOURCE_BUILD
I64 I386HeapScanSelect(CI386Heap *hc,U8 *ptr,U32 need,CI386HeapBlock **selected,Bool first=FALSE)
{//Check the whole physical block chain before trusting metadata for mutation.
  //Each span is bounded by the remaining arena before advancing the cursor.
  //Thus the accumulated used bytes and block count cannot overflow U32.
  CI386HeapBlock *block;
  U8 *cursor;
  U32 remaining,span,used=0,count=0;
  Bool last_free=FALSE;
  I64 requested=-1;
  CI386HeapBlock *candidate=0;
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
      if(need && span>=need && (!first || !candidate)) candidate=block;
    } else if(block->tag==I386_HEAP_USED) {
      if(block->requested>span-16) return -1;
      if(cursor+16==ptr) requested=block->requested;
      used+=span; count++;
      last_free=FALSE;
    } else return -1;
    cursor+=span; remaining-=span;
  }
  if(used!=hc->used || count!=hc->allocations) return -1;
  if(selected) *selected=candidate;
  if(!ptr) return 0;
  return requested;
}

#else
I64 I386HeapScanSelect(CI386Heap *hc,U8 *ptr,U32 need,CI386HeapBlock **selected,Bool first=FALSE)
{//Check the whole physical block chain before trusting metadata for mutation.
  //This hot loop uses bounded U32 arithmetic: each span is checked against the
  //remaining arena before advancing, so used/count cannot overflow. The region
  //check retains the wide address-overflow and control/arena overlap checks.
  Bool valid=FALSE;
  U32 requested=0xFFFFFFFF;
  CI386HeapBlock *candidate=0;
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
    XOR EBX,EBX //Previous block was free; keep it off the stack in the hot loop.
@@10:
    CMP ECX,24
    JB I32 @@90
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    CMP EAX,24
    JB I32 @@90
    TEST EAX,7
    JNZ I32 @@90
    CMP EAX,ECX
    JA I32 @@90
    CMP U32 CI386HeapBlock.reserved[ESI],0
    JNZ I32 @@90
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_USED
    JNE @@30
    //A used block ends the free run, so EBX can first hold its payload bound.
    LEA EBX,U32 -16[EAX]
    CMP U32 CI386HeapBlock.requested[ESI],EBX
    JA I32 @@90
    ADD EDI,EAX
    ADD EDX,1
    XOR EBX,EBX
    CMP ESI,U32 &target[EBP]
    JNE @@40
    PUSH EAX
    MOV EAX,U32 CI386HeapBlock.requested[ESI]
    MOV U32 &requested[EBP],EAX
    POP EAX
    JMP @@40
@@30:
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_FREE
    JNE I32 @@90
    TEST EBX,EBX
    JNZ I32 @@90
    CMP U32 CI386HeapBlock.requested[ESI],0
    JNZ I32 @@90
    MOV EBX,1
    CMP U32 &need[EBP],0
    JE @@40
    CMP EAX,U32 &need[EBP]
    JB @@40
    CMP U8 &first[EBP],0
    JE @@35
    CMP U32 &candidate[EBP],0
    JNE @@40
@@35:
    MOV U32 &candidate[EBP],ESI
@@40:
    ADD ESI,EAX
    SUB ECX,EAX
    JNZ I32 @@10
    MOV EBX,U32 &hc[EBP]
    CMP EDI,U32 CI386Heap.used[EBX]
    JNE I32 @@90
    CMP EDX,U32 CI386Heap.allocations[EBX]
    JNE I32 @@90
    MOV U8 &valid[EBP],1
@@90:
  }
  //No requested size can equal the sentinel: every arena needs a header.
  if(!valid) return -1;
  if(selected) *selected=candidate;
  if(!ptr) return 0;
  if(requested==0xFFFFFFFF) return -1;
  return requested;
}

#endif
I64 I386HeapScan(CI386Heap *hc,U8 *ptr)
{
#ifdef I386_HEAP_SOURCE_BUILD
  return I386HeapScanSelect(hc,ptr,0,0);
#else
  //A size/validity query never selects a free block. Keep its hot traversal
  //separate from first/last-fit selection while retaining the complete audit.
  Bool valid=FALSE;
  U32 requested=0xFFFFFFFF;
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
    XOR EBX,EBX
@@10:
    CMP ECX,24
    JB I32 @@90
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    CMP EAX,24
    JB I32 @@90
    TEST EAX,7
    JNZ I32 @@90
    CMP EAX,ECX
    JA I32 @@90
    CMP U32 CI386HeapBlock.reserved[ESI],0
    JNZ I32 @@90
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_USED
    JNE @@30
    LEA EBX,U32 -16[EAX]
    CMP U32 CI386HeapBlock.requested[ESI],EBX
    JA I32 @@90
    ADD EDI,EAX
    ADD EDX,1
    XOR EBX,EBX
    CMP ESI,U32 &target[EBP]
    JNE @@40
    PUSH EAX
    MOV EAX,U32 CI386HeapBlock.requested[ESI]
    MOV U32 &requested[EBP],EAX
    POP EAX
    JMP @@40
@@30:
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_FREE
    JNE I32 @@90
    TEST EBX,EBX
    JNZ I32 @@90
    CMP U32 CI386HeapBlock.requested[ESI],0
    JNZ I32 @@90
    MOV EBX,1
@@40:
    ADD ESI,EAX
    SUB ECX,EAX
    JNZ I32 @@10
    MOV EBX,U32 &hc[EBP]
    CMP EDI,U32 CI386Heap.used[EBX]
    JNE I32 @@90
    CMP EDX,U32 CI386Heap.allocations[EBX]
    JNE I32 @@90
    MOV U8 &valid[EBP],1
@@90:
  }
  if(!valid) return -1;
  if(!ptr) return 0;
  if(requested==0xFFFFFFFF) return -1;
  return requested;
#endif
}
public Bool I386HeapValid(CI386Heap *hc)
{
  return I386HeapScan(hc,0)>=0;
}

#ifdef I386_HEAP_FAILURE_TRACE
U0 I386HeapExhausted(CI386Heap *hc,I64 request)
{//Allocation failure only: report physical capacity without allocating scratch.
  CI386HeapBlock *block;
  U32 offset=0,largest=0;
#ifdef I386_ARENA_CALLER_TRACE
  U32 *frame=GetRBP;
#endif
  while(offset<hc->size) {
    block=hc->base+offset;
    if(block->tag==I386_HEAP_FREE && block->span-16>largest)
      largest=block->span-16;
    offset+=block->span;
  }
  KernelLog("HEAP EXHAUSTED "); KernelHex(request); KernelLog(" ");
  KernelHex(hc->used); KernelLog(" "); KernelHex(hc->size); KernelLog(" ");
  KernelHex(largest); KernelLog(" "); KernelHex(hc->allocations); KernelLog("\n");
#ifdef I386_ARENA_CALLER_TRACE
  //Skip this logger and show the allocator's caller and its parent.
  if(frame) frame=frame[0](U32 *);
  KernelLog("HEAP FAILURE CALLERS");
  if(frame) {
    KernelLog(" "); KernelHex(frame[1]);
    frame=frame[0](U32 *);
    if(frame) { KernelLog(" "); KernelHex(frame[1]); }
  }
  KernelLog("\n");
#endif
}
#endif

public U8 *I386HeapAlloc(CI386Heap *hc,I64 size,Bool zero=FALSE)
{//Validate all metadata before locating a first-fit block and mutating the arena.
  CI386HeapBlock *block=0,*rest;
  U8 *result;
  U32 offset=0,need,i,requested;
  if(size<0 || size>0xFFFFFFFF-23) return 0;
  requested=size; need=(size+7)&~7;
  if(!need) need=8;
  need+=16;
  //Remember the first fit, but finish validation before publishing or mutating it.
  if(I386HeapScanSelect(hc,0,need,&block,TRUE)<0)return 0;
  if(!block) {
#ifdef I386_HEAP_FAILURE_TRACE
    I386HeapExhausted(hc,size);
#endif
    return 0;
  }
  offset=block(U8 *)-hc->base;
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

//Caller holds heap exclusion across this operation. Validate a prior payload and
//select the first fit in the same complete traversal; invalid guards do not mutate.
public U8 *I386HeapAllocGuarded(CI386Heap *hc,I64 size,U8 *guard,Bool *guard_valid)
{
  CI386HeapBlock *block=0,*rest;
  U8 *result;
  U32 offset,need;
  I64 found;
  *guard_valid=FALSE;
  if(size<0 || size>0xFFFFFFFF-23) {
    if(!guard || I386HeapScan(hc,guard)>=1) *guard_valid=TRUE;
    return 0;
  }
  need=(size+7)&~7;
  if(!need)need=8;
  need+=16;
  found=I386HeapScanSelect(hc,guard,need,&block,TRUE);
  if(guard && found<1)return 0;
  *guard_valid=TRUE;
  if(found<0)return 0;
  if(!block) {
#ifdef I386_HEAP_FAILURE_TRACE
    I386HeapExhausted(hc,size);
#endif
    return 0;
  }
  offset=block(U8 *)-hc->base;
  if(block->span-need>=24) {
    rest=hc->base+offset+need;
    rest->span=block->span-need;rest->requested=0;
    rest->tag=I386_HEAP_FREE;rest->reserved=0;
    block->span=need;
  }
  block->requested=size;block->tag=I386_HEAP_USED;
  hc->used+=block->span;hc->allocations++;
  if(hc->used>hc->peak)hc->peak=hc->used;
  result=hc->base+offset+16;
  return result;
}

public U8 *I386HeapAllocHigh(CI386Heap *hc,I64 size,Bool zero=FALSE)
{//Validate the complete arena; use the high end of the last fitting free block.
  CI386HeapBlock *block=0;
  U8 *result;
  U32 need,prefix,i,requested;
  if(size<0 || size>0xFFFFFFFF-23)return 0;
  requested=size;need=(size+7)&~7;
  if(!need)need=8;
  need+=16;
  //Select while validating; publish the candidate only after all counters match.
  if(I386HeapScanSelect(hc,0,need,&block)<0)return 0;
  if(!block) {
#ifdef I386_HEAP_FAILURE_TRACE
    I386HeapExhausted(hc,size);
#endif
    return 0;
  }
  prefix=block->span-need;
  if(prefix>=24) {
    block->span=prefix;
    block=block(U8 *)+prefix;
    block->span=need;block->reserved=0;
  }
  block->requested=size;block->tag=I386_HEAP_USED;
  hc->used+=block->span;hc->allocations++;
  if(hc->used>hc->peak)hc->peak=hc->used;
  result=block(U8 *)+16;
  if(zero)for(i=0;i<requested;i++)result[i]=0;
  return result;
}

public I64 I386HeapSize(CI386Heap *hc,U8 *ptr)
{//Requested byte count, or -1 for an invalid or freed pointer.
  //Do not accept an early match until later blocks and counters are checked.
  if(!ptr) return -1;
  return I386HeapScan(hc,ptr);
}

public Bool I386HeapFree(CI386Heap *hc,U8 *ptr)
{//NULL is a no-op; validate every block and counter before mutating anything.
  CI386HeapBlock *block=0,*previous=0,*next;
  U8 *target=ptr-16;
#ifdef I386_HEAP_SOURCE_BUILD
  CI386HeapBlock *cursor,*last_free=0;
  U32 remaining,span,used=0,count=0;
#else
  Bool valid=FALSE;
#endif
  if(!ptr)return TRUE;
  if(!hc || hc->signature!=I386_HEAP_MAGIC ||
      !I386HeapRegionValid(hc,hc->base,hc->size) ||
      hc->peak>hc->size || hc->used>hc->peak)return FALSE;
#ifdef I386_HEAP_SOURCE_BUILD
  cursor=hc->base;remaining=hc->size;
  while(remaining) {
    if(remaining<24)return FALSE;
    span=cursor->span;
    if(span<24 || span&7 || span>remaining || cursor->reserved)return FALSE;
    if(cursor->tag==I386_HEAP_USED) {
      if(cursor->requested>span-16)return FALSE;
      if(cursor==target) {block=cursor;previous=last_free;}
      used+=span;count++;last_free=0;
    } else if(cursor->tag==I386_HEAP_FREE) {
      if(last_free || cursor->requested)return FALSE;
      last_free=cursor;
    } else return FALSE;
    cursor=cursor(U8 *)+span;remaining-=span;
  }
  if(used!=hc->used || count!=hc->allocations || !block)return FALSE;
#else
  //The prior-free pointer is also the free-run flag. Remember a target only
  //while validating, but do not write the arena until the final counters pass.
  asm {
    MOV EBX,U32 &hc[EBP]
    MOV ESI,U32 CI386Heap.base[EBX]
    MOV ECX,U32 CI386Heap.size[EBX]
    XOR EDI,EDI
    XOR EDX,EDX
    XOR EBX,EBX
@@10:
    CMP ECX,24
    JB I32 @@90
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    CMP EAX,24
    JB I32 @@90
    TEST EAX,7
    JNZ I32 @@90
    CMP EAX,ECX
    JA I32 @@90
    CMP U32 CI386HeapBlock.reserved[ESI],0
    JNZ I32 @@90
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_USED
    JNE @@30
    SUB EAX,16
    CMP U32 CI386HeapBlock.requested[ESI],EAX
    JA I32 @@90
    ADD EAX,16
    CMP ESI,U32 &target[EBP]
    JNE @@20
    MOV U32 &block[EBP],ESI
    MOV U32 &previous[EBP],EBX
@@20:
    ADD EDI,EAX
    INC EDX
    XOR EBX,EBX
    JMP @@40
@@30:
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_FREE
    JNE I32 @@90
    TEST EBX,EBX
    JNZ I32 @@90
    CMP U32 CI386HeapBlock.requested[ESI],0
    JNZ I32 @@90
    MOV EBX,ESI
@@40:
    ADD ESI,EAX
    SUB ECX,EAX
    JNZ I32 @@10
    MOV EBX,U32 &hc[EBP]
    CMP EDI,U32 CI386Heap.used[EBX]
    JNE I32 @@90
    CMP EDX,U32 CI386Heap.allocations[EBX]
    JNE I32 @@90
    MOV U8 &valid[EBP],1
@@90:
  }
  if(!valid || !block)return FALSE;
#endif
  hc->used-=block->span;hc->allocations--;
  block->tag=I386_HEAP_FREE;block->requested=0;
  if(block(U8 *)+block->span<hc->base+hc->size) {
    next=block(U8 *)+block->span;
    if(next->tag==I386_HEAP_FREE)block->span+=next->span;
  }
  if(previous)previous->span+=block->span;
  return TRUE;
}

public Bool I386HeapShrink(CI386Heap *hc,U8 *ptr,I64 size)
{//Shrink an owned allocation in place; validate the entire arena before writes.
  CI386HeapBlock *block,*rest,*next;
  U32 need,tail,span;
  I64 old_size=I386HeapSize(hc,ptr);
  if(old_size<0 || size<0 || size>old_size) return FALSE;
  block=ptr-16; span=block->span;
  need=(size+7)&~7;
  if(!need) need=8;
  need+=16; tail=span-need;
  if(tail>=24) {
    rest=(ptr-16)+need;
    //Read the old successor before writing the new free-block header.
    if((ptr-16)+span<hc->base+hc->size) {
      next=(ptr-16)+span;
      if(next->tag==I386_HEAP_FREE) tail+=next->span;
    }
    rest->span=tail; rest->requested=0;
    rest->tag=I386_HEAP_FREE; rest->reserved=0;
    block->span=need; hc->used-=span-need;
  }
  block->requested=size;
  return TRUE;
}
