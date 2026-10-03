//Retained lifecycle helpers share the boot task layout and installed switch/bind
//callbacks. Local names keep imports and core entry addresses independent.
//Include last: HolyC has no undef directive, so aliases remain in this unit.
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Context.HH"
#define I386_TASK_RETAINED_BUILD 1
#define I386HeapRegionValid TaskRuntimeHeapRegionValid
#define I386HeapInit TaskRuntimeHeapInit
#define I386ContextInit TaskRuntimeContextInit
#define I386TaskHeapHooks TaskRuntimeTaskHeapHooks
#define I386SchedInit TaskRuntimeSchedInit
#define I386SchedPrepare TaskRuntimeSchedPrepare
#define I386SchedActivate TaskRuntimeSchedActivate
#define I386SchedAdd TaskRuntimeSchedAdd
#define I386SchedReady TaskRuntimeSchedReady
#define I386SchedSetClock TaskRuntimeSchedSetClock
#define I386SchedNext TaskRuntimeSchedNext
#define I386SchedYield TaskRuntimeSchedYield
#define I386SchedFinish TaskRuntimeSchedFinish
#define I386SchedReap TaskRuntimeSchedReap
#define I386SchedBlock TaskRuntimeSchedBlock
#define I386SchedWake TaskRuntimeSchedWake
#define I386SchedIdle TaskRuntimeSchedIdle
#define I386SchedSetBind TaskRuntimeSchedSetBind
#define I386SchedSetCleanup TaskRuntimeSchedSetCleanup
#define I386TaskReturn TaskRuntimeTaskReturn
#define I386TaskCreateFrom TaskRuntimeTaskCreateFrom
#define I386TaskSpawnFrom TaskRuntimeTaskSpawnFrom
#define I386TaskSpawn TaskRuntimeTaskSpawn
#define I386TaskDestroy TaskRuntimeTaskDestroy
public extern Bool TaskRuntimeSchedWake(CI386Scheduler *s,CI386Task *task);
#include "/Kernel/I386/HeapInit.HC"
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/SchedulerCore.HC"
#include "/Kernel/I386/TaskLifetime.HC"

public Bool TaskRuntimeTaskDiscard(CI386OwnedTask *owned)
{//Dispose an exclusively owned dormant context from another task's stack.
//A failed teardown keeps a retired owned record for a later destroy attempt.
  U32 flags=I386IrqSave;
  CI386Task *task;
  Bool result;
  if(!owned || owned->signature!=0x54323349 ||
      I386HeapSize(owned->heap,owned)!=owned->allocation_size) {
    I386IrqRestore(flags); return FALSE;
  }
  task=&owned->task;
  if(!task->owner || task==task->owner->current || task==task->owner->root ||
      task->addr!=task || task->task_signature!=TASK_SIGNATURE_VAL ||
      !task->context.esp || task->finished || task->finishing || task->blocked ||
      task->next || task->last || task->next_task!=task || task->last_task!=task ||
      task->lifetime_refs || task->join_head || task->join_target || task->messages ||
      task->except_top || task->io_locks || task->wait || task->active_controls ||
      task->compiler_cleanup || task->compiler_cleanup_failed || task->compiler_busy ||
      task->cleanup || task->next_ctrl!=&task->next_ctrl ||
      task->last_ctrl!=&task->next_ctrl || task->next_cc!=&task->next_cc ||
      task->last_cc!=&task->next_cc || task->owner->focus==task) {
    I386IrqRestore(flags); return FALSE;
  }
  task->next_task=task->last_task=0;
  task->finished=1; task->finishing=1;
  result=TaskRuntimeTaskDestroy(owned);
  I386IrqRestore(flags); return result;
}
