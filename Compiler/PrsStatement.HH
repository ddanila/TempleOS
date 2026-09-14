#ifndef PRS_STATEMENT_INCLUDED
#define PRS_STATEMENT_INCLUDED
#include "/Compiler/PrsGlobal.HH"
#include "/Compiler/PrsCompileFlags.HH"
class CPrsStatementServices {
  U8 *context;
  U0 (*stack_check)(U8 *context,CCmpCtrl *cc);
  CPrsGlobalServices *globals;
  CCodeCtrl *(*pop_saved)(U8 *context,CCmpCtrl *cc);
  U0 (*assembly)(U8 *context,CCmpCtrl *cc,I64 flags);
  CAOT *(*join)(U8 *context,CCmpCtrl *cc,I64 flags);
  U0 (*fix_assembly)(U8 *context,CCmpCtrl *cc,CAOT *aot);
  CHashTable *(*task_symbols)(U8 *context);
  U0 (*execute_line)(U8 *context,CCmpCtrl *cc);
  U0 (*include)(U8 *context,CCmpCtrl *cc,U8 *name,U8 *source,Bool actual_file);
};
extern U0 PrsIfCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt,CCodeMisc *lb_break);
extern U0 PrsWhileCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt);
extern U0 PrsDoWhileCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt);
extern U0 PrsForCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt);
extern U0 PrsSwitchCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt);
extern U0 PrsNoWarnCore(CPrsStatementServices *services,CCmpCtrl *cc);
extern U0 PrsStreamBlkCore(CPrsStatementServices *services,CCmpCtrl *cc);
extern U0 PrsI386TryCallCore(CPrsStatementServices *services,CCmpCtrl *cc,CHashFun *fun,Bool begin=TRUE);
extern U0 PrsTryBlkCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt);
extern Bool PrsStmtCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt=0,
  CCodeMisc *lb_break=NULL,I64 cmp_flags=CMPF_PRS_SEMICOLON);
#endif
