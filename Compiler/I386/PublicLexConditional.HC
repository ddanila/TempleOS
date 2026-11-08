//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexConditional.HC"
if(native_jit_support.lex_stage!=8)throw('LexLoad');
native_jit_support.lex_stage=9;
