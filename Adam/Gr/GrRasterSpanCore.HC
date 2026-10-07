#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original horizontal and vertical raster spans.
public I64 GrHLine(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 x2,I64 y,I64 z1=0,I64 z2=0)
{//3D. No transformation or thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
//Returns cnt of pixs changed
  //Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  I64 dist,dx,dz,z,res=0,i,j,d;
  U8 *dst;
  CColorROPU32 c,c2,color=dc->color,bkcolor=dc->bkcolor,dither_colors;
  I32 *db;
  Bool plot=TRUE,char_clear,dither,probability_dither;
  CTask *win_task;

  if (!dc->depth_buf) {
    if (x2<x1) SwapI64(&x1,&x2);
    return GrRect(dc,x1,y,x2-x1+1,1);
  }

  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x1+=win_task->scroll_x;
    x2+=win_task->scroll_x;
    y +=win_task->scroll_y;
    z1+=win_task->scroll_z;
    z2+=win_task->scroll_z;
  }
  if (dc->flags & DCF_RECORD_EXTENTS) {
    if (x1<dc->min_x) dc->min_x=x1;
    if (x1>dc->max_x) dc->max_x=x1;
    if (x2<dc->min_x) dc->min_x=x2;
    if (x2>dc->max_x) dc->max_x=x2;
    if (y<dc->min_y) dc->min_y=y;
    if (y>dc->max_y) dc->max_y=y;
  }
  if (y<0) goto gr_done;
  if (x2<x1) {
    SwapI64(&x1,&x2);
    SwapI64(&z1,&z2);
  }
  if (x2<0)
    goto gr_done;
  if (x1<0) {
    i=-x1;
    x1=0;
  } else
    i=0;
  j=0;
  if (dc->flags & DCF_SCRN_BITMAP) {
    x1+=win_task->pix_left;
    x2+=win_task->pix_left;
    if (x1>win_task->pix_right)
      goto gr_done;
    if (x2>win_task->pix_right) {
      j=x2-win_task->pix_right;
      x2=win_task->pix_right;
    }
    y+=win_task->pix_top;
    if (!(0<=y<=win_task->pix_bottom) || x2<0)
      goto gr_done;
  }
  if (x1>=dc->width || y>=dc->height)
    goto gr_done;
  dx=x2+j-(x1-i);
  d=dc->width_internal*y+x1;
  if (db=dc->depth_buf) {
    db+=d;
    if (dx)
      dz=(z2-z1)<<32/dx;
    else
      dz=0;
    z=z1<<32;
  }
  if (i)
    z+=i*dz;
  if (x2>=dc->width)
    x2=dc->width-1;

  if (dc->flags & DCF_LOCATE_NEAREST) {
    if (x1<=dc->cur_x<=x2)
      dist=0;
    else if (dc->cur_x<x1)
      dist=SqrI64(x1-dc->cur_x);
    else
      dist=SqrI64(dc->cur_x-x2);
    dist+=SqrI64(y-dc->cur_y);
    if (dist<=dc->nearest_dist)
      dc->nearest_dist=dist;
  }
  if (dc->flags & DCF_DONT_DRAW)
    goto gr_done;

  if (!(dc->flags & DCF_SCRN_BITMAP) ||
	win_task->next_task==sys_winmgr_task ||
	dc->flags&DCF_ON_TOP ||	!IsPixCovered0(win_task,x1,y))
    char_clear=TRUE;
  else
    char_clear=FALSE;
  if (color.c1.rop&(ROPBF_DITHER|ROPBF_PROBABILITY_DITHER)) {
    dither=TRUE;
    if (color.c1.rop&ROPBF_PROBABILITY_DITHER) {
      probability_dither=TRUE;
      color.c1.rop=color.c0.rop;
      dither_colors=color;
      if (RandU16<dc->dither_probability_u16)
	color.c0=dither_colors.c1;
      else
	color.c0=dither_colors.c0;
    } else {
      probability_dither=FALSE;
      color.c1.rop=color.c0.rop;
      if ((x1^y)&1)
	SwapU16(&color.c0,&color.c1);
    }
  } else
    dither=FALSE;
  while (x1<=x2) {
    if (char_clear) {
      if (db) {
	if (0<=z.i32[1]<=*db) {
	  *db=z.i32[1];
	  plot=TRUE;
	} else
	  plot=FALSE;
      }
      if (plot) {
	dst=dc->body+d;
	c=color.c0.color;
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
      }
    }
    if (dither) {
      if (probability_dither) {
	if (RandU16<dc->dither_probability_u16)
	  color.c0=dither_colors.c1;
	else
	  color.c0=dither_colors.c0;
      } else
	SwapU16(&color.c0,&color.c1);
    }
    d++;
    x1++;
    if (db)
      db++;
    z+=dz;
    if (!(x1&(FONT_WIDTH-1)) && x1<=x2) {
      if (!(dc->flags & DCF_SCRN_BITMAP)||
	    win_task->next_task==sys_winmgr_task ||
	    dc->flags&DCF_ON_TOP || !IsPixCovered0(win_task,x1,y))
	char_clear=TRUE;
      else
	char_clear=FALSE;
    }
  }
gr_done:
  return res;
}

public I64 GrVLine(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y1,I64 y2,I64 z1=0,I64 z2=0)
{//3D. No transformation or thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
//Returns cnt of pixs changed
  //Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  I64 dist,dy,dz,z,res=0,i,j,d;
  U8 *dst;
  CColorROPU32 c,c2,color=dc->color,bkcolor=dc->bkcolor,dither_colors;
  I32 *db;
  Bool plot=TRUE,char_clear,dither,probability_dither;
  CTask *win_task;

  if (!dc->depth_buf) {
    if (y2<y1) SwapI64(&y1,&y2);
    return GrRect(dc,x,y1,1,y2-y1+1);
  }

  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x +=win_task->scroll_x;
    y1+=win_task->scroll_y;
    y2+=win_task->scroll_y;
    z1+=win_task->scroll_z;
    z2+=win_task->scroll_z;
  }
  if (dc->flags & DCF_RECORD_EXTENTS) {
    if (x<dc->min_x) dc->min_x=x;
    if (x>dc->max_x) dc->max_x=x;
    if (y1<dc->min_y) dc->min_y=y1;
    if (y1>dc->max_y) dc->max_y=y1;
    if (y2<dc->min_y) dc->min_y=y2;
    if (y2>dc->max_y) dc->max_y=y2;
  }
  if (x<0) goto gr_done;
  if (y2<y1) {
    SwapI64(&y1,&y2);
    SwapI64(&z1,&z2);
  }
  if (y2<0)
    goto gr_done;
  if (y1<0) {
    i=-y1;
    y1=0;
  } else
    i=0;
  j=0;
  if (dc->flags & DCF_SCRN_BITMAP) {
    y1+=win_task->pix_top;
    y2+=win_task->pix_top;
    if (y1>win_task->pix_bottom)
      goto gr_done;
    if (y2>win_task->pix_bottom) {
      j=y2-win_task->pix_bottom;
      y2=win_task->pix_bottom;
    }
    x+=win_task->pix_left;
    if (!(0<=x<=win_task->pix_right) || y2<0)
      goto gr_done;
  }
  if (y1>=dc->height || x>=dc->width)
    goto gr_done;
  dy=y2+j-(y1-i);
  d=dc->width_internal*y1+x;
  if (db=dc->depth_buf) {
    db+=d;
    if (dy)
      dz=(z2-z1)<<32/dy;
    else
      dz=0;
    z=z1<<32;
  }
  if (i)
    z+=i*dz;
  if (y2>=dc->height)
    y2=dc->height-1;

  if (dc->flags & DCF_LOCATE_NEAREST) {
    if (y1<=dc->cur_y<=y2)
      dist=0;
    else if (dc->cur_y<y1)
      dist=SqrI64(y1-dc->cur_y);
    else
      dist=SqrI64(dc->cur_y-y2);
    dist+=SqrI64(x-dc->cur_x);
    if (dist<=dc->nearest_dist)
      dc->nearest_dist=dist;
  }
  if (dc->flags & DCF_DONT_DRAW)
    goto gr_done;

  if (!(dc->flags & DCF_SCRN_BITMAP) ||
	win_task->next_task==sys_winmgr_task ||
	dc->flags&DCF_ON_TOP ||	!IsPixCovered0(win_task,x,y1))
    char_clear=TRUE;
  else
    char_clear=FALSE;
  if (color.c1.rop&(ROPBF_DITHER|ROPBF_PROBABILITY_DITHER)) {
    dither=TRUE;
    if (color.c1.rop&ROPBF_PROBABILITY_DITHER) {
      probability_dither=TRUE;
      color.c1.rop=color.c0.rop;
      dither_colors=color;
      if (RandU16<dc->dither_probability_u16)
	color.c0=dither_colors.c1;
      else
	color.c0=dither_colors.c0;
    } else {
      probability_dither=FALSE;
      color.c1.rop=color.c0.rop;
      if ((x^y1)&1)
	SwapU16(&color.c0,&color.c1);
    }
  } else
    dither=FALSE;
  while (y1<=y2) {
    if (char_clear) {
      if (db) {
	if (0<=z.i32[1]<=*db) {
	  *db=z.i32[1];
	  plot=TRUE;
	} else
	  plot=FALSE;
      }
      if (plot) {
	dst=dc->body+d;
	c=color.c0.color;
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
      }
    }
    if (dither) {
      if (probability_dither) {
	if (RandU16<dc->dither_probability_u16)
	  color.c0=dither_colors.c1;
	else
	  color.c0=dither_colors.c0;
      } else
	SwapU16(&color.c0,&color.c1);
    }
    d+=dc->width_internal;
    y1++;
    if (db)
      db+=dc->width_internal;
    z+=dz;
    if (!(y1&(FONT_HEIGHT-1)) && y1<=y2) {
      if (!(dc->flags & DCF_SCRN_BITMAP)||
	    win_task->next_task==sys_winmgr_task ||
	    dc->flags&DCF_ON_TOP || !IsPixCovered0(win_task,x,y1))
	char_clear=TRUE;
      else
	char_clear=FALSE;
    }
  }
gr_done:
  return res;
}
