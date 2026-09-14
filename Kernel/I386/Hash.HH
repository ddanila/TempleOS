#ifndef I386_HASH_INCLUDED
#define I386_HASH_INCLUDED
#include "/Kernel/HashTypes.HH"
public extern I64 HashStr(U8 *st);
public extern CHash **HashBucketFind(U8 *needle_str,CHashTable *haystack_table);
public extern U0 HashAdd(CHash *entry,CHashTable *table);
public extern CHash *HashFind(U8 *needle_str,CHashTable *haystack_table,
  I64 mask,I64 instance=1);
public extern CHash *HashSingleTableFind(U8 *needle_str,CHashTable *haystack_table,
  I64 mask,I64 instance=1);
#endif
