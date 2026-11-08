#include "/Kernel/I386/TaskHeaps.HH"
I64 helper_frame_reject_calls;
U8 *ProbeHelperRejectCode(CI386TaskHeaps *owner,I64 bytes)
{helper_frame_reject_calls++;return 0;}
U0 ProbeHelperFrameFailure(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
 CI386Task *task=I386TaskSelf;CI386TaskHeaps *owner=task->heap_state;
 CCmpCtrl *cc;CPrsSymbolServices *symbols;CPrsDeclarationServices *d;CPrsExpressionServices *e;
 CAOT *aot;CAOTCtrl *aotc;CHashTable *hash;CHashFun *fun;
 U8 *code,*(*allocate)(CI386TaskHeaps *owner,I64 bytes);
 I64 i,type,value,exception,used,allocations,public_used;
 if(!owner || owner->signature!=I386_TASK_HEAPS_MAGIC || owner->task!=task ||
    task->code_heap!=&owner->control || !owner->code_allocate)KernelStop;
 for(i=0;i<3;i++) {
  used=heap->used;allocations=heap->allocations;public_used=owner->control.used_u8s;
  cc=probe->files->control_new("1.25+2.5;",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/HelperFrame.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0) ||
     !(symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include)))KernelStop;
  d=symbols->declarations;e=d->expression;e->lex(e->context,cc);
  aot=cc->aot;aotc=cc->aotc;hash=cc->htc.hash_table_lst;fun=cc->htc.fun;
  allocate=owner->code_allocate;helper_frame_reject_calls=0;code=0;exception=0;
  if(i==1)owner->code_allocate=&ProbeHelperRejectCode;
  try {code=d->compile_expression(d->context,cc,&type);}
  catch {exception=task->except_ch;task->catch_except=TRUE;}
  owner->code_allocate=allocate;
  if(cc->aot!=aot || cc->aotc!=aotc || cc->htc.hash_table_lst!=hash || cc->htc.fun!=fun)KernelStop;
  if(i==1) {
   if(exception!='OutMem' || code || helper_frame_reject_calls!=1)KernelStop;
  } else {
   if(exception || !code || type!=RT_F64 || helper_frame_reject_calls)KernelStop;
   value=d->execute(d->context,code);
   if(value!=0x400E000000000000)KernelStop;
   d->release(d->context,code);
  }
  if(!probe->compiler->control_unwind(task,outer))KernelStop;
  //Warm the task allocator once before requiring exact physical recovery.
  if(i && (heap->used!=used || heap->allocations!=allocations ||
      owner->control.used_u8s!=public_used))KernelStop;
 }
 KernelLog("HELPER FRAME FAULT ");KernelHex(probe->phase);KernelLog(" ");KernelHex(1);KernelLog(" ");KernelHex(0);KernelLog("\n");
}
