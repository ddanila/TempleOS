//Keep the source compiler's live metadata and public ownership callbacks.
#include "/Compiler/OptPass012.HH"
public _extern _I386_OPT_CORE_METADATA CIntermediateCode *NativeSystemOptMetadata(
 CCmpCtrl *cc,COptPass012Services *services,
 CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
 CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node),
 U8 *opcodes,I64 opcode_bytes);
CIntermediateCode *OptPass012CoreMetadata(CCmpCtrl *cc,COptPass012Services *services,
 CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
 CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node),
 U8 *opcodes,I64 opcode_bytes)
{
 if(sizeof(COptPass012Services)!=12 || offset(COptPass012Services.types)!=0 ||
   offset(COptPass012Services.context)!=4 || offset(COptPass012Services.report)!=8 ||
   offset(CIntermediateStruct.arg_cnt)!=0 || offset(CIntermediateStruct.res_cnt)!=1 ||
   offset(CIntermediateStruct.not_const)!=4)throw('OptABI',TRUE);
 return NativeSystemOptMetadata(cc,services,branch_zero,branch_nonzero,opcodes,opcode_bytes);
}
CIntermediateCode *OptPass012CorePolicy(CCmpCtrl *cc,COptPass012Services *services,
 CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
 CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node))
{
 return OptPass012CoreMetadata(cc,services,branch_zero,branch_nonzero,
   intermediate_code_table,sizeof(CIntermediateStruct));
}
CIntermediateCode *OptPass012Core(CCmpCtrl *cc,COptPass012Services *services)
{
 return OptPass012CorePolicy(cc,services,&OptBrZero,&OptBrNotZero);
}
