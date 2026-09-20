#include "/Kernel/I386/Bits.HH"
//Resident bit-memory primitives owned by MemoryRuntime. The shared backend
//folds the complete signed I64 bit offset into the native pointer width.
//Return the previous bit, not the assigned value. LBts/LBtr emit LOCK prefixes.
Bool MemoryBitEqu(U8 *bit_field,I64 bit,Bool val)
{
  if(val) return Bts(bit_field,bit);
  return Btr(bit_field,bit);
}
Bool MemoryLockedBitEqu(U8 *bit_field,I64 bit,Bool val)
{
  if(val) return LBts(bit_field,bit);
  return LBtr(bit_field,bit);
}
