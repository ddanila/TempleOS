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
  for(i=0;i<count;i++) dst[i]=value;
  return dst;
}
#include "/Adam/Gr/GrDCCore.HC"
