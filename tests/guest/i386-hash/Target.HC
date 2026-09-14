#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/HashTable.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#assert sizeof(CHash)==16
#assert sizeof(CHashTable)==24
U64 hash_oracle[512];
extern I64 HashLifetimeTest();
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
  return HashLifetimeTest;
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

#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/HashTable.HC"
I64 HashLifetimeTest()
{
  CI386Heap heap,tiny,other;
  CHashTable *table,*parent;
  CHash entries[5],**body;
  U8 *spare;
  U32 flags=I386IrqSave;
  I64 i,round,count,used,allocations,saved[4];
  if(!I386HeapInit(&heap,0x40000,65536) || !I386HeapInit(&tiny,0x51000,64) ||
      !I386HeapInit(&other,0x52000,8192)) return 40;
  if(I386HashTableNew(0,8) || I386HashTableNew(&heap,0) ||
      I386HashTableNew(&heap,-1) || I386HashTableNew(&heap,3) ||
      I386HashTableNew(&heap,0x40000000) || I386HashTableNew(&tiny,1) ||
      tiny.used || tiny.allocations || !I386HeapValid(&tiny) || heap.used) return 41;
  SetRFlags(GetRFlags|0x200);
  table=I386HashTableNew(&heap,8);
  if(!table || !(GetRFlags&0x200) || !I386HashTableValid(&heap,table) || I386HashTableValid(&other,table) ||
      I386HashTableValid(&heap,(table+0)(U8 *)+4) || table->mask!=7 ||
      table->next || table->locked_flags || heap.allocations!=2) return 42;
  I386IrqSave;
  for(i=0;i<8;i++) if(table->body[i]) return 43;
  body=table->body; used=heap.used;
  spare=I386HeapAlloc(&heap,65536-used-16);
  if(!spare || heap.used!=65536 || I386HashTableResize(&heap,table,16) ||
      I386HashTableNew(&heap,1) || table->body!=body || table->mask!=7 ||
      heap.allocations!=3 || !I386HeapFree(&heap,spare) || heap.used!=used) return 44;
  //Reject damaged public shape without freeing the owner as its own bucket array.
  table->body=table;
  if(I386HashTableValid(&heap,table) || I386HashTableDelete(&heap,table)) return 45;
  table->body=body;
  for(i=0;i<5;i++) {
    entries[i].str="same"; entries[i].type=1; entries[i].next=0; entries[i].use_cnt=i+10;
  }
  entries[2].str="other"; entries[2].type=2; entries[4].str="parent";
  for(i=0;i<4;i++) HashAdd(&entries[i],table);
  if(I386HashTableDelete(&heap,table) || I386HashTableResize(&heap,table,3) ||
      I386HashTableResize(&heap,table,0x40000000) || I386HashTableResize(&heap,table,32768) ||
      table->body!=body || heap.used!=used || HashFind("same",table,1,2)!=&entries[1]) return 46;
  table->locked_flags=1;
  if(I386HashTableResize(&heap,table,16) || I386HashTableRemove(&heap,table,&entries[3]) ||
      I386HashTableDelete(&heap,table) || table->body!=body || heap.used!=used) return 47;
  table->locked_flags=0;
  for(round=0;round<5;round++) {
    count=8;
    if(round==0) count=16;
    if(round==1) count=1;
    if(round==2) count=64;
    if(round==3) count=2;
    for(i=0;i<4;i++) saved[i]=entries[i].use_cnt;
    SetRFlags(GetRFlags|0x200);
    if(!I386HashTableResize(&heap,table,count) || !(GetRFlags&0x200) ||
        !I386HashTableValid(&heap,table) || table->mask!=count-1 || heap.allocations!=2) return 48;
    I386IrqSave;
    for(i=0;i<4;i++) if(entries[i].use_cnt!=saved[i]) return 49;
    if(HashFind("same",table,1)!=&entries[3] || HashFind("same",table,1,2)!=&entries[1] ||
        HashFind("same",table,1,3)!=&entries[0] || HashFind("same",table,1,4) ||
        HashFind("other",table,2)!=&entries[2]) return 50;
  }
  parent=I386HashTableNew(&heap,2);
  if(!parent) return 51;
  HashAdd(&entries[4],parent); table->next=parent;
  if(!I386HashTableResize(&heap,table,1) || table->next!=parent ||
      HashFind("parent",table,1)!=&entries[4] ||
      I386HashTableRemove(&heap,table,&entries[4]) ||
      I386HashTableDelete(&other,table)) return 52;
  used=heap.used; allocations=heap.allocations;
  SetRFlags(GetRFlags|0x200);
  //Remove a middle node, then head and tail, retaining caller-owned records.
  if(!I386HashTableRemove(&heap,table,&entries[1]) || entries[1].next ||
      I386HashTableRemove(&heap,table,&entries[1]) || !(GetRFlags&0x200) ||
      HashFind("same",table,1,2)!=&entries[0]) return 53;
  if(!I386HashTableRemove(&heap,table,&entries[3]) ||
      !I386HashTableRemove(&heap,table,&entries[0]) ||
      !I386HashTableRemove(&heap,table,&entries[2]) || heap.used!=used ||
      heap.allocations!=allocations) return 54;
  if(!I386HashTableDelete(&heap,table) || !(GetRFlags&0x200) ||
      I386HashTableDelete(&heap,table) || !I386HashTableValid(&heap,parent) ||
      HashFind("parent",parent,1)!=&entries[4] || heap.allocations!=2) return 55;
  I386IrqSave;
  if(!I386HashTableRemove(&heap,parent,&entries[4]) ||
      !I386HashTableDelete(&heap,parent) || heap.used || heap.allocations ||
      !I386HeapValid(&heap)) return 56;
  spare=I386HeapAlloc(&heap,65520);
  if(!spare || !I386HeapFree(&heap,spare) || heap.used) return 57;
  I386IrqRestore(flags);
  return 0;
}
