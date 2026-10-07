#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original filled-circle and all semicircle branches.
I64 GrFillSemiCircle(CDC *dc=GRAPHICS_DEFAULT_DC,I64 cx,I64 cy,I64 z=0,I64 diameter,I64 n)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 res=0,i,k,r=diameter>>1,rr;
  if (diameter>=1)
    switch (n) {
      case 0:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=0;i<r;i++)
	    res+=GrHLine(dc,gr.circle_lo[diameter][i]+cx,
		  gr.circle_hi[diameter][i]+cx,cy+i-r,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=0;i<r;i++)
	    res+=GrHLine(dc,-Sqrt(rr-SqrI64(r-i))+cx,
		  Sqrt(rr-SqrI64(r-i))+cx,cy+i-r,z,z);
	}
	break;
      case 1:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=r+1;i<diameter;i++)
	    res+=GrHLine(dc,gr.circle_lo[diameter][i]+cx,
		  gr.circle_hi[diameter][i]+cx,cy+i-r,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=r+1;i<k;i++)
	    res+=GrHLine(dc,-Sqrt(rr-SqrI64(i-r))+cx,
		  Sqrt(rr-SqrI64(i-r))+cx,cy+i-r,z,z);
	}
	break;
      case 2:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=0;i<r;i++)
	    res+=GrVLine(dc,cx+i-r,gr.circle_lo[diameter][i]+cy,
		  gr.circle_hi[diameter][i]+cy,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=0;i<r;i++)
	    res+=GrVLine(dc,cx+i-r,-Sqrt(rr-SqrI64(r-i))+cy,
		  Sqrt(rr-SqrI64(r-i))+cy,z,z);
	}
	break;
      case 3:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=r+1;i<diameter;i++)
	    res+=GrVLine(dc,cx+i-r,gr.circle_lo[diameter][i]+cy,
		  gr.circle_hi[diameter][i]+cy,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=r+1;i<k;i++)
	    res+=GrVLine(dc,cx+i-r,-Sqrt(rr-SqrI64(i-r))+cy,
		  Sqrt(rr-SqrI64(i-r))+cy,z,z);
	}
	break;
      case 4:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=0;i<r;i++)
	    res+=GrHLine(dc,gr.circle_lo[diameter][i]+cx,
		  gr.circle_hi[diameter][i]+cx,cy+i-r,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=0;i<r;i++)
	    res+=GrHLine(dc,-Sqrt(rr-SqrI64(r-i))+cx,
		  Sqrt(rr-SqrI64(r-i))+cx,cy+i-r,z,z);
	}
	break;
      case 5:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=r+1;i<diameter;i++)
	    res+=GrHLine(dc,gr.circle_lo[diameter][i]+cx,
		  gr.circle_hi[diameter][i]+cx,cy+i-r,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=r+1;i<k;i++)
	    res+=GrHLine(dc,-Sqrt(rr-SqrI64(i-r))+cx,
		  Sqrt(rr-SqrI64(i-r))+cx,cy+i-r,z,z);
	}
	break;
      case 6:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=0;i<r;i++)
	    res+=GrVLine(dc,cx+i-r,gr.circle_lo[diameter][i]+cy,
		  gr.circle_hi[diameter][i]+cy,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=0;i<r;i++)
	    res+=GrVLine(dc,cx+i-r,-Sqrt(rr-SqrI64(r-i))+cy,
		  Sqrt(rr-SqrI64(r-i))+cy,z,z);
	}
	break;
      case 7:
	if (diameter<GR_PEN_BRUSHES_NUM)
	  for (i=r+1;i<diameter;i++)
	    res+=GrVLine(dc,cx+i-r,gr.circle_lo[diameter][i]+cy,
		  gr.circle_hi[diameter][i]+cy,z,z);
	else {
	  k=diameter+1;
	  rr=SqrI64((k+1)>>1);
	  for (i=r+1;i<k;i++)
	    res+=GrVLine(dc,cx+i-r,-Sqrt(rr-SqrI64(i-r))+cy,
		  Sqrt(rr-SqrI64(i-r))+cy,z,z);
	}
	break;
    }
  return res;
}

public I64 GrFillCircle(CDC *dc=GRAPHICS_DEFAULT_DC,I64 cx,I64 cy,I64 z=0,I64 diameter)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 res=0,i,k,r=diameter>>1,rr;
  if (diameter>=1) {
    if (diameter<GR_PEN_BRUSHES_NUM)
      for (i=0;i<diameter;i++)
	res+=GrHLine(dc,gr.circle_lo[diameter][i]+cx,
	      gr.circle_hi[diameter][i]+cx,cy+i-r,z,z);
    else {
      k=diameter+1;
      rr=SqrI64((k+1)>>1);
      for (i=0;i<=r;i++)
	res+=GrHLine(dc,-Sqrt(rr-SqrI64(r-i))+cx,
	      Sqrt(rr-SqrI64(r-i))+cx,cy+i-r,z,z);
      for (;i<k;i++)
	res+=GrHLine(dc,-Sqrt(rr-SqrI64(i-r))+cx,
	      Sqrt(rr-SqrI64(i-r))+cx,cy+i-r,z,z);
    }
  }
  return res;
}

