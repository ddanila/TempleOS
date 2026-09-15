#ifndef I386_SCHEDULER_INCLUDED
#define I386_SCHEDULER_INCLUDED
#include "/Kernel/I386/Context.HH"
#include "/Kernel/I386/Heap.HH"
extern class CI386Scheduler;
#include "/Kernel/HashTypes.HH"
extern class CI386MsgQueue;
extern class CI386Except;
#ifndef CCmpCtrl
extern class CCmpCtrl;
#endif
#include "/Kernel/I386/PublicTaskTypes.HH"
#define I386_EXCEPT_CALLERS TASK_EXCEPT_CALLERS
class CI386Task:CTask
{
  CI386Context context;
  CI386Task *next,*last;
  CI386Scheduler *owner;
  U32 finished,blocked;
  CI386Task *join_head,*join_next,*join_target;
  CI386Heap *memory;
  U0 (*cleanup)(CI386Task *task);
  U32 finishing;
  CI386MsgQueue *messages;
  CI386Except *except_top;
  U32 io_locks;
  U8 *file_state;
  Bool (*file_clone)(CI386Task *source,CI386Task *target,CI386Heap *heap);
  Bool (*file_destroy)(CI386Task *task);
  U32 lifetime_refs;
  U8 *symbol_state;
  Bool (*symbol_clone)(CI386Task *source,CI386Task *target,CI386Heap *heap);
  Bool (*symbol_destroy)(CI386Task *task);
  Bool (*compiler_cleanup)(CI386Task *task);
  U32 active_controls,compiler_cleanup_failed,compiler_busy;
  U8 *heap_state;
  Bool (*heap_clone)(CI386Task *source,CI386Task *target,CI386Heap *heap);
  Bool (*heap_destroy)(CI386Task *task);
};
class CI386Scheduler
{
  CI386Task *root,*current;
  U0 (*swap)(CI386Context *old,CI386Context *next);
  U0 (*bind)(CI386Task *task);
  CI386Task *focus;
};
class CI386Cpu:CCPU { CI386Scheduler *scheduler; };
//Internal hook shape: 0 absent, 31 complete; other masks are partial state.
extern I64 I386TaskHeapHooks(CI386Task *task);
public extern Bool I386SchedInit(CI386Scheduler *s,CI386Task *root,
  U0 (*swap)(CI386Context *old,CI386Context *next));
public extern Bool I386SchedAdd(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedYield(CI386Scheduler *s);
public extern Bool I386SchedFinish(CI386Scheduler *s);
public extern Bool I386SchedReap(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedBlock(CI386Scheduler *s);
public extern Bool I386SchedWake(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedIdle(CI386Scheduler *s,U0 (*idle)());
public extern Bool I386SchedSetBind(CI386Scheduler *s,U0 (*bind)(CI386Task *task));
public extern Bool I386SchedJoin(CI386Scheduler *s,CI386Task *target);
public extern Bool I386SchedSetCleanup(CI386Scheduler *s,U0 (*cleanup)(CI386Task *task));
#endif
