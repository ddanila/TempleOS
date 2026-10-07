I64 mr_x[16]={0x100000000,0,0,0,0,0,-0x100000000,0,0,0x100000000,0,0,0,0,0,0x100000000};
I64 mr_y[16]={0,0,0x100000000,0,0,0x100000000,0,0,-0x100000000,0,0,0,0,0,0,0x100000000};
I64 mr_z[16]={0,-0x100000000,0,0,0x100000000,0,0,0,0,0,0x100000000,0,0,0,0,0x100000000};
U0 MRIdentity(I64 *m)
{MemSet(m,0,128);m[0]=m[5]=m[10]=m[15]=0x100000000;}
Bool MRNear(I64 *a,I64 *b,I64 tolerance=2)
{I64 i;for(i=0;i<16;i++)if(AbsI64(a[i]-b[i])>tolerance)return FALSE;return TRUE;}
I64 JRContract(I64 unused)
{
  I64 m[16],identity[16],expected[16],mask=0;
  F64 quarter=1.5707963267948966;
  MRIdentity(identity);MRIdentity(m);
  if(Mat4x4RotX(m,0)==m && Mat4x4RotY(m,0)==m && Mat4x4RotZ(m,0)==m && MRNear(m,identity,0))mask|=1;
  MRIdentity(m);Mat4x4RotX(m,quarter);if(MRNear(m,mr_x))mask|=2;
  MRIdentity(m);Mat4x4RotY(m,quarter);if(MRNear(m,mr_y))mask|=4;
  MRIdentity(m);Mat4x4RotZ(m,quarter);if(MRNear(m,mr_z))mask|=8;
  MRIdentity(m);Mat4x4RotX(m,0.3);Mat4x4RotX(m,-0.3);
  Mat4x4RotY(m,0.7);Mat4x4RotY(m,-0.7);Mat4x4RotZ(m,1.1);Mat4x4RotZ(m,-1.1);
  if(MRNear(m,identity,12))mask|=16;
  MRIdentity(expected);expected[0]=expected[5]=-0x100000000;
  MRIdentity(m);Mat4x4RotZ(m,quarter);Mat4x4RotZ(m,quarter);
  if(MRNear(m,expected,4))mask|=32;
  return mask;
}
