#ifndef I386_HASH_TABLE_INCLUDED
#define I386_HASH_TABLE_INCLUDED
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/Heap.HH"
public extern CHashTable *I386HashTableNew(CI386Heap *heap,I64 buckets);
public extern Bool I386HashTableValid(CI386Heap *heap,CHashTable *table);
public extern Bool I386HashTableResize(CI386Heap *heap,CHashTable *table,I64 buckets);
public extern Bool I386HashTableRemove(CI386Heap *heap,CHashTable *table,CHash *entry);
public extern Bool I386HashTableDelete(CI386Heap *heap,CHashTable *table);
#endif
