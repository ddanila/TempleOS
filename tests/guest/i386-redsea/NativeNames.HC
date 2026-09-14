CI386Heap name_heap;
I64 name_errors;
U8 *NameDefault(U8 *name,U8 *extension) { return I386ExtDft(&name_heap,name,extension); }
U8 *NameToggle(U8 *name) { return I386ToggleZorNotZ(&name_heap,name); }
U0 NameFree(U8 *name) { if(!I386HeapFree(&name_heap,name)) name_errors++; }
#include "T:/Names.HC"
I64 TestNames()
{
  U8 *a,*b,source[258];
  I64 result,i,size;
  U32 flags=I386IrqSave;
  if(!I386HeapInit(&name_heap,0x40000,65536)) return 64;
  result=NameRulesTest; if(result) return result;
  if(name_errors || name_heap.used || name_heap.allocations || !I386HeapValid(&name_heap)) return 65;
  if(I386ExtDft(&name_heap,0,"HC.Z") || I386ExtDft(&name_heap,"a",0) ||
      I386ExtDft(0,"a","HC.Z") || I386ToggleZorNotZ(&name_heap,0) ||
      I386ToggleZorNotZ(0,"a")) return 66;
  for(i=0;i<257;i++) source[i]='a';
  source[257]=0;
  for(size=24;size<280;size+=8) {
    if(!I386HeapInit(&name_heap,0x40000,size) ||
        NameDefault(source,"HC.Z") || NameToggle(source) || name_heap.used ||
        name_heap.allocations || !I386HeapValid(&name_heap) || GetRFlags&0x200) return 67;
    for(i=0;i<257;i++) if(source[i]!='a') return 68;
    if(source[257]) return 69;
  }
  if(!I386HeapInit(&name_heap,0x40000,65536)) return 70;
  OutU8(0x21,255); OutU8(0xA1,255); SetRFlags(GetRFlags|0x200);
  a=NameDefault("child","HC.Z"); b=NameToggle("child.HC.Z");
  if(!a || !b || I386HeapSize(&name_heap,a)!=11 || I386HeapSize(&name_heap,b)!=9 ||
      !NameEqual(a,"child.HC.Z") || !NameEqual(b,"child.HC") || !(GetRFlags&0x200)) return 71;
  NameFree(a); NameFree(b);
  if(name_errors || name_heap.used || name_heap.allocations || !(GetRFlags&0x200)) return 72;
  I386IrqRestore(flags); return 0;
}
