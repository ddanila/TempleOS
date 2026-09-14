#ifndef I386_EXCEPT_INCLUDED
#define I386_EXCEPT_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Frame.HH"
#define I386_EXCEPT_MAGIC 0x45323349
class CI386ExceptCapture
{
  U32 ebp,esp,ebx,esi,edi,eflags;
  U8 *catch_start,*untry_start;
};
class CI386Except
{
  CI386Except *previous;
  CI386Task *task;
  CI386Heap *heap;
  U32 signature;
  CI386ExceptCapture capture;
};
#assert sizeof(CI386ExceptCapture)==32
#assert sizeof(CI386Except)==48
public extern CI386Except *I386ExceptPush(CI386Task *task,CI386Heap *heap,
  CI386ExceptCapture *capture);
public extern Bool I386ExceptPop(CI386Task *task);
public extern Bool I386ExceptClear(CI386Task *task);
#define I386_EXCEPT_UNHANDLED 0
#define I386_EXCEPT_INVALID 1
#define I386_EXCEPT_RESUME_RETURNED 2
public extern I64 I386ExceptDispatch(CI386Task *task,I64 ch,
  U0 (*invoke)(CI386ExceptCapture *capture),
  U0 (*resume)(CI386ExceptCapture *capture));
#endif
