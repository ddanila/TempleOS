CHashGeneric *HashGenericAdd(U8 *name,I64 type,
	I64 u0=0,I64 u1=0,I64 u2=0,CTask *task=NULL)
{//Add any type to task hash_table, 3 user_data values.
  if (!task) task=Fs;
  CHashGeneric *res=CAlloc(sizeof(CHashGeneric),task);
  res->type=type;
  res->user_data0=u0;
  res->user_data1=u1;
  res->user_data2=u2;
  res->str=StrNew(name,task);
  HashAdd(res,task->hash_table);
  return res;
}
