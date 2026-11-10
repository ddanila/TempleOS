#ifndef COMPILER_OPT_PASS012_INCLUDED
#define COMPILER_OPT_PASS012_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#define OPT012_WARN_DEREF 0
#define OPT012_WARN_ASSIGN 1
#define OPT012_ERROR_OPCODE 2
#define OPT012_ERROR_STACK 3
class COptPass012Services {
  CHashClass **types;
  U8 *context;
  U0 (*report)(U8 *context,CCmpCtrl *cc,CIntermediateCode *node,I64 reason);
};
//Valid parser-produced graph and an allocated cc->ps. Error reports must not return.
public extern CIntermediateCode *OptPass012Core(CCmpCtrl *cc,COptPass012Services *services);
//Explicit invocation-local branch ownership; callbacks must remain live and callable.
public extern CIntermediateCode *OptPass012CorePolicy(CCmpCtrl *cc,COptPass012Services *services,
  CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
  CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node));
//Live opcode rows: arg_cnt/res_cnt/not_const at offsets 0/1/4; row size >=5.
//The caller owns IC_ICS_NUM readable rows throughout this synchronous call.
public extern CIntermediateCode *OptPass012CoreMetadata(CCmpCtrl *cc,COptPass012Services *services,
  CIntermediateCode *(*branch_zero)(CCmpCtrl *cc,CIntermediateCode *node),
  CIntermediateCode *(*branch_nonzero)(CCmpCtrl *cc,CIntermediateCode *node),
  U8 *opcodes,I64 opcode_bytes);
#endif
