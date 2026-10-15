public U0 WinMax(CTask *task=NULL)
{//Maximize task's window, preserving interrupt state on callback exceptions.
  I64 no_border,flags;
  if (!task) task=Fs;
  if (!TaskValidate(task)) return;
  flags=GetRFlags;
  SetRFlags(flags&~512); //TODO Multiprocessor safe
  try {
    no_border=Bt(&task->display_flags,DISPLAYf_NO_BORDER);
    WinHorz(1-no_border,TEXT_COLS-2+no_border,task);
    WinVert(2-no_border,TEXT_ROWS-2+no_border,task);
    WinToTop(task);
  } catch { SetRFlags(flags); }
  SetRFlags(flags);
}
