//Definitions must survive control destruction and later failed input.
U8 *ProbeProgramRead(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *cc,
  CPrsSymbolServices *symbols,Bool execute=TRUE)
{
  CPrsDeclarationServices *d=symbols->declarations;
  CPrsExpressionServices *e=d->expression;
  U8 *code,*last=0;
  I64 type,count=0;
  e->report=&ProbeExpressionReport; d->types->report=&ProbeExpressionReport;
  e->lex(e->context,cc);
  while(cc->token!=TK_EOF) {
    if(++count>32) KernelStop;
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) {
      if(execute) d->execute(d->context,code);
      if(cc->flags&CCF_HAS_MISC_DATA) last=code;
      else d->release(d->context,code);
    }
  }
  return last;
}
I64 ProbeProgramUse(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer,U8 *source)
{
  CCmpCtrl *cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/ProgramUse.HC");
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *d;
  CPrsExpressionServices *e;
  U8 *code;
  I64 type,value=0;
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
  if(!symbols) KernelStop;
  d=symbols->declarations; e=d->expression;
  e->lex(e->context,cc);
  while(cc->token!=TK_EOF) {
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) { value=d->execute(d->context,code); d->release(d->context,code); }
  }
  if(!probe->compiler->control_unwind(I386TaskSelf,outer)) KernelStop;
  return value;
}
U0 ProbePrograms(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage,*storage;
  CCmpCtrl *cc,*failed;
  CPrsSymbolServices *symbols,*failed_symbols;
  CHashSrcSym *roots[16],*entry;
  CHashFun *fun,*static_fun;
  CHashGlblVar *alias;
  CHashClass *collision;
  CHashTable *source_table;
  CMemberLst *member;
  U8 *source,*old_index,*old_code,*old_static,*literal,*block,*fill,*next,*name;
  I64 kind,count,i,j,before_used,before_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 irq,flags=GetRFlags;
  Bool result,recovered;
  for(kind=0;kind<12;kind++) {
    source="I64i DurableData=20;"
      "class DurablePair{I64i a,b;};DurablePair DurablePairData={20,22};"
      "I64i DurableAdd(I64i x=22){return DurableData+x;}"
      "I64i DurableNext(){static I64i n=40;return ++n;}"
      "I64i DurableFact(I64i n){if(n<2)return 1;return n*DurableFact(n-1);}"
      "I64i DurableDefault(U8i *s=\"xy\"){return s[1];}"
      "U8i *DurableText(){return \"hello\";}"
      "U8i *DurableLiteral=0;DurableLiteral=(\"hello\");"
      "U8i *DurableInit=\"abc\";"
      "I64i DurableString(){static U8i *p=\"def\";return ++p[0];}"
      "U8i DurableZero;";
    if(kind==7) source="extern I64i Future();";
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Program.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    KernelLog("PROGRAM START "); KernelHex(kind); KernelLog("\n");
    literal=ProbeProgramRead(probe,heap,cc,symbols);
    if(kind!=7) {
      //Model a system-symbol alias after address resolution. The native system
      //symbol linker is separate; exercise publication without reading address 0.
      alias=ProbeSymbolFind(0,"DurableZero",cc->htc.glbl_hash_table,HTT_GLBL_VAR);
      if(!alias || !alias->data_addr) KernelStop;
      symbols->declarations->release(symbols->declarations->context,alias->data_addr);
      alias->data_addr=0; alias->flags|=GVF_ALIAS;
    }
    source_table=cc->htc.glbl_hash_table; count=0; collision=0; fill=0;
    for(i=0;i<=source_table->mask;i++)
      for(entry=source_table->body[i];entry;entry=entry->next) {
        if(count>=16) KernelStop;
        roots[count++]=entry;
      }
    fun=ProbeSymbolFind(0,"DurableAdd",source_table,HTT_FUN);
    static_fun=ProbeSymbolFind(0,"DurableNext",source_table,HTT_FUN);
    member=0; old_index=0; old_code=0; old_static=0;
    if(kind!=7) {
      if(!fun || !static_fun || !literal) KernelStop;
      old_index=fun->idx; old_code=fun->exe_addr;
      member=static_fun->member_lst_and_root;
      if(!member || !(member->flags&MLF_STATIC)) KernelStop;
      old_static=member->static_data;
    }
    switch(kind) {
      case 1:
        collision=I386HeapAlloc(heap,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE);
        name=I386HeapAlloc(heap,12,FALSE);
        if(!collision || !name) KernelStop;
        PrsClassInit(collision); source="DurableData";
        for(i=0;i<12;i++) name[i]=source[i];
        collision->str=name; HashAdd(collision,task->hash_table); break;
      case 2: fun->idx="Foreign"; break;
      case 3: fun->idx=fun->str; break;
      case 4:
        for(j=65536;j>=8;j=j/2)
          while(block=I386HeapAlloc(heap,j,FALSE)) { block(U8 **)[0]=fill; fill=block; }
        break;
      case 5:
        if(!probe->compiler->code_add(heap,cc,IC_IMM_I64,1,probe->internal_types[RT_I64],0)) KernelStop;
        break;
      case 6: cc->error_cnt=1; break;
      case 8: fun->exe_addr="Foreign"; break;
      case 9: member->static_data=fun->str; break;
    }
    before_used=heap->used; before_allocations=heap->allocations;
    result=probe->compiler->publish(heap,cc,symbols);
    if(result!=(!kind || kind>=10)) KernelStop;
    if(!result) {
      if(heap->used!=before_used || heap->allocations!=before_allocations || scope->storage!=old_storage) KernelStop;
      for(i=0;i<count;i++) if(ProbeSymbolFind(0,roots[i]->str,source_table,roots[i]->type)!=roots[i]) KernelStop;
      if(kind!=7) { fun->idx=old_index; fun->exe_addr=old_code; member->static_data=old_static; }
      if(collision && (!ProbePublishedRemove(task->hash_table,collision) || !I386HashDel(heap,collision))) KernelStop;
      while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    } else {
      if(scope->storage==old_storage || scope->storage->next!=old_storage) KernelStop;
      if(kind==10) {
        storage=scope->storage; before_used=heap->used; before_allocations=heap->allocations;
        if(!probe->compiler->publish(heap,cc,symbols) || scope->storage!=storage ||
            heap->used!=before_used || heap->allocations!=before_allocations) KernelStop;
      }
      if(kind==11) {
        recovered=FALSE;
        try { symbols->declarations->execute(symbols->declarations->context,literal); }
        catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; recovered=TRUE; } }
        if(!recovered) KernelStop;
      }
    }
    if(!probe->compiler->control_unwind(task,outer)) KernelStop;
    if(result) {
      if(ProbeProgramUse(probe,heap,outer,"DurableAdd;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableNext;")!=41 ||
          ProbeProgramUse(probe,heap,outer,"DurableFact(5);")!=120 ||
          ProbeProgramUse(probe,heap,outer,"DurablePairData.a+DurablePairData.b;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableDefault;")!=121 ||
          ProbeProgramUse(probe,heap,outer,"DurableInit[1];")!=98 ||
          ProbeProgramUse(probe,heap,outer,"DurableString;")!=101 ||
          ProbeProgramUse(probe,heap,outer,"DurableInit[0]=90;")!=90 ||
          ProbeProgramUse(probe,heap,outer,"&DurableZero;")!=0 ||
          ProbeProgramUse(probe,heap,outer,"(DurableText)[1]+DurableLiteral[1];")!=202) KernelStop;
      failed=probe->files->control_new("U8i *Fresh=\"lost\";Unknown bad;",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/ProgramFailure.HC");
      if(!failed || !probe->compiler->control_enter(heap,failed,0,0)) KernelStop;
      failed_symbols=probe->compiler->frontend(heap,failed,probe->internal_types,probe->disk_include);
      if(!failed_symbols) KernelStop;
      recovered=FALSE;
      try { ProbeProgramRead(probe,heap,failed,failed_symbols); }
      catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; recovered=TRUE; } }
      if(!recovered || probe->compiler->publish(heap,failed,failed_symbols) ||
          !probe->compiler->control_unwind(task,outer) || ProbeSymbolFind(0,"Fresh",task->hash_table,HTT_GLBL_VAR) ||
          ProbeProgramUse(probe,heap,outer,"DurableAdd;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableNext;")!=42 ||
          ProbeProgramUse(probe,heap,outer,"DurableInit[0]+DurableInit[2];")!=189 ||
          ProbeProgramUse(probe,heap,outer,"DurableString;")!=102) KernelStop;
      //The fixture has exclusive references. Remove its published roots and
      //storage; production teardown is covered separately by task-symbol tests.
      for(i=0;i<count;i++)
        if(!ProbePublishedRemove(task->hash_table,roots[i]) || !I386HashDel(heap,roots[i])) KernelStop;
      storage=scope->storage; scope->storage=storage->next;
      for(i=0;i<storage->count;i++) if(!I386HeapFree(heap,storage->allocations[i])) KernelStop;
      if(!I386HeapFree(heap,storage)) KernelStop;
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        scope->storage!=old_storage || heap->used!=used || heap->allocations!=allocations ||
        !I386HeapValid(heap) || (GetRFlags&0x200)!=(flags&0x200)) { KernelLog("PROGRAM OWNERSHIP REJECT\n"); KernelStop; }
    KernelLog("PROGRAM CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
