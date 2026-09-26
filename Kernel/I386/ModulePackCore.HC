//Allocation-free T32M serializer shared by native and host compilers.
//Named record offsets refer to the supplied string table until serialized.
#include "/Kernel/I386/ModuleCheck.HH"
public I64 I386ModulePackRaw(U8 *output,I64 capacity,U8 *code,I64 code_bytes,
  CI386ModuleRecord *records,I64 record_count,U8 *strings,I64 string_bytes)
{
  CI386ModuleHeader *header;
  CI386ModuleRecord *record,*packed;
  I64 payload,total,records_offset,strings_offset,i;
  Bool pointers=FALSE,named_pointers=FALSE;
  if(!code || code_bytes<1 || code_bytes>0xFFFFFFF0 || record_count<1 ||
      record_count>0x0FFFFFFF || !records || string_bytes<1 ||
      string_bytes>0xFFFFFFFF || !strings) return 0;
  payload=(code_bytes+7)&~7;
  if(record_count>(0xFFFFFFFF-32-payload)/16) return 0;
  records_offset=32+payload; strings_offset=records_offset+record_count*16;
  if(string_bytes>0xFFFFFFFF-strings_offset) return 0;
  total=strings_offset+string_bytes;
  for(i=0;i<record_count;i++) {
    record=records+i;
    if(record->kind==I386_MODULE_POINTER) pointers=TRUE;
    else if(record->kind!=I386_MODULE_DATA_RANGE) {
      if(record->kind==I386_MODULE_NAMED_POINTER) named_pointers=TRUE;
      if(record->name_length<1 || record->name_length>255 ||
          record->name_length>=string_bytes ||
          record->name_offset>string_bytes-record->name_length-1 ||
          strings[record->name_offset+record->name_length]) return 0;
    }
  }
  if(!output) return total;
  if(capacity<total) return 0;
  header=output;
  header->magic=I386_MODULE_MAGIC;
  header->version=I386_MODULE_VERSION;
  if(pointers) header->version=I386_MODULE_POINTER_VERSION;
  if(named_pointers) header->version=I386_MODULE_NAMED_POINTER_VERSION;
  header->cpu=3; header->pointer_size=4; header->abi=I386_MODULE_ABI;
  header->total_size=total; header->code_size=payload;
  header->record_count=record_count; header->records_offset=records_offset;
  header->strings_offset=strings_offset;
  for(i=0;i<code_bytes;i++) output[32+i]=code[i];
  for(;i<payload;i++) output[32+i]=0;
  packed=output+records_offset;
  for(i=0;i<record_count;i++) {
    record=records+i;
    packed[i].kind=record->kind;
    packed[i].offset=record->offset;
    packed[i].name_offset=record->name_offset;
    packed[i].name_length=record->name_length;
    if(record->kind!=I386_MODULE_POINTER && record->kind!=I386_MODULE_DATA_RANGE)
      packed[i].name_offset+=strings_offset;
    if((record->kind==I386_MODULE_POINTER ||
        record->kind==I386_MODULE_NAMED_POINTER) && record->offset<=payload-4)
      (output+32+record->offset)(U32 *)[0]=0;
  }
  for(i=0;i<string_bytes;i++) output[strings_offset+i]=strings[i];
  if(!I386ModuleValid(output,total)) return 0;
  return total;
}
