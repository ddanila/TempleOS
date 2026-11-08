//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexNumber.HC"
if(native_jit_support.lex_stage!=3)throw('LexLoad');
native_jit_support.lex_stage=4;
