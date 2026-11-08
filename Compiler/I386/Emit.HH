#ifndef I386_EMIT_TYPES_INCLUDED
#define I386_EMIT_TYPES_INCLUDED
class CI386Out
{
  U8 *data;
  I64 count,capacity,planned;
  Bool measuring;
  U0 (*reserve)(CI386Out *out,I64 minimum);
  //Private frontend scratch can be segmented; data is its current write window.
  //Public/host buffers use window_start=0/address=0 and keep a contiguous view.
  //The address callback borrows a byte at a logical offset for random patches.
  I64 window_start;
  U8 *(*address)(CI386Out *out,I64 offset);
};
//The reserve callback must satisfy minimum or throw without returning.
//Byte views are borrowed and expire on growth, deletion or owner cleanup.
#endif
