I64 InternalRegistryTest()
{
  CI386InternalTypes registry;
  CI386Heap small;
  CHashClass *entry;
  CHashTable *saved;
  I64 i,j,size,successes=0,failures=0;
  U32 flags=I386IrqSave;
  registry.heap=0; registry.table=0;
  for(i=0;i<RT_RTS_NUM;i++) registry.by_raw[i]=0;
  if(I386InternalTypesInit(0,&delete_heap) || I386InternalTypesInit(&registry,0) ||
      !I386InternalTypesDelete(&registry)) return 92;
  SetRFlags(GetRFlags|0x200);
  if(!I386InternalTypesInit(&registry,&delete_heap) || !(GetRFlags&0x200)) return 93;
  saved=registry.table;
  if(I386InternalTypesInit(&registry,&delete_heap) || registry.table!=saved) return 94;
  for(i=0;i<17;i++) {
    entry=HashFind(internal_types_table[i].name,registry.table,HTT_INTERNAL_TYPE);
    if(!entry || entry->raw_type!=internal_expected_raw[i] || entry->size!=internal_expected_size[i] ||
        entry->flags!=2 || I386HeapSize(&delete_heap,entry)!=sizeof(CHashClass)*5 ||
        I386HeapSize(&delete_heap,entry->str)!=8) return 95;
    for(j=1;j<5;j++) if(entry[j].size!=4 || entry[j].ptr_stars_cnt!=j) return 96;
    for(j=i+1;j<17;j++) if(internal_expected_raw[i]==internal_expected_raw[j]) break;
    if(j==17 && registry.by_raw[entry->raw_type]!=entry) return 97;
  }
  if(registry.by_raw[0] || registry.by_raw[1] || registry.by_raw[12] ||
      registry.by_raw[13] || registry.by_raw[15] || HashFind("I64",registry.table,HTT_INTERNAL_TYPE)) return 98;
  registry.table->locked_flags=1;
  if(I386InternalTypesDelete(&registry) || registry.table!=saved) return 99;
  registry.table->locked_flags=0;
  if(!I386InternalTypesDelete(&registry) || !(GetRFlags&0x200) || delete_heap.used || delete_heap.allocations) return 128;
  I386IrqSave;
  //Every aligned arena size exercises allocation cutoffs, including partial names/records.
  for(size=24;size<=8192;size+=8) {
    if(!I386HeapInit(&small,0x52000,size)) return 129;
    if(I386InternalTypesInit(&registry,&small)) {
      successes++;
      if(!I386InternalTypesDelete(&registry)) return 130;
    } else failures++;
    if(registry.table || registry.heap || small.used || small.allocations || !I386HeapValid(&small)) return 131;
    for(i=0;i<RT_RTS_NUM;i++) if(registry.by_raw[i]) return 132;
  }
  if(!successes || !failures || GetRFlags&0x200) return 133;
  I386IrqRestore(flags); return 0;
}
