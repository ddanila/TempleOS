//Shared module validation: compile unchanged for the host or i386 target.
#include "/Kernel/I386/ModuleCheck.HH"

public Bool I386ModuleValid(U8 *data,I64 size)
{
  CI386ModuleHeader *h=data;
  CI386ModuleRecord *r,*q;
  I64 i,j,end,lo,hi;
  Bool in_data,target_data,pointers=FALSE,named_pointers=FALSE;
  if (!data || size<32 || size>U32_MAX) return FALSE;
  if (h->magic!=I386_MODULE_MAGIC || (h->version!=I386_MODULE_VERSION &&
      h->version!=I386_MODULE_POINTER_VERSION &&
      h->version!=I386_MODULE_NAMED_POINTER_VERSION) ||
      h->cpu!=3 || h->pointer_size!=4 || h->abi!=I386_MODULE_ABI ||
      h->total_size!=size || !h->code_size || h->code_size&7) return FALSE;
  if (h->code_size>size-32) return FALSE;
  if (h->records_offset!=32+h->code_size) return FALSE;
  if (h->record_count>(size-h->records_offset)/16) return FALSE;
  end=h->records_offset+h->record_count*16;
  if (end!=h->strings_offset || end>size) return FALSE;
  r=data+h->records_offset;
  //Range records use name_offset as byte length and have no name.
  for (i=0;i<h->record_count;i++,r++) {
    if (r->kind==I386_MODULE_DATA_RANGE) {
      if (r->name_length || !r->name_offset || r->name_offset>h->code_size ||
          r->offset>h->code_size-r->name_offset) return FALSE;
      q=data+h->records_offset;
      for (j=0;j<i;j++,q++)
        if (q->kind==I386_MODULE_DATA_RANGE &&
            r->offset<q->offset+q->name_offset &&
            q->offset<r->offset+r->name_offset) return FALSE;
    }
  }
  r=data+h->records_offset;
  for (i=0;i<h->record_count;i++,r++) {
    if (r->kind==I386_MODULE_DATA_RANGE) goto next_record;
    if (r->kind==I386_MODULE_POINTER) {
      pointers=TRUE;
      if ((h->version!=I386_MODULE_POINTER_VERSION &&
          h->version!=I386_MODULE_NAMED_POINTER_VERSION) || r->name_length ||
          r->offset>h->code_size-4 || r->name_offset>=h->code_size ||
          (data+32+r->offset)(U32 *)[0]) return FALSE;
      in_data=FALSE; target_data=FALSE; q=data+h->records_offset;
      for (j=0;j<h->record_count;j++,q++) {
        if (q->kind==I386_MODULE_DATA_RANGE) {
          if (r->offset>=q->offset && r->offset+4<=q->offset+q->name_offset) in_data=TRUE;
          if (r->name_offset>=q->offset && r->name_offset<q->offset+q->name_offset) target_data=TRUE;
        }
        if (j<i && (q->kind==I386_MODULE_POINTER ||
            q->kind==I386_MODULE_NAMED_POINTER) &&
            r->offset<q->offset+4 && q->offset<r->offset+4) return FALSE;
      }
      if (!in_data || !target_data) return FALSE;
      goto next_record;
    }
    if (!r->name_length || r->name_length>255 || r->name_offset<end ||
        r->name_offset>size-r->name_length-1) return FALSE;
    if (data[r->name_offset+r->name_length]) return FALSE;
    for (j=0;j<r->name_length;j++)
      if (!data[r->name_offset+j]) return FALSE;
    lo=r->offset; hi=lo+1;
    if (r->kind==I386_MODULE_NAMED_POINTER) {
      named_pointers=TRUE;
      if (h->version!=I386_MODULE_NAMED_POINTER_VERSION ||
          lo>h->code_size-4 || (data+32+lo)(U32 *)[0]) return FALSE;
      q=data+h->records_offset;
      for (j=0;j<i;j++,q++)
        if ((q->kind==I386_MODULE_POINTER ||
            q->kind==I386_MODULE_NAMED_POINTER) &&
            lo<q->offset+4 && q->offset<lo+4) return FALSE;
      hi=lo+4;
    } else if (r->kind==I386_MODULE_EXPORT || r->kind==I386_MODULE_DATA_EXPORT) {
      if (lo>=h->code_size) return FALSE;
    } else if (r->kind==I386_MODULE_REL32 || r->kind==I386_MODULE_ADDRESS) {
      if (lo<1 || lo>h->code_size-4) return FALSE;
      if (r->kind==I386_MODULE_REL32) {
        if (data[32+lo-1]!=0xE8) return FALSE;
      } else if (data[32+lo-1]!=0x05) return FALSE;
      if ((data+32+lo)(U32 *)[0]) return FALSE;
      q=data+h->records_offset;
      for (j=0;j<i;j++,q++)
        if ((q->kind==I386_MODULE_REL32 || q->kind==I386_MODULE_ADDRESS) &&
            q->offset<lo+4 && lo<q->offset+4) return FALSE;
      lo--; hi=r->offset+4;
    } else return FALSE;
    in_data=FALSE;
    q=data+h->records_offset;
    for (j=0;j<h->record_count;j++,q++) {
      if (q->kind==I386_MODULE_DATA_RANGE) {
        if (r->kind==I386_MODULE_NAMED_POINTER) {
          if (lo>=q->offset && hi<=q->offset+q->name_offset) in_data=TRUE;
        } else if (lo<q->offset+q->name_offset && q->offset<hi) in_data=TRUE;
      }
    }
    if (r->kind==I386_MODULE_DATA_EXPORT ||
        r->kind==I386_MODULE_NAMED_POINTER) {
      if (!in_data) return FALSE;
    } else if (in_data) return FALSE;
next_record:
  }
  if (h->version==I386_MODULE_POINTER_VERSION) return pointers;
  if (h->version==I386_MODULE_NAMED_POINTER_VERSION) return named_pointers;
  return TRUE;
}
