#ifndef I386_FILE_LOAD_INCLUDED
#define I386_FILE_LOAD_INCLUDED
#include "/Kernel/I386/FileRead.HH"
#include "/Kernel/I386/FileNames.HH"
#include "/Kernel/I386/Expand.HH"
//Volume-scoped paths; exact name then toggled .Z if absent. Quiescent volume, IF clear.
//Optional parent search: all exact-name ancestors precede all alternate-name ancestors.
//Owned raw/expanded bytes plus NUL. Failure preserves optional size/attributes.
public extern U8 *I386RedSeaFileLoad(CI386RedSea *volume,CI386Heap *heap,I64 directory,
  U8 *path,I64 *size=0,I64 *attr=0,Bool scan_parents=FALSE);
#endif
