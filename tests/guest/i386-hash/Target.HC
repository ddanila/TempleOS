#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#assert sizeof(CHash)==16
#assert sizeof(CHashTable)==24
U64 hash_oracle[512];
extern U0 HashReport(U64 value);
extern U0 HashTestString(U8 *buffer,I64 index);
I64 Main(I64 unused,I64 unused2)
{
  U8 buffer[257];
  CHashTable local,parent;
  CHash entries[6],*heads[2];
  I64 i;
  U32 flags;
  for(i=0;i<512;i++) {
    HashTestString(buffer,i);
    if(HashStr(buffer)!=hash_oracle[i]) {
      HashReport(HashStr(buffer)); HashReport(hash_oracle[i]); return 100+i;
    }
  }
  if(HashStr(0) || HashStr("") || HashStr("a")!=97) return 1;
  local.next=&parent; parent.next=0;
  local.mask=0; parent.mask=0;
  local.locked_flags=0; parent.locked_flags=0;
  heads[0]=0; heads[1]=0; local.body=heads; parent.body=heads+1;
  for(i=0;i<6;i++) {
    entries[i].next=0; entries[i].str="name"; entries[i].type=1;
    entries[i].use_cnt=0;
  }
  entries[1].type=2; entries[2].str="other";
  entries[4].type=2;
  OutU8(0x21,255); OutU8(0xA1,255);
  flags=I386IrqSave;
  for(i=0;i<4;i++) HashAdd(&entries[i],&local);
  if(GetRFlags&0x200) return 2;
  SetRFlags(GetRFlags|0x200);
  HashAdd(&entries[4],&parent); HashAdd(&entries[5],&parent);
  if(!(GetRFlags&0x200)) return 3;
  I386IrqSave;
  if(HashBucketFind("name",&local)!=heads || heads[0]!=&entries[3] ||
      heads[1]!=&entries[5] || entries[3].next!=&entries[2] ||
      entries[2].next!=&entries[1] || entries[1].next!=&entries[0]) return 4;
  if(HashSingleTableFind("name",&local,1)!=&entries[3]) return 10;
  if(HashSingleTableFind("name",&local,1,2)!=&entries[0]) return 11;
  if(HashSingleTableFind("name",&local,1,3)) return 12;
  if(HashSingleTableFind("name",&local,2)!=&entries[1]) return 13;
  if(HashFind("name",&local,1,3)!=&entries[5]) return 14;
  if(HashFind("name",&local,2,2)!=&entries[4]) return 15;
  if(HashFind("name",&local,3,5)!=&entries[4]) return 16;
  if(HashFind("name",&local,3,6)) return 17;
  if(HashFind("Name",&local,3)) return 18;
  if(HashFind("name",&local,0)) return 19;
  if(HashFind("name",&local,0x100000000)) return 20;
  if(HashFind("name",&local,3,0)) return 21;
  if(HashFind("name",&local,3,-1)) return 22;
  if(HashFind("name",0,3)) return 23;
  if(HashFind("other",&local,3)!=&entries[2]) return 24;
  if(entries[0].use_cnt!=1 || entries[1].use_cnt!=1 || entries[2].use_cnt!=1 ||
      entries[3].use_cnt!=1 || entries[4].use_cnt!=2 || entries[5].use_cnt!=1) return 6;
  entries[3].use_cnt=0xFFFFFFFF;
  SetRFlags(GetRFlags|0x200);
  if(HashFind("name",&local,1)!=&entries[3] || entries[3].use_cnt ||
      !(GetRFlags&0x200)) return 7;
  I386IrqSave;
  //Nontrivial bucket addressing must use target pointer width, not eight-byte slots.
  local.mask=1; heads[0]=0; heads[1]=0; local.next=0;
  entries[0].str="a"; entries[1].str="b";
  HashAdd(&entries[0],&local); HashAdd(&entries[1],&local);
  if(HashBucketFind("a",&local)!=heads+1 || HashBucketFind("b",&local)!=heads ||
      heads[0]!=&entries[1] || heads[1]!=&entries[0] ||
      HashFind("a",&local,1)!=&entries[0] || HashFind("b",&local,2)!=&entries[1]) return 8;
  I386IrqRestore(flags);
  return 0;
}
#include "T:/Vectors.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Hash.HC"

U0 HashReport(U64 value)
{
  I64 i; U8 *digits="0123456789ABCDEF";
  for(i=60;i>=0;i-=4) OutU8(0xE9,digits[(value>>i)&15]);
  OutU8(0xE9,10);
}
