#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original circle, ellipse and regular polygon rendering.
public Bool GrEllipse3(CDC *dc=GRAPHICS_DEFAULT_DC,
		I64 cx,I64 cy,I64 cz,
		I64 x_radius,I64 y_radius,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{//3D. Transformation with thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res;
  I64 x,y,z,xx,yy,zz;
  F64 m1,arg1,m2,arg2,s,c;
  if (dc->flags & DCF_TRANSFORMATION) {
    dc->flags&=~DCF_TRANSFORMATION;
    (*dc->transform)(dc,&cx,&cy,&cz);

    c=Cos(rot_angle);
    s=Sin(rot_angle);

    x_radius<<=16;
    y_radius<<=16;

    xx=0;
    yy=0;
    zz=0;
    (*dc->transform)(dc,&xx,&yy,&zz);

    x=x_radius*c;
    y=x_radius*s;
    z=0;
    (*dc->transform)(dc,&x,&y,&z);
    x-=xx;
    y-=yy;
    z-=zz;
    R2P(&m1,&arg1,x,y);

    x=-y_radius*s;
    y=y_radius*c;
    z=0;
    (*dc->transform)(dc,&x,&y,&z);
    x-=xx;
    y-=yy;
    z-=zz;
    R2P(&m2,&arg2,x,y);
    m2*=Abs(Sin(arg2-arg1));

    res=Ellipse(dc,cx,cy,cz,
	  m1/0x10000,m2/0x10000,&GrPlot3,-arg1,step,start_radians,len_radians);
    dc->flags|=DCF_TRANSFORMATION;
  } else
    res=Ellipse(dc,cx,cy,cz,x_radius,y_radius,&GrPlot3,
	  rot_angle,step,start_radians,len_radians);
  return res;
}

public Bool GrCircle3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 cx,I64 cy,I64 cz,I64 radius,
  I64 step=1,F64 start_radians=0,F64 len_radians=2*ã)
{//3D. Transformation with thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  if (dc->flags & DCF_TRANSFORMATION)
    return GrEllipse3(dc,cx,cy,cz,radius,radius,0,step,
	  start_radians,len_radians);
  else
    return Circle(dc,cx,cy,cz,radius,&GrPlot3,step,
	  start_radians,len_radians);
}

public Bool GrRegPoly3(CDC *dc=GRAPHICS_DEFAULT_DC,
		I64 cx,I64 cy,I64 cz,
		I64 x_radius,I64 y_radius,I64 sides,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{//3D. Clipping and transform and thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res;
  I64 x,y,z,xx,yy,zz;
  F64 m1,arg1,m2,arg2,s,c;
  if (dc->flags & DCF_TRANSFORMATION) {
    dc->flags&=~DCF_TRANSFORMATION;
    (*dc->transform)(dc,&cx,&cy,&cz);

    c=Cos(rot_angle);
    s=Sin(rot_angle);

    x_radius<<=16;
    y_radius<<=16;

    xx=0;
    yy=0;
    zz=0;
    (*dc->transform)(dc,&xx,&yy,&zz);

    x=x_radius*c;
    y=x_radius*s;
    z=0;
    (*dc->transform)(dc,&x,&y,&z);
    x-=xx;
    y-=yy;
    z-=zz;
    R2P(&m1,&arg1,x,y);

    x=-y_radius*s;
    y=y_radius*c;
    z=0;
    (*dc->transform)(dc,&x,&y,&z);
    x-=xx;
    y-=yy;
    z-=zz;
    R2P(&m2,&arg2,x,y);
    m2*=Abs(Sin(arg2-arg1));

    res=RegPoly(dc,cx,cy,cz,
	  m1/0x10000,m2/0x10000,sides,&GrPlot3,-arg1,
	  step,start_radians,len_radians);
    dc->flags|=DCF_TRANSFORMATION;
  } else
    res=RegPoly(dc,cx,cy,cz,x_radius,y_radius,sides,&GrPlot3,
	  rot_angle,step,start_radians,len_radians);
  return res;
}

