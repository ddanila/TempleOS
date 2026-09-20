#include "/Kernel/I386/DocLock.HH"
#include "/Kernel/I386/TaskBreak.HH"
#include "/Kernel/I386/Intrinsic.HH"
#include "/Adam/DolDoc/DocLockCore.HC"
U0 I386DocYield()
{//A document waiter owns no lock yet. Resume normally before checking breaks.
  I386SchedYield(I386TaskSelf->owner);
  I386DocBreakPoll;
}
Bool I386DocBreakLock(CTask *task)
{
  return I386TaskBreakLock(task);
}
Bool I386DocBreakUnlock(CTask *task)
{//DocUnlockCore has already released ownership and the document lock bit.
  Bool result=I386TaskBreakUnlock(task);
  I386DocBreakPoll;
  return result;
}
public Bool I386DocLock(CDoc *doc)
{
  return DocLockCore(doc,I386TaskSelf,&I386DocYield,&I386DocBreakLock);
}
public Bool I386DocUnlock(CDoc *doc)
{
  return DocUnlockCore(doc,I386TaskSelf,&I386DocBreakUnlock);
}
