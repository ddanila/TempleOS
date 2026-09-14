#ifndef I386_SYMBOL_ALLOC_INCLUDED
#define I386_SYMBOL_ALLOC_INCLUDED
#include "/Compiler/SymbolInit.HH"
#include "/Kernel/I386/Heap.HH"
public extern CHashClass *I386PrsClassNew(CI386Heap *heap);
public extern CHashFun *I386PrsFunNew(CI386Heap *heap);
#endif
