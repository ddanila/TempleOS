#ifndef I386_EMIT_TYPES_INCLUDED
#define I386_EMIT_TYPES_INCLUDED
class CI386Out
{
  U8 *data;
  I64 count,capacity;
  U0 (*reserve)(CI386Out *out,I64 minimum);
};
//The reserve callback must satisfy minimum or throw without returning.
//Byte views are borrowed and expire on growth, deletion or owner cleanup.
#endif
