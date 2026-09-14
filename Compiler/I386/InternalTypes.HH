#ifndef I386_INTERNAL_TYPES_INCLUDED
#define I386_INTERNAL_TYPES_INCLUDED
#include "/Compiler/InternalTypes.HH"
#include "/Kernel/I386/HashTable.HH"
class CI386InternalTypes
{
  CI386Heap *heap;
  CHashTable *table;
  CHashClass *by_raw[RT_RTS_NUM];
};
//Caller supplies a zeroed, exclusively owned registry. Keep its table read-only.
public extern Bool I386InternalTypesInit(CI386InternalTypes *registry,CI386Heap *heap);
//Detach all incoming references before deletion; leaves a reusable zeroed registry.
public extern Bool I386InternalTypesDelete(CI386InternalTypes *registry);
#endif
