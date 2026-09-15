//One retained source stream may define symbols and execute top-level statements.
U0 ProbeCommands(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *declarations;
  CPrsExpressionServices *expression;
  CIntermediateCode *sentinel;
  CHashGlblVar *global;
  U8 *source,*code,*saved[2];
  I64 kind,expected,actual,raw_type,expected_type,outputs,expected_outputs,steps,accepted,i;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  for(kind=0;kind<16;kind++) {
    source="6*7;"; expected=42; expected_type=RT_I64; expected_outputs=1;
    switch(kind) {
      case 1: source="83.0/2.0+0.5;"; expected=0x4045000000000000; expected_type=RT_F64; break;
      case 2: source="I64i x=20;x+=22;x;"; expected_outputs=2; break;
      case 3: source="I64i Twice(I64i x=21){return x*2;}Twice;"; break;
      case 4: source="I64i x=0;while(x<42)x++;x;"; expected_outputs=2; break;
      case 5: source="I64i i=0,sum=0;for(i=0;i<7;i++)sum+=i;sum*2;"; expected_outputs=2; break;
      case 6: source="{I64i x=20;x+=22;}x;"; expected_outputs=2; break;
      case 7: source="I64i data[3]={10,20,12};data[0]+data[1]+data[2];"; break;
      case 8: source="F64 x=41.5;x+=0.5;x;"; expected=0x4045000000000000; expected_type=RT_F64; expected_outputs=2; break;
      case 9: source="I64i Fact(I64i n){if(n<2)return 1;return n*Fact(n-1);}Fact(5);"; expected=120; break;
      case 10: source="(\"hello\");"; expected_type=RT_PTR; break;
      case 11: source="I64i x=1;x=42;Missing bad;"; break;
      case 12: source="return 42;"; break;
      case 13: source="42+;"; break;
      case 14: source="1+1;40+2;"; expected_outputs=2; break;
      case 15: source="I64i x=1;x=99;"; expected=0; break;
    }
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Commands.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    declarations=symbols->declarations; expression=declarations->expression;
    expression->report=&ProbeExpressionReport; declarations->types->report=&ProbeExpressionReport;
    sentinel=probe->compiler->code_add(heap,cc,IC_IMM_I64,0x12345678,probe->internal_types[RT_I64],0);
    if(!sentinel) KernelStop;
    if(kind==15) cc->flags|=CCF_JUST_LOAD;
    KernelLog("COMMAND START "); KernelHex(kind); KernelLog("\n");
    outputs=0; steps=0; actual=0; accepted=0; saved[0]=saved[1]=0;
    try {
      expression->lex(expression->context,cc);
      while(cc->token!=TK_EOF) {
        if(++steps>32) KernelStop;
        code=probe->compiler->command(heap,cc,symbols,&raw_type);
        if(cc->coc.coc_head.next!=sentinel || cc->coc.coc_head.last!=sentinel ||
            sentinel->next!=&cc->coc.coc_head || sentinel->ic_data!=0x12345678 || !(cc->flags&CCF_AOT_COMPILE)) KernelStop;
        if(code) {
          outputs++;
          if(!(cc->flags&CCF_JUST_LOAD)) actual=declarations->execute(declarations->context,code);
          KernelLog("COMMAND VALUE "); KernelHex(raw_type); KernelLog(" "); KernelHex(actual); KernelLog("\n");
          if(kind==10) {
            if(StrCmp(actual,"hello") || !(cc->flags&CCF_HAS_MISC_DATA)) KernelStop;
            actual=42;
          }
          if(kind==14) { if(outputs>2) KernelStop; saved[outputs-1]=code; }
          else declarations->release(declarations->context,code);
        } else if(raw_type!=RT_U0) KernelStop;
      }
      if(11<=kind<=13 || outputs!=expected_outputs || actual!=expected || raw_type!=expected_type) KernelStop;
      if(kind==14) {
        if(declarations->execute(declarations->context,saved[0])!=2 ||
            declarations->execute(declarations->context,saved[1])!=42) KernelStop;
        for(i=0;i<2;i++) declarations->release(declarations->context,saved[i]);
      }
      if(kind==15) {
        global=ProbeSymbolFind(0,"x",cc->htc.glbl_hash_table,HTT_GLBL_VAR);
        if(!global || !global->data_addr || *global->data_addr(I64 *)!=1) KernelStop;
      }
      accepted=1;
    } catch {
      if(!(11<=kind<=13) || task->except_ch!='Compiler') {
        KernelLog("COMMAND EXCEPTION "); KernelHex(kind); KernelLog(" "); KernelHex(task->except_ch); KernelLog("\n"); KernelStop;
      }
      task->catch_except=TRUE; accepted=1;
    }
    if(!accepted || !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
        task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) { KernelLog("COMMAND OWNERSHIP REJECT\n"); KernelStop; }
    KernelLog("COMMAND CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
