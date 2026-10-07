#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original line drawing helpers and branches.
I64 GrLineFat3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	I64 width,I64 start=0)
{//Step through line segment calling callback.
  GRAPHICS_RESOLVE_DEFAULT_DC
//Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  I64 res=0,i,j,d,dx=x2-x1,dy=y2-y1,dz=z2-z1,_x,_y,_z,d_lo,d_hi,
	adx=AbsI64(dx),ady=AbsI64(dy),adz=AbsI64(dz);
  if (width>0) {
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
      x1<<=32; y1<<=32; z1<<=32;
      for (j=0;j<start;j++) {
	x1+=dx; y1+=dy; z1+=dz;
      }
      if (start>=d)
	res+=GrFillCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width);
      else {
	if (width==1)
	  for (i=start;i<=d;i++) {
	    dc->db_z=z1.i32[1];
	    res+=GrPlot1(dc,x1.i32[1],y1.i32[1]);
	    _x=x1.i32[1]; _y=y1.i32[1]; _z=z1.i32[1];
	    x1+=dx; y1+=dy; z1+=dz;
	  }
	else {
	  i=width*Sqrt(SqrI64(adx)+SqrI64(ady))/adx;
	  d_lo=i>>1; d_hi=(i-1)>>1;

	  if (dx>=0)
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,2);
	  else
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,7);
	  for (i=start;i<=d;i++) {
	    res+=GrVLine(dc,x1.i32[1],y1.i32[1]-d_lo,y1.i32[1]+d_hi,
		  z1.i32[1],z1.i32[1]);
	    _x=x1.i32[1]; _y=y1.i32[1]; _z=z1.i32[1];
	    x1+=dx; y1+=dy; z1+=dz;
	  }
	  x1-=dx; y1-=dy; z1-=dz;
	  if (dx>=0)
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,3);
	  else
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,6);
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
      x1<<=32; y1<<=32; z1<<=32;
      for (j=0;j<start;j++) {
	x1+=dx; y1+=dy; z1+=dz;
      }
      if (start>=d)
	res+=GrFillCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width);
      else {
	if (width==1)
	  for (i=start;i<=d;i++) {
	    dc->db_z=z1.i32[1];
	    res+=GrPlot1(dc,x1.i32[1],y1.i32[1]);
	    _x=x1.i32[1]; _y=y1.i32[1]; _z=z1.i32[1];
	    x1+=dx; y1+=dy; z1+=dz;
	  }
	else {
	  i=width*Sqrt(SqrI64(ady)+SqrI64(adx))/ady;
	  d_lo=i>>1; d_hi=(i-1)>>1;

	  if (dy>=0)
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,0);
	  else
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,5);
	  for (i=start;i<=d;i++) {
	    res+=GrHLine(dc,x1.i32[1]-d_lo,x1.i32[1]+d_hi,y1.i32[1],
		  z1.i32[1],z1.i32[1]);
	    _x=x1.i32[1]; _y=y1.i32[1]; _z=z1.i32[1];
	    x1+=dx; y1+=dy; z1+=dz;
	  }
	  x1-=dx; y1-=dy; z1-=dz;
	  if (dy>=0)
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,1);
	  else
	    res+=GrFillSemiCircle(dc,x1.i32[1],y1.i32[1],z1.i32[1],width,4);
	}
      }
    }
  }
  return res;
}

public Bool GrLine3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	I64 step=1,I64 start=0)
{//3D. Transformation with thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 _x1,_y1,_z1,_x2,_y2,_z2;
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
    if (step==1 && !dc->brush) {
      if (!start && dc->thick<2 && !dc->depth_buf) {//TODO: clip z depbuf
	if (DCClipLine(dc,&_x1,&_y1,&_x2,&_y2))
	  res=Line(dc,_x1,_y1,0,_x2,_y2,0,&GrLinePlot0,step,start);
      } else {
	if (GrLineFat3(dc,_x1,_y1,_z1,_x2,_y2,_z2,dc->thick,start))
	  res=TRUE;
      }
    } else
      res=Line(dc,_x1,_y1,_z1,_x2,_y2,_z2,&GrPlot3,step,start);
    was_symmetry=TRUE;
    if (dc->flags&DCF_JUST_MIRROR)
      goto gr_done;
  }
  if (step==1 && !dc->brush) {
    if (!start && dc->thick<2 && !dc->depth_buf) {//TODO: clip z depbuf
      if (DCClipLine(dc,&x1,&y1,&x2,&y2))
	res|=Line(dc,x1,y1,0,x2,y2,0,&GrLinePlot0,step,start);
    } else {
      if (GrLineFat3(dc,x1,y1,z1,x2,y2,z2,dc->thick,start))
	res=TRUE;
    }
  } else
    res|=Line(dc,x1,y1,z1,x2,y2,z2,&GrPlot3,step,start);
gr_done:
  if (was_transform)
    dc->flags|=DCF_TRANSFORMATION;
  if (was_symmetry)
    dc->flags|=DCF_SYMMETRY;
  return res;
}

