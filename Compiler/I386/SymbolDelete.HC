#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/SymbolDelete.HC"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/TaskExtern.HC"
class CI386SymbolRelease
{
  CI386Heap *heap;
  Bool ok;
};
U0 I386SymbolFree(U8 *context,U8 *allocation)
{
  CI386SymbolRelease *state=context;
  U32 flags=I386IrqSave;
  if(allocation && !I386HeapFree(state->heap,allocation)) state->ok=FALSE;
  I386IrqRestore(flags);
}
public Bool I386HashDel(CI386Heap *heap,CHashSrcSym *symbol)
{
  CSymbolRelease owner;
  CI386SymbolRelease state;
  U32 flags=I386IrqSave;
  state.heap=heap; state.ok=TRUE;
  owner.context=&state; owner.release=&I386SymbolFree;
  if(!I386TaskExternSymbolDetach(heap,symbol)) {I386IrqRestore(flags);return FALSE;}
  SymbolHashDel(&owner,symbol);
  I386IrqRestore(flags);return state.ok;
}
public Bool I386ClassMemberLstDel(CI386Heap *heap,CHashClass *symbol)
{
  CSymbolRelease owner;
  CI386SymbolRelease state;
  state.heap=heap; state.ok=TRUE;
  owner.context=&state; owner.release=&I386SymbolFree;
  SymbolClassMemberLstDel(&owner,symbol);
  return state.ok;
}
