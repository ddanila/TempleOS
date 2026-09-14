//Included after native Control.HC; the containing module supplies throw.
#include "/Compiler/I386/NativeEmit.HH"
#include "/Compiler/I386/EmitCore.HC"
class CI386OwnedOut {
  CI386Out out;
  CI386Heap *heap;
  CCmpCtrl *cc;
  CI386CodeAllocation lifetime;
};
Bool I386OutValid(CI386Heap *heap,CCmpCtrl *cc,CI386Out *out)
{
  CI386OwnedOut *owned=out;
  return I386CmpCodeOwner(heap,cc) && out &&
    I386HeapSize(heap,out)==sizeof(CI386OwnedOut) && owned->heap==heap && owned->cc==cc &&
    owned->lifetime.control==cc && owned->lifetime.allocation==out && owned->lifetime.kind==5;
}
U0 I386NativeOutReserve(CI386Out *out,I64 minimum)
{
  CI386OwnedOut *owned=out;
  I64 capacity=I386OutCapacity(out,minimum),i;
  U8 *next;
  U32 irq=I386IrqSave;
  if(!I386OutValid(owned->heap,owned->cc,out) || !capacity ||
      (out->data && I386HeapSize(owned->heap,out->data)!=out->capacity)) {
    I386IrqRestore(irq); throw('Compiler',TRUE);
  }
  if(capacity<=out->capacity) { I386IrqRestore(irq); return; }
  next=I386HeapAlloc(owned->heap,capacity,FALSE);
  if(!next) { I386IrqRestore(irq); throw('OutMem',TRUE); }
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
  owned=I386HeapAlloc(heap,sizeof(CI386OwnedOut),TRUE);
  if(!owned) { I386IrqRestore(irq); throw('OutMem',TRUE); }
  owned->heap=heap; owned->cc=cc; owned->out.reserve=&I386NativeOutReserve;
  I386CodeAttach(cc,&owned->lifetime,owned,5);
  I386IrqRestore(irq); return owned;
}
Bool I386OutDel(CI386Heap *heap,CCmpCtrl *cc,CI386Out *out)
{
  CI386OwnedOut *owned=out;
  CI386CmpRelease state;
  U32 irq=I386IrqSave;
  if(!I386OutValid(heap,cc,out)) { I386IrqRestore(irq); return FALSE; }
  state.heap=heap; state.control=cc; state.ok=TRUE;
  I386CmpReleaseAllocation(&state,out->data);
  if(state.ok) I386CodeFree(&state,&owned->lifetime);
  I386IrqRestore(irq); return state.ok;
}
