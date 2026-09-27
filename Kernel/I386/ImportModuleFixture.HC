//A source-built module must retain a named import of an already resident API.
#include "/Kernel/Types.HH"
#include "/Kernel/I386/Heap.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import U32 char_bmp_hex_numeric[16];
public U8 *I386ImportModuleFixture(CI386Heap *heap)
{ return I386HeapAlloc(heap,16); }
public U32 I386ImportGlobalFixture()
{ return char_bmp_hex_numeric[0]; }
