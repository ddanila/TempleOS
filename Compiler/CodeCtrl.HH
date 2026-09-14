#ifndef COMPILER_CODE_CTRL_INCLUDED
#define COMPILER_CODE_CTRL_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#include "/Kernel/SymbolDelete.HH"
public extern U0 COCSeed(CCodeCtrl *coc);
public extern U0 ICSeed(CCmpCtrl *cc,CIntermediateCode *node,I64 opcode,I64 arg,CHashClass *type,I64 flags);
public extern U0 COCMiscSeed(CCmpCtrl *cc,CCodeMisc *node,I64 type);
//Valid exclusive graph. The diagnostic callback borrows the label and must return.
//Returns whether an undefined label was found, after reclaiming all allocations.
public extern Bool COCRelease(CCmpCtrl *cc,CCodeCtrl *coc,CSymbolRelease *owner,
  U0 (*label)(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)=0);
#endif
