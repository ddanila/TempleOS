#include "/Kernel/I386/NativeTTFGeometry.HC"
#define GR_SCALE (1<<32)
#include "/Adam/Gr/MatrixRotationCore.HC"
#include "/Adam/Gr/SpriteBaseSizes.HC"
#include "/Kernel/Freq2OnaCore.HC"
#include "/Kernel/SerialDev/KeyCharPollCore.HC"

public CD3 *D3Equ(CD3 *dst,F64 x=0,F64 y=0,F64 z=0)
{
  dst->x=x; dst->y=y; dst->z=z;
  return dst;
}

public CD3 *D3Add(CD3 *sum,CD3 *a,CD3 *b)
{
  return D3Equ(sum,a->x+b->x,a->y+b->y,a->z+b->z);
}

public CD3 *D3Cross(CD3 *product,CD3 *a,CD3 *b)
{
  return D3Equ(product,a->y*b->z-a->z*b->y,
               a->z*b->x-a->x*b->z,a->x*b->y-a->y*b->x);
}

public F64 D3Dot(CD3 *a,CD3 *b)
{
  return a->x*b->x+a->y*b->y+a->z*b->z;
}

public F64 D3DistSqr(CD3 *a,CD3 *b)
{
  CD3 delta;
  D3Sub(&delta,a,b);
  return D3NormSqr(&delta);
}
