#ifndef I386_MODULE_FILE_INCLUDED
#define I386_MODULE_FILE_INCLUDED
#include "/Kernel/I386/RedSea.HH"
#include "/Kernel/I386/Heap.HH"
public extern U8 *I386RedSeaLoad(CI386RedSea *volume,CI386RedSeaEntry *entry,CI386Heap *heap,U8 *entry_name);
public extern U8 *I386RedSeaLoadSet(CI386RedSea *volume,CI386RedSeaEntry *entries,I64 count,CI386Heap *heap,U8 *entry_name);
#endif
