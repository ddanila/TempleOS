#ifndef I386_FILE_RUNTIME_INCLUDED
#define I386_FILE_RUNTIME_INCLUDED
#include "/Compiler/I386/LexFileRead.HH"
#include "/Kernel/I386/TaskFileRead.HH"
#include "/Kernel/I386/TaskCompiler.HH"
//Native task extensions include public heap ownership callbacks.
#define I386_FILE_SERVICES_VERSION 24
//Caller-owned interface. Code is borrowed from a kernel-lifetime retained module.
class CI386FileServices {
  U32 version,bytes;
  Bool (*include)(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name);
  U8 *(*read)(CI386Heap *heap,U8 *filename,I64 *size,I64 *attr,U8 **name);
  Bool (*bind)(CI386Scheduler *scheduler,CI386RedSea *volume);
  Bool (*init)(CI386Task *task,CI386Heap *heap,CFilePathContext *paths,CI386FileVolumes *volumes);
  Bool (*compiler_init)(CI386CompilerServices *compiler,U8 *tmp_filename,U32 *alpha_numeric,U32 *alpha_numeric_no_at);
  //Owned absolute name with default extension; no disk access or existence check.
  U8 *(*name_abs)(CI386Heap *heap,U8 *name,U8 *extension);
  CCmpCtrl *(*control_new)(U8 *buffer,I64 flags,U8 *filename);
  //Cancel a queued ATA-channel acquisition, not an active transfer or owner.
  Bool (*cancel_wait)(CI386Task *task);
  Bool (*write)(U8 *filename,U8 *buffer,I64 size,I64 attr=0);
};
#endif
