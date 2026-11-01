F64 *ONCollect()
{
  I64 i;F64 *values=CAlloc(256*sizeof(F64));
  for(i=0;i<256;i++)values[i]=Ona2Freq(i(I8));
  return values;
}
