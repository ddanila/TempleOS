#ifndef I386_PUBLIC_MESSAGE_INCLUDED
#define I386_PUBLIC_MESSAGE_INCLUDED
#include "/Kernel/I386/PublicTaskTypes.HH"
#include "/Kernel/MessageCodes.HH"
#help_index "Messages"
public _extern _TASK_MSG CJob *TaskMsg(CTask *task,CTask *master,I64 msg_code,I64 arg1,I64 arg2,I64 flags);
public _extern _POST_MSG U0 PostMsg(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
public _extern _MSG U0 Msg(I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
#endif
