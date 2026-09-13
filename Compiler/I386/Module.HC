//Bootstrap module writer/linker runs on the x86-64 HolyC compiler host.
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
  I64 count=0,strings=0,total,pos;
  if (!size) return NULL;
  *size=0;
  aot=CmpI386Buf(source,error_cnt);
  if (!aot) return NULL;
  try {
    if (aot->abss || aot->heap_glbls || aot->aot_U8s<=0) throw('Compiler');
    for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
      if (ie->type!=IET_REL32_EXPORT && ie->type!=IET_REL_I32) throw('Compiler');
      if (!ie->str || !StrLen(ie->str) || StrLen(ie->str)>255) throw('Compiler');
      if (ie->rip<0 || ie->rip>U32_MAX) throw('Compiler');
      count++; strings+=StrLen(ie->str)+1;
    }
    total=32+aot->aot_U8s+count*16+strings;
    if (total>U32_MAX) throw('Compiler');
    h=data=CAlloc(total);
    h->magic=I386_MODULE_MAGIC; h->version=I386_MODULE_VERSION;
    h->cpu=3; h->pointer_size=4; h->abi=I386_MODULE_ABI;
    h->total_size=total; h->code_size=aot->aot_U8s; h->record_count=count;
    h->records_offset=32+h->code_size; h->strings_offset=h->records_offset+count*16;
    MemCpy(data+32,aot->buf,aot->aot_U8s);
    r=data+h->records_offset; pos=h->strings_offset;
    for (ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next,r++) {
      if (ie->type==IET_REL32_EXPORT) r->kind=I386_MODULE_EXPORT;
      else r->kind=I386_MODULE_REL32;
      r->offset=ie->rip; r->name_offset=pos; r->name_length=StrLen(ie->str);
      MemCpy(data+pos,ie->str,r->name_length+1); pos+=r->name_length+1;
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

I64 I386ModuleSymbol(U8 **modules,I64 count,I64 *bases,U8 *name,I64 *matches)
{
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  I64 i,j,result=0;
  *matches=0;
  for (i=0;i<count;i++) {
    h=modules[i]; r=modules[i]+h->records_offset;
    for (j=0;j<h->record_count;j++,r++)
      if (r->kind==I386_MODULE_EXPORT && !StrCmp(modules[i]+r->name_offset,name)) {
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
    target=I386ModuleSymbol(modules,count,bases,entry_name,&matches);
    if (matches!=1) throw('Compiler');
    image=CAlloc(total);
    image[0]=0xE9; (image+1)(U32 *)[0]=target-5;
    for (i=0;i<count;i++) {
      h=modules[i]; MemCpy(image+bases[i],modules[i]+32,h->code_size);
      r=modules[i]+h->records_offset;
      for (j=0;j<h->record_count;j++,r++) {
        target=I386ModuleSymbol(modules,count,bases,modules[i]+r->name_offset,&matches);
        if (matches!=1) throw('Compiler');
        if (r->kind==I386_MODULE_REL32) {
          patch=bases[i]+r->offset;
          (image+patch)(U32 *)[0]=target-(patch+4);
        }
      }
    }
    *size=total;
  } catch {
    Free(image); image=NULL; Fs->catch_except=TRUE;
  }
  Free(bases);
  return image;
}
