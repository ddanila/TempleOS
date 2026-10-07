#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original 3D arrow rendering.
public Bool GrArrow3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 z1,
	I64 x2,I64 y2,I64 z2,F64 w=2.75,I64 step=1,I64 start=0)
{//3D. Transformation with thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 _x1,_y1,_z1,_x2,_y2,_z2,dx,dy;
  F64 d;
  Bool res=FALSE,was_transform=FALSE,was_symmetry=FALSE;
  if (dc->flags & DCF_TRANSFORMATION) {
    (*dc->transform)(dc,&x1,&y1,&z1);
    (*dc->transform)(dc,&x2,&y2,&z2);
    dc->flags&=~DCF_TRANSFORMATION;
    was_transform=TRUE;
  }
  if (dc->flags & DCF_SYMMETRY) {
    _x1=x1; _y1=y1; _z1=z1;
    DCReflect(dc,&_x1,&_y1,&_z1);
    _x2=x2; _y2=y2; _z2=z2;
    DCReflect(dc,&_x2,&_y2,&_z2);
    dc->flags&=~DCF_SYMMETRY;
    res=Line(dc,_x1,_y1,_z1,_x2,_y2,_z2,&GrPlot3,step,start);
    dx=_x2-_x1; dy=_y2-_y1;
    if (d=Sqrt(dx*dx+dy*dy)) {
      d=w*dc->thick/d;
      res|=Line(dc,_x2-dx*d+dy*d+0.5,_y2-dy*d-dx*d+0.5,_z2,
	    _x2,_y2,_z2,&GrPlot3,step);
      res|=Line(dc,_x2-dx*d-dy*d+0.5,_y2-dy*d+dx*d+0.5,_z2,
	    _x2,_y2,_z2,&GrPlot3,step);
    }
    was_symmetry=TRUE;
    if (dc->flags&DCF_JUST_MIRROR)
      goto gr_done;
  }
  res|=Line(dc,x1,y1,z1,x2,y2,z2,&GrPlot3,step,start);
  dx=x2-x1; dy=y2-y1;
  if (d=Sqrt(dx*dx+dy*dy)) {
    d=w*dc->thick/d;
    res|=Line(dc,x2-dx*d+dy*d+0.5,y2-dy*d-dx*d+0.5,z2,
	  x2,y2,z2,&GrPlot3,step);
    res|=Line(dc,x2-dx*d-dy*d+0.5,y2-dy*d+dx*d+0.5,z2,
	  x2,y2,z2,&GrPlot3,step);
  }
gr_done:
  if (was_transform)
    dc->flags|=DCF_TRANSFORMATION;
  if (was_symmetry)
    dc->flags|=DCF_SYMMETRY;
  return res;
}

