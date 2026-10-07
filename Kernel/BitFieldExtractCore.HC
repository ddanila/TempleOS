//Equivalent U32 extraction without an unaligned eight-byte read.
//The original shift masks size modulo 64, then the U32 return truncates it.
#ifndef BIT_FIELD_EXTRACT_NAME
#define BIT_FIELD_EXTRACT_NAME BFieldExtU32
#endif
public U32 BIT_FIELD_EXTRACT_NAME(U8 *bit_field,I64 bit,I64 size)
{
  U32 result=0,value;
  I64 shift=bit&7,out_shift=0,take;
  U8 *source=bit_field+(bit>>3);
  size&=63;
  if(size>32)size=32;
  while(size>0) {
    take=8-shift;
    if(take>size)take=size;
    value=*source++;
    value=(value>>shift)&((1<<take)-1);
    result|=value<<out_shift;
    size-=take;out_shift+=take;shift=0;
  }
  return result;
}
