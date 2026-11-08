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

