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
#endif
