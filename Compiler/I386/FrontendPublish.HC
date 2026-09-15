//Publish complete private definitions and executable/static storage atomically.
U0 I386ProgramStorageVisit(CI386ClassTransfer *transfer,CI386TaskStorage *storage,U8 *allocation)
{
  if(!allocation) { transfer->ok=FALSE; return; }
  I386ClassTransferVisit(transfer,allocation);
  if(transfer->ok) storage->allocations[storage->count++]=allocation;
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
      cc->error_cnt || cc->lex_prs_stk || cc->htc.next || cc->htc.fun ||
      owned->code_next!=&owned->code_next) goto done;
  source=frontend->table; destination=scope->table;
  if(cc->htc.glbl_hash_table!=source || cc->htc.hash_table_lst!=source ||
      source==destination || frontend->parent!=destination || source->next!=destination ||
      !I386ParserRecord(owned,source) || I386HeapSize(heap,source)!=sizeof(CHashTable) ||
      !I386HashTableValid(heap,destination) || destination->locked_flags || source->locked_flags ||
      source->mask<0 || source->mask>=0x1FFFFFFF || (source->mask+1)&source->mask ||
      !I386ParserRecord(owned,source->body) ||
      I386HeapSize(heap,source->body)!=(source->mask+1)*sizeof(CHash *)) goto done;
  for(record=owned->parser_next;record!=&owned->parser_next;record=record->next) capacity++;
  if(capacity<1 || capacity>0x1FFFFFFD) goto done;
  transfer.records=I386HeapAlloc(heap,capacity*sizeof(CI386ParserAllocation *),FALSE);
  storage=I386HeapAlloc(heap,sizeof(CI386TaskStorage)+(capacity-1)*sizeof(U8 *),TRUE);
  if(!transfer.records || !storage) goto done;
  transfer.owned=owned; transfer.source=source; transfer.count=0;
  transfer.capacity=capacity; transfer.ok=TRUE;
  visitor.context=&transfer; visitor.release=&I386ClassTransferVisit;
  for(i=0;i<=source->mask;i++)
    for(entry=source->body[i];entry;entry=entry->next) {
      if(!entry->str || !I386ParserRecord(owned,entry) || entry->ie_lst ||
          I386ClassNamePresent(destination,entry->str)) goto done;
      for(j=0;j<=i;j++)
        for(prior=source->body[j];prior && prior!=entry;prior=prior->next)
          if(!StrCmp(prior->str,entry->str)) goto done;
      if(entry->type&HTT_FUN) {
        fun=entry;
        if(I386HeapSize(heap,fun)!=sizeof(CHashFun)*(PTR_STARS_NUM+1) ||
            Bt(&fun->flags,Cf_EXTERN) || fun->ext_lst || fun->type&HTF_IMPORT) goto done;
        found=FALSE;
        for(code=frontend->codes;code;code=code->next) if(code->code==fun->exe_addr) found=TRUE;
        if(!found) goto done;
      } else if(entry->type&HTT_CLASS) {
        if(I386HeapSize(heap,entry)!=sizeof(CHashClass)*(PTR_STARS_NUM+1) ||
            Bt(&entry(CHashClass *)->flags,Cf_EXTERN)) goto done;
      } else if(entry->type&HTT_GLBL_VAR) {
        global=entry;
        if(I386HeapSize(heap,global)!=sizeof(CHashGlblVar) || global->type&(HTF_IMPORT|HTF_UNRESOLVED) ||
            global->size<0 || !(global->flags&GVF_ALIAS) &&
            (!global->data_addr || I386HeapSize(heap,global->data_addr)<global->size)) goto done;
      } else if(!(entry->type&HTT_DEFINE_STR)) goto done;
      SymbolHashVisit(&visitor,entry);
      if(!transfer.ok) goto done;
      if(entry->type&(HTT_CLASS|HTT_FUN))
        for(member=entry(CHashClass *)->member_lst_and_root;member;member=member->next)
          if(member->flags&MLF_STATIC) {
            I386ProgramStorageVisit(&transfer,storage,member->static_data);
            if(!transfer.ok) goto done;
          }
    }
  //Live command literal pools may be referenced by published data. Retain every
  //remaining registered output, not only named function entry points.
  for(code=frontend->codes;code;code=code->next) {
    if(!I386ParserRecord(owned,code) || I386HeapSize(heap,code)!=sizeof(CI386FrontendCode) ||
        code->bytes<1 || I386HeapSize(heap,code->code)!=code->bytes) goto done;
    I386ProgramStorageVisit(&transfer,storage,code->code);
    if(!transfer.ok) goto done;
  }
  if(storage->count) {
    retained=I386HeapAlloc(heap,sizeof(CI386TaskStorage)+(storage->count-1)*sizeof(U8 *),FALSE);
    if(!retained) goto done;
    retained->next=0; retained->count=storage->count;
    for(i=0;i<storage->count;i++) retained->allocations[i]=storage->allocations[i];
    I386HeapFree(heap,storage); storage=retained;
  }
  //Validation and allocation are finished. No fallible work remains in the move.
  for(i=0;i<transfer.count;i++) {
    record=transfer.records[i];
    record->last->next=record->next; record->next->last=record->last;
    I386HeapFree(heap,record);
  }
  if(storage->count) {
    storage->next=scope->storage; scope->storage=storage; storage=0;
  }
  frontend->codes=0;
  for(i=0;i<=source->mask;i++)
    while(entry=source->body[i]) {
      source->body[i]=entry->next; entry->next=0;
      HashAdd(entry,destination);
    }
  result=TRUE;
done:
  if(storage) I386HeapFree(heap,storage);
  if(transfer.records) I386HeapFree(heap,transfer.records);
  I386IrqRestore(irq); return result;
}
