#ifndef I386_FILE_READ_INCLUDED
#define I386_FILE_READ_INCLUDED
#include "/Kernel/I386/RedSea.HH"
#include "/Kernel/I386/Heap.HH"
//Quiescent channel/volume, IF clear. Raw bytes with an extra NUL, owned by heap.
//Partial I/O and allocation failure return zero, reclaim storage and preserve size.
public extern U8 *I386RedSeaReadAll(CI386RedSea *volume,CI386Heap *heap,CI386RedSeaEntry *entry,I64 *size=0);
public extern U8 *I386RedSeaFileRead(CI386RedSea *volume,CI386Heap *heap,I64 directory,U8 *path,I64 *size=0);
#endif
