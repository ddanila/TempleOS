#ifndef I386_EMIT_CORE_INCLUDED
#define I386_EMIT_CORE_INCLUDED
#include "/Compiler/I386/Emit.HH"
I64 I386OutCapacity(CI386Out *out,I64 minimum)
{//Keep offsets and doubled capacities within the signed 32-bit code-size domain.
  I64 capacity=out->capacity;
  if(minimum<1 || minimum>0x7FFFFFFF || out->count<0 || out->count>capacity ||
      capacity<0 || capacity>0x7FFFFFFF || (capacity && !out->data)) return 0;
  if(capacity<64) capacity=64;
  while(capacity<minimum) {
    if(capacity>0x3FFFFFFF) capacity=0x7FFFFFFF;
    else capacity*=2;
  }
  return capacity;
}
U0 I386Byte(CI386Out *out,U8 val)
{
  if(out->count>=out->capacity) (*out->reserve)(out,out->count+1);
  out->data[out->count++]=val;
}
U0 I386Dword(CI386Out *out,U32 val)
{
  I64 i;
  for(i=0;i<4;i++) I386Byte(out,val.u8[i]);
}
U0 I386Bytes(CI386Out *out,U8 *bytes,I64 count)
{//Input must not alias the growable output buffer.
  I64 i;
  for(i=0;i<count;i++) I386Byte(out,bytes[i]);
}
#endif
