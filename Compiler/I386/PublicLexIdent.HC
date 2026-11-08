//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexIdentSystemCore.HC"
if(native_jit_support.lex_stage!=6)throw('LexLoad');
native_jit_support.lex_stage=7;
