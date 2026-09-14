//Included by the temporary probe; all compilation services come from the retained runtime.
I64 opt_reports,opt_reason;
U0 ProbeOptReport(CCmpCtrl *cc,CIntermediateCode *node,I64 reason)
{
  if(!cc || (reason!=OPT012_ERROR_STACK && !node)) KernelStop;
  opt_reports++; opt_reason=reason;
}
U0 ProbeOptimize(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CIntermediateCode *left,*right,*result;
  CHashClass *left_type,*right_type;
  U8 *fill,*block,*next;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  I64 base_used,base_allocations,pass,kind,opcode,a,b,expected,expected_code,accepted,size;
  U32 flags=GetRFlags;
  cc=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/Optimize.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  cc->pass=3;
  if(probe->compiler->code_optimize(heap,cc,probe->internal_types,0) || cc->ps) KernelStop;
  cc->pass=0;
  if(probe->compiler->code_optimize(heap,cc,0,0) || cc->ps ||
      probe->compiler->code_optimize(heap,cc,probe->internal_types,&ProbeOptReport) || !cc->ps) KernelStop;
  base_used=heap->used; base_allocations=heap->allocations;
  for(pass=0;pass<3;pass++) for(kind=0;kind<7;kind++) {
    left_type=right_type=probe->internal_types[RT_I64];
    opcode=IC_MUL; a=6; b=7; expected=42; expected_code=IC_IMM_I64;
    switch(kind) {
      case 1:
        left_type=right_type=probe->internal_types[RT_U64];
        opcode=IC_DIV; a=0x8000000000000000; b=3; expected=0x2AAAAAAAAAAAAAAA;
        break;
      case 2:
        left_type=right_type=probe->internal_types[RT_F64]; expected_code=IC_IMM_F64;
        opcode=IC_ADD; a=0x3FF8000000000000; b=0x4000000000000000; expected=0x400C000000000000;
        break;
      case 3:
        left_type=right_type=probe->internal_types[RT_F64]; expected_code=IC_IMM_F64;
        opcode=IC_MOD; a=0x4016000000000000; b=0x4000000000000000; expected=0x3FF8000000000000;
        break;
      case 4:
        left_type=right_type=probe->internal_types[RT_F64]; expected_code=IC_IMM_F64;
        opcode=IC_XOR; a=0x7FF0000000000001; b=0x8000000000000000; expected=0xFFF0000000000001;
        break;
      case 5:
        left_type=right_type=probe->internal_types[RT_F64]; expected_code=IC_IMM_F64;
        opcode=IC_SHR; a=0x8000000000000000; b=1; expected=0xC000000000000000;
        break;
      case 6:
        right_type=probe->internal_types[RT_F64]; expected_code=IC_IMM_F64;
        opcode=IC_ADD; a=7; b=0x4004000000000000; expected=0x4023000000000000;
        break;
    }
    cc->pass=pass;
    size=IC_IMM_I64; if(left_type->raw_type==RT_F64) size=IC_IMM_F64;
    left=probe->compiler->code_add(heap,cc,size,a,left_type,0);
    size=IC_IMM_I64; if(right_type->raw_type==RT_F64) size=IC_IMM_F64;
    right=probe->compiler->code_add(heap,cc,size,b,right_type,0);
    result=probe->compiler->code_add(heap,cc,opcode,0,left_type,0);
    if(!left || !right || !result ||
        probe->compiler->code_optimize(heap,cc,probe->internal_types,&ProbeOptReport)!=result ||
        result->ic_code!=expected_code || result->ic_data!=expected ||
        result->t.arg1_tree!=left || result->t.arg2_tree!=right ||
        left->ic_code!=IC_NOP1 || right->ic_code!=IC_NOP1 || cc->ps->ptr!=2 ||
        cc->error_cnt || cc->warning_cnt || !(cc->flags&CCF_TARGET_I386) ||
        !probe->compiler->code_discard(heap,cc,0,0) ||
        heap->used!=base_used || heap->allocations!=base_allocations) KernelStop;
  }
  cc->pass=2; opt_reports=0;
  left=probe->compiler->code_add(heap,cc,IC_IMM_I64,0,probe->i64_type,0);
  result=probe->compiler->code_add(heap,cc,IC_DEREF,0,probe->internal_types[RT_U0],0);
  if(!left || !result || probe->compiler->code_optimize(heap,cc,probe->internal_types,&ProbeOptReport)!=result ||
      opt_reports!=1 || opt_reason!=OPT012_WARN_DEREF || cc->warning_cnt!=1 ||
      !probe->compiler->code_discard(heap,cc,0,0)) KernelStop;
  //Two unconsumed values report the real pass's stack diagnostic and throw.
  if(!probe->compiler->code_add(heap,cc,IC_IMM_I64,1,probe->i64_type,0) ||
      !probe->compiler->code_add(heap,cc,IC_IMM_I64,2,probe->i64_type,0)) KernelStop;
  accepted=0; opt_reports=0;
  try {
    probe->compiler->code_optimize(heap,cc,probe->internal_types,&ProbeOptReport); KernelStop;
  } catch {
    if(task->except_ch!='Compiler' || cc->error_cnt!=1 || opt_reports!=1 ||
        opt_reason!=OPT012_ERROR_STACK || !probe->compiler->control_unwind(task,outer)) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  if(!accepted || heap->used!=used || heap->allocations!=allocations) KernelStop;
  //Failure to allocate the pass stack must leave the control reclaimable.
  cc=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/OptOutMem.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  fill=0; accepted=0;
  try {
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
    probe->compiler->code_optimize(heap,cc,probe->internal_types,0); KernelStop;
  } catch {
    if(task->except_ch!='OutMem' || cc->ps) KernelStop;
    task->catch_except=TRUE; accepted=1;
  }
  while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
  if(!accepted || !probe->compiler->control_unwind(task,outer) || task->except_top ||
      task->last_cc!=outer || task->active_controls!=1 || task->lifetime_refs!=refs ||
      heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
      (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("OPTIMIZER PROBE "); KernelHex(probe->phase); KernelLog("\n");
}
