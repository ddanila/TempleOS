#ifndef KERNEL_SYMBOL_DELETE_INCLUDED
#define KERNEL_SYMBOL_DELETE_INCLUDED
#include "/Kernel/SymbolVisit.HH"
public extern U0 SymbolMemberLstDel(CSymbolRelease *owner,CMemberLst *members);
public extern U0 SymbolClassMemberLstDel(CSymbolRelease *owner,CHashClass *symbol);
public extern U0 SymbolHashDel(CSymbolRelease *owner,CHashSrcSym *symbol);
#endif
