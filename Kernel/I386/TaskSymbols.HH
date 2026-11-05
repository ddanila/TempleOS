#ifndef I386_TASK_SYMBOLS_INCLUDED
#define I386_TASK_SYMBOLS_INCLUDED
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/HashTable.HH"
#include "/Kernel/I386/TaskHeaps.HH"
#define I386_TASK_SYMBOLS_MAGIC 0x54535933
#define I386_TASK_EXTERN_MAGIC 0x45585433
extern class CI386TaskSymbols;
#ifndef KERNEL_SYMBOL_TYPES_INCLUDED
extern class CHashFun;
extern class CHashClass;
#endif
class CI386TaskExternUsage {
  //Public CExternUsage prefix, followed by the native ownership journal.
  CI386TaskExternUsage *next;
  I64 rip;
  CI386TaskExternUsage *pending_next;
  CI386TaskSymbols *scope;
  CHashFun *function;
  U8 *code,*undefined_address;
  Bool indirect;
  CI386TaskHeaps *code_owner;
  I64 code_bytes,offset,argument_count,flags;
  CHashClass *result_type;
  U32 signature;
  CHashClass *arguments[1];
};
class CI386StoredAllocation {
  U8 *allocation;
  //NULL means bootstrap storage; otherwise this retained provider owns the bytes.
  CI386TaskHeaps *owner;
};
class CI386TaskStorage {
  CI386TaskStorage *next;
  U32 count;
  CI386StoredAllocation allocations[1];
};
class CI386TaskSymbols {
  CI386Task *task;
  CI386TaskSymbols *parent;
  CI386Heap *heap;
  CHashTable *table;
  U32 signature,children,buckets;
  CI386TaskStorage *storage;
  //Private answer category: the public RT_PTR value aliases RT_I64.
  U32 answer_ptr_stars;
  CI386TaskExternUsage *pending_externs;
};
extern Bool I386TaskStorageValid(CI386Heap *heap,CI386TaskStorage *storage);
extern Bool I386TaskStorageRelease(CI386Heap *heap,CI386TaskStorage *storage);
//Root table is borrowed; children own tables chained to their parent's scope.
//Owned entries obey the public HashDel allocation/borrowed-code contract.
//Published executable/static storage has a separate task lifetime. Children keep
//the parent alive; storage is reclaimed after owned symbols during destruction.
public extern Bool I386TaskSymbolsInit(CI386Task *task,CI386Heap *heap,CHashTable *table,I64 buckets=1024);
public extern Bool I386TaskSymbolsClone(CI386Task *source,CI386Task *target,CI386Heap *heap);
public extern Bool I386TaskSymbolsDestroy(CI386Task *task);
#endif
