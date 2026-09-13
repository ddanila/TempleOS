//Allocation-free module loading shared by the cross host and native i386 kernel.
#include "/Kernel/I386/ModuleCheck.HC"

Bool I386NameEqual(U8 *a,U8 *b)
{
  while (*a && *a==*b) { a++; b++; }
  return *a==*b;
}

Bool I386BuffersOverlap(U8 *a,I64 an,U8 *b,I64 bn)
{
  U64 av=(a+0)(U64),bv=(b+0)(U64);
  if (av<bv) return bv-av<an;
  return av-bv<bn;
}

I64 I386FindSymbol(U8 **modules,I64 count,U8 *name,I64 kind,I64 *matches)
{
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  I64 i,j,base=8,result=0;
  *matches=0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++)
      if ((r->kind==I386_MODULE_EXPORT || r->kind==I386_MODULE_DATA_EXPORT) &&
          (!kind || kind==r->kind) && I386NameEqual(modules[i]+r->name_offset,name)) {
        (*matches)++; result=base+r->offset;
      }
    base+=h->code_size;
  }
  return result;
}

public I64 I386LoadInto(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name)
{//Return loaded size, or zero on failure. NULL image/zero capacity queries size.
 //Validate all references before writing. Caller owns buffers and execution lifetime.
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  I64 i,j,total=8,matches,target,entry,base,patch,name_size;
  if (!modules || !sizes || !entry_name || count<=0 || count>U32_MAX/8 ||
      capacity<0 || capacity>U32_MAX) return 0;
  for (name_size=0;name_size<=255;name_size++)
    if (!entry_name[name_size]) break;
  if (!name_size || name_size>255) return 0;
  for (i=0;i<count;i++) {
    if (!I386ModuleValid(modules[i],sizes[i])) return 0;
    h=modules[i]; total+=h->code_size;
    if (total>U32_MAX) return 0;
  }
  entry=I386FindSymbol(modules,count,entry_name,I386_MODULE_EXPORT,&matches);
  if (matches!=1) return 0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      if (r->kind==I386_MODULE_DATA_RANGE) goto validate_next;
      I386FindSymbol(modules,count,modules[i]+r->name_offset,0,&matches);
      if (matches!=1) return 0;
      if (r->kind==I386_MODULE_REL32) {
        I386FindSymbol(modules,count,modules[i]+r->name_offset,I386_MODULE_EXPORT,&matches);
        if (matches!=1) return 0;
      }
validate_next:
    }
  }
  if (!image) {
    if (capacity) return 0;
    return total;
  }
  if (capacity<total || (image+total)(U64)<(image+0)(U64)) return 0;
  if (I386BuffersOverlap(image,total,modules,count*sizeof(U8 *)) ||
      I386BuffersOverlap(image,total,sizes,count*8) ||
      I386BuffersOverlap(image,total,entry_name,name_size+1)) return 0;
  for (i=0;i<count;i++)
    if (I386BuffersOverlap(image,total,modules[i],sizes[i])) return 0;
  //No writes above this point, including on malformed or unresolved input.
  image[0]=0xE9; (image+1)(U32 *)[0]=entry-5;
  image[5]=0; image[6]=0; image[7]=0;
  base=8;
  for (i=0;i<count;i++) {
    h=modules[i];
    for (j=0;j<h->code_size;j++) image[base+j]=modules[i][32+j];
    r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      if (r->kind==I386_MODULE_REL32 || r->kind==I386_MODULE_ADDRESS) {
        target=I386FindSymbol(modules,count,modules[i]+r->name_offset,0,&matches);
        patch=base+r->offset;
        (image+patch)(U32 *)[0]=target-(patch+4);
      }
    }
    base+=h->code_size;
  }
  return total;
}
