#ifndef I386_NATIVE_BACKEND_INCLUDED
#define I386_NATIVE_BACKEND_INCLUDED
#include "/Compiler/I386/NativeEmit.HH"
#include "/Compiler/I386/Backend.HH"
//Current owner; fresh output, valid function IR and private borrowed AOT/symbol state.
//Generated output and attached relocation records remain owned by cc until cleanup.
//Invalid setup returns FALSE. Compilation/allocation errors throw; unwind cc on failure.
public extern Bool I386BackendCompile(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386Out *out,CI386BackendStatus *status=0);
#endif
