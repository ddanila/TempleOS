//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexDefineSystemCore.HC"
if(native_jit_support.lex_stage!=7)throw('LexLoad');
native_jit_support.lex_stage=8;
