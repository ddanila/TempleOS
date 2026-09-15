//Completion changes one published identity only after a complete input commits.
U0 ProbeCompletions(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage,*storage;
  CCmpCtrl *cc,*nested;
  CPrsSymbolServices *symbols,*nested_symbols;
  CHashSrcSym *roots[16],*entry;
  CHashClass *opaque,*holder,*other,*derived,*box,*staged;
  CHashFun *function,*callback;
  CMemberLst *member,*indexed;
  U8 *source,*name,*old_index,*fill,*block,*next;
  I64 kind,i,count,used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  I64 before_used,before_allocations,size;
  Bool recovered,accepted;
  U32 flags=GetRFlags;
  for(kind=0;kind<14;kind++) {
    KernelLog("COMPLETION START "); KernelHex(kind); KernelLog("\n");
    source="extern class Opaque;class Holder{Opaque *p;I64i value;};";
    if(kind==5) source="extern class Opaque;extern class Other;class Holder{Opaque *p;I64i value;};";
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Forward.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols || ProbeProgramRead(probe,heap,cc,symbols)) KernelStop;
    opaque=ProbeSymbolFind(0,"Opaque",cc->htc.glbl_hash_table,HTT_CLASS);
    holder=ProbeSymbolFind(0,"Holder",cc->htc.glbl_hash_table,HTT_CLASS);
    other=0; count=0;
    for(i=0;i<=cc->htc.glbl_hash_table->mask;i++)
      for(entry=cc->htc.glbl_hash_table->body[i];entry;entry=entry->next) roots[count++]=entry;
    if(!opaque || !holder || !probe->compiler->publish(heap,cc,symbols) ||
        !probe->compiler->control_unwind(task,outer)) KernelStop;
    if(kind==5) other=ProbeSymbolFind(0,"Other",task->hash_table,HTT_CLASS);
    name=opaque->str; old_index=opaque->idx; member=holder->member_lst_and_root;
    if(kind==13) opaque->idx="Foreign";
    source="class Opaque{I64i value;};";
    if(kind==1) source="class Opaque{I64i value;};Unknown bad;";
    if(kind==5) source="class Opaque{Other *p;I64i value;};class Other{Opaque *p;};";
    if(kind==6) source="extern Opaque *CompletionId(Opaque *p);"
      "Opaque *CompletionCaller(Opaque *p){return CompletionId(p);}"
      "class Opaque{I64i value;};class CompletionDerived:Opaque{Opaque *p;};"
      "class CompletionBox{Opaque *(*callback)(Opaque *p);};"
      "Opaque *CompletionId(Opaque *p){Opaque *local=p;return local;}"
      "I64i CompletionUse(Holder *h){return h->p->value;}"
      "U8i *CompletionName(U8i *p,U8i *s=lastclass){return s;}"
      "Opaque CompletionData;Holder CompletionHolder;"
      "CompletionHolder.p=&CompletionData;CompletionData.value=42;";
    if(kind==8) source="Opaque early;class Opaque{I64i value;};early.value=42;";
    if(kind==9) source="class Early:Opaque{I64i value;};class Opaque{I64i value;};";
    if(kind==10) source="extern class Local;Local early;class Local{I64i value;};early.value=42;";
    if(kind==11) source="class Early{Opaque value;};class Opaque{I64i value;};";
    if(kind==12) source="class Opaque{};";
    if(kind==7) source="extern class Opaque;class Opaque{I64i value;};";
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Completion.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    recovered=FALSE;
    try { ProbeProgramRead(probe,heap,cc,symbols); }
    catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; recovered=TRUE; } }
    if(recovered!=(kind==1 || 8<=kind<=11 || kind==13) || !Bt(&opaque->flags,Cf_EXTERN) || opaque->size ||
        opaque->member_lst_and_root || opaque->str!=name || member->member_class!=opaque+1) KernelStop;
    if(kind==13) opaque->idx=old_index;
    staged=ProbeSymbolFind(0,"Opaque",cc->htc.glbl_hash_table,HTT_CLASS);
    if(kind<8 && (!staged || staged==opaque || staged->str!=name)) KernelStop;
    KernelLog("COMPLETION STAGED\n");
    if(kind==2) {
      //Only ordinary class metadata can move into a completed class root.
      staged->dbg_info=staged;
      if(probe->compiler->publish(heap,cc,symbols) || !Bt(&opaque->flags,Cf_EXTERN)) KernelStop;
      staged->dbg_info=0;
    }
    if(kind==1 || kind==2 || 8<=kind<=11 || kind==13) {
      if(kind!=2 && probe->compiler->publish(heap,cc,symbols)) KernelStop;
      if(!probe->compiler->control_unwind(task,outer) || !Bt(&opaque->flags,Cf_EXTERN) ||
          opaque->size || opaque->member_lst_and_root) KernelStop;
      cc=probe->files->control_new("class Opaque{I64i value;};",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Retry.HC");
      if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
      symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
      if(!symbols || ProbeProgramRead(probe,heap,cc,symbols)) KernelStop;
    }
    if(kind==3) {
      fill=0;
      for(size=0x10000;size>=8;size>>=1)
        while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
      before_used=heap->used; before_allocations=heap->allocations;
      if(probe->compiler->publish(heap,cc,symbols) || heap->used!=before_used ||
          heap->allocations!=before_allocations || !Bt(&opaque->flags,Cf_EXTERN) || opaque->size) KernelStop;
      while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    }
    if(kind==4) {
      //A nested successful input wins. The outer stale completion must not replace it.
      nested=probe->files->control_new("class Opaque{I64i value,second;};",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Nested.HC");
      if(!nested || !probe->compiler->control_enter(heap,nested,0,0)) KernelStop;
      nested_symbols=probe->compiler->frontend(heap,nested,probe->internal_types,probe->disk_include);
      if(!nested_symbols || ProbeProgramRead(probe,heap,nested,nested_symbols) ||
          !probe->compiler->publish(heap,nested,nested_symbols) ||
          !probe->compiler->control_unwind(task,cc)) KernelStop;
    }
    //Match CommandInput: collect retired nodes after the final executed command.
    if(!probe->compiler->code_discard(heap,cc,0,0)) KernelStop;
    accepted=probe->compiler->publish(heap,cc,symbols);
    KernelLog("COMPLETION PUBLISHED "); KernelHex(accepted); KernelLog("\n");
    if(accepted!=(kind!=4)) KernelStop;
    if(accepted)
      for(i=0;i<=task->hash_table->mask;i++)
        for(entry=task->hash_table->body[i];entry;entry=entry->next)
          if(!StrCmp(entry->str,"CompletionDerived") || !StrCmp(entry->str,"CompletionBox") ||
              !StrCmp(entry->str,"CompletionId") || !StrCmp(entry->str,"CompletionCaller") || !StrCmp(entry->str,"CompletionUse") ||
              !StrCmp(entry->str,"CompletionName") || !StrCmp(entry->str,"CompletionData") ||
              !StrCmp(entry->str,"CompletionHolder")) {
            if(count>=16) KernelStop;
            roots[count++]=entry;
          }
    if(!probe->compiler->control_unwind(task,outer) || Bt(&opaque->flags,Cf_EXTERN) ||
        opaque->str!=name || member->member_class!=opaque+1 ||
        ProbeSymbolFind(0,"Opaque",task->hash_table,HTT_CLASS)!=opaque) KernelStop;
    KernelLog("COMPLETION IDENTITY\n");
    size=8; if(kind==4) size=16; if(kind==5) size=12; if(kind==12) size=0;
    if(opaque->size!=size || ProbeProgramUse(probe,heap,outer,"sizeof(Opaque);")!=size ||
        kind!=12 && ProbeProgramUse(probe,heap,outer,"Opaque x;x.value=42;Holder h;h.p=&x;h.p->value;")!=42) KernelStop;
    if(kind==12 && opaque->last_in_member_lst!=&opaque->member_lst_and_root) KernelStop;
    if(kind==5) {
      if(!other || other->size!=4 || opaque->member_lst_and_root->member_class!=other+1 ||
          other->member_lst_and_root->member_class!=opaque+1 ||
          ProbeProgramUse(probe,heap,outer,"Opaque x;Other y;x.p=&y;y.p=&x;x.value=42;x.p->p->value;")!=42) KernelStop;
    }
    KernelLog("COMPLETION USED\n");
    if(kind==6) {
      derived=ProbeSymbolFind(0,"CompletionDerived",task->hash_table,HTT_CLASS);
      box=ProbeSymbolFind(0,"CompletionBox",task->hash_table,HTT_CLASS);
      function=ProbeSymbolFind(0,"CompletionId",task->hash_table,HTT_FUN);
      if(!box || !function) KernelStop;
      callback=box->member_lst_and_root->fun_ptr;
      callback-=callback->ptr_stars_cnt;
      indexed=function->member_class_base_root;
      while(indexed && indexed->member_class_base!=opaque) {
        if(opaque<indexed->member_class_base) indexed=indexed->left_class_base;
        else indexed=indexed->right_class_base;
      }
      KernelLog("COMPLETION GRAPH "); KernelHex((indexed+0)(U64)); KernelLog("\n");
      if(!derived || derived->base_class!=opaque ||
          function->return_class!=opaque+1 || function->member_lst_and_root->member_class!=opaque+1 ||
          !indexed ||
          callback->return_class!=opaque+1 || callback->member_lst_and_root->member_class!=opaque+1 ||
          ProbeProgramUse(probe,heap,outer,"CompletionUse(&CompletionHolder);")!=42 ||
          ProbeProgramUse(probe,heap,outer,"CompletionId(&CompletionData)->value;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"CompletionCaller(&CompletionData)->value;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"CompletionName(&CompletionData);")!=(name+0)(U64) ||
          ProbeProgramUse(probe,heap,outer,"CompletionBox b;b.callback=&CompletionId;b.callback(&CompletionData)->value;")!=42) KernelStop;
    }
    for(i=0;i<count;i++)
      if(!ProbePublishedRemove(task->hash_table,roots[i]) || !I386HashDel(heap,roots[i])) KernelStop;
    while(scope->storage!=old_storage) {
      storage=scope->storage; scope->storage=storage->next;
      for(i=0;i<storage->count;i++) if(!I386HeapFree(heap,storage->allocations[i])) KernelStop;
      if(!I386HeapFree(heap,storage)) KernelStop;
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("COMPLETION CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
