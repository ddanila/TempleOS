import U64 I386F64Sqrt(U64 value);
import U64 I386F64Abs(U64 value);
import U64 I386F64Add(U64 a,U64 b);
import U64 I386F64Sub(U64 a,U64 b);
import U64 I386F64Mul(U64 a,U64 b);
import U64 I386F64Div(U64 a,U64 b);
import U64 I386F64Mod(U64 a,U64 b);
import U64 I386F64FromI64(I64 value);
import I64 I386F64ToI64(U64 value);
import I64 I386F64Compare(U64 a,U64 b);
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/GraphicsTypes.HH"
#include "/Adam/Gr/GrGlobalsTypes.HH"
public CGrGlbls gr;
#include "/Adam/Gr/GrPaletteStd.HC"
//The original depth reset uses the U32 fill primitive.
U32 *MemSetU32(U32 *dst,I64 value,I64 count)
{
  I64 i;
  asm { CLD }
  for(i=0;i<count;i++) dst[i]=value;
  return dst+count;
}
U8 *(*native_graphics_body_calloc)(I64 size,CTask *task);
U8 *NativeGraphicsBodyCAlloc(I64 size,CTask *task=NULL)
{ return (*native_graphics_body_calloc)(size,task); }
#define DC_BODY_CALLOC NativeGraphicsBodyCAlloc
#include "/Adam/Gr/GrDCCore.HC"

#include "/Adam/Gr/GrBlotColor8.HC"
