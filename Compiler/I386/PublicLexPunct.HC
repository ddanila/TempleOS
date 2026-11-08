//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexPunct.HC"
if(native_jit_support.lex_stage!=5)throw('LexLoad');
native_jit_support.lex_stage=6;
