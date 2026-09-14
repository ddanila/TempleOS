#ifndef I386_FILE_PATHS_INCLUDED
#define I386_FILE_PATHS_INCLUDED
#include "/Kernel/BlkDev/FilePaths.HH"
#include "/Kernel/I386/Heap.HH"
//Owned strings, no I/O; null on invalid context or allocation failure. IF preserved.
public extern U8 *I386DirNameAbs(CI386Heap *heap,CFilePathContext *context,U8 *name);
public extern U8 *I386FileNameAbs(CI386Heap *heap,CFilePathContext *context,U8 *name);
#endif
