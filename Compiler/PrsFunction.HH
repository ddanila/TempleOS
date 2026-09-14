#ifndef PRS_FUNCTION_INCLUDED
#define PRS_FUNCTION_INCLUDED
#include "/Compiler/PrsGlobal.HH"
//Compilation returns padded AOT bytes or code retained by the function symbol.
class CPrsFunctionServices {
  U8 *context;
  CPrsGlobalServices *globals;
  Bool (*statement)(U8 *context,CCmpCtrl *cc,I64 try_count,CCodeMisc *break_label,I64 flags);
  U8 *(*compile)(U8 *context,CCmpCtrl *cc,I64 *bytes,CDbgInfo **debug,I64 *type);
  U0 (*disassemble)(U8 *context,U8 *code,I64 bytes);
  U0 (*member_warning)(U8 *context,CCmpCtrl *cc,CMemberLst *member,Bool unneeded);
};
extern U0 PrsFunCore(CPrsFunctionServices *services,CCmpCtrl *cc,
  CHashClass *return_type,U8 *name,I64 flags);
#endif
