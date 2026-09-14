#include "/Compiler/I386/Control.HH"
#include "/Compiler/ControlRelease.HC"
#include "/Compiler/CodeCtrl.HC"
#include "/Kernel/I386/Cpu.HH"
#define I386_COMPILER_CONTROL_MAGIC 0x43435431
class CI386CodeAllocation {
  CI386CodeAllocation *next,*last;
  CCmpCtrl *control;
  U8 *allocation;
  U32 kind;
};
class CI386ParserAllocation {
  CI386ParserAllocation *next,*last;
  U8 *allocation;
};
class CI386CmpCtrl {
  CCmpCtrl control;
  CI386Heap *heap;
  U32 signature;
  CI386Task *task;
  U32 active;
  U0 (*document)(U8 *context,CDoc *document);
  U8 *document_context;
  CI386CodeAllocation *code_next,*code_last;
  U32 code_headers,code_busy;
  CI386ParserAllocation *parser_next,*parser_last;
};
Bool I386CmpTaskOwnerValid(CI386Task *task,CI386Heap *heap,CHashTable *symbols)
{
  CI386TaskSymbols *scope;
  if(!task) return TRUE;
  if(!task->owner || !task->symbol_state || task->hash_table!=symbols ||
      I386HeapSize(heap,task->symbol_state)!=sizeof(CI386TaskSymbols)) return FALSE;
  scope=task->symbol_state;
  return scope->task==task && scope->heap==heap && scope->table==symbols &&
    scope->signature==I386_TASK_SYMBOLS_MAGIC;
}
CCmpCtrl *I386CmpCtrlNew(CI386Heap *heap,U8 *buffer,I64 flags,U8 *name,
  CHashTable *symbols,U32 *alpha_numeric,CI386Task *task=0)
{
  U32 irq=I386IrqSave;
  CI386CmpCtrl *owned=0;
  CCmpCtrl *cc;
  CLexFile *file=0;
  U8 *copy=0,*prompt=0;
  I64 i,length=1,size;
  if(!name || !alpha_numeric || !I386CmpTaskOwnerValid(task,heap,symbols) ||
      task && (task->finished || task->finishing || task->compiler_busy || task->lifetime_refs==0xFFFFFFFF)) goto control_new_failed;
  if(buffer && !(flags&(CCF_DONT_FREE_BUF|CCF_PMT))) {
    size=I386HeapSize(heap,buffer);
    if(size<1 || buffer[size-1]) goto control_new_failed;
  }
  while(name[length-1]) {
    if(length>=0xFFFFFFFF-24) goto control_new_failed;
    length++;
  }
  owned=I386HeapAlloc(heap,sizeof(CI386CmpCtrl),TRUE);
  if(!owned) goto control_new_failed;
  cc=&owned->control;
  owned->parser_next=owned->parser_last=&owned->parser_next;
  CmpCtrlSeed(cc,flags,symbols,alpha_numeric);
  COCSeed(&cc->coc);
  owned->code_next=owned->code_last=&owned->code_next;
  file=I386LexFilePush(heap,cc);
  if(!file) goto control_new_failed;
  copy=I386HeapAlloc(heap,length,FALSE);
  if(!copy) goto control_new_failed;
  if(flags&CCF_PMT) {
    prompt=I386HeapAlloc(heap,8,TRUE);
    if(!prompt) goto control_new_failed;
    buffer=prompt;
  }
  for(i=0;i<length;i++) copy[i]=name[i];
  file->full_name=copy;
  LexFileSeed(file,buffer); cc->cur_buf_ptr=buffer;
  owned->heap=heap; owned->signature=I386_COMPILER_CONTROL_MAGIC; owned->task=task;
  if(task) task->lifetime_refs++;
  I386IrqRestore(irq); return cc;
control_new_failed:
  if(prompt) I386HeapFree(heap,prompt);
  if(copy) I386HeapFree(heap,copy);
  if(file) I386HeapFree(heap,file);
  if(owned) I386HeapFree(heap,owned);
  I386IrqRestore(irq); return 0;
}
class CI386CmpRelease {
  CI386Heap *heap;
  U0 (*document)(U8 *context,CDoc *document);
  U8 *context;
  Bool ok;
  CCmpCtrl *control;
  U0 (*label)(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined);
};
U0 I386CmpReleaseAllocation(U8 *context,U8 *allocation)
{
  CI386CmpRelease *state=context;
  CI386CmpCtrl *owned=state->control;
  CI386ParserAllocation *record;
  U32 irq=I386IrqSave;
  if(allocation==state->control) {
    //Graph and lexer cleanup has finished. Reclaim detached parser temporaries.
    while((record=owned->parser_next)!=&owned->parser_next) {
      record->last->next=record->next; record->next->last=record->last;
      if(!I386HeapFree(state->heap,record->allocation)) state->ok=FALSE;
      if(!I386HeapFree(state->heap,record)) state->ok=FALSE;
    }
  } else if(allocation) {
    //A payload release may reach tracked storage before final control cleanup.
    for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
      if(record->allocation==allocation) {
        record->last->next=record->next; record->next->last=record->last;
        if(!I386HeapFree(state->heap,record)) state->ok=FALSE;
        break;
      }
  }
  if(allocation && !I386HeapFree(state->heap,allocation)) state->ok=FALSE;
  I386IrqRestore(irq);
}
U0 I386CmpReleaseDocument(U8 *context,CDoc *document)
{
  CI386CmpRelease *state=context;
  (*state->document)(state->context,document);
}
Bool I386CmpControlValid(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386CmpCtrl *owned=cc;
  return cc && I386HeapSize(heap,cc)==sizeof(CI386CmpCtrl) &&
    owned->heap==heap && owned->signature==I386_COMPILER_CONTROL_MAGIC;
}
#include "/Compiler/I386/Code.HC"
Bool I386CmpActiveValid(CI386CmpCtrl *owned)
{
  CCmpCtrl *cc=&owned->control;
  CI386Task *task=owned->task;
  return task && task->owner && (task->owner->current==task || task->finished) &&
    owned->active && task->active_controls && task->compiler_cleanup==&I386CmpCtrlDrain &&
    cc->next && cc->last && cc->next->last==cc && cc->last->next==cc;
}
U0 I386CmpUnlink(CI386CmpCtrl *owned)
{//Caller holds IRQ exclusion and has validated active links.
  CCmpCtrl *cc=&owned->control;
  CI386Task *task=owned->task;
  cc->last->next=cc->next; cc->next->last=cc->last;
  cc->next=cc->last=cc; owned->active=0;
  owned->document=0; owned->document_context=0;
  task->active_controls--;
  if(!task->active_controls) {
    task->compiler_cleanup=0; task->compiler_cleanup_failed=0;
  }
}
Bool I386CmpCtrlEnter(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0)
{
  U32 irq=I386IrqSave;
  CI386CmpCtrl *owned=cc;
  CI386Task *task;
  if(!I386CmpControlValid(heap,cc)) goto control_enter_failed;
  task=owned->task;
  if(!task || !I386CmpTaskOwnerValid(task,heap,task->hash_table) ||
      task->owner->current!=task || task->finished || task->finishing || task->compiler_busy ||
      task->active_controls==0xFFFFFFFF || owned->active || cc->next!=cc || cc->last!=cc ||
      (task->compiler_cleanup && task->compiler_cleanup!=&I386CmpCtrlDrain)) goto control_enter_failed;
  owned->document=document; owned->document_context=context; owned->active=1;
  cc->next=&task->next_cc; cc->last=task->last_cc;
  cc->last->next=cc; task->last_cc=cc;
  task->active_controls++; task->compiler_cleanup=&I386CmpCtrlDrain;
  I386IrqRestore(irq); return TRUE;
control_enter_failed:
  I386IrqRestore(irq); return FALSE;
}
Bool I386CmpCtrlLeave(CI386Heap *heap,CCmpCtrl *cc)
{
  U32 irq=I386IrqSave;
  CI386CmpCtrl *owned=cc;
  if(!I386CmpControlValid(heap,cc) || !I386CmpActiveValid(owned) || owned->task->compiler_busy) {
    I386IrqRestore(irq); return FALSE;
  }
  I386CmpUnlink(owned);
  I386IrqRestore(irq); return TRUE;
}
Bool I386CmpReleaseReady(CCmpCtrl *cc,U0 (*document)(U8 *context,CDoc *document))
{
  CLexFile *file;
  for(file=cc->lex_include_stk;file;file=file->next)
    if((file->next || !(cc->flags&CCF_DONT_FREE_BUF)) && file->flags&LFSF_DOC && file->doc && !document)
      return FALSE;
  return TRUE;
}
Bool I386CmpCtrlDelete(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document),U8 *context,Bool draining)
{
  CI386CmpCtrl *owned=cc;
  CI386Task *task;
  CLexFileRelease owner;
  CI386CmpRelease state;
  U32 irq=I386IrqSave;
  if(!I386CmpControlValid(heap,cc) || owned->code_busy) goto control_delete_failed;
  task=owned->task;
  if(task && (!task->lifetime_refs || !I386CmpTaskOwnerValid(task,heap,task->hash_table) ||
      task->compiler_busy && !draining)) goto control_delete_failed;
  if(owned->active && !I386CmpActiveValid(owned)) goto control_delete_failed;
  if(!I386CmpReleaseReady(cc,document)) goto control_delete_failed;
  if(owned->active) I386CmpUnlink(owned);
  owned->signature=0;
  if(task) task->compiler_busy=1;
  I386IrqRestore(irq);
  state.heap=heap; state.document=document; state.context=context; state.ok=TRUE; state.control=cc;
  owner.context=&state; owner.allocation=&I386CmpReleaseAllocation; owner.document=&I386CmpReleaseDocument;
  I386CmpCodeRelease(cc,&state);
  CmpCtrlRelease(cc,&owner);
  irq=I386IrqSave;
  if(task) { task->lifetime_refs--; if(!draining) task->compiler_busy=0; }
  I386IrqRestore(irq);
  return state.ok;
control_delete_failed:
  I386IrqRestore(irq); return FALSE;
}
Bool I386CmpCtrlDel(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0)
{
  return I386CmpCtrlDelete(heap,cc,document,context,FALSE);
}
Bool I386CmpCtrlUnwind(CI386Task *task,CCmpCtrl *boundary)
{//Explicit compiler catch boundary. Preflight the suffix before any release.
  U32 irq=I386IrqSave,count;
  CI386CmpCtrl *owned;
  CCmpCtrl *node;
  CI386TaskSymbols *scope;
  Bool ok=TRUE;
  if(!task || !boundary || !task->owner || task->compiler_busy ||
      (task->owner->current!=task && !task->finished)) goto control_drain_failed;
  if(!task->active_controls) {
    ok=boundary==&task->next_cc && task->next_cc==&task->next_cc && task->last_cc==&task->next_cc && !task->compiler_cleanup;
    I386IrqRestore(irq); return ok;
  }
  scope=task->symbol_state;
  if(!scope || !I386CmpTaskOwnerValid(task,scope->heap,task->hash_table)) goto control_drain_failed;
  node=task->last_cc;
  for(count=0;node!=boundary;count++) {
    if(count>=task->active_controls || node==&task->next_cc || !I386CmpControlValid(scope->heap,node)) goto control_drain_failed;
    owned=node;
    if(owned->task!=task || !I386CmpActiveValid(owned) ||
        !I386CmpReleaseReady(node,owned->document)) goto control_drain_failed;
    node=node->last;
  }
  if(boundary!=&task->next_cc) {
    if(!I386CmpControlValid(scope->heap,boundary)) goto control_drain_failed;
    owned=boundary;
    if(owned->task!=task || !I386CmpActiveValid(owned)) goto control_drain_failed;
  }
  task->compiler_busy=1;
  I386IrqRestore(irq);
  while(count) {
    owned=task->last_cc;
    if(!I386CmpCtrlDelete(scope->heap,&owned->control,owned->document,owned->document_context,TRUE)) {
      ok=FALSE; break;
    }
    count--;
  }
  irq=I386IrqSave; task->compiler_busy=0;
  if(!ok) task->compiler_cleanup_failed=1;
  I386IrqRestore(irq); return ok;
control_drain_failed:
  I386IrqRestore(irq); return FALSE;
}
Bool I386CmpCtrlDrain(CI386Task *task)
{
  if(!task) return FALSE;
  return I386CmpCtrlUnwind(task,&task->next_cc);
}
