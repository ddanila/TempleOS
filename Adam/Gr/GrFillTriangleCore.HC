#include "/Adam/Gr/GrDefaultContext.HH"
//Swap typed pointers using their actual width on either target.
U0 GrTriangleSwapPoint(CD3I32 **a,CD3I32 **b)
{
  CD3I32 *tmp=*a;
  *a=*b; *b=tmp;
}

I64 GrTriangleScan(CDC *dc,Bool vertical,I64 count,I64 step,
  I64 *position,I64 *edge1,I64 *edge2,I64 *depth1,I64 *depth2,
  I64 edge_step1,I64 edge_step2,I64 depth_step1,I64 depth_step2,I64 limit)
{//Clip only the scan cases that previously tested their position per span.
  I64 result=0,at=*position,a=*edge1,b=*edge2,z1=*depth1,z2=*depth2;
  while (count-->0) {
    if (at<limit) {
      if (vertical)
	result+=GrVLine(dc,at,a.i32[1],b.i32[1],z1.i32[1],z2.i32[1]);
      else
	result+=GrHLine(dc,a.i32[1],b.i32[1],at,z1.i32[1],z2.i32[1]);
    }
    at+=step;
    a+=edge_step1;
    b+=edge_step2;
    z1+=depth_step1;
    z2+=depth_step2;
  }
  *position=at; *edge1=a; *edge2=b; *depth1=z1; *depth2=z2;
  return result;
}

public I64 GrFillTri0(CDC *dc=GRAPHICS_DEFAULT_DC,CD3I32 *p1,CD3I32 *p2,CD3I32 *p4)
{//3D. Returns cnt of pixs changed
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 x1,x2,y1,y2,z1,z2,dx1,dy1,dz1,dx2,dy2,dz2,res=0,i,min,max;
  CTask *win_task;

  if (AbsI64(p1->y-p2->y)+AbsI64(p1->y-p4->y)<=
	AbsI64(p1->x-p2->x)+AbsI64(p1->x-p4->x)) {
//p1 is min x
    if (p4->x<p2->x)
      GrTriangleSwapPoint(&p4,&p2);
    if (p2->x<p1->x)
      GrTriangleSwapPoint(&p2,&p1);

      //p2y<=p4y
    if (p4->y<p2->y)
      GrTriangleSwapPoint(&p4,&p2);

    min=0;
    max=dc->height;
    if (dc->flags & DCF_SCRN_BITMAP) {
      win_task=dc->win_task;
      min-=win_task->scroll_y+win_task->pix_top;
      max-=win_task->scroll_y+win_task->pix_top;
      if (max>win_task->pix_bottom-(win_task->scroll_y+win_task->pix_top))
	max=win_task->pix_bottom-(win_task->scroll_y+win_task->pix_top);
    }

    if ((dy2=p4->y-p1->y)<0) {
      dy1=p2->y-p1->y;
      dx1=(p1->x-p2->x)<<32/dy1;
      dz1=(p1->z-p2->z)<<32/dy1;

      dx2=(p1->x-p4->x)<<32/dy2;
      dz2=(p1->z-p4->z)<<32/dy2;
      x1=x2=p1->x<<32; y1=p1->y; z1=z2=p1->z<<32;
      if (y1+dy2<min) {
	i=min-(y1+dy2);
	if (i>-dy2) goto ft_done;
	dy2+=i;
      }
      if (y1>=max) {
	i=y1-max+1;
	if (i>-dy2)
	  i=-dy2;
	dy2+=i;
	y1-=i;
	x1+=dx1*i;
	x2+=dx2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      res+=GrTriangleScan(dc,FALSE,-dy2,-1,
          &y1,&x1,&x2,&z1,&z2,dx1,dx2,dz1,dz2,I64_MAX);
      if (dy2=p2->y-p4->y) {
	dx2=(p4->x-p2->x)<<32/dy2;
	dz2=(p4->z-p2->z)<<32/dy2;
	if (y1+dy2<min) {
	  i=min-(y1+dy2);
	  if (i>-dy2) goto ft_done;
	  dy2+=i;
	}
	if (y1>=max) {
	  i=y1-max+1;
	  if (i>-dy2) goto ft_done;
	  dy2+=i;
	  y1-=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      res+=GrTriangleScan(dc,FALSE,1-dy2,-1,
          &y1,&x1,&x2,&z1,&z2,dx1,dx2,dz1,dz2,I64_MAX);
    } else if ((dy2=p2->y-p1->y)>0) {
      dy1=p4->y-p1->y;
      dx1=(p4->x-p1->x)<<32/dy1;
      dz1=(p4->z-p1->z)<<32/dy1;

      dx2=(p2->x-p1->x)<<32/dy2;
      dz2=(p2->z-p1->z)<<32/dy2;
      x1=x2=p1->x<<32; y1=p1->y; z1=z2=p1->z<<32;
      if (y1+dy2>=max) {
	i=y1+dy2-max+1;
	if (i>dy2) goto ft_done;
	dy2-=i;
      }
      if (y1<min) {
	i=min-y1;
	if (i>dy2)
	  i=dy2;
	dy2-=i;
	y1+=i;
	x1+=dx1*i;
	x2+=dx2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      res+=GrTriangleScan(dc,FALSE,dy2,1,
          &y1,&x1,&x2,&z1,&z2,dx1,dx2,dz1,dz2,I64_MAX);
      if (dy2=p4->y-p2->y) {
	dx2=(p4->x-p2->x)<<32/dy2;
	dz2=(p4->z-p2->z)<<32/dy2;
	if (y1+dy2>=max) {
	  i=y1+dy2-max+1;
	  if (i>dy2) goto ft_done;
	  dy2-=i;
	}
	if (y1<min) {
	  i=min-y1;
	  if (i>dy2) goto ft_done;
	  dy2-=i;
	  y1+=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      res+=GrTriangleScan(dc,FALSE,1+dy2,1,
          &y1,&x1,&x2,&z1,&z2,dx1,dx2,dz1,dz2,I64_MAX);
    } else {
      if (dy1=p2->y-p1->y) {
	dx1=(p2->x-p1->x)<<32/dy1;
	dz1=(p2->z-p1->z)<<32/dy1;
	if (dy2=p2->y-p4->y) {
	  dx2=(p2->x-p4->x)<<32/dy2;
	  dz2=(p2->z-p4->z)<<32/dy2;
	} else {
	  dx2=0;
	  dz2=0;
	}
	x1=x2=p2->x<<32; y1=p2->y; z1=z2=p2->z<<32;
	if (y1<min) {
	  i=min-y1;
	  if (i>-dy1)
	    i=-dy1;
	  dy1+=i;
	  y1+=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	res+=GrTriangleScan(dc,FALSE,1-dy1,1,
	    &y1,&x1,&x2,&z1,&z2,dx1,dx2,dz1,dz2,max);
      }
      if (dy1=p4->y-p1->y) {
	dx1=(p1->x-p4->x)<<32/dy1;
	dz1=(p1->z-p4->z)<<32/dy1;
	if (dy2=p4->y-p2->y) {
	  dx2=(p2->x-p4->x)<<32/dy2;
	  dz2=(p2->z-p4->z)<<32/dy2;
	} else {
	  dx2=0;
	  dz2=0;
	}
	x1=x2=p4->x<<32; y1=p4->y; z1=z2=p4->z<<32;
	if (y1-dy1<min) {
	  i=min-(y1-dy1);
	  if (i>dy1) goto ft_done;
	  dy1-=i;
	}
	if (y1>=max) {
	  i=y1-max+1;
	  if (i>dy1) goto ft_done;
	  dy1-=i;
	  y1-=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	res+=GrTriangleScan(dc,FALSE,1+dy1,-1,
	    &y1,&x1,&x2,&z1,&z2,dx1,dx2,dz1,dz2,I64_MAX);
      }
    }
  } else {
//p1 is min y
    if (p4->y<p2->y)
      GrTriangleSwapPoint(&p4,&p2);
    if (p2->y<p1->y)
      GrTriangleSwapPoint(&p2,&p1);

      //p2x<=p4x
    if (p4->x<p2->x)
      GrTriangleSwapPoint(&p4,&p2);

    min=0;
    max=dc->width;
    if (dc->flags & DCF_SCRN_BITMAP) {
      win_task=dc->win_task;
      min-=win_task->scroll_x+win_task->pix_left;
      max-=win_task->scroll_x+win_task->pix_left;
      if (max>win_task->pix_right-(win_task->scroll_x+win_task->pix_left))
	max=win_task->pix_right-(win_task->scroll_x+win_task->pix_left);
    }

    if ((dx2=p4->x-p1->x)<0) {
      dx1=p2->x-p1->x;
      dy1=(p1->y-p2->y)<<32/dx1;
      dz1=(p1->z-p2->z)<<32/dx1;

      dy2=(p1->y-p4->y)<<32/dx2;
      dz2=(p1->z-p4->z)<<32/dx2;
      y1=y2=p1->y<<32; x1=p1->x; z1=z2=p1->z<<32;
      if (x1+dx2<min) {
	i=min-(x1+dx2);
	if (i>-dx2) goto ft_done;
	dx2+=i;
      }
      if (x1>=max) {
	i=x1-max+1;
	if (i>-dx2)
	  i=-dx2;
	dx2+=i;
	x1-=i;
	y1+=dy1*i;
	y2+=dy2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      res+=GrTriangleScan(dc,TRUE,-dx2,-1,
          &x1,&y1,&y2,&z1,&z2,dy1,dy2,dz1,dz2,I64_MAX);
      if (dx2=p2->x-p4->x) {
	dy2=(p4->y-p2->y)<<32/dx2;
	dz2=(p4->z-p2->z)<<32/dx2;
	if (x1+dx2<min) {
	  i=min-(x1+dx2);
	  if (i>-dx2) goto ft_done;
	  dx2+=i;
	}
	if (x1>=max) {
	  i=x1-max+1;
	  if (i>-dx2) goto ft_done;
	  dx2+=i;
	  x1-=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      res+=GrTriangleScan(dc,TRUE,1-dx2,-1,
          &x1,&y1,&y2,&z1,&z2,dy1,dy2,dz1,dz2,I64_MAX);
    } else if ((dx2=p2->x-p1->x)>0) {
      dx1=p4->x-p1->x;
      dy1=(p4->y-p1->y)<<32/dx1;
      dz1=(p4->z-p1->z)<<32/dx1;

      dy2=(p2->y-p1->y)<<32/dx2;
      dz2=(p2->z-p1->z)<<32/dx2;
      y1=y2=p1->y<<32; x1=p1->x; z1=z2=p1->z<<32;
      if (x1+dx2>=max) {
	i=x1+dx2-max+1;
	if (i>dx2) goto ft_done;
	dx2-=i;
      }
      if (x1<min) {
	i=min-x1;
	if (i>dx2)
	  i=dx2;
	dx2-=i;
	x1+=i;
	y1+=dy1*i;
	y2+=dy2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      res+=GrTriangleScan(dc,TRUE,dx2,1,
          &x1,&y1,&y2,&z1,&z2,dy1,dy2,dz1,dz2,I64_MAX);
      if (dx2=p4->x-p2->x) {
	dy2=(p4->y-p2->y)<<32/dx2;
	dz2=(p4->z-p2->z)<<32/dx2;
	if (x1+dx2>=max) {
	  i=x1+dx2-max+1;
	  if (i>dx2) goto ft_done;
	  dx2-=i;
	}
	if (x1<min) {
	  i=min-x1;
	  if (i>dx2) goto ft_done;
	  dx2-=i;
	  x1+=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      res+=GrTriangleScan(dc,TRUE,1+dx2,1,
          &x1,&y1,&y2,&z1,&z2,dy1,dy2,dz1,dz2,I64_MAX);
    } else {
      if (dx1=p2->x-p1->x) {
	dy1=(p2->y-p1->y)<<32/dx1;
	dz1=(p2->z-p1->z)<<32/dx1;
	if (dx2=p2->x-p4->x) {
	  dy2=(p2->y-p4->y)<<32/dx2;
	  dz2=(p2->z-p4->z)<<32/dx2;
	} else {
	  dy2=0;
	  dz2=0;
	}
	y1=y2=p2->y<<32; x1=p2->x; z1=z2=p2->z<<32;
	if (x1<min) {
	  i=min-x1;
	  if (i>-dx1)
	    i=-dx1;
	  dx1+=i;
	  x1+=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	res+=GrTriangleScan(dc,TRUE,1-dx1,1,
	    &x1,&y1,&y2,&z1,&z2,dy1,dy2,dz1,dz2,max);
      }
      if (dx1=p4->x-p1->x) {
	dy1=(p1->y-p4->y)<<32/dx1;
	dz1=(p1->z-p4->z)<<32/dx1;
	if (dx2=p4->x-p2->x) {
	  dy2=(p2->y-p4->y)<<32/dx2;
	  dz2=(p2->z-p4->z)<<32/dx2;
	} else {
	  dy2=0;
	  dz2=0;
	}
	y1=y2=p4->y<<32; x1=p4->x; z1=z2=p4->z<<32;
	if (x1-dx1<min) {
	  i=min-(x1-dx1);
	  if (i>dx1) goto ft_done;
	  dx1-=i;
	}
	if (x1>=max) {
	  i=x1-max+1;
	  if (i>dx1) goto ft_done;
	  dx1-=i;
	  x1-=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	res+=GrTriangleScan(dc,TRUE,1+dx1,-1,
	    &x1,&y1,&y2,&z1,&z2,dy1,dy2,dz1,dz2,I64_MAX);
      }
    }
  }
ft_done:
  return res;
}
