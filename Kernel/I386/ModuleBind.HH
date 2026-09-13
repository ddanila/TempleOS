#ifndef I386_MODULE_BIND_INCLUDED
#define I386_MODULE_BIND_INCLUDED
#include "/Kernel/I386/Heap.HH"
#include "/Kernel/I386/Module.HH"
class CI386ModuleBinding {
  U8 *name;
  U32 kind,address;
};
public extern I64 I386LoadBoundInto(U8 **modules,I64 *sizes,I64 count,U8 *image,I64 capacity,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count);
public extern U8 *I386LoadBoundAlloc(CI386Heap *heap,U8 **modules,I64 *sizes,I64 count,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count);
#endif
