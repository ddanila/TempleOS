I64 MMContract()
{
  I64 mask=0;
  if(Max(2.5,-7.0)==2.5&&Max(-7.0,2.5)==2.5)mask|=1;
  if(Min(2.5,-7.0)==-7.0&&Min(-7.0,2.5)==-7.0)mask|=2;
  if(Clamp(-2.0,-1.0,3.0)==-1.0)mask|=4;
  if(Clamp(4.0,-1.0,3.0)==3.0)mask|=8;
  if(Clamp(1.25,-1.0,3.0)==1.25)mask|=16;
  if(Max(3,7)==7&&Min(3,7)==3)mask|=32;
  if(Clamp(2.0,3.0,1.0)==3.0)mask|=64;
  return mask;
}
I64 MMCheck(){I64 v=MMContract;if(v!=127)throw('MinMax',TRUE);return v;}
