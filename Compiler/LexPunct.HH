#ifndef COMPILER_LEX_PUNCT_INCLUDED
#define COMPILER_LEX_PUNCT_INCLUDED
#include "/Compiler/LexInput.HH"
class CLexPunctTables { U32 *first,*second,*third; };
//Populate three caller-owned, zeroed TK_TKS_NUM arrays. Retains no pointers.
public extern U0 LexPunctInit(U32 *first,U32 *second,U32 *third);
//Initial punctuation character is consumed. Return token, -1 failure, -2 skip.
//On a token, finish requests the common final lookahead; block-comment EOF does not.
public extern I64 LexPunctBody(CCmpCtrl *cc,I64 ch,CLexCharSource *source,CLexPunctTables *tables,Bool *finish);
#endif
