#include "/Kernel/I386/Expand.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/ArcExpand.HH"
#include "/Kernel/I386/CompactExpand.HC"
U8 *I386ExpandBufWorkspace(CI386Heap *heap,CI386Heap *workspace_heap,
  CArcCompress *arc,I64 archive_size,I64 *size=0)
{
  CI386CompactArc *c=0;
  U8 *output=0,*body;
  I64 i,expanded,packed,type;
  U32 flags;
  Bool ok=FALSE;
  if(!heap || !arc || archive_size<17 || archive_size>0xFFFFFFFF ||
      (arc+0)(U64)+archive_size>0xFFFFFFFF) return 0;
  expanded=arc->expanded_size; packed=arc->compressed_size; type=arc->compression_type;
  if(expanded<0 || expanded>0xFFFFFFFF-24 || packed<17 || packed>archive_size ||
      type<CT_NONE || type>CT_8_BIT || (type==CT_NONE && expanded>packed-17)) return 0;
  flags=I386IrqSave;
  output=I386HeapAlloc(heap,expanded+1,FALSE);
  I386IrqRestore(flags);
  if(!output) return 0;
  if(type==CT_NONE) {
    body=(arc+0)(U8 *)+17;
    for(i=0;i<expanded;i++) output[i]=body[i];
    ok=TRUE;
  } else if(!expanded) ok=packed==17;
  else {
    flags=I386IrqSave;
    if(!workspace_heap)workspace_heap=heap;
    c=I386HeapAlloc(workspace_heap,sizeof(CI386CompactArc),TRUE);
    if(!c && workspace_heap!=heap) {
      workspace_heap=heap;
      c=I386HeapAlloc(workspace_heap,sizeof(CI386CompactArc),TRUE);
    }
    I386IrqRestore(flags);
    if(c) {
      ok=I386CompactArcExpand(c,arc,output);
      flags=I386IrqSave;
      if(!I386HeapFree(workspace_heap,c))ok=FALSE;
      I386IrqRestore(flags);
    }
  }
  if(!ok) {
    flags=I386IrqSave; I386HeapFree(heap,output); I386IrqRestore(flags); return 0;
  }
  output[expanded]=0;
  if(size) *size=expanded;
  return output;
}

U8 *I386ExpandBuf(CI386Heap *heap,CArcCompress *arc,I64 archive_size,I64 *size=0)
{
  return I386ExpandBufWorkspace(heap,heap,arc,archive_size,size);
}
