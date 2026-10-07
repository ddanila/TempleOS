#include "/Adam/Gr/GrDefaultContext.HH"
/*

This is an easier to understand
version of the nonrecursive routine below.
I64 GrFloodFillRay(CDC *dc,I64 x,I64 y,I64 z,I32 *db)
{
  I64 res,j,x1,ray_len,ray_len2;

  if (UnusedStk<0x80)
    Panic("Stk Overflow",Fs);

  res=ray_len=GrRayLen(dc,&x,y,z,db);
  y--;
  j=ray_len;
  x1=x;
  while (j>0) {
    if (ray_len2=GrRayLenMinus(dc,x1,y))
      res+=GrFloodFillRay(dc,x1,y,z,db);
    j-=ray_len2+1;
    x1-=ray_len2+1;
  }
  y+=2;
  j=ray_len;
  x1=x;
  while (j>0) {
    if (ray_len2=GrRayLenMinus(dc,x1,y))
      res+=GrFloodFillRay(dc,x1,y,z,db);
    j-=ray_len2+1;
    x1-=ray_len2+1;
  }
  return res;
}
*/

class CFFRay
{
  I64 state,x,y,j,x1,ray_len,ray_len2;
};

I64 GrFloodFillRay(CDC *dc,I64 x,I64 y,I64 z,I32 *db)
{//See the above commented-out routine for an easier to understand version.
//Returns cnt of pixs changed
  I64 res=0;
//We don't dynamically calculate the size to avoid
  //fragmentation of memory.
  CFFRay *f_dc=MAlloc(sizeof(CFFRay)*0x80000),*f=f_dc;
  f->x=x;
  f->y=y;
  f->state=0;
  do {
    switch [f->state] {
      case 0:
	f->state++;
	res+=f->ray_len=GrRayLen(dc,&f->x,f->y,z,db);
	f->y--;
	f->j=f->ray_len;
	f->x1=f->x;
	break;
      case 1:
	if (f->j>0) {
	  f->state++;
	  if (f->ray_len2=GrRayLenMinus(dc,f->x1,f->y)) {
	    f[1].x=f->x1;
	    f[1].y=f->y;
	    f[1].state=0;
	    f++;
	  }
	} else
	  f->state+=2;
	break;
      case 2:
	f->state--;
	f->j-=f->ray_len2+1;
	f->x1-=f->ray_len2+1;
	break;
      case 3:
	f->state++;
	f->y+=2;
	f->j=f->ray_len;
	f->x1=f->x;
	break;
      case 4:
	if (f->j>0) {
	  f->state++;
	  if (f->ray_len2=GrRayLenMinus(dc,f->x1,f->y)) {
	    f[1].x=f->x1;
	    f[1].y=f->y;
	    f[1].state=0;
	    f++;
	  }
	} else
	  f->state+=2;
	break;
      case 5:
	f->state--;
	f->j-=f->ray_len2+1;
	f->x1-=f->ray_len2+1;
	break;
      case 6:
	f--;
	break;
    }
  } while (f>=f_dc);
  Free(f_dc);
  return res;
}

public I64 GrFloodFill(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,
	Bool not_color=FALSE,I64 z=0,I32 *db=NULL)
{//2D. Ignore z and db.
  GRAPHICS_RESOLVE_DEFAULT_DC
//not_color=TRUE means fill up to everything which is not the current color.
  //not_color=FALSE means fill all parts equ to the color under the point.
  //Returns cnt of pixs changed
  I64 res=0,j,old_flags=dc->flags;
  CColorROPU32 old_color2=dc->color2;
  CDC *old_brush;
  if (dc->flags & DCF_DONT_DRAW) //TODO
    return 0;
  old_brush=dc->brush;
  dc->brush=NULL;
  if ((j=GrPeek(dc,x,y))>=0) {
    if (not_color) {
      dc->color2=dc->color.c0.color;
      dc->flags|=DCF_FILL_NOT_COLOR;
    } else {
      dc->color2=j;
      if (dc->color.c1.rop&ROPBF_DITHER) {
	if (dc->color2.c0.color==dc->color.c0.color &&
	      dc->color.c0.color==dc->color.c1.color)
	  goto ff_done;
      } else if (dc->color2.c0.color==dc->color.c0.color)
	goto ff_done;
      dc->flags&=~DCF_FILL_NOT_COLOR;
    }
    if (not_color && j!=dc->color2 ||
	  !not_color)
      res=GrFloodFillRay(dc,x,y,z,db);
  }
ff_done:
  dc->brush=old_brush;
  dc->flags=old_flags;
  dc->color2=old_color2;
  return res;
}

