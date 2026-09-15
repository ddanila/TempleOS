class CProbeInputAnswer {
  I64 value,raw_type,pointers,count,diagnostics,exception;
  Bool fail;
};
U0 ProbeInputAnswer(U8 *context,I64 value,CHashClass *value_class)
{
  CProbeInputAnswer *answer=context;
  if(answer->fail) throw(answer->exception,TRUE);
  if(!value_class) KernelStop;
  answer->value=value; answer->raw_type=value_class->raw_type;
  answer->pointers=value_class->ptr_stars_cnt; answer->count++;
  if(answer->pointers) answer->value=value(U8 *)[1];
}
U0 ProbeInputDiagnostic(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  CProbeInputAnswer *answer=context;
  if(!cc || !message || !*message) KernelStop;
  answer->diagnostics++;
}
U0 ProbeInputs(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *storage,*old_storage=scope->storage;
  CI386CommandInput input;
  CProbeInputAnswer answer;
  CHash *entry;
  CIntermediateCode *sentinel;
  U8 *bytes,*names[3];
  I64 kind,i,used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  Bool result,caught;
  bytes=&input; for(i=0;i<sizeof(CI386CommandInput);i++) bytes[i]=0;
  input.heap=heap; input.types=probe->internal_types; input.files=probe->files;
  input.includes=probe->disk_include; input.filename="Probe/Input.HC";
  input.context=&answer; input.answer=&ProbeInputAnswer; input.diagnostic=&ProbeInputDiagnostic;
  sentinel=probe->compiler->code_add(heap,outer,IC_IMM_I64,123,probe->i64_type,0);
  if(!sentinel) KernelStop;
  for(kind=0;kind<11;kind++) {
    KernelLog("INPUT RUN START "); KernelHex(kind); KernelLog("\n");
    bytes=&answer; for(i=0;i<sizeof(CProbeInputAnswer);i++) bytes[i]=0;
    input.flags=0; input.source="6*7;"; caught=FALSE;
    switch(kind) {
      case 1: input.source="0x100000000+42;"; break;
      case 2: input.source="1.5+2.25;"; break;
      case 3: input.source="(\"hello\");"; break;
      case 4: input.source="1;2;Unknown bad;"; break;
      case 5: input.flags=CCF_JUST_LOAD; input.source="1;2;"; break;
      case 6: answer.fail=TRUE; answer.exception='InputCb'; break;
      case 10: answer.fail=TRUE; break;
      case 7: input.source="I64i InputTemp=1;Unknown bad;"; break;
      case 8: input.flags=CCF_AOT_COMPILE; break;
      case 9: input.source="I64i InputValue=20;I64i *InputPointer=&InputValue;"
        "I64i InputAdd(){return *InputPointer+22;}InputAdd;"; break;
    }
    result=FALSE;
    try { result=probe->compiler->input(&input); }
    catch { if(kind==6 && task->except_ch=='InputCb' || kind==10 && !task->except_ch) { task->catch_except=TRUE; caught=TRUE; } }
    KernelLog("INPUT RUN RESULT "); KernelHex(result); KernelLog(" \n");
    KernelLog("INPUT RUN COUNTS "); KernelHex(input.commands); KernelLog(" "); KernelHex(input.answers); KernelLog(" "); KernelHex(input.exception); KernelLog(" "); KernelHex(answer.value); KernelLog(" "); KernelHex(answer.raw_type); KernelLog("\n");
    if(result!=(kind<4 || kind==5 || kind==9) || caught!=(kind==6 || kind==10)) KernelStop;
    if(kind==0 && (answer.count!=1 || answer.value!=42 || input.answers!=1 || input.commands!=1)) KernelStop;
    if(kind==1 && (answer.value!=0x10000002A || answer.raw_type!=RT_I64)) KernelStop;
    if(kind==2 && (answer.value!=0x400E000000000000 || answer.raw_type!=RT_F64)) KernelStop;
    if(kind==3 && (answer.value!='e' || answer.raw_type!=RT_PTR || answer.pointers!=1)) KernelStop;
    if(kind==4 && (answer.count!=2 || answer.value!=2 || !answer.diagnostics ||
        input.exception!='Compiler' || !input.errors)) KernelStop;
    if(kind==5 && (answer.count || input.answers || input.commands!=2)) KernelStop;
    if(kind==6 && input.exception!='InputCb') KernelStop;
    if(kind==7 && (ProbeSymbolFind(0,"InputTemp",task->hash_table,HTT_GLBL_VAR) ||
        !answer.diagnostics || input.exception!='Compiler')) KernelStop;
    if(kind==8 && (input.commands || input.answers || input.exception)) KernelStop;
    if(kind==9) {
      if(answer.value!=42 || answer.count!=1) KernelStop;
      input.source="InputAdd;";
      if(!probe->compiler->input(&input) || answer.value!=42 || answer.count!=2) KernelStop;
      input.source="Unknown bad;";
      if(probe->compiler->input(&input)) KernelStop;
      input.source="*InputPointer;";
      if(!probe->compiler->input(&input) || answer.value!=20 || answer.count!=3) KernelStop;
      names[0]="InputAdd"; names[1]="InputPointer"; names[2]="InputValue";
      for(i=0;i<3;i++) {
        entry=ProbeSymbolFind(0,names[i],task->hash_table,HTT_FUN|HTT_GLBL_VAR);
        if(!entry || !ProbePublishedRemove(task->hash_table,entry) || !I386HashDel(heap,entry)) KernelStop;
      }
    }
    //The pure literal case also retains its returned pool until task destruction.
    while(scope->storage!=old_storage) {
      storage=scope->storage; scope->storage=storage->next;
      for(i=0;i<storage->count;i++) if(!I386HeapFree(heap,storage->allocations[i])) KernelStop;
      if(!I386HeapFree(heap,storage)) KernelStop;
    }
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs ||
        task->except_top || outer->coc.coc_head.next!=sentinel || sentinel->ic_data!=123 ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("INPUT RUN CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
  if(!probe->compiler->code_discard(heap,outer,0,0) || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
}
