#include "/Kernel/Types.HH"
#include "/Kernel/I386/Ports.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Heap.HH"
extern U0 I386VgaPresent(U8 *planes);
extern U0 I386VgaPalette(U8 *rgb6);
U8 palette[]={
  0,0,0, 0,0,42, 0,42,0, 0,42,42,
  42,0,0, 42,0,42, 42,21,0, 42,42,42,
  21,21,21, 21,21,63, 21,63,21, 21,63,63,
  63,21,21, 63,21,63, 63,63,21, 63,63,63};
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;
  U8 *planes;
  I64 i,x,y,plane,color,index;
  if (!I386HeapInit(&heap,0x30000,0x40000)) return 1;
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
  if (!I386HeapFree(&heap,planes) || heap.used || !I386HeapValid(&heap)) return 3;
  return 42;
}
#include "/Kernel/I386/Vga.HC"

#include "/Kernel/I386/Heap.HC"
