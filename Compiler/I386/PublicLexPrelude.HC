//Stage 1: shared declarations; later stages retain the full token implementation.
#include "/Kernel/I386/PublicLexer.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicMath.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/StringLimits.HH"
#include "/Compiler/Keywords.HH"
#include "/Kernel/CharBitmaps.HH"
#include "/Kernel/I386/PublicExpression.HH"
if(native_jit_support.lex_stage!=0)throw('LexLoad');
native_jit_support.lex_stage=1;
