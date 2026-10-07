#help_index "Graphics"

#include "/Adam/Gr/GrPointClipCore.HC"

#include "/Adam/Gr/GrFloodFillCore.HC"

#include "/Adam/Gr/GrFillCircleCore.HC"

#include "/Adam/Gr/GrPlot3Core.HC"

#include "/Adam/Gr/GrLineCore.HC"

public Bool GrCircle(CDC *dc=gr.dc,I64 cx,I64 cy,I64 radius,
  I64 step=1,F64 start_radians=0,F64 len_radians=2*ã)
{//2D. Clipping but not transformation.
  Bool res;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  res=Circle(dc,cx,cy,0,radius,&GrLinePlot,step,start_radians,len_radians);
  dc->depth_buf=db;
  return res;
}

public Bool GrEllipse(CDC *dc=gr.dc,
		I64 cx,I64 cy,
		I64 x_radius,I64 y_radius,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{//2D. Clipping but not transformation.
  Bool res;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  res=Ellipse(dc,cx,cy,0,x_radius,y_radius,&GrLinePlot,
	rot_angle,step,start_radians,len_radians);
  dc->depth_buf=db;
  return res;
}

public Bool GrRegPoly(CDC *dc=gr.dc,
		I64 cx,I64 cy,
		I64 x_radius,I64 y_radius,I64 sides,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{//2D. Clipping but no transform or thick.
  Bool res;
  I32 *db=dc->depth_buf;
  dc->depth_buf=NULL;
  res=RegPoly(dc,cx,cy,0,x_radius,y_radius,sides,
	&GrLinePlot,rot_angle,step,start_radians,len_radians);
  dc->depth_buf=db;
  return res;
}

public Bool Gr2Bezier(CDC *dc=gr.dc,CD3I32 *ctrl)
{//2nd order. Clipping but no transform or thick.
  return Bezier2(dc,ctrl,&GrLinePlot);
}

public Bool Gr3Bezier(CDC *dc=gr.dc,CD3I32 *ctrl)
{//3rd order. Clipping but no transform or thick.
  return Bezier3(dc,ctrl,&GrLinePlot);
}

public Bool Gr2BSpline(CDC *dc=gr.dc,CD3I32 *ctrl,I64 cnt,Bool closed=FALSE)
{//2nd order. Clipping but no transform or thick.
  return BSpline2(dc,ctrl,cnt,&GrLinePlot,closed);
}

public Bool Gr3BSpline(CDC *dc=gr.dc,CD3I32 *ctrl,I64 cnt,Bool closed=FALSE)
{//3rd order. Clipping but no transform or thick.
  return BSpline3(dc,ctrl,cnt,&GrLinePlot,closed);
}

#include "/Adam/Gr/GrLine3Core.HC"

#help_index "Graphics/Char;Char/Graphics"

#include "/Adam/Gr/GrText3Core.HC"

#help_index "Graphics"

#include "/Adam/Gr/GrCurves3Core.HC"

#include "/Adam/Gr/GrFloodFill3Core.HC"

#help_index "Graphics;Graphics/Device Contexts"

Option(OPTf_WARN_HEADER_MISMATCH,OFF);
#include "/Adam/Gr/GrBlot3Core.HC"
Option(OPTf_WARN_HEADER_MISMATCH,ON);

#help_index "Graphics"

#include "/Adam/Gr/GrSplines3Core.HC"

#include "/Adam/Gr/GrFillTriangleCore.HC"
