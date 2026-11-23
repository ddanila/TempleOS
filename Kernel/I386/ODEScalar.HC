public CD3 *D3Zero(CD3 *d)
{
  d->x=0; d->y=0; d->z=0;
  return d;
}
public CD3 *D3Copy(CD3 *dst,CD3 *src)
{
  dst->x=src->x; dst->y=src->y; dst->z=src->z;
  return dst;
}
public CD3 *D3AddEqu(CD3 *dst,CD3 *src)
{
  dst->x+=src->x; dst->y+=src->y; dst->z+=src->z;
  return dst;
}
public CD3 *D3Sub(CD3 *dst,CD3 *a,CD3 *b)
{
  dst->x=a->x-b->x; dst->y=a->y-b->y; dst->z=a->z-b->z;
  return dst;
}
public CD3 *D3SubEqu(CD3 *dst,CD3 *src)
{
  dst->x-=src->x; dst->y-=src->y; dst->z-=src->z;
  return dst;
}
public CD3 *D3Mul(CD3 *dst,F64 scale,CD3 *src)
{
  dst->x=scale*src->x; dst->y=scale*src->y; dst->z=scale*src->z;
  return dst;
}
public CD3 *D3MulEqu(CD3 *dst,F64 scale)
{ return D3Mul(dst,scale,dst); }
public CD3 *D3DivEqu(CD3 *dst,F64 scale)
{
  dst->x/=scale; dst->y/=scale; dst->z/=scale;
  return dst;
}
public F64 D3NormSqr(CD3 *a)
{ return a->x*a->x+a->y*a->y+a->z*a->z; }
public F64 D3Norm(CD3 *a)
{ return Sqrt(D3NormSqr(a)); }
public F64 D3Dist(CD3 *a,CD3 *b)
{
  CD3 d;
  D3Sub(&d,a,b);
  return D3Norm(&d);
}
public CD3 *D3Unit(CD3 *a)
{ return D3DivEqu(a,D3Norm(a)); }
