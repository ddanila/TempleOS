#ifndef I386_MODULE_INCLUDED
#define I386_MODULE_INCLUDED
#define I386_MODULE_MAGIC 0x4D323354 //T32M, little endian
#define I386_MODULE_VERSION 2
#define I386_MODULE_ABI 1
#define I386_MODULE_EXPORT 1
#define I386_MODULE_REL32 2
#define I386_MODULE_DATA_EXPORT 3
#define I386_MODULE_DATA_RANGE 4
#define I386_MODULE_ADDRESS 5
class CI386ModuleHeader
{
  U32 magic;
  U16 version;
  U8 cpu,pointer_size;
  U32 abi,total_size,code_size,record_count,records_offset,strings_offset;
};
class CI386ModuleRecord
{
  U32 kind,offset,name_offset,name_length;
};
#assert sizeof(CI386ModuleHeader)==32
#assert sizeof(CI386ModuleRecord)==16
#endif
