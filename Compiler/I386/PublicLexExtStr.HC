//Ordered stage after PublicLexPrelude; complete shared production bodies.
#define LEX_EXT_STR_IMPL NativeSystemLexExtStr
#include "/Compiler/LexExtStrCore.HC"
if(native_jit_support.lex_stage!=10)throw('LexLoad');
native_jit_support.lex_stage=11;
