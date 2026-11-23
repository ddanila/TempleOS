class BallVertexSample
{
  F64 ring,angle,cosine,x,y,z;
  I64 xi,yi,zi;
} ball_samples[128];

U0 BallVertexMath()
{
  I64 i,j,k=0;
  I64 n=4,m=8;
  F64 r=20.0,d_a1,d_a2;
  BallVertexSample *v;
  U8 msg[128],*p;
  d_a1=2*ã/n/4;
  d_a2=2*ã/m/2;
  for (j=-4;j<4;j++)
    for (i=0;i<16;i++) {
      v=&ball_samples[k++];
      v->ring=j*d_a1;
      v->angle=(i+j)*d_a2;
      v->cosine=Cos(v->angle);
      v->x=r*Cos(v->ring)*v->cosine;
      v->y=r*Cos(v->ring)*Sin(v->angle);
      v->z=r*Sin(v->ring);
      v->xi=v->x;
      v->yi=v->y;
      v->zi=v->z;
    }
  StrPrint(msg,"EXPORT BallVertexMath.bin %X %X\n",ball_samples,sizeof(ball_samples));
  for (p=msg;*p;p++)
    OutU8(0xE9,*p);
  Sleep(2000);
  for (p="BALL math ready\n";*p;p++)
    OutU8(0xE9,*p);
}
BallVertexMath;
