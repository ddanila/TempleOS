#include "/Adam/Gr/GrEllipse3Core.HC"
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

