#ifndef I386_BACKEND_INCLUDED
#define I386_BACKEND_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/PatchTypes.HH"
#include "/Compiler/I386/Emit.HH"
class CI386Logic
{
  CI386Logic *next;
  CIntermediateCode *left,*end;
  I64 address;
};
class CI386Chain
{
  CI386Chain *next;
  CIntermediateCode *comparison,*push;
  I64 slot;
};

class CI386Call
{
  CI386Call *next;
  CHashFun *fun;
  I64 depth,slots;
  Bool called,indirect;
};

class CI386BackendStatus {
  CIntermediateCode *node;
  I64 depth,pass,reason;
};
class CI386Backend {
  CCmpCtrl *cc;
  CI386Out *out;
  CHashClass **types;
  U8 *context;
  U8 *(*allocate)(U8 *context,I64 bytes);
  U0 (*release)(U8 *context,U8 *allocation);
  U0 (*fold)(U8 *context,CCmpCtrl *cc);
  U0 (*assembly)(U8 *context,CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass);
  U0 (*report)(U8 *context,I64 reason,CIntermediateCode *ic,U8 *name);
  CI386Call *calls;
  CI386Logic *logics;
  CI386Chain *chains;
  CI386BackendStatus *status;
  CIntermediateCode *current;
  I64 depth,pass;
};
//Valid target IR, initialized output and borrowed AOT/type/symbol context.
//Allocations are zeroed or throw. The caller owns success/failure cleanup.
#endif
