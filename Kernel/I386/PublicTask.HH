#ifndef I386_PUBLIC_TASK_INCLUDED
#define I386_PUBLIC_TASK_INCLUDED
public _extern _YIELD U0 Yield();
public _extern _SLEEP U0 Sleep(I64 mS);
public _extern _SLEEP_UNTIL U0 SleepUntil(I64 wake_jiffy);
#endif
