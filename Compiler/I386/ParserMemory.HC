//Included after native control ownership and release helpers.
#include "/Compiler/I386/ParserMemory.HH"
#ifdef I386_PARSER_FAILURE_TRACE
U0 I386ParserFailure(U8 *label,CCmpCtrl *cc)
{//Allocation failure only; bounded native frame chain and no scratch heap.
#ifdef I386_FAILURE_CALLER_TRACE
  U32 *frame=GetRBP,address;
  U8 text[9],*digits="0123456789ABCDEF";
  I64 i,depth;
#endif
  KernelLog(label);
  if(cc->lex_include_stk && cc->lex_include_stk->full_name) KernelLog(cc->lex_include_stk->full_name);
#ifdef I386_FAILURE_CALLER_TRACE
  for(depth=0;depth<3 && frame;depth++) {
    address=frame[1];
    for(i=0;i<8;i++) text[7-i]=digits[(address>>(i*4))&15];
    text[8]=0; KernelLog(" "); KernelLog(text);
    frame=frame[0](U32 *);
  }
#endif
  KernelLog("\n");
}
#endif
U8 *I386ParserAlloc(CI386Heap *heap,CCmpCtrl *cc,I64 bytes,Bool zeroed=TRUE)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  U8 *allocation;
  U32 irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc) || bytes<1 || bytes>0x7FFFFFFF) {
    I386IrqRestore(irq); return 0;
  }
  allocation=I386HeapAlloc(heap,bytes,zeroed);
  if(!allocation) {
#ifdef I386_PARSER_FAILURE_TRACE
    I386ParserFailure("PARSER PAYLOAD ALLOCATION REJECT ",cc);
#endif
    I386IrqRestore(irq); throw('OutMem',TRUE);
  }
  record=I386HeapAllocHigh(heap,offset(CI386ParserAllocation.requested),TRUE);
  if(!record) {
    I386HeapFree(heap,allocation);
    I386IrqRestore(irq); throw('OutMem',TRUE);
  }
  record->allocation=allocation; record->next=&owned->parser_next;
  record->last=owned->parser_last; record->last->next=record; owned->parser_last=record;
  I386IrqRestore(irq); return allocation;
}
Bool I386ParserFree(CI386Heap *heap,CCmpCtrl *cc,U8 *allocation)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  CI386CmpRelease release;
  U32 irq=I386IrqSave;
  Bool found=FALSE;
  if(!I386CmpCodeOwner(heap,cc)) { I386IrqRestore(irq); return FALSE; }
  if(!allocation) { I386IrqRestore(irq); return TRUE; }
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
    if(record->allocation==allocation) { found=TRUE; break; }
  if(!found) { I386IrqRestore(irq); return FALSE; }
  release.heap=heap; release.control=cc; release.ok=TRUE;
  I386CmpReleaseAllocation(&release,allocation);
  I386IrqRestore(irq); return release.ok;
}

U8 *I386ParserCodeAlloc(CI386Heap *heap,CCmpCtrl *cc,I64 bytes)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  CI386TaskHeaps *owner;
  U8 *allocation=0;
  U32 irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc) || bytes<1 || bytes>0x7FFFFFFF) goto done;
  if(!owned->task || !owned->task->heap_state) {
    I386IrqRestore(irq); return I386ParserAlloc(heap,cc,bytes,FALSE);
  }
  owner=owned->task->heap_state;
  if(owner->task!=owned->task || owner->signature!=I386_TASK_HEAPS_MAGIC ||
      owned->task->code_heap!=&owner->control || !owner->code_allocate ||
      !owner->code_release || !owner->code_capacity) goto done;
  record=I386HeapAllocHigh(heap,sizeof(CI386ParserAllocation),TRUE);
  if(!record) goto exhausted;
  allocation=(*owner->code_allocate)(owner,bytes);
  if(!allocation) { I386HeapFree(heap,record); goto exhausted; }
  record->owner=owner; record->requested=bytes; record->allocation=allocation;
  record->next=&owned->parser_next; record->last=owned->parser_last;
  record->last->next=record; owned->parser_last=record;
done:
  I386IrqRestore(irq); return allocation;
exhausted:
#ifdef I386_PARSER_FAILURE_TRACE
  I386ParserFailure("PARSER CODE ALLOCATION REJECT ",cc);
#endif
  I386IrqRestore(irq); throw('OutMem',TRUE); return 0;
}
I64 I386ParserSize(CI386Heap *heap,CCmpCtrl *cc,U8 *allocation)
{//Publication compares logical output bytes, not rounded public allocation capacity.
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  I64 size=-1;
  U32 irq=I386IrqSave;
  if(!I386CmpControlValid(heap,cc)) goto done;
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
    if(record->allocation==allocation) {
      if(!record->owner) size=I386HeapSize(heap,allocation);
      else if(record->owner->code_capacity && record->requested &&
          (*record->owner->code_capacity)(record->owner,allocation)>=record->requested)
        size=record->requested;
      break;
    }
done:
  I386IrqRestore(irq); return size;
}

Bool I386ParserTake(CI386Heap *heap,CCmpCtrl *cc,U8 *allocation)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record;
  U32 irq=I386IrqSave;
  Bool result=FALSE;
  if(!I386CmpCodeOwner(heap,cc) || !allocation || I386HeapSize(heap,allocation)<1) goto done;
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
    if(record->allocation==allocation) goto done;
  record=I386HeapAllocHigh(heap,offset(CI386ParserAllocation.requested),TRUE);
  if(!record) goto done;
  record->allocation=allocation; record->next=&owned->parser_next;
  record->last=owned->parser_last; record->last->next=record; owned->parser_last=record;
  result=TRUE;
done:
  I386IrqRestore(irq); return result;
}
