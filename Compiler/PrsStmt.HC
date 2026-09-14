#include "/Compiler/PrsSymbolCore.HC"
CHashClass *PrsHostClassNew(U8 *context) { return PrsClassNew; }
CHashFun *PrsHostFunNew(U8 *context) { return PrsFunNew; }
CHash *PrsHostSingleFind(U8 *context,U8 *name,CHashTable *table,I64 mask)
{ return HashSingleTableFind(name,table,mask); }
U0 PrsHostClassMembersDelete(U8 *context,CHashClass *symbol) { ClassMemberLstDel(symbol); }
U0 PrsHostMembersDelete(U8 *context,CMemberLst *members) { MemberLstDel(members); }
U0 PrsHostSource(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol,I64 line_adjust)
{ HashSrcFileSet(cc,symbol,line_adjust); }
Bool PrsHostOption(U8 *context,I64 index) { return GetOption(index); }
U0 PrsHostSymbolWarning(U8 *context,CCmpCtrl *cc,I64 kind,CHashSrcSym *symbol)
{
  if(kind==0) UnusedExternWarning(cc,symbol);
  else {
    if(kind==1) PrintWarn("Fun Header return mismatch '%s'\n",symbol->str);
    else PrintWarn("Fun header args mismatch '%s'\n",symbol->str);
    cc->warning_cnt++;
  }
}
U0 PrsHostSymbolServices(CPrsSymbolServices *services,CPrsDeclarationServices *declarations)
{
  services->context=0; services->declarations=declarations;
  services->used_mask=REGG_CLOBBERED+REGG_SAVED+REGG_STK_TMP;
  services->clobbered_mask=REGG_CLOBBERED+REGG_STK_TMP;
  services->undefined_function=&UndefinedExtern;
  services->class_new=&PrsHostClassNew; services->fun_new=&PrsHostFunNew;
  services->single_find=&PrsHostSingleFind; services->class_members_delete=&PrsHostClassMembersDelete;
  services->members_delete=&PrsHostMembersDelete; services->source=&PrsHostSource;
  services->option=&PrsHostOption; services->warning=&PrsHostSymbolWarning;
}

CHashClass *PrsClass(CCmpCtrl *cc,I64 keyword,I64 fsp_flags,Bool is_extern)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostSymbolServices(&services,&declarations);
  return PrsClassCore(&services,cc,keyword,fsp_flags,is_extern);
}

CHashFun *PrsFunJoin(CCmpCtrl *cc,CHashClass *tmp_return,
	U8 *name,I64 fsp_flags)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostSymbolServices(&services,&declarations);
  return PrsFunJoinCore(&services,cc,tmp_return,name,fsp_flags);
}

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
U0 PrsHostExecuteLine(U8 *context,CCmpCtrl *cc) { ExeCmdLine(cc); }
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

U0 PrsStreamBlk(CCmpCtrl *cc)
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
