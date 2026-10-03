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
