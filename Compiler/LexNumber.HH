#ifndef COMPILER_LEX_NUMBER_INCLUDED
#define COMPILER_LEX_NUMBER_INCLUDED
#include "/Compiler/LexInput.HH"
//First digit/dot already consumed. Returns the body token or -1 on reader error.
//The caller performs the common final lookahead/replay step after success.
public extern I64 LexNumberBody(CCmpCtrl *cc,I64 ch,CLexCharSource *source);
#endif
