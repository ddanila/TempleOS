I64 MCContract()
{
  I64 mask=0;F64 v=sqrt2;
  if(pi==0x400921FB54442D18(F64))mask|=1;
  if(exp_1==0x4005BF0A8B145769(F64))mask|=2;
  if(log2_10==0x400A934F0979A371(F64))mask|=4;
  if(log2_e==0x3FF71547652B82FE(F64))mask|=8;
  if(log10_2==0x3FD34413509F79FF(F64))mask|=16;
  if(loge_2==0x3FE62E42FEFA39EF(F64))mask|=32;
  if(sqrt2==0x3FF6A09E667F3BCD(F64) && v*v>1.99999 && v*v<2.00001)mask|=64;
  if(eps==0x3CB0000000000000(F64))mask|=128;
  return mask;
}
I64 MCCheck(){I64 v=MCContract;if(v!=255)throw('MathCnst',TRUE);return v;}
