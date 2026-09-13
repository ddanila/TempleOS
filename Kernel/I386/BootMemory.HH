#ifndef I386_BOOT_MEMORY_INCLUDED
#define I386_BOOT_MEMORY_INCLUDED
#define I386_BOOT_INFO_ADDRESS 0x5000
#define I386_BOOT_INFO_MAGIC 0x4D323349
class CI386BootInfo
{
  U32 magic,version,conventional_kib,extended_kib,ebda_base;
  U32 stage_begin,stage_end,flags;
};
class CI386MemRange
{
  U32 base,size;
};
#assert sizeof(CI386BootInfo)==32
#assert sizeof(CI386MemRange)==8
public extern Bool I386BootArena(CI386BootInfo *info,CI386MemRange *reserved,
  I64 count,CI386MemRange *result,Bool extended=FALSE);
#endif
