#ifndef COMPILER_LEX_CONDITIONAL_INCLUDED
#define COMPILER_LEX_CONDITIONAL_INCLUDED
#include "/Compiler/LexInput.HH"
#include "/Compiler/Keywords.HH"
//Raw skip with token recognition only after a hash sign. 1 delimiter found, 0 EOF,
//negative reader/token failure. Callers own final lookahead and error handling.
public extern I64 LexSkipConditional(CCmpCtrl *cc,CLexCharSource *characters,CLexCharSource *tokens,I64 depth,Bool stop_else);
#endif
