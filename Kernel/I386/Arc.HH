#ifndef I386_ARC_INCLUDED
#define I386_ARC_INCLUDED
#include "/Kernel/Arc.HH"
#include "/Kernel/I386/Heap.HH"
//Exclusive initialized compression control and valid dictionary chains are required.
public extern U0 I386ArcEntryGet(CArcCtrl *c);
//Owned native control and optional 4096-byte expansion stack. Buffers remain borrowed.
public extern CArcCtrl *I386ArcCtrlNew(CI386Heap *heap,Bool expand,I64 compression_type=CT_8_BIT);
public extern Bool I386ArcCtrlDel(CI386Heap *heap,CArcCtrl *c);
#endif
