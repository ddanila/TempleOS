#ifndef COMPILER_LEX_DEFINE_INCLUDED
#define COMPILER_LEX_DEFINE_INCLUDED
#include "/Compiler/LexInput.HH"
#include "/Kernel/StringLimits.HH"
#include "/Kernel/CharBitmaps.HH"
class CLexDefineSink {
  U8 *context;
  Bool (*append)(U8 *context,U8 *text,I64 count);
};
class CLexDefineBuffer { U8 *text; I64 length; };
//After the name token, including its pending lookahead. Every chunk includes NUL;
//append replaces the preceding chunk's NUL. Partial sink output belongs to caller.
public extern Bool LexDefineRead(CCmpCtrl *cc,CLexCharSource *source,CLexDefineSink *sink);
#endif
