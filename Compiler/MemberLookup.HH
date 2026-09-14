#ifndef COMPILER_MEMBER_LOOKUP_INCLUDED
#define COMPILER_MEMBER_LOOKUP_INCLUDED
#include "/Kernel/SymbolTypes.HH"
public extern I64 MemberMetaData(U8 *name,CMemberLst *member);
public extern CMemberLstMeta *MemberMetaFind(U8 *name,CMemberLst *member);
public extern CMemberLst *MemberFind(U8 *name,CHashClass *type);
extern CMemberLst *MemberClassBaseFind(CHashClass *needle,CHashClass *type);
#endif
