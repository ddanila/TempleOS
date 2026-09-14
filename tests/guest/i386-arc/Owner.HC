CI386Heap owner_heap;
CArcCtrl *ArcNew(Bool expand,I64 mode) { return I386ArcCtrlNew(&owner_heap,expand,mode); }
Bool ArcDelete(CArcCtrl *c) { return I386ArcCtrlDel(&owner_heap,c); }
#include "T:/Lifecycle.HC"
I64 ArcOwnerTest()
{
  CI386Heap small,foreign;
  CArcCtrl *c;
  U8 *borrowed;
  I64 i,result;
  U32 flags=I386IrqSave;
  if(!I386HeapInit(&owner_heap,0x40000,131072)) return 16;
  result=ArcLifecycleTest; if(result) return result;
  if(owner_heap.used || owner_heap.allocations) return 17;
  for(i=65664;i<69808;i+=128) {
    if(!I386HeapInit(&small,0x70000,i) || I386ArcCtrlNew(&small,TRUE) ||
        small.used || small.allocations || !I386HeapValid(&small)) return 18;
  }
  if(!I386HeapInit(&small,0x70000,69808)) return 29;
  c=I386ArcCtrlNew(&small,TRUE);
  if(!c || small.used!=69808 || !I386ArcCtrlDel(&small,c) || small.used || small.allocations) return 30;
  if(!I386HeapInit(&small,0x70000,65688) || I386ArcCtrlNew(&small,FALSE) ||
      small.used || small.allocations || I386ArcCtrlNew(0,FALSE)) return 19;
  OutU8(0x21,255); OutU8(0xA1,255); SetRFlags(GetRFlags|0x200);
  c=ArcNew(FALSE,CT_8_BIT);
  if(!c || owner_heap.used!=65696 || owner_heap.allocations!=1 || !(GetRFlags&0x200)) return 20;
  if(!I386HeapInit(&foreign,0x90000,4096) || I386ArcCtrlDel(&foreign,c) ||
      I386ArcCtrlDel(0,c) || ArcDelete(0) || owner_heap.used!=65696) return 21;
  if(!ArcDelete(c) || ArcDelete(c) || owner_heap.used || !(GetRFlags&0x200)) return 22;
  c=ArcNew(TRUE,CT_7_BIT);
  if(!c || owner_heap.used!=69808 || owner_heap.allocations!=2) return 23;
  borrowed=I386HeapAlloc(&owner_heap,64,TRUE); if(!borrowed) return 24;
  c->src_buf=c->dst_buf=c->stk_base=borrowed; c->stk_ptr=borrowed+64;
  if(!ArcDelete(c) || owner_heap.allocations!=1 || I386HeapSize(&owner_heap,borrowed)!=64 ||
      !I386HeapFree(&owner_heap,borrowed) || owner_heap.used || !(GetRFlags&0x200)) return 25;
  c=I386HeapAlloc(&owner_heap,sizeof(CArcCtrl),TRUE);
  if(!c || ArcDelete(c) || !I386HeapFree(&owner_heap,c)) return 26;
  if(!I386HeapInit(&small,0x70000,65688) || I386ArcCtrlNew(&small,TRUE) ||
      small.used || small.allocations || !(GetRFlags&0x200)) return 27;
  if(owner_heap.used || owner_heap.allocations || !I386HeapValid(&owner_heap)) return 28;
  I386IrqRestore(flags); return 0;
}
