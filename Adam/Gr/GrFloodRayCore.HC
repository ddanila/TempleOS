I64 GrRayLenMinus(CDC *dc,I64 x,I64 y)
{
//Returns cnt of pixs changed
  I64 res=0,c,x3,y3,d;
  U8 *dst,*dst2;
  Bool not_color=ToBool(dc->flags&DCF_FILL_NOT_COLOR);
  CTask *win_task;

  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x+=win_task->scroll_x;
    y+=win_task->scroll_y;
  }
  x3=x;
  y3=y;
  if (x3<0 || y3<0)
    goto gr_done;
  if (dc->flags & DCF_SCRN_BITMAP) {
    x3+=win_task->pix_left;
    y3+=win_task->pix_top;
    if (!(0<=x3<=win_task->pix_right) || !(0<=y3<=win_task->pix_bottom) ||
	  !(dc->flags&DCF_ON_TOP) && IsPixCovered0(win_task,x3,y3))
      goto gr_done;
  }
  if (x3>=dc->width || y3>=dc->height)
    goto gr_done;

  d=y3*dc->width_internal;
  dst2=dc->body+d;
  while (TRUE) {
    x3=x;
    if (x3&(FONT_WIDTH-1)==FONT_WIDTH-1) {
      if (dc->flags & DCF_SCRN_BITMAP) {
	if (x3<0) break;
	x3+=win_task->pix_left;
	if (!(0<=x3<=win_task->pix_right) || x3>=dc->width ||
	      !(dc->flags&DCF_ON_TOP) && IsPixCovered0(win_task,x3,y3))
	  break;
      } else
	if (!(0<=x3<dc->width))
	  break;
    } else if (dc->flags & DCF_SCRN_BITMAP)
      x3+=win_task->pix_left;
    dst=dst2+x3;
    c=*dst;
    if (not_color) {
      if (c!=dc->color2) {
	res++;
	x--;
      } else
	break;
    } else {
      if (c==dc->color2) {
	res++;
	x--;
      } else
	break;
    }
  }
  return res;
gr_done:
  return 0;
}

I64 GrRayLen(CDC *dc,I64 *x1,I64 y,I64 z=0,I32 *db=NULL)
{
//Returns cnt of pixs changed
  I64 res=0,d,x=*x1,x2,x3,y3,dist;
  Bool plot,dither,probability_dither,
	not_color=ToBool(dc->flags&DCF_FILL_NOT_COLOR);
  U8 *dst,*dst2;
  CColorROPU32 c,c2,color=dc->color,bkcolor=dc->bkcolor;
  I32 *db2;
  CTask *win_task;

  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x+=win_task->scroll_x;
    y+=win_task->scroll_y;
    z+=win_task->scroll_z;
  }
  x2=x;
  x3=x;
  y3=y;
  if (x3<0 || y3<0)
    goto gr_done;
  if (dc->flags & DCF_SCRN_BITMAP) {
    x3+=win_task->pix_left;
    y3+=win_task->pix_top;
    if (!(0<=x3<=win_task->pix_right) || !(0<=y3<=win_task->pix_bottom) ||
	  !(dc->flags&DCF_ON_TOP) &&  IsPixCovered0(win_task,x3,y3))
      goto gr_done;
  }
  if (x3>=dc->width || y3>=dc->height)
    goto gr_done;

  d=dc->width_internal*y3;
  if (db) db+=d;

  color=dc->color;
  if (color.c1.rop&(ROPBF_DITHER|ROPBF_PROBABILITY_DITHER)) {
    dither=TRUE;
    if (color.c1.rop&ROPBF_PROBABILITY_DITHER) {
      probability_dither=TRUE;
      color.c1.rop=color.c0.rop;
    } else {
      probability_dither=FALSE;
      color.c1.rop=color.c0.rop;
    }
  } else
    dither=FALSE;
  dst2=dc->body+d;
  while (TRUE) {
    x3=x;
    if (!(x3&(FONT_WIDTH-1))) {
      if (dc->flags & DCF_SCRN_BITMAP) {
	if (x3<0) break;
	x3+=win_task->pix_left;
	if (!(0<=x3<=win_task->pix_right) || x3>=dc->width ||
	      !(dc->flags&DCF_ON_TOP) && IsPixCovered0(win_task,x3,y3))
	  break;
      } else {
	if (!(0<=x3<dc->width))
	  break;
      }
    } else if (dc->flags & DCF_SCRN_BITMAP)
      x3+=win_task->pix_left;

    dst=dst2+x3;

    c=*dst;
    if (db) {
      db2=db+x3;
      if (0<=z<=*db2) {
	*db2=z;
	plot=TRUE;
      } else
	plot=FALSE;
    } else
      plot=TRUE;

    if ((not_color && c!=dc->color2 ||
	  !not_color && c==dc->color2) && plot) {
      if (dc->flags & DCF_LOCATE_NEAREST) {
	dist=DistSqrI64(x3,y3,dc->cur_x,dc->cur_y);
	if (dist<=dc->nearest_dist)
	  dc->nearest_dist=dist;
      }
      if (dc->flags & DCF_RECORD_EXTENTS) {
	if (x3<dc->min_x) dc->min_x=x3;
	if (x3>dc->max_x) dc->max_x=x3;
	if (y3<dc->min_y) dc->min_y=y3;
	if (y3>dc->max_y) dc->max_y=y3;
      }
      dst=dst2+x3;

      c=color.c0.color;
      if (dither) {
	if (probability_dither) {
	  if (RandU16<dc->dither_probability_u16)
	    c=color.c1.color;
	} else
	  if ((x3^y3)&1)
	    c=color.c1.color;
      }
      switch [color.c0.rop] {
	case ROPB_EQU:
	case ROPB_MONO:
	  *dst=c;
	  break;
	case ROPB_COLLISION:
	  c2=*dst;
	  if (c2!=TRANSPARENT && c2!=bkcolor.c0.color)
	    dc->collision_cnt++;
	  break;
	case ROPB_XOR:
	  *dst^=c;
	  break;
      }
      res++;
      x++;
    } else
      break;
  }
  if (dc->flags & DCF_SCRN_BITMAP)
    *x1=x-1-win_task->scroll_x;
  else
    *x1=x-1;
  x=x2-1;
  while (TRUE) {
    x3=x;
    if (x3&(FONT_WIDTH-1)==FONT_WIDTH-1) {
      if (dc->flags & DCF_SCRN_BITMAP) {
	if (x3<0) break;
	x3+=win_task->pix_left;
	if (!(0<=x3<=win_task->pix_right) || x3>=dc->width ||
	      !(dc->flags&DCF_ON_TOP) && IsPixCovered0(win_task,x3,y3))
	  break;
      } else
	if (!(0<=x3<dc->width))
	  break;
    } else if (dc->flags & DCF_SCRN_BITMAP)
      x3+=win_task->pix_left;

    dst=dst2+x3;
    c=*dst;
    if (db) {
      db2=db+x3;
      if (0<=z<=*db2) {
	*db2=z;
	plot=TRUE;
      } else
	plot=FALSE;
    } else
      plot=TRUE;

    if ((not_color && c!=dc->color2 ||
	  !not_color && c==dc->color2) && plot) {
      if (dc->flags & DCF_LOCATE_NEAREST) {
	dist=DistSqrI64(x3,y3,dc->cur_x,dc->cur_y);
	if (dist<=dc->nearest_dist)
	  dc->nearest_dist=dist;
      }
      if (dc->flags & DCF_RECORD_EXTENTS) {
	if (x3<dc->min_x) dc->min_x=x3;
	if (x3>dc->max_x) dc->max_x=x3;
	if (y3<dc->min_y) dc->min_y=y3;
	if (y3>dc->max_y) dc->max_y=y3;
      }
      dst=dst2+x3;

      c=color.c0.color;
      if (dither) {
	if (probability_dither) {
	  if (RandU16<dc->dither_probability_u16)
	    c=color.c1.color;
	} else
	  if ((x3^y3)&1)
	    c=color.c1.color;
      }
      switch [color.c0.rop] {
	case ROPB_EQU:
	case ROPB_MONO:
	  *dst=c;
	  break;
	case ROPB_COLLISION:
	  c2=*dst;
	  if (c2!=TRANSPARENT && c2!=bkcolor.c0.color)
	    dc->collision_cnt++;
	  break;
	case ROPB_XOR:
	  *dst^=c;
	  break;
      }
      res++;
      x--;
    } else
      break;
  }
  return res;
gr_done:
  return 0;
}

