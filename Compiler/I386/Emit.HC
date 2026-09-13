#ifndef I386_EMIT_INCLUDED
#define I386_EMIT_INCLUDED
class CI386Out
{
  U8 *data;
  I64 count,capacity;
};
U0 I386Byte(CI386Out *out,U8 val)
{
  U8 *next;
  if (out->count==out->capacity) {
    out->capacity=MaxI64(64,out->capacity*2);
    next=MAlloc(out->capacity);
    MemCpy(next,out->data,out->count);
    Free(out->data);
    out->data=next;
  }
  out->data[out->count++]=val;
}
U0 I386Dword(CI386Out *out,U32 val)
{
  I64 i;
  for (i=0;i<4;i++) I386Byte(out,val.u8[i]);
}
U0 I386Bytes(CI386Out *out,U8 *bytes,I64 count)
{
  I64 i;
  for (i=0;i<count;i++) I386Byte(out,bytes[i]);
}

#endif
