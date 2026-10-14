#ifndef I386_BOOT_MAP_INCLUDED
#define I386_BOOT_MAP_INCLUDED
#include "/Kernel/I386/BootMemory.HH"
#define I386_BOOT_MAP_ADDRESS 0x5040
#define I386_BOOT_MAP_MAGIC 0x50324D49
#define I386_BOOT_MAP_MAX 32
class CI386BootMapEntry
{
  U64 base,size;
  U32 type,attributes;
};
class CI386BootMap
{
  U32 magic,version,count,complete;
  CI386BootMapEntry entries[I386_BOOT_MAP_MAX];
};
#assert sizeof(CI386BootMapEntry)==24
#assert offset(CI386BootMap.entries)==16
#assert sizeof(CI386BootMap)==784
public extern Bool I386BootMapArena(CI386BootInfo *info,CI386BootMap *map,
  CI386MemRange *reserved,I64 count,CI386MemRange *result);
#endif
