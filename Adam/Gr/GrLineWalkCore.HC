public Bool Line(U8 *aux_data,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),I64 step=1,I64 start=0)
{//Step through line segment calling callback.
//Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  I64 i,j,d,dx=x2-x1,dy=y2-y1,dz=z2-z1,_x,_y,_z,
	adx=AbsI64(dx),ady=AbsI64(dy),adz=AbsI64(dz);
  Bool first=TRUE;
  if (adx>=ady) {
    if (adx>=adz) {
      if (d=adx) {
	if (dx>=0)
	  dx=0x100000000;
	else
	  dx=-0x100000000;
	dy=dy<<32/d;
	dz=dz<<32/d;
      }
    } else {
      if (d=adz) {
	dx=dx<<32/d;
	dy=dy<<32/d;
	if (dz>=0)
	  dz=0x100000000;
	else
	  dz=-0x100000000;
      }
    }
  } else {
    if (ady>=adz) {
      if (d=ady) {
	dx=dx<<32/d;
	if (dy>=0)
	  dy=0x100000000;
	else
	  dy=-0x100000000;
	dz=dz<<32/d;
      }
    } else {
      if (d=adz) {
	dx=dx<<32/d;
	dy=dy<<32/d;
	if (dz>=0)
	  dz=0x100000000;
	else
	  dz=-0x100000000;
      }
    }
  }
  x1<<=32; y1<<=32; z1<<=32;
  for (j=0;j<start;j++) {
    x1+=dx; y1+=dy; z1+=dz;
  }
  if (step!=1 && step!=0) {
    dx*=step;
    dy*=step;
    dz*=step;
    d/=step;
  }
  for (i=start;i<=d;i++) {
    if ((_x!=x1.i32[1] || _y!=y1.i32[1] || _z!=z1.i32[1] || first) &&
	  !(*fp_plot)(aux_data,x1.i32[1],y1.i32[1],z1.i32[1]))
      return FALSE;
    first=FALSE;
    _x=x1.i32[1]; _y=y1.i32[1]; _z=z1.i32[1];
    x1+=dx; y1+=dy; z1+=dz;
  }
  if (step==1 && (_x!=x2||_y!=y2||_z!=z2) && !(*fp_plot)(aux_data,x2,y2,z2))
    return FALSE;
  return TRUE;
}

