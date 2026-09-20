#include "/Kernel/I386/HashPublic.HH"
#include "/Kernel/HashTablePublicCore.HC"
#include "/Kernel/SymbolDelete.HC"
U0 MemorySymbolFree(U8 *context,U8 *allocation) { MemoryFree(allocation); }
U0 MemoryHashDel(CHashSrcSym *symbol)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&MemorySymbolFree;
  SymbolHashDel(&owner,symbol);
}
CHashTable *MemoryHashTableNew(I64 size,CTask *task=0)
{
  return HashTableNewCore(size,task,&MemoryCAlloc,&MemoryFree);
}
U0 MemoryHashTableDel(CHashTable *table)
{
  HashTableDelCore(table,&MemoryHashDel,&MemoryFree);
}
I64 MemoryHashLstAdd(U8 *list,I64 type,CHashTable *table)
{
  return HashLstAddCore(list,type,table,&MemoryCAlloc,&MemoryStrNew,&MemoryFree,&HashAdd);
}

#include "/Kernel/I386/Frame.HH"
#include "/Kernel/DefineListCore.HC"
U8 *MemoryDefineSourceLink(U8 *caller)
{//The original AD:0x%X source metadata, with uppercase unpadded hex.
  U8 buf[22],*digits="0123456789ABCDEF";
  U64 address=(caller+0)(U64);
  I64 shift=60,pos=5;
  buf[0]='A'; buf[1]='D'; buf[2]=':'; buf[3]='0'; buf[4]='x';
  while(shift && !(address>>shift)) shift-=4;
  do { buf[pos++]=digits[(address>>shift)&15]; shift-=4; } while(shift>=0);
  buf[pos]=0;
  return MemoryStrNew(buf);
}
CHashDefineStr *MemoryDefineLstLoad(U8 *name,U8 *list)
{
  CI386Frame *frame=GetRBP;
  CI386Task *task=I386TaskSelf;
  return DefineLstLoadCore(name,list,task->hash_table,frame->return_address,
    &MemoryCAlloc,&MemoryStrNew,&MemoryDefineSourceLink,&MemoryHashDel,&HashAdd);
}
I64 MemoryHashDefineLstAdd(U8 *name,I64 type,CHashTable *table)
{
  CI386Task *task=I386TaskSelf;
  CHashDefineStr *entry=HashFind(name,task->hash_table,HTT_DEFINE_STR);
  if(entry) return MemoryHashLstAdd(entry->data,type,table);
  return 0;
}
