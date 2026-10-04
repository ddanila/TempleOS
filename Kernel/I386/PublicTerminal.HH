#ifndef I386_PUBLIC_TERMINAL_INCLUDED
#define I386_PUBLIC_TERMINAL_INCLUDED
public _extern _USER_CMD_LINE U0 UserCmdLine(I64 dummy=0);
public _extern _USER_TASK_CONT U0 UserTaskCont();
public _extern _WIN_FOCUS CTask *WinFocus(CTask *task=0);
public _extern _USER CTask *User(U8 *fmt=0,...);
public _extern _XTALK U0 XTalk(CTask *task,U8 *fmt,...);
public _extern _TASK_WAIT U0 TaskWait(CTask *task=0,Bool cmd_line_pmt=0);
#endif
