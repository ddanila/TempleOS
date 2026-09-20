#help_index "DolDoc"
#include "/Adam/DolDoc/DocLockCore.HC"
public Bool DocLock(CDoc *doc)
{//Make this task have exclusive access to this doc.
  return DocLockCore(doc,Fs,&Yield,&BreakLock);
}
public Bool DocUnlock(CDoc *doc)
{//Release exclusive lock on access to doc.
  return DocUnlockCore(doc,Fs,&BreakUnlock);
}

