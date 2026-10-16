U0 PostMsgWait(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags=0)
{//Post message to a task and wait until task is idle.See $LK,"msg_code",A="MN:MSG_CMD"$.
  PostMsg(task,msg_code,arg1,arg2,flags);
  TaskWait(task);
}
