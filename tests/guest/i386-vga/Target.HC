#include "/Kernel/Types.HH"
#include "/Kernel/I386/Ports.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Heap.HH"
#include "/Kernel/I386/BootMemory.HH"
#include "/Kernel/I386/A20.HH"
#include "/Kernel/I386/Vga.HH"
#include "/Kernel/I386/TextVga.HH"
extern U0 I386VgaPalette(U8 *rgb6);
U8 palette[]={
  0,0,0, 0,0,42, 0,42,0, 0,42,42,
  42,0,0, 42,0,42, 42,21,0, 42,42,42,
  21,21,21, 21,21,63, 21,63,21, 21,63,63,
  63,21,21, 63,21,63, 63,63,21, 63,63,63};
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;
  CI386Text text;
  CI386MemRange reserved,arena;
  CI386BootInfo *boot=I386_BOOT_INFO_ADDRESS;
  Bool extended=FALSE;
  U8 *planes;
  I64 i,x,y,plane,color,index;
  if (boot->flags&2 && boot->extended_kib>=64)
    extended=I386A20Enable()!=0;
  reserved.base=0x70000; reserved.size=0x20000;
  if (!I386BootArena(boot,&reserved,1,&arena,extended) ||
      !I386HeapInit(&heap,arena.base,arena.size)) return 1;
  if (!extended || arena.base<0x110000) return 4; //This 8 MiB QEMU fixture requires high RAM.
  planes=I386HeapAlloc(&heap,153600);
  if (!planes) return 2;
  for (i=0;i<153600;i++) planes[i]=255;
  I386VgaPalette(palette);
  I386VgaPresent(planes);
  for (i=0;i<153600;i++) planes[i]=0;
  for (y=0;y<480;y++)
    for (x=0;x<640;x++) {
      color=((x/40+y/30)&15)^(x&7);
      index=y*80+x/8;
      for (plane=0;plane<4;plane++)
        if (color&(1<<plane)) planes[plane*38400+index]|=1<<(x&7);
    }
  I386VgaPresent(planes);
  for(i=0;i<153600;i++) planes[i]=0;
  if(!I386VgaRows(planes,0,1) || !I386VgaRows(planes,7,1) ||
      !I386VgaRows(planes,479,1) || !I386VgaRows(planes,480,0) ||
      I386VgaRows(0,0,1) || I386VgaRows(0xFFFF0000,0,1) ||
      I386VgaRows(planes,-1,1) || I386VgaRows(planes,0,-1) ||
      I386VgaRows(planes,479,2) || I386VgaRows(planes,481,0)) return 5;
  text.planes=planes; text.dirty_first=0; text.dirty_last=1;
  if(I386TextPresent(&text)!=1 || text.dirty_first!=60 || text.dirty_last) return 6;
  for(i=0;i<153600;i++) planes[i]=255;
  if(I386TextPresent(&text)!=0) return 7;
  text.dirty_first=59; text.dirty_last=61;
  if(I386TextPresent(&text)!=-1 || text.dirty_first!=59 || text.dirty_last!=61) return 8;
  text.dirty_first=1; text.dirty_last=2; text.planes=0xFFFF0000;
  if(I386TextPresent(&text)!=-1 || text.dirty_first!=1 || text.dirty_last!=2) return 9;
  if (!I386HeapFree(&heap,planes) || heap.used || !I386HeapValid(&heap)) return 3;
  return 42;
}
#include "/Kernel/I386/Vga.HC"
#include "/Kernel/I386/TextVga.HC"

#include "/Kernel/I386/Heap.HC"

#include "/Kernel/I386/BootMemory.HC"

#include "/Kernel/I386/A20.HC"
