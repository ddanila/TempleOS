#include "/Compiler/I386/Control.HH"
#include "/Compiler/ControlRelease.HC"
#include "/Kernel/I386/Cpu.HH"
#define I386_COMPILER_CONTROL_MAGIC 0x43435431
class CI386CmpCtrl {
  CCmpCtrl control;
  CI386Heap *heap;
  U32 signature;
  CI386Task *task;
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
      task && (task->finished || task->finishing || task->lifetime_refs==0xFFFFFFFF)) goto control_new_failed;
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
  CmpCtrlSeed(cc,flags,symbols,alpha_numeric);
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
};
U0 I386CmpReleaseAllocation(U8 *context,U8 *allocation)
{
  CI386CmpRelease *state=context;
  U32 irq=I386IrqSave;
  if(allocation && !I386HeapFree(state->heap,allocation)) state->ok=FALSE;
  I386IrqRestore(irq);
}
U0 I386CmpReleaseDocument(U8 *context,CDoc *document)
{
  CI386CmpRelease *state=context;
  (*state->document)(state->context,document);
}
Bool I386CmpCtrlDel(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0)
{
  CI386CmpCtrl *owned=cc;
  CI386Task *task;
  CLexFile *file;
  CLexFileRelease owner;
  CI386CmpRelease state;
  U32 irq=I386IrqSave;
  if(!cc || I386HeapSize(heap,cc)!=sizeof(CI386CmpCtrl) || owned->heap!=heap ||
      owned->signature!=I386_COMPILER_CONTROL_MAGIC) { I386IrqRestore(irq); return FALSE; }
  task=owned->task;
  if(task && (!task->lifetime_refs || !I386CmpTaskOwnerValid(task,heap,task->hash_table))) {
    I386IrqRestore(irq); return FALSE;
  }
  for(file=cc->lex_include_stk;file;file=file->next)
    if((file->next || !(cc->flags&CCF_DONT_FREE_BUF)) && file->flags&LFSF_DOC && file->doc && !document) {
      I386IrqRestore(irq); return FALSE;
    }
  owned->signature=0;
  I386IrqRestore(irq);
  state.heap=heap; state.document=document; state.context=context; state.ok=TRUE;
  owner.context=&state; owner.allocation=&I386CmpReleaseAllocation; owner.document=&I386CmpReleaseDocument;
  CmpCtrlRelease(cc,&owner);
  irq=I386IrqSave;
  if(task) task->lifetime_refs--;
  I386IrqRestore(irq);
  return state.ok;
}
