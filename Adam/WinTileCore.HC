//Original window tiling traversal; caller supplies interrupt exclusion.
U0 WinTileHorzCore()
{//Tile windows horizontally top-to-bottom.
  CTask *task,*last_task=Fs;
  I64 cnt,c,i,vert_size,no_border;

  task=sys_winmgr_task;
  cnt=0;
  do {
    if (!Bt(&task->win_inhibit,WIf_SELF_FOCUS))
      cnt++;
    task=task->last_task;
  } while (task!=sys_winmgr_task);

  task=sys_winmgr_task;
  i=0;
  do {
    if (!Bt(&task->win_inhibit,WIf_SELF_FOCUS)) {
      no_border=Bt(&task->display_flags,DISPLAYf_NO_BORDER);
      c=cnt- i&~3;
      if (!c)
	c=1;
      else if (c>4)
	c=4;
      vert_size=(TEXT_ROWS-1)/c;

      WinHorz(1-no_border,TEXT_COLS-2+no_border,task);
      WinVert((i&3)*vert_size+2-no_border,(i&3+1)*vert_size+no_border,task);
      last_task=task;
      if (i&3==3)
	WinVert(task->win_top,TEXT_ROWS-2,task);
      i++;
    }
    task=task->last_task;
  } while (task!=sys_winmgr_task);
  WinVert(last_task->win_top,TEXT_ROWS-2,last_task);
}

U0 WinTileVertCore()
{//Tile windows vertically side-by-side.
  CTask *task,*last_task=Fs;
  I64 cnt,c,i,horz_size,no_border;
  task=sys_winmgr_task;
  cnt=0;
  do {
    if (!Bt(&task->win_inhibit,WIf_SELF_FOCUS))
      cnt++;
    task=task->last_task;
  } while (task!=sys_winmgr_task);

  task=sys_winmgr_task;
  i=0;
  do {
    if (!Bt(&task->win_inhibit,WIf_SELF_FOCUS)) {
      no_border=Bt(&task->display_flags,DISPLAYf_NO_BORDER);
      c=cnt- i&~3;
      if (!c)
	c=1;
      else if (c>4)
	c=4;
      horz_size=TEXT_COLS/c;
      WinHorz((i&3)*horz_size+1-no_border,(i&3+1)*horz_size-1+no_border,task);
      WinVert(2-no_border,TEXT_ROWS-2+no_border,task);
      last_task=task;
      if (i&3==3)
	WinHorz(task->win_left,TEXT_COLS-2,task);
      i++;
    }
    task=task->last_task;
  } while (task!=sys_winmgr_task);
  WinHorz(last_task->win_left,TEXT_COLS-2,last_task);
}
