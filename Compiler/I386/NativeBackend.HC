//Included after native control, optimizer and output-buffer implementations.
#include "/Compiler/I386/NativeBackend.HH"
#define I386_DIV_KEEP32 1
#include "/Compiler/I386/Divide.HC"
#include "/Compiler/CodeLabel.HC"
#include "/Compiler/I386/BackendCore.HC"
#include "/Compiler/I386/AsmCore.HC"
class CI386NativeBackend {
  CI386Backend backend;
  CI386Heap *heap;
};
U8 *I386NativeBackendAlloc(U8 *context,I64 bytes)
{
  CI386NativeBackend *state=context;
  CI386CodeAllocation *record;
  U8 *result;
  U32 irq=I386IrqSave;
  I64 aligned;
  if(!I386CmpCodeOwner(state->heap,state->backend.cc) || bytes<1 || bytes>0x7FFFFFFF-32) {
    I386IrqRestore(irq); throw('Compiler',TRUE);
  }
  aligned=(bytes+7)&~7;
  result=I386HeapAlloc(state->heap,aligned+sizeof(CI386CodeAllocation),TRUE);
  if(!result) { I386IrqRestore(irq); throw('OutMem',TRUE); }
  record=result+aligned;
  I386CodeAttach(state->backend.cc,record,result,6);
  I386IrqRestore(irq); return result;
}
U0 I386NativeBackendFree(U8 *context,U8 *allocation)
{
  CI386NativeBackend *state=context;
  CI386CmpCtrl *owned=state->backend.cc;
  CI386CodeAllocation *record;
  CI386CmpRelease release;
  U32 irq=I386IrqSave;
  if(!allocation) { I386IrqRestore(irq); return; }
  if(!I386CmpCodeOwner(state->heap,state->backend.cc)) {
    I386IrqRestore(irq); throw('Compiler',TRUE);
  }
  for(record=owned->code_next;record!=&owned->code_next;record=record->next)
    if(record->allocation==allocation && record->kind==6) {
      release.heap=state->heap; release.control=state->backend.cc; release.ok=TRUE;
      I386CodeFree(&release,record);
      I386IrqRestore(irq);
      if(!release.ok) throw('Compiler',TRUE);
      return;
    }
  I386IrqRestore(irq); throw('Compiler',TRUE);
}
U0 I386NativeBackendFold(U8 *context,CCmpCtrl *cc)
{
  CI386NativeBackend *state=context;
  I386OptPass012(state->heap,cc,state->backend.types);
}
U0 I386NativeBackendAsm(U8 *context,CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass)
{
  CI386NativeBackend *state=context;
  I386AsmCore(&state->backend,cc,out,aot,pass);
}
U0 I386NativeBackendReport(U8 *context,I64 reason,CIntermediateCode *ic,U8 *name)
{
  CI386NativeBackend *state=context;
  state->backend.cc->error_cnt++;
  if(state->backend.status) state->backend.status->reason=reason;
}
U0 I386NativeBackendListFree(CI386NativeBackend *state,U8 *head)
{
  U8 *next;
  while(head) { next=head(U8 **)[0]; I386NativeBackendFree(state,head); head=next; }
}
Bool I386BackendCompile(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386Out *out,CI386BackendStatus *status=0)
{
  CI386NativeBackend state;
  CI386Backend *backend=&state.backend;
  I64 i;
  U8 *bytes=&state;
  if(!I386OutValid(heap,cc,out) || out->count || !cc->aot || !cc->aotc || !cc->htc.fun ||
      !(cc->flags&CCF_AOT_COMPILE) || cc->flags&(CCF_TARGET_HOST_CONST|CCF_EXE_BLK) ||
      !types || !types[RT_I64] || !types[RT_U64] || !types[RT_F64] ||
      types[RT_I64]->raw_type!=RT_I64 || types[RT_U64]->raw_type!=RT_U64 ||
      types[RT_F64]->raw_type!=RT_F64) return FALSE;
  for(i=0;i<sizeof(state);i++) bytes[i]=0;
  state.heap=heap;
  if(status) { status->node=0; status->depth=0; status->pass=-2; status->reason=0; }
  backend->status=status;
  backend->cc=cc; backend->out=out; backend->types=types; backend->context=&state;
  backend->allocate=&I386NativeBackendAlloc; backend->release=&I386NativeBackendFree;
  backend->fold=&I386NativeBackendFold; backend->assembly=&I386NativeBackendAsm;
  backend->report=&I386NativeBackendReport;
  cc->flags|=CCF_TARGET_I386;
  I386BackendCore(backend);
  if(status) status->pass=2;
  I386NativeBackendListFree(&state,backend->calls);
  I386NativeBackendListFree(&state,backend->logics);
  I386NativeBackendListFree(&state,backend->chains);
  if(status) status->reason=0;
  return TRUE;
}
