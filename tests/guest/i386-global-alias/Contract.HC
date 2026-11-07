public class AggregateRecord { U8 kind,size,name[8]; };
public extern AggregateRecord aggregate_records[2];
AggregateRecord aggregate_records[2]={{1,2,"one"},{3,4,"two"}};
public extern I64 aggregate_scalar;
I64 aggregate_scalar=0x1122334455667788;
public extern U8 aggregate_bytes[];
U8 aggregate_bytes[3]={1,2,3};
I64 AGAlias(U8 *name)
{
  CHashGlblVar *value=HashFind(name,Fs->hash_table,HTT_GLBL_VAR,1),
    *prior=HashFind(name,Fs->hash_table,HTT_GLBL_VAR,2);
  return value && prior && !(value->flags&(GVF_ALIAS|GVF_EXTERN)) &&
    (prior->flags&(GVF_ALIAS|GVF_EXTERN))==(GVF_ALIAS|GVF_EXTERN) &&
    prior->type&HTF_UNRESOLVED && value->data_addr && prior->data_addr==value->data_addr;
}
U0 AGLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 AGExport(U8 *name)
{
  U8 *buffer=MAlloc(55),*s;I64 *status=buffer;
  status[0]=AGAlias("aggregate_records");status[1]=AGAlias("aggregate_scalar");
  status[2]=AGAlias("aggregate_bytes");
  MemCpy(buffer+24,aggregate_records,20);MemCpy(buffer+44,&aggregate_scalar,8);
  MemCpy(buffer+52,aggregate_bytes,3);
  s=MStrPrint("EXPORT %s %X 37\n",name,buffer);AGLog(s);Free(s);
  AGLog(name);AGLog(" DONE\n");Sleep(1000);
}
AGExport("aggregate-initial.bin");
