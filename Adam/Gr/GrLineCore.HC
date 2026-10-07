#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original line drawing helpers and branches.
Bool GrLinePlot0(CDC *dc,I64 x,I64 y,I64 z)
{//This is a callback.
  CTask *win_task=dc->win_task;
  if (!(dc->flags & DCF_SCRN_BITMAP) ||
	win_task->next_task==sys_winmgr_task ||
	dc->flags&DCF_ON_TOP ||
	!IsPixCovered0(win_task,x,y)) {
    dc->db_z=z;
    GrPlot0(dc,x,y);
  }
  return TRUE;
}

Bool GrLinePlot(CDC *dc,I64 x,I64 y,I64 z)
{//This is a callback.
  dc->db_z=z;
  GrPlot1(dc,x,y);
  return TRUE;
}

public Bool GrLine(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 x2,I64 y2,
	I64 step=1,I64 start=0)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res=FALSE;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  if (step==1 && !start && !dc->brush && !dc->depth_buf) {
    if (DCClipLine(dc,&x1,&y1,&x2,&y2))
      res=Line(dc,x1,y1,0,x2,y2,0,&GrLinePlot0,step,start);
  } else
    res=Line(dc,x1,y1,0,x2,y2,0,&GrLinePlot,step,start);
  dc->depth_buf=db;
  return res;
}

