//Publish complete private definitions and executable/static storage atomically.
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
      for(reloc=code->relocs;reloc;reloc=reloc->next) count++;
      if(!views) {
        if(capacity) return -1;
        return count;
      }
      if(capacity<count) return -1;
      count=0;
      for(reloc=code->relocs;reloc;reloc=reloc->next) {
        views[count].offset=reloc->offset;
        views[count].name=reloc->name;
        count++;
      }
      return count;
    }
  return -1;
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
