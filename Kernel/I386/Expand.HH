#ifndef I386_EXPAND_INCLUDED
#define I386_EXPAND_INCLUDED
#include "/Kernel/I386/ArcExpand.HH"
//Borrowed readable archive extent; owned exact output plus NUL on success.
//Failure returns zero, reclaims allocations and preserves optional size. IF is preserved.
public extern U8 *I386ExpandBuf(CI386Heap *heap,CArcCompress *arc,I64 archive_size,I64 *size=0);
#endif
