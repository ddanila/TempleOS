#ifndef I386_FOCUS_INCLUDED
#define I386_FOCUS_INCLUDED
#include "/Kernel/I386/Message.HH"
public extern Bool I386FocusSet(CI386Scheduler *scheduler,CI386Task *task);
public extern Bool I386FocusMsgSend(CI386Scheduler *scheduler,I64 type,I64 arg1,I64 arg2);
#endif
