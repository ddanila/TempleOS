public Bool WinHorz(I64 left,I64 right,CTask *task=NULL)
{//Set task's win left and right columns.
  I64 d=right-left,flags;
  Bool changed=FALSE;
  if (!task) task=Fs;
  if (!TaskValidate(task)) return FALSE;
  if (d<0) d=0;
  if (left>=TEXT_COLS) {
    left=TEXT_COLS-1;
    right=left+d;
  }
  if (right<0) {
    right=0;
    left=right-d;
  }
  if (left>right) {
    if (left>0)
      right=left;
    else
      left=right;
  }
  flags=GetRFlags;
  SetRFlags(flags&~0x200);
  try {
    if (task->win_left!=left || task->win_right!=right) {
      task->win_left=left;
      task->win_right=right;
      TaskDerivedValsUpdate(task);
      changed=TRUE;
    }
  } catch { SetRFlags(flags); }
  SetRFlags(flags);
  return changed;
}

public Bool WinVert(I64 top,I64 bottom,CTask *task=NULL)
{//Set task's win top and bottom rows.
  I64 d=bottom-top,flags;
  Bool changed=FALSE;
  if (!task) task=Fs;
  if (!TaskValidate(task)) return FALSE;
  if (d<0) d=0;
  if (top>=TEXT_ROWS) {
    top=TEXT_ROWS-1;
    bottom=top+d;
  }
  if (bottom<=0) {
    bottom=1;
    top=bottom-d;
  }
  if (top>bottom) {
    if (top>=0)
      bottom=top;
    else
      top=bottom;
  }
  flags=GetRFlags;
  SetRFlags(flags&~0x200);
  try {
    if (task->win_top!=top || task->win_bottom!=bottom) {
      task->win_top=top;
      task->win_bottom=bottom;
      TaskDerivedValsUpdate(task);
      changed=TRUE;
    }
  } catch { SetRFlags(flags); }
  SetRFlags(flags);
  return changed;
}
