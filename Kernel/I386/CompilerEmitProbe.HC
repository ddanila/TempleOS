//The probe uses the same byte writer as the production target backend.
#include "/Compiler/I386/EmitCore.HC"
U0 ProbeEmit(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CI386Out *out;
  CCodeCtrl *saved;
  U8 *before,*fill,*block,*next;
  I64 (*generated)();
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  I64 base_used,base_allocations,round,i,count,capacity,size,accepted,value;
  U32 flags=GetRFlags;
  cc=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/Emit.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  base_used=heap->used; base_allocations=heap->allocations;
  for(round=0;round<64;round++) {
    out=probe->compiler->out_new(heap,cc);
    if(!out || out->data || out->count || out->capacity || !out->reserve ||
        probe->compiler->out_del(heap,outer,out)) KernelStop;
    //Cross 64, 128 and 256-byte growth boundaries before executing native code.
    for(i=0;i<257;i++) I386Byte(out,0x90);
    value=0x1234567887654300+round;
    I386Byte(out,0xB8); I386Dword(out,value.u32[0]);
    I386Byte(out,0xBA); I386Dword(out,value.u32[1]); I386Bytes(out,"\xC3",1);
    if(out->count!=268 || out->capacity!=512 || I386HeapSize(heap,out->data)!=512) KernelStop;
    for(i=0;i<257;i++) if(out->data[i]!=0x90) KernelStop;
    if(out->data[257]!=0xB8 || out->data[262]!=0xBA || out->data[267]!=0xC3) KernelStop;
    for(i=0;i<4;i++)
      if(out->data[258+i]!=value.u8[i] || out->data[263+i]!=value.u8[i+4]) KernelStop;
    generated=out->data;
    if((*generated)()!=value) KernelStop;
    //IR discard is not an output-buffer lifetime boundary, including saved views.
    saved=probe->compiler->code_save(heap,cc);
    if(!saved || !probe->compiler->code_discard(heap,cc,0,0) || (*generated)()!=value ||
        !probe->compiler->code_free(heap,cc,saved) ||
        !probe->compiler->out_del(heap,cc,out) ||
        heap->used!=base_used || heap->allocations!=base_allocations) KernelStop;
  }
  out=probe->compiler->out_new(heap,cc);
  for(i=0;i<64;i++) I386Byte(out,i);
  before=out->data; count=out->count; capacity=out->capacity;
  fill=0; accepted=0;
  try {
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
    I386Byte(out,0xAA); KernelStop;
  } catch {
    if(task->except_ch!='OutMem' || out->data!=before || out->count!=count ||
        out->capacity!=capacity) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  if(!accepted) KernelStop;
  accepted=0;
  try { probe->compiler->out_new(heap,cc); KernelStop; }
  catch {
    if(task->except_ch!='OutMem') KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  for(i=0;i<64;i++) if(out->data[i]!=i) KernelStop;
  while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
  if(!accepted) KernelStop;
  //A failed reserve preserves the builder, allowing a real retry after reclamation.
  I386Byte(out,0xAA);
  if(out->count!=65 || out->capacity!=128 || out->data[64]!=0xAA) KernelStop;
  accepted=0;
  try { (*out->reserve)(out,0x80000000); KernelStop; }
  catch {
    if(task->except_ch!='Compiler' || out->count!=65 || out->capacity!=128 ||
        out->data[64]!=0xAA) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  if(!accepted) KernelStop;
  //Unwind owns the live builder and its buffer; callers need no catch-local frees.
  accepted=0;
  try { throw('Compiler',TRUE); }
  catch {
    if(task->except_ch!='Compiler' || !probe->compiler->control_unwind(task,outer)) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  if(!accepted || task->except_top || task->last_cc!=outer || task->active_controls!=1 ||
      task->lifetime_refs!=refs || heap->used!=used || heap->allocations!=allocations ||
      !I386HeapValid(heap) || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("EMITTER PROBE "); KernelHex(probe->phase); KernelLog("\n");
}
