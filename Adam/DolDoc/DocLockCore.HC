//Shared original document lock policy; platform callbacks yield and control breaks.
#help_index "DolDoc"

Bool DocLockCore(CDoc *doc,CTask *self,U0 (*yield)(),Bool (*break_lock)(CTask *task))
{//Make this task have exclusive access to this doc.
  if (!Bt(&doc->locked_flags,DOClf_LOCKED) || doc->owning_task!=self) {
    while (LBts(&doc->locked_flags,DOClf_LOCKED))
      (*yield)();
    if (doc->owning_task!=self) {
      if ((*break_lock)(self))
        LBts(&doc->flags,DOCf_BREAK_UNLOCKED);
      else
        LBtr(&doc->flags,DOCf_BREAK_UNLOCKED);
    }
    doc->owning_task=self;
    return TRUE;
  } else
    return FALSE;
}

Bool DocUnlockCore(CDoc *doc,CTask *self,Bool (*break_unlock)(CTask *task))
{//Release exclusive lock on access to doc.
  Bool unlock_break;
  if (Bt(&doc->locked_flags,DOClf_LOCKED) && doc->owning_task==self) {
    doc->owning_task=0;
    unlock_break=Bt(&doc->flags,DOCf_BREAK_UNLOCKED);
    LBtr(&doc->locked_flags,DOClf_LOCKED);
    if (unlock_break)
      (*break_unlock)(self);
    return TRUE;
  } else
    return FALSE;
}

