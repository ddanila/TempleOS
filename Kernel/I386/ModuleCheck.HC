//Shared module validation: compile unchanged for the host or i386 target.
#include "/Kernel/I386/Module.HH"

public Bool I386ModuleValid(U8 *data,I64 size)
{
  CI386ModuleHeader *h=data;
  CI386ModuleRecord *r;
  I64 i,j,end;
  if (!data || size<32 || size>U32_MAX) return FALSE;
  if (h->magic!=I386_MODULE_MAGIC || h->version!=I386_MODULE_VERSION ||
      h->cpu!=3 || h->pointer_size!=4 || h->abi!=I386_MODULE_ABI ||
      h->total_size!=size || !h->code_size || h->code_size&7) return FALSE;
  if (h->code_size>size-32) return FALSE;
  if (h->records_offset!=32+h->code_size) return FALSE;
  if (h->record_count>(size-h->records_offset)/16) return FALSE;
  end=h->records_offset+h->record_count*16;
  if (end!=h->strings_offset || end>size) return FALSE;
  r=data+h->records_offset;
  for (i=0;i<h->record_count;i++,r++) {
    if (!r->name_length || r->name_length>255 || r->name_offset<end ||
        r->name_offset>size-r->name_length-1) return FALSE;
    if (data[r->name_offset+r->name_length]) return FALSE;
    for (j=0;j<r->name_length;j++)
      if (!data[r->name_offset+j]) return FALSE;
    if (r->kind==I386_MODULE_EXPORT) {
      if (r->offset>=h->code_size) return FALSE;
    } else if (r->kind==I386_MODULE_REL32) {
      if (r->offset<1 || r->offset>h->code_size-4) return FALSE;
      if (data[32+r->offset-1]!=0xE8) return FALSE;
      if ((data+32+r->offset)(U32 *)[0]) return FALSE;
      for (j=0;j<i;j++)
        if ((data+h->records_offset)(CI386ModuleRecord *)[j].kind==I386_MODULE_REL32 &&
            (data+h->records_offset)(CI386ModuleRecord *)[j].offset==r->offset)
          return FALSE;
    } else return FALSE;
  }
  return TRUE;
}

