#include "/Compiler/PrsSymbolCore.HC"
CHashClass *PrsHostClassNew(U8 *context) { return PrsClassNew; }
CHashFun *PrsHostFunNew(U8 *context) { return PrsFunNew; }
CHash *PrsHostSingleFind(U8 *context,U8 *name,CHashTable *table,I64 mask)
{ return HashSingleTableFind(name,table,mask); }
U0 PrsHostClassMembersDelete(U8 *context,CHashClass *symbol) { ClassMemberLstDel(symbol); }
U0 PrsHostMembersDelete(U8 *context,CMemberLst *members) { MemberLstDel(members); }
U0 PrsHostFunctionDelete(U8 *context,CHashFun *function) { HashDel(function); }
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
  services->header=0;
  services->class_new=&PrsHostClassNew; services->fun_new=&PrsHostFunNew;
  services->single_find=&PrsHostSingleFind; services->class_members_delete=&PrsHostClassMembersDelete;
  services->members_delete=&PrsHostMembersDelete; services->source=&PrsHostSource;
  services->option=&PrsHostOption; services->warning=&PrsHostSymbolWarning;
  services->function_delete=&PrsHostFunctionDelete;
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

