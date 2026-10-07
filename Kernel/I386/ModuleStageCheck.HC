//Shared staged validator; caller supplies metadata storage, never a code image.
#include "/Kernel/I386/ModuleStage.HH"
#include "/Kernel/I386/ModuleCheck.HH"
class CI386ModuleStageCheck {
  CI386ModuleStage *unit;
  U32 code_bytes,start,count;
  Bool failed;
  U8 cache[512];
};
I64 I386ModuleStageMetadataSize(CI386ModuleStage *unit,CI386ModuleHeader *h)
{
  U32 end;
  if(!unit || !h || !unit->owned || unit->phase!=I386_STAGE_READY ||
      !unit->read_range || unit->bytes<32 ||
      (*unit->read_range)(unit,0,h,32)!=32)return -1;
  if(h->magic!=I386_MODULE_MAGIC ||
      (h->version!=2 && h->version!=3 && h->version!=4) ||
      h->cpu!=3 || h->pointer_size!=4 || h->abi!=I386_MODULE_ABI ||
      h->total_size!=unit->bytes || !h->code_size || h->code_size&7 ||
      h->code_size>unit->bytes-32 || h->records_offset!=32+h->code_size ||
      h->record_count>(unit->bytes-h->records_offset)/16)return -1;
  end=h->records_offset+h->record_count*16;
  if(h->strings_offset!=end)return -1;
  return unit->bytes-h->records_offset;
}
U8 I386ModuleStageCodeByte(U8 *context,U32 offset)
{
  CI386ModuleStageCheck *check=context;
  U32 absolute,start,count;
  if(check->failed)return 0;
  if(offset>=check->code_bytes){check->failed=TRUE;return 0;}
  absolute=32+offset;
  if(!check->count || absolute<check->start || absolute-check->start>=check->count) {
    start=absolute&~511;count=check->unit->bytes-start;
    if(count>512)count=512;
    if((*check->unit->read_range)(check->unit,start,check->cache,count)!=count) {
      check->failed=TRUE;return 0;
    }
    check->start=start;check->count=count;
  }
  return check->cache[absolute-check->start];
}
Bool I386ModuleStageValid(CI386ModuleStage *unit,U8 *metadata,I64 capacity,
  Bool (*valid_parts)(CI386ModuleHeader *h,CI386ModuleRecord *records,
    U8 *strings,I64 size,U8 (*code)(U8 *context,U32 offset),U8 *context))
{
  CI386ModuleHeader h;
  CI386ModuleStageCheck check;
  I64 bytes=I386ModuleStageMetadataSize(unit,&h);
  U32 offset=0,n;
  Bool valid;
  if(bytes<0 || capacity<bytes || !metadata || !valid_parts)return FALSE;
  while(offset<bytes) {
    n=bytes-offset;if(n>4096)n=4096;
    if((*unit->read_range)(unit,h.records_offset+offset,metadata+offset,n)!=n)return FALSE;
    offset+=n;
  }
  check.unit=unit;check.code_bytes=h.code_size;check.count=0;check.failed=FALSE;
  valid=(*valid_parts)(&h,metadata,metadata+h.strings_offset-h.records_offset,
    unit->bytes,&I386ModuleStageCodeByte,&check);
  //Zero bytes on failed transport must never masquerade as valid relocations.
  return valid && !check.failed && unit->owned && unit->phase==I386_STAGE_READY;
}
