//Stage 1: shared declarations; later stages retain the full token implementation.
#include "/Kernel/I386/PublicLexer.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicMath.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/StringLimits.HH"
#include "/Compiler/Keywords.HH"
#include "/Kernel/CharBitmaps.HH"
public extern I64 LexExpression(CCmpCtrl *cc);
public extern U0 PrsStreamBlk(CCmpCtrl *cc);
if(native_jit_support.lex_stage!=0)throw('LexLoad');
native_jit_support.lex_stage=1;
