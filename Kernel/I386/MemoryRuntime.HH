#ifndef I386_MEMORY_RUNTIME_INCLUDED
#define I386_MEMORY_RUNTIME_INCLUDED
#include "/Kernel/I386/Task.HH"
#define I386_MEMORY_SERVICES_VERSION 8
//Every entry is retained module code. Main only fills this candidate table;
//binding starts after the kernel accepts its target, imports and API addresses.
class CI386MemoryServices {
  U32 version,bytes;
  Bool (*bind)(CI386Task *root,CI386Heap *heap,CHashTable *symbols);
  U0 (*probe)(I64 phase);
};
#endif
