//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexStringSystemCore.HC"
if(native_jit_support.lex_stage!=2)throw('LexLoad');
native_jit_support.lex_stage=3;
