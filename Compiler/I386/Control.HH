#ifndef I386_COMPILER_CONTROL_INCLUDED
#define I386_COMPILER_CONTROL_INCLUDED
#include "/Compiler/ControlInit.HH"
#include "/Compiler/CodeCtrl.HH"
#include "/Compiler/I386/LexFiles.HH"
#include "/Kernel/I386/TaskSymbols.HH"
//Native allocation boundary. Name is already resolved and bitmap already selected.
//Borrow name/symbols/bitmap; copy name. Transfer buffer only on success, unless
//DONT_FREE_BUF borrows it or PMT replaces it with a fresh eight-byte input buffer.
public extern CCmpCtrl *I386CmpCtrlNew(CI386Heap *heap,U8 *buffer,I64 flags,U8 *name,
  CHashTable *symbols,U32 *alpha_numeric,CI386Task *task=0);
//Exclusive control and allocation graph. Source/doc ownership follows public flags.
//Reject missing document release before mutation. No arbitrary corruption recovery.
public extern Bool I386CmpCtrlDel(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0);
//Active queue operations require the current owner, or a finished owner for
//leave/drain/recovery. Callbacks must return normally; no throwing through cleanup.
public extern Bool I386CmpCtrlEnter(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*document)(U8 *context,CDoc *document)=0,U8 *context=0);
public extern Bool I386CmpCtrlLeave(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386CmpCtrlDrain(CI386Task *task);
//Release the active suffix after a live boundary; the boundary itself survives.
//Use the task queue sentinel to release all. A detached/stale boundary is invalid.
public extern Bool I386CmpCtrlUnwind(CI386Task *task,CCmpCtrl *boundary);
//Reset the active view after saving it; allocation ownership is unchanged.
public extern Bool I386COCInit(CI386Heap *heap,CCmpCtrl *cc);
//Native temporary IR allocation. Current owner, or an exclusively owned unbound
//control. Failure leaves queues unchanged. Discard is silent compiler recovery.
public extern CIntermediateCode *I386ICAdd(CI386Heap *heap,CCmpCtrl *cc,
  I64 opcode,I64 arg,CHashClass *type,I64 flags=0);
public extern CCodeMisc *I386COCMiscNew(CI386Heap *heap,CCmpCtrl *cc,I64 type);
public extern Bool I386COCDiscard(CI386Heap *heap,CCmpCtrl *cc,
  U0 (*label)(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)=0,U8 *context=0);
//Header views retain the public fixed active-sentinel convention. The control
//owns native IR allocations independently, including detached/aliased views.
public extern CCodeCtrl *I386COCSave(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386COCPush(CI386Heap *heap,CCmpCtrl *cc);
public extern CCodeCtrl *I386COCPopNoFree(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386COCHeaderFree(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header);
public extern Bool I386COCAppend(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header);
//Unlink an instruction but preserve its fields for borrowed optimizer tree links.
//Discard reclaims retired nodes only when no other native code allocations remain.
public extern Bool I386ICRetire(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node);
#endif
