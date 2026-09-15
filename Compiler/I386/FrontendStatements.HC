//Full shared statement/function/initializer grammar with one private native owner.
#include "/Compiler/PrsInitializerCore.HC"
#include "/Compiler/PrsGlobalCore.HC"
#include "/Compiler/PrsFunctionCore.HC"
#include "/Compiler/PrsStatementCore.HC"
U0 I386FrontendCopy(U8 *context,U8 *destination,U8 *source,I64 bytes)
{
  I64 i;
  if(bytes<0) I386FrontendUnavailable(context);
  for(i=0;i<bytes;i++) destination[i]=source[i];
}
U0 I386FrontendSet(U8 *context,U8 *destination,U8 value,I64 bytes)
{
  I64 i;
  if(bytes<0) I386FrontendUnavailable(context);
  for(i=0;i<bytes;i++) destination[i]=value;
}
U0 I386FrontendStack(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(cc!=state->cc || !I386CmpCodeOwner(state->heap,cc) || !I386ParserStackCheck(cc))
    I386FrontendUnavailable(state);
}
Bool I386FrontendStatementCall(U8 *context,CCmpCtrl *cc,I64 count,CCodeMisc *label,I64 flags)
{
  CI386Frontend *state=context;
  return PrsStmtCore(&state->statements,cc,count,label,flags);
}
U8 *I386FrontendFunctionCode(U8 *context,CCmpCtrl *cc,I64 *bytes,CDbgInfo **debug,I64 *raw_type)
{
  CI386Frontend *state=context;
  CI386FrontendCode *result;
  CHashClass *type;
  CCodeMisc *label;
  I386FrontendStack(state,cc);
  if(!cc->htc.fun || !(type=OptClassFwd(cc->htc.fun->return_class))) I386FrontendUnavailable(state);
  for(label=cc->coc.coc_next_misc;label!=&cc->coc.coc_next_misc;label=label->next)
    if(label->type==CMT_GOTO_LABEL && !(label->flags&CMF_DEFINED)) I386FrontendUnavailable(state);
  result=I386FrontendOutput(state,cc,type,cc->flags&CCF_HAS_MISC_DATA);
  if(bytes) *bytes=result->bytes;
  if(debug) *debug=0;
  if(raw_type) *raw_type=result->raw_type;
  return result->code;
}
U0 I386FrontendFunction(U8 *context,CCmpCtrl *cc,CHashClass *type,U8 *name,I64 flags)
{
  CI386Frontend *state=context;
  I386FrontendStack(state,cc);
  if(cc->flags&CCF_AOT_COMPILE || cc->htc.fun) I386FrontendUnavailable(state);
  PrsFunCore(&state->functions,cc,type,name,flags);
}
U0 I386FrontendResolve(U8 *context,CCmpCtrl *cc,U8 *name)
{
  CI386Frontend *state=context;
  CHash *symbol=I386FrontendSingleFind(state,name,state->table,HTT_FUN|HTT_GLBL_VAR);
  CI386FrontendFixup **link=&state->fixups,*fixup;
  CHashFun *fun;
  CMemberLst *member;
  CI386FrontendCode *code;
  I64 i;
  if(!symbol || cc->htc.glbl_hash_table!=state->table) I386FrontendUnavailable(state);
  if(!(symbol->type&HTT_FUN)) return;
  fun=symbol;
  if(fun->ie_lst || fun->ext_lst || !fun->exe_addr || fun->type&HTF_IMPORT) I386FrontendUnavailable(state);
  //The shared function parser calls resolve before clearing Cf_EXTERN.
  while(fixup=*link) {
    if(fixup->function==fun) {
      if(fixup->argument_count!=fun->arg_cnt || fixup->result_type!=fun->return_class ||
          fixup->flags!=(fun->flags&(FSG_FUN_FLAGS1|1<<Ff_DOT_DOT_DOT))) I386FrontendUnavailable(state);
      member=fun->member_lst_and_root;
      for(i=0;i<fun->arg_cnt;i++) {
        if(!member || member->member_class!=fixup->arguments[i]) I386FrontendUnavailable(state);
        member=member->next;
      }
      for(code=state->codes;code && code->code!=fixup->code;code=code->next);
      if(!code || fixup->offset<0 || fixup->offset>code->bytes-4) I386FrontendUnavailable(state);
      (code->code+fixup->offset)(U32 *)[0]=(fun->exe_addr+0)(U64)-(code->code+fixup->offset+4)(U64);
      *link=fixup->next; I386FrontendFree(state,fixup);
    } else link=&fixup->next;
  }
}
Bool I386FrontendSameHeap(U8 *context,U8 *left,U8 *right)
{
  CI386Frontend *state=context;
  return I386ParserRecord(state->cc,left) && I386ParserRecord(state->cc,right);
}
U0 I386FrontendAliasWarning(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol)
{ cc->warning_cnt++; }
U0 I386FrontendMemberWarning(U8 *context,CCmpCtrl *cc,CMemberLst *member,Bool unneeded)
{ cc->warning_cnt++; }
U0 I386FrontendDisassemble(U8 *context,U8 *code,I64 bytes)
{ I386FrontendUnavailable(context); }
U8 *I386FrontendInitializerCode(U8 *context,CCmpCtrl *cc,I64 *bytes)
{ I386FrontendUnavailable(context); return 0; }
U0 I386FrontendStoreByte(U8 *context,CCmpCtrl *cc,U8 value)
{ I386FrontendUnavailable(context); }
CCodeCtrl *I386FrontendPopSaved(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  CCodeCtrl *saved=I386COCPopNoFree(state->heap,cc);
  if(!saved) I386FrontendUnavailable(state);
  return saved;
}
U0 I386FrontendAssembly(U8 *context,CCmpCtrl *cc,I64 flags)
{ I386FrontendUnavailable(context); }
CAOT *I386FrontendJoin(U8 *context,CCmpCtrl *cc,I64 flags)
{ I386FrontendUnavailable(context); return 0; }
U0 I386FrontendFixAssembly(U8 *context,CCmpCtrl *cc,CAOT *aot)
{ I386FrontendUnavailable(context); }
CHashTable *I386FrontendTaskSymbols(U8 *context)
{ CI386Frontend *state=context; return state->table; }
U0 I386FrontendExecuteLine(U8 *context,CCmpCtrl *cc)
{ I386FrontendUnavailable(context); }
U0 I386FrontendInclude(U8 *context,CCmpCtrl *cc,U8 *name,U8 *source,Bool file)
{ I386FrontendUnavailable(context); }
U0 I386FrontendStatementsInit(CI386Frontend *state)
{
  CPrsInitializerServices *i=&state->initializers;
  CPrsGlobalServices *g=&state->globals;
  CPrsFunctionServices *f=&state->functions;
  CPrsStatementServices *s=&state->statements;
  i->context=state; i->declarations=&state->declarations;
  i->copy=&I386FrontendCopy; i->set=&I386FrontendSet;
  i->store_u8=&I386FrontendStoreByte; i->compile_code=&I386FrontendInitializerCode;
  g->context=state; g->symbols=&state->symbols; g->initializers=i;
  g->function=&I386FrontendFunction; g->resolve=&I386FrontendResolve;
  g->same_heap=&I386FrontendSameHeap; g->alias_warning=&I386FrontendAliasWarning;
  f->context=state; f->globals=g; f->statement=&I386FrontendStatementCall;
  f->compile=&I386FrontendFunctionCode; f->disassemble=&I386FrontendDisassemble;
  f->member_warning=&I386FrontendMemberWarning;
  s->context=state; s->globals=g; s->pop_saved=&I386FrontendPopSaved;
  s->assembly=&I386FrontendAssembly; s->join=&I386FrontendJoin; s->fix_assembly=&I386FrontendFixAssembly;
  s->task_symbols=&I386FrontendTaskSymbols; s->execute_line=&I386FrontendExecuteLine;
  s->include=&I386FrontendInclude; s->stack_check=&I386FrontendStack;
}
Bool I386FrontendStatement(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 flags)
{
  CI386Frontend *state;
  I64 old_flags;
  if(!I386CmpCodeOwner(heap,cc) || !symbols || !(state=symbols->context) ||
      state->heap!=heap || state->cc!=cc || symbols!=&state->symbols || cc->error_cnt) return FALSE;
  old_flags=cc->flags; cc->flags&=~CCF_AOT_COMPILE;
  PrsStmtCore(&state->statements,cc,0,0,flags);
  cc->flags=cc->flags&~CCF_AOT_COMPILE|old_flags&CCF_AOT_COMPILE;
  return TRUE;
}
U8 *I386FrontendCommand(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 *raw_type)
{//Native LexStmt2Bin staging: parse globally, then give generated code a frame.
  CI386Frontend *state;
  CI386FrontendBound *bound;
  CI386FrontendCode *result=0;
  CIntermediateCode *node,*enter;
  CHashClass *type;
  I64 old_flags,old_pass;
  if(!I386CmpCodeOwner(heap,cc) || !symbols || !(state=symbols->context) ||
      state->heap!=heap || state->cc!=cc || symbols!=&state->symbols || cc->error_cnt || cc->htc.fun)
    throw('Compiler',TRUE);
  I386FrontendStack(state,cc);
  if(raw_type) *raw_type=RT_U0;
  old_flags=cc->flags; old_pass=cc->pass;
  I386FrontendPush(state,cc); I386FrontendInit(state,cc);
  cc->flags&=~(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA|(1<<CCf_PASS_TRACE_PRESENT));
  if(PrsStmtCore(&state->statements,cc,0,0,CMPF_PRS_SEMICOLON)) I386FrontendUnavailable(state);
  if(cc->coc.coc_head.next!=&cc->coc.coc_head) {
    cc->coc.coc_head.last->ic_flags&=~ICF_RES_NOT_USED;
    bound=I386FrontendAlloc(state,sizeof(CI386FrontendBound),TRUE,FALSE);
    bound->typer.types=state->expression.types;
    cc->pass=0; I386FrontendOptimize(state,cc); I386FrontendOptimize(state,cc);
    type=state->expression.types[RT_I64];
    for(node=cc->coc.coc_head.last;node!=&cc->coc.coc_head;node=node->last)
      if(node->ic_code>IC_END_EXP && node->ic_code!=IC_NOP2 && node->ic_class) {
        type=I386ValueClass(&bound->typer,node); break;
      }
    //Do not install the dummy function until parsing has finished: declarations
    //inside top-level blocks must retain their ordinary global scope.
    bound->fun.return_class=type; cc->htc.fun=&bound->fun;
    enter=I386FrontendAdd(state,cc,IC_ENTER,0,0,0);
    ICDetach(enter);
    enter->last=&cc->coc.coc_head; enter->next=cc->coc.coc_head.next;
    enter->next->last=enter; cc->coc.coc_head.next=enter;
    I386FrontendAdd(state,cc,IC_RETURN_VAL2,0,type,0);
    I386FrontendAdd(state,cc,IC_LEAVE,0,type,0);
    result=I386FrontendOutput(state,cc,type,0);
    cc->htc.fun=0;
    I386FrontendFree(state,bound);
    if(raw_type) *raw_type=result->raw_type;
  } else if(!I386COCDiscard(heap,cc)) I386FrontendUnavailable(state);
  I386FrontendPop(state,cc);
  cc->flags=cc->flags&~(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA)|old_flags&(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA);
  cc->pass=old_pass;
  if(result) return result->code;
  return 0;
}
