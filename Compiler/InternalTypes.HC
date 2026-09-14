#include "/Compiler/InternalTypes.HH"
CInternalType internal_types_table[INTERNAL_TYPES_NUM]={
  {RT_I0,0,"I0i"},{RT_I0,0,"I0"},{RT_U0,0,"U0i"},{RT_U0,0,"U0"},
  {RT_I8,1,"I8i"},{RT_I8,1,"I8"},{RT_I8,1,"Bool"},
  {RT_U8,1,"U8i"},{RT_U8,1,"U8"},
  {RT_I16,2,"I16i"},{RT_U16,2,"U16i"},
  {RT_I32,4,"I32i"},{RT_U32,4,"U32i"},
  {RT_I64,8,"I64i"},{RT_U64,8,"U64i"},
  {RT_F64,8,"F64i"},{RT_F64,8,"F64"},
};
Bool InternalTypeSet(CHashClass *record,I64 index)
{
  CInternalType *descriptor;
  if(!record || index<0 || index>=INTERNAL_TYPES_NUM) return FALSE;
  descriptor=internal_types_table+index;
  record->type=HTT_INTERNAL_TYPE;
  record->raw_type=descriptor->type;
  record->flags|=1<<Cf_INTERNAL_TYPE;
  record->size=descriptor->size;
  return TRUE;
}
