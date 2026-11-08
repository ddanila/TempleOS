#include "/Compiler/PublicLexSavepointsCore.HC"

#include "/Compiler/MemberLookup.HC"

#include "/Compiler/MemberBuild.HC"
U0 MemberCompilerDiagnostic(U8 *context,Bool warning)
{
  CCmpCtrl *cc=context;
  if(warning) LexWarn(cc,"Duplicate type at ");
  else LexExcept(cc,"Duplicate member at ");
}
U0 MemberAdd(CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode)
{
  MemberInsert(member,type,mode==PRS1B_LOCAL_VAR,
    Bt(&cc->opts,OPTf_WARN_DUP_TYPES),&MemberCompilerDiagnostic,cc);
}
CMemberLst *MemberLstNew(I64 _reg)
{
  CMemberLst *res=CAlloc(sizeof(CMemberLst));
  res->reg=_reg;
  return res;
}

#include "/Kernel/SymbolDelete.HH"
U0 SymbolCompilerFree(U8 *context,U8 *allocation)
{
  Free(allocation);
}
U0 MemberLstDel(CMemberLst *members)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&SymbolCompilerFree;
  SymbolMemberLstDel(&owner,members);
}
U0 ClassMemberLstDel(CHashClass *symbol)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&SymbolCompilerFree;
  SymbolClassMemberLstDel(&owner,symbol);
}

#include "/Compiler/MemberSizeCore.HC"

#include "/Compiler/LexExtStrCore.HC"
