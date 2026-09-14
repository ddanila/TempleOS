#ifndef I386_TASK_SYMBOLS_INCLUDED
#define I386_TASK_SYMBOLS_INCLUDED
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/HashTable.HH"
#define I386_TASK_SYMBOLS_MAGIC 0x54535931
class CI386TaskSymbols {
  CI386Task *task;
  CI386TaskSymbols *parent;
  CI386Heap *heap;
  CHashTable *table;
  U32 signature,children,buckets;
};
//Root table is borrowed; children own tables chained to their parent's scope.
//Owned entries obey the public HashDel allocation/borrowed-code contract.
public extern Bool I386TaskSymbolsInit(CI386Task *task,CI386Heap *heap,CHashTable *table,I64 buckets=1024);
public extern Bool I386TaskSymbolsClone(CI386Task *source,CI386Task *target,CI386Heap *heap);
public extern Bool I386TaskSymbolsDestroy(CI386Task *task);
#endif
