#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original 3D Bezier and B-spline rendering.
public Bool Gr2Bezier3(CDC *dc=GRAPHICS_DEFAULT_DC,CD3I32 *ctrl)
{//2nd order. Clipping and transform and thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res=FALSE;
  I64 i,x,y,z,
	old_flags=dc->flags;
  CD3I32 *ctrl2=NULL,*ctrl3=NULL;
  if (dc->flags & DCF_TRANSFORMATION) {
    ctrl2=MAlloc(sizeof(CD3I32)*3);
    for (i=0;i<3;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      (*dc->transform)(dc,&x,&y,&z);
      ctrl2[i].x=x;
      ctrl2[i].y=y;
      ctrl2[i].z=z;
    }
    dc->flags&=~DCF_TRANSFORMATION;
    ctrl=ctrl2;
  }
  if (dc->flags & DCF_SYMMETRY) {
    ctrl3=MAlloc(sizeof(CD3I32)*3);
    for (i=0;i<3;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      DCReflect(dc,&x,&y,&z);
      ctrl3[i].x=x;
      ctrl3[i].y=y;
      ctrl3[i].z=z;
    }
    dc->flags&=~DCF_SYMMETRY;
    res=Bezier2(dc,ctrl3,&GrPlot3);
    if (dc->flags & DCF_JUST_MIRROR)
      goto gr_done;
  }

  res|=Bezier2(dc,ctrl,&GrPlot3);
gr_done:
  Free(ctrl2);
  Free(ctrl3);
  dc->flags=old_flags;
  return res;
}

public Bool Gr3Bezier3(CDC *dc=GRAPHICS_DEFAULT_DC,CD3I32 *ctrl)
{//3rd order. Clipping and transform and thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res=FALSE;
  I64 i,x,y,z,
	old_flags=dc->flags;
  CD3I32 *ctrl2=NULL,*ctrl3=NULL;
  if (dc->flags & DCF_TRANSFORMATION) {
    ctrl2=MAlloc(sizeof(CD3I32)*4);
    for (i=0;i<4;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      (*dc->transform)(dc,&x,&y,&z);
      ctrl2[i].x=x;
      ctrl2[i].y=y;
      ctrl2[i].z=z;
    }
    dc->flags&=~DCF_TRANSFORMATION;
    ctrl=ctrl2;
  }
  if (dc->flags & DCF_SYMMETRY) {
    ctrl3=MAlloc(sizeof(CD3I32)*4);
    for (i=0;i<4;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      DCReflect(dc,&x,&y,&z);
      ctrl3[i].x=x;
      ctrl3[i].y=y;
      ctrl3[i].z=z;
    }
    dc->flags&=~DCF_SYMMETRY;
    res=Bezier3(dc,ctrl3,&GrPlot3);
    if (dc->flags & DCF_JUST_MIRROR)
      goto gr_done;
  }

  res|=Bezier3(dc,ctrl,&GrPlot3);
gr_done:
  Free(ctrl2);
  Free(ctrl3);
  dc->flags=old_flags;
  return res;
}

public I64 Gr2BSpline3(CDC *dc=GRAPHICS_DEFAULT_DC,CD3I32 *ctrl,I64 cnt,Bool closed=FALSE)
{//2nd order. Clipping and transform and thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res=FALSE;
  I64 i,x,y,z,
	old_flags=dc->flags;
  CD3I32 *ctrl2=NULL,*ctrl3=NULL;
  if (dc->flags & DCF_TRANSFORMATION) {
    ctrl2=MAlloc(sizeof(CD3I32)*cnt);
    for (i=0;i<cnt;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      (*dc->transform)(dc,&x,&y,&z);
      ctrl2[i].x=x;
      ctrl2[i].y=y;
      ctrl2[i].z=z;
    }
    dc->flags&=~DCF_TRANSFORMATION;
    ctrl=ctrl2;
  }
  if (dc->flags & DCF_SYMMETRY) {
    ctrl3=MAlloc(sizeof(CD3I32)*cnt);
    for (i=0;i<cnt;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      DCReflect(dc,&x,&y,&z);
      ctrl3[i].x=x;
      ctrl3[i].y=y;
      ctrl3[i].z=z;
    }
    dc->flags&=~DCF_SYMMETRY;
    res=BSpline2(dc,ctrl3,cnt,&GrPlot3,closed);
    if (dc->flags & DCF_JUST_MIRROR)
      goto gr_done;
  }

  res|=BSpline2(dc,ctrl,cnt,&GrPlot3,closed);
gr_done:
  Free(ctrl2);
  Free(ctrl3);
  dc->flags=old_flags;
  return res;
}

public Bool Gr3BSpline3(CDC *dc=GRAPHICS_DEFAULT_DC,CD3I32 *ctrl,I64 cnt,Bool closed=FALSE)
{//3rd order. Clipping and transform and thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool res=FALSE;
  I64 i,x,y,z,
	old_flags=dc->flags;
  CD3I32 *ctrl2=NULL,*ctrl3=NULL;
  if (dc->flags & DCF_TRANSFORMATION) {
    ctrl2=MAlloc(sizeof(CD3I32)*cnt);
    for (i=0;i<cnt;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      (*dc->transform)(dc,&x,&y,&z);
      ctrl2[i].x=x;
      ctrl2[i].y=y;
      ctrl2[i].z=z;
    }
    dc->flags&=~DCF_TRANSFORMATION;
    ctrl=ctrl2;
  }
  if (dc->flags & DCF_SYMMETRY) {
    ctrl3=MAlloc(sizeof(CD3I32)*cnt);
    for (i=0;i<cnt;i++) {
      x=ctrl[i].x;
      y=ctrl[i].y;
      z=ctrl[i].z;
      DCReflect(dc,&x,&y,&z);
      ctrl3[i].x=x;
      ctrl3[i].y=y;
      ctrl3[i].z=z;
    }
    dc->flags&=~DCF_SYMMETRY;
    res=BSpline3(dc,ctrl3,cnt,&GrPlot3,closed);
    if (dc->flags & DCF_JUST_MIRROR)
      goto gr_done;
  }

  res|=BSpline3(dc,ctrl,cnt,&GrPlot3,closed);
gr_done:
  Free(ctrl2);
  Free(ctrl3);
  dc->flags=old_flags;
  return res;
}

