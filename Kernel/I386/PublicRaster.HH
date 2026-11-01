#ifndef I386_PUBLIC_RASTER_INCLUDED
#define I386_PUBLIC_RASTER_INCLUDED
#include "/Kernel/MathConstants.HH"
//Load after NativeGraphicsStart so the default is the target context.
public _extern _GR_RECT I64 GrRect(CDC *dc=gr.dc,I64 x,I64 y,I64 w,I64 h);
public _extern _GR_PUT_CHAR I64 GrPutChar(CDC *dc=gr.dc,I64 x,I64 y,U8 ch);
public _extern _GR_PUT_S I64 GrPutS(CDC *dc=gr.dc,I64 x,I64 y,U8 *s);
public _extern _GR_VPUT_S I64 GrVPutS(CDC *dc=gr.dc,I64 x,I64 y,U8 *s);
public _extern _GR_PRINT I64 GrPrint(CDC *dc=gr.dc,I64 x,I64 y,U8 *fmt,...);
public _extern _GR_VPRINT I64 GrVPrint(CDC *dc=gr.dc,I64 x,I64 y,U8 *fmt,...);
public _extern _GR_PUT_CHAR3 Bool GrPutChar3(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 ch);
public _extern _GR_PRINT3 I64 GrPrint3(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *fmt,...);
public _extern _GR_VPRINT3 I64 GrVPrint3(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *fmt,...);
public _extern _GR_TEXT_BOX3 Bool GrTextBox3(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *s,I64 border=2);
public _extern _GR_TEXT_DIAMOND3 Bool GrTextDiamond3(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *s,I64 border=2);
public _extern _SPRITE3 U0 Sprite3(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,Bool just_one_elem=FALSE);
public _extern _GR_LINE Bool GrLine(CDC *dc=gr.dc,I64 x1,I64 y1,I64 x2,I64 y2,I64 step=1,I64 start=0);
public _extern _GR_CIRCLE Bool GrCircle(CDC *dc=gr.dc,I64 cx,I64 cy,I64 radius,I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public _extern _GR_ELLIPSE Bool GrEllipse(CDC *dc=gr.dc,I64 cx,I64 cy,I64 x_radius,I64 y_radius,F64 rot_angle=0,I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public _extern _GR_REG_POLY Bool GrRegPoly(CDC *dc=gr.dc,I64 cx,I64 cy,I64 x_radius,I64 y_radius,I64 sides,F64 rot_angle=0,I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public _extern _GR_FLOOD_FILL I64 GrFloodFill(CDC *dc=gr.dc,I64 x,I64 y,Bool not_color=FALSE,I64 z=0,I32 *db=NULL);
public _extern _GR_PLOT0 Bool GrPlot0(CDC *dc=gr.dc,I64 x,I64 y);
public _extern _GR_PEEK0 I64 GrPeek0(CDC *dc=gr.dc,I64 x,I64 y);
public _extern _SPRITE_INTERPOLATE U8 *SpriteInterpolate(F64 t,U8 *elems0,U8 *elems1);
public _extern _SPRITE_3B U0 Sprite3B(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems);
public _extern _SPRITE_3_MAT4X4B U0 Sprite3Mat4x4B(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,I64 *m);
public _extern _SPRITE_3XB U0 Sprite3XB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 angle=0);
public _extern _SPRITE_3YB U0 Sprite3YB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 angle=0);
public _extern _SPRITE_3ZB U0 Sprite3ZB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 angle=0);
public _extern _SPRITE_SIZE I64 SpriteSize(U8 *elems);
#endif
