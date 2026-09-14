U8 internal_expected_raw[17]={2,2,3,3,4,4,4,5,5,6,7,8,9,10,11,14,14};
U8 internal_expected_size[17]={0,0,0,0,1,1,1,1,1,2,2,4,4,8,8,8,8};
I64 InternalTypeSeedTest(I64 pointer_bytes)
{
  U8 *name="I0i\0I0\0U0i\0U0\0I8i\0I8\0Bool\0U8i\0U8\0I16i\0U16i\0I32i\0U32i\0I64i\0U64i\0F64i\0F64\0";
  CHashClass *record=DeleteAllocRaw(sizeof(CHashClass)*5);
  I64 i,j,result=0;
  if(!record) return 87;
  PrsClassInit(record); record->str="retained"; record->flags=1;
  if(InternalTypeSet(0,0) || InternalTypeSet(record,-1) || InternalTypeSet(record,17) ||
      record->type!=HTT_CLASS || record->flags!=1) result=88;
  for(i=0;i<17;i++) {
    if(internal_types_table[i].type!=internal_expected_raw[i] ||
        internal_types_table[i].size!=internal_expected_size[i] ||
        StrCmp(internal_types_table[i].name,name)) result=89;
    if(!InternalTypeSet(record,i) || record->type!=HTT_INTERNAL_TYPE ||
        record->raw_type!=internal_expected_raw[i] || record->size!=internal_expected_size[i] ||
        record->flags!=3 || StrCmp(record->str,"retained") ||
        record->last_in_member_lst!=&record->member_lst_and_root) result=90;
    for(j=1;j<5;j++) if(record[j].type!=HTT_CLASS || record[j].raw_type!=RT_PTR ||
        record[j].size!=pointer_bytes || record[j].flags || record[j].ptr_stars_cnt!=j) result=91;
    while(*name) name++;
    name++;
  }
  DeleteFreeRaw(record); return result;
}
