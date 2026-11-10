#include "/Compiler/I386/Emit.HH"
//Included by Control.HC after its private control and release-state declarations.
class CI386OwnedIC { CIntermediateCode node; CI386CodeAllocation lifetime; };
class CI386OwnedMisc { CCodeMisc node; CI386CodeAllocation lifetime; };
class CI386OwnedCode { CCodeCtrl header; CI386CodeAllocation lifetime; };
//Kinds 1..7 include the parser's owned pass stack. Keep segmented headers distinct.
#define I386_CODE_SEGMENTED_OUT 8
//The native emitter stores machine bytes in CI386Out, not the original ic_body.
//Private frontend nodes need all tree links, but no unused machine-byte tail.
//Keep public I386ICAdd allocations complete and preserve every field offset.
#define I386_FRONTEND_IC_BYTES ((offset(CIntermediateCode.t)+sizeof(CICTreeLinks)+3)&~3)
//The following lifetime has only 32-bit pointers/words. Four-byte alignment
//retains every tree byte and avoids an extra eight-byte heap span per node.
#assert I386_FRONTEND_IC_BYTES>=offset(CIntermediateCode.t)+sizeof(CICTreeLinks)
#assert !(I386_FRONTEND_IC_BYTES&3)
#define I386_CODE_IC_SLAB 9
#define I386_IC_SLAB_SLOTS 160
#define I386_IC_SLAB_SLOT_BYTES ((I386_FRONTEND_IC_BYTES+sizeof(CI386CodeAllocation)+7)&~7)
class CI386ICSlab {
  CI386CodeAllocation lifetime;
  CI386ICSlab *next;
  U32 capacity,issued,live;
  CIntermediateCode *free_nodes;
  U8 body[1];
};
CI386ICSlab *I386ICSlabFind(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node)
{//Only registered slabs can admit an interior node; never trust a nearby header.
  CI386CmpCtrl *owned=cc;
  CI386ICSlab *slab;
  U64 address=(node+0)(U64),base,distance;
  for(slab=owned->ic_slabs;slab;slab=slab->next) {
    base=(slab->body+0)(U64);
    if(address>=base) {
      distance=address-base;
      if(distance<slab->issued*I386_IC_SLAB_SLOT_BYTES && !(distance%I386_IC_SLAB_SLOT_BYTES)) {
        if(slab->lifetime.control!=cc || slab->lifetime.allocation!=slab ||
            slab->lifetime.kind!=I386_CODE_IC_SLAB || slab->issued>slab->capacity ||
            slab->live>slab->issued || !slab->capacity || slab->capacity>I386_IC_SLAB_SLOTS ||
            I386HeapSize(heap,slab)!=offset(CI386ICSlab.body)+slab->capacity*I386_IC_SLAB_SLOT_BYTES)
          return 0;
        return slab;
      }
    }
  }
  return 0;
}
CI386CodeAllocation *I386ICLifetime(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node)
{
  I64 bytes;
  CI386ICSlab *slab;
  CI386CodeAllocation *record;
  if(!node) return 0;
  if(slab=I386ICSlabFind(heap,cc,node)) {
    record=node(U8 *)+I386_FRONTEND_IC_BYTES;
    if(record->control==cc && record->allocation==node && (record->kind==1 || record->kind==4))
      return record;
    return 0;
  }
  bytes=I386HeapSize(heap,node);
  if(bytes==sizeof(CI386OwnedIC)) return &node(CI386OwnedIC *)->lifetime;
  if(bytes==I386_FRONTEND_IC_BYTES+sizeof(CI386CodeAllocation))
    return node(U8 *)+I386_FRONTEND_IC_BYTES;
  return 0;
}

#include "/Kernel/I386/HeapKnown.HC"
Bool I386CmpCodeOwner(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386CmpCtrl *owned=cc;
  CI386Task *task;
  CI386TaskSymbols *scope;
  U32 irq=I386IrqSave;
  Bool result=FALSE;
  if(!I386CmpControlValid(heap,cc) || owned->code_busy) goto done;
  task=owned->task;
  if(!task) { result=TRUE; goto done; }
  if(!task->owner || !(scope=task->symbol_state) ||
      !I386HeapKnownSize(heap,scope,sizeof(CI386TaskSymbols)) ||
      scope->task!=task || scope->heap!=heap || scope->signature!=I386_TASK_SYMBOLS_MAGIC ||
      !I386CompilerScopeLinked(task->hash_table,scope->table)) goto done;
  result=task->owner->current==task && !task->finished && !task->finishing && !task->compiler_busy;
done:
  I386IrqRestore(irq); return result;
}
Bool I386COCInit(CI386Heap *heap,CCmpCtrl *cc)
{
  U32 irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc)) { I386IrqRestore(irq); return FALSE; }
  COCSeed(&cc->coc);
  I386IrqRestore(irq); return TRUE;
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
  CI386ICSlab *slab,**link;
  if(record->control!=state->control || record->last->next!=record || record->next->last!=record) {
    state->ok=FALSE; return;
  }
  if(record->kind==1 || record->kind==4) {
    slab=I386ICSlabFind(state->heap,state->control,allocation);
    if(slab) {
      if(!slab->live || record!=allocation+I386_FRONTEND_IC_BYTES) {state->ok=FALSE;return;}
      record->last->next=record->next;record->next->last=record->last;
      record->kind=0;slab->live--;
      allocation(CIntermediateCode *)->next=slab->free_nodes;
      slab->free_nodes=allocation;
      return;
    }
  }
  if(record->kind==I386_CODE_IC_SLAB) {
    slab=allocation;link=&owned->ic_slabs;
    if(slab->live) {state->ok=FALSE;return;}
    while(*link && *link!=slab)link=&(*link)->next;
    if(*link!=slab) {state->ok=FALSE;return;}
    *link=slab->next;
  }
  record->last->next=record->next; record->next->last=record->last;
  if(record->kind==3) owned->code_headers--;
  I386CmpReleaseAllocation(state,allocation);
}
U0 I386ICSlabsCollect(CI386CmpRelease *state)
{//Free only after slot iteration: saved next-record pointers can be in a slab.
  CI386CmpCtrl *owned=state->control;
  CI386ICSlab *slab=owned->ic_slabs,*next;
  while(slab) {
    next=slab->next;
    if(!slab->live)I386CodeFree(state,&slab->lifetime);
    if(!state->ok)return;
    slab=next;
  }
}
U0 I386CodeFreeIC(U8 *context,CIntermediateCode *node)
{
  CI386CmpRelease *state=context;
  CI386CmpCtrl *owned=state->control;
  CI386CodeAllocation *record;
  //Discard already owns the graph. Locate its registered lifetime instead of
  //adding a whole-arena size scan for each node; release still validates the
  //record links/control and the heap allocation before freeing it.
  for(record=owned->code_next;record!=&owned->code_next;record=record->next)
    if(record->allocation==node && (record->kind==1 || record->kind==4)) {
      I386CodeFree(context,record); return;
    }
  state->ok=FALSE;
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
CIntermediateCode *I386ICSlabSlot(CI386Heap *heap,CCmpCtrl *cc)
{//Owner/arena already validated with IRQs excluded. No fixed node-count limit.
  CI386CmpCtrl *owned=cc;
  CI386ICSlab *slab;
  CI386HeapBlock *block;
  CIntermediateCode *node;
  U32 position=0,capacity=0,slots;
  for(slab=owned->ic_slabs;slab;slab=slab->next)
    if(slab->free_nodes || slab->issued<slab->capacity)break;
  if(!slab) {
    while(position<heap->size) {
      block=heap->base+position;
      if(block->tag==I386_HEAP_FREE && block->span>16+offset(CI386ICSlab.body)) {
        slots=(block->span-16-offset(CI386ICSlab.body))/I386_IC_SLAB_SLOT_BYTES;
        if(slots>capacity)capacity=slots;
        if(capacity>=I386_IC_SLAB_SLOTS) {capacity=I386_IC_SLAB_SLOTS;break;}
      }
      position+=block->span;
    }
    //One-slot slabs cost more than the existing individual compact allocation.
    if(capacity<2)return 0;
    slab=I386HeapAlloc(heap,offset(CI386ICSlab.body)+capacity*I386_IC_SLAB_SLOT_BYTES,FALSE);
    if(!slab)return 0;
    slab->capacity=capacity;slab->issued=slab->live=0;slab->free_nodes=0;
    slab->next=owned->ic_slabs;owned->ic_slabs=slab;
    I386CodeAttach(cc,&slab->lifetime,slab,I386_CODE_IC_SLAB);
  }
  if(node=slab->free_nodes)slab->free_nodes=node->next;
  else {
    node=slab->body+slab->issued*I386_IC_SLAB_SLOT_BYTES;slab->issued++;
  }
  slab->live++;
  return node;
}
CIntermediateCode *I386ICAddBytes(CI386Heap *heap,CCmpCtrl *cc,
  I64 opcode,I64 arg,CHashClass *type,I64 flags,I64 node_bytes)
{
  U32 irq=I386IrqSave;
  CIntermediateCode *node=0;
  CI386CodeAllocation *record;
  if(I386CmpCodeOwner(heap,cc)) {
    if(node_bytes==I386_FRONTEND_IC_BYTES)node=I386ICSlabSlot(heap,cc);
    if(!node)node=I386HeapAlloc(heap,node_bytes+sizeof(CI386CodeAllocation),FALSE);
    if(node) {
      record=node(U8 *)+node_bytes;
      I386CodeAttach(cc,record,node,1);
      ICSeed(cc,node,opcode,arg,type,flags);
    }
  }
  I386IrqRestore(irq); return node;
}
CIntermediateCode *I386ICAdd(CI386Heap *heap,CCmpCtrl *cc,
  I64 opcode,I64 arg,CHashClass *type,I64 flags=0)
{
  return I386ICAddBytes(heap,cc,opcode,arg,type,flags,sizeof(CIntermediateCode));
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
  CI386CodeAllocation *record;
  if(!I386CmpCodeOwner(heap,cc) || !(record=I386ICLifetime(heap,cc,node)) ||
      record->control!=cc || record->allocation!=node || record->kind!=1 ||
      !node->next || !node->last || node->next==node || node->last==node ||
      node->next->last!=node || node->last->next!=node) {
    I386IrqRestore(irq); return FALSE;
  }
  ICDetach(node); record->kind=4;
  I386IrqRestore(irq); return TRUE;
}
U0 I386CodeRetiredCollect(CI386CmpRelease *state)
{//A completed discard is the collection boundary. Slabs contain no IR roots.
  CI386CmpCtrl *owned=state->control;
  CI386CodeAllocation *record,*next;
  I386ICSlabsCollect(state);
  if(!state->ok)return;
  for(record=owned->code_next;record!=&owned->code_next;record=record->next)
    if(record->kind!=4 && record->kind!=I386_CODE_IC_SLAB)return;
  record=owned->code_next;
  while(record!=&owned->code_next) {
    next=record->next;
    if(record->kind==4)I386CodeFree(state,record);
    if(!state->ok)return;
    record=next;
  }
  I386ICSlabsCollect(state);
}
Bool I386COCInstructionsRelease(CI386Heap *heap,CCmpCtrl *cc)
{//Emission is complete. Linking still borrows misc payloads and import metadata.
  U32 irq=I386IrqSave;
  CI386CmpRelease state;
  CI386CmpCtrl *control=cc;
  CIntermediateCode *node;
  CI386CodeAllocation *record,*next;
  Bool live=FALSE;
  if(!I386CmpCodeOwner(heap,cc)) { I386IrqRestore(irq); return FALSE; }
  control->code_busy=1;if(control->task)control->task->compiler_busy=1;
  state.heap=heap;state.control=cc;state.ok=TRUE;
  I386IrqRestore(irq);
  while((node=cc->coc.coc_head.next)!=&cc->coc.coc_head.next) {
    irq=I386IrqSave;ICDetach(node);I386CodeFreeIC(&state,node);I386IrqRestore(irq);
    if(!state.ok)break;
  }
  //A saved outer graph may still borrow retired tree operands. With no live
  //IR records anywhere in this control, no such tree can remain. Misc payloads,
  //saved headers, output buffers and relocation records do not contain IR roots.
  for(record=control->code_next;record!=&control->code_next;record=record->next)
    if(record->kind==1) {live=TRUE;break;}
  if(state.ok && !live) {
    record=control->code_next;
    while(record!=&control->code_next) {
      next=record->next;
      if(record->kind==4) {
        irq=I386IrqSave;I386CodeFree(&state,record);I386IrqRestore(irq);
        if(!state.ok)break;
      }
      record=next;
    }
  }
  irq=I386IrqSave;
  if(state.ok)I386ICSlabsCollect(&state);
  control->code_busy=0;if(control->task)control->task->compiler_busy=0;
  I386IrqRestore(irq);return state.ok;
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
  if(state.ok) I386ICSlabsCollect(&state);
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
Bool I386CodeHeaderKnownValid(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{//Only after CodeOwner audits this unchanged arena, with IRQ exclusion held.
  CI386OwnedCode *saved=header;
  return header && I386HeapKnownSize(heap,header,sizeof(CI386OwnedCode)) &&
    saved->lifetime.control==cc && saved->lifetime.kind==3 && saved->lifetime.allocation==header;
}
CCodeCtrl *I386COCPopNoFree(CI386Heap *heap,CCmpCtrl *cc)
{
  U32 irq=I386IrqSave;
  CCodeCtrl *saved=0;
  if(I386CmpCodeOwner(heap,cc) && I386CodeHeaderKnownValid(heap,cc,cc->coc.coc_next)) saved=COCRestore(cc);
  I386IrqRestore(irq); return saved;
}
Bool I386CodeHeaderKnownDetached(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{//Same validated arena and exclusion as CodeHeaderKnownValid; no mutation.
  CI386CmpCtrl *owned=cc;
  CCodeCtrl *node=cc->coc.coc_next;
  U32 count=0;
  while(node) {
    if(count++>=owned->code_headers || node==header || !I386CodeHeaderKnownValid(heap,cc,node)) return FALSE;
    node=node->coc_next;
  }
  return TRUE;
}
Bool I386COCHeaderFree(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{//Free only the header view. Its IR remains owned independently by the control.
  U32 irq=I386IrqSave;
  CI386OwnedCode *saved=header;
  CI386CmpRelease state;
  if(!I386CmpCodeOwner(heap,cc) || !I386CodeHeaderKnownValid(heap,cc,header) ||
      !I386CodeHeaderKnownDetached(heap,cc,header)) { I386IrqRestore(irq); return FALSE; }
  state.heap=heap; state.ok=TRUE; state.control=cc;
  I386CodeFree(&state,&saved->lifetime);
  I386IrqRestore(irq); return state.ok;
}
Bool I386COCAppend(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header)
{
  U32 irq=I386IrqSave;
  Bool ok;
  if(!I386CmpCodeOwner(heap,cc) || !I386CodeHeaderKnownValid(heap,cc,header) ||
      !I386CodeHeaderKnownDetached(heap,cc,header)) { I386IrqRestore(irq); return FALSE; }
  COCJoin(cc,header);
  ok=I386COCHeaderFree(heap,cc,header);
  I386IrqRestore(irq); return ok;
}
//Implemented by NativeEmit.HC in the same retained module. Control teardown
//must release raw segmented chunks before retiring their registered header.
extern Bool I386OutChunksRelease(CI386Heap *heap,CI386Out *out);
U0 I386CmpCodeRelease(CCmpCtrl *cc,CI386CmpRelease *state)
{//Walk allocation ownership, never potentially aliased or detached queue views.
  CI386CmpCtrl *owned=cc;
  CI386CodeAllocation *record;
  CCodeMisc *cm;
  CSymbolRelease owner;
  owner.context=state; owner.release=&I386CmpReleaseAllocation;
  while(owned->code_next!=&owned->code_next) {
    record=owned->code_next;
    //Drain slot lifetimes first, including detached/saved graphs. Empty slab
    //headers can then be released without following invalidated slot records.
    while(record!=&owned->code_next && record->kind==I386_CODE_IC_SLAB)record=record->next;
    if(record==&owned->code_next)record=owned->code_next;
    if(record->kind==2) {
      cm=record->allocation; COCPayloadRelease(cm,&owner);
      (*owner.release)(owner.context,cm->str);
    }
    if(record->kind==I386_CODE_SEGMENTED_OUT && !I386OutChunksRelease(state->heap,record->allocation)) {
      state->ok=FALSE;return;
    }
    if(record->kind==5) I386CmpReleaseAllocation(state,record->allocation(CI386Out *)->data);
    I386CodeFree(state,record);
    if(!state->ok) return;
  }
  cc->coc.coc_next=0; COCSeed(&cc->coc);
}
