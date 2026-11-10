#ifdef I386_PARSER_FAILURE_TRACE
extern U0 I386ParserFailure(U8 *label,CCmpCtrl *cc);
#endif
//Included after native Control.HC; the containing module supplies throw.
#include "/Compiler/I386/NativeEmit.HH"
#include "/Compiler/I386/EmitCore.HC"
//Implemented later by ParserMemory.HC in this same retained module.
extern U8 *I386ParserHeapAllocKnown(CI386Heap *heap,I64 bytes,Bool zeroed,Bool high);
#define I386_OUT_CHUNK_BYTES 512
class CI386OutChunk {
  CI386OutChunk *next;
  I64 start,bytes;
  U8 body[I386_OUT_CHUNK_BYTES];
};
class CI386OwnedOut {
  CI386Out out;
  CI386Heap *heap;
  CCmpCtrl *cc;
  CI386CodeAllocation lifetime;
  CI386OutChunk *chunks,*last_chunk,*cached_chunk;
};
Bool I386OutValid(CI386Heap *heap,CCmpCtrl *cc,CI386Out *out)
{
  CI386OwnedOut *owned=out;
  U32 irq=I386IrqSave;
  //Some callers enter without exclusion. Keep the owner audit and the actual
  //physical-boundary size lookup together; cache no proof across exclusion.
  Bool valid=I386CmpCodeOwner(heap,cc) && out &&
    I386HeapKnownSize(heap,out,sizeof(CI386OwnedOut)) && owned->heap==heap && owned->cc==cc &&
    owned->lifetime.control==cc && owned->lifetime.allocation==out && (owned->lifetime.kind==5 || owned->lifetime.kind==I386_CODE_SEGMENTED_OUT);
  I386IrqRestore(irq);return valid;
}
U0 I386NativeOutReserve(CI386Out *out,I64 minimum)
{
  CI386OwnedOut *owned=out;
  I64 capacity=I386OutCapacity(out,minimum),i;
  U8 *next;
  U32 irq=I386IrqSave;
  if(!I386OutValid(owned->heap,owned->cc,out) || !capacity ||
      (out->data && !I386HeapKnownSize(owned->heap,out->data,out->capacity))) {
    I386IrqRestore(irq); throw('Compiler',TRUE);
  }
  if(capacity<=out->capacity) { I386IrqRestore(irq); return; }
  next=I386ParserHeapAllocKnown(owned->heap,capacity,FALSE,FALSE);
  if(!next) {
#ifdef I386_PARSER_FAILURE_TRACE
    I386ParserFailure("EMITTER BUFFER ALLOCATION REJECT ",owned->cc);
#endif
    I386IrqRestore(irq); throw('OutMem',TRUE);
  }
  for(i=0;i<out->count;i++) next[i]=out->data[i];
  if(out->data && !I386HeapFree(owned->heap,out->data)) {
    I386HeapFree(owned->heap,next); I386IrqRestore(irq); throw('Compiler',TRUE);
  }
  out->data=next; out->capacity=capacity;
  I386IrqRestore(irq);
}
CI386Out *I386OutNew(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386OwnedOut *owned;
  U32 irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc)) { I386IrqRestore(irq); return 0; }
  owned=I386ParserHeapAllocKnown(heap,sizeof(CI386OwnedOut),TRUE,FALSE);
  if(!owned) { I386IrqRestore(irq); throw('OutMem',TRUE); }
  owned->heap=heap; owned->cc=cc; owned->out.reserve=&I386NativeOutReserve;
  I386CodeAttach(cc,&owned->lifetime,owned,5);
  I386IrqRestore(irq); return owned;
}
//Segmented scratch is private to the retained frontend. Its registered output
//header owns every chunk, including partial growth during control unwind.
U8 *I386SegmentedOutAddress(CI386Out *out,I64 offset)
{
  CI386OwnedOut *owned=out;
  CI386OutChunk *chunk=owned->cached_chunk;
  if(offset<0 || offset>=out->capacity)throw('Compiler',TRUE);
  if(!chunk || offset<chunk->start)chunk=owned->chunks;
  while(chunk && offset>=chunk->start+chunk->bytes)chunk=chunk->next;
  if(!chunk)throw('Compiler',TRUE);
  owned->cached_chunk=chunk;return chunk->body+offset-chunk->start;
}
U0 I386SegmentedOutReserve(CI386Out *out,I64 minimum)
{
  CI386OwnedOut *owned=out;
  CI386OutChunk *chunk;
  CI386HeapBlock *block;
  I64 capacity=I386OutCapacity(out,minimum),wanted,bytes=0,available;
  U32 irq=I386IrqSave,position=0;
  if(!I386OutValid(owned->heap,owned->cc,out) || !capacity || owned->lifetime.kind!=I386_CODE_SEGMENTED_OUT ||
      minimum!=out->count+1 || out->count!=out->capacity ||
      out->address!=&I386SegmentedOutAddress) {
    I386IrqRestore(irq);throw('Compiler',TRUE);
  }
  wanted=capacity-out->count;
  if(wanted>I386_OUT_CHUNK_BYTES)wanted=I386_OUT_CHUNK_BYTES;
  //OutValid has validated the entire arena; retain IRQ exclusion while finding
  //the largest useful window and allocating from that unchanged valid arena.
  while(position<owned->heap->size) {
    block=owned->heap->base+position;
    if(block->tag==I386_HEAP_FREE && block->span>16+offset(CI386OutChunk.body)) {
      available=block->span-16-offset(CI386OutChunk.body);
      if(available>wanted)available=wanted;
      if(available>bytes)bytes=available;
      if(bytes==wanted)break;
    }
    position+=block->span;
  }
  if(!bytes) {
#ifdef I386_PARSER_FAILURE_TRACE
    I386ParserFailure("EMITTER CHUNK SPACE REJECT ",owned->cc);
#endif
    I386IrqRestore(irq);throw('OutMem',TRUE);
  }
  chunk=I386ParserHeapAllocKnown(owned->heap,offset(CI386OutChunk.body)+bytes,TRUE,FALSE);
  if(!chunk) {
#ifdef I386_PARSER_FAILURE_TRACE
    I386ParserFailure("EMITTER CHUNK ALLOCATION REJECT ",owned->cc);
#endif
    I386IrqRestore(irq);throw('OutMem',TRUE);
  }
  chunk->start=out->count;chunk->bytes=bytes;
  if(owned->last_chunk)owned->last_chunk->next=chunk;
  else owned->chunks=chunk;
  owned->last_chunk=chunk;
  out->data=chunk->body;out->window_start=chunk->start;
  out->capacity=chunk->start+bytes;I386IrqRestore(irq);
}
CI386Out *I386OutNewSegmented(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386Out *out=I386OutNew(heap,cc);
  CI386OwnedOut *owned=out;
  if(out) {
    owned->lifetime.kind=I386_CODE_SEGMENTED_OUT; //Header owns no contiguous data allocation.
    out->reserve=&I386SegmentedOutReserve;
    out->address=&I386SegmentedOutAddress;
  }
  return out;
}
Bool I386OutChunksRelease(CI386Heap *heap,CI386Out *out)
{//The owning header stays registered until every raw chunk has been released.
  CI386OwnedOut *owned=out;
  CI386OutChunk *chunk,*next;
  U32 irq=I386IrqSave;
  Bool result=TRUE;
  while(chunk=owned->chunks) {
    if(I386HeapSize(heap,chunk)<offset(CI386OutChunk.body)+1) {result=FALSE;break;}
    next=chunk->next;
    if(!I386HeapFree(heap,chunk)) {result=FALSE;break;}
    owned->chunks=next;
  }
  owned->cached_chunk=0;
  if(!owned->chunks)owned->last_chunk=0;
  I386IrqRestore(irq);return result;
}
Bool I386OutDel(CI386Heap *heap,CCmpCtrl *cc,CI386Out *out)
{
  CI386OwnedOut *owned=out;
  CI386CmpRelease state;
  U32 irq=I386IrqSave;
  if(!I386OutValid(heap,cc,out)) { I386IrqRestore(irq); return FALSE; }
  state.heap=heap; state.control=cc; state.ok=TRUE;
  if(owned->lifetime.kind==5)I386CmpReleaseAllocation(&state,out->data);
  if(owned->lifetime.kind==I386_CODE_SEGMENTED_OUT && !I386OutChunksRelease(heap,out))state.ok=FALSE;
  if(state.ok) I386CodeFree(&state,&owned->lifetime);
  I386IrqRestore(irq); return state.ok;
}
