#ifndef I386_NATIVE_EMIT_INCLUDED
#define I386_NATIVE_EMIT_INCLUDED
#include "/Compiler/I386/Control.HH"
#include "/Compiler/I386/Emit.HH"
//Current control owner; invalid setup returns null/false. New/growth throw OutMem.
//No transfer of code ownership: deleting/unwinding the control invalidates the buffer.
public extern CI386Out *I386OutNew(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386OutDel(CI386Heap *heap,CCmpCtrl *cc,CI386Out *out);
#endif
