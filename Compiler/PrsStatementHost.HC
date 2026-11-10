extern U0 PrsFun(CCmpCtrl *cc,CHashClass *tmp_return,U8 *name,I64 fsp_flags);

#include "/Compiler/PrsGlobalCore.HC"
U0 PrsHostFunction(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags)
{ PrsFun(cc,return_type,name,flags); }
U0 PrsHostResolve(U8 *context,CCmpCtrl *cc,U8 *name) { SysSymImportsResolve(name); }
Bool PrsHostSameHeap(U8 *context,U8 *left,U8 *right) { return MHeapCtrl(left)==MHeapCtrl(right); }
U0 PrsHostAliasWarning(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol)
{ PrintWarn("Unused extern '%s'\n",symbol->str); cc->warning_cnt++; }
U0 PrsHostGlobalServices(CPrsGlobalServices *services,
  CPrsSymbolServices *symbols,CPrsInitializerServices *initializers)
{
  services->context=0; services->symbols=symbols; services->initializers=initializers;
  services->function=&PrsHostFunction; services->resolve=&PrsHostResolve;
  services->same_heap=&PrsHostSameHeap; services->alias_warning=&PrsHostAliasWarning;
  services->completed=0;
}

U0 PrsGlblVarLst(CCmpCtrl *cc,I64 saved_mode,CHashClass *saved_tmpc,
  I64 saved_val,I64 fsp_flags)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&services,&symbols,&initializers);
  PrsGlblVarLstCore(&services,cc,saved_mode,saved_tmpc,saved_val,fsp_flags);
}

#include "/Compiler/PrsFunctionCore.HC"
Bool PrsHostStatement(U8 *context,CCmpCtrl *cc,I64 try_count,CCodeMisc *break_label,I64 flags)
{ return PrsStmt(cc,try_count,break_label,flags); }
U8 *PrsHostCompileFunction(U8 *context,CCmpCtrl *cc,I64 *bytes,CDbgInfo **debug,I64 *type)
{ return COCCompile(cc,bytes,debug,type); }
U0 PrsHostDisassemble(U8 *context,U8 *code,I64 bytes) { Un(code,bytes,64); }
U0 PrsHostMemberWarning(U8 *context,CCmpCtrl *cc,CMemberLst *member,Bool unneeded)
{
  if(unneeded)
    PrintWarn("Unneeded no_warn\n $$LK,\"FL:%s,%d\"$$ '%s' in '%s'\n",
      cc->lex_include_stk->full_name,cc->lex_include_stk->line_num,member->str,cc->htc.fun->str);
  else
    PrintWarn("Unused var\n $$LK,\"FL:%s,%d\"$$ '%s' in '%s'\n",
      cc->lex_include_stk->full_name,cc->lex_include_stk->line_num,member->str,cc->htc.fun->str);
}
U0 PrsHostFunctionServices(CPrsFunctionServices *services,CPrsGlobalServices *globals)
{
  services->context=0; services->globals=globals;
  services->statement=&PrsHostStatement; services->compile=&PrsHostCompileFunction;
  services->disassemble=&PrsHostDisassemble; services->member_warning=&PrsHostMemberWarning;
}

U0 PrsFun(CCmpCtrl *cc,CHashClass *tmp_return,U8 *name,I64 fsp_flags)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsFunctionServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostFunctionServices(&services,&globals);
  PrsFunCore(&services,cc,tmp_return,name,fsp_flags);
}

#include "/Compiler/PrsStatementCore.HC"
CCodeCtrl *PrsHostPopSaved(U8 *context,CCmpCtrl *cc) { return COCPopNoFree(cc); }
U0 PrsHostAssembly(U8 *context,CCmpCtrl *cc,I64 flags) { PrsAsmBlk(cc,flags); }
CAOT *PrsHostJoin(U8 *context,CCmpCtrl *cc,I64 flags) { return CmpJoin(cc,flags); }
U0 PrsHostFixAssembly(U8 *context,CCmpCtrl *cc,CAOT *aot) { CmpFixUpJITAsm(cc,aot); }
CHashTable *PrsHostTaskSymbols(U8 *context) { return Fs->hash_table; }
U0 PrsHostExecuteLine(U8 *context,CCmpCtrl *cc)
{//Compile-time stream code runs on this compiler host, even for a 386 AOT.
  I64 mask=CCF_TARGET_I386|CCF_TARGET_HOST_CONST,flags=cc->flags;
  cc->flags&=~mask;
  try { ExeCmdLine(cc); }
  catch { cc->flags=cc->flags&~mask|flags&mask; }
  cc->flags=cc->flags&~mask|flags&mask;
}
U0 PrsHostInclude(U8 *context,CCmpCtrl *cc,U8 *name,U8 *source,Bool actual_file)
{ LexIncludeStr(cc,name,source,actual_file); }
U0 PrsHostStatementServices(CPrsStatementServices *services,CPrsGlobalServices *globals)
{
  services->context=0; services->globals=globals; services->stack_check=0;
  services->pop_saved=&PrsHostPopSaved; services->assembly=&PrsHostAssembly;
  services->join=&PrsHostJoin; services->fix_assembly=&PrsHostFixAssembly;
  services->task_symbols=&PrsHostTaskSymbols; services->execute_line=&PrsHostExecuteLine;
  services->include=&PrsHostInclude;
}

U0 PrsIf(CCmpCtrl *cc,I64 try_cnt,CCodeMisc *lb_break)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsIfCore(&services,cc,try_cnt,lb_break);
}

U0 PrsWhile(CCmpCtrl *cc,I64 try_cnt)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsWhileCore(&services,cc,try_cnt);
}

U0 PrsDoWhile(CCmpCtrl *cc,I64 try_cnt)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsDoWhileCore(&services,cc,try_cnt);
}

U0 PrsFor(CCmpCtrl *cc,I64 try_cnt)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsForCore(&services,cc,try_cnt);
}

U0 PrsSwitch(CCmpCtrl *cc,I64 try_cnt)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsSwitchCore(&services,cc,try_cnt);
}

U0 PrsNoWarn(CCmpCtrl *cc)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsNoWarnCore(&services,cc);
}

#ifndef PRS_STREAM_BLK_IMPL
#define PRS_STREAM_BLK_IMPL PrsStreamBlk
#endif
U0 PRS_STREAM_BLK_IMPL(CCmpCtrl *cc)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsStreamBlkCore(&services,cc);
}

U0 PrsI386TryCall(CCmpCtrl *cc,CHashFun *fun,Bool begin=TRUE)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsI386TryCallCore(&services,cc,fun,begin);
}

U0 PrsTryBlk(CCmpCtrl *cc,I64 try_cnt)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  PrsTryBlkCore(&services,cc,try_cnt);
}

Bool PrsStmt(CCmpCtrl *cc,I64 try_cnt=0,
  CCodeMisc *lb_break=NULL,I64 cmp_flags=CMPF_PRS_SEMICOLON)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsStatementServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostStatementServices(&services,&globals);
  return PrsStmtCore(&services,cc,try_cnt,lb_break,cmp_flags);
}
