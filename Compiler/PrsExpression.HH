#ifndef PRS_EXPRESSION_INCLUDED
#define PRS_EXPRESSION_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#include "/Compiler/PrsPrecedence.HH"
#include "/Compiler/PrsTypeFlags.HH"
//Complete expression parser dependencies. The environment owns allocations and
//partially built graphs. Error reports must throw; warnings may return.
class CPrsExpressionServices {
  U8 *context;
  CHashClass **types;
  U32 *binary_ops;
  I64 (*lex)(U8 *context,CCmpCtrl *cc);
  U0 (*report)(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message);
  CIntermediateCode *(*add)(U8 *context,CCmpCtrl *cc,I64 op,I64 value,CHashClass *type,I64 flags);
  U0 (*retire)(U8 *context,CCmpCtrl *cc,CIntermediateCode *node);
  CCodeMisc *(*misc)(U8 *context,CCmpCtrl *cc,I64 kind);
  U0 (*init)(U8 *context,CCmpCtrl *cc);
  U0 (*push)(U8 *context,CCmpCtrl *cc);
  U0 (*pop)(U8 *context,CCmpCtrl *cc);
  U0 (*append)(U8 *context,CCmpCtrl *cc,CCodeCtrl *saved);
  CIntermediateCode *(*optimize)(U8 *context,CCmpCtrl *cc);
  U8 *(*allocate)(U8 *context,I64 size,Bool zeroed,Bool code_heap);
  U8 *(*duplicate)(U8 *context,U8 *source);
  U8 *(*string)(U8 *context,CCmpCtrl *cc,I64 *length);
  U0 (*hash_add)(U8 *context,CHash *entry,CHashTable *table);
  U0 (*hash_after)(U8 *context,CHash *entry,CHash *after,CHashTable *table);
  CHashClass *(*type)(U8 *context,CCmpCtrl *cc,CHashClass **first,I64 *mode,
    CMemberLst *member,U8 **ident,CHashFun **fun,CHashExport **export_entry,CArrayDim *dim,I64 flags);
  //Optional private type view; NULL preserves the supplied descriptor.
  CHashClass *(*class_view)(U8 *context,CHashClass *type);
  Bool (*expression)(U8 *context,CCmpCtrl *cc,I64 *precedence,Bool end_exp,CPrsStk *stack);
  //Native JITs retain named function-address sites for later module packaging.
  Bool retain_function_addresses;
  //Retain named global-address sites instead of embedding live allocation addresses.
  Bool retain_data_addresses;
  //Native module frontends retain function-local static address sites.
  Bool retain_static_addresses;
};
extern CIntermediateCode *PrsAddOpCore(CPrsExpressionServices *services,CCmpCtrl *cc,I64 stk_op,CHashClass *tmpc);
extern U0 PrsExpression2Core(CPrsExpressionServices *services,CCmpCtrl *cc,I64 *_max_prec,CPrsStk *ps);
extern U0 PrsSizeOfCore(CPrsExpressionServices *services,CCmpCtrl *cc);
extern U0 PrsOffsetOfCore(CPrsExpressionServices *services,CCmpCtrl *cc);
extern I64 PrsFunCallCore(CPrsExpressionServices *services,CCmpCtrl *cc,CPrsStk *ps,Bool indirect,CHashFun *tmpf);
extern I64 PrsUnaryTermCore(CPrsExpressionServices *services,CCmpCtrl *cc,CPrsStk *ps,CMemberLst **_local_var,
	CArrayDim **_tmpad,I64 *max_prec,I64 *unary_pre_prec,I64 *paren_prec);
extern I64 PrsUnaryModifierCore(CPrsExpressionServices *services,CCmpCtrl *cc,CPrsStk *ps,CMemberLst **_local_var,
	CArrayDim **_tmpad,I64 *unary_post_prec);
#endif
