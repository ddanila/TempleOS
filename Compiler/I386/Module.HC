//Bootstrap module writer/linker runs on the x86-64 HolyC compiler host.
#include "/Kernel/I386/Module.HH"

#include "/Kernel/I386/ModuleLoad.HC"
#include "/Kernel/I386/ModulePackCore.HC"

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
  CAOTAbsAddr *absolute;
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
    if (aot->heap_glbls || aot->aot_U8s<=0) throw('Compiler');
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
    for(absolute=aot->abss;absolute;absolute=absolute->next) {
      if(absolute->type!=AAT_ADD_U32 || absolute->rip<0 || absolute->rip>aot->aot_U8s-4)
        throw('Compiler');
      count++;
    }
    payload=(aot->aot_U8s+7)&~7;
    total=32+payload+count*16+strings;
    if (total>U32_MAX) throw('Compiler');
    h=data=CAlloc(total);
    h->magic=I386_MODULE_MAGIC; h->version=I386_MODULE_VERSION;
    if(aot->abss) h->version=I386_MODULE_POINTER_VERSION;
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
      r->name_offset=pos-h->strings_offset; r->name_length=StrLen(ie->str);
      MemCpy(data+pos,ie->str,r->name_length+1); pos+=r->name_length+1;
record_done:
    }
    for(absolute=aot->abss;absolute;absolute=absolute->next,r++) {
      r->kind=I386_MODULE_POINTER; r->offset=absolute->rip;
      r->name_offset=(data+32+r->offset)(U32 *)[0];
      (data+32+r->offset)(U32 *)[0]=0;
    }
    if (I386ModulePackRaw(data,total,aot->buf,aot->aot_U8s,
        data+h->records_offset,count,data+h->strings_offset,strings)!=total) throw('Compiler');
    *size=total;
  } catch {
    Free(data); data=NULL;
    if (error_cnt) *error_cnt=1;
    Fs->catch_except=TRUE;
  }
  I386AOTDel(aot);
  return data;
}

public U8 *I386Link(U8 **modules,I64 *sizes,I64 count,I64 *size,U8 *entry_name="Main",I64 load_address=-1)
{//Host allocation wrapper around the shared native loader.
  U8 *image=NULL;
  I64 required,i,j;
  CI386ModuleHeader *h;
  CI386ModuleRecord *record;
  if (!size) return NULL;
  *size=0;
  required=I386LoadBoundAt(modules,sizes,count,NULL,0,entry_name,0,0,load_address);
  if (!required) return NULL;
  //A flat cross-built image needs its future address, never the host heap address.
  if(load_address<0)
    for(i=0;i<count;i++) {
      h=modules[i]; record=modules[i]+h->records_offset;
      for(j=0;j<h->record_count;j++,record++)
        if(record->kind==I386_MODULE_POINTER) return NULL;
    }
  try {
    image=CAlloc(required);
    if (I386LoadBoundAt(modules,sizes,count,image,required,entry_name,0,0,load_address)!=required) {
      Free(image); image=NULL;
    }
  } catch {
    Free(image); image=NULL; Fs->catch_except=TRUE;
  }
  if (image) *size=required;
  return image;
}
