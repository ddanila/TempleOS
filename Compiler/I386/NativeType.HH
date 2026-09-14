#ifndef I386_NATIVE_TYPE_INCLUDED
#define I386_NATIVE_TYPE_INCLUDED
#include "/Compiler/PrsType.HH"
#include "/Compiler/I386/Control.HH"
//Borrow complete type services. Callback allocations need control-owned unwind.
extern CHashClass *I386ParseType(CI386Heap *heap,CCmpCtrl *cc,CPrsTypeServices *services,
  CHashClass **first,I64 *mode,CMemberLst *member,U8 **ident,CHashFun **fun,
  CHashExport **export_entry,CArrayDim *dim,I64 flags);
#endif
