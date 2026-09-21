#ifndef I386_PUBLIC_GRAPHICS_CONTEXT_INCLUDED
#define I386_PUBLIC_GRAPHICS_CONTEXT_INCLUDED
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/GraphicsTypes.HH"
#include "/Adam/Gr/GrGlobalsTypes.HH"
public _extern _MAT4X4MULXYZ U0 Mat4x4MulXYZ(I64 *r,I64 *x,I64 *y,I64 *z);
public _extern _DCTRANSFORM U0 DCTransform(CDC *dc,I64 *x,I64 *y,I64 *z);
public _extern _MAT4X4IDENTEQU I64 * Mat4x4IdentEqu(I64 *r);
public _extern _MAT4X4IDENTNEW I64 * Mat4x4IdentNew(CTask *task=NULL);
public _extern _MAT4X4NORMSQR65536 I64 Mat4x4NormSqr65536(I64 *r);
public _extern _DCMAT4X4SET U0 DCMat4x4Set(CDC *dc=NULL,I64 *r);
public _extern _DCLIGHTING U0 DCLighting(CDC *dc,CD3I32 *p1,CD3I32 *p2,CD3I32 *p3,CColorROPU32 color);
public _extern _DCFILL U0 DCFill(CDC *dc=NULL,CColorROPU32 value=TRANSPARENT);
public _extern _DCCLEAR U0 DCClear(CDC *dc=NULL);
public _extern _DCRST U0 DCRst(CDC *dc);
public _extern _DCEXTENTSINIT U0 DCExtentsInit(CDC *dc=NULL);
public _extern _DCALIAS CDC * DCAlias(CDC *dc=NULL,CTask *task=NULL);
public _extern _DCNEW CDC * DCNew(I64 width,I64 height,CTask *task=NULL,Bool null_bitmap=FALSE);
public _extern _DCDEL U0 DCDel(CDC *dc);
public _extern _DCSIZE I64 DCSize(CDC *dc);
public _extern _DCDEPTHBUFRST I32 * DCDepthBufRst(CDC *dc);
public _extern _DCDEPTHBUFALLOC I32 * DCDepthBufAlloc(CDC *dc);
public extern CGrGlbls gr;
public extern CBGR48 gr_palette_std[COLORS_NUM];
public _extern _GRAPHICS_START Bool NativeGraphicsStart();
public _extern _GRAPHICS_PRESENT Bool NativeGraphicsPresent(U0 (*draw)(CDC *dc)=NULL,Bool blink=FALSE);
#endif
