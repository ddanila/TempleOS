#ifndef I386_PUBLIC_RASTER_INCLUDED
#define I386_PUBLIC_RASTER_INCLUDED
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
#endif
