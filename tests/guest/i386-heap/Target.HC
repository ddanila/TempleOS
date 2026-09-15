#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Heap.HH"
extern U64 Hash(U8 *base,I64 size);
extern I64 PublicHeapTest();
I64 Main(I64 a,I64 b)
{
  CI386Heap hc,other;
  CI386HeapBlock *block;
  U8 *arena=0x40000,*p,*q,*r,*slots[32],tags[32],*guard,*control=&hc;
  I64 sizes[32],i,j,round,slot;
  U64 before;
  for (i=0;i<sizeof(hc);i++) control[i]=0x5A;
  before=Hash(control,sizeof(hc));
  guard=arena-8;
  for (i=0;i<8216;i++) guard[i]=0xA5;
  if (I386HeapInit(&hc,arena,23)) return 201;
  if (I386HeapInit(&hc,arena,-1)) return 202;
  if (I386HeapInit(&hc,arena,0x100000000)) return 203;
  if (I386HeapInit(&hc,arena+1,8192)) return 204;
  if (I386HeapInit(&hc,0,8192)) return 205;
  if (I386HeapInit(0,arena,8192)) return 206;
  if (I386HeapInit(arena,arena,8192)) return 207;
  if (I386HeapInit(&hc,0xFFFFFFF0,8192)) return 208;
  if (I386HeapInit(&hc,0xFFFFF000,4096)) return 209;
  if (Hash(control,sizeof(hc))!=before) return 2;
  for (i=0;i<8216;i++) if (guard[i]!=0xA5) return 2;
  if (!I386HeapInit(&hc,arena,8199) || hc.size!=8192 || !I386HeapValid(&hc)) return 3;
  p=I386HeapAlloc(&hc,0); q=I386HeapAlloc(&hc,1,TRUE);
  if (!p || !q || p==q || (p+0)(U64)&7 || (q+0)(U64)&7 ||
      I386HeapSize(&hc,p)!=0 || I386HeapSize(&hc,q)!=1 || *q) return 4;
  if (!I386HeapInit(&other,0x44000,8192) || I386HeapFree(&other,q) ||
      other.used || !I386HeapValid(&other)) return 27;
  *q=91;
  if (I386HeapFree(&hc,p+1) || I386HeapFree(&hc,arena) ||
      I386HeapFree(&hc,arena+8192) || I386HeapSize(&hc,p+1)!=-1 ||
      I386HeapAlloc(&hc,-1) || I386HeapAlloc(&hc,0xFFFFFFFF) ||
      I386HeapAlloc(&hc,0x100000000) || I386HeapAlloc(&hc,8192) || *q!=91) return 5;
  if (!I386HeapFree(&hc,p) || I386HeapFree(&hc,p) || I386HeapSize(&hc,p)!=-1 ||
      !I386HeapFree(&hc,0) || !I386HeapFree(&hc,q) || !I386HeapValid(&hc)) return 6;
  p=I386HeapAlloc(&hc,100); q=I386HeapAlloc(&hc,200); r=I386HeapAlloc(&hc,300);
  if (!p || !q || !r || !I386HeapFree(&hc,p) || !I386HeapFree(&hc,r) ||
      !I386HeapFree(&hc,q) || hc.used || hc.allocations || !I386HeapValid(&hc)) return 7;
  //Both neighbors coalesced: the entire arena is available again.
  p=I386HeapAlloc(&hc,8176,TRUE);
  if (!p || hc.used!=8192 || hc.peak!=8192 || hc.allocations!=1) return 8;
  for (i=0;i<8176;i++) if (p[i]) return 9;
  before=Hash(arena,8192);
  if (I386HeapAlloc(&hc,0) || I386HeapAlloc(&hc,1) ||
      I386HeapFree(&hc,p+8) || Hash(arena,8192)!=before || hc.used!=8192 ||
      hc.allocations!=1 || !I386HeapFree(&hc,p)) return 10;
  //A remainder too small for another header is absorbed into the allocation.
  p=I386HeapAlloc(&hc,8160);
  if (!p || hc.used!=8192 || I386HeapSize(&hc,p)!=8160 ||
      !I386HeapFree(&hc,p)) return 11;
  for (i=0;i<32;i++) slots[i]=0;
  for (round=0;round<512;round++) {
    slot=(round*17+round/7)%32;
    if (slots[slot]) {
      for (j=0;j<sizes[slot];j++) if (slots[slot][j]!=tags[slot]) return 12;
      if (!I386HeapFree(&hc,slots[slot])) return 13;
      slots[slot]=0;
    } else {
      sizes[slot]=(round*73)%129;
      slots[slot]=I386HeapAlloc(&hc,sizes[slot],TRUE);
      if (!slots[slot] || (slots[slot]+0)(U64)&7 ||
          I386HeapSize(&hc,slots[slot])!=sizes[slot]) return 14;
      tags[slot]=round;
      for (j=0;j<sizes[slot];j++) {
        if (slots[slot][j]) return 15;
        slots[slot][j]=tags[slot];
      }
    }
    if (!I386HeapValid(&hc)) return 16;
  }
  for (i=0;i<32;i++) if (slots[i] && !I386HeapFree(&hc,slots[i])) return 17;
  if (hc.used || hc.allocations || hc.peak!=8192) return 18;
  //Metadata corruption must be rejected before allocation/free changes anything.
  block=arena;
  block->span=1; before=Hash(arena,8192);
  if (I386HeapValid(&hc) || I386HeapAlloc(&hc,1) ||
      I386HeapFree(&hc,arena+16) || Hash(arena,8192)!=before) return 19;
  block->span=8192; block->reserved=1;
  if (I386HeapValid(&hc)) return 20;
  block->reserved=0; block->tag=0;
  if (I386HeapValid(&hc)) return 21;
  block->tag=I386_HEAP_FREE;
  p=I386HeapAlloc(&hc,10); block->requested=100;
  if (I386HeapValid(&hc)) return 22;
  block->requested=10;
  hc.allocations++;
  if (I386HeapValid(&hc)) return 23;
  hc.allocations--;
  if (!I386HeapFree(&hc,p) || !I386HeapValid(&hc)) return 24;
  for (i=0;i<8;i++) if (guard[i]!=0xA5) return 25;
  for (i=8200;i<8216;i++) if (guard[i]!=0xA5) return 26;
  return PublicHeapTest;
}
U64 Hash(U8 *base,I64 size)
{
  U64 h=0x123456789ABCDEF0;
  I64 i;
  for (i=0;i<size;i++) h=(h<<5)^base[i]^(h>>59);
  return h;
}
#include "/Kernel/I386/Heap.HC"

#include "Public.HC"
