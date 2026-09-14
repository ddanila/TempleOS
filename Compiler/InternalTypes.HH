#ifndef COMPILER_INTERNAL_TYPES_INCLUDED
#define COMPILER_INTERNAL_TYPES_INCLUDED
#include "/Kernel/SymbolTypes.HH"
#include "/Kernel/RawTypes.HH"
#define INTERNAL_TYPES_NUM 17
public class CInternalType
{
  U8 type,size,name[8];
};
public extern CInternalType internal_types_table[INTERNAL_TYPES_NUM];
public extern Bool InternalTypeSet(CHashClass *record,I64 index);
#endif
