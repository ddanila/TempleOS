#ifndef I386_EMIT_INCLUDED
#define I386_EMIT_INCLUDED
#include "/Compiler/I386/EmitCore.HC"
U0 I386HostOutReserve(CI386Out *out,I64 minimum)
{
  I64 capacity=I386OutCapacity(out,minimum);
  U8 *next;
  if(!capacity) throw('Compiler');
  if(capacity<=out->capacity) return;
  next=MAlloc(capacity);
  MemCpy(next,out->data,out->count);
  Free(out->data);
  out->data=next; out->capacity=capacity;
}
U0 I386OutInit(CI386Out *out)
{
  out->data=0; out->count=out->capacity=0; out->reserve=&I386HostOutReserve;
}
#endif
