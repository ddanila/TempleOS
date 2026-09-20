#ifndef I386_COMPILER_PROBE_INCLUDED
#define I386_COMPILER_PROBE_INCLUDED
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Kernel/I386/FileRuntime.HH"
//Boot diagnostics also borrow the mounted volume and resident source helpers.
#define I386_COMPILER_PROBE_VERSION 13
//Borrowed for a synchronous call only. The probe registers no callbacks or tasks.
class CI386CompilerProbe {
  U32 version,bytes;
  CI386Heap *heap;
  CI386CompilerServices *compiler;
  CHashTable *symbols;
  CHashClass *i64_type;
  U8 *runtime_image;
  I64 runtime_size,phase;
  CI386LexIncludeService *disk_include;
  CI386FileServices *files;
  CHashClass **internal_types;
  //Boot-only diagnostics borrow the mounted volume and original resident helpers.
  CI386RedSea *volume;
  U8 *(*source_read)(CI386RedSea *volume,CI386Heap *heap,I64 directory,U8 *path,I64 *size);
  Bool (*source_pop)(CI386Heap *heap,CCmpCtrl *cc,U0 (*document)(U8 *context,CDoc *document),U8 *context);
};
#endif
