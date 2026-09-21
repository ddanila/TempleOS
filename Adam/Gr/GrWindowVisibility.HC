U0 WinZBufFill(CTask *task)
{//Not public
  I64 y,t,b,l,r,w;
  if (!Bt(&task->display_flags,DISPLAYf_NO_BORDER)) {
    if (task->win_top-1>0)
      t=task->win_top-1;
    else
      t=0;
    if (task->win_bottom+1<TEXT_ROWS)
      b=task->win_bottom+1;
    else
      b=TEXT_ROWS-1;
    if (task->win_left-1>0)
      l=task->win_left-1;
    else
      l=0;
    if (task->win_right+1<TEXT_COLS)
      r=task->win_right+1;
    else
      r=TEXT_COLS-1;
  } else {
    if (task->win_top>0)
      t=task->win_top;
    else
      t=0;
    if (task->win_bottom<TEXT_ROWS)
      b=task->win_bottom;
    else
      b=TEXT_ROWS-1;
    if (task->win_left>0)
      l=task->win_left;
    else
      l=0;
    if (task->win_right<TEXT_COLS)
      r=task->win_right;
    else
      r=TEXT_COLS-1;
  }
  t=MinI64(TEXT_ROWS-1,MaxI64(0,t));
  b=MinI64(TEXT_ROWS-1,MaxI64(t,b));
  l=MinI64(TEXT_COLS-1,MaxI64(0,l));
  r=MinI64(TEXT_COLS-1,MaxI64(l,r));
  if (w=r-l+1)
    for (y=t;y<=b;y++)
      MemSetU16(gr.win_z_buf(U8 *)+(y*TEXT_COLS+l)*sizeof(U16),
	    task->win_z_num,w);
}

U0 WindowVisibilityCore(CTask *anchor)
{//Might have to call if doing graphics outside winmgr callback routines.
//Call it if, for example, when a pop-up window closes and you need to refresh
  //before graphics.
  I64 i,z=1;
  U16 *ptr;
  CTask *task,*task1;
  if (gr.win_z_buf) {
    MemSet(gr.win_z_buf,0,TEXT_ROWS*TEXT_COLS*sizeof(U16));
    task1=task=anchor;
    do {
      if (!TaskValidate(task)) break;
      if (Bt(&task->display_flags,DISPLAYf_SHOW)) {
	task->win_z_num=z++;
	WinZBufFill(task);
      }
      task=task->next_task;
    } while (task!=task1 && z<0x10000);

    MemSet(gr.win_uncovered_bitmap,0,(gr.highest_uncovered+7)>>3+1);
    gr.highest_uncovered=z-1;
    for (ptr=gr.win_z_buf,i=TEXT_ROWS*TEXT_COLS;i;i--)
      Bts(gr.win_uncovered_bitmap,*ptr++);
  }
}
