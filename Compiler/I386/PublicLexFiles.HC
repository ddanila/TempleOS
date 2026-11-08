//Ordered stage after PublicLexPrelude; complete shared production bodies.
#include "/Compiler/LexFiles.HC"
#include "/Compiler/LexFilePushCore.HC"
#include "/Compiler/LexIncludeCore.HC"
if(native_jit_support.lex_stage!=1)throw('LexLoad');
native_jit_support.lex_stage=2;
