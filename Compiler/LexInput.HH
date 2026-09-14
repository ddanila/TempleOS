#ifndef COMPILER_LEX_INPUT_INCLUDED
#define COMPILER_LEX_INPUT_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#include "/Kernel/CharCodes.HH"
class CLexCharSource {
  U8 *context;
  I64 (*read)(U8 *context,CCmpCtrl *cc);
};
public extern Bool LexBufferStep(CCmpCtrl *cc,I64 *compiled_lines,U8 **end);
public extern U0 LexNormalizeChar(CCmpCtrl *cc);
#endif
