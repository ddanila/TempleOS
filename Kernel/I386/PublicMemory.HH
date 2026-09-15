#ifndef I386_PUBLIC_MEMORY_INCLUDED
#define I386_PUBLIC_MEMORY_INCLUDED
#include "/Kernel/I386/PublicTaskTypes.HH"
#include "/Kernel/MemoryAllocTypes.HH"
#include "/Kernel/MemoryTypes.HH"
#help_index "Memory/Heap"
public _extern _MALLOC U8 *MAlloc(I64 size,CTask *mem_task=0);
public _extern _FREE U0 Free(U8 *addr);
public _extern _MSIZE I64 MSize(U8 *src);
public _extern _MSIZE2 I64 MSize2(U8 *src);
public _extern _MHEAP_CTRL CHeapCtrl *MHeapCtrl(U8 *src);
public _extern _CALLOC U8 *CAlloc(I64 size,CTask *mem_task=0);
public _extern _MALLOC_ALIGNED U8 *MAllocAligned(I64 size,I64 alignment,CTask *mem_task=0,I64 misalignment=0);
public _extern _CALLOC_ALIGNED U8 *CAllocAligned(I64 size,I64 alignment,CTask *mem_task=0,I64 misalignment=0);
#endif
