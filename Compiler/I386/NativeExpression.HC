//Included after native control, optimizer and backend implementations.
#include "/Compiler/I386/NativeExpression.HH"
I64 StrLen(U8 *text) { I64 length=0; while(text[length]) length++; return length; }
#ifndef NULL
#define NULL 0
#endif
#include "/Compiler/PrsExpressionCore.HC"
Bool I386ExpressionStackValid(CCmpCtrl *cc,CPrsStk *stack)
{
  CI386CmpCtrl *owned=cc;
  CI386CodeAllocation *record;
  for(record=owned->code_next;record!=&owned->code_next;record=record->next)
    if(record->allocation==stack && record->kind==7) return TRUE;
  return FALSE;
}
Bool I386ParseExpression(CI386Heap *heap,CCmpCtrl *cc,CPrsExpressionServices *services,
  I64 *precedence,Bool end_exp,CPrsStk *stack=0)
{
  CPrsStk *ps=stack;
  CI386CmpCtrl *owned=cc;
  CI386Task *task;
  U8 *frame;
  CI386CodeAllocation *record;
  CI386CmpRelease release;
  I64 old_flags;
  U32 irq;
  if(!I386CmpCodeOwner(heap,cc) || !services || !services->types || !services->binary_ops ||
      !services->lex || !services->report || !services->add || !services->retire ||
      !services->misc || !services->init || !services->push || !services->pop ||
      !services->append || !services->optimize || !services->allocate || !services->duplicate ||
      !services->string || !services->hash_add || !services->hash_after || !services->type ||
      !services->expression || stack && !I386ExpressionStackValid(cc,stack)) return FALSE;
  task=owned->task;
  if(!task) return FALSE;
  frame=GetRBP;
  if(frame<task->stack_base || frame>task->stack_base+task->stack_size ||
      frame-task->stack_base<4096) throw('Compiler',TRUE);
  old_flags=cc->flags;
  if(!ps) {
    irq=I386IrqSave;
    ps=I386HeapAlloc(heap,sizeof(CPrsStk)+sizeof(CI386CodeAllocation),TRUE);
    if(!ps) { I386IrqRestore(irq); throw('OutMem',TRUE); }
    record=ps(U8 *)+sizeof(CPrsStk);
    I386CodeAttach(cc,record,ps,7);
    I386IrqRestore(irq);
  }
  PrsPush(ps,0); PrsPush(ps,0);
  PrsExpression2Core(services,cc,precedence,ps);
  if(!stack) {
    if(ps->ptr) (*services->report)(services->context,cc,0,"Compiler Parse Error at ");
    irq=I386IrqSave;
    release.heap=heap; release.control=cc; release.ok=TRUE;
    I386CodeFree(&release,record);
    I386IrqRestore(irq);
    if(!release.ok) throw('Compiler',TRUE);
  }
  if(end_exp) PrsEmit(services,cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);
  if(cc->coc.coc_head.last->ic_class==services->types[RT_U0])
    (*services->report)(services->context,cc,1,"U0 Expression ");
  cc->flags|=old_flags&(CCF_PREINC|CCF_PREDEC);
  return TRUE;
}
