#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original point/clamp/line clipping helpers.
public Bool GrClamp(CDC *dc=GRAPHICS_DEFAULT_DC,I64 *left,I64 *top,I64 *right,I64 *bottom,
	I64 width=0,I64 height=0)
{//Returns scrn, not window coordinates.
  GRAPHICS_RESOLVE_DEFAULT_DC
  CTask *win_task;
  *left=0;
  *top=0;
  *right=dc->width-1;
  *bottom=dc->height-1;
  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    if (GR_WIDTH-1<*right)
      *right=GR_WIDTH-1;
    if (GR_HEIGHT-1<*bottom)
      *bottom=GR_HEIGHT-1;
    if (win_task->pix_left>*left)
      *left=win_task->pix_left;
    if (win_task->pix_top>*top)
      *top=win_task->pix_top;
    if (win_task->pix_right<*right)
      *right=win_task->pix_right;
    if (win_task->pix_bottom<*bottom)
      *bottom=win_task->pix_bottom;
  }
  *left-=width;
  *right+=width;
  *top-=height;
  *bottom+=height;
  return *left<=*right && *top<=*bottom;
}

Bool DCClipLine(CDC *dc=GRAPHICS_DEFAULT_DC,I64 *x1,I64 *y1,I64 *x2,I64 *y2,
	I64 width=0,I64 height=0)
{//Also converts window to scrn coordinates
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 left,top,right,bottom;
  CTask *win_task;
  if (GrClamp(dc,&left,&top,&right,&bottom,width,height)) {
    if (dc->flags & DCF_SCRN_BITMAP) {
      win_task=dc->win_task;
      *x1+=win_task->pix_left+win_task->scroll_x;
      *y1+=win_task->pix_top+win_task->scroll_y;
      *x2+=win_task->pix_left+win_task->scroll_x;
      *y2+=win_task->pix_top+win_task->scroll_y;
    }
    return ClipLine(x1,y1,x2,y2,left,top,right,bottom);
  } else
    return FALSE;
}

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

Bool GrPlot1(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y)
{//Clipping but No transformation or thick, called with db_z set
  GRAPHICS_RESOLVE_DEFAULT_DC
  CTask *win_task;
  CColorROPU32 old_color;
  if (dc->brush) {
    old_color=dc->color;
    if (dc->color.c0.rop!=ROPB_COLLISION)
      dc->color.c0.rop=ROPB_MONO;
    if (dc->depth_buf)
      GrBlot3(dc,x,y,dc->db_z,dc->brush);
    else
      GrBlot(dc,x,y,dc->brush);
    dc->color=old_color;
  } else if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x+=win_task->pix_left+win_task->scroll_x;
    y+=win_task->pix_top+win_task->scroll_y;
    if (win_task->pix_left<=x<=win_task->pix_right &&
	  win_task->pix_top <=y<=win_task->pix_bottom &&
	  0<=x<dc->width && 0<=y<dc->height &&
	  (win_task->next_task==sys_winmgr_task ||
	  dc->flags&DCF_ON_TOP ||
	  !IsPixCovered0(win_task,x,y)))
      GrPlot0(dc,x,y);
  } else
    if (0<=x<dc->width && 0<=y<dc->height)
      GrPlot0(dc,x,y);
  return TRUE;
}

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

