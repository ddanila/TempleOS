#ifndef I386_PUBLIC_MESSAGE_INCLUDED
#define I386_PUBLIC_MESSAGE_INCLUDED
#include "/Kernel/I386/PublicTaskTypes.HH"
#include "/Kernel/MessageCodes.HH"
#include "/Kernel/SemaTypes.HH"
#help_index "Messages"
public _extern _SYS_SEMAS CSema sys_semas[SEMA_SEMAS_NUM];
public _extern _SYS_MACRO_HEAD CJob sys_macro_head;
public _extern _SYS_MACRO_TASK CTask *sys_macro_task;
public _extern _TASK_MSG CJob *TaskMsg(CTask *task,CTask *master,I64 msg_code,I64 arg1,I64 arg2,I64 flags);
public _extern _POST_MSG U0 PostMsg(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
public _extern _MSG U0 Msg(I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
public _extern _JOBS_HNDLR I64 JobsHndlr(I64 run_flags,CTask *task=0);
public _extern _SCAN_MSG I64 ScanMsg(I64 *arg1=0,I64 *arg2=0,I64 mask=~1,CTask *task=0);
public _extern _GET_MSG I64 GetMsg(I64 *arg1=0,I64 *arg2=0,I64 mask=~1,CTask *task=0);
public _extern _FLUSH_MSGS I64 FlushMsgs(CTask *task=0);
#endif
