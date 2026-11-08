//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexChar.HC"
if(native_jit_support.lex_stage!=4)throw('LexLoad');
native_jit_support.lex_stage=5;
