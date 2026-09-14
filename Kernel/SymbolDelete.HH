#ifndef KERNEL_SYMBOL_DELETE_INCLUDED
#define KERNEL_SYMBOL_DELETE_INCLUDED
#include "/Kernel/SymbolTypes.HH"
public class CSymbolRelease
{
  U8 *context;
  U0 (*release)(U8 *context,U8 *allocation);
};
public extern U0 SymbolMemberLstDel(CSymbolRelease *owner,CMemberLst *members);
public extern U0 SymbolClassMemberLstDel(CSymbolRelease *owner,CHashClass *symbol);
public extern U0 SymbolHashDel(CSymbolRelease *owner,CHashSrcSym *symbol);
#endif
