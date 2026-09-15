#ifndef I386_MEMORY_PUBLIC_INCLUDED
#define I386_MEMORY_PUBLIC_INCLUDED
#include "/Kernel/I386/TaskHeaps.HH"
extern U8 *MemoryAlloc(I64 size,CTask *selector=0);
extern U0 MemoryFree(U8 *ptr);
extern I64 MemorySize(U8 *ptr);
extern I64 MemorySize2(U8 *ptr);
extern CHeapCtrl *MemoryHeap(U8 *ptr);
extern U8 *MemoryCAlloc(I64 size,CTask *selector=0);
extern U8 *MemoryAligned(I64 size,I64 alignment,CTask *selector=0,I64 misalignment=0);
extern U8 *MemoryCAligned(I64 size,I64 alignment,CTask *selector=0,I64 misalignment=0);
#endif
