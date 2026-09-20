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
