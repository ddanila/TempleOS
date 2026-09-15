#ifndef I386_COMPILER_PROBE_INCLUDED
#define I386_COMPILER_PROBE_INCLUDED
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Kernel/I386/FileRuntime.HH"
//Native task extensions include public heap ownership callbacks.
#define I386_COMPILER_PROBE_VERSION 10
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
};
#endif
