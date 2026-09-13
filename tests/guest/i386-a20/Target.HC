#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/A20.HH"
#include "/Kernel/I386/Heap.HH"
#include "/Kernel/I386/BootMemory.HH"
extern Bool I386A20KbcEmpty(I64 polls);
extern Bool DisableGate();
I64 Main(I64 a,I64 b)
{
  CI386BootInfo *boot=I386_BOOT_INFO_ADDRESS;
  CI386MemRange reserved,arena;
  CI386Heap heap;
  U8 *low=0x5100,*high=0x105100,*p;
  I64 method,i,size;
  if (!(boot->flags&2) || boot->extended_kib<64) return 1;
  method=I386A20Enable();
  if (!method || !I386A20Test()) return 2;
  *low=0x31; *high=0x42;
  if (!I386A20Test() || *low!=0x31 || *high!=0x42) return 3;
  if (!DisableGate() || *low!=0x31) return 4;
  //Zero polls exercises bounded controller failure without issuing a command.
  if (I386A20Enable(FALSE,0) || I386A20Test() || *low!=0x31) return 5;
  if (I386A20Enable(FALSE)!=2 || !I386A20Test() || *low!=0x31 || *high!=0x42) return 6;
  if (!DisableGate()) return 7;
  if (I386A20Enable(TRUE,0)!=3 || !I386A20Test() || *low!=0x31 || *high!=0x42) return 8;
  if (I386A20Enable()!=1 || I386A20Enable(FALSE,-1) ||
      I386A20Enable(FALSE,100001) || !I386A20Test()) return 9;
  reserved.base=0x70000; reserved.size=0x20000;
  if (!I386BootArena(boot,&reserved,1,&arena,TRUE) || arena.base<0x110000 ||
      arena.base+arena.size>0x100000+boot->extended_kib*1024 ||
      arena.base+arena.size>0xF00000 || !I386HeapInit(&heap,arena.base,arena.size)) return 10;
  size=arena.size-16;
  p=I386HeapAlloc(&heap,size);
  if (!p || I386HeapAlloc(&heap,1) || I386HeapSize(&heap,p)!=size) return 11;
  for (i=0;i<size;i+=4096) (p+i)(U32 *)[0]=0xA5000000+i/4096;
  p[size-1]=0x5A;
  for (i=0;i<size;i+=4096) if ((p+i)(U32 *)[0]!=0xA5000000+i/4096) return 12;
  if (p[size-1]!=0x5A || *low!=0x31 || *high!=0x42 ||
      !I386HeapFree(&heap,p) || heap.used || !I386HeapValid(&heap)) return 13;
  return 0;
}
Bool DisableGate()
{//QEMU-only fixture setup: disable both controller and port-0x92 sources.
  if (!I386A20KbcEmpty(100000)) return FALSE;
  OutU8(0x64,0xD1);
  if (!I386A20KbcEmpty(100000)) return FALSE;
  OutU8(0x60,0xDD);
  if (!I386A20KbcEmpty(100000)) return FALSE;
  OutU8(0x92,InU8(0x92)&0xFC);
  return !I386A20Test();
}
#include "/Kernel/I386/A20.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/BootMemory.HC"
