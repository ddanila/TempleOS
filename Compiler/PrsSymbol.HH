#ifndef PRS_SYMBOL_INCLUDED
#define PRS_SYMBOL_INCLUDED
#include "/Compiler/PrsDeclaration.HH"
#include "/Compiler/PrsFunctionFlags.HH"
#include "/Kernel/NumericLimits.HH"
//Private mutable symbol tables and member graphs belong to one parser owner.
class CPrsSymbolServices {
  U8 *context;
  CPrsDeclarationServices *declarations;
  I64 used_mask,clobbered_mask;
  U8 *undefined_function;
  CHashClass *(*class_new)(U8 *context);
  CHashFun *(*fun_new)(U8 *context);
  CHash *(*single_find)(U8 *context,U8 *name,CHashTable *table,I64 mask);
  U0 (*class_members_delete)(U8 *context,CHashClass *symbol);
  U0 (*members_delete)(U8 *context,CMemberLst *members);
  U0 (*source)(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol,I64 line_adjust);
  Bool (*option)(U8 *context,I64 index);
  U0 (*warning)(U8 *context,CCmpCtrl *cc,I64 kind,CHashSrcSym *symbol);
};
extern CHashClass *PrsClassCore(CPrsSymbolServices *services,CCmpCtrl *cc,I64 keyword,I64 fsp_flags,Bool is_extern);
extern CHashFun *PrsFunJoinCore(CPrsSymbolServices *services,CCmpCtrl *cc,CHashClass *tmp_return,
	U8 *name,I64 fsp_flags);
#endif
