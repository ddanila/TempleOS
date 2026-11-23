public I64 GrPeek(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y)
{//2D. Clipping but no transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
//Returns pix color or -1 if off-scrn or covered.
  CTask *win_task;
  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x+=win_task->pix_left+win_task->scroll_x;
    y+=win_task->pix_top+win_task->scroll_y;
    if (!(win_task->pix_left<=x<=win_task->pix_right)  ||
	  !(win_task->pix_top <=y<=win_task->pix_bottom) ||
	  !(0<=x<dc->width) || !(0<=y<dc->height) ||
	  win_task->next_task!=sys_winmgr_task &&
	  !(dc->flags&DCF_ON_TOP) &&
	  IsPixCovered0(win_task,x,y))
      return -1;
  } else
    if (!(0<=x<dc->width) || !(0<=y<dc->height))
      return -1;
  return GrPeek0(dc,x,y);
}

