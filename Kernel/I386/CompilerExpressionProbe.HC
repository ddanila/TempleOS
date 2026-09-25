//Native source parsing through the full shared core. This fixture deliberately
//fails if a callback outside its arithmetic coverage is requested.
#include "/Compiler/PrsBinary.HC"
class CProbeExpression {
  CI386CompilerProbe *probe;
  CI386Heap *heap;
  CPrsExpressionServices services;
  CPrsTypeServices types;
  I64 lines;
};
class CProbeExpressionStorage {
  U32 binary_ops[TK_TKS_NUM];
  U8 deep[604],unary[304];
  CHashFun fun;
  CAOT aot;
  CAOTCtrl aotc;
};
U0 ProbeExpressionUnexpected() { KernelLog("UNEXPECTED EXPRESSION SERVICE\n"); KernelStop; }
I64 ProbeExpressionLex(U8 *context,CCmpCtrl *cc)
{
  CProbeExpression *state=context;
  return state->probe->compiler->parser_token(state->heap,cc,"Expression",&state->lines,state->probe->disk_include);
}
U0 ProbeExpressionReport(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  if(!kind) {
    KernelLog("PARSER DIAGNOSTIC "); KernelLog(message); KernelLog("\n");
    cc->error_cnt++; throw('Compiler',TRUE);
  }
  cc->warning_cnt++;
}
CIntermediateCode *ProbeExpressionAdd(U8 *context,CCmpCtrl *cc,I64 op,I64 value,CHashClass *type,I64 flags)
{
  CProbeExpression *state=context;
  CIntermediateCode *node=state->probe->compiler->code_add(state->heap,cc,op,value,type,flags);
  if(!node) KernelStop;
  return node;
}
Bool ProbeExpressionNested(U8 *context,CCmpCtrl *cc,I64 *precedence,Bool end_exp,CPrsStk *stack)
{
  CProbeExpression *state=context;
  return state->probe->compiler->expression(state->heap,cc,&state->services,precedence,end_exp,stack);
}
CHashClass *ProbeExpressionType(U8 *context,CCmpCtrl *cc,CHashClass **first,I64 *mode,
  CMemberLst *member,U8 **ident,CHashFun **fun,CHashExport **export_entry,CArrayDim *dim,I64 flags)
{
  CProbeExpression *state=context;
  CHashClass *result=state->probe->compiler->parse_type(state->heap,cc,&state->types,
    first,mode,member,ident,fun,export_entry,dim,flags);
  if(!result) KernelStop;
  return result;
}
U0 ProbeExpressionSetup(CProbeExpression *state,CI386CompilerProbe *probe,CI386Heap *heap,U32 *binary_ops)
{
  CPrsExpressionServices *services=&state->services;
  state->probe=probe; state->heap=heap; state->lines=0;
  PrsBinaryInit(binary_ops);
  services->context=state; services->types=probe->internal_types; services->binary_ops=binary_ops;
  services->lex=&ProbeExpressionLex; services->report=&ProbeExpressionReport; services->add=&ProbeExpressionAdd;
  services->class_view=0;
  services->retain_function_addresses=FALSE;
  services->expression=&ProbeExpressionNested;
  services->retire=&ProbeExpressionUnexpected; services->misc=&ProbeExpressionUnexpected;
  services->init=&ProbeExpressionUnexpected; services->push=&ProbeExpressionUnexpected;
  services->pop=&ProbeExpressionUnexpected; services->append=&ProbeExpressionUnexpected;
  services->optimize=&ProbeExpressionUnexpected; services->allocate=&ProbeExpressionUnexpected;
  services->duplicate=&ProbeExpressionUnexpected; services->string=&ProbeExpressionUnexpected;
  services->hash_add=&ProbeExpressionUnexpected; services->hash_after=&ProbeExpressionUnexpected;
  services->type=&ProbeExpressionType;
  state->types.context=state; state->types.types=probe->internal_types;
  state->types.lex=&ProbeExpressionLex; state->types.report=&ProbeExpressionReport;
  state->types.snapshot_drop=&ProbeExpressionUnexpected; state->types.snapshot_push=&ProbeExpressionUnexpected;
  state->types.integer_expression=&ProbeExpressionUnexpected;
  state->types.class_join=&ProbeExpressionUnexpected; state->types.fun_join=&ProbeExpressionUnexpected;
  state->types.allocate=&ProbeExpressionUnexpected; state->types.duplicate=&ProbeExpressionUnexpected;
  state->types.member_new=&ProbeExpressionUnexpected; state->types.member_add=&ProbeExpressionUnexpected;
}
U0 ProbeExpression(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CProbeExpression state;
  CPrsExpressionServices *services=&state.services;
  CProbeExpressionStorage *storage;
  U32 *binary_ops;
  U8 *deep,*unary;
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CI386Out *out;
  CI386BackendStatus status;
  CHashFun *fun;
  CAOT *aot;
  CAOTCtrl *aotc;
  U8 *bytes,*source,*fill,*block,*next;
  I64 i,kind,expected,actual,accepted,size;
  I64 (*generated)();
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  I64 original_used=used,original_allocations=allocations;
  U32 flags=GetRFlags;
  storage=I386HeapAlloc(heap,sizeof(CProbeExpressionStorage),TRUE);
  if(!storage) KernelStop;
  used=heap->used; allocations=heap->allocations;
  binary_ops=storage->binary_ops; deep=storage->deep; unary=storage->unary;
  fun=&storage->fun; aot=&storage->aot; aotc=&storage->aotc;
  ProbeExpressionSetup(&state,probe,heap,binary_ops);
  for(i=0;i<300;i++) { deep[i]='('; deep[301+i]=')'; }
  deep[300]='1'; deep[601]=';'; deep[602]=0;
  for(i=0;i<300;i++) unary[i]='~';
  unary[300]='1'; unary[301]=';'; unary[302]=0;
  for(kind=0;kind<22;kind++) {
    source="1+2*3;"; expected=7;
    switch(kind) {
      case 1: source="(1+2)*3;"; expected=9; break;
      case 2: source="-43/6;"; expected=-7; break;
      case 3: source="1<<40;"; expected=0x10000000000; break;
      case 4: source="3<4<5;"; expected=1; break;
      case 5: source="3<4>5;"; expected=0; break;
      case 6: source="0x7FFFFFFFFFFFFFFF+1;"; expected=0x8000000000000000; break;
      case 7: source="~0xFFFFFFFF;"; expected=0xFFFFFFFF00000000; break;
      case 8: source="1+);"; break;
      case 9: source="1+2;"; break;
      case 10: source=deep; break;
      case 11: source=unary; break;
      case 12: source="0x100000001(U32i);"; expected=1; break;
      case 13: source="0xFF(I8);"; expected=-1; break;
      case 14: source="0x100000001(U8 *);"; expected=1; break;
      case 15: source="0x1000(U8 *)+3;"; expected=0x1003; break;
      case 16: source="0x1000(I64i *)+3;"; expected=0x1018; break;
      case 17: source="0x1018(I64i *)-0x1000(I64i *);"; expected=3; break;
      case 18: source="sizeof(U8 *);"; expected=4; break;
      case 19: source="sizeof(I64i);"; expected=8; break;
      case 20: source="1(MissingType);"; break;
      case 21: source="1(U8 ********************************);"; break;
    }
    bytes=fun; for(i=0;i<sizeof(CHashFun);i++) bytes[i]=0;
    bytes=aot; for(i=0;i<sizeof(CAOT);i++) bytes[i]=0;
    bytes=aotc; for(i=0;i<sizeof(CAOTCtrl);i++) bytes[i]=0;
    aot->next_ie=aot->last_ie=&aot->next_ie; fun->return_class=probe->i64_type;
    cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Expression.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    cc->htc.fun=fun; cc->aot=aot; cc->aotc=aotc;
    out=probe->compiler->out_new(heap,cc); if(!out) KernelStop;
    ProbeExpressionAdd(&state,cc,IC_ENTER,0,0,0);
    ProbeExpressionLex(&state,cc);
    fill=0;
    accepted=0;
    try {
      if(kind==9) for(size=65536;size>=8;size=size/2)
        while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
      if(!probe->compiler->expression(heap,cc,services,0,FALSE,0) || (8<=kind<=11 || kind>=20) || cc->token!=';') KernelStop;
      ProbeExpressionAdd(&state,cc,IC_RETURN_VAL,0,probe->i64_type,0);
      ProbeExpressionAdd(&state,cc,IC_LEAVE,0,0,0);
      if(!probe->compiler->backend(heap,cc,probe->internal_types,out,&status) || !out->count || cc->error_cnt) KernelStop;
      generated=out->data; actual=(*generated)();
      if(actual!=expected) { KernelLog("EXPRESSION RESULT "); KernelHex(kind); KernelLog(" "); KernelHex(actual); KernelLog("\n"); KernelStop; }
      accepted=1;
    } catch {
      if(kind<8 || 12<=kind<=19 || kind!=9 && task->except_ch!='Compiler' || kind==9 && task->except_ch!='OutMem') {
        KernelLog("EXPRESSION EXCEPTION "); KernelHex(kind); KernelLog(" "); KernelHex(task->except_ch); KernelLog(" "); KernelHex(cc->token); KernelLog(" "); KernelHex(cc->error_cnt); KernelLog("\n"); KernelStop;
      }
      task->catch_except=TRUE; accepted=1;
    }
    while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    if(!accepted || !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
        task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
    KernelLog("EXPRESSION CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
  if(!I386HeapFree(heap,storage) || heap->used!=original_used ||
      heap->allocations!=original_allocations || !I386HeapValid(heap)) KernelStop;
  KernelLog("EXPRESSION PROBE "); KernelHex(probe->phase); KernelLog("\n");
}
