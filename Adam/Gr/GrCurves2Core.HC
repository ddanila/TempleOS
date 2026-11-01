#include "/Adam/Gr/GrDefaultContext.HH"
public Bool GrCircle(CDC *dc=GRAPHICS_DEFAULT_DC,I64 cx,I64 cy,I64 radius,
  I64 step=1,F64 start_radians=0,F64 len_radians=2*ã)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  res=Circle(dc,cx,cy,0,radius,&GrLinePlot,step,start_radians,len_radians);
  dc->depth_buf=db;
  return res;
}

public Bool GrEllipse(CDC *dc=GRAPHICS_DEFAULT_DC,
		I64 cx,I64 cy,
		I64 x_radius,I64 y_radius,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  res=Ellipse(dc,cx,cy,0,x_radius,y_radius,&GrLinePlot,
	rot_angle,step,start_radians,len_radians);
  dc->depth_buf=db;
  return res;
}

public Bool GrRegPoly(CDC *dc=GRAPHICS_DEFAULT_DC,
		I64 cx,I64 cy,
		I64 x_radius,I64 y_radius,I64 sides,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{//2D. Clipping but no transform or thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  res=RegPoly(dc,cx,cy,0,x_radius,y_radius,sides,
	&GrLinePlot,rot_angle,step,start_radians,len_radians);
  dc->depth_buf=db;
  return res;
}
