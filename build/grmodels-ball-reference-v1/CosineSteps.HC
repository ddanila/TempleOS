#include "/Kernel/I386/FloatTrig.HC"

F64 cos_steps[12];

U0 BallCosineSteps()
{
  F64 x,z,r,qx,hz,a,head,tail;
  F64 c1=0x3FA555555555554C(F64),c2=0xBF56C16C16C15177(F64),
    c3=0x3EFA01A019CB1590(F64),c4=0xBE927E4F809C52AD(F64),
    c5=0x3E21EE9EBDB4B1C4(F64),c6=0xBDA8FAE9BE8838D4(F64);
  U8 msg[128],*p;
  x=0x3FE921FB54442D18(F64);
  cos_steps[0]=Cos(x);
  cos_steps[1]=I386TrigCos(x);
  cos_steps[2]=I386TrigReduce(x,&head,&tail);
  cos_steps[3]=head;
  cos_steps[4]=tail;
  cos_steps[5]=I386TrigKernelCos(head,tail);
  z=x*x;
  r=z*(c1+z*(c2+z*(c3+z*(c4+z*(c5+z*c6)))));
  qx=0.28125;
  hz=0.5*z-qx;
  a=1.0-qx;
  cos_steps[6]=z;
  cos_steps[7]=r;
  cos_steps[8]=qx;
  cos_steps[9]=hz;
  cos_steps[10]=a;
  cos_steps[11]=a-(hz-(z*r-x*tail));
  StrPrint(msg,"EXPORT BallVertexMath.bin %X %X\n",cos_steps,sizeof(cos_steps));
  for (p=msg;*p;p++) OutU8(0xE9,*p);
  Sleep(2000);
  for (p="BALL math ready\n";*p;p++) OutU8(0xE9,*p);
}
BallCosineSteps;
