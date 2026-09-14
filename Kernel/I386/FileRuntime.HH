#ifndef I386_FILE_RUNTIME_INCLUDED
#define I386_FILE_RUNTIME_INCLUDED
#include "/Compiler/I386/LexFileRead.HH"
#include "/Kernel/I386/Scheduler.HH"
#define I386_FILE_SERVICES_VERSION 2
//Caller-owned interface. Code is borrowed from a kernel-lifetime retained module.
class CI386FileServices {
  U32 version,bytes;
  Bool (*include)(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name);
  U8 *(*read)(CI386Heap *heap,CFilePathContext *paths,CI386FileVolumes *volumes,
    U8 *filename,I64 *size,I64 *attr,U8 **name);
  Bool (*bind)(CI386Scheduler *scheduler,CI386RedSea *volume);
};
#endif
