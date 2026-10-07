#ifndef I386_PUBLIC_RASTER_INCLUDED
#define I386_PUBLIC_RASTER_INCLUDED
//Load after NativeGraphicsStart so the default is the target context.
public _extern _GR_RECT I64 GrRect(CDC *dc=gr.dc,I64 x,I64 y,I64 w,I64 h);
#endif
