//Ordered normal shared-parser stage.
#define LEX_EXPRESSION_IMPL NativeSystemLexExpression
#define LEX_EXPRESSION_I64_IMPL NativeSystemLexExpressionI64
#define LEX_EXPRESSION_F64_IMPL NativeSystemLexExpressionF64
#define LEX_EXPRESSION_BIN_IMPL NativeSystemLexExpression2Bin
#define IS_LEX_EXPRESSION_BIN_IMPL NativeSystemIsLexExpression2Bin
#include "/Compiler/PrsExp.HC"
#define LEX_EXPRESSION_IMPL LexExpression
#define LEX_EXPRESSION_I64_IMPL LexExpressionI64
#define LEX_EXPRESSION_F64_IMPL LexExpressionF64
#define LEX_EXPRESSION_BIN_IMPL LexExpression2Bin
#define IS_LEX_EXPRESSION_BIN_IMPL IsLexExpression2Bin

if(native_jit_support.prs_stage!=1)throw('PrsLoad');
native_jit_support.prs_stage=2;
