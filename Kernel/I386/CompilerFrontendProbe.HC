//Exercise the retained environment, including code ownership and function defaults.
U0 ProbeFrontend(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *declarations;
  CPrsExpressionServices *expression;
  CHashFun *fun;
  CIntermediateCode *saved_node;
  CHashClass *type;
  CMemberLst *member;
  U8 *source,*code,*second,*name,*fill,*block,*next;
  I64 kind,raw,value,expected,accepted,i,size;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  for(kind=0;kind<17;kind++) {
    source="6*7"; expected=42;
    switch(kind) {
      case 1: source="0xFEDCBA9876543210>>36"; expected=0xFEDCBA9; break;
      case 2: source="0xFF(I8i)"; expected=-1; break;
      case 3: source="7/2.0"; expected=0x400C000000000000; break;
      case 4: source="(\"1\")[0]+0.5"; expected=0x4048C00000000000; break;
      case 5: source="(\"a\")[0]+=0.5"; expected=97; break;
      case 6: source="(\"1\")[0]*2.0-1.0"; expected=0x4058400000000000; break;
      case 7: source="(\"a\")[0]>96.0"; expected=1; break;
      case 8: source="\"hello\" \" world\""; break;
      case 9: source="Defaults(I64i a=6*7,F64 b=7/2.0,I64i c=7/2.0,U8i *text=\"ab\" \"cd\",I64i d=lastclass,F64 e=(\"1\")[0]+0.5)"; break;
      case 10: source="Bad(I64i a=42,U8i *text=\"owned\",F64 b=1+)"; break;
      case 11: source="6+"; break;
      case 12: source=";"; break;
      case 14: source="\"keep\"; 17+25"; break;
      case 16: source="Bounds { U8i data[(\"a\")[0]/2.0]; }"; break;
    }
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Frontend.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
    if(!symbols) KernelStop;
    declarations=symbols->declarations; expression=declarations->expression;
    accepted=0; fill=0;
    KernelLog("FRONTEND START "); KernelHex(kind); KernelLog("\n");
    try {
      expression->lex(expression->context,cc);
      if(kind==9 || kind==10) {
        name=cc->cur_str; cc->cur_str=0; expression->lex(expression->context,cc);
        fun=declarations->types->fun_join(declarations->types->context,cc,probe->i64_type,name,0);
        if(kind==10 || !fun || fun->arg_cnt!=6 || cc->token!=TK_EOF) KernelStop;
        member=fun->member_lst_and_root;
        for(i=0;i<6;i++,member=member->next) {
          if(!member || member->offset!=8+i*8 || !(member->flags&MLF_DFT_AVAILABLE)) KernelStop;
          switch(i) {
            case 0: if(member->dft_val!=42) KernelStop; break;
            case 1: if(member->dft_val!=0x400C000000000000) KernelStop; break;
            case 2: if(member->dft_val!=3) KernelStop; break;
            case 3: if(!(member->flags&MLF_STR_DFT_AVAILABLE) || StrCmp(member->dft_val,"abcd")) KernelStop; break;
            case 4: if(!(member->flags&MLF_LASTCLASS)) KernelStop; break;
            case 5: if(member->dft_val!=0x4048C00000000000) KernelStop; break;
          }
        }
      } else if(kind==16) {
        type=declarations->types->class_join(declarations->types->context,cc,KW_CLASS,0,FALSE);
        if(!type || type->size!=48 || !type->member_lst_and_root ||
            type->member_lst_and_root->dim.total_cnt!=48 || cc->token!=TK_EOF) KernelStop;
      } else {
        if(kind==15) for(size=65536;size>=8;size=size/2)
          while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
        saved_node=0;
        if(kind==14) saved_node=probe->compiler->code_add(heap,cc,IC_IMM_I64,123,probe->i64_type,0);
        code=declarations->compile_expression(declarations->context,cc,&raw);
        if(kind==14 && (!saved_node || cc->coc.coc_head.next!=saved_node || cc->coc.coc_head.last!=saved_node)) KernelStop;
        if(kind==12) KernelStop;
        else {
          if(!code || kind==11 || kind==15) KernelStop;
          if(kind==13) declarations->release(declarations->context,code);
          value=declarations->execute(declarations->context,code);
          KernelLog("FRONTEND VALUE "); KernelHex(kind); KernelLog(" "); KernelHex(raw); KernelLog(" "); KernelHex(value); KernelLog("\n");
          if(kind==13) KernelStop;
          if(kind==14) {
            if(StrCmp(value,"keep") || cc->token!=';') KernelStop;
            expression->lex(expression->context,cc);
            second=declarations->compile_expression(declarations->context,cc,&raw);
            if(!second || declarations->execute(declarations->context,second)!=42 || StrCmp(value,"keep")) KernelStop;
            declarations->release(declarations->context,second);
            if(StrCmp(declarations->execute(declarations->context,code),"keep")) KernelStop;
          } else if(kind==8) { if(raw!=RT_PTR || StrCmp(value,"hello world")) KernelStop; }
          else {
            if(value!=expected || (raw==RT_F64)!=(kind==3 || kind==4 || kind==6)) KernelStop;
          }
          declarations->release(declarations->context,code);
          if(cc->token!=TK_EOF) { KernelLog("FRONTEND TOKEN "); KernelHex(cc->token); KernelLog("\n"); KernelStop; }
        }
      }
      accepted=1;
    } catch {
      if(kind!=10 && kind!=11 && kind!=12 && kind!=13 && kind!=15 ||
          kind==15 && task->except_ch!='OutMem' || kind!=15 && task->except_ch!='Compiler') {
        KernelLog("FRONTEND EXCEPTION "); KernelHex(kind); KernelLog(" "); KernelHex(task->except_ch); KernelLog("\n"); KernelStop;
      }
      task->catch_except=TRUE; accepted=1;
    }
    while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    KernelLog("FRONTEND END "); KernelHex(kind); KernelLog(" "); KernelHex(cc->token); KernelLog("\n");
    if(!accepted || !probe->compiler->control_unwind(task,outer)) { KernelLog("FRONTEND UNWIND REJECT\n"); KernelStop; }
    KernelLog("FRONTEND HEAP "); KernelHex(heap->used-used); KernelLog(" "); KernelHex(heap->allocations-allocations); KernelLog("\n");
    if(task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("FRONTEND CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
