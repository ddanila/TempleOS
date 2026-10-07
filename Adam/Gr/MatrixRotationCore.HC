public I64 *Mat4x4MulMat4x4Equ(I64 *dst,I64 *m1,I64 *m2)
{//Multiply 4x4 matrices and store in dst. Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
//Conceptually, the transform m1 is applied after m2
  I64 i,j,k;
  F64 sum;
  for (i=0;i<4;i++) {
    for (j=0;j<4;j++) {
      sum=0;
      for (k=0;k<4;k++)
	sum+=ToF64(m1[k+4*j])*ToF64(m2[i+4*k]);
      dst[i+4*j]=sum/GR_SCALE;
    }
  }
  return dst;
}

public I64 *Mat4x4MulMat4x4New(I64 *m1,I64 *m2,CTask *mem_task=NULL)
{//Multiply 4x4 matrices. Return MAlloced matrix. Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
//Conceptually, the transform m1 is applied after m2
  return Mat4x4MulMat4x4Equ(MAlloc(sizeof(I64)*16,mem_task),m1,m2);
}

public I64 *Mat4x4Equ(I64 *dst,I64 *src)
{//Copy 4x4 Rot matrix.
  MemCpy(dst,src,sizeof(I64)*16);
  return dst;
}

public I64 *Mat4x4New(I64 *src,CTask *mem_task=NULL)
{//Return MAlloced copy of 4x4 Rot matrix.
  return Mat4x4Equ(MAlloc(sizeof(I64)*16,mem_task),src);
}

public I64 *Mat4x4RotX(I64 *m,F64 è)
{//Rot matrix about X axis. Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  F64 my_cos=Cos(è)*GR_SCALE,my_sin=Sin(è)*GR_SCALE;
  I64 r[16],r2[16];
  MemSet(r,0,sizeof(r));
  r[5]=my_cos;
  r[10]=my_cos;
  r[9]=my_sin;
  r[6]=-my_sin;
  r[0]=GR_SCALE;
  r[15]=GR_SCALE;
  return Mat4x4Equ(m,Mat4x4MulMat4x4Equ(r2,r,m));
}

public I64 *Mat4x4RotY(I64 *m,F64 ê)
{//Rot matrix about Y axis. Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  F64 my_cos=Cos(ê)*GR_SCALE,my_sin=Sin(ê)*GR_SCALE;
  I64 r[16],r2[16];
  MemSet(r,0,sizeof(r));
  r[0]=my_cos;
  r[10]=my_cos;
  r[8]=-my_sin;
  r[2]=my_sin;
  r[5]=GR_SCALE;
  r[15]=GR_SCALE;
  return Mat4x4Equ(m,Mat4x4MulMat4x4Equ(r2,r,m));
}

public I64 *Mat4x4RotZ(I64 *m,F64 é)
{//Rot matrix about Z axis. Uses $LK,"fixed-point",A="FI:::/Demo/Lectures/FixedPoint.HC"$.
  F64 my_cos=Cos(é)*GR_SCALE,my_sin=Sin(é)*GR_SCALE;
  I64 r[16],r2[16];
  MemSet(r,0,sizeof(r));
  r[0]=my_cos;
  r[5]=my_cos;
  r[4]=my_sin;
  r[1]=-my_sin;
  r[10]=GR_SCALE;
  r[15]=GR_SCALE;
  return Mat4x4Equ(m,Mat4x4MulMat4x4Equ(r2,r,m));
}

