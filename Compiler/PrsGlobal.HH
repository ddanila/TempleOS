#ifndef PRS_GLOBAL_INCLUDED
#define PRS_GLOBAL_INCLUDED
#include "/Compiler/PrsSymbol.HH"
#include "/Compiler/PrsInitializer.HH"
//Shared symbol/initializer environments must have the same compilation owner.
class CPrsGlobalServices {
  U8 *context;
  CPrsSymbolServices *symbols;
  CPrsInitializerServices *initializers;
  U0 (*function)(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags);
  U0 (*resolve)(U8 *context,CCmpCtrl *cc,U8 *name);
  Bool (*same_heap)(U8 *context,U8 *left,U8 *right);
  U0 (*alias_warning)(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol);
};
extern U0 PrsGlblVarLstCore(CPrsGlobalServices *services,CCmpCtrl *cc,
  I64 saved_mode,CHashClass *saved_type,I64 saved_value,I64 flags);
#endif
