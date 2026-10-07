#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original thin and thick 3D point rendering.
public Bool GrPlot3B(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z)
{//3D. Clipping and transformation but no thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 _x,_y,_z;
  Bool was_transform=FALSE,was_symmetry=FALSE;
  if (dc->flags & DCF_TRANSFORMATION) {
    (*dc->transform)(dc,&x,&y,&z);
    dc->flags&=~DCF_TRANSFORMATION;
    was_transform=TRUE;
  }
  if (dc->flags & DCF_SYMMETRY) {
    _x=x; _y=y; _z=z;
    DCReflect(dc,&_x,&_y,&_z);
    dc->flags&=~DCF_SYMMETRY;
    dc->db_z=_z;
    GrPlot1(dc,_x,_y);
    was_symmetry=TRUE;
    if (dc->flags&DCF_JUST_MIRROR)
      goto gr_done;
  }
  dc->db_z=z;
  GrPlot1(dc,x,y);
gr_done:
  if (was_transform)
    dc->flags|=DCF_TRANSFORMATION;
  if (was_symmetry)
    dc->flags|=DCF_SYMMETRY;
  return TRUE;
}

public Bool GrPlot3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z)
{//3D. Clipping and transformation and thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 _x,_y,_z,w,dist;
  CColorROPU32 old_color=dc->color;
  Bool record,was_transform=FALSE,was_symmetry=FALSE;
  CTask *win_task;
  if (dc->flags & DCF_TRANSFORMATION) {
    (*dc->transform)(dc,&x,&y,&z);
    dc->flags&=~DCF_TRANSFORMATION;
    was_transform=TRUE;
  }
  if (dc->flags & DCF_SYMMETRY) {
    _x=x; _y=y; _z=z;
    DCReflect(dc,&_x,&_y,&_z);
    dc->flags&=~DCF_SYMMETRY;
    GrPlot3(dc,_x,_y,_z);
    was_symmetry=TRUE;
    if (dc->flags&DCF_JUST_MIRROR)
      goto gr_done;
  }
  w=dc->thick>>1;
  dc->db_z=z;
  if (dc->brush || w<=0)
    GrPlot1(dc,x,y);
  else if (dc->thick<GR_PEN_BRUSHES_NUM) {
    if (dc->color.c0.rop!=ROPB_COLLISION)
      dc->color.c0.rop=ROPB_MONO;
    if (dc->depth_buf) {
      if (dc->color.c1.rop&ROPBF_DITHER) {
	dc->color.c1.rop=dc->color.c0.rop;
	if (((x-w)^(y-w))&1) {
	  record=GrBlot3(dc,x-w,y-w,z,gr.odd_pen_brushes[dc->thick]);
	  dc->color.c0=dc->color.c1;
	  record=GrBlot3(dc,x-w,y-w,z,gr.even_pen_brushes[dc->thick]);
	} else {
	  record=GrBlot3(dc,x-w,y-w,z,gr.even_pen_brushes[dc->thick]);
	  dc->color.c0=dc->color.c1;
	  record=GrBlot3(dc,x-w,y-w,z,gr.odd_pen_brushes[dc->thick]);
	}
      } else {
	if (dc->color.c0.rop==ROPB_COLLISION) {
	  if (dc->color.c0.color!=dc->bkcolor.c0.color &&
		dc->color.c0.color!=TRANSPARENT)
	    record=GrBlot3(dc,x-w,y-w,z,
		  gr.collision_pen_brushes[dc->thick]);
	  else
	    record=FALSE;
	} else
	  record=GrBlot3(dc,x-w,y-w,z,gr.pen_brushes[dc->thick]);
      }
    } else {
      if (dc->color.c1.rop&ROPBF_DITHER) {
	dc->color.c1.rop=dc->color.c0.rop;
	if (((x-w)^(y-w))&1) {
	  record=GrBlot(dc,x-w,y-w,gr.odd_pen_brushes[dc->thick]);
	  dc->color.c0=dc->color.c1;
	  record=GrBlot(dc,x-w,y-w,gr.even_pen_brushes[dc->thick]);
	} else {
	  record=GrBlot(dc,x-w,y-w,gr.even_pen_brushes[dc->thick]);
	  dc->color.c0=dc->color.c1;
	  record=GrBlot(dc,x-w,y-w,gr.odd_pen_brushes[dc->thick]);
	}
      } else {
	if (dc->color.c0.rop==ROPB_COLLISION) {
	  if (dc->color.c0.color!=dc->bkcolor.c0.color &&
		dc->color.c0.color!=TRANSPARENT)
	    record=GrBlot(dc,x-w,y-w,gr.collision_pen_brushes[dc->thick]);
	  else
	    record=FALSE;
	} else
	  record=GrBlot(dc,x-w,y-w,gr.pen_brushes[dc->thick]);
      }
    }
    if (record) {
      if (dc->flags & DCF_SCRN_BITMAP) {
	win_task=dc->win_task;
	x+=win_task->pix_left+win_task->scroll_x;
	y+=win_task->pix_top+win_task->scroll_y;
      }
      if (dc->flags & DCF_LOCATE_NEAREST) {
	dist=DistSqrI64(x,y,dc->cur_x,dc->cur_y);
	if (dist<=dc->nearest_dist)
	  dc->nearest_dist=dist;
      }
      if (dc->flags & DCF_RECORD_EXTENTS) {
	if (x-w<dc->min_x) dc->min_x=x-w;
	if (y-w<dc->min_y) dc->min_y=y-w;
	if (dc->thick & 1) {
	  if (x+w>dc->max_x) dc->max_x=x+w;
	  if (y+w>dc->max_y) dc->max_y=y+w;
	} else {
	  if (x+w-1>dc->max_x) dc->max_x=x+w-1;
	  if (y+w-1>dc->max_y) dc->max_y=y+w-1;
	}
      }
    }
  } else
    GrFillCircle(dc,x,y,dc->db_z,dc->thick);
gr_done:
  dc->color=old_color;
  if (was_transform)
    dc->flags|=DCF_TRANSFORMATION;
  if (was_symmetry)
    dc->flags|=DCF_SYMMETRY;
  return TRUE;
}

