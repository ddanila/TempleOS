#ifndef I386_PUBLIC_HASH_INCLUDED
#define I386_PUBLIC_HASH_INCLUDED
#include "/Kernel/I386/PublicTaskTypes.HH"
#include "/Kernel/HashFlags.HH"
#include "/Kernel/DefineTypes.HH"
#help_index "Hash"
public extern U0 HashAdd(CHash *entry,CHashTable *table);
public extern CHash *HashFind(U8 *name,CHashTable *table,I64 mask,I64 instance=1);
public _extern _HASH_TABLE_NEW CHashTable *HashTableNew(I64 size,CTask *mem_task=0);
public _extern _HASH_TABLE_DEL U0 HashTableDel(CHashTable *table);
public _extern _HASH_DEL U0 HashDel(CHashSrcSym *symbol);
public _extern _HASH_LIST_ADD I64 HashLstAdd(U8 *list,I64 type,CHashTable *table);
public _extern _DEFINE_LIST_LOAD CHashDefineStr *DefineLstLoad(U8 *name,U8 *list);
public _extern _HASH_DEFINE_LIST_ADD I64 HashDefineLstAdd(U8 *name,I64 type,CHashTable *table);
#include "/Kernel/ListFlags.HH"
public _extern _LIST_SUB U8 *LstSub(I64 sub,U8 *list);
public _extern _LIST_MATCH I64 LstMatch(U8 *needle,U8 *list,I64 flags=0);
public _extern _DEFINE U8 *Define(U8 *name);
public _extern _DEFINE_SUB U8 *DefineSub(I64 sub,U8 *name);
public _extern _DEFINE_COUNT I64 DefineCnt(U8 *name);
public _extern _DEFINE_MATCH I64 DefineMatch(U8 *needle,U8 *name,I64 flags=0);
#endif
