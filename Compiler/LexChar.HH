#ifndef COMPILER_LEX_CHAR_INCLUDED
#define COMPILER_LEX_CHAR_INCLUDED
#include "/Compiler/LexInput.HH"
//Opening quote is consumed. Return token, -1 reader failure or -2 overlength.
//Failures retain partial input state but do not publish a token/value.
public extern I64 LexCharBody(CCmpCtrl *cc,CLexCharSource *source);
#endif
