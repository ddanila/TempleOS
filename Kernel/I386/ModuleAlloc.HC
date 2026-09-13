//Native module-set allocation. The caller owns input lifetimes and heap access.
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/ModuleLoad.HC"

public U8 *I386LoadBoundAlloc(CI386Heap *heap,U8 **modules,I64 *sizes,I64 count,
  U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//Validate before allocation; release temporary storage if final loading fails.
//Inputs in this heap must be live allocations, never bytes in a free block.
//The result is an entry trampoline and is released with I386HeapFree once idle.
//I386HeapSize reports the loaded image size. Failure returns zero, without OutMem.
  I64 required=I386LoadBoundInto(modules,sizes,count,0,0,entry_name,bindings,binding_count);
  U8 *image;
  if (!required) return 0;
  image=I386HeapAlloc(heap,required);
  if (!image) return 0;
  if (I386LoadBoundInto(modules,sizes,count,image,required,entry_name,bindings,binding_count)!=required) {
    I386HeapFree(heap,image);
    return 0;
  }
  return image;
}

public U8 *I386LoadAlloc(CI386Heap *heap,U8 **modules,I64 *sizes,I64 count,U8 *entry_name)
{
  return I386LoadBoundAlloc(heap,modules,sizes,count,entry_name,0,0);
}
