#ifndef COMPILER_LEX_INPUT_INCLUDED
#define COMPILER_LEX_INPUT_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#include "/Kernel/CharCodes.HH"
public extern Bool LexBufferStep(CCmpCtrl *cc,I64 *compiled_lines,U8 **end);
public extern U0 LexNormalizeChar(CCmpCtrl *cc);
#endif
