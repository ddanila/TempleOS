//Allocation-free module loading shared by the cross host and native i386 kernel.
#include "/Kernel/I386/ModuleCheck.HC"
#include "/Kernel/I386/ModuleBind.HH"

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

I64 I386BoundSymbol(U8 **modules,I64 count,U8 *name,I64 kind,I64 *matches,
  CI386ModuleBinding *bindings,I64 binding_count,I64 load_address)
{
  I64 i,result=I386FindSymbol(modules,count,name,kind,matches);
  for (i=0;i<binding_count;i++)
    if ((!kind || bindings[i].kind==kind) && I386NameEqual(bindings[i].name,name)) {
      (*matches)++; result=(bindings[i].address+0)(U64)-load_address;
    }
  return result;
}
public I64 I386LoadBoundAt(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count,I64 load_address)
{//Return loaded size, or zero on failure. NULL image/zero capacity queries size.
 //Validate all references before writing. Caller owns buffers and execution lifetime.
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  I64 i,j,k,n,total=8,matches,target,entry,base,patch,name_size,address;
  Bool pointers=FALSE;
  if (!modules || !sizes || !entry_name || count<=0 || count>U32_MAX/8 ||
      capacity<0 || capacity>U32_MAX || load_address< -1 || load_address>U32_MAX || binding_count<0 ||
      binding_count>U32_MAX/sizeof(CI386ModuleBinding) || (binding_count && (!bindings || (bindings+0)(U64)>
        0x100000000-binding_count*sizeof(CI386ModuleBinding)))) return 0;
  for (i=0;i<binding_count;i++) {
    if (!bindings[i].name || !bindings[i].address ||
        (bindings[i].kind!=I386_MODULE_EXPORT && bindings[i].kind!=I386_MODULE_DATA_EXPORT)) return 0;
    for (n=0;n<=255;n++) if (!bindings[i].name[n]) break;
    if (!n || n>255) return 0;
    for (j=0;j<i;j++) if (I386NameEqual(bindings[i].name,bindings[j].name)) return 0;
  }
  for (name_size=0;name_size<=255;name_size++)
    if (!entry_name[name_size]) break;
  if (!name_size || name_size>255) return 0;
  for (i=0;i<count;i++) {
    if (!I386ModuleValid(modules[i],sizes[i])) return 0;
    h=modules[i]; total+=h->code_size;
    if (total>U32_MAX) return 0;
  }
  address=load_address; if(address<0) address=(image+0)(U64);
  if(load_address>=0 && address>0x100000000-total) return 0;
  entry=I386FindSymbol(modules,count,entry_name,I386_MODULE_EXPORT,&matches);
  if (matches!=1) return 0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      if (r->kind==I386_MODULE_DATA_RANGE) goto validate_next;
      if (r->kind==I386_MODULE_POINTER) { pointers=TRUE; goto validate_next; }
      target=I386BoundSymbol(modules,count,modules[i]+r->name_offset,0,&matches,
        bindings,binding_count,address);
      if (matches!=1) return 0;
      if (r->kind==I386_MODULE_NAMED_POINTER) {
        pointers=TRUE;
        if (address+target<1 || address+target>U32_MAX) return 0;
      }
      if (r->kind==I386_MODULE_REL32) {
        I386BoundSymbol(modules,count,modules[i]+r->name_offset,I386_MODULE_EXPORT,&matches,bindings,binding_count,address);
        if (matches!=1) return 0;
      }
validate_next:
    }
  }
  if (!image) {
    if (capacity) return 0;
    return total;
  }
  if ((pointers || binding_count) && address>0x100000000-total) return 0;
  if (capacity<total ||
      sizeof(U8 *)==4 && (image+0)(U64)>0x100000000-total ||
      (image+0)(U64)>0xFFFFFFFFFFFFFFFF-total) return 0;
  if (I386BuffersOverlap(image,total,modules,count*sizeof(U8 *)) ||
      I386BuffersOverlap(image,total,sizes,count*8) ||
      I386BuffersOverlap(image,total,entry_name,name_size+1)) return 0;
  for (i=0;i<count;i++)
    if (I386BuffersOverlap(image,total,modules[i],sizes[i])) return 0;
  if (binding_count) {
    if (I386BuffersOverlap(image,total,bindings,binding_count*sizeof(CI386ModuleBinding))) return 0;
    for (k=0;k<binding_count;k++) {
      n=0; while (bindings[k].name[n]) n++;
      if (I386BuffersOverlap(image,total,bindings[k].name,n+1) ||
          ((bindings[k].address+0)(U64)>=(image+0)(U64) &&
           (bindings[k].address+0)(U64)-(image+0)(U64)<total)) return 0;
    }
  }
  //No writes above this point, including on malformed or unresolved input.
  image[0]=0xE9; (image+1)(U32 *)[0]=entry-5;
  image[5]=0; image[6]=0; image[7]=0;
  base=8;
  for (i=0;i<count;i++) {
    h=modules[i];
    for (j=0;j<h->code_size;j++) image[base+j]=modules[i][32+j];
    r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++) {
      if (r->kind==I386_MODULE_POINTER)
        (image+base+r->offset)(U32 *)[0]=address+base+r->name_offset;
      else if (r->kind==I386_MODULE_NAMED_POINTER) {
        target=I386BoundSymbol(modules,count,modules[i]+r->name_offset,0,
          &matches,bindings,binding_count,address);
        (image+base+r->offset)(U32 *)[0]=address+target;
      }
      else if (r->kind==I386_MODULE_REL32 || r->kind==I386_MODULE_ADDRESS) {
        target=I386BoundSymbol(modules,count,modules[i]+r->name_offset,0,&matches,bindings,binding_count,address);
        patch=base+r->offset;
        (image+patch)(U32 *)[0]=target-(patch+4);
      }
    }
    base+=h->code_size;
  }
  return total;
}

public I64 I386LoadBoundInto(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//Runtime images use their actual destination address.
  return I386LoadBoundAt(modules,sizes,count,image,capacity,entry_name,bindings,binding_count,-1);
}

public I64 I386LoadInto(U8 **modules,I64 *sizes,I64 count,U8 *image,
  I64 capacity,U8 *entry_name)
{//Existing API keeps module-only resolution and calling convention.
  return I386LoadBoundInto(modules,sizes,count,image,capacity,entry_name,0,0);
}
