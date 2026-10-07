#include "/Adam/Gr/GrDefaultContext.HH"
public I64 GrFloodFill3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 z1,Bool not_color=FALSE)
{//3D. Transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
//not_color=TRUE means fill up to everything which is not the current color.
  //not_color=FALSE means fill all parts equ to the color under the point.
  //Returns cnt of pixs changed
  I64 res,old_flags=dc->flags,
	_x,_y,_z;
  if (dc->flags & DCF_TRANSFORMATION) {
    (*dc->transform)(dc,&x1,&y1,&z1);
    dc->flags&=~DCF_TRANSFORMATION;
  }
  if (dc->flags & DCF_SYMMETRY) {
    _x=x1; _y=y1; _z=z1;
    DCReflect(dc,&_x,&_y,&_z);
    dc->flags&=~DCF_SYMMETRY;
    res=GrFloodFill(dc,_x,_y,not_color,_z,dc->depth_buf);
    if (dc->flags&DCF_JUST_MIRROR)
      goto gr_done;
  }
  res=GrFloodFill(dc,x1,y1,not_color,z1,dc->depth_buf);
gr_done:
  dc->flags=old_flags;
  return res;
}

