#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/Heap.HH"
#include "/Kernel/I386/BootMemory.HH"
#include "/Kernel/I386/A20.HH"
extern U8 *I386LoadAlloc(CI386Heap *heap,U8 **modules,I64 *sizes,I64 count,U8 *entry_name);
extern I64 I386LoadInto(U8 **modules,I64 *sizes,I64 count,U8 *image,I64 capacity,U8 *entry_name);
U8 entry_name[5]="Main",output[2048],other[2048],original[2048];
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;
  CI386MemRange reserved,arena;
  CI386BootInfo *boot=I386_BOOT_INFO_ADDRESS;
  Bool extended=FALSE;
  U8 *packet=a,*modules[3],*cursor,*first,*second,*again,*reserve,*stored,*heap_modules[3];
  I64 sizes[3],count,mode,expected,required,i,j,result;
  I64 (*entry)(I64 x,I64 y);
  if (b<28 || b>2048) return 1;
  mode=packet(U32 *)[0]; count=packet(U32 *)[1]; expected=(packet+8)(I64 *)[0];
  if (count<1 || count>3) return 2;
  cursor=packet+28;
  for (i=0;i<count;i++) {
    sizes[i]=(packet+16)(U32 *)[i]; modules[i]=cursor;
    if (sizes[i]>b-(cursor-packet)) return 3;
    cursor+=sizes[i];
  }
  for (i=0;i<b;i++) original[i]=packet[i];
  for (i=0;i<2048;i++) { output[i]=0xA5; other[i]=0x5A; }
  if (boot->flags&2 && boot->extended_kib>=64)
    extended=I386A20Enable()!=0;
  reserved.base=0x70000; reserved.size=0x20000;
  if (!I386BootArena(boot,&reserved,1,&arena,extended) ||
      !I386HeapInit(&heap,arena.base,arena.size)) return 21;
  if (!extended || arena.base<0x110000) return 40; //Assert high-memory execution in this profile.
  required=I386LoadInto(modules,sizes,count,0,0,entry_name);
  if (mode) {
    if (required || I386LoadInto(modules,sizes,count,output,2048,entry_name)) return 4;
    if (I386LoadAlloc(&heap,modules,sizes,count,entry_name) || heap.used ||
        heap.allocations || heap.peak || !I386HeapValid(&heap)) return 22;
  } else {
    if (required<8 || required>2048) return 5;
    if (I386LoadInto(modules,sizes,count,output,required-1,entry_name)) return 6;
    if (I386LoadInto(modules,sizes,count,modules[0],required,entry_name)) return 7;
    if (I386LoadInto(modules,sizes,count,modules,required,entry_name)) return 8;
    if (I386LoadInto(modules,sizes,count,sizes,required,entry_name)) return 9;
    if (I386LoadInto(modules,sizes,count,entry_name,required,entry_name)) return 10;
    if (I386LoadInto(modules,sizes,count,0xFFFFFFF0,required,entry_name)) return 11;
    if (I386LoadInto(modules,sizes,count,0,1,entry_name) ||
        I386LoadInto(modules,sizes,0,output,2048,entry_name) ||
        I386LoadInto(0,sizes,count,output,2048,entry_name) ||
        I386LoadInto(modules,0,count,output,2048,entry_name) ||
        I386LoadInto(modules,sizes,count,output,2048,0) ||
        I386LoadInto(modules,sizes,count,output,-1,entry_name) ||
        I386LoadInto(modules,sizes,count,output,0x100000000,entry_name) ||
        I386LoadInto(modules,sizes,0x20000000,output,2048,entry_name) ||
        I386LoadInto(modules,sizes,count,other,2048,output) ||
        I386LoadInto(modules,sizes,count,other,2048,entry_name+4)) return 12;
  }
  for (i=0;i<2048;i++)
    if (output[i]!=0xA5 || other[i]!=0x5A) return 13;
  if (!mode) {
    if (I386LoadInto(modules,sizes,count,output,required,entry_name)!=required ||
        I386LoadInto(modules,sizes,count,other,2048,entry_name)!=required) return 14;
    for (i=0;i<required;i++) if (output[i]!=other[i]) return 15;
    reserve=I386HeapAlloc(&heap,heap.size-16);
    if (!reserve || I386LoadAlloc(&heap,modules,sizes,count,entry_name) ||
        heap.used!=heap.size || heap.allocations!=1 || !I386HeapValid(&heap) ||
        !I386HeapFree(&heap,reserve)) return 23;
    if (I386LoadAlloc(0,modules,sizes,count,entry_name)) return 24;
    first=I386LoadAlloc(&heap,modules,sizes,count,entry_name);
    second=I386LoadAlloc(&heap,modules,sizes,count,entry_name);
    if (!first || !second || first==second || heap.allocations!=2 ||
        I386HeapSize(&heap,first)!=required || I386HeapSize(&heap,second)!=required)
      return 25;
    for (i=0;i<required;i++)
      if (first[i]!=output[i] || second[i]!=output[i]) return 26;
    entry=first; if ((*entry)(0,0)!=expected) return 27;
    entry=second; if ((*entry)(0,0)!=expected) return 28;
    if (!I386HeapFree(&heap,first) || I386HeapSize(&heap,first)!=-1) return 29;
    again=I386LoadAlloc(&heap,modules,sizes,count,entry_name);
    if (again!=first) return 30;
    entry=again; if ((*entry)(0,0)!=expected) return 31;
    if (!I386HeapFree(&heap,second) || !I386HeapFree(&heap,again) ||
        heap.used || heap.allocations || !I386HeapValid(&heap)) return 32;
    stored=I386HeapAlloc(&heap,b);
    if (!stored) return 33;
    for (i=0;i<b;i++) stored[i]=packet[i];
    for (i=0;i<count;i++) heap_modules[i]=stored+(modules[i]-packet);
    again=I386LoadAlloc(&heap,heap_modules,sizes,count,entry_name);
    if (!again) return 34;
    for (i=0;i<b;i++) if (stored[i]!=packet[i]) return 35;
    if (!I386HeapFree(&heap,stored)) return 36;
    reserve=I386HeapAlloc(&heap,b,TRUE);
    if (reserve!=stored) return 37;
    //The source module bytes have been erased; the image must remain executable.
    entry=again; if ((*entry)(0,0)!=expected) return 38;
    if (!I386HeapFree(&heap,reserve) || !I386HeapFree(&heap,again) ||
        heap.used || heap.allocations || !I386HeapValid(&heap)) return 39;
    entry=output; result=(*entry)(0,0);
    if (result!=expected) return 16;
    entry=other; result=(*entry)(0,0);
    if (result!=expected) return 17;
    for (i=required;i<2048;i++)
      if (output[i]!=0xA5 || other[i]!=0x5A) return 18;
  }
  for (i=0;i<b;i++) if (original[i]!=packet[i]) return 19;
  if (entry_name[0]!='M' || entry_name[1]!='a' || entry_name[2]!='i' ||
      entry_name[3]!='n' || entry_name[4]) return 20;
  return 0;
}
#include "/Kernel/I386/ModuleAlloc.HC"

#include "/Kernel/I386/BootMemory.HC"

#include "/Kernel/I386/A20.HC"
