//Bounded T32M serializer; metadata uses final absolute string offsets.
#include "/Kernel/I386/ModuleCheck.HH"
//Sorted borrowed spans cover live code/data; alignment holes read as zero.
class CI386ModuleWriteSpan {
  U32 offset,bytes;
  U8 *data;
};
class CI386ModuleWriteSpans {
  CI386ModuleWriteSpan *spans;
  U32 count,bytes;
};
Bool I386ModuleWriteSpansValid(CI386ModuleWriteSpans *view)
{
  U32 i,end=0;
  CI386ModuleWriteSpan *span;
  if(!view || !view->bytes || !view->count || !view->spans) return FALSE;
  for(i=0;i<view->count;i++) {
    span=view->spans+i;
    if(!span->data || !span->bytes || span->offset<end ||
        span->offset>view->bytes || span->bytes>view->bytes-span->offset)
      return FALSE;
    end=span->offset+span->bytes;
  }
  return TRUE;
}
U8 I386ModuleWriteSpanByte(U8 *context,U32 offset)
{//Use only after validating the view; no allocation or payload copy.
  CI386ModuleWriteSpans *view=context;
  CI386ModuleWriteSpan *span;
  U32 lo=0,hi=view->count,mid;
  if(offset>=view->bytes)return 0;
  while(lo<hi) {
    mid=lo+(hi-lo)/2;span=view->spans+mid;
    if(offset<span->offset)hi=mid;
    else if(offset-span->offset>=span->bytes)lo=mid+1;
    else return span->data[offset-span->offset];
  }
  return 0;
}
class CI386ModuleWriteView {
  CI386ModuleHeader *header;
  CI386ModuleRecord *records;
  U8 (*code)(U8 *context,U32 offset);
  U8 *context;
};
U8 I386ModuleWriteByte(U8 *context,U32 offset)
{//Validation observes the same normalized fixups the writer will emit.
  CI386ModuleWriteView *view=context;
  CI386ModuleRecord *record;
  U32 i;
  for(i=0;i<view->header->record_count;i++) {
    record=view->records+i;
    if(record->kind==I386_MODULE_REL32 || record->kind==I386_MODULE_ADDRESS ||
        record->kind==I386_MODULE_POINTER || record->kind==I386_MODULE_NAMED_POINTER)
      if(offset>=record->offset && offset-record->offset<4) return 0;
  }
  return (*view->code)(view->context,offset);
}
I64 I386ModuleWriteParts(CI386ModuleHeader *header,CI386ModuleRecord *records,
  U8 *strings,U8 (*code)(U8 *context,U32 offset),U8 *code_context,
  I64 (*sink)(U8 *context,U32 offset,U8 *buffer,U32 bytes),U8 *sink_context,
  U8 *scratch,I64 scratch_bytes)
{//Validate before any writes; exact short/error writes abort without retry.
  CI386ModuleWriteView view;
  CI386ModuleRecord *record;
  U8 patch_bits[512];
  I64 offset=0,count,i,j,position,lo,hi,start,end,patch_base=0,patch_end=0,bit;
  if(!header || !records || !strings || !code || !sink || !scratch ||
      scratch_bytes<1 || scratch_bytes>4096) return 0;
  view.header=header;view.records=records;view.code=code;view.context=code_context;
  if(!I386ModuleValidParts(header,records,strings,header->total_size,
      &I386ModuleWriteByte,&view)) return 0;
  while(offset<header->total_size) {
    count=header->total_size-offset;
    if(count>scratch_bytes) count=scratch_bytes;
    for(i=0;i<count;i++) {
      position=offset+i;
      if(position<32) scratch[i]=header(U8 *)[position];
      else if(position<header->records_offset) {
        if(position>=patch_end) {
          patch_base=position & -4096;
          patch_end=patch_base+4096;
          for(j=0;j<sizeof(patch_bits);j++)patch_bits[j]=0;
          for(j=0;j<header->record_count;j++) {
            record=records+j;
            if(record->kind==I386_MODULE_REL32 || record->kind==I386_MODULE_ADDRESS ||
                record->kind==I386_MODULE_POINTER || record->kind==I386_MODULE_NAMED_POINTER) {
              start=32+record->offset;end=start+4;
              lo=patch_base;if(start>lo)lo=start;
              hi=patch_end;if(end<hi)hi=end;
              while(lo<hi) {
                bit=lo++-patch_base;
                patch_bits[bit>>3]|=1<<(bit&7);
              }
            }
          }
        }
        scratch[i]=(*code)(code_context,position-32);
        bit=position-patch_base;
        if(patch_bits[bit>>3] & 1<<(bit&7))scratch[i]=0;
      }
      else if(position<header->strings_offset)
        scratch[i]=records(U8 *)[position-header->records_offset];
      else scratch[i]=strings[position-header->strings_offset];
    }
    if((*sink)(sink_context,offset,scratch,count)!=count) return 0;
    offset+=count;
  }
  return offset;
}
