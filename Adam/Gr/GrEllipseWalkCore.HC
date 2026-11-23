#define GR_SCALE1_BITS	24
#define GR_SCALE2_BITS	8
public Bool Circle(U8 *aux_data,I64 cx,I64 cy,I64 cz,I64 radius,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),
	I64 step=1,F64 start_radians=0,F64 len_radians=2*ã)
{//Step through circle arc calling callback.
  I64 i,j,len=Ceil(len_radians*radius),
	x,y,x1,y1,s1,s2,c;
  F64 t;
  if (radius<=0||!step) return TRUE;
  t=1.0/radius;
  c=1<<GR_SCALE1_BITS*Cos(t);
  if (step<0) {
    step=-step;
    s2=1<<GR_SCALE1_BITS*Sin(t);
    s1=-s2;
  } else {
    s1=1<<GR_SCALE1_BITS*Sin(t);
    s2=-s1;
  }
  if (start_radians) {
    x=radius*Cos(start_radians);
    y=-radius*Sin(start_radians);
  } else {
    x=radius;
    y=0;
  }
  x<<=GR_SCALE2_BITS;
  y<<=GR_SCALE2_BITS;
  for (i=0;i<=len;i+=step) {
    if (!(*fp_plot)(aux_data,cx+x>>GR_SCALE2_BITS,cy+y>>GR_SCALE2_BITS,cz))
      return FALSE;
    for (j=0;j<step;j++) {
      x1=(c*x+s1*y)>>GR_SCALE1_BITS;
      y1=(s2*x+c*y)>>GR_SCALE1_BITS;
      x=x1; y=y1;
    }
  }
  return TRUE;
}

public Bool Ellipse(U8 *aux_data,I64 cx,I64 cy,I64 cz,
	I64 x_radius,I64 y_radius,Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),
	F64 rot_angle=0,I64 step=1,F64 start_radians=0,F64 len_radians=2*ã)
{//Step through ellipse arc calling callback.
  I64 i,j,len,
	x,y,_x,_y,x1,y1,x2,y2, s1,s2,c, s12,s22,c2;
  F64 t;
  Bool first=TRUE;
  if (x_radius<=0 || y_radius<=0 || !step)
    return TRUE;
  if (x_radius>=y_radius) {
    t=1.0/x_radius;
    len=Ceil(len_radians*x_radius);
  } else {
    t=1.0/y_radius;
    len=Ceil(len_radians*y_radius);
  }

  c=1<<GR_SCALE1_BITS*Cos(t);
  if (step<0) {
    step=-step;
    s2=1<<GR_SCALE1_BITS*Sin(t);
    s1=-s2;
  } else {
    s1=1<<GR_SCALE1_BITS*Sin(t);
    s2=-s1;
  }

  c2=1<<GR_SCALE1_BITS*Cos(rot_angle);
  s12=1<<GR_SCALE1_BITS*Sin(rot_angle);
  s22=-s12;

  if (start_radians) {
    x=x_radius*Cos(start_radians);
    y=-x_radius*Sin(start_radians);
  } else {
    x=x_radius;
    y=0;
  }
  x<<=GR_SCALE2_BITS;
  y<<=GR_SCALE2_BITS;
  x2=x;
  y2=y;

  y1=y2*y_radius/x_radius;
  x=(c2*x2+s12*y1)>>GR_SCALE1_BITS;
  y=(s22*x2+c2*y1)>>GR_SCALE1_BITS;

  for (i=0;i<=len;i+=step) {
    if ((x>>GR_SCALE2_BITS!=_x || y>>GR_SCALE2_BITS!=_y || first) &&
	  !(*fp_plot)(aux_data,cx+x>>GR_SCALE2_BITS,cy+y>>GR_SCALE2_BITS,cz))
      return FALSE;

    _x=x>>GR_SCALE2_BITS; _y=y>>GR_SCALE2_BITS; first=FALSE;
    for (j=0;j<step;j++) {
      x1=(c*x2+s1*y2)>>GR_SCALE1_BITS;
      y1=(s2*x2+c*y2)>>GR_SCALE1_BITS;
      x2=x1;
      y2=y1;
      y1=y1*y_radius/x_radius;
      x=(c2*x1+s12*y1)>>GR_SCALE1_BITS;
      y=(s22*x1+c2*y1)>>GR_SCALE1_BITS;
    }
  }
  return TRUE;
}

