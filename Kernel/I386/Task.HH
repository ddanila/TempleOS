#ifndef I386_TASK_INCLUDED
#define I386_TASK_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Heap.HH"
class CI386OwnedTask
{
  CI386Task task;
  CI386Heap *heap;
  U32 allocation_size,signature;
  CI386Heap local_heap;
};
public _intern 0x15 CI386Task *I386TaskSelf();
public extern U0 I386TaskReturn();
public extern CI386OwnedTask *I386TaskSpawn(CI386Scheduler *s,CI386Heap *heap,
  I64 stack_size,U0 (*entry)(I64 arg),I64 arg,U16 fs=0x18,U16 gs=0x20,I64 private_size=0);
public extern Bool I386TaskDestroy(CI386OwnedTask *owned);
public extern U8 *I386TaskAlloc(I64 size,Bool zero=FALSE);
public extern Bool I386TaskFree(U8 *ptr);
#endif
