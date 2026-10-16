public Bool WinBorder(Bool val=OFF,CTask *task=NULL)
{//Turn off (or on) window border.
  Bool old_has_border;
  if (!task) task=Fs;
  if (!TaskValidate(task)) return FALSE;
  PUSHFD
  CLI //TODO Multiprocessor safe
  old_has_border=!Bt(&task->display_flags,DISPLAYf_NO_BORDER);
  if (val) {
    if (!old_has_border) {
      LBtr(&task->display_flags,DISPLAYf_NO_BORDER);
      task->win_left++; task->win_right--;
      task->win_top++;	task->win_bottom--;
      TaskDerivedValsUpdate(task,FALSE);
    }
  } else {
    if (old_has_border) {
      LBts(&task->display_flags,DISPLAYf_NO_BORDER);
      task->win_left--; task->win_right++;
      task->win_top--;	task->win_bottom++;
      TaskDerivedValsUpdate(task,FALSE);
    }
  }
  POPFD
  return old_has_border;
}
