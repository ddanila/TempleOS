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

