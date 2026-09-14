#ifndef I386_FILE_NAMES_INCLUDED
#define I386_FILE_NAMES_INCLUDED
#include "/Kernel/BlkDev/FileNames.HH"
#include "/Kernel/I386/Heap.HH"
//Owned results; null on invalid input/allocation failure. Interrupt state is preserved.
public extern U8 *I386ExtDft(CI386Heap *heap,U8 *name,U8 *extension);
public extern U8 *I386ToggleZorNotZ(CI386Heap *heap,U8 *name);
#endif
