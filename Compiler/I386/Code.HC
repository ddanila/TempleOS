//Included by Control.HC after its private control and release-state declarations.
class CI386OwnedIC { CIntermediateCode node; CI386CodeAllocation lifetime; };
class CI386OwnedMisc { CCodeMisc node; CI386CodeAllocation lifetime; };
class CI386OwnedCode { CCodeCtrl header; CI386CodeAllocation lifetime; };
Bool I386CmpCodeOwner(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386CmpCtrl *owned=cc;
  CI386Task *task;
  if(!I386CmpControlValid(heap,cc) || owned->code_busy) return FALSE;
  task=owned->task;
  return !task || (I386CmpTaskOwnerValid(task,heap,task->hash_table) &&
    task->owner->current==task && !task->finished && !task->finishing && !task->compiler_busy);
}
U0 I386CodeAttach(CCmpCtrl *cc,CI386CodeAllocation *record,U8 *allocation,U32 kind)
{
  CI386CmpCtrl *owned=cc;
  record->control=cc; record->allocation=allocation; record->kind=kind;
  record->last=owned->code_last; record->next=&owned->code_next;
  record->last->next=record; owned->code_last=record;
  if(kind==3) owned->code_headers++;
}
U0 I386CodeFree(CI386CmpRelease *state,CI386CodeAllocation *record)
{
  CI386CmpCtrl *owned=state->control;
  U8 *allocation=record->allocation;
  if(record->control!=state->control || record->last->next!=record || record->next->last!=record) {
    state->ok=FALSE; return;
  }
  record->last->next=record->next; record->next->last=record->last;
  if(record->kind==3) owned->code_headers--;
  I386CmpReleaseAllocation(state,allocation);
}
U0 I386CodeFreeIC(U8 *context,CIntermediateCode *node)
{
  CI386OwnedIC *owned=node;
  I386CodeFree(context,&owned->lifetime);
}
U0 I386CodeFreeMisc(U8 *context,CCodeMisc *node)
{
  CI386OwnedMisc *owned=node;
  I386CodeFree(context,&owned->lifetime);
}
U0 I386CodeLabel(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)
{
  CI386CmpRelease *state=context;
  if(state->label) (*state->label)(state->context,cc,name,undefined);
}
CIntermediateCode *I386ICAdd(CI386Heap *heap,CCmpCtrl *cc,
  I64 opcode,I64 arg,CHashClass *type,I64 flags=0)
{
  U32 irq=I386IrqSave;
  CI386OwnedIC *owned=0;
  if(I386CmpCodeOwner(heap,cc)) {
    owned=I386HeapAlloc(heap,sizeof(CI386OwnedIC),FALSE);
    if(owned) {
      I386CodeAttach(cc,&owned->lifetime,owned,1);
      ICSeed(cc,&owned->node,opcode,arg,type,flags);
    }
  }
  I386IrqRestore(irq); return owned;
}
CCodeMisc *I386COCMiscNew(CI386Heap *heap,CCmpCtrl *cc,I64 type)
{
  U32 irq=I386IrqSave;
  CI386OwnedMisc *owned=0;
  if(type>=CMT_LABEL && type<=CMT_HASH_ENTRY && I386CmpCodeOwner(heap,cc)) {
    owned=I386HeapAlloc(heap,sizeof(CI386OwnedMisc),TRUE);
    if(owned) {
      I386CodeAttach(cc,&owned->lifetime,owned,2);
      COCMiscSeed(cc,&owned->node,type);
    }
  }
  I386IrqRestore(irq); return owned;
}
Bool I386ICRetire(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node)
{
  U32 irq=I386IrqSave;
  CI386OwnedIC *owned=node;
  if(!I386CmpCodeOwner(heap,cc) || !node || I386HeapSize(heap,node)!=sizeof(CI386OwnedIC) ||
      owned->lifetime.control!=cc || owned->lifetime.allocation!=node || owned->lifetime.kind!=1 ||
      !node->next || !node->last || node->next==node || node->last==node ||
      node->next->last!=node || node->last->next!=node) {
    I386IrqRestore(irq); return FALSE;
  }
  ICDetach(node); owned->lifetime.kind=4;
  I386IrqRestore(irq); return TRUE;
}
U0 I386CodeRetiredCollect(CI386CmpRelease *state)
{//A completed discard is the collection boundary. Any other record defers it.
  CI386CmpCtrl *owned=state->control;
  CI386CodeAllocation *record;
  for(record=owned->code_next;record!=&owned->code_next;record=record->next)
    if(record->kind!=4) return;
  while((record=owned->code_next)!=&owned->code_next) {
    I386CodeFree(state,record);
    if(!state->ok) return;
  }
}
Bool I386COCDiscard(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*label)(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)=0,U8 *context=0)
{//Only the current valid graph; callers must not restore a discarded view.
  U32 irq=I386IrqSave;
  CI386CmpRelease state;
  CSymbolRelease owner;
  CI386CmpCtrl *control=cc;
  if(!I386CmpCodeOwner(heap,cc)) { I386IrqRestore(irq); return FALSE; }
  control->code_busy=1; if(control->task) control->task->compiler_busy=1;
  state.heap=heap; state.ok=TRUE; state.control=cc; state.label=label; state.context=context;
  owner.context=&state; owner.release=&I386CmpReleaseAllocation;
  I386IrqRestore(irq);
  COCRelease(cc,&cc->coc,&owner,&I386CodeLabel,&I386CodeFreeIC,&I386CodeFreeMisc);
  irq=I386IrqSave;
  if(state.ok) I386CodeRetiredCollect(&state);
  control->code_busy=0; if(control->task) control->task->compiler_busy=0;
  I386IrqRestore(irq); return state.ok;
}
CCodeCtrl *I386COCSave(CI386Heap *heap,CCmpCtrl *cc)
{//Allocate a registered header view without changing the active stack or lists.
  U32 irq=I386IrqSave;
  CI386OwnedCode *saved=0;
  CI386CmpCtrl *owned=cc;
  if(I386CmpCodeOwner(heap,cc) && owned->code_headers!=0xFFFFFFFF) {
    saved=I386HeapAlloc(heap,sizeof(CI386OwnedCode),FALSE);
    if(saved) { COCCopy(&saved->header,&cc->coc); I386CodeAttach(cc,&saved->lifetime,saved,3); }
  }
  I386IrqRestore(irq); return saved;
}
Bool I386COCPush(CI386Heap *heap,CCmpCtrl *cc)
{
  U32 irq=I386IrqSave;
  CCodeCtrl *saved=I386COCSave(heap,cc);
  if(saved) cc->coc.coc_next=saved;
  I386IrqRestore(irq); return saved!=0;
}
Bool I386CodeHeaderValid(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{
  CI386OwnedCode *saved=header;
  return header && I386HeapSize(heap,header)==sizeof(CI386OwnedCode) &&
    saved->lifetime.control==cc && saved->lifetime.kind==3 && saved->lifetime.allocation==header;
}
CCodeCtrl *I386COCPopNoFree(CI386Heap *heap,CCmpCtrl *cc)
{
  U32 irq=I386IrqSave;
  CCodeCtrl *saved=0;
  if(I386CmpCodeOwner(heap,cc) && I386CodeHeaderValid(heap,cc,cc->coc.coc_next)) saved=COCRestore(cc);
  I386IrqRestore(irq); return saved;
}
Bool I386CodeHeaderDetached(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{
  CI386CmpCtrl *owned=cc;
  CCodeCtrl *node=cc->coc.coc_next;
  U32 count=0;
  while(node) {
    if(count++>=owned->code_headers || node==header || !I386CodeHeaderValid(heap,cc,node)) return FALSE;
    node=node->coc_next;
  }
  return TRUE;
}
Bool I386COCHeaderFree(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{//Free only the header view. Its IR remains owned independently by the control.
  U32 irq=I386IrqSave;
  CI386OwnedCode *saved=header;
  CI386CmpRelease state;
  if(!I386CmpCodeOwner(heap,cc) || !I386CodeHeaderValid(heap,cc,header) ||
      !I386CodeHeaderDetached(heap,cc,header)) { I386IrqRestore(irq); return FALSE; }
  state.heap=heap; state.ok=TRUE; state.control=cc;
  I386CodeFree(&state,&saved->lifetime);
  I386IrqRestore(irq); return state.ok;
}
Bool I386COCAppend(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{
  U32 irq=I386IrqSave;
  Bool ok;
  if(!I386CmpCodeOwner(heap,cc) || !I386CodeHeaderValid(heap,cc,header) ||
      !I386CodeHeaderDetached(heap,cc,header)) { I386IrqRestore(irq); return FALSE; }
  COCJoin(cc,header);
  ok=I386COCHeaderFree(heap,cc,header);
  I386IrqRestore(irq); return ok;
}
U0 I386CmpCodeRelease(CCmpCtrl *cc,CI386CmpRelease *state)
{//Walk allocation ownership, never potentially aliased or detached queue views.
  CI386CmpCtrl *owned=cc;
  CI386CodeAllocation *record;
  CCodeMisc *cm;
  CSymbolRelease owner;
  owner.context=state; owner.release=&I386CmpReleaseAllocation;
  while((record=owned->code_next)!=&owned->code_next) {
    if(record->kind==2) {
      cm=record->allocation; COCPayloadRelease(cm,&owner);
      (*owner.release)(owner.context,cm->str);
    }
    I386CodeFree(state,record);
    if(!state->ok) return;
  }
  cc->coc.coc_next=0; COCSeed(&cc->coc);
}
