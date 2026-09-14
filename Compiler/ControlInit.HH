#ifndef COMPILER_CONTROL_INIT_INCLUDED
#define COMPILER_CONTROL_INIT_INCLUDED
#include "/Kernel/CompilerTypes.HH"
public extern U0 CmpCtrlSeed(CCmpCtrl *cc,I64 flags,CHashTable *symbols,U32 *alpha_numeric);
public extern U0 LexFileSeed(CLexFile *file,U8 *buffer);
#endif
