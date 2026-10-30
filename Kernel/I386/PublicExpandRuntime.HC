//Original task-owned archive expansion over the retained native dictionary service.
#include "/Kernel/Arc.HH"
import U0 I386ArcEntryGet(CArcCtrl *c);
#include "/Kernel/ArcSeed.HC"
#include "/Kernel/ArcExpand.HC"
#define ArcEntryGet I386ArcEntryGet
//Initialized from the native arena before public console services run.
U64 mem_mapped_space;
#include "/Kernel/ExpandBufCore.HC"
#include "/Kernel/ArcCompressCore.HC"
#include "/Kernel/CompressBufCore.HC"
