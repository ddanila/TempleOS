#ifndef I386_PUBLIC_TASK_INCLUDED
#define I386_PUBLIC_TASK_INCLUDED
public _extern _YIELD U0 Yield();
public _extern _SLEEP U0 Sleep(I64 mS);
public _extern _SLEEP_UNTIL U0 SleepUntil(I64 wake_jiffy);
public _extern _SPAWN CTask *Spawn(U0 (*entry)(U8 *data),U8 *data=0,U8 *name=0,I64 target_cpu=-1,CTask *parent=0,I64 stack_size=0,I64 flags=256);
public _extern _EXIT U0 Exit();
public _extern _TASK_QUE_INS U0 TaskQueIns(CTask *task,CTask *pred=0);
public _extern _SUSPEND Bool Suspend(CTask *task=0,Bool state=1);
public _extern _IS_SUSPENDED Bool IsSuspended(CTask *task=0);
public _extern _KILL Bool Kill(CTask *task,Bool wait=1,Bool just_break=0);
#endif
