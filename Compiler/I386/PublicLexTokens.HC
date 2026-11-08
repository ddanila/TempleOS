//Ordered stage after PublicLexPrelude; complete shared production bodies.
#define LEX_TOKEN_IMPL NativeSystemLex
#include "/Compiler/LexDispatchCore.HC"
if(native_jit_support.lex_stage!=9)throw('LexLoad');
native_jit_support.lex_stage=10;
