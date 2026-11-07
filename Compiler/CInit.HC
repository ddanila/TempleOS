#include "/Kernel/RawTypes.HH"
#include "/Compiler/PrsBinary.HC"
#include "/Compiler/LexPunctInit.HC"
#include "/Compiler/InternalTypes.HC"

#include "/Compiler/ICInfo.HC"

#include "/Compiler/CompilerDefinesCore.HC"

U0 CmpFillTables()
{
  I64 i;
  U32 *d;

  ICInfoInit;
  cmp.to_reg_vars_map=CAlloc(REG_REGS_NUM*sizeof(U8));
  cmp.num_reg_vars=0;
  cmp.reg_vars_mask=REGG_LOCAL_VARS;
  for (i=0;i<REG_REGS_NUM;i++)
    if (Bt(&cmp.reg_vars_mask,i))
      cmp.to_reg_vars_map[cmp.num_reg_vars++]=i;

  cmp.non_ptr_vars_map=CAlloc(REG_REGS_NUM*sizeof(U8));
  cmp.num_non_ptr_vars=0;
  cmp.non_ptr_vars_mask=REGG_LOCAL_NON_PTR_VARS;
  for (i=0;i<REG_REGS_NUM;i++)
    if (Bt(&cmp.non_ptr_vars_mask,i))
      cmp.non_ptr_vars_map[cmp.num_non_ptr_vars++]=i;

  cmp.dual_U16_tokens1=CAlloc(sizeof(U32)*TK_TKS_NUM);
  cmp.dual_U16_tokens2=CAlloc(sizeof(U32)*TK_TKS_NUM);
  cmp.dual_U16_tokens3=CAlloc(sizeof(U32)*TK_TKS_NUM);
  LexPunctInit(cmp.dual_U16_tokens1,cmp.dual_U16_tokens2,cmp.dual_U16_tokens3);

  cmp.binary_ops=d=CAlloc(sizeof(U32)*TK_TKS_NUM);
  PrsBinaryInit(d);
}
