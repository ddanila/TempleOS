//Construct valid function IR, then call the production shared backend natively.
#include "/Kernel/PatchTypes.HH"
U0 ProbeBackendAdd(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *cc,I64 op,I64 value,CHashClass *type)
{
  if(!probe->compiler->code_add(heap,cc,op,value,type,0)) KernelStop;
}
U0 ProbeBackendArg(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *cc,I64 offset,CHashClass *type)
{
  ProbeBackendAdd(probe,heap,cc,IC_RBP,0,probe->i64_type);
  ProbeBackendAdd(probe,heap,cc,IC_IMM_I64,offset,probe->i64_type);
  ProbeBackendAdd(probe,heap,cc,IC_ADD,0,probe->i64_type);
  ProbeBackendAdd(probe,heap,cc,IC_DEREF,0,type);
}
U0 ProbeBackend(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CI386Out *out;
  CI386BackendStatus status;
  CHashFun fun;
  CAOT aot;
  CAOTCtrl aotc;
  CHashClass *type;
  CCodeMisc *label,*literal;
  CAOTImportExport *metadata;
  I64 (*generated)(I64 a,I64 b);
  U8 *text_value,*fill,*block,*next,*bytes;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  I64 i,kind,op,a,b,expected,accepted,size,actual;
  U32 flags=GetRFlags;
  for(kind=0;kind<16;kind++) {
    KernelLog("BACKEND CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
    bytes=&fun; for(i=0;i<sizeof(fun);i++) bytes[i]=0;
    bytes=&aot; for(i=0;i<sizeof(aot);i++) bytes[i]=0;
    bytes=&aotc; for(i=0;i<sizeof(aotc);i++) bytes[i]=0;
    aot.next_ie=aot.last_ie=&aot.next_ie;
    fun.arg_cnt=2; fun.return_class=probe->i64_type;
    cc=probe->files->control_new("",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Backend.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    cc->htc.fun=&fun; cc->aot=&aot; cc->aotc=&aotc;
    out=probe->compiler->out_new(heap,cc);
    if(!out || probe->compiler->backend(heap,outer,probe->internal_types,out,&status)) KernelStop;
    type=probe->i64_type; op=IC_ADD; a=0x7FFFFFFFFFFFFFFF; b=1; expected=0x8000000000000000;
    switch(kind) {
      case 1: op=IC_SUB; a=0x100000000; b=1; expected=0xFFFFFFFF; break;
      case 2: op=IC_MUL; a=-7; b=6; expected=-42; break;
      case 3: op=IC_DIV; a=-43; b=6; expected=-7; break;
      case 4: op=IC_MOD; a=-43; b=6; expected=-1; break;
      case 5: op=IC_SHL; a=1; b=63; expected=0x8000000000000000; break;
      case 6: op=IC_SHR; a=0x8000000000000000; b=33; expected=0xFFFFFFFFC0000000; break;
      case 7: op=IC_SHR; type=probe->internal_types[RT_U64]; a=0x8000000000000000; b=33; expected=0x40000000; break;
      case 8: op=IC_XOR; a=0xAAAAAAAA55555555; b=0x55555555AAAAAAAA; expected=-1; break;
      case 9: op=IC_LESS; a=-1; b=1; expected=1; break;
      case 10: op=IC_LESS; type=probe->internal_types[RT_U64]; a=-1; b=1; expected=0; break;
      case 11: op=IC_GREATER; a=0x100000000; b=0xFFFFFFFF; expected=1; break;
      case 12: op=IC_AND_AND; a=0; b=1; expected=456; break;
      case 13: op=IC_OR_OR; a=0; b=1; expected=123; break;
      case 14: op=IC_OR_OR; a=0; b=0; expected=456; break;
    }
    ProbeBackendAdd(probe,heap,cc,IC_ENTER,0,0);
    if(kind==15) {
      literal=probe->compiler->code_misc(heap,cc,CMT_STR_CONST);
      if(!literal) KernelStop;
      literal->str=I386HeapAlloc(heap,4,FALSE); literal->st_len=4;
      if(!literal->str) KernelStop;
      literal->str[0]='J'; literal->str[1]='I'; literal->str[2]='T'; literal->str[3]=0;
      ProbeBackendAdd(probe,heap,cc,IC_STR_CONST,literal,probe->internal_types[RT_U8]+1);
      ProbeBackendAdd(probe,heap,cc,IC_RETURN_VAL,0,probe->internal_types[RT_U8]+1);
      ProbeBackendAdd(probe,heap,cc,IC_LEAVE,0,0);
    } else {
      ProbeBackendArg(probe,heap,cc,8,type);
      ProbeBackendArg(probe,heap,cc,16,type);
      ProbeBackendAdd(probe,heap,cc,op,0,type);
      if(kind>=12) {
        label=probe->compiler->code_misc(heap,cc,CMT_LABEL);
        if(!label) KernelStop;
        ProbeBackendAdd(probe,heap,cc,IC_BR_ZERO,label,0);
        ProbeBackendAdd(probe,heap,cc,IC_IMM_I64,123,probe->i64_type);
        ProbeBackendAdd(probe,heap,cc,IC_RETURN_VAL,0,probe->i64_type);
        ProbeBackendAdd(probe,heap,cc,IC_LEAVE,0,0);
        ProbeBackendAdd(probe,heap,cc,IC_LABEL,label,0);
        ProbeBackendAdd(probe,heap,cc,IC_IMM_I64,456,probe->i64_type);
      }
      ProbeBackendAdd(probe,heap,cc,IC_RETURN_VAL,0,probe->i64_type);
      ProbeBackendAdd(probe,heap,cc,IC_LEAVE,0,0);
    }
    try {
      if(!probe->compiler->backend(heap,cc,probe->internal_types,out,&status) || !out->count || cc->error_cnt) KernelStop;
    } catch {
      KernelLog("BACKEND EXCEPTION "); KernelHex(task->except_ch); KernelLog(" ");
      KernelHex(status.pass); KernelLog(" "); KernelHex(status.depth); KernelLog(" ");
      if(status.node) KernelHex(status.node->ic_code); KernelLog(" "); KernelHex(status.reason);
      KernelLog(" "); KernelHex(out->count); KernelLog(" "); KernelHex(out->capacity);
      KernelLog("\n"); KernelStop;
    }
    KernelLog("BACKEND BYTES "); KernelHex(out->count); KernelLog("\n");
    generated=out->data;
    if(kind==15) {
      text_value=(*generated)(0,0);
      metadata=aot.next_ie;
      if(text_value<out->data || text_value>out->data+out->count-4 ||
          text_value[0]!='J' || text_value[1]!='I' || text_value[2]!='T' || text_value[3] ||
          metadata==&aot.next_ie || metadata->type!=IET_I386_DATA || metadata->flags!=4 ||
          metadata->rip!=text_value-out->data || metadata->next!=&aot.next_ie) KernelStop;
    } else {
      actual=(*generated)(a,b);
      KernelLog("BACKEND RESULT "); KernelHex(actual); KernelLog("\n");
      if(actual!=expected) KernelStop;
    }
    if(!probe->compiler->control_unwind(task,outer) || heap->used!=used ||
        heap->allocations!=allocations || task->lifetime_refs!=refs) KernelStop;
  }
  //OutMem inside the lowering loop: first emit fills a real owned output buffer.
  bytes=&fun; for(i=0;i<sizeof(fun);i++) bytes[i]=0;
  bytes=&aot; for(i=0;i<sizeof(aot);i++) bytes[i]=0;
  bytes=&aotc; for(i=0;i<sizeof(aotc);i++) bytes[i]=0;
  aot.next_ie=aot.last_ie=&aot.next_ie; fun.return_class=probe->i64_type;
  cc=probe->files->control_new("",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/BackendOutMem.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  cc->htc.fun=&fun; cc->aot=&aot; cc->aotc=&aotc;
  ProbeBackendAdd(probe,heap,cc,IC_ENTER,0,0);
  ProbeBackendAdd(probe,heap,cc,IC_IMM_I64,42,probe->i64_type);
  ProbeBackendAdd(probe,heap,cc,IC_RETURN_VAL,0,probe->i64_type);
  ProbeBackendAdd(probe,heap,cc,IC_LEAVE,0,0);
  //Allocate pass stack before exhaustion, so the failure comes from code emission.
  probe->compiler->code_optimize(heap,cc,probe->internal_types,0);
  out=probe->compiler->out_new(heap,cc); if(!out) KernelStop;
  fill=0; accepted=0;
  try {
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
    probe->compiler->backend(heap,cc,probe->internal_types,out,&status); KernelStop;
  } catch {
    if(task->except_ch!='OutMem' || out->count || out->data) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
  if(!accepted || !probe->compiler->control_unwind(task,outer) || task->except_top ||
      task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs ||
      heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
      (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("BACKEND PROBE "); KernelHex(probe->phase); KernelLog("\n");
}
