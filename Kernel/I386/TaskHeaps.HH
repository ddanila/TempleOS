#ifndef I386_TASK_HEAPS_INCLUDED
#define I386_TASK_HEAPS_INCLUDED
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Memory.HH"
#define I386_TASK_HEAPS_MAGIC 'TH32'
class CI386TaskHeaps {
  CI386Task *task;
  CI386TaskHeaps *parent;
  CI386Heap *storage;
  U32 signature,children;
  CHeapCtrl control;
  //Retained provider callbacks for compiler-owned executable buffers. The task
  //and its heap control outlive compiler controls and published code storage.
  U8 *(*code_allocate)(CI386TaskHeaps *owner,I64 bytes);
  Bool (*code_release)(CI386TaskHeaps *owner,U8 *allocation);
  I64 (*code_capacity)(CI386TaskHeaps *owner,U8 *allocation);
};
//One public code/data control per task on the shared flat i386 target.
//Pool and callback code are borrowed. Descendants pin the parent's state;
//the root's provider must retain its pool/arena until the root is detached.
//Storage uses the bootstrap allocator until its callers migrate to public heaps.
extern Bool I386TaskHeapsInit(CI386Task *root,CI386Heap *storage,CI386PublicPool *pool);
extern Bool I386TaskHeapsClone(CI386Task *source,CI386Task *target,CI386Heap *storage);
extern Bool I386TaskHeapsDestroy(CI386Task *task);
#endif
