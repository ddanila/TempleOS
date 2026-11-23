public Bool GrPlot(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y)
{//2D. Clipping but No transformation or thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I32 *db=dc->depth_buf;
  CTask *win_task;
  CColorROPU32 old_color;
  dc->depth_buf=NULL;
  if (dc->brush) {
    old_color=dc->color;
    if (dc->color.c0.rop!=ROPB_COLLISION)
      dc->color.c0.rop=ROPB_MONO;
    GrBlot(dc,x,y,dc->brush);
    dc->color=old_color;
  } else if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x+=win_task->pix_left+win_task->scroll_x;
    y+=win_task->pix_top+win_task->scroll_y;
    if (win_task->pix_left<=x<=win_task->pix_right &&
	  win_task->pix_top<=y<=win_task->pix_bottom &&
	  0<=x<dc->width && 0<=y<dc->height &&
	  (win_task->next_task==sys_winmgr_task ||
	  dc->flags&DCF_ON_TOP ||
	  !IsPixCovered0(win_task,x,y)))
      GrPlot0(dc,x,y);
  } else
    if (0<=x<dc->width && 0<=y<dc->height)
      GrPlot0(dc,x,y);
  dc->depth_buf=db;
  return TRUE;
}

