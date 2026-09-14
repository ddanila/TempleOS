#ifndef PRS_DECLARATION_INCLUDED
#define PRS_DECLARATION_INCLUDED
#include "/Compiler/PrsExpression.HH"
#include "/Compiler/PrsType.HH"
//One environment owns expression/type services and partially constructed members.
//Compile/execute/release keep executable storage alive through default-value copying.
class CPrsDeclarationServices {
  U8 *context;
  CPrsExpressionServices *expression;
  CPrsTypeServices *types;
  I64 (*define_match)(U8 *context,U8 *name,U8 *list);
  I64 (*evaluate)(U8 *context,CCmpCtrl *cc);
  U0 (*snapshot_restore)(U8 *context,CCmpCtrl *cc);
  U0 (*initialize_static)(U8 *context,U8 *data,I64 bytes);
  U0 (*static_init)(U8 *context,CCmpCtrl *cc,CMemberLst *member,I64 pass);
  U0 (*store_u64)(U8 *context,CCmpCtrl *cc,I64 value);
  U0 (*store_u8_at)(U8 *context,CCmpCtrl *cc,I64 address,U8 value);
  U0 (*data_range)(U8 *context,CCmpCtrl *cc,I64 address,I64 bytes);
  U8 *(*compile_expression)(U8 *context,CCmpCtrl *cc,I64 *type);
  I64 (*execute)(U8 *context,U8 *code);
  U0 (*release)(U8 *context,U8 *allocation);
};
extern U0 PrsVarLstCore(CPrsDeclarationServices *services,CCmpCtrl *cc,
  CHashClass *type,I64 mode,I64 union_base=0);
#endif
