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

