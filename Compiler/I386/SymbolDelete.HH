#ifndef I386_SYMBOL_DELETE_INCLUDED
#define I386_SYMBOL_DELETE_INCLUDED
#include "/Kernel/SymbolDelete.HH"
#include "/Kernel/I386/Heap.HH"
//Detached live symbols; every owned allocation must belong to heap.
//False reports a failed release, not rollback or validation of arbitrary graphs.
public extern Bool I386HashDel(CI386Heap *heap,CHashSrcSym *symbol);
public extern Bool I386ClassMemberLstDel(CI386Heap *heap,CHashClass *symbol);
#endif
