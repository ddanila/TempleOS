extern U0 PrsStaticInit(CCmpCtrl *cc,CMemberLst *member,I64 pass);
#include "/Compiler/PrsTypeCore.HC"
U0 PrsHostSnapshotDrop(U8 *context,CCmpCtrl *cc) { LexPopNoRestore(cc); }
U0 PrsHostSnapshotPush(U8 *context,CCmpCtrl *cc) { LexPush(cc); }
I64 PrsHostIntegerExpression(U8 *context,CCmpCtrl *cc) { return LexExpressionI64(cc); }
CHashClass *PrsHostClassJoin(U8 *context,CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern)
{ return PrsClass(cc,keyword,flags,is_extern); }
CHashFun *PrsHostFunJoin(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags)
{ return PrsFunJoin(cc,return_type,name,flags); }
U8 *PrsHostTypeAllocate(U8 *context,I64 bytes) { return MAlloc(bytes); }
CMemberLst *PrsHostMemberNew(U8 *context,I64 register_hint) { return MemberLstNew(register_hint); }
U0 PrsHostMemberAdd(U8 *context,CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode)
{ MemberAdd(cc,member,type,mode); }
U0 PrsHostTypeServices(CPrsTypeServices *services)
{
  services->context=0; services->types=cmp.internal_types;
  services->lex=&PrsHostLex; services->report=&PrsHostReport;
  services->snapshot_drop=&PrsHostSnapshotDrop; services->snapshot_push=&PrsHostSnapshotPush;
  services->integer_expression=&PrsHostIntegerExpression;
  services->class_join=&PrsHostClassJoin; services->fun_join=&PrsHostFunJoin;
  services->allocate=&PrsHostTypeAllocate; services->duplicate=&PrsHostDuplicate;
  services->member_new=&PrsHostMemberNew; services->member_add=&PrsHostMemberAdd;
}

U0 PrsArrayDims(CCmpCtrl *cc,I64 mode,CArrayDim *dim)
{
  CPrsTypeServices services;
  PrsHostTypeServices(&services);
  PrsArrayDimsCore(&services,cc,mode,dim);
}

CHashClass *PrsType(CCmpCtrl *cc,CHashClass **_tmpc1,
  I64 *_mode,CMemberLst *tmpm,U8 **_ident,CHashFun **_fun_ptr,
  CHashExport **_tmpex,CArrayDim *tmpad,I64 fsp_flags)
{
  CPrsTypeServices services;
  PrsHostTypeServices(&services);
  return PrsTypeCore(&services,cc,_tmpc1,_mode,tmpm,_ident,_fun_ptr,_tmpex,tmpad,fsp_flags);
}

U0 PrsDotDotDot(CCmpCtrl *cc,CHashFun *tmpf,I64 _reg)
{
  CPrsTypeServices services;
  PrsHostTypeServices(&services);
  PrsDotDotDotCore(&services,cc,tmpf,_reg);
}

#include "/Compiler/PrsDeclarationCore.HC"
I64 PrsHostDefineMatch(U8 *context,U8 *name,U8 *list) { return DefineMatch(name,list); }
I64 PrsHostEvaluate(U8 *context,CCmpCtrl *cc) { return LexExpression(cc); }
U0 PrsHostSnapshotRestore(U8 *context,CCmpCtrl *cc) { LexPopRestore(cc); }
U0 PrsHostInitializeStatic(U8 *context,U8 *data,I64 bytes)
{ if(sys_var_init_flag) MemSet(data,sys_var_init_val,bytes); }
U0 PrsHostStaticInit(U8 *context,CCmpCtrl *cc,CMemberLst *member,I64 pass)
{ PrsStaticInit(cc,member,pass); }
U0 PrsHostStoreU64(U8 *context,CCmpCtrl *cc,I64 value) { AOTStoreCodeU64(cc,value); }
U0 PrsHostStoreU8At(U8 *context,CCmpCtrl *cc,I64 address,U8 value)
{ AOTStoreCodeU8At(cc,address,value); }
U0 PrsHostDataRange(U8 *context,CCmpCtrl *cc,I64 address,I64 bytes)
{ PrsI386DataRange(cc,address,bytes); }
U8 *PrsHostCompileExpression(U8 *context,CCmpCtrl *cc,I64 *type)
{ return LexExpression2Bin(cc,type); }
I64 PrsHostExecute(U8 *context,U8 *code) { return Call(code); }
U0 PrsHostRelease(U8 *context,U8 *allocation) { Free(allocation); }
U0 PrsHostDeclarationServices(CPrsDeclarationServices *services,
  CPrsExpressionServices *expression,CPrsTypeServices *types)
{
  services->context=0; services->expression=expression; services->types=types;
  services->define_match=&PrsHostDefineMatch; services->evaluate=&PrsHostEvaluate;
  services->snapshot_restore=&PrsHostSnapshotRestore; services->initialize_static=&PrsHostInitializeStatic;
  services->static_init=&PrsHostStaticInit; services->store_u64=&PrsHostStoreU64;
  services->store_u8_at=&PrsHostStoreU8At; services->data_range=&PrsHostDataRange;
  services->compile_expression=&PrsHostCompileExpression; services->execute=&PrsHostExecute;
  services->release=&PrsHostRelease;
}

U0 PrsVarLst(CCmpCtrl *cc,CHashClass *tmpc,I64 mode,I64 union_base=0)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&services,&expression,&types);
  PrsVarLstCore(&services,cc,tmpc,mode,union_base);
}

#include "/Compiler/PrsInitializerCore.HC"
U0 PrsHostCopy(U8 *context,U8 *destination,U8 *source,I64 bytes) { MemCpy(destination,source,bytes); }
U0 PrsHostSet(U8 *context,U8 *destination,U8 value,I64 bytes) { MemSet(destination,value,bytes); }
U0 PrsHostStoreU8(U8 *context,CCmpCtrl *cc,U8 value) { AOTStoreCodeU8(cc,value); }
U8 *PrsHostCompileCode(U8 *context,CCmpCtrl *cc,I64 *bytes) { return COCCompile(cc,bytes,NULL,NULL); }
U0 PrsHostInitializerServices(CPrsInitializerServices *services,CPrsDeclarationServices *declarations)
{
  services->context=0; services->declarations=declarations;
  services->copy=&PrsHostCopy; services->set=&PrsHostSet;
  services->store_u8=&PrsHostStoreU8; services->compile_code=&PrsHostCompileCode;
}

U0 PrsVarInit(CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,CArrayDim *tmpad,
	U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&services,&declarations);
  PrsVarInitCore(&services,cc,_dst,tmpc,tmpad,data_addr_rip,_base,data_heap,pass);
}

U0 PrsVarInit2(CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,
	CArrayDim *tmpad,U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&services,&declarations);
  PrsVarInit2Core(&services,cc,_dst,tmpc,tmpad,data_addr_rip,_base,data_heap,pass);
}

U0 PrsGlblInit(CCmpCtrl *cc,CHashGlblVar *tmpg,I64 pass)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&services,&declarations);
  PrsGlblInitCore(&services,cc,tmpg,pass);
}

U0 PrsStaticInit(CCmpCtrl *cc,CMemberLst *tmpm,I64 pass)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&services,&declarations);
  PrsStaticInitCore(&services,cc,tmpm,pass);
}
