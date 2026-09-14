#ifndef COMPILER_MEMBER_BUILD_INCLUDED
#define COMPILER_MEMBER_BUILD_INCLUDED
#include "/Kernel/SymbolTypes.HH"
public extern Bool MemberInsert(CMemberLst *member,CHashClass *type,Bool local_var,
  Bool warn_dup_types,U0 (*diagnostic)(U8 *context,Bool warning),U8 *context);
public extern Bool MemberLstCmp(CMemberLst *left,CMemberLst *right,I64 cnt=0x7FFFFFFFFFFFFFFF);
#endif
