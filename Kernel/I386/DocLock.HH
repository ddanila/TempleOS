#ifndef I386_DOC_LOCK_INCLUDED
#define I386_DOC_LOCK_INCLUDED
#include "/Kernel/DocTypes.HH"
public extern Bool I386DocLock(CDoc *doc);
public extern Bool I386DocUnlock(CDoc *doc);
//Containing retained runtime supplies a cleanup-aware current-task checkpoint.
extern U0 I386DocBreakPoll();
#endif
