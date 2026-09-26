//Publish complete private definitions and executable/static storage atomically.
#define I386_GVF_MODULE_PRIVATE 0x100000000
Bool I386FrontendCodeSpan(CPrsSymbolServices *symbols,U8 *address,I64 *bytes,I64 **data_start)
{
  CI386Frontend *frontend;
  CI386FrontendCode *code;
  if(!symbols || !address || !bytes || !data_start || !(frontend=symbols->context) ||
      symbols!=&frontend->symbols) return FALSE;
  for(code=frontend->codes;code;code=code->next)
    if(code->code==address) {
      *bytes=code->bytes; *data_start=&code->data_start;
      return TRUE;
    }
  return FALSE;
}
I64 I386FrontendCodeRelocs(CPrsSymbolServices *symbols,U8 *address,
  CI386FrontendRelocView *views,I64 capacity)
{
  CI386Frontend *frontend;
  CI386FrontendCode *code;
  CI386FrontendReloc *reloc;
  I64 count=0;
  if(!symbols || !address || capacity<0 || !(frontend=symbols->context) ||
      symbols!=&frontend->symbols) return -1;
  for(code=frontend->codes;code;code=code->next)
    if(code->code==address) {
      for(reloc=code->relocs;reloc;reloc=reloc->next)
        if(reloc->kind==I386_MODULE_REL32) count++;
      if(!views) {
        if(capacity) return -1;
        return count;
      }
      if(capacity<count) return -1;
      count=0;
      for(reloc=code->relocs;reloc;reloc=reloc->next) {
        if(reloc->kind==I386_MODULE_REL32) {
          views[count].offset=reloc->offset;
          views[count].name=reloc->name;
          count++;
        }
      }
      return count;
    }
  return -1;
}
Bool I386FrontendModuleType(CHashClass *type,I64 depth)
{//Every stored pointer must be discoverable from the published type layout.
  CMemberLst *member;
  I64 count;
  if(!type || depth>32 || type->size<1) return FALSE;
  if(type->ptr_stars_cnt) return type->size==4;
  if(type->base_class && !I386FrontendModuleType(type->base_class,depth+1)) return FALSE;
  if(!type->member_cnt)
    return type->raw_type>=RT_I8 && type->raw_type<=RT_U64 || type->raw_type==RT_F64;
  count=0;
  for(member=type->member_lst_and_root;member;member=member->next) {
    count++;
    if(count>8192) return FALSE;
    if(!(member->flags&(MLF_STATIC|MLF_FUN)))
      if(!member->member_class || member->offset<0 || member->size<1 ||
          member->offset>type->size-member->size ||
          member->dim.total_cnt<1 ||
          member->member_class->size>type->size/member->dim.total_cnt ||
          member->size!=member->member_class->size*member->dim.total_cnt ||
          !I386FrontendModuleType(member->member_class,depth+1)) return FALSE;
  }
  return count==type->member_cnt;
}
Bool I386FrontendPointerInSpan(CHashClass *type,U8 *data,I64 data_bytes,
  I64 offset,I64 depth,I64 start,I64 end)
{//Inspect typed initialized storage before retaining a literal pool.
  CMemberLst *member;
  I64 i,value;
  if(!type || depth>32 || offset<0 || type->size<1 ||
      offset>data_bytes-type->size) return FALSE;
  if(type->ptr_stars_cnt) {
    if(type->size!=4) return FALSE;
    value=(data+offset)(U32 *)[0];
    return value>=start && value<end;
  }
  if(type->base_class && I386FrontendPointerInSpan(type->base_class,data,
      data_bytes,offset,depth+1,start,end)) return TRUE;
  for(member=type->member_lst_and_root;member;member=member->next)
    if(!(member->flags&(MLF_STATIC|MLF_FUN)) && member->member_class &&
        member->offset>=0 && member->dim.total_cnt>0 &&
        member->dim.total_cnt<=8192 && member->member_class->size>0)
      for(i=0;i<member->dim.total_cnt;i++)
        if(I386FrontendPointerInSpan(member->member_class,data,data_bytes,
            offset+member->offset+i*member->member_class->size,
            depth+1,start,end)) return TRUE;
  return FALSE;
}
Bool I386FrontendGlobalUsesSpan(CHashGlblVar *global,I64 start,I64 end)
{
  I64 i;
  if(!global || !global->data_addr || !global->var_class ||
      global->dim.total_cnt<1 || global->dim.total_cnt>8192 ||
      global->var_class->size<1) return FALSE;
  for(i=0;i<global->dim.total_cnt;i++)
    if(I386FrontendPointerInSpan(global->var_class,global->data_addr,
        global->size,i*global->var_class->size,0,start,end)) return TRUE;
  return FALSE;
}
Bool I386FrontendGlobalDataOwned(CI386Frontend *frontend,CHashGlblVar *global)
{//A referenced literal begins inside a retained expression's code allocation.
  CI386FrontendCode *code;
  for(code=frontend->codes;code;code=code->next)
    if(code->data_start<code->bytes &&
        global->data_addr==code->code+code->data_start &&
        global->size==code->bytes-code->data_start)
      return I386ParserSize(frontend->heap,frontend->cc,code->code)>=code->bytes;
  return I386HeapSize(frontend->heap,global->data_addr)>=global->size;
}
I64 I386FrontendPointerTarget(I64 value,CHashGlblVar **globals,I64 count,
  I64 function_payload)
{
  CHashGlblVar *global;
  I64 i,base=function_payload,address;
  for(i=0;i<count;i++) {
    global=globals[i];
    if(!global || !global->data_addr || global->size<1) return -1;
    base=(base+7)&~7; address=(global->data_addr+0)(U64);
    if(value>=address && value-address<global->size) return base+value-address;
    if(global->size>0xFFFFFFF0-base) return -1;
    base+=global->size;
  }
  return -1;
}
U8 *I386FrontendPointerName(CI386Frontend *frontend,I64 value)
{//An external stored pointer needs one unambiguous native symbol name.
  CHashTable *table=frontend->table;
  CHash *entry;
  CHashFun *fun;
  CHashGlblVar *global;
  U8 *name=0;
  I64 i,hits=0;
  while(table) {
    for(i=0;i<=table->mask;i++)
      for(entry=table->body[i];entry;entry=entry->next) {
        if(entry->type&HTT_FUN) {
          fun=entry;
          if((fun->exe_addr+0)(U64)==value) { name=entry->str; hits++; }
        } else if(entry->type&HTT_GLBL_VAR) {
          global=entry;
          if(!(global->flags&(GVF_ALIAS|GVF_EXTERN|GVF_IMPORT)) &&
              (global->data_addr+0)(U64)==value) { name=entry->str; hits++; }
        }
      }
    if(table==frontend->table) table=frontend->parent;
    else table=0;
  }
  if(hits!=1 || !name) return 0;
  return name;
}
I64 I386FrontendPointerSites(CHashClass *type,U8 *data,I64 data_bytes,I64 offset,
  I64 depth,CHashGlblVar **globals,I64 global_count,I64 function_payload,
  I64 body_base,CI386ModuleRecord *records,CI386Frontend *frontend,
  I64 *string_bytes,U8 *strings)
{
  CMemberLst *member;
  CI386ModuleRecord *next_records;
  U8 *name;
  I64 i,k,count=0,sites,value,target,length;
  if(!type || depth>32 || offset<0 || type->size>data_bytes-offset) return -1;
  if(type->ptr_stars_cnt) {
    if(type->size!=4) return -1;
    value=(data+offset)(U32 *)[0];
    if(!value) return 0;
    target=I386FrontendPointerTarget(value,globals,global_count,function_payload);
    if(target<0) {
      name=I386FrontendPointerName(frontend,value);
      if(!name) return -1;
      length=StrLen(name);
      if(length<1 || length>255 || *string_bytes>0xFFFFFFFF-length-1) return -1;
    }
    if(records) {
      if(target>=0) records[0].kind=I386_MODULE_POINTER;
      else records[0].kind=I386_MODULE_NAMED_POINTER;
      records[0].offset=body_base+offset;
      if(target>=0) {
        records[0].name_offset=target; records[0].name_length=0;
      } else {
        records[0].name_offset=*string_bytes; records[0].name_length=length;
        for(k=0;k<=length;k++) strings[*string_bytes+k]=name[k];
      }
    }
    if(target<0) *string_bytes+=length+1;
    return 1;
  }
  if(type->base_class) {
    sites=I386FrontendPointerSites(type->base_class,data,data_bytes,offset,
      depth+1,globals,global_count,function_payload,body_base,records,
      frontend,string_bytes,strings);
    if(sites<0) return -1;
    count+=sites;
  }
  for(member=type->member_lst_and_root;member;member=member->next)
    if(!(member->flags&(MLF_STATIC|MLF_FUN)))
      for(i=0;i<member->dim.total_cnt;i++) {
        next_records=0; if(records) next_records=records+count;
        sites=I386FrontendPointerSites(member->member_class,data,data_bytes,
          offset+member->offset+i*member->member_class->size,depth+1,
          globals,global_count,function_payload,body_base,next_records,
          frontend,string_bytes,strings);
        if(sites<0 || count>0x0FFFFFFF-sites) return -1;
        count+=sites;
      }
  return count;
}
I64 I386FrontendGlobalPointers(CHashGlblVar *global,CHashGlblVar **globals,
  I64 global_count,I64 function_payload,I64 body_base,CI386ModuleRecord *records,
  CI386Frontend *frontend,I64 *string_bytes,U8 *strings)
{
  CI386ModuleRecord *next_records;
  I64 i,count=0,sites;
  for(i=0;i<global->dim.total_cnt;i++) {
    next_records=0; if(records) next_records=records+count;
    sites=I386FrontendPointerSites(global->var_class,global->data_addr,
      global->size,i*global->var_class->size,0,globals,global_count,
      function_payload,body_base,next_records,frontend,string_bytes,strings);
    if(sites<0 || count>0x0FFFFFFF-sites) return -1;
    count+=sites;
  }
  return count;
}
I64 I386FrontendModulePackData(CPrsSymbolServices *symbols,CHashFun **functions,
  I64 count,CHashGlblVar **globals,I64 global_count,U8 *output,I64 capacity)
{
  CI386Frontend *frontend;
  CI386FrontendCode *code;
  CI386FrontendReloc *reloc;
  CI386ModuleRecord *records,*record;
  CHashFun *fun;
  CHashGlblVar *global;
  CMemberLst *member;
  CI386FrontendStatic *static_ref;
  U8 *strings,*body;
  I64 i,j,k,m,base,payload=0,record_count=0,string_bytes=0,function_payload,pointers;
  I64 records_offset,strings_offset,total,pos=0,index=0,length;
  if(!symbols || !(frontend=symbols->context) || symbols!=&frontend->symbols ||
      !functions || count<1 || count>8192 || global_count<0 || global_count>8192 ||
      (global_count && !globals) || capacity<0) return 0;
  for(i=0;i<count;i++) {
    fun=functions[i];
    if(!fun || !fun->str || !fun->exe_addr || !(fun->type&HTT_FUN)) return 0;
    for(member=fun->member_lst_and_root;member;member=member->next)
      if(member->flags&MLF_STATIC) {
        for(static_ref=frontend->saved_vars;static_ref;static_ref=static_ref->next)
          if(static_ref->owner==fun && static_ref->member==member) break;
        if(!static_ref) return 0;
        for(m=0;m<global_count;m++) if(globals[m]==&static_ref->symbol) break;
        if(m==global_count) return 0;
      }
    length=StrLen(fun->str);
    if(length<1 || length>255 || string_bytes>0xFFFFFFFF-length-1) return 0;
    for(j=0;j<i;j++) if(!StrCmp(fun->str,functions[j]->str)) return 0;
    code=frontend->codes;
    while(code && code->code!=fun->exe_addr) code=code->next;
    if(!code || code->bytes<1 || code->data_start<1 ||
        code->data_start>code->bytes ||
        code->bytes>0xFFFFFFF0-payload) return 0;
    payload=(payload+7)&~7;
    if(code->bytes>0xFFFFFFF0-payload) return 0;
    payload+=code->bytes;
    record_count++; string_bytes+=length+1;
    if(code->data_start<code->bytes) record_count++;
    for(reloc=code->relocs;reloc;reloc=reloc->next) {
      length=StrLen(reloc->name);
      if(length<1 || length>255 || reloc->offset<1 ||
          reloc->offset>code->bytes-4 ||
          (reloc->kind!=I386_MODULE_REL32 && reloc->kind!=I386_MODULE_ADDRESS) ||
          (reloc->kind==I386_MODULE_REL32 && code->code[reloc->offset-1]!=0xE8) ||
          (reloc->kind==I386_MODULE_ADDRESS && code->code[reloc->offset-1]!=0x05) ||
          string_bytes>0xFFFFFFFF-length-1) return 0;
      record_count++; string_bytes+=length+1;
    }
    if(record_count>0x0FFFFFFF) return 0;
  }
  function_payload=payload;
  for(i=0;i<global_count;i++) {
    global=globals[i];
    if(!global || !global->str || !(global->type&HTT_GLBL_VAR) ||
        global->flags&(GVF_ALIAS|GVF_EXTERN|GVF_IMPORT) ||
        !global->data_addr || global->size<1 ||
        !I386FrontendGlobalDataOwned(frontend,global) ||
        !I386FrontendModuleType(global->var_class,0) ||
        global->dim.total_cnt<1 ||
        global->var_class->size>0xFFFFFFF0/global->dim.total_cnt ||
        global->size!=global->var_class->size*global->dim.total_cnt) return 0;
    length=StrLen(global->str);
    if(length<1 || length>255 ||
        !(global->flags&I386_GVF_MODULE_PRIVATE) &&
        string_bytes>0xFFFFFFFF-length-1) return 0;
    for(j=0;j<count;j++) if(!StrCmp(global->str,functions[j]->str)) return 0;
    for(j=0;j<i;j++) if(!StrCmp(global->str,globals[j]->str)) return 0;
    payload=(payload+7)&~7;
    m=2; if(global->flags&I386_GVF_MODULE_PRIVATE) m=1;
    if(global->size>0xFFFFFFF0-payload || record_count>0x0FFFFFFF-m) return 0;
    pointers=I386FrontendGlobalPointers(global,globals,global_count,
      function_payload,payload,0,frontend,&string_bytes,0);
    if(pointers<0 || record_count>0x0FFFFFFF-pointers-m) return 0;
    payload+=global->size; record_count+=pointers+m;
    if(m==2) string_bytes+=length+1;
  }
  payload=(payload+7)&~7;
  if(record_count>(0xFFFFFFFF-32-payload)/16) return 0;
  records_offset=32+payload;
  strings_offset=records_offset+record_count*16;
  if(string_bytes>0xFFFFFFFF-strings_offset) return 0;
  total=strings_offset+string_bytes;
  if(!output) {
    if(capacity) return 0;
    return total;
  }
  if(capacity<total) return 0;
  body=output+32; records=output+records_offset; strings=output+strings_offset;
  for(i=0;i<payload;i++) body[i]=0;
  string_bytes=0;
  for(i=0;i<count;i++) {
    fun=functions[i]; code=frontend->codes;
    while(code && code->code!=fun->exe_addr) code=code->next;
    base=(pos+7)&~7; pos=base+code->bytes;
    for(k=0;k<code->bytes;k++) body[base+k]=code->code[k];
    record=records+index++; record->kind=I386_MODULE_EXPORT; record->offset=base;
    record->name_offset=string_bytes; length=StrLen(fun->str); record->name_length=length;
    for(k=0;k<=length;k++) strings[string_bytes+k]=fun->str[k];
    string_bytes+=length+1;
    for(reloc=code->relocs;reloc;reloc=reloc->next) {
      record=records+index++; record->kind=reloc->kind;
      record->offset=base+reloc->offset; record->name_offset=string_bytes;
      length=StrLen(reloc->name); record->name_length=length;
      for(k=0;k<=length;k++) strings[string_bytes+k]=reloc->name[k];
      string_bytes+=length+1;
      (body+record->offset)(U32 *)[0]=0;
    }
    if(code->data_start<code->bytes) {
      record=records+index++; record->kind=I386_MODULE_DATA_RANGE;
      record->offset=base+code->data_start;
      record->name_offset=code->bytes-code->data_start;
      record->name_length=0;
    }
  }
  for(i=0;i<global_count;i++) {
    global=globals[i]; base=(pos+7)&~7; pos=base+global->size;
    for(k=0;k<global->size;k++) body[base+k]=global->data_addr[k];
    record=records+index++; record->kind=I386_MODULE_DATA_RANGE;
    record->offset=base; record->name_offset=global->size; record->name_length=0;
    if(!(global->flags&I386_GVF_MODULE_PRIVATE)) {
      record=records+index++; record->kind=I386_MODULE_DATA_EXPORT;
      record->offset=base; record->name_offset=string_bytes;
      length=StrLen(global->str); record->name_length=length;
      for(k=0;k<=length;k++) strings[string_bytes+k]=global->str[k];
      string_bytes+=length+1;
    }
    pointers=I386FrontendGlobalPointers(global,globals,global_count,
      function_payload,base,records+index,frontend,&string_bytes,strings);
    if(pointers<0) return 0;
    index+=pointers;
  }
  if(index!=record_count || string_bytes!=total-strings_offset) return 0;
  return I386ModulePackRaw(output,total,body,payload,records,record_count,
    strings,string_bytes);
}
I64 I386FrontendModulePack(CPrsSymbolServices *symbols,CHashFun **functions,
  I64 count,U8 *output,I64 capacity)
{
  return I386FrontendModulePackData(symbols,functions,count,0,0,output,capacity);
}
extern class CI386FrontendLiteral;
class CI386FrontendLiteral {
  CI386FrontendLiteral *next;
  CHashGlblVar symbol;
  U8 name[16];
};
Bool I386FrontendOwnsFunction(CI386Frontend *frontend,CHashFun *fun)
{
  CI386FrontendCode *code;
  if(!fun || !fun->exe_addr || fun->type&HTF_IMPORT) return FALSE;
  for(code=frontend->codes;code;code=code->next)
    if(code->code==fun->exe_addr) return TRUE;
  return FALSE;
}
I64 I386FrontendModulePackUnit(CPrsSymbolServices *symbols,U8 *output,I64 capacity)
{//Package every owned function/global definition in this private source unit.
  CI386Frontend *frontend;
  CHashTable *table;
  CHash *entry;
  CI386FrontendCode *code;
  CI386FrontendStatic *static_ref;
  CI386FrontendLiteral *literal=0,*literals=0,*next_literal;
  CHashFun **functions=0,*fun,*swap_fun;
  CHashGlblVar **globals=0,*global,*swap_global;
  U8 *hex="0123456789ABCDEF",*prefix="@literal/";
  I64 i,j,k,functions_count=0,globals_count=0,literal_slots=0;
  I64 fi=0,gi=0,original_globals,ordinal=0,bytes,start,result=0;
  if(!symbols || !(frontend=symbols->context) ||
      symbols!=&frontend->symbols || !(table=frontend->table) || capacity<0) return 0;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next) {
      if(entry->type&HTT_FUN) {
        fun=entry;
        if(I386FrontendOwnsFunction(frontend,fun)) functions_count++;
      } else if(entry->type&HTT_GLBL_VAR) {
        global=entry;
        if(global->data_addr && !(global->flags&(GVF_ALIAS|GVF_EXTERN|GVF_IMPORT)))
          globals_count++;
      }
    }
  for(static_ref=frontend->saved_vars;static_ref;static_ref=static_ref->next)
    globals_count++;
  for(code=frontend->codes;code;code=code->next)
    if(code->data_start<code->bytes) literal_slots++;
  if(functions_count<1 || functions_count>8192 || globals_count>8192 ||
      literal_slots>8192-globals_count) return 0;
  functions=I386HeapAlloc(frontend->heap,functions_count*sizeof(CHashFun *));
  if(globals_count+literal_slots)
    globals=I386HeapAlloc(frontend->heap,(globals_count+literal_slots)*sizeof(CHashGlblVar *));
  if(!functions || globals_count+literal_slots && !globals) goto done;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next) {
      if(entry->type&HTT_FUN) {
        fun=entry;
        if(I386FrontendOwnsFunction(frontend,fun)) functions[fi++]=fun;
      } else if(entry->type&HTT_GLBL_VAR) {
        global=entry;
        if(global->data_addr && !(global->flags&(GVF_ALIAS|GVF_EXTERN|GVF_IMPORT)))
          globals[gi++]=global;
      }
    }
  for(static_ref=frontend->saved_vars;static_ref;static_ref=static_ref->next)
    globals[gi++]=&static_ref->symbol;
  if(fi!=functions_count || gi!=globals_count) goto done;
  original_globals=gi;
  for(code=frontend->codes;code;code=code->next)
    if(code->data_start<code->bytes) {
      bytes=code->bytes-code->data_start;
      start=(code->code+code->data_start+0)(U64);
      for(j=0;j<original_globals;j++)
        if(I386FrontendGlobalUsesSpan(globals[j],start,start+bytes)) break;
      if(j<original_globals) {
        if(ordinal>8191) goto done;
        literal=I386HeapAlloc(frontend->heap,sizeof(CI386FrontendLiteral),TRUE);
        if(!literal) goto done;
        literal->next=literals; literals=literal;
        for(k=0;k<9;k++) literal->name[k]=prefix[k];
        for(k=0;k<4;k++) literal->name[9+k]=hex[(ordinal>>(12-4*k))&15];
        literal->name[13]=0; ordinal++;
        literal->symbol.type=HTT_GLBL_VAR;
        literal->symbol.flags=I386_GVF_MODULE_PRIVATE;
        literal->symbol.str=literal->name;
        literal->symbol.size=bytes;
        literal->symbol.var_class=frontend->expression.types[RT_U8];
        literal->symbol.dim.cnt=bytes;
        literal->symbol.dim.total_cnt=bytes;
        literal->symbol.data_addr=code->code+code->data_start;
        globals[gi++]=&literal->symbol;
      }
    }
  globals_count=gi;
  for(i=1;i<functions_count;i++) {
    swap_fun=functions[i]; j=i;
    while(j && StrCmp(functions[j-1]->str,swap_fun->str)>0) {
      functions[j]=functions[j-1]; j--;
    }
    functions[j]=swap_fun;
  }
  for(i=1;i<globals_count;i++) {
    swap_global=globals[i]; j=i;
    while(j && StrCmp(globals[j-1]->str,swap_global->str)>0) {
      globals[j]=globals[j-1]; j--;
    }
    globals[j]=swap_global;
  }
  result=I386FrontendModulePackData(symbols,functions,functions_count,
    globals,globals_count,output,capacity);
done:
  if(globals && !I386HeapFree(frontend->heap,globals)) return 0;
  if(functions && !I386HeapFree(frontend->heap,functions)) return 0;
  for(literal=literals;literal;literal=next_literal) {
    next_literal=literal->next;
    if(!I386HeapFree(frontend->heap,literal)) return 0;
  }
  return result;
}
U0 I386ProgramStorageVisit(CI386ClassTransfer *transfer,CI386TaskStorage *storage,U8 *allocation)
{
  if(!allocation) { transfer->ok=FALSE; return; }
  I386ClassTransferVisit(transfer,allocation);
  if(transfer->ok) {
    storage->allocations[storage->count].allocation=allocation;
    storage->allocations[storage->count++].owner=I386ParserRecord(transfer->owned,allocation)->owner;
  }
}
Bool I386FrontendPublish(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols)
{
  CI386CmpCtrl *owned=cc;
  CI386Frontend *frontend;
  CI386ClassTransfer transfer;
  CI386TaskSymbols *scope;
  CI386TaskStorage *storage=0,*retained;
  CI386ParserAllocation *record;
  CI386FrontendCode *code;
  CI386FrontendResident *binding;
  CI386FrontendCompletion *completion;
  CI386CompletionTransfer visit;
  CHashTable *source,*destination;
  CHashSrcSym *entry,*prior;
  CHashFun *fun;
  CHashGlblVar *global;
  CMemberLst *member;
  CSymbolRelease visitor;
  I64 capacity=0,i,j;
  Bool result=FALSE,found;
  U32 irq=I386IrqSave;
  transfer.records=0;
  if(!I386CmpCodeOwner(heap,cc) || !symbols || !(frontend=symbols->context) ||
      frontend->heap!=heap || frontend->cc!=cc || symbols!=&frontend->symbols ||
      !owned->task || !(scope=I386TaskSymbolsValid(owned->task)) || scope->heap!=heap ||
      frontend->fixups || cc->error_cnt || cc->lex_prs_stk || cc->htc.next || cc->htc.fun ||
      owned->code_next!=&owned->code_next) goto done;
  source=frontend->table; destination=scope->table;
  if(cc->htc.glbl_hash_table!=source || cc->htc.hash_table_lst!=source ||
      source==destination || frontend->parent!=destination ||
      source->next!=destination && (!frontend->defines || source->next!=frontend->defines) ||
      !I386ParserRecord(owned,source) || I386HeapSize(heap,source)!=sizeof(CHashTable) ||
      !I386HashTableValid(heap,destination) || destination->locked_flags || source->locked_flags ||
      source->mask<0 || source->mask>=0x1FFFFFFF || (source->mask+1)&source->mask ||
      !I386ParserRecord(owned,source->body) ||
      I386HeapSize(heap,source->body)!=(source->mask+1)*sizeof(CHash *)) goto done;
  if(frontend->defines) {
    if(frontend->defines!=owned->private_defines || !I386HashTableValid(heap,frontend->defines) ||
        source->next!=frontend->defines || frontend->defines->next!=destination ||
        frontend->defines->mask!=31 || frontend->defines->locked_flags ||
        cc->htc.define_hash_table!=frontend->defines) goto done;
    for(i=0;i<=frontend->defines->mask;i++)
      for(entry=frontend->defines->body[i];entry;entry=entry->next) {
        if(!(entry->type&HTT_DEFINE_STR) || !entry->str ||
            I386HeapSize(heap,entry)!=sizeof(CHashDefineStr) ||
            I386ClassNamePresent(source,entry->str)) goto done;
        //Macro redefinition keeps ordinary lookup order, but a header must not
        //hide an existing class, function or other non-macro declaration.
        for(j=0;j<=destination->mask;j++)
          for(prior=destination->body[j];prior;prior=prior->next)
            if(!StrCmp(prior->str,entry->str) && !(prior->type&HTT_DEFINE_STR)) goto done;
      }
  }
  for(completion=frontend->completions;completion;completion=completion->next)
    if(!I386CompletionValid(frontend,completion)) goto done;
  for(binding=frontend->residents;binding;binding=binding->next)
    if(!I386FrontendResidentValid(frontend,binding)) goto done;
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next) capacity++;
  if(capacity<1 || capacity>0xFFFFFFD) goto done;
  transfer.records=I386HeapAlloc(heap,capacity*sizeof(CI386ParserAllocation *),FALSE);
  storage=I386HeapAlloc(heap,sizeof(CI386TaskStorage)+(capacity-1)*sizeof(CI386StoredAllocation),TRUE);
  if(!transfer.records || !storage) goto done;
  transfer.owned=owned; transfer.source=source; transfer.count=0;
  transfer.capacity=capacity; transfer.ok=TRUE;
  visit.transfer=&transfer; visit.completion=0;
  visitor.context=&visit; visitor.release=&I386CompletionVisit;
  for(i=0;i<=source->mask;i++)
    for(entry=source->body[i];entry;entry=entry->next) {
      binding=I386FrontendResidentFind(frontend,entry);
      completion=I386CompletionFind(frontend,entry);
      visit.completion=completion;
      if(!entry->str || !I386ParserRecord(owned,entry) || entry->ie_lst) goto done;
      if(binding) {
        if(I386FrontendResidentCollision(destination,entry->str,binding->export)) goto done;
      } else if(!(entry->type&HTT_HELP_FILE) && !completion && I386ClassNamePresent(destination,entry->str)) goto done;
      for(j=0;j<=i;j++)
        for(prior=source->body[j];prior && prior!=entry;prior=prior->next)
          if(!StrCmp(prior->str,entry->str) &&
              !((prior->type&HTT_HELP_FILE) && (entry->type&HTT_HELP_FILE))) goto done;
      if(entry->type&HTT_FUN) {
        fun=entry;
        if(I386HeapSize(heap,fun)!=sizeof(CHashFun)*(PTR_STARS_NUM+1) ||
            Bt(&fun->flags,Cf_EXTERN) || fun->ext_lst || fun->type&HTF_IMPORT ||
            !I386ProgramTypeReady(fun->return_class)) goto done;
        found=FALSE;
        for(code=frontend->codes;code;code=code->next) if(code->code==fun->exe_addr) found=TRUE;
        if(Bt(&fun->flags,Ff_INTERNAL)) {
          if(found || binding || !I386IntrinsicValid(fun)) goto done;
        } else if(!found && !binding) goto done;
      } else if(entry->type&HTT_CLASS) {
        if(I386HeapSize(heap,entry)!=sizeof(CHashClass)*(PTR_STARS_NUM+1) ||
            !I386ProgramClassReady(entry)) goto done;
      } else if(entry->type&HTT_GLBL_VAR) {
        global=entry;
        if(I386HeapSize(heap,global)!=sizeof(CHashGlblVar) || global->type&(HTF_IMPORT|HTF_UNRESOLVED) ||
            !I386ProgramTypeReady(global->var_class) ||
            global->size<0 || !(global->flags&GVF_ALIAS) &&
            (!global->data_addr || I386HeapSize(heap,global->data_addr)<global->size)) goto done;
      } else if(entry->type&HTT_HELP_FILE) {
        if(I386HeapSize(heap,entry)!=sizeof(CHashSrcSym) || !(entry->type&HTF_PUBLIC) ||
            entry->type&(HTF_IMPORT|HTF_UNRESOLVED) || !entry->src_link) goto done;
      } else if(!(entry->type&HTT_DEFINE_STR)) goto done;
      SymbolHashVisit(&visitor,entry);
      if(!transfer.ok) goto done;
      if(entry->type&(HTT_CLASS|HTT_FUN))
        for(member=entry(CHashClass *)->member_lst_and_root;member;member=member->next) {
          if(!I386ProgramTypeReady(member->member_class)) goto done;
          if(member->flags&MLF_STATIC) {
            I386ProgramStorageVisit(&transfer,storage,member->static_data);
            if(!transfer.ok) goto done;
          }
        }
    }
  //Live command literal pools may be referenced by published data. Retain every
  //remaining registered output, not only named function entry points.
  for(code=frontend->codes;code;code=code->next) {
    if(!I386ParserRecord(owned,code) || I386HeapSize(heap,code)!=sizeof(CI386FrontendCode) ||
        code->bytes<1 || code->data_start<1 || code->data_start>code->bytes ||
        I386ParserSize(heap,cc,code->code)!=code->bytes) goto done;
    I386ProgramStorageVisit(&transfer,storage,code->code);
    if(!transfer.ok) goto done;
  }
  if(storage->count) {
    retained=I386HeapAlloc(heap,sizeof(CI386TaskStorage)+(storage->count-1)*sizeof(CI386StoredAllocation),FALSE);
    if(!retained) goto done;
    retained->next=0; retained->count=storage->count;
    for(i=0;i<storage->count;i++) {
      retained->allocations[i].allocation=storage->allocations[i].allocation;
      retained->allocations[i].owner=storage->allocations[i].owner;
    }
    I386HeapFree(heap,storage); storage=retained;
  }
  //Validation and allocation are finished. No fallible work remains in the move.
  if(frontend->completions)
    for(i=0;i<=source->mask;i++)
      for(entry=source->body[i];entry;entry=entry->next) I386CompletionRebind(frontend,entry);
  for(i=0;i<transfer.count;i++) {
    record=transfer.records[i];
    record->last->next=record->next; record->next->last=record->last;
    I386HeapFree(heap,record);
  }
  if(storage->count) {
    storage->next=scope->storage; scope->storage=storage; storage=0;
  }
  frontend->codes=0; frontend->residents=0;
  for(i=0;i<=source->mask;i++) {
    //Repeated help-file entries retain original newest-first lookup order.
    prior=0;
    while(entry=source->body[i]) {
      source->body[i]=entry->next; entry->next=prior; prior=entry;
    }
    while(entry=prior) {
      prior=entry->next; entry->next=0;
      completion=I386CompletionFind(frontend,entry);
      if(completion) I386CompletionCommit(frontend,completion);
      else HashAdd(entry,destination);
    }
  }
  frontend->completions=0;
  if(frontend->defines)
    for(i=0;i<=frontend->defines->mask;i++) {
      //HashAdd prepends. Reverse first so repeated definitions keep the newest
      //replacement first after moving into the task's table.
      prior=0;
      while(entry=frontend->defines->body[i]) {
        frontend->defines->body[i]=entry->next;
        entry->next=prior; prior=entry;
      }
      while(entry=prior) {
        prior=entry->next; HashAdd(entry,destination);
      }
    }
  result=TRUE;
done:
  if(storage) I386HeapFree(heap,storage);
  if(transfer.records) I386HeapFree(heap,transfer.records);
  I386IrqRestore(irq); return result;
}
