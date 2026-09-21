public U0 WinScrollNull(CTask *task,CD3I64 *s)
{//If panning a window has been done, restore to zero.
  s->x=task->scroll_x;
  s->y=task->scroll_y;
  s->z=task->scroll_z;
  task->scroll_x=0;
  task->scroll_y=0;
  task->scroll_z=0;
}

public U0 WinScrollRestore(CTask *task,CD3I64 *s)
{//Set window pan value to stored value.
  task->scroll_x=s->x;
  task->scroll_y=s->y;
  task->scroll_z=s->z;
}

