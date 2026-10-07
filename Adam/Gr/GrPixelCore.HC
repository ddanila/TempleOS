#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original low-level pixel drawing and reading.
public Bool GrPlot0(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y)
{//2D. No clipping or transformation or thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  U8 *dst;
  I32 *db;
  I64 d,dist;
  CColorROPU32 c,color=dc->color,bkcolor=dc->bkcolor;

  if (dc->flags & DCF_LOCATE_NEAREST) {
    dist=DistSqrI64(x,y,dc->cur_x,dc->cur_y);
    if (dist<=dc->nearest_dist)
      dc->nearest_dist=dist;
  }
  if (dc->flags & DCF_RECORD_EXTENTS) {
    if (x<dc->min_x) dc->min_x=x;
    if (x>dc->max_x) dc->max_x=x;
    if (y<dc->min_y) dc->min_y=y;
    if (y>dc->max_y) dc->max_y=y;
  }
  if (dc->flags & DCF_DONT_DRAW)
    return TRUE;
  d=dc->width_internal*y+x;
  if (db=dc->depth_buf) {
    db+=d;
    if (0<=dc->db_z<=*db)
      *db=dc->db_z;
    else
      return TRUE;
  }
  if (color.c1.rop&(ROPBF_DITHER|ROPBF_PROBABILITY_DITHER)) {
    if (color.c1.rop&ROPBF_PROBABILITY_DITHER) {
      if (RandU16<dc->dither_probability_u16) {
	color.c1.rop=color.c0.rop;
	color.c0=color.c1;
      }
    } else {
      if ((x^y)&1) {
	color.c1.rop=color.c0.rop;
	color.c0=color.c1;
      }
    }
  }
  dst=dc->body+d;
  switch [color.c0.rop] {
    case ROPB_EQU:
    case ROPB_MONO:
      *dst=color.c0.color;
      break;
    case ROPB_COLLISION:
      c=*dst;
      if (c!=TRANSPARENT && c!=bkcolor.c0.color)
	dc->collision_cnt++;
      break;
    case ROPB_XOR:
      *dst^=color.c0.color;
      break;
  }
  return TRUE;
}
public I64 GrPeek0(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y)
{//2D. No clipping or transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  return dc->body[dc->width_internal*y+x];
}

