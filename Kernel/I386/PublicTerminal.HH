#ifndef I386_PUBLIC_TERMINAL_INCLUDED
#define I386_PUBLIC_TERMINAL_INCLUDED
public _extern _USER_CMD_LINE U0 UserCmdLine(I64 dummy=0);
public _extern _USER_TASK_CONT U0 UserTaskCont();
public _extern _WIN_FOCUS CTask *WinFocus(CTask *task=0);
#endif
