//Bootstrap module writer/linker runs on the x86-64 HolyC compiler host.
#include "/Kernel/I386/Module.HH"

#include "/Kernel/I386/ModuleCheck.HC"

U0 I386AOTDel(CAOT *aot)
{
  CAOTImportExport *ie,*next;
  CAOTHeapGlbl *hg,*hg_next;
  if (!aot) return;
  for (ie=aot->next_ie;ie!=&aot->next_ie;ie=next) {
    next=ie->next; Free(ie->str); Free(ie->src_link); Free(ie);
  }
  for (hg=aot->heap_glbls;hg;hg=hg_next) {
    hg_next=hg->next; LinkedLstDel(hg->references); Free(hg->str); Free(hg);
  }
  LinkedLstDel(aot->abss); Free(aot->buf); Free(aot);
}

public U8 *CmpI386Module(U8 *source,I64 *size,I64 *error_cnt=NULL)
{
  CAOT *aot;
  CAOTImportExport *ie;
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  U8 *data=NULL;
  I64 count=0,strings=0,total,pos,payload;
  if (!size) return NULL;
  *size=0;
  aot=CmpI386Buf(source,error_cnt);
  if (!aot) return NULL;
  try {
    if (aot->abss || aot->heap_glbls || aot->aot_U8s<=0) throw('Compiler');
    for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
      if (ie->type!=IET_REL32_EXPORT && ie->type!=IET_REL_I32 &&
          ie->type!=IET_I386_REL32_ADDR && ie->type!=IET_I386_DATA) throw('Compiler');
      if (ie->type==IET_I386_DATA) {
        if (ie->flags<=0 || ie->flags>U32_MAX) throw('Compiler');
      } else {
        if (!ie->str || !StrLen(ie->str) || StrLen(ie->str)>255) throw('Compiler');
        strings+=StrLen(ie->str)+1;
      }
      if (ie->rip<0 || ie->rip>U32_MAX) throw('Compiler');
      count++;
    }
    payload=(aot->aot_U8s+7)&~7;
    total=32+payload+count*16+strings;
    if (total>U32_MAX) throw('Compiler');
    h=data=CAlloc(total);
    h->magic=I386_MODULE_MAGIC; h->version=I386_MODULE_VERSION;
    h->cpu=3; h->pointer_size=4; h->abi=I386_MODULE_ABI;
    h->total_size=total; h->code_size=payload; h->record_count=count;
    h->records_offset=32+h->code_size; h->strings_offset=h->records_offset+count*16;
    MemCpy(data+32,aot->buf,aot->aot_U8s);
    r=data+h->records_offset; pos=h->strings_offset;
    for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next,r++) {
      r->offset=ie->rip;
      if (ie->type==IET_I386_DATA) {
        r->kind=I386_MODULE_DATA_RANGE; r->name_offset=ie->flags;
        goto record_done;
      }
      if (ie->type==IET_REL32_EXPORT) {
        if (ie->flags&IEF_I386_DATA_EXPORT) r->kind=I386_MODULE_DATA_EXPORT;
        else r->kind=I386_MODULE_EXPORT;
      } else if (ie->type==IET_I386_REL32_ADDR) r->kind=I386_MODULE_ADDRESS;
      else r->kind=I386_MODULE_REL32;
      r->name_offset=pos; r->name_length=StrLen(ie->str);
      MemCpy(data+pos,ie->str,r->name_length+1); pos+=r->name_length+1;
record_done:
    }
    if (!I386ModuleValid(data,total)) throw('Compiler');
    *size=total;
  } catch {
    Free(data); data=NULL;
    if (error_cnt) *error_cnt=1;
    Fs->catch_except=TRUE;
  }
  I386AOTDel(aot);
  return data;
}

I64 I386ModuleSymbol(U8 **modules,I64 count,I64 *bases,U8 *name,I64 *matches,I64 kind=0)
{
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  I64 i,j,result=0;
  *matches=0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++)
      if ((r->kind==I386_MODULE_EXPORT || r->kind==I386_MODULE_DATA_EXPORT) &&
          (!kind || kind==r->kind) && !StrCmp(modules[i]+r->name_offset,name)) {
        (*matches)++; result=bases[i]+r->offset;
      }
  }
  return result;
}

public U8 *I386Link(U8 **modules,I64 *sizes,I64 count,I64 *size,U8 *entry_name="Main")
{//Link immutable T32M inputs to a flat bootstrap image with an entry trampoline.
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  U8 *image=NULL;
  I64 *bases=NULL,i,j,total=8,matches,target,patch;
  if (!size) return NULL;
  *size=0;
  if (!modules || !sizes || count<=0 || count>U32_MAX/8 || !entry_name) return NULL;
  try {
    bases=CAlloc(count*8);
    for (i=0;i<count;i++) {
      if (!I386ModuleValid(modules[i],sizes[i])) throw('Compiler');
      h=modules[i]; bases[i]=total; total+=h->code_size;
      if (total>U32_MAX) throw('Compiler');
    }
    target=I386ModuleSymbol(modules,count,bases,entry_name,&matches,I386_MODULE_EXPORT);
    if (matches!=1) throw('Compiler');
    image=CAlloc(total);
    image[0]=0xE9; (image+1)(U32 *)[0]=target-5;
    for (i=0;i<count;i++) {
      h=modules[i]; MemCpy(image+bases[i],modules[i]+32,h->code_size);
      r=modules[i]+h->records_offset;
      for (j=0;j<h->record_count;j++,r++) {
        if (r->kind==I386_MODULE_DATA_RANGE) goto link_next_record;
        target=I386ModuleSymbol(modules,count,bases,modules[i]+r->name_offset,&matches);
        if (matches!=1) throw('Compiler');
        if (r->kind==I386_MODULE_REL32) {
          target=I386ModuleSymbol(modules,count,bases,modules[i]+r->name_offset,
            &matches,I386_MODULE_EXPORT);
          if (matches!=1) throw('Compiler');
        }
        if (r->kind==I386_MODULE_REL32 || r->kind==I386_MODULE_ADDRESS) {
          patch=bases[i]+r->offset;
          (image+patch)(U32 *)[0]=target-(patch+4);
        }
link_next_record:
      }
    }
    *size=total;
  } catch {
    Free(image); image=NULL; Fs->catch_except=TRUE;
  }
  Free(bases);
  return image;
}
