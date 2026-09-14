//Production declaration parsing with native snapshots, members and bound execution.
#include "/Compiler/SymbolInit.HC"
#include "/Compiler/MemberLookup.HC"
#include "/Compiler/MemberBuild.HC"
#include "/Compiler/LexFiles.HC"
#include "/Compiler/I386/LexState.HC"
class CProbeDeclarations {
  CProbeExpression expression;
  CCmpCtrl *cc;
  CPrsDeclarationServices declarations;
};
class CProbeBound {
  CHashFun fun;
  CAOT aot;
  CAOTCtrl aotc;
  CI386BackendStatus status;
};
U8 *ProbeDeclarationAllocate(U8 *context,I64 size,Bool zeroed,Bool code_heap)
{
  CProbeDeclarations *state=context;
  U8 *value=state->expression.probe->compiler->parser_alloc(state->expression.heap,state->cc,size,zeroed);
  if(!value) throw('Compiler',TRUE);
  return value;
}
U8 *ProbeDeclarationTypeAllocate(U8 *context,I64 size)
{ return ProbeDeclarationAllocate(context,size,TRUE,FALSE); }
U8 *ProbeDeclarationDuplicate(U8 *context,U8 *source)
{
  I64 i=0;
  U8 *result;
  while(source[i]) i++;
  result=ProbeDeclarationAllocate(context,i+1,FALSE,FALSE);
  do { result[i]=source[i]; } while(i--);
  return result;
}
U0 ProbeDeclarationRelease(U8 *context,U8 *allocation)
{
  CProbeDeclarations *state=context;
  if(!state->expression.probe->compiler->parser_free(state->expression.heap,state->cc,allocation)) KernelStop;
}
U0 ProbeDeclarationSnapshot(U8 *context,CCmpCtrl *cc)
{
  CProbeDeclarations *state=context;
  if(!I386LexPush(state->expression.heap,cc)) throw('OutMem',TRUE);
}
U0 ProbeDeclarationDrop(U8 *context,CCmpCtrl *cc)
{
  CProbeDeclarations *state=context;
  if(!I386LexPop(state->expression.heap,cc,FALSE)) KernelStop;
}
U0 ProbeDeclarationRestore(U8 *context,CCmpCtrl *cc)
{
  CProbeDeclarations *state=context;
  if(!I386LexPop(state->expression.heap,cc,TRUE)) KernelStop;
}
CMemberLst *ProbeDeclarationMember(U8 *context,I64 register_hint)
{
  CMemberLst *member=ProbeDeclarationAllocate(context,sizeof(CMemberLst),TRUE,FALSE);
  member->reg=register_hint; return member;
}
U0 ProbeDeclarationDiagnostic(U8 *context,Bool warning)
{
  CProbeDeclarations *state=context;
  ProbeExpressionReport(context,state->cc,warning,"Duplicate member at ");
}
U0 ProbeDeclarationMemberAdd(U8 *context,CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode)
{
  if(!MemberInsert(member,type,mode==PRS1B_LOCAL_VAR,FALSE,&ProbeDeclarationDiagnostic,context)) KernelStop;
}
I64 ProbeDeclarationInteger(U8 *context,CCmpCtrl *cc)
{
  CProbeDeclarations *state=context;
  CI386CompilerProbe *probe=state->expression.probe;
  CI386Heap *heap=state->expression.heap;
  CProbeBound *bound=ProbeDeclarationAllocate(context,sizeof(CProbeBound),TRUE,FALSE);
  CHashFun *old_fun=cc->htc.fun;
  CAOT *old_aot=cc->aot;
  CAOTCtrl *old_aotc=cc->aotc;
  I64 old_flags=cc->flags,old_pass=cc->pass,result;
  I64 mask=CCF_DONT_MAKE_RES|CCF_AOT_COMPILE|CCF_EXE_BLK|CCF_TARGET_HOST_CONST;
  I64 (*code)();
  CI386Out *out;
  CCodeCtrl *saved;
  if(!probe->compiler->code_push(heap,cc) || !probe->compiler->code_init(heap,cc)) KernelStop;
  bound->fun.return_class=probe->i64_type;
  bound->aot.next_ie=bound->aot.last_ie=&bound->aot.next_ie;
  cc->htc.fun=&bound->fun; cc->aot=&bound->aot; cc->aotc=&bound->aotc;
  cc->flags=cc->flags&~mask|CCF_AOT_COMPILE; cc->pass=0;
  ProbeExpressionAdd(context,cc,IC_ENTER,0,0,0);
  if(!probe->compiler->expression(heap,cc,&state->expression.services,0,FALSE,0)) KernelStop;
  ProbeExpressionAdd(context,cc,IC_RETURN_VAL,0,probe->i64_type,0);
  ProbeExpressionAdd(context,cc,IC_LEAVE,0,0,0);
  out=probe->compiler->out_new(heap,cc);
  if(!out || !probe->compiler->backend(heap,cc,probe->internal_types,out,&bound->status)) KernelStop;
  code=out->data; result=(*code)();
  if(!probe->compiler->out_del(heap,cc,out) || !probe->compiler->code_discard(heap,cc,0,0) ||
      !(saved=probe->compiler->code_pop(heap,cc)) || !probe->compiler->code_free(heap,cc,saved)) KernelStop;
  cc->htc.fun=old_fun; cc->aot=old_aot; cc->aotc=old_aotc;
  cc->flags=cc->flags&~mask|old_flags&mask; cc->pass=old_pass;
  ProbeDeclarationRelease(context,bound); return result;
}
U0 ProbeDeclarations(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CProbeDeclarations *state;
  U32 *binary_ops;
  CPrsTypeServices *types;
  CPrsDeclarationServices *services;
  CHashClass *type;
  CMemberLst *first,*last;
  CIntermediateCode *prefix;
  CCmpCtrl *cc;
  CI386Task *task=I386TaskSelf;
  U8 *source,*fill,*block,*next;
  I64 kind,mode,expected,count,accepted,size;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  for(kind=0;kind<9;kind++) {
    source="{ U8 lo; I64i hi; }"; expected=9; count=2; mode=PRS0_NULL|PRS1_CLASS;
    switch(kind) {
      case 1: mode|=PRSF_UNION; expected=8; break;
      case 2: source="{ U8 bytes[2+3]; I64i tail; }"; expected=13; break;
      case 3: source="{ U8 tag; union { U8 small; I64i large; }; U8 tail; }"; expected=10; count=4; break;
      case 4: source="{ U16i one,two; }"; expected=4; break;
      case 5: source="{ U8 good; Missing bad; }"; break;
      case 6: source="{ U8 same; U8 same; }"; break;
      case 7: source="U8 value; }"; break;
      case 8: source="{ U8 bad[2+)]; }"; break;
    }
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Declarations.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    state=probe->compiler->parser_alloc(heap,cc,sizeof(CProbeDeclarations),TRUE);
    binary_ops=probe->compiler->parser_alloc(heap,cc,TK_TKS_NUM*sizeof(U32),TRUE);
    type=probe->compiler->parser_alloc(heap,cc,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE);
    if(!state || !binary_ops || !type) KernelStop;
    PrsClassInit(type); state->cc=cc;
    ProbeExpressionSetup(&state->expression,probe,heap,binary_ops);
    state->expression.services.allocate=&ProbeDeclarationAllocate;
    state->expression.services.duplicate=&ProbeDeclarationDuplicate;
    types=&state->expression.types;
    types->allocate=&ProbeDeclarationTypeAllocate; types->duplicate=&ProbeDeclarationDuplicate;
    types->snapshot_push=&ProbeDeclarationSnapshot; types->snapshot_drop=&ProbeDeclarationDrop;
    types->member_new=&ProbeDeclarationMember; types->member_add=&ProbeDeclarationMemberAdd;
    types->integer_expression=&ProbeDeclarationInteger;
    services=&state->declarations; services->context=state;
    services->expression=&state->expression.services; services->types=types;
    services->evaluate=&ProbeDeclarationInteger; services->snapshot_restore=&ProbeDeclarationRestore;
    services->release=&ProbeDeclarationRelease;
    //Remaining callback paths are outside this fixture's declared coverage.
    services->define_match=&ProbeExpressionUnexpected; services->initialize_static=&ProbeExpressionUnexpected;
    services->static_init=&ProbeExpressionUnexpected; services->store_u64=&ProbeExpressionUnexpected;
    services->store_u8_at=&ProbeExpressionUnexpected; services->data_range=&ProbeExpressionUnexpected;
    services->compile_expression=&ProbeExpressionUnexpected; services->execute=&ProbeExpressionUnexpected;
    prefix=0;
    if(kind==2) prefix=probe->compiler->code_add(heap,cc,IC_IMM_I64,1234,probe->i64_type,0);
    ProbeExpressionLex(state,cc); fill=0; accepted=0;
    try {
      if(kind==7) for(size=65536;size>=8;size=size/2)
        while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
      if(!probe->compiler->parse_declarations(heap,cc,services,type,mode,0) || kind>=5 ||
          type->size!=expected || type->member_cnt!=count || cc->lex_prs_stk || cc->token!=TK_EOF) KernelStop;
      if(kind==2 && (!prefix || cc->coc.coc_head.next!=prefix || cc->coc.coc_head.last!=prefix ||
          prefix->ic_data!=1234 || prefix->next!=&cc->coc.coc_head || prefix->last!=&cc->coc.coc_head)) KernelStop;
      first=type->member_lst_and_root; last=type->last_in_member_lst;
      if(!first || !last || first->offset || last->next) KernelStop;
      if(kind==0 && last->offset!=1 || kind==1 && last->offset ||
          kind==2 && (first->dim.total_cnt!=5 || first->dim.next->cnt!=5 || last->offset!=5) ||
          kind==3 && (first->next->offset!=1 || first->next->next->offset!=1 || last->offset!=9) ||
          kind==4 && last->offset!=2) KernelStop;
      accepted=1;
    } catch {
      if(kind<5 || kind==7 && task->except_ch!='OutMem' || kind!=7 && task->except_ch!='Compiler') {
        KernelLog("DECLARATION EXCEPTION "); KernelHex(kind); KernelLog(" "); KernelHex(task->except_ch); KernelLog("\n"); KernelStop;
      }
      task->catch_except=TRUE; accepted=1;
    }
    while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    if(!accepted || !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
        task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("DECLARATION CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
}
