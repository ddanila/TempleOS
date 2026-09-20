#ifndef I386_HASH_PUBLIC_INCLUDED
#define I386_HASH_PUBLIC_INCLUDED
#include "/Kernel/SymbolTypes.HH"
extern CHashTable *MemoryHashTableNew(I64 size,CTask *task=0);
extern U0 MemoryHashTableDel(CHashTable *table);
extern U0 MemoryHashDel(CHashSrcSym *symbol);
extern I64 MemoryHashLstAdd(U8 *list,I64 type,CHashTable *table);
extern U0 MemoryHashProbe();
#endif
