I64 VNContract()
{
  CD3I32 a,b;I64 mask=0;F64 norm;
  a.x=0;a.y=0;a.z=0;b.x=0;b.y=0;b.z=0;
  if(D3I32Norm(&a)==0 && D3I32NormSqr(&a)==0)mask|=1;
  if(D3I32Dist(&a,&b)==0 && D3I32DistSqr(&a,&b)==0)mask|=2;
  a.x=3;a.y=4;a.z=12;
  if(D3I32Norm(&a)==13 && D3I32NormSqr(&a)==169)mask|=4;
  b.x=-3;b.y=4;b.z=12;
  if(D3I32Dist(&a,&b)==6 && D3I32DistSqr(&a,&b)==36)mask|=8;
  if(D3I32Dist(&a,&b)==D3I32Dist(&b,&a))mask|=16;
  a.x=-10000;a.y=60000;a.z=10000;norm=D3I32Norm(&a);
  if(D3I32NormSqr(&a)==3800000000 && norm>61644 && norm<61645)mask|=32;
  b.x=-10003;b.y=59996;b.z=9988;
  if(D3I32DistSqr(&a,&b)==169 && D3I32Dist(&a,&b)==13)mask|=64;
  return mask;
}
I64 VNCheck(){I64 v=VNContract;if(v!=127)throw('Vector',TRUE);return v;}
