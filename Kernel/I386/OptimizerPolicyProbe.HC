//Stack-owned controls exercise the resident policy entry without private owners.
#include "/Compiler/OptPass012.HH"
#include "/Kernel/I386/KernelSymbols.HH"
class CI386OptimizerPolicyProbeCtrl: CCmpCtrl {
  I64 zero_calls,nonzero_calls;
  U8 *opcodes;I64 opcode_bytes;
};
CIntermediateCode *ProbeOptimizerZero(CCmpCtrl *cc,CIntermediateCode *node)
{
  CI386OptimizerPolicyProbeCtrl *state=cc;
  state->zero_calls++;
  if(state->opcodes)state->opcodes[node->ic_code*state->opcode_bytes+1]=1;
  return node;
}
CIntermediateCode *ProbeOptimizerNonzero(CCmpCtrl *cc,CIntermediateCode *node)
{
  CI386OptimizerPolicyProbeCtrl *state=cc;
  state->nonzero_calls++;
  if(state->opcodes)state->opcodes[node->ic_code*state->opcode_bytes+1]=1;
  return node;
}
U0 ProbeOptimizerReport(U8 *context,CCmpCtrl *cc,CIntermediateCode *node,I64 reason)
{ KernelStop; }
U0 ProbeOptimizerZeroBytes(U8 *bytes,I64 count)
{ while(count--)*bytes++=0; }
U0 ProbeOptimizerResidentPolicy(CI386CompilerProbe *probe)
{
  CI386ModuleBinding binding;
  CI386KernelSymbol *symbol=0;
  CHashTable *table;
  CI386OptimizerPolicyProbeCtrl control;
  CPrsStk stack;
  CIntermediateCode immediate,branch,*head=&control.coc.coc_head;
  COptPass012Services services;
  I64 native,which,pass,expected,used=probe->heap->used,allocations=probe->heap->allocations;
  CIntermediateCode *(*core)(CCmpCtrl *cc,COptPass012Services *services,
    CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
    CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node));
  for(table=I386TaskSelf->hash_table;table && !symbol;table=table->next)
    symbol=ProbeSymbolFind(0,"_I386_OPT_CORE_POLICY",table,HTT_EXPORT_SYS_SYM);
  if(!symbol || symbol->kind!=I386_MODULE_EXPORT ||
      !probe->compiler->export_at(6,&binding) || binding.kind!=I386_MODULE_EXPORT ||
      StrCmp(binding.name,"_I386_OPT_CORE_POLICY") || binding.address!=symbol->val ||
      binding.address<(probe->runtime_image+8+0)(U64) ||
      binding.address>=(probe->runtime_image+probe->runtime_size+0)(U64))KernelStop;
  core=binding.address;
  services.types=probe->internal_types;services.context=0;services.report=&ProbeOptimizerReport;
  for(native=0;native<2;native++)for(which=0;which<2;which++) {
    ProbeOptimizerZeroBytes(&control,sizeof(control));ProbeOptimizerZeroBytes(&stack,sizeof(stack));
    ProbeOptimizerZeroBytes(&immediate,sizeof(immediate));ProbeOptimizerZeroBytes(&branch,sizeof(branch));
    control.ps=&stack;head->next=&immediate;head->last=&branch;
    immediate.last=head;immediate.next=&branch;branch.last=&immediate;branch.next=head;
    immediate.ic_code=IC_IMM_I64;immediate.ic_data=7;
    immediate.ic_class=probe->internal_types[RT_I64];
    branch.ic_code=IC_BR_ZERO;if(which)branch.ic_code=IC_BR_NOT_ZERO;
    expected=3;if(native){control.flags|=CCF_TARGET_I386;expected=0;}
    for(pass=0;pass<3;pass++) {
      control.pass=pass;(*core)(&control,&services,&ProbeOptimizerZero,&ProbeOptimizerNonzero);
    }
    if(which) {
      if(control.zero_calls || control.nonzero_calls!=expected)KernelStop;
    } else if(control.nonzero_calls || control.zero_calls!=expected)KernelStop;
    if(control.error_cnt || control.warning_cnt)KernelStop;
  }
  if(probe->heap->used!=used || probe->heap->allocations!=allocations)KernelStop;
  KernelLog("OPT RESIDENT POLICY ");KernelHex(probe->phase);KernelLog("\n");
}
U0 ProbeOptimizerResidentMetadata(CI386CompilerProbe *probe)
{
  CI386ModuleBinding binding;CI386KernelSymbol *symbol=0;CHashTable *table;
  CI386OptimizerPolicyProbeCtrl control;CPrsStk stack;
  CIntermediateCode immediate,branch,*head=&control.coc.coc_head;
  COptPass012Services services;U8 rows[IC_ICS_NUM*16];
  I64 layout,stride,native,which,pass,expected;
  I64 used=probe->heap->used,allocations=probe->heap->allocations;
  CIntermediateCode *(*core)(CCmpCtrl *cc,COptPass012Services *services,
    CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
    CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node),
    U8 *opcodes,I64 opcode_bytes);
  for(table=I386TaskSelf->hash_table;table && !symbol;table=table->next)
    symbol=ProbeSymbolFind(0,"_I386_OPT_CORE_METADATA",table,HTT_EXPORT_SYS_SYM);
  if(!symbol || symbol->kind!=I386_MODULE_EXPORT ||
      !probe->compiler->export_at(7,&binding) || binding.kind!=I386_MODULE_EXPORT ||
      StrCmp(binding.name,"_I386_OPT_CORE_METADATA") || binding.address!=symbol->val ||
      binding.address<(probe->runtime_image+8+0)(U64) ||
      binding.address>=(probe->runtime_image+probe->runtime_size+0)(U64))KernelStop;
  core=binding.address;
  services.types=probe->internal_types;services.context=0;services.report=&ProbeOptimizerReport;
  for(layout=0;layout<2;layout++)for(native=0;native<2;native++)for(which=0;which<2;which++) {
    stride=5;if(layout)stride=16;
    ProbeOptimizerZeroBytes(&control,sizeof(control));ProbeOptimizerZeroBytes(&stack,sizeof(stack));
    ProbeOptimizerZeroBytes(&immediate,sizeof(immediate));ProbeOptimizerZeroBytes(&branch,sizeof(branch));
    ProbeOptimizerZeroBytes(rows,sizeof(rows));
    rows[IC_IMM_I64*stride+1]=1;
    rows[IC_BR_ZERO*stride]=1;rows[IC_BR_NOT_ZERO*stride]=1;
    control.ps=&stack;control.opcodes=rows;control.opcode_bytes=stride;
    head->next=&immediate;head->last=&branch;
    immediate.last=head;immediate.next=&branch;branch.last=&immediate;branch.next=head;
    immediate.ic_code=IC_IMM_I64;immediate.ic_data=7;immediate.ic_class=probe->internal_types[RT_I64];
    branch.ic_code=IC_BR_ZERO;if(which)branch.ic_code=IC_BR_NOT_ZERO;
    expected=3;if(native){control.flags|=CCF_TARGET_I386;expected=0;}
    for(pass=0;pass<3;pass++) {
      control.pass=pass;
      (*core)(&control,&services,&ProbeOptimizerZero,&ProbeOptimizerNonzero,rows,stride);
      if(native){if(stack.ptr)KernelStop;}else if(stack.ptr!=2)KernelStop;
    }
    if(which){if(control.zero_calls || control.nonzero_calls!=expected)KernelStop;}
    else if(control.nonzero_calls || control.zero_calls!=expected)KernelStop;
    if(control.flags&CCF_NOT_CONST || control.error_cnt || control.warning_cnt)KernelStop;
  }
  if(probe->heap->used!=used || probe->heap->allocations!=allocations)KernelStop;
  KernelLog("OPT RESIDENT METADATA ");KernelHex(probe->phase);KernelLog("\n");
}
