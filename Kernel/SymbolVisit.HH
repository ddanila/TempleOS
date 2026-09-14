#ifndef KERNEL_SYMBOL_VISIT_INCLUDED
#define KERNEL_SYMBOL_VISIT_INCLUDED
#include "/Kernel/SymbolTypes.HH"
public class CSymbolRelease
{
  U8 *context;
  U0 (*release)(U8 *context,U8 *allocation);
};
public extern U0 SymbolLinkedLstVisit(CSymbolRelease *owner,U8 **node);
public extern U0 SymbolMemberLstVisit(CSymbolRelease *owner,CMemberLst *members);
public extern U0 SymbolHashVisit(CSymbolRelease *owner,CHashSrcSym *symbol);
#endif
