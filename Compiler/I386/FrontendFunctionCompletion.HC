//Complete a published extern without exposing a partially parsed replacement.
Bool I386FrontendPublishedExtern(CI386Frontend *state,CHashFun *function)
{
  return function && function->str && function->type&HTT_FUN &&
    !(function->type&HTF_IMPORT) && Bt(&function->flags,Cf_EXTERN) &&
    function->exe_addr==&I386FrontendUndefined &&
    I386HeapSize(state->heap,function)==sizeof(CHashFun)*(PTR_STARS_NUM+1) &&
    HashFind(function->str,state->parent,HTT_FUN)==function;
}
Bool I386FunctionCompletionTargetValid(CI386Frontend *state,CHashFun *published)
{
  CI386CmpCtrl *owned=state->cc;
  CI386TaskSymbols *scope=owned->task->symbol_state;
  //Ordinary child declarations shadow inherited names. Explicit mutation of an
  //ancestor task's namespace needs a cross-task storage transfer, not child code.
  for(scope=scope->parent;scope;scope=scope->parent)
    if(state->parent==scope->table)return FALSE;
  return I386FrontendPublishedExtern(state,published) &&
    I386FrontendSingleFind(state,published->str,state->parent,HTT_FUN)==published &&
    !published->import_name && !published->ie_lst && !published->dbg_info &&
    I386ProgramTypeReady(published->return_class) &&
    I386TaskExternFunctionValid(state->heap,published);
}
CHashFun *I386FrontendStageFunction(CI386Frontend *state,CHashFun *published)
{
  CI386FrontendCompletion *completion;
  CHashFun *staged;
  if(!I386FunctionCompletionTargetValid(state,published))I386FrontendUnavailable(state);
  completion=I386FrontendAlloc(state,sizeof(CI386FrontendCompletion),TRUE,FALSE);
  staged=I386FrontendFunNew(state);
  staged->str=published->str;staged->type=published->type;
  staged->flags=published->flags;staged->use_cnt=published->use_cnt;
  staged->exe_addr=&I386FrontendUndefined;
  completion->published=published;completion->staged=staged;
  completion->next=state->completions;state->completions=completion;
  I386FrontendHashAdd(state,staged,state->table);
  return staged;
}
Bool I386FunctionUsageMatches(CI386Frontend *state,CI386TaskExternUsage *usage,CHashFun *function)
{
  CMemberLst *member=function->member_lst_and_root;
  I64 i;
  if(usage->argument_count!=function->arg_cnt ||
      I386FrontendClassView(state,usage->result_type)!=I386FrontendClassView(state,function->return_class) ||
      usage->flags!=(function->flags&(FSG_FUN_FLAGS1|1<<Ff_DOT_DOT_DOT)))return FALSE;
  for(i=0;i<function->arg_cnt;i++) {
    if(!member || I386FrontendClassView(state,member->member_class)!=
        I386FrontendClassView(state,usage->arguments[i]))return FALSE;
    member=member->next;
  }
  return TRUE;
}
Bool I386FunctionDebugValid(CI386Frontend *state,CHashFun *function)
{//Only parser-owned line records for this output may enter a published symbol.
  CDbgInfo *debug=function->dbg_info;
  CI386FrontendCode *code;
  I64 lines,i,start,end;
  if(!debug)return TRUE;
  if(!I386ParserRecord(state->cc,debug) ||
      I386HeapSize(state->heap,debug)<offset(CDbgInfo.body)+2*sizeof(U32) ||
      debug->max_line<debug->min_line)return FALSE;
  lines=debug->max_line-debug->min_line+1;
  if(lines>(0x7FFFFFFF-offset(CDbgInfo.body))/sizeof(U32)-1 ||
      I386HeapSize(state->heap,debug)!=offset(CDbgInfo.body)+(lines+1)*sizeof(U32))return FALSE;
  for(code=state->codes;code && code->code!=function->exe_addr;code=code->next);
  if(!code || code->bytes<1)return FALSE;
  start=(code->code+0)(U64);end=start+code->bytes;
  if(end>0xFFFFFFFF || debug->body[0]!=start || debug->body[lines]!=end)return FALSE;
  for(i=0;i<lines;i++)
    if(debug->body[i] && !(start<=debug->body[i]<=end))return FALSE;
  return TRUE;
}
Bool I386FunctionCompletionValid(CI386Frontend *state,CI386FrontendCompletion *completion)
{
  CHashFun *staged=completion->staged,*published=completion->published;
  CI386TaskExternUsage *usage;
  CI386FrontendDeclaration *declaration=I386FrontendDeclarationFind(state,staged);
  if(!I386ParserRecord(state->cc,completion) ||
      I386HeapSize(state->heap,completion)!=sizeof(CI386FrontendCompletion) ||
      !I386FunctionCompletionTargetValid(state,published) ||
      !I386ParserRecord(state->cc,staged) ||
      I386HeapSize(state->heap,staged)!=sizeof(CHashFun)*(PTR_STARS_NUM+1) ||
      staged->str!=published->str || staged->import_name || !I386FunctionDebugValid(state,staged) ||
      !declaration || !declaration->complete ||
      I386FrontendSingleFind(state,staged->str,state->table,HTT_FUN)!=staged)return FALSE;
  for(usage=published->ext_lst;usage;usage=usage->next)
    if(!I386FunctionUsageMatches(state,usage,staged))return FALSE;
  return TRUE;
}
class CI386RetiredSignature {
  CI386Heap *heap;
  CI386TaskStorage *storage;
  I64 count,capacity;
  Bool ok;
};
U0 I386FunctionRetiredVisit(U8 *context,U8 *allocation)
{
  CI386RetiredSignature *visit=context;
  I64 i;
  if(!allocation || !visit->ok)return;
  if(visit->count>=visit->capacity || I386HeapSize(visit->heap,allocation)<1) {
    visit->ok=FALSE;return;
  }
  if(visit->storage) {
    for(i=0;i<visit->count;i++)
      if(visit->storage->allocations[i].allocation==allocation) {visit->ok=FALSE;return;}
    visit->storage->allocations[visit->count].allocation=allocation;
    visit->storage->allocations[visit->count].owner=0;
  }
  visit->count++;
}
Bool I386FunctionCompletionPrepare(CI386Frontend *state,CI386FrontendCompletion *completion)
{//Old default strings can be embedded in already compiled callers. Retain them.
  CHashFun *published=completion->published;
  CI386CmpCtrl *owned=state->cc;
  CI386TaskSymbols *scope=owned->task->symbol_state,*candidate;
  CI386RetiredSignature visit;
  CSymbolRelease visitor;
  CHash *entry;
  I64 i,capacity;
  if(!(published->type&HTT_FUN))return TRUE;
  completion->retired_scope=scope;
  for(candidate=scope;candidate;candidate=candidate->parent)
    for(i=0;i<=candidate->table->mask;i++)
      for(entry=candidate->table->body[i];entry;entry=entry->next)
        if(entry==published)completion->retired_scope=candidate;
  visit.heap=state->heap;visit.storage=0;visit.count=0;visit.capacity=state->heap->allocations;visit.ok=TRUE;
  visitor.context=&visit;visitor.release=&I386FunctionRetiredVisit;
  SymbolMemberLstVisit(&visitor,published->member_lst_and_root);
  I386FunctionRetiredVisit(&visit,published->src_link);
  I386FunctionRetiredVisit(&visit,published->idx);
  if(!visit.ok)return FALSE;
  capacity=visit.count;
  if(!capacity)return TRUE;
  visit.storage=I386HeapAlloc(state->heap,sizeof(CI386TaskStorage)+
    (capacity-1)*sizeof(CI386StoredAllocation),TRUE);
  if(!visit.storage)return FALSE;
  completion->retired_storage=visit.storage;
  visit.storage->count=capacity;visit.count=0;visit.capacity=capacity;
  SymbolMemberLstVisit(&visitor,published->member_lst_and_root);
  I386FunctionRetiredVisit(&visit,published->src_link);
  I386FunctionRetiredVisit(&visit,published->idx);
  return visit.ok && visit.count==capacity;
}
U0 I386FunctionRetainMetadata(CI386Frontend *state,U8 *allocation)
{//Detach an active parent's ownership record without freeing the old payload.
  CI386CmpCtrl *owned=state->cc;
  CI386ParserAllocation *record;
  CI386Task *task=owned->task;
  CCmpCtrl *cc=state->cc;
  while(cc) {
    if(record=I386ParserRecord(cc,allocation)) {
      record->last->next=record->next;record->next->last=record->last;
      I386HeapFree(state->heap,record);return;
    }
    if(!task || cc->last==&task->next_cc || !I386CmpActiveValid(cc))break;
    cc=cc->last;
  }
}
U0 I386FunctionCompletionCommit(CI386Frontend *state,CI386FrontendCompletion *completion)
{
  CHashFun *published=completion->published,*staged=completion->staged;
  CI386TaskExternUsage *pending=published->ext_lst;
  CI386TaskStorage *storage=completion->retired_storage;
  U8 *destination=published,*source=staged;
  I64 i;
  if(storage) {
    for(i=0;i<storage->count;i++)I386FunctionRetainMetadata(state,storage->allocations[i].allocation);
    storage->next=completion->retired_scope->storage;
    completion->retired_scope->storage=storage;completion->retired_storage=0;
  }
  published->src_link=staged->src_link;published->idx=staged->idx;
  published->dbg_info=staged->dbg_info;
  published->type=staged->type;published->use_cnt=staged->use_cnt;
  for(i=offset(CHashClass.size);i<sizeof(CHashFun)*(PTR_STARS_NUM+1);i++)destination[i]=source[i];
  if(published->last_in_member_lst==&staged->member_lst_and_root)
    published->last_in_member_lst=&published->member_lst_and_root;
  published->ext_lst=pending;
}
CHashFun *I386CompletionFunction(CI386Frontend *state,CHashFun *function)
{
  CI386FrontendCompletion *completion=I386CompletionFind(state,function);
  if(completion && completion->published->type&HTT_FUN)return completion->published;
  return function;
}

Bool I386FrontendPublishedFunction(CI386Frontend *state,CHashFun *function)
{
  CHashTable *table;
  CHash *entry;
  I64 i;
  if(!function || I386HeapSize(state->heap,function)!=sizeof(CHashFun)*(PTR_STARS_NUM+1) ||
      !(function->type&HTT_FUN))return FALSE;
  for(table=state->parent;table;table=table->next)
    for(i=0;i<=table->mask;i++)
      for(entry=table->body[i];entry;entry=entry->next)
        if(entry==function)return TRUE;
  return FALSE;
}
Bool I386FrontendFixupsReady(CI386Frontend *state)
{
  CI386FrontendFixup *fixup;
  CI386FrontendCode *code;
  CHashFun *function,*canonical;
  I64 count=0;
  for(fixup=state->fixups;fixup;fixup=fixup->pending_next) {
    if(++count>state->heap->allocations || !I386ParserRecord(state->cc,fixup) ||
        fixup->signature!=I386_TASK_EXTERN_MAGIC || fixup->scope || fixup->next ||
        fixup->argument_count<0 || fixup->argument_count>4095 ||
        I386HeapSize(state->heap,fixup)!=sizeof(CI386FrontendFixup)+
          fixup->argument_count*sizeof(CHashClass *))return FALSE;
    function=fixup->function;
    if(!function || !I386FunctionUsageMatches(state,fixup,function) ||
        !I386ParserRecord(state->cc,function) &&
        !I386FrontendPublishedFunction(state,function))return FALSE;
    for(code=state->codes;code && code->code!=fixup->code;code=code->next);
    if(!code || code->bytes!=fixup->code_bytes || fixup->offset<1 ||
        fixup->offset>code->bytes-4 ||
        fixup->rip!=(code->code+fixup->offset+0)(U64))return FALSE;
    if(fixup->indirect) {
      canonical=I386CompletionFunction(state,function);
      if(fixup->offset<2 || code->code[fixup->offset-2]!=0xFF ||
          code->code[fixup->offset-1]!=0x15 ||
          fixup->undefined_address!=&I386FrontendUndefined ||
          (code->code+fixup->offset)(U32 *)[0]!=
            (&canonical->exe_addr+0)(U64))return FALSE;
    } else if(code->code[fixup->offset-1]!=0xE8)return FALSE;
  }
  return TRUE;
}
U0 I386FrontendFixupsCommit(CI386Frontend *state,CI386Frontend *parent,CI386TaskSymbols *scope)
{
  CI386FrontendFixup *fixup,*next;
  I64 i;
  for(fixup=state->fixups;fixup;fixup=next) {
    next=fixup->pending_next;
    fixup->function=I386CompletionFunction(state,fixup->function);
    fixup->result_type=I386CompletionCanonical(state,fixup->result_type);
    for(i=0;i<fixup->argument_count;i++)
      fixup->arguments[i]=I386CompletionCanonical(state,fixup->arguments[i]);
    if(!fixup->indirect && !Bt(&fixup->function->flags,Cf_EXTERN)) {
      (fixup->code+fixup->offset)(U32 *)[0]=(fixup->function->exe_addr+0)(U64)-
        (fixup->code+fixup->offset+4)(U64);
      fixup->pending_next=0;
    } else if(parent) {
      fixup->pending_next=parent->fixups;parent->fixups=fixup;
    } else {
      fixup->scope=scope;
      fixup->pending_next=scope->pending_externs;scope->pending_externs=fixup;
      fixup->next=fixup->function->ext_lst;fixup->function->ext_lst=fixup;
    }
  }
  state->fixups=0;
}
